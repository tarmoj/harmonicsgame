<CsoundSynthesizer>
<CsOptions>
-odac -d
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

;;channels
chn_k "envelope",3

gaAttack init 0

alwayson "Kontroll"
instr Kontroll
	kControl chnget "envelope"
	if (trigger(kControl, 0.9, 1)==1) then
		printf "Lülita välja %f\n", timeinstk(), kControl
		turnoff2 "Siinus", 8, 1 ; lülita välja lõputud siinused
	endif
endin

instr Nupp
	if (chnget:i("envelope")==1 && active:i("Siinus")>0)then ; pikk heli peal, siis tee pumps
		schedule "Pumps", 0, 0.5
	else 
		schedule "Siinus", 0, 1
	endif
	
endin

instr Pumps
	if (active:i("Pumps")>1) then
		prints "Juba mängib!"
		turnoff
	endif
	prints "PUMPS\n"
	gaAttack linseg  0,0.05,1.5,p3-0.05,0
	
endin


instr Siinus
	iAmp = 0.1
	iFactor chnget "envelope"
	iDuration = 0.2 + iFactor * 4
	p3 = iDuration
	
	iAttack = iFactor * iDuration/2  + 0.005
	iDecay = iDuration -  iAttack
	
	p3 = iDuration
	
	if (iFactor==1) then
		p3 = -1
		iAttack = 4
		iDecay = 8
	endif
	
	print iAttack, iDecay, p3
	
	if (iFactor<0.5) then
		aEnvelope expseg 0.0001, iAttack, 1, iDecay, 0.0001
	elseif (iFactor>=0.5 && iFactor < 0.99) then
		aEnvelope adsr iAttack, 0, 1, iDecay ;linen 1, iAttack, p3, iDecay
	else 
		aEnvelope linenr 1, 2, 2, 0.001
	endif   
	aEnvelope *= 1 + gaAttack
	aSignal poscil iAmp*aEnvelope, int(random:i(1, 20))*100
	outs aSignal, aSignal
	
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
 <width>225</width>
 <height>359</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject version="2" type="BSBVSlider">
  <objectName>envelope</objectName>
  <x>51</x>
  <y>50</y>
  <width>20</width>
  <height>100</height>
  <uuid>{eb37be13-3184-47fb-b54c-8f67b82ee3e3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>31</x>
  <y>170</y>
  <width>80</width>
  <height>25</height>
  <uuid>{fa6171e2-5646-456e-b698-4c81f188dbb9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Tilk</label>
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
  <x>26</x>
  <y>20</y>
  <width>80</width>
  <height>25</height>
  <uuid>{d997ba7b-4382-4049-b9e8-144c216b8da9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Vikerkaar</label>
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
 <bsbObject version="2" type="BSBButton">
  <objectName>button3</objectName>
  <x>125</x>
  <y>329</y>
  <width>100</width>
  <height>30</height>
  <uuid>{07dcd799-0fd3-4bd4-87f1-21830e2336ed}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Mängi
</text>
  <image>/</image>
  <eventLine>i "Nupp" 0 1</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
