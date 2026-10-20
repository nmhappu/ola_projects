     0:  0c 94 62 00  jmp    0xc4 <RESET_startup>
     4:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
     8:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
     c:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    10:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    14:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    18:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    1c:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    20:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    24:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    28:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    2c:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    30:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    34:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    38:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    3c:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    40:  0c 94 1c 0a  jmp    0x1438 <ISR_TIMER0_OVF>
    44:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    48:  0c 94 8c 0a  jmp    0x1518 <ISR_USART_RX>
    4c:  0c 94 66 0a  jmp    0x14cc <ISR_USART_UDRE>
    50:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    54:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    58:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    5c:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    60:  0c 94 be 0a  jmp    0x157c <ISR_TWI>
    64:  0c 94 8a 00  jmp    0x114 <__bad_interrupt>
    68:  00 00        nop    
    6a:  00 00        nop    
    6c:  24 00        .word  0x0024
    6e:  27 00        .word  0x0027
    70:  2a 00        .word  0x002a
    72:  00 00        nop    
    74:  00 00        nop    
    76:  25 00        .word  0x0025
    78:  28 00        .word  0x0028
    7a:  2b 00        .word  0x002b
    7c:  00 00        nop    
    7e:  00 00        nop    
    80:  23 00        .word  0x0023
    82:  26 00        .word  0x0026
    84:  29 00        .word  0x0029
    86:  04 04        cpc    r0, r4
    88:  04 04        cpc    r0, r4
    8a:  04 04        cpc    r0, r4
    8c:  04 04        cpc    r0, r4
    8e:  02 02        muls   r16, r18
    90:  02 02        muls   r16, r18
    92:  02 02        muls   r16, r18
    94:  03 03        mulsu  r16, r19
    96:  03 03        mulsu  r16, r19
    98:  03 03        mulsu  r16, r19
    9a:  01 02        muls   r16, r17
    9c:  04 08        sbc    r0, r4
    9e:  10 20        and    r1, r0
    a0:  40 80        ld     r4, Z
    a2:  01 02        muls   r16, r17
    a4:  04 08        sbc    r0, r4
    a6:  10 20        and    r1, r0
    a8:  01 02        muls   r16, r17
    aa:  04 08        sbc    r0, r4
    ac:  10 20        and    r1, r0
    ae:  00 00        nop    
    b0:  00 08        sbc    r0, r0
    b2:  00 02        muls   r16, r16
    b4:  01 00        .word  0x0001
    b6:  00 03        mulsu  r16, r16
    b8:  04 07        cpc    r16, r20
    c2:  dd 0b        sbc    r29, r29

; ===================== RESET_startup =====================
    c4:  11 24        eor    r1, r1
    c6:  1f be        out    0x3f, r1   ; SREG
    c8:  cf ef        ldi    r28, 0xFF   ; 255
    ca:  d8 e0        ldi    r29, 0x08   ; 8  pair r28:r29 = 0x08FF = 2303
    cc:  de bf        out    0x3e, r29   ; SPH
    ce:  cd bf        out    0x3d, r28   ; SPL
    d0:  11 e0        ldi    r17, 0x01   ; 1
    d2:  a0 e0        ldi    r26, 0x00   ; 0
    d4:  b1 e0        ldi    r27, 0x01   ; 1  pair r26:r27 = 0x0100 = 256
    d6:  e8 eb        ldi    r30, 0xB8   ; 184
    d8:  f2 e2        ldi    r31, 0x22   ; 34 '"'  pair r30:r31 = 0x22B8 = 8888
    da:  02 c0        rjmp   0xe0
    dc:  05 90        lpm    r0, Z+
    de:  0d 92        st     X+, r0
    e0:  aa 3d        cpi    r26, 0xDA
    e2:  b1 07        cpc    r27, r17
    e4:  d9 f7        brne   0xdc
    e6:  23 e0        ldi    r18, 0x03   ; 3
    e8:  aa ed        ldi    r26, 0xDA   ; 218
    ea:  b1 e0        ldi    r27, 0x01   ; 1  pair r26:r27 = 0x01DA = 474
    ec:  01 c0        rjmp   0xf0
    ee:  1d 92        st     X+, r1
    f0:  a0 38        cpi    r26, 0x80
    f2:  b2 07        cpc    r27, r18
    f4:  e1 f7        brne   0xee
    f6:  10 e0        ldi    r17, 0x00   ; 0
    f8:  c2 e6        ldi    r28, 0x62   ; 98 'b'
    fa:  d0 e0        ldi    r29, 0x00   ; 0  pair r28:r29 = 0x0062 = 98
    fc:  04 c0        rjmp   0x106
    fe:  21 97        sbiw   r28, 0x01
   100:  fe 01        movw   r30, r28
   102:  0e 94 4b 11  call   0x2296
   106:  c1 36        cpi    r28, 0x61
   108:  d1 07        cpc    r29, r17
   10a:  c9 f7        brne   0xfe
   10c:  0e 94 44 0c  call   0x1888 <main>
   110:  0c 94 5a 11  jmp    0x22b4 <exit>

; ===================== __bad_interrupt =====================
   114:  0c 94 00 00  jmp    0x0
   118:  83 30        cpi    r24, 0x03
   11a:  81 f0        breq   0x13c
   11c:  28 f4        brcc   0x128
   11e:  81 30        cpi    r24, 0x01
   120:  99 f0        breq   0x148
   122:  82 30        cpi    r24, 0x02
   124:  a9 f0        breq   0x150
   126:  08 95        ret    
   128:  87 30        cpi    r24, 0x07
   12a:  a9 f0        breq   0x156
   12c:  88 30        cpi    r24, 0x08
   12e:  c9 f0        breq   0x162
   130:  84 30        cpi    r24, 0x04
   132:  b1 f4        brne   0x160
   134:  80 91 80 00  lds    r24, 0x0080   ; TCCR1A
   138:  8f 7d        andi   r24, 0xDF
   13a:  03 c0        rjmp   0x142
   13c:  80 91 80 00  lds    r24, 0x0080   ; TCCR1A
   140:  8f 77        andi   r24, 0x7F
   142:  80 93 80 00  sts    0x0080, r24   ; TCCR1A
   146:  08 95        ret    
   148:  84 b5        in     r24, 0x24   ; TCCR0A
   14a:  8f 77        andi   r24, 0x7F
   14c:  84 bd        out    0x24, r24   ; TCCR0A
   14e:  08 95        ret    
   150:  84 b5        in     r24, 0x24   ; TCCR0A
   152:  8f 7d        andi   r24, 0xDF
   154:  fb cf        rjmp   0x14c
   156:  80 91 b0 00  lds    r24, 0x00B0   ; TCCR2A
   15a:  8f 77        andi   r24, 0x7F
   15c:  80 93 b0 00  sts    0x00B0, r24   ; TCCR2A
   160:  08 95        ret    
   162:  80 91 b0 00  lds    r24, 0x00B0   ; TCCR2A
   166:  8f 7d        andi   r24, 0xDF
   168:  f9 cf        rjmp   0x15c

; ===================== digitalRead =====================
   16a:  cf 93        push   r28
   16c:  df 93        push   r29
   16e:  28 2f        mov    r18, r24
   170:  30 e0        ldi    r19, 0x00   ; 0
   172:  f9 01        movw   r30, r18
   174:  e2 55        subi   r30, 0x52
   176:  ff 4f        sbci   r31, 0xFF
   178:  84 91        lpm    r24, Z
   17a:  f9 01        movw   r30, r18
   17c:  e6 56        subi   r30, 0x66
   17e:  ff 4f        sbci   r31, 0xFF
   180:  d4 91        lpm    r29, Z
   182:  f9 01        movw   r30, r18
   184:  ea 57        subi   r30, 0x7A
   186:  ff 4f        sbci   r31, 0xFF
   188:  c4 91        lpm    r28, Z
   18a:  cc 23        and    r28, r28
   18c:  a1 f0        breq   0x1b6
   18e:  81 11        cpse   r24, r1
   190:  0e 94 8c 00  call   0x118
   194:  ec 2f        mov    r30, r28
   196:  f0 e0        ldi    r31, 0x00   ; 0
   198:  ee 0f        add    r30, r30
   19a:  ff 1f        adc    r31, r31
   19c:  e4 58        subi   r30, 0x84
   19e:  ff 4f        sbci   r31, 0xFF
   1a0:  a5 91        lpm    r26, Z+
   1a2:  b4 91        lpm    r27, Z
   1a4:  ec 91        ld     r30, X
   1a6:  ed 23        and    r30, r29
   1a8:  81 e0        ldi    r24, 0x01   ; 1
   1aa:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
   1ac:  09 f4        brne   0x1b0
   1ae:  80 e0        ldi    r24, 0x00   ; 0
   1b0:  df 91        pop    r29
   1b2:  cf 91        pop    r28
   1b4:  08 95        ret    
   1b6:  80 e0        ldi    r24, 0x00   ; 0
   1b8:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
   1ba:  fa cf        rjmp   0x1b0

; ===================== digitalWrite =====================
   1bc:  1f 93        push   r17
   1be:  cf 93        push   r28
   1c0:  df 93        push   r29
   1c2:  28 2f        mov    r18, r24
   1c4:  30 e0        ldi    r19, 0x00   ; 0
   1c6:  f9 01        movw   r30, r18
   1c8:  e2 55        subi   r30, 0x52
   1ca:  ff 4f        sbci   r31, 0xFF
   1cc:  84 91        lpm    r24, Z
   1ce:  f9 01        movw   r30, r18
   1d0:  e6 56        subi   r30, 0x66
   1d2:  ff 4f        sbci   r31, 0xFF
   1d4:  d4 91        lpm    r29, Z
   1d6:  f9 01        movw   r30, r18
   1d8:  ea 57        subi   r30, 0x7A
   1da:  ff 4f        sbci   r31, 0xFF
   1dc:  c4 91        lpm    r28, Z
   1de:  cc 23        and    r28, r28
   1e0:  a9 f0        breq   0x20c
   1e2:  16 2f        mov    r17, r22
   1e4:  81 11        cpse   r24, r1
   1e6:  0e 94 8c 00  call   0x118
   1ea:  ec 2f        mov    r30, r28
   1ec:  f0 e0        ldi    r31, 0x00   ; 0
   1ee:  ee 0f        add    r30, r30
   1f0:  ff 1f        adc    r31, r31
   1f2:  ee 58        subi   r30, 0x8E
   1f4:  ff 4f        sbci   r31, 0xFF
   1f6:  a5 91        lpm    r26, Z+
   1f8:  b4 91        lpm    r27, Z
   1fa:  8f b7        in     r24, 0x3f   ; SREG
   1fc:  f8 94        cli    
   1fe:  ec 91        ld     r30, X
   200:  11 11        cpse   r17, r1
   202:  08 c0        rjmp   0x214
   204:  d0 95        com    r29
   206:  de 23        and    r29, r30
   208:  dc 93        st     X, r29
   20a:  8f bf        out    0x3f, r24   ; SREG
   20c:  df 91        pop    r29
   20e:  cf 91        pop    r28
   210:  1f 91        pop    r17
   212:  08 95        ret    
   214:  de 2b        or     r29, r30
   216:  f8 cf        rjmp   0x208

; ===================== mcp_endSPI =====================
   218:  61 e0        ldi    r22, 0x01   ; 1
   21a:  80 91 66 03  lds    r24, 0x0366
   21e:  0c 94 de 00  jmp    0x1bc <digitalWrite>

; ===================== pinMode =====================
   222:  cf 93        push   r28
   224:  df 93        push   r29
   226:  90 e0        ldi    r25, 0x00   ; 0
   228:  fc 01        movw   r30, r24
   22a:  e6 56        subi   r30, 0x66
   22c:  ff 4f        sbci   r31, 0xFF
   22e:  24 91        lpm    r18, Z
   230:  8a 57        subi   r24, 0x7A
   232:  9f 4f        sbci   r25, 0xFF
   234:  fc 01        movw   r30, r24
   236:  84 91        lpm    r24, Z
   238:  88 23        and    r24, r24
   23a:  d1 f0        breq   0x270
   23c:  90 e0        ldi    r25, 0x00   ; 0
   23e:  88 0f        add    r24, r24
   240:  99 1f        adc    r25, r25
   242:  fc 01        movw   r30, r24
   244:  e8 59        subi   r30, 0x98
   246:  ff 4f        sbci   r31, 0xFF
   248:  a5 91        lpm    r26, Z+
   24a:  b4 91        lpm    r27, Z
   24c:  fc 01        movw   r30, r24
   24e:  ee 58        subi   r30, 0x8E
   250:  ff 4f        sbci   r31, 0xFF
   252:  c5 91        lpm    r28, Z+
   254:  d4 91        lpm    r29, Z
   256:  62 30        cpi    r22, 0x02
   258:  71 f4        brne   0x276
   25a:  9f b7        in     r25, 0x3f   ; SREG
   25c:  f8 94        cli    
   25e:  3c 91        ld     r19, X
   260:  82 2f        mov    r24, r18
   262:  80 95        com    r24
   264:  83 23        and    r24, r19
   266:  8c 93        st     X, r24
   268:  e8 81        ld     r30, Y
   26a:  2e 2b        or     r18, r30
   26c:  28 83        st     Y, r18
   26e:  9f bf        out    0x3f, r25   ; SREG
   270:  df 91        pop    r29
   272:  cf 91        pop    r28
   274:  08 95        ret    
   276:  8f b7        in     r24, 0x3f   ; SREG
   278:  f8 94        cli    
   27a:  ec 91        ld     r30, X
   27c:  2e 2b        or     r18, r30
   27e:  2c 93        st     X, r18
   280:  8f bf        out    0x3f, r24   ; SREG
   282:  f6 cf        rjmp   0x270
   284:  3f b7        in     r19, 0x3f   ; SREG
   286:  f8 94        cli    
   288:  80 91 a4 02  lds    r24, 0x02A4
   28c:  90 91 a5 02  lds    r25, 0x02A5
   290:  a0 91 a6 02  lds    r26, 0x02A6
   294:  b0 91 a7 02  lds    r27, 0x02A7
   298:  26 b5        in     r18, 0x26   ; TCNT0
   29a:  a8 9b        sbis   0x15, 0   ; TIFR0
   29c:  05 c0        rjmp   0x2a8
   29e:  2f 3f        cpi    r18, 0xFF
   2a0:  19 f0        breq   0x2a8
   2a2:  01 96        adiw   r24, 0x01
   2a4:  a1 1d        adc    r26, r1
   2a6:  b1 1d        adc    r27, r1
   2a8:  3f bf        out    0x3f, r19   ; SREG
   2aa:  ba 2f        mov    r27, r26
   2ac:  a9 2f        mov    r26, r25
   2ae:  98 2f        mov    r25, r24
   2b0:  88 27        eor    r24, r24
   2b2:  bc 01        movw   r22, r24
   2b4:  cd 01        movw   r24, r26
   2b6:  62 0f        add    r22, r18
   2b8:  71 1d        adc    r23, r1
   2ba:  81 1d        adc    r24, r1
   2bc:  91 1d        adc    r25, r1
   2be:  42 e0        ldi    r20, 0x02   ; 2
   2c0:  66 0f        add    r22, r22
   2c2:  77 1f        adc    r23, r23
   2c4:  88 1f        adc    r24, r24
   2c6:  99 1f        adc    r25, r25
   2c8:  4a 95        dec    r20
   2ca:  d1 f7        brne   0x2c0
   2cc:  08 95        ret    

; ===================== delay =====================
   2ce:  8f 92        push   r8
   2d0:  9f 92        push   r9
   2d2:  af 92        push   r10
   2d4:  bf 92        push   r11
   2d6:  cf 92        push   r12
   2d8:  df 92        push   r13
   2da:  ef 92        push   r14
   2dc:  ff 92        push   r15
   2de:  4b 01        movw   r8, r22
   2e0:  5c 01        movw   r10, r24
   2e2:  0e 94 42 01  call   0x284
   2e6:  6b 01        movw   r12, r22
   2e8:  7c 01        movw   r14, r24
   2ea:  0e 94 42 01  call   0x284
   2ee:  6c 19        sub    r22, r12
   2f0:  7d 09        sbc    r23, r13
   2f2:  8e 09        sbc    r24, r14
   2f4:  9f 09        sbc    r25, r15
   2f6:  68 3e        cpi    r22, 0xE8
   2f8:  73 40        sbci   r23, 0x03
   2fa:  81 05        cpc    r24, r1
   2fc:  91 05        cpc    r25, r1
   2fe:  a8 f3        brcs   0x2ea
   300:  21 e0        ldi    r18, 0x01   ; 1
   302:  82 1a        sub    r8, r18
   304:  91 08        sbc    r9, r1
   306:  a1 08        sbc    r10, r1
   308:  b1 08        sbc    r11, r1
   30a:  88 ee        ldi    r24, 0xE8   ; 232
   30c:  c8 0e        add    r12, r24
   30e:  83 e0        ldi    r24, 0x03   ; 3
   310:  d8 1e        adc    r13, r24
   312:  e1 1c        adc    r14, r1
   314:  f1 1c        adc    r15, r1
   316:  81 14        cp     r8, r1
   318:  91 04        cpc    r9, r1
   31a:  a1 04        cpc    r10, r1
   31c:  b1 04        cpc    r11, r1
   31e:  29 f7        brne   0x2ea
   320:  ff 90        pop    r15
   322:  ef 90        pop    r14
   324:  df 90        pop    r13
   326:  cf 90        pop    r12
   328:  bf 90        pop    r11
   32a:  af 90        pop    r10
   32c:  9f 90        pop    r9
   32e:  8f 90        pop    r8
   330:  08 95        ret    
   332:  08 95        ret    
   334:  08 95        ret    
   336:  af 92        push   r10
   338:  bf 92        push   r11
   33a:  cf 92        push   r12
   33c:  df 92        push   r13
   33e:  ef 92        push   r14
   340:  ff 92        push   r15
   342:  0f 93        push   r16
   344:  1f 93        push   r17
   346:  cf 93        push   r28
   348:  df 93        push   r29
   34a:  6c 01        movw   r12, r24
   34c:  7b 01        movw   r14, r22
   34e:  8b 01        movw   r16, r22
   350:  04 0f        add    r16, r20
   352:  15 1f        adc    r17, r21
   354:  eb 01        movw   r28, r22
   356:  5e 01        movw   r10, r28
   358:  ae 18        sub    r10, r14
   35a:  bf 08        sbc    r11, r15
   35c:  c0 17        cp     r28, r16
   35e:  d1 07        cpc    r29, r17
   360:  59 f0        breq   0x378
   362:  69 91        ld     r22, Y+
   364:  d6 01        movw   r26, r12
   366:  ed 91        ld     r30, X+
   368:  fc 91        ld     r31, X
   36a:  01 90        ld     r0, Z+
   36c:  f0 81        ld     r31, Z
   36e:  e0 2d        mov    r30, r0
   370:  c6 01        movw   r24, r12
   372:  09 95        icall  
   374:  89 2b        or     r24, r25
   376:  79 f7        brne   0x356
   378:  c5 01        movw   r24, r10
   37a:  df 91        pop    r29
   37c:  cf 91        pop    r28
   37e:  1f 91        pop    r17
   380:  0f 91        pop    r16
   382:  ff 90        pop    r15
   384:  ef 90        pop    r14
   386:  df 90        pop    r13
   388:  cf 90        pop    r12
   38a:  bf 90        pop    r11
   38c:  af 90        pop    r10
   38e:  08 95        ret    
   390:  fc 01        movw   r30, r24
   392:  53 8d        ldd    r21, Z+27
   394:  44 8d        ldd    r20, Z+28
   396:  25 2f        mov    r18, r21
   398:  30 e0        ldi    r19, 0x00   ; 0
   39a:  84 2f        mov    r24, r20
   39c:  90 e0        ldi    r25, 0x00   ; 0
   39e:  82 1b        sub    r24, r18
   3a0:  93 0b        sbc    r25, r19
   3a2:  54 17        cp     r21, r20
   3a4:  10 f0        brcs   0x3aa
   3a6:  cf 96        adiw   r24, 0x3f
   3a8:  08 95        ret    
   3aa:  01 97        sbiw   r24, 0x01
   3ac:  08 95        ret    
   3ae:  fc 01        movw   r30, r24
   3b0:  91 8d        ldd    r25, Z+25
   3b2:  82 8d        ldd    r24, Z+26
   3b4:  98 17        cp     r25, r24
   3b6:  61 f0        breq   0x3d0
   3b8:  a2 8d        ldd    r26, Z+26
   3ba:  ae 0f        add    r26, r30
   3bc:  bf 2f        mov    r27, r31
   3be:  b1 1d        adc    r27, r1
   3c0:  5d 96        adiw   r26, 0x1d
   3c2:  8c 91        ld     r24, X
   3c4:  92 8d        ldd    r25, Z+26
   3c6:  9f 5f        subi   r25, 0xFF
   3c8:  9f 73        andi   r25, 0x3F
   3ca:  92 8f        std    Z+26, r25
   3cc:  90 e0        ldi    r25, 0x00   ; 0
   3ce:  08 95        ret    
   3d0:  8f ef        ldi    r24, 0xFF   ; 255
   3d2:  9f ef        ldi    r25, 0xFF   ; 255  pair r24:r25 = 0xFFFF = 65535
   3d4:  08 95        ret    
   3d6:  fc 01        movw   r30, r24
   3d8:  91 8d        ldd    r25, Z+25
   3da:  82 8d        ldd    r24, Z+26
   3dc:  98 17        cp     r25, r24
   3de:  31 f0        breq   0x3ec
   3e0:  82 8d        ldd    r24, Z+26
   3e2:  e8 0f        add    r30, r24
   3e4:  f1 1d        adc    r31, r1
   3e6:  85 8d        ldd    r24, Z+29
   3e8:  90 e0        ldi    r25, 0x00   ; 0
   3ea:  08 95        ret    
   3ec:  8f ef        ldi    r24, 0xFF   ; 255
   3ee:  9f ef        ldi    r25, 0xFF   ; 255  pair r24:r25 = 0xFFFF = 65535
   3f0:  08 95        ret    

; ===================== HardwareSerial_available =====================
   3f2:  fc 01        movw   r30, r24
   3f4:  91 8d        ldd    r25, Z+25
   3f6:  22 8d        ldd    r18, Z+26
   3f8:  89 2f        mov    r24, r25
   3fa:  90 e0        ldi    r25, 0x00   ; 0
   3fc:  80 5c        subi   r24, 0xC0
   3fe:  9f 4f        sbci   r25, 0xFF
   400:  82 1b        sub    r24, r18
   402:  91 09        sbc    r25, r1
   404:  8f 73        andi   r24, 0x3F
   406:  99 27        eor    r25, r25
   408:  08 95        ret    

