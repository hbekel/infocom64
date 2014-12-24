0    rem $Id$
10   print
15   co=peek(646)
20   dr=peek(186)
30   ca$="foreground"
40   gosub 3000
50   fg=ch
60   ca$="background"
70   gosub 3000
80   bg=ch
90   ca$="page prompt (more)"
100  gosub 3000
110  mo=ch
120  rt=1
130  gosub 4000
150  gosub 2000
160  end

2000 open 15,dr,15,"s0:prefs":close 15
2010 open 5,dr,5,"prefs,w"
2020 print#5,chr$(fg)+chr$(bg)+chr$(mo)+chr$(rt)+chr$(16*tp)+chr$(222+(1*tb))
2030 close 5
2040 return


3000 print "possible "+ca$+" colors:"
3010 print " 0: "+chr$(144)+"black":poke646,co
3020 print " 1: "+chr$(  5)+"white (default foreground)":poke646,co
3030 print " 2: "+chr$( 28)+"red":poke646,co
3040 print " 3: "+chr$(159)+"cyan":poke646,co
3050 print " 4: "+chr$(156)+"purple":poke646,co
3060 print " 5: "+chr$( 30)+"green":poke646,co
3070 print " 6: "+chr$( 31)+"blue":poke646,co
3080 print " 7: "+chr$(158)+"yellow":poke646,co
3090 print " 8: "+chr$(129)+"orange":poke646,co
3100 print " 9: "+chr$(149)+"brown":poke646,co
3110 print "10: "+chr$(150)+"light red":poke646,co
3120 print "11: "+chr$(151)+"dark gray":poke646,co
3130 print "12: "+chr$(152)+"med gray (default background)":poke646,co
3140 print "13: "+chr$(153)+"light green":poke646,co
3150 print "14: "+chr$(154)+"light blue":poke646,co
3160 print "15: "+chr$(155)+"light gray":poke646,co
3180 print
3180 print "choose 1-15?"
3190 input ch
3200 if ch > 15 then goto 3180
3210 return

4000 print "possible turbo232 base addresses:"
4010 print " 0: de00"
4020 print " 1: df00"
4030 print
4040 print "choose 0-1?"
4050 input tb
4060 if tb > 1 then goto 4040
4070 print
4080 print "possible turbo232 page addresses:"
4090 print " 0: 00"
4100 print " 1: 10"
4110 print " 2: 20"
4120 print " 3: 30"
4130 print " 4: 40"
4140 print " 5: 50"
4150 print " 6: 60"
4160 print " 7: 70"
4170 print " 8: 80"
4180 print " 9: 90"
4190 print "10: a0"
4200 print "11: b0"
4210 print "12: c0"
4220 print "13: d0"
4230 print "14: e0"
4240 print "15: f0"
4250 print
4260 print "choose 0-15?"
4270 input tp
4280 if tp > 15 then goto 4260
4290 return
