#-------------------------------------------------
#
# Project created by QtCreator 2013-11-19T11:54:40
#
#-------------------------------------------------

QT += core websockets
QT += widgets

#greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = rotation-gui
INCLUDEPATH += /home/tarmo/src/cs6/include/
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

LIBS += -L/home/tarmo/src/cs6/lib -lcsound64 -lsndfile  -ldl -lpthread -lcsnd6
