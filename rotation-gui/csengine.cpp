#include "csengine.h"
#include <QDebug>
#include <QCoreApplication>


CsEngine::CsEngine(QObject *parent) : QObject(parent)
{
	csd = "../rotation-piece.csd";
	stopNow = false;
	cs = NULL;
}

CsEngine::~CsEngine()
{
	stop(); // this is mess
}


void CsEngine::play() {
	cs = new Csound();
	cs->Compile(csd.toLocal8Bit().data()); // ERROR HANDLING!
	MYFLT runTime = 0, value = 0, circleTime = 0;
	while (cs->PerformKsmps()==0 && !stopNow) {
		QCoreApplication::processEvents(); // probably bad solution but works. otherwise other slots will never be called

		value = getChannel("time");
		if ( value != runTime) {
			runTime = value;
			emit newTime(int(runTime));
		}

		value = getChannel("circletime");
		if ( value != circleTime) {
			circleTime = value;
			emit newCirleTime(int((circleTime-2)/18*100));
		}
	}
	qDebug()<<"Stopping csound";
	cs->Stop();
	delete cs;
	stopNow = false;

}

void CsEngine::stop() {
	stopNow = true;
}

void CsEngine::setChannel(QString channel, double value) {
	//qDebug()<<"channel: "<<channel << " value: "<<value;
	if (cs)
		cs->SetChannel(channel.toLocal8Bit(),value);
}

void CsEngine::csEvent(QString event)
{
	if (cs)
		cs->InputMessage(event.toLocal8Bit());
}


MYFLT CsEngine::getChannel(QString channel)
{
	if (cs)
		return cs->GetChannel(channel.toLocal8Bit());
	else
		return -1;
}
