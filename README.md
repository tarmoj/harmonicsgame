harmonicsgame
=============

Interactive soundgame developed for Participation concerts http://tarmo.uuu.ee/osaluskontserdid/
Also named: Rotation piece, Harmonics control

Languages used:
User interface: written in html5, javascript
Communication between clients and server: websockets
Sound syntehsis: Csound
Main server program (WS-server, Csound-API, GUI): Qt C++

Users need to go to local wifi network and connect to WS server. They get assigned a harmonic, 
which they are going to control. User can influence the amplitude of the harmonic and play atacks on the harmonic.
The Csound side of the server plays the harmonics, makes them  rotatate between 4 channels, introduces some changes to 
timbre, frequency etc.

Created by: Tarmo Johannes tarmo@otsakool.edu.ee
