#ifndef WSSERVER_H
#define WSSERVER_H

#include <QObject>
#include <QtCore/QList>
#include <QtCore/QByteArray>
#include <QtCore/QHash>

QT_FORWARD_DECLARE_CLASS(QWebSocketServer)
QT_FORWARD_DECLARE_CLASS(QWebSocket)


class WsServer : public QObject
{
    Q_OBJECT
public:
    explicit WsServer(quint16 port, QObject *parent = NULL);
    ~WsServer();
    int getHarmonic(QString uuid);
    void sendMessage(QWebSocket *socket, QString message);
    void setMaxHarmonic(int number) {maxHarmonic = number;}
Q_SIGNALS:
    void closed();
    void newConnection(int connectionsCount);
	void newSliderValue(int,int);
	void newShapeValue(int,int);
	void attack(int);


private Q_SLOTS:
    void onNewConnection();
    void processTextMessage(QString message);
    void processBinaryMessage(QByteArray message);
    void socketDisconnected();

private:
    QWebSocketServer *m_pWebSocketServer;
    QList<QWebSocket *> m_clients;
    int lastHarmonic;
    QHash<QString, int>  clientsHash;
    int maxHarmonic;

};



#endif // WSSERVER_H
