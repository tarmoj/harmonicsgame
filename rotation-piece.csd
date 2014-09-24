<CsoundSynthesizer>
<CsOptions>
-b1024 -B2048 
-+rtaudio=jack -odac:system:playback_ -+jack_client=rotation-piece 
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2; 4
0dbfs = 1

#define MAXAMP #0.5#
#define MINAMP # $MAXAMP*0.25 #

#define MINSPEED #1#
#define MAXSPEED #2#

#define MAXCLIENTS #20#

;CONSTANTS: -----------------------
giHandle init 0;OSCinit 9000 ; osc messages about level of harmonics

giSine ftgen 101, 0, 16384, 10, 1
giSine1 ftgen 102, 0, 16384, 10, 1, 0.1
giSine2 ftgen 103, 0, 16384, 10, 1, 0.1, 0.02
giSine3 ftgen 104, 0, 16384, 10, 1, 0.1, 0.04, 0.001
giSine4 ftgen 105, 0, 16384, 10, 1, 0.1, 0.06, 0.002,0.001
giSine5 ftgen 106, 0, 16384, 10, 1, 0.1, 0.08, 0.003,0.002, 0.001

giMixTable  ftgen 101, 0, 16384, 10, 1 ; same ase giSine for beginning
giLine ftgen 0, 0, 1024, 7, 0, 512, 1, 512, 0 ; back and forth pan for stereo mode

;

gkFade init 1

giBaseFreq=cpspch(5.07)
;giRotationSpeed[] fillarray 1, 1.25,  1.5, 1.75, 2, 2.1, 2.2, 2.3

gkCircleTime init 15
chnset 15,"circletime"

giHarmCount init $MAXCLIENTS;20
print giHarmCount
gkAmplitude[] init giHarmCount+1
gkAtack[] init giHarmCount+1
gkFreq[] genarray_i giBaseFreq, giBaseFreq*giHarmCount, giBaseFreq



; CHANNELS: ----------

chn_k "circletime", 3
chn_k "time",2
chn_k "fn",3
chn_k "level", 1
chnset giSine,"fn"
chnset 0.8, "level"

giharm = 1
channels:
	Schn sprintf "h%d",giharm	
	chn_k Schn,3
	loop_le giharm, 1, giHarmCount, channels

if (nchnls==4) then
	vbaplsinit 2, 4, -30, 30, 150, -150
elseif (nchnls==2) then
	vbaplsinit 2, 2, -45, 45
endif
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
gSClientIP = ""

;alwayson "osc"
pyinit
pyruni {{
ids = [] #  ;id-s (last parts of IP addresses of client
clientsCount = 0
}}

; TODO! vaata, et indeks poleks kunagi -1!!!
instr osc
	SClientIP = ""
	kID init 0
	khello OSClisten giHandle, "/harmonics/hello","si",gSClientIP,kID ; id - viimane osa IP aadressist. Antud arvuna, et ei peaks enam eraldi eraldama
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
		strset 1001, SClientIP
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
	
	if (kattack>0) then
		schedkwhen kattack, 0, 0, "atack", 0, 1, kharmonic ; only when kharmonic is not 0
	endif
endin


instr sendHarmonic
	
	iport = p4
	Shost =gSClientIP;strget 1001;p5
	prints Shost
	iharmonic = p6
	print iport,iharmonic
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
	ifast = 2.5
	ifastest = 2
	islowest = 20
	islidestart = p3*0.55
	gkCircleTime expseg istart, p3/8, istart, p3/16, ifast+1, p3/16, istart,
	p3/4, istart, p3/4,ifastest, p3/16,ifastest,p3/8,islowest, p3/16, islowest
	chnset gkCircleTime, "circletime"
	ktime timeinsts
	ktrig metro 1 ; take time every second
	if ktrig==1 then		
		chnset int(ktime),"time" 
	endif
	schedule "slide_start",islidestart,p3/4,4/3
	schedule "fade", p3+10,30,0 ; 10 sec after end of cotrol fade out int 30 seconds
	
	; changes in wave table
	imixtime = 3
	schedule "mixTable",p3*3/16,imixtime, giSine, giSine1
	schedule "mixTable",p3/4,imixtime, giSine1, giSine2
	schedule "mixTable",p3/2,imixtime, giSine2, giSine3
	schedule "mixTable",p3*0.75,imixtime, giSine3, giSine5
	schedule "mixTable",p3*0.825,imixtime, giSine5, giSine2
	schedule "mixTable",p3*0.9,imixtime, giSine2, giSine ; was giSine1
	

