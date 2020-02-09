#include "wsserver.h"
#include "QtWebSockets/qwebsocketserver.h"
#include "QtWebSockets/qwebsocket.h"
#include <QtCore/QDebug>
#include "rotationwindow.h"


QT_USE_NAMESPACE


WsServer::WsServer(quint16 port, QObject *parent) :
    QObject(parent),
    m_pWebSocketServer(new QWebSocketServer(QStringLiteral("Echo Server"),
                                            QWebSocketServer::NonSecureMode, this)),
    m_clients()
{
    lastHarmonic = 0;
    if (m_pWebSocketServer->listen(QHostAddress::Any, port)) {
        qDebug() << "WsServer listening on port" << port;
        connect(m_pWebSocketServer, &QWebSocketServer::newConnection,
                this, &WsServer::onNewConnection);
        connect(m_pWebSocketServer, &QWebSocketServer::closed, this, &WsServer::closed);
    }
}


WsServer::~WsServer()
{
    m_pWebSocketServer->close();
    qDeleteAll(m_clients.begin(), m_clients.end());
}

int WsServer::getHarmonic(QString uuid)
{
    int harmonic = 0;

    if (clientsHash.contains(uuid))
        harmonic = clientsHash[uuid];
    else {
        harmonic = ++lastHarmonic;
        if (harmonic<=maxHarmonic) // add only if it is not out of given slidercount
            clientsHash.insert(uuid,harmonic);
    }
    return (harmonic>maxHarmonic) ? -1 : harmonic; // return -1 if
}


void WsServer::onNewConnection()
{
    QWebSocket *pSocket = m_pWebSocketServer->nextPendingConnection();

    connect(pSocket, &QWebSocket::textMessageReceived, this, &WsServer::processTextMessage);
    connect(pSocket, &QWebSocket::binaryMessageReceived, this, &WsServer::processBinaryMessage);
    connect(pSocket, &QWebSocket::disconnected, this, &WsServer::socketDisconnected);

    m_clients << pSocket;
    emit newConnection(m_clients.count());
}

void WsServer::processTextMessage(QString message)
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (!pClient) {
        return;
    }



    QStringList messageParts = message.split(" ");
    if (message.startsWith("harmonic_for")) {
        // check if the uui of the client is already known and the harmonic set

        QString uuid = messageParts[1];
        int harmonic = getHarmonic(uuid);

        pClient->sendTextMessage("harmonic "+ QString::number(harmonic)); // TODO: vastavalt
        if (harmonic==-1) { // there are already too many clients
            m_clients.removeAll(pClient);
            pClient->deleteLater();
            emit newConnection(m_clients.count());
        }
        //return;
    }

    if (message.startsWith("harmonic ")) {
        //qDebug()<<"Harmonic: "<<messageParts[1]<<" amplitude: "<< messageParts[2];
        emit newSliderValue(messageParts[1].toInt(), int(messageParts[2].toFloat()*100)  );
    }

	if (message.startsWith("shape ")) { // comes as shape <no> <value>
		qDebug()<<"Shape: "<<messageParts[1]<<" value: "<< messageParts[2];
		emit newShapeValue(messageParts[1].toInt(), int(messageParts[2].toFloat()*100)  );
	}

    if (message.startsWith("attack")) {
        //qDebug()<<"Harmonic: "<<messageParts[1]<<" attack!";
        emit attack(messageParts[1].toInt());
    }




//    m_pWebSocketServer->close();
}

void WsServer::processBinaryMessage(QByteArray message)
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (pClient) {
        pClient->sendBinaryMessage(message);
    }
}

void WsServer::socketDisconnected()
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (pClient) {
        m_clients.removeAll(pClient);
        emit newConnection(m_clients.count());
        pClient->deleteLater();
    }
}


void WsServer::sendMessage(QWebSocket *socket, QString message )
{
    if (socket == 0)
    {
        return;
    }
    socket->sendTextMessage(message);

}

