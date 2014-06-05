#include "rotationwindow.h"
#include "ui_rotationwindow.h"

RotationWindow::RotationWindow(int slidercount, QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::RotationWindow)
{
    ui->setupUi(this);
    sliderCount = slidercount;
    wsServer = new WsServer(7007);
    cs = new CsEngine("rotation-piece.csd",sliderCount);
    cs->start();
    for (int i=0; i<sliderCount;i++) {
        sliders.append(new QSlider);
        sliderLabels.append(new QLabel(QString::number(i+1)));
        ui->sliderLayout->addWidget(sliders[i],0,i);
        ui->sliderLayout->addWidget(sliderLabels[i],1,i);
    }

    connect(cs,SIGNAL(newSliderValue(int,int)),this,SLOT(setSliderValue(int,int)) );
    connect(cs, SIGNAL(newClient(int)),this, SLOT(setClientsCount(int)));
    connect(cs,SIGNAL(newTime(int)),this,SLOT(setRunTime(int)));
    connect(cs,SIGNAL(newCirleTime(int)),this,SLOT(setCircleTime(int)));

    connect(wsServer, SIGNAL(newConnection(int)), this, SLOT(setClientsCount(int)));
}

RotationWindow::~RotationWindow()
{
    delete ui;
}

void RotationWindow::setSliderValue(int slider, int value)
{
    sliders[slider-1]->setValue(value);
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
    QString cmd = "jack_rec -f rotation-performance"+QString::number(random()%1000)+".wav -d "+QString::number(dur+95) +" rotation-piece:output1 rotation-piece:output2 rotation-piece:output3 rotation-piece:output4 &";
    system(cmd.toLocal8Bit());
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
