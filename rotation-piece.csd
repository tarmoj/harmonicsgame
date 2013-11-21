<CsoundSynthesizer>
<CsOptions>
-b1024 -B2048 --realtime -+rtaudio=jack -odac:system:playback_ -+jack_client=rotation-piece  -+rtmidi=alsaraw -Ma
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2;4
0dbfs = 1

#define MAXAMP #0.5#
#define MINAMP # $MAXAMP*0.25 #

#define MINSPEED #1#
#define MAXSPEED #2#

;CONSTANTS: -----------------------
giHandle OSCinit 9000 ; osc messages about level of harmonics

giSine ftgen 0, 0, 65536, 10, 1, 0.1;,0.05;,0.05,0.01;0.1,0.1,0.05,0.04,0.03,0.02,0.02



giSine2 ftgen 0, 0, 65536, 10, 1, 0.6,0.4,0.3,0.2,0.1,0.05,0.002

gkFn init -1;giSine;-1
gkLevel init 1

giBaseFreq=cpspch(6.02)
;giRotationSpeed[] fillarray 1, 1.25,  1.5, 1.75, 2, 2.1, 2.2, 2.3

gkCircleTime init 15
chnset 15,"circletime"

giHarmCount init 20;20
gkAmplitude[] init giHarmCount
gaAtack[] init giHarmCount
gkFreq[] genarray_i giBaseFreq, giBaseFreq*giHarmCount, giBaseFreq



; CHANNELS: ----------

chn_k "circletime", 3
chn_k "time",2

giharm = 1
channels:
	Schn sprintf "h%d",giharm	
	chn_k Schn,3
	loop_le giharm, 1, giHarmCount, channels

;vbaplsinit 2, 4, -45, 45, 135, -135
vbaplsinit 2, 2, -45, 45

; TEST: --------------
seed 0
index = 6
label:
	;schedule "tester", 0,3600,index
	loop_le index, 1, 16, label


instr tester
	iharm = p4
	kamp = 0.5+jspline(0.4,0.2,1)
	gkAmplitude[iharm-1] = kamp
	kout trigger kamp, 0.6,2
	schedkwhen kout, 0, 0, "atack", 0, 0.1, iharm	
endin




;TODO: checkbox või menu, kas midi või OSC
; MIDI: --------------------------------------------
;alwayson "readmidi"
; schedule "readmidi",0,5
instr readmidi	

	gkAmplitude[0]  ctrl7 1, 0, 0, 1 
	gkAmplitude[1] ctrl7 1, 1, 0, 1
	gkAmplitude[2] ctrl7 1, 2, 0, 1
	gkAmplitude[3] ctrl7 1, 3, 0, 1
	gkAmplitude[4] ctrl7 1, 4, 0, 1
	gkAmplitude[5] ctrl7 1, 5, 0, 1
	gkAmplitude[6] ctrl7 1, 6, 0, 1
	initc7 1, 7, 0
	gkAmplitude[7] ctrl7 1, 7, 0, 1
	
	gkAmplitude[8] ctrl7 1, 16, 0, 1	
	gkAmplitude[9] ctrl7 1, 17, 0, 1
	gkAmplitude[10] ctrl7 1, 18, 0, 1
	gkAmplitude[11] ctrl7 1, 19, 0, 1
	gkAmplitude[12] ctrl7 1, 20, 0, 1
	gkAmplitude[13] ctrl7 1, 21, 0, 1
	gkAmplitude[14] ctrl7 1, 22, 0, 1
	gkAmplitude[15] ctrl7 1, 23, 0, 1

schedule "readmidibutton",0,3600,64,1
schedule "readmidibutton",0,3600,65,2
schedule "readmidibutton",0,3600,66,3
schedule "readmidibutton",0,3600,67,4
schedule "readmidibutton",0,3600,68,5
schedule "readmidibutton",0,3600,69,6
schedule "readmidibutton",0,3600,70,7
schedule "readmidibutton",0,3600,71,8

