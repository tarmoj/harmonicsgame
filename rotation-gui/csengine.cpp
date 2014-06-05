#include "csengine.h"
#include <QDebug>


// NB! use DEFINES += USE_DOUBLE


CsEngine::CsEngine(char *csd, int slidercount)
{
    mStop=false;
    m_csd = csd;
    errorValue=0;
    sliderCount = slidercount;

}

/*
CsEngine::~CsEngine()
{
    free cs;

} */



Csound *CsEngine::getCsound() {return &cs;}

void CsEngine::run()
{

    //if ( open(m_csd)) {
    if ( cs.Compile(m_csd)) {
		qDebug()<<"Could not open csound file "<<m_csd;
        return;
    }
    CsoundPerformanceThread perfThread(&cs);
    perfThread.Play();

    MYFLT *sliderValue = new MYFLT[sliderCount];
    MYFLT clientsCount = 0 , runTime = 0, value = 0, circleTime = 0;
    while (!mStop  && perfThread.GetStatus() == 0 ) {
        usleep(10000);  // ? et ei teeks tööd kogu aeg

        for (int i=0;i<sliderCount;i++)  {
            value=getChannel("h"+QString::number(i+1));
            if (value!=sliderValue[i]) {
                emit newSliderValue(i+1,int(value*100));
                sliderValue[i]=value;
            }
        }
        value = getChannel("clients");
        if ( value != clientsCount) {
            clientsCount = value;
            emit newClient(clientsCount);
        }

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
    qDebug()<<"Stopping thread";
    perfThread.Stop();
    perfThread.Join();
    mStop=false; // luba uuesti käivitamine
}

void CsEngine::stop()
{
    // cs.Reset();  // ?kills Csound at all
    mStop = true;

}

QString CsEngine::getErrorString()  // probably not necessry
{
    return errorString;
}

int CsEngine::getErrorValue()
{
    return errorValue;
}


MYFLT CsEngine::getChannel(QString channel)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
    return cs.GetChannel(channel.toLocal8Bit());
}

//void CsEngine::compileOrc(QString code)
//{

//    //qDebug()<<"Code to compile: "<<code;
//    //mutex.lock(); // is it necessary?
//    QString message;
//    errorValue =  cs.CompileOrc(code.toLocal8Bit());
//    if ( errorValue )
//        message = "Could not compile the code";
//    else
//        message = "OK";
//    //mutex.unlock();

//}

void CsEngine::restart()
{
    stop(); // sets mStop true
    while (mStop) // run sets mStop false again when perftrhead has joined
        usleep(100000);
    start();
}

void CsEngine::setChannel(QString channel, MYFLT value)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
    cs.SetChannel(channel.toLocal8Bit(), value);
}

void CsEngine::csEvent(QString event_string)
{
    cs.InputMessage(event_string.toLocal8Bit());
}