endin

;schedule "mixTable",0,0.1, 104
instr mixTable
	itable1 = p4
	itable2 = p5
	kgain line 0,p3,1
	tablemix giMixTable, 0, ftlen(itable1), itable1, 0, 1-kgain, itable2, 0, kgain
endin

; SOUND: -----------------------------------------

schedule "rotate",0,9600
instr rotate
	iharm = 1
looppoint:
    event_i "i", "note", 0, p3, iharm ; algus oli 0.05*iharm
    ;gkFreq[iharm-1] init giBaseFreq*iharm ; does init work?
    loop_le	iharm,1,giHarmCount,looppoint
    
    gkCircleTime chnget "circletime"
    gkLevel chnget "level"
    gkLevel port gkLevel, 0.05
    ; TODO: gkLevel chnget "level", gkFade
endin


;event_i "i", "atack", 0, 0.5, 16, 0.2
instr atack ; line up and down during p3, if p3 short, like atack
	index = p4-1 ; p4 - harmonic's number
	printf_i "Atack %d\n", 1, p4
	; oli:
	;atack linseg 0,0.05,3,p3-0.05,0 ; lisa see instrumendsi "note"
	;gaAtack[index] = gaAtack[index] + atack
	; nüüd:
	kline linseg  0,0.05,2.5,p3-0.05,0
	gkAtack[index] = kline
	;gaAtack[index] linseg 0,0.05,3,p3-0.05,0
	
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

; schedule "fade",0,20,0
instr fade ; p4: 0 - out 1 - in
	
	istart = (p4==$OUT) ? 1 : 0.0001
	iend = (p4==$OUT) ? 0.0001 : 1
	gkFade init istart
	gkFade expon istart,p3,iend
	;gkFade port iend,p3/2
	
endin

instr note
	iharmonic = p4
	; 4 kanalit- kasuta vbap4 ?
	iamp = $MAXAMP*1/iharmonic ;($MAXAMP - ($MAXAMP-$MINAMP)/giHarmCount*(iharmonic-1))/sqrt(giHarmCount)*0.5
	iRotationSpeed = $MINSPEED + ($MAXSPEED-$MINSPEED)/giHarmCount*(iharmonic-1)
	;print giRotationSpeed[iharmonic-1]*giCircleTime
	print iamp, iRotationSpeed
	kphase phasor 1/gkCircleTime*iRotationSpeed;giRotationSpeed[iharmonic]
	if (nchnls==4) then
		kdegree = kphase * 360
	elseif (nchnls==2) then
		kdegree tablei kphase, giLine, 1
		kdegree = -45+kdegree*90  
	endif
	;SchannelName sprintf "harm%d",iharmonic-1
	SharmName sprintf "h%d",iharmonic
	;WAS for OSC variant (for output): chnset gkAmplitude[iharmonic-1], SharmName ; ? *(k(gaAtack[iharmonic-1])+1)
	;ifn =  (iharmonic == 1) ? giSine2 : giSine; -1
	aenv linen 1,0.2,p3,0.2
	
	;kfn chnget "fn"
	kamp = chnget:k(SharmName) *iamp*(gkAtack[iharmonic-1]+1)*gkFade*gkLevel
	kamp port kamp, 0.05
	amp interp kamp
	;asig oscilikt amp*aenv,gkFreq[iharmonic-1], kfn; gkFn;ifn
	asig poscil amp*aenv,gkFreq[iharmonic-1], giMixTable
	;Milleks liita: gaAtack[iharmonic-1] = 0
	if (nchnls==4) then
		a1, a2, a3, a4 vbap4 asig, kdegree 
	elseif (nchnls==2) then
		;a1,a2 pan2 asig, kpan 
		a1,a2 vbap asig, kdegree 
	endif
	if (nchnls==2) then
		outs a1,a2
	elseif (nchnls==4) then
		outq a1,a2,a4,a3 ; check, if back speakers right!
	endif
	
endin


