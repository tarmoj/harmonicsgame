#ifndef CSENGINE_H
#define CSENGINE_H

#include <QThread>
#include <csound/csound.hpp>
#include <csound/csPerfThread.hpp>
#include <QMutex>


class CsEngine : public QThread
{
    Q_OBJECT
private:
    bool mStop;
    Csound cs;
    char *m_csd;
    int errorValue;
    QString errorString;
    int sliderCount;

    //QMutex mutex;

public:
    explicit CsEngine(char *csd, int slidercount=16);
    void run();
    void stop();
    QString getErrorString();
    int getErrorValue();

    void setChannel(QString channel, MYFLT value);
    void csEvent(QString event_string);


    double getChannel(QString);
    Csound *getCsound();
signals:
    void newSliderValue(int silderno, int value);
    void newClient(int clientsCount);
    void newTime(int newTime);
    void newCirleTime(int newValue); // in 0..100
public slots:
    //void compileOrc(QString code);
    void restart();
};

#endif // CSENGINE_H