schedule "readmidibutton",0,3600,48,9
schedule "readmidibutton",0,3600,49,10
schedule "readmidibutton",0,3600,50,11
schedule "readmidibutton",0,3600,51,12
schedule "readmidibutton",0,3600,52,13
schedule "readmidibutton",0,3600,53,14
schedule "readmidibutton",0,3600,54,15
schedule "readmidibutton",0,3600,55,16

endin



instr readmidibutton
	ibutton = p4
	iharmonic = p5
	kval ctrl7 1,ibutton,0,1
	if (changed(kval)==1 && kval==1) then
		schedkwhen kval, 0, 0, "atack", 0, 1, iharmonic
	endif
endin


; OSC: ---------------------------------------------
alwayson "osc"
pyinit
pyruni {{
ids = [] #  ;id-s (last parts of IP addresses of client
clientsCount = 0
}}

; TODO! vaata, et indeks poleks kunagi -1!!!
instr osc
	SClientIP = ""
	kID init 0
	khello OSClisten giHandle, "/harmonics/hello","si",SClientIP,kID ; id - viimane osa IP aadressist. Antud arvuna, et ei peaks enam eraldi eraldama
	if (khello==1) then 
	   ; salvesta ID, uuri, kas see on juba olemas, kui ei, lisa massiivi
	  	; saada ip vatava harm. numbriga
		;printk2 kID
		pyassign "id", kID
		pyrun {{
if not (id in ids):
	ids.append(id)
	clientsCount += 1
	#q.setChannelValue("clients",clientsCount)
	harmonic = float(clientsCount)
	new = 1.0 
else:
	harmonic = float(ids.index(id)+1) # kui juba registreeritud, anna osaheli number asendi järgi massiivis
	new = 0.0
}}	 	   		
	    kport = 9000 + kID ; kuna nii arvestab seda android klient

	    kharmonic pyeval "harmonic"
	    chnset kharmonic,"clients"
		knew pyeval "new"	    

	    ;schedkwhen knew,0,0, nstrnum("sound")+kharmonic/100,0,-1,kharmonic
	         
		Sin sprintfk "i \"sendHarmonic\" 0 0.1 %d \"%s\" %d",kport,SClientIP, kharmonic
		puts Sin, kharmonic
		scoreline Sin, khello
		
	endif						
	
	kAmpNo init 0
	kamp init 0
	kAmpMessage OSClisten giHandle, "/harmonics/harmonic", "if", kAmpNo,kamp ; in android - do not send ID, not necessary
	if (kAmpMessage==1 && kAmpNo>0) then
		
		gkAmplitude[kAmpNo-1]=kamp ; port?		
		;printk2 	gkAmplitude[kAmpNo]	
	endif
	kdummy init 0
	kattack OSClisten giHandle, "/harmonics/atack", "if", kharmonic,kdummy
	schedkwhen kattack&kharmonic, 0, 0, "atack", 0, 1, kharmonic ; only when kharmonic is not 0
endin


instr sendHarmonic
	iport = p4
	Shost strget p5
	iharmonic = p6
	prints Shost
	OSCsend 1, Shost, iport,"/harmonics/number", "i", iharmonic
	turnoff
endin

; CONTROL LINES: ----------------------------------
;schedule "control", 0,120
instr control ; 15 min?
	; 1 -kiirususe jonksud: 15-5-20 pealt alla suureneb 
	; 2 - paigal ? suunamuutused? edasip
	; slide, kiirus kasvab
	; kiirus aeglustub
	; faasid 1 && 2
	istart = 15
	ifast = 4
	ifastest = 2
	islowest = 20
	islidestart = p3*0.5
	gkCircleTime expseg istart, p3/8, istart, p3/16, ifast+2, p3/16, istart,
	p3/4, istart, p3/4,ifastest, p3/16,ifastest,p3/8,islowest, p3/16, islowest
	chnset gkCircleTime, "circletime"
	ktrig metro 1 ; take time every second
	if ktrig==1 then
		ktime timeinsts	
		chnset int(ktime),"time" 
		printk2 ktime
	endif
	schedule "slide_start",islidestart,p3/4,4/3
	 
