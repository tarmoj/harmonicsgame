#ifndef ROTATIONWINDOW_H
#define ROTATIONWINDOW_H

#include <QMainWindow>
#include <QtWidgets>
#include "csengine.h"
#include "wsserver.h"

namespace Ui {
class RotationWindow;
}

class RotationWindow : public QMainWindow
{
    Q_OBJECT
    
public:
    explicit RotationWindow(int slidercount = 16, QWidget *parent = 0);
    ~RotationWindow();

public slots:
    void setSliderValue(int slider, int value);
    void sliderMoved(int value);
    void setClientsCount(int clientsCount);
    void setRunTime(int runTime);
    void setCircleTime(int newValue);
    int getSliderCount() {return sliderCount;}

    void attack(int harmonic);
private slots:
    void on_cirleTimeSlider_valueChanged(int value);

    void on_playButton_clicked();

    void on_inButton_clicked();

    void on_outButton_clicked();

    void on_levelSlider_sliderMoved(int position);

    void on_resetButton_clicked();

private:
    Ui::RotationWindow *ui;
    QList <QSlider *> sliders;
    QList <QLabel *> sliderLabels;
    int sliderCount;
    CsEngine *cs;
    WsServer *wsServer;


};

#endif // ROTATIONWINDOW_H