; ===================== Serial_available_bool =====================
   40a:  8c eb        ldi    r24, 0xBC   ; 188
   40c:  92 e0        ldi    r25, 0x02   ; 2  pair r24:r25 = 0x02BC = 700
   40e:  0e 94 f9 01  call   0x3f2 <HardwareSerial_available>
   412:  21 e0        ldi    r18, 0x01   ; 1
   414:  89 2b        or     r24, r25
   416:  09 f4        brne   0x41a
   418:  20 e0        ldi    r18, 0x00   ; 0
   41a:  82 2f        mov    r24, r18
   41c:  08 95        ret    
   41e:  80 e0        ldi    r24, 0x00   ; 0
   420:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
   422:  89 2b        or     r24, r25
   424:  29 f0        breq   0x430
   426:  0e 94 05 02  call   0x40a <Serial_available_bool>
   42a:  81 11        cpse   r24, r1
   42c:  0c 94 00 00  jmp    0x0
   430:  08 95        ret    
   432:  fc 01        movw   r30, r24
   434:  a4 8d        ldd    r26, Z+28
   436:  a8 0f        add    r26, r24
   438:  b9 2f        mov    r27, r25
   43a:  b1 1d        adc    r27, r1
   43c:  a3 5a        subi   r26, 0xA3
   43e:  bf 4f        sbci   r27, 0xFF
   440:  2c 91        ld     r18, X
   442:  84 8d        ldd    r24, Z+28
   444:  90 e0        ldi    r25, 0x00   ; 0
   446:  01 96        adiw   r24, 0x01
   448:  8f 73        andi   r24, 0x3F
   44a:  99 27        eor    r25, r25
   44c:  84 8f        std    Z+28, r24
   44e:  a6 89        ldd    r26, Z+22
   450:  b7 89        ldd    r27, Z+23
   452:  2c 93        st     X, r18
   454:  a0 89        ldd    r26, Z+16
   456:  b1 89        ldd    r27, Z+17
   458:  8c 91        ld     r24, X
   45a:  83 70        andi   r24, 0x03
   45c:  80 64        ori    r24, 0x40
   45e:  8c 93        st     X, r24
   460:  93 8d        ldd    r25, Z+27
   462:  84 8d        ldd    r24, Z+28
   464:  98 13        cpse   r25, r24
   466:  06 c0        rjmp   0x474
   468:  02 88        ldd    r0, Z+18
   46a:  f3 89        ldd    r31, Z+19
   46c:  e0 2d        mov    r30, r0
   46e:  80 81        ld     r24, Z
   470:  8f 7d        andi   r24, 0xDF
   472:  80 83        st     Z, r24
   474:  08 95        ret    
   476:  ef 92        push   r14
   478:  ff 92        push   r15
   47a:  0f 93        push   r16
   47c:  1f 93        push   r17
   47e:  cf 93        push   r28
   480:  df 93        push   r29
   482:  ec 01        movw   r28, r24
   484:  81 e0        ldi    r24, 0x01   ; 1
   486:  88 8f        std    Y+24, r24
   488:  9b 8d        ldd    r25, Y+27
   48a:  8c 8d        ldd    r24, Y+28
   48c:  98 13        cpse   r25, r24
   48e:  1a c0        rjmp   0x4c4
   490:  e8 89        ldd    r30, Y+16
   492:  f9 89        ldd    r31, Y+17
   494:  80 81        ld     r24, Z
   496:  85 ff        sbrs   r24, 5
   498:  15 c0        rjmp   0x4c4
   49a:  9f b7        in     r25, 0x3f   ; SREG
   49c:  f8 94        cli    
   49e:  ee 89        ldd    r30, Y+22
   4a0:  ff 89        ldd    r31, Y+23
   4a2:  60 83        st     Z, r22
   4a4:  e8 89        ldd    r30, Y+16
   4a6:  f9 89        ldd    r31, Y+17
   4a8:  80 81        ld     r24, Z
   4aa:  83 70        andi   r24, 0x03
   4ac:  80 64        ori    r24, 0x40
   4ae:  80 83        st     Z, r24
   4b0:  9f bf        out    0x3f, r25   ; SREG
   4b2:  81 e0        ldi    r24, 0x01   ; 1
   4b4:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
   4b6:  df 91        pop    r29
   4b8:  cf 91        pop    r28
   4ba:  1f 91        pop    r17
   4bc:  0f 91        pop    r16
   4be:  ff 90        pop    r15
   4c0:  ef 90        pop    r14
   4c2:  08 95        ret    
   4c4:  f6 2e        mov    r15, r22
   4c6:  0b 8d        ldd    r16, Y+27
   4c8:  10 e0        ldi    r17, 0x00   ; 0
   4ca:  0f 5f        subi   r16, 0xFF
   4cc:  1f 4f        sbci   r17, 0xFF
   4ce:  0f 73        andi   r16, 0x3F
   4d0:  11 27        eor    r17, r17
   4d2:  e0 2e        mov    r14, r16
   4d4:  8c 8d        ldd    r24, Y+28
   4d6:  8e 11        cpse   r24, r14
   4d8:  0c c0        rjmp   0x4f2
   4da:  0f b6        in     r0, 0x3f   ; SREG
   4dc:  07 fc        sbrc   r0, 7
   4de:  fa cf        rjmp   0x4d4
   4e0:  e8 89        ldd    r30, Y+16
   4e2:  f9 89        ldd    r31, Y+17
   4e4:  80 81        ld     r24, Z
   4e6:  85 ff        sbrs   r24, 5
   4e8:  f5 cf        rjmp   0x4d4
   4ea:  ce 01        movw   r24, r28
   4ec:  0e 94 19 02  call   0x432
   4f0:  f1 cf        rjmp   0x4d4
   4f2:  eb 8d        ldd    r30, Y+27
   4f4:  ec 0f        add    r30, r28
   4f6:  fd 2f        mov    r31, r29
   4f8:  f1 1d        adc    r31, r1
   4fa:  e3 5a        subi   r30, 0xA3
   4fc:  ff 4f        sbci   r31, 0xFF
   4fe:  f0 82        st     Z, r15
   500:  9f b7        in     r25, 0x3f   ; SREG
   502:  f8 94        cli    
   504:  0b 8f        std    Y+27, r16
   506:  ea 89        ldd    r30, Y+18
   508:  fb 89        ldd    r31, Y+19
   50a:  80 81        ld     r24, Z
   50c:  80 62        ori    r24, 0x20
   50e:  cf cf        rjmp   0x4ae
   510:  cf 93        push   r28
   512:  df 93        push   r29
   514:  ec 01        movw   r28, r24
   516:  88 8d        ldd    r24, Y+24
   518:  88 23        and    r24, r24
   51a:  b9 f0        breq   0x54a
   51c:  aa 89        ldd    r26, Y+18
   51e:  bb 89        ldd    r27, Y+19
   520:  e8 89        ldd    r30, Y+16
   522:  f9 89        ldd    r31, Y+17
   524:  8c 91        ld     r24, X
   526:  85 fd        sbrc   r24, 5
   528:  03 c0        rjmp   0x530
   52a:  80 81        ld     r24, Z
   52c:  86 fd        sbrc   r24, 6
   52e:  0d c0        rjmp   0x54a
   530:  0f b6        in     r0, 0x3f   ; SREG
   532:  07 fc        sbrc   r0, 7
   534:  f7 cf        rjmp   0x524
   536:  8c 91        ld     r24, X
   538:  85 ff        sbrs   r24, 5
   53a:  f2 cf        rjmp   0x520
   53c:  80 81        ld     r24, Z
   53e:  85 ff        sbrs   r24, 5
   540:  ed cf        rjmp   0x51c
   542:  ce 01        movw   r24, r28
   544:  0e 94 19 02  call   0x432
   548:  e9 cf        rjmp   0x51c
   54a:  df 91        pop    r29
   54c:  cf 91        pop    r28
   54e:  08 95        ret    

; ===================== SPI_transfer =====================
   550:  8e bd        out    0x2e, r24   ; SPDR
   552:  00 00        nop    
   554:  0d b4        in     r0, 0x2d   ; SPSR
   556:  07 fe        sbrs   r0, 7
   558:  fd cf        rjmp   0x554
   55a:  8e b5        in     r24, 0x2e   ; SPDR
   55c:  08 95        ret    

; ===================== SPI_begin =====================
   55e:  cf 93        push   r28
   560:  cf b7        in     r28, 0x3f   ; SREG
   562:  f8 94        cli    
   564:  80 91 9a 02  lds    r24, 0x029A
   568:  81 11        cpse   r24, r1
   56a:  27 c0        rjmp   0x5ba
   56c:  e0 e9        ldi    r30, 0x90   ; 144
   56e:  f0 e0        ldi    r31, 0x00   ; 0  pair r30:r31 = 0x0090 = 144
   570:  84 91        lpm    r24, Z
   572:  e4 ea        ldi    r30, 0xA4   ; 164
   574:  f0 e0        ldi    r31, 0x00   ; 0  pair r30:r31 = 0x00A4 = 164
   576:  94 91        lpm    r25, Z
   578:  e8 2f        mov    r30, r24
   57a:  f0 e0        ldi    r31, 0x00   ; 0
   57c:  ee 0f        add    r30, r30
   57e:  ff 1f        adc    r31, r31
   580:  e8 59        subi   r30, 0x98
   582:  ff 4f        sbci   r31, 0xFF
   584:  a5 91        lpm    r26, Z+
   586:  b4 91        lpm    r27, Z
   588:  ec 91        ld     r30, X
   58a:  e9 23        and    r30, r25
   58c:  21 f4        brne   0x596
   58e:  61 e0        ldi    r22, 0x01   ; 1
   590:  8a e0        ldi    r24, 0x0A   ; 10
   592:  0e 94 de 00  call   0x1bc <digitalWrite>
   596:  61 e0        ldi    r22, 0x01   ; 1
   598:  8a e0        ldi    r24, 0x0A   ; 10
   59a:  0e 94 11 01  call   0x222 <pinMode>
   59e:  8c b5        in     r24, 0x2c   ; SPCR
   5a0:  80 61        ori    r24, 0x10
   5a2:  8c bd        out    0x2c, r24   ; SPCR
   5a4:  8c b5        in     r24, 0x2c   ; SPCR
   5a6:  80 64        ori    r24, 0x40
   5a8:  8c bd        out    0x2c, r24   ; SPCR
   5aa:  61 e0        ldi    r22, 0x01   ; 1
   5ac:  8d e0        ldi    r24, 0x0D   ; 13
   5ae:  0e 94 11 01  call   0x222 <pinMode>
   5b2:  61 e0        ldi    r22, 0x01   ; 1
   5b4:  8b e0        ldi    r24, 0x0B   ; 11
   5b6:  0e 94 11 01  call   0x222 <pinMode>
   5ba:  80 91 9a 02  lds    r24, 0x029A
   5be:  8f 5f        subi   r24, 0xFF
   5c0:  80 93 9a 02  sts    0x029A, r24
   5c4:  cf bf        out    0x3f, r28   ; SREG
   5c6:  cf 91        pop    r28
   5c8:  08 95        ret    
   5ca:  08 95        ret    
   5cc:  20 91 29 02  lds    r18, 0x0229
   5d0:  26 0f        add    r18, r22
   5d2:  33 27        eor    r19, r19
   5d4:  33 1f        adc    r19, r19
   5d6:  21 32        cpi    r18, 0x21
   5d8:  31 05        cpc    r19, r1
   5da:  ec f4        brge   0x616
   5dc:  20 91 72 02  lds    r18, 0x0272
   5e0:  fc 01        movw   r30, r24
   5e2:  90 e0        ldi    r25, 0x00   ; 0
   5e4:  80 e0        ldi    r24, 0x00   ; 0
   5e6:  24 30        cpi    r18, 0x04
   5e8:  69 f0        breq   0x604
   5ea:  82 e0        ldi    r24, 0x02   ; 2
   5ec:  08 95        ret    
   5ee:  a0 91 29 02  lds    r26, 0x0229
   5f2:  21 91        ld     r18, Z+
   5f4:  ac 01        movw   r20, r24
   5f6:  47 5f        subi   r20, 0xF7
   5f8:  5d 4f        sbci   r21, 0xFD
   5fa:  a4 0f        add    r26, r20
   5fc:  b5 2f        mov    r27, r21
   5fe:  b1 1d        adc    r27, r1
   600:  2c 93        st     X, r18
   602:  01 96        adiw   r24, 0x01
   604:  86 17        cp     r24, r22
   606:  98 f3        brcs   0x5ee
   608:  80 91 29 02  lds    r24, 0x0229
   60c:  68 0f        add    r22, r24
   60e:  60 93 29 02  sts    0x0229, r22
   612:  80 e0        ldi    r24, 0x00   ; 0
   614:  08 95        ret    
   616:  81 e0        ldi    r24, 0x01   ; 1
   618:  08 95        ret    

; ===================== Wire_begin =====================
   61a:  10 92 72 02  sts    0x0272, r1
   61e:  81 e0        ldi    r24, 0x01   ; 1
   620:  80 93 71 02  sts    0x0271, r24
   624:  10 92 4c 02  sts    0x024C, r1
   628:  61 e0        ldi    r22, 0x01   ; 1
   62a:  82 e1        ldi    r24, 0x12   ; 18
   62c:  0e 94 de 00  call   0x1bc <digitalWrite>
   630:  61 e0        ldi    r22, 0x01   ; 1
   632:  83 e1        ldi    r24, 0x13   ; 19
   634:  0e 94 de 00  call   0x1bc <digitalWrite>
   638:  e9 eb        ldi    r30, 0xB9   ; 185
   63a:  f0 e0        ldi    r31, 0x00   ; 0  pair r30:r31 = 0x00B9 = 185
   63c:  80 81        ld     r24, Z
   63e:  8e 7f        andi   r24, 0xFE
   640:  80 83        st     Z, r24
   642:  80 81        ld     r24, Z
   644:  8d 7f        andi   r24, 0xFD
   646:  80 83        st     Z, r24
   648:  88 e4        ldi    r24, 0x48   ; 72 'H'
   64a:  80 93 b8 00  sts    0x00B8, r24   ; TWBR
   64e:  85 e4        ldi    r24, 0x45   ; 69 'E'
   650:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
   654:  08 95        ret    
   656:  cf 93        push   r28
   658:  df 93        push   r29
   65a:  91 e0        ldi    r25, 0x01   ; 1
   65c:  90 93 08 02  sts    0x0208, r25
   660:  88 23        and    r24, r24
   662:  b9 f0        breq   0x692
   664:  c0 91 b8 00  lds    r28, 0x00B8   ; TWBR
   668:  d0 91 ba 00  lds    r29, 0x00BA   ; TWAR
   66c:  80 91 bc 00  lds    r24, 0x00BC   ; TWCR
   670:  8a 7b        andi   r24, 0xBA
   672:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
   676:  60 e0        ldi    r22, 0x00   ; 0
   678:  82 e1        ldi    r24, 0x12   ; 18
   67a:  0e 94 de 00  call   0x1bc <digitalWrite>
   67e:  60 e0        ldi    r22, 0x00   ; 0
   680:  83 e1        ldi    r24, 0x13   ; 19
   682:  0e 94 de 00  call   0x1bc <digitalWrite>
   686:  0e 94 0d 03  call   0x61a <Wire_begin>
   68a:  d0 93 ba 00  sts    0x00BA, r29   ; TWAR
   68e:  c0 93 b8 00  sts    0x00B8, r28   ; TWBR
   692:  df 91        pop    r29
   694:  cf 91        pop    r28
   696:  08 95        ret    
   698:  08 95        ret    
   69a:  e0 91 a2 02  lds    r30, 0x02A2
   69e:  80 91 a1 02  lds    r24, 0x02A1
   6a2:  e8 17        cp     r30, r24
   6a4:  30 f4        brcc   0x6b2
   6a6:  f0 e0        ldi    r31, 0x00   ; 0
   6a8:  e8 51        subi   r30, 0x18
   6aa:  fe 4f        sbci   r31, 0xFE
   6ac:  80 81        ld     r24, Z
   6ae:  90 e0        ldi    r25, 0x00   ; 0
   6b0:  08 95        ret    
   6b2:  8f ef        ldi    r24, 0xFF   ; 255
   6b4:  9f ef        ldi    r25, 0xFF   ; 255  pair r24:r25 = 0xFFFF = 65535
   6b6:  08 95        ret    
   6b8:  90 91 a2 02  lds    r25, 0x02A2
   6bc:  80 91 a1 02  lds    r24, 0x02A1
   6c0:  2f ef        ldi    r18, 0xFF   ; 255
   6c2:  3f ef        ldi    r19, 0xFF   ; 255  pair r18:r19 = 0xFFFF = 65535
   6c4:  98 17        cp     r25, r24
   6c6:  48 f4        brcc   0x6da
   6c8:  e9 2f        mov    r30, r25
   6ca:  f0 e0        ldi    r31, 0x00   ; 0
   6cc:  e8 51        subi   r30, 0x18
   6ce:  fe 4f        sbci   r31, 0xFE
   6d0:  20 81        ld     r18, Z
   6d2:  30 e0        ldi    r19, 0x00   ; 0
   6d4:  9f 5f        subi   r25, 0xFF
   6d6:  90 93 a2 02  sts    0x02A2, r25
   6da:  c9 01        movw   r24, r18
   6dc:  08 95        ret    
   6de:  80 91 a1 02  lds    r24, 0x02A1
   6e2:  90 91 a2 02  lds    r25, 0x02A2
   6e6:  89 1b        sub    r24, r25
   6e8:  99 0b        sbc    r25, r25
   6ea:  08 95        ret    
   6ec:  cf 92        push   r12
   6ee:  df 92        push   r13
   6f0:  ef 92        push   r14
   6f2:  ff 92        push   r15
   6f4:  0f 93        push   r16
   6f6:  1f 93        push   r17
   6f8:  cf 93        push   r28
   6fa:  df 93        push   r29
   6fc:  7c 01        movw   r14, r24
   6fe:  cb 01        movw   r24, r22
   700:  8a 01        movw   r16, r20
   702:  20 91 78 02  lds    r18, 0x0278
   706:  22 23        and    r18, r18
   708:  89 f0        breq   0x72c
   70a:  eb 01        movw   r28, r22
   70c:  6b 01        movw   r12, r22
   70e:  c4 0e        add    r12, r20
   710:  d5 1e        adc    r13, r21
   712:  cc 15        cp     r28, r12
   714:  dd 05        cpc    r29, r13
   716:  69 f0        breq   0x732
   718:  69 91        ld     r22, Y+
   71a:  d7 01        movw   r26, r14
   71c:  ed 91        ld     r30, X+
   71e:  fc 91        ld     r31, X
   720:  01 90        ld     r0, Z+
   722:  f0 81        ld     r31, Z
   724:  e0 2d        mov    r30, r0
   726:  c7 01        movw   r24, r14
   728:  09 95        icall  
   72a:  f3 cf        rjmp   0x712
   72c:  64 2f        mov    r22, r20
   72e:  0e 94 e6 02  call   0x5cc
   732:  c8 01        movw   r24, r16
   734:  df 91        pop    r29
   736:  cf 91        pop    r28
   738:  1f 91        pop    r17
   73a:  0f 91        pop    r16
   73c:  ff 90        pop    r15
   73e:  ef 90        pop    r14
   740:  df 90        pop    r13
   742:  cf 90        pop    r12
   744:  08 95        ret    
   746:  cf 93        push   r28
   748:  df 93        push   r29
   74a:  1f 92        push   r1
   74c:  cd b7        in     r28, 0x3d   ; SPL
   74e:  de b7        in     r29, 0x3e   ; SPH
   750:  69 83        std    Y+1, r22
   752:  20 91 78 02  lds    r18, 0x0278
   756:  22 23        and    r18, r18
   758:  f9 f0        breq   0x798
   75a:  20 91 9f 02  lds    r18, 0x029F
   75e:  20 32        cpi    r18, 0x20
   760:  58 f0        brcs   0x778
   762:  21 e0        ldi    r18, 0x01   ; 1
   764:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x0001 = 1
   766:  fc 01        movw   r30, r24
   768:  33 83        std    Z+3, r19
   76a:  22 83        std    Z+2, r18
   76c:  90 e0        ldi    r25, 0x00   ; 0
   76e:  80 e0        ldi    r24, 0x00   ; 0
   770:  0f 90        pop    r0
   772:  df 91        pop    r29
   774:  cf 91        pop    r28
   776:  08 95        ret    
   778:  80 91 a0 02  lds    r24, 0x02A0
   77c:  e8 2f        mov    r30, r24
   77e:  f0 e0        ldi    r31, 0x00   ; 0
   780:  e7 58        subi   r30, 0x87
   782:  fd 4f        sbci   r31, 0xFD
   784:  99 81        ldd    r25, Y+1
   786:  90 83        st     Z, r25
   788:  8f 5f        subi   r24, 0xFF
   78a:  80 93 a0 02  sts    0x02A0, r24
   78e:  80 93 9f 02  sts    0x029F, r24
   792:  81 e0        ldi    r24, 0x01   ; 1
   794:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
   796:  ec cf        rjmp   0x770
   798:  61 e0        ldi    r22, 0x01   ; 1
   79a:  ce 01        movw   r24, r28
   79c:  01 96        adiw   r24, 0x01
   79e:  0e 94 e6 02  call   0x5cc
   7a2:  f7 cf        rjmp   0x792

; ===================== lcd_expanderWrite =====================
   7a4:  cf 92        push   r12
   7a6:  df 92        push   r13
   7a8:  ef 92        push   r14
   7aa:  ff 92        push   r15
   7ac:  0f 93        push   r16
   7ae:  1f 93        push   r17
   7b0:  cf 93        push   r28
   7b2:  df 93        push   r29
   7b4:  fc 01        movw   r30, r24
   7b6:  c4 81        ldd    r28, Z+4
   7b8:  21 e0        ldi    r18, 0x01   ; 1
   7ba:  20 93 78 02  sts    0x0278, r18
   7be:  c0 93 99 02  sts    0x0299, r28
   7c2:  10 92 a0 02  sts    0x02A0, r1
   7c6:  10 92 9f 02  sts    0x029F, r1
   7ca:  83 85        ldd    r24, Z+11
   7cc:  68 2b        or     r22, r24
   7ce:  89 e5        ldi    r24, 0x59   ; 89 'Y'
   7d0:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x0359 = 857
   7d2:  0e 94 a3 03  call   0x746
   7d6:  d0 91 9f 02  lds    r29, 0x029F
   7da:  d1 32        cpi    r29, 0x21
   7dc:  08 f0        brcs   0x7e0
   7de:  92 c0        rjmp   0x904
   7e0:  0e 94 42 01  call   0x284
   7e4:  6b 01        movw   r12, r22
   7e6:  7c 01        movw   r14, r24
   7e8:  80 91 72 02  lds    r24, 0x0272
   7ec:  81 11        cpse   r24, r1
   7ee:  65 c0        rjmp   0x8ba
   7f0:  82 e0        ldi    r24, 0x02   ; 2
   7f2:  80 93 72 02  sts    0x0272, r24
   7f6:  81 e0        ldi    r24, 0x01   ; 1
   7f8:  80 93 71 02  sts    0x0271, r24
   7fc:  8f ef        ldi    r24, 0xFF   ; 255
   7fe:  80 93 70 02  sts    0x0270, r24
   802:  10 92 6f 02  sts    0x026F, r1
   806:  d0 93 6e 02  sts    0x026E, r29
   80a:  a9 e7        ldi    r26, 0x79   ; 121 'y'
   80c:  b2 e0        ldi    r27, 0x02   ; 2  pair r26:r27 = 0x0279 = 633
   80e:  ee e4        ldi    r30, 0x4E   ; 78 'N'
   810:  f2 e0        ldi    r31, 0x02   ; 2  pair r30:r31 = 0x024E = 590
   812:  80 e0        ldi    r24, 0x00   ; 0
   814:  d8 13        cpse   r29, r24
   816:  85 c0        rjmp   0x922
   818:  10 92 4d 02  sts    0x024D, r1
   81c:  80 91 4d 02  lds    r24, 0x024D
   820:  cc 0f        add    r28, r28
   822:  c8 2b        or     r28, r24
   824:  c0 93 4d 02  sts    0x024D, r28
   828:  80 91 4c 02  lds    r24, 0x024C
   82c:  81 30        cpi    r24, 0x01
   82e:  09 f0        breq   0x832
   830:  7c c0        rjmp   0x92a
   832:  10 92 4c 02  sts    0x024C, r1
   836:  0e 94 42 01  call   0x284
   83a:  6b 01        movw   r12, r22
   83c:  7c 01        movw   r14, r24
   83e:  80 91 4d 02  lds    r24, 0x024D
   842:  80 93 bb 00  sts    0x00BB, r24   ; TWDR
   846:  80 91 74 02  lds    r24, 0x0274
   84a:  90 91 75 02  lds    r25, 0x0275
   84e:  a0 91 76 02  lds    r26, 0x0276
   852:  b0 91 77 02  lds    r27, 0x0277
   856:  89 2b        or     r24, r25
   858:  8a 2b        or     r24, r26
   85a:  8b 2b        or     r24, r27
   85c:  99 f0        breq   0x884
   85e:  0e 94 42 01  call   0x284
   862:  00 91 74 02  lds    r16, 0x0274
   866:  10 91 75 02  lds    r17, 0x0275
   86a:  20 91 76 02  lds    r18, 0x0276
   86e:  30 91 77 02  lds    r19, 0x0277
   872:  6c 19        sub    r22, r12
   874:  7d 09        sbc    r23, r13
   876:  8e 09        sbc    r24, r14
   878:  9f 09        sbc    r25, r15
   87a:  06 17        cp     r16, r22
   87c:  17 07        cpc    r17, r23
   87e:  28 07        cpc    r18, r24
   880:  39 07        cpc    r19, r25
   882:  e0 f1        brcs   0x8fc
   884:  80 91 bc 00  lds    r24, 0x00BC   ; TWCR
   888:  83 fd        sbrc   r24, 3
   88a:  d9 cf        rjmp   0x83e
   88c:  85 ec        ldi    r24, 0xC5   ; 197
   88e:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
   892:  0e 94 42 01  call   0x284
   896:  6b 01        movw   r12, r22
   898:  7c 01        movw   r14, r24
   89a:  80 91 72 02  lds    r24, 0x0272
   89e:  82 30        cpi    r24, 0x02
   8a0:  09 f4        brne   0x8a4
   8a2:  45 c0        rjmp   0x92e
   8a4:  80 91 70 02  lds    r24, 0x0270
   8a8:  8f 3f        cpi    r24, 0xFF
   8aa:  61 f1        breq   0x904
   8ac:  80 91 70 02  lds    r24, 0x0270
   8b0:  80 32        cpi    r24, 0x20
   8b2:  41 f1        breq   0x904
   8b4:  80 91 70 02  lds    r24, 0x0270
   8b8:  25 c0        rjmp   0x904
   8ba:  80 91 74 02  lds    r24, 0x0274
   8be:  90 91 75 02  lds    r25, 0x0275
   8c2:  a0 91 76 02  lds    r26, 0x0276
   8c6:  b0 91 77 02  lds    r27, 0x0277
   8ca:  89 2b        or     r24, r25
   8cc:  8a 2b        or     r24, r26
   8ce:  8b 2b        or     r24, r27
   8d0:  09 f4        brne   0x8d4
   8d2:  8a cf        rjmp   0x7e8
   8d4:  0e 94 42 01  call   0x284
   8d8:  00 91 74 02  lds    r16, 0x0274
   8dc:  10 91 75 02  lds    r17, 0x0275
   8e0:  20 91 76 02  lds    r18, 0x0276
   8e4:  30 91 77 02  lds    r19, 0x0277
   8e8:  6c 19        sub    r22, r12
   8ea:  7d 09        sbc    r23, r13
   8ec:  8e 09        sbc    r24, r14
   8ee:  9f 09        sbc    r25, r15
   8f0:  06 17        cp     r16, r22
   8f2:  17 07        cpc    r17, r23
   8f4:  28 07        cpc    r18, r24
   8f6:  39 07        cpc    r19, r25
   8f8:  08 f0        brcs   0x8fc
   8fa:  76 cf        rjmp   0x7e8
   8fc:  80 91 73 02  lds    r24, 0x0273
   900:  0e 94 2b 03  call   0x656
   904:  10 92 a0 02  sts    0x02A0, r1
   908:  10 92 9f 02  sts    0x029F, r1
   90c:  10 92 78 02  sts    0x0278, r1
   910:  df 91        pop    r29
   912:  cf 91        pop    r28
   914:  1f 91        pop    r17
   916:  0f 91        pop    r16
   918:  ff 90        pop    r15
   91a:  ef 90        pop    r14
   91c:  df 90        pop    r13
   91e:  cf 90        pop    r12
   920:  08 95        ret    
   922:  9d 91        ld     r25, X+
   924:  91 93        st     Z+, r25
   926:  8f 5f        subi   r24, 0xFF
   928:  75 cf        rjmp   0x814
   92a:  85 ee        ldi    r24, 0xE5   ; 229
   92c:  b0 cf        rjmp   0x88e
   92e:  80 91 74 02  lds    r24, 0x0274
   932:  90 91 75 02  lds    r25, 0x0275
   936:  a0 91 76 02  lds    r26, 0x0276
   93a:  b0 91 77 02  lds    r27, 0x0277
   93e:  89 2b        or     r24, r25
   940:  8a 2b        or     r24, r26
   942:  8b 2b        or     r24, r27
   944:  09 f4        brne   0x948
   946:  a9 cf        rjmp   0x89a
   948:  0e 94 42 01  call   0x284
   94c:  00 91 74 02  lds    r16, 0x0274
   950:  10 91 75 02  lds    r17, 0x0275
   954:  20 91 76 02  lds    r18, 0x0276
   958:  30 91 77 02  lds    r19, 0x0277
   95c:  6c 19        sub    r22, r12
   95e:  7d 09        sbc    r23, r13
   960:  8e 09        sbc    r24, r14
   962:  9f 09        sbc    r25, r15
   964:  06 17        cp     r16, r22
   966:  17 07        cpc    r17, r23
   968:  28 07        cpc    r18, r24
   96a:  39 07        cpc    r19, r25
   96c:  08 f0        brcs   0x970
   96e:  95 cf        rjmp   0x89a
   970:  c5 cf        rjmp   0x8fc
   972:  90 e0        ldi    r25, 0x00   ; 0
   974:  80 e0        ldi    r24, 0x00   ; 0
   976:  08 95        ret    