endin


; SOUND: -----------------------------------------

schedule "rotate",0,3600
instr rotate
	iharm = 1
looppoint:
    event_i "i", "note", 0, p3, iharm ; algus oli 0.05*iharm
    ;gkFreq[iharm-1] init giBaseFreq*iharm ; does init work?
    loop_le	iharm,1,giHarmCount,looppoint
    
    gkCircleTime chnget "circletime"
endin


;event_i "i", "atack", 0, 0.5, 16, 0.2
instr atack ; line up and down during p3, if p3 short, like atack
	index = p4-1 ; p4 - harmonic's number
	printf_i "Atack %d\n", 1, p4
	
	atack linseg 0,0.05,3,p3-0.05,0 ; lisa see instrumendsi "note"
	gaAtack[index] = gaAtack[index] + atack
endin

;schedule "slide_start",0,60,2
instr slide_start
	;iHarmCount = giHarmCount
	iEndInterval = p4
	iharm = 1
looppoint:
    event_i "i", "slide", 0, p3, iharm, iEndInterval ; algus oli 0.05*iharm
    ;gkFreq[iharm-1] init giBaseFreq*iharm ; does init work?
    loop_le	iharm,1,giHarmCount,looppoint    
endin

;schedule "slide",0,15
instr slide
	index = p4-1
	iEndInterval = p5-1
	;gkFreq[index] line giBase*(index+1),p3,giBase*(index+1)*1.5
	
	kmod phasor 1/p3
	kcurve expcurve kmod,index*4+1.1 ; give different curve for all harmonics
	;printk 0.1,kcurve
	gkFreq[index] =  giBaseFreq*(index+1)*(1+kcurve*iEndInterval)

endin

#define OUT #0#
#define IN #1#

; schedule "fade",0,5,1
instr fade ; p4: 0 - out 1 - in
	istart = (p4==$OUT) ? 1 : 0
	iend = (p4==$OUT) ? 0 : 1
	gkLevel line istart,p3,iend
endin

instr note
	iharmonic = p4
	; 4 kanalit- kasuta vbap4 ?
	iamp = ($MAXAMP - ($MAXAMP-$MINAMP)/giHarmCount*(iharmonic-1))/sqrt(giHarmCount)*0.5
	iRotationSpeed = $MINSPEED + ($MAXSPEED-$MINSPEED)/giHarmCount*(iharmonic-1)
	;print giRotationSpeed[iharmonic-1]*giCircleTime
	print iamp, iRotationSpeed
	kdegree phasor 1/gkCircleTime*iRotationSpeed;giRotationSpeed[iharmonic]
	kdegree *= 360
	;SchannelName sprintf "harm%d",iharmonic-1
	SharmName sprintf "h%d",iharmonic
	chnset gkAmplitude[iharmonic-1], SharmName
	;ifn =  (iharmonic == 1) ? giSine2 : giSine; -1
	aenv linen 1,0.2,p3,0.2
	kamp port gkAmplitude[iharmonic-1],0.05
	asig oscilikt kamp*aenv*iamp*(gaAtack[iharmonic-1]+1)*gkLevel,gkFreq[iharmonic-1], gkFn;ifn
	gaAtack[iharmonic-1] = 0
	a1, a2, a3, a4 vbap4 asig, kdegree 
	;a1, a2,a3,a4 locsig asig, kdegree, 1, 0
	a1,a2 vbap asig, kdegree  
	;outs a1,a2
	;outq a1,a2,a3,a4
	
endin


</CsInstruments>
<CsScore>
</CsScore>
</CsoundSynthesizer>



##### KNOBS ------------
harmcount = 40
diameter = 30
#for row in range(harmcount/5):
for count in range(harmcount):
    	q.createNewKnob(20+(count%5)*diameter, 40+(count/5)*diameter, "harm"+str(count))
    	q.setWidgetProperty("harm"+str(count),"QCS_width",diameter)


