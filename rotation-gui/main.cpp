#include "rotationwindow.h"
#include <QApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    int slidercount = 20;
    qDebug()<<"Usage: rotation-gui [--sliders | -s <slidercount> ]"<<endl;
    if (argc>1) {
        if (QString(argv[1]).startsWith("--sliders") || QString(argv[1]).startsWith("-s")) {
            slidercount =  atoi(argv[2]);
        }
    }

    RotationWindow w(slidercount);

    w.show();

    
    return a.exec();
}
