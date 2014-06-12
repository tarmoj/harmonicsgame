;rotation-piece tester client
<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 44100 
ksmps = 1024
nchnls = 2
0dbfs = 1

#define OSC #0#
#define WS #1#

gimode = $WS

#define HOST #"localhost"# ;  hiljem: "192.168.11.199"
;instr fromWidget
;	kamp chnget "amp"
;	kharm chnget "harmonic"
;	katack chnget "atack"
;	;etc	
;endin

index = 1
label:
	schedule "tester", 0,3600,index
	loop_le index, 1, 20, label

; for websocket-connection


pyinit
pyruni {{
from websocket import create_connection # you need websocket-client module installed
ws = create_connection("ws://localhost:7007")
ws.send("csound: hello")
print "Websocket created"

def sendMessage(harmonic, value): # if value 999, then atack
	if (value==999):
		command = "attack " + str(int(harmonic))
		print command
	else:
		command = "harmonic %d %f" % (harmonic, value) 
		
	#print command
	ws.send(command) 
	

}}


instr tester
	iharm = p4
	kamp = 0.4+jspline(0.3,0.2,1)
	if (gimode == $OSC) then
		OSCsend 1, $HOST,9000,"/harmonics/hello","si","localhost",100+iharm
	endif
	
	ktrig metro 20 ; 50  korda sekundis
	if (gimode == $OSC) then
		OSCsend ktrig, $HOST, 9000, "/harmonics/harmonic", "if", iharm, kamp
	elseif (gimode == $WS) then
		pycall "sendMessage", iharm, kamp
	endif
	kout trigger kamp, 0.6,2
	schedkwhen kout, 0, 0, "sendAtack", 0, 0.1, iharm	
endin

; schedule "sendAtack",0,0.1,7
instr sendAtack
	iharm = p4
	if (gimode == $OSC) then
		OSCsend 1, $HOST, 9000, "/harmonics/atack", "if", iharm, 0
	elseif (gimode == $WS) then
		pycalli "sendMessage", iharm, 999
	endif
endin


</CsInstruments>
<CsScore>


</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>203</width>
 <height>82</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>8</x>
  <y>11</y>
  <width>80</width>
  <height>25</height>
  <uuid>{1970b281-a884-4e56-a7dd-8cf5888ef390}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Harmonic:</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>harmonic</objectName>
  <x>100</x>
  <y>13</y>
  <width>80</width>
  <height>25</height>
  <uuid>{e2e72f3a-c800-4d7b-8f15-71b5659bcbb8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>1</minimum>
  <maximum>40</maximum>
  <randomizable group="0">false</randomizable>
  <value>0</value>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>amp</objectName>
  <x>7</x>
  <y>54</y>
  <width>89</width>
  <height>27</height>
  <uuid>{a7ad63ee-93b5-4543-8e40-26abf37bf957}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>atack</objectName>
  <x>103</x>
  <y>52</y>
  <width>100</width>
  <height>30</height>
  <uuid>{da5551e0-fb61-45c5-8c5d-c1f9e0d51b8a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>value</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Atack</text>
  <image>/</image>
  <eventLine>i "sendAtack" 0 0.1 1</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