#### METERS ------------------

meter = [] # meter widgets for level displays
label = []	# and according labels
meterWidth = 21

def deleteMeters():
	global meterWidth
	for w in  q.getWidgetUuids():
		if (q.getWidgetProperty(w,"QCS_width")==meterWidth): 	# let's hope there are no other widgets with that width
			q.destroyWidget(w)		

def createMeters(metersCount):
	global meter
	global label
	if (len(meter)>0):
		for m in meter:
			q.destroyWidget(m)
		meter = []
	if (len(label)>0):
		for l in label:
			q.destroyWidget(l)
		label = []	
	Y = 125
	X0 = 5
	
	for i in range(0,metersCount):
		meter.append(q.createNewMeter(X0+i*meterWidth,Y,"h"+str(i+1)))
		q.setWidgetProperty(meter[i],"QCS_height",200)
		q.setWidgetProperty(meter[i],"QCS_height",200)
		q.setWidgetProperty(meter[i],"QCS_width",meterWidth)
		label.append(q.createNewLabel(X0+i*meterWidth, Y-20,str(i+1)))
		q.setWidgetProperty(label[i],"QCS_width",meterWidth)

deleteMeters()
createMeters(20)


<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>425</width>
 <height>803</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm0</objectName>
  <x>21</x>
  <y>513</y>
  <width>30</width>
  <height>80</height>
  <uuid>{c9ca5d94-381d-439a-8698-cc1319c611f2}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.75243537</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm1</objectName>
  <x>51</x>
  <y>513</y>
  <width>30</width>
  <height>80</height>
  <uuid>{f86fcfa7-3c5a-4b98-af1e-4cf62881c0da}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.92446259</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm2</objectName>
  <x>81</x>
  <y>513</y>
  <width>30</width>
  <height>80</height>
  <uuid>{fe1d441f-5a39-4771-8def-d3b6aa899b04}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.09648980</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm3</objectName>
  <x>111</x>
  <y>513</y>
  <width>30</width>
  <height>80</height>
  <uuid>{1adf40cc-5803-4e67-be4c-d83dbe9d2e09}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.26851701</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm4</objectName>
  <x>141</x>
  <y>513</y>
  <width>30</width>
  <height>80</height>
  <uuid>{245d591c-c8ad-4624-ba0d-4ec9e982ce48}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.44054422</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm5</objectName>
  <x>21</x>
  <y>543</y>
  <width>30</width>
  <height>80</height>
  <uuid>{dd9601ee-3642-4404-9a6d-2b7986dd2ae9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.61257143</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm6</objectName>
  <x>51</x>
  <y>543</y>
  <width>30</width>
  <height>80</height>
  <uuid>{6e1e06c0-abf6-4f10-934c-b3011c7e58cc}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.78459864</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm7</objectName>
  <x>81</x>
  <y>543</y>
  <width>30</width>
  <height>80</height>
  <uuid>{7c77da81-419d-4a43-a4b9-47c99d26a4b5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.95662585</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm8</objectName>
  <x>111</x>
  <y>543</y>
  <width>30</width>
  <height>80</height>
  <uuid>{89408ffa-8ac2-41b0-9efe-89a24d5f745d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.12865306</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm9</objectName>
  <x>141</x>
  <y>543</y>
  <width>30</width>
  <height>80</height>
  <uuid>{0007c654-7e71-438f-9bbe-81ed1fce0c33}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.30068027</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm10</objectName>
  <x>21</x>
  <y>573</y>
  <width>30</width>
  <height>80</height>
  <uuid>{12bf206c-f0fb-4c9a-8688-5ba988f74857}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.47270748</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm11</objectName>
  <x>51</x>
  <y>573</y>
  <width>30</width>
  <height>80</height>
  <uuid>{040e3ae0-d5de-4023-88b4-08fb9a340b3c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.64473469</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm12</objectName>
  <x>81</x>
  <y>573</y>
  <width>30</width>
  <height>80</height>
  <uuid>{9356d378-ee24-4c08-9d4e-eccbfecec343}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.81676190</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm13</objectName>
  <x>111</x>
  <y>573</y>
  <width>30</width>
  <height>80</height>
  <uuid>{5010689b-cd4f-4ed1-a5ac-3ac03b02b3dc}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.98878912</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm14</objectName>
  <x>141</x>
  <y>573</y>
  <width>30</width>
  <height>80</height>
  <uuid>{f76b9a2f-1d49-4b6d-971b-69711e016885}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.16081633</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm15</objectName>
  <x>21</x>
  <y>603</y>
  <width>30</width>
  <height>80</height>
  <uuid>{04a57aa7-98be-473b-9cb2-fa5bdae1d351}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.33284354</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm16</objectName>
  <x>51</x>
  <y>603</y>
  <width>30</width>
  <height>80</height>
  <uuid>{f3013ccf-54fa-40fd-b88a-afddfd547b9f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.16403896</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm17</objectName>
  <x>81</x>
  <y>603</y>
  <width>30</width>
  <height>80</height>
  <uuid>{01e50657-7a99-4fc5-8e60-0f22a71ab673}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.52214896</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm18</objectName>
  <x>111</x>
  <y>603</y>
  <width>30</width>
  <height>80</height>
  <uuid>{b7f399e2-4adf-4e58-9ed8-17749b6149fc}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.87834893</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm19</objectName>
  <x>141</x>
  <y>603</y>
  <width>30</width>
  <height>80</height>
  <uuid>{2495d514-915a-4699-b38c-f37de0112623}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.23044796</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm20</objectName>
  <x>21</x>
  <y>633</y>
  <width>30</width>
  <height>80</height>
  <uuid>{f0448970-6203-44cb-b969-20aa59c55eb5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.14920342</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm21</objectName>
  <x>51</x>
  <y>633</y>
  <width>30</width>
  <height>80</height>
  <uuid>{a76ecc21-1aa7-4e27-8970-094b9408a9ac}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.42256221</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm22</objectName>
  <x>81</x>
  <y>633</y>
  <width>30</width>
  <height>80</height>
  <uuid>{06ab0998-921a-4a5e-b24a-addb16b7d219}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.69496599</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm23</objectName>
  <x>111</x>
  <y>633</y>
  <width>30</width>
  <height>80</height>
  <uuid>{22e570a3-456b-4768-a268-37fb66e7b89f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.96641475</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm24</objectName>
  <x>141</x>
  <y>633</y>
  <width>30</width>
  <height>80</height>
  <uuid>{0251c5be-f7f8-43e5-918f-a21836ec1429}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.23511082</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm25</objectName>
  <x>21</x>
  <y>663</y>
  <width>30</width>
  <height>80</height>
  <uuid>{497ecbb2-410c-402c-adcc-dc4c937d940b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.50462146</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm26</objectName>
  <x>51</x>
  <y>663</y>
  <width>30</width>
  <height>80</height>
  <uuid>{cb33ab73-afa1-4768-b89b-c2309649d01e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.77317709</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm27</objectName>
  <x>81</x>
  <y>663</y>
  <width>30</width>
  <height>80</height>
  <uuid>{5009bffa-affc-4aea-b0f3-8c66919029bf}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.04077770</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm28</objectName>
  <x>111</x>
  <y>663</y>
  <width>30</width>
  <height>80</height>
  <uuid>{c4746785-07d6-4f57-a7b0-c6f6b2770af0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.30551328</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm29</objectName>
  <x>141</x>
  <y>663</y>
  <width>30</width>
  <height>80</height>
  <uuid>{88a9bb51-f3e0-44b9-822b-3c08c8c8144f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.57117577</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm30</objectName>
  <x>21</x>
  <y>693</y>
  <width>30</width>
  <height>80</height>
  <uuid>{9c5ad4e6-6c7a-4520-a6ef-89f384a09ce1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.83588326</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm31</objectName>
  <x>51</x>
  <y>693</y>
  <width>30</width>
  <height>80</height>
  <uuid>{0b76b89e-30b8-47b8-997b-ba1875f2222b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.09963573</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm32</objectName>
  <x>81</x>
  <y>693</y>
  <width>30</width>
  <height>80</height>
  <uuid>{e44f98e5-dfc5-49db-bbcb-1075b2509637}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.36243318</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm33</objectName>
  <x>111</x>
  <y>693</y>
  <width>30</width>
  <height>80</height>
  <uuid>{8cacb66b-73fd-4b54-8dd5-552d8590051e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.62222515</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm34</objectName>
  <x>141</x>
  <y>693</y>
  <width>30</width>
  <height>80</height>
  <uuid>{20fe3752-5b6f-47dd-aa99-86189421b9d1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.88308449</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm35</objectName>
  <x>21</x>
  <y>723</y>
  <width>30</width>
  <height>80</height>
  <uuid>{be8954a8-62e1-4605-afaf-b5e6f0776184}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.14298881</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm36</objectName>
  <x>51</x>
  <y>723</y>
  <width>30</width>
  <height>80</height>
  <uuid>{3cad98b9-3c31-4a96-8762-3d61c69b8028}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.40193812</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm37</objectName>
  <x>81</x>
  <y>723</y>
  <width>30</width>
  <height>80</height>
  <uuid>{e7806f7d-0de6-423d-912e-72e79ba5d2d1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.65776959</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm38</objectName>
  <x>111</x>
  <y>723</y>
  <width>30</width>
  <height>80</height>
  <uuid>{a2feff26-fd1d-41f3-8f6f-906b13b6a650}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.91478078</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBKnob">
  <objectName>harm39</objectName>
  <x>141</x>
  <y>723</y>
  <width>30</width>
  <height>80</height>
  <uuid>{a4e28441-1057-4c50-9baf-0de28fed2ff6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.17083695</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>0.01000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBScope">
  <objectName/>
  <x>5</x>
  <y>341</y>
  <width>350</width>
  <height>150</height>
  <uuid>{8b12513e-4fb1-4969-bea1-137b912671e4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <value>1.00000000</value>
  <type>lissajou</type>
  <zoomx>2.00000000</zoomx>
  <zoomy>10.00000000</zoomy>
  <dispx>1.00000000</dispx>
  <dispy>1.00000000</dispy>
  <mode>0.00000000</mode>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>circletime</objectName>
  <x>103</x>
  <y>4</y>
  <width>144</width>
  <height>28</height>
  <uuid>{943e3fb0-4279-494f-b3ab-e8214108319c}</uuid>
  <visible>true</visible>
  <midichan>1</midichan>
  <midicc>23</midicc>
  <minimum>1.00000000</minimum>
  <maximum>20.00000000</maximum>
  <value>9.77537128</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>hor42</objectName>
  <x>5</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{84012c96-0745-4719-b431-cd880d56e11a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h1</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>5</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{788badcc-9bdc-4866-b1fa-9f0f33e8a5c9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>1</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor44</objectName>
  <x>26</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{0e67b377-7021-4573-8db0-02315bd18b04}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h2</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>26</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{cc43ce1d-e96c-4a90-83da-f0fe65fee010}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>2</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor46</objectName>
  <x>47</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{8df758cd-82d1-4478-a22d-43ca8fbe4a83}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h3</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>47</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{0b55e7ed-a123-451e-b6c6-0c4803b06fc6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>3</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor48</objectName>
  <x>68</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{0bdcc792-486c-4015-ab6c-be12bada316e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h4</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>68</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{7a168e15-6317-4ae5-9c6d-2dc8fbbc82df}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>4</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor50</objectName>
  <x>89</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{621b3719-a6ea-45f3-84eb-c9a9b289bd46}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h5</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>89</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{4c4f1951-21fe-4c52-9eaa-af7f52bbd786}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>5</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor52</objectName>
  <x>110</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{0c2cbd17-3dae-439d-b3f9-2f31f83ebd18}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h6</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>110</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{cd928c6e-1ee6-4877-9c7b-976fb83712c9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>6</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor54</objectName>
  <x>131</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{749f49ed-5300-44af-a7b6-ecfe41908a6a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h7</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>131</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{815f6f45-3096-4a5f-91d1-3af6015ad9a0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>7</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor56</objectName>
  <x>152</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{f0aa8c9f-b141-4886-ba33-1335228cac49}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h8</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>152</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{79e0edbf-013a-47b0-bc03-81c1e0a33584}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>8</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor58</objectName>
  <x>173</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{fe8c4b40-0819-4f8d-8977-8a7a13520c77}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h9</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>173</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{b4b28d93-32d7-442f-81d5-f2400f0beefc}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>9</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor60</objectName>
  <x>194</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{a0737962-d87c-40a2-97d9-b92ca06ab48c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h10</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>194</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{08dcebcb-3d9d-46ed-8ceb-1edafb95154d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>10</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor62</objectName>
  <x>215</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{d5dd5020-5147-45b2-9437-f49879b36e09}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h11</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>215</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{14409877-7295-40de-9776-17a19f7c0ec1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>11</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor64</objectName>
  <x>236</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{3a199927-d2b4-440f-88ad-420017cec010}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h12</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>236</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{0d3d15fd-88c1-4b35-9a51-05d326d1b05e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>12</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor66</objectName>
  <x>257</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{d173147d-11f2-4fb2-a0be-d3887883a8ff}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h13</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>257</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{de0c3531-834e-4747-85c1-959e47465a01}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>13</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor68</objectName>
  <x>278</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{66e63ec2-12c4-43a9-b777-df021f4202e3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h14</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>278</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{2a4e15bf-45f2-46bd-8f72-d01c80a0797f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>14</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor70</objectName>
  <x>299</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{07a42e82-c36e-446e-8150-00bf61ea5660}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h15</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>299</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{fc5be5ee-0856-4c55-9be2-b455eb878391}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>15</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor72</objectName>
  <x>320</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{fa617d39-4eb4-41c7-9be9-a67ba61dc331}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h16</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>320</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{6aa48330-005c-440c-b64d-45980d251d0a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>16</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor74</objectName>
  <x>341</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{1a466fde-dfdc-440e-9b00-115dca552e81}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h17</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>341</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{2eb3846d-5b8d-43bc-b589-90ab4e9472ca}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>17</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor76</objectName>
  <x>362</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{87d28abc-9c50-42e2-8add-49024263262b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h18</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>362</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{96087db8-54a7-495f-b1f9-912cef0763d2}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>18</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor78</objectName>
  <x>383</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{f391771b-b60e-41d5-afef-eaae0a9b5950}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h19</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>383</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{8d01a270-e319-46d7-9520-caea310458e0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>19</label>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor80</objectName>
  <x>404</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{84ec5d7f-9e38-4524-8aca-d07f03298535}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h20</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>404</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{b9a963f9-cbee-4646-a4b6-19f6a64287ec}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>20</label>
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
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>6</x>
  <y>3</y>
  <width>80</width>
  <height>25</height>
  <uuid>{9029e25c-10dc-4fef-a6f3-9df45a35004e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Circle time</label>
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
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>41</y>
  <width>80</width>
  <height>25</height>
  <uuid>{8ea13628-8f66-4ead-ba08-f59a6c7804a5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Clients:</label>
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
 <bsbObject version="2" type="BSBDisplay">
  <objectName>clients</objectName>
  <x>102</x>
  <y>42</y>
  <width>80</width>
  <height>25</height>
  <uuid>{13656e53-0115-4068-af00-82a2597f12b1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>5.000</label>
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
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>button85</objectName>
  <x>218</x>
  <y>40</y>
  <width>100</width>
  <height>30</height>
  <uuid>{91e10230-8b4f-42ae-b925-3ae4470a0ff4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Start</text>
  <image>/</image>
  <eventLine>i "control" 0 60</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
