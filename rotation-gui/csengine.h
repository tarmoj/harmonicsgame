#ifndef CSENGINE_H
#define CSENGINE_H

#include <QObject>
#include "csound.hpp"


class CsEngine : public QObject
{
	Q_OBJECT
public:
	explicit CsEngine(QObject *parent = 0);
	~CsEngine();


signals:
	void newTime(int newTime);
	void newCirleTime(int newValue); // in 0..100

public slots:
	void setChannel(QString channel, MYFLT value);
	MYFLT getChannel(QString channel);
	void play();
	void stop();
	void csEvent(QString event);

private:
	Csound * cs;
	QString csd; // resolve later
	bool stopNow;
};

#endif // CSENGINE_H