; ===================== Print_write_str =====================
   978:  fc 01        movw   r30, r24
   97a:  01 90        ld     r0, Z+
   97c:  00 20        and    r0, r0
   97e:  e9 f7        brne   0x97a
   980:  31 97        sbiw   r30, 0x01
   982:  af 01        movw   r20, r30
   984:  48 1b        sub    r20, r24
   986:  59 0b        sbc    r21, r25
   988:  bc 01        movw   r22, r24
   98a:  8d e6        ldi    r24, 0x6D   ; 109 'm'
   98c:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
   98e:  0c 94 9b 01  jmp    0x336
   992:  8f 92        push   r8
   994:  9f 92        push   r9
   996:  af 92        push   r10
   998:  bf 92        push   r11
   99a:  0f 93        push   r16
   99c:  1f 93        push   r17
   99e:  cf 93        push   r28
   9a0:  df 93        push   r29
   9a2:  cd b7        in     r28, 0x3d   ; SPL
   9a4:  de b7        in     r29, 0x3e   ; SPH
   9a6:  a1 97        sbiw   r28, 0x21
   9a8:  0f b6        in     r0, 0x3f   ; SREG
   9aa:  f8 94        cli    
   9ac:  de bf        out    0x3e, r29   ; SPH
   9ae:  0f be        out    0x3f, r0   ; SREG
   9b0:  cd bf        out    0x3d, r28   ; SPL
   9b2:  19 a2        std    Y+33, r1
   9b4:  42 30        cpi    r20, 0x02
   9b6:  08 f4        brcc   0x9ba
   9b8:  4a e0        ldi    r20, 0x0A   ; 10
   9ba:  8e 01        movw   r16, r28
   9bc:  0f 5d        subi   r16, 0xDF
   9be:  1f 4f        sbci   r17, 0xFF
   9c0:  84 2e        mov    r8, r20
   9c2:  91 2c        mov    r9, r1
   9c4:  b1 2c        mov    r11, r1
   9c6:  a1 2c        mov    r10, r1
   9c8:  a5 01        movw   r20, r10
   9ca:  94 01        movw   r18, r8
   9cc:  0e 94 29 11  call   0x2252
   9d0:  e6 2f        mov    r30, r22
   9d2:  b9 01        movw   r22, r18
   9d4:  ca 01        movw   r24, r20
   9d6:  ea 30        cpi    r30, 0x0A
   9d8:  f4 f4        brge   0xa16
   9da:  e0 5d        subi   r30, 0xD0
   9dc:  d8 01        movw   r26, r16
   9de:  ee 93        st     -X, r30
   9e0:  8d 01        movw   r16, r26
   9e2:  23 2b        or     r18, r19
   9e4:  24 2b        or     r18, r20
   9e6:  25 2b        or     r18, r21
   9e8:  79 f7        brne   0x9c8
   9ea:  90 e0        ldi    r25, 0x00   ; 0
   9ec:  80 e0        ldi    r24, 0x00   ; 0
   9ee:  10 97        sbiw   r26, 0x00
   9f0:  19 f0        breq   0x9f8
   9f2:  cd 01        movw   r24, r26
   9f4:  0e 94 bc 04  call   0x978 <Print_write_str>
   9f8:  a1 96        adiw   r28, 0x21
   9fa:  0f b6        in     r0, 0x3f   ; SREG
   9fc:  f8 94        cli    
   9fe:  de bf        out    0x3e, r29   ; SPH
   a00:  0f be        out    0x3f, r0   ; SREG
   a02:  cd bf        out    0x3d, r28   ; SPL
   a04:  df 91        pop    r29
   a06:  cf 91        pop    r28
   a08:  1f 91        pop    r17
   a0a:  0f 91        pop    r16
   a0c:  bf 90        pop    r11
   a0e:  af 90        pop    r10
   a10:  9f 90        pop    r9
   a12:  8f 90        pop    r8
   a14:  08 95        ret    
   a16:  e9 5c        subi   r30, 0xC9
   a18:  e1 cf        rjmp   0x9dc

; ===================== lcd_print_str =====================
   a1a:  0c 94 bc 04  jmp    0x978 <Print_write_str>

; ===================== lcd_write4bits =====================
   a1e:  0f 93        push   r16
   a20:  1f 93        push   r17
   a22:  cf 93        push   r28
   a24:  8c 01        movw   r16, r24
   a26:  c6 2f        mov    r28, r22
   a28:  0e 94 d2 03  call   0x7a4 <lcd_expanderWrite>
   a2c:  6c 2f        mov    r22, r28
   a2e:  64 60        ori    r22, 0x04
   a30:  c8 01        movw   r24, r16
   a32:  0e 94 d2 03  call   0x7a4 <lcd_expanderWrite>
   a36:  6c 2f        mov    r22, r28
   a38:  6b 7f        andi   r22, 0xFB
   a3a:  c8 01        movw   r24, r16
   a3c:  0e 94 d2 03  call   0x7a4 <lcd_expanderWrite>
   a40:  83 ec        ldi    r24, 0xC3   ; 195
   a42:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x00C3 = 195
   a44:  01 97        sbiw   r24, 0x01
   a46:  f1 f7        brne   0xa44
   a48:  cf 91        pop    r28
   a4a:  1f 91        pop    r17
   a4c:  0f 91        pop    r16
   a4e:  08 95        ret    

; ===================== lcd_send =====================
   a50:  0f 93        push   r16
   a52:  1f 93        push   r17
   a54:  cf 93        push   r28
   a56:  df 93        push   r29
   a58:  8c 01        movw   r16, r24
   a5a:  d6 2f        mov    r29, r22
   a5c:  c4 2f        mov    r28, r20
   a5e:  60 7f        andi   r22, 0xF0
   a60:  64 2b        or     r22, r20
   a62:  0e 94 0f 05  call   0xa1e <lcd_write4bits>
   a66:  80 e1        ldi    r24, 0x10   ; 16
   a68:  d8 9f        mul    r29, r24
   a6a:  b0 01        movw   r22, r0
   a6c:  11 24        eor    r1, r1
   a6e:  6c 2b        or     r22, r28
   a70:  c8 01        movw   r24, r16
   a72:  df 91        pop    r29
   a74:  cf 91        pop    r28
   a76:  1f 91        pop    r17
   a78:  0f 91        pop    r16
   a7a:  0c 94 0f 05  jmp    0xa1e <lcd_write4bits>
   a7e:  41 e0        ldi    r20, 0x01   ; 1
   a80:  0e 94 28 05  call   0xa50 <lcd_send>
   a84:  81 e0        ldi    r24, 0x01   ; 1
   a86:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
   a88:  08 95        ret    

; ===================== lcd_print_int =====================
   a8a:  cf 92        push   r12
   a8c:  df 92        push   r13
   a8e:  ef 92        push   r14
   a90:  ff 92        push   r15
   a92:  6c 01        movw   r12, r24
   a94:  99 0f        add    r25, r25
   a96:  ee 08        sbc    r14, r14
   a98:  ff 08        sbc    r15, r15
   a9a:  f7 fe        sbrs   r15, 7
   a9c:  16 c0        rjmp   0xaca
   a9e:  41 e0        ldi    r20, 0x01   ; 1
   aa0:  6d e2        ldi    r22, 0x2D   ; 45 '-'
   aa2:  8d e6        ldi    r24, 0x6D   ; 109 'm'
   aa4:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
   aa6:  0e 94 28 05  call   0xa50 <lcd_send>
   aaa:  66 27        eor    r22, r22
   aac:  77 27        eor    r23, r23
   aae:  cb 01        movw   r24, r22
   ab0:  6c 19        sub    r22, r12
   ab2:  7d 09        sbc    r23, r13
   ab4:  8e 09        sbc    r24, r14
   ab6:  9f 09        sbc    r25, r15
   ab8:  4a e0        ldi    r20, 0x0A   ; 10
   aba:  0e 94 c9 04  call   0x992
   abe:  01 96        adiw   r24, 0x01
   ac0:  ff 90        pop    r15
   ac2:  ef 90        pop    r14
   ac4:  df 90        pop    r13
   ac6:  cf 90        pop    r12
   ac8:  08 95        ret    
   aca:  4a e0        ldi    r20, 0x0A   ; 10
   acc:  c7 01        movw   r24, r14
   ace:  b6 01        movw   r22, r12
   ad0:  ff 90        pop    r15
   ad2:  ef 90        pop    r14
   ad4:  df 90        pop    r13
   ad6:  cf 90        pop    r12
   ad8:  0c 94 c9 04  jmp    0x992

; ===================== lcd_setCursor =====================
   adc:  cf 93        push   r28
   ade:  df 93        push   r29
   ae0:  cd b7        in     r28, 0x3d   ; SPL
   ae2:  de b7        in     r29, 0x3e   ; SPH
   ae4:  28 97        sbiw   r28, 0x08
   ae6:  0f b6        in     r0, 0x3f   ; SREG
   ae8:  f8 94        cli    
   aea:  de bf        out    0x3e, r29   ; SPH
   aec:  0f be        out    0x3f, r0   ; SREG
   aee:  cd bf        out    0x3d, r28   ; SPL
   af0:  98 e0        ldi    r25, 0x08   ; 8
   af2:  e2 e0        ldi    r30, 0x02   ; 2
   af4:  f1 e0        ldi    r31, 0x01   ; 1  pair r30:r31 = 0x0102 = 258
   af6:  de 01        movw   r26, r28
   af8:  11 96        adiw   r26, 0x01
   afa:  01 90        ld     r0, Z+
   afc:  0d 92        st     X+, r0
   afe:  9a 95        dec    r25
   b00:  e1 f7        brne   0xafa
   b02:  90 91 76 03  lds    r25, 0x0376
   b06:  96 17        cp     r25, r22
   b08:  08 f4        brcc   0xb0c
   b0a:  6f ef        ldi    r22, 0xFF   ; 255
   b0c:  26 2f        mov    r18, r22
   b0e:  30 e0        ldi    r19, 0x00   ; 0
   b10:  22 0f        add    r18, r18
   b12:  33 1f        adc    r19, r19
   b14:  41 e0        ldi    r20, 0x01   ; 1
   b16:  50 e0        ldi    r21, 0x00   ; 0  pair r20:r21 = 0x0001 = 1
   b18:  4c 0f        add    r20, r28
   b1a:  5d 1f        adc    r21, r29
   b1c:  24 0f        add    r18, r20
   b1e:  35 1f        adc    r19, r21
   b20:  f9 01        movw   r30, r18
   b22:  60 81        ld     r22, Z
   b24:  68 0f        add    r22, r24
   b26:  60 68        ori    r22, 0x80
   b28:  40 e0        ldi    r20, 0x00   ; 0
   b2a:  8d e6        ldi    r24, 0x6D   ; 109 'm'
   b2c:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
   b2e:  28 96        adiw   r28, 0x08
   b30:  0f b6        in     r0, 0x3f   ; SREG
   b32:  f8 94        cli    
   b34:  de bf        out    0x3e, r29   ; SPH
   b36:  0f be        out    0x3f, r0   ; SREG
   b38:  cd bf        out    0x3d, r28   ; SPL
   b3a:  df 91        pop    r29
   b3c:  cf 91        pop    r28
   b3e:  0c 94 28 05  jmp    0xa50 <lcd_send>

; ===================== lcd_print_float =====================
   b42:  4f 92        push   r4
   b44:  5f 92        push   r5
   b46:  6f 92        push   r6
   b48:  7f 92        push   r7
   b4a:  8f 92        push   r8
   b4c:  9f 92        push   r9
   b4e:  af 92        push   r10
   b50:  bf 92        push   r11
   b52:  cf 92        push   r12
   b54:  df 92        push   r13
   b56:  ef 92        push   r14
   b58:  ff 92        push   r15
   b5a:  0f 93        push   r16
   b5c:  1f 93        push   r17
   b5e:  cf 93        push   r28
   b60:  6b 01        movw   r12, r22
   b62:  7c 01        movw   r14, r24
   b64:  74 2e        mov    r7, r20
   b66:  ac 01        movw   r20, r24
   b68:  9b 01        movw   r18, r22
   b6a:  0e 94 24 11  call   0x2248
   b6e:  88 23        and    r24, r24
   b70:  99 f0        breq   0xb98
   b72:  8d e5        ldi    r24, 0x5D   ; 93 ']'
   b74:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x015D = 349  "nan"
   b76:  cf 91        pop    r28
   b78:  1f 91        pop    r17
   b7a:  0f 91        pop    r16
   b7c:  ff 90        pop    r15
   b7e:  ef 90        pop    r14
   b80:  df 90        pop    r13
   b82:  cf 90        pop    r12
   b84:  bf 90        pop    r11
   b86:  af 90        pop    r10
   b88:  9f 90        pop    r9
   b8a:  8f 90        pop    r8
   b8c:  7f 90        pop    r7
   b8e:  6f 90        pop    r6
   b90:  5f 90        pop    r5
   b92:  4f 90        pop    r4
   b94:  0c 94 bc 04  jmp    0x978 <Print_write_str>
   b98:  46 01        movw   r8, r12
   b9a:  57 01        movw   r10, r14
   b9c:  e8 94        clt    
   b9e:  b7 f8        bld    r11, 7
   ba0:  2f ef        ldi    r18, 0xFF   ; 255
   ba2:  3f ef        ldi    r19, 0xFF   ; 255  pair r18:r19 = 0xFFFF = 65535
   ba4:  4f e7        ldi    r20, 0x7F   ; 127
   ba6:  5f e7        ldi    r21, 0x7F   ; 127  pair r20:r21 = 0x7F7F = 32639
   ba8:  c5 01        movw   r24, r10
   baa:  b4 01        movw   r22, r8
   bac:  0e 94 24 11  call   0x2248
   bb0:  81 11        cpse   r24, r1
   bb2:  0d c0        rjmp   0xbce
   bb4:  2f ef        ldi    r18, 0xFF   ; 255
   bb6:  3f ef        ldi    r19, 0xFF   ; 255  pair r18:r19 = 0xFFFF = 65535
   bb8:  4f e7        ldi    r20, 0x7F   ; 127
   bba:  5f e7        ldi    r21, 0x7F   ; 127  pair r20:r21 = 0x7F7F = 32639
   bbc:  c5 01        movw   r24, r10
   bbe:  b4 01        movw   r22, r8
   bc0:  0e 94 5a 0f  call   0x1eb4
   bc4:  18 16        cp     r1, r24
   bc6:  1c f4        brge   0xbce
   bc8:  81 e6        ldi    r24, 0x61   ; 97 'a'
   bca:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0161 = 353  "inf"
   bcc:  d4 cf        rjmp   0xb76
   bce:  2f ef        ldi    r18, 0xFF   ; 255
   bd0:  3f ef        ldi    r19, 0xFF   ; 255  pair r18:r19 = 0xFFFF = 65535
   bd2:  4f e7        ldi    r20, 0x7F   ; 127
   bd4:  5f e4        ldi    r21, 0x4F   ; 79 'O'  pair r20:r21 = 0x4F7F = 20351
   bd6:  c7 01        movw   r24, r14
   bd8:  b6 01        movw   r22, r12
   bda:  0e 94 b2 10  call   0x2164
   bde:  18 16        cp     r1, r24
   be0:  1c f4        brge   0xbe8
   be2:  85 e6        ldi    r24, 0x65   ; 101 'e'
   be4:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0165 = 357  "ovf"
   be6:  c7 cf        rjmp   0xb76
   be8:  2f ef        ldi    r18, 0xFF   ; 255
   bea:  3f ef        ldi    r19, 0xFF   ; 255  pair r18:r19 = 0xFFFF = 65535
   bec:  4f e7        ldi    r20, 0x7F   ; 127
   bee:  5f ec        ldi    r21, 0xCF   ; 207  pair r20:r21 = 0xCF7F = 53119
   bf0:  c7 01        movw   r24, r14
   bf2:  b6 01        movw   r22, r12
   bf4:  0e 94 5a 0f  call   0x1eb4
   bf8:  87 fd        sbrc   r24, 7
   bfa:  f3 cf        rjmp   0xbe2
   bfc:  20 e0        ldi    r18, 0x00   ; 0
   bfe:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x0000 = 0
   c00:  a9 01        movw   r20, r18
   c02:  c7 01        movw   r24, r14
   c04:  b6 01        movw   r22, r12
   c06:  0e 94 5a 0f  call   0x1eb4
   c0a:  10 e0        ldi    r17, 0x00   ; 0
   c0c:  00 e0        ldi    r16, 0x00   ; 0
   c0e:  87 ff        sbrs   r24, 7
   c10:  0c c0        rjmp   0xc2a
   c12:  41 e0        ldi    r20, 0x01   ; 1
   c14:  6d e2        ldi    r22, 0x2D   ; 45 '-'
   c16:  8d e6        ldi    r24, 0x6D   ; 109 'm'
   c18:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
   c1a:  0e 94 28 05  call   0xa50 <lcd_send>
   c1e:  f7 fa        bst    r15, 7
   c20:  f0 94        com    r15
   c22:  f7 f8        bld    r15, 7
   c24:  f0 94        com    r15
   c26:  01 e0        ldi    r16, 0x01   ; 1
   c28:  10 e0        ldi    r17, 0x00   ; 0  pair r16:r17 = 0x0001 = 1
   c2a:  c0 e0        ldi    r28, 0x00   ; 0
   c2c:  60 e0        ldi    r22, 0x00   ; 0
   c2e:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0000 = 0
   c30:  80 e0        ldi    r24, 0x00   ; 0
   c32:  9f e3        ldi    r25, 0x3F   ; 63 '?'  pair r24:r25 = 0x3F00 = 16128
   c34:  7c 16        cp     r7, r28
   c36:  41 f0        breq   0xc48
   c38:  20 e0        ldi    r18, 0x00   ; 0
   c3a:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x0000 = 0
   c3c:  40 e2        ldi    r20, 0x20   ; 32 ' '
   c3e:  51 e4        ldi    r21, 0x41   ; 65 'A'  pair r20:r21 = 0x4120 = 16672
   c40:  0e 94 5f 0f  call   0x1ebe <__divsf3>
   c44:  cf 5f        subi   r28, 0xFF
   c46:  f6 cf        rjmp   0xc34
   c48:  a7 01        movw   r20, r14
   c4a:  96 01        movw   r18, r12
   c4c:  0e 94 ee 0e  call   0x1ddc
   c50:  4b 01        movw   r8, r22
   c52:  5c 01        movw   r10, r24
   c54:  0e 94 d1 0f  call   0x1fa2
   c58:  2b 01        movw   r4, r22
   c5a:  3c 01        movw   r6, r24
   c5c:  4a e0        ldi    r20, 0x0A   ; 10
   c5e:  0e 94 c9 04  call   0x992
   c62:  08 0f        add    r16, r24
   c64:  19 1f        adc    r17, r25
   c66:  cc 23        and    r28, r28
   c68:  c9 f1        breq   0xcdc
   c6a:  c3 01        movw   r24, r6
   c6c:  b2 01        movw   r22, r4
   c6e:  0e 94 00 10  call   0x2000 <__floatunsisf>
   c72:  9b 01        movw   r18, r22
   c74:  ac 01        movw   r20, r24
   c76:  c5 01        movw   r24, r10
   c78:  b4 01        movw   r22, r8
   c7a:  0e 94 ed 0e  call   0x1dda
   c7e:  4b 01        movw   r8, r22
   c80:  5c 01        movw   r10, r24
   c82:  41 e0        ldi    r20, 0x01   ; 1
   c84:  6e e2        ldi    r22, 0x2E   ; 46 '.'
   c86:  8d e6        ldi    r24, 0x6D   ; 109 'm'
   c88:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
   c8a:  0e 94 28 05  call   0xa50 <lcd_send>
   c8e:  0f 5f        subi   r16, 0xFF
   c90:  1f 4f        sbci   r17, 0xFF
   c92:  c1 50        subi   r28, 0x01
   c94:  18 f1        brcs   0xcdc
   c96:  20 e0        ldi    r18, 0x00   ; 0
   c98:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x0000 = 0
   c9a:  40 e2        ldi    r20, 0x20   ; 32 ' '
   c9c:  51 e4        ldi    r21, 0x41   ; 65 'A'  pair r20:r21 = 0x4120 = 16672
   c9e:  c5 01        movw   r24, r10
   ca0:  b4 01        movw   r22, r8
   ca2:  0e 94 b7 10  call   0x216e
   ca6:  2b 01        movw   r4, r22
   ca8:  3c 01        movw   r6, r24
   caa:  0e 94 d1 0f  call   0x1fa2
   cae:  4b 01        movw   r8, r22
   cb0:  b1 2c        mov    r11, r1
   cb2:  a1 2c        mov    r10, r1
   cb4:  4a e0        ldi    r20, 0x0A   ; 10
   cb6:  c5 01        movw   r24, r10
   cb8:  b4 01        movw   r22, r8
   cba:  0e 94 c9 04  call   0x992
   cbe:  08 0f        add    r16, r24
   cc0:  19 1f        adc    r17, r25
   cc2:  c5 01        movw   r24, r10
   cc4:  b4 01        movw   r22, r8
   cc6:  0e 94 00 10  call   0x2000 <__floatunsisf>
   cca:  9b 01        movw   r18, r22
   ccc:  ac 01        movw   r20, r24
   cce:  c3 01        movw   r24, r6
   cd0:  b2 01        movw   r22, r4
   cd2:  0e 94 ed 0e  call   0x1dda
   cd6:  4b 01        movw   r8, r22
   cd8:  5c 01        movw   r10, r24
   cda:  db cf        rjmp   0xc92
   cdc:  c8 01        movw   r24, r16
   cde:  cf 91        pop    r28
   ce0:  1f 91        pop    r17
   ce2:  0f 91        pop    r16
   ce4:  ff 90        pop    r15
   ce6:  ef 90        pop    r14
   ce8:  df 90        pop    r13
   cea:  cf 90        pop    r12
   cec:  bf 90        pop    r11
   cee:  af 90        pop    r10
   cf0:  9f 90        pop    r9
   cf2:  8f 90        pop    r8
   cf4:  7f 90        pop    r7
   cf6:  6f 90        pop    r6
   cf8:  5f 90        pop    r5
   cfa:  4f 90        pop    r4
   cfc:  08 95        ret    

; ===================== lcd_clear =====================
   cfe:  40 e0        ldi    r20, 0x00   ; 0
   d00:  61 e0        ldi    r22, 0x01   ; 1
   d02:  8d e6        ldi    r24, 0x6D   ; 109 'm'
   d04:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
   d06:  0e 94 28 05  call   0xa50 <lcd_send>
   d0a:  8b e3        ldi    r24, 0x3B   ; 59 ';'
   d0c:  9f e1        ldi    r25, 0x1F   ; 31  pair r24:r25 = 0x1F3B = 7995
   d0e:  01 97        sbiw   r24, 0x01
   d10:  f1 f7        brne   0xd0e
   d12:  08 95        ret    

; ===================== triggerDone =====================
   d14:  0e 94 7f 06  call   0xcfe <lcd_clear>
   d18:  89 e6        ldi    r24, 0x69   ; 105 'i'
   d1a:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0169 = 361  ">Trigger done"
   d1c:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   d20:  64 e6        ldi    r22, 0x64   ; 100 'd'
   d22:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0064 = 100
   d24:  80 e0        ldi    r24, 0x00   ; 0
   d26:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
   d28:  0c 94 67 01  jmp    0x2ce <delay>

