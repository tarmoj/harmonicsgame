#-------------------------------------------------
#
# Project created by QtCreator 2013-11-19T11:54:40
#
#-------------------------------------------------

QT += core websockets
QT += widgets

#greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = rotation-gui
INCLUDEPATH += /usr/local/include/csound # not necessary when csound is installed to default place
TEMPLATE = app

#DEFINES += USE_DOUBLE


SOURCES += main.cpp\
        rotationwindow.cpp \
    csengine.cpp \
    wsserver.cpp

HEADERS  += rotationwindow.h \
    csengine.h \
    wsserver.h

FORMS    += rotationwindow.ui

LIBS += -lcsound64  -lcsnd6
 # -lsndfile  -ldl -lpthread
# -L/home/tarmo/src/cs6/lib not necessary when csound is installed to default place
