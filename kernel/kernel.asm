
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	f1e78793          	addi	a5,a5,-226 # 80005f80 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	532080e7          	jalr	1330(ra) # 8000265c <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	f10080e7          	jalr	-240(ra) # 800020e0 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	3fa080e7          	jalr	1018(ra) # 80002606 <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	3c6080e7          	jalr	966(ra) # 800026b2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	f9a080e7          	jalr	-102(ra) # 800023da <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	0a678793          	addi	a5,a5,166 # 80021518 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	b4c080e7          	jalr	-1204(ra) # 800023da <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	7c6080e7          	jalr	1990(ra) # 800020e0 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	a9e080e7          	jalr	-1378(ra) # 80002956 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	100080e7          	jalr	256(ra) # 80005fc0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	012080e7          	jalr	18(ra) # 80001eda <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	9fe080e7          	jalr	-1538(ra) # 8000292e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	a1e080e7          	jalr	-1506(ra) # 80002956 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	06a080e7          	jalr	106(ra) # 80005faa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	078080e7          	jalr	120(ra) # 80005fc0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	23e080e7          	jalr	574(ra) # 8000318e <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	8cc080e7          	jalr	-1844(ra) # 80003824 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	87e080e7          	jalr	-1922(ra) # 800047de <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	178080e7          	jalr	376(ra) # 800060e0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d02080e7          	jalr	-766(ra) # 80001c72 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	a7ca0a13          	addi	s4,s4,-1412 # 800172d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	8591                	srai	a1,a1,0x4
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	17048493          	addi	s1,s1,368
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00016997          	auipc	s3,0x16
    80001924:	9b098993          	addi	s3,s3,-1616 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	8791                	srai	a5,a5,0x4
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	17048493          	addi	s1,s1,368
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	e4a7a783          	lw	a5,-438(a5) # 80008830 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	f7e080e7          	jalr	-130(ra) # 8000296e <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e207a823          	sw	zero,-464(a5) # 80008830 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	d9a080e7          	jalr	-614(ra) # 800037a4 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e0278793          	addi	a5,a5,-510 # 80008834 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	06093683          	ld	a3,96(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	7128                	ld	a0,96(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b64:	6ca8                	ld	a0,88(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	68ac                	ld	a1,80(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b76:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001b82:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	71c90913          	addi	s2,s2,1820 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	17048493          	addi	s1,s1,368
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a899                	j	80001c34 <allocproc+0x94>
  p->cputime = 0;
    80001be0:	0204aa23          	sw	zero,52(s1)
  p->pid = allocpid();
    80001be4:	00000097          	auipc	ra,0x0
    80001be8:	e30080e7          	jalr	-464(ra) # 80001a14 <allocpid>
    80001bec:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bee:	4785                	li	a5,1
    80001bf0:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	eee080e7          	jalr	-274(ra) # 80000ae0 <kalloc>
    80001bfa:	892a                	mv	s2,a0
    80001bfc:	f0a8                	sd	a0,96(s1)
    80001bfe:	c131                	beqz	a0,80001c42 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	e58080e7          	jalr	-424(ra) # 80001a5a <proc_pagetable>
    80001c0a:	892a                	mv	s2,a0
    80001c0c:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c0e:	c531                	beqz	a0,80001c5a <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c10:	07000613          	li	a2,112
    80001c14:	4581                	li	a1,0
    80001c16:	06848513          	addi	a0,s1,104
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	0b2080e7          	jalr	178(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c22:	00000797          	auipc	a5,0x0
    80001c26:	dac78793          	addi	a5,a5,-596 # 800019ce <forkret>
    80001c2a:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c2c:	64bc                	ld	a5,72(s1)
    80001c2e:	6705                	lui	a4,0x1
    80001c30:	97ba                	add	a5,a5,a4
    80001c32:	f8bc                	sd	a5,112(s1)
}
    80001c34:	8526                	mv	a0,s1
    80001c36:	60e2                	ld	ra,24(sp)
    80001c38:	6442                	ld	s0,16(sp)
    80001c3a:	64a2                	ld	s1,8(sp)
    80001c3c:	6902                	ld	s2,0(sp)
    80001c3e:	6105                	addi	sp,sp,32
    80001c40:	8082                	ret
    freeproc(p);
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	f04080e7          	jalr	-252(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	036080e7          	jalr	54(ra) # 80000c84 <release>
    return 0;
    80001c56:	84ca                	mv	s1,s2
    80001c58:	bff1                	j	80001c34 <allocproc+0x94>
    freeproc(p);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	eec080e7          	jalr	-276(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	01e080e7          	jalr	30(ra) # 80000c84 <release>
    return 0;
    80001c6e:	84ca                	mv	s1,s2
    80001c70:	b7d1                	j	80001c34 <allocproc+0x94>

0000000080001c72 <userinit>:
{
    80001c72:	1101                	addi	sp,sp,-32
    80001c74:	ec06                	sd	ra,24(sp)
    80001c76:	e822                	sd	s0,16(sp)
    80001c78:	e426                	sd	s1,8(sp)
    80001c7a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	f24080e7          	jalr	-220(ra) # 80001ba0 <allocproc>
    80001c84:	84aa                	mv	s1,a0
  initproc = p;
    80001c86:	00007797          	auipc	a5,0x7
    80001c8a:	3aa7b123          	sd	a0,930(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8e:	03400613          	li	a2,52
    80001c92:	00007597          	auipc	a1,0x7
    80001c96:	bae58593          	addi	a1,a1,-1106 # 80008840 <initcode>
    80001c9a:	6d28                	ld	a0,88(a0)
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	6b0080e7          	jalr	1712(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca4:	6785                	lui	a5,0x1
    80001ca6:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca8:	70b8                	ld	a4,96(s1)
    80001caa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cae:	70b8                	ld	a4,96(s1)
    80001cb0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cb2:	4641                	li	a2,16
    80001cb4:	00006597          	auipc	a1,0x6
    80001cb8:	54c58593          	addi	a1,a1,1356 # 80008200 <digits+0x1c0>
    80001cbc:	16048513          	addi	a0,s1,352
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	156080e7          	jalr	342(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	54850513          	addi	a0,a0,1352 # 80008210 <digits+0x1d0>
    80001cd0:	00002097          	auipc	ra,0x2
    80001cd4:	50a080e7          	jalr	1290(ra) # 800041da <namei>
    80001cd8:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001cdc:	478d                	li	a5,3
    80001cde:	cc9c                	sw	a5,24(s1)
  p->readytime = sys_uptime();
    80001ce0:	00001097          	auipc	ra,0x1
    80001ce4:	43a080e7          	jalr	1082(ra) # 8000311a <sys_uptime>
    80001ce8:	dcc8                	sw	a0,60(s1)
  release(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	f98080e7          	jalr	-104(ra) # 80000c84 <release>
}
    80001cf4:	60e2                	ld	ra,24(sp)
    80001cf6:	6442                	ld	s0,16(sp)
    80001cf8:	64a2                	ld	s1,8(sp)
    80001cfa:	6105                	addi	sp,sp,32
    80001cfc:	8082                	ret

0000000080001cfe <growproc>:
{
    80001cfe:	1101                	addi	sp,sp,-32
    80001d00:	ec06                	sd	ra,24(sp)
    80001d02:	e822                	sd	s0,16(sp)
    80001d04:	e426                	sd	s1,8(sp)
    80001d06:	e04a                	sd	s2,0(sp)
    80001d08:	1000                	addi	s0,sp,32
    80001d0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	c8a080e7          	jalr	-886(ra) # 80001996 <myproc>
    80001d14:	892a                	mv	s2,a0
  sz = p->sz;
    80001d16:	692c                	ld	a1,80(a0)
    80001d18:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d1c:	00904f63          	bgtz	s1,80001d3a <growproc+0x3c>
  } else if(n < 0){
    80001d20:	0204cd63          	bltz	s1,80001d5a <growproc+0x5c>
  p->sz = sz;
    80001d24:	1782                	slli	a5,a5,0x20
    80001d26:	9381                	srli	a5,a5,0x20
    80001d28:	04f93823          	sd	a5,80(s2)
  return 0;
    80001d2c:	4501                	li	a0,0
}
    80001d2e:	60e2                	ld	ra,24(sp)
    80001d30:	6442                	ld	s0,16(sp)
    80001d32:	64a2                	ld	s1,8(sp)
    80001d34:	6902                	ld	s2,0(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d3a:	00f4863b          	addw	a2,s1,a5
    80001d3e:	1602                	slli	a2,a2,0x20
    80001d40:	9201                	srli	a2,a2,0x20
    80001d42:	1582                	slli	a1,a1,0x20
    80001d44:	9181                	srli	a1,a1,0x20
    80001d46:	6d28                	ld	a0,88(a0)
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	6be080e7          	jalr	1726(ra) # 80001406 <uvmalloc>
    80001d50:	0005079b          	sext.w	a5,a0
    80001d54:	fbe1                	bnez	a5,80001d24 <growproc+0x26>
      return -1;
    80001d56:	557d                	li	a0,-1
    80001d58:	bfd9                	j	80001d2e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d5a:	00f4863b          	addw	a2,s1,a5
    80001d5e:	1602                	slli	a2,a2,0x20
    80001d60:	9201                	srli	a2,a2,0x20
    80001d62:	1582                	slli	a1,a1,0x20
    80001d64:	9181                	srli	a1,a1,0x20
    80001d66:	6d28                	ld	a0,88(a0)
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	656080e7          	jalr	1622(ra) # 800013be <uvmdealloc>
    80001d70:	0005079b          	sext.w	a5,a0
    80001d74:	bf45                	j	80001d24 <growproc+0x26>

0000000080001d76 <fork>:
{
    80001d76:	7139                	addi	sp,sp,-64
    80001d78:	fc06                	sd	ra,56(sp)
    80001d7a:	f822                	sd	s0,48(sp)
    80001d7c:	f426                	sd	s1,40(sp)
    80001d7e:	f04a                	sd	s2,32(sp)
    80001d80:	ec4e                	sd	s3,24(sp)
    80001d82:	e852                	sd	s4,16(sp)
    80001d84:	e456                	sd	s5,8(sp)
    80001d86:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c0e080e7          	jalr	-1010(ra) # 80001996 <myproc>
    80001d90:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	e0e080e7          	jalr	-498(ra) # 80001ba0 <allocproc>
    80001d9a:	12050263          	beqz	a0,80001ebe <fork+0x148>
    80001d9e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da0:	050ab603          	ld	a2,80(s5)
    80001da4:	6d2c                	ld	a1,88(a0)
    80001da6:	058ab503          	ld	a0,88(s5)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	7ac080e7          	jalr	1964(ra) # 80001556 <uvmcopy>
    80001db2:	04054863          	bltz	a0,80001e02 <fork+0x8c>
  np->sz = p->sz;
    80001db6:	050ab783          	ld	a5,80(s5)
    80001dba:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dbe:	060ab683          	ld	a3,96(s5)
    80001dc2:	87b6                	mv	a5,a3
    80001dc4:	0609b703          	ld	a4,96(s3)
    80001dc8:	12068693          	addi	a3,a3,288
    80001dcc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd0:	6788                	ld	a0,8(a5)
    80001dd2:	6b8c                	ld	a1,16(a5)
    80001dd4:	6f90                	ld	a2,24(a5)
    80001dd6:	01073023          	sd	a6,0(a4)
    80001dda:	e708                	sd	a0,8(a4)
    80001ddc:	eb0c                	sd	a1,16(a4)
    80001dde:	ef10                	sd	a2,24(a4)
    80001de0:	02078793          	addi	a5,a5,32
    80001de4:	02070713          	addi	a4,a4,32
    80001de8:	fed792e3          	bne	a5,a3,80001dcc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dec:	0609b783          	ld	a5,96(s3)
    80001df0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001df4:	0d8a8493          	addi	s1,s5,216
    80001df8:	0d898913          	addi	s2,s3,216
    80001dfc:	158a8a13          	addi	s4,s5,344
    80001e00:	a00d                	j	80001e22 <fork+0xac>
    freeproc(np);
    80001e02:	854e                	mv	a0,s3
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d44080e7          	jalr	-700(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e76080e7          	jalr	-394(ra) # 80000c84 <release>
    return -1;
    80001e16:	597d                	li	s2,-1
    80001e18:	a849                	j	80001eaa <fork+0x134>
  for(i = 0; i < NOFILE; i++)
    80001e1a:	04a1                	addi	s1,s1,8
    80001e1c:	0921                	addi	s2,s2,8
    80001e1e:	01448b63          	beq	s1,s4,80001e34 <fork+0xbe>
    if(p->ofile[i])
    80001e22:	6088                	ld	a0,0(s1)
    80001e24:	d97d                	beqz	a0,80001e1a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00003097          	auipc	ra,0x3
    80001e2a:	a4a080e7          	jalr	-1462(ra) # 80004870 <filedup>
    80001e2e:	00a93023          	sd	a0,0(s2)
    80001e32:	b7e5                	j	80001e1a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e34:	158ab503          	ld	a0,344(s5)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	ba8080e7          	jalr	-1112(ra) # 800039e0 <idup>
    80001e40:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	160a8593          	addi	a1,s5,352
    80001e4a:	16098513          	addi	a0,s3,352
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fc8080e7          	jalr	-56(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e56:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e5a:	854e                	mv	a0,s3
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e28080e7          	jalr	-472(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	45448493          	addi	s1,s1,1108 # 800112b8 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d62080e7          	jalr	-670(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e76:	0559b023          	sd	s5,64(s3)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e08080e7          	jalr	-504(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e84:	854e                	mv	a0,s3
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d4a080e7          	jalr	-694(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00f9ac23          	sw	a5,24(s3)
  np->readytime = sys_uptime();
    80001e94:	00001097          	auipc	ra,0x1
    80001e98:	286080e7          	jalr	646(ra) # 8000311a <sys_uptime>
    80001e9c:	02a9ae23          	sw	a0,60(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	de2080e7          	jalr	-542(ra) # 80000c84 <release>
}
    80001eaa:	854a                	mv	a0,s2
    80001eac:	70e2                	ld	ra,56(sp)
    80001eae:	7442                	ld	s0,48(sp)
    80001eb0:	74a2                	ld	s1,40(sp)
    80001eb2:	7902                	ld	s2,32(sp)
    80001eb4:	69e2                	ld	s3,24(sp)
    80001eb6:	6a42                	ld	s4,16(sp)
    80001eb8:	6aa2                	ld	s5,8(sp)
    80001eba:	6121                	addi	sp,sp,64
    80001ebc:	8082                	ret
    return -1;
    80001ebe:	597d                	li	s2,-1
    80001ec0:	b7ed                	j	80001eaa <fork+0x134>

0000000080001ec2 <min>:
int min(int a, int b){
    80001ec2:	1141                	addi	sp,sp,-16
    80001ec4:	e422                	sd	s0,8(sp)
    80001ec6:	0800                	addi	s0,sp,16
return (a< b) ? a : b;
    80001ec8:	87ae                	mv	a5,a1
    80001eca:	00b55363          	bge	a0,a1,80001ed0 <min+0xe>
    80001ece:	87aa                	mv	a5,a0
}
    80001ed0:	0007851b          	sext.w	a0,a5
    80001ed4:	6422                	ld	s0,8(sp)
    80001ed6:	0141                	addi	sp,sp,16
    80001ed8:	8082                	ret

0000000080001eda <scheduler>:
{
    80001eda:	7159                	addi	sp,sp,-112
    80001edc:	f486                	sd	ra,104(sp)
    80001ede:	f0a2                	sd	s0,96(sp)
    80001ee0:	eca6                	sd	s1,88(sp)
    80001ee2:	e8ca                	sd	s2,80(sp)
    80001ee4:	e4ce                	sd	s3,72(sp)
    80001ee6:	e0d2                	sd	s4,64(sp)
    80001ee8:	fc56                	sd	s5,56(sp)
    80001eea:	f85a                	sd	s6,48(sp)
    80001eec:	f45e                	sd	s7,40(sp)
    80001eee:	f062                	sd	s8,32(sp)
    80001ef0:	ec66                	sd	s9,24(sp)
    80001ef2:	e86a                	sd	s10,16(sp)
    80001ef4:	e46e                	sd	s11,8(sp)
    80001ef6:	1880                	addi	s0,sp,112
    80001ef8:	8792                	mv	a5,tp
  int id = r_tp();
    80001efa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efc:	00779d93          	slli	s11,a5,0x7
    80001f00:	0000f717          	auipc	a4,0xf
    80001f04:	3a070713          	addi	a4,a4,928 # 800112a0 <pid_lock>
    80001f08:	976e                	add	a4,a4,s11
    80001f0a:	02073823          	sd	zero,48(a4)
        	swtch(&c->context, &tempP->context);
    80001f0e:	0000f717          	auipc	a4,0xf
    80001f12:	3ca70713          	addi	a4,a4,970 # 800112d8 <cpus+0x8>
    80001f16:	9dba                	add	s11,s11,a4
    struct proc *tempP = proc;
    80001f18:	0000fd17          	auipc	s10,0xf
    80001f1c:	7b8d0d13          	addi	s10,s10,1976 # 800116d0 <proc>
return (a< b) ? a : b;
    80001f20:	06300b93          	li	s7,99
        if(p->priority>topPrio && p->state == RUNNABLE){
    80001f24:	4b0d                	li	s6,3
        for(p = proc; p < &proc[NPROC]; p++) {
    80001f26:	00015a97          	auipc	s5,0x15
    80001f2a:	3aaa8a93          	addi	s5,s5,938 # 800172d0 <tickslock>
        	c->proc = tempP;
    80001f2e:	079e                	slli	a5,a5,0x7
    80001f30:	0000fc97          	auipc	s9,0xf
    80001f34:	370c8c93          	addi	s9,s9,880 # 800112a0 <pid_lock>
    80001f38:	9cbe                	add	s9,s9,a5
    80001f3a:	a88d                	j	80001fac <scheduler+0xd2>
        p->priority = effective_priority;// Update Priority after checking current prio
    80001f3c:	dc88                	sw	a0,56(s1)
        for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	17048493          	addi	s1,s1,368
    80001f42:	03548b63          	beq	s1,s5,80001f78 <scheduler+0x9e>
        effective_priority = min(MAXEFFPRIORITY, p->priority + (sys_uptime() - p->readytime)); // Get Aging number
    80001f46:	0384a903          	lw	s2,56(s1)
    80001f4a:	00001097          	auipc	ra,0x1
    80001f4e:	1d0080e7          	jalr	464(ra) # 8000311a <sys_uptime>
    80001f52:	0125053b          	addw	a0,a0,s2
    80001f56:	5cdc                	lw	a5,60(s1)
    80001f58:	9d1d                	subw	a0,a0,a5
return (a< b) ? a : b;
    80001f5a:	0005079b          	sext.w	a5,a0
    80001f5e:	00fa5363          	bge	s4,a5,80001f64 <scheduler+0x8a>
    80001f62:	855e                	mv	a0,s7
    80001f64:	2501                	sext.w	a0,a0
        if(p->priority>topPrio && p->state == RUNNABLE){
    80001f66:	5c9c                	lw	a5,56(s1)
    80001f68:	fcf9dae3          	bge	s3,a5,80001f3c <scheduler+0x62>
    80001f6c:	4c98                	lw	a4,24(s1)
    80001f6e:	fd6717e3          	bne	a4,s6,80001f3c <scheduler+0x62>
    80001f72:	8c26                	mv	s8,s1
        	topPrio = p->priority;
    80001f74:	89be                	mv	s3,a5
    80001f76:	b7d9                	j	80001f3c <scheduler+0x62>
              	acquire(&tempP->lock);
    80001f78:	8562                	mv	a0,s8
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	c56080e7          	jalr	-938(ra) # 80000bd0 <acquire>
        	tempP->state = RUNNING;
    80001f82:	4791                	li	a5,4
    80001f84:	00fc2c23          	sw	a5,24(s8)
        	tempP->priority = 0; // reset priority after time slice
    80001f88:	020c2c23          	sw	zero,56(s8)
        	c->proc = tempP;
    80001f8c:	038cb823          	sd	s8,48(s9)
        	swtch(&c->context, &tempP->context);
    80001f90:	068c0593          	addi	a1,s8,104
    80001f94:	856e                	mv	a0,s11
    80001f96:	00001097          	auipc	ra,0x1
    80001f9a:	92e080e7          	jalr	-1746(ra) # 800028c4 <swtch>
        	c->proc = 0;
    80001f9e:	020cb823          	sd	zero,48(s9)
      	release(&tempP->lock);
    80001fa2:	8562                	mv	a0,s8
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	ce0080e7          	jalr	-800(ra) # 80000c84 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb4:	10079073          	csrw	sstatus,a5
    struct proc *tempP = proc;
    80001fb8:	8c6a                	mv	s8,s10
    int topPrio = -1;
    80001fba:	59fd                	li	s3,-1
        for(p = proc; p < &proc[NPROC]; p++) {
    80001fbc:	84ea                	mv	s1,s10
return (a< b) ? a : b;
    80001fbe:	06300a13          	li	s4,99
    80001fc2:	b751                	j	80001f46 <scheduler+0x6c>

0000000080001fc4 <sched>:
{
    80001fc4:	7179                	addi	sp,sp,-48
    80001fc6:	f406                	sd	ra,40(sp)
    80001fc8:	f022                	sd	s0,32(sp)
    80001fca:	ec26                	sd	s1,24(sp)
    80001fcc:	e84a                	sd	s2,16(sp)
    80001fce:	e44e                	sd	s3,8(sp)
    80001fd0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	9c4080e7          	jalr	-1596(ra) # 80001996 <myproc>
    80001fda:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	b7a080e7          	jalr	-1158(ra) # 80000b56 <holding>
    80001fe4:	c93d                	beqz	a0,8000205a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fe8:	2781                	sext.w	a5,a5
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	0000f717          	auipc	a4,0xf
    80001ff0:	2b470713          	addi	a4,a4,692 # 800112a0 <pid_lock>
    80001ff4:	97ba                	add	a5,a5,a4
    80001ff6:	0a87a703          	lw	a4,168(a5)
    80001ffa:	4785                	li	a5,1
    80001ffc:	06f71763          	bne	a4,a5,8000206a <sched+0xa6>
  if(p->state == RUNNING)
    80002000:	4c98                	lw	a4,24(s1)
    80002002:	4791                	li	a5,4
    80002004:	06f70b63          	beq	a4,a5,8000207a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002008:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000200c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000200e:	efb5                	bnez	a5,8000208a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002010:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002012:	0000f917          	auipc	s2,0xf
    80002016:	28e90913          	addi	s2,s2,654 # 800112a0 <pid_lock>
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	97ca                	add	a5,a5,s2
    80002020:	0ac7a983          	lw	s3,172(a5)
    80002024:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002026:	2781                	sext.w	a5,a5
    80002028:	079e                	slli	a5,a5,0x7
    8000202a:	0000f597          	auipc	a1,0xf
    8000202e:	2ae58593          	addi	a1,a1,686 # 800112d8 <cpus+0x8>
    80002032:	95be                	add	a1,a1,a5
    80002034:	06848513          	addi	a0,s1,104
    80002038:	00001097          	auipc	ra,0x1
    8000203c:	88c080e7          	jalr	-1908(ra) # 800028c4 <swtch>
    80002040:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002042:	2781                	sext.w	a5,a5
    80002044:	079e                	slli	a5,a5,0x7
    80002046:	993e                	add	s2,s2,a5
    80002048:	0b392623          	sw	s3,172(s2)
}
    8000204c:	70a2                	ld	ra,40(sp)
    8000204e:	7402                	ld	s0,32(sp)
    80002050:	64e2                	ld	s1,24(sp)
    80002052:	6942                	ld	s2,16(sp)
    80002054:	69a2                	ld	s3,8(sp)
    80002056:	6145                	addi	sp,sp,48
    80002058:	8082                	ret
    panic("sched p->lock");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	1be50513          	addi	a0,a0,446 # 80008218 <digits+0x1d8>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	4d8080e7          	jalr	1240(ra) # 8000053a <panic>
    panic("sched locks");
    8000206a:	00006517          	auipc	a0,0x6
    8000206e:	1be50513          	addi	a0,a0,446 # 80008228 <digits+0x1e8>
    80002072:	ffffe097          	auipc	ra,0xffffe
    80002076:	4c8080e7          	jalr	1224(ra) # 8000053a <panic>
    panic("sched running");
    8000207a:	00006517          	auipc	a0,0x6
    8000207e:	1be50513          	addi	a0,a0,446 # 80008238 <digits+0x1f8>
    80002082:	ffffe097          	auipc	ra,0xffffe
    80002086:	4b8080e7          	jalr	1208(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000208a:	00006517          	auipc	a0,0x6
    8000208e:	1be50513          	addi	a0,a0,446 # 80008248 <digits+0x208>
    80002092:	ffffe097          	auipc	ra,0xffffe
    80002096:	4a8080e7          	jalr	1192(ra) # 8000053a <panic>

000000008000209a <yield>:
{
    8000209a:	1101                	addi	sp,sp,-32
    8000209c:	ec06                	sd	ra,24(sp)
    8000209e:	e822                	sd	s0,16(sp)
    800020a0:	e426                	sd	s1,8(sp)
    800020a2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020a4:	00000097          	auipc	ra,0x0
    800020a8:	8f2080e7          	jalr	-1806(ra) # 80001996 <myproc>
    800020ac:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b22080e7          	jalr	-1246(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    800020b6:	478d                	li	a5,3
    800020b8:	cc9c                	sw	a5,24(s1)
  p->readytime = sys_uptime();
    800020ba:	00001097          	auipc	ra,0x1
    800020be:	060080e7          	jalr	96(ra) # 8000311a <sys_uptime>
    800020c2:	dcc8                	sw	a0,60(s1)
  sched();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	f00080e7          	jalr	-256(ra) # 80001fc4 <sched>
  release(&p->lock);
    800020cc:	8526                	mv	a0,s1
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	bb6080e7          	jalr	-1098(ra) # 80000c84 <release>
}
    800020d6:	60e2                	ld	ra,24(sp)
    800020d8:	6442                	ld	s0,16(sp)
    800020da:	64a2                	ld	s1,8(sp)
    800020dc:	6105                	addi	sp,sp,32
    800020de:	8082                	ret

00000000800020e0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020e0:	7179                	addi	sp,sp,-48
    800020e2:	f406                	sd	ra,40(sp)
    800020e4:	f022                	sd	s0,32(sp)
    800020e6:	ec26                	sd	s1,24(sp)
    800020e8:	e84a                	sd	s2,16(sp)
    800020ea:	e44e                	sd	s3,8(sp)
    800020ec:	1800                	addi	s0,sp,48
    800020ee:	89aa                	mv	s3,a0
    800020f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	8a4080e7          	jalr	-1884(ra) # 80001996 <myproc>
    800020fa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ad4080e7          	jalr	-1324(ra) # 80000bd0 <acquire>
  release(lk);
    80002104:	854a                	mv	a0,s2
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b7e080e7          	jalr	-1154(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    8000210e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002112:	4789                	li	a5,2
    80002114:	cc9c                	sw	a5,24(s1)

  sched();
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	eae080e7          	jalr	-338(ra) # 80001fc4 <sched>

  // Tidy up.
  p->chan = 0;
    8000211e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	b60080e7          	jalr	-1184(ra) # 80000c84 <release>
  acquire(lk);
    8000212c:	854a                	mv	a0,s2
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	aa2080e7          	jalr	-1374(ra) # 80000bd0 <acquire>
}
    80002136:	70a2                	ld	ra,40(sp)
    80002138:	7402                	ld	s0,32(sp)
    8000213a:	64e2                	ld	s1,24(sp)
    8000213c:	6942                	ld	s2,16(sp)
    8000213e:	69a2                	ld	s3,8(sp)
    80002140:	6145                	addi	sp,sp,48
    80002142:	8082                	ret

0000000080002144 <wait>:
{
    80002144:	715d                	addi	sp,sp,-80
    80002146:	e486                	sd	ra,72(sp)
    80002148:	e0a2                	sd	s0,64(sp)
    8000214a:	fc26                	sd	s1,56(sp)
    8000214c:	f84a                	sd	s2,48(sp)
    8000214e:	f44e                	sd	s3,40(sp)
    80002150:	f052                	sd	s4,32(sp)
    80002152:	ec56                	sd	s5,24(sp)
    80002154:	e85a                	sd	s6,16(sp)
    80002156:	e45e                	sd	s7,8(sp)
    80002158:	e062                	sd	s8,0(sp)
    8000215a:	0880                	addi	s0,sp,80
    8000215c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	838080e7          	jalr	-1992(ra) # 80001996 <myproc>
    80002166:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	15050513          	addi	a0,a0,336 # 800112b8 <wait_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	a60080e7          	jalr	-1440(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002178:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000217a:	4a15                	li	s4,5
        havekids = 1;
    8000217c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000217e:	00015997          	auipc	s3,0x15
    80002182:	15298993          	addi	s3,s3,338 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002186:	0000fc17          	auipc	s8,0xf
    8000218a:	132c0c13          	addi	s8,s8,306 # 800112b8 <wait_lock>
    havekids = 0;
    8000218e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002190:	0000f497          	auipc	s1,0xf
    80002194:	54048493          	addi	s1,s1,1344 # 800116d0 <proc>
    80002198:	a0bd                	j	80002206 <wait+0xc2>
          pid = np->pid;
    8000219a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000219e:	000b0e63          	beqz	s6,800021ba <wait+0x76>
    800021a2:	4691                	li	a3,4
    800021a4:	02c48613          	addi	a2,s1,44
    800021a8:	85da                	mv	a1,s6
    800021aa:	05893503          	ld	a0,88(s2)
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	4ac080e7          	jalr	1196(ra) # 8000165a <copyout>
    800021b6:	02054563          	bltz	a0,800021e0 <wait+0x9c>
          freeproc(np);
    800021ba:	8526                	mv	a0,s1
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	98c080e7          	jalr	-1652(ra) # 80001b48 <freeproc>
          release(&np->lock);
    800021c4:	8526                	mv	a0,s1
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	abe080e7          	jalr	-1346(ra) # 80000c84 <release>
          release(&wait_lock);
    800021ce:	0000f517          	auipc	a0,0xf
    800021d2:	0ea50513          	addi	a0,a0,234 # 800112b8 <wait_lock>
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	aae080e7          	jalr	-1362(ra) # 80000c84 <release>
          return pid;
    800021de:	a09d                	j	80002244 <wait+0x100>
            release(&np->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	aa2080e7          	jalr	-1374(ra) # 80000c84 <release>
            release(&wait_lock);
    800021ea:	0000f517          	auipc	a0,0xf
    800021ee:	0ce50513          	addi	a0,a0,206 # 800112b8 <wait_lock>
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	a92080e7          	jalr	-1390(ra) # 80000c84 <release>
            return -1;
    800021fa:	59fd                	li	s3,-1
    800021fc:	a0a1                	j	80002244 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021fe:	17048493          	addi	s1,s1,368
    80002202:	03348463          	beq	s1,s3,8000222a <wait+0xe6>
      if(np->parent == p){
    80002206:	60bc                	ld	a5,64(s1)
    80002208:	ff279be3          	bne	a5,s2,800021fe <wait+0xba>
        acquire(&np->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	9c2080e7          	jalr	-1598(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002216:	4c9c                	lw	a5,24(s1)
    80002218:	f94781e3          	beq	a5,s4,8000219a <wait+0x56>
        release(&np->lock);
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	a66080e7          	jalr	-1434(ra) # 80000c84 <release>
        havekids = 1;
    80002226:	8756                	mv	a4,s5
    80002228:	bfd9                	j	800021fe <wait+0xba>
    if(!havekids || p->killed){
    8000222a:	c701                	beqz	a4,80002232 <wait+0xee>
    8000222c:	02892783          	lw	a5,40(s2)
    80002230:	c79d                	beqz	a5,8000225e <wait+0x11a>
      release(&wait_lock);
    80002232:	0000f517          	auipc	a0,0xf
    80002236:	08650513          	addi	a0,a0,134 # 800112b8 <wait_lock>
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a4a080e7          	jalr	-1462(ra) # 80000c84 <release>
      return -1;
    80002242:	59fd                	li	s3,-1
}
    80002244:	854e                	mv	a0,s3
    80002246:	60a6                	ld	ra,72(sp)
    80002248:	6406                	ld	s0,64(sp)
    8000224a:	74e2                	ld	s1,56(sp)
    8000224c:	7942                	ld	s2,48(sp)
    8000224e:	79a2                	ld	s3,40(sp)
    80002250:	7a02                	ld	s4,32(sp)
    80002252:	6ae2                	ld	s5,24(sp)
    80002254:	6b42                	ld	s6,16(sp)
    80002256:	6ba2                	ld	s7,8(sp)
    80002258:	6c02                	ld	s8,0(sp)
    8000225a:	6161                	addi	sp,sp,80
    8000225c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000225e:	85e2                	mv	a1,s8
    80002260:	854a                	mv	a0,s2
    80002262:	00000097          	auipc	ra,0x0
    80002266:	e7e080e7          	jalr	-386(ra) # 800020e0 <sleep>
    havekids = 0;
    8000226a:	b715                	j	8000218e <wait+0x4a>

000000008000226c <wait2>:
{
    8000226c:	7159                	addi	sp,sp,-112
    8000226e:	f486                	sd	ra,104(sp)
    80002270:	f0a2                	sd	s0,96(sp)
    80002272:	eca6                	sd	s1,88(sp)
    80002274:	e8ca                	sd	s2,80(sp)
    80002276:	e4ce                	sd	s3,72(sp)
    80002278:	e0d2                	sd	s4,64(sp)
    8000227a:	fc56                	sd	s5,56(sp)
    8000227c:	f85a                	sd	s6,48(sp)
    8000227e:	f45e                	sd	s7,40(sp)
    80002280:	f062                	sd	s8,32(sp)
    80002282:	ec66                	sd	s9,24(sp)
    80002284:	1880                	addi	s0,sp,112
    80002286:	8baa                	mv	s7,a0
    80002288:	8b2e                	mv	s6,a1
  struct proc *p = myproc();
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	70c080e7          	jalr	1804(ra) # 80001996 <myproc>
    80002292:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002294:	0000f517          	auipc	a0,0xf
    80002298:	02450513          	addi	a0,a0,36 # 800112b8 <wait_lock>
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	934080e7          	jalr	-1740(ra) # 80000bd0 <acquire>
    havekids = 0;
    800022a4:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    800022a6:	4a15                	li	s4,5
        havekids = 1;
    800022a8:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022aa:	00015997          	auipc	s3,0x15
    800022ae:	02698993          	addi	s3,s3,38 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022b2:	0000fc97          	auipc	s9,0xf
    800022b6:	006c8c93          	addi	s9,s9,6 # 800112b8 <wait_lock>
    havekids = 0;
    800022ba:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    800022bc:	0000f497          	auipc	s1,0xf
    800022c0:	41448493          	addi	s1,s1,1044 # 800116d0 <proc>
    800022c4:	a07d                	j	80002372 <wait2+0x106>
          pid = np->pid;
    800022c6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ca:	040b9663          	bnez	s7,80002316 <wait2+0xaa>
          cptime.cputime = np->cputime;
    800022ce:	58dc                	lw	a5,52(s1)
    800022d0:	f8f42c23          	sw	a5,-104(s0)
          if(addr1 != 0 && copyout(p->pagetable, addr1, (char *)&cptime,
    800022d4:	000b0e63          	beqz	s6,800022f0 <wait2+0x84>
    800022d8:	4691                	li	a3,4
    800022da:	f9840613          	addi	a2,s0,-104
    800022de:	85da                	mv	a1,s6
    800022e0:	05893503          	ld	a0,88(s2)
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	376080e7          	jalr	886(ra) # 8000165a <copyout>
    800022ec:	06054063          	bltz	a0,8000234c <wait2+0xe0>
          freeproc(np);
    800022f0:	8526                	mv	a0,s1
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	856080e7          	jalr	-1962(ra) # 80001b48 <freeproc>
          release(&np->lock);
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
          release(&wait_lock);
    80002304:	0000f517          	auipc	a0,0xf
    80002308:	fb450513          	addi	a0,a0,-76 # 800112b8 <wait_lock>
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	978080e7          	jalr	-1672(ra) # 80000c84 <release>
          return pid;
    80002314:	a871                	j	800023b0 <wait2+0x144>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002316:	4691                	li	a3,4
    80002318:	02c48613          	addi	a2,s1,44
    8000231c:	85de                	mv	a1,s7
    8000231e:	05893503          	ld	a0,88(s2)
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	338080e7          	jalr	824(ra) # 8000165a <copyout>
    8000232a:	fa0552e3          	bgez	a0,800022ce <wait2+0x62>
            release(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	954080e7          	jalr	-1708(ra) # 80000c84 <release>
            release(&wait_lock);
    80002338:	0000f517          	auipc	a0,0xf
    8000233c:	f8050513          	addi	a0,a0,-128 # 800112b8 <wait_lock>
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	944080e7          	jalr	-1724(ra) # 80000c84 <release>
            return -1;
    80002348:	59fd                	li	s3,-1
    8000234a:	a09d                	j	800023b0 <wait2+0x144>
            release(&np->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	936080e7          	jalr	-1738(ra) # 80000c84 <release>
            release(&wait_lock);
    80002356:	0000f517          	auipc	a0,0xf
    8000235a:	f6250513          	addi	a0,a0,-158 # 800112b8 <wait_lock>
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	926080e7          	jalr	-1754(ra) # 80000c84 <release>
            return -1;
    80002366:	59fd                	li	s3,-1
    80002368:	a0a1                	j	800023b0 <wait2+0x144>
    for(np = proc; np < &proc[NPROC]; np++){
    8000236a:	17048493          	addi	s1,s1,368
    8000236e:	03348463          	beq	s1,s3,80002396 <wait2+0x12a>
      if(np->parent == p){
    80002372:	60bc                	ld	a5,64(s1)
    80002374:	ff279be3          	bne	a5,s2,8000236a <wait2+0xfe>
        acquire(&np->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	856080e7          	jalr	-1962(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002382:	4c9c                	lw	a5,24(s1)
    80002384:	f54781e3          	beq	a5,s4,800022c6 <wait2+0x5a>
        release(&np->lock);
    80002388:	8526                	mv	a0,s1
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	8fa080e7          	jalr	-1798(ra) # 80000c84 <release>
        havekids = 1;
    80002392:	8756                	mv	a4,s5
    80002394:	bfd9                	j	8000236a <wait2+0xfe>
    if(!havekids || p->killed){
    80002396:	c701                	beqz	a4,8000239e <wait2+0x132>
    80002398:	02892783          	lw	a5,40(s2)
    8000239c:	cb85                	beqz	a5,800023cc <wait2+0x160>
      release(&wait_lock);
    8000239e:	0000f517          	auipc	a0,0xf
    800023a2:	f1a50513          	addi	a0,a0,-230 # 800112b8 <wait_lock>
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	8de080e7          	jalr	-1826(ra) # 80000c84 <release>
      return -1;
    800023ae:	59fd                	li	s3,-1
}
    800023b0:	854e                	mv	a0,s3
    800023b2:	70a6                	ld	ra,104(sp)
    800023b4:	7406                	ld	s0,96(sp)
    800023b6:	64e6                	ld	s1,88(sp)
    800023b8:	6946                	ld	s2,80(sp)
    800023ba:	69a6                	ld	s3,72(sp)
    800023bc:	6a06                	ld	s4,64(sp)
    800023be:	7ae2                	ld	s5,56(sp)
    800023c0:	7b42                	ld	s6,48(sp)
    800023c2:	7ba2                	ld	s7,40(sp)
    800023c4:	7c02                	ld	s8,32(sp)
    800023c6:	6ce2                	ld	s9,24(sp)
    800023c8:	6165                	addi	sp,sp,112
    800023ca:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023cc:	85e6                	mv	a1,s9
    800023ce:	854a                	mv	a0,s2
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	d10080e7          	jalr	-752(ra) # 800020e0 <sleep>
    havekids = 0;
    800023d8:	b5cd                	j	800022ba <wait2+0x4e>

00000000800023da <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023da:	7139                	addi	sp,sp,-64
    800023dc:	fc06                	sd	ra,56(sp)
    800023de:	f822                	sd	s0,48(sp)
    800023e0:	f426                	sd	s1,40(sp)
    800023e2:	f04a                	sd	s2,32(sp)
    800023e4:	ec4e                	sd	s3,24(sp)
    800023e6:	e852                	sd	s4,16(sp)
    800023e8:	e456                	sd	s5,8(sp)
    800023ea:	0080                	addi	s0,sp,64
    800023ec:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	2e248493          	addi	s1,s1,738 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023f6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023f8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fa:	00015917          	auipc	s2,0x15
    800023fe:	ed690913          	addi	s2,s2,-298 # 800172d0 <tickslock>
    80002402:	a811                	j	80002416 <wakeup+0x3c>
  	p->readytime = sys_uptime();
      }
      release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	87e080e7          	jalr	-1922(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240e:	17048493          	addi	s1,s1,368
    80002412:	03248b63          	beq	s1,s2,80002448 <wakeup+0x6e>
    if(p != myproc()){
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	580080e7          	jalr	1408(ra) # 80001996 <myproc>
    8000241e:	fea488e3          	beq	s1,a0,8000240e <wakeup+0x34>
      acquire(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7ac080e7          	jalr	1964(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000242c:	4c9c                	lw	a5,24(s1)
    8000242e:	fd379be3          	bne	a5,s3,80002404 <wakeup+0x2a>
    80002432:	709c                	ld	a5,32(s1)
    80002434:	fd4798e3          	bne	a5,s4,80002404 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002438:	0154ac23          	sw	s5,24(s1)
  	p->readytime = sys_uptime();
    8000243c:	00001097          	auipc	ra,0x1
    80002440:	cde080e7          	jalr	-802(ra) # 8000311a <sys_uptime>
    80002444:	dcc8                	sw	a0,60(s1)
    80002446:	bf7d                	j	80002404 <wakeup+0x2a>
    }
  }
}
    80002448:	70e2                	ld	ra,56(sp)
    8000244a:	7442                	ld	s0,48(sp)
    8000244c:	74a2                	ld	s1,40(sp)
    8000244e:	7902                	ld	s2,32(sp)
    80002450:	69e2                	ld	s3,24(sp)
    80002452:	6a42                	ld	s4,16(sp)
    80002454:	6aa2                	ld	s5,8(sp)
    80002456:	6121                	addi	sp,sp,64
    80002458:	8082                	ret

000000008000245a <reparent>:
{
    8000245a:	7179                	addi	sp,sp,-48
    8000245c:	f406                	sd	ra,40(sp)
    8000245e:	f022                	sd	s0,32(sp)
    80002460:	ec26                	sd	s1,24(sp)
    80002462:	e84a                	sd	s2,16(sp)
    80002464:	e44e                	sd	s3,8(sp)
    80002466:	e052                	sd	s4,0(sp)
    80002468:	1800                	addi	s0,sp,48
    8000246a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246c:	0000f497          	auipc	s1,0xf
    80002470:	26448493          	addi	s1,s1,612 # 800116d0 <proc>
      pp->parent = initproc;
    80002474:	00007a17          	auipc	s4,0x7
    80002478:	bb4a0a13          	addi	s4,s4,-1100 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000247c:	00015997          	auipc	s3,0x15
    80002480:	e5498993          	addi	s3,s3,-428 # 800172d0 <tickslock>
    80002484:	a029                	j	8000248e <reparent+0x34>
    80002486:	17048493          	addi	s1,s1,368
    8000248a:	01348d63          	beq	s1,s3,800024a4 <reparent+0x4a>
    if(pp->parent == p){
    8000248e:	60bc                	ld	a5,64(s1)
    80002490:	ff279be3          	bne	a5,s2,80002486 <reparent+0x2c>
      pp->parent = initproc;
    80002494:	000a3503          	ld	a0,0(s4)
    80002498:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	f40080e7          	jalr	-192(ra) # 800023da <wakeup>
    800024a2:	b7d5                	j	80002486 <reparent+0x2c>
}
    800024a4:	70a2                	ld	ra,40(sp)
    800024a6:	7402                	ld	s0,32(sp)
    800024a8:	64e2                	ld	s1,24(sp)
    800024aa:	6942                	ld	s2,16(sp)
    800024ac:	69a2                	ld	s3,8(sp)
    800024ae:	6a02                	ld	s4,0(sp)
    800024b0:	6145                	addi	sp,sp,48
    800024b2:	8082                	ret

00000000800024b4 <exit>:
{
    800024b4:	7179                	addi	sp,sp,-48
    800024b6:	f406                	sd	ra,40(sp)
    800024b8:	f022                	sd	s0,32(sp)
    800024ba:	ec26                	sd	s1,24(sp)
    800024bc:	e84a                	sd	s2,16(sp)
    800024be:	e44e                	sd	s3,8(sp)
    800024c0:	e052                	sd	s4,0(sp)
    800024c2:	1800                	addi	s0,sp,48
    800024c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	4d0080e7          	jalr	1232(ra) # 80001996 <myproc>
    800024ce:	89aa                	mv	s3,a0
  if(p == initproc)
    800024d0:	00007797          	auipc	a5,0x7
    800024d4:	b587b783          	ld	a5,-1192(a5) # 80009028 <initproc>
    800024d8:	0d850493          	addi	s1,a0,216
    800024dc:	15850913          	addi	s2,a0,344
    800024e0:	02a79363          	bne	a5,a0,80002506 <exit+0x52>
    panic("init exiting");
    800024e4:	00006517          	auipc	a0,0x6
    800024e8:	d7c50513          	addi	a0,a0,-644 # 80008260 <digits+0x220>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	04e080e7          	jalr	78(ra) # 8000053a <panic>
      fileclose(f);
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	3ce080e7          	jalr	974(ra) # 800048c2 <fileclose>
      p->ofile[fd] = 0;
    800024fc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002500:	04a1                	addi	s1,s1,8
    80002502:	01248563          	beq	s1,s2,8000250c <exit+0x58>
    if(p->ofile[fd]){
    80002506:	6088                	ld	a0,0(s1)
    80002508:	f575                	bnez	a0,800024f4 <exit+0x40>
    8000250a:	bfdd                	j	80002500 <exit+0x4c>
  begin_op();
    8000250c:	00002097          	auipc	ra,0x2
    80002510:	eee080e7          	jalr	-274(ra) # 800043fa <begin_op>
  iput(p->cwd);
    80002514:	1589b503          	ld	a0,344(s3)
    80002518:	00001097          	auipc	ra,0x1
    8000251c:	6c0080e7          	jalr	1728(ra) # 80003bd8 <iput>
  end_op();
    80002520:	00002097          	auipc	ra,0x2
    80002524:	f58080e7          	jalr	-168(ra) # 80004478 <end_op>
  p->cwd = 0;
    80002528:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000252c:	0000f497          	auipc	s1,0xf
    80002530:	d8c48493          	addi	s1,s1,-628 # 800112b8 <wait_lock>
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	69a080e7          	jalr	1690(ra) # 80000bd0 <acquire>
  reparent(p);
    8000253e:	854e                	mv	a0,s3
    80002540:	00000097          	auipc	ra,0x0
    80002544:	f1a080e7          	jalr	-230(ra) # 8000245a <reparent>
  wakeup(p->parent);
    80002548:	0409b503          	ld	a0,64(s3)
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	e8e080e7          	jalr	-370(ra) # 800023da <wakeup>
  acquire(&p->lock);
    80002554:	854e                	mv	a0,s3
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	67a080e7          	jalr	1658(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000255e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002562:	4795                	li	a5,5
    80002564:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	71a080e7          	jalr	1818(ra) # 80000c84 <release>
  sched();
    80002572:	00000097          	auipc	ra,0x0
    80002576:	a52080e7          	jalr	-1454(ra) # 80001fc4 <sched>
  panic("zombie exit");
    8000257a:	00006517          	auipc	a0,0x6
    8000257e:	cf650513          	addi	a0,a0,-778 # 80008270 <digits+0x230>
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	fb8080e7          	jalr	-72(ra) # 8000053a <panic>

000000008000258a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000258a:	7179                	addi	sp,sp,-48
    8000258c:	f406                	sd	ra,40(sp)
    8000258e:	f022                	sd	s0,32(sp)
    80002590:	ec26                	sd	s1,24(sp)
    80002592:	e84a                	sd	s2,16(sp)
    80002594:	e44e                	sd	s3,8(sp)
    80002596:	1800                	addi	s0,sp,48
    80002598:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000259a:	0000f497          	auipc	s1,0xf
    8000259e:	13648493          	addi	s1,s1,310 # 800116d0 <proc>
    800025a2:	00015997          	auipc	s3,0x15
    800025a6:	d2e98993          	addi	s3,s3,-722 # 800172d0 <tickslock>
    acquire(&p->lock);
    800025aa:	8526                	mv	a0,s1
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	624080e7          	jalr	1572(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800025b4:	589c                	lw	a5,48(s1)
    800025b6:	01278d63          	beq	a5,s2,800025d0 <kill+0x46>
  	p->readytime = sys_uptime();
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6c8080e7          	jalr	1736(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c4:	17048493          	addi	s1,s1,368
    800025c8:	ff3491e3          	bne	s1,s3,800025aa <kill+0x20>
  }
  return -1;
    800025cc:	557d                	li	a0,-1
    800025ce:	a829                	j	800025e8 <kill+0x5e>
      p->killed = 1;
    800025d0:	4785                	li	a5,1
    800025d2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025d4:	4c98                	lw	a4,24(s1)
    800025d6:	4789                	li	a5,2
    800025d8:	00f70f63          	beq	a4,a5,800025f6 <kill+0x6c>
      release(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6a6080e7          	jalr	1702(ra) # 80000c84 <release>
      return 0;
    800025e6:	4501                	li	a0,0
}
    800025e8:	70a2                	ld	ra,40(sp)
    800025ea:	7402                	ld	s0,32(sp)
    800025ec:	64e2                	ld	s1,24(sp)
    800025ee:	6942                	ld	s2,16(sp)
    800025f0:	69a2                	ld	s3,8(sp)
    800025f2:	6145                	addi	sp,sp,48
    800025f4:	8082                	ret
  	p->state = RUNNABLE;
    800025f6:	478d                	li	a5,3
    800025f8:	cc9c                	sw	a5,24(s1)
  	p->readytime = sys_uptime();
    800025fa:	00001097          	auipc	ra,0x1
    800025fe:	b20080e7          	jalr	-1248(ra) # 8000311a <sys_uptime>
    80002602:	dcc8                	sw	a0,60(s1)
    80002604:	bfe1                	j	800025dc <kill+0x52>

0000000080002606 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002606:	7179                	addi	sp,sp,-48
    80002608:	f406                	sd	ra,40(sp)
    8000260a:	f022                	sd	s0,32(sp)
    8000260c:	ec26                	sd	s1,24(sp)
    8000260e:	e84a                	sd	s2,16(sp)
    80002610:	e44e                	sd	s3,8(sp)
    80002612:	e052                	sd	s4,0(sp)
    80002614:	1800                	addi	s0,sp,48
    80002616:	84aa                	mv	s1,a0
    80002618:	892e                	mv	s2,a1
    8000261a:	89b2                	mv	s3,a2
    8000261c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000261e:	fffff097          	auipc	ra,0xfffff
    80002622:	378080e7          	jalr	888(ra) # 80001996 <myproc>
  if(user_dst){
    80002626:	c08d                	beqz	s1,80002648 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002628:	86d2                	mv	a3,s4
    8000262a:	864e                	mv	a2,s3
    8000262c:	85ca                	mv	a1,s2
    8000262e:	6d28                	ld	a0,88(a0)
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	02a080e7          	jalr	42(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002638:	70a2                	ld	ra,40(sp)
    8000263a:	7402                	ld	s0,32(sp)
    8000263c:	64e2                	ld	s1,24(sp)
    8000263e:	6942                	ld	s2,16(sp)
    80002640:	69a2                	ld	s3,8(sp)
    80002642:	6a02                	ld	s4,0(sp)
    80002644:	6145                	addi	sp,sp,48
    80002646:	8082                	ret
    memmove((char *)dst, src, len);
    80002648:	000a061b          	sext.w	a2,s4
    8000264c:	85ce                	mv	a1,s3
    8000264e:	854a                	mv	a0,s2
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	6d8080e7          	jalr	1752(ra) # 80000d28 <memmove>
    return 0;
    80002658:	8526                	mv	a0,s1
    8000265a:	bff9                	j	80002638 <either_copyout+0x32>

000000008000265c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000265c:	7179                	addi	sp,sp,-48
    8000265e:	f406                	sd	ra,40(sp)
    80002660:	f022                	sd	s0,32(sp)
    80002662:	ec26                	sd	s1,24(sp)
    80002664:	e84a                	sd	s2,16(sp)
    80002666:	e44e                	sd	s3,8(sp)
    80002668:	e052                	sd	s4,0(sp)
    8000266a:	1800                	addi	s0,sp,48
    8000266c:	892a                	mv	s2,a0
    8000266e:	84ae                	mv	s1,a1
    80002670:	89b2                	mv	s3,a2
    80002672:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	322080e7          	jalr	802(ra) # 80001996 <myproc>
  if(user_src){
    8000267c:	c08d                	beqz	s1,8000269e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000267e:	86d2                	mv	a3,s4
    80002680:	864e                	mv	a2,s3
    80002682:	85ca                	mv	a1,s2
    80002684:	6d28                	ld	a0,88(a0)
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	060080e7          	jalr	96(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000268e:	70a2                	ld	ra,40(sp)
    80002690:	7402                	ld	s0,32(sp)
    80002692:	64e2                	ld	s1,24(sp)
    80002694:	6942                	ld	s2,16(sp)
    80002696:	69a2                	ld	s3,8(sp)
    80002698:	6a02                	ld	s4,0(sp)
    8000269a:	6145                	addi	sp,sp,48
    8000269c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000269e:	000a061b          	sext.w	a2,s4
    800026a2:	85ce                	mv	a1,s3
    800026a4:	854a                	mv	a0,s2
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	682080e7          	jalr	1666(ra) # 80000d28 <memmove>
    return 0;
    800026ae:	8526                	mv	a0,s1
    800026b0:	bff9                	j	8000268e <either_copyin+0x32>

00000000800026b2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026b2:	715d                	addi	sp,sp,-80
    800026b4:	e486                	sd	ra,72(sp)
    800026b6:	e0a2                	sd	s0,64(sp)
    800026b8:	fc26                	sd	s1,56(sp)
    800026ba:	f84a                	sd	s2,48(sp)
    800026bc:	f44e                	sd	s3,40(sp)
    800026be:	f052                	sd	s4,32(sp)
    800026c0:	ec56                	sd	s5,24(sp)
    800026c2:	e85a                	sd	s6,16(sp)
    800026c4:	e45e                	sd	s7,8(sp)
    800026c6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026c8:	00006517          	auipc	a0,0x6
    800026cc:	a0050513          	addi	a0,a0,-1536 # 800080c8 <digits+0x88>
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	eb4080e7          	jalr	-332(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026d8:	0000f497          	auipc	s1,0xf
    800026dc:	15848493          	addi	s1,s1,344 # 80011830 <proc+0x160>
    800026e0:	00015917          	auipc	s2,0x15
    800026e4:	d5090913          	addi	s2,s2,-688 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026ea:	00006997          	auipc	s3,0x6
    800026ee:	b9698993          	addi	s3,s3,-1130 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800026f2:	00006a97          	auipc	s5,0x6
    800026f6:	b96a8a93          	addi	s5,s5,-1130 # 80008288 <digits+0x248>
    printf("\n");
    800026fa:	00006a17          	auipc	s4,0x6
    800026fe:	9cea0a13          	addi	s4,s4,-1586 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002702:	00006b97          	auipc	s7,0x6
    80002706:	bbeb8b93          	addi	s7,s7,-1090 # 800082c0 <states.0>
    8000270a:	a00d                	j	8000272c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000270c:	ed06a583          	lw	a1,-304(a3)
    80002710:	8556                	mv	a0,s5
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	e72080e7          	jalr	-398(ra) # 80000584 <printf>
    printf("\n");
    8000271a:	8552                	mv	a0,s4
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	e68080e7          	jalr	-408(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002724:	17048493          	addi	s1,s1,368
    80002728:	03248263          	beq	s1,s2,8000274c <procdump+0x9a>
    if(p->state == UNUSED)
    8000272c:	86a6                	mv	a3,s1
    8000272e:	eb84a783          	lw	a5,-328(s1)
    80002732:	dbed                	beqz	a5,80002724 <procdump+0x72>
      state = "???";
    80002734:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002736:	fcfb6be3          	bltu	s6,a5,8000270c <procdump+0x5a>
    8000273a:	02079713          	slli	a4,a5,0x20
    8000273e:	01d75793          	srli	a5,a4,0x1d
    80002742:	97de                	add	a5,a5,s7
    80002744:	6390                	ld	a2,0(a5)
    80002746:	f279                	bnez	a2,8000270c <procdump+0x5a>
      state = "???";
    80002748:	864e                	mv	a2,s3
    8000274a:	b7c9                	j	8000270c <procdump+0x5a>
  }
}
    8000274c:	60a6                	ld	ra,72(sp)
    8000274e:	6406                	ld	s0,64(sp)
    80002750:	74e2                	ld	s1,56(sp)
    80002752:	7942                	ld	s2,48(sp)
    80002754:	79a2                	ld	s3,40(sp)
    80002756:	7a02                	ld	s4,32(sp)
    80002758:	6ae2                	ld	s5,24(sp)
    8000275a:	6b42                	ld	s6,16(sp)
    8000275c:	6ba2                	ld	s7,8(sp)
    8000275e:	6161                	addi	sp,sp,80
    80002760:	8082                	ret

0000000080002762 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    80002762:	7119                	addi	sp,sp,-128
    80002764:	fc86                	sd	ra,120(sp)
    80002766:	f8a2                	sd	s0,112(sp)
    80002768:	f4a6                	sd	s1,104(sp)
    8000276a:	f0ca                	sd	s2,96(sp)
    8000276c:	ecce                	sd	s3,88(sp)
    8000276e:	e8d2                	sd	s4,80(sp)
    80002770:	e4d6                	sd	s5,72(sp)
    80002772:	e0da                	sd	s6,64(sp)
    80002774:	fc5e                	sd	s7,56(sp)
    80002776:	0100                	addi	s0,sp,128
    80002778:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	21c080e7          	jalr	540(ra) # 80001996 <myproc>
    80002782:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002784:	0000f917          	auipc	s2,0xf
    80002788:	0ac90913          	addi	s2,s2,172 # 80011830 <proc+0x160>
    8000278c:	00015a17          	auipc	s4,0x15
    80002790:	ca4a0a13          	addi	s4,s4,-860 # 80017430 <bcache+0x148>
  int nprocs = 0;
    80002794:	4a81                	li	s5,0
    procinfo.priority = p->priority;
    procinfo.readytime = p->readytime;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    80002796:	4b81                	li	s7,0
    80002798:	fa440493          	addi	s1,s0,-92
    8000279c:	a089                	j	800027de <procinfo+0x7c>
    8000279e:	f8f42823          	sw	a5,-112(s0)
    for (int i=0; i<16; i++)
    800027a2:	f9440793          	addi	a5,s0,-108
      procinfo.ppid = 0;
    800027a6:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    800027a8:	00074683          	lbu	a3,0(a4)
    800027ac:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    800027b0:	0705                	addi	a4,a4,1
    800027b2:	0785                	addi	a5,a5,1
    800027b4:	fe979ae3          	bne	a5,s1,800027a8 <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    800027b8:	03000693          	li	a3,48
    800027bc:	f8040613          	addi	a2,s0,-128
    800027c0:	85ce                	mv	a1,s3
    800027c2:	058b3503          	ld	a0,88(s6)
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	e94080e7          	jalr	-364(ra) # 8000165a <copyout>
    800027ce:	04054463          	bltz	a0,80002816 <procinfo+0xb4>
      return -1;
    addr += sizeof(procinfo);
    800027d2:	03098993          	addi	s3,s3,48
  for(p = proc; p < &proc[NPROC]; p++){ 
    800027d6:	17090913          	addi	s2,s2,368
    800027da:	03490f63          	beq	s2,s4,80002818 <procinfo+0xb6>
    if(p->state == UNUSED)
    800027de:	eb892783          	lw	a5,-328(s2)
    800027e2:	dbf5                	beqz	a5,800027d6 <procinfo+0x74>
    nprocs++;
    800027e4:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    800027e6:	ed092703          	lw	a4,-304(s2)
    800027ea:	f8e42023          	sw	a4,-128(s0)
    procinfo.state = p->state;
    800027ee:	f8f42223          	sw	a5,-124(s0)
    procinfo.size = p->sz;
    800027f2:	ef093783          	ld	a5,-272(s2)
    800027f6:	f8f43423          	sd	a5,-120(s0)
    procinfo.priority = p->priority;
    800027fa:	ed892783          	lw	a5,-296(s2)
    800027fe:	faf42223          	sw	a5,-92(s0)
    procinfo.readytime = p->readytime;
    80002802:	edc92783          	lw	a5,-292(s2)
    80002806:	faf42423          	sw	a5,-88(s0)
    if (p->parent)
    8000280a:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    8000280e:	87de                	mv	a5,s7
    if (p->parent)
    80002810:	d759                	beqz	a4,8000279e <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    80002812:	5b1c                	lw	a5,48(a4)
    80002814:	b769                	j	8000279e <procinfo+0x3c>
      return -1;
    80002816:	5afd                	li	s5,-1
  }
  return nprocs;
}
    80002818:	8556                	mv	a0,s5
    8000281a:	70e6                	ld	ra,120(sp)
    8000281c:	7446                	ld	s0,112(sp)
    8000281e:	74a6                	ld	s1,104(sp)
    80002820:	7906                	ld	s2,96(sp)
    80002822:	69e6                	ld	s3,88(sp)
    80002824:	6a46                	ld	s4,80(sp)
    80002826:	6aa6                	ld	s5,72(sp)
    80002828:	6b06                	ld	s6,64(sp)
    8000282a:	7be2                	ld	s7,56(sp)
    8000282c:	6109                	addi	sp,sp,128
    8000282e:	8082                	ret

0000000080002830 <getpriority>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
getpriority(uint64 addr)
{
    80002830:	7179                	addi	sp,sp,-48
    80002832:	f406                	sd	ra,40(sp)
    80002834:	f022                	sd	s0,32(sp)
    80002836:	ec26                	sd	s1,24(sp)
    80002838:	e84a                	sd	s2,16(sp)
    8000283a:	1800                	addi	s0,sp,48
    8000283c:	84aa                	mv	s1,a0
  struct proc *thisproc = myproc();
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	158080e7          	jalr	344(ra) # 80001996 <myproc>
  struct ruprio priority;
  int pid;
  pid = thisproc->pid;
    80002846:	03052903          	lw	s2,48(a0)
  priority.priority = thisproc->priority;
    8000284a:	5d1c                	lw	a5,56(a0)
    8000284c:	fcf42c23          	sw	a5,-40(s0)
   if (addr != 0 && copyout(thisproc->pagetable, addr, (char *)&priority, sizeof(priority)) < 0){
    80002850:	e881                	bnez	s1,80002860 <getpriority+0x30>
      return -1;
  }
  return pid;
}
    80002852:	854a                	mv	a0,s2
    80002854:	70a2                	ld	ra,40(sp)
    80002856:	7402                	ld	s0,32(sp)
    80002858:	64e2                	ld	s1,24(sp)
    8000285a:	6942                	ld	s2,16(sp)
    8000285c:	6145                	addi	sp,sp,48
    8000285e:	8082                	ret
   if (addr != 0 && copyout(thisproc->pagetable, addr, (char *)&priority, sizeof(priority)) < 0){
    80002860:	4691                	li	a3,4
    80002862:	fd840613          	addi	a2,s0,-40
    80002866:	85a6                	mv	a1,s1
    80002868:	6d28                	ld	a0,88(a0)
    8000286a:	fffff097          	auipc	ra,0xfffff
    8000286e:	df0080e7          	jalr	-528(ra) # 8000165a <copyout>
    80002872:	fe0550e3          	bgez	a0,80002852 <getpriority+0x22>
      return -1;
    80002876:	597d                	li	s2,-1
    80002878:	bfe9                	j	80002852 <getpriority+0x22>

000000008000287a <setpriority>:

int
setpriority(uint64 addr)
{
    8000287a:	7179                	addi	sp,sp,-48
    8000287c:	f406                	sd	ra,40(sp)
    8000287e:	f022                	sd	s0,32(sp)
    80002880:	ec26                	sd	s1,24(sp)
    80002882:	e84a                	sd	s2,16(sp)
    80002884:	e44e                	sd	s3,8(sp)
    80002886:	1800                	addi	s0,sp,48
    80002888:	892a                	mv	s2,a0
  struct proc *thisproc = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	10c080e7          	jalr	268(ra) # 80001996 <myproc>
  int pid;
  pid = thisproc->pid;
    80002892:	03052983          	lw	s3,48(a0)
  int *temp =0;
   if (addr != 0){
    80002896:	00091a63          	bnez	s2,800028aa <setpriority+0x30>
   //either_copyin(void *dst, int user_src, uint64 src, uint64 len)
   either_copyin(temp,1,addr,8);
   thisproc->priority = *temp;
  }
  return pid;
}
    8000289a:	854e                	mv	a0,s3
    8000289c:	70a2                	ld	ra,40(sp)
    8000289e:	7402                	ld	s0,32(sp)
    800028a0:	64e2                	ld	s1,24(sp)
    800028a2:	6942                	ld	s2,16(sp)
    800028a4:	69a2                	ld	s3,8(sp)
    800028a6:	6145                	addi	sp,sp,48
    800028a8:	8082                	ret
    800028aa:	84aa                	mv	s1,a0
   either_copyin(temp,1,addr,8);
    800028ac:	46a1                	li	a3,8
    800028ae:	864a                	mv	a2,s2
    800028b0:	4585                	li	a1,1
    800028b2:	4501                	li	a0,0
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	da8080e7          	jalr	-600(ra) # 8000265c <either_copyin>
   thisproc->priority = *temp;
    800028bc:	00002783          	lw	a5,0(zero) # 0 <_entry-0x80000000>
    800028c0:	dc9c                	sw	a5,56(s1)
    800028c2:	bfe1                	j	8000289a <setpriority+0x20>

00000000800028c4 <swtch>:
    800028c4:	00153023          	sd	ra,0(a0)
    800028c8:	00253423          	sd	sp,8(a0)
    800028cc:	e900                	sd	s0,16(a0)
    800028ce:	ed04                	sd	s1,24(a0)
    800028d0:	03253023          	sd	s2,32(a0)
    800028d4:	03353423          	sd	s3,40(a0)
    800028d8:	03453823          	sd	s4,48(a0)
    800028dc:	03553c23          	sd	s5,56(a0)
    800028e0:	05653023          	sd	s6,64(a0)
    800028e4:	05753423          	sd	s7,72(a0)
    800028e8:	05853823          	sd	s8,80(a0)
    800028ec:	05953c23          	sd	s9,88(a0)
    800028f0:	07a53023          	sd	s10,96(a0)
    800028f4:	07b53423          	sd	s11,104(a0)
    800028f8:	0005b083          	ld	ra,0(a1)
    800028fc:	0085b103          	ld	sp,8(a1)
    80002900:	6980                	ld	s0,16(a1)
    80002902:	6d84                	ld	s1,24(a1)
    80002904:	0205b903          	ld	s2,32(a1)
    80002908:	0285b983          	ld	s3,40(a1)
    8000290c:	0305ba03          	ld	s4,48(a1)
    80002910:	0385ba83          	ld	s5,56(a1)
    80002914:	0405bb03          	ld	s6,64(a1)
    80002918:	0485bb83          	ld	s7,72(a1)
    8000291c:	0505bc03          	ld	s8,80(a1)
    80002920:	0585bc83          	ld	s9,88(a1)
    80002924:	0605bd03          	ld	s10,96(a1)
    80002928:	0685bd83          	ld	s11,104(a1)
    8000292c:	8082                	ret

000000008000292e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000292e:	1141                	addi	sp,sp,-16
    80002930:	e406                	sd	ra,8(sp)
    80002932:	e022                	sd	s0,0(sp)
    80002934:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002936:	00006597          	auipc	a1,0x6
    8000293a:	9ba58593          	addi	a1,a1,-1606 # 800082f0 <states.0+0x30>
    8000293e:	00015517          	auipc	a0,0x15
    80002942:	99250513          	addi	a0,a0,-1646 # 800172d0 <tickslock>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	1fa080e7          	jalr	506(ra) # 80000b40 <initlock>
}
    8000294e:	60a2                	ld	ra,8(sp)
    80002950:	6402                	ld	s0,0(sp)
    80002952:	0141                	addi	sp,sp,16
    80002954:	8082                	ret

0000000080002956 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002956:	1141                	addi	sp,sp,-16
    80002958:	e422                	sd	s0,8(sp)
    8000295a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000295c:	00003797          	auipc	a5,0x3
    80002960:	59478793          	addi	a5,a5,1428 # 80005ef0 <kernelvec>
    80002964:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002968:	6422                	ld	s0,8(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000296e:	1141                	addi	sp,sp,-16
    80002970:	e406                	sd	ra,8(sp)
    80002972:	e022                	sd	s0,0(sp)
    80002974:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	020080e7          	jalr	32(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002982:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002984:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002988:	00004697          	auipc	a3,0x4
    8000298c:	67868693          	addi	a3,a3,1656 # 80007000 <_trampoline>
    80002990:	00004717          	auipc	a4,0x4
    80002994:	67070713          	addi	a4,a4,1648 # 80007000 <_trampoline>
    80002998:	8f15                	sub	a4,a4,a3
    8000299a:	040007b7          	lui	a5,0x4000
    8000299e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029a0:	07b2                	slli	a5,a5,0xc
    800029a2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a4:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029a8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029aa:	18002673          	csrr	a2,satp
    800029ae:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029b0:	7130                	ld	a2,96(a0)
    800029b2:	6538                	ld	a4,72(a0)
    800029b4:	6585                	lui	a1,0x1
    800029b6:	972e                	add	a4,a4,a1
    800029b8:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ba:	7138                	ld	a4,96(a0)
    800029bc:	00000617          	auipc	a2,0x0
    800029c0:	13860613          	addi	a2,a2,312 # 80002af4 <usertrap>
    800029c4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029c6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c8:	8612                	mv	a2,tp
    800029ca:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029cc:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029d0:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029d4:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029dc:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029de:	6f18                	ld	a4,24(a4)
    800029e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029e4:	6d2c                	ld	a1,88(a0)
    800029e6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029e8:	00004717          	auipc	a4,0x4
    800029ec:	6a870713          	addi	a4,a4,1704 # 80007090 <userret>
    800029f0:	8f15                	sub	a4,a4,a3
    800029f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029f4:	577d                	li	a4,-1
    800029f6:	177e                	slli	a4,a4,0x3f
    800029f8:	8dd9                	or	a1,a1,a4
    800029fa:	02000537          	lui	a0,0x2000
    800029fe:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a00:	0536                	slli	a0,a0,0xd
    80002a02:	9782                	jalr	a5
}
    80002a04:	60a2                	ld	ra,8(sp)
    80002a06:	6402                	ld	s0,0(sp)
    80002a08:	0141                	addi	sp,sp,16
    80002a0a:	8082                	ret

0000000080002a0c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a0c:	1101                	addi	sp,sp,-32
    80002a0e:	ec06                	sd	ra,24(sp)
    80002a10:	e822                	sd	s0,16(sp)
    80002a12:	e426                	sd	s1,8(sp)
    80002a14:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a16:	00015497          	auipc	s1,0x15
    80002a1a:	8ba48493          	addi	s1,s1,-1862 # 800172d0 <tickslock>
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  ticks++;
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	60850513          	addi	a0,a0,1544 # 80009030 <ticks>
    80002a30:	411c                	lw	a5,0(a0)
    80002a32:	2785                	addiw	a5,a5,1
    80002a34:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	9a4080e7          	jalr	-1628(ra) # 800023da <wakeup>
  release(&tickslock);
    80002a3e:	8526                	mv	a0,s1
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	244080e7          	jalr	580(ra) # 80000c84 <release>
}
    80002a48:	60e2                	ld	ra,24(sp)
    80002a4a:	6442                	ld	s0,16(sp)
    80002a4c:	64a2                	ld	s1,8(sp)
    80002a4e:	6105                	addi	sp,sp,32
    80002a50:	8082                	ret

0000000080002a52 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a5c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a60:	00074d63          	bltz	a4,80002a7a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a64:	57fd                	li	a5,-1
    80002a66:	17fe                	slli	a5,a5,0x3f
    80002a68:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a6a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a6c:	06f70363          	beq	a4,a5,80002ad2 <devintr+0x80>
  }
}
    80002a70:	60e2                	ld	ra,24(sp)
    80002a72:	6442                	ld	s0,16(sp)
    80002a74:	64a2                	ld	s1,8(sp)
    80002a76:	6105                	addi	sp,sp,32
    80002a78:	8082                	ret
     (scause & 0xff) == 9){
    80002a7a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002a7e:	46a5                	li	a3,9
    80002a80:	fed792e3          	bne	a5,a3,80002a64 <devintr+0x12>
    int irq = plic_claim();
    80002a84:	00003097          	auipc	ra,0x3
    80002a88:	574080e7          	jalr	1396(ra) # 80005ff8 <plic_claim>
    80002a8c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a8e:	47a9                	li	a5,10
    80002a90:	02f50763          	beq	a0,a5,80002abe <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a94:	4785                	li	a5,1
    80002a96:	02f50963          	beq	a0,a5,80002ac8 <devintr+0x76>
    return 1;
    80002a9a:	4505                	li	a0,1
    } else if(irq){
    80002a9c:	d8f1                	beqz	s1,80002a70 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a9e:	85a6                	mv	a1,s1
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	85850513          	addi	a0,a0,-1960 # 800082f8 <states.0+0x38>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	adc080e7          	jalr	-1316(ra) # 80000584 <printf>
      plic_complete(irq);
    80002ab0:	8526                	mv	a0,s1
    80002ab2:	00003097          	auipc	ra,0x3
    80002ab6:	56a080e7          	jalr	1386(ra) # 8000601c <plic_complete>
    return 1;
    80002aba:	4505                	li	a0,1
    80002abc:	bf55                	j	80002a70 <devintr+0x1e>
      uartintr();
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	ed4080e7          	jalr	-300(ra) # 80000992 <uartintr>
    80002ac6:	b7ed                	j	80002ab0 <devintr+0x5e>
      virtio_disk_intr();
    80002ac8:	00004097          	auipc	ra,0x4
    80002acc:	9e0080e7          	jalr	-1568(ra) # 800064a8 <virtio_disk_intr>
    80002ad0:	b7c5                	j	80002ab0 <devintr+0x5e>
    if(cpuid() == 0){
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	e98080e7          	jalr	-360(ra) # 8000196a <cpuid>
    80002ada:	c901                	beqz	a0,80002aea <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002adc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ae0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ae2:	14479073          	csrw	sip,a5
    return 2;
    80002ae6:	4509                	li	a0,2
    80002ae8:	b761                	j	80002a70 <devintr+0x1e>
      clockintr();
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	f22080e7          	jalr	-222(ra) # 80002a0c <clockintr>
    80002af2:	b7ed                	j	80002adc <devintr+0x8a>

0000000080002af4 <usertrap>:
{
    80002af4:	1101                	addi	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	e426                	sd	s1,8(sp)
    80002afc:	e04a                	sd	s2,0(sp)
    80002afe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b00:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b04:	1007f793          	andi	a5,a5,256
    80002b08:	e3ad                	bnez	a5,80002b6a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b0a:	00003797          	auipc	a5,0x3
    80002b0e:	3e678793          	addi	a5,a5,998 # 80005ef0 <kernelvec>
    80002b12:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	e80080e7          	jalr	-384(ra) # 80001996 <myproc>
    80002b1e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b20:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b22:	14102773          	csrr	a4,sepc
    80002b26:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b28:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b2c:	47a1                	li	a5,8
    80002b2e:	04f71c63          	bne	a4,a5,80002b86 <usertrap+0x92>
    if(p->killed)
    80002b32:	551c                	lw	a5,40(a0)
    80002b34:	e3b9                	bnez	a5,80002b7a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b36:	70b8                	ld	a4,96(s1)
    80002b38:	6f1c                	ld	a5,24(a4)
    80002b3a:	0791                	addi	a5,a5,4
    80002b3c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b46:	10079073          	csrw	sstatus,a5
    syscall();
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	2f4080e7          	jalr	756(ra) # 80002e3e <syscall>
  if(p->killed)
    80002b52:	549c                	lw	a5,40(s1)
    80002b54:	ebd9                	bnez	a5,80002bea <usertrap+0xf6>
  usertrapret();
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	e18080e7          	jalr	-488(ra) # 8000296e <usertrapret>
}
    80002b5e:	60e2                	ld	ra,24(sp)
    80002b60:	6442                	ld	s0,16(sp)
    80002b62:	64a2                	ld	s1,8(sp)
    80002b64:	6902                	ld	s2,0(sp)
    80002b66:	6105                	addi	sp,sp,32
    80002b68:	8082                	ret
    panic("usertrap: not from user mode");
    80002b6a:	00005517          	auipc	a0,0x5
    80002b6e:	7ae50513          	addi	a0,a0,1966 # 80008318 <states.0+0x58>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	9c8080e7          	jalr	-1592(ra) # 8000053a <panic>
      exit(-1);
    80002b7a:	557d                	li	a0,-1
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	938080e7          	jalr	-1736(ra) # 800024b4 <exit>
    80002b84:	bf4d                	j	80002b36 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	ecc080e7          	jalr	-308(ra) # 80002a52 <devintr>
    80002b8e:	892a                	mv	s2,a0
    80002b90:	c501                	beqz	a0,80002b98 <usertrap+0xa4>
  if(p->killed)
    80002b92:	549c                	lw	a5,40(s1)
    80002b94:	c3a1                	beqz	a5,80002bd4 <usertrap+0xe0>
    80002b96:	a815                	j	80002bca <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b98:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b9c:	5890                	lw	a2,48(s1)
    80002b9e:	00005517          	auipc	a0,0x5
    80002ba2:	79a50513          	addi	a0,a0,1946 # 80008338 <states.0+0x78>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9de080e7          	jalr	-1570(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb6:	00005517          	auipc	a0,0x5
    80002bba:	7b250513          	addi	a0,a0,1970 # 80008368 <states.0+0xa8>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9c6080e7          	jalr	-1594(ra) # 80000584 <printf>
    p->killed = 1;
    80002bc6:	4785                	li	a5,1
    80002bc8:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bca:	557d                	li	a0,-1
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	8e8080e7          	jalr	-1816(ra) # 800024b4 <exit>
  if(which_dev == 2){
    80002bd4:	4789                	li	a5,2
    80002bd6:	f8f910e3          	bne	s2,a5,80002b56 <usertrap+0x62>
  p->cputime +=1; // Anytime proc yields increament ticks by 1
    80002bda:	58dc                	lw	a5,52(s1)
    80002bdc:	2785                	addiw	a5,a5,1
    80002bde:	d8dc                	sw	a5,52(s1)
    yield();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	4ba080e7          	jalr	1210(ra) # 8000209a <yield>
    80002be8:	b7bd                	j	80002b56 <usertrap+0x62>
  int which_dev = 0;
    80002bea:	4901                	li	s2,0
    80002bec:	bff9                	j	80002bca <usertrap+0xd6>

0000000080002bee <kerneltrap>:
{
    80002bee:	7179                	addi	sp,sp,-48
    80002bf0:	f406                	sd	ra,40(sp)
    80002bf2:	f022                	sd	s0,32(sp)
    80002bf4:	ec26                	sd	s1,24(sp)
    80002bf6:	e84a                	sd	s2,16(sp)
    80002bf8:	e44e                	sd	s3,8(sp)
    80002bfa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bfc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c00:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c04:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c08:	1004f793          	andi	a5,s1,256
    80002c0c:	cb85                	beqz	a5,80002c3c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c12:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c14:	ef85                	bnez	a5,80002c4c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	e3c080e7          	jalr	-452(ra) # 80002a52 <devintr>
    80002c1e:	cd1d                	beqz	a0,80002c5c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002c20:	4789                	li	a5,2
    80002c22:	06f50a63          	beq	a0,a5,80002c96 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c26:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2a:	10049073          	csrw	sstatus,s1
}
    80002c2e:	70a2                	ld	ra,40(sp)
    80002c30:	7402                	ld	s0,32(sp)
    80002c32:	64e2                	ld	s1,24(sp)
    80002c34:	6942                	ld	s2,16(sp)
    80002c36:	69a2                	ld	s3,8(sp)
    80002c38:	6145                	addi	sp,sp,48
    80002c3a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c3c:	00005517          	auipc	a0,0x5
    80002c40:	74c50513          	addi	a0,a0,1868 # 80008388 <states.0+0xc8>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	8f6080e7          	jalr	-1802(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	76450513          	addi	a0,a0,1892 # 800083b0 <states.0+0xf0>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	8e6080e7          	jalr	-1818(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002c5c:	85ce                	mv	a1,s3
    80002c5e:	00005517          	auipc	a0,0x5
    80002c62:	77250513          	addi	a0,a0,1906 # 800083d0 <states.0+0x110>
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	91e080e7          	jalr	-1762(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c72:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c76:	00005517          	auipc	a0,0x5
    80002c7a:	76a50513          	addi	a0,a0,1898 # 800083e0 <states.0+0x120>
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	906080e7          	jalr	-1786(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002c86:	00005517          	auipc	a0,0x5
    80002c8a:	77250513          	addi	a0,a0,1906 # 800083f8 <states.0+0x138>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	8ac080e7          	jalr	-1876(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	d00080e7          	jalr	-768(ra) # 80001996 <myproc>
    80002c9e:	d541                	beqz	a0,80002c26 <kerneltrap+0x38>
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	cf6080e7          	jalr	-778(ra) # 80001996 <myproc>
    80002ca8:	4d18                	lw	a4,24(a0)
    80002caa:	4791                	li	a5,4
    80002cac:	f6f71de3          	bne	a4,a5,80002c26 <kerneltrap+0x38>
    myproc()->cputime +=1;// Anytime proc yields increament ticks by 1
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	ce6080e7          	jalr	-794(ra) # 80001996 <myproc>
    80002cb8:	595c                	lw	a5,52(a0)
    80002cba:	2785                	addiw	a5,a5,1
    80002cbc:	d95c                	sw	a5,52(a0)
    yield();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	3dc080e7          	jalr	988(ra) # 8000209a <yield>
    80002cc6:	b785                	j	80002c26 <kerneltrap+0x38>

0000000080002cc8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	e426                	sd	s1,8(sp)
    80002cd0:	1000                	addi	s0,sp,32
    80002cd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	cc2080e7          	jalr	-830(ra) # 80001996 <myproc>
  switch (n) {
    80002cdc:	4795                	li	a5,5
    80002cde:	0497e163          	bltu	a5,s1,80002d20 <argraw+0x58>
    80002ce2:	048a                	slli	s1,s1,0x2
    80002ce4:	00005717          	auipc	a4,0x5
    80002ce8:	74c70713          	addi	a4,a4,1868 # 80008430 <states.0+0x170>
    80002cec:	94ba                	add	s1,s1,a4
    80002cee:	409c                	lw	a5,0(s1)
    80002cf0:	97ba                	add	a5,a5,a4
    80002cf2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf4:	713c                	ld	a5,96(a0)
    80002cf6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret
    return p->trapframe->a1;
    80002d02:	713c                	ld	a5,96(a0)
    80002d04:	7fa8                	ld	a0,120(a5)
    80002d06:	bfcd                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a2;
    80002d08:	713c                	ld	a5,96(a0)
    80002d0a:	63c8                	ld	a0,128(a5)
    80002d0c:	b7f5                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a3;
    80002d0e:	713c                	ld	a5,96(a0)
    80002d10:	67c8                	ld	a0,136(a5)
    80002d12:	b7dd                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a4;
    80002d14:	713c                	ld	a5,96(a0)
    80002d16:	6bc8                	ld	a0,144(a5)
    80002d18:	b7c5                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a5;
    80002d1a:	713c                	ld	a5,96(a0)
    80002d1c:	6fc8                	ld	a0,152(a5)
    80002d1e:	bfe9                	j	80002cf8 <argraw+0x30>
  panic("argraw");
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	6e850513          	addi	a0,a0,1768 # 80008408 <states.0+0x148>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	812080e7          	jalr	-2030(ra) # 8000053a <panic>

0000000080002d30 <fetchaddr>:
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	e04a                	sd	s2,0(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84aa                	mv	s1,a0
    80002d3e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	c56080e7          	jalr	-938(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d48:	693c                	ld	a5,80(a0)
    80002d4a:	02f4f863          	bgeu	s1,a5,80002d7a <fetchaddr+0x4a>
    80002d4e:	00848713          	addi	a4,s1,8
    80002d52:	02e7e663          	bltu	a5,a4,80002d7e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d56:	46a1                	li	a3,8
    80002d58:	8626                	mv	a2,s1
    80002d5a:	85ca                	mv	a1,s2
    80002d5c:	6d28                	ld	a0,88(a0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	988080e7          	jalr	-1656(ra) # 800016e6 <copyin>
    80002d66:	00a03533          	snez	a0,a0
    80002d6a:	40a00533          	neg	a0,a0
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6902                	ld	s2,0(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret
    return -1;
    80002d7a:	557d                	li	a0,-1
    80002d7c:	bfcd                	j	80002d6e <fetchaddr+0x3e>
    80002d7e:	557d                	li	a0,-1
    80002d80:	b7fd                	j	80002d6e <fetchaddr+0x3e>

0000000080002d82 <fetchstr>:
{
    80002d82:	7179                	addi	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	e44e                	sd	s3,8(sp)
    80002d8e:	1800                	addi	s0,sp,48
    80002d90:	892a                	mv	s2,a0
    80002d92:	84ae                	mv	s1,a1
    80002d94:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	c00080e7          	jalr	-1024(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d9e:	86ce                	mv	a3,s3
    80002da0:	864a                	mv	a2,s2
    80002da2:	85a6                	mv	a1,s1
    80002da4:	6d28                	ld	a0,88(a0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	9ce080e7          	jalr	-1586(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002dae:	00054763          	bltz	a0,80002dbc <fetchstr+0x3a>
  return strlen(buf);
    80002db2:	8526                	mv	a0,s1
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	094080e7          	jalr	148(ra) # 80000e48 <strlen>
}
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6942                	ld	s2,16(sp)
    80002dc4:	69a2                	ld	s3,8(sp)
    80002dc6:	6145                	addi	sp,sp,48
    80002dc8:	8082                	ret

0000000080002dca <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dca:	1101                	addi	sp,sp,-32
    80002dcc:	ec06                	sd	ra,24(sp)
    80002dce:	e822                	sd	s0,16(sp)
    80002dd0:	e426                	sd	s1,8(sp)
    80002dd2:	1000                	addi	s0,sp,32
    80002dd4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	ef2080e7          	jalr	-270(ra) # 80002cc8 <argraw>
    80002dde:	c088                	sw	a0,0(s1)
  return 0;
}
    80002de0:	4501                	li	a0,0
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	64a2                	ld	s1,8(sp)
    80002de8:	6105                	addi	sp,sp,32
    80002dea:	8082                	ret

0000000080002dec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dec:	1101                	addi	sp,sp,-32
    80002dee:	ec06                	sd	ra,24(sp)
    80002df0:	e822                	sd	s0,16(sp)
    80002df2:	e426                	sd	s1,8(sp)
    80002df4:	1000                	addi	s0,sp,32
    80002df6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	ed0080e7          	jalr	-304(ra) # 80002cc8 <argraw>
    80002e00:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e02:	4501                	li	a0,0
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e0e:	1101                	addi	sp,sp,-32
    80002e10:	ec06                	sd	ra,24(sp)
    80002e12:	e822                	sd	s0,16(sp)
    80002e14:	e426                	sd	s1,8(sp)
    80002e16:	e04a                	sd	s2,0(sp)
    80002e18:	1000                	addi	s0,sp,32
    80002e1a:	84ae                	mv	s1,a1
    80002e1c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	eaa080e7          	jalr	-342(ra) # 80002cc8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e26:	864a                	mv	a2,s2
    80002e28:	85a6                	mv	a1,s1
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	f58080e7          	jalr	-168(ra) # 80002d82 <fetchstr>
}
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6902                	ld	s2,0(sp)
    80002e3a:	6105                	addi	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <syscall>:
[SYS_getprocs]   sys_getprocs,
};

void
syscall(void)
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	e04a                	sd	s2,0(sp)
    80002e48:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b4c080e7          	jalr	-1204(ra) # 80001996 <myproc>
    80002e52:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e54:	06053903          	ld	s2,96(a0)
    80002e58:	0a893783          	ld	a5,168(s2)
    80002e5c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e60:	37fd                	addiw	a5,a5,-1
    80002e62:	4761                	li	a4,24
    80002e64:	00f76f63          	bltu	a4,a5,80002e82 <syscall+0x44>
    80002e68:	00369713          	slli	a4,a3,0x3
    80002e6c:	00005797          	auipc	a5,0x5
    80002e70:	5dc78793          	addi	a5,a5,1500 # 80008448 <syscalls>
    80002e74:	97ba                	add	a5,a5,a4
    80002e76:	639c                	ld	a5,0(a5)
    80002e78:	c789                	beqz	a5,80002e82 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e7a:	9782                	jalr	a5
    80002e7c:	06a93823          	sd	a0,112(s2)
    80002e80:	a839                	j	80002e9e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e82:	16048613          	addi	a2,s1,352
    80002e86:	588c                	lw	a1,48(s1)
    80002e88:	00005517          	auipc	a0,0x5
    80002e8c:	58850513          	addi	a0,a0,1416 # 80008410 <states.0+0x150>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	6f4080e7          	jalr	1780(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e98:	70bc                	ld	a5,96(s1)
    80002e9a:	577d                	li	a4,-1
    80002e9c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	64a2                	ld	s1,8(sp)
    80002ea4:	6902                	ld	s2,0(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eaa:	1101                	addi	sp,sp,-32
    80002eac:	ec06                	sd	ra,24(sp)
    80002eae:	e822                	sd	s0,16(sp)
    80002eb0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eb2:	fec40593          	addi	a1,s0,-20
    80002eb6:	4501                	li	a0,0
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	f12080e7          	jalr	-238(ra) # 80002dca <argint>
    return -1;
    80002ec0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec2:	00054963          	bltz	a0,80002ed4 <sys_exit+0x2a>
  exit(n);
    80002ec6:	fec42503          	lw	a0,-20(s0)
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	5ea080e7          	jalr	1514(ra) # 800024b4 <exit>
  return 0;  // not reached
    80002ed2:	4781                	li	a5,0
}
    80002ed4:	853e                	mv	a0,a5
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ede:	1141                	addi	sp,sp,-16
    80002ee0:	e406                	sd	ra,8(sp)
    80002ee2:	e022                	sd	s0,0(sp)
    80002ee4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	ab0080e7          	jalr	-1360(ra) # 80001996 <myproc>
}
    80002eee:	5908                	lw	a0,48(a0)
    80002ef0:	60a2                	ld	ra,8(sp)
    80002ef2:	6402                	ld	s0,0(sp)
    80002ef4:	0141                	addi	sp,sp,16
    80002ef6:	8082                	ret

0000000080002ef8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ef8:	1141                	addi	sp,sp,-16
    80002efa:	e406                	sd	ra,8(sp)
    80002efc:	e022                	sd	s0,0(sp)
    80002efe:	0800                	addi	s0,sp,16
  return fork();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	e76080e7          	jalr	-394(ra) # 80001d76 <fork>
}
    80002f08:	60a2                	ld	ra,8(sp)
    80002f0a:	6402                	ld	s0,0(sp)
    80002f0c:	0141                	addi	sp,sp,16
    80002f0e:	8082                	ret

0000000080002f10 <sys_wait>:

uint64
sys_wait(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f18:	fe840593          	addi	a1,s0,-24
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	ece080e7          	jalr	-306(ra) # 80002dec <argaddr>
    80002f26:	87aa                	mv	a5,a0
    return -1;
    80002f28:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f2a:	0007c863          	bltz	a5,80002f3a <sys_wait+0x2a>
  return wait(p);
    80002f2e:	fe843503          	ld	a0,-24(s0)
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	212080e7          	jalr	530(ra) # 80002144 <wait>
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	6105                	addi	sp,sp,32
    80002f40:	8082                	ret

0000000080002f42 <sys_wait2>:

uint64
sys_wait2(void)
{
    80002f42:	1101                	addi	sp,sp,-32
    80002f44:	ec06                	sd	ra,24(sp)
    80002f46:	e822                	sd	s0,16(sp)
    80002f48:	1000                	addi	s0,sp,32
  uint64 p;
  uint64 p1; //Pointer for second argument
  
  if(argaddr(0, &p) < 0)
    80002f4a:	fe840593          	addi	a1,s0,-24
    80002f4e:	4501                	li	a0,0
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	e9c080e7          	jalr	-356(ra) # 80002dec <argaddr>
    return -1;
    80002f58:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002f5a:	02054563          	bltz	a0,80002f84 <sys_wait2+0x42>
  if(argaddr(1, &p1) < 0) //1 is in refrence to second argument ie rusage * we sent in
    80002f5e:	fe040593          	addi	a1,s0,-32
    80002f62:	4505                	li	a0,1
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	e88080e7          	jalr	-376(ra) # 80002dec <argaddr>
    return -1;
    80002f6c:	57fd                	li	a5,-1
  if(argaddr(1, &p1) < 0) //1 is in refrence to second argument ie rusage * we sent in
    80002f6e:	00054b63          	bltz	a0,80002f84 <sys_wait2+0x42>
  return wait2(p,p1);
    80002f72:	fe043583          	ld	a1,-32(s0)
    80002f76:	fe843503          	ld	a0,-24(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	2f2080e7          	jalr	754(ra) # 8000226c <wait2>
    80002f82:	87aa                	mv	a5,a0
}
    80002f84:	853e                	mv	a0,a5
    80002f86:	60e2                	ld	ra,24(sp)
    80002f88:	6442                	ld	s0,16(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret

0000000080002f8e <sys_getpriority>:

uint64
sys_getpriority(void)
{
    80002f8e:	1101                	addi	sp,sp,-32
    80002f90:	ec06                	sd	ra,24(sp)
    80002f92:	e822                	sd	s0,16(sp)
    80002f94:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f96:	fe840593          	addi	a1,s0,-24
    80002f9a:	4501                	li	a0,0
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	e50080e7          	jalr	-432(ra) # 80002dec <argaddr>
    80002fa4:	87aa                	mv	a5,a0
    return -1;
    80002fa6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fa8:	0007c863          	bltz	a5,80002fb8 <sys_getpriority+0x2a>
  return wait(p);
    80002fac:	fe843503          	ld	a0,-24(s0)
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	194080e7          	jalr	404(ra) # 80002144 <wait>
}
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	6105                	addi	sp,sp,32
    80002fbe:	8082                	ret

0000000080002fc0 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc8:	fe840593          	addi	a1,s0,-24
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	e1e080e7          	jalr	-482(ra) # 80002dec <argaddr>
    80002fd6:	87aa                	mv	a5,a0
    return -1;
    80002fd8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fda:	0007c863          	bltz	a5,80002fea <sys_setpriority+0x2a>
  return wait(p);
    80002fde:	fe843503          	ld	a0,-24(s0)
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	162080e7          	jalr	354(ra) # 80002144 <wait>
}
    80002fea:	60e2                	ld	ra,24(sp)
    80002fec:	6442                	ld	s0,16(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ff2:	7179                	addi	sp,sp,-48
    80002ff4:	f406                	sd	ra,40(sp)
    80002ff6:	f022                	sd	s0,32(sp)
    80002ff8:	ec26                	sd	s1,24(sp)
    80002ffa:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ffc:	fdc40593          	addi	a1,s0,-36
    80003000:	4501                	li	a0,0
    80003002:	00000097          	auipc	ra,0x0
    80003006:	dc8080e7          	jalr	-568(ra) # 80002dca <argint>
    8000300a:	87aa                	mv	a5,a0
    return -1;
    8000300c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000300e:	0207c063          	bltz	a5,8000302e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	984080e7          	jalr	-1660(ra) # 80001996 <myproc>
    8000301a:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    8000301c:	fdc42503          	lw	a0,-36(s0)
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	cde080e7          	jalr	-802(ra) # 80001cfe <growproc>
    80003028:	00054863          	bltz	a0,80003038 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000302c:	8526                	mv	a0,s1
}
    8000302e:	70a2                	ld	ra,40(sp)
    80003030:	7402                	ld	s0,32(sp)
    80003032:	64e2                	ld	s1,24(sp)
    80003034:	6145                	addi	sp,sp,48
    80003036:	8082                	ret
    return -1;
    80003038:	557d                	li	a0,-1
    8000303a:	bfd5                	j	8000302e <sys_sbrk+0x3c>

000000008000303c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000303c:	7139                	addi	sp,sp,-64
    8000303e:	fc06                	sd	ra,56(sp)
    80003040:	f822                	sd	s0,48(sp)
    80003042:	f426                	sd	s1,40(sp)
    80003044:	f04a                	sd	s2,32(sp)
    80003046:	ec4e                	sd	s3,24(sp)
    80003048:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000304a:	fcc40593          	addi	a1,s0,-52
    8000304e:	4501                	li	a0,0
    80003050:	00000097          	auipc	ra,0x0
    80003054:	d7a080e7          	jalr	-646(ra) # 80002dca <argint>
    return -1;
    80003058:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000305a:	06054563          	bltz	a0,800030c4 <sys_sleep+0x88>
  acquire(&tickslock);
    8000305e:	00014517          	auipc	a0,0x14
    80003062:	27250513          	addi	a0,a0,626 # 800172d0 <tickslock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	b6a080e7          	jalr	-1174(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    8000306e:	00006917          	auipc	s2,0x6
    80003072:	fc292903          	lw	s2,-62(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003076:	fcc42783          	lw	a5,-52(s0)
    8000307a:	cf85                	beqz	a5,800030b2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000307c:	00014997          	auipc	s3,0x14
    80003080:	25498993          	addi	s3,s3,596 # 800172d0 <tickslock>
    80003084:	00006497          	auipc	s1,0x6
    80003088:	fac48493          	addi	s1,s1,-84 # 80009030 <ticks>
    if(myproc()->killed){
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	90a080e7          	jalr	-1782(ra) # 80001996 <myproc>
    80003094:	551c                	lw	a5,40(a0)
    80003096:	ef9d                	bnez	a5,800030d4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003098:	85ce                	mv	a1,s3
    8000309a:	8526                	mv	a0,s1
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	044080e7          	jalr	68(ra) # 800020e0 <sleep>
  while(ticks - ticks0 < n){
    800030a4:	409c                	lw	a5,0(s1)
    800030a6:	412787bb          	subw	a5,a5,s2
    800030aa:	fcc42703          	lw	a4,-52(s0)
    800030ae:	fce7efe3          	bltu	a5,a4,8000308c <sys_sleep+0x50>
  }
  release(&tickslock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	21e50513          	addi	a0,a0,542 # 800172d0 <tickslock>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	bca080e7          	jalr	-1078(ra) # 80000c84 <release>
  return 0;
    800030c2:	4781                	li	a5,0
}
    800030c4:	853e                	mv	a0,a5
    800030c6:	70e2                	ld	ra,56(sp)
    800030c8:	7442                	ld	s0,48(sp)
    800030ca:	74a2                	ld	s1,40(sp)
    800030cc:	7902                	ld	s2,32(sp)
    800030ce:	69e2                	ld	s3,24(sp)
    800030d0:	6121                	addi	sp,sp,64
    800030d2:	8082                	ret
      release(&tickslock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	1fc50513          	addi	a0,a0,508 # 800172d0 <tickslock>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	ba8080e7          	jalr	-1112(ra) # 80000c84 <release>
      return -1;
    800030e4:	57fd                	li	a5,-1
    800030e6:	bff9                	j	800030c4 <sys_sleep+0x88>

00000000800030e8 <sys_kill>:

uint64
sys_kill(void)
{
    800030e8:	1101                	addi	sp,sp,-32
    800030ea:	ec06                	sd	ra,24(sp)
    800030ec:	e822                	sd	s0,16(sp)
    800030ee:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030f0:	fec40593          	addi	a1,s0,-20
    800030f4:	4501                	li	a0,0
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	cd4080e7          	jalr	-812(ra) # 80002dca <argint>
    800030fe:	87aa                	mv	a5,a0
    return -1;
    80003100:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003102:	0007c863          	bltz	a5,80003112 <sys_kill+0x2a>
  return kill(pid);
    80003106:	fec42503          	lw	a0,-20(s0)
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	480080e7          	jalr	1152(ra) # 8000258a <kill>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	1ac50513          	addi	a0,a0,428 # 800172d0 <tickslock>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	aa4080e7          	jalr	-1372(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80003134:	00006497          	auipc	s1,0x6
    80003138:	efc4a483          	lw	s1,-260(s1) # 80009030 <ticks>
  release(&tickslock);
    8000313c:	00014517          	auipc	a0,0x14
    80003140:	19450513          	addi	a0,a0,404 # 800172d0 <tickslock>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	b40080e7          	jalr	-1216(ra) # 80000c84 <release>
  return xticks;
}
    8000314c:	02049513          	slli	a0,s1,0x20
    80003150:	9101                	srli	a0,a0,0x20
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    80003164:	fe840593          	addi	a1,s0,-24
    80003168:	4501                	li	a0,0
    8000316a:	00000097          	auipc	ra,0x0
    8000316e:	c82080e7          	jalr	-894(ra) # 80002dec <argaddr>
    80003172:	87aa                	mv	a5,a0
    return -1;
    80003174:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80003176:	0007c863          	bltz	a5,80003186 <sys_getprocs+0x2a>
  return(procinfo(addr));
    8000317a:	fe843503          	ld	a0,-24(s0)
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	5e4080e7          	jalr	1508(ra) # 80002762 <procinfo>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	6105                	addi	sp,sp,32
    8000318c:	8082                	ret

000000008000318e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000318e:	7179                	addi	sp,sp,-48
    80003190:	f406                	sd	ra,40(sp)
    80003192:	f022                	sd	s0,32(sp)
    80003194:	ec26                	sd	s1,24(sp)
    80003196:	e84a                	sd	s2,16(sp)
    80003198:	e44e                	sd	s3,8(sp)
    8000319a:	e052                	sd	s4,0(sp)
    8000319c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000319e:	00005597          	auipc	a1,0x5
    800031a2:	37a58593          	addi	a1,a1,890 # 80008518 <syscalls+0xd0>
    800031a6:	00014517          	auipc	a0,0x14
    800031aa:	14250513          	addi	a0,a0,322 # 800172e8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	992080e7          	jalr	-1646(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031b6:	0001c797          	auipc	a5,0x1c
    800031ba:	13278793          	addi	a5,a5,306 # 8001f2e8 <bcache+0x8000>
    800031be:	0001c717          	auipc	a4,0x1c
    800031c2:	39270713          	addi	a4,a4,914 # 8001f550 <bcache+0x8268>
    800031c6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031ca:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ce:	00014497          	auipc	s1,0x14
    800031d2:	13248493          	addi	s1,s1,306 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    800031d6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031d8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031da:	00005a17          	auipc	s4,0x5
    800031de:	346a0a13          	addi	s4,s4,838 # 80008520 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031e2:	2b893783          	ld	a5,696(s2)
    800031e6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031e8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031ec:	85d2                	mv	a1,s4
    800031ee:	01048513          	addi	a0,s1,16
    800031f2:	00001097          	auipc	ra,0x1
    800031f6:	4c2080e7          	jalr	1218(ra) # 800046b4 <initsleeplock>
    bcache.head.next->prev = b;
    800031fa:	2b893783          	ld	a5,696(s2)
    800031fe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003200:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003204:	45848493          	addi	s1,s1,1112
    80003208:	fd349de3          	bne	s1,s3,800031e2 <binit+0x54>
  }
}
    8000320c:	70a2                	ld	ra,40(sp)
    8000320e:	7402                	ld	s0,32(sp)
    80003210:	64e2                	ld	s1,24(sp)
    80003212:	6942                	ld	s2,16(sp)
    80003214:	69a2                	ld	s3,8(sp)
    80003216:	6a02                	ld	s4,0(sp)
    80003218:	6145                	addi	sp,sp,48
    8000321a:	8082                	ret

000000008000321c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000321c:	7179                	addi	sp,sp,-48
    8000321e:	f406                	sd	ra,40(sp)
    80003220:	f022                	sd	s0,32(sp)
    80003222:	ec26                	sd	s1,24(sp)
    80003224:	e84a                	sd	s2,16(sp)
    80003226:	e44e                	sd	s3,8(sp)
    80003228:	1800                	addi	s0,sp,48
    8000322a:	892a                	mv	s2,a0
    8000322c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000322e:	00014517          	auipc	a0,0x14
    80003232:	0ba50513          	addi	a0,a0,186 # 800172e8 <bcache>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	99a080e7          	jalr	-1638(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000323e:	0001c497          	auipc	s1,0x1c
    80003242:	3624b483          	ld	s1,866(s1) # 8001f5a0 <bcache+0x82b8>
    80003246:	0001c797          	auipc	a5,0x1c
    8000324a:	30a78793          	addi	a5,a5,778 # 8001f550 <bcache+0x8268>
    8000324e:	02f48f63          	beq	s1,a5,8000328c <bread+0x70>
    80003252:	873e                	mv	a4,a5
    80003254:	a021                	j	8000325c <bread+0x40>
    80003256:	68a4                	ld	s1,80(s1)
    80003258:	02e48a63          	beq	s1,a4,8000328c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000325c:	449c                	lw	a5,8(s1)
    8000325e:	ff279ce3          	bne	a5,s2,80003256 <bread+0x3a>
    80003262:	44dc                	lw	a5,12(s1)
    80003264:	ff3799e3          	bne	a5,s3,80003256 <bread+0x3a>
      b->refcnt++;
    80003268:	40bc                	lw	a5,64(s1)
    8000326a:	2785                	addiw	a5,a5,1
    8000326c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000326e:	00014517          	auipc	a0,0x14
    80003272:	07a50513          	addi	a0,a0,122 # 800172e8 <bcache>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	a0e080e7          	jalr	-1522(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000327e:	01048513          	addi	a0,s1,16
    80003282:	00001097          	auipc	ra,0x1
    80003286:	46c080e7          	jalr	1132(ra) # 800046ee <acquiresleep>
      return b;
    8000328a:	a8b9                	j	800032e8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000328c:	0001c497          	auipc	s1,0x1c
    80003290:	30c4b483          	ld	s1,780(s1) # 8001f598 <bcache+0x82b0>
    80003294:	0001c797          	auipc	a5,0x1c
    80003298:	2bc78793          	addi	a5,a5,700 # 8001f550 <bcache+0x8268>
    8000329c:	00f48863          	beq	s1,a5,800032ac <bread+0x90>
    800032a0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032a2:	40bc                	lw	a5,64(s1)
    800032a4:	cf81                	beqz	a5,800032bc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032a6:	64a4                	ld	s1,72(s1)
    800032a8:	fee49de3          	bne	s1,a4,800032a2 <bread+0x86>
  panic("bget: no buffers");
    800032ac:	00005517          	auipc	a0,0x5
    800032b0:	27c50513          	addi	a0,a0,636 # 80008528 <syscalls+0xe0>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	286080e7          	jalr	646(ra) # 8000053a <panic>
      b->dev = dev;
    800032bc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032c0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032c4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032c8:	4785                	li	a5,1
    800032ca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032cc:	00014517          	auipc	a0,0x14
    800032d0:	01c50513          	addi	a0,a0,28 # 800172e8 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	9b0080e7          	jalr	-1616(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800032dc:	01048513          	addi	a0,s1,16
    800032e0:	00001097          	auipc	ra,0x1
    800032e4:	40e080e7          	jalr	1038(ra) # 800046ee <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032e8:	409c                	lw	a5,0(s1)
    800032ea:	cb89                	beqz	a5,800032fc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032ec:	8526                	mv	a0,s1
    800032ee:	70a2                	ld	ra,40(sp)
    800032f0:	7402                	ld	s0,32(sp)
    800032f2:	64e2                	ld	s1,24(sp)
    800032f4:	6942                	ld	s2,16(sp)
    800032f6:	69a2                	ld	s3,8(sp)
    800032f8:	6145                	addi	sp,sp,48
    800032fa:	8082                	ret
    virtio_disk_rw(b, 0);
    800032fc:	4581                	li	a1,0
    800032fe:	8526                	mv	a0,s1
    80003300:	00003097          	auipc	ra,0x3
    80003304:	f22080e7          	jalr	-222(ra) # 80006222 <virtio_disk_rw>
    b->valid = 1;
    80003308:	4785                	li	a5,1
    8000330a:	c09c                	sw	a5,0(s1)
  return b;
    8000330c:	b7c5                	j	800032ec <bread+0xd0>

000000008000330e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000330e:	1101                	addi	sp,sp,-32
    80003310:	ec06                	sd	ra,24(sp)
    80003312:	e822                	sd	s0,16(sp)
    80003314:	e426                	sd	s1,8(sp)
    80003316:	1000                	addi	s0,sp,32
    80003318:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000331a:	0541                	addi	a0,a0,16
    8000331c:	00001097          	auipc	ra,0x1
    80003320:	46c080e7          	jalr	1132(ra) # 80004788 <holdingsleep>
    80003324:	cd01                	beqz	a0,8000333c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003326:	4585                	li	a1,1
    80003328:	8526                	mv	a0,s1
    8000332a:	00003097          	auipc	ra,0x3
    8000332e:	ef8080e7          	jalr	-264(ra) # 80006222 <virtio_disk_rw>
}
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	64a2                	ld	s1,8(sp)
    80003338:	6105                	addi	sp,sp,32
    8000333a:	8082                	ret
    panic("bwrite");
    8000333c:	00005517          	auipc	a0,0x5
    80003340:	20450513          	addi	a0,a0,516 # 80008540 <syscalls+0xf8>
    80003344:	ffffd097          	auipc	ra,0xffffd
    80003348:	1f6080e7          	jalr	502(ra) # 8000053a <panic>

000000008000334c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000334c:	1101                	addi	sp,sp,-32
    8000334e:	ec06                	sd	ra,24(sp)
    80003350:	e822                	sd	s0,16(sp)
    80003352:	e426                	sd	s1,8(sp)
    80003354:	e04a                	sd	s2,0(sp)
    80003356:	1000                	addi	s0,sp,32
    80003358:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000335a:	01050913          	addi	s2,a0,16
    8000335e:	854a                	mv	a0,s2
    80003360:	00001097          	auipc	ra,0x1
    80003364:	428080e7          	jalr	1064(ra) # 80004788 <holdingsleep>
    80003368:	c92d                	beqz	a0,800033da <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	3d8080e7          	jalr	984(ra) # 80004744 <releasesleep>

  acquire(&bcache.lock);
    80003374:	00014517          	auipc	a0,0x14
    80003378:	f7450513          	addi	a0,a0,-140 # 800172e8 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	854080e7          	jalr	-1964(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003384:	40bc                	lw	a5,64(s1)
    80003386:	37fd                	addiw	a5,a5,-1
    80003388:	0007871b          	sext.w	a4,a5
    8000338c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000338e:	eb05                	bnez	a4,800033be <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003390:	68bc                	ld	a5,80(s1)
    80003392:	64b8                	ld	a4,72(s1)
    80003394:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003396:	64bc                	ld	a5,72(s1)
    80003398:	68b8                	ld	a4,80(s1)
    8000339a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000339c:	0001c797          	auipc	a5,0x1c
    800033a0:	f4c78793          	addi	a5,a5,-180 # 8001f2e8 <bcache+0x8000>
    800033a4:	2b87b703          	ld	a4,696(a5)
    800033a8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033aa:	0001c717          	auipc	a4,0x1c
    800033ae:	1a670713          	addi	a4,a4,422 # 8001f550 <bcache+0x8268>
    800033b2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033b4:	2b87b703          	ld	a4,696(a5)
    800033b8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033ba:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033be:	00014517          	auipc	a0,0x14
    800033c2:	f2a50513          	addi	a0,a0,-214 # 800172e8 <bcache>
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	8be080e7          	jalr	-1858(ra) # 80000c84 <release>
}
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	64a2                	ld	s1,8(sp)
    800033d4:	6902                	ld	s2,0(sp)
    800033d6:	6105                	addi	sp,sp,32
    800033d8:	8082                	ret
    panic("brelse");
    800033da:	00005517          	auipc	a0,0x5
    800033de:	16e50513          	addi	a0,a0,366 # 80008548 <syscalls+0x100>
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	158080e7          	jalr	344(ra) # 8000053a <panic>

00000000800033ea <bpin>:

void
bpin(struct buf *b) {
    800033ea:	1101                	addi	sp,sp,-32
    800033ec:	ec06                	sd	ra,24(sp)
    800033ee:	e822                	sd	s0,16(sp)
    800033f0:	e426                	sd	s1,8(sp)
    800033f2:	1000                	addi	s0,sp,32
    800033f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033f6:	00014517          	auipc	a0,0x14
    800033fa:	ef250513          	addi	a0,a0,-270 # 800172e8 <bcache>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	7d2080e7          	jalr	2002(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003406:	40bc                	lw	a5,64(s1)
    80003408:	2785                	addiw	a5,a5,1
    8000340a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000340c:	00014517          	auipc	a0,0x14
    80003410:	edc50513          	addi	a0,a0,-292 # 800172e8 <bcache>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	870080e7          	jalr	-1936(ra) # 80000c84 <release>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret

0000000080003426 <bunpin>:

void
bunpin(struct buf *b) {
    80003426:	1101                	addi	sp,sp,-32
    80003428:	ec06                	sd	ra,24(sp)
    8000342a:	e822                	sd	s0,16(sp)
    8000342c:	e426                	sd	s1,8(sp)
    8000342e:	1000                	addi	s0,sp,32
    80003430:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003432:	00014517          	auipc	a0,0x14
    80003436:	eb650513          	addi	a0,a0,-330 # 800172e8 <bcache>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	796080e7          	jalr	1942(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003442:	40bc                	lw	a5,64(s1)
    80003444:	37fd                	addiw	a5,a5,-1
    80003446:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003448:	00014517          	auipc	a0,0x14
    8000344c:	ea050513          	addi	a0,a0,-352 # 800172e8 <bcache>
    80003450:	ffffe097          	auipc	ra,0xffffe
    80003454:	834080e7          	jalr	-1996(ra) # 80000c84 <release>
}
    80003458:	60e2                	ld	ra,24(sp)
    8000345a:	6442                	ld	s0,16(sp)
    8000345c:	64a2                	ld	s1,8(sp)
    8000345e:	6105                	addi	sp,sp,32
    80003460:	8082                	ret

0000000080003462 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003462:	1101                	addi	sp,sp,-32
    80003464:	ec06                	sd	ra,24(sp)
    80003466:	e822                	sd	s0,16(sp)
    80003468:	e426                	sd	s1,8(sp)
    8000346a:	e04a                	sd	s2,0(sp)
    8000346c:	1000                	addi	s0,sp,32
    8000346e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003470:	00d5d59b          	srliw	a1,a1,0xd
    80003474:	0001c797          	auipc	a5,0x1c
    80003478:	5507a783          	lw	a5,1360(a5) # 8001f9c4 <sb+0x1c>
    8000347c:	9dbd                	addw	a1,a1,a5
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	d9e080e7          	jalr	-610(ra) # 8000321c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003486:	0074f713          	andi	a4,s1,7
    8000348a:	4785                	li	a5,1
    8000348c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003490:	14ce                	slli	s1,s1,0x33
    80003492:	90d9                	srli	s1,s1,0x36
    80003494:	00950733          	add	a4,a0,s1
    80003498:	05874703          	lbu	a4,88(a4)
    8000349c:	00e7f6b3          	and	a3,a5,a4
    800034a0:	c69d                	beqz	a3,800034ce <bfree+0x6c>
    800034a2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034a4:	94aa                	add	s1,s1,a0
    800034a6:	fff7c793          	not	a5,a5
    800034aa:	8f7d                	and	a4,a4,a5
    800034ac:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034b0:	00001097          	auipc	ra,0x1
    800034b4:	120080e7          	jalr	288(ra) # 800045d0 <log_write>
  brelse(bp);
    800034b8:	854a                	mv	a0,s2
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	e92080e7          	jalr	-366(ra) # 8000334c <brelse>
}
    800034c2:	60e2                	ld	ra,24(sp)
    800034c4:	6442                	ld	s0,16(sp)
    800034c6:	64a2                	ld	s1,8(sp)
    800034c8:	6902                	ld	s2,0(sp)
    800034ca:	6105                	addi	sp,sp,32
    800034cc:	8082                	ret
    panic("freeing free block");
    800034ce:	00005517          	auipc	a0,0x5
    800034d2:	08250513          	addi	a0,a0,130 # 80008550 <syscalls+0x108>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	064080e7          	jalr	100(ra) # 8000053a <panic>

00000000800034de <balloc>:
{
    800034de:	711d                	addi	sp,sp,-96
    800034e0:	ec86                	sd	ra,88(sp)
    800034e2:	e8a2                	sd	s0,80(sp)
    800034e4:	e4a6                	sd	s1,72(sp)
    800034e6:	e0ca                	sd	s2,64(sp)
    800034e8:	fc4e                	sd	s3,56(sp)
    800034ea:	f852                	sd	s4,48(sp)
    800034ec:	f456                	sd	s5,40(sp)
    800034ee:	f05a                	sd	s6,32(sp)
    800034f0:	ec5e                	sd	s7,24(sp)
    800034f2:	e862                	sd	s8,16(sp)
    800034f4:	e466                	sd	s9,8(sp)
    800034f6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034f8:	0001c797          	auipc	a5,0x1c
    800034fc:	4b47a783          	lw	a5,1204(a5) # 8001f9ac <sb+0x4>
    80003500:	cbc1                	beqz	a5,80003590 <balloc+0xb2>
    80003502:	8baa                	mv	s7,a0
    80003504:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003506:	0001cb17          	auipc	s6,0x1c
    8000350a:	4a2b0b13          	addi	s6,s6,1186 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000350e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003510:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003512:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003514:	6c89                	lui	s9,0x2
    80003516:	a831                	j	80003532 <balloc+0x54>
    brelse(bp);
    80003518:	854a                	mv	a0,s2
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	e32080e7          	jalr	-462(ra) # 8000334c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003522:	015c87bb          	addw	a5,s9,s5
    80003526:	00078a9b          	sext.w	s5,a5
    8000352a:	004b2703          	lw	a4,4(s6)
    8000352e:	06eaf163          	bgeu	s5,a4,80003590 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003532:	41fad79b          	sraiw	a5,s5,0x1f
    80003536:	0137d79b          	srliw	a5,a5,0x13
    8000353a:	015787bb          	addw	a5,a5,s5
    8000353e:	40d7d79b          	sraiw	a5,a5,0xd
    80003542:	01cb2583          	lw	a1,28(s6)
    80003546:	9dbd                	addw	a1,a1,a5
    80003548:	855e                	mv	a0,s7
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	cd2080e7          	jalr	-814(ra) # 8000321c <bread>
    80003552:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003554:	004b2503          	lw	a0,4(s6)
    80003558:	000a849b          	sext.w	s1,s5
    8000355c:	8762                	mv	a4,s8
    8000355e:	faa4fde3          	bgeu	s1,a0,80003518 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003562:	00777693          	andi	a3,a4,7
    80003566:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000356a:	41f7579b          	sraiw	a5,a4,0x1f
    8000356e:	01d7d79b          	srliw	a5,a5,0x1d
    80003572:	9fb9                	addw	a5,a5,a4
    80003574:	4037d79b          	sraiw	a5,a5,0x3
    80003578:	00f90633          	add	a2,s2,a5
    8000357c:	05864603          	lbu	a2,88(a2)
    80003580:	00c6f5b3          	and	a1,a3,a2
    80003584:	cd91                	beqz	a1,800035a0 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003586:	2705                	addiw	a4,a4,1
    80003588:	2485                	addiw	s1,s1,1
    8000358a:	fd471ae3          	bne	a4,s4,8000355e <balloc+0x80>
    8000358e:	b769                	j	80003518 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003590:	00005517          	auipc	a0,0x5
    80003594:	fd850513          	addi	a0,a0,-40 # 80008568 <syscalls+0x120>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	fa2080e7          	jalr	-94(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035a0:	97ca                	add	a5,a5,s2
    800035a2:	8e55                	or	a2,a2,a3
    800035a4:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	026080e7          	jalr	38(ra) # 800045d0 <log_write>
        brelse(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	d98080e7          	jalr	-616(ra) # 8000334c <brelse>
  bp = bread(dev, bno);
    800035bc:	85a6                	mv	a1,s1
    800035be:	855e                	mv	a0,s7
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	c5c080e7          	jalr	-932(ra) # 8000321c <bread>
    800035c8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035ca:	40000613          	li	a2,1024
    800035ce:	4581                	li	a1,0
    800035d0:	05850513          	addi	a0,a0,88
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	6f8080e7          	jalr	1784(ra) # 80000ccc <memset>
  log_write(bp);
    800035dc:	854a                	mv	a0,s2
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	ff2080e7          	jalr	-14(ra) # 800045d0 <log_write>
  brelse(bp);
    800035e6:	854a                	mv	a0,s2
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	d64080e7          	jalr	-668(ra) # 8000334c <brelse>
}
    800035f0:	8526                	mv	a0,s1
    800035f2:	60e6                	ld	ra,88(sp)
    800035f4:	6446                	ld	s0,80(sp)
    800035f6:	64a6                	ld	s1,72(sp)
    800035f8:	6906                	ld	s2,64(sp)
    800035fa:	79e2                	ld	s3,56(sp)
    800035fc:	7a42                	ld	s4,48(sp)
    800035fe:	7aa2                	ld	s5,40(sp)
    80003600:	7b02                	ld	s6,32(sp)
    80003602:	6be2                	ld	s7,24(sp)
    80003604:	6c42                	ld	s8,16(sp)
    80003606:	6ca2                	ld	s9,8(sp)
    80003608:	6125                	addi	sp,sp,96
    8000360a:	8082                	ret

000000008000360c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000360c:	7179                	addi	sp,sp,-48
    8000360e:	f406                	sd	ra,40(sp)
    80003610:	f022                	sd	s0,32(sp)
    80003612:	ec26                	sd	s1,24(sp)
    80003614:	e84a                	sd	s2,16(sp)
    80003616:	e44e                	sd	s3,8(sp)
    80003618:	e052                	sd	s4,0(sp)
    8000361a:	1800                	addi	s0,sp,48
    8000361c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000361e:	47ad                	li	a5,11
    80003620:	04b7fe63          	bgeu	a5,a1,8000367c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003624:	ff45849b          	addiw	s1,a1,-12
    80003628:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000362c:	0ff00793          	li	a5,255
    80003630:	0ae7e463          	bltu	a5,a4,800036d8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003634:	08052583          	lw	a1,128(a0)
    80003638:	c5b5                	beqz	a1,800036a4 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000363a:	00092503          	lw	a0,0(s2)
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	bde080e7          	jalr	-1058(ra) # 8000321c <bread>
    80003646:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003648:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000364c:	02049713          	slli	a4,s1,0x20
    80003650:	01e75593          	srli	a1,a4,0x1e
    80003654:	00b784b3          	add	s1,a5,a1
    80003658:	0004a983          	lw	s3,0(s1)
    8000365c:	04098e63          	beqz	s3,800036b8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003660:	8552                	mv	a0,s4
    80003662:	00000097          	auipc	ra,0x0
    80003666:	cea080e7          	jalr	-790(ra) # 8000334c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000366a:	854e                	mv	a0,s3
    8000366c:	70a2                	ld	ra,40(sp)
    8000366e:	7402                	ld	s0,32(sp)
    80003670:	64e2                	ld	s1,24(sp)
    80003672:	6942                	ld	s2,16(sp)
    80003674:	69a2                	ld	s3,8(sp)
    80003676:	6a02                	ld	s4,0(sp)
    80003678:	6145                	addi	sp,sp,48
    8000367a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000367c:	02059793          	slli	a5,a1,0x20
    80003680:	01e7d593          	srli	a1,a5,0x1e
    80003684:	00b504b3          	add	s1,a0,a1
    80003688:	0504a983          	lw	s3,80(s1)
    8000368c:	fc099fe3          	bnez	s3,8000366a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003690:	4108                	lw	a0,0(a0)
    80003692:	00000097          	auipc	ra,0x0
    80003696:	e4c080e7          	jalr	-436(ra) # 800034de <balloc>
    8000369a:	0005099b          	sext.w	s3,a0
    8000369e:	0534a823          	sw	s3,80(s1)
    800036a2:	b7e1                	j	8000366a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036a4:	4108                	lw	a0,0(a0)
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	e38080e7          	jalr	-456(ra) # 800034de <balloc>
    800036ae:	0005059b          	sext.w	a1,a0
    800036b2:	08b92023          	sw	a1,128(s2)
    800036b6:	b751                	j	8000363a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036b8:	00092503          	lw	a0,0(s2)
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	e22080e7          	jalr	-478(ra) # 800034de <balloc>
    800036c4:	0005099b          	sext.w	s3,a0
    800036c8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036cc:	8552                	mv	a0,s4
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	f02080e7          	jalr	-254(ra) # 800045d0 <log_write>
    800036d6:	b769                	j	80003660 <bmap+0x54>
  panic("bmap: out of range");
    800036d8:	00005517          	auipc	a0,0x5
    800036dc:	ea850513          	addi	a0,a0,-344 # 80008580 <syscalls+0x138>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	e5a080e7          	jalr	-422(ra) # 8000053a <panic>

00000000800036e8 <iget>:
{
    800036e8:	7179                	addi	sp,sp,-48
    800036ea:	f406                	sd	ra,40(sp)
    800036ec:	f022                	sd	s0,32(sp)
    800036ee:	ec26                	sd	s1,24(sp)
    800036f0:	e84a                	sd	s2,16(sp)
    800036f2:	e44e                	sd	s3,8(sp)
    800036f4:	e052                	sd	s4,0(sp)
    800036f6:	1800                	addi	s0,sp,48
    800036f8:	89aa                	mv	s3,a0
    800036fa:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036fc:	0001c517          	auipc	a0,0x1c
    80003700:	2cc50513          	addi	a0,a0,716 # 8001f9c8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	4cc080e7          	jalr	1228(ra) # 80000bd0 <acquire>
  empty = 0;
    8000370c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000370e:	0001c497          	auipc	s1,0x1c
    80003712:	2d248493          	addi	s1,s1,722 # 8001f9e0 <itable+0x18>
    80003716:	0001e697          	auipc	a3,0x1e
    8000371a:	d5a68693          	addi	a3,a3,-678 # 80021470 <log>
    8000371e:	a039                	j	8000372c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003720:	02090b63          	beqz	s2,80003756 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003724:	08848493          	addi	s1,s1,136
    80003728:	02d48a63          	beq	s1,a3,8000375c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000372c:	449c                	lw	a5,8(s1)
    8000372e:	fef059e3          	blez	a5,80003720 <iget+0x38>
    80003732:	4098                	lw	a4,0(s1)
    80003734:	ff3716e3          	bne	a4,s3,80003720 <iget+0x38>
    80003738:	40d8                	lw	a4,4(s1)
    8000373a:	ff4713e3          	bne	a4,s4,80003720 <iget+0x38>
      ip->ref++;
    8000373e:	2785                	addiw	a5,a5,1
    80003740:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003742:	0001c517          	auipc	a0,0x1c
    80003746:	28650513          	addi	a0,a0,646 # 8001f9c8 <itable>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	53a080e7          	jalr	1338(ra) # 80000c84 <release>
      return ip;
    80003752:	8926                	mv	s2,s1
    80003754:	a03d                	j	80003782 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003756:	f7f9                	bnez	a5,80003724 <iget+0x3c>
    80003758:	8926                	mv	s2,s1
    8000375a:	b7e9                	j	80003724 <iget+0x3c>
  if(empty == 0)
    8000375c:	02090c63          	beqz	s2,80003794 <iget+0xac>
  ip->dev = dev;
    80003760:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003764:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003768:	4785                	li	a5,1
    8000376a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000376e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003772:	0001c517          	auipc	a0,0x1c
    80003776:	25650513          	addi	a0,a0,598 # 8001f9c8 <itable>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	50a080e7          	jalr	1290(ra) # 80000c84 <release>
}
    80003782:	854a                	mv	a0,s2
    80003784:	70a2                	ld	ra,40(sp)
    80003786:	7402                	ld	s0,32(sp)
    80003788:	64e2                	ld	s1,24(sp)
    8000378a:	6942                	ld	s2,16(sp)
    8000378c:	69a2                	ld	s3,8(sp)
    8000378e:	6a02                	ld	s4,0(sp)
    80003790:	6145                	addi	sp,sp,48
    80003792:	8082                	ret
    panic("iget: no inodes");
    80003794:	00005517          	auipc	a0,0x5
    80003798:	e0450513          	addi	a0,a0,-508 # 80008598 <syscalls+0x150>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	d9e080e7          	jalr	-610(ra) # 8000053a <panic>

00000000800037a4 <fsinit>:
fsinit(int dev) {
    800037a4:	7179                	addi	sp,sp,-48
    800037a6:	f406                	sd	ra,40(sp)
    800037a8:	f022                	sd	s0,32(sp)
    800037aa:	ec26                	sd	s1,24(sp)
    800037ac:	e84a                	sd	s2,16(sp)
    800037ae:	e44e                	sd	s3,8(sp)
    800037b0:	1800                	addi	s0,sp,48
    800037b2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037b4:	4585                	li	a1,1
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	a66080e7          	jalr	-1434(ra) # 8000321c <bread>
    800037be:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037c0:	0001c997          	auipc	s3,0x1c
    800037c4:	1e898993          	addi	s3,s3,488 # 8001f9a8 <sb>
    800037c8:	02000613          	li	a2,32
    800037cc:	05850593          	addi	a1,a0,88
    800037d0:	854e                	mv	a0,s3
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	556080e7          	jalr	1366(ra) # 80000d28 <memmove>
  brelse(bp);
    800037da:	8526                	mv	a0,s1
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	b70080e7          	jalr	-1168(ra) # 8000334c <brelse>
  if(sb.magic != FSMAGIC)
    800037e4:	0009a703          	lw	a4,0(s3)
    800037e8:	102037b7          	lui	a5,0x10203
    800037ec:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037f0:	02f71263          	bne	a4,a5,80003814 <fsinit+0x70>
  initlog(dev, &sb);
    800037f4:	0001c597          	auipc	a1,0x1c
    800037f8:	1b458593          	addi	a1,a1,436 # 8001f9a8 <sb>
    800037fc:	854a                	mv	a0,s2
    800037fe:	00001097          	auipc	ra,0x1
    80003802:	b56080e7          	jalr	-1194(ra) # 80004354 <initlog>
}
    80003806:	70a2                	ld	ra,40(sp)
    80003808:	7402                	ld	s0,32(sp)
    8000380a:	64e2                	ld	s1,24(sp)
    8000380c:	6942                	ld	s2,16(sp)
    8000380e:	69a2                	ld	s3,8(sp)
    80003810:	6145                	addi	sp,sp,48
    80003812:	8082                	ret
    panic("invalid file system");
    80003814:	00005517          	auipc	a0,0x5
    80003818:	d9450513          	addi	a0,a0,-620 # 800085a8 <syscalls+0x160>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	d1e080e7          	jalr	-738(ra) # 8000053a <panic>

0000000080003824 <iinit>:
{
    80003824:	7179                	addi	sp,sp,-48
    80003826:	f406                	sd	ra,40(sp)
    80003828:	f022                	sd	s0,32(sp)
    8000382a:	ec26                	sd	s1,24(sp)
    8000382c:	e84a                	sd	s2,16(sp)
    8000382e:	e44e                	sd	s3,8(sp)
    80003830:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003832:	00005597          	auipc	a1,0x5
    80003836:	d8e58593          	addi	a1,a1,-626 # 800085c0 <syscalls+0x178>
    8000383a:	0001c517          	auipc	a0,0x1c
    8000383e:	18e50513          	addi	a0,a0,398 # 8001f9c8 <itable>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	2fe080e7          	jalr	766(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000384a:	0001c497          	auipc	s1,0x1c
    8000384e:	1a648493          	addi	s1,s1,422 # 8001f9f0 <itable+0x28>
    80003852:	0001e997          	auipc	s3,0x1e
    80003856:	c2e98993          	addi	s3,s3,-978 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000385a:	00005917          	auipc	s2,0x5
    8000385e:	d6e90913          	addi	s2,s2,-658 # 800085c8 <syscalls+0x180>
    80003862:	85ca                	mv	a1,s2
    80003864:	8526                	mv	a0,s1
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	e4e080e7          	jalr	-434(ra) # 800046b4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000386e:	08848493          	addi	s1,s1,136
    80003872:	ff3498e3          	bne	s1,s3,80003862 <iinit+0x3e>
}
    80003876:	70a2                	ld	ra,40(sp)
    80003878:	7402                	ld	s0,32(sp)
    8000387a:	64e2                	ld	s1,24(sp)
    8000387c:	6942                	ld	s2,16(sp)
    8000387e:	69a2                	ld	s3,8(sp)
    80003880:	6145                	addi	sp,sp,48
    80003882:	8082                	ret

0000000080003884 <ialloc>:
{
    80003884:	715d                	addi	sp,sp,-80
    80003886:	e486                	sd	ra,72(sp)
    80003888:	e0a2                	sd	s0,64(sp)
    8000388a:	fc26                	sd	s1,56(sp)
    8000388c:	f84a                	sd	s2,48(sp)
    8000388e:	f44e                	sd	s3,40(sp)
    80003890:	f052                	sd	s4,32(sp)
    80003892:	ec56                	sd	s5,24(sp)
    80003894:	e85a                	sd	s6,16(sp)
    80003896:	e45e                	sd	s7,8(sp)
    80003898:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000389a:	0001c717          	auipc	a4,0x1c
    8000389e:	11a72703          	lw	a4,282(a4) # 8001f9b4 <sb+0xc>
    800038a2:	4785                	li	a5,1
    800038a4:	04e7fa63          	bgeu	a5,a4,800038f8 <ialloc+0x74>
    800038a8:	8aaa                	mv	s5,a0
    800038aa:	8bae                	mv	s7,a1
    800038ac:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038ae:	0001ca17          	auipc	s4,0x1c
    800038b2:	0faa0a13          	addi	s4,s4,250 # 8001f9a8 <sb>
    800038b6:	00048b1b          	sext.w	s6,s1
    800038ba:	0044d593          	srli	a1,s1,0x4
    800038be:	018a2783          	lw	a5,24(s4)
    800038c2:	9dbd                	addw	a1,a1,a5
    800038c4:	8556                	mv	a0,s5
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	956080e7          	jalr	-1706(ra) # 8000321c <bread>
    800038ce:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038d0:	05850993          	addi	s3,a0,88
    800038d4:	00f4f793          	andi	a5,s1,15
    800038d8:	079a                	slli	a5,a5,0x6
    800038da:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038dc:	00099783          	lh	a5,0(s3)
    800038e0:	c785                	beqz	a5,80003908 <ialloc+0x84>
    brelse(bp);
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	a6a080e7          	jalr	-1430(ra) # 8000334c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ea:	0485                	addi	s1,s1,1
    800038ec:	00ca2703          	lw	a4,12(s4)
    800038f0:	0004879b          	sext.w	a5,s1
    800038f4:	fce7e1e3          	bltu	a5,a4,800038b6 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	cd850513          	addi	a0,a0,-808 # 800085d0 <syscalls+0x188>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c3a080e7          	jalr	-966(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003908:	04000613          	li	a2,64
    8000390c:	4581                	li	a1,0
    8000390e:	854e                	mv	a0,s3
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	3bc080e7          	jalr	956(ra) # 80000ccc <memset>
      dip->type = type;
    80003918:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000391c:	854a                	mv	a0,s2
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	cb2080e7          	jalr	-846(ra) # 800045d0 <log_write>
      brelse(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	a24080e7          	jalr	-1500(ra) # 8000334c <brelse>
      return iget(dev, inum);
    80003930:	85da                	mv	a1,s6
    80003932:	8556                	mv	a0,s5
    80003934:	00000097          	auipc	ra,0x0
    80003938:	db4080e7          	jalr	-588(ra) # 800036e8 <iget>
}
    8000393c:	60a6                	ld	ra,72(sp)
    8000393e:	6406                	ld	s0,64(sp)
    80003940:	74e2                	ld	s1,56(sp)
    80003942:	7942                	ld	s2,48(sp)
    80003944:	79a2                	ld	s3,40(sp)
    80003946:	7a02                	ld	s4,32(sp)
    80003948:	6ae2                	ld	s5,24(sp)
    8000394a:	6b42                	ld	s6,16(sp)
    8000394c:	6ba2                	ld	s7,8(sp)
    8000394e:	6161                	addi	sp,sp,80
    80003950:	8082                	ret

0000000080003952 <iupdate>:
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	e04a                	sd	s2,0(sp)
    8000395c:	1000                	addi	s0,sp,32
    8000395e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003960:	415c                	lw	a5,4(a0)
    80003962:	0047d79b          	srliw	a5,a5,0x4
    80003966:	0001c597          	auipc	a1,0x1c
    8000396a:	05a5a583          	lw	a1,90(a1) # 8001f9c0 <sb+0x18>
    8000396e:	9dbd                	addw	a1,a1,a5
    80003970:	4108                	lw	a0,0(a0)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	8aa080e7          	jalr	-1878(ra) # 8000321c <bread>
    8000397a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000397c:	05850793          	addi	a5,a0,88
    80003980:	40d8                	lw	a4,4(s1)
    80003982:	8b3d                	andi	a4,a4,15
    80003984:	071a                	slli	a4,a4,0x6
    80003986:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003988:	04449703          	lh	a4,68(s1)
    8000398c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003990:	04649703          	lh	a4,70(s1)
    80003994:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003998:	04849703          	lh	a4,72(s1)
    8000399c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039a0:	04a49703          	lh	a4,74(s1)
    800039a4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039a8:	44f8                	lw	a4,76(s1)
    800039aa:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039ac:	03400613          	li	a2,52
    800039b0:	05048593          	addi	a1,s1,80
    800039b4:	00c78513          	addi	a0,a5,12
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	370080e7          	jalr	880(ra) # 80000d28 <memmove>
  log_write(bp);
    800039c0:	854a                	mv	a0,s2
    800039c2:	00001097          	auipc	ra,0x1
    800039c6:	c0e080e7          	jalr	-1010(ra) # 800045d0 <log_write>
  brelse(bp);
    800039ca:	854a                	mv	a0,s2
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	980080e7          	jalr	-1664(ra) # 8000334c <brelse>
}
    800039d4:	60e2                	ld	ra,24(sp)
    800039d6:	6442                	ld	s0,16(sp)
    800039d8:	64a2                	ld	s1,8(sp)
    800039da:	6902                	ld	s2,0(sp)
    800039dc:	6105                	addi	sp,sp,32
    800039de:	8082                	ret

00000000800039e0 <idup>:
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	1000                	addi	s0,sp,32
    800039ea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ec:	0001c517          	auipc	a0,0x1c
    800039f0:	fdc50513          	addi	a0,a0,-36 # 8001f9c8 <itable>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	1dc080e7          	jalr	476(ra) # 80000bd0 <acquire>
  ip->ref++;
    800039fc:	449c                	lw	a5,8(s1)
    800039fe:	2785                	addiw	a5,a5,1
    80003a00:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a02:	0001c517          	auipc	a0,0x1c
    80003a06:	fc650513          	addi	a0,a0,-58 # 8001f9c8 <itable>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	27a080e7          	jalr	634(ra) # 80000c84 <release>
}
    80003a12:	8526                	mv	a0,s1
    80003a14:	60e2                	ld	ra,24(sp)
    80003a16:	6442                	ld	s0,16(sp)
    80003a18:	64a2                	ld	s1,8(sp)
    80003a1a:	6105                	addi	sp,sp,32
    80003a1c:	8082                	ret

0000000080003a1e <ilock>:
{
    80003a1e:	1101                	addi	sp,sp,-32
    80003a20:	ec06                	sd	ra,24(sp)
    80003a22:	e822                	sd	s0,16(sp)
    80003a24:	e426                	sd	s1,8(sp)
    80003a26:	e04a                	sd	s2,0(sp)
    80003a28:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a2a:	c115                	beqz	a0,80003a4e <ilock+0x30>
    80003a2c:	84aa                	mv	s1,a0
    80003a2e:	451c                	lw	a5,8(a0)
    80003a30:	00f05f63          	blez	a5,80003a4e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a34:	0541                	addi	a0,a0,16
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	cb8080e7          	jalr	-840(ra) # 800046ee <acquiresleep>
  if(ip->valid == 0){
    80003a3e:	40bc                	lw	a5,64(s1)
    80003a40:	cf99                	beqz	a5,80003a5e <ilock+0x40>
}
    80003a42:	60e2                	ld	ra,24(sp)
    80003a44:	6442                	ld	s0,16(sp)
    80003a46:	64a2                	ld	s1,8(sp)
    80003a48:	6902                	ld	s2,0(sp)
    80003a4a:	6105                	addi	sp,sp,32
    80003a4c:	8082                	ret
    panic("ilock");
    80003a4e:	00005517          	auipc	a0,0x5
    80003a52:	b9a50513          	addi	a0,a0,-1126 # 800085e8 <syscalls+0x1a0>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	ae4080e7          	jalr	-1308(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a5e:	40dc                	lw	a5,4(s1)
    80003a60:	0047d79b          	srliw	a5,a5,0x4
    80003a64:	0001c597          	auipc	a1,0x1c
    80003a68:	f5c5a583          	lw	a1,-164(a1) # 8001f9c0 <sb+0x18>
    80003a6c:	9dbd                	addw	a1,a1,a5
    80003a6e:	4088                	lw	a0,0(s1)
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	7ac080e7          	jalr	1964(ra) # 8000321c <bread>
    80003a78:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a7a:	05850593          	addi	a1,a0,88
    80003a7e:	40dc                	lw	a5,4(s1)
    80003a80:	8bbd                	andi	a5,a5,15
    80003a82:	079a                	slli	a5,a5,0x6
    80003a84:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a86:	00059783          	lh	a5,0(a1)
    80003a8a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a8e:	00259783          	lh	a5,2(a1)
    80003a92:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a96:	00459783          	lh	a5,4(a1)
    80003a9a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a9e:	00659783          	lh	a5,6(a1)
    80003aa2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003aa6:	459c                	lw	a5,8(a1)
    80003aa8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003aaa:	03400613          	li	a2,52
    80003aae:	05b1                	addi	a1,a1,12
    80003ab0:	05048513          	addi	a0,s1,80
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	274080e7          	jalr	628(ra) # 80000d28 <memmove>
    brelse(bp);
    80003abc:	854a                	mv	a0,s2
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	88e080e7          	jalr	-1906(ra) # 8000334c <brelse>
    ip->valid = 1;
    80003ac6:	4785                	li	a5,1
    80003ac8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003aca:	04449783          	lh	a5,68(s1)
    80003ace:	fbb5                	bnez	a5,80003a42 <ilock+0x24>
      panic("ilock: no type");
    80003ad0:	00005517          	auipc	a0,0x5
    80003ad4:	b2050513          	addi	a0,a0,-1248 # 800085f0 <syscalls+0x1a8>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	a62080e7          	jalr	-1438(ra) # 8000053a <panic>

0000000080003ae0 <iunlock>:
{
    80003ae0:	1101                	addi	sp,sp,-32
    80003ae2:	ec06                	sd	ra,24(sp)
    80003ae4:	e822                	sd	s0,16(sp)
    80003ae6:	e426                	sd	s1,8(sp)
    80003ae8:	e04a                	sd	s2,0(sp)
    80003aea:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003aec:	c905                	beqz	a0,80003b1c <iunlock+0x3c>
    80003aee:	84aa                	mv	s1,a0
    80003af0:	01050913          	addi	s2,a0,16
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	c92080e7          	jalr	-878(ra) # 80004788 <holdingsleep>
    80003afe:	cd19                	beqz	a0,80003b1c <iunlock+0x3c>
    80003b00:	449c                	lw	a5,8(s1)
    80003b02:	00f05d63          	blez	a5,80003b1c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b06:	854a                	mv	a0,s2
    80003b08:	00001097          	auipc	ra,0x1
    80003b0c:	c3c080e7          	jalr	-964(ra) # 80004744 <releasesleep>
}
    80003b10:	60e2                	ld	ra,24(sp)
    80003b12:	6442                	ld	s0,16(sp)
    80003b14:	64a2                	ld	s1,8(sp)
    80003b16:	6902                	ld	s2,0(sp)
    80003b18:	6105                	addi	sp,sp,32
    80003b1a:	8082                	ret
    panic("iunlock");
    80003b1c:	00005517          	auipc	a0,0x5
    80003b20:	ae450513          	addi	a0,a0,-1308 # 80008600 <syscalls+0x1b8>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	a16080e7          	jalr	-1514(ra) # 8000053a <panic>

0000000080003b2c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b2c:	7179                	addi	sp,sp,-48
    80003b2e:	f406                	sd	ra,40(sp)
    80003b30:	f022                	sd	s0,32(sp)
    80003b32:	ec26                	sd	s1,24(sp)
    80003b34:	e84a                	sd	s2,16(sp)
    80003b36:	e44e                	sd	s3,8(sp)
    80003b38:	e052                	sd	s4,0(sp)
    80003b3a:	1800                	addi	s0,sp,48
    80003b3c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b3e:	05050493          	addi	s1,a0,80
    80003b42:	08050913          	addi	s2,a0,128
    80003b46:	a021                	j	80003b4e <itrunc+0x22>
    80003b48:	0491                	addi	s1,s1,4
    80003b4a:	01248d63          	beq	s1,s2,80003b64 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b4e:	408c                	lw	a1,0(s1)
    80003b50:	dde5                	beqz	a1,80003b48 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b52:	0009a503          	lw	a0,0(s3)
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	90c080e7          	jalr	-1780(ra) # 80003462 <bfree>
      ip->addrs[i] = 0;
    80003b5e:	0004a023          	sw	zero,0(s1)
    80003b62:	b7dd                	j	80003b48 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b64:	0809a583          	lw	a1,128(s3)
    80003b68:	e185                	bnez	a1,80003b88 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b6a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b6e:	854e                	mv	a0,s3
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	de2080e7          	jalr	-542(ra) # 80003952 <iupdate>
}
    80003b78:	70a2                	ld	ra,40(sp)
    80003b7a:	7402                	ld	s0,32(sp)
    80003b7c:	64e2                	ld	s1,24(sp)
    80003b7e:	6942                	ld	s2,16(sp)
    80003b80:	69a2                	ld	s3,8(sp)
    80003b82:	6a02                	ld	s4,0(sp)
    80003b84:	6145                	addi	sp,sp,48
    80003b86:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b88:	0009a503          	lw	a0,0(s3)
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	690080e7          	jalr	1680(ra) # 8000321c <bread>
    80003b94:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b96:	05850493          	addi	s1,a0,88
    80003b9a:	45850913          	addi	s2,a0,1112
    80003b9e:	a021                	j	80003ba6 <itrunc+0x7a>
    80003ba0:	0491                	addi	s1,s1,4
    80003ba2:	01248b63          	beq	s1,s2,80003bb8 <itrunc+0x8c>
      if(a[j])
    80003ba6:	408c                	lw	a1,0(s1)
    80003ba8:	dde5                	beqz	a1,80003ba0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003baa:	0009a503          	lw	a0,0(s3)
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	8b4080e7          	jalr	-1868(ra) # 80003462 <bfree>
    80003bb6:	b7ed                	j	80003ba0 <itrunc+0x74>
    brelse(bp);
    80003bb8:	8552                	mv	a0,s4
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	792080e7          	jalr	1938(ra) # 8000334c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bc2:	0809a583          	lw	a1,128(s3)
    80003bc6:	0009a503          	lw	a0,0(s3)
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	898080e7          	jalr	-1896(ra) # 80003462 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bd2:	0809a023          	sw	zero,128(s3)
    80003bd6:	bf51                	j	80003b6a <itrunc+0x3e>

0000000080003bd8 <iput>:
{
    80003bd8:	1101                	addi	sp,sp,-32
    80003bda:	ec06                	sd	ra,24(sp)
    80003bdc:	e822                	sd	s0,16(sp)
    80003bde:	e426                	sd	s1,8(sp)
    80003be0:	e04a                	sd	s2,0(sp)
    80003be2:	1000                	addi	s0,sp,32
    80003be4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003be6:	0001c517          	auipc	a0,0x1c
    80003bea:	de250513          	addi	a0,a0,-542 # 8001f9c8 <itable>
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	fe2080e7          	jalr	-30(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bf6:	4498                	lw	a4,8(s1)
    80003bf8:	4785                	li	a5,1
    80003bfa:	02f70363          	beq	a4,a5,80003c20 <iput+0x48>
  ip->ref--;
    80003bfe:	449c                	lw	a5,8(s1)
    80003c00:	37fd                	addiw	a5,a5,-1
    80003c02:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c04:	0001c517          	auipc	a0,0x1c
    80003c08:	dc450513          	addi	a0,a0,-572 # 8001f9c8 <itable>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	078080e7          	jalr	120(ra) # 80000c84 <release>
}
    80003c14:	60e2                	ld	ra,24(sp)
    80003c16:	6442                	ld	s0,16(sp)
    80003c18:	64a2                	ld	s1,8(sp)
    80003c1a:	6902                	ld	s2,0(sp)
    80003c1c:	6105                	addi	sp,sp,32
    80003c1e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c20:	40bc                	lw	a5,64(s1)
    80003c22:	dff1                	beqz	a5,80003bfe <iput+0x26>
    80003c24:	04a49783          	lh	a5,74(s1)
    80003c28:	fbf9                	bnez	a5,80003bfe <iput+0x26>
    acquiresleep(&ip->lock);
    80003c2a:	01048913          	addi	s2,s1,16
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00001097          	auipc	ra,0x1
    80003c34:	abe080e7          	jalr	-1346(ra) # 800046ee <acquiresleep>
    release(&itable.lock);
    80003c38:	0001c517          	auipc	a0,0x1c
    80003c3c:	d9050513          	addi	a0,a0,-624 # 8001f9c8 <itable>
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	044080e7          	jalr	68(ra) # 80000c84 <release>
    itrunc(ip);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	ee2080e7          	jalr	-286(ra) # 80003b2c <itrunc>
    ip->type = 0;
    80003c52:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c56:	8526                	mv	a0,s1
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	cfa080e7          	jalr	-774(ra) # 80003952 <iupdate>
    ip->valid = 0;
    80003c60:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c64:	854a                	mv	a0,s2
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	ade080e7          	jalr	-1314(ra) # 80004744 <releasesleep>
    acquire(&itable.lock);
    80003c6e:	0001c517          	auipc	a0,0x1c
    80003c72:	d5a50513          	addi	a0,a0,-678 # 8001f9c8 <itable>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	f5a080e7          	jalr	-166(ra) # 80000bd0 <acquire>
    80003c7e:	b741                	j	80003bfe <iput+0x26>

0000000080003c80 <iunlockput>:
{
    80003c80:	1101                	addi	sp,sp,-32
    80003c82:	ec06                	sd	ra,24(sp)
    80003c84:	e822                	sd	s0,16(sp)
    80003c86:	e426                	sd	s1,8(sp)
    80003c88:	1000                	addi	s0,sp,32
    80003c8a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	e54080e7          	jalr	-428(ra) # 80003ae0 <iunlock>
  iput(ip);
    80003c94:	8526                	mv	a0,s1
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	f42080e7          	jalr	-190(ra) # 80003bd8 <iput>
}
    80003c9e:	60e2                	ld	ra,24(sp)
    80003ca0:	6442                	ld	s0,16(sp)
    80003ca2:	64a2                	ld	s1,8(sp)
    80003ca4:	6105                	addi	sp,sp,32
    80003ca6:	8082                	ret

0000000080003ca8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ca8:	1141                	addi	sp,sp,-16
    80003caa:	e422                	sd	s0,8(sp)
    80003cac:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cae:	411c                	lw	a5,0(a0)
    80003cb0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cb2:	415c                	lw	a5,4(a0)
    80003cb4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cb6:	04451783          	lh	a5,68(a0)
    80003cba:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cbe:	04a51783          	lh	a5,74(a0)
    80003cc2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cc6:	04c56783          	lwu	a5,76(a0)
    80003cca:	e99c                	sd	a5,16(a1)
}
    80003ccc:	6422                	ld	s0,8(sp)
    80003cce:	0141                	addi	sp,sp,16
    80003cd0:	8082                	ret

0000000080003cd2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cd2:	457c                	lw	a5,76(a0)
    80003cd4:	0ed7e963          	bltu	a5,a3,80003dc6 <readi+0xf4>
{
    80003cd8:	7159                	addi	sp,sp,-112
    80003cda:	f486                	sd	ra,104(sp)
    80003cdc:	f0a2                	sd	s0,96(sp)
    80003cde:	eca6                	sd	s1,88(sp)
    80003ce0:	e8ca                	sd	s2,80(sp)
    80003ce2:	e4ce                	sd	s3,72(sp)
    80003ce4:	e0d2                	sd	s4,64(sp)
    80003ce6:	fc56                	sd	s5,56(sp)
    80003ce8:	f85a                	sd	s6,48(sp)
    80003cea:	f45e                	sd	s7,40(sp)
    80003cec:	f062                	sd	s8,32(sp)
    80003cee:	ec66                	sd	s9,24(sp)
    80003cf0:	e86a                	sd	s10,16(sp)
    80003cf2:	e46e                	sd	s11,8(sp)
    80003cf4:	1880                	addi	s0,sp,112
    80003cf6:	8baa                	mv	s7,a0
    80003cf8:	8c2e                	mv	s8,a1
    80003cfa:	8ab2                	mv	s5,a2
    80003cfc:	84b6                	mv	s1,a3
    80003cfe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d00:	9f35                	addw	a4,a4,a3
    return 0;
    80003d02:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d04:	0ad76063          	bltu	a4,a3,80003da4 <readi+0xd2>
  if(off + n > ip->size)
    80003d08:	00e7f463          	bgeu	a5,a4,80003d10 <readi+0x3e>
    n = ip->size - off;
    80003d0c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d10:	0a0b0963          	beqz	s6,80003dc2 <readi+0xf0>
    80003d14:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d16:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d1a:	5cfd                	li	s9,-1
    80003d1c:	a82d                	j	80003d56 <readi+0x84>
    80003d1e:	020a1d93          	slli	s11,s4,0x20
    80003d22:	020ddd93          	srli	s11,s11,0x20
    80003d26:	05890613          	addi	a2,s2,88
    80003d2a:	86ee                	mv	a3,s11
    80003d2c:	963a                	add	a2,a2,a4
    80003d2e:	85d6                	mv	a1,s5
    80003d30:	8562                	mv	a0,s8
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	8d4080e7          	jalr	-1836(ra) # 80002606 <either_copyout>
    80003d3a:	05950d63          	beq	a0,s9,80003d94 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d3e:	854a                	mv	a0,s2
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	60c080e7          	jalr	1548(ra) # 8000334c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d48:	013a09bb          	addw	s3,s4,s3
    80003d4c:	009a04bb          	addw	s1,s4,s1
    80003d50:	9aee                	add	s5,s5,s11
    80003d52:	0569f763          	bgeu	s3,s6,80003da0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d56:	000ba903          	lw	s2,0(s7)
    80003d5a:	00a4d59b          	srliw	a1,s1,0xa
    80003d5e:	855e                	mv	a0,s7
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	8ac080e7          	jalr	-1876(ra) # 8000360c <bmap>
    80003d68:	0005059b          	sext.w	a1,a0
    80003d6c:	854a                	mv	a0,s2
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	4ae080e7          	jalr	1198(ra) # 8000321c <bread>
    80003d76:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d78:	3ff4f713          	andi	a4,s1,1023
    80003d7c:	40ed07bb          	subw	a5,s10,a4
    80003d80:	413b06bb          	subw	a3,s6,s3
    80003d84:	8a3e                	mv	s4,a5
    80003d86:	2781                	sext.w	a5,a5
    80003d88:	0006861b          	sext.w	a2,a3
    80003d8c:	f8f679e3          	bgeu	a2,a5,80003d1e <readi+0x4c>
    80003d90:	8a36                	mv	s4,a3
    80003d92:	b771                	j	80003d1e <readi+0x4c>
      brelse(bp);
    80003d94:	854a                	mv	a0,s2
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	5b6080e7          	jalr	1462(ra) # 8000334c <brelse>
      tot = -1;
    80003d9e:	59fd                	li	s3,-1
  }
  return tot;
    80003da0:	0009851b          	sext.w	a0,s3
}
    80003da4:	70a6                	ld	ra,104(sp)
    80003da6:	7406                	ld	s0,96(sp)
    80003da8:	64e6                	ld	s1,88(sp)
    80003daa:	6946                	ld	s2,80(sp)
    80003dac:	69a6                	ld	s3,72(sp)
    80003dae:	6a06                	ld	s4,64(sp)
    80003db0:	7ae2                	ld	s5,56(sp)
    80003db2:	7b42                	ld	s6,48(sp)
    80003db4:	7ba2                	ld	s7,40(sp)
    80003db6:	7c02                	ld	s8,32(sp)
    80003db8:	6ce2                	ld	s9,24(sp)
    80003dba:	6d42                	ld	s10,16(sp)
    80003dbc:	6da2                	ld	s11,8(sp)
    80003dbe:	6165                	addi	sp,sp,112
    80003dc0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dc2:	89da                	mv	s3,s6
    80003dc4:	bff1                	j	80003da0 <readi+0xce>
    return 0;
    80003dc6:	4501                	li	a0,0
}
    80003dc8:	8082                	ret

0000000080003dca <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dca:	457c                	lw	a5,76(a0)
    80003dcc:	10d7e863          	bltu	a5,a3,80003edc <writei+0x112>
{
    80003dd0:	7159                	addi	sp,sp,-112
    80003dd2:	f486                	sd	ra,104(sp)
    80003dd4:	f0a2                	sd	s0,96(sp)
    80003dd6:	eca6                	sd	s1,88(sp)
    80003dd8:	e8ca                	sd	s2,80(sp)
    80003dda:	e4ce                	sd	s3,72(sp)
    80003ddc:	e0d2                	sd	s4,64(sp)
    80003dde:	fc56                	sd	s5,56(sp)
    80003de0:	f85a                	sd	s6,48(sp)
    80003de2:	f45e                	sd	s7,40(sp)
    80003de4:	f062                	sd	s8,32(sp)
    80003de6:	ec66                	sd	s9,24(sp)
    80003de8:	e86a                	sd	s10,16(sp)
    80003dea:	e46e                	sd	s11,8(sp)
    80003dec:	1880                	addi	s0,sp,112
    80003dee:	8b2a                	mv	s6,a0
    80003df0:	8c2e                	mv	s8,a1
    80003df2:	8ab2                	mv	s5,a2
    80003df4:	8936                	mv	s2,a3
    80003df6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003df8:	00e687bb          	addw	a5,a3,a4
    80003dfc:	0ed7e263          	bltu	a5,a3,80003ee0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e00:	00043737          	lui	a4,0x43
    80003e04:	0ef76063          	bltu	a4,a5,80003ee4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e08:	0c0b8863          	beqz	s7,80003ed8 <writei+0x10e>
    80003e0c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e0e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e12:	5cfd                	li	s9,-1
    80003e14:	a091                	j	80003e58 <writei+0x8e>
    80003e16:	02099d93          	slli	s11,s3,0x20
    80003e1a:	020ddd93          	srli	s11,s11,0x20
    80003e1e:	05848513          	addi	a0,s1,88
    80003e22:	86ee                	mv	a3,s11
    80003e24:	8656                	mv	a2,s5
    80003e26:	85e2                	mv	a1,s8
    80003e28:	953a                	add	a0,a0,a4
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	832080e7          	jalr	-1998(ra) # 8000265c <either_copyin>
    80003e32:	07950263          	beq	a0,s9,80003e96 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e36:	8526                	mv	a0,s1
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	798080e7          	jalr	1944(ra) # 800045d0 <log_write>
    brelse(bp);
    80003e40:	8526                	mv	a0,s1
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	50a080e7          	jalr	1290(ra) # 8000334c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e4a:	01498a3b          	addw	s4,s3,s4
    80003e4e:	0129893b          	addw	s2,s3,s2
    80003e52:	9aee                	add	s5,s5,s11
    80003e54:	057a7663          	bgeu	s4,s7,80003ea0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e58:	000b2483          	lw	s1,0(s6)
    80003e5c:	00a9559b          	srliw	a1,s2,0xa
    80003e60:	855a                	mv	a0,s6
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	7aa080e7          	jalr	1962(ra) # 8000360c <bmap>
    80003e6a:	0005059b          	sext.w	a1,a0
    80003e6e:	8526                	mv	a0,s1
    80003e70:	fffff097          	auipc	ra,0xfffff
    80003e74:	3ac080e7          	jalr	940(ra) # 8000321c <bread>
    80003e78:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e7a:	3ff97713          	andi	a4,s2,1023
    80003e7e:	40ed07bb          	subw	a5,s10,a4
    80003e82:	414b86bb          	subw	a3,s7,s4
    80003e86:	89be                	mv	s3,a5
    80003e88:	2781                	sext.w	a5,a5
    80003e8a:	0006861b          	sext.w	a2,a3
    80003e8e:	f8f674e3          	bgeu	a2,a5,80003e16 <writei+0x4c>
    80003e92:	89b6                	mv	s3,a3
    80003e94:	b749                	j	80003e16 <writei+0x4c>
      brelse(bp);
    80003e96:	8526                	mv	a0,s1
    80003e98:	fffff097          	auipc	ra,0xfffff
    80003e9c:	4b4080e7          	jalr	1204(ra) # 8000334c <brelse>
  }

  if(off > ip->size)
    80003ea0:	04cb2783          	lw	a5,76(s6)
    80003ea4:	0127f463          	bgeu	a5,s2,80003eac <writei+0xe2>
    ip->size = off;
    80003ea8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003eac:	855a                	mv	a0,s6
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	aa4080e7          	jalr	-1372(ra) # 80003952 <iupdate>

  return tot;
    80003eb6:	000a051b          	sext.w	a0,s4
}
    80003eba:	70a6                	ld	ra,104(sp)
    80003ebc:	7406                	ld	s0,96(sp)
    80003ebe:	64e6                	ld	s1,88(sp)
    80003ec0:	6946                	ld	s2,80(sp)
    80003ec2:	69a6                	ld	s3,72(sp)
    80003ec4:	6a06                	ld	s4,64(sp)
    80003ec6:	7ae2                	ld	s5,56(sp)
    80003ec8:	7b42                	ld	s6,48(sp)
    80003eca:	7ba2                	ld	s7,40(sp)
    80003ecc:	7c02                	ld	s8,32(sp)
    80003ece:	6ce2                	ld	s9,24(sp)
    80003ed0:	6d42                	ld	s10,16(sp)
    80003ed2:	6da2                	ld	s11,8(sp)
    80003ed4:	6165                	addi	sp,sp,112
    80003ed6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ed8:	8a5e                	mv	s4,s7
    80003eda:	bfc9                	j	80003eac <writei+0xe2>
    return -1;
    80003edc:	557d                	li	a0,-1
}
    80003ede:	8082                	ret
    return -1;
    80003ee0:	557d                	li	a0,-1
    80003ee2:	bfe1                	j	80003eba <writei+0xf0>
    return -1;
    80003ee4:	557d                	li	a0,-1
    80003ee6:	bfd1                	j	80003eba <writei+0xf0>

0000000080003ee8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ee8:	1141                	addi	sp,sp,-16
    80003eea:	e406                	sd	ra,8(sp)
    80003eec:	e022                	sd	s0,0(sp)
    80003eee:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ef0:	4639                	li	a2,14
    80003ef2:	ffffd097          	auipc	ra,0xffffd
    80003ef6:	eaa080e7          	jalr	-342(ra) # 80000d9c <strncmp>
}
    80003efa:	60a2                	ld	ra,8(sp)
    80003efc:	6402                	ld	s0,0(sp)
    80003efe:	0141                	addi	sp,sp,16
    80003f00:	8082                	ret

0000000080003f02 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f02:	7139                	addi	sp,sp,-64
    80003f04:	fc06                	sd	ra,56(sp)
    80003f06:	f822                	sd	s0,48(sp)
    80003f08:	f426                	sd	s1,40(sp)
    80003f0a:	f04a                	sd	s2,32(sp)
    80003f0c:	ec4e                	sd	s3,24(sp)
    80003f0e:	e852                	sd	s4,16(sp)
    80003f10:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f12:	04451703          	lh	a4,68(a0)
    80003f16:	4785                	li	a5,1
    80003f18:	00f71a63          	bne	a4,a5,80003f2c <dirlookup+0x2a>
    80003f1c:	892a                	mv	s2,a0
    80003f1e:	89ae                	mv	s3,a1
    80003f20:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f22:	457c                	lw	a5,76(a0)
    80003f24:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f26:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f28:	e79d                	bnez	a5,80003f56 <dirlookup+0x54>
    80003f2a:	a8a5                	j	80003fa2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f2c:	00004517          	auipc	a0,0x4
    80003f30:	6dc50513          	addi	a0,a0,1756 # 80008608 <syscalls+0x1c0>
    80003f34:	ffffc097          	auipc	ra,0xffffc
    80003f38:	606080e7          	jalr	1542(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003f3c:	00004517          	auipc	a0,0x4
    80003f40:	6e450513          	addi	a0,a0,1764 # 80008620 <syscalls+0x1d8>
    80003f44:	ffffc097          	auipc	ra,0xffffc
    80003f48:	5f6080e7          	jalr	1526(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4c:	24c1                	addiw	s1,s1,16
    80003f4e:	04c92783          	lw	a5,76(s2)
    80003f52:	04f4f763          	bgeu	s1,a5,80003fa0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f56:	4741                	li	a4,16
    80003f58:	86a6                	mv	a3,s1
    80003f5a:	fc040613          	addi	a2,s0,-64
    80003f5e:	4581                	li	a1,0
    80003f60:	854a                	mv	a0,s2
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	d70080e7          	jalr	-656(ra) # 80003cd2 <readi>
    80003f6a:	47c1                	li	a5,16
    80003f6c:	fcf518e3          	bne	a0,a5,80003f3c <dirlookup+0x3a>
    if(de.inum == 0)
    80003f70:	fc045783          	lhu	a5,-64(s0)
    80003f74:	dfe1                	beqz	a5,80003f4c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f76:	fc240593          	addi	a1,s0,-62
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	f6c080e7          	jalr	-148(ra) # 80003ee8 <namecmp>
    80003f84:	f561                	bnez	a0,80003f4c <dirlookup+0x4a>
      if(poff)
    80003f86:	000a0463          	beqz	s4,80003f8e <dirlookup+0x8c>
        *poff = off;
    80003f8a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f8e:	fc045583          	lhu	a1,-64(s0)
    80003f92:	00092503          	lw	a0,0(s2)
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	752080e7          	jalr	1874(ra) # 800036e8 <iget>
    80003f9e:	a011                	j	80003fa2 <dirlookup+0xa0>
  return 0;
    80003fa0:	4501                	li	a0,0
}
    80003fa2:	70e2                	ld	ra,56(sp)
    80003fa4:	7442                	ld	s0,48(sp)
    80003fa6:	74a2                	ld	s1,40(sp)
    80003fa8:	7902                	ld	s2,32(sp)
    80003faa:	69e2                	ld	s3,24(sp)
    80003fac:	6a42                	ld	s4,16(sp)
    80003fae:	6121                	addi	sp,sp,64
    80003fb0:	8082                	ret

0000000080003fb2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fb2:	711d                	addi	sp,sp,-96
    80003fb4:	ec86                	sd	ra,88(sp)
    80003fb6:	e8a2                	sd	s0,80(sp)
    80003fb8:	e4a6                	sd	s1,72(sp)
    80003fba:	e0ca                	sd	s2,64(sp)
    80003fbc:	fc4e                	sd	s3,56(sp)
    80003fbe:	f852                	sd	s4,48(sp)
    80003fc0:	f456                	sd	s5,40(sp)
    80003fc2:	f05a                	sd	s6,32(sp)
    80003fc4:	ec5e                	sd	s7,24(sp)
    80003fc6:	e862                	sd	s8,16(sp)
    80003fc8:	e466                	sd	s9,8(sp)
    80003fca:	e06a                	sd	s10,0(sp)
    80003fcc:	1080                	addi	s0,sp,96
    80003fce:	84aa                	mv	s1,a0
    80003fd0:	8b2e                	mv	s6,a1
    80003fd2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fd4:	00054703          	lbu	a4,0(a0)
    80003fd8:	02f00793          	li	a5,47
    80003fdc:	02f70363          	beq	a4,a5,80004002 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fe0:	ffffe097          	auipc	ra,0xffffe
    80003fe4:	9b6080e7          	jalr	-1610(ra) # 80001996 <myproc>
    80003fe8:	15853503          	ld	a0,344(a0)
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	9f4080e7          	jalr	-1548(ra) # 800039e0 <idup>
    80003ff4:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ff6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003ffa:	4cb5                	li	s9,13
  len = path - s;
    80003ffc:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ffe:	4c05                	li	s8,1
    80004000:	a87d                	j	800040be <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004002:	4585                	li	a1,1
    80004004:	4505                	li	a0,1
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	6e2080e7          	jalr	1762(ra) # 800036e8 <iget>
    8000400e:	8a2a                	mv	s4,a0
    80004010:	b7dd                	j	80003ff6 <namex+0x44>
      iunlockput(ip);
    80004012:	8552                	mv	a0,s4
    80004014:	00000097          	auipc	ra,0x0
    80004018:	c6c080e7          	jalr	-916(ra) # 80003c80 <iunlockput>
      return 0;
    8000401c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000401e:	8552                	mv	a0,s4
    80004020:	60e6                	ld	ra,88(sp)
    80004022:	6446                	ld	s0,80(sp)
    80004024:	64a6                	ld	s1,72(sp)
    80004026:	6906                	ld	s2,64(sp)
    80004028:	79e2                	ld	s3,56(sp)
    8000402a:	7a42                	ld	s4,48(sp)
    8000402c:	7aa2                	ld	s5,40(sp)
    8000402e:	7b02                	ld	s6,32(sp)
    80004030:	6be2                	ld	s7,24(sp)
    80004032:	6c42                	ld	s8,16(sp)
    80004034:	6ca2                	ld	s9,8(sp)
    80004036:	6d02                	ld	s10,0(sp)
    80004038:	6125                	addi	sp,sp,96
    8000403a:	8082                	ret
      iunlock(ip);
    8000403c:	8552                	mv	a0,s4
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	aa2080e7          	jalr	-1374(ra) # 80003ae0 <iunlock>
      return ip;
    80004046:	bfe1                	j	8000401e <namex+0x6c>
      iunlockput(ip);
    80004048:	8552                	mv	a0,s4
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	c36080e7          	jalr	-970(ra) # 80003c80 <iunlockput>
      return 0;
    80004052:	8a4e                	mv	s4,s3
    80004054:	b7e9                	j	8000401e <namex+0x6c>
  len = path - s;
    80004056:	40998633          	sub	a2,s3,s1
    8000405a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000405e:	09acd863          	bge	s9,s10,800040ee <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004062:	4639                	li	a2,14
    80004064:	85a6                	mv	a1,s1
    80004066:	8556                	mv	a0,s5
    80004068:	ffffd097          	auipc	ra,0xffffd
    8000406c:	cc0080e7          	jalr	-832(ra) # 80000d28 <memmove>
    80004070:	84ce                	mv	s1,s3
  while(*path == '/')
    80004072:	0004c783          	lbu	a5,0(s1)
    80004076:	01279763          	bne	a5,s2,80004084 <namex+0xd2>
    path++;
    8000407a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000407c:	0004c783          	lbu	a5,0(s1)
    80004080:	ff278de3          	beq	a5,s2,8000407a <namex+0xc8>
    ilock(ip);
    80004084:	8552                	mv	a0,s4
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	998080e7          	jalr	-1640(ra) # 80003a1e <ilock>
    if(ip->type != T_DIR){
    8000408e:	044a1783          	lh	a5,68(s4)
    80004092:	f98790e3          	bne	a5,s8,80004012 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004096:	000b0563          	beqz	s6,800040a0 <namex+0xee>
    8000409a:	0004c783          	lbu	a5,0(s1)
    8000409e:	dfd9                	beqz	a5,8000403c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040a0:	865e                	mv	a2,s7
    800040a2:	85d6                	mv	a1,s5
    800040a4:	8552                	mv	a0,s4
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	e5c080e7          	jalr	-420(ra) # 80003f02 <dirlookup>
    800040ae:	89aa                	mv	s3,a0
    800040b0:	dd41                	beqz	a0,80004048 <namex+0x96>
    iunlockput(ip);
    800040b2:	8552                	mv	a0,s4
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	bcc080e7          	jalr	-1076(ra) # 80003c80 <iunlockput>
    ip = next;
    800040bc:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040be:	0004c783          	lbu	a5,0(s1)
    800040c2:	01279763          	bne	a5,s2,800040d0 <namex+0x11e>
    path++;
    800040c6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040c8:	0004c783          	lbu	a5,0(s1)
    800040cc:	ff278de3          	beq	a5,s2,800040c6 <namex+0x114>
  if(*path == 0)
    800040d0:	cb9d                	beqz	a5,80004106 <namex+0x154>
  while(*path != '/' && *path != 0)
    800040d2:	0004c783          	lbu	a5,0(s1)
    800040d6:	89a6                	mv	s3,s1
  len = path - s;
    800040d8:	8d5e                	mv	s10,s7
    800040da:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040dc:	01278963          	beq	a5,s2,800040ee <namex+0x13c>
    800040e0:	dbbd                	beqz	a5,80004056 <namex+0xa4>
    path++;
    800040e2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040e4:	0009c783          	lbu	a5,0(s3)
    800040e8:	ff279ce3          	bne	a5,s2,800040e0 <namex+0x12e>
    800040ec:	b7ad                	j	80004056 <namex+0xa4>
    memmove(name, s, len);
    800040ee:	2601                	sext.w	a2,a2
    800040f0:	85a6                	mv	a1,s1
    800040f2:	8556                	mv	a0,s5
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	c34080e7          	jalr	-972(ra) # 80000d28 <memmove>
    name[len] = 0;
    800040fc:	9d56                	add	s10,s10,s5
    800040fe:	000d0023          	sb	zero,0(s10)
    80004102:	84ce                	mv	s1,s3
    80004104:	b7bd                	j	80004072 <namex+0xc0>
  if(nameiparent){
    80004106:	f00b0ce3          	beqz	s6,8000401e <namex+0x6c>
    iput(ip);
    8000410a:	8552                	mv	a0,s4
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	acc080e7          	jalr	-1332(ra) # 80003bd8 <iput>
    return 0;
    80004114:	4a01                	li	s4,0
    80004116:	b721                	j	8000401e <namex+0x6c>

0000000080004118 <dirlink>:
{
    80004118:	7139                	addi	sp,sp,-64
    8000411a:	fc06                	sd	ra,56(sp)
    8000411c:	f822                	sd	s0,48(sp)
    8000411e:	f426                	sd	s1,40(sp)
    80004120:	f04a                	sd	s2,32(sp)
    80004122:	ec4e                	sd	s3,24(sp)
    80004124:	e852                	sd	s4,16(sp)
    80004126:	0080                	addi	s0,sp,64
    80004128:	892a                	mv	s2,a0
    8000412a:	8a2e                	mv	s4,a1
    8000412c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000412e:	4601                	li	a2,0
    80004130:	00000097          	auipc	ra,0x0
    80004134:	dd2080e7          	jalr	-558(ra) # 80003f02 <dirlookup>
    80004138:	e93d                	bnez	a0,800041ae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413a:	04c92483          	lw	s1,76(s2)
    8000413e:	c49d                	beqz	s1,8000416c <dirlink+0x54>
    80004140:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004142:	4741                	li	a4,16
    80004144:	86a6                	mv	a3,s1
    80004146:	fc040613          	addi	a2,s0,-64
    8000414a:	4581                	li	a1,0
    8000414c:	854a                	mv	a0,s2
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	b84080e7          	jalr	-1148(ra) # 80003cd2 <readi>
    80004156:	47c1                	li	a5,16
    80004158:	06f51163          	bne	a0,a5,800041ba <dirlink+0xa2>
    if(de.inum == 0)
    8000415c:	fc045783          	lhu	a5,-64(s0)
    80004160:	c791                	beqz	a5,8000416c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004162:	24c1                	addiw	s1,s1,16
    80004164:	04c92783          	lw	a5,76(s2)
    80004168:	fcf4ede3          	bltu	s1,a5,80004142 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000416c:	4639                	li	a2,14
    8000416e:	85d2                	mv	a1,s4
    80004170:	fc240513          	addi	a0,s0,-62
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	c64080e7          	jalr	-924(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    8000417c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004180:	4741                	li	a4,16
    80004182:	86a6                	mv	a3,s1
    80004184:	fc040613          	addi	a2,s0,-64
    80004188:	4581                	li	a1,0
    8000418a:	854a                	mv	a0,s2
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	c3e080e7          	jalr	-962(ra) # 80003dca <writei>
    80004194:	872a                	mv	a4,a0
    80004196:	47c1                	li	a5,16
  return 0;
    80004198:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419a:	02f71863          	bne	a4,a5,800041ca <dirlink+0xb2>
}
    8000419e:	70e2                	ld	ra,56(sp)
    800041a0:	7442                	ld	s0,48(sp)
    800041a2:	74a2                	ld	s1,40(sp)
    800041a4:	7902                	ld	s2,32(sp)
    800041a6:	69e2                	ld	s3,24(sp)
    800041a8:	6a42                	ld	s4,16(sp)
    800041aa:	6121                	addi	sp,sp,64
    800041ac:	8082                	ret
    iput(ip);
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	a2a080e7          	jalr	-1494(ra) # 80003bd8 <iput>
    return -1;
    800041b6:	557d                	li	a0,-1
    800041b8:	b7dd                	j	8000419e <dirlink+0x86>
      panic("dirlink read");
    800041ba:	00004517          	auipc	a0,0x4
    800041be:	47650513          	addi	a0,a0,1142 # 80008630 <syscalls+0x1e8>
    800041c2:	ffffc097          	auipc	ra,0xffffc
    800041c6:	378080e7          	jalr	888(ra) # 8000053a <panic>
    panic("dirlink");
    800041ca:	00004517          	auipc	a0,0x4
    800041ce:	57650513          	addi	a0,a0,1398 # 80008740 <syscalls+0x2f8>
    800041d2:	ffffc097          	auipc	ra,0xffffc
    800041d6:	368080e7          	jalr	872(ra) # 8000053a <panic>

00000000800041da <namei>:

struct inode*
namei(char *path)
{
    800041da:	1101                	addi	sp,sp,-32
    800041dc:	ec06                	sd	ra,24(sp)
    800041de:	e822                	sd	s0,16(sp)
    800041e0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041e2:	fe040613          	addi	a2,s0,-32
    800041e6:	4581                	li	a1,0
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	dca080e7          	jalr	-566(ra) # 80003fb2 <namex>
}
    800041f0:	60e2                	ld	ra,24(sp)
    800041f2:	6442                	ld	s0,16(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041f8:	1141                	addi	sp,sp,-16
    800041fa:	e406                	sd	ra,8(sp)
    800041fc:	e022                	sd	s0,0(sp)
    800041fe:	0800                	addi	s0,sp,16
    80004200:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004202:	4585                	li	a1,1
    80004204:	00000097          	auipc	ra,0x0
    80004208:	dae080e7          	jalr	-594(ra) # 80003fb2 <namex>
}
    8000420c:	60a2                	ld	ra,8(sp)
    8000420e:	6402                	ld	s0,0(sp)
    80004210:	0141                	addi	sp,sp,16
    80004212:	8082                	ret

0000000080004214 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004214:	1101                	addi	sp,sp,-32
    80004216:	ec06                	sd	ra,24(sp)
    80004218:	e822                	sd	s0,16(sp)
    8000421a:	e426                	sd	s1,8(sp)
    8000421c:	e04a                	sd	s2,0(sp)
    8000421e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004220:	0001d917          	auipc	s2,0x1d
    80004224:	25090913          	addi	s2,s2,592 # 80021470 <log>
    80004228:	01892583          	lw	a1,24(s2)
    8000422c:	02892503          	lw	a0,40(s2)
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	fec080e7          	jalr	-20(ra) # 8000321c <bread>
    80004238:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000423a:	02c92683          	lw	a3,44(s2)
    8000423e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004240:	02d05863          	blez	a3,80004270 <write_head+0x5c>
    80004244:	0001d797          	auipc	a5,0x1d
    80004248:	25c78793          	addi	a5,a5,604 # 800214a0 <log+0x30>
    8000424c:	05c50713          	addi	a4,a0,92
    80004250:	36fd                	addiw	a3,a3,-1
    80004252:	02069613          	slli	a2,a3,0x20
    80004256:	01e65693          	srli	a3,a2,0x1e
    8000425a:	0001d617          	auipc	a2,0x1d
    8000425e:	24a60613          	addi	a2,a2,586 # 800214a4 <log+0x34>
    80004262:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004264:	4390                	lw	a2,0(a5)
    80004266:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004268:	0791                	addi	a5,a5,4
    8000426a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000426c:	fed79ce3          	bne	a5,a3,80004264 <write_head+0x50>
  }
  bwrite(buf);
    80004270:	8526                	mv	a0,s1
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	09c080e7          	jalr	156(ra) # 8000330e <bwrite>
  brelse(buf);
    8000427a:	8526                	mv	a0,s1
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	0d0080e7          	jalr	208(ra) # 8000334c <brelse>
}
    80004284:	60e2                	ld	ra,24(sp)
    80004286:	6442                	ld	s0,16(sp)
    80004288:	64a2                	ld	s1,8(sp)
    8000428a:	6902                	ld	s2,0(sp)
    8000428c:	6105                	addi	sp,sp,32
    8000428e:	8082                	ret

0000000080004290 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004290:	0001d797          	auipc	a5,0x1d
    80004294:	20c7a783          	lw	a5,524(a5) # 8002149c <log+0x2c>
    80004298:	0af05d63          	blez	a5,80004352 <install_trans+0xc2>
{
    8000429c:	7139                	addi	sp,sp,-64
    8000429e:	fc06                	sd	ra,56(sp)
    800042a0:	f822                	sd	s0,48(sp)
    800042a2:	f426                	sd	s1,40(sp)
    800042a4:	f04a                	sd	s2,32(sp)
    800042a6:	ec4e                	sd	s3,24(sp)
    800042a8:	e852                	sd	s4,16(sp)
    800042aa:	e456                	sd	s5,8(sp)
    800042ac:	e05a                	sd	s6,0(sp)
    800042ae:	0080                	addi	s0,sp,64
    800042b0:	8b2a                	mv	s6,a0
    800042b2:	0001da97          	auipc	s5,0x1d
    800042b6:	1eea8a93          	addi	s5,s5,494 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042bc:	0001d997          	auipc	s3,0x1d
    800042c0:	1b498993          	addi	s3,s3,436 # 80021470 <log>
    800042c4:	a00d                	j	800042e6 <install_trans+0x56>
    brelse(lbuf);
    800042c6:	854a                	mv	a0,s2
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	084080e7          	jalr	132(ra) # 8000334c <brelse>
    brelse(dbuf);
    800042d0:	8526                	mv	a0,s1
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	07a080e7          	jalr	122(ra) # 8000334c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042da:	2a05                	addiw	s4,s4,1
    800042dc:	0a91                	addi	s5,s5,4
    800042de:	02c9a783          	lw	a5,44(s3)
    800042e2:	04fa5e63          	bge	s4,a5,8000433e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042e6:	0189a583          	lw	a1,24(s3)
    800042ea:	014585bb          	addw	a1,a1,s4
    800042ee:	2585                	addiw	a1,a1,1
    800042f0:	0289a503          	lw	a0,40(s3)
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	f28080e7          	jalr	-216(ra) # 8000321c <bread>
    800042fc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042fe:	000aa583          	lw	a1,0(s5)
    80004302:	0289a503          	lw	a0,40(s3)
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	f16080e7          	jalr	-234(ra) # 8000321c <bread>
    8000430e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004310:	40000613          	li	a2,1024
    80004314:	05890593          	addi	a1,s2,88
    80004318:	05850513          	addi	a0,a0,88
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	a0c080e7          	jalr	-1524(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	fe8080e7          	jalr	-24(ra) # 8000330e <bwrite>
    if(recovering == 0)
    8000432e:	f80b1ce3          	bnez	s6,800042c6 <install_trans+0x36>
      bunpin(dbuf);
    80004332:	8526                	mv	a0,s1
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	0f2080e7          	jalr	242(ra) # 80003426 <bunpin>
    8000433c:	b769                	j	800042c6 <install_trans+0x36>
}
    8000433e:	70e2                	ld	ra,56(sp)
    80004340:	7442                	ld	s0,48(sp)
    80004342:	74a2                	ld	s1,40(sp)
    80004344:	7902                	ld	s2,32(sp)
    80004346:	69e2                	ld	s3,24(sp)
    80004348:	6a42                	ld	s4,16(sp)
    8000434a:	6aa2                	ld	s5,8(sp)
    8000434c:	6b02                	ld	s6,0(sp)
    8000434e:	6121                	addi	sp,sp,64
    80004350:	8082                	ret
    80004352:	8082                	ret

0000000080004354 <initlog>:
{
    80004354:	7179                	addi	sp,sp,-48
    80004356:	f406                	sd	ra,40(sp)
    80004358:	f022                	sd	s0,32(sp)
    8000435a:	ec26                	sd	s1,24(sp)
    8000435c:	e84a                	sd	s2,16(sp)
    8000435e:	e44e                	sd	s3,8(sp)
    80004360:	1800                	addi	s0,sp,48
    80004362:	892a                	mv	s2,a0
    80004364:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004366:	0001d497          	auipc	s1,0x1d
    8000436a:	10a48493          	addi	s1,s1,266 # 80021470 <log>
    8000436e:	00004597          	auipc	a1,0x4
    80004372:	2d258593          	addi	a1,a1,722 # 80008640 <syscalls+0x1f8>
    80004376:	8526                	mv	a0,s1
    80004378:	ffffc097          	auipc	ra,0xffffc
    8000437c:	7c8080e7          	jalr	1992(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004380:	0149a583          	lw	a1,20(s3)
    80004384:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004386:	0109a783          	lw	a5,16(s3)
    8000438a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000438c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004390:	854a                	mv	a0,s2
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	e8a080e7          	jalr	-374(ra) # 8000321c <bread>
  log.lh.n = lh->n;
    8000439a:	4d34                	lw	a3,88(a0)
    8000439c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	02d05663          	blez	a3,800043ca <initlog+0x76>
    800043a2:	05c50793          	addi	a5,a0,92
    800043a6:	0001d717          	auipc	a4,0x1d
    800043aa:	0fa70713          	addi	a4,a4,250 # 800214a0 <log+0x30>
    800043ae:	36fd                	addiw	a3,a3,-1
    800043b0:	02069613          	slli	a2,a3,0x20
    800043b4:	01e65693          	srli	a3,a2,0x1e
    800043b8:	06050613          	addi	a2,a0,96
    800043bc:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043be:	4390                	lw	a2,0(a5)
    800043c0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043c2:	0791                	addi	a5,a5,4
    800043c4:	0711                	addi	a4,a4,4
    800043c6:	fed79ce3          	bne	a5,a3,800043be <initlog+0x6a>
  brelse(buf);
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	f82080e7          	jalr	-126(ra) # 8000334c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043d2:	4505                	li	a0,1
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	ebc080e7          	jalr	-324(ra) # 80004290 <install_trans>
  log.lh.n = 0;
    800043dc:	0001d797          	auipc	a5,0x1d
    800043e0:	0c07a023          	sw	zero,192(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	e30080e7          	jalr	-464(ra) # 80004214 <write_head>
}
    800043ec:	70a2                	ld	ra,40(sp)
    800043ee:	7402                	ld	s0,32(sp)
    800043f0:	64e2                	ld	s1,24(sp)
    800043f2:	6942                	ld	s2,16(sp)
    800043f4:	69a2                	ld	s3,8(sp)
    800043f6:	6145                	addi	sp,sp,48
    800043f8:	8082                	ret

00000000800043fa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043fa:	1101                	addi	sp,sp,-32
    800043fc:	ec06                	sd	ra,24(sp)
    800043fe:	e822                	sd	s0,16(sp)
    80004400:	e426                	sd	s1,8(sp)
    80004402:	e04a                	sd	s2,0(sp)
    80004404:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004406:	0001d517          	auipc	a0,0x1d
    8000440a:	06a50513          	addi	a0,a0,106 # 80021470 <log>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	7c2080e7          	jalr	1986(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004416:	0001d497          	auipc	s1,0x1d
    8000441a:	05a48493          	addi	s1,s1,90 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000441e:	4979                	li	s2,30
    80004420:	a039                	j	8000442e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004422:	85a6                	mv	a1,s1
    80004424:	8526                	mv	a0,s1
    80004426:	ffffe097          	auipc	ra,0xffffe
    8000442a:	cba080e7          	jalr	-838(ra) # 800020e0 <sleep>
    if(log.committing){
    8000442e:	50dc                	lw	a5,36(s1)
    80004430:	fbed                	bnez	a5,80004422 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004432:	5098                	lw	a4,32(s1)
    80004434:	2705                	addiw	a4,a4,1
    80004436:	0007069b          	sext.w	a3,a4
    8000443a:	0027179b          	slliw	a5,a4,0x2
    8000443e:	9fb9                	addw	a5,a5,a4
    80004440:	0017979b          	slliw	a5,a5,0x1
    80004444:	54d8                	lw	a4,44(s1)
    80004446:	9fb9                	addw	a5,a5,a4
    80004448:	00f95963          	bge	s2,a5,8000445a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000444c:	85a6                	mv	a1,s1
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffe097          	auipc	ra,0xffffe
    80004454:	c90080e7          	jalr	-880(ra) # 800020e0 <sleep>
    80004458:	bfd9                	j	8000442e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000445a:	0001d517          	auipc	a0,0x1d
    8000445e:	01650513          	addi	a0,a0,22 # 80021470 <log>
    80004462:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	820080e7          	jalr	-2016(ra) # 80000c84 <release>
      break;
    }
  }
}
    8000446c:	60e2                	ld	ra,24(sp)
    8000446e:	6442                	ld	s0,16(sp)
    80004470:	64a2                	ld	s1,8(sp)
    80004472:	6902                	ld	s2,0(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret

0000000080004478 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004478:	7139                	addi	sp,sp,-64
    8000447a:	fc06                	sd	ra,56(sp)
    8000447c:	f822                	sd	s0,48(sp)
    8000447e:	f426                	sd	s1,40(sp)
    80004480:	f04a                	sd	s2,32(sp)
    80004482:	ec4e                	sd	s3,24(sp)
    80004484:	e852                	sd	s4,16(sp)
    80004486:	e456                	sd	s5,8(sp)
    80004488:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000448a:	0001d497          	auipc	s1,0x1d
    8000448e:	fe648493          	addi	s1,s1,-26 # 80021470 <log>
    80004492:	8526                	mv	a0,s1
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	73c080e7          	jalr	1852(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    8000449c:	509c                	lw	a5,32(s1)
    8000449e:	37fd                	addiw	a5,a5,-1
    800044a0:	0007891b          	sext.w	s2,a5
    800044a4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044a6:	50dc                	lw	a5,36(s1)
    800044a8:	e7b9                	bnez	a5,800044f6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044aa:	04091e63          	bnez	s2,80004506 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044ae:	0001d497          	auipc	s1,0x1d
    800044b2:	fc248493          	addi	s1,s1,-62 # 80021470 <log>
    800044b6:	4785                	li	a5,1
    800044b8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044ba:	8526                	mv	a0,s1
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7c8080e7          	jalr	1992(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044c4:	54dc                	lw	a5,44(s1)
    800044c6:	06f04763          	bgtz	a5,80004534 <end_op+0xbc>
    acquire(&log.lock);
    800044ca:	0001d497          	auipc	s1,0x1d
    800044ce:	fa648493          	addi	s1,s1,-90 # 80021470 <log>
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	6fc080e7          	jalr	1788(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800044dc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffe097          	auipc	ra,0xffffe
    800044e6:	ef8080e7          	jalr	-264(ra) # 800023da <wakeup>
    release(&log.lock);
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	798080e7          	jalr	1944(ra) # 80000c84 <release>
}
    800044f4:	a03d                	j	80004522 <end_op+0xaa>
    panic("log.committing");
    800044f6:	00004517          	auipc	a0,0x4
    800044fa:	15250513          	addi	a0,a0,338 # 80008648 <syscalls+0x200>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	03c080e7          	jalr	60(ra) # 8000053a <panic>
    wakeup(&log);
    80004506:	0001d497          	auipc	s1,0x1d
    8000450a:	f6a48493          	addi	s1,s1,-150 # 80021470 <log>
    8000450e:	8526                	mv	a0,s1
    80004510:	ffffe097          	auipc	ra,0xffffe
    80004514:	eca080e7          	jalr	-310(ra) # 800023da <wakeup>
  release(&log.lock);
    80004518:	8526                	mv	a0,s1
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	76a080e7          	jalr	1898(ra) # 80000c84 <release>
}
    80004522:	70e2                	ld	ra,56(sp)
    80004524:	7442                	ld	s0,48(sp)
    80004526:	74a2                	ld	s1,40(sp)
    80004528:	7902                	ld	s2,32(sp)
    8000452a:	69e2                	ld	s3,24(sp)
    8000452c:	6a42                	ld	s4,16(sp)
    8000452e:	6aa2                	ld	s5,8(sp)
    80004530:	6121                	addi	sp,sp,64
    80004532:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004534:	0001da97          	auipc	s5,0x1d
    80004538:	f6ca8a93          	addi	s5,s5,-148 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000453c:	0001da17          	auipc	s4,0x1d
    80004540:	f34a0a13          	addi	s4,s4,-204 # 80021470 <log>
    80004544:	018a2583          	lw	a1,24(s4)
    80004548:	012585bb          	addw	a1,a1,s2
    8000454c:	2585                	addiw	a1,a1,1
    8000454e:	028a2503          	lw	a0,40(s4)
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	cca080e7          	jalr	-822(ra) # 8000321c <bread>
    8000455a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000455c:	000aa583          	lw	a1,0(s5)
    80004560:	028a2503          	lw	a0,40(s4)
    80004564:	fffff097          	auipc	ra,0xfffff
    80004568:	cb8080e7          	jalr	-840(ra) # 8000321c <bread>
    8000456c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000456e:	40000613          	li	a2,1024
    80004572:	05850593          	addi	a1,a0,88
    80004576:	05848513          	addi	a0,s1,88
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	7ae080e7          	jalr	1966(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    80004582:	8526                	mv	a0,s1
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	d8a080e7          	jalr	-630(ra) # 8000330e <bwrite>
    brelse(from);
    8000458c:	854e                	mv	a0,s3
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	dbe080e7          	jalr	-578(ra) # 8000334c <brelse>
    brelse(to);
    80004596:	8526                	mv	a0,s1
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	db4080e7          	jalr	-588(ra) # 8000334c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a0:	2905                	addiw	s2,s2,1
    800045a2:	0a91                	addi	s5,s5,4
    800045a4:	02ca2783          	lw	a5,44(s4)
    800045a8:	f8f94ee3          	blt	s2,a5,80004544 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	c68080e7          	jalr	-920(ra) # 80004214 <write_head>
    install_trans(0); // Now install writes to home locations
    800045b4:	4501                	li	a0,0
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	cda080e7          	jalr	-806(ra) # 80004290 <install_trans>
    log.lh.n = 0;
    800045be:	0001d797          	auipc	a5,0x1d
    800045c2:	ec07af23          	sw	zero,-290(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	c4e080e7          	jalr	-946(ra) # 80004214 <write_head>
    800045ce:	bdf5                	j	800044ca <end_op+0x52>

00000000800045d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045d0:	1101                	addi	sp,sp,-32
    800045d2:	ec06                	sd	ra,24(sp)
    800045d4:	e822                	sd	s0,16(sp)
    800045d6:	e426                	sd	s1,8(sp)
    800045d8:	e04a                	sd	s2,0(sp)
    800045da:	1000                	addi	s0,sp,32
    800045dc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045de:	0001d917          	auipc	s2,0x1d
    800045e2:	e9290913          	addi	s2,s2,-366 # 80021470 <log>
    800045e6:	854a                	mv	a0,s2
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	5e8080e7          	jalr	1512(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045f0:	02c92603          	lw	a2,44(s2)
    800045f4:	47f5                	li	a5,29
    800045f6:	06c7c563          	blt	a5,a2,80004660 <log_write+0x90>
    800045fa:	0001d797          	auipc	a5,0x1d
    800045fe:	e927a783          	lw	a5,-366(a5) # 8002148c <log+0x1c>
    80004602:	37fd                	addiw	a5,a5,-1
    80004604:	04f65e63          	bge	a2,a5,80004660 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004608:	0001d797          	auipc	a5,0x1d
    8000460c:	e887a783          	lw	a5,-376(a5) # 80021490 <log+0x20>
    80004610:	06f05063          	blez	a5,80004670 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004614:	4781                	li	a5,0
    80004616:	06c05563          	blez	a2,80004680 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000461a:	44cc                	lw	a1,12(s1)
    8000461c:	0001d717          	auipc	a4,0x1d
    80004620:	e8470713          	addi	a4,a4,-380 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004624:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004626:	4314                	lw	a3,0(a4)
    80004628:	04b68c63          	beq	a3,a1,80004680 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000462c:	2785                	addiw	a5,a5,1
    8000462e:	0711                	addi	a4,a4,4
    80004630:	fef61be3          	bne	a2,a5,80004626 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004634:	0621                	addi	a2,a2,8
    80004636:	060a                	slli	a2,a2,0x2
    80004638:	0001d797          	auipc	a5,0x1d
    8000463c:	e3878793          	addi	a5,a5,-456 # 80021470 <log>
    80004640:	97b2                	add	a5,a5,a2
    80004642:	44d8                	lw	a4,12(s1)
    80004644:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004646:	8526                	mv	a0,s1
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	da2080e7          	jalr	-606(ra) # 800033ea <bpin>
    log.lh.n++;
    80004650:	0001d717          	auipc	a4,0x1d
    80004654:	e2070713          	addi	a4,a4,-480 # 80021470 <log>
    80004658:	575c                	lw	a5,44(a4)
    8000465a:	2785                	addiw	a5,a5,1
    8000465c:	d75c                	sw	a5,44(a4)
    8000465e:	a82d                	j	80004698 <log_write+0xc8>
    panic("too big a transaction");
    80004660:	00004517          	auipc	a0,0x4
    80004664:	ff850513          	addi	a0,a0,-8 # 80008658 <syscalls+0x210>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	ed2080e7          	jalr	-302(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004670:	00004517          	auipc	a0,0x4
    80004674:	00050513          	mv	a0,a0
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	ec2080e7          	jalr	-318(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004680:	00878693          	addi	a3,a5,8
    80004684:	068a                	slli	a3,a3,0x2
    80004686:	0001d717          	auipc	a4,0x1d
    8000468a:	dea70713          	addi	a4,a4,-534 # 80021470 <log>
    8000468e:	9736                	add	a4,a4,a3
    80004690:	44d4                	lw	a3,12(s1)
    80004692:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004694:	faf609e3          	beq	a2,a5,80004646 <log_write+0x76>
  }
  release(&log.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	dd850513          	addi	a0,a0,-552 # 80021470 <log>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5e4080e7          	jalr	1508(ra) # 80000c84 <release>
}
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6902                	ld	s2,0(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret

00000000800046b4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046b4:	1101                	addi	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	e04a                	sd	s2,0(sp)
    800046be:	1000                	addi	s0,sp,32
    800046c0:	84aa                	mv	s1,a0
    800046c2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046c4:	00004597          	auipc	a1,0x4
    800046c8:	fcc58593          	addi	a1,a1,-52 # 80008690 <syscalls+0x248>
    800046cc:	0521                	addi	a0,a0,8
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	472080e7          	jalr	1138(ra) # 80000b40 <initlock>
  lk->name = name;
    800046d6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046de:	0204a423          	sw	zero,40(s1)
}
    800046e2:	60e2                	ld	ra,24(sp)
    800046e4:	6442                	ld	s0,16(sp)
    800046e6:	64a2                	ld	s1,8(sp)
    800046e8:	6902                	ld	s2,0(sp)
    800046ea:	6105                	addi	sp,sp,32
    800046ec:	8082                	ret

00000000800046ee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046ee:	1101                	addi	sp,sp,-32
    800046f0:	ec06                	sd	ra,24(sp)
    800046f2:	e822                	sd	s0,16(sp)
    800046f4:	e426                	sd	s1,8(sp)
    800046f6:	e04a                	sd	s2,0(sp)
    800046f8:	1000                	addi	s0,sp,32
    800046fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046fc:	00850913          	addi	s2,a0,8
    80004700:	854a                	mv	a0,s2
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4ce080e7          	jalr	1230(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000470a:	409c                	lw	a5,0(s1)
    8000470c:	cb89                	beqz	a5,8000471e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000470e:	85ca                	mv	a1,s2
    80004710:	8526                	mv	a0,s1
    80004712:	ffffe097          	auipc	ra,0xffffe
    80004716:	9ce080e7          	jalr	-1586(ra) # 800020e0 <sleep>
  while (lk->locked) {
    8000471a:	409c                	lw	a5,0(s1)
    8000471c:	fbed                	bnez	a5,8000470e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000471e:	4785                	li	a5,1
    80004720:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004722:	ffffd097          	auipc	ra,0xffffd
    80004726:	274080e7          	jalr	628(ra) # 80001996 <myproc>
    8000472a:	591c                	lw	a5,48(a0)
    8000472c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000472e:	854a                	mv	a0,s2
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	554080e7          	jalr	1364(ra) # 80000c84 <release>
}
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6902                	ld	s2,0(sp)
    80004740:	6105                	addi	sp,sp,32
    80004742:	8082                	ret

0000000080004744 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004744:	1101                	addi	sp,sp,-32
    80004746:	ec06                	sd	ra,24(sp)
    80004748:	e822                	sd	s0,16(sp)
    8000474a:	e426                	sd	s1,8(sp)
    8000474c:	e04a                	sd	s2,0(sp)
    8000474e:	1000                	addi	s0,sp,32
    80004750:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004752:	00850913          	addi	s2,a0,8
    80004756:	854a                	mv	a0,s2
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	478080e7          	jalr	1144(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004760:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004764:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004768:	8526                	mv	a0,s1
    8000476a:	ffffe097          	auipc	ra,0xffffe
    8000476e:	c70080e7          	jalr	-912(ra) # 800023da <wakeup>
  release(&lk->lk);
    80004772:	854a                	mv	a0,s2
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	510080e7          	jalr	1296(ra) # 80000c84 <release>
}
    8000477c:	60e2                	ld	ra,24(sp)
    8000477e:	6442                	ld	s0,16(sp)
    80004780:	64a2                	ld	s1,8(sp)
    80004782:	6902                	ld	s2,0(sp)
    80004784:	6105                	addi	sp,sp,32
    80004786:	8082                	ret

0000000080004788 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004788:	7179                	addi	sp,sp,-48
    8000478a:	f406                	sd	ra,40(sp)
    8000478c:	f022                	sd	s0,32(sp)
    8000478e:	ec26                	sd	s1,24(sp)
    80004790:	e84a                	sd	s2,16(sp)
    80004792:	e44e                	sd	s3,8(sp)
    80004794:	1800                	addi	s0,sp,48
    80004796:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004798:	00850913          	addi	s2,a0,8
    8000479c:	854a                	mv	a0,s2
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	432080e7          	jalr	1074(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a6:	409c                	lw	a5,0(s1)
    800047a8:	ef99                	bnez	a5,800047c6 <holdingsleep+0x3e>
    800047aa:	4481                	li	s1,0
  release(&lk->lk);
    800047ac:	854a                	mv	a0,s2
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	4d6080e7          	jalr	1238(ra) # 80000c84 <release>
  return r;
}
    800047b6:	8526                	mv	a0,s1
    800047b8:	70a2                	ld	ra,40(sp)
    800047ba:	7402                	ld	s0,32(sp)
    800047bc:	64e2                	ld	s1,24(sp)
    800047be:	6942                	ld	s2,16(sp)
    800047c0:	69a2                	ld	s3,8(sp)
    800047c2:	6145                	addi	sp,sp,48
    800047c4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047c6:	0284a983          	lw	s3,40(s1)
    800047ca:	ffffd097          	auipc	ra,0xffffd
    800047ce:	1cc080e7          	jalr	460(ra) # 80001996 <myproc>
    800047d2:	5904                	lw	s1,48(a0)
    800047d4:	413484b3          	sub	s1,s1,s3
    800047d8:	0014b493          	seqz	s1,s1
    800047dc:	bfc1                	j	800047ac <holdingsleep+0x24>

00000000800047de <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047de:	1141                	addi	sp,sp,-16
    800047e0:	e406                	sd	ra,8(sp)
    800047e2:	e022                	sd	s0,0(sp)
    800047e4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047e6:	00004597          	auipc	a1,0x4
    800047ea:	eba58593          	addi	a1,a1,-326 # 800086a0 <syscalls+0x258>
    800047ee:	0001d517          	auipc	a0,0x1d
    800047f2:	dca50513          	addi	a0,a0,-566 # 800215b8 <ftable>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	34a080e7          	jalr	842(ra) # 80000b40 <initlock>
}
    800047fe:	60a2                	ld	ra,8(sp)
    80004800:	6402                	ld	s0,0(sp)
    80004802:	0141                	addi	sp,sp,16
    80004804:	8082                	ret

0000000080004806 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004806:	1101                	addi	sp,sp,-32
    80004808:	ec06                	sd	ra,24(sp)
    8000480a:	e822                	sd	s0,16(sp)
    8000480c:	e426                	sd	s1,8(sp)
    8000480e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004810:	0001d517          	auipc	a0,0x1d
    80004814:	da850513          	addi	a0,a0,-600 # 800215b8 <ftable>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	3b8080e7          	jalr	952(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004820:	0001d497          	auipc	s1,0x1d
    80004824:	db048493          	addi	s1,s1,-592 # 800215d0 <ftable+0x18>
    80004828:	0001e717          	auipc	a4,0x1e
    8000482c:	d4870713          	addi	a4,a4,-696 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004830:	40dc                	lw	a5,4(s1)
    80004832:	cf99                	beqz	a5,80004850 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004834:	02848493          	addi	s1,s1,40
    80004838:	fee49ce3          	bne	s1,a4,80004830 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000483c:	0001d517          	auipc	a0,0x1d
    80004840:	d7c50513          	addi	a0,a0,-644 # 800215b8 <ftable>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	440080e7          	jalr	1088(ra) # 80000c84 <release>
  return 0;
    8000484c:	4481                	li	s1,0
    8000484e:	a819                	j	80004864 <filealloc+0x5e>
      f->ref = 1;
    80004850:	4785                	li	a5,1
    80004852:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004854:	0001d517          	auipc	a0,0x1d
    80004858:	d6450513          	addi	a0,a0,-668 # 800215b8 <ftable>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	428080e7          	jalr	1064(ra) # 80000c84 <release>
}
    80004864:	8526                	mv	a0,s1
    80004866:	60e2                	ld	ra,24(sp)
    80004868:	6442                	ld	s0,16(sp)
    8000486a:	64a2                	ld	s1,8(sp)
    8000486c:	6105                	addi	sp,sp,32
    8000486e:	8082                	ret

0000000080004870 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004870:	1101                	addi	sp,sp,-32
    80004872:	ec06                	sd	ra,24(sp)
    80004874:	e822                	sd	s0,16(sp)
    80004876:	e426                	sd	s1,8(sp)
    80004878:	1000                	addi	s0,sp,32
    8000487a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000487c:	0001d517          	auipc	a0,0x1d
    80004880:	d3c50513          	addi	a0,a0,-708 # 800215b8 <ftable>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	34c080e7          	jalr	844(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000488c:	40dc                	lw	a5,4(s1)
    8000488e:	02f05263          	blez	a5,800048b2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004892:	2785                	addiw	a5,a5,1
    80004894:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004896:	0001d517          	auipc	a0,0x1d
    8000489a:	d2250513          	addi	a0,a0,-734 # 800215b8 <ftable>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	3e6080e7          	jalr	998(ra) # 80000c84 <release>
  return f;
}
    800048a6:	8526                	mv	a0,s1
    800048a8:	60e2                	ld	ra,24(sp)
    800048aa:	6442                	ld	s0,16(sp)
    800048ac:	64a2                	ld	s1,8(sp)
    800048ae:	6105                	addi	sp,sp,32
    800048b0:	8082                	ret
    panic("filedup");
    800048b2:	00004517          	auipc	a0,0x4
    800048b6:	df650513          	addi	a0,a0,-522 # 800086a8 <syscalls+0x260>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	c80080e7          	jalr	-896(ra) # 8000053a <panic>

00000000800048c2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048c2:	7139                	addi	sp,sp,-64
    800048c4:	fc06                	sd	ra,56(sp)
    800048c6:	f822                	sd	s0,48(sp)
    800048c8:	f426                	sd	s1,40(sp)
    800048ca:	f04a                	sd	s2,32(sp)
    800048cc:	ec4e                	sd	s3,24(sp)
    800048ce:	e852                	sd	s4,16(sp)
    800048d0:	e456                	sd	s5,8(sp)
    800048d2:	0080                	addi	s0,sp,64
    800048d4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048d6:	0001d517          	auipc	a0,0x1d
    800048da:	ce250513          	addi	a0,a0,-798 # 800215b8 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	2f2080e7          	jalr	754(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800048e6:	40dc                	lw	a5,4(s1)
    800048e8:	06f05163          	blez	a5,8000494a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048ec:	37fd                	addiw	a5,a5,-1
    800048ee:	0007871b          	sext.w	a4,a5
    800048f2:	c0dc                	sw	a5,4(s1)
    800048f4:	06e04363          	bgtz	a4,8000495a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048f8:	0004a903          	lw	s2,0(s1)
    800048fc:	0094ca83          	lbu	s5,9(s1)
    80004900:	0104ba03          	ld	s4,16(s1)
    80004904:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004908:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000490c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004910:	0001d517          	auipc	a0,0x1d
    80004914:	ca850513          	addi	a0,a0,-856 # 800215b8 <ftable>
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	36c080e7          	jalr	876(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004920:	4785                	li	a5,1
    80004922:	04f90d63          	beq	s2,a5,8000497c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004926:	3979                	addiw	s2,s2,-2
    80004928:	4785                	li	a5,1
    8000492a:	0527e063          	bltu	a5,s2,8000496a <fileclose+0xa8>
    begin_op();
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	acc080e7          	jalr	-1332(ra) # 800043fa <begin_op>
    iput(ff.ip);
    80004936:	854e                	mv	a0,s3
    80004938:	fffff097          	auipc	ra,0xfffff
    8000493c:	2a0080e7          	jalr	672(ra) # 80003bd8 <iput>
    end_op();
    80004940:	00000097          	auipc	ra,0x0
    80004944:	b38080e7          	jalr	-1224(ra) # 80004478 <end_op>
    80004948:	a00d                	j	8000496a <fileclose+0xa8>
    panic("fileclose");
    8000494a:	00004517          	auipc	a0,0x4
    8000494e:	d6650513          	addi	a0,a0,-666 # 800086b0 <syscalls+0x268>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	be8080e7          	jalr	-1048(ra) # 8000053a <panic>
    release(&ftable.lock);
    8000495a:	0001d517          	auipc	a0,0x1d
    8000495e:	c5e50513          	addi	a0,a0,-930 # 800215b8 <ftable>
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	322080e7          	jalr	802(ra) # 80000c84 <release>
  }
}
    8000496a:	70e2                	ld	ra,56(sp)
    8000496c:	7442                	ld	s0,48(sp)
    8000496e:	74a2                	ld	s1,40(sp)
    80004970:	7902                	ld	s2,32(sp)
    80004972:	69e2                	ld	s3,24(sp)
    80004974:	6a42                	ld	s4,16(sp)
    80004976:	6aa2                	ld	s5,8(sp)
    80004978:	6121                	addi	sp,sp,64
    8000497a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000497c:	85d6                	mv	a1,s5
    8000497e:	8552                	mv	a0,s4
    80004980:	00000097          	auipc	ra,0x0
    80004984:	34c080e7          	jalr	844(ra) # 80004ccc <pipeclose>
    80004988:	b7cd                	j	8000496a <fileclose+0xa8>

000000008000498a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000498a:	715d                	addi	sp,sp,-80
    8000498c:	e486                	sd	ra,72(sp)
    8000498e:	e0a2                	sd	s0,64(sp)
    80004990:	fc26                	sd	s1,56(sp)
    80004992:	f84a                	sd	s2,48(sp)
    80004994:	f44e                	sd	s3,40(sp)
    80004996:	0880                	addi	s0,sp,80
    80004998:	84aa                	mv	s1,a0
    8000499a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000499c:	ffffd097          	auipc	ra,0xffffd
    800049a0:	ffa080e7          	jalr	-6(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049a4:	409c                	lw	a5,0(s1)
    800049a6:	37f9                	addiw	a5,a5,-2
    800049a8:	4705                	li	a4,1
    800049aa:	04f76763          	bltu	a4,a5,800049f8 <filestat+0x6e>
    800049ae:	892a                	mv	s2,a0
    ilock(f->ip);
    800049b0:	6c88                	ld	a0,24(s1)
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	06c080e7          	jalr	108(ra) # 80003a1e <ilock>
    stati(f->ip, &st);
    800049ba:	fb840593          	addi	a1,s0,-72
    800049be:	6c88                	ld	a0,24(s1)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	2e8080e7          	jalr	744(ra) # 80003ca8 <stati>
    iunlock(f->ip);
    800049c8:	6c88                	ld	a0,24(s1)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	116080e7          	jalr	278(ra) # 80003ae0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049d2:	46e1                	li	a3,24
    800049d4:	fb840613          	addi	a2,s0,-72
    800049d8:	85ce                	mv	a1,s3
    800049da:	05893503          	ld	a0,88(s2)
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	c7c080e7          	jalr	-900(ra) # 8000165a <copyout>
    800049e6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049ea:	60a6                	ld	ra,72(sp)
    800049ec:	6406                	ld	s0,64(sp)
    800049ee:	74e2                	ld	s1,56(sp)
    800049f0:	7942                	ld	s2,48(sp)
    800049f2:	79a2                	ld	s3,40(sp)
    800049f4:	6161                	addi	sp,sp,80
    800049f6:	8082                	ret
  return -1;
    800049f8:	557d                	li	a0,-1
    800049fa:	bfc5                	j	800049ea <filestat+0x60>

00000000800049fc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049fc:	7179                	addi	sp,sp,-48
    800049fe:	f406                	sd	ra,40(sp)
    80004a00:	f022                	sd	s0,32(sp)
    80004a02:	ec26                	sd	s1,24(sp)
    80004a04:	e84a                	sd	s2,16(sp)
    80004a06:	e44e                	sd	s3,8(sp)
    80004a08:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a0a:	00854783          	lbu	a5,8(a0)
    80004a0e:	c3d5                	beqz	a5,80004ab2 <fileread+0xb6>
    80004a10:	84aa                	mv	s1,a0
    80004a12:	89ae                	mv	s3,a1
    80004a14:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a16:	411c                	lw	a5,0(a0)
    80004a18:	4705                	li	a4,1
    80004a1a:	04e78963          	beq	a5,a4,80004a6c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a1e:	470d                	li	a4,3
    80004a20:	04e78d63          	beq	a5,a4,80004a7a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a24:	4709                	li	a4,2
    80004a26:	06e79e63          	bne	a5,a4,80004aa2 <fileread+0xa6>
    ilock(f->ip);
    80004a2a:	6d08                	ld	a0,24(a0)
    80004a2c:	fffff097          	auipc	ra,0xfffff
    80004a30:	ff2080e7          	jalr	-14(ra) # 80003a1e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a34:	874a                	mv	a4,s2
    80004a36:	5094                	lw	a3,32(s1)
    80004a38:	864e                	mv	a2,s3
    80004a3a:	4585                	li	a1,1
    80004a3c:	6c88                	ld	a0,24(s1)
    80004a3e:	fffff097          	auipc	ra,0xfffff
    80004a42:	294080e7          	jalr	660(ra) # 80003cd2 <readi>
    80004a46:	892a                	mv	s2,a0
    80004a48:	00a05563          	blez	a0,80004a52 <fileread+0x56>
      f->off += r;
    80004a4c:	509c                	lw	a5,32(s1)
    80004a4e:	9fa9                	addw	a5,a5,a0
    80004a50:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a52:	6c88                	ld	a0,24(s1)
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	08c080e7          	jalr	140(ra) # 80003ae0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a5c:	854a                	mv	a0,s2
    80004a5e:	70a2                	ld	ra,40(sp)
    80004a60:	7402                	ld	s0,32(sp)
    80004a62:	64e2                	ld	s1,24(sp)
    80004a64:	6942                	ld	s2,16(sp)
    80004a66:	69a2                	ld	s3,8(sp)
    80004a68:	6145                	addi	sp,sp,48
    80004a6a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a6c:	6908                	ld	a0,16(a0)
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	3c0080e7          	jalr	960(ra) # 80004e2e <piperead>
    80004a76:	892a                	mv	s2,a0
    80004a78:	b7d5                	j	80004a5c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a7a:	02451783          	lh	a5,36(a0)
    80004a7e:	03079693          	slli	a3,a5,0x30
    80004a82:	92c1                	srli	a3,a3,0x30
    80004a84:	4725                	li	a4,9
    80004a86:	02d76863          	bltu	a4,a3,80004ab6 <fileread+0xba>
    80004a8a:	0792                	slli	a5,a5,0x4
    80004a8c:	0001d717          	auipc	a4,0x1d
    80004a90:	a8c70713          	addi	a4,a4,-1396 # 80021518 <devsw>
    80004a94:	97ba                	add	a5,a5,a4
    80004a96:	639c                	ld	a5,0(a5)
    80004a98:	c38d                	beqz	a5,80004aba <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a9a:	4505                	li	a0,1
    80004a9c:	9782                	jalr	a5
    80004a9e:	892a                	mv	s2,a0
    80004aa0:	bf75                	j	80004a5c <fileread+0x60>
    panic("fileread");
    80004aa2:	00004517          	auipc	a0,0x4
    80004aa6:	c1e50513          	addi	a0,a0,-994 # 800086c0 <syscalls+0x278>
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	a90080e7          	jalr	-1392(ra) # 8000053a <panic>
    return -1;
    80004ab2:	597d                	li	s2,-1
    80004ab4:	b765                	j	80004a5c <fileread+0x60>
      return -1;
    80004ab6:	597d                	li	s2,-1
    80004ab8:	b755                	j	80004a5c <fileread+0x60>
    80004aba:	597d                	li	s2,-1
    80004abc:	b745                	j	80004a5c <fileread+0x60>

0000000080004abe <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004abe:	715d                	addi	sp,sp,-80
    80004ac0:	e486                	sd	ra,72(sp)
    80004ac2:	e0a2                	sd	s0,64(sp)
    80004ac4:	fc26                	sd	s1,56(sp)
    80004ac6:	f84a                	sd	s2,48(sp)
    80004ac8:	f44e                	sd	s3,40(sp)
    80004aca:	f052                	sd	s4,32(sp)
    80004acc:	ec56                	sd	s5,24(sp)
    80004ace:	e85a                	sd	s6,16(sp)
    80004ad0:	e45e                	sd	s7,8(sp)
    80004ad2:	e062                	sd	s8,0(sp)
    80004ad4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ad6:	00954783          	lbu	a5,9(a0)
    80004ada:	10078663          	beqz	a5,80004be6 <filewrite+0x128>
    80004ade:	892a                	mv	s2,a0
    80004ae0:	8b2e                	mv	s6,a1
    80004ae2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae4:	411c                	lw	a5,0(a0)
    80004ae6:	4705                	li	a4,1
    80004ae8:	02e78263          	beq	a5,a4,80004b0c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aec:	470d                	li	a4,3
    80004aee:	02e78663          	beq	a5,a4,80004b1a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004af2:	4709                	li	a4,2
    80004af4:	0ee79163          	bne	a5,a4,80004bd6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004af8:	0ac05d63          	blez	a2,80004bb2 <filewrite+0xf4>
    int i = 0;
    80004afc:	4981                	li	s3,0
    80004afe:	6b85                	lui	s7,0x1
    80004b00:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b04:	6c05                	lui	s8,0x1
    80004b06:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b0a:	a861                	j	80004ba2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b0c:	6908                	ld	a0,16(a0)
    80004b0e:	00000097          	auipc	ra,0x0
    80004b12:	22e080e7          	jalr	558(ra) # 80004d3c <pipewrite>
    80004b16:	8a2a                	mv	s4,a0
    80004b18:	a045                	j	80004bb8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b1a:	02451783          	lh	a5,36(a0)
    80004b1e:	03079693          	slli	a3,a5,0x30
    80004b22:	92c1                	srli	a3,a3,0x30
    80004b24:	4725                	li	a4,9
    80004b26:	0cd76263          	bltu	a4,a3,80004bea <filewrite+0x12c>
    80004b2a:	0792                	slli	a5,a5,0x4
    80004b2c:	0001d717          	auipc	a4,0x1d
    80004b30:	9ec70713          	addi	a4,a4,-1556 # 80021518 <devsw>
    80004b34:	97ba                	add	a5,a5,a4
    80004b36:	679c                	ld	a5,8(a5)
    80004b38:	cbdd                	beqz	a5,80004bee <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b3a:	4505                	li	a0,1
    80004b3c:	9782                	jalr	a5
    80004b3e:	8a2a                	mv	s4,a0
    80004b40:	a8a5                	j	80004bb8 <filewrite+0xfa>
    80004b42:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	8b4080e7          	jalr	-1868(ra) # 800043fa <begin_op>
      ilock(f->ip);
    80004b4e:	01893503          	ld	a0,24(s2)
    80004b52:	fffff097          	auipc	ra,0xfffff
    80004b56:	ecc080e7          	jalr	-308(ra) # 80003a1e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b5a:	8756                	mv	a4,s5
    80004b5c:	02092683          	lw	a3,32(s2)
    80004b60:	01698633          	add	a2,s3,s6
    80004b64:	4585                	li	a1,1
    80004b66:	01893503          	ld	a0,24(s2)
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	260080e7          	jalr	608(ra) # 80003dca <writei>
    80004b72:	84aa                	mv	s1,a0
    80004b74:	00a05763          	blez	a0,80004b82 <filewrite+0xc4>
        f->off += r;
    80004b78:	02092783          	lw	a5,32(s2)
    80004b7c:	9fa9                	addw	a5,a5,a0
    80004b7e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b82:	01893503          	ld	a0,24(s2)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	f5a080e7          	jalr	-166(ra) # 80003ae0 <iunlock>
      end_op();
    80004b8e:	00000097          	auipc	ra,0x0
    80004b92:	8ea080e7          	jalr	-1814(ra) # 80004478 <end_op>

      if(r != n1){
    80004b96:	009a9f63          	bne	s5,s1,80004bb4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b9a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b9e:	0149db63          	bge	s3,s4,80004bb4 <filewrite+0xf6>
      int n1 = n - i;
    80004ba2:	413a04bb          	subw	s1,s4,s3
    80004ba6:	0004879b          	sext.w	a5,s1
    80004baa:	f8fbdce3          	bge	s7,a5,80004b42 <filewrite+0x84>
    80004bae:	84e2                	mv	s1,s8
    80004bb0:	bf49                	j	80004b42 <filewrite+0x84>
    int i = 0;
    80004bb2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bb4:	013a1f63          	bne	s4,s3,80004bd2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bb8:	8552                	mv	a0,s4
    80004bba:	60a6                	ld	ra,72(sp)
    80004bbc:	6406                	ld	s0,64(sp)
    80004bbe:	74e2                	ld	s1,56(sp)
    80004bc0:	7942                	ld	s2,48(sp)
    80004bc2:	79a2                	ld	s3,40(sp)
    80004bc4:	7a02                	ld	s4,32(sp)
    80004bc6:	6ae2                	ld	s5,24(sp)
    80004bc8:	6b42                	ld	s6,16(sp)
    80004bca:	6ba2                	ld	s7,8(sp)
    80004bcc:	6c02                	ld	s8,0(sp)
    80004bce:	6161                	addi	sp,sp,80
    80004bd0:	8082                	ret
    ret = (i == n ? n : -1);
    80004bd2:	5a7d                	li	s4,-1
    80004bd4:	b7d5                	j	80004bb8 <filewrite+0xfa>
    panic("filewrite");
    80004bd6:	00004517          	auipc	a0,0x4
    80004bda:	afa50513          	addi	a0,a0,-1286 # 800086d0 <syscalls+0x288>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	95c080e7          	jalr	-1700(ra) # 8000053a <panic>
    return -1;
    80004be6:	5a7d                	li	s4,-1
    80004be8:	bfc1                	j	80004bb8 <filewrite+0xfa>
      return -1;
    80004bea:	5a7d                	li	s4,-1
    80004bec:	b7f1                	j	80004bb8 <filewrite+0xfa>
    80004bee:	5a7d                	li	s4,-1
    80004bf0:	b7e1                	j	80004bb8 <filewrite+0xfa>

0000000080004bf2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bf2:	7179                	addi	sp,sp,-48
    80004bf4:	f406                	sd	ra,40(sp)
    80004bf6:	f022                	sd	s0,32(sp)
    80004bf8:	ec26                	sd	s1,24(sp)
    80004bfa:	e84a                	sd	s2,16(sp)
    80004bfc:	e44e                	sd	s3,8(sp)
    80004bfe:	e052                	sd	s4,0(sp)
    80004c00:	1800                	addi	s0,sp,48
    80004c02:	84aa                	mv	s1,a0
    80004c04:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c06:	0005b023          	sd	zero,0(a1)
    80004c0a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c0e:	00000097          	auipc	ra,0x0
    80004c12:	bf8080e7          	jalr	-1032(ra) # 80004806 <filealloc>
    80004c16:	e088                	sd	a0,0(s1)
    80004c18:	c551                	beqz	a0,80004ca4 <pipealloc+0xb2>
    80004c1a:	00000097          	auipc	ra,0x0
    80004c1e:	bec080e7          	jalr	-1044(ra) # 80004806 <filealloc>
    80004c22:	00aa3023          	sd	a0,0(s4)
    80004c26:	c92d                	beqz	a0,80004c98 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	eb8080e7          	jalr	-328(ra) # 80000ae0 <kalloc>
    80004c30:	892a                	mv	s2,a0
    80004c32:	c125                	beqz	a0,80004c92 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c34:	4985                	li	s3,1
    80004c36:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c3a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c3e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c42:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c46:	00004597          	auipc	a1,0x4
    80004c4a:	a9a58593          	addi	a1,a1,-1382 # 800086e0 <syscalls+0x298>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	ef2080e7          	jalr	-270(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004c56:	609c                	ld	a5,0(s1)
    80004c58:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c5c:	609c                	ld	a5,0(s1)
    80004c5e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c62:	609c                	ld	a5,0(s1)
    80004c64:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c68:	609c                	ld	a5,0(s1)
    80004c6a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c6e:	000a3783          	ld	a5,0(s4)
    80004c72:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c76:	000a3783          	ld	a5,0(s4)
    80004c7a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c7e:	000a3783          	ld	a5,0(s4)
    80004c82:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c86:	000a3783          	ld	a5,0(s4)
    80004c8a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c8e:	4501                	li	a0,0
    80004c90:	a025                	j	80004cb8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c92:	6088                	ld	a0,0(s1)
    80004c94:	e501                	bnez	a0,80004c9c <pipealloc+0xaa>
    80004c96:	a039                	j	80004ca4 <pipealloc+0xb2>
    80004c98:	6088                	ld	a0,0(s1)
    80004c9a:	c51d                	beqz	a0,80004cc8 <pipealloc+0xd6>
    fileclose(*f0);
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	c26080e7          	jalr	-986(ra) # 800048c2 <fileclose>
  if(*f1)
    80004ca4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ca8:	557d                	li	a0,-1
  if(*f1)
    80004caa:	c799                	beqz	a5,80004cb8 <pipealloc+0xc6>
    fileclose(*f1);
    80004cac:	853e                	mv	a0,a5
    80004cae:	00000097          	auipc	ra,0x0
    80004cb2:	c14080e7          	jalr	-1004(ra) # 800048c2 <fileclose>
  return -1;
    80004cb6:	557d                	li	a0,-1
}
    80004cb8:	70a2                	ld	ra,40(sp)
    80004cba:	7402                	ld	s0,32(sp)
    80004cbc:	64e2                	ld	s1,24(sp)
    80004cbe:	6942                	ld	s2,16(sp)
    80004cc0:	69a2                	ld	s3,8(sp)
    80004cc2:	6a02                	ld	s4,0(sp)
    80004cc4:	6145                	addi	sp,sp,48
    80004cc6:	8082                	ret
  return -1;
    80004cc8:	557d                	li	a0,-1
    80004cca:	b7fd                	j	80004cb8 <pipealloc+0xc6>

0000000080004ccc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ccc:	1101                	addi	sp,sp,-32
    80004cce:	ec06                	sd	ra,24(sp)
    80004cd0:	e822                	sd	s0,16(sp)
    80004cd2:	e426                	sd	s1,8(sp)
    80004cd4:	e04a                	sd	s2,0(sp)
    80004cd6:	1000                	addi	s0,sp,32
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	ef4080e7          	jalr	-268(ra) # 80000bd0 <acquire>
  if(writable){
    80004ce4:	02090d63          	beqz	s2,80004d1e <pipeclose+0x52>
    pi->writeopen = 0;
    80004ce8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cec:	21848513          	addi	a0,s1,536
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	6ea080e7          	jalr	1770(ra) # 800023da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cf8:	2204b783          	ld	a5,544(s1)
    80004cfc:	eb95                	bnez	a5,80004d30 <pipeclose+0x64>
    release(&pi->lock);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	f84080e7          	jalr	-124(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	cd8080e7          	jalr	-808(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004d12:	60e2                	ld	ra,24(sp)
    80004d14:	6442                	ld	s0,16(sp)
    80004d16:	64a2                	ld	s1,8(sp)
    80004d18:	6902                	ld	s2,0(sp)
    80004d1a:	6105                	addi	sp,sp,32
    80004d1c:	8082                	ret
    pi->readopen = 0;
    80004d1e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d22:	21c48513          	addi	a0,s1,540
    80004d26:	ffffd097          	auipc	ra,0xffffd
    80004d2a:	6b4080e7          	jalr	1716(ra) # 800023da <wakeup>
    80004d2e:	b7e9                	j	80004cf8 <pipeclose+0x2c>
    release(&pi->lock);
    80004d30:	8526                	mv	a0,s1
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	f52080e7          	jalr	-174(ra) # 80000c84 <release>
}
    80004d3a:	bfe1                	j	80004d12 <pipeclose+0x46>

0000000080004d3c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d3c:	711d                	addi	sp,sp,-96
    80004d3e:	ec86                	sd	ra,88(sp)
    80004d40:	e8a2                	sd	s0,80(sp)
    80004d42:	e4a6                	sd	s1,72(sp)
    80004d44:	e0ca                	sd	s2,64(sp)
    80004d46:	fc4e                	sd	s3,56(sp)
    80004d48:	f852                	sd	s4,48(sp)
    80004d4a:	f456                	sd	s5,40(sp)
    80004d4c:	f05a                	sd	s6,32(sp)
    80004d4e:	ec5e                	sd	s7,24(sp)
    80004d50:	e862                	sd	s8,16(sp)
    80004d52:	1080                	addi	s0,sp,96
    80004d54:	84aa                	mv	s1,a0
    80004d56:	8aae                	mv	s5,a1
    80004d58:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	c3c080e7          	jalr	-964(ra) # 80001996 <myproc>
    80004d62:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	e6a080e7          	jalr	-406(ra) # 80000bd0 <acquire>
  while(i < n){
    80004d6e:	0b405363          	blez	s4,80004e14 <pipewrite+0xd8>
  int i = 0;
    80004d72:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d74:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d76:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d7a:	21c48b93          	addi	s7,s1,540
    80004d7e:	a089                	j	80004dc0 <pipewrite+0x84>
      release(&pi->lock);
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	f02080e7          	jalr	-254(ra) # 80000c84 <release>
      return -1;
    80004d8a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d8c:	854a                	mv	a0,s2
    80004d8e:	60e6                	ld	ra,88(sp)
    80004d90:	6446                	ld	s0,80(sp)
    80004d92:	64a6                	ld	s1,72(sp)
    80004d94:	6906                	ld	s2,64(sp)
    80004d96:	79e2                	ld	s3,56(sp)
    80004d98:	7a42                	ld	s4,48(sp)
    80004d9a:	7aa2                	ld	s5,40(sp)
    80004d9c:	7b02                	ld	s6,32(sp)
    80004d9e:	6be2                	ld	s7,24(sp)
    80004da0:	6c42                	ld	s8,16(sp)
    80004da2:	6125                	addi	sp,sp,96
    80004da4:	8082                	ret
      wakeup(&pi->nread);
    80004da6:	8562                	mv	a0,s8
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	632080e7          	jalr	1586(ra) # 800023da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004db0:	85a6                	mv	a1,s1
    80004db2:	855e                	mv	a0,s7
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	32c080e7          	jalr	812(ra) # 800020e0 <sleep>
  while(i < n){
    80004dbc:	05495d63          	bge	s2,s4,80004e16 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004dc0:	2204a783          	lw	a5,544(s1)
    80004dc4:	dfd5                	beqz	a5,80004d80 <pipewrite+0x44>
    80004dc6:	0289a783          	lw	a5,40(s3)
    80004dca:	fbdd                	bnez	a5,80004d80 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dcc:	2184a783          	lw	a5,536(s1)
    80004dd0:	21c4a703          	lw	a4,540(s1)
    80004dd4:	2007879b          	addiw	a5,a5,512
    80004dd8:	fcf707e3          	beq	a4,a5,80004da6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ddc:	4685                	li	a3,1
    80004dde:	01590633          	add	a2,s2,s5
    80004de2:	faf40593          	addi	a1,s0,-81
    80004de6:	0589b503          	ld	a0,88(s3)
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	8fc080e7          	jalr	-1796(ra) # 800016e6 <copyin>
    80004df2:	03650263          	beq	a0,s6,80004e16 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004df6:	21c4a783          	lw	a5,540(s1)
    80004dfa:	0017871b          	addiw	a4,a5,1
    80004dfe:	20e4ae23          	sw	a4,540(s1)
    80004e02:	1ff7f793          	andi	a5,a5,511
    80004e06:	97a6                	add	a5,a5,s1
    80004e08:	faf44703          	lbu	a4,-81(s0)
    80004e0c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e10:	2905                	addiw	s2,s2,1
    80004e12:	b76d                	j	80004dbc <pipewrite+0x80>
  int i = 0;
    80004e14:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e16:	21848513          	addi	a0,s1,536
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	5c0080e7          	jalr	1472(ra) # 800023da <wakeup>
  release(&pi->lock);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	e60080e7          	jalr	-416(ra) # 80000c84 <release>
  return i;
    80004e2c:	b785                	j	80004d8c <pipewrite+0x50>

0000000080004e2e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e2e:	715d                	addi	sp,sp,-80
    80004e30:	e486                	sd	ra,72(sp)
    80004e32:	e0a2                	sd	s0,64(sp)
    80004e34:	fc26                	sd	s1,56(sp)
    80004e36:	f84a                	sd	s2,48(sp)
    80004e38:	f44e                	sd	s3,40(sp)
    80004e3a:	f052                	sd	s4,32(sp)
    80004e3c:	ec56                	sd	s5,24(sp)
    80004e3e:	e85a                	sd	s6,16(sp)
    80004e40:	0880                	addi	s0,sp,80
    80004e42:	84aa                	mv	s1,a0
    80004e44:	892e                	mv	s2,a1
    80004e46:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	b4e080e7          	jalr	-1202(ra) # 80001996 <myproc>
    80004e50:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e52:	8526                	mv	a0,s1
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	d7c080e7          	jalr	-644(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e5c:	2184a703          	lw	a4,536(s1)
    80004e60:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e64:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e68:	02f71463          	bne	a4,a5,80004e90 <piperead+0x62>
    80004e6c:	2244a783          	lw	a5,548(s1)
    80004e70:	c385                	beqz	a5,80004e90 <piperead+0x62>
    if(pr->killed){
    80004e72:	028a2783          	lw	a5,40(s4)
    80004e76:	ebc9                	bnez	a5,80004f08 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e78:	85a6                	mv	a1,s1
    80004e7a:	854e                	mv	a0,s3
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	264080e7          	jalr	612(ra) # 800020e0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e84:	2184a703          	lw	a4,536(s1)
    80004e88:	21c4a783          	lw	a5,540(s1)
    80004e8c:	fef700e3          	beq	a4,a5,80004e6c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e90:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e92:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e94:	05505463          	blez	s5,80004edc <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004e98:	2184a783          	lw	a5,536(s1)
    80004e9c:	21c4a703          	lw	a4,540(s1)
    80004ea0:	02f70e63          	beq	a4,a5,80004edc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ea4:	0017871b          	addiw	a4,a5,1
    80004ea8:	20e4ac23          	sw	a4,536(s1)
    80004eac:	1ff7f793          	andi	a5,a5,511
    80004eb0:	97a6                	add	a5,a5,s1
    80004eb2:	0187c783          	lbu	a5,24(a5)
    80004eb6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eba:	4685                	li	a3,1
    80004ebc:	fbf40613          	addi	a2,s0,-65
    80004ec0:	85ca                	mv	a1,s2
    80004ec2:	058a3503          	ld	a0,88(s4)
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	794080e7          	jalr	1940(ra) # 8000165a <copyout>
    80004ece:	01650763          	beq	a0,s6,80004edc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ed2:	2985                	addiw	s3,s3,1
    80004ed4:	0905                	addi	s2,s2,1
    80004ed6:	fd3a91e3          	bne	s5,s3,80004e98 <piperead+0x6a>
    80004eda:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004edc:	21c48513          	addi	a0,s1,540
    80004ee0:	ffffd097          	auipc	ra,0xffffd
    80004ee4:	4fa080e7          	jalr	1274(ra) # 800023da <wakeup>
  release(&pi->lock);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	d9a080e7          	jalr	-614(ra) # 80000c84 <release>
  return i;
}
    80004ef2:	854e                	mv	a0,s3
    80004ef4:	60a6                	ld	ra,72(sp)
    80004ef6:	6406                	ld	s0,64(sp)
    80004ef8:	74e2                	ld	s1,56(sp)
    80004efa:	7942                	ld	s2,48(sp)
    80004efc:	79a2                	ld	s3,40(sp)
    80004efe:	7a02                	ld	s4,32(sp)
    80004f00:	6ae2                	ld	s5,24(sp)
    80004f02:	6b42                	ld	s6,16(sp)
    80004f04:	6161                	addi	sp,sp,80
    80004f06:	8082                	ret
      release(&pi->lock);
    80004f08:	8526                	mv	a0,s1
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	d7a080e7          	jalr	-646(ra) # 80000c84 <release>
      return -1;
    80004f12:	59fd                	li	s3,-1
    80004f14:	bff9                	j	80004ef2 <piperead+0xc4>

0000000080004f16 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f16:	de010113          	addi	sp,sp,-544
    80004f1a:	20113c23          	sd	ra,536(sp)
    80004f1e:	20813823          	sd	s0,528(sp)
    80004f22:	20913423          	sd	s1,520(sp)
    80004f26:	21213023          	sd	s2,512(sp)
    80004f2a:	ffce                	sd	s3,504(sp)
    80004f2c:	fbd2                	sd	s4,496(sp)
    80004f2e:	f7d6                	sd	s5,488(sp)
    80004f30:	f3da                	sd	s6,480(sp)
    80004f32:	efde                	sd	s7,472(sp)
    80004f34:	ebe2                	sd	s8,464(sp)
    80004f36:	e7e6                	sd	s9,456(sp)
    80004f38:	e3ea                	sd	s10,448(sp)
    80004f3a:	ff6e                	sd	s11,440(sp)
    80004f3c:	1400                	addi	s0,sp,544
    80004f3e:	892a                	mv	s2,a0
    80004f40:	dea43423          	sd	a0,-536(s0)
    80004f44:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	a4e080e7          	jalr	-1458(ra) # 80001996 <myproc>
    80004f50:	84aa                	mv	s1,a0

  begin_op();
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	4a8080e7          	jalr	1192(ra) # 800043fa <begin_op>

  if((ip = namei(path)) == 0){
    80004f5a:	854a                	mv	a0,s2
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	27e080e7          	jalr	638(ra) # 800041da <namei>
    80004f64:	c93d                	beqz	a0,80004fda <exec+0xc4>
    80004f66:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	ab6080e7          	jalr	-1354(ra) # 80003a1e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f70:	04000713          	li	a4,64
    80004f74:	4681                	li	a3,0
    80004f76:	e5040613          	addi	a2,s0,-432
    80004f7a:	4581                	li	a1,0
    80004f7c:	8556                	mv	a0,s5
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	d54080e7          	jalr	-684(ra) # 80003cd2 <readi>
    80004f86:	04000793          	li	a5,64
    80004f8a:	00f51a63          	bne	a0,a5,80004f9e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f8e:	e5042703          	lw	a4,-432(s0)
    80004f92:	464c47b7          	lui	a5,0x464c4
    80004f96:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f9a:	04f70663          	beq	a4,a5,80004fe6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f9e:	8556                	mv	a0,s5
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	ce0080e7          	jalr	-800(ra) # 80003c80 <iunlockput>
    end_op();
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	4d0080e7          	jalr	1232(ra) # 80004478 <end_op>
  }
  return -1;
    80004fb0:	557d                	li	a0,-1
}
    80004fb2:	21813083          	ld	ra,536(sp)
    80004fb6:	21013403          	ld	s0,528(sp)
    80004fba:	20813483          	ld	s1,520(sp)
    80004fbe:	20013903          	ld	s2,512(sp)
    80004fc2:	79fe                	ld	s3,504(sp)
    80004fc4:	7a5e                	ld	s4,496(sp)
    80004fc6:	7abe                	ld	s5,488(sp)
    80004fc8:	7b1e                	ld	s6,480(sp)
    80004fca:	6bfe                	ld	s7,472(sp)
    80004fcc:	6c5e                	ld	s8,464(sp)
    80004fce:	6cbe                	ld	s9,456(sp)
    80004fd0:	6d1e                	ld	s10,448(sp)
    80004fd2:	7dfa                	ld	s11,440(sp)
    80004fd4:	22010113          	addi	sp,sp,544
    80004fd8:	8082                	ret
    end_op();
    80004fda:	fffff097          	auipc	ra,0xfffff
    80004fde:	49e080e7          	jalr	1182(ra) # 80004478 <end_op>
    return -1;
    80004fe2:	557d                	li	a0,-1
    80004fe4:	b7f9                	j	80004fb2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	a72080e7          	jalr	-1422(ra) # 80001a5a <proc_pagetable>
    80004ff0:	8b2a                	mv	s6,a0
    80004ff2:	d555                	beqz	a0,80004f9e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff4:	e7042783          	lw	a5,-400(s0)
    80004ff8:	e8845703          	lhu	a4,-376(s0)
    80004ffc:	c735                	beqz	a4,80005068 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ffe:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005000:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80005004:	6a05                	lui	s4,0x1
    80005006:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000500a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000500e:	6d85                	lui	s11,0x1
    80005010:	7d7d                	lui	s10,0xfffff
    80005012:	ac1d                	j	80005248 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005014:	00003517          	auipc	a0,0x3
    80005018:	6d450513          	addi	a0,a0,1748 # 800086e8 <syscalls+0x2a0>
    8000501c:	ffffb097          	auipc	ra,0xffffb
    80005020:	51e080e7          	jalr	1310(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005024:	874a                	mv	a4,s2
    80005026:	009c86bb          	addw	a3,s9,s1
    8000502a:	4581                	li	a1,0
    8000502c:	8556                	mv	a0,s5
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	ca4080e7          	jalr	-860(ra) # 80003cd2 <readi>
    80005036:	2501                	sext.w	a0,a0
    80005038:	1aa91863          	bne	s2,a0,800051e8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000503c:	009d84bb          	addw	s1,s11,s1
    80005040:	013d09bb          	addw	s3,s10,s3
    80005044:	1f74f263          	bgeu	s1,s7,80005228 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005048:	02049593          	slli	a1,s1,0x20
    8000504c:	9181                	srli	a1,a1,0x20
    8000504e:	95e2                	add	a1,a1,s8
    80005050:	855a                	mv	a0,s6
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	000080e7          	jalr	ra # 80001052 <walkaddr>
    8000505a:	862a                	mv	a2,a0
    if(pa == 0)
    8000505c:	dd45                	beqz	a0,80005014 <exec+0xfe>
      n = PGSIZE;
    8000505e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005060:	fd49f2e3          	bgeu	s3,s4,80005024 <exec+0x10e>
      n = sz - i;
    80005064:	894e                	mv	s2,s3
    80005066:	bf7d                	j	80005024 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005068:	4481                	li	s1,0
  iunlockput(ip);
    8000506a:	8556                	mv	a0,s5
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	c14080e7          	jalr	-1004(ra) # 80003c80 <iunlockput>
  end_op();
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	404080e7          	jalr	1028(ra) # 80004478 <end_op>
  p = myproc();
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	91a080e7          	jalr	-1766(ra) # 80001996 <myproc>
    80005084:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005086:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000508a:	6785                	lui	a5,0x1
    8000508c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000508e:	97a6                	add	a5,a5,s1
    80005090:	777d                	lui	a4,0xfffff
    80005092:	8ff9                	and	a5,a5,a4
    80005094:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005098:	6609                	lui	a2,0x2
    8000509a:	963e                	add	a2,a2,a5
    8000509c:	85be                	mv	a1,a5
    8000509e:	855a                	mv	a0,s6
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	366080e7          	jalr	870(ra) # 80001406 <uvmalloc>
    800050a8:	8c2a                	mv	s8,a0
  ip = 0;
    800050aa:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050ac:	12050e63          	beqz	a0,800051e8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050b0:	75f9                	lui	a1,0xffffe
    800050b2:	95aa                	add	a1,a1,a0
    800050b4:	855a                	mv	a0,s6
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	572080e7          	jalr	1394(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    800050be:	7afd                	lui	s5,0xfffff
    800050c0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c2:	df043783          	ld	a5,-528(s0)
    800050c6:	6388                	ld	a0,0(a5)
    800050c8:	c925                	beqz	a0,80005138 <exec+0x222>
    800050ca:	e9040993          	addi	s3,s0,-368
    800050ce:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050d2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050d4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	d72080e7          	jalr	-654(ra) # 80000e48 <strlen>
    800050de:	0015079b          	addiw	a5,a0,1
    800050e2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050e6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050ea:	13596363          	bltu	s2,s5,80005210 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050ee:	df043d83          	ld	s11,-528(s0)
    800050f2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050f6:	8552                	mv	a0,s4
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	d50080e7          	jalr	-688(ra) # 80000e48 <strlen>
    80005100:	0015069b          	addiw	a3,a0,1
    80005104:	8652                	mv	a2,s4
    80005106:	85ca                	mv	a1,s2
    80005108:	855a                	mv	a0,s6
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	550080e7          	jalr	1360(ra) # 8000165a <copyout>
    80005112:	10054363          	bltz	a0,80005218 <exec+0x302>
    ustack[argc] = sp;
    80005116:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000511a:	0485                	addi	s1,s1,1
    8000511c:	008d8793          	addi	a5,s11,8
    80005120:	def43823          	sd	a5,-528(s0)
    80005124:	008db503          	ld	a0,8(s11)
    80005128:	c911                	beqz	a0,8000513c <exec+0x226>
    if(argc >= MAXARG)
    8000512a:	09a1                	addi	s3,s3,8
    8000512c:	fb3c95e3          	bne	s9,s3,800050d6 <exec+0x1c0>
  sz = sz1;
    80005130:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005134:	4a81                	li	s5,0
    80005136:	a84d                	j	800051e8 <exec+0x2d2>
  sp = sz;
    80005138:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000513a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000513c:	00349793          	slli	a5,s1,0x3
    80005140:	f9078793          	addi	a5,a5,-112
    80005144:	97a2                	add	a5,a5,s0
    80005146:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000514a:	00148693          	addi	a3,s1,1
    8000514e:	068e                	slli	a3,a3,0x3
    80005150:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005154:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005158:	01597663          	bgeu	s2,s5,80005164 <exec+0x24e>
  sz = sz1;
    8000515c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005160:	4a81                	li	s5,0
    80005162:	a059                	j	800051e8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005164:	e9040613          	addi	a2,s0,-368
    80005168:	85ca                	mv	a1,s2
    8000516a:	855a                	mv	a0,s6
    8000516c:	ffffc097          	auipc	ra,0xffffc
    80005170:	4ee080e7          	jalr	1262(ra) # 8000165a <copyout>
    80005174:	0a054663          	bltz	a0,80005220 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005178:	060bb783          	ld	a5,96(s7)
    8000517c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005180:	de843783          	ld	a5,-536(s0)
    80005184:	0007c703          	lbu	a4,0(a5)
    80005188:	cf11                	beqz	a4,800051a4 <exec+0x28e>
    8000518a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000518c:	02f00693          	li	a3,47
    80005190:	a039                	j	8000519e <exec+0x288>
      last = s+1;
    80005192:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005196:	0785                	addi	a5,a5,1
    80005198:	fff7c703          	lbu	a4,-1(a5)
    8000519c:	c701                	beqz	a4,800051a4 <exec+0x28e>
    if(*s == '/')
    8000519e:	fed71ce3          	bne	a4,a3,80005196 <exec+0x280>
    800051a2:	bfc5                	j	80005192 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800051a4:	4641                	li	a2,16
    800051a6:	de843583          	ld	a1,-536(s0)
    800051aa:	160b8513          	addi	a0,s7,352
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	c68080e7          	jalr	-920(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800051b6:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800051ba:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800051be:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051c2:	060bb783          	ld	a5,96(s7)
    800051c6:	e6843703          	ld	a4,-408(s0)
    800051ca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051cc:	060bb783          	ld	a5,96(s7)
    800051d0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051d4:	85ea                	mv	a1,s10
    800051d6:	ffffd097          	auipc	ra,0xffffd
    800051da:	920080e7          	jalr	-1760(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051de:	0004851b          	sext.w	a0,s1
    800051e2:	bbc1                	j	80004fb2 <exec+0x9c>
    800051e4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051e8:	df843583          	ld	a1,-520(s0)
    800051ec:	855a                	mv	a0,s6
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	908080e7          	jalr	-1784(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    800051f6:	da0a94e3          	bnez	s5,80004f9e <exec+0x88>
  return -1;
    800051fa:	557d                	li	a0,-1
    800051fc:	bb5d                	j	80004fb2 <exec+0x9c>
    800051fe:	de943c23          	sd	s1,-520(s0)
    80005202:	b7dd                	j	800051e8 <exec+0x2d2>
    80005204:	de943c23          	sd	s1,-520(s0)
    80005208:	b7c5                	j	800051e8 <exec+0x2d2>
    8000520a:	de943c23          	sd	s1,-520(s0)
    8000520e:	bfe9                	j	800051e8 <exec+0x2d2>
  sz = sz1;
    80005210:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005214:	4a81                	li	s5,0
    80005216:	bfc9                	j	800051e8 <exec+0x2d2>
  sz = sz1;
    80005218:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000521c:	4a81                	li	s5,0
    8000521e:	b7e9                	j	800051e8 <exec+0x2d2>
  sz = sz1;
    80005220:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005224:	4a81                	li	s5,0
    80005226:	b7c9                	j	800051e8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005228:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000522c:	e0843783          	ld	a5,-504(s0)
    80005230:	0017869b          	addiw	a3,a5,1
    80005234:	e0d43423          	sd	a3,-504(s0)
    80005238:	e0043783          	ld	a5,-512(s0)
    8000523c:	0387879b          	addiw	a5,a5,56
    80005240:	e8845703          	lhu	a4,-376(s0)
    80005244:	e2e6d3e3          	bge	a3,a4,8000506a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005248:	2781                	sext.w	a5,a5
    8000524a:	e0f43023          	sd	a5,-512(s0)
    8000524e:	03800713          	li	a4,56
    80005252:	86be                	mv	a3,a5
    80005254:	e1840613          	addi	a2,s0,-488
    80005258:	4581                	li	a1,0
    8000525a:	8556                	mv	a0,s5
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	a76080e7          	jalr	-1418(ra) # 80003cd2 <readi>
    80005264:	03800793          	li	a5,56
    80005268:	f6f51ee3          	bne	a0,a5,800051e4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000526c:	e1842783          	lw	a5,-488(s0)
    80005270:	4705                	li	a4,1
    80005272:	fae79de3          	bne	a5,a4,8000522c <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005276:	e4043603          	ld	a2,-448(s0)
    8000527a:	e3843783          	ld	a5,-456(s0)
    8000527e:	f8f660e3          	bltu	a2,a5,800051fe <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005282:	e2843783          	ld	a5,-472(s0)
    80005286:	963e                	add	a2,a2,a5
    80005288:	f6f66ee3          	bltu	a2,a5,80005204 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000528c:	85a6                	mv	a1,s1
    8000528e:	855a                	mv	a0,s6
    80005290:	ffffc097          	auipc	ra,0xffffc
    80005294:	176080e7          	jalr	374(ra) # 80001406 <uvmalloc>
    80005298:	dea43c23          	sd	a0,-520(s0)
    8000529c:	d53d                	beqz	a0,8000520a <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000529e:	e2843c03          	ld	s8,-472(s0)
    800052a2:	de043783          	ld	a5,-544(s0)
    800052a6:	00fc77b3          	and	a5,s8,a5
    800052aa:	ff9d                	bnez	a5,800051e8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052ac:	e2042c83          	lw	s9,-480(s0)
    800052b0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052b4:	f60b8ae3          	beqz	s7,80005228 <exec+0x312>
    800052b8:	89de                	mv	s3,s7
    800052ba:	4481                	li	s1,0
    800052bc:	b371                	j	80005048 <exec+0x132>

00000000800052be <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052be:	7179                	addi	sp,sp,-48
    800052c0:	f406                	sd	ra,40(sp)
    800052c2:	f022                	sd	s0,32(sp)
    800052c4:	ec26                	sd	s1,24(sp)
    800052c6:	e84a                	sd	s2,16(sp)
    800052c8:	1800                	addi	s0,sp,48
    800052ca:	892e                	mv	s2,a1
    800052cc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052ce:	fdc40593          	addi	a1,s0,-36
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	af8080e7          	jalr	-1288(ra) # 80002dca <argint>
    800052da:	04054063          	bltz	a0,8000531a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052de:	fdc42703          	lw	a4,-36(s0)
    800052e2:	47bd                	li	a5,15
    800052e4:	02e7ed63          	bltu	a5,a4,8000531e <argfd+0x60>
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	6ae080e7          	jalr	1710(ra) # 80001996 <myproc>
    800052f0:	fdc42703          	lw	a4,-36(s0)
    800052f4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    800052f8:	078e                	slli	a5,a5,0x3
    800052fa:	953e                	add	a0,a0,a5
    800052fc:	651c                	ld	a5,8(a0)
    800052fe:	c395                	beqz	a5,80005322 <argfd+0x64>
    return -1;
  if(pfd)
    80005300:	00090463          	beqz	s2,80005308 <argfd+0x4a>
    *pfd = fd;
    80005304:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005308:	4501                	li	a0,0
  if(pf)
    8000530a:	c091                	beqz	s1,8000530e <argfd+0x50>
    *pf = f;
    8000530c:	e09c                	sd	a5,0(s1)
}
    8000530e:	70a2                	ld	ra,40(sp)
    80005310:	7402                	ld	s0,32(sp)
    80005312:	64e2                	ld	s1,24(sp)
    80005314:	6942                	ld	s2,16(sp)
    80005316:	6145                	addi	sp,sp,48
    80005318:	8082                	ret
    return -1;
    8000531a:	557d                	li	a0,-1
    8000531c:	bfcd                	j	8000530e <argfd+0x50>
    return -1;
    8000531e:	557d                	li	a0,-1
    80005320:	b7fd                	j	8000530e <argfd+0x50>
    80005322:	557d                	li	a0,-1
    80005324:	b7ed                	j	8000530e <argfd+0x50>

0000000080005326 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005326:	1101                	addi	sp,sp,-32
    80005328:	ec06                	sd	ra,24(sp)
    8000532a:	e822                	sd	s0,16(sp)
    8000532c:	e426                	sd	s1,8(sp)
    8000532e:	1000                	addi	s0,sp,32
    80005330:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	664080e7          	jalr	1636(ra) # 80001996 <myproc>
    8000533a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000533c:	0d850793          	addi	a5,a0,216
    80005340:	4501                	li	a0,0
    80005342:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005344:	6398                	ld	a4,0(a5)
    80005346:	cb19                	beqz	a4,8000535c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005348:	2505                	addiw	a0,a0,1
    8000534a:	07a1                	addi	a5,a5,8
    8000534c:	fed51ce3          	bne	a0,a3,80005344 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005350:	557d                	li	a0,-1
}
    80005352:	60e2                	ld	ra,24(sp)
    80005354:	6442                	ld	s0,16(sp)
    80005356:	64a2                	ld	s1,8(sp)
    80005358:	6105                	addi	sp,sp,32
    8000535a:	8082                	ret
      p->ofile[fd] = f;
    8000535c:	01a50793          	addi	a5,a0,26
    80005360:	078e                	slli	a5,a5,0x3
    80005362:	963e                	add	a2,a2,a5
    80005364:	e604                	sd	s1,8(a2)
      return fd;
    80005366:	b7f5                	j	80005352 <fdalloc+0x2c>

0000000080005368 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005368:	715d                	addi	sp,sp,-80
    8000536a:	e486                	sd	ra,72(sp)
    8000536c:	e0a2                	sd	s0,64(sp)
    8000536e:	fc26                	sd	s1,56(sp)
    80005370:	f84a                	sd	s2,48(sp)
    80005372:	f44e                	sd	s3,40(sp)
    80005374:	f052                	sd	s4,32(sp)
    80005376:	ec56                	sd	s5,24(sp)
    80005378:	0880                	addi	s0,sp,80
    8000537a:	89ae                	mv	s3,a1
    8000537c:	8ab2                	mv	s5,a2
    8000537e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005380:	fb040593          	addi	a1,s0,-80
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	e74080e7          	jalr	-396(ra) # 800041f8 <nameiparent>
    8000538c:	892a                	mv	s2,a0
    8000538e:	12050e63          	beqz	a0,800054ca <create+0x162>
    return 0;

  ilock(dp);
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	68c080e7          	jalr	1676(ra) # 80003a1e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000539a:	4601                	li	a2,0
    8000539c:	fb040593          	addi	a1,s0,-80
    800053a0:	854a                	mv	a0,s2
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	b60080e7          	jalr	-1184(ra) # 80003f02 <dirlookup>
    800053aa:	84aa                	mv	s1,a0
    800053ac:	c921                	beqz	a0,800053fc <create+0x94>
    iunlockput(dp);
    800053ae:	854a                	mv	a0,s2
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	8d0080e7          	jalr	-1840(ra) # 80003c80 <iunlockput>
    ilock(ip);
    800053b8:	8526                	mv	a0,s1
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	664080e7          	jalr	1636(ra) # 80003a1e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053c2:	2981                	sext.w	s3,s3
    800053c4:	4789                	li	a5,2
    800053c6:	02f99463          	bne	s3,a5,800053ee <create+0x86>
    800053ca:	0444d783          	lhu	a5,68(s1)
    800053ce:	37f9                	addiw	a5,a5,-2
    800053d0:	17c2                	slli	a5,a5,0x30
    800053d2:	93c1                	srli	a5,a5,0x30
    800053d4:	4705                	li	a4,1
    800053d6:	00f76c63          	bltu	a4,a5,800053ee <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053da:	8526                	mv	a0,s1
    800053dc:	60a6                	ld	ra,72(sp)
    800053de:	6406                	ld	s0,64(sp)
    800053e0:	74e2                	ld	s1,56(sp)
    800053e2:	7942                	ld	s2,48(sp)
    800053e4:	79a2                	ld	s3,40(sp)
    800053e6:	7a02                	ld	s4,32(sp)
    800053e8:	6ae2                	ld	s5,24(sp)
    800053ea:	6161                	addi	sp,sp,80
    800053ec:	8082                	ret
    iunlockput(ip);
    800053ee:	8526                	mv	a0,s1
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	890080e7          	jalr	-1904(ra) # 80003c80 <iunlockput>
    return 0;
    800053f8:	4481                	li	s1,0
    800053fa:	b7c5                	j	800053da <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053fc:	85ce                	mv	a1,s3
    800053fe:	00092503          	lw	a0,0(s2)
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	482080e7          	jalr	1154(ra) # 80003884 <ialloc>
    8000540a:	84aa                	mv	s1,a0
    8000540c:	c521                	beqz	a0,80005454 <create+0xec>
  ilock(ip);
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	610080e7          	jalr	1552(ra) # 80003a1e <ilock>
  ip->major = major;
    80005416:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000541a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000541e:	4a05                	li	s4,1
    80005420:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	52c080e7          	jalr	1324(ra) # 80003952 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000542e:	2981                	sext.w	s3,s3
    80005430:	03498a63          	beq	s3,s4,80005464 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005434:	40d0                	lw	a2,4(s1)
    80005436:	fb040593          	addi	a1,s0,-80
    8000543a:	854a                	mv	a0,s2
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	cdc080e7          	jalr	-804(ra) # 80004118 <dirlink>
    80005444:	06054b63          	bltz	a0,800054ba <create+0x152>
  iunlockput(dp);
    80005448:	854a                	mv	a0,s2
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	836080e7          	jalr	-1994(ra) # 80003c80 <iunlockput>
  return ip;
    80005452:	b761                	j	800053da <create+0x72>
    panic("create: ialloc");
    80005454:	00003517          	auipc	a0,0x3
    80005458:	2b450513          	addi	a0,a0,692 # 80008708 <syscalls+0x2c0>
    8000545c:	ffffb097          	auipc	ra,0xffffb
    80005460:	0de080e7          	jalr	222(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005464:	04a95783          	lhu	a5,74(s2)
    80005468:	2785                	addiw	a5,a5,1
    8000546a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000546e:	854a                	mv	a0,s2
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	4e2080e7          	jalr	1250(ra) # 80003952 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005478:	40d0                	lw	a2,4(s1)
    8000547a:	00003597          	auipc	a1,0x3
    8000547e:	29e58593          	addi	a1,a1,670 # 80008718 <syscalls+0x2d0>
    80005482:	8526                	mv	a0,s1
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	c94080e7          	jalr	-876(ra) # 80004118 <dirlink>
    8000548c:	00054f63          	bltz	a0,800054aa <create+0x142>
    80005490:	00492603          	lw	a2,4(s2)
    80005494:	00003597          	auipc	a1,0x3
    80005498:	28c58593          	addi	a1,a1,652 # 80008720 <syscalls+0x2d8>
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	c7a080e7          	jalr	-902(ra) # 80004118 <dirlink>
    800054a6:	f80557e3          	bgez	a0,80005434 <create+0xcc>
      panic("create dots");
    800054aa:	00003517          	auipc	a0,0x3
    800054ae:	27e50513          	addi	a0,a0,638 # 80008728 <syscalls+0x2e0>
    800054b2:	ffffb097          	auipc	ra,0xffffb
    800054b6:	088080e7          	jalr	136(ra) # 8000053a <panic>
    panic("create: dirlink");
    800054ba:	00003517          	auipc	a0,0x3
    800054be:	27e50513          	addi	a0,a0,638 # 80008738 <syscalls+0x2f0>
    800054c2:	ffffb097          	auipc	ra,0xffffb
    800054c6:	078080e7          	jalr	120(ra) # 8000053a <panic>
    return 0;
    800054ca:	84aa                	mv	s1,a0
    800054cc:	b739                	j	800053da <create+0x72>

00000000800054ce <sys_dup>:
{
    800054ce:	7179                	addi	sp,sp,-48
    800054d0:	f406                	sd	ra,40(sp)
    800054d2:	f022                	sd	s0,32(sp)
    800054d4:	ec26                	sd	s1,24(sp)
    800054d6:	e84a                	sd	s2,16(sp)
    800054d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054da:	fd840613          	addi	a2,s0,-40
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	ddc080e7          	jalr	-548(ra) # 800052be <argfd>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054ec:	02054363          	bltz	a0,80005512 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800054f0:	fd843903          	ld	s2,-40(s0)
    800054f4:	854a                	mv	a0,s2
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	e30080e7          	jalr	-464(ra) # 80005326 <fdalloc>
    800054fe:	84aa                	mv	s1,a0
    return -1;
    80005500:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005502:	00054863          	bltz	a0,80005512 <sys_dup+0x44>
  filedup(f);
    80005506:	854a                	mv	a0,s2
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	368080e7          	jalr	872(ra) # 80004870 <filedup>
  return fd;
    80005510:	87a6                	mv	a5,s1
}
    80005512:	853e                	mv	a0,a5
    80005514:	70a2                	ld	ra,40(sp)
    80005516:	7402                	ld	s0,32(sp)
    80005518:	64e2                	ld	s1,24(sp)
    8000551a:	6942                	ld	s2,16(sp)
    8000551c:	6145                	addi	sp,sp,48
    8000551e:	8082                	ret

0000000080005520 <sys_read>:
{
    80005520:	7179                	addi	sp,sp,-48
    80005522:	f406                	sd	ra,40(sp)
    80005524:	f022                	sd	s0,32(sp)
    80005526:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005528:	fe840613          	addi	a2,s0,-24
    8000552c:	4581                	li	a1,0
    8000552e:	4501                	li	a0,0
    80005530:	00000097          	auipc	ra,0x0
    80005534:	d8e080e7          	jalr	-626(ra) # 800052be <argfd>
    return -1;
    80005538:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553a:	04054163          	bltz	a0,8000557c <sys_read+0x5c>
    8000553e:	fe440593          	addi	a1,s0,-28
    80005542:	4509                	li	a0,2
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	886080e7          	jalr	-1914(ra) # 80002dca <argint>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554e:	02054763          	bltz	a0,8000557c <sys_read+0x5c>
    80005552:	fd840593          	addi	a1,s0,-40
    80005556:	4505                	li	a0,1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	894080e7          	jalr	-1900(ra) # 80002dec <argaddr>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005562:	00054d63          	bltz	a0,8000557c <sys_read+0x5c>
  return fileread(f, p, n);
    80005566:	fe442603          	lw	a2,-28(s0)
    8000556a:	fd843583          	ld	a1,-40(s0)
    8000556e:	fe843503          	ld	a0,-24(s0)
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	48a080e7          	jalr	1162(ra) # 800049fc <fileread>
    8000557a:	87aa                	mv	a5,a0
}
    8000557c:	853e                	mv	a0,a5
    8000557e:	70a2                	ld	ra,40(sp)
    80005580:	7402                	ld	s0,32(sp)
    80005582:	6145                	addi	sp,sp,48
    80005584:	8082                	ret

0000000080005586 <sys_write>:
{
    80005586:	7179                	addi	sp,sp,-48
    80005588:	f406                	sd	ra,40(sp)
    8000558a:	f022                	sd	s0,32(sp)
    8000558c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000558e:	fe840613          	addi	a2,s0,-24
    80005592:	4581                	li	a1,0
    80005594:	4501                	li	a0,0
    80005596:	00000097          	auipc	ra,0x0
    8000559a:	d28080e7          	jalr	-728(ra) # 800052be <argfd>
    return -1;
    8000559e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a0:	04054163          	bltz	a0,800055e2 <sys_write+0x5c>
    800055a4:	fe440593          	addi	a1,s0,-28
    800055a8:	4509                	li	a0,2
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	820080e7          	jalr	-2016(ra) # 80002dca <argint>
    return -1;
    800055b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b4:	02054763          	bltz	a0,800055e2 <sys_write+0x5c>
    800055b8:	fd840593          	addi	a1,s0,-40
    800055bc:	4505                	li	a0,1
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	82e080e7          	jalr	-2002(ra) # 80002dec <argaddr>
    return -1;
    800055c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c8:	00054d63          	bltz	a0,800055e2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055cc:	fe442603          	lw	a2,-28(s0)
    800055d0:	fd843583          	ld	a1,-40(s0)
    800055d4:	fe843503          	ld	a0,-24(s0)
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	4e6080e7          	jalr	1254(ra) # 80004abe <filewrite>
    800055e0:	87aa                	mv	a5,a0
}
    800055e2:	853e                	mv	a0,a5
    800055e4:	70a2                	ld	ra,40(sp)
    800055e6:	7402                	ld	s0,32(sp)
    800055e8:	6145                	addi	sp,sp,48
    800055ea:	8082                	ret

00000000800055ec <sys_close>:
{
    800055ec:	1101                	addi	sp,sp,-32
    800055ee:	ec06                	sd	ra,24(sp)
    800055f0:	e822                	sd	s0,16(sp)
    800055f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055f4:	fe040613          	addi	a2,s0,-32
    800055f8:	fec40593          	addi	a1,s0,-20
    800055fc:	4501                	li	a0,0
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	cc0080e7          	jalr	-832(ra) # 800052be <argfd>
    return -1;
    80005606:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005608:	02054463          	bltz	a0,80005630 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000560c:	ffffc097          	auipc	ra,0xffffc
    80005610:	38a080e7          	jalr	906(ra) # 80001996 <myproc>
    80005614:	fec42783          	lw	a5,-20(s0)
    80005618:	07e9                	addi	a5,a5,26
    8000561a:	078e                	slli	a5,a5,0x3
    8000561c:	953e                	add	a0,a0,a5
    8000561e:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005622:	fe043503          	ld	a0,-32(s0)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	29c080e7          	jalr	668(ra) # 800048c2 <fileclose>
  return 0;
    8000562e:	4781                	li	a5,0
}
    80005630:	853e                	mv	a0,a5
    80005632:	60e2                	ld	ra,24(sp)
    80005634:	6442                	ld	s0,16(sp)
    80005636:	6105                	addi	sp,sp,32
    80005638:	8082                	ret

000000008000563a <sys_fstat>:
{
    8000563a:	1101                	addi	sp,sp,-32
    8000563c:	ec06                	sd	ra,24(sp)
    8000563e:	e822                	sd	s0,16(sp)
    80005640:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005642:	fe840613          	addi	a2,s0,-24
    80005646:	4581                	li	a1,0
    80005648:	4501                	li	a0,0
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	c74080e7          	jalr	-908(ra) # 800052be <argfd>
    return -1;
    80005652:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005654:	02054563          	bltz	a0,8000567e <sys_fstat+0x44>
    80005658:	fe040593          	addi	a1,s0,-32
    8000565c:	4505                	li	a0,1
    8000565e:	ffffd097          	auipc	ra,0xffffd
    80005662:	78e080e7          	jalr	1934(ra) # 80002dec <argaddr>
    return -1;
    80005666:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005668:	00054b63          	bltz	a0,8000567e <sys_fstat+0x44>
  return filestat(f, st);
    8000566c:	fe043583          	ld	a1,-32(s0)
    80005670:	fe843503          	ld	a0,-24(s0)
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	316080e7          	jalr	790(ra) # 8000498a <filestat>
    8000567c:	87aa                	mv	a5,a0
}
    8000567e:	853e                	mv	a0,a5
    80005680:	60e2                	ld	ra,24(sp)
    80005682:	6442                	ld	s0,16(sp)
    80005684:	6105                	addi	sp,sp,32
    80005686:	8082                	ret

0000000080005688 <sys_link>:
{
    80005688:	7169                	addi	sp,sp,-304
    8000568a:	f606                	sd	ra,296(sp)
    8000568c:	f222                	sd	s0,288(sp)
    8000568e:	ee26                	sd	s1,280(sp)
    80005690:	ea4a                	sd	s2,272(sp)
    80005692:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005694:	08000613          	li	a2,128
    80005698:	ed040593          	addi	a1,s0,-304
    8000569c:	4501                	li	a0,0
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	770080e7          	jalr	1904(ra) # 80002e0e <argstr>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a8:	10054e63          	bltz	a0,800057c4 <sys_link+0x13c>
    800056ac:	08000613          	li	a2,128
    800056b0:	f5040593          	addi	a1,s0,-176
    800056b4:	4505                	li	a0,1
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	758080e7          	jalr	1880(ra) # 80002e0e <argstr>
    return -1;
    800056be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c0:	10054263          	bltz	a0,800057c4 <sys_link+0x13c>
  begin_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	d36080e7          	jalr	-714(ra) # 800043fa <begin_op>
  if((ip = namei(old)) == 0){
    800056cc:	ed040513          	addi	a0,s0,-304
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	b0a080e7          	jalr	-1270(ra) # 800041da <namei>
    800056d8:	84aa                	mv	s1,a0
    800056da:	c551                	beqz	a0,80005766 <sys_link+0xde>
  ilock(ip);
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	342080e7          	jalr	834(ra) # 80003a1e <ilock>
  if(ip->type == T_DIR){
    800056e4:	04449703          	lh	a4,68(s1)
    800056e8:	4785                	li	a5,1
    800056ea:	08f70463          	beq	a4,a5,80005772 <sys_link+0xea>
  ip->nlink++;
    800056ee:	04a4d783          	lhu	a5,74(s1)
    800056f2:	2785                	addiw	a5,a5,1
    800056f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	258080e7          	jalr	600(ra) # 80003952 <iupdate>
  iunlock(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	3dc080e7          	jalr	988(ra) # 80003ae0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000570c:	fd040593          	addi	a1,s0,-48
    80005710:	f5040513          	addi	a0,s0,-176
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	ae4080e7          	jalr	-1308(ra) # 800041f8 <nameiparent>
    8000571c:	892a                	mv	s2,a0
    8000571e:	c935                	beqz	a0,80005792 <sys_link+0x10a>
  ilock(dp);
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	2fe080e7          	jalr	766(ra) # 80003a1e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005728:	00092703          	lw	a4,0(s2)
    8000572c:	409c                	lw	a5,0(s1)
    8000572e:	04f71d63          	bne	a4,a5,80005788 <sys_link+0x100>
    80005732:	40d0                	lw	a2,4(s1)
    80005734:	fd040593          	addi	a1,s0,-48
    80005738:	854a                	mv	a0,s2
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	9de080e7          	jalr	-1570(ra) # 80004118 <dirlink>
    80005742:	04054363          	bltz	a0,80005788 <sys_link+0x100>
  iunlockput(dp);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	538080e7          	jalr	1336(ra) # 80003c80 <iunlockput>
  iput(ip);
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	486080e7          	jalr	1158(ra) # 80003bd8 <iput>
  end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	d1e080e7          	jalr	-738(ra) # 80004478 <end_op>
  return 0;
    80005762:	4781                	li	a5,0
    80005764:	a085                	j	800057c4 <sys_link+0x13c>
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	d12080e7          	jalr	-750(ra) # 80004478 <end_op>
    return -1;
    8000576e:	57fd                	li	a5,-1
    80005770:	a891                	j	800057c4 <sys_link+0x13c>
    iunlockput(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	50c080e7          	jalr	1292(ra) # 80003c80 <iunlockput>
    end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	cfc080e7          	jalr	-772(ra) # 80004478 <end_op>
    return -1;
    80005784:	57fd                	li	a5,-1
    80005786:	a83d                	j	800057c4 <sys_link+0x13c>
    iunlockput(dp);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	4f6080e7          	jalr	1270(ra) # 80003c80 <iunlockput>
  ilock(ip);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	28a080e7          	jalr	650(ra) # 80003a1e <ilock>
  ip->nlink--;
    8000579c:	04a4d783          	lhu	a5,74(s1)
    800057a0:	37fd                	addiw	a5,a5,-1
    800057a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	1aa080e7          	jalr	426(ra) # 80003952 <iupdate>
  iunlockput(ip);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	4ce080e7          	jalr	1230(ra) # 80003c80 <iunlockput>
  end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	cbe080e7          	jalr	-834(ra) # 80004478 <end_op>
  return -1;
    800057c2:	57fd                	li	a5,-1
}
    800057c4:	853e                	mv	a0,a5
    800057c6:	70b2                	ld	ra,296(sp)
    800057c8:	7412                	ld	s0,288(sp)
    800057ca:	64f2                	ld	s1,280(sp)
    800057cc:	6952                	ld	s2,272(sp)
    800057ce:	6155                	addi	sp,sp,304
    800057d0:	8082                	ret

00000000800057d2 <sys_unlink>:
{
    800057d2:	7151                	addi	sp,sp,-240
    800057d4:	f586                	sd	ra,232(sp)
    800057d6:	f1a2                	sd	s0,224(sp)
    800057d8:	eda6                	sd	s1,216(sp)
    800057da:	e9ca                	sd	s2,208(sp)
    800057dc:	e5ce                	sd	s3,200(sp)
    800057de:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f3040593          	addi	a1,s0,-208
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	624080e7          	jalr	1572(ra) # 80002e0e <argstr>
    800057f2:	18054163          	bltz	a0,80005974 <sys_unlink+0x1a2>
  begin_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	c04080e7          	jalr	-1020(ra) # 800043fa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057fe:	fb040593          	addi	a1,s0,-80
    80005802:	f3040513          	addi	a0,s0,-208
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	9f2080e7          	jalr	-1550(ra) # 800041f8 <nameiparent>
    8000580e:	84aa                	mv	s1,a0
    80005810:	c979                	beqz	a0,800058e6 <sys_unlink+0x114>
  ilock(dp);
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	20c080e7          	jalr	524(ra) # 80003a1e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000581a:	00003597          	auipc	a1,0x3
    8000581e:	efe58593          	addi	a1,a1,-258 # 80008718 <syscalls+0x2d0>
    80005822:	fb040513          	addi	a0,s0,-80
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	6c2080e7          	jalr	1730(ra) # 80003ee8 <namecmp>
    8000582e:	14050a63          	beqz	a0,80005982 <sys_unlink+0x1b0>
    80005832:	00003597          	auipc	a1,0x3
    80005836:	eee58593          	addi	a1,a1,-274 # 80008720 <syscalls+0x2d8>
    8000583a:	fb040513          	addi	a0,s0,-80
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	6aa080e7          	jalr	1706(ra) # 80003ee8 <namecmp>
    80005846:	12050e63          	beqz	a0,80005982 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000584a:	f2c40613          	addi	a2,s0,-212
    8000584e:	fb040593          	addi	a1,s0,-80
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	6ae080e7          	jalr	1710(ra) # 80003f02 <dirlookup>
    8000585c:	892a                	mv	s2,a0
    8000585e:	12050263          	beqz	a0,80005982 <sys_unlink+0x1b0>
  ilock(ip);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	1bc080e7          	jalr	444(ra) # 80003a1e <ilock>
  if(ip->nlink < 1)
    8000586a:	04a91783          	lh	a5,74(s2)
    8000586e:	08f05263          	blez	a5,800058f2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005872:	04491703          	lh	a4,68(s2)
    80005876:	4785                	li	a5,1
    80005878:	08f70563          	beq	a4,a5,80005902 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000587c:	4641                	li	a2,16
    8000587e:	4581                	li	a1,0
    80005880:	fc040513          	addi	a0,s0,-64
    80005884:	ffffb097          	auipc	ra,0xffffb
    80005888:	448080e7          	jalr	1096(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000588c:	4741                	li	a4,16
    8000588e:	f2c42683          	lw	a3,-212(s0)
    80005892:	fc040613          	addi	a2,s0,-64
    80005896:	4581                	li	a1,0
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	530080e7          	jalr	1328(ra) # 80003dca <writei>
    800058a2:	47c1                	li	a5,16
    800058a4:	0af51563          	bne	a0,a5,8000594e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058a8:	04491703          	lh	a4,68(s2)
    800058ac:	4785                	li	a5,1
    800058ae:	0af70863          	beq	a4,a5,8000595e <sys_unlink+0x18c>
  iunlockput(dp);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	3cc080e7          	jalr	972(ra) # 80003c80 <iunlockput>
  ip->nlink--;
    800058bc:	04a95783          	lhu	a5,74(s2)
    800058c0:	37fd                	addiw	a5,a5,-1
    800058c2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058c6:	854a                	mv	a0,s2
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	08a080e7          	jalr	138(ra) # 80003952 <iupdate>
  iunlockput(ip);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	3ae080e7          	jalr	942(ra) # 80003c80 <iunlockput>
  end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	b9e080e7          	jalr	-1122(ra) # 80004478 <end_op>
  return 0;
    800058e2:	4501                	li	a0,0
    800058e4:	a84d                	j	80005996 <sys_unlink+0x1c4>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	b92080e7          	jalr	-1134(ra) # 80004478 <end_op>
    return -1;
    800058ee:	557d                	li	a0,-1
    800058f0:	a05d                	j	80005996 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058f2:	00003517          	auipc	a0,0x3
    800058f6:	e5650513          	addi	a0,a0,-426 # 80008748 <syscalls+0x300>
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	c40080e7          	jalr	-960(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005902:	04c92703          	lw	a4,76(s2)
    80005906:	02000793          	li	a5,32
    8000590a:	f6e7f9e3          	bgeu	a5,a4,8000587c <sys_unlink+0xaa>
    8000590e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005912:	4741                	li	a4,16
    80005914:	86ce                	mv	a3,s3
    80005916:	f1840613          	addi	a2,s0,-232
    8000591a:	4581                	li	a1,0
    8000591c:	854a                	mv	a0,s2
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	3b4080e7          	jalr	948(ra) # 80003cd2 <readi>
    80005926:	47c1                	li	a5,16
    80005928:	00f51b63          	bne	a0,a5,8000593e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000592c:	f1845783          	lhu	a5,-232(s0)
    80005930:	e7a1                	bnez	a5,80005978 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005932:	29c1                	addiw	s3,s3,16
    80005934:	04c92783          	lw	a5,76(s2)
    80005938:	fcf9ede3          	bltu	s3,a5,80005912 <sys_unlink+0x140>
    8000593c:	b781                	j	8000587c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000593e:	00003517          	auipc	a0,0x3
    80005942:	e2250513          	addi	a0,a0,-478 # 80008760 <syscalls+0x318>
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	bf4080e7          	jalr	-1036(ra) # 8000053a <panic>
    panic("unlink: writei");
    8000594e:	00003517          	auipc	a0,0x3
    80005952:	e2a50513          	addi	a0,a0,-470 # 80008778 <syscalls+0x330>
    80005956:	ffffb097          	auipc	ra,0xffffb
    8000595a:	be4080e7          	jalr	-1052(ra) # 8000053a <panic>
    dp->nlink--;
    8000595e:	04a4d783          	lhu	a5,74(s1)
    80005962:	37fd                	addiw	a5,a5,-1
    80005964:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	fe8080e7          	jalr	-24(ra) # 80003952 <iupdate>
    80005972:	b781                	j	800058b2 <sys_unlink+0xe0>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	a005                	j	80005996 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005978:	854a                	mv	a0,s2
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	306080e7          	jalr	774(ra) # 80003c80 <iunlockput>
  iunlockput(dp);
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	2fc080e7          	jalr	764(ra) # 80003c80 <iunlockput>
  end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	aec080e7          	jalr	-1300(ra) # 80004478 <end_op>
  return -1;
    80005994:	557d                	li	a0,-1
}
    80005996:	70ae                	ld	ra,232(sp)
    80005998:	740e                	ld	s0,224(sp)
    8000599a:	64ee                	ld	s1,216(sp)
    8000599c:	694e                	ld	s2,208(sp)
    8000599e:	69ae                	ld	s3,200(sp)
    800059a0:	616d                	addi	sp,sp,240
    800059a2:	8082                	ret

00000000800059a4 <sys_open>:

uint64
sys_open(void)
{
    800059a4:	7131                	addi	sp,sp,-192
    800059a6:	fd06                	sd	ra,184(sp)
    800059a8:	f922                	sd	s0,176(sp)
    800059aa:	f526                	sd	s1,168(sp)
    800059ac:	f14a                	sd	s2,160(sp)
    800059ae:	ed4e                	sd	s3,152(sp)
    800059b0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059b2:	08000613          	li	a2,128
    800059b6:	f5040593          	addi	a1,s0,-176
    800059ba:	4501                	li	a0,0
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	452080e7          	jalr	1106(ra) # 80002e0e <argstr>
    return -1;
    800059c4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059c6:	0c054163          	bltz	a0,80005a88 <sys_open+0xe4>
    800059ca:	f4c40593          	addi	a1,s0,-180
    800059ce:	4505                	li	a0,1
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	3fa080e7          	jalr	1018(ra) # 80002dca <argint>
    800059d8:	0a054863          	bltz	a0,80005a88 <sys_open+0xe4>

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	a1e080e7          	jalr	-1506(ra) # 800043fa <begin_op>

  if(omode & O_CREATE){
    800059e4:	f4c42783          	lw	a5,-180(s0)
    800059e8:	2007f793          	andi	a5,a5,512
    800059ec:	cbdd                	beqz	a5,80005aa2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059ee:	4681                	li	a3,0
    800059f0:	4601                	li	a2,0
    800059f2:	4589                	li	a1,2
    800059f4:	f5040513          	addi	a0,s0,-176
    800059f8:	00000097          	auipc	ra,0x0
    800059fc:	970080e7          	jalr	-1680(ra) # 80005368 <create>
    80005a00:	892a                	mv	s2,a0
    if(ip == 0){
    80005a02:	c959                	beqz	a0,80005a98 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a04:	04491703          	lh	a4,68(s2)
    80005a08:	478d                	li	a5,3
    80005a0a:	00f71763          	bne	a4,a5,80005a18 <sys_open+0x74>
    80005a0e:	04695703          	lhu	a4,70(s2)
    80005a12:	47a5                	li	a5,9
    80005a14:	0ce7ec63          	bltu	a5,a4,80005aec <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	dee080e7          	jalr	-530(ra) # 80004806 <filealloc>
    80005a20:	89aa                	mv	s3,a0
    80005a22:	10050263          	beqz	a0,80005b26 <sys_open+0x182>
    80005a26:	00000097          	auipc	ra,0x0
    80005a2a:	900080e7          	jalr	-1792(ra) # 80005326 <fdalloc>
    80005a2e:	84aa                	mv	s1,a0
    80005a30:	0e054663          	bltz	a0,80005b1c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a34:	04491703          	lh	a4,68(s2)
    80005a38:	478d                	li	a5,3
    80005a3a:	0cf70463          	beq	a4,a5,80005b02 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a3e:	4789                	li	a5,2
    80005a40:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a44:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a48:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a4c:	f4c42783          	lw	a5,-180(s0)
    80005a50:	0017c713          	xori	a4,a5,1
    80005a54:	8b05                	andi	a4,a4,1
    80005a56:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a5a:	0037f713          	andi	a4,a5,3
    80005a5e:	00e03733          	snez	a4,a4
    80005a62:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a66:	4007f793          	andi	a5,a5,1024
    80005a6a:	c791                	beqz	a5,80005a76 <sys_open+0xd2>
    80005a6c:	04491703          	lh	a4,68(s2)
    80005a70:	4789                	li	a5,2
    80005a72:	08f70f63          	beq	a4,a5,80005b10 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a76:	854a                	mv	a0,s2
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	068080e7          	jalr	104(ra) # 80003ae0 <iunlock>
  end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	9f8080e7          	jalr	-1544(ra) # 80004478 <end_op>

  return fd;
}
    80005a88:	8526                	mv	a0,s1
    80005a8a:	70ea                	ld	ra,184(sp)
    80005a8c:	744a                	ld	s0,176(sp)
    80005a8e:	74aa                	ld	s1,168(sp)
    80005a90:	790a                	ld	s2,160(sp)
    80005a92:	69ea                	ld	s3,152(sp)
    80005a94:	6129                	addi	sp,sp,192
    80005a96:	8082                	ret
      end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	9e0080e7          	jalr	-1568(ra) # 80004478 <end_op>
      return -1;
    80005aa0:	b7e5                	j	80005a88 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005aa2:	f5040513          	addi	a0,s0,-176
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	734080e7          	jalr	1844(ra) # 800041da <namei>
    80005aae:	892a                	mv	s2,a0
    80005ab0:	c905                	beqz	a0,80005ae0 <sys_open+0x13c>
    ilock(ip);
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	f6c080e7          	jalr	-148(ra) # 80003a1e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005aba:	04491703          	lh	a4,68(s2)
    80005abe:	4785                	li	a5,1
    80005ac0:	f4f712e3          	bne	a4,a5,80005a04 <sys_open+0x60>
    80005ac4:	f4c42783          	lw	a5,-180(s0)
    80005ac8:	dba1                	beqz	a5,80005a18 <sys_open+0x74>
      iunlockput(ip);
    80005aca:	854a                	mv	a0,s2
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	1b4080e7          	jalr	436(ra) # 80003c80 <iunlockput>
      end_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	9a4080e7          	jalr	-1628(ra) # 80004478 <end_op>
      return -1;
    80005adc:	54fd                	li	s1,-1
    80005ade:	b76d                	j	80005a88 <sys_open+0xe4>
      end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	998080e7          	jalr	-1640(ra) # 80004478 <end_op>
      return -1;
    80005ae8:	54fd                	li	s1,-1
    80005aea:	bf79                	j	80005a88 <sys_open+0xe4>
    iunlockput(ip);
    80005aec:	854a                	mv	a0,s2
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	192080e7          	jalr	402(ra) # 80003c80 <iunlockput>
    end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	982080e7          	jalr	-1662(ra) # 80004478 <end_op>
    return -1;
    80005afe:	54fd                	li	s1,-1
    80005b00:	b761                	j	80005a88 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b02:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b06:	04691783          	lh	a5,70(s2)
    80005b0a:	02f99223          	sh	a5,36(s3)
    80005b0e:	bf2d                	j	80005a48 <sys_open+0xa4>
    itrunc(ip);
    80005b10:	854a                	mv	a0,s2
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	01a080e7          	jalr	26(ra) # 80003b2c <itrunc>
    80005b1a:	bfb1                	j	80005a76 <sys_open+0xd2>
      fileclose(f);
    80005b1c:	854e                	mv	a0,s3
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	da4080e7          	jalr	-604(ra) # 800048c2 <fileclose>
    iunlockput(ip);
    80005b26:	854a                	mv	a0,s2
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	158080e7          	jalr	344(ra) # 80003c80 <iunlockput>
    end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	948080e7          	jalr	-1720(ra) # 80004478 <end_op>
    return -1;
    80005b38:	54fd                	li	s1,-1
    80005b3a:	b7b9                	j	80005a88 <sys_open+0xe4>

0000000080005b3c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b3c:	7175                	addi	sp,sp,-144
    80005b3e:	e506                	sd	ra,136(sp)
    80005b40:	e122                	sd	s0,128(sp)
    80005b42:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	8b6080e7          	jalr	-1866(ra) # 800043fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b4c:	08000613          	li	a2,128
    80005b50:	f7040593          	addi	a1,s0,-144
    80005b54:	4501                	li	a0,0
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	2b8080e7          	jalr	696(ra) # 80002e0e <argstr>
    80005b5e:	02054963          	bltz	a0,80005b90 <sys_mkdir+0x54>
    80005b62:	4681                	li	a3,0
    80005b64:	4601                	li	a2,0
    80005b66:	4585                	li	a1,1
    80005b68:	f7040513          	addi	a0,s0,-144
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	7fc080e7          	jalr	2044(ra) # 80005368 <create>
    80005b74:	cd11                	beqz	a0,80005b90 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	10a080e7          	jalr	266(ra) # 80003c80 <iunlockput>
  end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	8fa080e7          	jalr	-1798(ra) # 80004478 <end_op>
  return 0;
    80005b86:	4501                	li	a0,0
}
    80005b88:	60aa                	ld	ra,136(sp)
    80005b8a:	640a                	ld	s0,128(sp)
    80005b8c:	6149                	addi	sp,sp,144
    80005b8e:	8082                	ret
    end_op();
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	8e8080e7          	jalr	-1816(ra) # 80004478 <end_op>
    return -1;
    80005b98:	557d                	li	a0,-1
    80005b9a:	b7fd                	j	80005b88 <sys_mkdir+0x4c>

0000000080005b9c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b9c:	7135                	addi	sp,sp,-160
    80005b9e:	ed06                	sd	ra,152(sp)
    80005ba0:	e922                	sd	s0,144(sp)
    80005ba2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	856080e7          	jalr	-1962(ra) # 800043fa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bac:	08000613          	li	a2,128
    80005bb0:	f7040593          	addi	a1,s0,-144
    80005bb4:	4501                	li	a0,0
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	258080e7          	jalr	600(ra) # 80002e0e <argstr>
    80005bbe:	04054a63          	bltz	a0,80005c12 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bc2:	f6c40593          	addi	a1,s0,-148
    80005bc6:	4505                	li	a0,1
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	202080e7          	jalr	514(ra) # 80002dca <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bd0:	04054163          	bltz	a0,80005c12 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bd4:	f6840593          	addi	a1,s0,-152
    80005bd8:	4509                	li	a0,2
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	1f0080e7          	jalr	496(ra) # 80002dca <argint>
     argint(1, &major) < 0 ||
    80005be2:	02054863          	bltz	a0,80005c12 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005be6:	f6841683          	lh	a3,-152(s0)
    80005bea:	f6c41603          	lh	a2,-148(s0)
    80005bee:	458d                	li	a1,3
    80005bf0:	f7040513          	addi	a0,s0,-144
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	774080e7          	jalr	1908(ra) # 80005368 <create>
     argint(2, &minor) < 0 ||
    80005bfc:	c919                	beqz	a0,80005c12 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	082080e7          	jalr	130(ra) # 80003c80 <iunlockput>
  end_op();
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	872080e7          	jalr	-1934(ra) # 80004478 <end_op>
  return 0;
    80005c0e:	4501                	li	a0,0
    80005c10:	a031                	j	80005c1c <sys_mknod+0x80>
    end_op();
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	866080e7          	jalr	-1946(ra) # 80004478 <end_op>
    return -1;
    80005c1a:	557d                	li	a0,-1
}
    80005c1c:	60ea                	ld	ra,152(sp)
    80005c1e:	644a                	ld	s0,144(sp)
    80005c20:	610d                	addi	sp,sp,160
    80005c22:	8082                	ret

0000000080005c24 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c24:	7135                	addi	sp,sp,-160
    80005c26:	ed06                	sd	ra,152(sp)
    80005c28:	e922                	sd	s0,144(sp)
    80005c2a:	e526                	sd	s1,136(sp)
    80005c2c:	e14a                	sd	s2,128(sp)
    80005c2e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	d66080e7          	jalr	-666(ra) # 80001996 <myproc>
    80005c38:	892a                	mv	s2,a0
  
  begin_op();
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	7c0080e7          	jalr	1984(ra) # 800043fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c42:	08000613          	li	a2,128
    80005c46:	f6040593          	addi	a1,s0,-160
    80005c4a:	4501                	li	a0,0
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	1c2080e7          	jalr	450(ra) # 80002e0e <argstr>
    80005c54:	04054b63          	bltz	a0,80005caa <sys_chdir+0x86>
    80005c58:	f6040513          	addi	a0,s0,-160
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	57e080e7          	jalr	1406(ra) # 800041da <namei>
    80005c64:	84aa                	mv	s1,a0
    80005c66:	c131                	beqz	a0,80005caa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	db6080e7          	jalr	-586(ra) # 80003a1e <ilock>
  if(ip->type != T_DIR){
    80005c70:	04449703          	lh	a4,68(s1)
    80005c74:	4785                	li	a5,1
    80005c76:	04f71063          	bne	a4,a5,80005cb6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	e64080e7          	jalr	-412(ra) # 80003ae0 <iunlock>
  iput(p->cwd);
    80005c84:	15893503          	ld	a0,344(s2)
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	f50080e7          	jalr	-176(ra) # 80003bd8 <iput>
  end_op();
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	7e8080e7          	jalr	2024(ra) # 80004478 <end_op>
  p->cwd = ip;
    80005c98:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c9c:	4501                	li	a0,0
}
    80005c9e:	60ea                	ld	ra,152(sp)
    80005ca0:	644a                	ld	s0,144(sp)
    80005ca2:	64aa                	ld	s1,136(sp)
    80005ca4:	690a                	ld	s2,128(sp)
    80005ca6:	610d                	addi	sp,sp,160
    80005ca8:	8082                	ret
    end_op();
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	7ce080e7          	jalr	1998(ra) # 80004478 <end_op>
    return -1;
    80005cb2:	557d                	li	a0,-1
    80005cb4:	b7ed                	j	80005c9e <sys_chdir+0x7a>
    iunlockput(ip);
    80005cb6:	8526                	mv	a0,s1
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	fc8080e7          	jalr	-56(ra) # 80003c80 <iunlockput>
    end_op();
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	7b8080e7          	jalr	1976(ra) # 80004478 <end_op>
    return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	bfd1                	j	80005c9e <sys_chdir+0x7a>

0000000080005ccc <sys_exec>:

uint64
sys_exec(void)
{
    80005ccc:	7145                	addi	sp,sp,-464
    80005cce:	e786                	sd	ra,456(sp)
    80005cd0:	e3a2                	sd	s0,448(sp)
    80005cd2:	ff26                	sd	s1,440(sp)
    80005cd4:	fb4a                	sd	s2,432(sp)
    80005cd6:	f74e                	sd	s3,424(sp)
    80005cd8:	f352                	sd	s4,416(sp)
    80005cda:	ef56                	sd	s5,408(sp)
    80005cdc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cde:	08000613          	li	a2,128
    80005ce2:	f4040593          	addi	a1,s0,-192
    80005ce6:	4501                	li	a0,0
    80005ce8:	ffffd097          	auipc	ra,0xffffd
    80005cec:	126080e7          	jalr	294(ra) # 80002e0e <argstr>
    return -1;
    80005cf0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cf2:	0c054b63          	bltz	a0,80005dc8 <sys_exec+0xfc>
    80005cf6:	e3840593          	addi	a1,s0,-456
    80005cfa:	4505                	li	a0,1
    80005cfc:	ffffd097          	auipc	ra,0xffffd
    80005d00:	0f0080e7          	jalr	240(ra) # 80002dec <argaddr>
    80005d04:	0c054263          	bltz	a0,80005dc8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005d08:	10000613          	li	a2,256
    80005d0c:	4581                	li	a1,0
    80005d0e:	e4040513          	addi	a0,s0,-448
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	fba080e7          	jalr	-70(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d1a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d1e:	89a6                	mv	s3,s1
    80005d20:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d22:	02000a13          	li	s4,32
    80005d26:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d2a:	00391513          	slli	a0,s2,0x3
    80005d2e:	e3040593          	addi	a1,s0,-464
    80005d32:	e3843783          	ld	a5,-456(s0)
    80005d36:	953e                	add	a0,a0,a5
    80005d38:	ffffd097          	auipc	ra,0xffffd
    80005d3c:	ff8080e7          	jalr	-8(ra) # 80002d30 <fetchaddr>
    80005d40:	02054a63          	bltz	a0,80005d74 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d44:	e3043783          	ld	a5,-464(s0)
    80005d48:	c3b9                	beqz	a5,80005d8e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d4a:	ffffb097          	auipc	ra,0xffffb
    80005d4e:	d96080e7          	jalr	-618(ra) # 80000ae0 <kalloc>
    80005d52:	85aa                	mv	a1,a0
    80005d54:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d58:	cd11                	beqz	a0,80005d74 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d5a:	6605                	lui	a2,0x1
    80005d5c:	e3043503          	ld	a0,-464(s0)
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	022080e7          	jalr	34(ra) # 80002d82 <fetchstr>
    80005d68:	00054663          	bltz	a0,80005d74 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d6c:	0905                	addi	s2,s2,1
    80005d6e:	09a1                	addi	s3,s3,8
    80005d70:	fb491be3          	bne	s2,s4,80005d26 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d74:	f4040913          	addi	s2,s0,-192
    80005d78:	6088                	ld	a0,0(s1)
    80005d7a:	c531                	beqz	a0,80005dc6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d7c:	ffffb097          	auipc	ra,0xffffb
    80005d80:	c66080e7          	jalr	-922(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d84:	04a1                	addi	s1,s1,8
    80005d86:	ff2499e3          	bne	s1,s2,80005d78 <sys_exec+0xac>
  return -1;
    80005d8a:	597d                	li	s2,-1
    80005d8c:	a835                	j	80005dc8 <sys_exec+0xfc>
      argv[i] = 0;
    80005d8e:	0a8e                	slli	s5,s5,0x3
    80005d90:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005d94:	00878ab3          	add	s5,a5,s0
    80005d98:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d9c:	e4040593          	addi	a1,s0,-448
    80005da0:	f4040513          	addi	a0,s0,-192
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	172080e7          	jalr	370(ra) # 80004f16 <exec>
    80005dac:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dae:	f4040993          	addi	s3,s0,-192
    80005db2:	6088                	ld	a0,0(s1)
    80005db4:	c911                	beqz	a0,80005dc8 <sys_exec+0xfc>
    kfree(argv[i]);
    80005db6:	ffffb097          	auipc	ra,0xffffb
    80005dba:	c2c080e7          	jalr	-980(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dbe:	04a1                	addi	s1,s1,8
    80005dc0:	ff3499e3          	bne	s1,s3,80005db2 <sys_exec+0xe6>
    80005dc4:	a011                	j	80005dc8 <sys_exec+0xfc>
  return -1;
    80005dc6:	597d                	li	s2,-1
}
    80005dc8:	854a                	mv	a0,s2
    80005dca:	60be                	ld	ra,456(sp)
    80005dcc:	641e                	ld	s0,448(sp)
    80005dce:	74fa                	ld	s1,440(sp)
    80005dd0:	795a                	ld	s2,432(sp)
    80005dd2:	79ba                	ld	s3,424(sp)
    80005dd4:	7a1a                	ld	s4,416(sp)
    80005dd6:	6afa                	ld	s5,408(sp)
    80005dd8:	6179                	addi	sp,sp,464
    80005dda:	8082                	ret

0000000080005ddc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ddc:	7139                	addi	sp,sp,-64
    80005dde:	fc06                	sd	ra,56(sp)
    80005de0:	f822                	sd	s0,48(sp)
    80005de2:	f426                	sd	s1,40(sp)
    80005de4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005de6:	ffffc097          	auipc	ra,0xffffc
    80005dea:	bb0080e7          	jalr	-1104(ra) # 80001996 <myproc>
    80005dee:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005df0:	fd840593          	addi	a1,s0,-40
    80005df4:	4501                	li	a0,0
    80005df6:	ffffd097          	auipc	ra,0xffffd
    80005dfa:	ff6080e7          	jalr	-10(ra) # 80002dec <argaddr>
    return -1;
    80005dfe:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e00:	0e054063          	bltz	a0,80005ee0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e04:	fc840593          	addi	a1,s0,-56
    80005e08:	fd040513          	addi	a0,s0,-48
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	de6080e7          	jalr	-538(ra) # 80004bf2 <pipealloc>
    return -1;
    80005e14:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e16:	0c054563          	bltz	a0,80005ee0 <sys_pipe+0x104>
  fd0 = -1;
    80005e1a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e1e:	fd043503          	ld	a0,-48(s0)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	504080e7          	jalr	1284(ra) # 80005326 <fdalloc>
    80005e2a:	fca42223          	sw	a0,-60(s0)
    80005e2e:	08054c63          	bltz	a0,80005ec6 <sys_pipe+0xea>
    80005e32:	fc843503          	ld	a0,-56(s0)
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	4f0080e7          	jalr	1264(ra) # 80005326 <fdalloc>
    80005e3e:	fca42023          	sw	a0,-64(s0)
    80005e42:	06054963          	bltz	a0,80005eb4 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e46:	4691                	li	a3,4
    80005e48:	fc440613          	addi	a2,s0,-60
    80005e4c:	fd843583          	ld	a1,-40(s0)
    80005e50:	6ca8                	ld	a0,88(s1)
    80005e52:	ffffc097          	auipc	ra,0xffffc
    80005e56:	808080e7          	jalr	-2040(ra) # 8000165a <copyout>
    80005e5a:	02054063          	bltz	a0,80005e7a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e5e:	4691                	li	a3,4
    80005e60:	fc040613          	addi	a2,s0,-64
    80005e64:	fd843583          	ld	a1,-40(s0)
    80005e68:	0591                	addi	a1,a1,4
    80005e6a:	6ca8                	ld	a0,88(s1)
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	7ee080e7          	jalr	2030(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e74:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e76:	06055563          	bgez	a0,80005ee0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e7a:	fc442783          	lw	a5,-60(s0)
    80005e7e:	07e9                	addi	a5,a5,26
    80005e80:	078e                	slli	a5,a5,0x3
    80005e82:	97a6                	add	a5,a5,s1
    80005e84:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e88:	fc042783          	lw	a5,-64(s0)
    80005e8c:	07e9                	addi	a5,a5,26
    80005e8e:	078e                	slli	a5,a5,0x3
    80005e90:	00f48533          	add	a0,s1,a5
    80005e94:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e98:	fd043503          	ld	a0,-48(s0)
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	a26080e7          	jalr	-1498(ra) # 800048c2 <fileclose>
    fileclose(wf);
    80005ea4:	fc843503          	ld	a0,-56(s0)
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	a1a080e7          	jalr	-1510(ra) # 800048c2 <fileclose>
    return -1;
    80005eb0:	57fd                	li	a5,-1
    80005eb2:	a03d                	j	80005ee0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005eb4:	fc442783          	lw	a5,-60(s0)
    80005eb8:	0007c763          	bltz	a5,80005ec6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ebc:	07e9                	addi	a5,a5,26
    80005ebe:	078e                	slli	a5,a5,0x3
    80005ec0:	97a6                	add	a5,a5,s1
    80005ec2:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005ec6:	fd043503          	ld	a0,-48(s0)
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	9f8080e7          	jalr	-1544(ra) # 800048c2 <fileclose>
    fileclose(wf);
    80005ed2:	fc843503          	ld	a0,-56(s0)
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	9ec080e7          	jalr	-1556(ra) # 800048c2 <fileclose>
    return -1;
    80005ede:	57fd                	li	a5,-1
}
    80005ee0:	853e                	mv	a0,a5
    80005ee2:	70e2                	ld	ra,56(sp)
    80005ee4:	7442                	ld	s0,48(sp)
    80005ee6:	74a2                	ld	s1,40(sp)
    80005ee8:	6121                	addi	sp,sp,64
    80005eea:	8082                	ret
    80005eec:	0000                	unimp
	...

0000000080005ef0 <kernelvec>:
    80005ef0:	7111                	addi	sp,sp,-256
    80005ef2:	e006                	sd	ra,0(sp)
    80005ef4:	e40a                	sd	sp,8(sp)
    80005ef6:	e80e                	sd	gp,16(sp)
    80005ef8:	ec12                	sd	tp,24(sp)
    80005efa:	f016                	sd	t0,32(sp)
    80005efc:	f41a                	sd	t1,40(sp)
    80005efe:	f81e                	sd	t2,48(sp)
    80005f00:	fc22                	sd	s0,56(sp)
    80005f02:	e0a6                	sd	s1,64(sp)
    80005f04:	e4aa                	sd	a0,72(sp)
    80005f06:	e8ae                	sd	a1,80(sp)
    80005f08:	ecb2                	sd	a2,88(sp)
    80005f0a:	f0b6                	sd	a3,96(sp)
    80005f0c:	f4ba                	sd	a4,104(sp)
    80005f0e:	f8be                	sd	a5,112(sp)
    80005f10:	fcc2                	sd	a6,120(sp)
    80005f12:	e146                	sd	a7,128(sp)
    80005f14:	e54a                	sd	s2,136(sp)
    80005f16:	e94e                	sd	s3,144(sp)
    80005f18:	ed52                	sd	s4,152(sp)
    80005f1a:	f156                	sd	s5,160(sp)
    80005f1c:	f55a                	sd	s6,168(sp)
    80005f1e:	f95e                	sd	s7,176(sp)
    80005f20:	fd62                	sd	s8,184(sp)
    80005f22:	e1e6                	sd	s9,192(sp)
    80005f24:	e5ea                	sd	s10,200(sp)
    80005f26:	e9ee                	sd	s11,208(sp)
    80005f28:	edf2                	sd	t3,216(sp)
    80005f2a:	f1f6                	sd	t4,224(sp)
    80005f2c:	f5fa                	sd	t5,232(sp)
    80005f2e:	f9fe                	sd	t6,240(sp)
    80005f30:	cbffc0ef          	jal	ra,80002bee <kerneltrap>
    80005f34:	6082                	ld	ra,0(sp)
    80005f36:	6122                	ld	sp,8(sp)
    80005f38:	61c2                	ld	gp,16(sp)
    80005f3a:	7282                	ld	t0,32(sp)
    80005f3c:	7322                	ld	t1,40(sp)
    80005f3e:	73c2                	ld	t2,48(sp)
    80005f40:	7462                	ld	s0,56(sp)
    80005f42:	6486                	ld	s1,64(sp)
    80005f44:	6526                	ld	a0,72(sp)
    80005f46:	65c6                	ld	a1,80(sp)
    80005f48:	6666                	ld	a2,88(sp)
    80005f4a:	7686                	ld	a3,96(sp)
    80005f4c:	7726                	ld	a4,104(sp)
    80005f4e:	77c6                	ld	a5,112(sp)
    80005f50:	7866                	ld	a6,120(sp)
    80005f52:	688a                	ld	a7,128(sp)
    80005f54:	692a                	ld	s2,136(sp)
    80005f56:	69ca                	ld	s3,144(sp)
    80005f58:	6a6a                	ld	s4,152(sp)
    80005f5a:	7a8a                	ld	s5,160(sp)
    80005f5c:	7b2a                	ld	s6,168(sp)
    80005f5e:	7bca                	ld	s7,176(sp)
    80005f60:	7c6a                	ld	s8,184(sp)
    80005f62:	6c8e                	ld	s9,192(sp)
    80005f64:	6d2e                	ld	s10,200(sp)
    80005f66:	6dce                	ld	s11,208(sp)
    80005f68:	6e6e                	ld	t3,216(sp)
    80005f6a:	7e8e                	ld	t4,224(sp)
    80005f6c:	7f2e                	ld	t5,232(sp)
    80005f6e:	7fce                	ld	t6,240(sp)
    80005f70:	6111                	addi	sp,sp,256
    80005f72:	10200073          	sret
    80005f76:	00000013          	nop
    80005f7a:	00000013          	nop
    80005f7e:	0001                	nop

0000000080005f80 <timervec>:
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	e10c                	sd	a1,0(a0)
    80005f86:	e510                	sd	a2,8(a0)
    80005f88:	e914                	sd	a3,16(a0)
    80005f8a:	6d0c                	ld	a1,24(a0)
    80005f8c:	7110                	ld	a2,32(a0)
    80005f8e:	6194                	ld	a3,0(a1)
    80005f90:	96b2                	add	a3,a3,a2
    80005f92:	e194                	sd	a3,0(a1)
    80005f94:	4589                	li	a1,2
    80005f96:	14459073          	csrw	sip,a1
    80005f9a:	6914                	ld	a3,16(a0)
    80005f9c:	6510                	ld	a2,8(a0)
    80005f9e:	610c                	ld	a1,0(a0)
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	30200073          	mret
	...

0000000080005faa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005faa:	1141                	addi	sp,sp,-16
    80005fac:	e422                	sd	s0,8(sp)
    80005fae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fb0:	0c0007b7          	lui	a5,0xc000
    80005fb4:	4705                	li	a4,1
    80005fb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fb8:	c3d8                	sw	a4,4(a5)
}
    80005fba:	6422                	ld	s0,8(sp)
    80005fbc:	0141                	addi	sp,sp,16
    80005fbe:	8082                	ret

0000000080005fc0 <plicinithart>:

void
plicinithart(void)
{
    80005fc0:	1141                	addi	sp,sp,-16
    80005fc2:	e406                	sd	ra,8(sp)
    80005fc4:	e022                	sd	s0,0(sp)
    80005fc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	9a2080e7          	jalr	-1630(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fd0:	0085171b          	slliw	a4,a0,0x8
    80005fd4:	0c0027b7          	lui	a5,0xc002
    80005fd8:	97ba                	add	a5,a5,a4
    80005fda:	40200713          	li	a4,1026
    80005fde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fe2:	00d5151b          	slliw	a0,a0,0xd
    80005fe6:	0c2017b7          	lui	a5,0xc201
    80005fea:	97aa                	add	a5,a5,a0
    80005fec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ff0:	60a2                	ld	ra,8(sp)
    80005ff2:	6402                	ld	s0,0(sp)
    80005ff4:	0141                	addi	sp,sp,16
    80005ff6:	8082                	ret

0000000080005ff8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ff8:	1141                	addi	sp,sp,-16
    80005ffa:	e406                	sd	ra,8(sp)
    80005ffc:	e022                	sd	s0,0(sp)
    80005ffe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006000:	ffffc097          	auipc	ra,0xffffc
    80006004:	96a080e7          	jalr	-1686(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006008:	00d5151b          	slliw	a0,a0,0xd
    8000600c:	0c2017b7          	lui	a5,0xc201
    80006010:	97aa                	add	a5,a5,a0
  return irq;
}
    80006012:	43c8                	lw	a0,4(a5)
    80006014:	60a2                	ld	ra,8(sp)
    80006016:	6402                	ld	s0,0(sp)
    80006018:	0141                	addi	sp,sp,16
    8000601a:	8082                	ret

000000008000601c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000601c:	1101                	addi	sp,sp,-32
    8000601e:	ec06                	sd	ra,24(sp)
    80006020:	e822                	sd	s0,16(sp)
    80006022:	e426                	sd	s1,8(sp)
    80006024:	1000                	addi	s0,sp,32
    80006026:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006028:	ffffc097          	auipc	ra,0xffffc
    8000602c:	942080e7          	jalr	-1726(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006030:	00d5151b          	slliw	a0,a0,0xd
    80006034:	0c2017b7          	lui	a5,0xc201
    80006038:	97aa                	add	a5,a5,a0
    8000603a:	c3c4                	sw	s1,4(a5)
}
    8000603c:	60e2                	ld	ra,24(sp)
    8000603e:	6442                	ld	s0,16(sp)
    80006040:	64a2                	ld	s1,8(sp)
    80006042:	6105                	addi	sp,sp,32
    80006044:	8082                	ret

0000000080006046 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006046:	1141                	addi	sp,sp,-16
    80006048:	e406                	sd	ra,8(sp)
    8000604a:	e022                	sd	s0,0(sp)
    8000604c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000604e:	479d                	li	a5,7
    80006050:	06a7c863          	blt	a5,a0,800060c0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006054:	0001d717          	auipc	a4,0x1d
    80006058:	fac70713          	addi	a4,a4,-84 # 80023000 <disk>
    8000605c:	972a                	add	a4,a4,a0
    8000605e:	6789                	lui	a5,0x2
    80006060:	97ba                	add	a5,a5,a4
    80006062:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006066:	e7ad                	bnez	a5,800060d0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006068:	00451793          	slli	a5,a0,0x4
    8000606c:	0001f717          	auipc	a4,0x1f
    80006070:	f9470713          	addi	a4,a4,-108 # 80025000 <disk+0x2000>
    80006074:	6314                	ld	a3,0(a4)
    80006076:	96be                	add	a3,a3,a5
    80006078:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000607c:	6314                	ld	a3,0(a4)
    8000607e:	96be                	add	a3,a3,a5
    80006080:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006084:	6314                	ld	a3,0(a4)
    80006086:	96be                	add	a3,a3,a5
    80006088:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000608c:	6318                	ld	a4,0(a4)
    8000608e:	97ba                	add	a5,a5,a4
    80006090:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006094:	0001d717          	auipc	a4,0x1d
    80006098:	f6c70713          	addi	a4,a4,-148 # 80023000 <disk>
    8000609c:	972a                	add	a4,a4,a0
    8000609e:	6789                	lui	a5,0x2
    800060a0:	97ba                	add	a5,a5,a4
    800060a2:	4705                	li	a4,1
    800060a4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060a8:	0001f517          	auipc	a0,0x1f
    800060ac:	f7050513          	addi	a0,a0,-144 # 80025018 <disk+0x2018>
    800060b0:	ffffc097          	auipc	ra,0xffffc
    800060b4:	32a080e7          	jalr	810(ra) # 800023da <wakeup>
}
    800060b8:	60a2                	ld	ra,8(sp)
    800060ba:	6402                	ld	s0,0(sp)
    800060bc:	0141                	addi	sp,sp,16
    800060be:	8082                	ret
    panic("free_desc 1");
    800060c0:	00002517          	auipc	a0,0x2
    800060c4:	6c850513          	addi	a0,a0,1736 # 80008788 <syscalls+0x340>
    800060c8:	ffffa097          	auipc	ra,0xffffa
    800060cc:	472080e7          	jalr	1138(ra) # 8000053a <panic>
    panic("free_desc 2");
    800060d0:	00002517          	auipc	a0,0x2
    800060d4:	6c850513          	addi	a0,a0,1736 # 80008798 <syscalls+0x350>
    800060d8:	ffffa097          	auipc	ra,0xffffa
    800060dc:	462080e7          	jalr	1122(ra) # 8000053a <panic>

00000000800060e0 <virtio_disk_init>:
{
    800060e0:	1101                	addi	sp,sp,-32
    800060e2:	ec06                	sd	ra,24(sp)
    800060e4:	e822                	sd	s0,16(sp)
    800060e6:	e426                	sd	s1,8(sp)
    800060e8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060ea:	00002597          	auipc	a1,0x2
    800060ee:	6be58593          	addi	a1,a1,1726 # 800087a8 <syscalls+0x360>
    800060f2:	0001f517          	auipc	a0,0x1f
    800060f6:	03650513          	addi	a0,a0,54 # 80025128 <disk+0x2128>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	a46080e7          	jalr	-1466(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006102:	100017b7          	lui	a5,0x10001
    80006106:	4398                	lw	a4,0(a5)
    80006108:	2701                	sext.w	a4,a4
    8000610a:	747277b7          	lui	a5,0x74727
    8000610e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006112:	0ef71063          	bne	a4,a5,800061f2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006116:	100017b7          	lui	a5,0x10001
    8000611a:	43dc                	lw	a5,4(a5)
    8000611c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000611e:	4705                	li	a4,1
    80006120:	0ce79963          	bne	a5,a4,800061f2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006124:	100017b7          	lui	a5,0x10001
    80006128:	479c                	lw	a5,8(a5)
    8000612a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000612c:	4709                	li	a4,2
    8000612e:	0ce79263          	bne	a5,a4,800061f2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006132:	100017b7          	lui	a5,0x10001
    80006136:	47d8                	lw	a4,12(a5)
    80006138:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000613a:	554d47b7          	lui	a5,0x554d4
    8000613e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006142:	0af71863          	bne	a4,a5,800061f2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006146:	100017b7          	lui	a5,0x10001
    8000614a:	4705                	li	a4,1
    8000614c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000614e:	470d                	li	a4,3
    80006150:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006152:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006154:	c7ffe6b7          	lui	a3,0xc7ffe
    80006158:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000615c:	8f75                	and	a4,a4,a3
    8000615e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006160:	472d                	li	a4,11
    80006162:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006164:	473d                	li	a4,15
    80006166:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006168:	6705                	lui	a4,0x1
    8000616a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000616c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006170:	5bdc                	lw	a5,52(a5)
    80006172:	2781                	sext.w	a5,a5
  if(max == 0)
    80006174:	c7d9                	beqz	a5,80006202 <virtio_disk_init+0x122>
  if(max < NUM)
    80006176:	471d                	li	a4,7
    80006178:	08f77d63          	bgeu	a4,a5,80006212 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000617c:	100014b7          	lui	s1,0x10001
    80006180:	47a1                	li	a5,8
    80006182:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006184:	6609                	lui	a2,0x2
    80006186:	4581                	li	a1,0
    80006188:	0001d517          	auipc	a0,0x1d
    8000618c:	e7850513          	addi	a0,a0,-392 # 80023000 <disk>
    80006190:	ffffb097          	auipc	ra,0xffffb
    80006194:	b3c080e7          	jalr	-1220(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006198:	0001d717          	auipc	a4,0x1d
    8000619c:	e6870713          	addi	a4,a4,-408 # 80023000 <disk>
    800061a0:	00c75793          	srli	a5,a4,0xc
    800061a4:	2781                	sext.w	a5,a5
    800061a6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800061a8:	0001f797          	auipc	a5,0x1f
    800061ac:	e5878793          	addi	a5,a5,-424 # 80025000 <disk+0x2000>
    800061b0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800061b2:	0001d717          	auipc	a4,0x1d
    800061b6:	ece70713          	addi	a4,a4,-306 # 80023080 <disk+0x80>
    800061ba:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061bc:	0001e717          	auipc	a4,0x1e
    800061c0:	e4470713          	addi	a4,a4,-444 # 80024000 <disk+0x1000>
    800061c4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061c6:	4705                	li	a4,1
    800061c8:	00e78c23          	sb	a4,24(a5)
    800061cc:	00e78ca3          	sb	a4,25(a5)
    800061d0:	00e78d23          	sb	a4,26(a5)
    800061d4:	00e78da3          	sb	a4,27(a5)
    800061d8:	00e78e23          	sb	a4,28(a5)
    800061dc:	00e78ea3          	sb	a4,29(a5)
    800061e0:	00e78f23          	sb	a4,30(a5)
    800061e4:	00e78fa3          	sb	a4,31(a5)
}
    800061e8:	60e2                	ld	ra,24(sp)
    800061ea:	6442                	ld	s0,16(sp)
    800061ec:	64a2                	ld	s1,8(sp)
    800061ee:	6105                	addi	sp,sp,32
    800061f0:	8082                	ret
    panic("could not find virtio disk");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	5c650513          	addi	a0,a0,1478 # 800087b8 <syscalls+0x370>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	340080e7          	jalr	832(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006202:	00002517          	auipc	a0,0x2
    80006206:	5d650513          	addi	a0,a0,1494 # 800087d8 <syscalls+0x390>
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	330080e7          	jalr	816(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006212:	00002517          	auipc	a0,0x2
    80006216:	5e650513          	addi	a0,a0,1510 # 800087f8 <syscalls+0x3b0>
    8000621a:	ffffa097          	auipc	ra,0xffffa
    8000621e:	320080e7          	jalr	800(ra) # 8000053a <panic>

0000000080006222 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006222:	7119                	addi	sp,sp,-128
    80006224:	fc86                	sd	ra,120(sp)
    80006226:	f8a2                	sd	s0,112(sp)
    80006228:	f4a6                	sd	s1,104(sp)
    8000622a:	f0ca                	sd	s2,96(sp)
    8000622c:	ecce                	sd	s3,88(sp)
    8000622e:	e8d2                	sd	s4,80(sp)
    80006230:	e4d6                	sd	s5,72(sp)
    80006232:	e0da                	sd	s6,64(sp)
    80006234:	fc5e                	sd	s7,56(sp)
    80006236:	f862                	sd	s8,48(sp)
    80006238:	f466                	sd	s9,40(sp)
    8000623a:	f06a                	sd	s10,32(sp)
    8000623c:	ec6e                	sd	s11,24(sp)
    8000623e:	0100                	addi	s0,sp,128
    80006240:	8aaa                	mv	s5,a0
    80006242:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006244:	00c52c83          	lw	s9,12(a0)
    80006248:	001c9c9b          	slliw	s9,s9,0x1
    8000624c:	1c82                	slli	s9,s9,0x20
    8000624e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006252:	0001f517          	auipc	a0,0x1f
    80006256:	ed650513          	addi	a0,a0,-298 # 80025128 <disk+0x2128>
    8000625a:	ffffb097          	auipc	ra,0xffffb
    8000625e:	976080e7          	jalr	-1674(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006262:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006264:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006266:	0001dc17          	auipc	s8,0x1d
    8000626a:	d9ac0c13          	addi	s8,s8,-614 # 80023000 <disk>
    8000626e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006270:	4b0d                	li	s6,3
    80006272:	a0ad                	j	800062dc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006274:	00fc0733          	add	a4,s8,a5
    80006278:	975e                	add	a4,a4,s7
    8000627a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000627e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006280:	0207c563          	bltz	a5,800062aa <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006284:	2905                	addiw	s2,s2,1
    80006286:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006288:	19690c63          	beq	s2,s6,80006420 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000628c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000628e:	0001f717          	auipc	a4,0x1f
    80006292:	d8a70713          	addi	a4,a4,-630 # 80025018 <disk+0x2018>
    80006296:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006298:	00074683          	lbu	a3,0(a4)
    8000629c:	fee1                	bnez	a3,80006274 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000629e:	2785                	addiw	a5,a5,1
    800062a0:	0705                	addi	a4,a4,1
    800062a2:	fe979be3          	bne	a5,s1,80006298 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062a6:	57fd                	li	a5,-1
    800062a8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062aa:	01205d63          	blez	s2,800062c4 <virtio_disk_rw+0xa2>
    800062ae:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062b0:	000a2503          	lw	a0,0(s4)
    800062b4:	00000097          	auipc	ra,0x0
    800062b8:	d92080e7          	jalr	-622(ra) # 80006046 <free_desc>
      for(int j = 0; j < i; j++)
    800062bc:	2d85                	addiw	s11,s11,1
    800062be:	0a11                	addi	s4,s4,4
    800062c0:	ff2d98e3          	bne	s11,s2,800062b0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062c4:	0001f597          	auipc	a1,0x1f
    800062c8:	e6458593          	addi	a1,a1,-412 # 80025128 <disk+0x2128>
    800062cc:	0001f517          	auipc	a0,0x1f
    800062d0:	d4c50513          	addi	a0,a0,-692 # 80025018 <disk+0x2018>
    800062d4:	ffffc097          	auipc	ra,0xffffc
    800062d8:	e0c080e7          	jalr	-500(ra) # 800020e0 <sleep>
  for(int i = 0; i < 3; i++){
    800062dc:	f8040a13          	addi	s4,s0,-128
{
    800062e0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062e2:	894e                	mv	s2,s3
    800062e4:	b765                	j	8000628c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062e6:	0001f697          	auipc	a3,0x1f
    800062ea:	d1a6b683          	ld	a3,-742(a3) # 80025000 <disk+0x2000>
    800062ee:	96ba                	add	a3,a3,a4
    800062f0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062f4:	0001d817          	auipc	a6,0x1d
    800062f8:	d0c80813          	addi	a6,a6,-756 # 80023000 <disk>
    800062fc:	0001f697          	auipc	a3,0x1f
    80006300:	d0468693          	addi	a3,a3,-764 # 80025000 <disk+0x2000>
    80006304:	6290                	ld	a2,0(a3)
    80006306:	963a                	add	a2,a2,a4
    80006308:	00c65583          	lhu	a1,12(a2)
    8000630c:	0015e593          	ori	a1,a1,1
    80006310:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006314:	f8842603          	lw	a2,-120(s0)
    80006318:	628c                	ld	a1,0(a3)
    8000631a:	972e                	add	a4,a4,a1
    8000631c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006320:	20050593          	addi	a1,a0,512
    80006324:	0592                	slli	a1,a1,0x4
    80006326:	95c2                	add	a1,a1,a6
    80006328:	577d                	li	a4,-1
    8000632a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000632e:	00461713          	slli	a4,a2,0x4
    80006332:	6290                	ld	a2,0(a3)
    80006334:	963a                	add	a2,a2,a4
    80006336:	03078793          	addi	a5,a5,48
    8000633a:	97c2                	add	a5,a5,a6
    8000633c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000633e:	629c                	ld	a5,0(a3)
    80006340:	97ba                	add	a5,a5,a4
    80006342:	4605                	li	a2,1
    80006344:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006346:	629c                	ld	a5,0(a3)
    80006348:	97ba                	add	a5,a5,a4
    8000634a:	4809                	li	a6,2
    8000634c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006350:	629c                	ld	a5,0(a3)
    80006352:	97ba                	add	a5,a5,a4
    80006354:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006358:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000635c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006360:	6698                	ld	a4,8(a3)
    80006362:	00275783          	lhu	a5,2(a4)
    80006366:	8b9d                	andi	a5,a5,7
    80006368:	0786                	slli	a5,a5,0x1
    8000636a:	973e                	add	a4,a4,a5
    8000636c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006370:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006374:	6698                	ld	a4,8(a3)
    80006376:	00275783          	lhu	a5,2(a4)
    8000637a:	2785                	addiw	a5,a5,1
    8000637c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006380:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006384:	100017b7          	lui	a5,0x10001
    80006388:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000638c:	004aa783          	lw	a5,4(s5)
    80006390:	02c79163          	bne	a5,a2,800063b2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006394:	0001f917          	auipc	s2,0x1f
    80006398:	d9490913          	addi	s2,s2,-620 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000639c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000639e:	85ca                	mv	a1,s2
    800063a0:	8556                	mv	a0,s5
    800063a2:	ffffc097          	auipc	ra,0xffffc
    800063a6:	d3e080e7          	jalr	-706(ra) # 800020e0 <sleep>
  while(b->disk == 1) {
    800063aa:	004aa783          	lw	a5,4(s5)
    800063ae:	fe9788e3          	beq	a5,s1,8000639e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800063b2:	f8042903          	lw	s2,-128(s0)
    800063b6:	20090713          	addi	a4,s2,512
    800063ba:	0712                	slli	a4,a4,0x4
    800063bc:	0001d797          	auipc	a5,0x1d
    800063c0:	c4478793          	addi	a5,a5,-956 # 80023000 <disk>
    800063c4:	97ba                	add	a5,a5,a4
    800063c6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063ca:	0001f997          	auipc	s3,0x1f
    800063ce:	c3698993          	addi	s3,s3,-970 # 80025000 <disk+0x2000>
    800063d2:	00491713          	slli	a4,s2,0x4
    800063d6:	0009b783          	ld	a5,0(s3)
    800063da:	97ba                	add	a5,a5,a4
    800063dc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063e0:	854a                	mv	a0,s2
    800063e2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063e6:	00000097          	auipc	ra,0x0
    800063ea:	c60080e7          	jalr	-928(ra) # 80006046 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063ee:	8885                	andi	s1,s1,1
    800063f0:	f0ed                	bnez	s1,800063d2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063f2:	0001f517          	auipc	a0,0x1f
    800063f6:	d3650513          	addi	a0,a0,-714 # 80025128 <disk+0x2128>
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	88a080e7          	jalr	-1910(ra) # 80000c84 <release>
}
    80006402:	70e6                	ld	ra,120(sp)
    80006404:	7446                	ld	s0,112(sp)
    80006406:	74a6                	ld	s1,104(sp)
    80006408:	7906                	ld	s2,96(sp)
    8000640a:	69e6                	ld	s3,88(sp)
    8000640c:	6a46                	ld	s4,80(sp)
    8000640e:	6aa6                	ld	s5,72(sp)
    80006410:	6b06                	ld	s6,64(sp)
    80006412:	7be2                	ld	s7,56(sp)
    80006414:	7c42                	ld	s8,48(sp)
    80006416:	7ca2                	ld	s9,40(sp)
    80006418:	7d02                	ld	s10,32(sp)
    8000641a:	6de2                	ld	s11,24(sp)
    8000641c:	6109                	addi	sp,sp,128
    8000641e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006420:	f8042503          	lw	a0,-128(s0)
    80006424:	20050793          	addi	a5,a0,512
    80006428:	0792                	slli	a5,a5,0x4
  if(write)
    8000642a:	0001d817          	auipc	a6,0x1d
    8000642e:	bd680813          	addi	a6,a6,-1066 # 80023000 <disk>
    80006432:	00f80733          	add	a4,a6,a5
    80006436:	01a036b3          	snez	a3,s10
    8000643a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000643e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006442:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006446:	7679                	lui	a2,0xffffe
    80006448:	963e                	add	a2,a2,a5
    8000644a:	0001f697          	auipc	a3,0x1f
    8000644e:	bb668693          	addi	a3,a3,-1098 # 80025000 <disk+0x2000>
    80006452:	6298                	ld	a4,0(a3)
    80006454:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006456:	0a878593          	addi	a1,a5,168
    8000645a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000645c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000645e:	6298                	ld	a4,0(a3)
    80006460:	9732                	add	a4,a4,a2
    80006462:	45c1                	li	a1,16
    80006464:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006466:	6298                	ld	a4,0(a3)
    80006468:	9732                	add	a4,a4,a2
    8000646a:	4585                	li	a1,1
    8000646c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006470:	f8442703          	lw	a4,-124(s0)
    80006474:	628c                	ld	a1,0(a3)
    80006476:	962e                	add	a2,a2,a1
    80006478:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000647c:	0712                	slli	a4,a4,0x4
    8000647e:	6290                	ld	a2,0(a3)
    80006480:	963a                	add	a2,a2,a4
    80006482:	058a8593          	addi	a1,s5,88
    80006486:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006488:	6294                	ld	a3,0(a3)
    8000648a:	96ba                	add	a3,a3,a4
    8000648c:	40000613          	li	a2,1024
    80006490:	c690                	sw	a2,8(a3)
  if(write)
    80006492:	e40d1ae3          	bnez	s10,800062e6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006496:	0001f697          	auipc	a3,0x1f
    8000649a:	b6a6b683          	ld	a3,-1174(a3) # 80025000 <disk+0x2000>
    8000649e:	96ba                	add	a3,a3,a4
    800064a0:	4609                	li	a2,2
    800064a2:	00c69623          	sh	a2,12(a3)
    800064a6:	b5b9                	j	800062f4 <virtio_disk_rw+0xd2>

00000000800064a8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064a8:	1101                	addi	sp,sp,-32
    800064aa:	ec06                	sd	ra,24(sp)
    800064ac:	e822                	sd	s0,16(sp)
    800064ae:	e426                	sd	s1,8(sp)
    800064b0:	e04a                	sd	s2,0(sp)
    800064b2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064b4:	0001f517          	auipc	a0,0x1f
    800064b8:	c7450513          	addi	a0,a0,-908 # 80025128 <disk+0x2128>
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	714080e7          	jalr	1812(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064c4:	10001737          	lui	a4,0x10001
    800064c8:	533c                	lw	a5,96(a4)
    800064ca:	8b8d                	andi	a5,a5,3
    800064cc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064ce:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064d2:	0001f797          	auipc	a5,0x1f
    800064d6:	b2e78793          	addi	a5,a5,-1234 # 80025000 <disk+0x2000>
    800064da:	6b94                	ld	a3,16(a5)
    800064dc:	0207d703          	lhu	a4,32(a5)
    800064e0:	0026d783          	lhu	a5,2(a3)
    800064e4:	06f70163          	beq	a4,a5,80006546 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064e8:	0001d917          	auipc	s2,0x1d
    800064ec:	b1890913          	addi	s2,s2,-1256 # 80023000 <disk>
    800064f0:	0001f497          	auipc	s1,0x1f
    800064f4:	b1048493          	addi	s1,s1,-1264 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064f8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064fc:	6898                	ld	a4,16(s1)
    800064fe:	0204d783          	lhu	a5,32(s1)
    80006502:	8b9d                	andi	a5,a5,7
    80006504:	078e                	slli	a5,a5,0x3
    80006506:	97ba                	add	a5,a5,a4
    80006508:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000650a:	20078713          	addi	a4,a5,512
    8000650e:	0712                	slli	a4,a4,0x4
    80006510:	974a                	add	a4,a4,s2
    80006512:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006516:	e731                	bnez	a4,80006562 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006518:	20078793          	addi	a5,a5,512
    8000651c:	0792                	slli	a5,a5,0x4
    8000651e:	97ca                	add	a5,a5,s2
    80006520:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006522:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006526:	ffffc097          	auipc	ra,0xffffc
    8000652a:	eb4080e7          	jalr	-332(ra) # 800023da <wakeup>

    disk.used_idx += 1;
    8000652e:	0204d783          	lhu	a5,32(s1)
    80006532:	2785                	addiw	a5,a5,1
    80006534:	17c2                	slli	a5,a5,0x30
    80006536:	93c1                	srli	a5,a5,0x30
    80006538:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000653c:	6898                	ld	a4,16(s1)
    8000653e:	00275703          	lhu	a4,2(a4)
    80006542:	faf71be3          	bne	a4,a5,800064f8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006546:	0001f517          	auipc	a0,0x1f
    8000654a:	be250513          	addi	a0,a0,-1054 # 80025128 <disk+0x2128>
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	736080e7          	jalr	1846(ra) # 80000c84 <release>
}
    80006556:	60e2                	ld	ra,24(sp)
    80006558:	6442                	ld	s0,16(sp)
    8000655a:	64a2                	ld	s1,8(sp)
    8000655c:	6902                	ld	s2,0(sp)
    8000655e:	6105                	addi	sp,sp,32
    80006560:	8082                	ret
      panic("virtio_disk_intr status");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	2b650513          	addi	a0,a0,694 # 80008818 <syscalls+0x3d0>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd0080e7          	jalr	-48(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