; ===================== updateMenu =====================
   d2c:  0e 94 7f 06  call   0xcfe <lcd_clear>
   d30:  80 91 00 01  lds    r24, 0x0100   ; menu
   d34:  90 91 01 01  lds    r25, 0x0101   ; menu +1
   d38:  82 30        cpi    r24, 0x02
   d3a:  91 05        cpc    r25, r1
   d3c:  11 f1        breq   0xd82
   d3e:  83 30        cpi    r24, 0x03
   d40:  91 05        cpc    r25, r1
   d42:  51 f1        breq   0xd98
   d44:  01 97        sbiw   r24, 0x01
   d46:  61 f4        brne   0xd60
   d48:  87 e7        ldi    r24, 0x77   ; 119 'w'
   d4a:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0177 = 375  ">BMS Reset"
   d4c:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   d50:  61 e0        ldi    r22, 0x01   ; 1
   d52:  80 e0        ldi    r24, 0x00   ; 0
   d54:  0e 94 6e 05  call   0xadc <lcd_setCursor>
   d58:  8e e8        ldi    r24, 0x8E   ; 142
   d5a:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x018E = 398  "System Reset S1X"
   d5c:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   d60:  10 92 e1 01  sts    0x01E1, r1   ; rawVoltage +1
   d64:  10 92 e0 01  sts    0x01E0, r1   ; rawVoltage
   d68:  10 92 e3 01  sts    0x01E3, r1   ; soc +1
   d6c:  10 92 e2 01  sts    0x01E2, r1   ; soc
   d70:  10 92 e4 01  sts    0x01E4, r1   ; packVoltage
   d74:  10 92 e5 01  sts    0x01E5, r1   ; packVoltage +1
   d78:  10 92 e6 01  sts    0x01E6, r1   ; packVoltage +2
   d7c:  10 92 e7 01  sts    0x01E7, r1   ; packVoltage +3
   d80:  08 95        ret    
   d82:  82 e8        ldi    r24, 0x82   ; 130
   d84:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0182 = 386  "BMS Reset "
   d86:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   d8a:  61 e0        ldi    r22, 0x01   ; 1
   d8c:  80 e0        ldi    r24, 0x00   ; 0
   d8e:  0e 94 6e 05  call   0xadc <lcd_setCursor>
   d92:  8d e8        ldi    r24, 0x8D   ; 141
   d94:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x018D = 397  ">System Reset S1X"
   d96:  e2 cf        rjmp   0xd5c
   d98:  0e 94 7f 06  call   0xcfe <lcd_clear>
   d9c:  8f e9        ldi    r24, 0x9F   ; 159
   d9e:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x019F = 415  ">Pack_V: "
   da0:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   da4:  60 91 e4 01  lds    r22, 0x01E4   ; packVoltage
   da8:  70 91 e5 01  lds    r23, 0x01E5   ; packVoltage +1
   dac:  80 91 e6 01  lds    r24, 0x01E6   ; packVoltage +2
   db0:  90 91 e7 01  lds    r25, 0x01E7   ; packVoltage +3
   db4:  42 e0        ldi    r20, 0x02   ; 2
   db6:  0e 94 a1 05  call   0xb42 <lcd_print_float>
   dba:  89 ea        ldi    r24, 0xA9   ; 169
   dbc:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01A9 = 425  "V"
   dbe:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   dc2:  61 e0        ldi    r22, 0x01   ; 1
   dc4:  80 e0        ldi    r24, 0x00   ; 0
   dc6:  0e 94 6e 05  call   0xadc <lcd_setCursor>
   dca:  8b ea        ldi    r24, 0xAB   ; 171
   dcc:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01AB = 427  "SOC: "
   dce:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   dd2:  80 91 e2 01  lds    r24, 0x01E2   ; soc
   dd6:  90 91 e3 01  lds    r25, 0x01E3   ; soc +1
   dda:  0e 94 45 05  call   0xa8a <lcd_print_int>
   dde:  81 eb        ldi    r24, 0xB1   ; 177
   de0:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01B1 = 433  "%"
   de2:  0e 94 0d 05  call   0xa1a <lcd_print_str>
   de6:  64 e6        ldi    r22, 0x64   ; 100 'd'
   de8:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0064 = 100
   dea:  80 e0        ldi    r24, 0x00   ; 0
   dec:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
   dee:  0e 94 67 01  call   0x2ce <delay>
   df2:  b6 cf        rjmp   0xd60

; ===================== mcp_startSPI =====================
   df4:  0f 93        push   r16
   df6:  1f 93        push   r17
   df8:  00 91 67 03  lds    r16, 0x0367
   dfc:  10 91 68 03  lds    r17, 0x0368
   e00:  20 91 69 03  lds    r18, 0x0369
   e04:  30 91 6a 03  lds    r19, 0x036A
   e08:  40 e0        ldi    r20, 0x00   ; 0
   e0a:  52 e1        ldi    r21, 0x12   ; 18  pair r20:r21 = 0x1200 = 4608
   e0c:  6a e7        ldi    r22, 0x7A   ; 122 'z'
   e0e:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x007A = 122
   e10:  80 e0        ldi    r24, 0x00   ; 0
   e12:  04 17        cp     r16, r20
   e14:  15 07        cpc    r17, r21
   e16:  26 07        cpc    r18, r22
   e18:  37 07        cpc    r19, r23
   e1a:  40 f4        brcc   0xe2c
   e1c:  76 95        lsr    r23
   e1e:  67 95        ror    r22
   e20:  57 95        ror    r21
   e22:  47 95        ror    r20
   e24:  8f 5f        subi   r24, 0xFF
   e26:  86 30        cpi    r24, 0x06
   e28:  a1 f7        brne   0xe12
   e2a:  87 e0        ldi    r24, 0x07   ; 7
   e2c:  98 2f        mov    r25, r24
   e2e:  90 6a        ori    r25, 0xA0
   e30:  96 95        lsr    r25
   e32:  80 95        com    r24
   e34:  81 70        andi   r24, 0x01
   e36:  9c bd        out    0x2c, r25   ; SPCR
   e38:  8d bd        out    0x2d, r24   ; SPSR
   e3a:  60 e0        ldi    r22, 0x00   ; 0
   e3c:  80 91 66 03  lds    r24, 0x0366
   e40:  1f 91        pop    r17
   e42:  0f 91        pop    r16
   e44:  0c 94 de 00  jmp    0x1bc <digitalWrite>

; ===================== mcp_readRegister =====================
   e48:  cf 93        push   r28
   e4a:  c8 2f        mov    r28, r24
   e4c:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
   e50:  83 e0        ldi    r24, 0x03   ; 3
   e52:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e56:  8c 2f        mov    r24, r28
   e58:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e5c:  80 e0        ldi    r24, 0x00   ; 0
   e5e:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e62:  c8 2f        mov    r28, r24
   e64:  0e 94 0c 01  call   0x218 <mcp_endSPI>
   e68:  8c 2f        mov    r24, r28
   e6a:  cf 91        pop    r28
   e6c:  08 95        ret    

; ===================== mcp_modifyRegister =====================
   e6e:  1f 93        push   r17
   e70:  cf 93        push   r28
   e72:  df 93        push   r29
   e74:  18 2f        mov    r17, r24
   e76:  d6 2f        mov    r29, r22
   e78:  c4 2f        mov    r28, r20
   e7a:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
   e7e:  85 e0        ldi    r24, 0x05   ; 5
   e80:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e84:  81 2f        mov    r24, r17
   e86:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e8a:  8d 2f        mov    r24, r29
   e8c:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e90:  8c 2f        mov    r24, r28
   e92:  0e 94 a8 02  call   0x550 <SPI_transfer>
   e96:  df 91        pop    r29
   e98:  cf 91        pop    r28
   e9a:  1f 91        pop    r17
   e9c:  0c 94 0c 01  jmp    0x218 <mcp_endSPI>

; ===================== mcp_setMode =====================
   ea0:  cf 92        push   r12
   ea2:  df 92        push   r13
   ea4:  ef 92        push   r14
   ea6:  ff 92        push   r15
   ea8:  cf 93        push   r28
   eaa:  c8 2f        mov    r28, r24
   eac:  48 2f        mov    r20, r24
   eae:  60 ee        ldi    r22, 0xE0   ; 224
   eb0:  8f e0        ldi    r24, 0x0F   ; 15
   eb2:  0e 94 37 07  call   0xe6e <mcp_modifyRegister>
   eb6:  8f b7        in     r24, 0x3f   ; SREG
   eb8:  f8 94        cli    
   eba:  c0 90 b8 02  lds    r12, 0x02B8
   ebe:  d0 90 b9 02  lds    r13, 0x02B9
   ec2:  e0 90 ba 02  lds    r14, 0x02BA
   ec6:  f0 90 bb 02  lds    r15, 0x02BB
   eca:  8f bf        out    0x3f, r24   ; SREG
   ecc:  8a e0        ldi    r24, 0x0A   ; 10
   ece:  c8 0e        add    r12, r24
   ed0:  d1 1c        adc    r13, r1
   ed2:  e1 1c        adc    r14, r1
   ed4:  f1 1c        adc    r15, r1
   ed6:  2f b7        in     r18, 0x3f   ; SREG
   ed8:  f8 94        cli    
   eda:  80 91 b8 02  lds    r24, 0x02B8
   ede:  90 91 b9 02  lds    r25, 0x02B9
   ee2:  a0 91 ba 02  lds    r26, 0x02BA
   ee6:  b0 91 bb 02  lds    r27, 0x02BB
   eea:  2f bf        out    0x3f, r18   ; SREG
   eec:  8c 15        cp     r24, r12
   eee:  9d 05        cpc    r25, r13
   ef0:  ae 05        cpc    r26, r14
   ef2:  bf 05        cpc    r27, r15
   ef4:  80 f4        brcc   0xf16
   ef6:  8e e0        ldi    r24, 0x0E   ; 14
   ef8:  0e 94 24 07  call   0xe48 <mcp_readRegister>
   efc:  80 7e        andi   r24, 0xE0
   efe:  c8 13        cpse   r28, r24
   f00:  ea cf        rjmp   0xed6
   f02:  81 e0        ldi    r24, 0x01   ; 1
   f04:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0101 = 257
   f06:  89 27        eor    r24, r25
   f08:  90 e0        ldi    r25, 0x00   ; 0
   f0a:  cf 91        pop    r28
   f0c:  ff 90        pop    r15
   f0e:  ef 90        pop    r14
   f10:  df 90        pop    r13
   f12:  cf 90        pop    r12
   f14:  08 95        ret    
   f16:  80 e0        ldi    r24, 0x00   ; 0
   f18:  f5 cf        rjmp   0xf04

; ===================== mcp_setRegister =====================
   f1a:  cf 93        push   r28
   f1c:  df 93        push   r29
   f1e:  d8 2f        mov    r29, r24
   f20:  c6 2f        mov    r28, r22
   f22:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
   f26:  82 e0        ldi    r24, 0x02   ; 2
   f28:  0e 94 a8 02  call   0x550 <SPI_transfer>
   f2c:  8d 2f        mov    r24, r29
   f2e:  0e 94 a8 02  call   0x550 <SPI_transfer>
   f32:  8c 2f        mov    r24, r28
   f34:  0e 94 a8 02  call   0x550 <SPI_transfer>
   f38:  df 91        pop    r29
   f3a:  cf 91        pop    r28
   f3c:  0c 94 0c 01  jmp    0x218 <mcp_endSPI>

; ===================== mcp_setRegisters =====================
   f40:  ff 92        push   r15
   f42:  0f 93        push   r16
   f44:  1f 93        push   r17
   f46:  cf 93        push   r28
   f48:  df 93        push   r29
   f4a:  c8 2f        mov    r28, r24
   f4c:  f6 2e        mov    r15, r22
   f4e:  17 2f        mov    r17, r23
   f50:  04 2f        mov    r16, r20
   f52:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
   f56:  82 e0        ldi    r24, 0x02   ; 2
   f58:  0e 94 a8 02  call   0x550 <SPI_transfer>
   f5c:  8c 2f        mov    r24, r28
   f5e:  0e 94 a8 02  call   0x550 <SPI_transfer>
   f62:  cf 2d        mov    r28, r15
   f64:  d1 2f        mov    r29, r17
   f66:  0c 0f        add    r16, r28
   f68:  1d 2f        mov    r17, r29
   f6a:  11 1d        adc    r17, r1
   f6c:  c0 17        cp     r28, r16
   f6e:  d1 07        cpc    r29, r17
   f70:  21 f0        breq   0xf7a
   f72:  89 91        ld     r24, Y+
   f74:  0e 94 a8 02  call   0x550 <SPI_transfer>
   f78:  f9 cf        rjmp   0xf6c
   f7a:  df 91        pop    r29
   f7c:  cf 91        pop    r28
   f7e:  1f 91        pop    r17
   f80:  0f 91        pop    r16
   f82:  ff 90        pop    r15
   f84:  0c 94 0c 01  jmp    0x218 <mcp_endSPI>
   f88:  ff 92        push   r15
   f8a:  0f 93        push   r16
   f8c:  1f 93        push   r17
   f8e:  cf 93        push   r28
   f90:  df 93        push   r29
   f92:  c8 2f        mov    r28, r24
   f94:  f6 2e        mov    r15, r22
   f96:  17 2f        mov    r17, r23
   f98:  04 2f        mov    r16, r20
   f9a:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
   f9e:  83 e0        ldi    r24, 0x03   ; 3
   fa0:  0e 94 a8 02  call   0x550 <SPI_transfer>
   fa4:  8c 2f        mov    r24, r28
   fa6:  0e 94 a8 02  call   0x550 <SPI_transfer>
   faa:  cf 2d        mov    r28, r15
   fac:  d1 2f        mov    r29, r17
   fae:  0c 0f        add    r16, r28
   fb0:  1d 2f        mov    r17, r29
   fb2:  11 1d        adc    r17, r1
   fb4:  c0 17        cp     r28, r16
   fb6:  d1 07        cpc    r29, r17
   fb8:  29 f0        breq   0xfc4
   fba:  80 e0        ldi    r24, 0x00   ; 0
   fbc:  0e 94 a8 02  call   0x550 <SPI_transfer>
   fc0:  89 93        st     Y+, r24
   fc2:  f8 cf        rjmp   0xfb4
   fc4:  df 91        pop    r29
   fc6:  cf 91        pop    r28
   fc8:  1f 91        pop    r17
   fca:  0f 91        pop    r16
   fcc:  ff 90        pop    r15
   fce:  0c 94 0c 01  jmp    0x218 <mcp_endSPI>

; ===================== mcp_readMessage_rxb =====================
   fd2:  bf 92        push   r11
   fd4:  cf 92        push   r12
   fd6:  df 92        push   r13
   fd8:  ef 92        push   r14
   fda:  ff 92        push   r15
   fdc:  0f 93        push   r16
   fde:  1f 93        push   r17
   fe0:  cf 93        push   r28
   fe2:  df 93        push   r29
   fe4:  00 d0        rcall  0xfe6
   fe6:  00 d0        rcall  0xfe8
   fe8:  1f 92        push   r1
   fea:  cd b7        in     r28, 0x3d   ; SPL
   fec:  de b7        in     r29, 0x3e   ; SPH
   fee:  8c 01        movw   r16, r24
   ff0:  00 0f        add    r16, r16
   ff2:  11 1f        adc    r17, r17
   ff4:  00 0f        add    r16, r16
   ff6:  11 1f        adc    r17, r17
   ff8:  f8 01        movw   r30, r16
   ffa:  eb 5d        subi   r30, 0xDB
   ffc:  fe 4f        sbci   r31, 0xFE
   ffe:  45 e0        ldi    r20, 0x05   ; 5
  1000:  be 01        movw   r22, r28
  1002:  6f 5f        subi   r22, 0xFF
  1004:  7f 4f        sbci   r23, 0xFF
  1006:  81 81        ldd    r24, Z+1
  1008:  0e 94 c4 07  call   0xf88
  100c:  8a 81        ldd    r24, Y+2
  100e:  c9 80        ldd    r12, Y+1
  1010:  98 e0        ldi    r25, 0x08   ; 8
  1012:  c9 9e        mul    r12, r25
  1014:  60 01        movw   r12, r0
  1016:  11 24        eor    r1, r1
  1018:  28 2f        mov    r18, r24
  101a:  30 e0        ldi    r19, 0x00   ; 0
  101c:  55 e0        ldi    r21, 0x05   ; 5
  101e:  35 95        asr    r19
  1020:  27 95        ror    r18
  1022:  5a 95        dec    r21
  1024:  e1 f7        brne   0x101e
  1026:  c2 0e        add    r12, r18
  1028:  d3 1e        adc    r13, r19
  102a:  0d 2c        mov    r0, r13
  102c:  00 0c        add    r0, r0
  102e:  ee 08        sbc    r14, r14
  1030:  ff 08        sbc    r15, r15
  1032:  83 ff        sbrs   r24, 3
  1034:  20 c0        rjmp   0x1076
  1036:  92 e0        ldi    r25, 0x02   ; 2
  1038:  cc 0c        add    r12, r12
  103a:  dd 1c        adc    r13, r13
  103c:  ee 1c        adc    r14, r14
  103e:  ff 1c        adc    r15, r15
  1040:  9a 95        dec    r25
  1042:  d1 f7        brne   0x1038
  1044:  83 70        andi   r24, 0x03
  1046:  c8 0e        add    r12, r24
  1048:  d1 1c        adc    r13, r1
  104a:  e1 1c        adc    r14, r1
  104c:  f1 1c        adc    r15, r1
  104e:  fe 2c        mov    r15, r14
  1050:  ed 2c        mov    r14, r13
  1052:  dc 2c        mov    r13, r12
  1054:  cc 24        eor    r12, r12
  1056:  8b 81        ldd    r24, Y+3
  1058:  c8 0e        add    r12, r24
  105a:  d1 1c        adc    r13, r1
  105c:  e1 1c        adc    r14, r1
  105e:  f1 1c        adc    r15, r1
  1060:  fe 2c        mov    r15, r14
  1062:  ed 2c        mov    r14, r13
  1064:  dc 2c        mov    r13, r12
  1066:  cc 24        eor    r12, r12
  1068:  8c 81        ldd    r24, Y+4
  106a:  c8 0e        add    r12, r24
  106c:  d1 1c        adc    r13, r1
  106e:  e1 1c        adc    r14, r1
  1070:  f1 1c        adc    r15, r1
  1072:  68 94        set    
  1074:  f7 f8        bld    r15, 7
  1076:  8d 81        ldd    r24, Y+5
  1078:  8f 70        andi   r24, 0x0F
  107a:  b8 2e        mov    r11, r24
  107c:  e8 e0        ldi    r30, 0x08   ; 8
  107e:  81 e0        ldi    r24, 0x01   ; 1
  1080:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
  1082:  eb 15        cp     r30, r11
  1084:  28 f1        brcs   0x10d0
  1086:  f8 01        movw   r30, r16
  1088:  eb 5d        subi   r30, 0xDB
  108a:  fe 4f        sbci   r31, 0xFE
  108c:  80 81        ld     r24, Z
  108e:  0e 94 24 07  call   0xe48 <mcp_readRegister>
  1092:  83 ff        sbrs   r24, 3
  1094:  02 c0        rjmp   0x109a
  1096:  68 94        set    
  1098:  f6 f8        bld    r15, 6
  109a:  c0 92 a8 02  sts    0x02A8, r12   ; canMsg.can_id
  109e:  d0 92 a9 02  sts    0x02A9, r13   ; canMsg.can_id +1
  10a2:  e0 92 aa 02  sts    0x02AA, r14   ; canMsg.can_id +2
  10a6:  f0 92 ab 02  sts    0x02AB, r15   ; canMsg.can_id +3
  10aa:  b0 92 ac 02  sts    0x02AC, r11   ; canMsg.can_dlc
  10ae:  0b 5d        subi   r16, 0xDB
  10b0:  1e 4f        sbci   r17, 0xFE
  10b2:  4b 2d        mov    r20, r11
  10b4:  60 eb        ldi    r22, 0xB0   ; 176
  10b6:  72 e0        ldi    r23, 0x02   ; 2  pair r22:r23 = 0x02B0 = 688
  10b8:  f8 01        movw   r30, r16
  10ba:  82 81        ldd    r24, Z+2
  10bc:  0e 94 c4 07  call   0xf88
  10c0:  40 e0        ldi    r20, 0x00   ; 0
  10c2:  f8 01        movw   r30, r16
  10c4:  63 81        ldd    r22, Z+3
  10c6:  8c e2        ldi    r24, 0x2C   ; 44 ','
  10c8:  0e 94 37 07  call   0xe6e <mcp_modifyRegister>
  10cc:  90 e0        ldi    r25, 0x00   ; 0
  10ce:  80 e0        ldi    r24, 0x00   ; 0
  10d0:  0f 90        pop    r0
  10d2:  0f 90        pop    r0
  10d4:  0f 90        pop    r0
  10d6:  0f 90        pop    r0
  10d8:  0f 90        pop    r0
  10da:  df 91        pop    r29
  10dc:  cf 91        pop    r28
  10de:  1f 91        pop    r17
  10e0:  0f 91        pop    r16
  10e2:  ff 90        pop    r15
  10e4:  ef 90        pop    r14
  10e6:  df 90        pop    r13
  10e8:  cf 90        pop    r12
  10ea:  bf 90        pop    r11
  10ec:  08 95        ret    

; ===================== readCAN =====================
  10ee:  cf 93        push   r28
  10f0:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
  10f4:  80 ea        ldi    r24, 0xA0   ; 160
  10f6:  0e 94 a8 02  call   0x550 <SPI_transfer>
  10fa:  80 e0        ldi    r24, 0x00   ; 0
  10fc:  0e 94 a8 02  call   0x550 <SPI_transfer>
  1100:  c8 2f        mov    r28, r24
  1102:  0e 94 0c 01  call   0x218 <mcp_endSPI>
  1106:  90 e0        ldi    r25, 0x00   ; 0
  1108:  80 e0        ldi    r24, 0x00   ; 0
  110a:  c0 fd        sbrc   r28, 0
  110c:  04 c0        rjmp   0x1116
  110e:  c1 ff        sbrs   r28, 1
  1110:  79 c0        rjmp   0x1204
  1112:  81 e0        ldi    r24, 0x01   ; 1
  1114:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
  1116:  0e 94 e9 07  call   0xfd2 <mcp_readMessage_rxb>
  111a:  89 2b        or     r24, r25
  111c:  09 f0        breq   0x1120
  111e:  72 c0        rjmp   0x1204
  1120:  80 91 a8 02  lds    r24, 0x02A8   ; canMsg.can_id
  1124:  90 91 a9 02  lds    r25, 0x02A9   ; canMsg.can_id +1
  1128:  a0 91 aa 02  lds    r26, 0x02AA   ; canMsg.can_id +2
  112c:  b0 91 ab 02  lds    r27, 0x02AB   ; canMsg.can_id +3
  1130:  88 3a        cpi    r24, 0xA8
  1132:  21 e0        ldi    r18, 0x01   ; 1
  1134:  92 07        cpc    r25, r18
  1136:  a1 05        cpc    r26, r1
  1138:  b1 05        cpc    r27, r1
  113a:  09 f0        breq   0x113e
  113c:  50 c0        rjmp   0x11de
  113e:  80 91 ac 02  lds    r24, 0x02AC   ; canMsg.can_dlc
  1142:  82 30        cpi    r24, 0x02
  1144:  40 f0        brcs   0x1156
  1146:  80 91 b4 02  lds    r24, 0x02B4   ; canMsg.data +4
  114a:  90 91 b5 02  lds    r25, 0x02B5   ; canMsg.data +5
  114e:  90 93 e1 01  sts    0x01E1, r25   ; rawVoltage +1
  1152:  80 93 e0 01  sts    0x01E0, r24   ; rawVoltage
  1156:  60 91 e0 01  lds    r22, 0x01E0   ; rawVoltage
  115a:  70 91 e1 01  lds    r23, 0x01E1   ; rawVoltage +1
  115e:  90 e0        ldi    r25, 0x00   ; 0
  1160:  80 e0        ldi    r24, 0x00   ; 0
  1162:  0e 94 00 10  call   0x2000 <__floatunsisf>
  1166:  20 e0        ldi    r18, 0x00   ; 0
  1168:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x0000 = 0
  116a:  4a e7        ldi    r20, 0x7A   ; 122 'z'
  116c:  54 e4        ldi    r21, 0x44   ; 68 'D'  pair r20:r21 = 0x447A = 17530
  116e:  0e 94 5f 0f  call   0x1ebe <__divsf3>
  1172:  60 93 e4 01  sts    0x01E4, r22   ; packVoltage
  1176:  70 93 e5 01  sts    0x01E5, r23   ; packVoltage +1
  117a:  80 93 e6 01  sts    0x01E6, r24   ; packVoltage +2
  117e:  90 93 e7 01  sts    0x01E7, r25   ; packVoltage +3
  1182:  0e 94 7f 06  call   0xcfe <lcd_clear>
  1186:  8f e9        ldi    r24, 0x9F   ; 159
  1188:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x019F = 415  ">Pack_V: "
  118a:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  118e:  60 91 e4 01  lds    r22, 0x01E4   ; packVoltage
  1192:  70 91 e5 01  lds    r23, 0x01E5   ; packVoltage +1
  1196:  80 91 e6 01  lds    r24, 0x01E6   ; packVoltage +2
  119a:  90 91 e7 01  lds    r25, 0x01E7   ; packVoltage +3
  119e:  42 e0        ldi    r20, 0x02   ; 2
  11a0:  0e 94 a1 05  call   0xb42 <lcd_print_float>
  11a4:  89 ea        ldi    r24, 0xA9   ; 169
  11a6:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01A9 = 425  "V"
  11a8:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  11ac:  61 e0        ldi    r22, 0x01   ; 1
  11ae:  80 e0        ldi    r24, 0x00   ; 0
  11b0:  0e 94 6e 05  call   0xadc <lcd_setCursor>
  11b4:  8b ea        ldi    r24, 0xAB   ; 171
  11b6:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01AB = 427  "SOC: "
  11b8:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  11bc:  80 91 e2 01  lds    r24, 0x01E2   ; soc
  11c0:  90 91 e3 01  lds    r25, 0x01E3   ; soc +1
  11c4:  0e 94 45 05  call   0xa8a <lcd_print_int>
  11c8:  81 eb        ldi    r24, 0xB1   ; 177
  11ca:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01B1 = 433  "%"
  11cc:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  11d0:  6a e0        ldi    r22, 0x0A   ; 10
  11d2:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x000A = 10
  11d4:  80 e0        ldi    r24, 0x00   ; 0
  11d6:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  11d8:  cf 91        pop    r28
  11da:  0c 94 67 01  jmp    0x2ce <delay>
  11de:  82 35        cpi    r24, 0x52
  11e0:  93 40        sbci   r25, 0x03
  11e2:  a1 05        cpc    r26, r1
  11e4:  b1 05        cpc    r27, r1
  11e6:  09 f0        breq   0x11ea
  11e8:  b6 cf        rjmp   0x1156
  11ea:  80 91 ac 02  lds    r24, 0x02AC   ; canMsg.can_dlc
  11ee:  82 30        cpi    r24, 0x02
  11f0:  08 f4        brcc   0x11f4
  11f2:  b1 cf        rjmp   0x1156
  11f4:  80 91 b0 02  lds    r24, 0x02B0   ; canMsg.data
  11f8:  90 e0        ldi    r25, 0x00   ; 0
  11fa:  90 93 e3 01  sts    0x01E3, r25   ; soc +1
  11fe:  80 93 e2 01  sts    0x01E2, r24   ; soc
  1202:  a9 cf        rjmp   0x1156
  1204:  0e 94 7f 06  call   0xcfe <lcd_clear>
  1208:  83 eb        ldi    r24, 0xB3   ; 179
  120a:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01B3 = 435  "No_CAN Data"
  120c:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  1210:  6a ef        ldi    r22, 0xFA   ; 250
  1212:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x00FA = 250
  1214:  80 e0        ldi    r24, 0x00   ; 0
  1216:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1218:  0e 94 67 01  call   0x2ce <delay>
  121c:  b2 cf        rjmp   0x1182
  121e:  85 ed        ldi    r24, 0xD5   ; 213
  1220:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
  1224:  80 91 74 02  lds    r24, 0x0274
  1228:  90 91 75 02  lds    r25, 0x0275
  122c:  a0 91 76 02  lds    r26, 0x0276
  1230:  b0 91 77 02  lds    r27, 0x0277
  1234:  07 96        adiw   r24, 0x07
  1236:  a1 1d        adc    r26, r1
  1238:  b1 1d        adc    r27, r1
  123a:  23 e0        ldi    r18, 0x03   ; 3
  123c:  b6 95        lsr    r27
  123e:  a7 95        ror    r26
  1240:  97 95        ror    r25
  1242:  87 95        ror    r24
  1244:  2a 95        dec    r18
  1246:  d1 f7        brne   0x123c
  1248:  20 91 bc 00  lds    r18, 0x00BC   ; TWCR
  124c:  24 fd        sbrc   r18, 4
  124e:  03 c0        rjmp   0x1256
  1250:  10 92 72 02  sts    0x0272, r1
  1254:  08 95        ret    
  1256:  40 91 74 02  lds    r20, 0x0274
  125a:  50 91 75 02  lds    r21, 0x0275
  125e:  60 91 76 02  lds    r22, 0x0276
  1262:  70 91 77 02  lds    r23, 0x0277
  1266:  45 2b        or     r20, r21
  1268:  46 2b        or     r20, r22
  126a:  47 2b        or     r20, r23
  126c:  69 f3        breq   0x1248
  126e:  00 97        sbiw   r24, 0x00
  1270:  a1 05        cpc    r26, r1
  1272:  b1 05        cpc    r27, r1
  1274:  41 f0        breq   0x1286
  1276:  2a e2        ldi    r18, 0x2A   ; 42 '*'
  1278:  2a 95        dec    r18
  127a:  f1 f7        brne   0x1278
  127c:  00 c0        rjmp   0x127e
  127e:  01 97        sbiw   r24, 0x01
  1280:  a1 09        sbc    r26, r1
  1282:  b1 09        sbc    r27, r1
  1284:  e1 cf        rjmp   0x1248
  1286:  80 91 73 02  lds    r24, 0x0273
  128a:  0c 94 2b 03  jmp    0x656

