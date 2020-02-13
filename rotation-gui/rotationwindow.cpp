#include "rotationwindow.h"
#include "ui_rotationwindow.h"

RotationWindow::RotationWindow(int slidercount, QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::RotationWindow)
{
    ui->setupUi(this);
    sliderCount = slidercount;
    wsServer = new WsServer(7007);
    wsServer->setMaxHarmonic(sliderCount);


	//new CsEngine("rotation-piece.csd",sliderCount);

	// move csound into another thread
	csoundThread = new QThread(this);
	cs = new CsEngine();
	cs->moveToThread(csoundThread);


	connect(csoundThread, &QThread::finished, cs, &CsEngine::deleteLater);
	connect(csoundThread, &QThread::finished, csoundThread, &QThread::deleteLater); // somehow exiting from Csound is not clear yet, the thread gets destoyed when Csoun is still running.
	//connect(QApplication::instance(), &QApplication::aboutToQuit,cs,&CsEngine::stop ); // does not work here...

	// kuskile funtsioonid startCsound, stopCsoundm thread private
	// stopCsound -> connecct widget destoyed ja kuskil cs->stop(), csoundThread.quit(), csoundThread.wait()
	connect(this, &QWidget::destroyed, cs, &CsEngine::stop);
	connect(csoundThread, &QThread::started, cs, &CsEngine::play);
	csoundThread->start();

	//fill sliderLayout:
	ui->sliderLayout->addWidget(new QLabel("Amp"),0,0);
	ui->sliderLayout->addWidget(new QLabel("Shape"),1,0);
    for (int i=0; i<sliderCount;i++) {
        sliders.append(new QSlider);
		shapeSliders.append(new QSlider);
        sliderLabels.append(new QLabel(QString::number(i+1)));
		ui->sliderLayout->addWidget(sliders[i],0,i+1);
		ui->sliderLayout->addWidget(shapeSliders[i],1,i+1);
		ui->sliderLayout->addWidget(sliderLabels[i],2,i+1);
        connect(sliders[i],SIGNAL(valueChanged(int)),this, SLOT(sliderMoved(int)) );
		connect(shapeSliders[i],SIGNAL(valueChanged(int)),this, SLOT(sliderMoved(int)) );
    }

    connect(cs,SIGNAL(newTime(int)),this,SLOT(setRunTime(int)));
    connect(cs,SIGNAL(newCirleTime(int)),this,SLOT(setCircleTime(int)));

    connect(wsServer, SIGNAL(newConnection(int)), this, SLOT(setClientsCount(int)));
    connect(wsServer, SIGNAL(newSliderValue(int,int)), this, SLOT(setSliderValue(int,int)));
	connect(wsServer, SIGNAL(newShapeValue(int,int)), this, SLOT(setShapeValue(int,int)));

    connect(wsServer, SIGNAL(attack(int)), this, SLOT(attack(int)));

}

RotationWindow::~RotationWindow()
{
	cs->stop();
	csoundThread->quit();
	csoundThread->wait();
	delete ui;
}

void RotationWindow::setSliderValue(int slider, int value)
{
    if (slider>sliderCount) { // avoid array index out of range
        qDebug()<<"Slider number out of the range!";
        return;
    }
    sliders[slider-1]->setValue(value);
    cs->setChannel("h"+QString::number(slider), (MYFLT) value/100.0);  // send it now throug the widget ? time lag?

}

void RotationWindow::setShapeValue(int slider, int value)
{
	if (slider>sliderCount) { // avoid array index out of range
		qDebug()<<"Slider number out of the range!";
		return;
	}
	shapeSliders[slider-1]->setValue(value);
	//qDebug() << "Shape to Csound " << slider << " " << value;
	cs->setChannel("shape"+QString::number(slider), (MYFLT) value/100.0);


}

void RotationWindow::sliderMoved(int value)
{
    QSlider *slider = qobject_cast<QSlider *>(sender());
    int sliderno = sliders.indexOf(slider)+1;
    cs->setChannel("h"+QString::number(sliderno), (MYFLT) value/100.0);

}

void RotationWindow::setClientsCount(int clientsCount)
{
    ui->clientsNoLabel->setText(QString::number(clientsCount));
}

void RotationWindow::setRunTime(int runTime)
{
    ui->playTimeEdit->setTime(QTime(0,runTime/60,runTime%60));
}

void RotationWindow::setCircleTime(int newValue)
{
    ui->cirleTimeSlider->setValue(newValue);
}

void RotationWindow::on_cirleTimeSlider_valueChanged(int value)
{
    cs->setChannel("circletime",MYFLT(2+(float)value/100*18)); // vahemikku 2..20
}

void RotationWindow::on_playButton_clicked()
{
    int dur = ui->durationEdit->time().minute()*60 + ui->durationEdit->time().second();
    qDebug()<< "Starting the runthrough, duration (seconds): "<<dur;
    cs->csEvent("i \"control\" 0 " + QString::number(dur)); //TODO: aeg widgetist durTimeEdit-> sekunditesks
    //QString cmd = "jack_rec -f rotation-performance"+QString::number(random()%1000)+".wav -d "+QString::number(dur+95) +" rotation-piece:output1 rotation-piece:output2 rotation-piece:output3 rotation-piece:output4 &";
    //system(cmd.toLocal8Bit());
}

void RotationWindow::on_inButton_clicked()
{
    //int const fadeTime = 5;
    cs->csEvent("i \"fade\" 0 5 1");
}

void RotationWindow::on_outButton_clicked()
{
    cs->csEvent("i \"fade\" 0 20 0");
}

void RotationWindow::attack(int harmonic) {
	cs->csEvent("i \"atack\" 0 1 " + QString::number(harmonic));
}

void RotationWindow::closeEvent(QCloseEvent *event)
{
	qDebug() << Q_FUNC_INFO;
	cs->stop();
	cs->deleteLater();
	//csoundThread->exit();
	QMainWindow::closeEvent(event);
}

void RotationWindow::on_levelSlider_sliderMoved(int position)
{
    cs->setChannel("level",MYFLT((float)position/100));
}

void RotationWindow::on_resetButton_clicked()
{
    for (int i=0; i<sliderCount;i++) {
        sliders[i]->setValue(0);
        cs->setChannel("h"+QString::number(i+1), 0);
    }
}


void RotationWindow::on_playAllButton_clicked()
{
	for (int i=1; i<=sliderCount;i++) {
		setShapeValue(i,100);
		//attack(i);
	}
	QThread::msleep(100);
	for (int i=1; i<=sliderCount;i++) {
		attack(i);
	}
}