</CsInstruments>
<CsScore>
;i "sendHarmonic" 0 0.1 9114 "192.168.11.14" 1

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
createMeters(50)


<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>1055</width>
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
  <value>0.75243539</value>
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
  <value>0.92446262</value>
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
  <value>0.26851702</value>
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
  <value>0.61257142</value>
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
  <value>0.78459865</value>
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
  <value>0.95662588</value>
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
  <value>0.30068028</value>
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
  <value>0.64473468</value>
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
  <value>0.81676191</value>
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
  <value>0.98878914</value>
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
  <value>0.52214897</value>
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
  <value>0.87834895</value>
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
  <value>0.69496602</value>
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
  <value>0.50462145</value>
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
  <value>0.30551329</value>
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
  <value>0.57117575</value>
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
  <value>0.36243317</value>
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
  <value>0.62222517</value>
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
  <value>0.88308448</value>
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
  <value>0.14298882</value>
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
  <value>0.40193811</value>
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
  <value>0.65776956</value>
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
  <value>0.91478080</value>
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
  <value>0.17083696</value>
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
  <value>-255.00000000</value>
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
  <value>20.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
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
  <x>5</x>
  <y>70</y>
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
  <x>100</x>
  <y>71</y>
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
  <x>216</x>
  <y>69</y>
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
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>7</x>
  <y>37</y>
  <width>80</width>
  <height>25</height>
  <uuid>{4bd987b1-4448-4562-93bf-c362b96f2c5c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Level:</label>
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
 <bsbObject version="2" type="BSBHSlider">
  <objectName>level</objectName>
  <x>104</x>
  <y>38</y>
  <width>144</width>
  <height>21</height>
  <uuid>{a73a01ce-f4c3-494c-9277-56500a25f7db}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.66666669</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>hor48</objectName>
  <x>5</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{076c1109-adb7-4e9a-a1b8-dc9b07560fab}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h1</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.55500000</yValue>
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
  <uuid>{62eab194-b059-4c60-8da1-91c91e2a721f}</uuid>
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
  <objectName>hor50</objectName>
  <x>26</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{44caa0d6-049d-4401-b44a-d6598fe3752f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h2</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.01500000</yValue>
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
  <uuid>{ab5a4be5-0491-4dcf-a0d9-d7130527bb6a}</uuid>
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
  <objectName>hor52</objectName>
  <x>47</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{174ba543-7500-458e-8e64-3636e0bc595b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h3</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.01500000</yValue>
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
  <uuid>{8fc4f16d-b5f2-4311-9225-ae3a174a04f7}</uuid>
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
  <objectName>hor54</objectName>
  <x>68</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{96de53b0-a00f-45ed-8c8d-ec841dbaba26}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h4</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.73500000</yValue>
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
  <uuid>{b6f4aed5-898a-435b-af46-b4c369947e5d}</uuid>
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
  <objectName>hor56</objectName>
  <x>89</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{46fac5bf-d175-4174-888d-5d2f726c1fd9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h5</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.03500000</yValue>
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
  <uuid>{e98e87ac-213f-477a-a6a4-90e602f0dfa8}</uuid>
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
  <objectName>hor58</objectName>
  <x>110</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{5a4de599-78de-42e3-a90a-285bc7eba962}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h6</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.03500000</yValue>
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
  <uuid>{8782178c-fe93-495d-a643-8f0d8592690e}</uuid>
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
  <objectName>hor60</objectName>
  <x>131</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{b276124a-eadb-4a7e-9938-f5583909f9b1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h7</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.03500000</yValue>
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
  <uuid>{76577cf2-5ad3-489b-8008-5896ab58b929}</uuid>
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
  <objectName>hor62</objectName>
  <x>152</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{dc09041c-60e7-4ca8-b5ff-72e62d47b28c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h8</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.03500000</yValue>
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
  <uuid>{29adc850-01b5-478b-a674-b20a416e92e6}</uuid>
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
  <objectName>hor64</objectName>
  <x>173</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{6e137356-307f-48ae-a7ad-755bd1261d51}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h9</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.03500000</yValue>
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
  <uuid>{9561caf6-f176-4478-b072-2e6db663fb01}</uuid>
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
  <objectName>hor66</objectName>
  <x>194</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{22c652e1-a032-42be-911d-5e022df79fb7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h10</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.57500000</yValue>
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
  <uuid>{2eb0f948-aca8-4203-b832-42159f2fece0}</uuid>
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
  <objectName>hor68</objectName>
  <x>215</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{8052d6a5-cdec-49ef-a233-cd034a812a49}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h11</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.05000000</yValue>
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
  <uuid>{4ebffa53-4607-4a49-a087-588ea4c60c91}</uuid>
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
  <objectName>hor70</objectName>
  <x>236</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{cfe61de4-cf75-494d-bb61-3bb14c65cfab}</uuid>
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
  <uuid>{d54e0209-bb99-45d2-9a9e-027803c1d7c8}</uuid>
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
  <objectName>hor72</objectName>
  <x>257</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{3cca4fbf-d0e5-46aa-8f60-d5808981b7db}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h13</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.05500000</yValue>
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
  <uuid>{ba58533e-42b7-469d-b778-5aeb7746746a}</uuid>
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
  <objectName>hor74</objectName>
  <x>278</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{7b24663f-afa5-4287-b8c1-6edadb3f3f11}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h14</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.56000000</yValue>
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
  <uuid>{53f9e60c-484f-495b-85b8-d8bb2bb41017}</uuid>
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
  <objectName>hor76</objectName>
  <x>299</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{8dccc703-3ca9-4edf-b2f4-a15b432756df}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h15</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.06000000</yValue>
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
  <uuid>{fb708c64-7e4e-4bac-9b94-237808c089b1}</uuid>
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
  <objectName>hor78</objectName>
  <x>320</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{77d0c65c-53db-4203-a28d-79b8a32cd34c}</uuid>
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
  <uuid>{9f49814b-eeb8-47cd-96da-b73b041758c7}</uuid>
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
  <objectName>hor80</objectName>
  <x>341</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{7b1735d4-ecb0-4cc2-af90-d5039177d134}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h17</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.06000000</yValue>
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
  <uuid>{7cc1a2f1-a092-4ef3-85c4-99fea8309b73}</uuid>
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
  <objectName>hor82</objectName>
  <x>362</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{e5ffae56-995a-4450-859f-cb0ffe6e7acb}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h18</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.04000000</yValue>
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
  <uuid>{3558924a-97cd-40ff-993b-604873b8dbe0}</uuid>
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
  <objectName>hor84</objectName>
  <x>383</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{f1d18296-2651-42af-83c9-57b797e2fab2}</uuid>
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
  <uuid>{b3731631-9500-499b-8a34-1e34ce47d2ab}</uuid>
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
  <objectName>hor86</objectName>
  <x>404</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{1527dd47-0925-4a78-8ac4-3d8035745625}</uuid>
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
  <uuid>{3aab410b-dfdf-4cf8-9b0d-5b871a1be5e9}</uuid>
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
 <bsbObject version="2" type="BSBController">
  <objectName>hor88</objectName>
  <x>425</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{f84857d1-095a-4e60-a2ec-c63c678980fc}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h21</objectName2>
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
  <x>425</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{0ce3fb41-a2b0-413c-a24b-f417babd6856}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>21</label>
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
  <objectName>hor90</objectName>
  <x>446</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{d3ac2495-6c1b-4019-9091-c35efea9e541}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h22</objectName2>
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
  <x>446</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{03ba1ed1-00dc-4d79-8a6e-c2b9a04d10f4}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>22</label>
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
  <objectName>hor92</objectName>
  <x>467</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{8ff7795a-143a-4cbc-8f9e-ae117018d4cd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h23</objectName2>
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
  <x>467</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{98e17630-62e0-4fe5-ada4-63a32d9ad5c5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>23</label>
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
  <objectName>hor94</objectName>
  <x>488</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{7ab805ba-11d7-4ced-a4e4-2ec12ab11d58}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h24</objectName2>
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
  <x>488</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{7e04d737-8931-402d-ade3-f8c8e4454b0e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>24</label>
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
  <objectName>hor96</objectName>
  <x>509</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{5c58606d-b525-4eed-92df-76169ccaa7ae}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h25</objectName2>
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
  <x>509</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{b101895a-8b36-40b6-ae11-8abc3c269b11}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>25</label>
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
  <objectName>hor98</objectName>
  <x>530</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{3f617ee5-c981-4bcb-8c5a-467791df31e7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h26</objectName2>
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
  <x>530</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{5913e30a-660e-4537-9f68-5711626b7385}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>26</label>
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
  <objectName>hor100</objectName>
  <x>551</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{5b173898-e3eb-441f-8cbe-fdebd06664ff}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h27</objectName2>
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
  <x>551</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{3b4d901e-651c-43c8-9a16-e598f0d50724}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>27</label>
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
  <objectName>hor102</objectName>
  <x>572</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{5a192b9b-db5a-41b2-8659-6ee0abbd0b80}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h28</objectName2>
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
  <x>572</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{dae2ed2a-10f3-4eb6-aa11-306a132286a6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>28</label>
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
  <objectName>hor104</objectName>
  <x>593</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{de3675c1-2a47-4d04-8443-790fbb225262}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h29</objectName2>
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
  <x>593</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{a0859e04-b486-4029-bff0-7d6590fd727f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>29</label>
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
  <objectName>hor106</objectName>
  <x>614</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{ba847d7d-d5ba-4b01-a786-728d5d19c6c9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h30</objectName2>
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
  <x>614</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{a0fe3ce5-9cb2-4756-bd2f-ac6765cafc43}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>30</label>
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
  <objectName>hor108</objectName>
  <x>635</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{c4147c52-3ead-4693-a6c7-ff7edc17d829}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h31</objectName2>
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
  <x>635</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{cce7f786-1bc8-4b6e-ab59-d88df9c20c78}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>31</label>
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
  <objectName>hor110</objectName>
  <x>656</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{25c13733-2703-4458-969c-703704d1e461}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h32</objectName2>
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
  <x>656</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{1865c266-6d49-4b19-a54a-144a6355b214}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>32</label>
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
  <objectName>hor112</objectName>
  <x>677</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{392775a9-a8a1-45ee-b068-db7847953788}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h33</objectName2>
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
  <x>677</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{ed33c212-ffea-4cfb-8b7f-6f7e8ead2dac}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>33</label>
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
  <objectName>hor114</objectName>
  <x>698</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{84870d74-4d1c-4c9d-982f-424848efa2a8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h34</objectName2>
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
  <x>698</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{57d7f0fb-ebbc-4d39-8dd3-d456a879d950}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>34</label>
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
  <objectName>hor116</objectName>
  <x>719</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{783029e9-ce12-4a10-bba9-2200ac52edf3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h35</objectName2>
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
  <x>719</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{b8a9b693-5d64-489e-9c0b-72f1320bb7ee}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>35</label>
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
  <objectName>hor118</objectName>
  <x>740</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{e3191bf3-9809-4756-a863-83cf301284d1}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h36</objectName2>
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
  <x>740</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{5bc5e580-a9ac-462b-bd72-aa92671c40f9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>36</label>
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
  <objectName>hor120</objectName>
  <x>761</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{40311a6a-8156-4bc3-8d5b-8f0360e028fb}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h37</objectName2>
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
  <x>761</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{1f2636dc-d881-45d7-8ca2-751fbda6b275}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>37</label>
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
  <objectName>hor122</objectName>
  <x>782</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{0b1b1b0a-1224-48a9-a896-55f6d0b5f01d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h38</objectName2>
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
  <x>782</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{efe2f1c9-19ff-4f52-93f7-f2856d3b9188}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>38</label>
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
  <objectName>hor124</objectName>
  <x>803</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{8e32f6f7-8035-4837-b42a-1a764f59474d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h39</objectName2>
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
  <x>803</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{b87e4b32-c31c-49a7-b2f5-942a62125a97}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>39</label>
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
  <objectName>hor126</objectName>
  <x>824</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{c63854b1-ff5b-489a-bd88-d8df841461ab}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h40</objectName2>
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
  <x>824</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{25c04a91-e950-4379-ba12-a479514708fa}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>40</label>
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
  <objectName>hor128</objectName>
  <x>845</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{f03fcc24-016c-4615-af48-e067ef2ea922}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h41</objectName2>
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
  <x>845</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{b3af9d61-b44b-480c-a25e-b1b87895c5bb}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>41</label>
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
  <objectName>hor130</objectName>
  <x>866</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{da7331af-0a9e-420e-8e82-1621628583cf}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h42</objectName2>
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
  <x>866</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{6d084470-dd8c-4931-adcc-aadbc7a16fe8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>42</label>
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
  <objectName>hor132</objectName>
  <x>887</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{248c6150-bc94-432d-81a3-3d04e3f18414}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h43</objectName2>
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
  <x>887</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{408b9436-4bbc-4e35-ba30-5d2df7bef192}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>43</label>
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
  <objectName>hor134</objectName>
  <x>908</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{f011b017-117b-4186-ae9e-03442e20dfa3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h44</objectName2>
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
  <x>908</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{c844b726-2b5b-4c68-b94c-7eb1ece28783}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>44</label>
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
  <objectName>hor136</objectName>
  <x>929</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{d19a4bc1-7f4e-4379-8cac-77ba1340cf50}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h45</objectName2>
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
  <x>929</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{d7f3db70-d86f-4056-b561-632e51835b53}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>45</label>
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
  <objectName>hor138</objectName>
  <x>950</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{dda16517-de15-4d40-942d-9052bbf249af}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h46</objectName2>
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
  <x>950</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{39f92ef7-7f7f-4e59-972c-9cc702bfef7e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>46</label>
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
  <objectName>hor140</objectName>
  <x>971</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{803852e8-92c3-4223-87b3-8f9afe815519}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h47</objectName2>
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
  <x>971</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{f0d788e3-8f2c-4a81-b76f-0bf52b830338}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>47</label>
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
  <objectName>hor142</objectName>
  <x>992</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{768154a7-b93c-4c9b-bcb8-899303ff3d77}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h48</objectName2>
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
  <x>992</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{a022a16c-0f32-4108-a305-7ee2ec485dc5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>48</label>
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
  <objectName>hor144</objectName>
  <x>1013</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{01fea4e1-c95d-4536-8b7a-c26648521b03}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h49</objectName2>
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
  <x>1013</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{c335d525-6664-4167-bfa1-c3dfb07d53db}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>49</label>
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
  <objectName>hor146</objectName>
  <x>1034</x>
  <y>125</y>
  <width>21</width>
  <height>200</height>
  <uuid>{61ce1466-8bd7-46f7-b2f8-4023375151d2}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>h50</objectName2>
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
  <x>1034</x>
  <y>105</y>
  <width>21</width>
  <height>25</height>
  <uuid>{e3691b0c-1c75-4b81-9813-6fcb869cf8a7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>50</label>
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
</bsbPanel>
<bsbPresets>
<preset name="all_null" number="0" >
<value id="{c9ca5d94-381d-439a-8698-cc1319c611f2}" mode="1" >0.75243539</value>
<value id="{f86fcfa7-3c5a-4b98-af1e-4cf62881c0da}" mode="1" >0.92446262</value>
<value id="{fe1d441f-5a39-4771-8def-d3b6aa899b04}" mode="1" >0.09648980</value>
<value id="{1adf40cc-5803-4e67-be4c-d83dbe9d2e09}" mode="1" >0.26851702</value>
<value id="{245d591c-c8ad-4624-ba0d-4ec9e982ce48}" mode="1" >0.44054422</value>
<value id="{dd9601ee-3642-4404-9a6d-2b7986dd2ae9}" mode="1" >0.61257142</value>
<value id="{6e1e06c0-abf6-4f10-934c-b3011c7e58cc}" mode="1" >0.78459865</value>
<value id="{7c77da81-419d-4a43-a4b9-47c99d26a4b5}" mode="1" >0.95662588</value>
<value id="{89408ffa-8ac2-41b0-9efe-89a24d5f745d}" mode="1" >0.12865306</value>
<value id="{0007c654-7e71-438f-9bbe-81ed1fce0c33}" mode="1" >0.30068028</value>
<value id="{12bf206c-f0fb-4c9a-8688-5ba988f74857}" mode="1" >0.47270748</value>
<value id="{040e3ae0-d5de-4023-88b4-08fb9a340b3c}" mode="1" >0.64473468</value>
<value id="{9356d378-ee24-4c08-9d4e-eccbfecec343}" mode="1" >0.81676191</value>
<value id="{5010689b-cd4f-4ed1-a5ac-3ac03b02b3dc}" mode="1" >0.98878914</value>
<value id="{f76b9a2f-1d49-4b6d-971b-69711e016885}" mode="1" >0.16081633</value>
<value id="{04a57aa7-98be-473b-9cb2-fa5bdae1d351}" mode="1" >0.33284354</value>
<value id="{f3013ccf-54fa-40fd-b88a-afddfd547b9f}" mode="1" >0.16403896</value>
<value id="{01e50657-7a99-4fc5-8e60-0f22a71ab673}" mode="1" >0.52214897</value>
<value id="{b7f399e2-4adf-4e58-9ed8-17749b6149fc}" mode="1" >0.87834895</value>
<value id="{2495d514-915a-4699-b38c-f37de0112623}" mode="1" >0.23044796</value>
<value id="{f0448970-6203-44cb-b969-20aa59c55eb5}" mode="1" >0.14920342</value>
<value id="{a76ecc21-1aa7-4e27-8970-094b9408a9ac}" mode="1" >0.42256221</value>
<value id="{06ab0998-921a-4a5e-b24a-addb16b7d219}" mode="1" >0.69496602</value>
<value id="{22e570a3-456b-4768-a268-37fb66e7b89f}" mode="1" >0.96641475</value>
<value id="{0251c5be-f7f8-43e5-918f-a21836ec1429}" mode="1" >0.23511082</value>
<value id="{497ecbb2-410c-402c-adcc-dc4c937d940b}" mode="1" >0.50462145</value>
<value id="{cb33ab73-afa1-4768-b89b-c2309649d01e}" mode="1" >0.77317709</value>
<value id="{5009bffa-affc-4aea-b0f3-8c66919029bf}" mode="1" >0.04077770</value>
<value id="{c4746785-07d6-4f57-a7b0-c6f6b2770af0}" mode="1" >0.30551329</value>
<value id="{88a9bb51-f3e0-44b9-822b-3c08c8c8144f}" mode="1" >0.57117575</value>
<value id="{9c5ad4e6-6c7a-4520-a6ef-89f384a09ce1}" mode="1" >0.83588326</value>
<value id="{0b76b89e-30b8-47b8-997b-ba1875f2222b}" mode="1" >0.09963573</value>
<value id="{e44f98e5-dfc5-49db-bbcb-1075b2509637}" mode="1" >0.36243317</value>
<value id="{8cacb66b-73fd-4b54-8dd5-552d8590051e}" mode="1" >0.62222517</value>
<value id="{20fe3752-5b6f-47dd-aa99-86189421b9d1}" mode="1" >0.88308448</value>
<value id="{be8954a8-62e1-4605-afaf-b5e6f0776184}" mode="1" >0.14298882</value>
<value id="{3cad98b9-3c31-4a96-8762-3d61c69b8028}" mode="1" >0.40193811</value>
<value id="{e7806f7d-0de6-423d-912e-72e79ba5d2d1}" mode="1" >0.65776956</value>
<value id="{a2feff26-fd1d-41f3-8f6f-906b13b6a650}" mode="1" >0.91478080</value>
<value id="{a4e28441-1057-4c50-9baf-0de28fed2ff6}" mode="1" >0.17083696</value>
<value id="{8b12513e-4fb1-4969-bea1-137b912671e4}" mode="1" >-255.00000000</value>
<value id="{943e3fb0-4279-494f-b3ab-e8214108319c}" mode="1" >20.00000000</value>
<value id="{84012c96-0745-4719-b431-cd880d56e11a}" mode="1" >0.00000000</value>
<value id="{84012c96-0745-4719-b431-cd880d56e11a}" mode="2" >0.00000000</value>
<value id="{0e67b377-7021-4573-8db0-02315bd18b04}" mode="1" >0.00000000</value>
<value id="{0e67b377-7021-4573-8db0-02315bd18b04}" mode="2" >0.00000000</value>
<value id="{8df758cd-82d1-4478-a22d-43ca8fbe4a83}" mode="1" >0.00000000</value>
<value id="{8df758cd-82d1-4478-a22d-43ca8fbe4a83}" mode="2" >0.00000000</value>
<value id="{0bdcc792-486c-4015-ab6c-be12bada316e}" mode="1" >0.00000000</value>
<value id="{0bdcc792-486c-4015-ab6c-be12bada316e}" mode="2" >0.00000000</value>
<value id="{621b3719-a6ea-45f3-84eb-c9a9b289bd46}" mode="1" >0.00000000</value>
<value id="{621b3719-a6ea-45f3-84eb-c9a9b289bd46}" mode="2" >0.00000000</value>
<value id="{0c2cbd17-3dae-439d-b3f9-2f31f83ebd18}" mode="1" >0.00000000</value>
<value id="{0c2cbd17-3dae-439d-b3f9-2f31f83ebd18}" mode="2" >0.00000000</value>
<value id="{749f49ed-5300-44af-a7b6-ecfe41908a6a}" mode="1" >0.00000000</value>
<value id="{749f49ed-5300-44af-a7b6-ecfe41908a6a}" mode="2" >0.00000000</value>
<value id="{f0aa8c9f-b141-4886-ba33-1335228cac49}" mode="1" >0.00000000</value>
<value id="{f0aa8c9f-b141-4886-ba33-1335228cac49}" mode="2" >0.00000000</value>
<value id="{fe8c4b40-0819-4f8d-8977-8a7a13520c77}" mode="1" >0.00000000</value>
<value id="{fe8c4b40-0819-4f8d-8977-8a7a13520c77}" mode="2" >0.00000000</value>
<value id="{a0737962-d87c-40a2-97d9-b92ca06ab48c}" mode="1" >0.00000000</value>
<value id="{a0737962-d87c-40a2-97d9-b92ca06ab48c}" mode="2" >0.00000000</value>
<value id="{d5dd5020-5147-45b2-9437-f49879b36e09}" mode="1" >0.00000000</value>
<value id="{d5dd5020-5147-45b2-9437-f49879b36e09}" mode="2" >0.00000000</value>
<value id="{3a199927-d2b4-440f-88ad-420017cec010}" mode="1" >0.00000000</value>
<value id="{3a199927-d2b4-440f-88ad-420017cec010}" mode="2" >0.00000000</value>
<value id="{d173147d-11f2-4fb2-a0be-d3887883a8ff}" mode="1" >0.00000000</value>
<value id="{d173147d-11f2-4fb2-a0be-d3887883a8ff}" mode="2" >0.00000000</value>
<value id="{66e63ec2-12c4-43a9-b777-df021f4202e3}" mode="1" >0.00000000</value>
<value id="{66e63ec2-12c4-43a9-b777-df021f4202e3}" mode="2" >0.00000000</value>
<value id="{07a42e82-c36e-446e-8150-00bf61ea5660}" mode="1" >0.00000000</value>
<value id="{07a42e82-c36e-446e-8150-00bf61ea5660}" mode="2" >0.00000000</value>
<value id="{fa617d39-4eb4-41c7-9be9-a67ba61dc331}" mode="1" >0.00000000</value>
<value id="{fa617d39-4eb4-41c7-9be9-a67ba61dc331}" mode="2" >0.00000000</value>
<value id="{1a466fde-dfdc-440e-9b00-115dca552e81}" mode="1" >0.00000000</value>
<value id="{1a466fde-dfdc-440e-9b00-115dca552e81}" mode="2" >0.00000000</value>
<value id="{87d28abc-9c50-42e2-8add-49024263262b}" mode="1" >0.00000000</value>
<value id="{87d28abc-9c50-42e2-8add-49024263262b}" mode="2" >0.00000000</value>
<value id="{f391771b-b60e-41d5-afef-eaae0a9b5950}" mode="1" >0.00000000</value>
<value id="{f391771b-b60e-41d5-afef-eaae0a9b5950}" mode="2" >0.00000000</value>
<value id="{84ec5d7f-9e38-4524-8aca-d07f03298535}" mode="1" >0.00000000</value>
<value id="{84ec5d7f-9e38-4524-8aca-d07f03298535}" mode="2" >0.00000000</value>
<value id="{13656e53-0115-4068-af00-82a2597f12b1}" mode="1" >5.00000000</value>
<value id="{13656e53-0115-4068-af00-82a2597f12b1}" mode="4" >5.000</value>
<value id="{91e10230-8b4f-42ae-b925-3ae4470a0ff4}" mode="4" >0</value>
<value id="{a73a01ce-f4c3-494c-9277-56500a25f7db}" mode="1" >0.66666669</value>
</preset>
</bsbPresets>