; ===================== sendCAN =====================
  128e:  8f 92        push   r8
  1290:  9f 92        push   r9
  1292:  af 92        push   r10
  1294:  bf 92        push   r11
  1296:  cf 92        push   r12
  1298:  df 92        push   r13
  129a:  ef 92        push   r14
  129c:  ff 92        push   r15
  129e:  0f 93        push   r16
  12a0:  1f 93        push   r17
  12a2:  cf 93        push   r28
  12a4:  df 93        push   r29
  12a6:  cd b7        in     r28, 0x3d   ; SPL
  12a8:  de b7        in     r29, 0x3e   ; SPH
  12aa:  63 97        sbiw   r28, 0x13
  12ac:  0f b6        in     r0, 0x3f   ; SREG
  12ae:  f8 94        cli    
  12b0:  de bf        out    0x3e, r29   ; SPH
  12b2:  0f be        out    0x3f, r0   ; SREG
  12b4:  cd bf        out    0x3d, r28   ; SPL
  12b6:  60 93 a8 02  sts    0x02A8, r22   ; canMsg.can_id
  12ba:  70 93 a9 02  sts    0x02A9, r23   ; canMsg.can_id +1
  12be:  80 93 aa 02  sts    0x02AA, r24   ; canMsg.can_id +2
  12c2:  90 93 ab 02  sts    0x02AB, r25   ; canMsg.can_id +3
  12c6:  88 e0        ldi    r24, 0x08   ; 8
  12c8:  80 93 ac 02  sts    0x02AC, r24   ; canMsg.can_dlc
  12cc:  10 92 b0 02  sts    0x02B0, r1   ; canMsg.data
  12d0:  86 e0        ldi    r24, 0x06   ; 6
  12d2:  ea e0        ldi    r30, 0x0A   ; 10
  12d4:  f1 e0        ldi    r31, 0x01   ; 1  pair r30:r31 = 0x010A = 266
  12d6:  de 01        movw   r26, r28
  12d8:  1e 96        adiw   r26, 0x0e
  12da:  01 90        ld     r0, Z+
  12dc:  0d 92        st     X+, r0
  12de:  8a 95        dec    r24
  12e0:  e1 f7        brne   0x12da
  12e2:  5e 01        movw   r10, r28
  12e4:  8e e0        ldi    r24, 0x0E   ; 14
  12e6:  a8 0e        add    r10, r24
  12e8:  b1 1c        adc    r11, r1
  12ea:  4e 01        movw   r8, r28
  12ec:  e4 e1        ldi    r30, 0x14   ; 20
  12ee:  8e 0e        add    r8, r30
  12f0:  91 1c        adc    r9, r1
  12f2:  f5 01        movw   r30, r10
  12f4:  e1 90        ld     r14, Z+
  12f6:  f1 90        ld     r15, Z+
  12f8:  5f 01        movw   r10, r30
  12fa:  87 01        movw   r16, r14
  12fc:  00 0f        add    r16, r16
  12fe:  11 1f        adc    r17, r17
  1300:  f8 01        movw   r30, r16
  1302:  ee 0d        add    r30, r14
  1304:  ff 1d        adc    r31, r15
  1306:  e4 5e        subi   r30, 0xE4
  1308:  fe 4f        sbci   r31, 0xFE
  130a:  c0 80        ld     r12, Z
  130c:  8c 2d        mov    r24, r12
  130e:  0e 94 24 07  call   0xe48 <mcp_readRegister>
  1312:  83 fd        sbrc   r24, 3
  1314:  8c c0        rjmp   0x142e
  1316:  d0 90 ac 02  lds    r13, 0x02AC   ; canMsg.can_dlc
  131a:  f8 e0        ldi    r31, 0x08   ; 8
  131c:  fd 15        cp     r31, r13
  131e:  08 f4        brcc   0x1322
  1320:  65 c0        rjmp   0x13ec
  1322:  80 91 a8 02  lds    r24, 0x02A8   ; canMsg.can_id
  1326:  90 91 a9 02  lds    r25, 0x02A9   ; canMsg.can_id +1
  132a:  a0 91 aa 02  lds    r26, 0x02AA   ; canMsg.can_id +2
  132e:  b0 91 ab 02  lds    r27, 0x02AB   ; canMsg.can_id +3
  1332:  ac 01        movw   r20, r24
  1334:  bd 01        movw   r22, r26
  1336:  44 27        eor    r20, r20
  1338:  77 fd        sbrc   r23, 7
  133a:  43 95        inc    r20
  133c:  55 27        eor    r21, r21
  133e:  66 27        eor    r22, r22
  1340:  77 27        eor    r23, r23
  1342:  24 2f        mov    r18, r20
  1344:  ac 01        movw   r20, r24
  1346:  bd 01        movw   r22, r26
  1348:  44 27        eor    r20, r20
  134a:  55 27        eor    r21, r21
  134c:  66 27        eor    r22, r22
  134e:  70 74        andi   r23, 0x40
  1350:  88 24        eor    r8, r8
  1352:  8a 94        dec    r8
  1354:  98 2c        mov    r9, r8
  1356:  a8 2c        mov    r10, r8
  1358:  ff e1        ldi    r31, 0x1F   ; 31
  135a:  bf 2e        mov    r11, r31
  135c:  21 11        cpse   r18, r1
  135e:  06 c0        rjmp   0x136c
  1360:  88 24        eor    r8, r8
  1362:  8a 94        dec    r8
  1364:  e7 e0        ldi    r30, 0x07   ; 7
  1366:  9e 2e        mov    r9, r30
  1368:  a1 2c        mov    r10, r1
  136a:  b1 2c        mov    r11, r1
  136c:  88 21        and    r24, r8
  136e:  99 21        and    r25, r9
  1370:  aa 21        and    r26, r10
  1372:  bb 21        and    r27, r11
  1374:  22 23        and    r18, r18
  1376:  09 f4        brne   0x137a
  1378:  4c c0        rjmp   0x1412
  137a:  8c 83        std    Y+4, r24
  137c:  9b 83        std    Y+3, r25
  137e:  cd 01        movw   r24, r26
  1380:  aa 27        eor    r26, r26
  1382:  bb 27        eor    r27, r27
  1384:  28 2f        mov    r18, r24
  1386:  22 0f        add    r18, r18
  1388:  22 0f        add    r18, r18
  138a:  22 0f        add    r18, r18
  138c:  20 7e        andi   r18, 0xE0
  138e:  38 2f        mov    r19, r24
  1390:  33 70        andi   r19, 0x03
  1392:  38 60        ori    r19, 0x08
  1394:  23 2b        or     r18, r19
  1396:  2a 83        std    Y+2, r18
  1398:  35 e0        ldi    r19, 0x05   ; 5
  139a:  96 95        lsr    r25
  139c:  87 95        ror    r24
  139e:  3a 95        dec    r19
  13a0:  e1 f7        brne   0x139a
  13a2:  89 83        std    Y+1, r24
  13a4:  8d 2d        mov    r24, r13
  13a6:  45 2b        or     r20, r21
  13a8:  46 2b        or     r20, r22
  13aa:  47 2b        or     r20, r23
  13ac:  09 f0        breq   0x13b0
  13ae:  80 64        ori    r24, 0x40
  13b0:  8d 83        std    Y+5, r24
  13b2:  4d 2d        mov    r20, r13
  13b4:  50 e0        ldi    r21, 0x00   ; 0
  13b6:  60 eb        ldi    r22, 0xB0   ; 176
  13b8:  72 e0        ldi    r23, 0x02   ; 2  pair r22:r23 = 0x02B0 = 688
  13ba:  ce 01        movw   r24, r28
  13bc:  06 96        adiw   r24, 0x06
  13be:  0e 94 51 11  call   0x22a2
  13c2:  45 e0        ldi    r20, 0x05   ; 5
  13c4:  4d 0d        add    r20, r13
  13c6:  0e 0d        add    r16, r14
  13c8:  1f 1d        adc    r17, r15
  13ca:  f8 01        movw   r30, r16
  13cc:  e4 5e        subi   r30, 0xE4
  13ce:  fe 4f        sbci   r31, 0xFE
  13d0:  be 01        movw   r22, r28
  13d2:  6f 5f        subi   r22, 0xFF
  13d4:  7f 4f        sbci   r23, 0xFF
  13d6:  81 81        ldd    r24, Z+1
  13d8:  0e 94 a0 07  call   0xf40 <mcp_setRegisters>
  13dc:  48 e0        ldi    r20, 0x08   ; 8
  13de:  68 e0        ldi    r22, 0x08   ; 8
  13e0:  8c 2d        mov    r24, r12
  13e2:  0e 94 37 07  call   0xe6e <mcp_modifyRegister>
  13e6:  8c 2d        mov    r24, r12
  13e8:  0e 94 24 07  call   0xe48 <mcp_readRegister>
  13ec:  63 96        adiw   r28, 0x13
  13ee:  0f b6        in     r0, 0x3f   ; SREG
  13f0:  f8 94        cli    
  13f2:  de bf        out    0x3e, r29   ; SPH
  13f4:  0f be        out    0x3f, r0   ; SREG
  13f6:  cd bf        out    0x3d, r28   ; SPL
  13f8:  df 91        pop    r29
  13fa:  cf 91        pop    r28
  13fc:  1f 91        pop    r17
  13fe:  0f 91        pop    r16
  1400:  ff 90        pop    r15
  1402:  ef 90        pop    r14
  1404:  df 90        pop    r13
  1406:  cf 90        pop    r12
  1408:  bf 90        pop    r11
  140a:  af 90        pop    r10
  140c:  9f 90        pop    r9
  140e:  8f 90        pop    r8
  1410:  08 95        ret    
  1412:  9c 01        movw   r18, r24
  1414:  93 e0        ldi    r25, 0x03   ; 3
  1416:  36 95        lsr    r19
  1418:  27 95        ror    r18
  141a:  9a 95        dec    r25
  141c:  e1 f7        brne   0x1416
  141e:  29 83        std    Y+1, r18
  1420:  82 95        swap   r24
  1422:  88 0f        add    r24, r24
  1424:  80 7e        andi   r24, 0xE0
  1426:  8a 83        std    Y+2, r24
  1428:  1c 82        std    Y+4, r1
  142a:  1b 82        std    Y+3, r1
  142c:  bb cf        rjmp   0x13a4
  142e:  a8 14        cp     r10, r8
  1430:  b9 04        cpc    r11, r9
  1432:  09 f0        breq   0x1436
  1434:  5e cf        rjmp   0x12f2
  1436:  da cf        rjmp   0x13ec

; ===================== ISR_TIMER0_OVF =====================
  1438:  1f 92        push   r1
  143a:  0f 92        push   r0
  143c:  0f b6        in     r0, 0x3f   ; SREG
  143e:  0f 92        push   r0
  1440:  11 24        eor    r1, r1
  1442:  2f 93        push   r18
  1444:  3f 93        push   r19
  1446:  8f 93        push   r24
  1448:  9f 93        push   r25
  144a:  af 93        push   r26
  144c:  bf 93        push   r27
  144e:  80 91 b8 02  lds    r24, 0x02B8
  1452:  90 91 b9 02  lds    r25, 0x02B9
  1456:  a0 91 ba 02  lds    r26, 0x02BA
  145a:  b0 91 bb 02  lds    r27, 0x02BB
  145e:  30 91 a3 02  lds    r19, 0x02A3
  1462:  23 e0        ldi    r18, 0x03   ; 3
  1464:  23 0f        add    r18, r19
  1466:  2d 37        cpi    r18, 0x7D
  1468:  58 f5        brcc   0x14c0
  146a:  01 96        adiw   r24, 0x01
  146c:  a1 1d        adc    r26, r1
  146e:  b1 1d        adc    r27, r1
  1470:  20 93 a3 02  sts    0x02A3, r18
  1474:  80 93 b8 02  sts    0x02B8, r24
  1478:  90 93 b9 02  sts    0x02B9, r25
  147c:  a0 93 ba 02  sts    0x02BA, r26
  1480:  b0 93 bb 02  sts    0x02BB, r27
  1484:  80 91 a4 02  lds    r24, 0x02A4
  1488:  90 91 a5 02  lds    r25, 0x02A5
  148c:  a0 91 a6 02  lds    r26, 0x02A6
  1490:  b0 91 a7 02  lds    r27, 0x02A7
  1494:  01 96        adiw   r24, 0x01
  1496:  a1 1d        adc    r26, r1
  1498:  b1 1d        adc    r27, r1
  149a:  80 93 a4 02  sts    0x02A4, r24
  149e:  90 93 a5 02  sts    0x02A5, r25
  14a2:  a0 93 a6 02  sts    0x02A6, r26
  14a6:  b0 93 a7 02  sts    0x02A7, r27
  14aa:  bf 91        pop    r27
  14ac:  af 91        pop    r26
  14ae:  9f 91        pop    r25
  14b0:  8f 91        pop    r24
  14b2:  3f 91        pop    r19
  14b4:  2f 91        pop    r18
  14b6:  0f 90        pop    r0
  14b8:  0f be        out    0x3f, r0   ; SREG
  14ba:  0f 90        pop    r0
  14bc:  1f 90        pop    r1
  14be:  18 95        reti   
  14c0:  26 e8        ldi    r18, 0x86   ; 134
  14c2:  23 0f        add    r18, r19
  14c4:  02 96        adiw   r24, 0x02
  14c6:  a1 1d        adc    r26, r1
  14c8:  b1 1d        adc    r27, r1
  14ca:  d2 cf        rjmp   0x1470

; ===================== ISR_USART_UDRE =====================
  14cc:  1f 92        push   r1
  14ce:  0f 92        push   r0
  14d0:  0f b6        in     r0, 0x3f   ; SREG
  14d2:  0f 92        push   r0
  14d4:  11 24        eor    r1, r1
  14d6:  2f 93        push   r18
  14d8:  3f 93        push   r19
  14da:  4f 93        push   r20
  14dc:  5f 93        push   r21
  14de:  6f 93        push   r22
  14e0:  7f 93        push   r23
  14e2:  8f 93        push   r24
  14e4:  9f 93        push   r25
  14e6:  af 93        push   r26
  14e8:  bf 93        push   r27
  14ea:  ef 93        push   r30
  14ec:  ff 93        push   r31
  14ee:  8c eb        ldi    r24, 0xBC   ; 188
  14f0:  92 e0        ldi    r25, 0x02   ; 2  pair r24:r25 = 0x02BC = 700
  14f2:  0e 94 19 02  call   0x432
  14f6:  ff 91        pop    r31
  14f8:  ef 91        pop    r30
  14fa:  bf 91        pop    r27
  14fc:  af 91        pop    r26
  14fe:  9f 91        pop    r25
  1500:  8f 91        pop    r24
  1502:  7f 91        pop    r23
  1504:  6f 91        pop    r22
  1506:  5f 91        pop    r21
  1508:  4f 91        pop    r20
  150a:  3f 91        pop    r19
  150c:  2f 91        pop    r18
  150e:  0f 90        pop    r0
  1510:  0f be        out    0x3f, r0   ; SREG
  1512:  0f 90        pop    r0
  1514:  1f 90        pop    r1
  1516:  18 95        reti   

; ===================== ISR_USART_RX =====================
  1518:  1f 92        push   r1
  151a:  0f 92        push   r0
  151c:  0f b6        in     r0, 0x3f   ; SREG
  151e:  0f 92        push   r0
  1520:  11 24        eor    r1, r1
  1522:  2f 93        push   r18
  1524:  8f 93        push   r24
  1526:  9f 93        push   r25
  1528:  ef 93        push   r30
  152a:  ff 93        push   r31
  152c:  e0 91 cc 02  lds    r30, 0x02CC
  1530:  f0 91 cd 02  lds    r31, 0x02CD
  1534:  80 81        ld     r24, Z
  1536:  e0 91 d2 02  lds    r30, 0x02D2
  153a:  f0 91 d3 02  lds    r31, 0x02D3
  153e:  82 fd        sbrc   r24, 2
  1540:  1b c0        rjmp   0x1578
  1542:  90 81        ld     r25, Z
  1544:  80 91 d5 02  lds    r24, 0x02D5
  1548:  8f 5f        subi   r24, 0xFF
  154a:  8f 73        andi   r24, 0x3F
  154c:  20 91 d6 02  lds    r18, 0x02D6
  1550:  82 17        cp     r24, r18
  1552:  41 f0        breq   0x1564
  1554:  e0 91 d5 02  lds    r30, 0x02D5
  1558:  f0 e0        ldi    r31, 0x00   ; 0
  155a:  e4 54        subi   r30, 0x44
  155c:  fd 4f        sbci   r31, 0xFD
  155e:  95 8f        std    Z+29, r25
  1560:  80 93 d5 02  sts    0x02D5, r24
  1564:  ff 91        pop    r31
  1566:  ef 91        pop    r30
  1568:  9f 91        pop    r25
  156a:  8f 91        pop    r24
  156c:  2f 91        pop    r18
  156e:  0f 90        pop    r0
  1570:  0f be        out    0x3f, r0   ; SREG
  1572:  0f 90        pop    r0
  1574:  1f 90        pop    r1
  1576:  18 95        reti   
  1578:  80 81        ld     r24, Z
  157a:  f4 cf        rjmp   0x1564

