10 'COPYRIGHT SCOTT ADAMS. 1978
20 CLEAR5400:DEFINTA-Z:D=-1
30 IFD=-1IFMEM<>4526PRINT"BAD LOAD":END
40 X=Y=Z:K=R=V:N=LL=F:TP$=K$:W=IP=P:Z$="I'VE TOO MUCH TOO CARRY. TRY -TAKE INVENTORY-":GOSUB1240:GOTO100
50 CLS:PRINT"     ***   WELCOME TO ADVENTURE LAND. (#4.6) ***":PRINT:PRINT" UNLESS TOLD DIFFERENTLY YOU MUST FIND *TREASURES* AND-RETURN-THEM-TO-THEIR-PROPER--PLACE!"
60 PRINT:PRINT"I'M YOUR PUPPET. GIVE ME ENGLISH COMMANDS THAT"
70 PRINT"CONSIST OF A NOUN AND VERB. SOME EXAMPLES...":PRINT:PRINT"TO FIND OUT WHAT YOU'RE CARRYING YOU MIGHT SAY: TAKE INVENTORY
TO GO INTO A HOLE YOU MIGHT SAY: GO HOLE
TO SAVE CURRENT GAME: SAVE GAME"
80 PRINT:PRINT"YOU WILL AT TIMES NEED SPECIAL ITEMS TO DO THINGS, BUT I'M SURE YOU'LL BE A GOOD ADVENTURER AND FIGURE THESE THINGS OUT."
90 PRINT:INPUT"     HAPPY ADVENTURING... HIT ENTER TO START";K$:CLS:RETURN
100 R=AR:LX=LT:DF=0:SF=0:INPUT"USE OLD 'SAVED' GAME";K$:IFLEFT$(K$,1)<>"Y"THEN130
110 IFD<>-1THENCLOSE:OPEN"I",D,SV$ELSEINPUT"READY SAVED TAPE";K$:PRINTINT(IL*5/60)+1;"MINUTES"
120 INPUT#D,SF,LX,DF,R:FORX=0TOIL:INPUT#D,IA(X):NEXT:IFD<>-1CLOSE
130 GOSUB50:GOSUB240:GOTO160
140 INPUT"TELL ME WHAT TO DO";TP$:PRINT:GOSUB170:IFFPRINT"YOU USE WORD(S) I DON'T KNOW":GOTO140
150 GOSUB360:IFIA(9)=-1THENLX=LX-1:IFLX<0THENPRINT"LIGHT HAS RUN OUT":IA(9)=0ELSEIFLX<25PRINT"LIGHT RUNS OUT IN";LX;"TURNS!"
160 NV(0)=0:GOSUB360:GOTO140
170 K=0:NT$(0)="":NT$(1)=""
180 FORX=1TOLEN(TP$):K$=MID$(TP$,X,1):IFK$=" "THENK=1ELSENT$(K)=LEFT$(NT$(K)+K$,LN)
190 NEXTX:FORX=0TO1:NV(X)=0:IFNT$(X)=""THEN230ELSEFORY=0TONL:K$=NV$(Y,X):IFLEFT$(K$,1)="*"THENK$=MID$(K$,2)
200 IFX=1IFY<7THENK$=LEFT$(K$,LN)
210 IFNT$(X)=K$THENNV(X)=YELSENEXTY:GOTO230
220 IFLEFT$(NV$(NV(X),X),1)="*"THENNV(X)=NV(X)-1:GOTO220
230 NEXTX:F=NV(0)<1ORLEN(NT$(1))>0ANDNV(1)<1:RETURN
240 IFDFIFIA(9)<>-1ANDIA(9)<>RPRINT"I CAN'T SEE: ITS TOO DARK.":RETURN
250 K=-1:IFLEFT$(RS$(R),1)="*"THENPRINTMID$(RS$(R),2);ELSEPRINT"I'M IN A ";RS$(R);
260 FORZ=0TOIL:IFKIFIA(Z)=RPRINT". VISIBLE ITEMS HERE: ":K=0 
270 GOTO300
280 TP$=IA$(Z):IFRIGHT$(TP$,1)="/"FORW=LEN(TP$)-1TO1STEP-1:IFMID$(TP$,W,1)="/"THENTP$=LEFT$(TP$,W-1)ELSENEXTW
290 RETURN
300 IFIA(Z)<>RTHEN320ELSEGOSUB280:IFPOS(0)+LEN(TP$)+3>63THENPRINT
310 PRINTTP$;".  ";
320 NEXT:PRINT
330 K=-1:FORZ=0TO5:IFKIFRM(R,Z)<>0PRINT"OBVIOUS EXITS: ";:K=0
340 IFRM(R,Z)<>0PRINTNV$(Z+1,1);" ";
350 NEXT:PRINT:PRINT:RETURN
360 F2=-1:F=-1:F3=0:IFNV(0)=1ANDNV(1)<7THEN610ELSEFORX=0TOCL:V=CA(X,0)/150:IFNV(0)=0IFV<>0RETURN
370 IFNV(0)<>VTHENNEXTX:GOTO990ELSEN=CA(X,0)-V*150
380 IFNV(0)=0THENF=0:IFRND(100)<=NTHEN400ELSENEXTX:GOTO990
390 IFN<>NV(1)ANDN<>0THENNEXTX:GOTO990
400 F2=-1:F=0:F3=-1:FORY=1TO5:W=CA(X,Y):LL=W/20:K=W-LL*20:F1=-1:ONK+1GOTO550,430,450,470,490,500,510,520,530,540,410,420,440,460,480
410 F1=-1:FORZ=0TOIL:IFIA(Z)=-1THEN550ELSENEXT:F1=0:GOTO550
420 F1=0:FORZ=0TOIL:IFIA(Z)=-1THEN550ELSENEXT:F1=-1:GOTO550
430 F1=IA(LL)=-1:GOTO550
440 F1=IA(LL)<>-1ANDIA(LL)<>R:GOTO550
450 F1=IA(LL)=R:GOTO550
460 F1=IA(LL)<>0:GOTO550
470 F1=IA(LL)=RORIA(LL)=-1:GOTO550
480 F1=IA(LL)=0:GOTO550
490 F1=R=LL:GOTO550
500 F1=IA(LL)<>R:GOTO550
510 F1=IA(LL)<>-1:GOTO550
520 F1=R<>LL:GOTO550
530 F1=SFANDCINT(2^LL+.5):F1=F1<>0:GOTO550
540 F1=SFANDCINT(2^LL+.5):F1=F1=0:GOTO550
550 F2=F2ANDF1:IFF2THENNEXTYELSENEXTX:GOTO990
560 IP=0:FORY=1TO4:K=(Y-1)/2+6:ONYGOTO570,580,570,580
570 AC=CA(X,K)/150:GOTO590
580 AC=CA(X,K)-CINT(CA(X,K)/150)*150
590 IFAC>101THEN600ELSEIFAC=0THEN960ELSEIFAC<52THENPRINTMS$(AC):GOTO960:ELSEONAC-51GOTO660,700,740,760,770,780,790,760,810,830,840,850,860,870,890,920,930,940,950,710,750
600 PRINTMS$(AC-50):GOTO960
610 L=DF:IFLTHENL=DFANDIA(9)<>R ANDIA(9)<>-1:IFL PRINT"DANGEROUS TO MOVE IN THE DARK!"
620 IFNV(1)<1PRINT"GIVE ME A DIRECTION TOO.":GOTO1040
630 K=RM(R,NV(1)-1):IFK<1IFLTHENPRINT"I FELL DOWN AND BROKE MY NECK.":K=RL:DF=0:ELSEPRINT"I CAN'T GO IN THAT DIRECTION":GOTO1040
640 IFNOTLCLS
650 R=K:GOSUB240:GOTO1040
660 L=0:FORZ=1TOIL:IFIA(Z)=-1LETL=L+1
670 NEXTZ
680 IFL>=MXPRINTZ$:GOTO970
690 GOSUB1050:IA(P)=-1:GOTO960
700 GOSUB1050:IA(P)=R:GOTO960
710 PRINT"SAVING GAME":IFD=-1THENINPUT"READY OUTPUT TAPE";K$:PRINTINT(IL*5/60)+1;"MINUTES"ELSEOPEN"O",D,SV$
720 PRINT#D,SF,LX,DF,R:FORW=0TOIL:PRINT#D,IA(W):NEXT:IFD<>-1CLOSE
730 GOTO960
740 GOSUB1050:R=P:GOTO960
750 GOSUB1050:L=P:GOSUB1050:Z=IA(P):IA(P)=IA(L):IA(L)=Z:GOTO960
760 GOSUB1050:IA(P)=0:GOTO960
770 DF=-1:GOTO960
780 DF=0:GOTO960
790 GOSUB1050
800 SF=SF ORCINT(.5+2^P):GOTO960
810 GOSUB1050
820 SF=SFANDNOTCINT(.5+2^P):GOTO960
830 PRINT"I'M DEAD...":R=RL:DF=0:GOTO860
840 GOSUB1050:L=P:GOSUB1050:IA(L)=P:GOTO960
850 INPUT"THE GAME IS NOW OVER ANOTHER GAME";K$:IFLEFT$(K$,1)="N"THENENDELSEFORX=0TOIL:IA(X)=I2(X):NEXT:GOTO100
860 GOSUB240:GOTO960
870 L=0:FORZ=1TOIL:IFIA(Z)=TRIFLEFT$(IA$(Z),1)="*"LETL=L+1
880 NEXTZ:PRINT"I'VE STORED";L;"TREASURES. ON A SCALE OF 0 TO 100 THAT RATES A";CINT(L/TT*100):IFL=TTTHENPRINT"WELL DONE.":GOTO850ELSE960
890 PRINT"I'M CARRYING:":K$="NOTHING":FORZ=0TOIL:IFIA(Z)<>-1THEN910ELSEGOSUB280:IFLEN(TP$)+POS(0)>63PRINT
900 PRINTTP$;".",;K$=""
910 NEXT:PRINTK$:GOTO960
920 P=0:GOTO800
930 P=0:GOTO820
940 LX=LT:IA(9)=-1:GOTO960
950 CLS:GOTO960
960 NEXTY
970 IFNV(0)<>0THEN990
980 NEXTX
990 '
1000 IFNV(0)=0THEN1040
1010 GOSUB1060
1020 IFFPRINT"I DON'T UNDERSTAND YOUR COMMAND":GOTO1040
1030 IFNOTF2PRINT"I CAN'T DO THAT YET":GOTO1040
1040 RETURN
1050 IP=IP+1:W=CA(X,IP):P=W/20:M=W-P*20:IFM<>0THEN1050ELSERETURN
1060 IFNV(0)<>10ANDNV(0)<>18ORF3THEN1230
1070 IFNV(1)=0PRINT"WHAT?":GOTO1180
1080 IFNV(0)<>10THEN1110
1090 L=0:FORZ=0TOIL:IFIA(Z)=-1THENL=L+1
1100 NEXT:IFL>=MXPRINTZ$GOTO1180
1110 K=0:FORX=0TOIL:IFRIGHT$(IA$(X),1)<>"/"THEN1190ELSELL=LEN(IA$(X))-1:TP$=MID$(IA$(X),1,LL):FORY=LLTO2STEP-1:IFMID$(TP$,Y,1)<>"/"THENNEXTY:GOTO1190
1120 TP$=LEFT$(MID$(TP$,Y+1),LN)
1130 IFTP$<>NV$(NV(1),1)THEN1190
1140 IFNV(0)=10THEN1160
1150 IFIA(X)<>-1THENK=1:GOTO1190ELSEIA(X)=R:K=3:GOTO1170
1160 IFIA(X)<>RTHENK=2:GOTO1190ELSEIA(X)=-1:K=3
1170 PRINT"OK, ";
1180 F=0:RETURN
1190 NEXTX
1200 IFK=1THENPRINT"I'M NOT CARRYING IT"ELSEIFK=2PRINT"I DON'T SEE IT HERE"
1210 IFK=0IFNOTF3PRINT"ITS BEYOND MY POWER TO DO THAT":F=0
1220 IFK<>0THENF=0
1230 RETURN
1240 IFD<>-1THEN1330ELSEINPUT"READY DATA TAPE. HIT ENTER";K$
1250 INPUT#D,IL,CL,NL,RL,MX,AR,TT,LN,LT,ML,TR
1260 W=(IL+CL/2+NL/10+RL+ML)/12:PRINTW+1;"MINUTES TO LOAD."
1270 DIMNV(1),CA(CL,7),NV$(NL,1),IA$(IL),IA(IL),RS$(RL),RM(RL,5),MS$(ML),NT$(1),I2(IL)
1280 FORX=0TOCL STEP2:Y=X+1:INPUT#D,CA(X,0),CA(X,1),CA(X,2),CA(X,3),CA(X,4),CA(X,5),CA(X,6),CA(X,7),CA(Y,0),CA(Y,1),CA(Y,2),CA(Y,3),CA(Y,4),CA(Y,5),CA(Y,6),CA(Y,7):NEXT
1290 FORX=0TONLSTEP10:FORY=0TO1:INPUT#D,NV$(X,Y),NV$(X+1,Y),NV$(X+2,Y),NV$(X+3,Y),NV$(X+4,Y),NV$(X+5,Y),NV$(X+6,Y),NV$(X+7,Y),NV$(X+8,Y),NV$(X+9,Y):NEXTY,X
1300 FORX=0TORL:INPUT#D,RM(X,0),RM(X,1),RM(X,2),RM(X,3),RM(X,4),RM(X,5),RS$(X):NEXT
1310 FORX=0TOML:INPUT#D,MS$(X):NEXT
1320 FORX=0TOIL:INPUT#D,IA$(X),IA(X):I2(X)=IA(X):NEXT:IFD=-1RETURN
1330 REM