; ===================== ISR_TWI =====================
  157c:  1f 92        push   r1
  157e:  0f 92        push   r0
  1580:  0f b6        in     r0, 0x3f   ; SREG
  1582:  0f 92        push   r0
  1584:  11 24        eor    r1, r1
  1586:  2f 93        push   r18
  1588:  3f 93        push   r19
  158a:  4f 93        push   r20
  158c:  5f 93        push   r21
  158e:  6f 93        push   r22
  1590:  7f 93        push   r23
  1592:  8f 93        push   r24
  1594:  9f 93        push   r25
  1596:  af 93        push   r26
  1598:  bf 93        push   r27
  159a:  ef 93        push   r30
  159c:  ff 93        push   r31
  159e:  80 91 b9 00  lds    r24, 0x00B9   ; TWSR
  15a2:  88 7f        andi   r24, 0xF8
  15a4:  80 36        cpi    r24, 0x60
  15a6:  09 f4        brne   0x15aa
  15a8:  4a c0        rjmp   0x163e
  15aa:  f0 f5        brcc   0x1628
  15ac:  88 32        cpi    r24, 0x28
  15ae:  09 f4        brne   0x15b2
  15b0:  a7 c0        rjmp   0x1700
  15b2:  18 f5        brcc   0x15fa
  15b4:  80 31        cpi    r24, 0x10
  15b6:  09 f4        brne   0x15ba
  15b8:  9b c0        rjmp   0x16f0
  15ba:  b8 f4        brcc   0x15ea
  15bc:  88 23        and    r24, r24
  15be:  09 f4        brne   0x15c2
  15c0:  f9 c0        rjmp   0x17b4
  15c2:  88 30        cpi    r24, 0x08
  15c4:  09 f4        brne   0x15c8
  15c6:  94 c0        rjmp   0x16f0
  15c8:  ff 91        pop    r31
  15ca:  ef 91        pop    r30
  15cc:  bf 91        pop    r27
  15ce:  af 91        pop    r26
  15d0:  9f 91        pop    r25
  15d2:  8f 91        pop    r24
  15d4:  7f 91        pop    r23
  15d6:  6f 91        pop    r22
  15d8:  5f 91        pop    r21
  15da:  4f 91        pop    r20
  15dc:  3f 91        pop    r19
  15de:  2f 91        pop    r18
  15e0:  0f 90        pop    r0
  15e2:  0f be        out    0x3f, r0   ; SREG
  15e4:  0f 90        pop    r0
  15e6:  1f 90        pop    r1
  15e8:  18 95        reti   
  15ea:  88 31        cpi    r24, 0x18
  15ec:  09 f4        brne   0x15f0
  15ee:  88 c0        rjmp   0x1700
  15f0:  80 32        cpi    r24, 0x20
  15f2:  51 f7        brne   0x15c8
  15f4:  80 93 70 02  sts    0x0270, r24
  15f8:  14 c0        rjmp   0x1622
  15fa:  80 34        cpi    r24, 0x40
  15fc:  09 f4        brne   0x1600
  15fe:  9d c0        rjmp   0x173a
  1600:  40 f4        brcc   0x1612
  1602:  80 33        cpi    r24, 0x30
  1604:  b9 f3        breq   0x15f4
  1606:  88 33        cpi    r24, 0x38
  1608:  f9 f6        brne   0x15c8
  160a:  80 93 70 02  sts    0x0270, r24
  160e:  85 ec        ldi    r24, 0xC5   ; 197
  1610:  b0 c0        rjmp   0x1772
  1612:  80 35        cpi    r24, 0x50
  1614:  09 f4        brne   0x1618
  1616:  85 c0        rjmp   0x1722
  1618:  88 35        cpi    r24, 0x58
  161a:  09 f4        brne   0x161e
  161c:  96 c0        rjmp   0x174a
  161e:  88 34        cpi    r24, 0x48
  1620:  99 f6        brne   0x15c8
  1622:  0e 94 0f 09  call   0x121e
  1626:  d0 cf        rjmp   0x15c8
  1628:  88 39        cpi    r24, 0x98
  162a:  09 f4        brne   0x162e
  162c:  8c c0        rjmp   0x1746
  162e:  38 f5        brcc   0x167e
  1630:  88 37        cpi    r24, 0x78
  1632:  29 f0        breq   0x163e
  1634:  50 f4        brcc   0x164a
  1636:  88 36        cpi    r24, 0x68
  1638:  11 f0        breq   0x163e
  163a:  80 37        cpi    r24, 0x70
  163c:  29 f6        brne   0x15c8
  163e:  83 e0        ldi    r24, 0x03   ; 3
  1640:  80 93 72 02  sts    0x0272, r24
  1644:  10 92 4b 02  sts    0x024B, r1
  1648:  57 c0        rjmp   0x16f8
  164a:  88 38        cpi    r24, 0x88
  164c:  09 f4        brne   0x1650
  164e:  7b c0        rjmp   0x1746
  1650:  80 39        cpi    r24, 0x90
  1652:  19 f0        breq   0x165a
  1654:  80 38        cpi    r24, 0x80
  1656:  09 f0        breq   0x165a
  1658:  b7 cf        rjmp   0x15c8
  165a:  80 91 4b 02  lds    r24, 0x024B
  165e:  80 32        cpi    r24, 0x20
  1660:  08 f0        brcs   0x1664
  1662:  71 c0        rjmp   0x1746
  1664:  e0 91 4b 02  lds    r30, 0x024B
  1668:  81 e0        ldi    r24, 0x01   ; 1
  166a:  8e 0f        add    r24, r30
  166c:  80 93 4b 02  sts    0x024B, r24
  1670:  80 91 bb 00  lds    r24, 0x00BB   ; TWDR
  1674:  f0 e0        ldi    r31, 0x00   ; 0
  1676:  e5 5d        subi   r30, 0xD5
  1678:  fd 4f        sbci   r31, 0xFD
  167a:  80 83        st     Z, r24
  167c:  3d c0        rjmp   0x16f8
  167e:  80 3b        cpi    r24, 0xB0
  1680:  39 f0        breq   0x1690
  1682:  e0 f4        brcc   0x16bc
  1684:  80 3a        cpi    r24, 0xA0
  1686:  09 f4        brne   0x168a
  1688:  79 c0        rjmp   0x177c
  168a:  88 3a        cpi    r24, 0xA8
  168c:  09 f0        breq   0x1690
  168e:  9c cf        rjmp   0x15c8
  1690:  84 e0        ldi    r24, 0x04   ; 4
  1692:  80 93 72 02  sts    0x0272, r24
  1696:  10 92 2a 02  sts    0x022A, r1
  169a:  10 92 29 02  sts    0x0229, r1
  169e:  e0 91 9d 02  lds    r30, 0x029D
  16a2:  f0 91 9e 02  lds    r31, 0x029E
  16a6:  09 95        icall  
  16a8:  80 91 29 02  lds    r24, 0x0229
  16ac:  81 11        cpse   r24, r1
  16ae:  0f c0        rjmp   0x16ce
  16b0:  81 e0        ldi    r24, 0x01   ; 1
  16b2:  80 93 29 02  sts    0x0229, r24
  16b6:  10 92 09 02  sts    0x0209, r1
  16ba:  09 c0        rjmp   0x16ce
  16bc:  80 3c        cpi    r24, 0xC0
  16be:  09 f4        brne   0x16c2
  16c0:  a6 cf        rjmp   0x160e
  16c2:  88 3c        cpi    r24, 0xC8
  16c4:  09 f4        brne   0x16c8
  16c6:  a3 cf        rjmp   0x160e
  16c8:  88 3b        cpi    r24, 0xB8
  16ca:  09 f0        breq   0x16ce
  16cc:  7d cf        rjmp   0x15c8
  16ce:  e0 91 2a 02  lds    r30, 0x022A
  16d2:  81 e0        ldi    r24, 0x01   ; 1
  16d4:  8e 0f        add    r24, r30
  16d6:  80 93 2a 02  sts    0x022A, r24
  16da:  f0 e0        ldi    r31, 0x00   ; 0
  16dc:  e7 5f        subi   r30, 0xF7
  16de:  fd 4f        sbci   r31, 0xFD
  16e0:  80 81        ld     r24, Z
  16e2:  80 93 bb 00  sts    0x00BB, r24   ; TWDR
  16e6:  90 91 2a 02  lds    r25, 0x022A
  16ea:  80 91 29 02  lds    r24, 0x0229
  16ee:  29 c0        rjmp   0x1742
  16f0:  80 91 4d 02  lds    r24, 0x024D
  16f4:  80 93 bb 00  sts    0x00BB, r24   ; TWDR
  16f8:  85 ec        ldi    r24, 0xC5   ; 197
  16fa:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
  16fe:  64 cf        rjmp   0x15c8
  1700:  90 91 6f 02  lds    r25, 0x026F
  1704:  80 91 6e 02  lds    r24, 0x026E
  1708:  98 17        cp     r25, r24
  170a:  58 f5        brcc   0x1762
  170c:  e0 91 6f 02  lds    r30, 0x026F
  1710:  81 e0        ldi    r24, 0x01   ; 1
  1712:  8e 0f        add    r24, r30
  1714:  80 93 6f 02  sts    0x026F, r24
  1718:  f0 e0        ldi    r31, 0x00   ; 0
  171a:  e2 5b        subi   r30, 0xB2
  171c:  fd 4f        sbci   r31, 0xFD
  171e:  80 81        ld     r24, Z
  1720:  e9 cf        rjmp   0x16f4
  1722:  e0 91 6f 02  lds    r30, 0x026F
  1726:  81 e0        ldi    r24, 0x01   ; 1
  1728:  8e 0f        add    r24, r30
  172a:  80 93 6f 02  sts    0x026F, r24
  172e:  80 91 bb 00  lds    r24, 0x00BB   ; TWDR
  1732:  f0 e0        ldi    r31, 0x00   ; 0
  1734:  e2 5b        subi   r30, 0xB2
  1736:  fd 4f        sbci   r31, 0xFD
  1738:  80 83        st     Z, r24
  173a:  90 91 6f 02  lds    r25, 0x026F
  173e:  80 91 6e 02  lds    r24, 0x026E
  1742:  98 17        cp     r25, r24
  1744:  c8 f2        brcs   0x16f8
  1746:  85 e8        ldi    r24, 0x85   ; 133
  1748:  d8 cf        rjmp   0x16fa
  174a:  e0 91 6f 02  lds    r30, 0x026F
  174e:  81 e0        ldi    r24, 0x01   ; 1
  1750:  8e 0f        add    r24, r30
  1752:  80 93 6f 02  sts    0x026F, r24
  1756:  80 91 bb 00  lds    r24, 0x00BB   ; TWDR
  175a:  f0 e0        ldi    r31, 0x00   ; 0
  175c:  e2 5b        subi   r30, 0xB2
  175e:  fd 4f        sbci   r31, 0xFD
  1760:  80 83        st     Z, r24
  1762:  80 91 71 02  lds    r24, 0x0271
  1766:  81 11        cpse   r24, r1
  1768:  5c cf        rjmp   0x1622
  176a:  81 e0        ldi    r24, 0x01   ; 1
  176c:  80 93 4c 02  sts    0x024C, r24
  1770:  84 ea        ldi    r24, 0xA4   ; 164
  1772:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
  1776:  10 92 72 02  sts    0x0272, r1
  177a:  26 cf        rjmp   0x15c8
  177c:  85 ec        ldi    r24, 0xC5   ; 197
  177e:  80 93 bc 00  sts    0x00BC, r24   ; TWCR
  1782:  10 92 72 02  sts    0x0272, r1
  1786:  80 91 4b 02  lds    r24, 0x024B
  178a:  80 32        cpi    r24, 0x20
  178c:  30 f4        brcc   0x179a
  178e:  e0 91 4b 02  lds    r30, 0x024B
  1792:  f0 e0        ldi    r31, 0x00   ; 0
  1794:  e5 5d        subi   r30, 0xD5
  1796:  fd 4f        sbci   r31, 0xFD
  1798:  10 82        st     Z, r1
  179a:  60 91 4b 02  lds    r22, 0x024B
  179e:  70 e0        ldi    r23, 0x00   ; 0
  17a0:  e0 91 9b 02  lds    r30, 0x029B
  17a4:  f0 91 9c 02  lds    r31, 0x029C
  17a8:  8b e2        ldi    r24, 0x2B   ; 43 '+'
  17aa:  92 e0        ldi    r25, 0x02   ; 2  pair r24:r25 = 0x022B = 555
  17ac:  09 95        icall  
  17ae:  10 92 4b 02  sts    0x024B, r1
  17b2:  0a cf        rjmp   0x15c8
  17b4:  10 92 70 02  sts    0x0270, r1
  17b8:  34 cf        rjmp   0x1622

; ===================== global_constructors =====================
  17ba:  cf 93        push   r28
  17bc:  df 93        push   r29
  17be:  ec eb        ldi    r30, 0xBC   ; 188
  17c0:  f2 e0        ldi    r31, 0x02   ; 2  pair r30:r31 = 0x02BC = 700
  17c2:  13 82        std    Z+3, r1
  17c4:  12 82        std    Z+2, r1
  17c6:  88 ee        ldi    r24, 0xE8   ; 232
  17c8:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x03E8 = 1000
  17ca:  a0 e0        ldi    r26, 0x00   ; 0
  17cc:  b0 e0        ldi    r27, 0x00   ; 0  pair r26:r27 = 0x0000 = 0
  17ce:  84 83        std    Z+4, r24
  17d0:  95 83        std    Z+5, r25
  17d2:  a6 83        std    Z+6, r26
  17d4:  b7 83        std    Z+7, r27
  17d6:  21 e3        ldi    r18, 0x31   ; 49 '1'
  17d8:  31 e0        ldi    r19, 0x01   ; 1  pair r18:r19 = 0x0131 = 305
  17da:  31 83        std    Z+1, r19
  17dc:  20 83        st     Z, r18
  17de:  25 ec        ldi    r18, 0xC5   ; 197
  17e0:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x00C5 = 197
  17e2:  35 87        std    Z+13, r19
  17e4:  24 87        std    Z+12, r18
  17e6:  24 ec        ldi    r18, 0xC4   ; 196
  17e8:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x00C4 = 196
  17ea:  37 87        std    Z+15, r19
  17ec:  26 87        std    Z+14, r18
  17ee:  20 ec        ldi    r18, 0xC0   ; 192
  17f0:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x00C0 = 192
  17f2:  31 8b        std    Z+17, r19
  17f4:  20 8b        std    Z+16, r18
  17f6:  21 ec        ldi    r18, 0xC1   ; 193
  17f8:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x00C1 = 193
  17fa:  33 8b        std    Z+19, r19
  17fc:  22 8b        std    Z+18, r18
  17fe:  22 ec        ldi    r18, 0xC2   ; 194
  1800:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x00C2 = 194
  1802:  35 8b        std    Z+21, r19
  1804:  24 8b        std    Z+20, r18
  1806:  26 ec        ldi    r18, 0xC6   ; 198
  1808:  30 e0        ldi    r19, 0x00   ; 0  pair r18:r19 = 0x00C6 = 198
  180a:  37 8b        std    Z+23, r19
  180c:  26 8b        std    Z+22, r18
  180e:  11 8e        std    Z+25, r1
  1810:  12 8e        std    Z+26, r1
  1812:  13 8e        std    Z+27, r1
  1814:  14 8e        std    Z+28, r1
  1816:  e9 e5        ldi    r30, 0x59   ; 89 'Y'
  1818:  f3 e0        ldi    r31, 0x03   ; 3  pair r30:r31 = 0x0359 = 857
  181a:  13 82        std    Z+3, r1
  181c:  12 82        std    Z+2, r1
  181e:  84 83        std    Z+4, r24
  1820:  95 83        std    Z+5, r25
  1822:  a6 83        std    Z+6, r26
  1824:  b7 83        std    Z+7, r27
  1826:  83 e4        ldi    r24, 0x43   ; 67 'C'
  1828:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0143 = 323
  182a:  91 83        std    Z+1, r25
  182c:  80 83        st     Z, r24
  182e:  ed e6        ldi    r30, 0x6D   ; 109 'm'
  1830:  f3 e0        ldi    r31, 0x03   ; 3  pair r30:r31 = 0x036D = 877
  1832:  13 82        std    Z+3, r1
  1834:  12 82        std    Z+2, r1
  1836:  85 e5        ldi    r24, 0x55   ; 85 'U'
  1838:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0155 = 341
  183a:  91 83        std    Z+1, r25
  183c:  80 83        st     Z, r24
  183e:  87 e2        ldi    r24, 0x27   ; 39 '''
  1840:  84 83        std    Z+4, r24
  1842:  80 e1        ldi    r24, 0x10   ; 16
  1844:  80 87        std    Z+8, r24
  1846:  82 e0        ldi    r24, 0x02   ; 2
  1848:  81 87        std    Z+9, r24
  184a:  12 86        std    Z+10, r1
  184c:  88 e0        ldi    r24, 0x08   ; 8
  184e:  83 87        std    Z+11, r24
  1850:  c6 e6        ldi    r28, 0x66   ; 102 'f'
  1852:  d3 e0        ldi    r29, 0x03   ; 3  pair r28:r29 = 0x0366 = 870
  1854:  85 e6        ldi    r24, 0x65   ; 101 'e'
  1856:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x0365 = 869
  1858:  9e 83        std    Y+6, r25
  185a:  8d 83        std    Y+5, r24
  185c:  0e 94 af 02  call   0x55e <SPI_begin>
  1860:  8a e0        ldi    r24, 0x0A   ; 10
  1862:  88 83        st     Y, r24
  1864:  80 e8        ldi    r24, 0x80   ; 128
  1866:  96 e9        ldi    r25, 0x96   ; 150  pair r24:r25 = 0x9680 = 38528
  1868:  a8 e9        ldi    r26, 0x98   ; 152
  186a:  b0 e0        ldi    r27, 0x00   ; 0  pair r26:r27 = 0x0098 = 152
  186c:  89 83        std    Y+1, r24
  186e:  9a 83        std    Y+2, r25
  1870:  ab 83        std    Y+3, r26
  1872:  bc 83        std    Y+4, r27
  1874:  61 e0        ldi    r22, 0x01   ; 1
  1876:  8a e0        ldi    r24, 0x0A   ; 10
  1878:  0e 94 11 01  call   0x222 <pinMode>
  187c:  61 e0        ldi    r22, 0x01   ; 1
  187e:  88 81        ld     r24, Y
  1880:  df 91        pop    r29
  1882:  cf 91        pop    r28
  1884:  0c 94 de 00  jmp    0x1bc <digitalWrite>

; ===================== main =====================
  1888:  cf 93        push   r28
  188a:  df 93        push   r29
  188c:  cd b7        in     r28, 0x3d   ; SPL
  188e:  de b7        in     r29, 0x3e   ; SPH
  1890:  a2 97        sbiw   r28, 0x22
  1892:  0f b6        in     r0, 0x3f   ; SREG
  1894:  f8 94        cli    
  1896:  de bf        out    0x3e, r29   ; SPH
  1898:  0f be        out    0x3f, r0   ; SREG
  189a:  cd bf        out    0x3d, r28   ; SPL
  189c:  78 94        sei    
  189e:  84 b5        in     r24, 0x24   ; TCCR0A
  18a0:  82 60        ori    r24, 0x02
  18a2:  84 bd        out    0x24, r24   ; TCCR0A
  18a4:  84 b5        in     r24, 0x24   ; TCCR0A
  18a6:  81 60        ori    r24, 0x01
  18a8:  84 bd        out    0x24, r24   ; TCCR0A
  18aa:  85 b5        in     r24, 0x25   ; TCCR0B
  18ac:  82 60        ori    r24, 0x02
  18ae:  85 bd        out    0x25, r24   ; TCCR0B
  18b0:  85 b5        in     r24, 0x25   ; TCCR0B
  18b2:  81 60        ori    r24, 0x01
  18b4:  85 bd        out    0x25, r24   ; TCCR0B
  18b6:  80 91 6e 00  lds    r24, 0x006E   ; TIMSK0
  18ba:  81 60        ori    r24, 0x01
  18bc:  80 93 6e 00  sts    0x006E, r24   ; TIMSK0
  18c0:  10 92 81 00  sts    0x0081, r1   ; TCCR1B
  18c4:  80 91 81 00  lds    r24, 0x0081   ; TCCR1B
  18c8:  82 60        ori    r24, 0x02
  18ca:  80 93 81 00  sts    0x0081, r24   ; TCCR1B
  18ce:  80 91 81 00  lds    r24, 0x0081   ; TCCR1B
  18d2:  81 60        ori    r24, 0x01
  18d4:  80 93 81 00  sts    0x0081, r24   ; TCCR1B
  18d8:  80 91 80 00  lds    r24, 0x0080   ; TCCR1A
  18dc:  81 60        ori    r24, 0x01
  18de:  80 93 80 00  sts    0x0080, r24   ; TCCR1A
  18e2:  80 91 b1 00  lds    r24, 0x00B1   ; TCCR2B
  18e6:  84 60        ori    r24, 0x04
  18e8:  80 93 b1 00  sts    0x00B1, r24   ; TCCR2B
  18ec:  80 91 b0 00  lds    r24, 0x00B0   ; TCCR2A
  18f0:  81 60        ori    r24, 0x01
  18f2:  80 93 b0 00  sts    0x00B0, r24   ; TCCR2A
  18f6:  80 91 7a 00  lds    r24, 0x007A   ; ADCSRA
  18fa:  84 60        ori    r24, 0x04
  18fc:  80 93 7a 00  sts    0x007A, r24   ; ADCSRA
  1900:  80 91 7a 00  lds    r24, 0x007A   ; ADCSRA
  1904:  82 60        ori    r24, 0x02
  1906:  80 93 7a 00  sts    0x007A, r24   ; ADCSRA
  190a:  80 91 7a 00  lds    r24, 0x007A   ; ADCSRA
  190e:  81 60        ori    r24, 0x01
  1910:  80 93 7a 00  sts    0x007A, r24   ; ADCSRA
  1914:  80 91 7a 00  lds    r24, 0x007A   ; ADCSRA
  1918:  80 68        ori    r24, 0x80
  191a:  80 93 7a 00  sts    0x007A, r24   ; ADCSRA
  191e:  10 92 c1 00  sts    0x00C1, r1   ; UCSR0B
  1922:  10 92 a2 02  sts    0x02A2, r1
  1926:  10 92 a1 02  sts    0x02A1, r1
  192a:  10 92 a0 02  sts    0x02A0, r1
  192e:  10 92 9f 02  sts    0x029F, r1
  1932:  0e 94 0d 03  call   0x61a <Wire_begin>
  1936:  89 e9        ldi    r24, 0x99   ; 153
  1938:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x0199 = 409  "t S1X"
  193a:  90 93 9e 02  sts    0x029E, r25
  193e:  80 93 9d 02  sts    0x029D, r24
  1942:  8a e9        ldi    r24, 0x9A   ; 154
  1944:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x019A = 410  " S1X"
  1946:  90 93 9c 02  sts    0x029C, r25
  194a:  80 93 9b 02  sts    0x029B, r24
  194e:  10 92 72 03  sts    0x0372, r1
  1952:  80 91 76 03  lds    r24, 0x0376
  1956:  82 30        cpi    r24, 0x02
  1958:  18 f0        brcs   0x1960
  195a:  98 e0        ldi    r25, 0x08   ; 8
  195c:  90 93 72 03  sts    0x0372, r25
  1960:  90 91 77 03  lds    r25, 0x0377
  1964:  99 23        and    r25, r25
  1966:  39 f0        breq   0x1976
  1968:  81 30        cpi    r24, 0x01
  196a:  29 f4        brne   0x1976
  196c:  80 91 72 03  lds    r24, 0x0372
  1970:  84 60        ori    r24, 0x04
  1972:  80 93 72 03  sts    0x0372, r24
  1976:  62 e3        ldi    r22, 0x32   ; 50 '2'
  1978:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0032 = 50
  197a:  80 e0        ldi    r24, 0x00   ; 0
  197c:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  197e:  0e 94 67 01  call   0x2ce <delay>
  1982:  60 91 78 03  lds    r22, 0x0378
  1986:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  1988:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  198a:  0e 94 d2 03  call   0x7a4 <lcd_expanderWrite>
  198e:  68 ee        ldi    r22, 0xE8   ; 232
  1990:  73 e0        ldi    r23, 0x03   ; 3  pair r22:r23 = 0x03E8 = 1000
  1992:  80 e0        ldi    r24, 0x00   ; 0
  1994:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1996:  0e 94 67 01  call   0x2ce <delay>
  199a:  60 e3        ldi    r22, 0x30   ; 48 '0'
  199c:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  199e:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  19a0:  0e 94 0f 05  call   0xa1e <lcd_write4bits>
  19a4:  0b e4        ldi    r16, 0x4B   ; 75 'K'
  19a6:  16 e4        ldi    r17, 0x46   ; 70 'F'  pair r16:r17 = 0x464B = 17995
  19a8:  c8 01        movw   r24, r16
  19aa:  01 97        sbiw   r24, 0x01
  19ac:  f1 f7        brne   0x19aa
  19ae:  60 e3        ldi    r22, 0x30   ; 48 '0'
  19b0:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  19b2:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  19b4:  0e 94 0f 05  call   0xa1e <lcd_write4bits>
  19b8:  c8 01        movw   r24, r16
  19ba:  01 97        sbiw   r24, 0x01
  19bc:  f1 f7        brne   0x19ba
  19be:  60 e3        ldi    r22, 0x30   ; 48 '0'
  19c0:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  19c2:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  19c4:  0e 94 0f 05  call   0xa1e <lcd_write4bits>
  19c8:  83 e5        ldi    r24, 0x53   ; 83 'S'
  19ca:  92 e0        ldi    r25, 0x02   ; 2  pair r24:r25 = 0x0253 = 595
  19cc:  01 97        sbiw   r24, 0x01
  19ce:  f1 f7        brne   0x19cc
  19d0:  60 e2        ldi    r22, 0x20   ; 32 ' '
  19d2:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  19d4:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  19d6:  0e 94 0f 05  call   0xa1e <lcd_write4bits>
  19da:  60 91 72 03  lds    r22, 0x0372
  19de:  60 62        ori    r22, 0x20
  19e0:  40 e0        ldi    r20, 0x00   ; 0
  19e2:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  19e4:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  19e6:  0e 94 28 05  call   0xa50 <lcd_send>
  19ea:  84 e0        ldi    r24, 0x04   ; 4
  19ec:  80 93 73 03  sts    0x0373, r24
  19f0:  40 e0        ldi    r20, 0x00   ; 0
  19f2:  6c e0        ldi    r22, 0x0C   ; 12
  19f4:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  19f6:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  19f8:  0e 94 28 05  call   0xa50 <lcd_send>
  19fc:  0e 94 7f 06  call   0xcfe <lcd_clear>
  1a00:  12 e0        ldi    r17, 0x02   ; 2
  1a02:  10 93 74 03  sts    0x0374, r17
  1a06:  40 e0        ldi    r20, 0x00   ; 0
  1a08:  66 e0        ldi    r22, 0x06   ; 6
  1a0a:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  1a0c:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  1a0e:  0e 94 28 05  call   0xa50 <lcd_send>
  1a12:  40 e0        ldi    r20, 0x00   ; 0
  1a14:  62 e0        ldi    r22, 0x02   ; 2
  1a16:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  1a18:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  1a1a:  0e 94 28 05  call   0xa50 <lcd_send>
  1a1e:  8b e3        ldi    r24, 0x3B   ; 59 ';'
  1a20:  9f e1        ldi    r25, 0x1F   ; 31  pair r24:r25 = 0x1F3B = 7995
  1a22:  01 97        sbiw   r24, 0x01
  1a24:  f1 f7        brne   0x1a22
  1a26:  88 e0        ldi    r24, 0x08   ; 8
  1a28:  80 93 78 03  sts    0x0378, r24
  1a2c:  60 e0        ldi    r22, 0x00   ; 0
  1a2e:  8d e6        ldi    r24, 0x6D   ; 109 'm'
  1a30:  93 e0        ldi    r25, 0x03   ; 3  pair r24:r25 = 0x036D = 877
  1a32:  0e 94 d2 03  call   0x7a4 <lcd_expanderWrite>
  1a36:  60 e0        ldi    r22, 0x00   ; 0
  1a38:  82 e0        ldi    r24, 0x02   ; 2
  1a3a:  0e 94 6e 05  call   0xadc <lcd_setCursor>
  1a3e:  8f eb        ldi    r24, 0xBF   ; 191
  1a40:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01BF = 447  "  OLA..."
  1a42:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  1a46:  60 ed        ldi    r22, 0xD0   ; 208
  1a48:  77 e0        ldi    r23, 0x07   ; 7  pair r22:r23 = 0x07D0 = 2000
  1a4a:  80 e0        ldi    r24, 0x00   ; 0
  1a4c:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1a4e:  0e 94 67 01  call   0x2ce <delay>
  1a52:  62 e0        ldi    r22, 0x02   ; 2
  1a54:  87 e0        ldi    r24, 0x07   ; 7
  1a56:  0e 94 11 01  call   0x222 <pinMode>
  1a5a:  62 e0        ldi    r22, 0x02   ; 2
  1a5c:  85 e0        ldi    r24, 0x05   ; 5
  1a5e:  0e 94 11 01  call   0x222 <pinMode>
  1a62:  62 e0        ldi    r22, 0x02   ; 2
  1a64:  86 e0        ldi    r24, 0x06   ; 6
  1a66:  0e 94 11 01  call   0x222 <pinMode>
  1a6a:  0e 94 96 06  call   0xd2c <updateMenu>
  1a6e:  e0 91 cc 02  lds    r30, 0x02CC
  1a72:  f0 91 cd 02  lds    r31, 0x02CD
  1a76:  10 83        st     Z, r17
  1a78:  e0 91 c8 02  lds    r30, 0x02C8
  1a7c:  f0 91 c9 02  lds    r31, 0x02C9
  1a80:  10 82        st     Z, r1
  1a82:  e0 91 ca 02  lds    r30, 0x02CA
  1a86:  f0 91 cb 02  lds    r31, 0x02CB
  1a8a:  8f ec        ldi    r24, 0xCF   ; 207
  1a8c:  80 83        st     Z, r24
  1a8e:  10 92 d4 02  sts    0x02D4, r1
  1a92:  e0 91 d0 02  lds    r30, 0x02D0
  1a96:  f0 91 d1 02  lds    r31, 0x02D1
  1a9a:  86 e0        ldi    r24, 0x06   ; 6
  1a9c:  80 83        st     Z, r24
  1a9e:  e0 91 ce 02  lds    r30, 0x02CE
  1aa2:  f0 91 cf 02  lds    r31, 0x02CF
  1aa6:  80 81        ld     r24, Z
  1aa8:  80 61        ori    r24, 0x10
  1aaa:  80 83        st     Z, r24
  1aac:  e0 91 ce 02  lds    r30, 0x02CE
  1ab0:  f0 91 cf 02  lds    r31, 0x02CF
  1ab4:  80 81        ld     r24, Z
  1ab6:  88 60        ori    r24, 0x08
  1ab8:  80 83        st     Z, r24
  1aba:  e0 91 ce 02  lds    r30, 0x02CE
  1abe:  f0 91 cf 02  lds    r31, 0x02CF
  1ac2:  80 81        ld     r24, Z
  1ac4:  80 68        ori    r24, 0x80
  1ac6:  80 83        st     Z, r24
  1ac8:  e0 91 ce 02  lds    r30, 0x02CE
  1acc:  f0 91 cf 02  lds    r31, 0x02CF
  1ad0:  80 81        ld     r24, Z
  1ad2:  8f 7d        andi   r24, 0xDF
  1ad4:  80 83        st     Z, r24
  1ad6:  0e 94 af 02  call   0x55e <SPI_begin>
  1ada:  0e 94 fa 06  call   0xdf4 <mcp_startSPI>
  1ade:  80 ec        ldi    r24, 0xC0   ; 192
  1ae0:  0e 94 a8 02  call   0x550 <SPI_transfer>
  1ae4:  0e 94 0c 01  call   0x218 <mcp_endSPI>
  1ae8:  6a e0        ldi    r22, 0x0A   ; 10
  1aea:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x000A = 10
  1aec:  80 e0        ldi    r24, 0x00   ; 0
  1aee:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1af0:  0e 94 67 01  call   0x2ce <delay>
  1af4:  8e 01        movw   r16, r28
  1af6:  0f 5f        subi   r16, 0xFF
  1af8:  1f 4f        sbci   r17, 0xFF
  1afa:  8e e0        ldi    r24, 0x0E   ; 14
  1afc:  f8 01        movw   r30, r16
  1afe:  11 92        st     Z+, r1
  1b00:  8a 95        dec    r24
  1b02:  e9 f7        brne   0x1afe
  1b04:  4e e0        ldi    r20, 0x0E   ; 14
  1b06:  b8 01        movw   r22, r16
  1b08:  80 e3        ldi    r24, 0x30   ; 48 '0'
  1b0a:  0e 94 a0 07  call   0xf40 <mcp_setRegisters>
  1b0e:  4e e0        ldi    r20, 0x0E   ; 14
  1b10:  b8 01        movw   r22, r16
  1b12:  80 e4        ldi    r24, 0x40   ; 64 '@'
  1b14:  0e 94 a0 07  call   0xf40 <mcp_setRegisters>
  1b18:  4e e0        ldi    r20, 0x0E   ; 14
  1b1a:  b8 01        movw   r22, r16
  1b1c:  80 e5        ldi    r24, 0x50   ; 80 'P'
  1b1e:  0e 94 a0 07  call   0xf40 <mcp_setRegisters>
  1b22:  60 e0        ldi    r22, 0x00   ; 0
  1b24:  80 e6        ldi    r24, 0x60   ; 96 '`'
  1b26:  0e 94 8d 07  call   0xf1a <mcp_setRegister>
  1b2a:  60 e0        ldi    r22, 0x00   ; 0
  1b2c:  80 e7        ldi    r24, 0x70   ; 112 'p'
  1b2e:  0e 94 8d 07  call   0xf1a <mcp_setRegister>
  1b32:  63 ea        ldi    r22, 0xA3   ; 163
  1b34:  8b e2        ldi    r24, 0x2B   ; 43 '+'
  1b36:  0e 94 8d 07  call   0xf1a <mcp_setRegister>
  1b3a:  44 e0        ldi    r20, 0x04   ; 4
  1b3c:  67 e6        ldi    r22, 0x67   ; 103 'g'
  1b3e:  80 e6        ldi    r24, 0x60   ; 96 '`'
  1b40:  0e 94 37 07  call   0xe6e <mcp_modifyRegister>
  1b44:  41 e0        ldi    r20, 0x01   ; 1
  1b46:  67 e6        ldi    r22, 0x67   ; 103 'g'
  1b48:  80 e7        ldi    r24, 0x70   ; 112 'p'
  1b4a:  0e 94 37 07  call   0xe6e <mcp_modifyRegister>
  1b4e:  8c e0        ldi    r24, 0x0C   ; 12
  1b50:  e0 e1        ldi    r30, 0x10   ; 16
  1b52:  f1 e0        ldi    r31, 0x01   ; 1  pair r30:r31 = 0x0110 = 272
  1b54:  de 01        movw   r26, r28
  1b56:  1f 96        adiw   r26, 0x0f
  1b58:  01 90        ld     r0, Z+
  1b5a:  0d 92        st     X+, r0
  1b5c:  8a 95        dec    r24
  1b5e:  e1 f7        brne   0x1b58
  1b60:  6e 01        movw   r12, r28
  1b62:  ff e0        ldi    r31, 0x0F   ; 15
  1b64:  cf 0e        add    r12, r31
  1b66:  d1 1c        adc    r13, r1
  1b68:  f1 2c        mov    r15, r1
  1b6a:  e1 2c        mov    r14, r1
  1b6c:  38 e0        ldi    r19, 0x08   ; 8
  1b6e:  b3 2e        mov    r11, r19
  1b70:  f6 01        movw   r30, r12
  1b72:  01 91        ld     r16, Z+
  1b74:  11 91        ld     r17, Z+
  1b76:  6f 01        movw   r12, r30
  1b78:  80 e8        ldi    r24, 0x80   ; 128
  1b7a:  0e 94 50 07  call   0xea0 <mcp_setMode>
  1b7e:  89 2b        or     r24, r25
  1b80:  71 f4        brne   0x1b9e
  1b82:  02 30        cpi    r16, 0x02
  1b84:  11 05        cpc    r17, r1
  1b86:  09 f4        brne   0x1b8a
  1b88:  f0 c0        rjmp   0x1d6a
  1b8a:  08 f0        brcs   0x1b8e
  1b8c:  a4 c0        rjmp   0x1cd6
  1b8e:  01 15        cp     r16, r1
  1b90:  11 05        cpc    r17, r1
  1b92:  09 f4        brne   0x1b96
  1b94:  ac c0        rjmp   0x1cee
  1b96:  01 30        cpi    r16, 0x01
  1b98:  11 05        cpc    r17, r1
  1b9a:  09 f4        brne   0x1b9e
  1b9c:  ec c0        rjmp   0x1d76
  1b9e:  80 e8        ldi    r24, 0x80   ; 128
  1ba0:  0e 94 50 07  call   0xea0 <mcp_setMode>
  1ba4:  89 2b        or     r24, r25
  1ba6:  61 f4        brne   0x1bc0
  1ba8:  60 e0        ldi    r22, 0x00   ; 0
  1baa:  8a e2        ldi    r24, 0x2A   ; 42 '*'
  1bac:  0e 94 8d 07  call   0xf1a <mcp_setRegister>
  1bb0:  60 e9        ldi    r22, 0x90   ; 144
  1bb2:  89 e2        ldi    r24, 0x29   ; 41 ')'
  1bb4:  0e 94 8d 07  call   0xf1a <mcp_setRegister>
  1bb8:  62 e8        ldi    r22, 0x82   ; 130
  1bba:  88 e2        ldi    r24, 0x28   ; 40 '('
  1bbc:  0e 94 8d 07  call   0xf1a <mcp_setRegister>
  1bc0:  80 e0        ldi    r24, 0x00   ; 0
  1bc2:  0e 94 50 07  call   0xea0 <mcp_setMode>
  1bc6:  00 e0        ldi    r16, 0x00   ; 0
  1bc8:  10 e0        ldi    r17, 0x00   ; 0  pair r16:r17 = 0x0000 = 0
  1bca:  ee 24        eor    r14, r14
  1bcc:  e3 94        inc    r14
  1bce:  f1 2c        mov    r15, r1
  1bd0:  93 e0        ldi    r25, 0x03   ; 3
  1bd2:  c9 2e        mov    r12, r25
  1bd4:  d1 2c        mov    r13, r1
  1bd6:  87 e0        ldi    r24, 0x07   ; 7
  1bd8:  0e 94 b5 00  call   0x16a <digitalRead>
  1bdc:  89 2b        or     r24, r25
  1bde:  d1 f4        brne   0x1c14
  1be0:  80 91 00 01  lds    r24, 0x0100   ; menu
  1be4:  90 91 01 01  lds    r25, 0x0101   ; menu +1
  1be8:  01 96        adiw   r24, 0x01
  1bea:  84 30        cpi    r24, 0x04
  1bec:  91 05        cpc    r25, r1
  1bee:  0c f0        brlt   0x1bf2
  1bf0:  d4 c0        rjmp   0x1d9a
  1bf2:  90 93 01 01  sts    0x0101, r25   ; menu +1
  1bf6:  80 93 00 01  sts    0x0100, r24   ; menu
  1bfa:  0e 94 96 06  call   0xd2c <updateMenu>
  1bfe:  64 e6        ldi    r22, 0x64   ; 100 'd'
  1c00:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0064 = 100
  1c02:  80 e0        ldi    r24, 0x00   ; 0
  1c04:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1c06:  0e 94 67 01  call   0x2ce <delay>
  1c0a:  87 e0        ldi    r24, 0x07   ; 7
  1c0c:  0e 94 b5 00  call   0x16a <digitalRead>
  1c10:  89 2b        or     r24, r25
  1c12:  d9 f3        breq   0x1c0a
  1c14:  85 e0        ldi    r24, 0x05   ; 5
  1c16:  0e 94 b5 00  call   0x16a <digitalRead>
  1c1a:  89 2b        or     r24, r25
  1c1c:  d1 f4        brne   0x1c52
  1c1e:  80 91 00 01  lds    r24, 0x0100   ; menu
  1c22:  90 91 01 01  lds    r25, 0x0101   ; menu +1
  1c26:  01 97        sbiw   r24, 0x01
  1c28:  18 16        cp     r1, r24
  1c2a:  19 06        cpc    r1, r25
  1c2c:  0c f0        brlt   0x1c30
  1c2e:  ba c0        rjmp   0x1da4
  1c30:  90 93 01 01  sts    0x0101, r25   ; menu +1
  1c34:  80 93 00 01  sts    0x0100, r24   ; menu
  1c38:  0e 94 96 06  call   0xd2c <updateMenu>
  1c3c:  64 e6        ldi    r22, 0x64   ; 100 'd'
  1c3e:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0064 = 100
  1c40:  80 e0        ldi    r24, 0x00   ; 0
  1c42:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1c44:  0e 94 67 01  call   0x2ce <delay>
  1c48:  85 e0        ldi    r24, 0x05   ; 5
  1c4a:  0e 94 b5 00  call   0x16a <digitalRead>
  1c4e:  89 2b        or     r24, r25
  1c50:  d9 f3        breq   0x1c48
  1c52:  86 e0        ldi    r24, 0x06   ; 6
  1c54:  0e 94 b5 00  call   0x16a <digitalRead>
  1c58:  89 2b        or     r24, r25
  1c5a:  19 f5        brne   0x1ca2
  1c5c:  80 91 00 01  lds    r24, 0x0100   ; menu
  1c60:  90 91 01 01  lds    r25, 0x0101   ; menu +1
  1c64:  82 30        cpi    r24, 0x02
  1c66:  91 05        cpc    r25, r1
  1c68:  09 f4        brne   0x1c6c
  1c6a:  a1 c0        rjmp   0x1dae
  1c6c:  83 30        cpi    r24, 0x03
  1c6e:  91 05        cpc    r25, r1
  1c70:  09 f4        brne   0x1c74
  1c72:  a4 c0        rjmp   0x1dbc
  1c74:  01 97        sbiw   r24, 0x01
  1c76:  41 f4        brne   0x1c88
  1c78:  0e 94 8a 06  call   0xd14 <triggerDone>
  1c7c:  61 ec        ldi    r22, 0xC1   ; 193
  1c7e:  77 e0        ldi    r23, 0x07   ; 7  pair r22:r23 = 0x07C1 = 1985
  1c80:  80 e0        ldi    r24, 0x00   ; 0
  1c82:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1c84:  0e 94 47 09  call   0x128e <sendCAN>
  1c88:  0e 94 96 06  call   0xd2c <updateMenu>
  1c8c:  64 e6        ldi    r22, 0x64   ; 100 'd'
  1c8e:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0064 = 100
  1c90:  80 e0        ldi    r24, 0x00   ; 0
  1c92:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1c94:  0e 94 67 01  call   0x2ce <delay>
  1c98:  86 e0        ldi    r24, 0x06   ; 6
  1c9a:  0e 94 b5 00  call   0x16a <digitalRead>
  1c9e:  89 2b        or     r24, r25
  1ca0:  d9 f3        breq   0x1c98
  1ca2:  80 91 00 01  lds    r24, 0x0100   ; menu
  1ca6:  90 91 01 01  lds    r25, 0x0101   ; menu +1
  1caa:  03 97        sbiw   r24, 0x03
  1cac:  41 f4        brne   0x1cbe
  1cae:  0e 94 77 08  call   0x10ee <readCAN>
  1cb2:  61 e0        ldi    r22, 0x01   ; 1
  1cb4:  70 e0        ldi    r23, 0x00   ; 0  pair r22:r23 = 0x0001 = 1
  1cb6:  80 e0        ldi    r24, 0x00   ; 0
  1cb8:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1cba:  0e 94 67 01  call   0x2ce <delay>
  1cbe:  01 15        cp     r16, r1
  1cc0:  11 05        cpc    r17, r1
  1cc2:  09 f4        brne   0x1cc6
  1cc4:  88 cf        rjmp   0x1bd6
  1cc6:  0e 94 05 02  call   0x40a <Serial_available_bool>
  1cca:  88 23        and    r24, r24
  1ccc:  09 f4        brne   0x1cd0
  1cce:  83 cf        rjmp   0x1bd6
  1cd0:  0e 94 00 00  call   0x0
  1cd4:  80 cf        rjmp   0x1bd6
  1cd6:  04 30        cpi    r16, 0x04
  1cd8:  11 05        cpc    r17, r1
  1cda:  09 f4        brne   0x1cde
  1cdc:  4a c0        rjmp   0x1d72
  1cde:  08 f4        brcc   0x1ce2
  1ce0:  46 c0        rjmp   0x1d6e
  1ce2:  05 30        cpi    r16, 0x05
  1ce4:  11 05        cpc    r17, r1
  1ce6:  09 f0        breq   0x1cea
  1ce8:  5a cf        rjmp   0x1b9e
  1cea:  88 e1        ldi    r24, 0x18   ; 24
  1cec:  01 c0        rjmp   0x1cf0
  1cee:  80 e0        ldi    r24, 0x00   ; 0
  1cf0:  f1 e0        ldi    r31, 0x01   ; 1
  1cf2:  ef 16        cp     r14, r31
  1cf4:  f1 04        cpc    r15, r1
  1cf6:  09 f0        breq   0x1cfa
  1cf8:  40 c0        rjmp   0x1d7a
  1cfa:  1e 8e        std    Y+30, r1
  1cfc:  1d 8e        std    Y+29, r1
  1cfe:  bc 8e        std    Y+28, r11
  1d00:  1b 8e        std    Y+27, r1
  1d02:  44 e0        ldi    r20, 0x04   ; 4
  1d04:  be 01        movw   r22, r28
  1d06:  65 5e        subi   r22, 0xE5
  1d08:  7f 4f        sbci   r23, 0xFF
  1d0a:  0e 94 a0 07  call   0xf40 <mcp_setRegisters>
  1d0e:  8f ef        ldi    r24, 0xFF   ; 255
  1d10:  e8 1a        sub    r14, r24
  1d12:  f8 0a        sbc    r15, r24
  1d14:  96 e0        ldi    r25, 0x06   ; 6
  1d16:  e9 16        cp     r14, r25
  1d18:  f1 04        cpc    r15, r1
  1d1a:  09 f0        breq   0x1d1e
  1d1c:  29 cf        rjmp   0x1b70
  1d1e:  18 a2        std    Y+32, r1
  1d20:  1f 8e        std    Y+31, r1
  1d22:  81 e0        ldi    r24, 0x01   ; 1
  1d24:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0001 = 1
  1d26:  9a a3        std    Y+34, r25
  1d28:  89 a3        std    Y+33, r24
  1d2a:  8e 01        movw   r16, r28
  1d2c:  01 5e        subi   r16, 0xE1
  1d2e:  1f 4f        sbci   r17, 0xFF
  1d30:  6e 01        movw   r12, r28
  1d32:  e3 e2        ldi    r30, 0x23   ; 35 '#'
  1d34:  ce 0e        add    r12, r30
  1d36:  d1 1c        adc    r13, r1
  1d38:  28 e0        ldi    r18, 0x08   ; 8
  1d3a:  b2 2e        mov    r11, r18
  1d3c:  f8 01        movw   r30, r16
  1d3e:  e1 90        ld     r14, Z+
  1d40:  f1 90        ld     r15, Z+
  1d42:  8f 01        movw   r16, r30
  1d44:  80 e8        ldi    r24, 0x80   ; 128
  1d46:  0e 94 50 07  call   0xea0 <mcp_setMode>
  1d4a:  89 2b        or     r24, r25
  1d4c:  09 f0        breq   0x1d50
  1d4e:  27 cf        rjmp   0x1b9e
  1d50:  1e 8e        std    Y+30, r1
  1d52:  1d 8e        std    Y+29, r1
  1d54:  bc 8e        std    Y+28, r11
  1d56:  1b 8e        std    Y+27, r1
  1d58:  e1 14        cp     r14, r1
  1d5a:  f1 04        cpc    r15, r1
  1d5c:  99 f0        breq   0x1d84
  1d5e:  ea 94        dec    r14
  1d60:  ef 28        or     r14, r15
  1d62:  09 f0        breq   0x1d66
  1d64:  1c cf        rjmp   0x1b9e
  1d66:  84 e2        ldi    r24, 0x24   ; 36 '$'
  1d68:  0e c0        rjmp   0x1d86
  1d6a:  88 e0        ldi    r24, 0x08   ; 8
  1d6c:  c1 cf        rjmp   0x1cf0
  1d6e:  80 e1        ldi    r24, 0x10   ; 16
  1d70:  bf cf        rjmp   0x1cf0
  1d72:  84 e1        ldi    r24, 0x14   ; 20
  1d74:  bd cf        rjmp   0x1cf0
  1d76:  84 e0        ldi    r24, 0x04   ; 4
  1d78:  bb cf        rjmp   0x1cf0
  1d7a:  1b 8e        std    Y+27, r1
  1d7c:  1c 8e        std    Y+28, r1
  1d7e:  1e 8e        std    Y+30, r1
  1d80:  1d 8e        std    Y+29, r1
  1d82:  bf cf        rjmp   0x1d02
  1d84:  80 e2        ldi    r24, 0x20   ; 32 ' '
  1d86:  44 e0        ldi    r20, 0x04   ; 4
  1d88:  be 01        movw   r22, r28
  1d8a:  65 5e        subi   r22, 0xE5
  1d8c:  7f 4f        sbci   r23, 0xFF
  1d8e:  0e 94 a0 07  call   0xf40 <mcp_setRegisters>
  1d92:  0c 15        cp     r16, r12
  1d94:  1d 05        cpc    r17, r13
  1d96:  91 f6        brne   0x1d3c
  1d98:  02 cf        rjmp   0x1b9e
  1d9a:  f0 92 01 01  sts    0x0101, r15   ; menu +1
  1d9e:  e0 92 00 01  sts    0x0100, r14   ; menu
  1da2:  2b cf        rjmp   0x1bfa
  1da4:  d0 92 01 01  sts    0x0101, r13   ; menu +1
  1da8:  c0 92 00 01  sts    0x0100, r12   ; menu
  1dac:  45 cf        rjmp   0x1c38
  1dae:  0e 94 8a 06  call   0xd14 <triggerDone>
  1db2:  62 ec        ldi    r22, 0xC2   ; 194
  1db4:  77 e0        ldi    r23, 0x07   ; 7  pair r22:r23 = 0x07C2 = 1986
  1db6:  80 e0        ldi    r24, 0x00   ; 0
  1db8:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1dba:  64 cf        rjmp   0x1c84
  1dbc:  0e 94 7f 06  call   0xcfe <lcd_clear>
  1dc0:  88 ec        ldi    r24, 0xC8   ; 200
  1dc2:  91 e0        ldi    r25, 0x01   ; 1  pair r24:r25 = 0x01C8 = 456  ">FetchingData.. "
  1dc4:  0e 94 0d 05  call   0xa1a <lcd_print_str>
  1dc8:  61 ec        ldi    r22, 0xC1   ; 193
  1dca:  77 e0        ldi    r23, 0x07   ; 7  pair r22:r23 = 0x07C1 = 1985
  1dcc:  80 e0        ldi    r24, 0x00   ; 0
  1dce:  90 e0        ldi    r25, 0x00   ; 0  pair r24:r25 = 0x0000 = 0
  1dd0:  0e 94 47 09  call   0x128e <sendCAN>
  1dd4:  0e 94 77 08  call   0x10ee <readCAN>
  1dd8:  57 cf        rjmp   0x1c88
  1dda:  50 58        subi   r21, 0x80
  1ddc:  bb 27        eor    r27, r27
  1dde:  aa 27        eor    r26, r26
  1de0:  0e 94 05 0f  call   0x1e0a
  1de4:  0c 94 78 10  jmp    0x20f0
  1de8:  0e 94 6a 10  call   0x20d4
  1dec:  38 f0        brcs   0x1dfc
  1dee:  0e 94 71 10  call   0x20e2
  1df2:  20 f0        brcs   0x1dfc
  1df4:  39 f4        brne   0x1e04
  1df6:  9f 3f        cpi    r25, 0xFF
  1df8:  19 f4        brne   0x1e00
  1dfa:  26 f4        brtc   0x1e04
  1dfc:  0c 94 67 10  jmp    0x20ce
  1e00:  0e f4        brtc   0x1e04
  1e02:  e0 95        com    r30
  1e04:  e7 fb        bst    r30, 7
  1e06:  0c 94 61 10  jmp    0x20c2
  1e0a:  e9 2f        mov    r30, r25
  1e0c:  0e 94 89 10  call   0x2112
  1e10:  58 f3        brcs   0x1de8
  1e12:  ba 17        cp     r27, r26
  1e14:  62 07        cpc    r22, r18
  1e16:  73 07        cpc    r23, r19
  1e18:  84 07        cpc    r24, r20
  1e1a:  95 07        cpc    r25, r21
  1e1c:  20 f0        brcs   0x1e26
  1e1e:  79 f4        brne   0x1e3e
  1e20:  a6 f5        brtc   0x1e8a
  1e22:  0c 94 ab 10  jmp    0x2156
  1e26:  0e f4        brtc   0x1e2a
  1e28:  e0 95        com    r30
  1e2a:  0b 2e        mov    r0, r27
  1e2c:  ba 2f        mov    r27, r26
  1e2e:  a0 2d        mov    r26, r0
  1e30:  0b 01        movw   r0, r22
  1e32:  b9 01        movw   r22, r18
  1e34:  90 01        movw   r18, r0
  1e36:  0c 01        movw   r0, r24
  1e38:  ca 01        movw   r24, r20
  1e3a:  a0 01        movw   r20, r0
  1e3c:  11 24        eor    r1, r1
  1e3e:  ff 27        eor    r31, r31
  1e40:  59 1b        sub    r21, r25
  1e42:  99 f0        breq   0x1e6a
  1e44:  59 3f        cpi    r21, 0xF9
  1e46:  50 f4        brcc   0x1e5c
  1e48:  50 3e        cpi    r21, 0xE0
  1e4a:  68 f1        brcs   0x1ea6
  1e4c:  1a 16        cp     r1, r26
  1e4e:  f0 40        sbci   r31, 0x00
  1e50:  a2 2f        mov    r26, r18
  1e52:  23 2f        mov    r18, r19
  1e54:  34 2f        mov    r19, r20
  1e56:  44 27        eor    r20, r20
  1e58:  58 5f        subi   r21, 0xF8
  1e5a:  f3 cf        rjmp   0x1e42
  1e5c:  46 95        lsr    r20
  1e5e:  37 95        ror    r19
  1e60:  27 95        ror    r18
  1e62:  a7 95        ror    r26
  1e64:  f0 40        sbci   r31, 0x00
  1e66:  53 95        inc    r21
  1e68:  c9 f7        brne   0x1e5c
  1e6a:  7e f4        brtc   0x1e8a
  1e6c:  1f 16        cp     r1, r31
  1e6e:  ba 0b        sbc    r27, r26
  1e70:  62 0b        sbc    r22, r18
  1e72:  73 0b        sbc    r23, r19
  1e74:  84 0b        sbc    r24, r20
  1e76:  ba f0        brmi   0x1ea6
  1e78:  91 50        subi   r25, 0x01
  1e7a:  a1 f0        breq   0x1ea4
  1e7c:  ff 0f        add    r31, r31
  1e7e:  bb 1f        adc    r27, r27
  1e80:  66 1f        adc    r22, r22
  1e82:  77 1f        adc    r23, r23
  1e84:  88 1f        adc    r24, r24
  1e86:  c2 f7        brpl   0x1e78
  1e88:  0e c0        rjmp   0x1ea6
  1e8a:  ba 0f        add    r27, r26
  1e8c:  62 1f        adc    r22, r18
  1e8e:  73 1f        adc    r23, r19
  1e90:  84 1f        adc    r24, r20
  1e92:  48 f4        brcc   0x1ea6
  1e94:  87 95        ror    r24
  1e96:  77 95        ror    r23
  1e98:  67 95        ror    r22
  1e9a:  b7 95        ror    r27
  1e9c:  f7 95        ror    r31
  1e9e:  9e 3f        cpi    r25, 0xFE
  1ea0:  08 f0        brcs   0x1ea4
  1ea2:  b0 cf        rjmp   0x1e04
  1ea4:  93 95        inc    r25
  1ea6:  88 0f        add    r24, r24
  1ea8:  08 f0        brcs   0x1eac
  1eaa:  99 27        eor    r25, r25
  1eac:  ee 0f        add    r30, r30
  1eae:  97 95        ror    r25
  1eb0:  87 95        ror    r24
  1eb2:  08 95        ret    
  1eb4:  0e 94 3d 10  call   0x207a
  1eb8:  08 f4        brcc   0x1ebc
  1eba:  81 e0        ldi    r24, 0x01   ; 1
  1ebc:  08 95        ret    

; ===================== __divsf3 =====================
  1ebe:  0e 94 73 0f  call   0x1ee6
  1ec2:  0c 94 78 10  jmp    0x20f0
  1ec6:  0e 94 71 10  call   0x20e2
  1eca:  58 f0        brcs   0x1ee2
  1ecc:  0e 94 6a 10  call   0x20d4
  1ed0:  40 f0        brcs   0x1ee2
  1ed2:  29 f4        brne   0x1ede
  1ed4:  5f 3f        cpi    r21, 0xFF
  1ed6:  29 f0        breq   0x1ee2
  1ed8:  0c 94 61 10  jmp    0x20c2
  1edc:  51 11        cpse   r21, r1
  1ede:  0c 94 ac 10  jmp    0x2158
  1ee2:  0c 94 67 10  jmp    0x20ce
  1ee6:  0e 94 89 10  call   0x2112
  1eea:  68 f3        brcs   0x1ec6
  1eec:  99 23        and    r25, r25
  1eee:  b1 f3        breq   0x1edc
  1ef0:  55 23        and    r21, r21
  1ef2:  91 f3        breq   0x1ed8
  1ef4:  95 1b        sub    r25, r21
  1ef6:  55 0b        sbc    r21, r21
  1ef8:  bb 27        eor    r27, r27
  1efa:  aa 27        eor    r26, r26
  1efc:  62 17        cp     r22, r18
  1efe:  73 07        cpc    r23, r19
  1f00:  84 07        cpc    r24, r20
  1f02:  38 f0        brcs   0x1f12
  1f04:  9f 5f        subi   r25, 0xFF
  1f06:  5f 4f        sbci   r21, 0xFF
  1f08:  22 0f        add    r18, r18
  1f0a:  33 1f        adc    r19, r19
  1f0c:  44 1f        adc    r20, r20
  1f0e:  aa 1f        adc    r26, r26
  1f10:  a9 f3        breq   0x1efc
  1f12:  35 d0        rcall  0x1f7e
  1f14:  0e 2e        mov    r0, r30
  1f16:  3a f0        brmi   0x1f26
  1f18:  e0 e8        ldi    r30, 0x80   ; 128
  1f1a:  32 d0        rcall  0x1f80
  1f1c:  91 50        subi   r25, 0x01
  1f1e:  50 40        sbci   r21, 0x00
  1f20:  e6 95        lsr    r30
  1f22:  00 1c        adc    r0, r0
  1f24:  ca f7        brpl   0x1f18
  1f26:  2b d0        rcall  0x1f7e
  1f28:  fe 2f        mov    r31, r30
  1f2a:  29 d0        rcall  0x1f7e
  1f2c:  66 0f        add    r22, r22
  1f2e:  77 1f        adc    r23, r23
  1f30:  88 1f        adc    r24, r24
  1f32:  bb 1f        adc    r27, r27
  1f34:  26 17        cp     r18, r22
  1f36:  37 07        cpc    r19, r23
  1f38:  48 07        cpc    r20, r24
  1f3a:  ab 07        cpc    r26, r27
  1f3c:  b0 e8        ldi    r27, 0x80   ; 128
  1f3e:  09 f0        breq   0x1f42
  1f40:  bb 0b        sbc    r27, r27
  1f42:  80 2d        mov    r24, r0
  1f44:  bf 01        movw   r22, r30
  1f46:  ff 27        eor    r31, r31
  1f48:  93 58        subi   r25, 0x83
  1f4a:  5f 4f        sbci   r21, 0xFF
  1f4c:  3a f0        brmi   0x1f5c
  1f4e:  9e 3f        cpi    r25, 0xFE
  1f50:  51 05        cpc    r21, r1
  1f52:  78 f0        brcs   0x1f72
  1f54:  0c 94 61 10  jmp    0x20c2
  1f58:  0c 94 ac 10  jmp    0x2158
  1f5c:  5f 3f        cpi    r21, 0xFF
  1f5e:  e4 f3        brlt   0x1f58
  1f60:  98 3e        cpi    r25, 0xE8
  1f62:  d4 f3        brlt   0x1f58
  1f64:  86 95        lsr    r24
  1f66:  77 95        ror    r23
  1f68:  67 95        ror    r22
  1f6a:  b7 95        ror    r27
  1f6c:  f7 95        ror    r31
  1f6e:  9f 5f        subi   r25, 0xFF
  1f70:  c9 f7        brne   0x1f64
  1f72:  88 0f        add    r24, r24
  1f74:  91 1d        adc    r25, r1
  1f76:  96 95        lsr    r25
  1f78:  87 95        ror    r24
  1f7a:  97 f9        bld    r25, 7
  1f7c:  08 95        ret    
  1f7e:  e1 e0        ldi    r30, 0x01   ; 1
  1f80:  66 0f        add    r22, r22
  1f82:  77 1f        adc    r23, r23
  1f84:  88 1f        adc    r24, r24
  1f86:  bb 1f        adc    r27, r27
  1f88:  62 17        cp     r22, r18
  1f8a:  73 07        cpc    r23, r19
  1f8c:  84 07        cpc    r24, r20
  1f8e:  ba 07        cpc    r27, r26
  1f90:  20 f0        brcs   0x1f9a
  1f92:  62 1b        sub    r22, r18
  1f94:  73 0b        sbc    r23, r19
  1f96:  84 0b        sbc    r24, r20
  1f98:  ba 0b        sbc    r27, r26
  1f9a:  ee 1f        adc    r30, r30
  1f9c:  88 f7        brcc   0x1f80
  1f9e:  e0 95        com    r30
  1fa0:  08 95        ret    
  1fa2:  0e 94 91 10  call   0x2122
  1fa6:  88 f0        brcs   0x1fca
  1fa8:  9f 57        subi   r25, 0x7F
  1faa:  98 f0        brcs   0x1fd2
  1fac:  b9 2f        mov    r27, r25
  1fae:  99 27        eor    r25, r25
  1fb0:  b7 51        subi   r27, 0x17
  1fb2:  b0 f0        brcs   0x1fe0
  1fb4:  e1 f0        breq   0x1fee
  1fb6:  66 0f        add    r22, r22
  1fb8:  77 1f        adc    r23, r23
  1fba:  88 1f        adc    r24, r24
  1fbc:  99 1f        adc    r25, r25
  1fbe:  1a f0        brmi   0x1fc6
  1fc0:  ba 95        dec    r27
  1fc2:  c9 f7        brne   0x1fb6
  1fc4:  14 c0        rjmp   0x1fee
  1fc6:  b1 30        cpi    r27, 0x01
  1fc8:  91 f0        breq   0x1fee
  1fca:  0e 94 ab 10  call   0x2156
  1fce:  b1 e0        ldi    r27, 0x01   ; 1
  1fd0:  08 95        ret    
  1fd2:  0c 94 ab 10  jmp    0x2156
  1fd6:  67 2f        mov    r22, r23
  1fd8:  78 2f        mov    r23, r24
  1fda:  88 27        eor    r24, r24
  1fdc:  b8 5f        subi   r27, 0xF8
  1fde:  39 f0        breq   0x1fee
  1fe0:  b9 3f        cpi    r27, 0xF9
  1fe2:  cc f3        brlt   0x1fd6
  1fe4:  86 95        lsr    r24
  1fe6:  77 95        ror    r23
  1fe8:  67 95        ror    r22
  1fea:  b3 95        inc    r27
  1fec:  d9 f7        brne   0x1fe4
  1fee:  3e f4        brtc   0x1ffe
  1ff0:  90 95        com    r25
  1ff2:  80 95        com    r24
  1ff4:  70 95        com    r23
  1ff6:  61 95        neg    r22
  1ff8:  7f 4f        sbci   r23, 0xFF
  1ffa:  8f 4f        sbci   r24, 0xFF
  1ffc:  9f 4f        sbci   r25, 0xFF
  1ffe:  08 95        ret    

; ===================== __floatunsisf =====================
  2000:  e8 94        clt    
  2002:  09 c0        rjmp   0x2016
  2004:  97 fb        bst    r25, 7
  2006:  3e f4        brtc   0x2016
  2008:  90 95        com    r25
  200a:  80 95        com    r24
  200c:  70 95        com    r23
  200e:  61 95        neg    r22
  2010:  7f 4f        sbci   r23, 0xFF
  2012:  8f 4f        sbci   r24, 0xFF
  2014:  9f 4f        sbci   r25, 0xFF
  2016:  99 23        and    r25, r25
  2018:  a9 f0        breq   0x2044
  201a:  f9 2f        mov    r31, r25
  201c:  96 e9        ldi    r25, 0x96   ; 150
  201e:  bb 27        eor    r27, r27
  2020:  93 95        inc    r25
  2022:  f6 95        lsr    r31
  2024:  87 95        ror    r24
  2026:  77 95        ror    r23
  2028:  67 95        ror    r22
  202a:  b7 95        ror    r27
  202c:  f1 11        cpse   r31, r1
  202e:  f8 cf        rjmp   0x2020
  2030:  fa f4        brpl   0x2070
  2032:  bb 0f        add    r27, r27
  2034:  11 f4        brne   0x203a
  2036:  60 ff        sbrs   r22, 0
  2038:  1b c0        rjmp   0x2070
  203a:  6f 5f        subi   r22, 0xFF
  203c:  7f 4f        sbci   r23, 0xFF
  203e:  8f 4f        sbci   r24, 0xFF
  2040:  9f 4f        sbci   r25, 0xFF
  2042:  16 c0        rjmp   0x2070
  2044:  88 23        and    r24, r24
  2046:  11 f0        breq   0x204c
  2048:  96 e9        ldi    r25, 0x96   ; 150
  204a:  11 c0        rjmp   0x206e
  204c:  77 23        and    r23, r23
  204e:  21 f0        breq   0x2058
  2050:  9e e8        ldi    r25, 0x8E   ; 142
  2052:  87 2f        mov    r24, r23
  2054:  76 2f        mov    r23, r22
  2056:  05 c0        rjmp   0x2062
  2058:  66 23        and    r22, r22
  205a:  71 f0        breq   0x2078
  205c:  96 e8        ldi    r25, 0x86   ; 134
  205e:  86 2f        mov    r24, r22
  2060:  70 e0        ldi    r23, 0x00   ; 0
  2062:  60 e0        ldi    r22, 0x00   ; 0
  2064:  2a f0        brmi   0x2070
  2066:  9a 95        dec    r25
  2068:  66 0f        add    r22, r22
  206a:  77 1f        adc    r23, r23
  206c:  88 1f        adc    r24, r24
  206e:  da f7        brpl   0x2066
  2070:  88 0f        add    r24, r24
  2072:  96 95        lsr    r25
  2074:  87 95        ror    r24
  2076:  97 f9        bld    r25, 7
  2078:  08 95        ret    
  207a:  99 0f        add    r25, r25
  207c:  00 08        sbc    r0, r0
  207e:  55 0f        add    r21, r21
  2080:  aa 0b        sbc    r26, r26
  2082:  e0 e8        ldi    r30, 0x80   ; 128
  2084:  fe ef        ldi    r31, 0xFE   ; 254  pair r30:r31 = 0xFE80 = 65152
  2086:  16 16        cp     r1, r22
  2088:  17 06        cpc    r1, r23
  208a:  e8 07        cpc    r30, r24
  208c:  f9 07        cpc    r31, r25
  208e:  c0 f0        brcs   0x20c0
  2090:  12 16        cp     r1, r18
  2092:  13 06        cpc    r1, r19
  2094:  e4 07        cpc    r30, r20
  2096:  f5 07        cpc    r31, r21
  2098:  98 f0        brcs   0x20c0
  209a:  62 1b        sub    r22, r18
  209c:  73 0b        sbc    r23, r19
  209e:  84 0b        sbc    r24, r20
  20a0:  95 0b        sbc    r25, r21
  20a2:  39 f4        brne   0x20b2
  20a4:  0a 26        eor    r0, r26
  20a6:  61 f0        breq   0x20c0
  20a8:  23 2b        or     r18, r19
  20aa:  24 2b        or     r18, r20
  20ac:  25 2b        or     r18, r21
  20ae:  21 f4        brne   0x20b8
  20b0:  08 95        ret    
  20b2:  0a 26        eor    r0, r26
  20b4:  09 f4        brne   0x20b8
  20b6:  a1 40        sbci   r26, 0x01
  20b8:  a6 95        lsr    r26
  20ba:  8f ef        ldi    r24, 0xFF   ; 255
  20bc:  81 1d        adc    r24, r1
  20be:  81 1d        adc    r24, r1
  20c0:  08 95        ret    
  20c2:  97 f9        bld    r25, 7
  20c4:  9f 67        ori    r25, 0x7F
  20c6:  80 e8        ldi    r24, 0x80   ; 128
  20c8:  70 e0        ldi    r23, 0x00   ; 0
  20ca:  60 e0        ldi    r22, 0x00   ; 0
  20cc:  08 95        ret    
  20ce:  9f ef        ldi    r25, 0xFF   ; 255
  20d0:  80 ec        ldi    r24, 0xC0   ; 192
  20d2:  08 95        ret    
  20d4:  00 24        eor    r0, r0
  20d6:  0a 94        dec    r0
  20d8:  16 16        cp     r1, r22
  20da:  17 06        cpc    r1, r23
  20dc:  18 06        cpc    r1, r24
  20de:  09 06        cpc    r0, r25
  20e0:  08 95        ret    
  20e2:  00 24        eor    r0, r0
  20e4:  0a 94        dec    r0
  20e6:  12 16        cp     r1, r18
  20e8:  13 06        cpc    r1, r19
  20ea:  14 06        cpc    r1, r20
  20ec:  05 06        cpc    r0, r21
  20ee:  08 95        ret    
  20f0:  09 2e        mov    r0, r25
  20f2:  03 94        inc    r0
  20f4:  00 0c        add    r0, r0
  20f6:  11 f4        brne   0x20fc
  20f8:  88 23        and    r24, r24
  20fa:  52 f0        brmi   0x2110
  20fc:  bb 0f        add    r27, r27
  20fe:  40 f4        brcc   0x2110
  2100:  bf 2b        or     r27, r31
  2102:  11 f4        brne   0x2108
  2104:  60 ff        sbrs   r22, 0
  2106:  04 c0        rjmp   0x2110
  2108:  6f 5f        subi   r22, 0xFF
  210a:  7f 4f        sbci   r23, 0xFF
  210c:  8f 4f        sbci   r24, 0xFF
  210e:  9f 4f        sbci   r25, 0xFF
  2110:  08 95        ret    
  2112:  57 fd        sbrc   r21, 7
  2114:  90 58        subi   r25, 0x80
  2116:  44 0f        add    r20, r20
  2118:  55 1f        adc    r21, r21
  211a:  59 f0        breq   0x2132
  211c:  5f 3f        cpi    r21, 0xFF
  211e:  71 f0        breq   0x213c
  2120:  47 95        ror    r20
  2122:  88 0f        add    r24, r24
  2124:  97 fb        bst    r25, 7
  2126:  99 1f        adc    r25, r25
  2128:  61 f0        breq   0x2142
  212a:  9f 3f        cpi    r25, 0xFF
  212c:  79 f0        breq   0x214c
  212e:  87 95        ror    r24
  2130:  08 95        ret    
  2132:  12 16        cp     r1, r18
  2134:  13 06        cpc    r1, r19
  2136:  14 06        cpc    r1, r20
  2138:  55 1f        adc    r21, r21
  213a:  f2 cf        rjmp   0x2120
  213c:  46 95        lsr    r20
  213e:  f1 df        rcall  0x2122
  2140:  08 c0        rjmp   0x2152
  2142:  16 16        cp     r1, r22
  2144:  17 06        cpc    r1, r23
  2146:  18 06        cpc    r1, r24
  2148:  99 1f        adc    r25, r25
  214a:  f1 cf        rjmp   0x212e
  214c:  86 95        lsr    r24
  214e:  71 05        cpc    r23, r1
  2150:  61 05        cpc    r22, r1
  2152:  08 94        sec    
  2154:  08 95        ret    
  2156:  e8 94        clt    
  2158:  bb 27        eor    r27, r27
  215a:  66 27        eor    r22, r22
  215c:  77 27        eor    r23, r23
  215e:  cb 01        movw   r24, r22
  2160:  97 f9        bld    r25, 7
  2162:  08 95        ret    
  2164:  0e 94 3d 10  call   0x207a
  2168:  08 f4        brcc   0x216c
  216a:  8f ef        ldi    r24, 0xFF   ; 255
  216c:  08 95        ret    
  216e:  0e 94 ca 10  call   0x2194
  2172:  0c 94 78 10  jmp    0x20f0
  2176:  0e 94 6a 10  call   0x20d4
  217a:  38 f0        brcs   0x218a
  217c:  0e 94 71 10  call   0x20e2
  2180:  20 f0        brcs   0x218a
  2182:  95 23        and    r25, r21
  2184:  11 f0        breq   0x218a
  2186:  0c 94 61 10  jmp    0x20c2
  218a:  0c 94 67 10  jmp    0x20ce
  218e:  11 24        eor    r1, r1
  2190:  0c 94 ac 10  jmp    0x2158
  2194:  0e 94 89 10  call   0x2112
  2198:  70 f3        brcs   0x2176
  219a:  95 9f        mul    r25, r21
  219c:  c1 f3        breq   0x218e
  219e:  95 0f        add    r25, r21
  21a0:  50 e0        ldi    r21, 0x00   ; 0
  21a2:  55 1f        adc    r21, r21
  21a4:  62 9f        mul    r22, r18
  21a6:  f0 01        movw   r30, r0
  21a8:  72 9f        mul    r23, r18
  21aa:  bb 27        eor    r27, r27
  21ac:  f0 0d        add    r31, r0
  21ae:  b1 1d        adc    r27, r1
  21b0:  63 9f        mul    r22, r19
  21b2:  aa 27        eor    r26, r26
  21b4:  f0 0d        add    r31, r0
  21b6:  b1 1d        adc    r27, r1
  21b8:  aa 1f        adc    r26, r26
  21ba:  64 9f        mul    r22, r20
  21bc:  66 27        eor    r22, r22
  21be:  b0 0d        add    r27, r0
  21c0:  a1 1d        adc    r26, r1
  21c2:  66 1f        adc    r22, r22
  21c4:  82 9f        mul    r24, r18
  21c6:  22 27        eor    r18, r18
  21c8:  b0 0d        add    r27, r0
  21ca:  a1 1d        adc    r26, r1
  21cc:  62 1f        adc    r22, r18
  21ce:  73 9f        mul    r23, r19
  21d0:  b0 0d        add    r27, r0
  21d2:  a1 1d        adc    r26, r1
  21d4:  62 1f        adc    r22, r18
  21d6:  83 9f        mul    r24, r19
  21d8:  a0 0d        add    r26, r0
  21da:  61 1d        adc    r22, r1
  21dc:  22 1f        adc    r18, r18
  21de:  74 9f        mul    r23, r20
  21e0:  33 27        eor    r19, r19
  21e2:  a0 0d        add    r26, r0
  21e4:  61 1d        adc    r22, r1
  21e6:  23 1f        adc    r18, r19
  21e8:  84 9f        mul    r24, r20
  21ea:  60 0d        add    r22, r0
  21ec:  21 1d        adc    r18, r1
  21ee:  82 2f        mov    r24, r18
  21f0:  76 2f        mov    r23, r22
  21f2:  6a 2f        mov    r22, r26
  21f4:  11 24        eor    r1, r1
  21f6:  9f 57        subi   r25, 0x7F
  21f8:  50 40        sbci   r21, 0x00
  21fa:  9a f0        brmi   0x2222
  21fc:  f1 f0        breq   0x223a
  21fe:  88 23        and    r24, r24
  2200:  4a f0        brmi   0x2214
  2202:  ee 0f        add    r30, r30
  2204:  ff 1f        adc    r31, r31
  2206:  bb 1f        adc    r27, r27
  2208:  66 1f        adc    r22, r22
  220a:  77 1f        adc    r23, r23
  220c:  88 1f        adc    r24, r24
  220e:  91 50        subi   r25, 0x01
  2210:  50 40        sbci   r21, 0x00
  2212:  a9 f7        brne   0x21fe
  2214:  9e 3f        cpi    r25, 0xFE
  2216:  51 05        cpc    r21, r1
  2218:  80 f0        brcs   0x223a
  221a:  0c 94 61 10  jmp    0x20c2
  221e:  0c 94 ac 10  jmp    0x2158
  2222:  5f 3f        cpi    r21, 0xFF
  2224:  e4 f3        brlt   0x221e
  2226:  98 3e        cpi    r25, 0xE8
  2228:  d4 f3        brlt   0x221e
  222a:  86 95        lsr    r24
  222c:  77 95        ror    r23
  222e:  67 95        ror    r22
  2230:  b7 95        ror    r27
  2232:  f7 95        ror    r31
  2234:  e7 95        ror    r30
  2236:  9f 5f        subi   r25, 0xFF
  2238:  c1 f7        brne   0x222a
  223a:  fe 2b        or     r31, r30
  223c:  88 0f        add    r24, r24
  223e:  91 1d        adc    r25, r1
  2240:  96 95        lsr    r25
  2242:  87 95        ror    r24
  2244:  97 f9        bld    r25, 7
  2246:  08 95        ret    
  2248:  0e 94 3d 10  call   0x207a
  224c:  88 0b        sbc    r24, r24
  224e:  99 0b        sbc    r25, r25
  2250:  08 95        ret    
  2252:  a1 e2        ldi    r26, 0x21   ; 33 '!'
  2254:  1a 2e        mov    r1, r26
  2256:  aa 1b        sub    r26, r26
  2258:  bb 1b        sub    r27, r27
  225a:  fd 01        movw   r30, r26
  225c:  0d c0        rjmp   0x2278
  225e:  aa 1f        adc    r26, r26
  2260:  bb 1f        adc    r27, r27
  2262:  ee 1f        adc    r30, r30
  2264:  ff 1f        adc    r31, r31
  2266:  a2 17        cp     r26, r18
  2268:  b3 07        cpc    r27, r19
  226a:  e4 07        cpc    r30, r20
  226c:  f5 07        cpc    r31, r21
  226e:  20 f0        brcs   0x2278
  2270:  a2 1b        sub    r26, r18
  2272:  b3 0b        sbc    r27, r19
  2274:  e4 0b        sbc    r30, r20
  2276:  f5 0b        sbc    r31, r21
  2278:  66 1f        adc    r22, r22
  227a:  77 1f        adc    r23, r23
  227c:  88 1f        adc    r24, r24
  227e:  99 1f        adc    r25, r25
  2280:  1a 94        dec    r1
  2282:  69 f7        brne   0x225e
  2284:  60 95        com    r22
  2286:  70 95        com    r23
  2288:  80 95        com    r24
  228a:  90 95        com    r25
  228c:  9b 01        movw   r18, r22
  228e:  ac 01        movw   r20, r24
  2290:  bd 01        movw   r22, r26
  2292:  cf 01        movw   r24, r30
  2294:  08 95        ret    
  2296:  ee 0f        add    r30, r30
  2298:  ff 1f        adc    r31, r31
  229a:  05 90        lpm    r0, Z+
  229c:  f4 91        lpm    r31, Z
  229e:  e0 2d        mov    r30, r0
  22a0:  09 94        ijmp   
  22a2:  fb 01        movw   r30, r22
  22a4:  dc 01        movw   r26, r24
  22a6:  02 c0        rjmp   0x22ac
  22a8:  01 90        ld     r0, Z+
  22aa:  0d 92        st     X+, r0
  22ac:  41 50        subi   r20, 0x01
  22ae:  50 40        sbci   r21, 0x00
  22b0:  d8 f7        brcc   0x22a8
  22b2:  08 95        ret    

; ===================== exit =====================
  22b4:  f8 94        cli    
  22b6:  ff cf        rjmp   0x22b6
