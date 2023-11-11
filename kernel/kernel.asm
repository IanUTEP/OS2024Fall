
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	81013103          	ld	sp,-2032(sp) # 80008810 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	fee78793          	addi	a5,a5,-18 # 80006050 <timervec>
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
    800000b0:	e1878793          	addi	a5,a5,-488 # 80000ec4 <main>
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
    8000012e:	4f0080e7          	jalr	1264(ra) # 8000261a <either_copyin>
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
    80000196:	a90080e7          	jalr	-1392(ra) # 80000c22 <acquire>
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
    800001c4:	7de080e7          	jalr	2014(ra) # 8000199e <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	ece080e7          	jalr	-306(ra) # 8000209e <sleep>
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
    80000210:	3b8080e7          	jalr	952(ra) # 800025c4 <either_copyout>
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
    8000022c:	aae080e7          	jalr	-1362(ra) # 80000cd6 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a98080e7          	jalr	-1384(ra) # 80000cd6 <release>
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
    800002d2:	954080e7          	jalr	-1708(ra) # 80000c22 <acquire>

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
    800002f0:	384080e7          	jalr	900(ra) # 80002670 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	9da080e7          	jalr	-1574(ra) # 80000cd6 <release>
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
    80000444:	f58080e7          	jalr	-168(ra) # 80002398 <wakeup>
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
    80000466:	730080e7          	jalr	1840(ra) # 80000b92 <initlock>

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
    80000600:	626080e7          	jalr	1574(ra) # 80000c22 <acquire>
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
    8000075e:	57c080e7          	jalr	1404(ra) # 80000cd6 <release>
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
    80000784:	412080e7          	jalr	1042(ra) # 80000b92 <initlock>
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
    800007da:	3bc080e7          	jalr	956(ra) # 80000b92 <initlock>
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
    800007f6:	3e4080e7          	jalr	996(ra) # 80000bd6 <push_off>

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
    80000824:	456080e7          	jalr	1110(ra) # 80000c76 <pop_off>
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
    80000892:	b0a080e7          	jalr	-1270(ra) # 80002398 <wakeup>
    
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
    800008d6:	350080e7          	jalr	848(ra) # 80000c22 <acquire>
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
    8000091e:	784080e7          	jalr	1924(ra) # 8000209e <sleep>
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
    8000095a:	380080e7          	jalr	896(ra) # 80000cd6 <release>
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
    800009c2:	264080e7          	jalr	612(ra) # 80000c22 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	306080e7          	jalr	774(ra) # 80000cd6 <release>
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
    80000a12:	310080e7          	jalr	784(ra) # 80000d1e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	202080e7          	jalr	514(ra) # 80000c22 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	2a2080e7          	jalr	674(ra) # 80000cd6 <release>
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
    80000ac0:	0d6080e7          	jalr	214(ra) # 80000b92 <initlock>
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
    80000af8:	12e080e7          	jalr	302(ra) # 80000c22 <acquire>
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
    80000b10:	1ca080e7          	jalr	458(ra) # 80000cd6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	204080e7          	jalr	516(ra) # 80000d1e <memset>
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
    80000b3a:	1a0080e7          	jalr	416(ra) # 80000cd6 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <freeMem>:
int 
freeMem(void){
    80000b40:	1101                	addi	sp,sp,-32
    80000b42:	ec06                	sd	ra,24(sp)
    80000b44:	e822                	sd	s0,16(sp)
    80000b46:	e426                	sd	s1,8(sp)
    80000b48:	1000                	addi	s0,sp,32
struct run *r;
	int sum = 0;
  acquire(&kmem.lock);
    80000b4a:	00010497          	auipc	s1,0x10
    80000b4e:	73648493          	addi	s1,s1,1846 # 80011280 <kmem>
    80000b52:	8526                	mv	a0,s1
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	0ce080e7          	jalr	206(ra) # 80000c22 <acquire>
  r = kmem.freelist;
    80000b5c:	6c9c                	ld	a5,24(s1)
	int sum = 0;
    80000b5e:	4481                	li	s1,0
  if(r){
    80000b60:	cb89                	beqz	a5,80000b72 <freeMem+0x32>
    while(r->next != NULL){
    80000b62:	639c                	ld	a5,0(a5)
    80000b64:	c78d                	beqz	a5,80000b8e <freeMem+0x4e>
	int sum = 0;
    80000b66:	4501                	li	a0,0
    sum++;
    80000b68:	2505                	addiw	a0,a0,1
    while(r->next != NULL){
    80000b6a:	639c                	ld	a5,0(a5)
    80000b6c:	fff5                	bnez	a5,80000b68 <freeMem+0x28>
    r=r->next;
    }
    sum++;
    80000b6e:	0015049b          	addiw	s1,a0,1
    }
  release(&kmem.lock);
    80000b72:	00010517          	auipc	a0,0x10
    80000b76:	70e50513          	addi	a0,a0,1806 # 80011280 <kmem>
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	15c080e7          	jalr	348(ra) # 80000cd6 <release>
	return sum;
}
    80000b82:	8526                	mv	a0,s1
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret
	int sum = 0;
    80000b8e:	4501                	li	a0,0
    80000b90:	bff9                	j	80000b6e <freeMem+0x2e>

0000000080000b92 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b92:	1141                	addi	sp,sp,-16
    80000b94:	e422                	sd	s0,8(sp)
    80000b96:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b98:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b9a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9e:	00053823          	sd	zero,16(a0)
}
    80000ba2:	6422                	ld	s0,8(sp)
    80000ba4:	0141                	addi	sp,sp,16
    80000ba6:	8082                	ret

0000000080000ba8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	411c                	lw	a5,0(a0)
    80000baa:	e399                	bnez	a5,80000bb0 <holding+0x8>
    80000bac:	4501                	li	a0,0
  return r;
}
    80000bae:	8082                	ret
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bba:	6904                	ld	s1,16(a0)
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dc6080e7          	jalr	-570(ra) # 80001982 <mycpu>
    80000bc4:	40a48533          	sub	a0,s1,a0
    80000bc8:	00153513          	seqz	a0,a0
}
    80000bcc:	60e2                	ld	ra,24(sp)
    80000bce:	6442                	ld	s0,16(sp)
    80000bd0:	64a2                	ld	s1,8(sp)
    80000bd2:	6105                	addi	sp,sp,32
    80000bd4:	8082                	ret

0000000080000bd6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000be0:	100024f3          	csrr	s1,sstatus
    80000be4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bea:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	d94080e7          	jalr	-620(ra) # 80001982 <mycpu>
    80000bf6:	5d3c                	lw	a5,120(a0)
    80000bf8:	cf89                	beqz	a5,80000c12 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bfa:	00001097          	auipc	ra,0x1
    80000bfe:	d88080e7          	jalr	-632(ra) # 80001982 <mycpu>
    80000c02:	5d3c                	lw	a5,120(a0)
    80000c04:	2785                	addiw	a5,a5,1
    80000c06:	dd3c                	sw	a5,120(a0)
}
    80000c08:	60e2                	ld	ra,24(sp)
    80000c0a:	6442                	ld	s0,16(sp)
    80000c0c:	64a2                	ld	s1,8(sp)
    80000c0e:	6105                	addi	sp,sp,32
    80000c10:	8082                	ret
    mycpu()->intena = old;
    80000c12:	00001097          	auipc	ra,0x1
    80000c16:	d70080e7          	jalr	-656(ra) # 80001982 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c1a:	8085                	srli	s1,s1,0x1
    80000c1c:	8885                	andi	s1,s1,1
    80000c1e:	dd64                	sw	s1,124(a0)
    80000c20:	bfe9                	j	80000bfa <push_off+0x24>

0000000080000c22 <acquire>:
{
    80000c22:	1101                	addi	sp,sp,-32
    80000c24:	ec06                	sd	ra,24(sp)
    80000c26:	e822                	sd	s0,16(sp)
    80000c28:	e426                	sd	s1,8(sp)
    80000c2a:	1000                	addi	s0,sp,32
    80000c2c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	fa8080e7          	jalr	-88(ra) # 80000bd6 <push_off>
  if(holding(lk))
    80000c36:	8526                	mv	a0,s1
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	f70080e7          	jalr	-144(ra) # 80000ba8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c40:	4705                	li	a4,1
  if(holding(lk))
    80000c42:	e115                	bnez	a0,80000c66 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c44:	87ba                	mv	a5,a4
    80000c46:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c4a:	2781                	sext.w	a5,a5
    80000c4c:	ffe5                	bnez	a5,80000c44 <acquire+0x22>
  __sync_synchronize();
    80000c4e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	d30080e7          	jalr	-720(ra) # 80001982 <mycpu>
    80000c5a:	e888                	sd	a0,16(s1)
}
    80000c5c:	60e2                	ld	ra,24(sp)
    80000c5e:	6442                	ld	s0,16(sp)
    80000c60:	64a2                	ld	s1,8(sp)
    80000c62:	6105                	addi	sp,sp,32
    80000c64:	8082                	ret
    panic("acquire");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	40a50513          	addi	a0,a0,1034 # 80008070 <digits+0x30>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8cc080e7          	jalr	-1844(ra) # 8000053a <panic>

0000000080000c76 <pop_off>:

void
pop_off(void)
{
    80000c76:	1141                	addi	sp,sp,-16
    80000c78:	e406                	sd	ra,8(sp)
    80000c7a:	e022                	sd	s0,0(sp)
    80000c7c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7e:	00001097          	auipc	ra,0x1
    80000c82:	d04080e7          	jalr	-764(ra) # 80001982 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c8c:	e78d                	bnez	a5,80000cb6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8e:	5d3c                	lw	a5,120(a0)
    80000c90:	02f05b63          	blez	a5,80000cc6 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c94:	37fd                	addiw	a5,a5,-1
    80000c96:	0007871b          	sext.w	a4,a5
    80000c9a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c9c:	eb09                	bnez	a4,80000cae <pop_off+0x38>
    80000c9e:	5d7c                	lw	a5,124(a0)
    80000ca0:	c799                	beqz	a5,80000cae <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000caa:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cae:	60a2                	ld	ra,8(sp)
    80000cb0:	6402                	ld	s0,0(sp)
    80000cb2:	0141                	addi	sp,sp,16
    80000cb4:	8082                	ret
    panic("pop_off - interruptible");
    80000cb6:	00007517          	auipc	a0,0x7
    80000cba:	3c250513          	addi	a0,a0,962 # 80008078 <digits+0x38>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	87c080e7          	jalr	-1924(ra) # 8000053a <panic>
    panic("pop_off");
    80000cc6:	00007517          	auipc	a0,0x7
    80000cca:	3ca50513          	addi	a0,a0,970 # 80008090 <digits+0x50>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	86c080e7          	jalr	-1940(ra) # 8000053a <panic>

0000000080000cd6 <release>:
{
    80000cd6:	1101                	addi	sp,sp,-32
    80000cd8:	ec06                	sd	ra,24(sp)
    80000cda:	e822                	sd	s0,16(sp)
    80000cdc:	e426                	sd	s1,8(sp)
    80000cde:	1000                	addi	s0,sp,32
    80000ce0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	ec6080e7          	jalr	-314(ra) # 80000ba8 <holding>
    80000cea:	c115                	beqz	a0,80000d0e <release+0x38>
  lk->cpu = 0;
    80000cec:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cf0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf4:	0f50000f          	fence	iorw,ow
    80000cf8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	f7a080e7          	jalr	-134(ra) # 80000c76 <pop_off>
}
    80000d04:	60e2                	ld	ra,24(sp)
    80000d06:	6442                	ld	s0,16(sp)
    80000d08:	64a2                	ld	s1,8(sp)
    80000d0a:	6105                	addi	sp,sp,32
    80000d0c:	8082                	ret
    panic("release");
    80000d0e:	00007517          	auipc	a0,0x7
    80000d12:	38a50513          	addi	a0,a0,906 # 80008098 <digits+0x58>
    80000d16:	00000097          	auipc	ra,0x0
    80000d1a:	824080e7          	jalr	-2012(ra) # 8000053a <panic>

0000000080000d1e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e422                	sd	s0,8(sp)
    80000d22:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d24:	ca19                	beqz	a2,80000d3a <memset+0x1c>
    80000d26:	87aa                	mv	a5,a0
    80000d28:	1602                	slli	a2,a2,0x20
    80000d2a:	9201                	srli	a2,a2,0x20
    80000d2c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d30:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d34:	0785                	addi	a5,a5,1
    80000d36:	fee79de3          	bne	a5,a4,80000d30 <memset+0x12>
  }
  return dst;
}
    80000d3a:	6422                	ld	s0,8(sp)
    80000d3c:	0141                	addi	sp,sp,16
    80000d3e:	8082                	ret

0000000080000d40 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d46:	ca05                	beqz	a2,80000d76 <memcmp+0x36>
    80000d48:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d4c:	1682                	slli	a3,a3,0x20
    80000d4e:	9281                	srli	a3,a3,0x20
    80000d50:	0685                	addi	a3,a3,1
    80000d52:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d54:	00054783          	lbu	a5,0(a0)
    80000d58:	0005c703          	lbu	a4,0(a1)
    80000d5c:	00e79863          	bne	a5,a4,80000d6c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d60:	0505                	addi	a0,a0,1
    80000d62:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d64:	fed518e3          	bne	a0,a3,80000d54 <memcmp+0x14>
  }

  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	a019                	j	80000d70 <memcmp+0x30>
      return *s1 - *s2;
    80000d6c:	40e7853b          	subw	a0,a5,a4
}
    80000d70:	6422                	ld	s0,8(sp)
    80000d72:	0141                	addi	sp,sp,16
    80000d74:	8082                	ret
  return 0;
    80000d76:	4501                	li	a0,0
    80000d78:	bfe5                	j	80000d70 <memcmp+0x30>

0000000080000d7a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d7a:	1141                	addi	sp,sp,-16
    80000d7c:	e422                	sd	s0,8(sp)
    80000d7e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d80:	c205                	beqz	a2,80000da0 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d82:	02a5e263          	bltu	a1,a0,80000da6 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d86:	1602                	slli	a2,a2,0x20
    80000d88:	9201                	srli	a2,a2,0x20
    80000d8a:	00c587b3          	add	a5,a1,a2
{
    80000d8e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d90:	0585                	addi	a1,a1,1
    80000d92:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d94:	fff5c683          	lbu	a3,-1(a1)
    80000d98:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d9c:	fef59ae3          	bne	a1,a5,80000d90 <memmove+0x16>

  return dst;
}
    80000da0:	6422                	ld	s0,8(sp)
    80000da2:	0141                	addi	sp,sp,16
    80000da4:	8082                	ret
  if(s < d && s + n > d){
    80000da6:	02061693          	slli	a3,a2,0x20
    80000daa:	9281                	srli	a3,a3,0x20
    80000dac:	00d58733          	add	a4,a1,a3
    80000db0:	fce57be3          	bgeu	a0,a4,80000d86 <memmove+0xc>
    d += n;
    80000db4:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000db6:	fff6079b          	addiw	a5,a2,-1
    80000dba:	1782                	slli	a5,a5,0x20
    80000dbc:	9381                	srli	a5,a5,0x20
    80000dbe:	fff7c793          	not	a5,a5
    80000dc2:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dc4:	177d                	addi	a4,a4,-1
    80000dc6:	16fd                	addi	a3,a3,-1
    80000dc8:	00074603          	lbu	a2,0(a4)
    80000dcc:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dd0:	fee79ae3          	bne	a5,a4,80000dc4 <memmove+0x4a>
    80000dd4:	b7f1                	j	80000da0 <memmove+0x26>

0000000080000dd6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd6:	1141                	addi	sp,sp,-16
    80000dd8:	e406                	sd	ra,8(sp)
    80000dda:	e022                	sd	s0,0(sp)
    80000ddc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dde:	00000097          	auipc	ra,0x0
    80000de2:	f9c080e7          	jalr	-100(ra) # 80000d7a <memmove>
}
    80000de6:	60a2                	ld	ra,8(sp)
    80000de8:	6402                	ld	s0,0(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret

0000000080000dee <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dee:	1141                	addi	sp,sp,-16
    80000df0:	e422                	sd	s0,8(sp)
    80000df2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000df4:	ce11                	beqz	a2,80000e10 <strncmp+0x22>
    80000df6:	00054783          	lbu	a5,0(a0)
    80000dfa:	cf89                	beqz	a5,80000e14 <strncmp+0x26>
    80000dfc:	0005c703          	lbu	a4,0(a1)
    80000e00:	00f71a63          	bne	a4,a5,80000e14 <strncmp+0x26>
    n--, p++, q++;
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	0505                	addi	a0,a0,1
    80000e08:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e0a:	f675                	bnez	a2,80000df6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e0c:	4501                	li	a0,0
    80000e0e:	a809                	j	80000e20 <strncmp+0x32>
    80000e10:	4501                	li	a0,0
    80000e12:	a039                	j	80000e20 <strncmp+0x32>
  if(n == 0)
    80000e14:	ca09                	beqz	a2,80000e26 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e16:	00054503          	lbu	a0,0(a0)
    80000e1a:	0005c783          	lbu	a5,0(a1)
    80000e1e:	9d1d                	subw	a0,a0,a5
}
    80000e20:	6422                	ld	s0,8(sp)
    80000e22:	0141                	addi	sp,sp,16
    80000e24:	8082                	ret
    return 0;
    80000e26:	4501                	li	a0,0
    80000e28:	bfe5                	j	80000e20 <strncmp+0x32>

0000000080000e2a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e2a:	1141                	addi	sp,sp,-16
    80000e2c:	e422                	sd	s0,8(sp)
    80000e2e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e30:	872a                	mv	a4,a0
    80000e32:	8832                	mv	a6,a2
    80000e34:	367d                	addiw	a2,a2,-1
    80000e36:	01005963          	blez	a6,80000e48 <strncpy+0x1e>
    80000e3a:	0705                	addi	a4,a4,1
    80000e3c:	0005c783          	lbu	a5,0(a1)
    80000e40:	fef70fa3          	sb	a5,-1(a4)
    80000e44:	0585                	addi	a1,a1,1
    80000e46:	f7f5                	bnez	a5,80000e32 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e48:	86ba                	mv	a3,a4
    80000e4a:	00c05c63          	blez	a2,80000e62 <strncpy+0x38>
    *s++ = 0;
    80000e4e:	0685                	addi	a3,a3,1
    80000e50:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e54:	40d707bb          	subw	a5,a4,a3
    80000e58:	37fd                	addiw	a5,a5,-1
    80000e5a:	010787bb          	addw	a5,a5,a6
    80000e5e:	fef048e3          	bgtz	a5,80000e4e <strncpy+0x24>
  return os;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret

0000000080000e68 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e68:	1141                	addi	sp,sp,-16
    80000e6a:	e422                	sd	s0,8(sp)
    80000e6c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e6e:	02c05363          	blez	a2,80000e94 <safestrcpy+0x2c>
    80000e72:	fff6069b          	addiw	a3,a2,-1
    80000e76:	1682                	slli	a3,a3,0x20
    80000e78:	9281                	srli	a3,a3,0x20
    80000e7a:	96ae                	add	a3,a3,a1
    80000e7c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e7e:	00d58963          	beq	a1,a3,80000e90 <safestrcpy+0x28>
    80000e82:	0585                	addi	a1,a1,1
    80000e84:	0785                	addi	a5,a5,1
    80000e86:	fff5c703          	lbu	a4,-1(a1)
    80000e8a:	fee78fa3          	sb	a4,-1(a5)
    80000e8e:	fb65                	bnez	a4,80000e7e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e90:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e94:	6422                	ld	s0,8(sp)
    80000e96:	0141                	addi	sp,sp,16
    80000e98:	8082                	ret

0000000080000e9a <strlen>:

int
strlen(const char *s)
{
    80000e9a:	1141                	addi	sp,sp,-16
    80000e9c:	e422                	sd	s0,8(sp)
    80000e9e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ea0:	00054783          	lbu	a5,0(a0)
    80000ea4:	cf91                	beqz	a5,80000ec0 <strlen+0x26>
    80000ea6:	0505                	addi	a0,a0,1
    80000ea8:	87aa                	mv	a5,a0
    80000eaa:	4685                	li	a3,1
    80000eac:	9e89                	subw	a3,a3,a0
    80000eae:	00f6853b          	addw	a0,a3,a5
    80000eb2:	0785                	addi	a5,a5,1
    80000eb4:	fff7c703          	lbu	a4,-1(a5)
    80000eb8:	fb7d                	bnez	a4,80000eae <strlen+0x14>
    ;
  return n;
}
    80000eba:	6422                	ld	s0,8(sp)
    80000ebc:	0141                	addi	sp,sp,16
    80000ebe:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ec0:	4501                	li	a0,0
    80000ec2:	bfe5                	j	80000eba <strlen+0x20>

0000000080000ec4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ec4:	1141                	addi	sp,sp,-16
    80000ec6:	e406                	sd	ra,8(sp)
    80000ec8:	e022                	sd	s0,0(sp)
    80000eca:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	aa6080e7          	jalr	-1370(ra) # 80001972 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ed4:	00008717          	auipc	a4,0x8
    80000ed8:	14470713          	addi	a4,a4,324 # 80009018 <started>
  if(cpuid() == 0){
    80000edc:	c139                	beqz	a0,80000f22 <main+0x5e>
    while(started == 0)
    80000ede:	431c                	lw	a5,0(a4)
    80000ee0:	2781                	sext.w	a5,a5
    80000ee2:	dff5                	beqz	a5,80000ede <main+0x1a>
      ;
    __sync_synchronize();
    80000ee4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee8:	00001097          	auipc	ra,0x1
    80000eec:	a8a080e7          	jalr	-1398(ra) # 80001972 <cpuid>
    80000ef0:	85aa                	mv	a1,a0
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1c650513          	addi	a0,a0,454 # 800080b8 <digits+0x78>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	68a080e7          	jalr	1674(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000f02:	00000097          	auipc	ra,0x0
    80000f06:	0d8080e7          	jalr	216(ra) # 80000fda <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f0a:	00002097          	auipc	ra,0x2
    80000f0e:	a60080e7          	jalr	-1440(ra) # 8000296a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f12:	00005097          	auipc	ra,0x5
    80000f16:	17e080e7          	jalr	382(ra) # 80006090 <plicinithart>
  }

  scheduler();        
    80000f1a:	00001097          	auipc	ra,0x1
    80000f1e:	fc8080e7          	jalr	-56(ra) # 80001ee2 <scheduler>
    consoleinit();
    80000f22:	fffff097          	auipc	ra,0xfffff
    80000f26:	528080e7          	jalr	1320(ra) # 8000044a <consoleinit>
    printfinit();
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	83a080e7          	jalr	-1990(ra) # 80000764 <printfinit>
    printf("\n");
    80000f32:	00007517          	auipc	a0,0x7
    80000f36:	19650513          	addi	a0,a0,406 # 800080c8 <digits+0x88>
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	64a080e7          	jalr	1610(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000f42:	00007517          	auipc	a0,0x7
    80000f46:	15e50513          	addi	a0,a0,350 # 800080a0 <digits+0x60>
    80000f4a:	fffff097          	auipc	ra,0xfffff
    80000f4e:	63a080e7          	jalr	1594(ra) # 80000584 <printf>
    printf("\n");
    80000f52:	00007517          	auipc	a0,0x7
    80000f56:	17650513          	addi	a0,a0,374 # 800080c8 <digits+0x88>
    80000f5a:	fffff097          	auipc	ra,0xfffff
    80000f5e:	62a080e7          	jalr	1578(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f62:	00000097          	auipc	ra,0x0
    80000f66:	b42080e7          	jalr	-1214(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	312080e7          	jalr	786(ra) # 8000127c <kvminit>
    kvminithart();   // turn on paging
    80000f72:	00000097          	auipc	ra,0x0
    80000f76:	068080e7          	jalr	104(ra) # 80000fda <kvminithart>
    procinit();      // process table
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	948080e7          	jalr	-1720(ra) # 800018c2 <procinit>
    trapinit();      // trap vectors
    80000f82:	00002097          	auipc	ra,0x2
    80000f86:	9c0080e7          	jalr	-1600(ra) # 80002942 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8a:	00002097          	auipc	ra,0x2
    80000f8e:	9e0080e7          	jalr	-1568(ra) # 8000296a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	0e8080e7          	jalr	232(ra) # 8000607a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9a:	00005097          	auipc	ra,0x5
    80000f9e:	0f6080e7          	jalr	246(ra) # 80006090 <plicinithart>
    binit();         // buffer cache
    80000fa2:	00002097          	auipc	ra,0x2
    80000fa6:	2bc080e7          	jalr	700(ra) # 8000325e <binit>
    iinit();         // inode table
    80000faa:	00003097          	auipc	ra,0x3
    80000fae:	94a080e7          	jalr	-1718(ra) # 800038f4 <iinit>
    fileinit();      // file table
    80000fb2:	00004097          	auipc	ra,0x4
    80000fb6:	8fc080e7          	jalr	-1796(ra) # 800048ae <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fba:	00005097          	auipc	ra,0x5
    80000fbe:	1f6080e7          	jalr	502(ra) # 800061b0 <virtio_disk_init>
    userinit();      // first user process
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	cb8080e7          	jalr	-840(ra) # 80001c7a <userinit>
    __sync_synchronize();
    80000fca:	0ff0000f          	fence
    started = 1;
    80000fce:	4785                	li	a5,1
    80000fd0:	00008717          	auipc	a4,0x8
    80000fd4:	04f72423          	sw	a5,72(a4) # 80009018 <started>
    80000fd8:	b789                	j	80000f1a <main+0x56>

0000000080000fda <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fda:	1141                	addi	sp,sp,-16
    80000fdc:	e422                	sd	s0,8(sp)
    80000fde:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe0:	00008797          	auipc	a5,0x8
    80000fe4:	0407b783          	ld	a5,64(a5) # 80009020 <kernel_pagetable>
    80000fe8:	83b1                	srli	a5,a5,0xc
    80000fea:	577d                	li	a4,-1
    80000fec:	177e                	slli	a4,a4,0x3f
    80000fee:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff4:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff8:	6422                	ld	s0,8(sp)
    80000ffa:	0141                	addi	sp,sp,16
    80000ffc:	8082                	ret

0000000080000ffe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ffe:	7139                	addi	sp,sp,-64
    80001000:	fc06                	sd	ra,56(sp)
    80001002:	f822                	sd	s0,48(sp)
    80001004:	f426                	sd	s1,40(sp)
    80001006:	f04a                	sd	s2,32(sp)
    80001008:	ec4e                	sd	s3,24(sp)
    8000100a:	e852                	sd	s4,16(sp)
    8000100c:	e456                	sd	s5,8(sp)
    8000100e:	e05a                	sd	s6,0(sp)
    80001010:	0080                	addi	s0,sp,64
    80001012:	84aa                	mv	s1,a0
    80001014:	89ae                	mv	s3,a1
    80001016:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001018:	57fd                	li	a5,-1
    8000101a:	83e9                	srli	a5,a5,0x1a
    8000101c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000101e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001020:	04b7f263          	bgeu	a5,a1,80001064 <walk+0x66>
    panic("walk");
    80001024:	00007517          	auipc	a0,0x7
    80001028:	0ac50513          	addi	a0,a0,172 # 800080d0 <digits+0x90>
    8000102c:	fffff097          	auipc	ra,0xfffff
    80001030:	50e080e7          	jalr	1294(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001034:	060a8663          	beqz	s5,800010a0 <walk+0xa2>
    80001038:	00000097          	auipc	ra,0x0
    8000103c:	aa8080e7          	jalr	-1368(ra) # 80000ae0 <kalloc>
    80001040:	84aa                	mv	s1,a0
    80001042:	c529                	beqz	a0,8000108c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001044:	6605                	lui	a2,0x1
    80001046:	4581                	li	a1,0
    80001048:	00000097          	auipc	ra,0x0
    8000104c:	cd6080e7          	jalr	-810(ra) # 80000d1e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001050:	00c4d793          	srli	a5,s1,0xc
    80001054:	07aa                	slli	a5,a5,0xa
    80001056:	0017e793          	ori	a5,a5,1
    8000105a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000105e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    80001060:	036a0063          	beq	s4,s6,80001080 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001064:	0149d933          	srl	s2,s3,s4
    80001068:	1ff97913          	andi	s2,s2,511
    8000106c:	090e                	slli	s2,s2,0x3
    8000106e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001070:	00093483          	ld	s1,0(s2)
    80001074:	0014f793          	andi	a5,s1,1
    80001078:	dfd5                	beqz	a5,80001034 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107a:	80a9                	srli	s1,s1,0xa
    8000107c:	04b2                	slli	s1,s1,0xc
    8000107e:	b7c5                	j	8000105e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001080:	00c9d513          	srli	a0,s3,0xc
    80001084:	1ff57513          	andi	a0,a0,511
    80001088:	050e                	slli	a0,a0,0x3
    8000108a:	9526                	add	a0,a0,s1
}
    8000108c:	70e2                	ld	ra,56(sp)
    8000108e:	7442                	ld	s0,48(sp)
    80001090:	74a2                	ld	s1,40(sp)
    80001092:	7902                	ld	s2,32(sp)
    80001094:	69e2                	ld	s3,24(sp)
    80001096:	6a42                	ld	s4,16(sp)
    80001098:	6aa2                	ld	s5,8(sp)
    8000109a:	6b02                	ld	s6,0(sp)
    8000109c:	6121                	addi	sp,sp,64
    8000109e:	8082                	ret
        return 0;
    800010a0:	4501                	li	a0,0
    800010a2:	b7ed                	j	8000108c <walk+0x8e>

00000000800010a4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a4:	57fd                	li	a5,-1
    800010a6:	83e9                	srli	a5,a5,0x1a
    800010a8:	00b7f463          	bgeu	a5,a1,800010b0 <walkaddr+0xc>
    return 0;
    800010ac:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010ae:	8082                	ret
{
    800010b0:	1141                	addi	sp,sp,-16
    800010b2:	e406                	sd	ra,8(sp)
    800010b4:	e022                	sd	s0,0(sp)
    800010b6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b8:	4601                	li	a2,0
    800010ba:	00000097          	auipc	ra,0x0
    800010be:	f44080e7          	jalr	-188(ra) # 80000ffe <walk>
  if(pte == 0)
    800010c2:	c105                	beqz	a0,800010e2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c6:	0117f693          	andi	a3,a5,17
    800010ca:	4745                	li	a4,17
    return 0;
    800010cc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ce:	00e68663          	beq	a3,a4,800010da <walkaddr+0x36>
}
    800010d2:	60a2                	ld	ra,8(sp)
    800010d4:	6402                	ld	s0,0(sp)
    800010d6:	0141                	addi	sp,sp,16
    800010d8:	8082                	ret
  pa = PTE2PA(*pte);
    800010da:	83a9                	srli	a5,a5,0xa
    800010dc:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010e0:	bfcd                	j	800010d2 <walkaddr+0x2e>
    return 0;
    800010e2:	4501                	li	a0,0
    800010e4:	b7fd                	j	800010d2 <walkaddr+0x2e>

00000000800010e6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e6:	715d                	addi	sp,sp,-80
    800010e8:	e486                	sd	ra,72(sp)
    800010ea:	e0a2                	sd	s0,64(sp)
    800010ec:	fc26                	sd	s1,56(sp)
    800010ee:	f84a                	sd	s2,48(sp)
    800010f0:	f44e                	sd	s3,40(sp)
    800010f2:	f052                	sd	s4,32(sp)
    800010f4:	ec56                	sd	s5,24(sp)
    800010f6:	e85a                	sd	s6,16(sp)
    800010f8:	e45e                	sd	s7,8(sp)
    800010fa:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010fc:	c639                	beqz	a2,8000114a <mappages+0x64>
    800010fe:	8a2a                	mv	s4,a0
    80001100:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001102:	777d                	lui	a4,0xfffff
    80001104:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001108:	fff58993          	addi	s3,a1,-1
    8000110c:	99b2                	add	s3,s3,a2
    8000110e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001112:	893e                	mv	s2,a5
    80001114:	40f68ab3          	sub	s5,a3,a5
      //panic("mappages: remap");
      continue;
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001118:	6b85                	lui	s7,0x1
    8000111a:	012a84b3          	add	s1,s5,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111e:	4605                	li	a2,1
    80001120:	85ca                	mv	a1,s2
    80001122:	8552                	mv	a0,s4
    80001124:	00000097          	auipc	ra,0x0
    80001128:	eda080e7          	jalr	-294(ra) # 80000ffe <walk>
    8000112c:	c51d                	beqz	a0,8000115a <mappages+0x74>
    if(*pte & PTE_V)
    8000112e:	611c                	ld	a5,0(a0)
    80001130:	8b85                	andi	a5,a5,1
    80001132:	f7f5                	bnez	a5,8000111e <mappages+0x38>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001134:	80b1                	srli	s1,s1,0xc
    80001136:	04aa                	slli	s1,s1,0xa
    80001138:	0164e4b3          	or	s1,s1,s6
    8000113c:	0014e493          	ori	s1,s1,1
    80001140:	e104                	sd	s1,0(a0)
    if(a == last)
    80001142:	03298863          	beq	s3,s2,80001172 <mappages+0x8c>
    a += PGSIZE;
    80001146:	995e                	add	s2,s2,s7
    pa += PGSIZE;
    80001148:	bfc9                	j	8000111a <mappages+0x34>
    panic("mappages: size");
    8000114a:	00007517          	auipc	a0,0x7
    8000114e:	f8e50513          	addi	a0,a0,-114 # 800080d8 <digits+0x98>
    80001152:	fffff097          	auipc	ra,0xfffff
    80001156:	3e8080e7          	jalr	1000(ra) # 8000053a <panic>
      return -1;
    8000115a:	557d                	li	a0,-1
  }
  return 0;
}
    8000115c:	60a6                	ld	ra,72(sp)
    8000115e:	6406                	ld	s0,64(sp)
    80001160:	74e2                	ld	s1,56(sp)
    80001162:	7942                	ld	s2,48(sp)
    80001164:	79a2                	ld	s3,40(sp)
    80001166:	7a02                	ld	s4,32(sp)
    80001168:	6ae2                	ld	s5,24(sp)
    8000116a:	6b42                	ld	s6,16(sp)
    8000116c:	6ba2                	ld	s7,8(sp)
    8000116e:	6161                	addi	sp,sp,80
    80001170:	8082                	ret
  return 0;
    80001172:	4501                	li	a0,0
    80001174:	b7e5                	j	8000115c <mappages+0x76>

0000000080001176 <kvmmap>:
{
    80001176:	1141                	addi	sp,sp,-16
    80001178:	e406                	sd	ra,8(sp)
    8000117a:	e022                	sd	s0,0(sp)
    8000117c:	0800                	addi	s0,sp,16
    8000117e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001180:	86b2                	mv	a3,a2
    80001182:	863e                	mv	a2,a5
    80001184:	00000097          	auipc	ra,0x0
    80001188:	f62080e7          	jalr	-158(ra) # 800010e6 <mappages>
    8000118c:	e509                	bnez	a0,80001196 <kvmmap+0x20>
}
    8000118e:	60a2                	ld	ra,8(sp)
    80001190:	6402                	ld	s0,0(sp)
    80001192:	0141                	addi	sp,sp,16
    80001194:	8082                	ret
    panic("kvmmap");
    80001196:	00007517          	auipc	a0,0x7
    8000119a:	f5250513          	addi	a0,a0,-174 # 800080e8 <digits+0xa8>
    8000119e:	fffff097          	auipc	ra,0xfffff
    800011a2:	39c080e7          	jalr	924(ra) # 8000053a <panic>

00000000800011a6 <kvmmake>:
{
    800011a6:	1101                	addi	sp,sp,-32
    800011a8:	ec06                	sd	ra,24(sp)
    800011aa:	e822                	sd	s0,16(sp)
    800011ac:	e426                	sd	s1,8(sp)
    800011ae:	e04a                	sd	s2,0(sp)
    800011b0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	92e080e7          	jalr	-1746(ra) # 80000ae0 <kalloc>
    800011ba:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011bc:	6605                	lui	a2,0x1
    800011be:	4581                	li	a1,0
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	b5e080e7          	jalr	-1186(ra) # 80000d1e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011c8:	4719                	li	a4,6
    800011ca:	6685                	lui	a3,0x1
    800011cc:	10000637          	lui	a2,0x10000
    800011d0:	100005b7          	lui	a1,0x10000
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	fa0080e7          	jalr	-96(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	6685                	lui	a3,0x1
    800011e2:	10001637          	lui	a2,0x10001
    800011e6:	100015b7          	lui	a1,0x10001
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f8a080e7          	jalr	-118(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f4:	4719                	li	a4,6
    800011f6:	004006b7          	lui	a3,0x400
    800011fa:	0c000637          	lui	a2,0xc000
    800011fe:	0c0005b7          	lui	a1,0xc000
    80001202:	8526                	mv	a0,s1
    80001204:	00000097          	auipc	ra,0x0
    80001208:	f72080e7          	jalr	-142(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120c:	00007917          	auipc	s2,0x7
    80001210:	df490913          	addi	s2,s2,-524 # 80008000 <etext>
    80001214:	4729                	li	a4,10
    80001216:	80007697          	auipc	a3,0x80007
    8000121a:	dea68693          	addi	a3,a3,-534 # 8000 <_entry-0x7fff8000>
    8000121e:	4605                	li	a2,1
    80001220:	067e                	slli	a2,a2,0x1f
    80001222:	85b2                	mv	a1,a2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f50080e7          	jalr	-176(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122e:	4719                	li	a4,6
    80001230:	46c5                	li	a3,17
    80001232:	06ee                	slli	a3,a3,0x1b
    80001234:	412686b3          	sub	a3,a3,s2
    80001238:	864a                	mv	a2,s2
    8000123a:	85ca                	mv	a1,s2
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f38080e7          	jalr	-200(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001246:	4729                	li	a4,10
    80001248:	6685                	lui	a3,0x1
    8000124a:	00006617          	auipc	a2,0x6
    8000124e:	db660613          	addi	a2,a2,-586 # 80007000 <_trampoline>
    80001252:	040005b7          	lui	a1,0x4000
    80001256:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001258:	05b2                	slli	a1,a1,0xc
    8000125a:	8526                	mv	a0,s1
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f1a080e7          	jalr	-230(ra) # 80001176 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	5c6080e7          	jalr	1478(ra) # 8000182c <proc_mapstacks>
}
    8000126e:	8526                	mv	a0,s1
    80001270:	60e2                	ld	ra,24(sp)
    80001272:	6442                	ld	s0,16(sp)
    80001274:	64a2                	ld	s1,8(sp)
    80001276:	6902                	ld	s2,0(sp)
    80001278:	6105                	addi	sp,sp,32
    8000127a:	8082                	ret

000000008000127c <kvminit>:
{
    8000127c:	1141                	addi	sp,sp,-16
    8000127e:	e406                	sd	ra,8(sp)
    80001280:	e022                	sd	s0,0(sp)
    80001282:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f22080e7          	jalr	-222(ra) # 800011a6 <kvmmake>
    8000128c:	00008797          	auipc	a5,0x8
    80001290:	d8a7ba23          	sd	a0,-620(a5) # 80009020 <kernel_pagetable>
}
    80001294:	60a2                	ld	ra,8(sp)
    80001296:	6402                	ld	s0,0(sp)
    80001298:	0141                	addi	sp,sp,16
    8000129a:	8082                	ret

000000008000129c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129c:	715d                	addi	sp,sp,-80
    8000129e:	e486                	sd	ra,72(sp)
    800012a0:	e0a2                	sd	s0,64(sp)
    800012a2:	fc26                	sd	s1,56(sp)
    800012a4:	f84a                	sd	s2,48(sp)
    800012a6:	f44e                	sd	s3,40(sp)
    800012a8:	f052                	sd	s4,32(sp)
    800012aa:	ec56                	sd	s5,24(sp)
    800012ac:	e85a                	sd	s6,16(sp)
    800012ae:	e45e                	sd	s7,8(sp)
    800012b0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;
  if((va % PGSIZE) != 0)
    800012b2:	03459793          	slli	a5,a1,0x34
    800012b6:	e795                	bnez	a5,800012e2 <uvmunmap+0x46>
    800012b8:	8a2a                	mv	s4,a0
    800012ba:	892e                	mv	s2,a1
    800012bc:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012be:	0632                	slli	a2,a2,0xc
    800012c0:	00b609b3          	add	s3,a2,a1
      continue;
    if((*pte & PTE_V) == 0){
      //panic("uvmunmap: not mapped");
      continue;
      }
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c6:	6a85                	lui	s5,0x1
    800012c8:	0535e263          	bltu	a1,s3,8000130c <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012cc:	60a6                	ld	ra,72(sp)
    800012ce:	6406                	ld	s0,64(sp)
    800012d0:	74e2                	ld	s1,56(sp)
    800012d2:	7942                	ld	s2,48(sp)
    800012d4:	79a2                	ld	s3,40(sp)
    800012d6:	7a02                	ld	s4,32(sp)
    800012d8:	6ae2                	ld	s5,24(sp)
    800012da:	6b42                	ld	s6,16(sp)
    800012dc:	6ba2                	ld	s7,8(sp)
    800012de:	6161                	addi	sp,sp,80
    800012e0:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e2:	00007517          	auipc	a0,0x7
    800012e6:	e0e50513          	addi	a0,a0,-498 # 800080f0 <digits+0xb0>
    800012ea:	fffff097          	auipc	ra,0xfffff
    800012ee:	250080e7          	jalr	592(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012f2:	00007517          	auipc	a0,0x7
    800012f6:	e1650513          	addi	a0,a0,-490 # 80008108 <digits+0xc8>
    800012fa:	fffff097          	auipc	ra,0xfffff
    800012fe:	240080e7          	jalr	576(ra) # 8000053a <panic>
    *pte = 0;
    80001302:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	9956                	add	s2,s2,s5
    80001308:	fd3972e3          	bgeu	s2,s3,800012cc <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000130c:	4601                	li	a2,0
    8000130e:	85ca                	mv	a1,s2
    80001310:	8552                	mv	a0,s4
    80001312:	00000097          	auipc	ra,0x0
    80001316:	cec080e7          	jalr	-788(ra) # 80000ffe <walk>
    8000131a:	84aa                	mv	s1,a0
    8000131c:	d56d                	beqz	a0,80001306 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0){
    8000131e:	611c                	ld	a5,0(a0)
    80001320:	0017f713          	andi	a4,a5,1
    80001324:	d36d                	beqz	a4,80001306 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001326:	3ff7f713          	andi	a4,a5,1023
    8000132a:	fd7704e3          	beq	a4,s7,800012f2 <uvmunmap+0x56>
    if(do_free){
    8000132e:	fc0b0ae3          	beqz	s6,80001302 <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    80001332:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001334:	00c79513          	slli	a0,a5,0xc
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	6aa080e7          	jalr	1706(ra) # 800009e2 <kfree>
    80001340:	b7c9                	j	80001302 <uvmunmap+0x66>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	794080e7          	jalr	1940(ra) # 80000ae0 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	9c2080e7          	jalr	-1598(ra) # 80000d1e <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	754080e7          	jalr	1876(ra) # 80000ae0 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	984080e7          	jalr	-1660(ra) # 80000d1e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d3a080e7          	jalr	-710(ra) # 800010e6 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	9c0080e7          	jalr	-1600(ra) # 80000d7a <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d4e50513          	addi	a0,a0,-690 # 80008120 <digits+0xe0>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	160080e7          	jalr	352(ra) # 8000053a <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	76fd                	lui	a3,0xfffff
    800013fe:	8f75                	and	a4,a4,a3
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff5                	and	a5,a5,a3
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e7c080e7          	jalr	-388(ra) # 8000129c <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6785                	lui	a5,0x1
    80001446:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001448:	95be                	add	a1,a1,a5
    8000144a:	77fd                	lui	a5,0xfffff
    8000144c:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	68a080e7          	jalr	1674(ra) # 80000ae0 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	8b8080e7          	jalr	-1864(ra) # 80000d1e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c6e080e7          	jalr	-914(ra) # 800010e6 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	530080e7          	jalr	1328(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a829                	j	80001508 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014f2:	00c79513          	slli	a0,a5,0xc
    800014f6:	00000097          	auipc	ra,0x0
    800014fa:	fde080e7          	jalr	-34(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fe:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001502:	04a1                	addi	s1,s1,8
    80001504:	03248163          	beq	s1,s2,80001526 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001508:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000150a:	00f7f713          	andi	a4,a5,15
    8000150e:	ff3701e3          	beq	a4,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001512:	8b85                	andi	a5,a5,1
    80001514:	d7fd                	beqz	a5,80001502 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001516:	00007517          	auipc	a0,0x7
    8000151a:	c2a50513          	addi	a0,a0,-982 # 80008140 <digits+0x100>
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	01c080e7          	jalr	28(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001526:	8552                	mv	a0,s4
    80001528:	fffff097          	auipc	ra,0xfffff
    8000152c:	4ba080e7          	jalr	1210(ra) # 800009e2 <kfree>
}
    80001530:	70a2                	ld	ra,40(sp)
    80001532:	7402                	ld	s0,32(sp)
    80001534:	64e2                	ld	s1,24(sp)
    80001536:	6942                	ld	s2,16(sp)
    80001538:	69a2                	ld	s3,8(sp)
    8000153a:	6a02                	ld	s4,0(sp)
    8000153c:	6145                	addi	sp,sp,48
    8000153e:	8082                	ret

0000000080001540 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001540:	1101                	addi	sp,sp,-32
    80001542:	ec06                	sd	ra,24(sp)
    80001544:	e822                	sd	s0,16(sp)
    80001546:	e426                	sd	s1,8(sp)
    80001548:	1000                	addi	s0,sp,32
    8000154a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154c:	e999                	bnez	a1,80001562 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154e:	8526                	mv	a0,s1
    80001550:	00000097          	auipc	ra,0x0
    80001554:	f84080e7          	jalr	-124(ra) # 800014d4 <freewalk>
}
    80001558:	60e2                	ld	ra,24(sp)
    8000155a:	6442                	ld	s0,16(sp)
    8000155c:	64a2                	ld	s1,8(sp)
    8000155e:	6105                	addi	sp,sp,32
    80001560:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001562:	6785                	lui	a5,0x1
    80001564:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001566:	95be                	add	a1,a1,a5
    80001568:	4685                	li	a3,1
    8000156a:	00c5d613          	srli	a2,a1,0xc
    8000156e:	4581                	li	a1,0
    80001570:	00000097          	auipc	ra,0x0
    80001574:	d2c080e7          	jalr	-724(ra) # 8000129c <uvmunmap>
    80001578:	bfd9                	j	8000154e <uvmfree+0xe>

000000008000157a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000157a:	ca4d                	beqz	a2,8000162c <uvmcopy+0xb2>
{
    8000157c:	715d                	addi	sp,sp,-80
    8000157e:	e486                	sd	ra,72(sp)
    80001580:	e0a2                	sd	s0,64(sp)
    80001582:	fc26                	sd	s1,56(sp)
    80001584:	f84a                	sd	s2,48(sp)
    80001586:	f44e                	sd	s3,40(sp)
    80001588:	f052                	sd	s4,32(sp)
    8000158a:	ec56                	sd	s5,24(sp)
    8000158c:	e85a                	sd	s6,16(sp)
    8000158e:	e45e                	sd	s7,8(sp)
    80001590:	0880                	addi	s0,sp,80
    80001592:	8aaa                	mv	s5,a0
    80001594:	8b2e                	mv	s6,a1
    80001596:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001598:	4481                	li	s1,0
    8000159a:	a029                	j	800015a4 <uvmcopy+0x2a>
    8000159c:	6785                	lui	a5,0x1
    8000159e:	94be                	add	s1,s1,a5
    800015a0:	0744fa63          	bgeu	s1,s4,80001614 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800015a4:	4601                	li	a2,0
    800015a6:	85a6                	mv	a1,s1
    800015a8:	8556                	mv	a0,s5
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	a54080e7          	jalr	-1452(ra) # 80000ffe <walk>
    800015b2:	d56d                	beqz	a0,8000159c <uvmcopy+0x22>
      //panic("uvmcopy: pte should exist");
      continue;
    if((*pte & PTE_V) == 0){
    800015b4:	6118                	ld	a4,0(a0)
    800015b6:	00177793          	andi	a5,a4,1
    800015ba:	d3ed                	beqz	a5,8000159c <uvmcopy+0x22>
      //panic("uvmcopy: page not present");
      continue;
      }
    pa = PTE2PA(*pte);
    800015bc:	00a75593          	srli	a1,a4,0xa
    800015c0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c4:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	518080e7          	jalr	1304(ra) # 80000ae0 <kalloc>
    800015d0:	89aa                	mv	s3,a0
    800015d2:	c515                	beqz	a0,800015fe <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d4:	6605                	lui	a2,0x1
    800015d6:	85de                	mv	a1,s7
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	7a2080e7          	jalr	1954(ra) # 80000d7a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015e0:	874a                	mv	a4,s2
    800015e2:	86ce                	mv	a3,s3
    800015e4:	6605                	lui	a2,0x1
    800015e6:	85a6                	mv	a1,s1
    800015e8:	855a                	mv	a0,s6
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	afc080e7          	jalr	-1284(ra) # 800010e6 <mappages>
    800015f2:	d54d                	beqz	a0,8000159c <uvmcopy+0x22>
      kfree(mem);
    800015f4:	854e                	mv	a0,s3
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	3ec080e7          	jalr	1004(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fe:	4685                	li	a3,1
    80001600:	00c4d613          	srli	a2,s1,0xc
    80001604:	4581                	li	a1,0
    80001606:	855a                	mv	a0,s6
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	c94080e7          	jalr	-876(ra) # 8000129c <uvmunmap>
  return -1;
    80001610:	557d                	li	a0,-1
    80001612:	a011                	j	80001616 <uvmcopy+0x9c>
  return 0;
    80001614:	4501                	li	a0,0
}
    80001616:	60a6                	ld	ra,72(sp)
    80001618:	6406                	ld	s0,64(sp)
    8000161a:	74e2                	ld	s1,56(sp)
    8000161c:	7942                	ld	s2,48(sp)
    8000161e:	79a2                	ld	s3,40(sp)
    80001620:	7a02                	ld	s4,32(sp)
    80001622:	6ae2                	ld	s5,24(sp)
    80001624:	6b42                	ld	s6,16(sp)
    80001626:	6ba2                	ld	s7,8(sp)
    80001628:	6161                	addi	sp,sp,80
    8000162a:	8082                	ret
  return 0;
    8000162c:	4501                	li	a0,0
}
    8000162e:	8082                	ret

0000000080001630 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001630:	1141                	addi	sp,sp,-16
    80001632:	e406                	sd	ra,8(sp)
    80001634:	e022                	sd	s0,0(sp)
    80001636:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001638:	4601                	li	a2,0
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	9c4080e7          	jalr	-1596(ra) # 80000ffe <walk>
  if(pte == 0)
    80001642:	c901                	beqz	a0,80001652 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001644:	611c                	ld	a5,0(a0)
    80001646:	9bbd                	andi	a5,a5,-17
    80001648:	e11c                	sd	a5,0(a0)
}
    8000164a:	60a2                	ld	ra,8(sp)
    8000164c:	6402                	ld	s0,0(sp)
    8000164e:	0141                	addi	sp,sp,16
    80001650:	8082                	ret
    panic("uvmclear");
    80001652:	00007517          	auipc	a0,0x7
    80001656:	afe50513          	addi	a0,a0,-1282 # 80008150 <digits+0x110>
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	ee0080e7          	jalr	-288(ra) # 8000053a <panic>

0000000080001662 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001662:	c6bd                	beqz	a3,800016d0 <copyout+0x6e>
{
    80001664:	715d                	addi	sp,sp,-80
    80001666:	e486                	sd	ra,72(sp)
    80001668:	e0a2                	sd	s0,64(sp)
    8000166a:	fc26                	sd	s1,56(sp)
    8000166c:	f84a                	sd	s2,48(sp)
    8000166e:	f44e                	sd	s3,40(sp)
    80001670:	f052                	sd	s4,32(sp)
    80001672:	ec56                	sd	s5,24(sp)
    80001674:	e85a                	sd	s6,16(sp)
    80001676:	e45e                	sd	s7,8(sp)
    80001678:	e062                	sd	s8,0(sp)
    8000167a:	0880                	addi	s0,sp,80
    8000167c:	8b2a                	mv	s6,a0
    8000167e:	8c2e                	mv	s8,a1
    80001680:	8a32                	mv	s4,a2
    80001682:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001684:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001686:	6a85                	lui	s5,0x1
    80001688:	a015                	j	800016ac <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168a:	9562                	add	a0,a0,s8
    8000168c:	0004861b          	sext.w	a2,s1
    80001690:	85d2                	mv	a1,s4
    80001692:	41250533          	sub	a0,a0,s2
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	6e4080e7          	jalr	1764(ra) # 80000d7a <memmove>

    len -= n;
    8000169e:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a8:	02098263          	beqz	s3,800016cc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ac:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b0:	85ca                	mv	a1,s2
    800016b2:	855a                	mv	a0,s6
    800016b4:	00000097          	auipc	ra,0x0
    800016b8:	9f0080e7          	jalr	-1552(ra) # 800010a4 <walkaddr>
    if(pa0 == 0)
    800016bc:	cd01                	beqz	a0,800016d4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016be:	418904b3          	sub	s1,s2,s8
    800016c2:	94d6                	add	s1,s1,s5
    800016c4:	fc99f3e3          	bgeu	s3,s1,8000168a <copyout+0x28>
    800016c8:	84ce                	mv	s1,s3
    800016ca:	b7c1                	j	8000168a <copyout+0x28>
  }
  return 0;
    800016cc:	4501                	li	a0,0
    800016ce:	a021                	j	800016d6 <copyout+0x74>
    800016d0:	4501                	li	a0,0
}
    800016d2:	8082                	ret
      return -1;
    800016d4:	557d                	li	a0,-1
}
    800016d6:	60a6                	ld	ra,72(sp)
    800016d8:	6406                	ld	s0,64(sp)
    800016da:	74e2                	ld	s1,56(sp)
    800016dc:	7942                	ld	s2,48(sp)
    800016de:	79a2                	ld	s3,40(sp)
    800016e0:	7a02                	ld	s4,32(sp)
    800016e2:	6ae2                	ld	s5,24(sp)
    800016e4:	6b42                	ld	s6,16(sp)
    800016e6:	6ba2                	ld	s7,8(sp)
    800016e8:	6c02                	ld	s8,0(sp)
    800016ea:	6161                	addi	sp,sp,80
    800016ec:	8082                	ret

00000000800016ee <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ee:	caa5                	beqz	a3,8000175e <copyin+0x70>
{
    800016f0:	715d                	addi	sp,sp,-80
    800016f2:	e486                	sd	ra,72(sp)
    800016f4:	e0a2                	sd	s0,64(sp)
    800016f6:	fc26                	sd	s1,56(sp)
    800016f8:	f84a                	sd	s2,48(sp)
    800016fa:	f44e                	sd	s3,40(sp)
    800016fc:	f052                	sd	s4,32(sp)
    800016fe:	ec56                	sd	s5,24(sp)
    80001700:	e85a                	sd	s6,16(sp)
    80001702:	e45e                	sd	s7,8(sp)
    80001704:	e062                	sd	s8,0(sp)
    80001706:	0880                	addi	s0,sp,80
    80001708:	8b2a                	mv	s6,a0
    8000170a:	8a2e                	mv	s4,a1
    8000170c:	8c32                	mv	s8,a2
    8000170e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001710:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001712:	6a85                	lui	s5,0x1
    80001714:	a01d                	j	8000173a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001716:	018505b3          	add	a1,a0,s8
    8000171a:	0004861b          	sext.w	a2,s1
    8000171e:	412585b3          	sub	a1,a1,s2
    80001722:	8552                	mv	a0,s4
    80001724:	fffff097          	auipc	ra,0xfffff
    80001728:	656080e7          	jalr	1622(ra) # 80000d7a <memmove>

    len -= n;
    8000172c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001730:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001732:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001736:	02098263          	beqz	s3,8000175a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000173e:	85ca                	mv	a1,s2
    80001740:	855a                	mv	a0,s6
    80001742:	00000097          	auipc	ra,0x0
    80001746:	962080e7          	jalr	-1694(ra) # 800010a4 <walkaddr>
    if(pa0 == 0)
    8000174a:	cd01                	beqz	a0,80001762 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000174c:	418904b3          	sub	s1,s2,s8
    80001750:	94d6                	add	s1,s1,s5
    80001752:	fc99f2e3          	bgeu	s3,s1,80001716 <copyin+0x28>
    80001756:	84ce                	mv	s1,s3
    80001758:	bf7d                	j	80001716 <copyin+0x28>
  }
  return 0;
    8000175a:	4501                	li	a0,0
    8000175c:	a021                	j	80001764 <copyin+0x76>
    8000175e:	4501                	li	a0,0
}
    80001760:	8082                	ret
      return -1;
    80001762:	557d                	li	a0,-1
}
    80001764:	60a6                	ld	ra,72(sp)
    80001766:	6406                	ld	s0,64(sp)
    80001768:	74e2                	ld	s1,56(sp)
    8000176a:	7942                	ld	s2,48(sp)
    8000176c:	79a2                	ld	s3,40(sp)
    8000176e:	7a02                	ld	s4,32(sp)
    80001770:	6ae2                	ld	s5,24(sp)
    80001772:	6b42                	ld	s6,16(sp)
    80001774:	6ba2                	ld	s7,8(sp)
    80001776:	6c02                	ld	s8,0(sp)
    80001778:	6161                	addi	sp,sp,80
    8000177a:	8082                	ret

000000008000177c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000177c:	c2dd                	beqz	a3,80001822 <copyinstr+0xa6>
{
    8000177e:	715d                	addi	sp,sp,-80
    80001780:	e486                	sd	ra,72(sp)
    80001782:	e0a2                	sd	s0,64(sp)
    80001784:	fc26                	sd	s1,56(sp)
    80001786:	f84a                	sd	s2,48(sp)
    80001788:	f44e                	sd	s3,40(sp)
    8000178a:	f052                	sd	s4,32(sp)
    8000178c:	ec56                	sd	s5,24(sp)
    8000178e:	e85a                	sd	s6,16(sp)
    80001790:	e45e                	sd	s7,8(sp)
    80001792:	0880                	addi	s0,sp,80
    80001794:	8a2a                	mv	s4,a0
    80001796:	8b2e                	mv	s6,a1
    80001798:	8bb2                	mv	s7,a2
    8000179a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000179c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000179e:	6985                	lui	s3,0x1
    800017a0:	a02d                	j	800017ca <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017a6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a8:	37fd                	addiw	a5,a5,-1
    800017aa:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ae:	60a6                	ld	ra,72(sp)
    800017b0:	6406                	ld	s0,64(sp)
    800017b2:	74e2                	ld	s1,56(sp)
    800017b4:	7942                	ld	s2,48(sp)
    800017b6:	79a2                	ld	s3,40(sp)
    800017b8:	7a02                	ld	s4,32(sp)
    800017ba:	6ae2                	ld	s5,24(sp)
    800017bc:	6b42                	ld	s6,16(sp)
    800017be:	6ba2                	ld	s7,8(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c8:	c8a9                	beqz	s1,8000181a <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ca:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ce:	85ca                	mv	a1,s2
    800017d0:	8552                	mv	a0,s4
    800017d2:	00000097          	auipc	ra,0x0
    800017d6:	8d2080e7          	jalr	-1838(ra) # 800010a4 <walkaddr>
    if(pa0 == 0)
    800017da:	c131                	beqz	a0,8000181e <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017dc:	417906b3          	sub	a3,s2,s7
    800017e0:	96ce                	add	a3,a3,s3
    800017e2:	00d4f363          	bgeu	s1,a3,800017e8 <copyinstr+0x6c>
    800017e6:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e8:	955e                	add	a0,a0,s7
    800017ea:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017ee:	daf9                	beqz	a3,800017c4 <copyinstr+0x48>
    800017f0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017f2:	41650633          	sub	a2,a0,s6
    800017f6:	fff48593          	addi	a1,s1,-1
    800017fa:	95da                	add	a1,a1,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017fe:	00f60733          	add	a4,a2,a5
    80001802:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001806:	df51                	beqz	a4,800017a2 <copyinstr+0x26>
        *dst = *p;
    80001808:	00e78023          	sb	a4,0(a5)
      --max;
    8000180c:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001810:	0785                	addi	a5,a5,1
    while(n > 0){
    80001812:	fed796e3          	bne	a5,a3,800017fe <copyinstr+0x82>
      dst++;
    80001816:	8b3e                	mv	s6,a5
    80001818:	b775                	j	800017c4 <copyinstr+0x48>
    8000181a:	4781                	li	a5,0
    8000181c:	b771                	j	800017a8 <copyinstr+0x2c>
      return -1;
    8000181e:	557d                	li	a0,-1
    80001820:	b779                	j	800017ae <copyinstr+0x32>
  int got_null = 0;
    80001822:	4781                	li	a5,0
  if(got_null){
    80001824:	37fd                	addiw	a5,a5,-1
    80001826:	0007851b          	sext.w	a0,a5
}
    8000182a:	8082                	ret

000000008000182c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000182c:	7139                	addi	sp,sp,-64
    8000182e:	fc06                	sd	ra,56(sp)
    80001830:	f822                	sd	s0,48(sp)
    80001832:	f426                	sd	s1,40(sp)
    80001834:	f04a                	sd	s2,32(sp)
    80001836:	ec4e                	sd	s3,24(sp)
    80001838:	e852                	sd	s4,16(sp)
    8000183a:	e456                	sd	s5,8(sp)
    8000183c:	e05a                	sd	s6,0(sp)
    8000183e:	0080                	addi	s0,sp,64
    80001840:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001842:	00010497          	auipc	s1,0x10
    80001846:	e8e48493          	addi	s1,s1,-370 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000184a:	8b26                	mv	s6,s1
    8000184c:	00006a97          	auipc	s5,0x6
    80001850:	7b4a8a93          	addi	s5,s5,1972 # 80008000 <etext>
    80001854:	04000937          	lui	s2,0x4000
    80001858:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00016a17          	auipc	s4,0x16
    80001860:	a74a0a13          	addi	s4,s4,-1420 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	27c080e7          	jalr	636(ra) # 80000ae0 <kalloc>
    8000186c:	862a                	mv	a2,a0
    if(pa == 0)
    8000186e:	c131                	beqz	a0,800018b2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001870:	416485b3          	sub	a1,s1,s6
    80001874:	8591                	srai	a1,a1,0x4
    80001876:	000ab783          	ld	a5,0(s5)
    8000187a:	02f585b3          	mul	a1,a1,a5
    8000187e:	2585                	addiw	a1,a1,1
    80001880:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001884:	4719                	li	a4,6
    80001886:	6685                	lui	a3,0x1
    80001888:	40b905b3          	sub	a1,s2,a1
    8000188c:	854e                	mv	a0,s3
    8000188e:	00000097          	auipc	ra,0x0
    80001892:	8e8080e7          	jalr	-1816(ra) # 80001176 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001896:	17048493          	addi	s1,s1,368
    8000189a:	fd4495e3          	bne	s1,s4,80001864 <proc_mapstacks+0x38>
  }
}
    8000189e:	70e2                	ld	ra,56(sp)
    800018a0:	7442                	ld	s0,48(sp)
    800018a2:	74a2                	ld	s1,40(sp)
    800018a4:	7902                	ld	s2,32(sp)
    800018a6:	69e2                	ld	s3,24(sp)
    800018a8:	6a42                	ld	s4,16(sp)
    800018aa:	6aa2                	ld	s5,8(sp)
    800018ac:	6b02                	ld	s6,0(sp)
    800018ae:	6121                	addi	sp,sp,64
    800018b0:	8082                	ret
      panic("kalloc");
    800018b2:	00007517          	auipc	a0,0x7
    800018b6:	8ae50513          	addi	a0,a0,-1874 # 80008160 <digits+0x120>
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	c80080e7          	jalr	-896(ra) # 8000053a <panic>

00000000800018c2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018c2:	7139                	addi	sp,sp,-64
    800018c4:	fc06                	sd	ra,56(sp)
    800018c6:	f822                	sd	s0,48(sp)
    800018c8:	f426                	sd	s1,40(sp)
    800018ca:	f04a                	sd	s2,32(sp)
    800018cc:	ec4e                	sd	s3,24(sp)
    800018ce:	e852                	sd	s4,16(sp)
    800018d0:	e456                	sd	s5,8(sp)
    800018d2:	e05a                	sd	s6,0(sp)
    800018d4:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018d6:	00007597          	auipc	a1,0x7
    800018da:	89258593          	addi	a1,a1,-1902 # 80008168 <digits+0x128>
    800018de:	00010517          	auipc	a0,0x10
    800018e2:	9c250513          	addi	a0,a0,-1598 # 800112a0 <pid_lock>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	2ac080e7          	jalr	684(ra) # 80000b92 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018ee:	00007597          	auipc	a1,0x7
    800018f2:	88258593          	addi	a1,a1,-1918 # 80008170 <digits+0x130>
    800018f6:	00010517          	auipc	a0,0x10
    800018fa:	9c250513          	addi	a0,a0,-1598 # 800112b8 <wait_lock>
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	294080e7          	jalr	660(ra) # 80000b92 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001906:	00010497          	auipc	s1,0x10
    8000190a:	dca48493          	addi	s1,s1,-566 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    8000190e:	00007b17          	auipc	s6,0x7
    80001912:	872b0b13          	addi	s6,s6,-1934 # 80008180 <digits+0x140>
      p->kstack = KSTACK((int) (p - proc));
    80001916:	8aa6                	mv	s5,s1
    80001918:	00006a17          	auipc	s4,0x6
    8000191c:	6e8a0a13          	addi	s4,s4,1768 # 80008000 <etext>
    80001920:	04000937          	lui	s2,0x4000
    80001924:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001926:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	00016997          	auipc	s3,0x16
    8000192c:	9a898993          	addi	s3,s3,-1624 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001930:	85da                	mv	a1,s6
    80001932:	8526                	mv	a0,s1
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	25e080e7          	jalr	606(ra) # 80000b92 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000193c:	415487b3          	sub	a5,s1,s5
    80001940:	8791                	srai	a5,a5,0x4
    80001942:	000a3703          	ld	a4,0(s4)
    80001946:	02e787b3          	mul	a5,a5,a4
    8000194a:	2785                	addiw	a5,a5,1
    8000194c:	00d7979b          	slliw	a5,a5,0xd
    80001950:	40f907b3          	sub	a5,s2,a5
    80001954:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001956:	17048493          	addi	s1,s1,368
    8000195a:	fd349be3          	bne	s1,s3,80001930 <procinit+0x6e>
  }
}
    8000195e:	70e2                	ld	ra,56(sp)
    80001960:	7442                	ld	s0,48(sp)
    80001962:	74a2                	ld	s1,40(sp)
    80001964:	7902                	ld	s2,32(sp)
    80001966:	69e2                	ld	s3,24(sp)
    80001968:	6a42                	ld	s4,16(sp)
    8000196a:	6aa2                	ld	s5,8(sp)
    8000196c:	6b02                	ld	s6,0(sp)
    8000196e:	6121                	addi	sp,sp,64
    80001970:	8082                	ret

0000000080001972 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001972:	1141                	addi	sp,sp,-16
    80001974:	e422                	sd	s0,8(sp)
    80001976:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001978:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000197a:	2501                	sext.w	a0,a0
    8000197c:	6422                	ld	s0,8(sp)
    8000197e:	0141                	addi	sp,sp,16
    80001980:	8082                	ret

0000000080001982 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001982:	1141                	addi	sp,sp,-16
    80001984:	e422                	sd	s0,8(sp)
    80001986:	0800                	addi	s0,sp,16
    80001988:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000198a:	2781                	sext.w	a5,a5
    8000198c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000198e:	00010517          	auipc	a0,0x10
    80001992:	94250513          	addi	a0,a0,-1726 # 800112d0 <cpus>
    80001996:	953e                	add	a0,a0,a5
    80001998:	6422                	ld	s0,8(sp)
    8000199a:	0141                	addi	sp,sp,16
    8000199c:	8082                	ret

000000008000199e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000199e:	1101                	addi	sp,sp,-32
    800019a0:	ec06                	sd	ra,24(sp)
    800019a2:	e822                	sd	s0,16(sp)
    800019a4:	e426                	sd	s1,8(sp)
    800019a6:	1000                	addi	s0,sp,32
  push_off();
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	22e080e7          	jalr	558(ra) # 80000bd6 <push_off>
    800019b0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
    800019b6:	00010717          	auipc	a4,0x10
    800019ba:	8ea70713          	addi	a4,a4,-1814 # 800112a0 <pid_lock>
    800019be:	97ba                	add	a5,a5,a4
    800019c0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	2b4080e7          	jalr	692(ra) # 80000c76 <pop_off>
  return p;
}
    800019ca:	8526                	mv	a0,s1
    800019cc:	60e2                	ld	ra,24(sp)
    800019ce:	6442                	ld	s0,16(sp)
    800019d0:	64a2                	ld	s1,8(sp)
    800019d2:	6105                	addi	sp,sp,32
    800019d4:	8082                	ret

00000000800019d6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e406                	sd	ra,8(sp)
    800019da:	e022                	sd	s0,0(sp)
    800019dc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019de:	00000097          	auipc	ra,0x0
    800019e2:	fc0080e7          	jalr	-64(ra) # 8000199e <myproc>
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	2f0080e7          	jalr	752(ra) # 80000cd6 <release>

  if (first) {
    800019ee:	00007797          	auipc	a5,0x7
    800019f2:	dd27a783          	lw	a5,-558(a5) # 800087c0 <first.1>
    800019f6:	eb89                	bnez	a5,80001a08 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f8:	00001097          	auipc	ra,0x1
    800019fc:	f8a080e7          	jalr	-118(ra) # 80002982 <usertrapret>
}
    80001a00:	60a2                	ld	ra,8(sp)
    80001a02:	6402                	ld	s0,0(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret
    first = 0;
    80001a08:	00007797          	auipc	a5,0x7
    80001a0c:	da07ac23          	sw	zero,-584(a5) # 800087c0 <first.1>
    fsinit(ROOTDEV);
    80001a10:	4505                	li	a0,1
    80001a12:	00002097          	auipc	ra,0x2
    80001a16:	e62080e7          	jalr	-414(ra) # 80003874 <fsinit>
    80001a1a:	bff9                	j	800019f8 <forkret+0x22>

0000000080001a1c <allocpid>:
allocpid() {
    80001a1c:	1101                	addi	sp,sp,-32
    80001a1e:	ec06                	sd	ra,24(sp)
    80001a20:	e822                	sd	s0,16(sp)
    80001a22:	e426                	sd	s1,8(sp)
    80001a24:	e04a                	sd	s2,0(sp)
    80001a26:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a28:	00010917          	auipc	s2,0x10
    80001a2c:	87890913          	addi	s2,s2,-1928 # 800112a0 <pid_lock>
    80001a30:	854a                	mv	a0,s2
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	1f0080e7          	jalr	496(ra) # 80000c22 <acquire>
  pid = nextpid;
    80001a3a:	00007797          	auipc	a5,0x7
    80001a3e:	d8a78793          	addi	a5,a5,-630 # 800087c4 <nextpid>
    80001a42:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a44:	0014871b          	addiw	a4,s1,1
    80001a48:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a4a:	854a                	mv	a0,s2
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	28a080e7          	jalr	650(ra) # 80000cd6 <release>
}
    80001a54:	8526                	mv	a0,s1
    80001a56:	60e2                	ld	ra,24(sp)
    80001a58:	6442                	ld	s0,16(sp)
    80001a5a:	64a2                	ld	s1,8(sp)
    80001a5c:	6902                	ld	s2,0(sp)
    80001a5e:	6105                	addi	sp,sp,32
    80001a60:	8082                	ret

0000000080001a62 <proc_pagetable>:
{
    80001a62:	1101                	addi	sp,sp,-32
    80001a64:	ec06                	sd	ra,24(sp)
    80001a66:	e822                	sd	s0,16(sp)
    80001a68:	e426                	sd	s1,8(sp)
    80001a6a:	e04a                	sd	s2,0(sp)
    80001a6c:	1000                	addi	s0,sp,32
    80001a6e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	8d2080e7          	jalr	-1838(ra) # 80001342 <uvmcreate>
    80001a78:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a7a:	c121                	beqz	a0,80001aba <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a7c:	4729                	li	a4,10
    80001a7e:	00005697          	auipc	a3,0x5
    80001a82:	58268693          	addi	a3,a3,1410 # 80007000 <_trampoline>
    80001a86:	6605                	lui	a2,0x1
    80001a88:	040005b7          	lui	a1,0x4000
    80001a8c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a8e:	05b2                	slli	a1,a1,0xc
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	656080e7          	jalr	1622(ra) # 800010e6 <mappages>
    80001a98:	02054863          	bltz	a0,80001ac8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a9c:	4719                	li	a4,6
    80001a9e:	06093683          	ld	a3,96(s2)
    80001aa2:	6605                	lui	a2,0x1
    80001aa4:	020005b7          	lui	a1,0x2000
    80001aa8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aaa:	05b6                	slli	a1,a1,0xd
    80001aac:	8526                	mv	a0,s1
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	638080e7          	jalr	1592(ra) # 800010e6 <mappages>
    80001ab6:	02054163          	bltz	a0,80001ad8 <proc_pagetable+0x76>
}
    80001aba:	8526                	mv	a0,s1
    80001abc:	60e2                	ld	ra,24(sp)
    80001abe:	6442                	ld	s0,16(sp)
    80001ac0:	64a2                	ld	s1,8(sp)
    80001ac2:	6902                	ld	s2,0(sp)
    80001ac4:	6105                	addi	sp,sp,32
    80001ac6:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac8:	4581                	li	a1,0
    80001aca:	8526                	mv	a0,s1
    80001acc:	00000097          	auipc	ra,0x0
    80001ad0:	a74080e7          	jalr	-1420(ra) # 80001540 <uvmfree>
    return 0;
    80001ad4:	4481                	li	s1,0
    80001ad6:	b7d5                	j	80001aba <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad8:	4681                	li	a3,0
    80001ada:	4605                	li	a2,1
    80001adc:	040005b7          	lui	a1,0x4000
    80001ae0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ae2:	05b2                	slli	a1,a1,0xc
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	7b6080e7          	jalr	1974(ra) # 8000129c <uvmunmap>
    uvmfree(pagetable, 0);
    80001aee:	4581                	li	a1,0
    80001af0:	8526                	mv	a0,s1
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	a4e080e7          	jalr	-1458(ra) # 80001540 <uvmfree>
    return 0;
    80001afa:	4481                	li	s1,0
    80001afc:	bf7d                	j	80001aba <proc_pagetable+0x58>

0000000080001afe <proc_freepagetable>:
{
    80001afe:	1101                	addi	sp,sp,-32
    80001b00:	ec06                	sd	ra,24(sp)
    80001b02:	e822                	sd	s0,16(sp)
    80001b04:	e426                	sd	s1,8(sp)
    80001b06:	e04a                	sd	s2,0(sp)
    80001b08:	1000                	addi	s0,sp,32
    80001b0a:	84aa                	mv	s1,a0
    80001b0c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0e:	4681                	li	a3,0
    80001b10:	4605                	li	a2,1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	782080e7          	jalr	1922(ra) # 8000129c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b22:	4681                	li	a3,0
    80001b24:	4605                	li	a2,1
    80001b26:	020005b7          	lui	a1,0x2000
    80001b2a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b2c:	05b6                	slli	a1,a1,0xd
    80001b2e:	8526                	mv	a0,s1
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	76c080e7          	jalr	1900(ra) # 8000129c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b38:	85ca                	mv	a1,s2
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	a04080e7          	jalr	-1532(ra) # 80001540 <uvmfree>
}
    80001b44:	60e2                	ld	ra,24(sp)
    80001b46:	6442                	ld	s0,16(sp)
    80001b48:	64a2                	ld	s1,8(sp)
    80001b4a:	6902                	ld	s2,0(sp)
    80001b4c:	6105                	addi	sp,sp,32
    80001b4e:	8082                	ret

0000000080001b50 <freeproc>:
{
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	1000                	addi	s0,sp,32
    80001b5a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b5c:	7128                	ld	a0,96(a0)
    80001b5e:	c509                	beqz	a0,80001b68 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	e82080e7          	jalr	-382(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b68:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b6c:	6ca8                	ld	a0,88(s1)
    80001b6e:	c511                	beqz	a0,80001b7a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b70:	68ac                	ld	a1,80(s1)
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	f8c080e7          	jalr	-116(ra) # 80001afe <proc_freepagetable>
  p->pagetable = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b7e:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001b82:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b86:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001b8a:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b8e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b92:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b96:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b9a:	0004ac23          	sw	zero,24(s1)
}
    80001b9e:	60e2                	ld	ra,24(sp)
    80001ba0:	6442                	ld	s0,16(sp)
    80001ba2:	64a2                	ld	s1,8(sp)
    80001ba4:	6105                	addi	sp,sp,32
    80001ba6:	8082                	ret

0000000080001ba8 <allocproc>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	e04a                	sd	s2,0(sp)
    80001bb2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb4:	00010497          	auipc	s1,0x10
    80001bb8:	b1c48493          	addi	s1,s1,-1252 # 800116d0 <proc>
    80001bbc:	00015917          	auipc	s2,0x15
    80001bc0:	71490913          	addi	s2,s2,1812 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	05c080e7          	jalr	92(ra) # 80000c22 <acquire>
    if(p->state == UNUSED) {
    80001bce:	4c9c                	lw	a5,24(s1)
    80001bd0:	cf81                	beqz	a5,80001be8 <allocproc+0x40>
      release(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	102080e7          	jalr	258(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	17048493          	addi	s1,s1,368
    80001be0:	ff2492e3          	bne	s1,s2,80001bc4 <allocproc+0x1c>
  return 0;
    80001be4:	4481                	li	s1,0
    80001be6:	a899                	j	80001c3c <allocproc+0x94>
  p->cputime = 0;
    80001be8:	0204aa23          	sw	zero,52(s1)
  p->pid = allocpid();
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	e30080e7          	jalr	-464(ra) # 80001a1c <allocpid>
    80001bf4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bf6:	4785                	li	a5,1
    80001bf8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	ee6080e7          	jalr	-282(ra) # 80000ae0 <kalloc>
    80001c02:	892a                	mv	s2,a0
    80001c04:	f0a8                	sd	a0,96(s1)
    80001c06:	c131                	beqz	a0,80001c4a <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e58080e7          	jalr	-424(ra) # 80001a62 <proc_pagetable>
    80001c12:	892a                	mv	s2,a0
    80001c14:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c16:	c531                	beqz	a0,80001c62 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c18:	07000613          	li	a2,112
    80001c1c:	4581                	li	a1,0
    80001c1e:	06848513          	addi	a0,s1,104
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	0fc080e7          	jalr	252(ra) # 80000d1e <memset>
  p->context.ra = (uint64)forkret;
    80001c2a:	00000797          	auipc	a5,0x0
    80001c2e:	dac78793          	addi	a5,a5,-596 # 800019d6 <forkret>
    80001c32:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c34:	64bc                	ld	a5,72(s1)
    80001c36:	6705                	lui	a4,0x1
    80001c38:	97ba                	add	a5,a5,a4
    80001c3a:	f8bc                	sd	a5,112(s1)
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    freeproc(p);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	f04080e7          	jalr	-252(ra) # 80001b50 <freeproc>
    release(&p->lock);
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	080080e7          	jalr	128(ra) # 80000cd6 <release>
    return 0;
    80001c5e:	84ca                	mv	s1,s2
    80001c60:	bff1                	j	80001c3c <allocproc+0x94>
    freeproc(p);
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	eec080e7          	jalr	-276(ra) # 80001b50 <freeproc>
    release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	068080e7          	jalr	104(ra) # 80000cd6 <release>
    return 0;
    80001c76:	84ca                	mv	s1,s2
    80001c78:	b7d1                	j	80001c3c <allocproc+0x94>

0000000080001c7a <userinit>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	f24080e7          	jalr	-220(ra) # 80001ba8 <allocproc>
    80001c8c:	84aa                	mv	s1,a0
  initproc = p;
    80001c8e:	00007797          	auipc	a5,0x7
    80001c92:	38a7bd23          	sd	a0,922(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c96:	03400613          	li	a2,52
    80001c9a:	00007597          	auipc	a1,0x7
    80001c9e:	b3658593          	addi	a1,a1,-1226 # 800087d0 <initcode>
    80001ca2:	6d28                	ld	a0,88(a0)
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	6cc080e7          	jalr	1740(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cac:	6785                	lui	a5,0x1
    80001cae:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb0:	70b8                	ld	a4,96(s1)
    80001cb2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb6:	70b8                	ld	a4,96(s1)
    80001cb8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cba:	4641                	li	a2,16
    80001cbc:	00006597          	auipc	a1,0x6
    80001cc0:	4cc58593          	addi	a1,a1,1228 # 80008188 <digits+0x148>
    80001cc4:	16048513          	addi	a0,s1,352
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	1a0080e7          	jalr	416(ra) # 80000e68 <safestrcpy>
  p->cwd = namei("/");
    80001cd0:	00006517          	auipc	a0,0x6
    80001cd4:	4c850513          	addi	a0,a0,1224 # 80008198 <digits+0x158>
    80001cd8:	00002097          	auipc	ra,0x2
    80001cdc:	5d2080e7          	jalr	1490(ra) # 800042aa <namei>
    80001ce0:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001ce4:	478d                	li	a5,3
    80001ce6:	cc9c                	sw	a5,24(s1)
  p->readytime = sys_uptime();
    80001ce8:	00001097          	auipc	ra,0x1
    80001cec:	502080e7          	jalr	1282(ra) # 800031ea <sys_uptime>
    80001cf0:	dcc8                	sw	a0,60(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	fe2080e7          	jalr	-30(ra) # 80000cd6 <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c8a080e7          	jalr	-886(ra) # 8000199e <myproc>
    80001d1c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d1e:	692c                	ld	a1,80(a0)
    80001d20:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d24:	00904f63          	bgtz	s1,80001d42 <growproc+0x3c>
  } else if(n < 0){
    80001d28:	0204cd63          	bltz	s1,80001d62 <growproc+0x5c>
  p->sz = sz;
    80001d2c:	1782                	slli	a5,a5,0x20
    80001d2e:	9381                	srli	a5,a5,0x20
    80001d30:	04f93823          	sd	a5,80(s2)
  return 0;
    80001d34:	4501                	li	a0,0
}
    80001d36:	60e2                	ld	ra,24(sp)
    80001d38:	6442                	ld	s0,16(sp)
    80001d3a:	64a2                	ld	s1,8(sp)
    80001d3c:	6902                	ld	s2,0(sp)
    80001d3e:	6105                	addi	sp,sp,32
    80001d40:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d42:	00f4863b          	addw	a2,s1,a5
    80001d46:	1602                	slli	a2,a2,0x20
    80001d48:	9201                	srli	a2,a2,0x20
    80001d4a:	1582                	slli	a1,a1,0x20
    80001d4c:	9181                	srli	a1,a1,0x20
    80001d4e:	6d28                	ld	a0,88(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	6da080e7          	jalr	1754(ra) # 8000142a <uvmalloc>
    80001d58:	0005079b          	sext.w	a5,a0
    80001d5c:	fbe1                	bnez	a5,80001d2c <growproc+0x26>
      return -1;
    80001d5e:	557d                	li	a0,-1
    80001d60:	bfd9                	j	80001d36 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d62:	00f4863b          	addw	a2,s1,a5
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6d28                	ld	a0,88(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	672080e7          	jalr	1650(ra) # 800013e2 <uvmdealloc>
    80001d78:	0005079b          	sext.w	a5,a0
    80001d7c:	bf45                	j	80001d2c <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7139                	addi	sp,sp,-64
    80001d80:	fc06                	sd	ra,56(sp)
    80001d82:	f822                	sd	s0,48(sp)
    80001d84:	f426                	sd	s1,40(sp)
    80001d86:	f04a                	sd	s2,32(sp)
    80001d88:	ec4e                	sd	s3,24(sp)
    80001d8a:	e852                	sd	s4,16(sp)
    80001d8c:	e456                	sd	s5,8(sp)
    80001d8e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	c0e080e7          	jalr	-1010(ra) # 8000199e <myproc>
    80001d98:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	e0e080e7          	jalr	-498(ra) # 80001ba8 <allocproc>
    80001da2:	12050263          	beqz	a0,80001ec6 <fork+0x148>
    80001da6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da8:	050ab603          	ld	a2,80(s5)
    80001dac:	6d2c                	ld	a1,88(a0)
    80001dae:	058ab503          	ld	a0,88(s5)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	7c8080e7          	jalr	1992(ra) # 8000157a <uvmcopy>
    80001dba:	04054863          	bltz	a0,80001e0a <fork+0x8c>
  np->sz = p->sz;
    80001dbe:	050ab783          	ld	a5,80(s5)
    80001dc2:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc6:	060ab683          	ld	a3,96(s5)
    80001dca:	87b6                	mv	a5,a3
    80001dcc:	0609b703          	ld	a4,96(s3)
    80001dd0:	12068693          	addi	a3,a3,288
    80001dd4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd8:	6788                	ld	a0,8(a5)
    80001dda:	6b8c                	ld	a1,16(a5)
    80001ddc:	6f90                	ld	a2,24(a5)
    80001dde:	01073023          	sd	a6,0(a4)
    80001de2:	e708                	sd	a0,8(a4)
    80001de4:	eb0c                	sd	a1,16(a4)
    80001de6:	ef10                	sd	a2,24(a4)
    80001de8:	02078793          	addi	a5,a5,32
    80001dec:	02070713          	addi	a4,a4,32
    80001df0:	fed792e3          	bne	a5,a3,80001dd4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001df4:	0609b783          	ld	a5,96(s3)
    80001df8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dfc:	0d8a8493          	addi	s1,s5,216
    80001e00:	0d898913          	addi	s2,s3,216
    80001e04:	158a8a13          	addi	s4,s5,344
    80001e08:	a00d                	j	80001e2a <fork+0xac>
    freeproc(np);
    80001e0a:	854e                	mv	a0,s3
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	d44080e7          	jalr	-700(ra) # 80001b50 <freeproc>
    release(&np->lock);
    80001e14:	854e                	mv	a0,s3
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	ec0080e7          	jalr	-320(ra) # 80000cd6 <release>
    return -1;
    80001e1e:	597d                	li	s2,-1
    80001e20:	a849                	j	80001eb2 <fork+0x134>
  for(i = 0; i < NOFILE; i++)
    80001e22:	04a1                	addi	s1,s1,8
    80001e24:	0921                	addi	s2,s2,8
    80001e26:	01448b63          	beq	s1,s4,80001e3c <fork+0xbe>
    if(p->ofile[i])
    80001e2a:	6088                	ld	a0,0(s1)
    80001e2c:	d97d                	beqz	a0,80001e22 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2e:	00003097          	auipc	ra,0x3
    80001e32:	b12080e7          	jalr	-1262(ra) # 80004940 <filedup>
    80001e36:	00a93023          	sd	a0,0(s2)
    80001e3a:	b7e5                	j	80001e22 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e3c:	158ab503          	ld	a0,344(s5)
    80001e40:	00002097          	auipc	ra,0x2
    80001e44:	c70080e7          	jalr	-912(ra) # 80003ab0 <idup>
    80001e48:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4c:	4641                	li	a2,16
    80001e4e:	160a8593          	addi	a1,s5,352
    80001e52:	16098513          	addi	a0,s3,352
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	012080e7          	jalr	18(ra) # 80000e68 <safestrcpy>
  pid = np->pid;
    80001e5e:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e62:	854e                	mv	a0,s3
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	e72080e7          	jalr	-398(ra) # 80000cd6 <release>
  acquire(&wait_lock);
    80001e6c:	0000f497          	auipc	s1,0xf
    80001e70:	44c48493          	addi	s1,s1,1100 # 800112b8 <wait_lock>
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	dac080e7          	jalr	-596(ra) # 80000c22 <acquire>
  np->parent = p;
    80001e7e:	0559b023          	sd	s5,64(s3)
  release(&wait_lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e52080e7          	jalr	-430(ra) # 80000cd6 <release>
  acquire(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	d94080e7          	jalr	-620(ra) # 80000c22 <acquire>
  np->state = RUNNABLE;
    80001e96:	478d                	li	a5,3
    80001e98:	00f9ac23          	sw	a5,24(s3)
  np->readytime = sys_uptime();
    80001e9c:	00001097          	auipc	ra,0x1
    80001ea0:	34e080e7          	jalr	846(ra) # 800031ea <sys_uptime>
    80001ea4:	02a9ae23          	sw	a0,60(s3)
  release(&np->lock);
    80001ea8:	854e                	mv	a0,s3
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	e2c080e7          	jalr	-468(ra) # 80000cd6 <release>
}
    80001eb2:	854a                	mv	a0,s2
    80001eb4:	70e2                	ld	ra,56(sp)
    80001eb6:	7442                	ld	s0,48(sp)
    80001eb8:	74a2                	ld	s1,40(sp)
    80001eba:	7902                	ld	s2,32(sp)
    80001ebc:	69e2                	ld	s3,24(sp)
    80001ebe:	6a42                	ld	s4,16(sp)
    80001ec0:	6aa2                	ld	s5,8(sp)
    80001ec2:	6121                	addi	sp,sp,64
    80001ec4:	8082                	ret
    return -1;
    80001ec6:	597d                	li	s2,-1
    80001ec8:	b7ed                	j	80001eb2 <fork+0x134>

0000000080001eca <min>:
int min(int a, int b){
    80001eca:	1141                	addi	sp,sp,-16
    80001ecc:	e422                	sd	s0,8(sp)
    80001ece:	0800                	addi	s0,sp,16
return (a< b) ? a : b;
    80001ed0:	87ae                	mv	a5,a1
    80001ed2:	00b55363          	bge	a0,a1,80001ed8 <min+0xe>
    80001ed6:	87aa                	mv	a5,a0
}
    80001ed8:	0007851b          	sext.w	a0,a5
    80001edc:	6422                	ld	s0,8(sp)
    80001ede:	0141                	addi	sp,sp,16
    80001ee0:	8082                	ret

0000000080001ee2 <scheduler>:
{
    80001ee2:	7139                	addi	sp,sp,-64
    80001ee4:	fc06                	sd	ra,56(sp)
    80001ee6:	f822                	sd	s0,48(sp)
    80001ee8:	f426                	sd	s1,40(sp)
    80001eea:	f04a                	sd	s2,32(sp)
    80001eec:	ec4e                	sd	s3,24(sp)
    80001eee:	e852                	sd	s4,16(sp)
    80001ef0:	e456                	sd	s5,8(sp)
    80001ef2:	e05a                	sd	s6,0(sp)
    80001ef4:	0080                	addi	s0,sp,64
    80001ef6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efa:	00779a93          	slli	s5,a5,0x7
    80001efe:	0000f717          	auipc	a4,0xf
    80001f02:	3a270713          	addi	a4,a4,930 # 800112a0 <pid_lock>
    80001f06:	9756                	add	a4,a4,s5
    80001f08:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f0c:	0000f717          	auipc	a4,0xf
    80001f10:	3cc70713          	addi	a4,a4,972 # 800112d8 <cpus+0x8>
    80001f14:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f16:	498d                	li	s3,3
        p->state = RUNNING;
    80001f18:	4b11                	li	s6,4
        c->proc = p;
    80001f1a:	079e                	slli	a5,a5,0x7
    80001f1c:	0000fa17          	auipc	s4,0xf
    80001f20:	384a0a13          	addi	s4,s4,900 # 800112a0 <pid_lock>
    80001f24:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f26:	00015917          	auipc	s2,0x15
    80001f2a:	3aa90913          	addi	s2,s2,938 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f32:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f36:	10079073          	csrw	sstatus,a5
    80001f3a:	0000f497          	auipc	s1,0xf
    80001f3e:	79648493          	addi	s1,s1,1942 # 800116d0 <proc>
    80001f42:	a811                	j	80001f56 <scheduler+0x74>
      release(&p->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d90080e7          	jalr	-624(ra) # 80000cd6 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4e:	17048493          	addi	s1,s1,368
    80001f52:	fd248ee3          	beq	s1,s2,80001f2e <scheduler+0x4c>
      acquire(&p->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	cca080e7          	jalr	-822(ra) # 80000c22 <acquire>
      if(p->state == RUNNABLE) {
    80001f60:	4c9c                	lw	a5,24(s1)
    80001f62:	ff3791e3          	bne	a5,s3,80001f44 <scheduler+0x62>
        p->state = RUNNING;
    80001f66:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f6a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f6e:	06848593          	addi	a1,s1,104
    80001f72:	8556                	mv	a0,s5
    80001f74:	00001097          	auipc	ra,0x1
    80001f78:	964080e7          	jalr	-1692(ra) # 800028d8 <swtch>
        c->proc = 0;
    80001f7c:	020a3823          	sd	zero,48(s4)
    80001f80:	b7d1                	j	80001f44 <scheduler+0x62>

0000000080001f82 <sched>:
{
    80001f82:	7179                	addi	sp,sp,-48
    80001f84:	f406                	sd	ra,40(sp)
    80001f86:	f022                	sd	s0,32(sp)
    80001f88:	ec26                	sd	s1,24(sp)
    80001f8a:	e84a                	sd	s2,16(sp)
    80001f8c:	e44e                	sd	s3,8(sp)
    80001f8e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	a0e080e7          	jalr	-1522(ra) # 8000199e <myproc>
    80001f98:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	c0e080e7          	jalr	-1010(ra) # 80000ba8 <holding>
    80001fa2:	c93d                	beqz	a0,80002018 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000f717          	auipc	a4,0xf
    80001fae:	2f670713          	addi	a4,a4,758 # 800112a0 <pid_lock>
    80001fb2:	97ba                	add	a5,a5,a4
    80001fb4:	0a87a703          	lw	a4,168(a5)
    80001fb8:	4785                	li	a5,1
    80001fba:	06f71763          	bne	a4,a5,80002028 <sched+0xa6>
  if(p->state == RUNNING)
    80001fbe:	4c98                	lw	a4,24(s1)
    80001fc0:	4791                	li	a5,4
    80001fc2:	06f70b63          	beq	a4,a5,80002038 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fca:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fcc:	efb5                	bnez	a5,80002048 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fce:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fd0:	0000f917          	auipc	s2,0xf
    80001fd4:	2d090913          	addi	s2,s2,720 # 800112a0 <pid_lock>
    80001fd8:	2781                	sext.w	a5,a5
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	97ca                	add	a5,a5,s2
    80001fde:	0ac7a983          	lw	s3,172(a5)
    80001fe2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	0000f597          	auipc	a1,0xf
    80001fec:	2f058593          	addi	a1,a1,752 # 800112d8 <cpus+0x8>
    80001ff0:	95be                	add	a1,a1,a5
    80001ff2:	06848513          	addi	a0,s1,104
    80001ff6:	00001097          	auipc	ra,0x1
    80001ffa:	8e2080e7          	jalr	-1822(ra) # 800028d8 <swtch>
    80001ffe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	993e                	add	s2,s2,a5
    80002006:	0b392623          	sw	s3,172(s2)
}
    8000200a:	70a2                	ld	ra,40(sp)
    8000200c:	7402                	ld	s0,32(sp)
    8000200e:	64e2                	ld	s1,24(sp)
    80002010:	6942                	ld	s2,16(sp)
    80002012:	69a2                	ld	s3,8(sp)
    80002014:	6145                	addi	sp,sp,48
    80002016:	8082                	ret
    panic("sched p->lock");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	18850513          	addi	a0,a0,392 # 800081a0 <digits+0x160>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	51a080e7          	jalr	1306(ra) # 8000053a <panic>
    panic("sched locks");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	18850513          	addi	a0,a0,392 # 800081b0 <digits+0x170>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50a080e7          	jalr	1290(ra) # 8000053a <panic>
    panic("sched running");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	18850513          	addi	a0,a0,392 # 800081c0 <digits+0x180>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fa080e7          	jalr	1274(ra) # 8000053a <panic>
    panic("sched interruptible");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	18850513          	addi	a0,a0,392 # 800081d0 <digits+0x190>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4ea080e7          	jalr	1258(ra) # 8000053a <panic>

0000000080002058 <yield>:
{
    80002058:	1101                	addi	sp,sp,-32
    8000205a:	ec06                	sd	ra,24(sp)
    8000205c:	e822                	sd	s0,16(sp)
    8000205e:	e426                	sd	s1,8(sp)
    80002060:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002062:	00000097          	auipc	ra,0x0
    80002066:	93c080e7          	jalr	-1732(ra) # 8000199e <myproc>
    8000206a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	bb6080e7          	jalr	-1098(ra) # 80000c22 <acquire>
  p->state = RUNNABLE;
    80002074:	478d                	li	a5,3
    80002076:	cc9c                	sw	a5,24(s1)
  p->readytime = sys_uptime();
    80002078:	00001097          	auipc	ra,0x1
    8000207c:	172080e7          	jalr	370(ra) # 800031ea <sys_uptime>
    80002080:	dcc8                	sw	a0,60(s1)
  sched();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	f00080e7          	jalr	-256(ra) # 80001f82 <sched>
  release(&p->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c4a080e7          	jalr	-950(ra) # 80000cd6 <release>
}
    80002094:	60e2                	ld	ra,24(sp)
    80002096:	6442                	ld	s0,16(sp)
    80002098:	64a2                	ld	s1,8(sp)
    8000209a:	6105                	addi	sp,sp,32
    8000209c:	8082                	ret

000000008000209e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000209e:	7179                	addi	sp,sp,-48
    800020a0:	f406                	sd	ra,40(sp)
    800020a2:	f022                	sd	s0,32(sp)
    800020a4:	ec26                	sd	s1,24(sp)
    800020a6:	e84a                	sd	s2,16(sp)
    800020a8:	e44e                	sd	s3,8(sp)
    800020aa:	1800                	addi	s0,sp,48
    800020ac:	89aa                	mv	s3,a0
    800020ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	8ee080e7          	jalr	-1810(ra) # 8000199e <myproc>
    800020b8:	84aa                	mv	s1,a0
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  acquire(&p->lock);  //DOC: sleeplock1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b68080e7          	jalr	-1176(ra) # 80000c22 <acquire>
  release(lk);
    800020c2:	854a                	mv	a0,s2
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	c12080e7          	jalr	-1006(ra) # 80000cd6 <release>
  // Go to sleep.
  p->chan = chan;
    800020cc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d0:	4789                	li	a5,2
    800020d2:	cc9c                	sw	a5,24(s1)

  sched();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	eae080e7          	jalr	-338(ra) # 80001f82 <sched>
  // Tidy up.
  p->chan = 0;
    800020dc:	0204b023          	sd	zero,32(s1)
  
  // Reacquire original lock.
  release(&p->lock);
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	bf4080e7          	jalr	-1036(ra) # 80000cd6 <release>
  acquire(lk);
    800020ea:	854a                	mv	a0,s2
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	b36080e7          	jalr	-1226(ra) # 80000c22 <acquire>
}
    800020f4:	70a2                	ld	ra,40(sp)
    800020f6:	7402                	ld	s0,32(sp)
    800020f8:	64e2                	ld	s1,24(sp)
    800020fa:	6942                	ld	s2,16(sp)
    800020fc:	69a2                	ld	s3,8(sp)
    800020fe:	6145                	addi	sp,sp,48
    80002100:	8082                	ret

0000000080002102 <wait>:
{
    80002102:	715d                	addi	sp,sp,-80
    80002104:	e486                	sd	ra,72(sp)
    80002106:	e0a2                	sd	s0,64(sp)
    80002108:	fc26                	sd	s1,56(sp)
    8000210a:	f84a                	sd	s2,48(sp)
    8000210c:	f44e                	sd	s3,40(sp)
    8000210e:	f052                	sd	s4,32(sp)
    80002110:	ec56                	sd	s5,24(sp)
    80002112:	e85a                	sd	s6,16(sp)
    80002114:	e45e                	sd	s7,8(sp)
    80002116:	e062                	sd	s8,0(sp)
    80002118:	0880                	addi	s0,sp,80
    8000211a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	882080e7          	jalr	-1918(ra) # 8000199e <myproc>
    80002124:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002126:	0000f517          	auipc	a0,0xf
    8000212a:	19250513          	addi	a0,a0,402 # 800112b8 <wait_lock>
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	af4080e7          	jalr	-1292(ra) # 80000c22 <acquire>
    havekids = 0;
    80002136:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002138:	4a15                	li	s4,5
        havekids = 1;
    8000213a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000213c:	00015997          	auipc	s3,0x15
    80002140:	19498993          	addi	s3,s3,404 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002144:	0000fc17          	auipc	s8,0xf
    80002148:	174c0c13          	addi	s8,s8,372 # 800112b8 <wait_lock>
    havekids = 0;
    8000214c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000214e:	0000f497          	auipc	s1,0xf
    80002152:	58248493          	addi	s1,s1,1410 # 800116d0 <proc>
    80002156:	a0bd                	j	800021c4 <wait+0xc2>
          pid = np->pid;
    80002158:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000215c:	000b0e63          	beqz	s6,80002178 <wait+0x76>
    80002160:	4691                	li	a3,4
    80002162:	02c48613          	addi	a2,s1,44
    80002166:	85da                	mv	a1,s6
    80002168:	05893503          	ld	a0,88(s2)
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	4f6080e7          	jalr	1270(ra) # 80001662 <copyout>
    80002174:	02054563          	bltz	a0,8000219e <wait+0x9c>
          freeproc(np);
    80002178:	8526                	mv	a0,s1
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	9d6080e7          	jalr	-1578(ra) # 80001b50 <freeproc>
          release(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b52080e7          	jalr	-1198(ra) # 80000cd6 <release>
          release(&wait_lock);
    8000218c:	0000f517          	auipc	a0,0xf
    80002190:	12c50513          	addi	a0,a0,300 # 800112b8 <wait_lock>
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b42080e7          	jalr	-1214(ra) # 80000cd6 <release>
          return pid;
    8000219c:	a09d                	j	80002202 <wait+0x100>
            release(&np->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	b36080e7          	jalr	-1226(ra) # 80000cd6 <release>
            release(&wait_lock);
    800021a8:	0000f517          	auipc	a0,0xf
    800021ac:	11050513          	addi	a0,a0,272 # 800112b8 <wait_lock>
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	b26080e7          	jalr	-1242(ra) # 80000cd6 <release>
            return -1;
    800021b8:	59fd                	li	s3,-1
    800021ba:	a0a1                	j	80002202 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021bc:	17048493          	addi	s1,s1,368
    800021c0:	03348463          	beq	s1,s3,800021e8 <wait+0xe6>
      if(np->parent == p){
    800021c4:	60bc                	ld	a5,64(s1)
    800021c6:	ff279be3          	bne	a5,s2,800021bc <wait+0xba>
        acquire(&np->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	a56080e7          	jalr	-1450(ra) # 80000c22 <acquire>
        if(np->state == ZOMBIE){
    800021d4:	4c9c                	lw	a5,24(s1)
    800021d6:	f94781e3          	beq	a5,s4,80002158 <wait+0x56>
        release(&np->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	afa080e7          	jalr	-1286(ra) # 80000cd6 <release>
        havekids = 1;
    800021e4:	8756                	mv	a4,s5
    800021e6:	bfd9                	j	800021bc <wait+0xba>
    if(!havekids || p->killed){
    800021e8:	c701                	beqz	a4,800021f0 <wait+0xee>
    800021ea:	02892783          	lw	a5,40(s2)
    800021ee:	c79d                	beqz	a5,8000221c <wait+0x11a>
      release(&wait_lock);
    800021f0:	0000f517          	auipc	a0,0xf
    800021f4:	0c850513          	addi	a0,a0,200 # 800112b8 <wait_lock>
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	ade080e7          	jalr	-1314(ra) # 80000cd6 <release>
      return -1;
    80002200:	59fd                	li	s3,-1
}
    80002202:	854e                	mv	a0,s3
    80002204:	60a6                	ld	ra,72(sp)
    80002206:	6406                	ld	s0,64(sp)
    80002208:	74e2                	ld	s1,56(sp)
    8000220a:	7942                	ld	s2,48(sp)
    8000220c:	79a2                	ld	s3,40(sp)
    8000220e:	7a02                	ld	s4,32(sp)
    80002210:	6ae2                	ld	s5,24(sp)
    80002212:	6b42                	ld	s6,16(sp)
    80002214:	6ba2                	ld	s7,8(sp)
    80002216:	6c02                	ld	s8,0(sp)
    80002218:	6161                	addi	sp,sp,80
    8000221a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000221c:	85e2                	mv	a1,s8
    8000221e:	854a                	mv	a0,s2
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e7e080e7          	jalr	-386(ra) # 8000209e <sleep>
    havekids = 0;
    80002228:	b715                	j	8000214c <wait+0x4a>

000000008000222a <wait2>:
{
    8000222a:	7159                	addi	sp,sp,-112
    8000222c:	f486                	sd	ra,104(sp)
    8000222e:	f0a2                	sd	s0,96(sp)
    80002230:	eca6                	sd	s1,88(sp)
    80002232:	e8ca                	sd	s2,80(sp)
    80002234:	e4ce                	sd	s3,72(sp)
    80002236:	e0d2                	sd	s4,64(sp)
    80002238:	fc56                	sd	s5,56(sp)
    8000223a:	f85a                	sd	s6,48(sp)
    8000223c:	f45e                	sd	s7,40(sp)
    8000223e:	f062                	sd	s8,32(sp)
    80002240:	ec66                	sd	s9,24(sp)
    80002242:	1880                	addi	s0,sp,112
    80002244:	8baa                	mv	s7,a0
    80002246:	8b2e                	mv	s6,a1
  struct proc *p = myproc();
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	756080e7          	jalr	1878(ra) # 8000199e <myproc>
    80002250:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002252:	0000f517          	auipc	a0,0xf
    80002256:	06650513          	addi	a0,a0,102 # 800112b8 <wait_lock>
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	9c8080e7          	jalr	-1592(ra) # 80000c22 <acquire>
    havekids = 0;
    80002262:	4c01                	li	s8,0
        if(np->state == ZOMBIE){
    80002264:	4a15                	li	s4,5
        havekids = 1;
    80002266:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002268:	00015997          	auipc	s3,0x15
    8000226c:	06898993          	addi	s3,s3,104 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002270:	0000fc97          	auipc	s9,0xf
    80002274:	048c8c93          	addi	s9,s9,72 # 800112b8 <wait_lock>
    havekids = 0;
    80002278:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    8000227a:	0000f497          	auipc	s1,0xf
    8000227e:	45648493          	addi	s1,s1,1110 # 800116d0 <proc>
    80002282:	a07d                	j	80002330 <wait2+0x106>
          pid = np->pid;
    80002284:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002288:	040b9663          	bnez	s7,800022d4 <wait2+0xaa>
          cptime.cputime = np->cputime;
    8000228c:	58dc                	lw	a5,52(s1)
    8000228e:	f8f42c23          	sw	a5,-104(s0)
          if(addr1 != 0 && copyout(p->pagetable, addr1, (char *)&cptime,
    80002292:	000b0e63          	beqz	s6,800022ae <wait2+0x84>
    80002296:	4691                	li	a3,4
    80002298:	f9840613          	addi	a2,s0,-104
    8000229c:	85da                	mv	a1,s6
    8000229e:	05893503          	ld	a0,88(s2)
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	3c0080e7          	jalr	960(ra) # 80001662 <copyout>
    800022aa:	06054063          	bltz	a0,8000230a <wait2+0xe0>
          freeproc(np);
    800022ae:	8526                	mv	a0,s1
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	8a0080e7          	jalr	-1888(ra) # 80001b50 <freeproc>
          release(&np->lock);
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	a1c080e7          	jalr	-1508(ra) # 80000cd6 <release>
          release(&wait_lock);
    800022c2:	0000f517          	auipc	a0,0xf
    800022c6:	ff650513          	addi	a0,a0,-10 # 800112b8 <wait_lock>
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	a0c080e7          	jalr	-1524(ra) # 80000cd6 <release>
          return pid;
    800022d2:	a871                	j	8000236e <wait2+0x144>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022d4:	4691                	li	a3,4
    800022d6:	02c48613          	addi	a2,s1,44
    800022da:	85de                	mv	a1,s7
    800022dc:	05893503          	ld	a0,88(s2)
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	382080e7          	jalr	898(ra) # 80001662 <copyout>
    800022e8:	fa0552e3          	bgez	a0,8000228c <wait2+0x62>
            release(&np->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	9e8080e7          	jalr	-1560(ra) # 80000cd6 <release>
            release(&wait_lock);
    800022f6:	0000f517          	auipc	a0,0xf
    800022fa:	fc250513          	addi	a0,a0,-62 # 800112b8 <wait_lock>
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	9d8080e7          	jalr	-1576(ra) # 80000cd6 <release>
            return -1;
    80002306:	59fd                	li	s3,-1
    80002308:	a09d                	j	8000236e <wait2+0x144>
            release(&np->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	9ca080e7          	jalr	-1590(ra) # 80000cd6 <release>
            release(&wait_lock);
    80002314:	0000f517          	auipc	a0,0xf
    80002318:	fa450513          	addi	a0,a0,-92 # 800112b8 <wait_lock>
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	9ba080e7          	jalr	-1606(ra) # 80000cd6 <release>
            return -1;
    80002324:	59fd                	li	s3,-1
    80002326:	a0a1                	j	8000236e <wait2+0x144>
    for(np = proc; np < &proc[NPROC]; np++){
    80002328:	17048493          	addi	s1,s1,368
    8000232c:	03348463          	beq	s1,s3,80002354 <wait2+0x12a>
      if(np->parent == p){
    80002330:	60bc                	ld	a5,64(s1)
    80002332:	ff279be3          	bne	a5,s2,80002328 <wait2+0xfe>
        acquire(&np->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	8ea080e7          	jalr	-1814(ra) # 80000c22 <acquire>
        if(np->state == ZOMBIE){
    80002340:	4c9c                	lw	a5,24(s1)
    80002342:	f54781e3          	beq	a5,s4,80002284 <wait2+0x5a>
        release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	98e080e7          	jalr	-1650(ra) # 80000cd6 <release>
        havekids = 1;
    80002350:	8756                	mv	a4,s5
    80002352:	bfd9                	j	80002328 <wait2+0xfe>
    if(!havekids || p->killed){
    80002354:	c701                	beqz	a4,8000235c <wait2+0x132>
    80002356:	02892783          	lw	a5,40(s2)
    8000235a:	cb85                	beqz	a5,8000238a <wait2+0x160>
      release(&wait_lock);
    8000235c:	0000f517          	auipc	a0,0xf
    80002360:	f5c50513          	addi	a0,a0,-164 # 800112b8 <wait_lock>
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	972080e7          	jalr	-1678(ra) # 80000cd6 <release>
      return -1;
    8000236c:	59fd                	li	s3,-1
}
    8000236e:	854e                	mv	a0,s3
    80002370:	70a6                	ld	ra,104(sp)
    80002372:	7406                	ld	s0,96(sp)
    80002374:	64e6                	ld	s1,88(sp)
    80002376:	6946                	ld	s2,80(sp)
    80002378:	69a6                	ld	s3,72(sp)
    8000237a:	6a06                	ld	s4,64(sp)
    8000237c:	7ae2                	ld	s5,56(sp)
    8000237e:	7b42                	ld	s6,48(sp)
    80002380:	7ba2                	ld	s7,40(sp)
    80002382:	7c02                	ld	s8,32(sp)
    80002384:	6ce2                	ld	s9,24(sp)
    80002386:	6165                	addi	sp,sp,112
    80002388:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000238a:	85e6                	mv	a1,s9
    8000238c:	854a                	mv	a0,s2
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	d10080e7          	jalr	-752(ra) # 8000209e <sleep>
    havekids = 0;
    80002396:	b5cd                	j	80002278 <wait2+0x4e>

0000000080002398 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002398:	7139                	addi	sp,sp,-64
    8000239a:	fc06                	sd	ra,56(sp)
    8000239c:	f822                	sd	s0,48(sp)
    8000239e:	f426                	sd	s1,40(sp)
    800023a0:	f04a                	sd	s2,32(sp)
    800023a2:	ec4e                	sd	s3,24(sp)
    800023a4:	e852                	sd	s4,16(sp)
    800023a6:	e456                	sd	s5,8(sp)
    800023a8:	0080                	addi	s0,sp,64
    800023aa:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023ac:	0000f497          	auipc	s1,0xf
    800023b0:	32448493          	addi	s1,s1,804 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023b4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023b6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b8:	00015917          	auipc	s2,0x15
    800023bc:	f1890913          	addi	s2,s2,-232 # 800172d0 <tickslock>
    800023c0:	a811                	j	800023d4 <wakeup+0x3c>
  	p->readytime = sys_uptime();
      }
      release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	912080e7          	jalr	-1774(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023cc:	17048493          	addi	s1,s1,368
    800023d0:	03248b63          	beq	s1,s2,80002406 <wakeup+0x6e>
    if(p != myproc()){
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	5ca080e7          	jalr	1482(ra) # 8000199e <myproc>
    800023dc:	fea488e3          	beq	s1,a0,800023cc <wakeup+0x34>
      acquire(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	840080e7          	jalr	-1984(ra) # 80000c22 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023ea:	4c9c                	lw	a5,24(s1)
    800023ec:	fd379be3          	bne	a5,s3,800023c2 <wakeup+0x2a>
    800023f0:	709c                	ld	a5,32(s1)
    800023f2:	fd4798e3          	bne	a5,s4,800023c2 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023f6:	0154ac23          	sw	s5,24(s1)
  	p->readytime = sys_uptime();
    800023fa:	00001097          	auipc	ra,0x1
    800023fe:	df0080e7          	jalr	-528(ra) # 800031ea <sys_uptime>
    80002402:	dcc8                	sw	a0,60(s1)
    80002404:	bf7d                	j	800023c2 <wakeup+0x2a>
    }
  }
}
    80002406:	70e2                	ld	ra,56(sp)
    80002408:	7442                	ld	s0,48(sp)
    8000240a:	74a2                	ld	s1,40(sp)
    8000240c:	7902                	ld	s2,32(sp)
    8000240e:	69e2                	ld	s3,24(sp)
    80002410:	6a42                	ld	s4,16(sp)
    80002412:	6aa2                	ld	s5,8(sp)
    80002414:	6121                	addi	sp,sp,64
    80002416:	8082                	ret

0000000080002418 <reparent>:
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	e052                	sd	s4,0(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242a:	0000f497          	auipc	s1,0xf
    8000242e:	2a648493          	addi	s1,s1,678 # 800116d0 <proc>
      pp->parent = initproc;
    80002432:	00007a17          	auipc	s4,0x7
    80002436:	bf6a0a13          	addi	s4,s4,-1034 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000243a:	00015997          	auipc	s3,0x15
    8000243e:	e9698993          	addi	s3,s3,-362 # 800172d0 <tickslock>
    80002442:	a029                	j	8000244c <reparent+0x34>
    80002444:	17048493          	addi	s1,s1,368
    80002448:	01348d63          	beq	s1,s3,80002462 <reparent+0x4a>
    if(pp->parent == p){
    8000244c:	60bc                	ld	a5,64(s1)
    8000244e:	ff279be3          	bne	a5,s2,80002444 <reparent+0x2c>
      pp->parent = initproc;
    80002452:	000a3503          	ld	a0,0(s4)
    80002456:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	f40080e7          	jalr	-192(ra) # 80002398 <wakeup>
    80002460:	b7d5                	j	80002444 <reparent+0x2c>
}
    80002462:	70a2                	ld	ra,40(sp)
    80002464:	7402                	ld	s0,32(sp)
    80002466:	64e2                	ld	s1,24(sp)
    80002468:	6942                	ld	s2,16(sp)
    8000246a:	69a2                	ld	s3,8(sp)
    8000246c:	6a02                	ld	s4,0(sp)
    8000246e:	6145                	addi	sp,sp,48
    80002470:	8082                	ret

0000000080002472 <exit>:
{
    80002472:	7179                	addi	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	ec26                	sd	s1,24(sp)
    8000247a:	e84a                	sd	s2,16(sp)
    8000247c:	e44e                	sd	s3,8(sp)
    8000247e:	e052                	sd	s4,0(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	51a080e7          	jalr	1306(ra) # 8000199e <myproc>
    8000248c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000248e:	00007797          	auipc	a5,0x7
    80002492:	b9a7b783          	ld	a5,-1126(a5) # 80009028 <initproc>
    80002496:	0d850493          	addi	s1,a0,216
    8000249a:	15850913          	addi	s2,a0,344
    8000249e:	02a79363          	bne	a5,a0,800024c4 <exit+0x52>
    panic("init exiting");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	d4650513          	addi	a0,a0,-698 # 800081e8 <digits+0x1a8>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	090080e7          	jalr	144(ra) # 8000053a <panic>
      fileclose(f);
    800024b2:	00002097          	auipc	ra,0x2
    800024b6:	4e0080e7          	jalr	1248(ra) # 80004992 <fileclose>
      p->ofile[fd] = 0;
    800024ba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024be:	04a1                	addi	s1,s1,8
    800024c0:	01248563          	beq	s1,s2,800024ca <exit+0x58>
    if(p->ofile[fd]){
    800024c4:	6088                	ld	a0,0(s1)
    800024c6:	f575                	bnez	a0,800024b2 <exit+0x40>
    800024c8:	bfdd                	j	800024be <exit+0x4c>
  begin_op();
    800024ca:	00002097          	auipc	ra,0x2
    800024ce:	000080e7          	jalr	ra # 800044ca <begin_op>
  iput(p->cwd);
    800024d2:	1589b503          	ld	a0,344(s3)
    800024d6:	00001097          	auipc	ra,0x1
    800024da:	7d2080e7          	jalr	2002(ra) # 80003ca8 <iput>
  end_op();
    800024de:	00002097          	auipc	ra,0x2
    800024e2:	06a080e7          	jalr	106(ra) # 80004548 <end_op>
  p->cwd = 0;
    800024e6:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800024ea:	0000f497          	auipc	s1,0xf
    800024ee:	dce48493          	addi	s1,s1,-562 # 800112b8 <wait_lock>
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	72e080e7          	jalr	1838(ra) # 80000c22 <acquire>
  reparent(p);
    800024fc:	854e                	mv	a0,s3
    800024fe:	00000097          	auipc	ra,0x0
    80002502:	f1a080e7          	jalr	-230(ra) # 80002418 <reparent>
  wakeup(p->parent);
    80002506:	0409b503          	ld	a0,64(s3)
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	e8e080e7          	jalr	-370(ra) # 80002398 <wakeup>
  acquire(&p->lock);
    80002512:	854e                	mv	a0,s3
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	70e080e7          	jalr	1806(ra) # 80000c22 <acquire>
  p->xstate = status;
    8000251c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002520:	4795                	li	a5,5
    80002522:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	7ae080e7          	jalr	1966(ra) # 80000cd6 <release>
  sched();
    80002530:	00000097          	auipc	ra,0x0
    80002534:	a52080e7          	jalr	-1454(ra) # 80001f82 <sched>
  panic("zombie exit");
    80002538:	00006517          	auipc	a0,0x6
    8000253c:	cc050513          	addi	a0,a0,-832 # 800081f8 <digits+0x1b8>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	ffa080e7          	jalr	-6(ra) # 8000053a <panic>

0000000080002548 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	1800                	addi	s0,sp,48
    80002556:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002558:	0000f497          	auipc	s1,0xf
    8000255c:	17848493          	addi	s1,s1,376 # 800116d0 <proc>
    80002560:	00015997          	auipc	s3,0x15
    80002564:	d7098993          	addi	s3,s3,-656 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	6b8080e7          	jalr	1720(ra) # 80000c22 <acquire>
    if(p->pid == pid){
    80002572:	589c                	lw	a5,48(s1)
    80002574:	01278d63          	beq	a5,s2,8000258e <kill+0x46>
  	p->readytime = sys_uptime();
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	75c080e7          	jalr	1884(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002582:	17048493          	addi	s1,s1,368
    80002586:	ff3491e3          	bne	s1,s3,80002568 <kill+0x20>
  }
  return -1;
    8000258a:	557d                	li	a0,-1
    8000258c:	a829                	j	800025a6 <kill+0x5e>
      p->killed = 1;
    8000258e:	4785                	li	a5,1
    80002590:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002592:	4c98                	lw	a4,24(s1)
    80002594:	4789                	li	a5,2
    80002596:	00f70f63          	beq	a4,a5,800025b4 <kill+0x6c>
      release(&p->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	73a080e7          	jalr	1850(ra) # 80000cd6 <release>
      return 0;
    800025a4:	4501                	li	a0,0
}
    800025a6:	70a2                	ld	ra,40(sp)
    800025a8:	7402                	ld	s0,32(sp)
    800025aa:	64e2                	ld	s1,24(sp)
    800025ac:	6942                	ld	s2,16(sp)
    800025ae:	69a2                	ld	s3,8(sp)
    800025b0:	6145                	addi	sp,sp,48
    800025b2:	8082                	ret
  	p->state = RUNNABLE;
    800025b4:	478d                	li	a5,3
    800025b6:	cc9c                	sw	a5,24(s1)
  	p->readytime = sys_uptime();
    800025b8:	00001097          	auipc	ra,0x1
    800025bc:	c32080e7          	jalr	-974(ra) # 800031ea <sys_uptime>
    800025c0:	dcc8                	sw	a0,60(s1)
    800025c2:	bfe1                	j	8000259a <kill+0x52>

00000000800025c4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025c4:	7179                	addi	sp,sp,-48
    800025c6:	f406                	sd	ra,40(sp)
    800025c8:	f022                	sd	s0,32(sp)
    800025ca:	ec26                	sd	s1,24(sp)
    800025cc:	e84a                	sd	s2,16(sp)
    800025ce:	e44e                	sd	s3,8(sp)
    800025d0:	e052                	sd	s4,0(sp)
    800025d2:	1800                	addi	s0,sp,48
    800025d4:	84aa                	mv	s1,a0
    800025d6:	892e                	mv	s2,a1
    800025d8:	89b2                	mv	s3,a2
    800025da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	3c2080e7          	jalr	962(ra) # 8000199e <myproc>
  if(user_dst){
    800025e4:	c08d                	beqz	s1,80002606 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025e6:	86d2                	mv	a3,s4
    800025e8:	864e                	mv	a2,s3
    800025ea:	85ca                	mv	a1,s2
    800025ec:	6d28                	ld	a0,88(a0)
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	074080e7          	jalr	116(ra) # 80001662 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025f6:	70a2                	ld	ra,40(sp)
    800025f8:	7402                	ld	s0,32(sp)
    800025fa:	64e2                	ld	s1,24(sp)
    800025fc:	6942                	ld	s2,16(sp)
    800025fe:	69a2                	ld	s3,8(sp)
    80002600:	6a02                	ld	s4,0(sp)
    80002602:	6145                	addi	sp,sp,48
    80002604:	8082                	ret
    memmove((char *)dst, src, len);
    80002606:	000a061b          	sext.w	a2,s4
    8000260a:	85ce                	mv	a1,s3
    8000260c:	854a                	mv	a0,s2
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	76c080e7          	jalr	1900(ra) # 80000d7a <memmove>
    return 0;
    80002616:	8526                	mv	a0,s1
    80002618:	bff9                	j	800025f6 <either_copyout+0x32>

000000008000261a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000261a:	7179                	addi	sp,sp,-48
    8000261c:	f406                	sd	ra,40(sp)
    8000261e:	f022                	sd	s0,32(sp)
    80002620:	ec26                	sd	s1,24(sp)
    80002622:	e84a                	sd	s2,16(sp)
    80002624:	e44e                	sd	s3,8(sp)
    80002626:	e052                	sd	s4,0(sp)
    80002628:	1800                	addi	s0,sp,48
    8000262a:	892a                	mv	s2,a0
    8000262c:	84ae                	mv	s1,a1
    8000262e:	89b2                	mv	s3,a2
    80002630:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	36c080e7          	jalr	876(ra) # 8000199e <myproc>
  if(user_src){
    8000263a:	c08d                	beqz	s1,8000265c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000263c:	86d2                	mv	a3,s4
    8000263e:	864e                	mv	a2,s3
    80002640:	85ca                	mv	a1,s2
    80002642:	6d28                	ld	a0,88(a0)
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	0aa080e7          	jalr	170(ra) # 800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000264c:	70a2                	ld	ra,40(sp)
    8000264e:	7402                	ld	s0,32(sp)
    80002650:	64e2                	ld	s1,24(sp)
    80002652:	6942                	ld	s2,16(sp)
    80002654:	69a2                	ld	s3,8(sp)
    80002656:	6a02                	ld	s4,0(sp)
    80002658:	6145                	addi	sp,sp,48
    8000265a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000265c:	000a061b          	sext.w	a2,s4
    80002660:	85ce                	mv	a1,s3
    80002662:	854a                	mv	a0,s2
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	716080e7          	jalr	1814(ra) # 80000d7a <memmove>
    return 0;
    8000266c:	8526                	mv	a0,s1
    8000266e:	bff9                	j	8000264c <either_copyin+0x32>

0000000080002670 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002670:	715d                	addi	sp,sp,-80
    80002672:	e486                	sd	ra,72(sp)
    80002674:	e0a2                	sd	s0,64(sp)
    80002676:	fc26                	sd	s1,56(sp)
    80002678:	f84a                	sd	s2,48(sp)
    8000267a:	f44e                	sd	s3,40(sp)
    8000267c:	f052                	sd	s4,32(sp)
    8000267e:	ec56                	sd	s5,24(sp)
    80002680:	e85a                	sd	s6,16(sp)
    80002682:	e45e                	sd	s7,8(sp)
    80002684:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002686:	00006517          	auipc	a0,0x6
    8000268a:	a4250513          	addi	a0,a0,-1470 # 800080c8 <digits+0x88>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	ef6080e7          	jalr	-266(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002696:	0000f497          	auipc	s1,0xf
    8000269a:	19a48493          	addi	s1,s1,410 # 80011830 <proc+0x160>
    8000269e:	00015917          	auipc	s2,0x15
    800026a2:	d9290913          	addi	s2,s2,-622 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026a8:	00006997          	auipc	s3,0x6
    800026ac:	b6098993          	addi	s3,s3,-1184 # 80008208 <digits+0x1c8>
    printf("%d %s %s", p->pid, state, p->name);
    800026b0:	00006a97          	auipc	s5,0x6
    800026b4:	b60a8a93          	addi	s5,s5,-1184 # 80008210 <digits+0x1d0>
    printf("\n");
    800026b8:	00006a17          	auipc	s4,0x6
    800026bc:	a10a0a13          	addi	s4,s4,-1520 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c0:	00006b97          	auipc	s7,0x6
    800026c4:	b88b8b93          	addi	s7,s7,-1144 # 80008248 <states.0>
    800026c8:	a00d                	j	800026ea <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026ca:	ed06a583          	lw	a1,-304(a3)
    800026ce:	8556                	mv	a0,s5
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	eb4080e7          	jalr	-332(ra) # 80000584 <printf>
    printf("\n");
    800026d8:	8552                	mv	a0,s4
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	eaa080e7          	jalr	-342(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e2:	17048493          	addi	s1,s1,368
    800026e6:	03248263          	beq	s1,s2,8000270a <procdump+0x9a>
    if(p->state == UNUSED)
    800026ea:	86a6                	mv	a3,s1
    800026ec:	eb84a783          	lw	a5,-328(s1)
    800026f0:	dbed                	beqz	a5,800026e2 <procdump+0x72>
      state = "???";
    800026f2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f4:	fcfb6be3          	bltu	s6,a5,800026ca <procdump+0x5a>
    800026f8:	02079713          	slli	a4,a5,0x20
    800026fc:	01d75793          	srli	a5,a4,0x1d
    80002700:	97de                	add	a5,a5,s7
    80002702:	6390                	ld	a2,0(a5)
    80002704:	f279                	bnez	a2,800026ca <procdump+0x5a>
      state = "???";
    80002706:	864e                	mv	a2,s3
    80002708:	b7c9                	j	800026ca <procdump+0x5a>
  }
}
    8000270a:	60a6                	ld	ra,72(sp)
    8000270c:	6406                	ld	s0,64(sp)
    8000270e:	74e2                	ld	s1,56(sp)
    80002710:	7942                	ld	s2,48(sp)
    80002712:	79a2                	ld	s3,40(sp)
    80002714:	7a02                	ld	s4,32(sp)
    80002716:	6ae2                	ld	s5,24(sp)
    80002718:	6b42                	ld	s6,16(sp)
    8000271a:	6ba2                	ld	s7,8(sp)
    8000271c:	6161                	addi	sp,sp,80
    8000271e:	8082                	ret

0000000080002720 <procinfo>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
procinfo(uint64 addr)
{
    80002720:	7119                	addi	sp,sp,-128
    80002722:	fc86                	sd	ra,120(sp)
    80002724:	f8a2                	sd	s0,112(sp)
    80002726:	f4a6                	sd	s1,104(sp)
    80002728:	f0ca                	sd	s2,96(sp)
    8000272a:	ecce                	sd	s3,88(sp)
    8000272c:	e8d2                	sd	s4,80(sp)
    8000272e:	e4d6                	sd	s5,72(sp)
    80002730:	e0da                	sd	s6,64(sp)
    80002732:	fc5e                	sd	s7,56(sp)
    80002734:	0100                	addi	s0,sp,128
    80002736:	89aa                	mv	s3,a0
  struct proc *p;
  struct proc *thisproc = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	266080e7          	jalr	614(ra) # 8000199e <myproc>
    80002740:	8b2a                	mv	s6,a0
  struct pstat procinfo;
  int nprocs = 0;
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002742:	0000f917          	auipc	s2,0xf
    80002746:	0ee90913          	addi	s2,s2,238 # 80011830 <proc+0x160>
    8000274a:	00015a17          	auipc	s4,0x15
    8000274e:	ce6a0a13          	addi	s4,s4,-794 # 80017430 <bcache+0x148>
  int nprocs = 0;
    80002752:	4a81                	li	s5,0
    procinfo.priority = p->priority;
    procinfo.readytime = p->readytime;
    if (p->parent)
      procinfo.ppid = (p->parent)->pid;
    else
      procinfo.ppid = 0;
    80002754:	4b81                	li	s7,0
    80002756:	fa440493          	addi	s1,s0,-92
    8000275a:	a089                	j	8000279c <procinfo+0x7c>
    8000275c:	f8f42823          	sw	a5,-112(s0)
    for (int i=0; i<16; i++)
    80002760:	f9440793          	addi	a5,s0,-108
      procinfo.ppid = 0;
    80002764:	874a                	mv	a4,s2
      procinfo.name[i] = p->name[i];
    80002766:	00074683          	lbu	a3,0(a4)
    8000276a:	00d78023          	sb	a3,0(a5)
    for (int i=0; i<16; i++)
    8000276e:	0705                	addi	a4,a4,1
    80002770:	0785                	addi	a5,a5,1
    80002772:	fe979ae3          	bne	a5,s1,80002766 <procinfo+0x46>
   if (copyout(thisproc->pagetable, addr, (char *)&procinfo, sizeof(procinfo)) < 0)
    80002776:	03000693          	li	a3,48
    8000277a:	f8040613          	addi	a2,s0,-128
    8000277e:	85ce                	mv	a1,s3
    80002780:	058b3503          	ld	a0,88(s6)
    80002784:	fffff097          	auipc	ra,0xfffff
    80002788:	ede080e7          	jalr	-290(ra) # 80001662 <copyout>
    8000278c:	04054463          	bltz	a0,800027d4 <procinfo+0xb4>
      return -1;
    addr += sizeof(procinfo);
    80002790:	03098993          	addi	s3,s3,48
  for(p = proc; p < &proc[NPROC]; p++){ 
    80002794:	17090913          	addi	s2,s2,368
    80002798:	03490f63          	beq	s2,s4,800027d6 <procinfo+0xb6>
    if(p->state == UNUSED)
    8000279c:	eb892783          	lw	a5,-328(s2)
    800027a0:	dbf5                	beqz	a5,80002794 <procinfo+0x74>
    nprocs++;
    800027a2:	2a85                	addiw	s5,s5,1
    procinfo.pid = p->pid;
    800027a4:	ed092703          	lw	a4,-304(s2)
    800027a8:	f8e42023          	sw	a4,-128(s0)
    procinfo.state = p->state;
    800027ac:	f8f42223          	sw	a5,-124(s0)
    procinfo.size = p->sz;
    800027b0:	ef093783          	ld	a5,-272(s2)
    800027b4:	f8f43423          	sd	a5,-120(s0)
    procinfo.priority = p->priority;
    800027b8:	ed892783          	lw	a5,-296(s2)
    800027bc:	faf42223          	sw	a5,-92(s0)
    procinfo.readytime = p->readytime;
    800027c0:	edc92783          	lw	a5,-292(s2)
    800027c4:	faf42423          	sw	a5,-88(s0)
    if (p->parent)
    800027c8:	ee093703          	ld	a4,-288(s2)
      procinfo.ppid = 0;
    800027cc:	87de                	mv	a5,s7
    if (p->parent)
    800027ce:	d759                	beqz	a4,8000275c <procinfo+0x3c>
      procinfo.ppid = (p->parent)->pid;
    800027d0:	5b1c                	lw	a5,48(a4)
    800027d2:	b769                	j	8000275c <procinfo+0x3c>
      return -1;
    800027d4:	5afd                	li	s5,-1
  }
  return nprocs;
}
    800027d6:	8556                	mv	a0,s5
    800027d8:	70e6                	ld	ra,120(sp)
    800027da:	7446                	ld	s0,112(sp)
    800027dc:	74a6                	ld	s1,104(sp)
    800027de:	7906                	ld	s2,96(sp)
    800027e0:	69e6                	ld	s3,88(sp)
    800027e2:	6a46                	ld	s4,80(sp)
    800027e4:	6aa6                	ld	s5,72(sp)
    800027e6:	6b06                	ld	s6,64(sp)
    800027e8:	7be2                	ld	s7,56(sp)
    800027ea:	6109                	addi	sp,sp,128
    800027ec:	8082                	ret

00000000800027ee <getpriority>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
getpriority(uint64 addr)
{
    800027ee:	7179                	addi	sp,sp,-48
    800027f0:	f406                	sd	ra,40(sp)
    800027f2:	f022                	sd	s0,32(sp)
    800027f4:	ec26                	sd	s1,24(sp)
    800027f6:	e84a                	sd	s2,16(sp)
    800027f8:	1800                	addi	s0,sp,48
    800027fa:	84aa                	mv	s1,a0
  struct proc *thisproc = myproc();
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	1a2080e7          	jalr	418(ra) # 8000199e <myproc>
  struct ruprio priority;
  int pid;
  pid = thisproc->pid;
    80002804:	03052903          	lw	s2,48(a0)
  priority.priority = thisproc->priority;
    80002808:	5d1c                	lw	a5,56(a0)
    8000280a:	fcf42c23          	sw	a5,-40(s0)
   if (addr != 0 && copyout(thisproc->pagetable, addr, (char *)&priority, sizeof(priority)) < 0){
    8000280e:	e881                	bnez	s1,8000281e <getpriority+0x30>
      return -1;
  }
  return pid;
}
    80002810:	854a                	mv	a0,s2
    80002812:	70a2                	ld	ra,40(sp)
    80002814:	7402                	ld	s0,32(sp)
    80002816:	64e2                	ld	s1,24(sp)
    80002818:	6942                	ld	s2,16(sp)
    8000281a:	6145                	addi	sp,sp,48
    8000281c:	8082                	ret
   if (addr != 0 && copyout(thisproc->pagetable, addr, (char *)&priority, sizeof(priority)) < 0){
    8000281e:	4691                	li	a3,4
    80002820:	fd840613          	addi	a2,s0,-40
    80002824:	85a6                	mv	a1,s1
    80002826:	6d28                	ld	a0,88(a0)
    80002828:	fffff097          	auipc	ra,0xfffff
    8000282c:	e3a080e7          	jalr	-454(ra) # 80001662 <copyout>
    80002830:	fe0550e3          	bgez	a0,80002810 <getpriority+0x22>
      return -1;
    80002834:	597d                	li	s2,-1
    80002836:	bfe9                	j	80002810 <getpriority+0x22>

0000000080002838 <setpriority>:

int
setpriority(uint64 addr)
{
    80002838:	7179                	addi	sp,sp,-48
    8000283a:	f406                	sd	ra,40(sp)
    8000283c:	f022                	sd	s0,32(sp)
    8000283e:	ec26                	sd	s1,24(sp)
    80002840:	e84a                	sd	s2,16(sp)
    80002842:	e44e                	sd	s3,8(sp)
    80002844:	1800                	addi	s0,sp,48
    80002846:	892a                	mv	s2,a0
  struct proc *thisproc = myproc();
    80002848:	fffff097          	auipc	ra,0xfffff
    8000284c:	156080e7          	jalr	342(ra) # 8000199e <myproc>
  int pid;
  pid = thisproc->pid;
    80002850:	03052983          	lw	s3,48(a0)
  int *temp =0;
   if (addr != 0){
    80002854:	00091a63          	bnez	s2,80002868 <setpriority+0x30>
   //either_copyin(void *dst, int user_src, uint64 src, uint64 len)
   either_copyin(temp,1,addr,8);
   thisproc->priority = *temp;
  }
  return pid;
}
    80002858:	854e                	mv	a0,s3
    8000285a:	70a2                	ld	ra,40(sp)
    8000285c:	7402                	ld	s0,32(sp)
    8000285e:	64e2                	ld	s1,24(sp)
    80002860:	6942                	ld	s2,16(sp)
    80002862:	69a2                	ld	s3,8(sp)
    80002864:	6145                	addi	sp,sp,48
    80002866:	8082                	ret
    80002868:	84aa                	mv	s1,a0
   either_copyin(temp,1,addr,8);
    8000286a:	46a1                	li	a3,8
    8000286c:	864a                	mv	a2,s2
    8000286e:	4585                	li	a1,1
    80002870:	4501                	li	a0,0
    80002872:	00000097          	auipc	ra,0x0
    80002876:	da8080e7          	jalr	-600(ra) # 8000261a <either_copyin>
   thisproc->priority = *temp;
    8000287a:	00002783          	lw	a5,0(zero) # 0 <_entry-0x80000000>
    8000287e:	dc9c                	sw	a5,56(s1)
    80002880:	bfe1                	j	80002858 <setpriority+0x20>

0000000080002882 <freepmem>:

// Fill in user-provided array with info for current processes
// Return the number of processes found
int
freepmem(uint64 addr)
{
    80002882:	7179                	addi	sp,sp,-48
    80002884:	f406                	sd	ra,40(sp)
    80002886:	f022                	sd	s0,32(sp)
    80002888:	ec26                	sd	s1,24(sp)
    8000288a:	e84a                	sd	s2,16(sp)
    8000288c:	1800                	addi	s0,sp,48
    8000288e:	84aa                	mv	s1,a0
	struct proc *thisproc = myproc();
    80002890:	fffff097          	auipc	ra,0xfffff
    80002894:	10e080e7          	jalr	270(ra) # 8000199e <myproc>
    80002898:	892a                	mv	s2,a0
  int freemem = freeMem() * PGSIZE;
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	2a6080e7          	jalr	678(ra) # 80000b40 <freeMem>
    800028a2:	00c5179b          	slliw	a5,a0,0xc
    800028a6:	fcf42e23          	sw	a5,-36(s0)
   if (addr != 0 && copyout(thisproc->pagetable, addr, (char *)&freemem, sizeof(freemem)) < 0){
    800028aa:	e889                	bnez	s1,800028bc <freepmem+0x3a>
      return -1;
  }
  return freemem;
    800028ac:	fdc42503          	lw	a0,-36(s0)
}
    800028b0:	70a2                	ld	ra,40(sp)
    800028b2:	7402                	ld	s0,32(sp)
    800028b4:	64e2                	ld	s1,24(sp)
    800028b6:	6942                	ld	s2,16(sp)
    800028b8:	6145                	addi	sp,sp,48
    800028ba:	8082                	ret
   if (addr != 0 && copyout(thisproc->pagetable, addr, (char *)&freemem, sizeof(freemem)) < 0){
    800028bc:	4691                	li	a3,4
    800028be:	fdc40613          	addi	a2,s0,-36
    800028c2:	85a6                	mv	a1,s1
    800028c4:	05893503          	ld	a0,88(s2)
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	d9a080e7          	jalr	-614(ra) # 80001662 <copyout>
    800028d0:	fc055ee3          	bgez	a0,800028ac <freepmem+0x2a>
      return -1;
    800028d4:	557d                	li	a0,-1
    800028d6:	bfe9                	j	800028b0 <freepmem+0x2e>

00000000800028d8 <swtch>:
    800028d8:	00153023          	sd	ra,0(a0)
    800028dc:	00253423          	sd	sp,8(a0)
    800028e0:	e900                	sd	s0,16(a0)
    800028e2:	ed04                	sd	s1,24(a0)
    800028e4:	03253023          	sd	s2,32(a0)
    800028e8:	03353423          	sd	s3,40(a0)
    800028ec:	03453823          	sd	s4,48(a0)
    800028f0:	03553c23          	sd	s5,56(a0)
    800028f4:	05653023          	sd	s6,64(a0)
    800028f8:	05753423          	sd	s7,72(a0)
    800028fc:	05853823          	sd	s8,80(a0)
    80002900:	05953c23          	sd	s9,88(a0)
    80002904:	07a53023          	sd	s10,96(a0)
    80002908:	07b53423          	sd	s11,104(a0)
    8000290c:	0005b083          	ld	ra,0(a1)
    80002910:	0085b103          	ld	sp,8(a1)
    80002914:	6980                	ld	s0,16(a1)
    80002916:	6d84                	ld	s1,24(a1)
    80002918:	0205b903          	ld	s2,32(a1)
    8000291c:	0285b983          	ld	s3,40(a1)
    80002920:	0305ba03          	ld	s4,48(a1)
    80002924:	0385ba83          	ld	s5,56(a1)
    80002928:	0405bb03          	ld	s6,64(a1)
    8000292c:	0485bb83          	ld	s7,72(a1)
    80002930:	0505bc03          	ld	s8,80(a1)
    80002934:	0585bc83          	ld	s9,88(a1)
    80002938:	0605bd03          	ld	s10,96(a1)
    8000293c:	0685bd83          	ld	s11,104(a1)
    80002940:	8082                	ret

0000000080002942 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002942:	1141                	addi	sp,sp,-16
    80002944:	e406                	sd	ra,8(sp)
    80002946:	e022                	sd	s0,0(sp)
    80002948:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000294a:	00006597          	auipc	a1,0x6
    8000294e:	92e58593          	addi	a1,a1,-1746 # 80008278 <states.0+0x30>
    80002952:	00015517          	auipc	a0,0x15
    80002956:	97e50513          	addi	a0,a0,-1666 # 800172d0 <tickslock>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	238080e7          	jalr	568(ra) # 80000b92 <initlock>
}
    80002962:	60a2                	ld	ra,8(sp)
    80002964:	6402                	ld	s0,0(sp)
    80002966:	0141                	addi	sp,sp,16
    80002968:	8082                	ret

000000008000296a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000296a:	1141                	addi	sp,sp,-16
    8000296c:	e422                	sd	s0,8(sp)
    8000296e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002970:	00003797          	auipc	a5,0x3
    80002974:	65078793          	addi	a5,a5,1616 # 80005fc0 <kernelvec>
    80002978:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000297c:	6422                	ld	s0,8(sp)
    8000297e:	0141                	addi	sp,sp,16
    80002980:	8082                	ret

0000000080002982 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002982:	1141                	addi	sp,sp,-16
    80002984:	e406                	sd	ra,8(sp)
    80002986:	e022                	sd	s0,0(sp)
    80002988:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	014080e7          	jalr	20(ra) # 8000199e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002996:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002998:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000299c:	00004697          	auipc	a3,0x4
    800029a0:	66468693          	addi	a3,a3,1636 # 80007000 <_trampoline>
    800029a4:	00004717          	auipc	a4,0x4
    800029a8:	65c70713          	addi	a4,a4,1628 # 80007000 <_trampoline>
    800029ac:	8f15                	sub	a4,a4,a3
    800029ae:	040007b7          	lui	a5,0x4000
    800029b2:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029b4:	07b2                	slli	a5,a5,0xc
    800029b6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b8:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029bc:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029be:	18002673          	csrr	a2,satp
    800029c2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c4:	7130                	ld	a2,96(a0)
    800029c6:	6538                	ld	a4,72(a0)
    800029c8:	6585                	lui	a1,0x1
    800029ca:	972e                	add	a4,a4,a1
    800029cc:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ce:	7138                	ld	a4,96(a0)
    800029d0:	00000617          	auipc	a2,0x0
    800029d4:	13860613          	addi	a2,a2,312 # 80002b08 <usertrap>
    800029d8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029da:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029dc:	8612                	mv	a2,tp
    800029de:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e0:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e4:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029e8:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029f0:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f2:	6f18                	ld	a4,24(a4)
    800029f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029f8:	6d2c                	ld	a1,88(a0)
    800029fa:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029fc:	00004717          	auipc	a4,0x4
    80002a00:	69470713          	addi	a4,a4,1684 # 80007090 <userret>
    80002a04:	8f15                	sub	a4,a4,a3
    80002a06:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a08:	577d                	li	a4,-1
    80002a0a:	177e                	slli	a4,a4,0x3f
    80002a0c:	8dd9                	or	a1,a1,a4
    80002a0e:	02000537          	lui	a0,0x2000
    80002a12:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a14:	0536                	slli	a0,a0,0xd
    80002a16:	9782                	jalr	a5
}
    80002a18:	60a2                	ld	ra,8(sp)
    80002a1a:	6402                	ld	s0,0(sp)
    80002a1c:	0141                	addi	sp,sp,16
    80002a1e:	8082                	ret

0000000080002a20 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2a:	00015497          	auipc	s1,0x15
    80002a2e:	8a648493          	addi	s1,s1,-1882 # 800172d0 <tickslock>
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	1ee080e7          	jalr	494(ra) # 80000c22 <acquire>
  ticks++;
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	5f450513          	addi	a0,a0,1524 # 80009030 <ticks>
    80002a44:	411c                	lw	a5,0(a0)
    80002a46:	2785                	addiw	a5,a5,1
    80002a48:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	94e080e7          	jalr	-1714(ra) # 80002398 <wakeup>
  release(&tickslock);
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	282080e7          	jalr	642(ra) # 80000cd6 <release>
}
    80002a5c:	60e2                	ld	ra,24(sp)
    80002a5e:	6442                	ld	s0,16(sp)
    80002a60:	64a2                	ld	s1,8(sp)
    80002a62:	6105                	addi	sp,sp,32
    80002a64:	8082                	ret

0000000080002a66 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a66:	1101                	addi	sp,sp,-32
    80002a68:	ec06                	sd	ra,24(sp)
    80002a6a:	e822                	sd	s0,16(sp)
    80002a6c:	e426                	sd	s1,8(sp)
    80002a6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a70:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a74:	00074d63          	bltz	a4,80002a8e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a78:	57fd                	li	a5,-1
    80002a7a:	17fe                	slli	a5,a5,0x3f
    80002a7c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a7e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a80:	06f70363          	beq	a4,a5,80002ae6 <devintr+0x80>
  }
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret
     (scause & 0xff) == 9){
    80002a8e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002a92:	46a5                	li	a3,9
    80002a94:	fed792e3          	bne	a5,a3,80002a78 <devintr+0x12>
    int irq = plic_claim();
    80002a98:	00003097          	auipc	ra,0x3
    80002a9c:	630080e7          	jalr	1584(ra) # 800060c8 <plic_claim>
    80002aa0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aa2:	47a9                	li	a5,10
    80002aa4:	02f50763          	beq	a0,a5,80002ad2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aa8:	4785                	li	a5,1
    80002aaa:	02f50963          	beq	a0,a5,80002adc <devintr+0x76>
    return 1;
    80002aae:	4505                	li	a0,1
    } else if(irq){
    80002ab0:	d8f1                	beqz	s1,80002a84 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ab2:	85a6                	mv	a1,s1
    80002ab4:	00005517          	auipc	a0,0x5
    80002ab8:	7cc50513          	addi	a0,a0,1996 # 80008280 <states.0+0x38>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	ac8080e7          	jalr	-1336(ra) # 80000584 <printf>
      plic_complete(irq);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	00003097          	auipc	ra,0x3
    80002aca:	626080e7          	jalr	1574(ra) # 800060ec <plic_complete>
    return 1;
    80002ace:	4505                	li	a0,1
    80002ad0:	bf55                	j	80002a84 <devintr+0x1e>
      uartintr();
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	ec0080e7          	jalr	-320(ra) # 80000992 <uartintr>
    80002ada:	b7ed                	j	80002ac4 <devintr+0x5e>
      virtio_disk_intr();
    80002adc:	00004097          	auipc	ra,0x4
    80002ae0:	a9c080e7          	jalr	-1380(ra) # 80006578 <virtio_disk_intr>
    80002ae4:	b7c5                	j	80002ac4 <devintr+0x5e>
    if(cpuid() == 0){
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	e8c080e7          	jalr	-372(ra) # 80001972 <cpuid>
    80002aee:	c901                	beqz	a0,80002afe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002af0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002af4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002af6:	14479073          	csrw	sip,a5
    return 2;
    80002afa:	4509                	li	a0,2
    80002afc:	b761                	j	80002a84 <devintr+0x1e>
      clockintr();
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	f22080e7          	jalr	-222(ra) # 80002a20 <clockintr>
    80002b06:	b7ed                	j	80002af0 <devintr+0x8a>

0000000080002b08 <usertrap>:
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	e44e                	sd	s3,8(sp)
    80002b14:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b16:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b1a:	1007f793          	andi	a5,a5,256
    80002b1e:	e3b5                	bnez	a5,80002b82 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b20:	00003797          	auipc	a5,0x3
    80002b24:	4a078793          	addi	a5,a5,1184 # 80005fc0 <kernelvec>
    80002b28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	e72080e7          	jalr	-398(ra) # 8000199e <myproc>
    80002b34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b36:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b38:	14102773          	csrr	a4,sepc
    80002b3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b42:	47a1                	li	a5,8
    80002b44:	04f71d63          	bne	a4,a5,80002b9e <usertrap+0x96>
    if(p->killed)
    80002b48:	551c                	lw	a5,40(a0)
    80002b4a:	e7a1                	bnez	a5,80002b92 <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002b4c:	70b8                	ld	a4,96(s1)
    80002b4e:	6f1c                	ld	a5,24(a4)
    80002b50:	0791                	addi	a5,a5,4
    80002b52:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	36a080e7          	jalr	874(ra) # 80002eca <syscall>
  if(p->killed)
    80002b68:	549c                	lw	a5,40(s1)
    80002b6a:	e7fd                	bnez	a5,80002c58 <usertrap+0x150>
  usertrapret();
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	e16080e7          	jalr	-490(ra) # 80002982 <usertrapret>
}
    80002b74:	70a2                	ld	ra,40(sp)
    80002b76:	7402                	ld	s0,32(sp)
    80002b78:	64e2                	ld	s1,24(sp)
    80002b7a:	6942                	ld	s2,16(sp)
    80002b7c:	69a2                	ld	s3,8(sp)
    80002b7e:	6145                	addi	sp,sp,48
    80002b80:	8082                	ret
    panic("usertrap: not from user mode");
    80002b82:	00005517          	auipc	a0,0x5
    80002b86:	71e50513          	addi	a0,a0,1822 # 800082a0 <states.0+0x58>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9b0080e7          	jalr	-1616(ra) # 8000053a <panic>
      exit(-1);
    80002b92:	557d                	li	a0,-1
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	8de080e7          	jalr	-1826(ra) # 80002472 <exit>
    80002b9c:	bf45                	j	80002b4c <usertrap+0x44>
   else if((which_dev = devintr()) != 0){
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	ec8080e7          	jalr	-312(ra) # 80002a66 <devintr>
    80002ba6:	892a                	mv	s2,a0
    80002ba8:	e54d                	bnez	a0,80002c52 <usertrap+0x14a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002baa:	14202773          	csrr	a4,scause
    else if (r_scause()==13 || r_scause()==15){
    80002bae:	47b5                	li	a5,13
    80002bb0:	00f70763          	beq	a4,a5,80002bbe <usertrap+0xb6>
    80002bb4:	14202773          	csrr	a4,scause
    80002bb8:	47bd                	li	a5,15
    80002bba:	06f71263          	bne	a4,a5,80002c1e <usertrap+0x116>
    if(myproc()->sz-PGSIZE < 0){
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	de0080e7          	jalr	-544(ra) # 8000199e <myproc>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc6:	14302973          	csrr	s2,stval
   	else if(r_stval()<myproc()->sz){
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	dd4080e7          	jalr	-556(ra) # 8000199e <myproc>
    80002bd2:	693c                	ld	a5,80(a0)
    80002bd4:	f8f97ae3          	bgeu	s2,a5,80002b68 <usertrap+0x60>
    80002bd8:	143029f3          	csrr	s3,stval
   		mem = kalloc();
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	f04080e7          	jalr	-252(ra) # 80000ae0 <kalloc>
    80002be4:	892a                	mv	s2,a0
   		memset(mem, 0, PGSIZE);
    80002be6:	6605                	lui	a2,0x1
    80002be8:	4581                	li	a1,0
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	134080e7          	jalr	308(ra) # 80000d1e <memset>
   if(mappages(myproc()->pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	dac080e7          	jalr	-596(ra) # 8000199e <myproc>
    80002bfa:	4779                	li	a4,30
    80002bfc:	86ca                	mv	a3,s2
    80002bfe:	6605                	lui	a2,0x1
    80002c00:	75fd                	lui	a1,0xfffff
    80002c02:	00b9f5b3          	and	a1,s3,a1
    80002c06:	6d28                	ld	a0,88(a0)
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	4de080e7          	jalr	1246(ra) # 800010e6 <mappages>
    80002c10:	dd21                	beqz	a0,80002b68 <usertrap+0x60>
      kfree(mem);
    80002c12:	854a                	mv	a0,s2
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	dce080e7          	jalr	-562(ra) # 800009e2 <kfree>
    80002c1c:	b7b1                	j	80002b68 <usertrap+0x60>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c22:	5890                	lw	a2,48(s1)
    80002c24:	00005517          	auipc	a0,0x5
    80002c28:	69c50513          	addi	a0,a0,1692 # 800082c0 <states.0+0x78>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	958080e7          	jalr	-1704(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c38:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c3c:	00005517          	auipc	a0,0x5
    80002c40:	6b450513          	addi	a0,a0,1716 # 800082f0 <states.0+0xa8>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	940080e7          	jalr	-1728(ra) # 80000584 <printf>
    p->killed = 1;
    80002c4c:	4785                	li	a5,1
    80002c4e:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80002c50:	a029                	j	80002c5a <usertrap+0x152>
    80002c52:	549c                	lw	a5,40(s1)
    80002c54:	cb81                	beqz	a5,80002c64 <usertrap+0x15c>
    80002c56:	a011                	j	80002c5a <usertrap+0x152>
    80002c58:	4901                	li	s2,0
    exit(-1);
    80002c5a:	557d                	li	a0,-1
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	816080e7          	jalr	-2026(ra) # 80002472 <exit>
  if(which_dev == 2){
    80002c64:	4789                	li	a5,2
    80002c66:	f0f913e3          	bne	s2,a5,80002b6c <usertrap+0x64>
  p->cputime +=1; // Anytime proc yields increament ticks by 1
    80002c6a:	58dc                	lw	a5,52(s1)
    80002c6c:	2785                	addiw	a5,a5,1
    80002c6e:	d8dc                	sw	a5,52(s1)
    yield();
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	3e8080e7          	jalr	1000(ra) # 80002058 <yield>
    80002c78:	bdd5                	j	80002b6c <usertrap+0x64>

0000000080002c7a <kerneltrap>:
{
    80002c7a:	7179                	addi	sp,sp,-48
    80002c7c:	f406                	sd	ra,40(sp)
    80002c7e:	f022                	sd	s0,32(sp)
    80002c80:	ec26                	sd	s1,24(sp)
    80002c82:	e84a                	sd	s2,16(sp)
    80002c84:	e44e                	sd	s3,8(sp)
    80002c86:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c88:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c8c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c90:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c94:	1004f793          	andi	a5,s1,256
    80002c98:	cb85                	beqz	a5,80002cc8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c9a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c9e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ca0:	ef85                	bnez	a5,80002cd8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	dc4080e7          	jalr	-572(ra) # 80002a66 <devintr>
    80002caa:	cd1d                	beqz	a0,80002ce8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002cac:	4789                	li	a5,2
    80002cae:	06f50a63          	beq	a0,a5,80002d22 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cb2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cb6:	10049073          	csrw	sstatus,s1
}
    80002cba:	70a2                	ld	ra,40(sp)
    80002cbc:	7402                	ld	s0,32(sp)
    80002cbe:	64e2                	ld	s1,24(sp)
    80002cc0:	6942                	ld	s2,16(sp)
    80002cc2:	69a2                	ld	s3,8(sp)
    80002cc4:	6145                	addi	sp,sp,48
    80002cc6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cc8:	00005517          	auipc	a0,0x5
    80002ccc:	64850513          	addi	a0,a0,1608 # 80008310 <states.0+0xc8>
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	86a080e7          	jalr	-1942(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002cd8:	00005517          	auipc	a0,0x5
    80002cdc:	66050513          	addi	a0,a0,1632 # 80008338 <states.0+0xf0>
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	85a080e7          	jalr	-1958(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002ce8:	85ce                	mv	a1,s3
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	66e50513          	addi	a0,a0,1646 # 80008358 <states.0+0x110>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	892080e7          	jalr	-1902(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cfa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cfe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d02:	00005517          	auipc	a0,0x5
    80002d06:	66650513          	addi	a0,a0,1638 # 80008368 <states.0+0x120>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	87a080e7          	jalr	-1926(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002d12:	00005517          	auipc	a0,0x5
    80002d16:	66e50513          	addi	a0,a0,1646 # 80008380 <states.0+0x138>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	820080e7          	jalr	-2016(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	c7c080e7          	jalr	-900(ra) # 8000199e <myproc>
    80002d2a:	d541                	beqz	a0,80002cb2 <kerneltrap+0x38>
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	c72080e7          	jalr	-910(ra) # 8000199e <myproc>
    80002d34:	4d18                	lw	a4,24(a0)
    80002d36:	4791                	li	a5,4
    80002d38:	f6f71de3          	bne	a4,a5,80002cb2 <kerneltrap+0x38>
    myproc()->cputime +=1;// Anytime proc yields increament ticks by 1
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	c62080e7          	jalr	-926(ra) # 8000199e <myproc>
    80002d44:	595c                	lw	a5,52(a0)
    80002d46:	2785                	addiw	a5,a5,1
    80002d48:	d95c                	sw	a5,52(a0)
    yield();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	30e080e7          	jalr	782(ra) # 80002058 <yield>
    80002d52:	b785                	j	80002cb2 <kerneltrap+0x38>

0000000080002d54 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d54:	1101                	addi	sp,sp,-32
    80002d56:	ec06                	sd	ra,24(sp)
    80002d58:	e822                	sd	s0,16(sp)
    80002d5a:	e426                	sd	s1,8(sp)
    80002d5c:	1000                	addi	s0,sp,32
    80002d5e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	c3e080e7          	jalr	-962(ra) # 8000199e <myproc>
  switch (n) {
    80002d68:	4795                	li	a5,5
    80002d6a:	0497e163          	bltu	a5,s1,80002dac <argraw+0x58>
    80002d6e:	048a                	slli	s1,s1,0x2
    80002d70:	00005717          	auipc	a4,0x5
    80002d74:	64870713          	addi	a4,a4,1608 # 800083b8 <states.0+0x170>
    80002d78:	94ba                	add	s1,s1,a4
    80002d7a:	409c                	lw	a5,0(s1)
    80002d7c:	97ba                	add	a5,a5,a4
    80002d7e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d80:	713c                	ld	a5,96(a0)
    80002d82:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d84:	60e2                	ld	ra,24(sp)
    80002d86:	6442                	ld	s0,16(sp)
    80002d88:	64a2                	ld	s1,8(sp)
    80002d8a:	6105                	addi	sp,sp,32
    80002d8c:	8082                	ret
    return p->trapframe->a1;
    80002d8e:	713c                	ld	a5,96(a0)
    80002d90:	7fa8                	ld	a0,120(a5)
    80002d92:	bfcd                	j	80002d84 <argraw+0x30>
    return p->trapframe->a2;
    80002d94:	713c                	ld	a5,96(a0)
    80002d96:	63c8                	ld	a0,128(a5)
    80002d98:	b7f5                	j	80002d84 <argraw+0x30>
    return p->trapframe->a3;
    80002d9a:	713c                	ld	a5,96(a0)
    80002d9c:	67c8                	ld	a0,136(a5)
    80002d9e:	b7dd                	j	80002d84 <argraw+0x30>
    return p->trapframe->a4;
    80002da0:	713c                	ld	a5,96(a0)
    80002da2:	6bc8                	ld	a0,144(a5)
    80002da4:	b7c5                	j	80002d84 <argraw+0x30>
    return p->trapframe->a5;
    80002da6:	713c                	ld	a5,96(a0)
    80002da8:	6fc8                	ld	a0,152(a5)
    80002daa:	bfe9                	j	80002d84 <argraw+0x30>
  panic("argraw");
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	5e450513          	addi	a0,a0,1508 # 80008390 <states.0+0x148>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	786080e7          	jalr	1926(ra) # 8000053a <panic>

0000000080002dbc <fetchaddr>:
{
    80002dbc:	1101                	addi	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	e426                	sd	s1,8(sp)
    80002dc4:	e04a                	sd	s2,0(sp)
    80002dc6:	1000                	addi	s0,sp,32
    80002dc8:	84aa                	mv	s1,a0
    80002dca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	bd2080e7          	jalr	-1070(ra) # 8000199e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002dd4:	693c                	ld	a5,80(a0)
    80002dd6:	02f4f863          	bgeu	s1,a5,80002e06 <fetchaddr+0x4a>
    80002dda:	00848713          	addi	a4,s1,8
    80002dde:	02e7e663          	bltu	a5,a4,80002e0a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002de2:	46a1                	li	a3,8
    80002de4:	8626                	mv	a2,s1
    80002de6:	85ca                	mv	a1,s2
    80002de8:	6d28                	ld	a0,88(a0)
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	904080e7          	jalr	-1788(ra) # 800016ee <copyin>
    80002df2:	00a03533          	snez	a0,a0
    80002df6:	40a00533          	neg	a0,a0
}
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	64a2                	ld	s1,8(sp)
    80002e00:	6902                	ld	s2,0(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret
    return -1;
    80002e06:	557d                	li	a0,-1
    80002e08:	bfcd                	j	80002dfa <fetchaddr+0x3e>
    80002e0a:	557d                	li	a0,-1
    80002e0c:	b7fd                	j	80002dfa <fetchaddr+0x3e>

0000000080002e0e <fetchstr>:
{
    80002e0e:	7179                	addi	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	e84a                	sd	s2,16(sp)
    80002e18:	e44e                	sd	s3,8(sp)
    80002e1a:	1800                	addi	s0,sp,48
    80002e1c:	892a                	mv	s2,a0
    80002e1e:	84ae                	mv	s1,a1
    80002e20:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	b7c080e7          	jalr	-1156(ra) # 8000199e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e2a:	86ce                	mv	a3,s3
    80002e2c:	864a                	mv	a2,s2
    80002e2e:	85a6                	mv	a1,s1
    80002e30:	6d28                	ld	a0,88(a0)
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	94a080e7          	jalr	-1718(ra) # 8000177c <copyinstr>
  if(err < 0)
    80002e3a:	00054763          	bltz	a0,80002e48 <fetchstr+0x3a>
  return strlen(buf);
    80002e3e:	8526                	mv	a0,s1
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	05a080e7          	jalr	90(ra) # 80000e9a <strlen>
}
    80002e48:	70a2                	ld	ra,40(sp)
    80002e4a:	7402                	ld	s0,32(sp)
    80002e4c:	64e2                	ld	s1,24(sp)
    80002e4e:	6942                	ld	s2,16(sp)
    80002e50:	69a2                	ld	s3,8(sp)
    80002e52:	6145                	addi	sp,sp,48
    80002e54:	8082                	ret

0000000080002e56 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e56:	1101                	addi	sp,sp,-32
    80002e58:	ec06                	sd	ra,24(sp)
    80002e5a:	e822                	sd	s0,16(sp)
    80002e5c:	e426                	sd	s1,8(sp)
    80002e5e:	1000                	addi	s0,sp,32
    80002e60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	ef2080e7          	jalr	-270(ra) # 80002d54 <argraw>
    80002e6a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e6c:	4501                	li	a0,0
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	1000                	addi	s0,sp,32
    80002e82:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	ed0080e7          	jalr	-304(ra) # 80002d54 <argraw>
    80002e8c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e8e:	4501                	li	a0,0
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	64a2                	ld	s1,8(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret

0000000080002e9a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	e426                	sd	s1,8(sp)
    80002ea2:	e04a                	sd	s2,0(sp)
    80002ea4:	1000                	addi	s0,sp,32
    80002ea6:	84ae                	mv	s1,a1
    80002ea8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	eaa080e7          	jalr	-342(ra) # 80002d54 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002eb2:	864a                	mv	a2,s2
    80002eb4:	85a6                	mv	a1,s1
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	f58080e7          	jalr	-168(ra) # 80002e0e <fetchstr>
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6902                	ld	s2,0(sp)
    80002ec6:	6105                	addi	sp,sp,32
    80002ec8:	8082                	ret

0000000080002eca <syscall>:
[SYS_freepmem] sys_freepmem,
};

void
syscall(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	e426                	sd	s1,8(sp)
    80002ed2:	e04a                	sd	s2,0(sp)
    80002ed4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	ac8080e7          	jalr	-1336(ra) # 8000199e <myproc>
    80002ede:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ee0:	06053903          	ld	s2,96(a0)
    80002ee4:	0a893783          	ld	a5,168(s2)
    80002ee8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eec:	37fd                	addiw	a5,a5,-1
    80002eee:	4765                	li	a4,25
    80002ef0:	00f76f63          	bltu	a4,a5,80002f0e <syscall+0x44>
    80002ef4:	00369713          	slli	a4,a3,0x3
    80002ef8:	00005797          	auipc	a5,0x5
    80002efc:	4d878793          	addi	a5,a5,1240 # 800083d0 <syscalls>
    80002f00:	97ba                	add	a5,a5,a4
    80002f02:	639c                	ld	a5,0(a5)
    80002f04:	c789                	beqz	a5,80002f0e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f06:	9782                	jalr	a5
    80002f08:	06a93823          	sd	a0,112(s2)
    80002f0c:	a839                	j	80002f2a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f0e:	16048613          	addi	a2,s1,352
    80002f12:	588c                	lw	a1,48(s1)
    80002f14:	00005517          	auipc	a0,0x5
    80002f18:	48450513          	addi	a0,a0,1156 # 80008398 <states.0+0x150>
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	668080e7          	jalr	1640(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f24:	70bc                	ld	a5,96(s1)
    80002f26:	577d                	li	a4,-1
    80002f28:	fbb8                	sd	a4,112(a5)
  }
}
    80002f2a:	60e2                	ld	ra,24(sp)
    80002f2c:	6442                	ld	s0,16(sp)
    80002f2e:	64a2                	ld	s1,8(sp)
    80002f30:	6902                	ld	s2,0(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f3e:	fec40593          	addi	a1,s0,-20
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	f12080e7          	jalr	-238(ra) # 80002e56 <argint>
    return -1;
    80002f4c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f4e:	00054963          	bltz	a0,80002f60 <sys_exit+0x2a>
  exit(n);
    80002f52:	fec42503          	lw	a0,-20(s0)
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	51c080e7          	jalr	1308(ra) # 80002472 <exit>
  return 0;  // not reached
    80002f5e:	4781                	li	a5,0
}
    80002f60:	853e                	mv	a0,a5
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret

0000000080002f6a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f6a:	1141                	addi	sp,sp,-16
    80002f6c:	e406                	sd	ra,8(sp)
    80002f6e:	e022                	sd	s0,0(sp)
    80002f70:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	a2c080e7          	jalr	-1492(ra) # 8000199e <myproc>
}
    80002f7a:	5908                	lw	a0,48(a0)
    80002f7c:	60a2                	ld	ra,8(sp)
    80002f7e:	6402                	ld	s0,0(sp)
    80002f80:	0141                	addi	sp,sp,16
    80002f82:	8082                	ret

0000000080002f84 <sys_fork>:

uint64
sys_fork(void)
{
    80002f84:	1141                	addi	sp,sp,-16
    80002f86:	e406                	sd	ra,8(sp)
    80002f88:	e022                	sd	s0,0(sp)
    80002f8a:	0800                	addi	s0,sp,16
  return fork();
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	df2080e7          	jalr	-526(ra) # 80001d7e <fork>
}
    80002f94:	60a2                	ld	ra,8(sp)
    80002f96:	6402                	ld	s0,0(sp)
    80002f98:	0141                	addi	sp,sp,16
    80002f9a:	8082                	ret

0000000080002f9c <sys_wait>:

uint64
sys_wait(void)
{
    80002f9c:	1101                	addi	sp,sp,-32
    80002f9e:	ec06                	sd	ra,24(sp)
    80002fa0:	e822                	sd	s0,16(sp)
    80002fa2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fa4:	fe840593          	addi	a1,s0,-24
    80002fa8:	4501                	li	a0,0
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	ece080e7          	jalr	-306(ra) # 80002e78 <argaddr>
    80002fb2:	87aa                	mv	a5,a0
    return -1;
    80002fb4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fb6:	0007c863          	bltz	a5,80002fc6 <sys_wait+0x2a>
  return wait(p);
    80002fba:	fe843503          	ld	a0,-24(s0)
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	144080e7          	jalr	324(ra) # 80002102 <wait>
}
    80002fc6:	60e2                	ld	ra,24(sp)
    80002fc8:	6442                	ld	s0,16(sp)
    80002fca:	6105                	addi	sp,sp,32
    80002fcc:	8082                	ret

0000000080002fce <sys_wait2>:

uint64
sys_wait2(void)
{
    80002fce:	1101                	addi	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	1000                	addi	s0,sp,32
  uint64 p;
  uint64 p1; //Pointer for second argument
  
  if(argaddr(0, &p) < 0)
    80002fd6:	fe840593          	addi	a1,s0,-24
    80002fda:	4501                	li	a0,0
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	e9c080e7          	jalr	-356(ra) # 80002e78 <argaddr>
    return -1;
    80002fe4:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002fe6:	02054563          	bltz	a0,80003010 <sys_wait2+0x42>
  if(argaddr(1, &p1) < 0) //1 is in refrence to second argument ie rusage * we sent in
    80002fea:	fe040593          	addi	a1,s0,-32
    80002fee:	4505                	li	a0,1
    80002ff0:	00000097          	auipc	ra,0x0
    80002ff4:	e88080e7          	jalr	-376(ra) # 80002e78 <argaddr>
    return -1;
    80002ff8:	57fd                	li	a5,-1
  if(argaddr(1, &p1) < 0) //1 is in refrence to second argument ie rusage * we sent in
    80002ffa:	00054b63          	bltz	a0,80003010 <sys_wait2+0x42>
  return wait2(p,p1);
    80002ffe:	fe043583          	ld	a1,-32(s0)
    80003002:	fe843503          	ld	a0,-24(s0)
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	224080e7          	jalr	548(ra) # 8000222a <wait2>
    8000300e:	87aa                	mv	a5,a0
}
    80003010:	853e                	mv	a0,a5
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <sys_getpriority>:

uint64
sys_getpriority(void)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003022:	fe840593          	addi	a1,s0,-24
    80003026:	4501                	li	a0,0
    80003028:	00000097          	auipc	ra,0x0
    8000302c:	e50080e7          	jalr	-432(ra) # 80002e78 <argaddr>
    80003030:	87aa                	mv	a5,a0
    return -1;
    80003032:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003034:	0007c863          	bltz	a5,80003044 <sys_getpriority+0x2a>
  return getpriority(p);
    80003038:	fe843503          	ld	a0,-24(s0)
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	7b2080e7          	jalr	1970(ra) # 800027ee <getpriority>
}
    80003044:	60e2                	ld	ra,24(sp)
    80003046:	6442                	ld	s0,16(sp)
    80003048:	6105                	addi	sp,sp,32
    8000304a:	8082                	ret

000000008000304c <sys_setpriority>:

uint64
sys_setpriority(void)
{
    8000304c:	1101                	addi	sp,sp,-32
    8000304e:	ec06                	sd	ra,24(sp)
    80003050:	e822                	sd	s0,16(sp)
    80003052:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003054:	fe840593          	addi	a1,s0,-24
    80003058:	4501                	li	a0,0
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	e1e080e7          	jalr	-482(ra) # 80002e78 <argaddr>
    80003062:	87aa                	mv	a5,a0
    return -1;
    80003064:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003066:	0007c863          	bltz	a5,80003076 <sys_setpriority+0x2a>
  return setpriority(p);
    8000306a:	fe843503          	ld	a0,-24(s0)
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	7ca080e7          	jalr	1994(ra) # 80002838 <setpriority>
}
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret

000000008000307e <sys_freepmem>:

uint64
sys_freepmem(void)
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003086:	fe840593          	addi	a1,s0,-24
    8000308a:	4501                	li	a0,0
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	dec080e7          	jalr	-532(ra) # 80002e78 <argaddr>
    80003094:	87aa                	mv	a5,a0
    return -1;
    80003096:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003098:	0007c863          	bltz	a5,800030a8 <sys_freepmem+0x2a>
  return freepmem(p);
    8000309c:	fe843503          	ld	a0,-24(s0)
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	7e2080e7          	jalr	2018(ra) # 80002882 <freepmem>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030b0:	7139                	addi	sp,sp,-64
    800030b2:	fc06                	sd	ra,56(sp)
    800030b4:	f822                	sd	s0,48(sp)
    800030b6:	f426                	sd	s1,40(sp)
    800030b8:	f04a                	sd	s2,32(sp)
    800030ba:	ec4e                	sd	s3,24(sp)
    800030bc:	0080                	addi	s0,sp,64
  int addr;
  int n;
  int size = myproc()->sz;
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	8e0080e7          	jalr	-1824(ra) # 8000199e <myproc>
    800030c6:	05053983          	ld	s3,80(a0)
  if(argint(0, &n) < 0)
    800030ca:	fcc40593          	addi	a1,s0,-52
    800030ce:	4501                	li	a0,0
    800030d0:	00000097          	auipc	ra,0x0
    800030d4:	d86080e7          	jalr	-634(ra) # 80002e56 <argint>
    800030d8:	87aa                	mv	a5,a0
    return -1;
    800030da:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030dc:	0007cf63          	bltz	a5,800030fa <sys_sbrk+0x4a>
  int size = myproc()->sz;
    800030e0:	0009849b          	sext.w	s1,s3
  addr = size;
  myproc()->sz = size+n;
    800030e4:	fcc42903          	lw	s2,-52(s0)
    800030e8:	0139093b          	addw	s2,s2,s3
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	8b2080e7          	jalr	-1870(ra) # 8000199e <myproc>
    800030f4:	05253823          	sd	s2,80(a0)
  return addr;
    800030f8:	8526                	mv	a0,s1
}
    800030fa:	70e2                	ld	ra,56(sp)
    800030fc:	7442                	ld	s0,48(sp)
    800030fe:	74a2                	ld	s1,40(sp)
    80003100:	7902                	ld	s2,32(sp)
    80003102:	69e2                	ld	s3,24(sp)
    80003104:	6121                	addi	sp,sp,64
    80003106:	8082                	ret

0000000080003108 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003108:	7139                	addi	sp,sp,-64
    8000310a:	fc06                	sd	ra,56(sp)
    8000310c:	f822                	sd	s0,48(sp)
    8000310e:	f426                	sd	s1,40(sp)
    80003110:	f04a                	sd	s2,32(sp)
    80003112:	ec4e                	sd	s3,24(sp)
    80003114:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003116:	fcc40593          	addi	a1,s0,-52
    8000311a:	4501                	li	a0,0
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	d3a080e7          	jalr	-710(ra) # 80002e56 <argint>
    return -1;
    80003124:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003126:	06054763          	bltz	a0,80003194 <sys_sleep+0x8c>
  ticks0 = ticks;
    8000312a:	00006497          	auipc	s1,0x6
    8000312e:	f0648493          	addi	s1,s1,-250 # 80009030 <ticks>
    80003132:	0004a903          	lw	s2,0(s1)
  acquire(&tickslock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	19a50513          	addi	a0,a0,410 # 800172d0 <tickslock>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	ae4080e7          	jalr	-1308(ra) # 80000c22 <acquire>
  while(ticks - ticks0 < n){
    80003146:	409c                	lw	a5,0(s1)
    80003148:	412787bb          	subw	a5,a5,s2
    8000314c:	fcc42703          	lw	a4,-52(s0)
    80003150:	02e7f963          	bgeu	a5,a4,80003182 <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
     return -1;
    }
    sleep(&ticks, &tickslock);
    80003154:	00014997          	auipc	s3,0x14
    80003158:	17c98993          	addi	s3,s3,380 # 800172d0 <tickslock>
    if(myproc()->killed){
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	842080e7          	jalr	-1982(ra) # 8000199e <myproc>
    80003164:	551c                	lw	a5,40(a0)
    80003166:	ef9d                	bnez	a5,800031a4 <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80003168:	85ce                	mv	a1,s3
    8000316a:	8526                	mv	a0,s1
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	f32080e7          	jalr	-206(ra) # 8000209e <sleep>
  while(ticks - ticks0 < n){
    80003174:	409c                	lw	a5,0(s1)
    80003176:	412787bb          	subw	a5,a5,s2
    8000317a:	fcc42703          	lw	a4,-52(s0)
    8000317e:	fce7efe3          	bltu	a5,a4,8000315c <sys_sleep+0x54>
  }
  release(&tickslock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	14e50513          	addi	a0,a0,334 # 800172d0 <tickslock>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	b4c080e7          	jalr	-1204(ra) # 80000cd6 <release>
  return 0;
    80003192:	4781                	li	a5,0
}
    80003194:	853e                	mv	a0,a5
    80003196:	70e2                	ld	ra,56(sp)
    80003198:	7442                	ld	s0,48(sp)
    8000319a:	74a2                	ld	s1,40(sp)
    8000319c:	7902                	ld	s2,32(sp)
    8000319e:	69e2                	ld	s3,24(sp)
    800031a0:	6121                	addi	sp,sp,64
    800031a2:	8082                	ret
      release(&tickslock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	12c50513          	addi	a0,a0,300 # 800172d0 <tickslock>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	b2a080e7          	jalr	-1238(ra) # 80000cd6 <release>
     return -1;
    800031b4:	57fd                	li	a5,-1
    800031b6:	bff9                	j	80003194 <sys_sleep+0x8c>

00000000800031b8 <sys_kill>:

uint64
sys_kill(void)
{
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800031c0:	fec40593          	addi	a1,s0,-20
    800031c4:	4501                	li	a0,0
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	c90080e7          	jalr	-880(ra) # 80002e56 <argint>
    800031ce:	87aa                	mv	a5,a0
    return -1;
    800031d0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031d2:	0007c863          	bltz	a5,800031e2 <sys_kill+0x2a>
  return kill(pid);
    800031d6:	fec42503          	lw	a0,-20(s0)
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	36e080e7          	jalr	878(ra) # 80002548 <kill>
}
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret

00000000800031ea <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	0dc50513          	addi	a0,a0,220 # 800172d0 <tickslock>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	a26080e7          	jalr	-1498(ra) # 80000c22 <acquire>
  xticks = ticks;
    80003204:	00006497          	auipc	s1,0x6
    80003208:	e2c4a483          	lw	s1,-468(s1) # 80009030 <ticks>
  release(&tickslock);
    8000320c:	00014517          	auipc	a0,0x14
    80003210:	0c450513          	addi	a0,a0,196 # 800172d0 <tickslock>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	ac2080e7          	jalr	-1342(ra) # 80000cd6 <release>
  return xticks;
}
    8000321c:	02049513          	slli	a0,s1,0x20
    80003220:	9101                	srli	a0,a0,0x20
    80003222:	60e2                	ld	ra,24(sp)
    80003224:	6442                	ld	s0,16(sp)
    80003226:	64a2                	ld	s1,8(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret

000000008000322c <sys_getprocs>:

// return the number of active processes in the system
// fill in user-provided data structure with pid,state,sz,ppid,name
uint64
sys_getprocs(void)
{
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	1000                	addi	s0,sp,32
  uint64 addr;  // user pointer to struct pstat

  if (argaddr(0, &addr) < 0)
    80003234:	fe840593          	addi	a1,s0,-24
    80003238:	4501                	li	a0,0
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	c3e080e7          	jalr	-962(ra) # 80002e78 <argaddr>
    80003242:	87aa                	mv	a5,a0
    return -1;
    80003244:	557d                	li	a0,-1
  if (argaddr(0, &addr) < 0)
    80003246:	0007c863          	bltz	a5,80003256 <sys_getprocs+0x2a>
  return(procinfo(addr));
    8000324a:	fe843503          	ld	a0,-24(s0)
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	4d2080e7          	jalr	1234(ra) # 80002720 <procinfo>
}
    80003256:	60e2                	ld	ra,24(sp)
    80003258:	6442                	ld	s0,16(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret

000000008000325e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000325e:	7179                	addi	sp,sp,-48
    80003260:	f406                	sd	ra,40(sp)
    80003262:	f022                	sd	s0,32(sp)
    80003264:	ec26                	sd	s1,24(sp)
    80003266:	e84a                	sd	s2,16(sp)
    80003268:	e44e                	sd	s3,8(sp)
    8000326a:	e052                	sd	s4,0(sp)
    8000326c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000326e:	00005597          	auipc	a1,0x5
    80003272:	23a58593          	addi	a1,a1,570 # 800084a8 <syscalls+0xd8>
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	07250513          	addi	a0,a0,114 # 800172e8 <bcache>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	914080e7          	jalr	-1772(ra) # 80000b92 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003286:	0001c797          	auipc	a5,0x1c
    8000328a:	06278793          	addi	a5,a5,98 # 8001f2e8 <bcache+0x8000>
    8000328e:	0001c717          	auipc	a4,0x1c
    80003292:	2c270713          	addi	a4,a4,706 # 8001f550 <bcache+0x8268>
    80003296:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000329a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000329e:	00014497          	auipc	s1,0x14
    800032a2:	06248493          	addi	s1,s1,98 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    800032a6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032a8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032aa:	00005a17          	auipc	s4,0x5
    800032ae:	206a0a13          	addi	s4,s4,518 # 800084b0 <syscalls+0xe0>
    b->next = bcache.head.next;
    800032b2:	2b893783          	ld	a5,696(s2)
    800032b6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032b8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032bc:	85d2                	mv	a1,s4
    800032be:	01048513          	addi	a0,s1,16
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	4c2080e7          	jalr	1218(ra) # 80004784 <initsleeplock>
    bcache.head.next->prev = b;
    800032ca:	2b893783          	ld	a5,696(s2)
    800032ce:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032d0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032d4:	45848493          	addi	s1,s1,1112
    800032d8:	fd349de3          	bne	s1,s3,800032b2 <binit+0x54>
  }
}
    800032dc:	70a2                	ld	ra,40(sp)
    800032de:	7402                	ld	s0,32(sp)
    800032e0:	64e2                	ld	s1,24(sp)
    800032e2:	6942                	ld	s2,16(sp)
    800032e4:	69a2                	ld	s3,8(sp)
    800032e6:	6a02                	ld	s4,0(sp)
    800032e8:	6145                	addi	sp,sp,48
    800032ea:	8082                	ret

00000000800032ec <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032ec:	7179                	addi	sp,sp,-48
    800032ee:	f406                	sd	ra,40(sp)
    800032f0:	f022                	sd	s0,32(sp)
    800032f2:	ec26                	sd	s1,24(sp)
    800032f4:	e84a                	sd	s2,16(sp)
    800032f6:	e44e                	sd	s3,8(sp)
    800032f8:	1800                	addi	s0,sp,48
    800032fa:	892a                	mv	s2,a0
    800032fc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032fe:	00014517          	auipc	a0,0x14
    80003302:	fea50513          	addi	a0,a0,-22 # 800172e8 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	91c080e7          	jalr	-1764(ra) # 80000c22 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000330e:	0001c497          	auipc	s1,0x1c
    80003312:	2924b483          	ld	s1,658(s1) # 8001f5a0 <bcache+0x82b8>
    80003316:	0001c797          	auipc	a5,0x1c
    8000331a:	23a78793          	addi	a5,a5,570 # 8001f550 <bcache+0x8268>
    8000331e:	02f48f63          	beq	s1,a5,8000335c <bread+0x70>
    80003322:	873e                	mv	a4,a5
    80003324:	a021                	j	8000332c <bread+0x40>
    80003326:	68a4                	ld	s1,80(s1)
    80003328:	02e48a63          	beq	s1,a4,8000335c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000332c:	449c                	lw	a5,8(s1)
    8000332e:	ff279ce3          	bne	a5,s2,80003326 <bread+0x3a>
    80003332:	44dc                	lw	a5,12(s1)
    80003334:	ff3799e3          	bne	a5,s3,80003326 <bread+0x3a>
      b->refcnt++;
    80003338:	40bc                	lw	a5,64(s1)
    8000333a:	2785                	addiw	a5,a5,1
    8000333c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000333e:	00014517          	auipc	a0,0x14
    80003342:	faa50513          	addi	a0,a0,-86 # 800172e8 <bcache>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	990080e7          	jalr	-1648(ra) # 80000cd6 <release>
      acquiresleep(&b->lock);
    8000334e:	01048513          	addi	a0,s1,16
    80003352:	00001097          	auipc	ra,0x1
    80003356:	46c080e7          	jalr	1132(ra) # 800047be <acquiresleep>
      return b;
    8000335a:	a8b9                	j	800033b8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000335c:	0001c497          	auipc	s1,0x1c
    80003360:	23c4b483          	ld	s1,572(s1) # 8001f598 <bcache+0x82b0>
    80003364:	0001c797          	auipc	a5,0x1c
    80003368:	1ec78793          	addi	a5,a5,492 # 8001f550 <bcache+0x8268>
    8000336c:	00f48863          	beq	s1,a5,8000337c <bread+0x90>
    80003370:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003372:	40bc                	lw	a5,64(s1)
    80003374:	cf81                	beqz	a5,8000338c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003376:	64a4                	ld	s1,72(s1)
    80003378:	fee49de3          	bne	s1,a4,80003372 <bread+0x86>
  panic("bget: no buffers");
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	13c50513          	addi	a0,a0,316 # 800084b8 <syscalls+0xe8>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	1b6080e7          	jalr	438(ra) # 8000053a <panic>
      b->dev = dev;
    8000338c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003390:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003394:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003398:	4785                	li	a5,1
    8000339a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	f4c50513          	addi	a0,a0,-180 # 800172e8 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	932080e7          	jalr	-1742(ra) # 80000cd6 <release>
      acquiresleep(&b->lock);
    800033ac:	01048513          	addi	a0,s1,16
    800033b0:	00001097          	auipc	ra,0x1
    800033b4:	40e080e7          	jalr	1038(ra) # 800047be <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033b8:	409c                	lw	a5,0(s1)
    800033ba:	cb89                	beqz	a5,800033cc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033bc:	8526                	mv	a0,s1
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	69a2                	ld	s3,8(sp)
    800033c8:	6145                	addi	sp,sp,48
    800033ca:	8082                	ret
    virtio_disk_rw(b, 0);
    800033cc:	4581                	li	a1,0
    800033ce:	8526                	mv	a0,s1
    800033d0:	00003097          	auipc	ra,0x3
    800033d4:	f22080e7          	jalr	-222(ra) # 800062f2 <virtio_disk_rw>
    b->valid = 1;
    800033d8:	4785                	li	a5,1
    800033da:	c09c                	sw	a5,0(s1)
  return b;
    800033dc:	b7c5                	j	800033bc <bread+0xd0>

00000000800033de <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033de:	1101                	addi	sp,sp,-32
    800033e0:	ec06                	sd	ra,24(sp)
    800033e2:	e822                	sd	s0,16(sp)
    800033e4:	e426                	sd	s1,8(sp)
    800033e6:	1000                	addi	s0,sp,32
    800033e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033ea:	0541                	addi	a0,a0,16
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	46c080e7          	jalr	1132(ra) # 80004858 <holdingsleep>
    800033f4:	cd01                	beqz	a0,8000340c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033f6:	4585                	li	a1,1
    800033f8:	8526                	mv	a0,s1
    800033fa:	00003097          	auipc	ra,0x3
    800033fe:	ef8080e7          	jalr	-264(ra) # 800062f2 <virtio_disk_rw>
}
    80003402:	60e2                	ld	ra,24(sp)
    80003404:	6442                	ld	s0,16(sp)
    80003406:	64a2                	ld	s1,8(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret
    panic("bwrite");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	0c450513          	addi	a0,a0,196 # 800084d0 <syscalls+0x100>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	126080e7          	jalr	294(ra) # 8000053a <panic>

000000008000341c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000341c:	1101                	addi	sp,sp,-32
    8000341e:	ec06                	sd	ra,24(sp)
    80003420:	e822                	sd	s0,16(sp)
    80003422:	e426                	sd	s1,8(sp)
    80003424:	e04a                	sd	s2,0(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000342a:	01050913          	addi	s2,a0,16
    8000342e:	854a                	mv	a0,s2
    80003430:	00001097          	auipc	ra,0x1
    80003434:	428080e7          	jalr	1064(ra) # 80004858 <holdingsleep>
    80003438:	c92d                	beqz	a0,800034aa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000343a:	854a                	mv	a0,s2
    8000343c:	00001097          	auipc	ra,0x1
    80003440:	3d8080e7          	jalr	984(ra) # 80004814 <releasesleep>

  acquire(&bcache.lock);
    80003444:	00014517          	auipc	a0,0x14
    80003448:	ea450513          	addi	a0,a0,-348 # 800172e8 <bcache>
    8000344c:	ffffd097          	auipc	ra,0xffffd
    80003450:	7d6080e7          	jalr	2006(ra) # 80000c22 <acquire>
  b->refcnt--;
    80003454:	40bc                	lw	a5,64(s1)
    80003456:	37fd                	addiw	a5,a5,-1
    80003458:	0007871b          	sext.w	a4,a5
    8000345c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000345e:	eb05                	bnez	a4,8000348e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003460:	68bc                	ld	a5,80(s1)
    80003462:	64b8                	ld	a4,72(s1)
    80003464:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003466:	64bc                	ld	a5,72(s1)
    80003468:	68b8                	ld	a4,80(s1)
    8000346a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000346c:	0001c797          	auipc	a5,0x1c
    80003470:	e7c78793          	addi	a5,a5,-388 # 8001f2e8 <bcache+0x8000>
    80003474:	2b87b703          	ld	a4,696(a5)
    80003478:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000347a:	0001c717          	auipc	a4,0x1c
    8000347e:	0d670713          	addi	a4,a4,214 # 8001f550 <bcache+0x8268>
    80003482:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003484:	2b87b703          	ld	a4,696(a5)
    80003488:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000348a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000348e:	00014517          	auipc	a0,0x14
    80003492:	e5a50513          	addi	a0,a0,-422 # 800172e8 <bcache>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	840080e7          	jalr	-1984(ra) # 80000cd6 <release>
}
    8000349e:	60e2                	ld	ra,24(sp)
    800034a0:	6442                	ld	s0,16(sp)
    800034a2:	64a2                	ld	s1,8(sp)
    800034a4:	6902                	ld	s2,0(sp)
    800034a6:	6105                	addi	sp,sp,32
    800034a8:	8082                	ret
    panic("brelse");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	02e50513          	addi	a0,a0,46 # 800084d8 <syscalls+0x108>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	088080e7          	jalr	136(ra) # 8000053a <panic>

00000000800034ba <bpin>:

void
bpin(struct buf *b) {
    800034ba:	1101                	addi	sp,sp,-32
    800034bc:	ec06                	sd	ra,24(sp)
    800034be:	e822                	sd	s0,16(sp)
    800034c0:	e426                	sd	s1,8(sp)
    800034c2:	1000                	addi	s0,sp,32
    800034c4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c6:	00014517          	auipc	a0,0x14
    800034ca:	e2250513          	addi	a0,a0,-478 # 800172e8 <bcache>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	754080e7          	jalr	1876(ra) # 80000c22 <acquire>
  b->refcnt++;
    800034d6:	40bc                	lw	a5,64(s1)
    800034d8:	2785                	addiw	a5,a5,1
    800034da:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034dc:	00014517          	auipc	a0,0x14
    800034e0:	e0c50513          	addi	a0,a0,-500 # 800172e8 <bcache>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	7f2080e7          	jalr	2034(ra) # 80000cd6 <release>
}
    800034ec:	60e2                	ld	ra,24(sp)
    800034ee:	6442                	ld	s0,16(sp)
    800034f0:	64a2                	ld	s1,8(sp)
    800034f2:	6105                	addi	sp,sp,32
    800034f4:	8082                	ret

00000000800034f6 <bunpin>:

void
bunpin(struct buf *b) {
    800034f6:	1101                	addi	sp,sp,-32
    800034f8:	ec06                	sd	ra,24(sp)
    800034fa:	e822                	sd	s0,16(sp)
    800034fc:	e426                	sd	s1,8(sp)
    800034fe:	1000                	addi	s0,sp,32
    80003500:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003502:	00014517          	auipc	a0,0x14
    80003506:	de650513          	addi	a0,a0,-538 # 800172e8 <bcache>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	718080e7          	jalr	1816(ra) # 80000c22 <acquire>
  b->refcnt--;
    80003512:	40bc                	lw	a5,64(s1)
    80003514:	37fd                	addiw	a5,a5,-1
    80003516:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003518:	00014517          	auipc	a0,0x14
    8000351c:	dd050513          	addi	a0,a0,-560 # 800172e8 <bcache>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	7b6080e7          	jalr	1974(ra) # 80000cd6 <release>
}
    80003528:	60e2                	ld	ra,24(sp)
    8000352a:	6442                	ld	s0,16(sp)
    8000352c:	64a2                	ld	s1,8(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret

0000000080003532 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	e04a                	sd	s2,0(sp)
    8000353c:	1000                	addi	s0,sp,32
    8000353e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003540:	00d5d59b          	srliw	a1,a1,0xd
    80003544:	0001c797          	auipc	a5,0x1c
    80003548:	4807a783          	lw	a5,1152(a5) # 8001f9c4 <sb+0x1c>
    8000354c:	9dbd                	addw	a1,a1,a5
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	d9e080e7          	jalr	-610(ra) # 800032ec <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003556:	0074f713          	andi	a4,s1,7
    8000355a:	4785                	li	a5,1
    8000355c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003560:	14ce                	slli	s1,s1,0x33
    80003562:	90d9                	srli	s1,s1,0x36
    80003564:	00950733          	add	a4,a0,s1
    80003568:	05874703          	lbu	a4,88(a4)
    8000356c:	00e7f6b3          	and	a3,a5,a4
    80003570:	c69d                	beqz	a3,8000359e <bfree+0x6c>
    80003572:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003574:	94aa                	add	s1,s1,a0
    80003576:	fff7c793          	not	a5,a5
    8000357a:	8f7d                	and	a4,a4,a5
    8000357c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003580:	00001097          	auipc	ra,0x1
    80003584:	120080e7          	jalr	288(ra) # 800046a0 <log_write>
  brelse(bp);
    80003588:	854a                	mv	a0,s2
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	e92080e7          	jalr	-366(ra) # 8000341c <brelse>
}
    80003592:	60e2                	ld	ra,24(sp)
    80003594:	6442                	ld	s0,16(sp)
    80003596:	64a2                	ld	s1,8(sp)
    80003598:	6902                	ld	s2,0(sp)
    8000359a:	6105                	addi	sp,sp,32
    8000359c:	8082                	ret
    panic("freeing free block");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	f4250513          	addi	a0,a0,-190 # 800084e0 <syscalls+0x110>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f94080e7          	jalr	-108(ra) # 8000053a <panic>

00000000800035ae <balloc>:
{
    800035ae:	711d                	addi	sp,sp,-96
    800035b0:	ec86                	sd	ra,88(sp)
    800035b2:	e8a2                	sd	s0,80(sp)
    800035b4:	e4a6                	sd	s1,72(sp)
    800035b6:	e0ca                	sd	s2,64(sp)
    800035b8:	fc4e                	sd	s3,56(sp)
    800035ba:	f852                	sd	s4,48(sp)
    800035bc:	f456                	sd	s5,40(sp)
    800035be:	f05a                	sd	s6,32(sp)
    800035c0:	ec5e                	sd	s7,24(sp)
    800035c2:	e862                	sd	s8,16(sp)
    800035c4:	e466                	sd	s9,8(sp)
    800035c6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035c8:	0001c797          	auipc	a5,0x1c
    800035cc:	3e47a783          	lw	a5,996(a5) # 8001f9ac <sb+0x4>
    800035d0:	cbc1                	beqz	a5,80003660 <balloc+0xb2>
    800035d2:	8baa                	mv	s7,a0
    800035d4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035d6:	0001cb17          	auipc	s6,0x1c
    800035da:	3d2b0b13          	addi	s6,s6,978 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035de:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035e0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035e4:	6c89                	lui	s9,0x2
    800035e6:	a831                	j	80003602 <balloc+0x54>
    brelse(bp);
    800035e8:	854a                	mv	a0,s2
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	e32080e7          	jalr	-462(ra) # 8000341c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035f2:	015c87bb          	addw	a5,s9,s5
    800035f6:	00078a9b          	sext.w	s5,a5
    800035fa:	004b2703          	lw	a4,4(s6)
    800035fe:	06eaf163          	bgeu	s5,a4,80003660 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003602:	41fad79b          	sraiw	a5,s5,0x1f
    80003606:	0137d79b          	srliw	a5,a5,0x13
    8000360a:	015787bb          	addw	a5,a5,s5
    8000360e:	40d7d79b          	sraiw	a5,a5,0xd
    80003612:	01cb2583          	lw	a1,28(s6)
    80003616:	9dbd                	addw	a1,a1,a5
    80003618:	855e                	mv	a0,s7
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	cd2080e7          	jalr	-814(ra) # 800032ec <bread>
    80003622:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003624:	004b2503          	lw	a0,4(s6)
    80003628:	000a849b          	sext.w	s1,s5
    8000362c:	8762                	mv	a4,s8
    8000362e:	faa4fde3          	bgeu	s1,a0,800035e8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003632:	00777693          	andi	a3,a4,7
    80003636:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000363a:	41f7579b          	sraiw	a5,a4,0x1f
    8000363e:	01d7d79b          	srliw	a5,a5,0x1d
    80003642:	9fb9                	addw	a5,a5,a4
    80003644:	4037d79b          	sraiw	a5,a5,0x3
    80003648:	00f90633          	add	a2,s2,a5
    8000364c:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003650:	00c6f5b3          	and	a1,a3,a2
    80003654:	cd91                	beqz	a1,80003670 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003656:	2705                	addiw	a4,a4,1
    80003658:	2485                	addiw	s1,s1,1
    8000365a:	fd471ae3          	bne	a4,s4,8000362e <balloc+0x80>
    8000365e:	b769                	j	800035e8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003660:	00005517          	auipc	a0,0x5
    80003664:	e9850513          	addi	a0,a0,-360 # 800084f8 <syscalls+0x128>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	ed2080e7          	jalr	-302(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003670:	97ca                	add	a5,a5,s2
    80003672:	8e55                	or	a2,a2,a3
    80003674:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003678:	854a                	mv	a0,s2
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	026080e7          	jalr	38(ra) # 800046a0 <log_write>
        brelse(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	00000097          	auipc	ra,0x0
    80003688:	d98080e7          	jalr	-616(ra) # 8000341c <brelse>
  bp = bread(dev, bno);
    8000368c:	85a6                	mv	a1,s1
    8000368e:	855e                	mv	a0,s7
    80003690:	00000097          	auipc	ra,0x0
    80003694:	c5c080e7          	jalr	-932(ra) # 800032ec <bread>
    80003698:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000369a:	40000613          	li	a2,1024
    8000369e:	4581                	li	a1,0
    800036a0:	05850513          	addi	a0,a0,88
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	67a080e7          	jalr	1658(ra) # 80000d1e <memset>
  log_write(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	ff2080e7          	jalr	-14(ra) # 800046a0 <log_write>
  brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	d64080e7          	jalr	-668(ra) # 8000341c <brelse>
}
    800036c0:	8526                	mv	a0,s1
    800036c2:	60e6                	ld	ra,88(sp)
    800036c4:	6446                	ld	s0,80(sp)
    800036c6:	64a6                	ld	s1,72(sp)
    800036c8:	6906                	ld	s2,64(sp)
    800036ca:	79e2                	ld	s3,56(sp)
    800036cc:	7a42                	ld	s4,48(sp)
    800036ce:	7aa2                	ld	s5,40(sp)
    800036d0:	7b02                	ld	s6,32(sp)
    800036d2:	6be2                	ld	s7,24(sp)
    800036d4:	6c42                	ld	s8,16(sp)
    800036d6:	6ca2                	ld	s9,8(sp)
    800036d8:	6125                	addi	sp,sp,96
    800036da:	8082                	ret

00000000800036dc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036dc:	7179                	addi	sp,sp,-48
    800036de:	f406                	sd	ra,40(sp)
    800036e0:	f022                	sd	s0,32(sp)
    800036e2:	ec26                	sd	s1,24(sp)
    800036e4:	e84a                	sd	s2,16(sp)
    800036e6:	e44e                	sd	s3,8(sp)
    800036e8:	e052                	sd	s4,0(sp)
    800036ea:	1800                	addi	s0,sp,48
    800036ec:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ee:	47ad                	li	a5,11
    800036f0:	04b7fe63          	bgeu	a5,a1,8000374c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036f4:	ff45849b          	addiw	s1,a1,-12
    800036f8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036fc:	0ff00793          	li	a5,255
    80003700:	0ae7e463          	bltu	a5,a4,800037a8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003704:	08052583          	lw	a1,128(a0)
    80003708:	c5b5                	beqz	a1,80003774 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000370a:	00092503          	lw	a0,0(s2)
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	bde080e7          	jalr	-1058(ra) # 800032ec <bread>
    80003716:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003718:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000371c:	02049713          	slli	a4,s1,0x20
    80003720:	01e75593          	srli	a1,a4,0x1e
    80003724:	00b784b3          	add	s1,a5,a1
    80003728:	0004a983          	lw	s3,0(s1)
    8000372c:	04098e63          	beqz	s3,80003788 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003730:	8552                	mv	a0,s4
    80003732:	00000097          	auipc	ra,0x0
    80003736:	cea080e7          	jalr	-790(ra) # 8000341c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000373a:	854e                	mv	a0,s3
    8000373c:	70a2                	ld	ra,40(sp)
    8000373e:	7402                	ld	s0,32(sp)
    80003740:	64e2                	ld	s1,24(sp)
    80003742:	6942                	ld	s2,16(sp)
    80003744:	69a2                	ld	s3,8(sp)
    80003746:	6a02                	ld	s4,0(sp)
    80003748:	6145                	addi	sp,sp,48
    8000374a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000374c:	02059793          	slli	a5,a1,0x20
    80003750:	01e7d593          	srli	a1,a5,0x1e
    80003754:	00b504b3          	add	s1,a0,a1
    80003758:	0504a983          	lw	s3,80(s1)
    8000375c:	fc099fe3          	bnez	s3,8000373a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003760:	4108                	lw	a0,0(a0)
    80003762:	00000097          	auipc	ra,0x0
    80003766:	e4c080e7          	jalr	-436(ra) # 800035ae <balloc>
    8000376a:	0005099b          	sext.w	s3,a0
    8000376e:	0534a823          	sw	s3,80(s1)
    80003772:	b7e1                	j	8000373a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003774:	4108                	lw	a0,0(a0)
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	e38080e7          	jalr	-456(ra) # 800035ae <balloc>
    8000377e:	0005059b          	sext.w	a1,a0
    80003782:	08b92023          	sw	a1,128(s2)
    80003786:	b751                	j	8000370a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003788:	00092503          	lw	a0,0(s2)
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	e22080e7          	jalr	-478(ra) # 800035ae <balloc>
    80003794:	0005099b          	sext.w	s3,a0
    80003798:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000379c:	8552                	mv	a0,s4
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	f02080e7          	jalr	-254(ra) # 800046a0 <log_write>
    800037a6:	b769                	j	80003730 <bmap+0x54>
  panic("bmap: out of range");
    800037a8:	00005517          	auipc	a0,0x5
    800037ac:	d6850513          	addi	a0,a0,-664 # 80008510 <syscalls+0x140>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	d8a080e7          	jalr	-630(ra) # 8000053a <panic>

00000000800037b8 <iget>:
{
    800037b8:	7179                	addi	sp,sp,-48
    800037ba:	f406                	sd	ra,40(sp)
    800037bc:	f022                	sd	s0,32(sp)
    800037be:	ec26                	sd	s1,24(sp)
    800037c0:	e84a                	sd	s2,16(sp)
    800037c2:	e44e                	sd	s3,8(sp)
    800037c4:	e052                	sd	s4,0(sp)
    800037c6:	1800                	addi	s0,sp,48
    800037c8:	89aa                	mv	s3,a0
    800037ca:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037cc:	0001c517          	auipc	a0,0x1c
    800037d0:	1fc50513          	addi	a0,a0,508 # 8001f9c8 <itable>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	44e080e7          	jalr	1102(ra) # 80000c22 <acquire>
  empty = 0;
    800037dc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037de:	0001c497          	auipc	s1,0x1c
    800037e2:	20248493          	addi	s1,s1,514 # 8001f9e0 <itable+0x18>
    800037e6:	0001e697          	auipc	a3,0x1e
    800037ea:	c8a68693          	addi	a3,a3,-886 # 80021470 <log>
    800037ee:	a039                	j	800037fc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f0:	02090b63          	beqz	s2,80003826 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037f4:	08848493          	addi	s1,s1,136
    800037f8:	02d48a63          	beq	s1,a3,8000382c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037fc:	449c                	lw	a5,8(s1)
    800037fe:	fef059e3          	blez	a5,800037f0 <iget+0x38>
    80003802:	4098                	lw	a4,0(s1)
    80003804:	ff3716e3          	bne	a4,s3,800037f0 <iget+0x38>
    80003808:	40d8                	lw	a4,4(s1)
    8000380a:	ff4713e3          	bne	a4,s4,800037f0 <iget+0x38>
      ip->ref++;
    8000380e:	2785                	addiw	a5,a5,1
    80003810:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003812:	0001c517          	auipc	a0,0x1c
    80003816:	1b650513          	addi	a0,a0,438 # 8001f9c8 <itable>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	4bc080e7          	jalr	1212(ra) # 80000cd6 <release>
      return ip;
    80003822:	8926                	mv	s2,s1
    80003824:	a03d                	j	80003852 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003826:	f7f9                	bnez	a5,800037f4 <iget+0x3c>
    80003828:	8926                	mv	s2,s1
    8000382a:	b7e9                	j	800037f4 <iget+0x3c>
  if(empty == 0)
    8000382c:	02090c63          	beqz	s2,80003864 <iget+0xac>
  ip->dev = dev;
    80003830:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003834:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003838:	4785                	li	a5,1
    8000383a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000383e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003842:	0001c517          	auipc	a0,0x1c
    80003846:	18650513          	addi	a0,a0,390 # 8001f9c8 <itable>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	48c080e7          	jalr	1164(ra) # 80000cd6 <release>
}
    80003852:	854a                	mv	a0,s2
    80003854:	70a2                	ld	ra,40(sp)
    80003856:	7402                	ld	s0,32(sp)
    80003858:	64e2                	ld	s1,24(sp)
    8000385a:	6942                	ld	s2,16(sp)
    8000385c:	69a2                	ld	s3,8(sp)
    8000385e:	6a02                	ld	s4,0(sp)
    80003860:	6145                	addi	sp,sp,48
    80003862:	8082                	ret
    panic("iget: no inodes");
    80003864:	00005517          	auipc	a0,0x5
    80003868:	cc450513          	addi	a0,a0,-828 # 80008528 <syscalls+0x158>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	cce080e7          	jalr	-818(ra) # 8000053a <panic>

0000000080003874 <fsinit>:
fsinit(int dev) {
    80003874:	7179                	addi	sp,sp,-48
    80003876:	f406                	sd	ra,40(sp)
    80003878:	f022                	sd	s0,32(sp)
    8000387a:	ec26                	sd	s1,24(sp)
    8000387c:	e84a                	sd	s2,16(sp)
    8000387e:	e44e                	sd	s3,8(sp)
    80003880:	1800                	addi	s0,sp,48
    80003882:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003884:	4585                	li	a1,1
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	a66080e7          	jalr	-1434(ra) # 800032ec <bread>
    8000388e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003890:	0001c997          	auipc	s3,0x1c
    80003894:	11898993          	addi	s3,s3,280 # 8001f9a8 <sb>
    80003898:	02000613          	li	a2,32
    8000389c:	05850593          	addi	a1,a0,88
    800038a0:	854e                	mv	a0,s3
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	4d8080e7          	jalr	1240(ra) # 80000d7a <memmove>
  brelse(bp);
    800038aa:	8526                	mv	a0,s1
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	b70080e7          	jalr	-1168(ra) # 8000341c <brelse>
  if(sb.magic != FSMAGIC)
    800038b4:	0009a703          	lw	a4,0(s3)
    800038b8:	102037b7          	lui	a5,0x10203
    800038bc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038c0:	02f71263          	bne	a4,a5,800038e4 <fsinit+0x70>
  initlog(dev, &sb);
    800038c4:	0001c597          	auipc	a1,0x1c
    800038c8:	0e458593          	addi	a1,a1,228 # 8001f9a8 <sb>
    800038cc:	854a                	mv	a0,s2
    800038ce:	00001097          	auipc	ra,0x1
    800038d2:	b56080e7          	jalr	-1194(ra) # 80004424 <initlog>
}
    800038d6:	70a2                	ld	ra,40(sp)
    800038d8:	7402                	ld	s0,32(sp)
    800038da:	64e2                	ld	s1,24(sp)
    800038dc:	6942                	ld	s2,16(sp)
    800038de:	69a2                	ld	s3,8(sp)
    800038e0:	6145                	addi	sp,sp,48
    800038e2:	8082                	ret
    panic("invalid file system");
    800038e4:	00005517          	auipc	a0,0x5
    800038e8:	c5450513          	addi	a0,a0,-940 # 80008538 <syscalls+0x168>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	c4e080e7          	jalr	-946(ra) # 8000053a <panic>

00000000800038f4 <iinit>:
{
    800038f4:	7179                	addi	sp,sp,-48
    800038f6:	f406                	sd	ra,40(sp)
    800038f8:	f022                	sd	s0,32(sp)
    800038fa:	ec26                	sd	s1,24(sp)
    800038fc:	e84a                	sd	s2,16(sp)
    800038fe:	e44e                	sd	s3,8(sp)
    80003900:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003902:	00005597          	auipc	a1,0x5
    80003906:	c4e58593          	addi	a1,a1,-946 # 80008550 <syscalls+0x180>
    8000390a:	0001c517          	auipc	a0,0x1c
    8000390e:	0be50513          	addi	a0,a0,190 # 8001f9c8 <itable>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	280080e7          	jalr	640(ra) # 80000b92 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000391a:	0001c497          	auipc	s1,0x1c
    8000391e:	0d648493          	addi	s1,s1,214 # 8001f9f0 <itable+0x28>
    80003922:	0001e997          	auipc	s3,0x1e
    80003926:	b5e98993          	addi	s3,s3,-1186 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000392a:	00005917          	auipc	s2,0x5
    8000392e:	c2e90913          	addi	s2,s2,-978 # 80008558 <syscalls+0x188>
    80003932:	85ca                	mv	a1,s2
    80003934:	8526                	mv	a0,s1
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	e4e080e7          	jalr	-434(ra) # 80004784 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000393e:	08848493          	addi	s1,s1,136
    80003942:	ff3498e3          	bne	s1,s3,80003932 <iinit+0x3e>
}
    80003946:	70a2                	ld	ra,40(sp)
    80003948:	7402                	ld	s0,32(sp)
    8000394a:	64e2                	ld	s1,24(sp)
    8000394c:	6942                	ld	s2,16(sp)
    8000394e:	69a2                	ld	s3,8(sp)
    80003950:	6145                	addi	sp,sp,48
    80003952:	8082                	ret

0000000080003954 <ialloc>:
{
    80003954:	715d                	addi	sp,sp,-80
    80003956:	e486                	sd	ra,72(sp)
    80003958:	e0a2                	sd	s0,64(sp)
    8000395a:	fc26                	sd	s1,56(sp)
    8000395c:	f84a                	sd	s2,48(sp)
    8000395e:	f44e                	sd	s3,40(sp)
    80003960:	f052                	sd	s4,32(sp)
    80003962:	ec56                	sd	s5,24(sp)
    80003964:	e85a                	sd	s6,16(sp)
    80003966:	e45e                	sd	s7,8(sp)
    80003968:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000396a:	0001c717          	auipc	a4,0x1c
    8000396e:	04a72703          	lw	a4,74(a4) # 8001f9b4 <sb+0xc>
    80003972:	4785                	li	a5,1
    80003974:	04e7fa63          	bgeu	a5,a4,800039c8 <ialloc+0x74>
    80003978:	8aaa                	mv	s5,a0
    8000397a:	8bae                	mv	s7,a1
    8000397c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000397e:	0001ca17          	auipc	s4,0x1c
    80003982:	02aa0a13          	addi	s4,s4,42 # 8001f9a8 <sb>
    80003986:	00048b1b          	sext.w	s6,s1
    8000398a:	0044d593          	srli	a1,s1,0x4
    8000398e:	018a2783          	lw	a5,24(s4)
    80003992:	9dbd                	addw	a1,a1,a5
    80003994:	8556                	mv	a0,s5
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	956080e7          	jalr	-1706(ra) # 800032ec <bread>
    8000399e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039a0:	05850993          	addi	s3,a0,88
    800039a4:	00f4f793          	andi	a5,s1,15
    800039a8:	079a                	slli	a5,a5,0x6
    800039aa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039ac:	00099783          	lh	a5,0(s3)
    800039b0:	c785                	beqz	a5,800039d8 <ialloc+0x84>
    brelse(bp);
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	a6a080e7          	jalr	-1430(ra) # 8000341c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039ba:	0485                	addi	s1,s1,1
    800039bc:	00ca2703          	lw	a4,12(s4)
    800039c0:	0004879b          	sext.w	a5,s1
    800039c4:	fce7e1e3          	bltu	a5,a4,80003986 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039c8:	00005517          	auipc	a0,0x5
    800039cc:	b9850513          	addi	a0,a0,-1128 # 80008560 <syscalls+0x190>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	b6a080e7          	jalr	-1174(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800039d8:	04000613          	li	a2,64
    800039dc:	4581                	li	a1,0
    800039de:	854e                	mv	a0,s3
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	33e080e7          	jalr	830(ra) # 80000d1e <memset>
      dip->type = type;
    800039e8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039ec:	854a                	mv	a0,s2
    800039ee:	00001097          	auipc	ra,0x1
    800039f2:	cb2080e7          	jalr	-846(ra) # 800046a0 <log_write>
      brelse(bp);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	a24080e7          	jalr	-1500(ra) # 8000341c <brelse>
      return iget(dev, inum);
    80003a00:	85da                	mv	a1,s6
    80003a02:	8556                	mv	a0,s5
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	db4080e7          	jalr	-588(ra) # 800037b8 <iget>
}
    80003a0c:	60a6                	ld	ra,72(sp)
    80003a0e:	6406                	ld	s0,64(sp)
    80003a10:	74e2                	ld	s1,56(sp)
    80003a12:	7942                	ld	s2,48(sp)
    80003a14:	79a2                	ld	s3,40(sp)
    80003a16:	7a02                	ld	s4,32(sp)
    80003a18:	6ae2                	ld	s5,24(sp)
    80003a1a:	6b42                	ld	s6,16(sp)
    80003a1c:	6ba2                	ld	s7,8(sp)
    80003a1e:	6161                	addi	sp,sp,80
    80003a20:	8082                	ret

0000000080003a22 <iupdate>:
{
    80003a22:	1101                	addi	sp,sp,-32
    80003a24:	ec06                	sd	ra,24(sp)
    80003a26:	e822                	sd	s0,16(sp)
    80003a28:	e426                	sd	s1,8(sp)
    80003a2a:	e04a                	sd	s2,0(sp)
    80003a2c:	1000                	addi	s0,sp,32
    80003a2e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a30:	415c                	lw	a5,4(a0)
    80003a32:	0047d79b          	srliw	a5,a5,0x4
    80003a36:	0001c597          	auipc	a1,0x1c
    80003a3a:	f8a5a583          	lw	a1,-118(a1) # 8001f9c0 <sb+0x18>
    80003a3e:	9dbd                	addw	a1,a1,a5
    80003a40:	4108                	lw	a0,0(a0)
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	8aa080e7          	jalr	-1878(ra) # 800032ec <bread>
    80003a4a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a4c:	05850793          	addi	a5,a0,88
    80003a50:	40d8                	lw	a4,4(s1)
    80003a52:	8b3d                	andi	a4,a4,15
    80003a54:	071a                	slli	a4,a4,0x6
    80003a56:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a58:	04449703          	lh	a4,68(s1)
    80003a5c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a60:	04649703          	lh	a4,70(s1)
    80003a64:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a68:	04849703          	lh	a4,72(s1)
    80003a6c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a70:	04a49703          	lh	a4,74(s1)
    80003a74:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a78:	44f8                	lw	a4,76(s1)
    80003a7a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a7c:	03400613          	li	a2,52
    80003a80:	05048593          	addi	a1,s1,80
    80003a84:	00c78513          	addi	a0,a5,12
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	2f2080e7          	jalr	754(ra) # 80000d7a <memmove>
  log_write(bp);
    80003a90:	854a                	mv	a0,s2
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	c0e080e7          	jalr	-1010(ra) # 800046a0 <log_write>
  brelse(bp);
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	00000097          	auipc	ra,0x0
    80003aa0:	980080e7          	jalr	-1664(ra) # 8000341c <brelse>
}
    80003aa4:	60e2                	ld	ra,24(sp)
    80003aa6:	6442                	ld	s0,16(sp)
    80003aa8:	64a2                	ld	s1,8(sp)
    80003aaa:	6902                	ld	s2,0(sp)
    80003aac:	6105                	addi	sp,sp,32
    80003aae:	8082                	ret

0000000080003ab0 <idup>:
{
    80003ab0:	1101                	addi	sp,sp,-32
    80003ab2:	ec06                	sd	ra,24(sp)
    80003ab4:	e822                	sd	s0,16(sp)
    80003ab6:	e426                	sd	s1,8(sp)
    80003ab8:	1000                	addi	s0,sp,32
    80003aba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003abc:	0001c517          	auipc	a0,0x1c
    80003ac0:	f0c50513          	addi	a0,a0,-244 # 8001f9c8 <itable>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	15e080e7          	jalr	350(ra) # 80000c22 <acquire>
  ip->ref++;
    80003acc:	449c                	lw	a5,8(s1)
    80003ace:	2785                	addiw	a5,a5,1
    80003ad0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad2:	0001c517          	auipc	a0,0x1c
    80003ad6:	ef650513          	addi	a0,a0,-266 # 8001f9c8 <itable>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	1fc080e7          	jalr	508(ra) # 80000cd6 <release>
}
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	60e2                	ld	ra,24(sp)
    80003ae6:	6442                	ld	s0,16(sp)
    80003ae8:	64a2                	ld	s1,8(sp)
    80003aea:	6105                	addi	sp,sp,32
    80003aec:	8082                	ret

0000000080003aee <ilock>:
{
    80003aee:	1101                	addi	sp,sp,-32
    80003af0:	ec06                	sd	ra,24(sp)
    80003af2:	e822                	sd	s0,16(sp)
    80003af4:	e426                	sd	s1,8(sp)
    80003af6:	e04a                	sd	s2,0(sp)
    80003af8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003afa:	c115                	beqz	a0,80003b1e <ilock+0x30>
    80003afc:	84aa                	mv	s1,a0
    80003afe:	451c                	lw	a5,8(a0)
    80003b00:	00f05f63          	blez	a5,80003b1e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b04:	0541                	addi	a0,a0,16
    80003b06:	00001097          	auipc	ra,0x1
    80003b0a:	cb8080e7          	jalr	-840(ra) # 800047be <acquiresleep>
  if(ip->valid == 0){
    80003b0e:	40bc                	lw	a5,64(s1)
    80003b10:	cf99                	beqz	a5,80003b2e <ilock+0x40>
}
    80003b12:	60e2                	ld	ra,24(sp)
    80003b14:	6442                	ld	s0,16(sp)
    80003b16:	64a2                	ld	s1,8(sp)
    80003b18:	6902                	ld	s2,0(sp)
    80003b1a:	6105                	addi	sp,sp,32
    80003b1c:	8082                	ret
    panic("ilock");
    80003b1e:	00005517          	auipc	a0,0x5
    80003b22:	a5a50513          	addi	a0,a0,-1446 # 80008578 <syscalls+0x1a8>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	a14080e7          	jalr	-1516(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b2e:	40dc                	lw	a5,4(s1)
    80003b30:	0047d79b          	srliw	a5,a5,0x4
    80003b34:	0001c597          	auipc	a1,0x1c
    80003b38:	e8c5a583          	lw	a1,-372(a1) # 8001f9c0 <sb+0x18>
    80003b3c:	9dbd                	addw	a1,a1,a5
    80003b3e:	4088                	lw	a0,0(s1)
    80003b40:	fffff097          	auipc	ra,0xfffff
    80003b44:	7ac080e7          	jalr	1964(ra) # 800032ec <bread>
    80003b48:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b4a:	05850593          	addi	a1,a0,88
    80003b4e:	40dc                	lw	a5,4(s1)
    80003b50:	8bbd                	andi	a5,a5,15
    80003b52:	079a                	slli	a5,a5,0x6
    80003b54:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b56:	00059783          	lh	a5,0(a1)
    80003b5a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b5e:	00259783          	lh	a5,2(a1)
    80003b62:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b66:	00459783          	lh	a5,4(a1)
    80003b6a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b6e:	00659783          	lh	a5,6(a1)
    80003b72:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b76:	459c                	lw	a5,8(a1)
    80003b78:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b7a:	03400613          	li	a2,52
    80003b7e:	05b1                	addi	a1,a1,12
    80003b80:	05048513          	addi	a0,s1,80
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	1f6080e7          	jalr	502(ra) # 80000d7a <memmove>
    brelse(bp);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	88e080e7          	jalr	-1906(ra) # 8000341c <brelse>
    ip->valid = 1;
    80003b96:	4785                	li	a5,1
    80003b98:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b9a:	04449783          	lh	a5,68(s1)
    80003b9e:	fbb5                	bnez	a5,80003b12 <ilock+0x24>
      panic("ilock: no type");
    80003ba0:	00005517          	auipc	a0,0x5
    80003ba4:	9e050513          	addi	a0,a0,-1568 # 80008580 <syscalls+0x1b0>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	992080e7          	jalr	-1646(ra) # 8000053a <panic>

0000000080003bb0 <iunlock>:
{
    80003bb0:	1101                	addi	sp,sp,-32
    80003bb2:	ec06                	sd	ra,24(sp)
    80003bb4:	e822                	sd	s0,16(sp)
    80003bb6:	e426                	sd	s1,8(sp)
    80003bb8:	e04a                	sd	s2,0(sp)
    80003bba:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bbc:	c905                	beqz	a0,80003bec <iunlock+0x3c>
    80003bbe:	84aa                	mv	s1,a0
    80003bc0:	01050913          	addi	s2,a0,16
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	00001097          	auipc	ra,0x1
    80003bca:	c92080e7          	jalr	-878(ra) # 80004858 <holdingsleep>
    80003bce:	cd19                	beqz	a0,80003bec <iunlock+0x3c>
    80003bd0:	449c                	lw	a5,8(s1)
    80003bd2:	00f05d63          	blez	a5,80003bec <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	c3c080e7          	jalr	-964(ra) # 80004814 <releasesleep>
}
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6902                	ld	s2,0(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret
    panic("iunlock");
    80003bec:	00005517          	auipc	a0,0x5
    80003bf0:	9a450513          	addi	a0,a0,-1628 # 80008590 <syscalls+0x1c0>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	946080e7          	jalr	-1722(ra) # 8000053a <panic>

0000000080003bfc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bfc:	7179                	addi	sp,sp,-48
    80003bfe:	f406                	sd	ra,40(sp)
    80003c00:	f022                	sd	s0,32(sp)
    80003c02:	ec26                	sd	s1,24(sp)
    80003c04:	e84a                	sd	s2,16(sp)
    80003c06:	e44e                	sd	s3,8(sp)
    80003c08:	e052                	sd	s4,0(sp)
    80003c0a:	1800                	addi	s0,sp,48
    80003c0c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c0e:	05050493          	addi	s1,a0,80
    80003c12:	08050913          	addi	s2,a0,128
    80003c16:	a021                	j	80003c1e <itrunc+0x22>
    80003c18:	0491                	addi	s1,s1,4
    80003c1a:	01248d63          	beq	s1,s2,80003c34 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c1e:	408c                	lw	a1,0(s1)
    80003c20:	dde5                	beqz	a1,80003c18 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c22:	0009a503          	lw	a0,0(s3)
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	90c080e7          	jalr	-1780(ra) # 80003532 <bfree>
      ip->addrs[i] = 0;
    80003c2e:	0004a023          	sw	zero,0(s1)
    80003c32:	b7dd                	j	80003c18 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c34:	0809a583          	lw	a1,128(s3)
    80003c38:	e185                	bnez	a1,80003c58 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c3a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c3e:	854e                	mv	a0,s3
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	de2080e7          	jalr	-542(ra) # 80003a22 <iupdate>
}
    80003c48:	70a2                	ld	ra,40(sp)
    80003c4a:	7402                	ld	s0,32(sp)
    80003c4c:	64e2                	ld	s1,24(sp)
    80003c4e:	6942                	ld	s2,16(sp)
    80003c50:	69a2                	ld	s3,8(sp)
    80003c52:	6a02                	ld	s4,0(sp)
    80003c54:	6145                	addi	sp,sp,48
    80003c56:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c58:	0009a503          	lw	a0,0(s3)
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	690080e7          	jalr	1680(ra) # 800032ec <bread>
    80003c64:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c66:	05850493          	addi	s1,a0,88
    80003c6a:	45850913          	addi	s2,a0,1112
    80003c6e:	a021                	j	80003c76 <itrunc+0x7a>
    80003c70:	0491                	addi	s1,s1,4
    80003c72:	01248b63          	beq	s1,s2,80003c88 <itrunc+0x8c>
      if(a[j])
    80003c76:	408c                	lw	a1,0(s1)
    80003c78:	dde5                	beqz	a1,80003c70 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c7a:	0009a503          	lw	a0,0(s3)
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	8b4080e7          	jalr	-1868(ra) # 80003532 <bfree>
    80003c86:	b7ed                	j	80003c70 <itrunc+0x74>
    brelse(bp);
    80003c88:	8552                	mv	a0,s4
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	792080e7          	jalr	1938(ra) # 8000341c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c92:	0809a583          	lw	a1,128(s3)
    80003c96:	0009a503          	lw	a0,0(s3)
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	898080e7          	jalr	-1896(ra) # 80003532 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ca2:	0809a023          	sw	zero,128(s3)
    80003ca6:	bf51                	j	80003c3a <itrunc+0x3e>

0000000080003ca8 <iput>:
{
    80003ca8:	1101                	addi	sp,sp,-32
    80003caa:	ec06                	sd	ra,24(sp)
    80003cac:	e822                	sd	s0,16(sp)
    80003cae:	e426                	sd	s1,8(sp)
    80003cb0:	e04a                	sd	s2,0(sp)
    80003cb2:	1000                	addi	s0,sp,32
    80003cb4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cb6:	0001c517          	auipc	a0,0x1c
    80003cba:	d1250513          	addi	a0,a0,-750 # 8001f9c8 <itable>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	f64080e7          	jalr	-156(ra) # 80000c22 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cc6:	4498                	lw	a4,8(s1)
    80003cc8:	4785                	li	a5,1
    80003cca:	02f70363          	beq	a4,a5,80003cf0 <iput+0x48>
  ip->ref--;
    80003cce:	449c                	lw	a5,8(s1)
    80003cd0:	37fd                	addiw	a5,a5,-1
    80003cd2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cd4:	0001c517          	auipc	a0,0x1c
    80003cd8:	cf450513          	addi	a0,a0,-780 # 8001f9c8 <itable>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	ffa080e7          	jalr	-6(ra) # 80000cd6 <release>
}
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6902                	ld	s2,0(sp)
    80003cec:	6105                	addi	sp,sp,32
    80003cee:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cf0:	40bc                	lw	a5,64(s1)
    80003cf2:	dff1                	beqz	a5,80003cce <iput+0x26>
    80003cf4:	04a49783          	lh	a5,74(s1)
    80003cf8:	fbf9                	bnez	a5,80003cce <iput+0x26>
    acquiresleep(&ip->lock);
    80003cfa:	01048913          	addi	s2,s1,16
    80003cfe:	854a                	mv	a0,s2
    80003d00:	00001097          	auipc	ra,0x1
    80003d04:	abe080e7          	jalr	-1346(ra) # 800047be <acquiresleep>
    release(&itable.lock);
    80003d08:	0001c517          	auipc	a0,0x1c
    80003d0c:	cc050513          	addi	a0,a0,-832 # 8001f9c8 <itable>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	fc6080e7          	jalr	-58(ra) # 80000cd6 <release>
    itrunc(ip);
    80003d18:	8526                	mv	a0,s1
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	ee2080e7          	jalr	-286(ra) # 80003bfc <itrunc>
    ip->type = 0;
    80003d22:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d26:	8526                	mv	a0,s1
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	cfa080e7          	jalr	-774(ra) # 80003a22 <iupdate>
    ip->valid = 0;
    80003d30:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d34:	854a                	mv	a0,s2
    80003d36:	00001097          	auipc	ra,0x1
    80003d3a:	ade080e7          	jalr	-1314(ra) # 80004814 <releasesleep>
    acquire(&itable.lock);
    80003d3e:	0001c517          	auipc	a0,0x1c
    80003d42:	c8a50513          	addi	a0,a0,-886 # 8001f9c8 <itable>
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	edc080e7          	jalr	-292(ra) # 80000c22 <acquire>
    80003d4e:	b741                	j	80003cce <iput+0x26>

0000000080003d50 <iunlockput>:
{
    80003d50:	1101                	addi	sp,sp,-32
    80003d52:	ec06                	sd	ra,24(sp)
    80003d54:	e822                	sd	s0,16(sp)
    80003d56:	e426                	sd	s1,8(sp)
    80003d58:	1000                	addi	s0,sp,32
    80003d5a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	e54080e7          	jalr	-428(ra) # 80003bb0 <iunlock>
  iput(ip);
    80003d64:	8526                	mv	a0,s1
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	f42080e7          	jalr	-190(ra) # 80003ca8 <iput>
}
    80003d6e:	60e2                	ld	ra,24(sp)
    80003d70:	6442                	ld	s0,16(sp)
    80003d72:	64a2                	ld	s1,8(sp)
    80003d74:	6105                	addi	sp,sp,32
    80003d76:	8082                	ret

0000000080003d78 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d78:	1141                	addi	sp,sp,-16
    80003d7a:	e422                	sd	s0,8(sp)
    80003d7c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d7e:	411c                	lw	a5,0(a0)
    80003d80:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d82:	415c                	lw	a5,4(a0)
    80003d84:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d86:	04451783          	lh	a5,68(a0)
    80003d8a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d8e:	04a51783          	lh	a5,74(a0)
    80003d92:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d96:	04c56783          	lwu	a5,76(a0)
    80003d9a:	e99c                	sd	a5,16(a1)
}
    80003d9c:	6422                	ld	s0,8(sp)
    80003d9e:	0141                	addi	sp,sp,16
    80003da0:	8082                	ret

0000000080003da2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003da2:	457c                	lw	a5,76(a0)
    80003da4:	0ed7e963          	bltu	a5,a3,80003e96 <readi+0xf4>
{
    80003da8:	7159                	addi	sp,sp,-112
    80003daa:	f486                	sd	ra,104(sp)
    80003dac:	f0a2                	sd	s0,96(sp)
    80003dae:	eca6                	sd	s1,88(sp)
    80003db0:	e8ca                	sd	s2,80(sp)
    80003db2:	e4ce                	sd	s3,72(sp)
    80003db4:	e0d2                	sd	s4,64(sp)
    80003db6:	fc56                	sd	s5,56(sp)
    80003db8:	f85a                	sd	s6,48(sp)
    80003dba:	f45e                	sd	s7,40(sp)
    80003dbc:	f062                	sd	s8,32(sp)
    80003dbe:	ec66                	sd	s9,24(sp)
    80003dc0:	e86a                	sd	s10,16(sp)
    80003dc2:	e46e                	sd	s11,8(sp)
    80003dc4:	1880                	addi	s0,sp,112
    80003dc6:	8baa                	mv	s7,a0
    80003dc8:	8c2e                	mv	s8,a1
    80003dca:	8ab2                	mv	s5,a2
    80003dcc:	84b6                	mv	s1,a3
    80003dce:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dd0:	9f35                	addw	a4,a4,a3
    return 0;
    80003dd2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dd4:	0ad76063          	bltu	a4,a3,80003e74 <readi+0xd2>
  if(off + n > ip->size)
    80003dd8:	00e7f463          	bgeu	a5,a4,80003de0 <readi+0x3e>
    n = ip->size - off;
    80003ddc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de0:	0a0b0963          	beqz	s6,80003e92 <readi+0xf0>
    80003de4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dea:	5cfd                	li	s9,-1
    80003dec:	a82d                	j	80003e26 <readi+0x84>
    80003dee:	020a1d93          	slli	s11,s4,0x20
    80003df2:	020ddd93          	srli	s11,s11,0x20
    80003df6:	05890613          	addi	a2,s2,88
    80003dfa:	86ee                	mv	a3,s11
    80003dfc:	963a                	add	a2,a2,a4
    80003dfe:	85d6                	mv	a1,s5
    80003e00:	8562                	mv	a0,s8
    80003e02:	ffffe097          	auipc	ra,0xffffe
    80003e06:	7c2080e7          	jalr	1986(ra) # 800025c4 <either_copyout>
    80003e0a:	05950d63          	beq	a0,s9,80003e64 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e0e:	854a                	mv	a0,s2
    80003e10:	fffff097          	auipc	ra,0xfffff
    80003e14:	60c080e7          	jalr	1548(ra) # 8000341c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e18:	013a09bb          	addw	s3,s4,s3
    80003e1c:	009a04bb          	addw	s1,s4,s1
    80003e20:	9aee                	add	s5,s5,s11
    80003e22:	0569f763          	bgeu	s3,s6,80003e70 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e26:	000ba903          	lw	s2,0(s7)
    80003e2a:	00a4d59b          	srliw	a1,s1,0xa
    80003e2e:	855e                	mv	a0,s7
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	8ac080e7          	jalr	-1876(ra) # 800036dc <bmap>
    80003e38:	0005059b          	sext.w	a1,a0
    80003e3c:	854a                	mv	a0,s2
    80003e3e:	fffff097          	auipc	ra,0xfffff
    80003e42:	4ae080e7          	jalr	1198(ra) # 800032ec <bread>
    80003e46:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e48:	3ff4f713          	andi	a4,s1,1023
    80003e4c:	40ed07bb          	subw	a5,s10,a4
    80003e50:	413b06bb          	subw	a3,s6,s3
    80003e54:	8a3e                	mv	s4,a5
    80003e56:	2781                	sext.w	a5,a5
    80003e58:	0006861b          	sext.w	a2,a3
    80003e5c:	f8f679e3          	bgeu	a2,a5,80003dee <readi+0x4c>
    80003e60:	8a36                	mv	s4,a3
    80003e62:	b771                	j	80003dee <readi+0x4c>
      brelse(bp);
    80003e64:	854a                	mv	a0,s2
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	5b6080e7          	jalr	1462(ra) # 8000341c <brelse>
      tot = -1;
    80003e6e:	59fd                	li	s3,-1
  }
  return tot;
    80003e70:	0009851b          	sext.w	a0,s3
}
    80003e74:	70a6                	ld	ra,104(sp)
    80003e76:	7406                	ld	s0,96(sp)
    80003e78:	64e6                	ld	s1,88(sp)
    80003e7a:	6946                	ld	s2,80(sp)
    80003e7c:	69a6                	ld	s3,72(sp)
    80003e7e:	6a06                	ld	s4,64(sp)
    80003e80:	7ae2                	ld	s5,56(sp)
    80003e82:	7b42                	ld	s6,48(sp)
    80003e84:	7ba2                	ld	s7,40(sp)
    80003e86:	7c02                	ld	s8,32(sp)
    80003e88:	6ce2                	ld	s9,24(sp)
    80003e8a:	6d42                	ld	s10,16(sp)
    80003e8c:	6da2                	ld	s11,8(sp)
    80003e8e:	6165                	addi	sp,sp,112
    80003e90:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e92:	89da                	mv	s3,s6
    80003e94:	bff1                	j	80003e70 <readi+0xce>
    return 0;
    80003e96:	4501                	li	a0,0
}
    80003e98:	8082                	ret

0000000080003e9a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e9a:	457c                	lw	a5,76(a0)
    80003e9c:	10d7e863          	bltu	a5,a3,80003fac <writei+0x112>
{
    80003ea0:	7159                	addi	sp,sp,-112
    80003ea2:	f486                	sd	ra,104(sp)
    80003ea4:	f0a2                	sd	s0,96(sp)
    80003ea6:	eca6                	sd	s1,88(sp)
    80003ea8:	e8ca                	sd	s2,80(sp)
    80003eaa:	e4ce                	sd	s3,72(sp)
    80003eac:	e0d2                	sd	s4,64(sp)
    80003eae:	fc56                	sd	s5,56(sp)
    80003eb0:	f85a                	sd	s6,48(sp)
    80003eb2:	f45e                	sd	s7,40(sp)
    80003eb4:	f062                	sd	s8,32(sp)
    80003eb6:	ec66                	sd	s9,24(sp)
    80003eb8:	e86a                	sd	s10,16(sp)
    80003eba:	e46e                	sd	s11,8(sp)
    80003ebc:	1880                	addi	s0,sp,112
    80003ebe:	8b2a                	mv	s6,a0
    80003ec0:	8c2e                	mv	s8,a1
    80003ec2:	8ab2                	mv	s5,a2
    80003ec4:	8936                	mv	s2,a3
    80003ec6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ec8:	00e687bb          	addw	a5,a3,a4
    80003ecc:	0ed7e263          	bltu	a5,a3,80003fb0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ed0:	00043737          	lui	a4,0x43
    80003ed4:	0ef76063          	bltu	a4,a5,80003fb4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ed8:	0c0b8863          	beqz	s7,80003fa8 <writei+0x10e>
    80003edc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ede:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ee2:	5cfd                	li	s9,-1
    80003ee4:	a091                	j	80003f28 <writei+0x8e>
    80003ee6:	02099d93          	slli	s11,s3,0x20
    80003eea:	020ddd93          	srli	s11,s11,0x20
    80003eee:	05848513          	addi	a0,s1,88
    80003ef2:	86ee                	mv	a3,s11
    80003ef4:	8656                	mv	a2,s5
    80003ef6:	85e2                	mv	a1,s8
    80003ef8:	953a                	add	a0,a0,a4
    80003efa:	ffffe097          	auipc	ra,0xffffe
    80003efe:	720080e7          	jalr	1824(ra) # 8000261a <either_copyin>
    80003f02:	07950263          	beq	a0,s9,80003f66 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f06:	8526                	mv	a0,s1
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	798080e7          	jalr	1944(ra) # 800046a0 <log_write>
    brelse(bp);
    80003f10:	8526                	mv	a0,s1
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	50a080e7          	jalr	1290(ra) # 8000341c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f1a:	01498a3b          	addw	s4,s3,s4
    80003f1e:	0129893b          	addw	s2,s3,s2
    80003f22:	9aee                	add	s5,s5,s11
    80003f24:	057a7663          	bgeu	s4,s7,80003f70 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f28:	000b2483          	lw	s1,0(s6)
    80003f2c:	00a9559b          	srliw	a1,s2,0xa
    80003f30:	855a                	mv	a0,s6
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	7aa080e7          	jalr	1962(ra) # 800036dc <bmap>
    80003f3a:	0005059b          	sext.w	a1,a0
    80003f3e:	8526                	mv	a0,s1
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	3ac080e7          	jalr	940(ra) # 800032ec <bread>
    80003f48:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f4a:	3ff97713          	andi	a4,s2,1023
    80003f4e:	40ed07bb          	subw	a5,s10,a4
    80003f52:	414b86bb          	subw	a3,s7,s4
    80003f56:	89be                	mv	s3,a5
    80003f58:	2781                	sext.w	a5,a5
    80003f5a:	0006861b          	sext.w	a2,a3
    80003f5e:	f8f674e3          	bgeu	a2,a5,80003ee6 <writei+0x4c>
    80003f62:	89b6                	mv	s3,a3
    80003f64:	b749                	j	80003ee6 <writei+0x4c>
      brelse(bp);
    80003f66:	8526                	mv	a0,s1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	4b4080e7          	jalr	1204(ra) # 8000341c <brelse>
  }

  if(off > ip->size)
    80003f70:	04cb2783          	lw	a5,76(s6)
    80003f74:	0127f463          	bgeu	a5,s2,80003f7c <writei+0xe2>
    ip->size = off;
    80003f78:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f7c:	855a                	mv	a0,s6
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	aa4080e7          	jalr	-1372(ra) # 80003a22 <iupdate>

  return tot;
    80003f86:	000a051b          	sext.w	a0,s4
}
    80003f8a:	70a6                	ld	ra,104(sp)
    80003f8c:	7406                	ld	s0,96(sp)
    80003f8e:	64e6                	ld	s1,88(sp)
    80003f90:	6946                	ld	s2,80(sp)
    80003f92:	69a6                	ld	s3,72(sp)
    80003f94:	6a06                	ld	s4,64(sp)
    80003f96:	7ae2                	ld	s5,56(sp)
    80003f98:	7b42                	ld	s6,48(sp)
    80003f9a:	7ba2                	ld	s7,40(sp)
    80003f9c:	7c02                	ld	s8,32(sp)
    80003f9e:	6ce2                	ld	s9,24(sp)
    80003fa0:	6d42                	ld	s10,16(sp)
    80003fa2:	6da2                	ld	s11,8(sp)
    80003fa4:	6165                	addi	sp,sp,112
    80003fa6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa8:	8a5e                	mv	s4,s7
    80003faa:	bfc9                	j	80003f7c <writei+0xe2>
    return -1;
    80003fac:	557d                	li	a0,-1
}
    80003fae:	8082                	ret
    return -1;
    80003fb0:	557d                	li	a0,-1
    80003fb2:	bfe1                	j	80003f8a <writei+0xf0>
    return -1;
    80003fb4:	557d                	li	a0,-1
    80003fb6:	bfd1                	j	80003f8a <writei+0xf0>

0000000080003fb8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fb8:	1141                	addi	sp,sp,-16
    80003fba:	e406                	sd	ra,8(sp)
    80003fbc:	e022                	sd	s0,0(sp)
    80003fbe:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fc0:	4639                	li	a2,14
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	e2c080e7          	jalr	-468(ra) # 80000dee <strncmp>
}
    80003fca:	60a2                	ld	ra,8(sp)
    80003fcc:	6402                	ld	s0,0(sp)
    80003fce:	0141                	addi	sp,sp,16
    80003fd0:	8082                	ret

0000000080003fd2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fd2:	7139                	addi	sp,sp,-64
    80003fd4:	fc06                	sd	ra,56(sp)
    80003fd6:	f822                	sd	s0,48(sp)
    80003fd8:	f426                	sd	s1,40(sp)
    80003fda:	f04a                	sd	s2,32(sp)
    80003fdc:	ec4e                	sd	s3,24(sp)
    80003fde:	e852                	sd	s4,16(sp)
    80003fe0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fe2:	04451703          	lh	a4,68(a0)
    80003fe6:	4785                	li	a5,1
    80003fe8:	00f71a63          	bne	a4,a5,80003ffc <dirlookup+0x2a>
    80003fec:	892a                	mv	s2,a0
    80003fee:	89ae                	mv	s3,a1
    80003ff0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff2:	457c                	lw	a5,76(a0)
    80003ff4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ff6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff8:	e79d                	bnez	a5,80004026 <dirlookup+0x54>
    80003ffa:	a8a5                	j	80004072 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ffc:	00004517          	auipc	a0,0x4
    80004000:	59c50513          	addi	a0,a0,1436 # 80008598 <syscalls+0x1c8>
    80004004:	ffffc097          	auipc	ra,0xffffc
    80004008:	536080e7          	jalr	1334(ra) # 8000053a <panic>
      panic("dirlookup read");
    8000400c:	00004517          	auipc	a0,0x4
    80004010:	5a450513          	addi	a0,a0,1444 # 800085b0 <syscalls+0x1e0>
    80004014:	ffffc097          	auipc	ra,0xffffc
    80004018:	526080e7          	jalr	1318(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401c:	24c1                	addiw	s1,s1,16
    8000401e:	04c92783          	lw	a5,76(s2)
    80004022:	04f4f763          	bgeu	s1,a5,80004070 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004026:	4741                	li	a4,16
    80004028:	86a6                	mv	a3,s1
    8000402a:	fc040613          	addi	a2,s0,-64
    8000402e:	4581                	li	a1,0
    80004030:	854a                	mv	a0,s2
    80004032:	00000097          	auipc	ra,0x0
    80004036:	d70080e7          	jalr	-656(ra) # 80003da2 <readi>
    8000403a:	47c1                	li	a5,16
    8000403c:	fcf518e3          	bne	a0,a5,8000400c <dirlookup+0x3a>
    if(de.inum == 0)
    80004040:	fc045783          	lhu	a5,-64(s0)
    80004044:	dfe1                	beqz	a5,8000401c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004046:	fc240593          	addi	a1,s0,-62
    8000404a:	854e                	mv	a0,s3
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	f6c080e7          	jalr	-148(ra) # 80003fb8 <namecmp>
    80004054:	f561                	bnez	a0,8000401c <dirlookup+0x4a>
      if(poff)
    80004056:	000a0463          	beqz	s4,8000405e <dirlookup+0x8c>
        *poff = off;
    8000405a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000405e:	fc045583          	lhu	a1,-64(s0)
    80004062:	00092503          	lw	a0,0(s2)
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	752080e7          	jalr	1874(ra) # 800037b8 <iget>
    8000406e:	a011                	j	80004072 <dirlookup+0xa0>
  return 0;
    80004070:	4501                	li	a0,0
}
    80004072:	70e2                	ld	ra,56(sp)
    80004074:	7442                	ld	s0,48(sp)
    80004076:	74a2                	ld	s1,40(sp)
    80004078:	7902                	ld	s2,32(sp)
    8000407a:	69e2                	ld	s3,24(sp)
    8000407c:	6a42                	ld	s4,16(sp)
    8000407e:	6121                	addi	sp,sp,64
    80004080:	8082                	ret

0000000080004082 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004082:	711d                	addi	sp,sp,-96
    80004084:	ec86                	sd	ra,88(sp)
    80004086:	e8a2                	sd	s0,80(sp)
    80004088:	e4a6                	sd	s1,72(sp)
    8000408a:	e0ca                	sd	s2,64(sp)
    8000408c:	fc4e                	sd	s3,56(sp)
    8000408e:	f852                	sd	s4,48(sp)
    80004090:	f456                	sd	s5,40(sp)
    80004092:	f05a                	sd	s6,32(sp)
    80004094:	ec5e                	sd	s7,24(sp)
    80004096:	e862                	sd	s8,16(sp)
    80004098:	e466                	sd	s9,8(sp)
    8000409a:	e06a                	sd	s10,0(sp)
    8000409c:	1080                	addi	s0,sp,96
    8000409e:	84aa                	mv	s1,a0
    800040a0:	8b2e                	mv	s6,a1
    800040a2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040a4:	00054703          	lbu	a4,0(a0)
    800040a8:	02f00793          	li	a5,47
    800040ac:	02f70363          	beq	a4,a5,800040d2 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040b0:	ffffe097          	auipc	ra,0xffffe
    800040b4:	8ee080e7          	jalr	-1810(ra) # 8000199e <myproc>
    800040b8:	15853503          	ld	a0,344(a0)
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	9f4080e7          	jalr	-1548(ra) # 80003ab0 <idup>
    800040c4:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040c6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040ca:	4cb5                	li	s9,13
  len = path - s;
    800040cc:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040ce:	4c05                	li	s8,1
    800040d0:	a87d                	j	8000418e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040d2:	4585                	li	a1,1
    800040d4:	4505                	li	a0,1
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	6e2080e7          	jalr	1762(ra) # 800037b8 <iget>
    800040de:	8a2a                	mv	s4,a0
    800040e0:	b7dd                	j	800040c6 <namex+0x44>
      iunlockput(ip);
    800040e2:	8552                	mv	a0,s4
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	c6c080e7          	jalr	-916(ra) # 80003d50 <iunlockput>
      return 0;
    800040ec:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040ee:	8552                	mv	a0,s4
    800040f0:	60e6                	ld	ra,88(sp)
    800040f2:	6446                	ld	s0,80(sp)
    800040f4:	64a6                	ld	s1,72(sp)
    800040f6:	6906                	ld	s2,64(sp)
    800040f8:	79e2                	ld	s3,56(sp)
    800040fa:	7a42                	ld	s4,48(sp)
    800040fc:	7aa2                	ld	s5,40(sp)
    800040fe:	7b02                	ld	s6,32(sp)
    80004100:	6be2                	ld	s7,24(sp)
    80004102:	6c42                	ld	s8,16(sp)
    80004104:	6ca2                	ld	s9,8(sp)
    80004106:	6d02                	ld	s10,0(sp)
    80004108:	6125                	addi	sp,sp,96
    8000410a:	8082                	ret
      iunlock(ip);
    8000410c:	8552                	mv	a0,s4
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	aa2080e7          	jalr	-1374(ra) # 80003bb0 <iunlock>
      return ip;
    80004116:	bfe1                	j	800040ee <namex+0x6c>
      iunlockput(ip);
    80004118:	8552                	mv	a0,s4
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	c36080e7          	jalr	-970(ra) # 80003d50 <iunlockput>
      return 0;
    80004122:	8a4e                	mv	s4,s3
    80004124:	b7e9                	j	800040ee <namex+0x6c>
  len = path - s;
    80004126:	40998633          	sub	a2,s3,s1
    8000412a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000412e:	09acd863          	bge	s9,s10,800041be <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004132:	4639                	li	a2,14
    80004134:	85a6                	mv	a1,s1
    80004136:	8556                	mv	a0,s5
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	c42080e7          	jalr	-958(ra) # 80000d7a <memmove>
    80004140:	84ce                	mv	s1,s3
  while(*path == '/')
    80004142:	0004c783          	lbu	a5,0(s1)
    80004146:	01279763          	bne	a5,s2,80004154 <namex+0xd2>
    path++;
    8000414a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000414c:	0004c783          	lbu	a5,0(s1)
    80004150:	ff278de3          	beq	a5,s2,8000414a <namex+0xc8>
    ilock(ip);
    80004154:	8552                	mv	a0,s4
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	998080e7          	jalr	-1640(ra) # 80003aee <ilock>
    if(ip->type != T_DIR){
    8000415e:	044a1783          	lh	a5,68(s4)
    80004162:	f98790e3          	bne	a5,s8,800040e2 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004166:	000b0563          	beqz	s6,80004170 <namex+0xee>
    8000416a:	0004c783          	lbu	a5,0(s1)
    8000416e:	dfd9                	beqz	a5,8000410c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004170:	865e                	mv	a2,s7
    80004172:	85d6                	mv	a1,s5
    80004174:	8552                	mv	a0,s4
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	e5c080e7          	jalr	-420(ra) # 80003fd2 <dirlookup>
    8000417e:	89aa                	mv	s3,a0
    80004180:	dd41                	beqz	a0,80004118 <namex+0x96>
    iunlockput(ip);
    80004182:	8552                	mv	a0,s4
    80004184:	00000097          	auipc	ra,0x0
    80004188:	bcc080e7          	jalr	-1076(ra) # 80003d50 <iunlockput>
    ip = next;
    8000418c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000418e:	0004c783          	lbu	a5,0(s1)
    80004192:	01279763          	bne	a5,s2,800041a0 <namex+0x11e>
    path++;
    80004196:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004198:	0004c783          	lbu	a5,0(s1)
    8000419c:	ff278de3          	beq	a5,s2,80004196 <namex+0x114>
  if(*path == 0)
    800041a0:	cb9d                	beqz	a5,800041d6 <namex+0x154>
  while(*path != '/' && *path != 0)
    800041a2:	0004c783          	lbu	a5,0(s1)
    800041a6:	89a6                	mv	s3,s1
  len = path - s;
    800041a8:	8d5e                	mv	s10,s7
    800041aa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041ac:	01278963          	beq	a5,s2,800041be <namex+0x13c>
    800041b0:	dbbd                	beqz	a5,80004126 <namex+0xa4>
    path++;
    800041b2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041b4:	0009c783          	lbu	a5,0(s3)
    800041b8:	ff279ce3          	bne	a5,s2,800041b0 <namex+0x12e>
    800041bc:	b7ad                	j	80004126 <namex+0xa4>
    memmove(name, s, len);
    800041be:	2601                	sext.w	a2,a2
    800041c0:	85a6                	mv	a1,s1
    800041c2:	8556                	mv	a0,s5
    800041c4:	ffffd097          	auipc	ra,0xffffd
    800041c8:	bb6080e7          	jalr	-1098(ra) # 80000d7a <memmove>
    name[len] = 0;
    800041cc:	9d56                	add	s10,s10,s5
    800041ce:	000d0023          	sb	zero,0(s10)
    800041d2:	84ce                	mv	s1,s3
    800041d4:	b7bd                	j	80004142 <namex+0xc0>
  if(nameiparent){
    800041d6:	f00b0ce3          	beqz	s6,800040ee <namex+0x6c>
    iput(ip);
    800041da:	8552                	mv	a0,s4
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	acc080e7          	jalr	-1332(ra) # 80003ca8 <iput>
    return 0;
    800041e4:	4a01                	li	s4,0
    800041e6:	b721                	j	800040ee <namex+0x6c>

00000000800041e8 <dirlink>:
{
    800041e8:	7139                	addi	sp,sp,-64
    800041ea:	fc06                	sd	ra,56(sp)
    800041ec:	f822                	sd	s0,48(sp)
    800041ee:	f426                	sd	s1,40(sp)
    800041f0:	f04a                	sd	s2,32(sp)
    800041f2:	ec4e                	sd	s3,24(sp)
    800041f4:	e852                	sd	s4,16(sp)
    800041f6:	0080                	addi	s0,sp,64
    800041f8:	892a                	mv	s2,a0
    800041fa:	8a2e                	mv	s4,a1
    800041fc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041fe:	4601                	li	a2,0
    80004200:	00000097          	auipc	ra,0x0
    80004204:	dd2080e7          	jalr	-558(ra) # 80003fd2 <dirlookup>
    80004208:	e93d                	bnez	a0,8000427e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000420a:	04c92483          	lw	s1,76(s2)
    8000420e:	c49d                	beqz	s1,8000423c <dirlink+0x54>
    80004210:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004212:	4741                	li	a4,16
    80004214:	86a6                	mv	a3,s1
    80004216:	fc040613          	addi	a2,s0,-64
    8000421a:	4581                	li	a1,0
    8000421c:	854a                	mv	a0,s2
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	b84080e7          	jalr	-1148(ra) # 80003da2 <readi>
    80004226:	47c1                	li	a5,16
    80004228:	06f51163          	bne	a0,a5,8000428a <dirlink+0xa2>
    if(de.inum == 0)
    8000422c:	fc045783          	lhu	a5,-64(s0)
    80004230:	c791                	beqz	a5,8000423c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004232:	24c1                	addiw	s1,s1,16
    80004234:	04c92783          	lw	a5,76(s2)
    80004238:	fcf4ede3          	bltu	s1,a5,80004212 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000423c:	4639                	li	a2,14
    8000423e:	85d2                	mv	a1,s4
    80004240:	fc240513          	addi	a0,s0,-62
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	be6080e7          	jalr	-1050(ra) # 80000e2a <strncpy>
  de.inum = inum;
    8000424c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004250:	4741                	li	a4,16
    80004252:	86a6                	mv	a3,s1
    80004254:	fc040613          	addi	a2,s0,-64
    80004258:	4581                	li	a1,0
    8000425a:	854a                	mv	a0,s2
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	c3e080e7          	jalr	-962(ra) # 80003e9a <writei>
    80004264:	872a                	mv	a4,a0
    80004266:	47c1                	li	a5,16
  return 0;
    80004268:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000426a:	02f71863          	bne	a4,a5,8000429a <dirlink+0xb2>
}
    8000426e:	70e2                	ld	ra,56(sp)
    80004270:	7442                	ld	s0,48(sp)
    80004272:	74a2                	ld	s1,40(sp)
    80004274:	7902                	ld	s2,32(sp)
    80004276:	69e2                	ld	s3,24(sp)
    80004278:	6a42                	ld	s4,16(sp)
    8000427a:	6121                	addi	sp,sp,64
    8000427c:	8082                	ret
    iput(ip);
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	a2a080e7          	jalr	-1494(ra) # 80003ca8 <iput>
    return -1;
    80004286:	557d                	li	a0,-1
    80004288:	b7dd                	j	8000426e <dirlink+0x86>
      panic("dirlink read");
    8000428a:	00004517          	auipc	a0,0x4
    8000428e:	33650513          	addi	a0,a0,822 # 800085c0 <syscalls+0x1f0>
    80004292:	ffffc097          	auipc	ra,0xffffc
    80004296:	2a8080e7          	jalr	680(ra) # 8000053a <panic>
    panic("dirlink");
    8000429a:	00004517          	auipc	a0,0x4
    8000429e:	43650513          	addi	a0,a0,1078 # 800086d0 <syscalls+0x300>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	298080e7          	jalr	664(ra) # 8000053a <panic>

00000000800042aa <namei>:

struct inode*
namei(char *path)
{
    800042aa:	1101                	addi	sp,sp,-32
    800042ac:	ec06                	sd	ra,24(sp)
    800042ae:	e822                	sd	s0,16(sp)
    800042b0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042b2:	fe040613          	addi	a2,s0,-32
    800042b6:	4581                	li	a1,0
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	dca080e7          	jalr	-566(ra) # 80004082 <namex>
}
    800042c0:	60e2                	ld	ra,24(sp)
    800042c2:	6442                	ld	s0,16(sp)
    800042c4:	6105                	addi	sp,sp,32
    800042c6:	8082                	ret

00000000800042c8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042c8:	1141                	addi	sp,sp,-16
    800042ca:	e406                	sd	ra,8(sp)
    800042cc:	e022                	sd	s0,0(sp)
    800042ce:	0800                	addi	s0,sp,16
    800042d0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042d2:	4585                	li	a1,1
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	dae080e7          	jalr	-594(ra) # 80004082 <namex>
}
    800042dc:	60a2                	ld	ra,8(sp)
    800042de:	6402                	ld	s0,0(sp)
    800042e0:	0141                	addi	sp,sp,16
    800042e2:	8082                	ret

00000000800042e4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042f0:	0001d917          	auipc	s2,0x1d
    800042f4:	18090913          	addi	s2,s2,384 # 80021470 <log>
    800042f8:	01892583          	lw	a1,24(s2)
    800042fc:	02892503          	lw	a0,40(s2)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	fec080e7          	jalr	-20(ra) # 800032ec <bread>
    80004308:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000430a:	02c92683          	lw	a3,44(s2)
    8000430e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004310:	02d05863          	blez	a3,80004340 <write_head+0x5c>
    80004314:	0001d797          	auipc	a5,0x1d
    80004318:	18c78793          	addi	a5,a5,396 # 800214a0 <log+0x30>
    8000431c:	05c50713          	addi	a4,a0,92
    80004320:	36fd                	addiw	a3,a3,-1
    80004322:	02069613          	slli	a2,a3,0x20
    80004326:	01e65693          	srli	a3,a2,0x1e
    8000432a:	0001d617          	auipc	a2,0x1d
    8000432e:	17a60613          	addi	a2,a2,378 # 800214a4 <log+0x34>
    80004332:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004334:	4390                	lw	a2,0(a5)
    80004336:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004338:	0791                	addi	a5,a5,4
    8000433a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000433c:	fed79ce3          	bne	a5,a3,80004334 <write_head+0x50>
  }
  bwrite(buf);
    80004340:	8526                	mv	a0,s1
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	09c080e7          	jalr	156(ra) # 800033de <bwrite>
  brelse(buf);
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	0d0080e7          	jalr	208(ra) # 8000341c <brelse>
}
    80004354:	60e2                	ld	ra,24(sp)
    80004356:	6442                	ld	s0,16(sp)
    80004358:	64a2                	ld	s1,8(sp)
    8000435a:	6902                	ld	s2,0(sp)
    8000435c:	6105                	addi	sp,sp,32
    8000435e:	8082                	ret

0000000080004360 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004360:	0001d797          	auipc	a5,0x1d
    80004364:	13c7a783          	lw	a5,316(a5) # 8002149c <log+0x2c>
    80004368:	0af05d63          	blez	a5,80004422 <install_trans+0xc2>
{
    8000436c:	7139                	addi	sp,sp,-64
    8000436e:	fc06                	sd	ra,56(sp)
    80004370:	f822                	sd	s0,48(sp)
    80004372:	f426                	sd	s1,40(sp)
    80004374:	f04a                	sd	s2,32(sp)
    80004376:	ec4e                	sd	s3,24(sp)
    80004378:	e852                	sd	s4,16(sp)
    8000437a:	e456                	sd	s5,8(sp)
    8000437c:	e05a                	sd	s6,0(sp)
    8000437e:	0080                	addi	s0,sp,64
    80004380:	8b2a                	mv	s6,a0
    80004382:	0001da97          	auipc	s5,0x1d
    80004386:	11ea8a93          	addi	s5,s5,286 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438c:	0001d997          	auipc	s3,0x1d
    80004390:	0e498993          	addi	s3,s3,228 # 80021470 <log>
    80004394:	a00d                	j	800043b6 <install_trans+0x56>
    brelse(lbuf);
    80004396:	854a                	mv	a0,s2
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	084080e7          	jalr	132(ra) # 8000341c <brelse>
    brelse(dbuf);
    800043a0:	8526                	mv	a0,s1
    800043a2:	fffff097          	auipc	ra,0xfffff
    800043a6:	07a080e7          	jalr	122(ra) # 8000341c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043aa:	2a05                	addiw	s4,s4,1
    800043ac:	0a91                	addi	s5,s5,4
    800043ae:	02c9a783          	lw	a5,44(s3)
    800043b2:	04fa5e63          	bge	s4,a5,8000440e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043b6:	0189a583          	lw	a1,24(s3)
    800043ba:	014585bb          	addw	a1,a1,s4
    800043be:	2585                	addiw	a1,a1,1
    800043c0:	0289a503          	lw	a0,40(s3)
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	f28080e7          	jalr	-216(ra) # 800032ec <bread>
    800043cc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043ce:	000aa583          	lw	a1,0(s5)
    800043d2:	0289a503          	lw	a0,40(s3)
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	f16080e7          	jalr	-234(ra) # 800032ec <bread>
    800043de:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043e0:	40000613          	li	a2,1024
    800043e4:	05890593          	addi	a1,s2,88
    800043e8:	05850513          	addi	a0,a0,88
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	98e080e7          	jalr	-1650(ra) # 80000d7a <memmove>
    bwrite(dbuf);  // write dst to disk
    800043f4:	8526                	mv	a0,s1
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	fe8080e7          	jalr	-24(ra) # 800033de <bwrite>
    if(recovering == 0)
    800043fe:	f80b1ce3          	bnez	s6,80004396 <install_trans+0x36>
      bunpin(dbuf);
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	0f2080e7          	jalr	242(ra) # 800034f6 <bunpin>
    8000440c:	b769                	j	80004396 <install_trans+0x36>
}
    8000440e:	70e2                	ld	ra,56(sp)
    80004410:	7442                	ld	s0,48(sp)
    80004412:	74a2                	ld	s1,40(sp)
    80004414:	7902                	ld	s2,32(sp)
    80004416:	69e2                	ld	s3,24(sp)
    80004418:	6a42                	ld	s4,16(sp)
    8000441a:	6aa2                	ld	s5,8(sp)
    8000441c:	6b02                	ld	s6,0(sp)
    8000441e:	6121                	addi	sp,sp,64
    80004420:	8082                	ret
    80004422:	8082                	ret

0000000080004424 <initlog>:
{
    80004424:	7179                	addi	sp,sp,-48
    80004426:	f406                	sd	ra,40(sp)
    80004428:	f022                	sd	s0,32(sp)
    8000442a:	ec26                	sd	s1,24(sp)
    8000442c:	e84a                	sd	s2,16(sp)
    8000442e:	e44e                	sd	s3,8(sp)
    80004430:	1800                	addi	s0,sp,48
    80004432:	892a                	mv	s2,a0
    80004434:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004436:	0001d497          	auipc	s1,0x1d
    8000443a:	03a48493          	addi	s1,s1,58 # 80021470 <log>
    8000443e:	00004597          	auipc	a1,0x4
    80004442:	19258593          	addi	a1,a1,402 # 800085d0 <syscalls+0x200>
    80004446:	8526                	mv	a0,s1
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	74a080e7          	jalr	1866(ra) # 80000b92 <initlock>
  log.start = sb->logstart;
    80004450:	0149a583          	lw	a1,20(s3)
    80004454:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004456:	0109a783          	lw	a5,16(s3)
    8000445a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000445c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004460:	854a                	mv	a0,s2
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	e8a080e7          	jalr	-374(ra) # 800032ec <bread>
  log.lh.n = lh->n;
    8000446a:	4d34                	lw	a3,88(a0)
    8000446c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000446e:	02d05663          	blez	a3,8000449a <initlog+0x76>
    80004472:	05c50793          	addi	a5,a0,92
    80004476:	0001d717          	auipc	a4,0x1d
    8000447a:	02a70713          	addi	a4,a4,42 # 800214a0 <log+0x30>
    8000447e:	36fd                	addiw	a3,a3,-1
    80004480:	02069613          	slli	a2,a3,0x20
    80004484:	01e65693          	srli	a3,a2,0x1e
    80004488:	06050613          	addi	a2,a0,96
    8000448c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000448e:	4390                	lw	a2,0(a5)
    80004490:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004492:	0791                	addi	a5,a5,4
    80004494:	0711                	addi	a4,a4,4
    80004496:	fed79ce3          	bne	a5,a3,8000448e <initlog+0x6a>
  brelse(buf);
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	f82080e7          	jalr	-126(ra) # 8000341c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044a2:	4505                	li	a0,1
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	ebc080e7          	jalr	-324(ra) # 80004360 <install_trans>
  log.lh.n = 0;
    800044ac:	0001d797          	auipc	a5,0x1d
    800044b0:	fe07a823          	sw	zero,-16(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    800044b4:	00000097          	auipc	ra,0x0
    800044b8:	e30080e7          	jalr	-464(ra) # 800042e4 <write_head>
}
    800044bc:	70a2                	ld	ra,40(sp)
    800044be:	7402                	ld	s0,32(sp)
    800044c0:	64e2                	ld	s1,24(sp)
    800044c2:	6942                	ld	s2,16(sp)
    800044c4:	69a2                	ld	s3,8(sp)
    800044c6:	6145                	addi	sp,sp,48
    800044c8:	8082                	ret

00000000800044ca <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044ca:	1101                	addi	sp,sp,-32
    800044cc:	ec06                	sd	ra,24(sp)
    800044ce:	e822                	sd	s0,16(sp)
    800044d0:	e426                	sd	s1,8(sp)
    800044d2:	e04a                	sd	s2,0(sp)
    800044d4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044d6:	0001d517          	auipc	a0,0x1d
    800044da:	f9a50513          	addi	a0,a0,-102 # 80021470 <log>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	744080e7          	jalr	1860(ra) # 80000c22 <acquire>
  while(1){
    if(log.committing){
    800044e6:	0001d497          	auipc	s1,0x1d
    800044ea:	f8a48493          	addi	s1,s1,-118 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044ee:	4979                	li	s2,30
    800044f0:	a039                	j	800044fe <begin_op+0x34>
      sleep(&log, &log.lock);
    800044f2:	85a6                	mv	a1,s1
    800044f4:	8526                	mv	a0,s1
    800044f6:	ffffe097          	auipc	ra,0xffffe
    800044fa:	ba8080e7          	jalr	-1112(ra) # 8000209e <sleep>
    if(log.committing){
    800044fe:	50dc                	lw	a5,36(s1)
    80004500:	fbed                	bnez	a5,800044f2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004502:	5098                	lw	a4,32(s1)
    80004504:	2705                	addiw	a4,a4,1
    80004506:	0007069b          	sext.w	a3,a4
    8000450a:	0027179b          	slliw	a5,a4,0x2
    8000450e:	9fb9                	addw	a5,a5,a4
    80004510:	0017979b          	slliw	a5,a5,0x1
    80004514:	54d8                	lw	a4,44(s1)
    80004516:	9fb9                	addw	a5,a5,a4
    80004518:	00f95963          	bge	s2,a5,8000452a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000451c:	85a6                	mv	a1,s1
    8000451e:	8526                	mv	a0,s1
    80004520:	ffffe097          	auipc	ra,0xffffe
    80004524:	b7e080e7          	jalr	-1154(ra) # 8000209e <sleep>
    80004528:	bfd9                	j	800044fe <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000452a:	0001d517          	auipc	a0,0x1d
    8000452e:	f4650513          	addi	a0,a0,-186 # 80021470 <log>
    80004532:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	7a2080e7          	jalr	1954(ra) # 80000cd6 <release>
      break;
    }
  }
}
    8000453c:	60e2                	ld	ra,24(sp)
    8000453e:	6442                	ld	s0,16(sp)
    80004540:	64a2                	ld	s1,8(sp)
    80004542:	6902                	ld	s2,0(sp)
    80004544:	6105                	addi	sp,sp,32
    80004546:	8082                	ret

0000000080004548 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004548:	7139                	addi	sp,sp,-64
    8000454a:	fc06                	sd	ra,56(sp)
    8000454c:	f822                	sd	s0,48(sp)
    8000454e:	f426                	sd	s1,40(sp)
    80004550:	f04a                	sd	s2,32(sp)
    80004552:	ec4e                	sd	s3,24(sp)
    80004554:	e852                	sd	s4,16(sp)
    80004556:	e456                	sd	s5,8(sp)
    80004558:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000455a:	0001d497          	auipc	s1,0x1d
    8000455e:	f1648493          	addi	s1,s1,-234 # 80021470 <log>
    80004562:	8526                	mv	a0,s1
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	6be080e7          	jalr	1726(ra) # 80000c22 <acquire>
  log.outstanding -= 1;
    8000456c:	509c                	lw	a5,32(s1)
    8000456e:	37fd                	addiw	a5,a5,-1
    80004570:	0007891b          	sext.w	s2,a5
    80004574:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004576:	50dc                	lw	a5,36(s1)
    80004578:	e7b9                	bnez	a5,800045c6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000457a:	04091e63          	bnez	s2,800045d6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000457e:	0001d497          	auipc	s1,0x1d
    80004582:	ef248493          	addi	s1,s1,-270 # 80021470 <log>
    80004586:	4785                	li	a5,1
    80004588:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000458a:	8526                	mv	a0,s1
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	74a080e7          	jalr	1866(ra) # 80000cd6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004594:	54dc                	lw	a5,44(s1)
    80004596:	06f04763          	bgtz	a5,80004604 <end_op+0xbc>
    acquire(&log.lock);
    8000459a:	0001d497          	auipc	s1,0x1d
    8000459e:	ed648493          	addi	s1,s1,-298 # 80021470 <log>
    800045a2:	8526                	mv	a0,s1
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	67e080e7          	jalr	1662(ra) # 80000c22 <acquire>
    log.committing = 0;
    800045ac:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045b0:	8526                	mv	a0,s1
    800045b2:	ffffe097          	auipc	ra,0xffffe
    800045b6:	de6080e7          	jalr	-538(ra) # 80002398 <wakeup>
    release(&log.lock);
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	71a080e7          	jalr	1818(ra) # 80000cd6 <release>
}
    800045c4:	a03d                	j	800045f2 <end_op+0xaa>
    panic("log.committing");
    800045c6:	00004517          	auipc	a0,0x4
    800045ca:	01250513          	addi	a0,a0,18 # 800085d8 <syscalls+0x208>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	f6c080e7          	jalr	-148(ra) # 8000053a <panic>
    wakeup(&log);
    800045d6:	0001d497          	auipc	s1,0x1d
    800045da:	e9a48493          	addi	s1,s1,-358 # 80021470 <log>
    800045de:	8526                	mv	a0,s1
    800045e0:	ffffe097          	auipc	ra,0xffffe
    800045e4:	db8080e7          	jalr	-584(ra) # 80002398 <wakeup>
  release(&log.lock);
    800045e8:	8526                	mv	a0,s1
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6ec080e7          	jalr	1772(ra) # 80000cd6 <release>
}
    800045f2:	70e2                	ld	ra,56(sp)
    800045f4:	7442                	ld	s0,48(sp)
    800045f6:	74a2                	ld	s1,40(sp)
    800045f8:	7902                	ld	s2,32(sp)
    800045fa:	69e2                	ld	s3,24(sp)
    800045fc:	6a42                	ld	s4,16(sp)
    800045fe:	6aa2                	ld	s5,8(sp)
    80004600:	6121                	addi	sp,sp,64
    80004602:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004604:	0001da97          	auipc	s5,0x1d
    80004608:	e9ca8a93          	addi	s5,s5,-356 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000460c:	0001da17          	auipc	s4,0x1d
    80004610:	e64a0a13          	addi	s4,s4,-412 # 80021470 <log>
    80004614:	018a2583          	lw	a1,24(s4)
    80004618:	012585bb          	addw	a1,a1,s2
    8000461c:	2585                	addiw	a1,a1,1
    8000461e:	028a2503          	lw	a0,40(s4)
    80004622:	fffff097          	auipc	ra,0xfffff
    80004626:	cca080e7          	jalr	-822(ra) # 800032ec <bread>
    8000462a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000462c:	000aa583          	lw	a1,0(s5)
    80004630:	028a2503          	lw	a0,40(s4)
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	cb8080e7          	jalr	-840(ra) # 800032ec <bread>
    8000463c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000463e:	40000613          	li	a2,1024
    80004642:	05850593          	addi	a1,a0,88
    80004646:	05848513          	addi	a0,s1,88
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	730080e7          	jalr	1840(ra) # 80000d7a <memmove>
    bwrite(to);  // write the log
    80004652:	8526                	mv	a0,s1
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	d8a080e7          	jalr	-630(ra) # 800033de <bwrite>
    brelse(from);
    8000465c:	854e                	mv	a0,s3
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	dbe080e7          	jalr	-578(ra) # 8000341c <brelse>
    brelse(to);
    80004666:	8526                	mv	a0,s1
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	db4080e7          	jalr	-588(ra) # 8000341c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004670:	2905                	addiw	s2,s2,1
    80004672:	0a91                	addi	s5,s5,4
    80004674:	02ca2783          	lw	a5,44(s4)
    80004678:	f8f94ee3          	blt	s2,a5,80004614 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	c68080e7          	jalr	-920(ra) # 800042e4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004684:	4501                	li	a0,0
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	cda080e7          	jalr	-806(ra) # 80004360 <install_trans>
    log.lh.n = 0;
    8000468e:	0001d797          	auipc	a5,0x1d
    80004692:	e007a723          	sw	zero,-498(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	c4e080e7          	jalr	-946(ra) # 800042e4 <write_head>
    8000469e:	bdf5                	j	8000459a <end_op+0x52>

00000000800046a0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	e04a                	sd	s2,0(sp)
    800046aa:	1000                	addi	s0,sp,32
    800046ac:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046ae:	0001d917          	auipc	s2,0x1d
    800046b2:	dc290913          	addi	s2,s2,-574 # 80021470 <log>
    800046b6:	854a                	mv	a0,s2
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	56a080e7          	jalr	1386(ra) # 80000c22 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046c0:	02c92603          	lw	a2,44(s2)
    800046c4:	47f5                	li	a5,29
    800046c6:	06c7c563          	blt	a5,a2,80004730 <log_write+0x90>
    800046ca:	0001d797          	auipc	a5,0x1d
    800046ce:	dc27a783          	lw	a5,-574(a5) # 8002148c <log+0x1c>
    800046d2:	37fd                	addiw	a5,a5,-1
    800046d4:	04f65e63          	bge	a2,a5,80004730 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046d8:	0001d797          	auipc	a5,0x1d
    800046dc:	db87a783          	lw	a5,-584(a5) # 80021490 <log+0x20>
    800046e0:	06f05063          	blez	a5,80004740 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046e4:	4781                	li	a5,0
    800046e6:	06c05563          	blez	a2,80004750 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ea:	44cc                	lw	a1,12(s1)
    800046ec:	0001d717          	auipc	a4,0x1d
    800046f0:	db470713          	addi	a4,a4,-588 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046f4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046f6:	4314                	lw	a3,0(a4)
    800046f8:	04b68c63          	beq	a3,a1,80004750 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046fc:	2785                	addiw	a5,a5,1
    800046fe:	0711                	addi	a4,a4,4
    80004700:	fef61be3          	bne	a2,a5,800046f6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004704:	0621                	addi	a2,a2,8
    80004706:	060a                	slli	a2,a2,0x2
    80004708:	0001d797          	auipc	a5,0x1d
    8000470c:	d6878793          	addi	a5,a5,-664 # 80021470 <log>
    80004710:	97b2                	add	a5,a5,a2
    80004712:	44d8                	lw	a4,12(s1)
    80004714:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004716:	8526                	mv	a0,s1
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	da2080e7          	jalr	-606(ra) # 800034ba <bpin>
    log.lh.n++;
    80004720:	0001d717          	auipc	a4,0x1d
    80004724:	d5070713          	addi	a4,a4,-688 # 80021470 <log>
    80004728:	575c                	lw	a5,44(a4)
    8000472a:	2785                	addiw	a5,a5,1
    8000472c:	d75c                	sw	a5,44(a4)
    8000472e:	a82d                	j	80004768 <log_write+0xc8>
    panic("too big a transaction");
    80004730:	00004517          	auipc	a0,0x4
    80004734:	eb850513          	addi	a0,a0,-328 # 800085e8 <syscalls+0x218>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	e02080e7          	jalr	-510(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004740:	00004517          	auipc	a0,0x4
    80004744:	ec050513          	addi	a0,a0,-320 # 80008600 <syscalls+0x230>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	df2080e7          	jalr	-526(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004750:	00878693          	addi	a3,a5,8
    80004754:	068a                	slli	a3,a3,0x2
    80004756:	0001d717          	auipc	a4,0x1d
    8000475a:	d1a70713          	addi	a4,a4,-742 # 80021470 <log>
    8000475e:	9736                	add	a4,a4,a3
    80004760:	44d4                	lw	a3,12(s1)
    80004762:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004764:	faf609e3          	beq	a2,a5,80004716 <log_write+0x76>
  }
  release(&log.lock);
    80004768:	0001d517          	auipc	a0,0x1d
    8000476c:	d0850513          	addi	a0,a0,-760 # 80021470 <log>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	566080e7          	jalr	1382(ra) # 80000cd6 <release>
}
    80004778:	60e2                	ld	ra,24(sp)
    8000477a:	6442                	ld	s0,16(sp)
    8000477c:	64a2                	ld	s1,8(sp)
    8000477e:	6902                	ld	s2,0(sp)
    80004780:	6105                	addi	sp,sp,32
    80004782:	8082                	ret

0000000080004784 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004784:	1101                	addi	sp,sp,-32
    80004786:	ec06                	sd	ra,24(sp)
    80004788:	e822                	sd	s0,16(sp)
    8000478a:	e426                	sd	s1,8(sp)
    8000478c:	e04a                	sd	s2,0(sp)
    8000478e:	1000                	addi	s0,sp,32
    80004790:	84aa                	mv	s1,a0
    80004792:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004794:	00004597          	auipc	a1,0x4
    80004798:	e8c58593          	addi	a1,a1,-372 # 80008620 <syscalls+0x250>
    8000479c:	0521                	addi	a0,a0,8
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	3f4080e7          	jalr	1012(ra) # 80000b92 <initlock>
  lk->name = name;
    800047a6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ae:	0204a423          	sw	zero,40(s1)
}
    800047b2:	60e2                	ld	ra,24(sp)
    800047b4:	6442                	ld	s0,16(sp)
    800047b6:	64a2                	ld	s1,8(sp)
    800047b8:	6902                	ld	s2,0(sp)
    800047ba:	6105                	addi	sp,sp,32
    800047bc:	8082                	ret

00000000800047be <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047be:	1101                	addi	sp,sp,-32
    800047c0:	ec06                	sd	ra,24(sp)
    800047c2:	e822                	sd	s0,16(sp)
    800047c4:	e426                	sd	s1,8(sp)
    800047c6:	e04a                	sd	s2,0(sp)
    800047c8:	1000                	addi	s0,sp,32
    800047ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047cc:	00850913          	addi	s2,a0,8
    800047d0:	854a                	mv	a0,s2
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	450080e7          	jalr	1104(ra) # 80000c22 <acquire>
  while (lk->locked) {
    800047da:	409c                	lw	a5,0(s1)
    800047dc:	cb89                	beqz	a5,800047ee <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047de:	85ca                	mv	a1,s2
    800047e0:	8526                	mv	a0,s1
    800047e2:	ffffe097          	auipc	ra,0xffffe
    800047e6:	8bc080e7          	jalr	-1860(ra) # 8000209e <sleep>
  while (lk->locked) {
    800047ea:	409c                	lw	a5,0(s1)
    800047ec:	fbed                	bnez	a5,800047de <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047ee:	4785                	li	a5,1
    800047f0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047f2:	ffffd097          	auipc	ra,0xffffd
    800047f6:	1ac080e7          	jalr	428(ra) # 8000199e <myproc>
    800047fa:	591c                	lw	a5,48(a0)
    800047fc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047fe:	854a                	mv	a0,s2
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	4d6080e7          	jalr	1238(ra) # 80000cd6 <release>
}
    80004808:	60e2                	ld	ra,24(sp)
    8000480a:	6442                	ld	s0,16(sp)
    8000480c:	64a2                	ld	s1,8(sp)
    8000480e:	6902                	ld	s2,0(sp)
    80004810:	6105                	addi	sp,sp,32
    80004812:	8082                	ret

0000000080004814 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	e04a                	sd	s2,0(sp)
    8000481e:	1000                	addi	s0,sp,32
    80004820:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004822:	00850913          	addi	s2,a0,8
    80004826:	854a                	mv	a0,s2
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	3fa080e7          	jalr	1018(ra) # 80000c22 <acquire>
  lk->locked = 0;
    80004830:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004834:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffe097          	auipc	ra,0xffffe
    8000483e:	b5e080e7          	jalr	-1186(ra) # 80002398 <wakeup>
  release(&lk->lk);
    80004842:	854a                	mv	a0,s2
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	492080e7          	jalr	1170(ra) # 80000cd6 <release>
}
    8000484c:	60e2                	ld	ra,24(sp)
    8000484e:	6442                	ld	s0,16(sp)
    80004850:	64a2                	ld	s1,8(sp)
    80004852:	6902                	ld	s2,0(sp)
    80004854:	6105                	addi	sp,sp,32
    80004856:	8082                	ret

0000000080004858 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004858:	7179                	addi	sp,sp,-48
    8000485a:	f406                	sd	ra,40(sp)
    8000485c:	f022                	sd	s0,32(sp)
    8000485e:	ec26                	sd	s1,24(sp)
    80004860:	e84a                	sd	s2,16(sp)
    80004862:	e44e                	sd	s3,8(sp)
    80004864:	1800                	addi	s0,sp,48
    80004866:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004868:	00850913          	addi	s2,a0,8
    8000486c:	854a                	mv	a0,s2
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	3b4080e7          	jalr	948(ra) # 80000c22 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004876:	409c                	lw	a5,0(s1)
    80004878:	ef99                	bnez	a5,80004896 <holdingsleep+0x3e>
    8000487a:	4481                	li	s1,0
  release(&lk->lk);
    8000487c:	854a                	mv	a0,s2
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	458080e7          	jalr	1112(ra) # 80000cd6 <release>
  return r;
}
    80004886:	8526                	mv	a0,s1
    80004888:	70a2                	ld	ra,40(sp)
    8000488a:	7402                	ld	s0,32(sp)
    8000488c:	64e2                	ld	s1,24(sp)
    8000488e:	6942                	ld	s2,16(sp)
    80004890:	69a2                	ld	s3,8(sp)
    80004892:	6145                	addi	sp,sp,48
    80004894:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004896:	0284a983          	lw	s3,40(s1)
    8000489a:	ffffd097          	auipc	ra,0xffffd
    8000489e:	104080e7          	jalr	260(ra) # 8000199e <myproc>
    800048a2:	5904                	lw	s1,48(a0)
    800048a4:	413484b3          	sub	s1,s1,s3
    800048a8:	0014b493          	seqz	s1,s1
    800048ac:	bfc1                	j	8000487c <holdingsleep+0x24>

00000000800048ae <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048ae:	1141                	addi	sp,sp,-16
    800048b0:	e406                	sd	ra,8(sp)
    800048b2:	e022                	sd	s0,0(sp)
    800048b4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048b6:	00004597          	auipc	a1,0x4
    800048ba:	d7a58593          	addi	a1,a1,-646 # 80008630 <syscalls+0x260>
    800048be:	0001d517          	auipc	a0,0x1d
    800048c2:	cfa50513          	addi	a0,a0,-774 # 800215b8 <ftable>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	2cc080e7          	jalr	716(ra) # 80000b92 <initlock>
}
    800048ce:	60a2                	ld	ra,8(sp)
    800048d0:	6402                	ld	s0,0(sp)
    800048d2:	0141                	addi	sp,sp,16
    800048d4:	8082                	ret

00000000800048d6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048d6:	1101                	addi	sp,sp,-32
    800048d8:	ec06                	sd	ra,24(sp)
    800048da:	e822                	sd	s0,16(sp)
    800048dc:	e426                	sd	s1,8(sp)
    800048de:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048e0:	0001d517          	auipc	a0,0x1d
    800048e4:	cd850513          	addi	a0,a0,-808 # 800215b8 <ftable>
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	33a080e7          	jalr	826(ra) # 80000c22 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048f0:	0001d497          	auipc	s1,0x1d
    800048f4:	ce048493          	addi	s1,s1,-800 # 800215d0 <ftable+0x18>
    800048f8:	0001e717          	auipc	a4,0x1e
    800048fc:	c7870713          	addi	a4,a4,-904 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004900:	40dc                	lw	a5,4(s1)
    80004902:	cf99                	beqz	a5,80004920 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004904:	02848493          	addi	s1,s1,40
    80004908:	fee49ce3          	bne	s1,a4,80004900 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000490c:	0001d517          	auipc	a0,0x1d
    80004910:	cac50513          	addi	a0,a0,-852 # 800215b8 <ftable>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	3c2080e7          	jalr	962(ra) # 80000cd6 <release>
  return 0;
    8000491c:	4481                	li	s1,0
    8000491e:	a819                	j	80004934 <filealloc+0x5e>
      f->ref = 1;
    80004920:	4785                	li	a5,1
    80004922:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004924:	0001d517          	auipc	a0,0x1d
    80004928:	c9450513          	addi	a0,a0,-876 # 800215b8 <ftable>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	3aa080e7          	jalr	938(ra) # 80000cd6 <release>
}
    80004934:	8526                	mv	a0,s1
    80004936:	60e2                	ld	ra,24(sp)
    80004938:	6442                	ld	s0,16(sp)
    8000493a:	64a2                	ld	s1,8(sp)
    8000493c:	6105                	addi	sp,sp,32
    8000493e:	8082                	ret

0000000080004940 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004940:	1101                	addi	sp,sp,-32
    80004942:	ec06                	sd	ra,24(sp)
    80004944:	e822                	sd	s0,16(sp)
    80004946:	e426                	sd	s1,8(sp)
    80004948:	1000                	addi	s0,sp,32
    8000494a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000494c:	0001d517          	auipc	a0,0x1d
    80004950:	c6c50513          	addi	a0,a0,-916 # 800215b8 <ftable>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	2ce080e7          	jalr	718(ra) # 80000c22 <acquire>
  if(f->ref < 1)
    8000495c:	40dc                	lw	a5,4(s1)
    8000495e:	02f05263          	blez	a5,80004982 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004962:	2785                	addiw	a5,a5,1
    80004964:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004966:	0001d517          	auipc	a0,0x1d
    8000496a:	c5250513          	addi	a0,a0,-942 # 800215b8 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	368080e7          	jalr	872(ra) # 80000cd6 <release>
  return f;
}
    80004976:	8526                	mv	a0,s1
    80004978:	60e2                	ld	ra,24(sp)
    8000497a:	6442                	ld	s0,16(sp)
    8000497c:	64a2                	ld	s1,8(sp)
    8000497e:	6105                	addi	sp,sp,32
    80004980:	8082                	ret
    panic("filedup");
    80004982:	00004517          	auipc	a0,0x4
    80004986:	cb650513          	addi	a0,a0,-842 # 80008638 <syscalls+0x268>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	bb0080e7          	jalr	-1104(ra) # 8000053a <panic>

0000000080004992 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004992:	7139                	addi	sp,sp,-64
    80004994:	fc06                	sd	ra,56(sp)
    80004996:	f822                	sd	s0,48(sp)
    80004998:	f426                	sd	s1,40(sp)
    8000499a:	f04a                	sd	s2,32(sp)
    8000499c:	ec4e                	sd	s3,24(sp)
    8000499e:	e852                	sd	s4,16(sp)
    800049a0:	e456                	sd	s5,8(sp)
    800049a2:	0080                	addi	s0,sp,64
    800049a4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049a6:	0001d517          	auipc	a0,0x1d
    800049aa:	c1250513          	addi	a0,a0,-1006 # 800215b8 <ftable>
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	274080e7          	jalr	628(ra) # 80000c22 <acquire>
  if(f->ref < 1)
    800049b6:	40dc                	lw	a5,4(s1)
    800049b8:	06f05163          	blez	a5,80004a1a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049bc:	37fd                	addiw	a5,a5,-1
    800049be:	0007871b          	sext.w	a4,a5
    800049c2:	c0dc                	sw	a5,4(s1)
    800049c4:	06e04363          	bgtz	a4,80004a2a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049c8:	0004a903          	lw	s2,0(s1)
    800049cc:	0094ca83          	lbu	s5,9(s1)
    800049d0:	0104ba03          	ld	s4,16(s1)
    800049d4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049d8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049dc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049e0:	0001d517          	auipc	a0,0x1d
    800049e4:	bd850513          	addi	a0,a0,-1064 # 800215b8 <ftable>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	2ee080e7          	jalr	750(ra) # 80000cd6 <release>

  if(ff.type == FD_PIPE){
    800049f0:	4785                	li	a5,1
    800049f2:	04f90d63          	beq	s2,a5,80004a4c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049f6:	3979                	addiw	s2,s2,-2
    800049f8:	4785                	li	a5,1
    800049fa:	0527e063          	bltu	a5,s2,80004a3a <fileclose+0xa8>
    begin_op();
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	acc080e7          	jalr	-1332(ra) # 800044ca <begin_op>
    iput(ff.ip);
    80004a06:	854e                	mv	a0,s3
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	2a0080e7          	jalr	672(ra) # 80003ca8 <iput>
    end_op();
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	b38080e7          	jalr	-1224(ra) # 80004548 <end_op>
    80004a18:	a00d                	j	80004a3a <fileclose+0xa8>
    panic("fileclose");
    80004a1a:	00004517          	auipc	a0,0x4
    80004a1e:	c2650513          	addi	a0,a0,-986 # 80008640 <syscalls+0x270>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b18080e7          	jalr	-1256(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004a2a:	0001d517          	auipc	a0,0x1d
    80004a2e:	b8e50513          	addi	a0,a0,-1138 # 800215b8 <ftable>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	2a4080e7          	jalr	676(ra) # 80000cd6 <release>
  }
}
    80004a3a:	70e2                	ld	ra,56(sp)
    80004a3c:	7442                	ld	s0,48(sp)
    80004a3e:	74a2                	ld	s1,40(sp)
    80004a40:	7902                	ld	s2,32(sp)
    80004a42:	69e2                	ld	s3,24(sp)
    80004a44:	6a42                	ld	s4,16(sp)
    80004a46:	6aa2                	ld	s5,8(sp)
    80004a48:	6121                	addi	sp,sp,64
    80004a4a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a4c:	85d6                	mv	a1,s5
    80004a4e:	8552                	mv	a0,s4
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	34c080e7          	jalr	844(ra) # 80004d9c <pipeclose>
    80004a58:	b7cd                	j	80004a3a <fileclose+0xa8>

0000000080004a5a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a5a:	715d                	addi	sp,sp,-80
    80004a5c:	e486                	sd	ra,72(sp)
    80004a5e:	e0a2                	sd	s0,64(sp)
    80004a60:	fc26                	sd	s1,56(sp)
    80004a62:	f84a                	sd	s2,48(sp)
    80004a64:	f44e                	sd	s3,40(sp)
    80004a66:	0880                	addi	s0,sp,80
    80004a68:	84aa                	mv	s1,a0
    80004a6a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	f32080e7          	jalr	-206(ra) # 8000199e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a74:	409c                	lw	a5,0(s1)
    80004a76:	37f9                	addiw	a5,a5,-2
    80004a78:	4705                	li	a4,1
    80004a7a:	04f76763          	bltu	a4,a5,80004ac8 <filestat+0x6e>
    80004a7e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a80:	6c88                	ld	a0,24(s1)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	06c080e7          	jalr	108(ra) # 80003aee <ilock>
    stati(f->ip, &st);
    80004a8a:	fb840593          	addi	a1,s0,-72
    80004a8e:	6c88                	ld	a0,24(s1)
    80004a90:	fffff097          	auipc	ra,0xfffff
    80004a94:	2e8080e7          	jalr	744(ra) # 80003d78 <stati>
    iunlock(f->ip);
    80004a98:	6c88                	ld	a0,24(s1)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	116080e7          	jalr	278(ra) # 80003bb0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aa2:	46e1                	li	a3,24
    80004aa4:	fb840613          	addi	a2,s0,-72
    80004aa8:	85ce                	mv	a1,s3
    80004aaa:	05893503          	ld	a0,88(s2)
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	bb4080e7          	jalr	-1100(ra) # 80001662 <copyout>
    80004ab6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004aba:	60a6                	ld	ra,72(sp)
    80004abc:	6406                	ld	s0,64(sp)
    80004abe:	74e2                	ld	s1,56(sp)
    80004ac0:	7942                	ld	s2,48(sp)
    80004ac2:	79a2                	ld	s3,40(sp)
    80004ac4:	6161                	addi	sp,sp,80
    80004ac6:	8082                	ret
  return -1;
    80004ac8:	557d                	li	a0,-1
    80004aca:	bfc5                	j	80004aba <filestat+0x60>

0000000080004acc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004acc:	7179                	addi	sp,sp,-48
    80004ace:	f406                	sd	ra,40(sp)
    80004ad0:	f022                	sd	s0,32(sp)
    80004ad2:	ec26                	sd	s1,24(sp)
    80004ad4:	e84a                	sd	s2,16(sp)
    80004ad6:	e44e                	sd	s3,8(sp)
    80004ad8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ada:	00854783          	lbu	a5,8(a0)
    80004ade:	c3d5                	beqz	a5,80004b82 <fileread+0xb6>
    80004ae0:	84aa                	mv	s1,a0
    80004ae2:	89ae                	mv	s3,a1
    80004ae4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae6:	411c                	lw	a5,0(a0)
    80004ae8:	4705                	li	a4,1
    80004aea:	04e78963          	beq	a5,a4,80004b3c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aee:	470d                	li	a4,3
    80004af0:	04e78d63          	beq	a5,a4,80004b4a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004af4:	4709                	li	a4,2
    80004af6:	06e79e63          	bne	a5,a4,80004b72 <fileread+0xa6>
    ilock(f->ip);
    80004afa:	6d08                	ld	a0,24(a0)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	ff2080e7          	jalr	-14(ra) # 80003aee <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b04:	874a                	mv	a4,s2
    80004b06:	5094                	lw	a3,32(s1)
    80004b08:	864e                	mv	a2,s3
    80004b0a:	4585                	li	a1,1
    80004b0c:	6c88                	ld	a0,24(s1)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	294080e7          	jalr	660(ra) # 80003da2 <readi>
    80004b16:	892a                	mv	s2,a0
    80004b18:	00a05563          	blez	a0,80004b22 <fileread+0x56>
      f->off += r;
    80004b1c:	509c                	lw	a5,32(s1)
    80004b1e:	9fa9                	addw	a5,a5,a0
    80004b20:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b22:	6c88                	ld	a0,24(s1)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	08c080e7          	jalr	140(ra) # 80003bb0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b2c:	854a                	mv	a0,s2
    80004b2e:	70a2                	ld	ra,40(sp)
    80004b30:	7402                	ld	s0,32(sp)
    80004b32:	64e2                	ld	s1,24(sp)
    80004b34:	6942                	ld	s2,16(sp)
    80004b36:	69a2                	ld	s3,8(sp)
    80004b38:	6145                	addi	sp,sp,48
    80004b3a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b3c:	6908                	ld	a0,16(a0)
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	3c0080e7          	jalr	960(ra) # 80004efe <piperead>
    80004b46:	892a                	mv	s2,a0
    80004b48:	b7d5                	j	80004b2c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b4a:	02451783          	lh	a5,36(a0)
    80004b4e:	03079693          	slli	a3,a5,0x30
    80004b52:	92c1                	srli	a3,a3,0x30
    80004b54:	4725                	li	a4,9
    80004b56:	02d76863          	bltu	a4,a3,80004b86 <fileread+0xba>
    80004b5a:	0792                	slli	a5,a5,0x4
    80004b5c:	0001d717          	auipc	a4,0x1d
    80004b60:	9bc70713          	addi	a4,a4,-1604 # 80021518 <devsw>
    80004b64:	97ba                	add	a5,a5,a4
    80004b66:	639c                	ld	a5,0(a5)
    80004b68:	c38d                	beqz	a5,80004b8a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b6a:	4505                	li	a0,1
    80004b6c:	9782                	jalr	a5
    80004b6e:	892a                	mv	s2,a0
    80004b70:	bf75                	j	80004b2c <fileread+0x60>
    panic("fileread");
    80004b72:	00004517          	auipc	a0,0x4
    80004b76:	ade50513          	addi	a0,a0,-1314 # 80008650 <syscalls+0x280>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	9c0080e7          	jalr	-1600(ra) # 8000053a <panic>
    return -1;
    80004b82:	597d                	li	s2,-1
    80004b84:	b765                	j	80004b2c <fileread+0x60>
      return -1;
    80004b86:	597d                	li	s2,-1
    80004b88:	b755                	j	80004b2c <fileread+0x60>
    80004b8a:	597d                	li	s2,-1
    80004b8c:	b745                	j	80004b2c <fileread+0x60>

0000000080004b8e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b8e:	715d                	addi	sp,sp,-80
    80004b90:	e486                	sd	ra,72(sp)
    80004b92:	e0a2                	sd	s0,64(sp)
    80004b94:	fc26                	sd	s1,56(sp)
    80004b96:	f84a                	sd	s2,48(sp)
    80004b98:	f44e                	sd	s3,40(sp)
    80004b9a:	f052                	sd	s4,32(sp)
    80004b9c:	ec56                	sd	s5,24(sp)
    80004b9e:	e85a                	sd	s6,16(sp)
    80004ba0:	e45e                	sd	s7,8(sp)
    80004ba2:	e062                	sd	s8,0(sp)
    80004ba4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ba6:	00954783          	lbu	a5,9(a0)
    80004baa:	10078663          	beqz	a5,80004cb6 <filewrite+0x128>
    80004bae:	892a                	mv	s2,a0
    80004bb0:	8b2e                	mv	s6,a1
    80004bb2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bb4:	411c                	lw	a5,0(a0)
    80004bb6:	4705                	li	a4,1
    80004bb8:	02e78263          	beq	a5,a4,80004bdc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bbc:	470d                	li	a4,3
    80004bbe:	02e78663          	beq	a5,a4,80004bea <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc2:	4709                	li	a4,2
    80004bc4:	0ee79163          	bne	a5,a4,80004ca6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bc8:	0ac05d63          	blez	a2,80004c82 <filewrite+0xf4>
    int i = 0;
    80004bcc:	4981                	li	s3,0
    80004bce:	6b85                	lui	s7,0x1
    80004bd0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bd4:	6c05                	lui	s8,0x1
    80004bd6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bda:	a861                	j	80004c72 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bdc:	6908                	ld	a0,16(a0)
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	22e080e7          	jalr	558(ra) # 80004e0c <pipewrite>
    80004be6:	8a2a                	mv	s4,a0
    80004be8:	a045                	j	80004c88 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bea:	02451783          	lh	a5,36(a0)
    80004bee:	03079693          	slli	a3,a5,0x30
    80004bf2:	92c1                	srli	a3,a3,0x30
    80004bf4:	4725                	li	a4,9
    80004bf6:	0cd76263          	bltu	a4,a3,80004cba <filewrite+0x12c>
    80004bfa:	0792                	slli	a5,a5,0x4
    80004bfc:	0001d717          	auipc	a4,0x1d
    80004c00:	91c70713          	addi	a4,a4,-1764 # 80021518 <devsw>
    80004c04:	97ba                	add	a5,a5,a4
    80004c06:	679c                	ld	a5,8(a5)
    80004c08:	cbdd                	beqz	a5,80004cbe <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c0a:	4505                	li	a0,1
    80004c0c:	9782                	jalr	a5
    80004c0e:	8a2a                	mv	s4,a0
    80004c10:	a8a5                	j	80004c88 <filewrite+0xfa>
    80004c12:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	8b4080e7          	jalr	-1868(ra) # 800044ca <begin_op>
      ilock(f->ip);
    80004c1e:	01893503          	ld	a0,24(s2)
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	ecc080e7          	jalr	-308(ra) # 80003aee <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c2a:	8756                	mv	a4,s5
    80004c2c:	02092683          	lw	a3,32(s2)
    80004c30:	01698633          	add	a2,s3,s6
    80004c34:	4585                	li	a1,1
    80004c36:	01893503          	ld	a0,24(s2)
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	260080e7          	jalr	608(ra) # 80003e9a <writei>
    80004c42:	84aa                	mv	s1,a0
    80004c44:	00a05763          	blez	a0,80004c52 <filewrite+0xc4>
        f->off += r;
    80004c48:	02092783          	lw	a5,32(s2)
    80004c4c:	9fa9                	addw	a5,a5,a0
    80004c4e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c52:	01893503          	ld	a0,24(s2)
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	f5a080e7          	jalr	-166(ra) # 80003bb0 <iunlock>
      end_op();
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	8ea080e7          	jalr	-1814(ra) # 80004548 <end_op>

      if(r != n1){
    80004c66:	009a9f63          	bne	s5,s1,80004c84 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c6a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c6e:	0149db63          	bge	s3,s4,80004c84 <filewrite+0xf6>
      int n1 = n - i;
    80004c72:	413a04bb          	subw	s1,s4,s3
    80004c76:	0004879b          	sext.w	a5,s1
    80004c7a:	f8fbdce3          	bge	s7,a5,80004c12 <filewrite+0x84>
    80004c7e:	84e2                	mv	s1,s8
    80004c80:	bf49                	j	80004c12 <filewrite+0x84>
    int i = 0;
    80004c82:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c84:	013a1f63          	bne	s4,s3,80004ca2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c88:	8552                	mv	a0,s4
    80004c8a:	60a6                	ld	ra,72(sp)
    80004c8c:	6406                	ld	s0,64(sp)
    80004c8e:	74e2                	ld	s1,56(sp)
    80004c90:	7942                	ld	s2,48(sp)
    80004c92:	79a2                	ld	s3,40(sp)
    80004c94:	7a02                	ld	s4,32(sp)
    80004c96:	6ae2                	ld	s5,24(sp)
    80004c98:	6b42                	ld	s6,16(sp)
    80004c9a:	6ba2                	ld	s7,8(sp)
    80004c9c:	6c02                	ld	s8,0(sp)
    80004c9e:	6161                	addi	sp,sp,80
    80004ca0:	8082                	ret
    ret = (i == n ? n : -1);
    80004ca2:	5a7d                	li	s4,-1
    80004ca4:	b7d5                	j	80004c88 <filewrite+0xfa>
    panic("filewrite");
    80004ca6:	00004517          	auipc	a0,0x4
    80004caa:	9ba50513          	addi	a0,a0,-1606 # 80008660 <syscalls+0x290>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	88c080e7          	jalr	-1908(ra) # 8000053a <panic>
    return -1;
    80004cb6:	5a7d                	li	s4,-1
    80004cb8:	bfc1                	j	80004c88 <filewrite+0xfa>
      return -1;
    80004cba:	5a7d                	li	s4,-1
    80004cbc:	b7f1                	j	80004c88 <filewrite+0xfa>
    80004cbe:	5a7d                	li	s4,-1
    80004cc0:	b7e1                	j	80004c88 <filewrite+0xfa>

0000000080004cc2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cc2:	7179                	addi	sp,sp,-48
    80004cc4:	f406                	sd	ra,40(sp)
    80004cc6:	f022                	sd	s0,32(sp)
    80004cc8:	ec26                	sd	s1,24(sp)
    80004cca:	e84a                	sd	s2,16(sp)
    80004ccc:	e44e                	sd	s3,8(sp)
    80004cce:	e052                	sd	s4,0(sp)
    80004cd0:	1800                	addi	s0,sp,48
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cd6:	0005b023          	sd	zero,0(a1)
    80004cda:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	bf8080e7          	jalr	-1032(ra) # 800048d6 <filealloc>
    80004ce6:	e088                	sd	a0,0(s1)
    80004ce8:	c551                	beqz	a0,80004d74 <pipealloc+0xb2>
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	bec080e7          	jalr	-1044(ra) # 800048d6 <filealloc>
    80004cf2:	00aa3023          	sd	a0,0(s4)
    80004cf6:	c92d                	beqz	a0,80004d68 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	de8080e7          	jalr	-536(ra) # 80000ae0 <kalloc>
    80004d00:	892a                	mv	s2,a0
    80004d02:	c125                	beqz	a0,80004d62 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d04:	4985                	li	s3,1
    80004d06:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d0a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d0e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d12:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d16:	00004597          	auipc	a1,0x4
    80004d1a:	95a58593          	addi	a1,a1,-1702 # 80008670 <syscalls+0x2a0>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	e74080e7          	jalr	-396(ra) # 80000b92 <initlock>
  (*f0)->type = FD_PIPE;
    80004d26:	609c                	ld	a5,0(s1)
    80004d28:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d2c:	609c                	ld	a5,0(s1)
    80004d2e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d32:	609c                	ld	a5,0(s1)
    80004d34:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d38:	609c                	ld	a5,0(s1)
    80004d3a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d3e:	000a3783          	ld	a5,0(s4)
    80004d42:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d46:	000a3783          	ld	a5,0(s4)
    80004d4a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d4e:	000a3783          	ld	a5,0(s4)
    80004d52:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d56:	000a3783          	ld	a5,0(s4)
    80004d5a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d5e:	4501                	li	a0,0
    80004d60:	a025                	j	80004d88 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d62:	6088                	ld	a0,0(s1)
    80004d64:	e501                	bnez	a0,80004d6c <pipealloc+0xaa>
    80004d66:	a039                	j	80004d74 <pipealloc+0xb2>
    80004d68:	6088                	ld	a0,0(s1)
    80004d6a:	c51d                	beqz	a0,80004d98 <pipealloc+0xd6>
    fileclose(*f0);
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	c26080e7          	jalr	-986(ra) # 80004992 <fileclose>
  if(*f1)
    80004d74:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d78:	557d                	li	a0,-1
  if(*f1)
    80004d7a:	c799                	beqz	a5,80004d88 <pipealloc+0xc6>
    fileclose(*f1);
    80004d7c:	853e                	mv	a0,a5
    80004d7e:	00000097          	auipc	ra,0x0
    80004d82:	c14080e7          	jalr	-1004(ra) # 80004992 <fileclose>
  return -1;
    80004d86:	557d                	li	a0,-1
}
    80004d88:	70a2                	ld	ra,40(sp)
    80004d8a:	7402                	ld	s0,32(sp)
    80004d8c:	64e2                	ld	s1,24(sp)
    80004d8e:	6942                	ld	s2,16(sp)
    80004d90:	69a2                	ld	s3,8(sp)
    80004d92:	6a02                	ld	s4,0(sp)
    80004d94:	6145                	addi	sp,sp,48
    80004d96:	8082                	ret
  return -1;
    80004d98:	557d                	li	a0,-1
    80004d9a:	b7fd                	j	80004d88 <pipealloc+0xc6>

0000000080004d9c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d9c:	1101                	addi	sp,sp,-32
    80004d9e:	ec06                	sd	ra,24(sp)
    80004da0:	e822                	sd	s0,16(sp)
    80004da2:	e426                	sd	s1,8(sp)
    80004da4:	e04a                	sd	s2,0(sp)
    80004da6:	1000                	addi	s0,sp,32
    80004da8:	84aa                	mv	s1,a0
    80004daa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	e76080e7          	jalr	-394(ra) # 80000c22 <acquire>
  if(writable){
    80004db4:	02090d63          	beqz	s2,80004dee <pipeclose+0x52>
    pi->writeopen = 0;
    80004db8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dbc:	21848513          	addi	a0,s1,536
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	5d8080e7          	jalr	1496(ra) # 80002398 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dc8:	2204b783          	ld	a5,544(s1)
    80004dcc:	eb95                	bnez	a5,80004e00 <pipeclose+0x64>
    release(&pi->lock);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	f06080e7          	jalr	-250(ra) # 80000cd6 <release>
    kfree((char*)pi);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	c08080e7          	jalr	-1016(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004de2:	60e2                	ld	ra,24(sp)
    80004de4:	6442                	ld	s0,16(sp)
    80004de6:	64a2                	ld	s1,8(sp)
    80004de8:	6902                	ld	s2,0(sp)
    80004dea:	6105                	addi	sp,sp,32
    80004dec:	8082                	ret
    pi->readopen = 0;
    80004dee:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004df2:	21c48513          	addi	a0,s1,540
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	5a2080e7          	jalr	1442(ra) # 80002398 <wakeup>
    80004dfe:	b7e9                	j	80004dc8 <pipeclose+0x2c>
    release(&pi->lock);
    80004e00:	8526                	mv	a0,s1
    80004e02:	ffffc097          	auipc	ra,0xffffc
    80004e06:	ed4080e7          	jalr	-300(ra) # 80000cd6 <release>
}
    80004e0a:	bfe1                	j	80004de2 <pipeclose+0x46>

0000000080004e0c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e0c:	711d                	addi	sp,sp,-96
    80004e0e:	ec86                	sd	ra,88(sp)
    80004e10:	e8a2                	sd	s0,80(sp)
    80004e12:	e4a6                	sd	s1,72(sp)
    80004e14:	e0ca                	sd	s2,64(sp)
    80004e16:	fc4e                	sd	s3,56(sp)
    80004e18:	f852                	sd	s4,48(sp)
    80004e1a:	f456                	sd	s5,40(sp)
    80004e1c:	f05a                	sd	s6,32(sp)
    80004e1e:	ec5e                	sd	s7,24(sp)
    80004e20:	e862                	sd	s8,16(sp)
    80004e22:	1080                	addi	s0,sp,96
    80004e24:	84aa                	mv	s1,a0
    80004e26:	8aae                	mv	s5,a1
    80004e28:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	b74080e7          	jalr	-1164(ra) # 8000199e <myproc>
    80004e32:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e34:	8526                	mv	a0,s1
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	dec080e7          	jalr	-532(ra) # 80000c22 <acquire>
  while(i < n){
    80004e3e:	0b405363          	blez	s4,80004ee4 <pipewrite+0xd8>
  int i = 0;
    80004e42:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e44:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e46:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e4a:	21c48b93          	addi	s7,s1,540
    80004e4e:	a089                	j	80004e90 <pipewrite+0x84>
      release(&pi->lock);
    80004e50:	8526                	mv	a0,s1
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	e84080e7          	jalr	-380(ra) # 80000cd6 <release>
      return -1;
    80004e5a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	60e6                	ld	ra,88(sp)
    80004e60:	6446                	ld	s0,80(sp)
    80004e62:	64a6                	ld	s1,72(sp)
    80004e64:	6906                	ld	s2,64(sp)
    80004e66:	79e2                	ld	s3,56(sp)
    80004e68:	7a42                	ld	s4,48(sp)
    80004e6a:	7aa2                	ld	s5,40(sp)
    80004e6c:	7b02                	ld	s6,32(sp)
    80004e6e:	6be2                	ld	s7,24(sp)
    80004e70:	6c42                	ld	s8,16(sp)
    80004e72:	6125                	addi	sp,sp,96
    80004e74:	8082                	ret
      wakeup(&pi->nread);
    80004e76:	8562                	mv	a0,s8
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	520080e7          	jalr	1312(ra) # 80002398 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e80:	85a6                	mv	a1,s1
    80004e82:	855e                	mv	a0,s7
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	21a080e7          	jalr	538(ra) # 8000209e <sleep>
  while(i < n){
    80004e8c:	05495d63          	bge	s2,s4,80004ee6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004e90:	2204a783          	lw	a5,544(s1)
    80004e94:	dfd5                	beqz	a5,80004e50 <pipewrite+0x44>
    80004e96:	0289a783          	lw	a5,40(s3)
    80004e9a:	fbdd                	bnez	a5,80004e50 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e9c:	2184a783          	lw	a5,536(s1)
    80004ea0:	21c4a703          	lw	a4,540(s1)
    80004ea4:	2007879b          	addiw	a5,a5,512
    80004ea8:	fcf707e3          	beq	a4,a5,80004e76 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eac:	4685                	li	a3,1
    80004eae:	01590633          	add	a2,s2,s5
    80004eb2:	faf40593          	addi	a1,s0,-81
    80004eb6:	0589b503          	ld	a0,88(s3)
    80004eba:	ffffd097          	auipc	ra,0xffffd
    80004ebe:	834080e7          	jalr	-1996(ra) # 800016ee <copyin>
    80004ec2:	03650263          	beq	a0,s6,80004ee6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ec6:	21c4a783          	lw	a5,540(s1)
    80004eca:	0017871b          	addiw	a4,a5,1
    80004ece:	20e4ae23          	sw	a4,540(s1)
    80004ed2:	1ff7f793          	andi	a5,a5,511
    80004ed6:	97a6                	add	a5,a5,s1
    80004ed8:	faf44703          	lbu	a4,-81(s0)
    80004edc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ee0:	2905                	addiw	s2,s2,1
    80004ee2:	b76d                	j	80004e8c <pipewrite+0x80>
  int i = 0;
    80004ee4:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ee6:	21848513          	addi	a0,s1,536
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	4ae080e7          	jalr	1198(ra) # 80002398 <wakeup>
  release(&pi->lock);
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	de2080e7          	jalr	-542(ra) # 80000cd6 <release>
  return i;
    80004efc:	b785                	j	80004e5c <pipewrite+0x50>

0000000080004efe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004efe:	715d                	addi	sp,sp,-80
    80004f00:	e486                	sd	ra,72(sp)
    80004f02:	e0a2                	sd	s0,64(sp)
    80004f04:	fc26                	sd	s1,56(sp)
    80004f06:	f84a                	sd	s2,48(sp)
    80004f08:	f44e                	sd	s3,40(sp)
    80004f0a:	f052                	sd	s4,32(sp)
    80004f0c:	ec56                	sd	s5,24(sp)
    80004f0e:	e85a                	sd	s6,16(sp)
    80004f10:	0880                	addi	s0,sp,80
    80004f12:	84aa                	mv	s1,a0
    80004f14:	892e                	mv	s2,a1
    80004f16:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	a86080e7          	jalr	-1402(ra) # 8000199e <myproc>
    80004f20:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f22:	8526                	mv	a0,s1
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	cfe080e7          	jalr	-770(ra) # 80000c22 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f2c:	2184a703          	lw	a4,536(s1)
    80004f30:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f34:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f38:	02f71463          	bne	a4,a5,80004f60 <piperead+0x62>
    80004f3c:	2244a783          	lw	a5,548(s1)
    80004f40:	c385                	beqz	a5,80004f60 <piperead+0x62>
    if(pr->killed){
    80004f42:	028a2783          	lw	a5,40(s4)
    80004f46:	ebc9                	bnez	a5,80004fd8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f48:	85a6                	mv	a1,s1
    80004f4a:	854e                	mv	a0,s3
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	152080e7          	jalr	338(ra) # 8000209e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f54:	2184a703          	lw	a4,536(s1)
    80004f58:	21c4a783          	lw	a5,540(s1)
    80004f5c:	fef700e3          	beq	a4,a5,80004f3c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f60:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f62:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f64:	05505463          	blez	s5,80004fac <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004f68:	2184a783          	lw	a5,536(s1)
    80004f6c:	21c4a703          	lw	a4,540(s1)
    80004f70:	02f70e63          	beq	a4,a5,80004fac <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f74:	0017871b          	addiw	a4,a5,1
    80004f78:	20e4ac23          	sw	a4,536(s1)
    80004f7c:	1ff7f793          	andi	a5,a5,511
    80004f80:	97a6                	add	a5,a5,s1
    80004f82:	0187c783          	lbu	a5,24(a5)
    80004f86:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f8a:	4685                	li	a3,1
    80004f8c:	fbf40613          	addi	a2,s0,-65
    80004f90:	85ca                	mv	a1,s2
    80004f92:	058a3503          	ld	a0,88(s4)
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	6cc080e7          	jalr	1740(ra) # 80001662 <copyout>
    80004f9e:	01650763          	beq	a0,s6,80004fac <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fa2:	2985                	addiw	s3,s3,1
    80004fa4:	0905                	addi	s2,s2,1
    80004fa6:	fd3a91e3          	bne	s5,s3,80004f68 <piperead+0x6a>
    80004faa:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fac:	21c48513          	addi	a0,s1,540
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	3e8080e7          	jalr	1000(ra) # 80002398 <wakeup>
  release(&pi->lock);
    80004fb8:	8526                	mv	a0,s1
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	d1c080e7          	jalr	-740(ra) # 80000cd6 <release>
  return i;
}
    80004fc2:	854e                	mv	a0,s3
    80004fc4:	60a6                	ld	ra,72(sp)
    80004fc6:	6406                	ld	s0,64(sp)
    80004fc8:	74e2                	ld	s1,56(sp)
    80004fca:	7942                	ld	s2,48(sp)
    80004fcc:	79a2                	ld	s3,40(sp)
    80004fce:	7a02                	ld	s4,32(sp)
    80004fd0:	6ae2                	ld	s5,24(sp)
    80004fd2:	6b42                	ld	s6,16(sp)
    80004fd4:	6161                	addi	sp,sp,80
    80004fd6:	8082                	ret
      release(&pi->lock);
    80004fd8:	8526                	mv	a0,s1
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	cfc080e7          	jalr	-772(ra) # 80000cd6 <release>
      return -1;
    80004fe2:	59fd                	li	s3,-1
    80004fe4:	bff9                	j	80004fc2 <piperead+0xc4>

0000000080004fe6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fe6:	de010113          	addi	sp,sp,-544
    80004fea:	20113c23          	sd	ra,536(sp)
    80004fee:	20813823          	sd	s0,528(sp)
    80004ff2:	20913423          	sd	s1,520(sp)
    80004ff6:	21213023          	sd	s2,512(sp)
    80004ffa:	ffce                	sd	s3,504(sp)
    80004ffc:	fbd2                	sd	s4,496(sp)
    80004ffe:	f7d6                	sd	s5,488(sp)
    80005000:	f3da                	sd	s6,480(sp)
    80005002:	efde                	sd	s7,472(sp)
    80005004:	ebe2                	sd	s8,464(sp)
    80005006:	e7e6                	sd	s9,456(sp)
    80005008:	e3ea                	sd	s10,448(sp)
    8000500a:	ff6e                	sd	s11,440(sp)
    8000500c:	1400                	addi	s0,sp,544
    8000500e:	892a                	mv	s2,a0
    80005010:	dea43423          	sd	a0,-536(s0)
    80005014:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	986080e7          	jalr	-1658(ra) # 8000199e <myproc>
    80005020:	84aa                	mv	s1,a0

  begin_op();
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	4a8080e7          	jalr	1192(ra) # 800044ca <begin_op>

  if((ip = namei(path)) == 0){
    8000502a:	854a                	mv	a0,s2
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	27e080e7          	jalr	638(ra) # 800042aa <namei>
    80005034:	c93d                	beqz	a0,800050aa <exec+0xc4>
    80005036:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	ab6080e7          	jalr	-1354(ra) # 80003aee <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005040:	04000713          	li	a4,64
    80005044:	4681                	li	a3,0
    80005046:	e5040613          	addi	a2,s0,-432
    8000504a:	4581                	li	a1,0
    8000504c:	8556                	mv	a0,s5
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	d54080e7          	jalr	-684(ra) # 80003da2 <readi>
    80005056:	04000793          	li	a5,64
    8000505a:	00f51a63          	bne	a0,a5,8000506e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000505e:	e5042703          	lw	a4,-432(s0)
    80005062:	464c47b7          	lui	a5,0x464c4
    80005066:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000506a:	04f70663          	beq	a4,a5,800050b6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000506e:	8556                	mv	a0,s5
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	ce0080e7          	jalr	-800(ra) # 80003d50 <iunlockput>
    end_op();
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	4d0080e7          	jalr	1232(ra) # 80004548 <end_op>
  }
  return -1;
    80005080:	557d                	li	a0,-1
}
    80005082:	21813083          	ld	ra,536(sp)
    80005086:	21013403          	ld	s0,528(sp)
    8000508a:	20813483          	ld	s1,520(sp)
    8000508e:	20013903          	ld	s2,512(sp)
    80005092:	79fe                	ld	s3,504(sp)
    80005094:	7a5e                	ld	s4,496(sp)
    80005096:	7abe                	ld	s5,488(sp)
    80005098:	7b1e                	ld	s6,480(sp)
    8000509a:	6bfe                	ld	s7,472(sp)
    8000509c:	6c5e                	ld	s8,464(sp)
    8000509e:	6cbe                	ld	s9,456(sp)
    800050a0:	6d1e                	ld	s10,448(sp)
    800050a2:	7dfa                	ld	s11,440(sp)
    800050a4:	22010113          	addi	sp,sp,544
    800050a8:	8082                	ret
    end_op();
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	49e080e7          	jalr	1182(ra) # 80004548 <end_op>
    return -1;
    800050b2:	557d                	li	a0,-1
    800050b4:	b7f9                	j	80005082 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050b6:	8526                	mv	a0,s1
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	9aa080e7          	jalr	-1622(ra) # 80001a62 <proc_pagetable>
    800050c0:	8b2a                	mv	s6,a0
    800050c2:	d555                	beqz	a0,8000506e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c4:	e7042783          	lw	a5,-400(s0)
    800050c8:	e8845703          	lhu	a4,-376(s0)
    800050cc:	c735                	beqz	a4,80005138 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050ce:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d0:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    800050d4:	6a05                	lui	s4,0x1
    800050d6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050da:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050de:	6d85                	lui	s11,0x1
    800050e0:	7d7d                	lui	s10,0xfffff
    800050e2:	ac1d                	j	80005318 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050e4:	00003517          	auipc	a0,0x3
    800050e8:	59450513          	addi	a0,a0,1428 # 80008678 <syscalls+0x2a8>
    800050ec:	ffffb097          	auipc	ra,0xffffb
    800050f0:	44e080e7          	jalr	1102(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050f4:	874a                	mv	a4,s2
    800050f6:	009c86bb          	addw	a3,s9,s1
    800050fa:	4581                	li	a1,0
    800050fc:	8556                	mv	a0,s5
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	ca4080e7          	jalr	-860(ra) # 80003da2 <readi>
    80005106:	2501                	sext.w	a0,a0
    80005108:	1aa91863          	bne	s2,a0,800052b8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000510c:	009d84bb          	addw	s1,s11,s1
    80005110:	013d09bb          	addw	s3,s10,s3
    80005114:	1f74f263          	bgeu	s1,s7,800052f8 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005118:	02049593          	slli	a1,s1,0x20
    8000511c:	9181                	srli	a1,a1,0x20
    8000511e:	95e2                	add	a1,a1,s8
    80005120:	855a                	mv	a0,s6
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	f82080e7          	jalr	-126(ra) # 800010a4 <walkaddr>
    8000512a:	862a                	mv	a2,a0
    if(pa == 0)
    8000512c:	dd45                	beqz	a0,800050e4 <exec+0xfe>
      n = PGSIZE;
    8000512e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005130:	fd49f2e3          	bgeu	s3,s4,800050f4 <exec+0x10e>
      n = sz - i;
    80005134:	894e                	mv	s2,s3
    80005136:	bf7d                	j	800050f4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005138:	4481                	li	s1,0
  iunlockput(ip);
    8000513a:	8556                	mv	a0,s5
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	c14080e7          	jalr	-1004(ra) # 80003d50 <iunlockput>
  end_op();
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	404080e7          	jalr	1028(ra) # 80004548 <end_op>
  p = myproc();
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	852080e7          	jalr	-1966(ra) # 8000199e <myproc>
    80005154:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005156:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000515a:	6785                	lui	a5,0x1
    8000515c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000515e:	97a6                	add	a5,a5,s1
    80005160:	777d                	lui	a4,0xfffff
    80005162:	8ff9                	and	a5,a5,a4
    80005164:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005168:	6609                	lui	a2,0x2
    8000516a:	963e                	add	a2,a2,a5
    8000516c:	85be                	mv	a1,a5
    8000516e:	855a                	mv	a0,s6
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	2ba080e7          	jalr	698(ra) # 8000142a <uvmalloc>
    80005178:	8c2a                	mv	s8,a0
  ip = 0;
    8000517a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000517c:	12050e63          	beqz	a0,800052b8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005180:	75f9                	lui	a1,0xffffe
    80005182:	95aa                	add	a1,a1,a0
    80005184:	855a                	mv	a0,s6
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	4aa080e7          	jalr	1194(ra) # 80001630 <uvmclear>
  stackbase = sp - PGSIZE;
    8000518e:	7afd                	lui	s5,0xfffff
    80005190:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005192:	df043783          	ld	a5,-528(s0)
    80005196:	6388                	ld	a0,0(a5)
    80005198:	c925                	beqz	a0,80005208 <exec+0x222>
    8000519a:	e9040993          	addi	s3,s0,-368
    8000519e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051a2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051a4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051a6:	ffffc097          	auipc	ra,0xffffc
    800051aa:	cf4080e7          	jalr	-780(ra) # 80000e9a <strlen>
    800051ae:	0015079b          	addiw	a5,a0,1
    800051b2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051b6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051ba:	13596363          	bltu	s2,s5,800052e0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051be:	df043d83          	ld	s11,-528(s0)
    800051c2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051c6:	8552                	mv	a0,s4
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	cd2080e7          	jalr	-814(ra) # 80000e9a <strlen>
    800051d0:	0015069b          	addiw	a3,a0,1
    800051d4:	8652                	mv	a2,s4
    800051d6:	85ca                	mv	a1,s2
    800051d8:	855a                	mv	a0,s6
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	488080e7          	jalr	1160(ra) # 80001662 <copyout>
    800051e2:	10054363          	bltz	a0,800052e8 <exec+0x302>
    ustack[argc] = sp;
    800051e6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051ea:	0485                	addi	s1,s1,1
    800051ec:	008d8793          	addi	a5,s11,8
    800051f0:	def43823          	sd	a5,-528(s0)
    800051f4:	008db503          	ld	a0,8(s11)
    800051f8:	c911                	beqz	a0,8000520c <exec+0x226>
    if(argc >= MAXARG)
    800051fa:	09a1                	addi	s3,s3,8
    800051fc:	fb3c95e3          	bne	s9,s3,800051a6 <exec+0x1c0>
  sz = sz1;
    80005200:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005204:	4a81                	li	s5,0
    80005206:	a84d                	j	800052b8 <exec+0x2d2>
  sp = sz;
    80005208:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000520a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000520c:	00349793          	slli	a5,s1,0x3
    80005210:	f9078793          	addi	a5,a5,-112
    80005214:	97a2                	add	a5,a5,s0
    80005216:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000521a:	00148693          	addi	a3,s1,1
    8000521e:	068e                	slli	a3,a3,0x3
    80005220:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005224:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005228:	01597663          	bgeu	s2,s5,80005234 <exec+0x24e>
  sz = sz1;
    8000522c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005230:	4a81                	li	s5,0
    80005232:	a059                	j	800052b8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005234:	e9040613          	addi	a2,s0,-368
    80005238:	85ca                	mv	a1,s2
    8000523a:	855a                	mv	a0,s6
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	426080e7          	jalr	1062(ra) # 80001662 <copyout>
    80005244:	0a054663          	bltz	a0,800052f0 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005248:	060bb783          	ld	a5,96(s7)
    8000524c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005250:	de843783          	ld	a5,-536(s0)
    80005254:	0007c703          	lbu	a4,0(a5)
    80005258:	cf11                	beqz	a4,80005274 <exec+0x28e>
    8000525a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000525c:	02f00693          	li	a3,47
    80005260:	a039                	j	8000526e <exec+0x288>
      last = s+1;
    80005262:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005266:	0785                	addi	a5,a5,1
    80005268:	fff7c703          	lbu	a4,-1(a5)
    8000526c:	c701                	beqz	a4,80005274 <exec+0x28e>
    if(*s == '/')
    8000526e:	fed71ce3          	bne	a4,a3,80005266 <exec+0x280>
    80005272:	bfc5                	j	80005262 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005274:	4641                	li	a2,16
    80005276:	de843583          	ld	a1,-536(s0)
    8000527a:	160b8513          	addi	a0,s7,352
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	bea080e7          	jalr	-1046(ra) # 80000e68 <safestrcpy>
  oldpagetable = p->pagetable;
    80005286:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    8000528a:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    8000528e:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005292:	060bb783          	ld	a5,96(s7)
    80005296:	e6843703          	ld	a4,-408(s0)
    8000529a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000529c:	060bb783          	ld	a5,96(s7)
    800052a0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052a4:	85ea                	mv	a1,s10
    800052a6:	ffffd097          	auipc	ra,0xffffd
    800052aa:	858080e7          	jalr	-1960(ra) # 80001afe <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052ae:	0004851b          	sext.w	a0,s1
    800052b2:	bbc1                	j	80005082 <exec+0x9c>
    800052b4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052b8:	df843583          	ld	a1,-520(s0)
    800052bc:	855a                	mv	a0,s6
    800052be:	ffffd097          	auipc	ra,0xffffd
    800052c2:	840080e7          	jalr	-1984(ra) # 80001afe <proc_freepagetable>
  if(ip){
    800052c6:	da0a94e3          	bnez	s5,8000506e <exec+0x88>
  return -1;
    800052ca:	557d                	li	a0,-1
    800052cc:	bb5d                	j	80005082 <exec+0x9c>
    800052ce:	de943c23          	sd	s1,-520(s0)
    800052d2:	b7dd                	j	800052b8 <exec+0x2d2>
    800052d4:	de943c23          	sd	s1,-520(s0)
    800052d8:	b7c5                	j	800052b8 <exec+0x2d2>
    800052da:	de943c23          	sd	s1,-520(s0)
    800052de:	bfe9                	j	800052b8 <exec+0x2d2>
  sz = sz1;
    800052e0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052e4:	4a81                	li	s5,0
    800052e6:	bfc9                	j	800052b8 <exec+0x2d2>
  sz = sz1;
    800052e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ec:	4a81                	li	s5,0
    800052ee:	b7e9                	j	800052b8 <exec+0x2d2>
  sz = sz1;
    800052f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052f4:	4a81                	li	s5,0
    800052f6:	b7c9                	j	800052b8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052f8:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052fc:	e0843783          	ld	a5,-504(s0)
    80005300:	0017869b          	addiw	a3,a5,1
    80005304:	e0d43423          	sd	a3,-504(s0)
    80005308:	e0043783          	ld	a5,-512(s0)
    8000530c:	0387879b          	addiw	a5,a5,56
    80005310:	e8845703          	lhu	a4,-376(s0)
    80005314:	e2e6d3e3          	bge	a3,a4,8000513a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005318:	2781                	sext.w	a5,a5
    8000531a:	e0f43023          	sd	a5,-512(s0)
    8000531e:	03800713          	li	a4,56
    80005322:	86be                	mv	a3,a5
    80005324:	e1840613          	addi	a2,s0,-488
    80005328:	4581                	li	a1,0
    8000532a:	8556                	mv	a0,s5
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	a76080e7          	jalr	-1418(ra) # 80003da2 <readi>
    80005334:	03800793          	li	a5,56
    80005338:	f6f51ee3          	bne	a0,a5,800052b4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000533c:	e1842783          	lw	a5,-488(s0)
    80005340:	4705                	li	a4,1
    80005342:	fae79de3          	bne	a5,a4,800052fc <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005346:	e4043603          	ld	a2,-448(s0)
    8000534a:	e3843783          	ld	a5,-456(s0)
    8000534e:	f8f660e3          	bltu	a2,a5,800052ce <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005352:	e2843783          	ld	a5,-472(s0)
    80005356:	963e                	add	a2,a2,a5
    80005358:	f6f66ee3          	bltu	a2,a5,800052d4 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000535c:	85a6                	mv	a1,s1
    8000535e:	855a                	mv	a0,s6
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	0ca080e7          	jalr	202(ra) # 8000142a <uvmalloc>
    80005368:	dea43c23          	sd	a0,-520(s0)
    8000536c:	d53d                	beqz	a0,800052da <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000536e:	e2843c03          	ld	s8,-472(s0)
    80005372:	de043783          	ld	a5,-544(s0)
    80005376:	00fc77b3          	and	a5,s8,a5
    8000537a:	ff9d                	bnez	a5,800052b8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000537c:	e2042c83          	lw	s9,-480(s0)
    80005380:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005384:	f60b8ae3          	beqz	s7,800052f8 <exec+0x312>
    80005388:	89de                	mv	s3,s7
    8000538a:	4481                	li	s1,0
    8000538c:	b371                	j	80005118 <exec+0x132>

000000008000538e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000538e:	7179                	addi	sp,sp,-48
    80005390:	f406                	sd	ra,40(sp)
    80005392:	f022                	sd	s0,32(sp)
    80005394:	ec26                	sd	s1,24(sp)
    80005396:	e84a                	sd	s2,16(sp)
    80005398:	1800                	addi	s0,sp,48
    8000539a:	892e                	mv	s2,a1
    8000539c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000539e:	fdc40593          	addi	a1,s0,-36
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	ab4080e7          	jalr	-1356(ra) # 80002e56 <argint>
    800053aa:	04054063          	bltz	a0,800053ea <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053ae:	fdc42703          	lw	a4,-36(s0)
    800053b2:	47bd                	li	a5,15
    800053b4:	02e7ed63          	bltu	a5,a4,800053ee <argfd+0x60>
    800053b8:	ffffc097          	auipc	ra,0xffffc
    800053bc:	5e6080e7          	jalr	1510(ra) # 8000199e <myproc>
    800053c0:	fdc42703          	lw	a4,-36(s0)
    800053c4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    800053c8:	078e                	slli	a5,a5,0x3
    800053ca:	953e                	add	a0,a0,a5
    800053cc:	651c                	ld	a5,8(a0)
    800053ce:	c395                	beqz	a5,800053f2 <argfd+0x64>
    return -1;
  if(pfd)
    800053d0:	00090463          	beqz	s2,800053d8 <argfd+0x4a>
    *pfd = fd;
    800053d4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053d8:	4501                	li	a0,0
  if(pf)
    800053da:	c091                	beqz	s1,800053de <argfd+0x50>
    *pf = f;
    800053dc:	e09c                	sd	a5,0(s1)
}
    800053de:	70a2                	ld	ra,40(sp)
    800053e0:	7402                	ld	s0,32(sp)
    800053e2:	64e2                	ld	s1,24(sp)
    800053e4:	6942                	ld	s2,16(sp)
    800053e6:	6145                	addi	sp,sp,48
    800053e8:	8082                	ret
    return -1;
    800053ea:	557d                	li	a0,-1
    800053ec:	bfcd                	j	800053de <argfd+0x50>
    return -1;
    800053ee:	557d                	li	a0,-1
    800053f0:	b7fd                	j	800053de <argfd+0x50>
    800053f2:	557d                	li	a0,-1
    800053f4:	b7ed                	j	800053de <argfd+0x50>

00000000800053f6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053f6:	1101                	addi	sp,sp,-32
    800053f8:	ec06                	sd	ra,24(sp)
    800053fa:	e822                	sd	s0,16(sp)
    800053fc:	e426                	sd	s1,8(sp)
    800053fe:	1000                	addi	s0,sp,32
    80005400:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	59c080e7          	jalr	1436(ra) # 8000199e <myproc>
    8000540a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000540c:	0d850793          	addi	a5,a0,216
    80005410:	4501                	li	a0,0
    80005412:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005414:	6398                	ld	a4,0(a5)
    80005416:	cb19                	beqz	a4,8000542c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005418:	2505                	addiw	a0,a0,1
    8000541a:	07a1                	addi	a5,a5,8
    8000541c:	fed51ce3          	bne	a0,a3,80005414 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005420:	557d                	li	a0,-1
}
    80005422:	60e2                	ld	ra,24(sp)
    80005424:	6442                	ld	s0,16(sp)
    80005426:	64a2                	ld	s1,8(sp)
    80005428:	6105                	addi	sp,sp,32
    8000542a:	8082                	ret
      p->ofile[fd] = f;
    8000542c:	01a50793          	addi	a5,a0,26
    80005430:	078e                	slli	a5,a5,0x3
    80005432:	963e                	add	a2,a2,a5
    80005434:	e604                	sd	s1,8(a2)
      return fd;
    80005436:	b7f5                	j	80005422 <fdalloc+0x2c>

0000000080005438 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005438:	715d                	addi	sp,sp,-80
    8000543a:	e486                	sd	ra,72(sp)
    8000543c:	e0a2                	sd	s0,64(sp)
    8000543e:	fc26                	sd	s1,56(sp)
    80005440:	f84a                	sd	s2,48(sp)
    80005442:	f44e                	sd	s3,40(sp)
    80005444:	f052                	sd	s4,32(sp)
    80005446:	ec56                	sd	s5,24(sp)
    80005448:	0880                	addi	s0,sp,80
    8000544a:	89ae                	mv	s3,a1
    8000544c:	8ab2                	mv	s5,a2
    8000544e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005450:	fb040593          	addi	a1,s0,-80
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	e74080e7          	jalr	-396(ra) # 800042c8 <nameiparent>
    8000545c:	892a                	mv	s2,a0
    8000545e:	12050e63          	beqz	a0,8000559a <create+0x162>
    return 0;

  ilock(dp);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	68c080e7          	jalr	1676(ra) # 80003aee <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000546a:	4601                	li	a2,0
    8000546c:	fb040593          	addi	a1,s0,-80
    80005470:	854a                	mv	a0,s2
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	b60080e7          	jalr	-1184(ra) # 80003fd2 <dirlookup>
    8000547a:	84aa                	mv	s1,a0
    8000547c:	c921                	beqz	a0,800054cc <create+0x94>
    iunlockput(dp);
    8000547e:	854a                	mv	a0,s2
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	8d0080e7          	jalr	-1840(ra) # 80003d50 <iunlockput>
    ilock(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	664080e7          	jalr	1636(ra) # 80003aee <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005492:	2981                	sext.w	s3,s3
    80005494:	4789                	li	a5,2
    80005496:	02f99463          	bne	s3,a5,800054be <create+0x86>
    8000549a:	0444d783          	lhu	a5,68(s1)
    8000549e:	37f9                	addiw	a5,a5,-2
    800054a0:	17c2                	slli	a5,a5,0x30
    800054a2:	93c1                	srli	a5,a5,0x30
    800054a4:	4705                	li	a4,1
    800054a6:	00f76c63          	bltu	a4,a5,800054be <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054aa:	8526                	mv	a0,s1
    800054ac:	60a6                	ld	ra,72(sp)
    800054ae:	6406                	ld	s0,64(sp)
    800054b0:	74e2                	ld	s1,56(sp)
    800054b2:	7942                	ld	s2,48(sp)
    800054b4:	79a2                	ld	s3,40(sp)
    800054b6:	7a02                	ld	s4,32(sp)
    800054b8:	6ae2                	ld	s5,24(sp)
    800054ba:	6161                	addi	sp,sp,80
    800054bc:	8082                	ret
    iunlockput(ip);
    800054be:	8526                	mv	a0,s1
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	890080e7          	jalr	-1904(ra) # 80003d50 <iunlockput>
    return 0;
    800054c8:	4481                	li	s1,0
    800054ca:	b7c5                	j	800054aa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054cc:	85ce                	mv	a1,s3
    800054ce:	00092503          	lw	a0,0(s2)
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	482080e7          	jalr	1154(ra) # 80003954 <ialloc>
    800054da:	84aa                	mv	s1,a0
    800054dc:	c521                	beqz	a0,80005524 <create+0xec>
  ilock(ip);
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	610080e7          	jalr	1552(ra) # 80003aee <ilock>
  ip->major = major;
    800054e6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054ea:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054ee:	4a05                	li	s4,1
    800054f0:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800054f4:	8526                	mv	a0,s1
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	52c080e7          	jalr	1324(ra) # 80003a22 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054fe:	2981                	sext.w	s3,s3
    80005500:	03498a63          	beq	s3,s4,80005534 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005504:	40d0                	lw	a2,4(s1)
    80005506:	fb040593          	addi	a1,s0,-80
    8000550a:	854a                	mv	a0,s2
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	cdc080e7          	jalr	-804(ra) # 800041e8 <dirlink>
    80005514:	06054b63          	bltz	a0,8000558a <create+0x152>
  iunlockput(dp);
    80005518:	854a                	mv	a0,s2
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	836080e7          	jalr	-1994(ra) # 80003d50 <iunlockput>
  return ip;
    80005522:	b761                	j	800054aa <create+0x72>
    panic("create: ialloc");
    80005524:	00003517          	auipc	a0,0x3
    80005528:	17450513          	addi	a0,a0,372 # 80008698 <syscalls+0x2c8>
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	00e080e7          	jalr	14(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005534:	04a95783          	lhu	a5,74(s2)
    80005538:	2785                	addiw	a5,a5,1
    8000553a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000553e:	854a                	mv	a0,s2
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	4e2080e7          	jalr	1250(ra) # 80003a22 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005548:	40d0                	lw	a2,4(s1)
    8000554a:	00003597          	auipc	a1,0x3
    8000554e:	15e58593          	addi	a1,a1,350 # 800086a8 <syscalls+0x2d8>
    80005552:	8526                	mv	a0,s1
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	c94080e7          	jalr	-876(ra) # 800041e8 <dirlink>
    8000555c:	00054f63          	bltz	a0,8000557a <create+0x142>
    80005560:	00492603          	lw	a2,4(s2)
    80005564:	00003597          	auipc	a1,0x3
    80005568:	14c58593          	addi	a1,a1,332 # 800086b0 <syscalls+0x2e0>
    8000556c:	8526                	mv	a0,s1
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	c7a080e7          	jalr	-902(ra) # 800041e8 <dirlink>
    80005576:	f80557e3          	bgez	a0,80005504 <create+0xcc>
      panic("create dots");
    8000557a:	00003517          	auipc	a0,0x3
    8000557e:	13e50513          	addi	a0,a0,318 # 800086b8 <syscalls+0x2e8>
    80005582:	ffffb097          	auipc	ra,0xffffb
    80005586:	fb8080e7          	jalr	-72(ra) # 8000053a <panic>
    panic("create: dirlink");
    8000558a:	00003517          	auipc	a0,0x3
    8000558e:	13e50513          	addi	a0,a0,318 # 800086c8 <syscalls+0x2f8>
    80005592:	ffffb097          	auipc	ra,0xffffb
    80005596:	fa8080e7          	jalr	-88(ra) # 8000053a <panic>
    return 0;
    8000559a:	84aa                	mv	s1,a0
    8000559c:	b739                	j	800054aa <create+0x72>

000000008000559e <sys_dup>:
{
    8000559e:	7179                	addi	sp,sp,-48
    800055a0:	f406                	sd	ra,40(sp)
    800055a2:	f022                	sd	s0,32(sp)
    800055a4:	ec26                	sd	s1,24(sp)
    800055a6:	e84a                	sd	s2,16(sp)
    800055a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055aa:	fd840613          	addi	a2,s0,-40
    800055ae:	4581                	li	a1,0
    800055b0:	4501                	li	a0,0
    800055b2:	00000097          	auipc	ra,0x0
    800055b6:	ddc080e7          	jalr	-548(ra) # 8000538e <argfd>
    return -1;
    800055ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055bc:	02054363          	bltz	a0,800055e2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800055c0:	fd843903          	ld	s2,-40(s0)
    800055c4:	854a                	mv	a0,s2
    800055c6:	00000097          	auipc	ra,0x0
    800055ca:	e30080e7          	jalr	-464(ra) # 800053f6 <fdalloc>
    800055ce:	84aa                	mv	s1,a0
    return -1;
    800055d0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055d2:	00054863          	bltz	a0,800055e2 <sys_dup+0x44>
  filedup(f);
    800055d6:	854a                	mv	a0,s2
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	368080e7          	jalr	872(ra) # 80004940 <filedup>
  return fd;
    800055e0:	87a6                	mv	a5,s1
}
    800055e2:	853e                	mv	a0,a5
    800055e4:	70a2                	ld	ra,40(sp)
    800055e6:	7402                	ld	s0,32(sp)
    800055e8:	64e2                	ld	s1,24(sp)
    800055ea:	6942                	ld	s2,16(sp)
    800055ec:	6145                	addi	sp,sp,48
    800055ee:	8082                	ret

00000000800055f0 <sys_read>:
{
    800055f0:	7179                	addi	sp,sp,-48
    800055f2:	f406                	sd	ra,40(sp)
    800055f4:	f022                	sd	s0,32(sp)
    800055f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055f8:	fe840613          	addi	a2,s0,-24
    800055fc:	4581                	li	a1,0
    800055fe:	4501                	li	a0,0
    80005600:	00000097          	auipc	ra,0x0
    80005604:	d8e080e7          	jalr	-626(ra) # 8000538e <argfd>
    return -1;
    80005608:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560a:	04054163          	bltz	a0,8000564c <sys_read+0x5c>
    8000560e:	fe440593          	addi	a1,s0,-28
    80005612:	4509                	li	a0,2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	842080e7          	jalr	-1982(ra) # 80002e56 <argint>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000561e:	02054763          	bltz	a0,8000564c <sys_read+0x5c>
    80005622:	fd840593          	addi	a1,s0,-40
    80005626:	4505                	li	a0,1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	850080e7          	jalr	-1968(ra) # 80002e78 <argaddr>
    return -1;
    80005630:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005632:	00054d63          	bltz	a0,8000564c <sys_read+0x5c>
  return fileread(f, p, n);
    80005636:	fe442603          	lw	a2,-28(s0)
    8000563a:	fd843583          	ld	a1,-40(s0)
    8000563e:	fe843503          	ld	a0,-24(s0)
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	48a080e7          	jalr	1162(ra) # 80004acc <fileread>
    8000564a:	87aa                	mv	a5,a0
}
    8000564c:	853e                	mv	a0,a5
    8000564e:	70a2                	ld	ra,40(sp)
    80005650:	7402                	ld	s0,32(sp)
    80005652:	6145                	addi	sp,sp,48
    80005654:	8082                	ret

0000000080005656 <sys_write>:
{
    80005656:	7179                	addi	sp,sp,-48
    80005658:	f406                	sd	ra,40(sp)
    8000565a:	f022                	sd	s0,32(sp)
    8000565c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000565e:	fe840613          	addi	a2,s0,-24
    80005662:	4581                	li	a1,0
    80005664:	4501                	li	a0,0
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	d28080e7          	jalr	-728(ra) # 8000538e <argfd>
    return -1;
    8000566e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005670:	04054163          	bltz	a0,800056b2 <sys_write+0x5c>
    80005674:	fe440593          	addi	a1,s0,-28
    80005678:	4509                	li	a0,2
    8000567a:	ffffd097          	auipc	ra,0xffffd
    8000567e:	7dc080e7          	jalr	2012(ra) # 80002e56 <argint>
    return -1;
    80005682:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005684:	02054763          	bltz	a0,800056b2 <sys_write+0x5c>
    80005688:	fd840593          	addi	a1,s0,-40
    8000568c:	4505                	li	a0,1
    8000568e:	ffffd097          	auipc	ra,0xffffd
    80005692:	7ea080e7          	jalr	2026(ra) # 80002e78 <argaddr>
    return -1;
    80005696:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005698:	00054d63          	bltz	a0,800056b2 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000569c:	fe442603          	lw	a2,-28(s0)
    800056a0:	fd843583          	ld	a1,-40(s0)
    800056a4:	fe843503          	ld	a0,-24(s0)
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	4e6080e7          	jalr	1254(ra) # 80004b8e <filewrite>
    800056b0:	87aa                	mv	a5,a0
}
    800056b2:	853e                	mv	a0,a5
    800056b4:	70a2                	ld	ra,40(sp)
    800056b6:	7402                	ld	s0,32(sp)
    800056b8:	6145                	addi	sp,sp,48
    800056ba:	8082                	ret

00000000800056bc <sys_close>:
{
    800056bc:	1101                	addi	sp,sp,-32
    800056be:	ec06                	sd	ra,24(sp)
    800056c0:	e822                	sd	s0,16(sp)
    800056c2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056c4:	fe040613          	addi	a2,s0,-32
    800056c8:	fec40593          	addi	a1,s0,-20
    800056cc:	4501                	li	a0,0
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	cc0080e7          	jalr	-832(ra) # 8000538e <argfd>
    return -1;
    800056d6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056d8:	02054463          	bltz	a0,80005700 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056dc:	ffffc097          	auipc	ra,0xffffc
    800056e0:	2c2080e7          	jalr	706(ra) # 8000199e <myproc>
    800056e4:	fec42783          	lw	a5,-20(s0)
    800056e8:	07e9                	addi	a5,a5,26
    800056ea:	078e                	slli	a5,a5,0x3
    800056ec:	953e                	add	a0,a0,a5
    800056ee:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800056f2:	fe043503          	ld	a0,-32(s0)
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	29c080e7          	jalr	668(ra) # 80004992 <fileclose>
  return 0;
    800056fe:	4781                	li	a5,0
}
    80005700:	853e                	mv	a0,a5
    80005702:	60e2                	ld	ra,24(sp)
    80005704:	6442                	ld	s0,16(sp)
    80005706:	6105                	addi	sp,sp,32
    80005708:	8082                	ret

000000008000570a <sys_fstat>:
{
    8000570a:	1101                	addi	sp,sp,-32
    8000570c:	ec06                	sd	ra,24(sp)
    8000570e:	e822                	sd	s0,16(sp)
    80005710:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005712:	fe840613          	addi	a2,s0,-24
    80005716:	4581                	li	a1,0
    80005718:	4501                	li	a0,0
    8000571a:	00000097          	auipc	ra,0x0
    8000571e:	c74080e7          	jalr	-908(ra) # 8000538e <argfd>
    return -1;
    80005722:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005724:	02054563          	bltz	a0,8000574e <sys_fstat+0x44>
    80005728:	fe040593          	addi	a1,s0,-32
    8000572c:	4505                	li	a0,1
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	74a080e7          	jalr	1866(ra) # 80002e78 <argaddr>
    return -1;
    80005736:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005738:	00054b63          	bltz	a0,8000574e <sys_fstat+0x44>
  return filestat(f, st);
    8000573c:	fe043583          	ld	a1,-32(s0)
    80005740:	fe843503          	ld	a0,-24(s0)
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	316080e7          	jalr	790(ra) # 80004a5a <filestat>
    8000574c:	87aa                	mv	a5,a0
}
    8000574e:	853e                	mv	a0,a5
    80005750:	60e2                	ld	ra,24(sp)
    80005752:	6442                	ld	s0,16(sp)
    80005754:	6105                	addi	sp,sp,32
    80005756:	8082                	ret

0000000080005758 <sys_link>:
{
    80005758:	7169                	addi	sp,sp,-304
    8000575a:	f606                	sd	ra,296(sp)
    8000575c:	f222                	sd	s0,288(sp)
    8000575e:	ee26                	sd	s1,280(sp)
    80005760:	ea4a                	sd	s2,272(sp)
    80005762:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005764:	08000613          	li	a2,128
    80005768:	ed040593          	addi	a1,s0,-304
    8000576c:	4501                	li	a0,0
    8000576e:	ffffd097          	auipc	ra,0xffffd
    80005772:	72c080e7          	jalr	1836(ra) # 80002e9a <argstr>
    return -1;
    80005776:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005778:	10054e63          	bltz	a0,80005894 <sys_link+0x13c>
    8000577c:	08000613          	li	a2,128
    80005780:	f5040593          	addi	a1,s0,-176
    80005784:	4505                	li	a0,1
    80005786:	ffffd097          	auipc	ra,0xffffd
    8000578a:	714080e7          	jalr	1812(ra) # 80002e9a <argstr>
    return -1;
    8000578e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005790:	10054263          	bltz	a0,80005894 <sys_link+0x13c>
  begin_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	d36080e7          	jalr	-714(ra) # 800044ca <begin_op>
  if((ip = namei(old)) == 0){
    8000579c:	ed040513          	addi	a0,s0,-304
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	b0a080e7          	jalr	-1270(ra) # 800042aa <namei>
    800057a8:	84aa                	mv	s1,a0
    800057aa:	c551                	beqz	a0,80005836 <sys_link+0xde>
  ilock(ip);
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	342080e7          	jalr	834(ra) # 80003aee <ilock>
  if(ip->type == T_DIR){
    800057b4:	04449703          	lh	a4,68(s1)
    800057b8:	4785                	li	a5,1
    800057ba:	08f70463          	beq	a4,a5,80005842 <sys_link+0xea>
  ip->nlink++;
    800057be:	04a4d783          	lhu	a5,74(s1)
    800057c2:	2785                	addiw	a5,a5,1
    800057c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057c8:	8526                	mv	a0,s1
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	258080e7          	jalr	600(ra) # 80003a22 <iupdate>
  iunlock(ip);
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	3dc080e7          	jalr	988(ra) # 80003bb0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057dc:	fd040593          	addi	a1,s0,-48
    800057e0:	f5040513          	addi	a0,s0,-176
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	ae4080e7          	jalr	-1308(ra) # 800042c8 <nameiparent>
    800057ec:	892a                	mv	s2,a0
    800057ee:	c935                	beqz	a0,80005862 <sys_link+0x10a>
  ilock(dp);
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	2fe080e7          	jalr	766(ra) # 80003aee <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057f8:	00092703          	lw	a4,0(s2)
    800057fc:	409c                	lw	a5,0(s1)
    800057fe:	04f71d63          	bne	a4,a5,80005858 <sys_link+0x100>
    80005802:	40d0                	lw	a2,4(s1)
    80005804:	fd040593          	addi	a1,s0,-48
    80005808:	854a                	mv	a0,s2
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	9de080e7          	jalr	-1570(ra) # 800041e8 <dirlink>
    80005812:	04054363          	bltz	a0,80005858 <sys_link+0x100>
  iunlockput(dp);
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	538080e7          	jalr	1336(ra) # 80003d50 <iunlockput>
  iput(ip);
    80005820:	8526                	mv	a0,s1
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	486080e7          	jalr	1158(ra) # 80003ca8 <iput>
  end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	d1e080e7          	jalr	-738(ra) # 80004548 <end_op>
  return 0;
    80005832:	4781                	li	a5,0
    80005834:	a085                	j	80005894 <sys_link+0x13c>
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	d12080e7          	jalr	-750(ra) # 80004548 <end_op>
    return -1;
    8000583e:	57fd                	li	a5,-1
    80005840:	a891                	j	80005894 <sys_link+0x13c>
    iunlockput(ip);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	50c080e7          	jalr	1292(ra) # 80003d50 <iunlockput>
    end_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	cfc080e7          	jalr	-772(ra) # 80004548 <end_op>
    return -1;
    80005854:	57fd                	li	a5,-1
    80005856:	a83d                	j	80005894 <sys_link+0x13c>
    iunlockput(dp);
    80005858:	854a                	mv	a0,s2
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	4f6080e7          	jalr	1270(ra) # 80003d50 <iunlockput>
  ilock(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	28a080e7          	jalr	650(ra) # 80003aee <ilock>
  ip->nlink--;
    8000586c:	04a4d783          	lhu	a5,74(s1)
    80005870:	37fd                	addiw	a5,a5,-1
    80005872:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	1aa080e7          	jalr	426(ra) # 80003a22 <iupdate>
  iunlockput(ip);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	4ce080e7          	jalr	1230(ra) # 80003d50 <iunlockput>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	cbe080e7          	jalr	-834(ra) # 80004548 <end_op>
  return -1;
    80005892:	57fd                	li	a5,-1
}
    80005894:	853e                	mv	a0,a5
    80005896:	70b2                	ld	ra,296(sp)
    80005898:	7412                	ld	s0,288(sp)
    8000589a:	64f2                	ld	s1,280(sp)
    8000589c:	6952                	ld	s2,272(sp)
    8000589e:	6155                	addi	sp,sp,304
    800058a0:	8082                	ret

00000000800058a2 <sys_unlink>:
{
    800058a2:	7151                	addi	sp,sp,-240
    800058a4:	f586                	sd	ra,232(sp)
    800058a6:	f1a2                	sd	s0,224(sp)
    800058a8:	eda6                	sd	s1,216(sp)
    800058aa:	e9ca                	sd	s2,208(sp)
    800058ac:	e5ce                	sd	s3,200(sp)
    800058ae:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058b0:	08000613          	li	a2,128
    800058b4:	f3040593          	addi	a1,s0,-208
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	5e0080e7          	jalr	1504(ra) # 80002e9a <argstr>
    800058c2:	18054163          	bltz	a0,80005a44 <sys_unlink+0x1a2>
  begin_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	c04080e7          	jalr	-1020(ra) # 800044ca <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058ce:	fb040593          	addi	a1,s0,-80
    800058d2:	f3040513          	addi	a0,s0,-208
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	9f2080e7          	jalr	-1550(ra) # 800042c8 <nameiparent>
    800058de:	84aa                	mv	s1,a0
    800058e0:	c979                	beqz	a0,800059b6 <sys_unlink+0x114>
  ilock(dp);
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	20c080e7          	jalr	524(ra) # 80003aee <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058ea:	00003597          	auipc	a1,0x3
    800058ee:	dbe58593          	addi	a1,a1,-578 # 800086a8 <syscalls+0x2d8>
    800058f2:	fb040513          	addi	a0,s0,-80
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	6c2080e7          	jalr	1730(ra) # 80003fb8 <namecmp>
    800058fe:	14050a63          	beqz	a0,80005a52 <sys_unlink+0x1b0>
    80005902:	00003597          	auipc	a1,0x3
    80005906:	dae58593          	addi	a1,a1,-594 # 800086b0 <syscalls+0x2e0>
    8000590a:	fb040513          	addi	a0,s0,-80
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	6aa080e7          	jalr	1706(ra) # 80003fb8 <namecmp>
    80005916:	12050e63          	beqz	a0,80005a52 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000591a:	f2c40613          	addi	a2,s0,-212
    8000591e:	fb040593          	addi	a1,s0,-80
    80005922:	8526                	mv	a0,s1
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	6ae080e7          	jalr	1710(ra) # 80003fd2 <dirlookup>
    8000592c:	892a                	mv	s2,a0
    8000592e:	12050263          	beqz	a0,80005a52 <sys_unlink+0x1b0>
  ilock(ip);
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	1bc080e7          	jalr	444(ra) # 80003aee <ilock>
  if(ip->nlink < 1)
    8000593a:	04a91783          	lh	a5,74(s2)
    8000593e:	08f05263          	blez	a5,800059c2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005942:	04491703          	lh	a4,68(s2)
    80005946:	4785                	li	a5,1
    80005948:	08f70563          	beq	a4,a5,800059d2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000594c:	4641                	li	a2,16
    8000594e:	4581                	li	a1,0
    80005950:	fc040513          	addi	a0,s0,-64
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	3ca080e7          	jalr	970(ra) # 80000d1e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000595c:	4741                	li	a4,16
    8000595e:	f2c42683          	lw	a3,-212(s0)
    80005962:	fc040613          	addi	a2,s0,-64
    80005966:	4581                	li	a1,0
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	530080e7          	jalr	1328(ra) # 80003e9a <writei>
    80005972:	47c1                	li	a5,16
    80005974:	0af51563          	bne	a0,a5,80005a1e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005978:	04491703          	lh	a4,68(s2)
    8000597c:	4785                	li	a5,1
    8000597e:	0af70863          	beq	a4,a5,80005a2e <sys_unlink+0x18c>
  iunlockput(dp);
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	3cc080e7          	jalr	972(ra) # 80003d50 <iunlockput>
  ip->nlink--;
    8000598c:	04a95783          	lhu	a5,74(s2)
    80005990:	37fd                	addiw	a5,a5,-1
    80005992:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005996:	854a                	mv	a0,s2
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	08a080e7          	jalr	138(ra) # 80003a22 <iupdate>
  iunlockput(ip);
    800059a0:	854a                	mv	a0,s2
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	3ae080e7          	jalr	942(ra) # 80003d50 <iunlockput>
  end_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	b9e080e7          	jalr	-1122(ra) # 80004548 <end_op>
  return 0;
    800059b2:	4501                	li	a0,0
    800059b4:	a84d                	j	80005a66 <sys_unlink+0x1c4>
    end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	b92080e7          	jalr	-1134(ra) # 80004548 <end_op>
    return -1;
    800059be:	557d                	li	a0,-1
    800059c0:	a05d                	j	80005a66 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059c2:	00003517          	auipc	a0,0x3
    800059c6:	d1650513          	addi	a0,a0,-746 # 800086d8 <syscalls+0x308>
    800059ca:	ffffb097          	auipc	ra,0xffffb
    800059ce:	b70080e7          	jalr	-1168(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059d2:	04c92703          	lw	a4,76(s2)
    800059d6:	02000793          	li	a5,32
    800059da:	f6e7f9e3          	bgeu	a5,a4,8000594c <sys_unlink+0xaa>
    800059de:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059e2:	4741                	li	a4,16
    800059e4:	86ce                	mv	a3,s3
    800059e6:	f1840613          	addi	a2,s0,-232
    800059ea:	4581                	li	a1,0
    800059ec:	854a                	mv	a0,s2
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	3b4080e7          	jalr	948(ra) # 80003da2 <readi>
    800059f6:	47c1                	li	a5,16
    800059f8:	00f51b63          	bne	a0,a5,80005a0e <sys_unlink+0x16c>
    if(de.inum != 0)
    800059fc:	f1845783          	lhu	a5,-232(s0)
    80005a00:	e7a1                	bnez	a5,80005a48 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a02:	29c1                	addiw	s3,s3,16
    80005a04:	04c92783          	lw	a5,76(s2)
    80005a08:	fcf9ede3          	bltu	s3,a5,800059e2 <sys_unlink+0x140>
    80005a0c:	b781                	j	8000594c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a0e:	00003517          	auipc	a0,0x3
    80005a12:	ce250513          	addi	a0,a0,-798 # 800086f0 <syscalls+0x320>
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	b24080e7          	jalr	-1244(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005a1e:	00003517          	auipc	a0,0x3
    80005a22:	cea50513          	addi	a0,a0,-790 # 80008708 <syscalls+0x338>
    80005a26:	ffffb097          	auipc	ra,0xffffb
    80005a2a:	b14080e7          	jalr	-1260(ra) # 8000053a <panic>
    dp->nlink--;
    80005a2e:	04a4d783          	lhu	a5,74(s1)
    80005a32:	37fd                	addiw	a5,a5,-1
    80005a34:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	fe8080e7          	jalr	-24(ra) # 80003a22 <iupdate>
    80005a42:	b781                	j	80005982 <sys_unlink+0xe0>
    return -1;
    80005a44:	557d                	li	a0,-1
    80005a46:	a005                	j	80005a66 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a48:	854a                	mv	a0,s2
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	306080e7          	jalr	774(ra) # 80003d50 <iunlockput>
  iunlockput(dp);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	2fc080e7          	jalr	764(ra) # 80003d50 <iunlockput>
  end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	aec080e7          	jalr	-1300(ra) # 80004548 <end_op>
  return -1;
    80005a64:	557d                	li	a0,-1
}
    80005a66:	70ae                	ld	ra,232(sp)
    80005a68:	740e                	ld	s0,224(sp)
    80005a6a:	64ee                	ld	s1,216(sp)
    80005a6c:	694e                	ld	s2,208(sp)
    80005a6e:	69ae                	ld	s3,200(sp)
    80005a70:	616d                	addi	sp,sp,240
    80005a72:	8082                	ret

0000000080005a74 <sys_open>:

uint64
sys_open(void)
{
    80005a74:	7131                	addi	sp,sp,-192
    80005a76:	fd06                	sd	ra,184(sp)
    80005a78:	f922                	sd	s0,176(sp)
    80005a7a:	f526                	sd	s1,168(sp)
    80005a7c:	f14a                	sd	s2,160(sp)
    80005a7e:	ed4e                	sd	s3,152(sp)
    80005a80:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a82:	08000613          	li	a2,128
    80005a86:	f5040593          	addi	a1,s0,-176
    80005a8a:	4501                	li	a0,0
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	40e080e7          	jalr	1038(ra) # 80002e9a <argstr>
    return -1;
    80005a94:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a96:	0c054163          	bltz	a0,80005b58 <sys_open+0xe4>
    80005a9a:	f4c40593          	addi	a1,s0,-180
    80005a9e:	4505                	li	a0,1
    80005aa0:	ffffd097          	auipc	ra,0xffffd
    80005aa4:	3b6080e7          	jalr	950(ra) # 80002e56 <argint>
    80005aa8:	0a054863          	bltz	a0,80005b58 <sys_open+0xe4>

  begin_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	a1e080e7          	jalr	-1506(ra) # 800044ca <begin_op>

  if(omode & O_CREATE){
    80005ab4:	f4c42783          	lw	a5,-180(s0)
    80005ab8:	2007f793          	andi	a5,a5,512
    80005abc:	cbdd                	beqz	a5,80005b72 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005abe:	4681                	li	a3,0
    80005ac0:	4601                	li	a2,0
    80005ac2:	4589                	li	a1,2
    80005ac4:	f5040513          	addi	a0,s0,-176
    80005ac8:	00000097          	auipc	ra,0x0
    80005acc:	970080e7          	jalr	-1680(ra) # 80005438 <create>
    80005ad0:	892a                	mv	s2,a0
    if(ip == 0){
    80005ad2:	c959                	beqz	a0,80005b68 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ad4:	04491703          	lh	a4,68(s2)
    80005ad8:	478d                	li	a5,3
    80005ada:	00f71763          	bne	a4,a5,80005ae8 <sys_open+0x74>
    80005ade:	04695703          	lhu	a4,70(s2)
    80005ae2:	47a5                	li	a5,9
    80005ae4:	0ce7ec63          	bltu	a5,a4,80005bbc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	dee080e7          	jalr	-530(ra) # 800048d6 <filealloc>
    80005af0:	89aa                	mv	s3,a0
    80005af2:	10050263          	beqz	a0,80005bf6 <sys_open+0x182>
    80005af6:	00000097          	auipc	ra,0x0
    80005afa:	900080e7          	jalr	-1792(ra) # 800053f6 <fdalloc>
    80005afe:	84aa                	mv	s1,a0
    80005b00:	0e054663          	bltz	a0,80005bec <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b04:	04491703          	lh	a4,68(s2)
    80005b08:	478d                	li	a5,3
    80005b0a:	0cf70463          	beq	a4,a5,80005bd2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b0e:	4789                	li	a5,2
    80005b10:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b14:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b18:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b1c:	f4c42783          	lw	a5,-180(s0)
    80005b20:	0017c713          	xori	a4,a5,1
    80005b24:	8b05                	andi	a4,a4,1
    80005b26:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b2a:	0037f713          	andi	a4,a5,3
    80005b2e:	00e03733          	snez	a4,a4
    80005b32:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b36:	4007f793          	andi	a5,a5,1024
    80005b3a:	c791                	beqz	a5,80005b46 <sys_open+0xd2>
    80005b3c:	04491703          	lh	a4,68(s2)
    80005b40:	4789                	li	a5,2
    80005b42:	08f70f63          	beq	a4,a5,80005be0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b46:	854a                	mv	a0,s2
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	068080e7          	jalr	104(ra) # 80003bb0 <iunlock>
  end_op();
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	9f8080e7          	jalr	-1544(ra) # 80004548 <end_op>

  return fd;
}
    80005b58:	8526                	mv	a0,s1
    80005b5a:	70ea                	ld	ra,184(sp)
    80005b5c:	744a                	ld	s0,176(sp)
    80005b5e:	74aa                	ld	s1,168(sp)
    80005b60:	790a                	ld	s2,160(sp)
    80005b62:	69ea                	ld	s3,152(sp)
    80005b64:	6129                	addi	sp,sp,192
    80005b66:	8082                	ret
      end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	9e0080e7          	jalr	-1568(ra) # 80004548 <end_op>
      return -1;
    80005b70:	b7e5                	j	80005b58 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b72:	f5040513          	addi	a0,s0,-176
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	734080e7          	jalr	1844(ra) # 800042aa <namei>
    80005b7e:	892a                	mv	s2,a0
    80005b80:	c905                	beqz	a0,80005bb0 <sys_open+0x13c>
    ilock(ip);
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	f6c080e7          	jalr	-148(ra) # 80003aee <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b8a:	04491703          	lh	a4,68(s2)
    80005b8e:	4785                	li	a5,1
    80005b90:	f4f712e3          	bne	a4,a5,80005ad4 <sys_open+0x60>
    80005b94:	f4c42783          	lw	a5,-180(s0)
    80005b98:	dba1                	beqz	a5,80005ae8 <sys_open+0x74>
      iunlockput(ip);
    80005b9a:	854a                	mv	a0,s2
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	1b4080e7          	jalr	436(ra) # 80003d50 <iunlockput>
      end_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	9a4080e7          	jalr	-1628(ra) # 80004548 <end_op>
      return -1;
    80005bac:	54fd                	li	s1,-1
    80005bae:	b76d                	j	80005b58 <sys_open+0xe4>
      end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	998080e7          	jalr	-1640(ra) # 80004548 <end_op>
      return -1;
    80005bb8:	54fd                	li	s1,-1
    80005bba:	bf79                	j	80005b58 <sys_open+0xe4>
    iunlockput(ip);
    80005bbc:	854a                	mv	a0,s2
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	192080e7          	jalr	402(ra) # 80003d50 <iunlockput>
    end_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	982080e7          	jalr	-1662(ra) # 80004548 <end_op>
    return -1;
    80005bce:	54fd                	li	s1,-1
    80005bd0:	b761                	j	80005b58 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bd2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bd6:	04691783          	lh	a5,70(s2)
    80005bda:	02f99223          	sh	a5,36(s3)
    80005bde:	bf2d                	j	80005b18 <sys_open+0xa4>
    itrunc(ip);
    80005be0:	854a                	mv	a0,s2
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	01a080e7          	jalr	26(ra) # 80003bfc <itrunc>
    80005bea:	bfb1                	j	80005b46 <sys_open+0xd2>
      fileclose(f);
    80005bec:	854e                	mv	a0,s3
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	da4080e7          	jalr	-604(ra) # 80004992 <fileclose>
    iunlockput(ip);
    80005bf6:	854a                	mv	a0,s2
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	158080e7          	jalr	344(ra) # 80003d50 <iunlockput>
    end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	948080e7          	jalr	-1720(ra) # 80004548 <end_op>
    return -1;
    80005c08:	54fd                	li	s1,-1
    80005c0a:	b7b9                	j	80005b58 <sys_open+0xe4>

0000000080005c0c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c0c:	7175                	addi	sp,sp,-144
    80005c0e:	e506                	sd	ra,136(sp)
    80005c10:	e122                	sd	s0,128(sp)
    80005c12:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	8b6080e7          	jalr	-1866(ra) # 800044ca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c1c:	08000613          	li	a2,128
    80005c20:	f7040593          	addi	a1,s0,-144
    80005c24:	4501                	li	a0,0
    80005c26:	ffffd097          	auipc	ra,0xffffd
    80005c2a:	274080e7          	jalr	628(ra) # 80002e9a <argstr>
    80005c2e:	02054963          	bltz	a0,80005c60 <sys_mkdir+0x54>
    80005c32:	4681                	li	a3,0
    80005c34:	4601                	li	a2,0
    80005c36:	4585                	li	a1,1
    80005c38:	f7040513          	addi	a0,s0,-144
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	7fc080e7          	jalr	2044(ra) # 80005438 <create>
    80005c44:	cd11                	beqz	a0,80005c60 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	10a080e7          	jalr	266(ra) # 80003d50 <iunlockput>
  end_op();
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	8fa080e7          	jalr	-1798(ra) # 80004548 <end_op>
  return 0;
    80005c56:	4501                	li	a0,0
}
    80005c58:	60aa                	ld	ra,136(sp)
    80005c5a:	640a                	ld	s0,128(sp)
    80005c5c:	6149                	addi	sp,sp,144
    80005c5e:	8082                	ret
    end_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	8e8080e7          	jalr	-1816(ra) # 80004548 <end_op>
    return -1;
    80005c68:	557d                	li	a0,-1
    80005c6a:	b7fd                	j	80005c58 <sys_mkdir+0x4c>

0000000080005c6c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c6c:	7135                	addi	sp,sp,-160
    80005c6e:	ed06                	sd	ra,152(sp)
    80005c70:	e922                	sd	s0,144(sp)
    80005c72:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	856080e7          	jalr	-1962(ra) # 800044ca <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c7c:	08000613          	li	a2,128
    80005c80:	f7040593          	addi	a1,s0,-144
    80005c84:	4501                	li	a0,0
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	214080e7          	jalr	532(ra) # 80002e9a <argstr>
    80005c8e:	04054a63          	bltz	a0,80005ce2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c92:	f6c40593          	addi	a1,s0,-148
    80005c96:	4505                	li	a0,1
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	1be080e7          	jalr	446(ra) # 80002e56 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ca0:	04054163          	bltz	a0,80005ce2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ca4:	f6840593          	addi	a1,s0,-152
    80005ca8:	4509                	li	a0,2
    80005caa:	ffffd097          	auipc	ra,0xffffd
    80005cae:	1ac080e7          	jalr	428(ra) # 80002e56 <argint>
     argint(1, &major) < 0 ||
    80005cb2:	02054863          	bltz	a0,80005ce2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cb6:	f6841683          	lh	a3,-152(s0)
    80005cba:	f6c41603          	lh	a2,-148(s0)
    80005cbe:	458d                	li	a1,3
    80005cc0:	f7040513          	addi	a0,s0,-144
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	774080e7          	jalr	1908(ra) # 80005438 <create>
     argint(2, &minor) < 0 ||
    80005ccc:	c919                	beqz	a0,80005ce2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	082080e7          	jalr	130(ra) # 80003d50 <iunlockput>
  end_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	872080e7          	jalr	-1934(ra) # 80004548 <end_op>
  return 0;
    80005cde:	4501                	li	a0,0
    80005ce0:	a031                	j	80005cec <sys_mknod+0x80>
    end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	866080e7          	jalr	-1946(ra) # 80004548 <end_op>
    return -1;
    80005cea:	557d                	li	a0,-1
}
    80005cec:	60ea                	ld	ra,152(sp)
    80005cee:	644a                	ld	s0,144(sp)
    80005cf0:	610d                	addi	sp,sp,160
    80005cf2:	8082                	ret

0000000080005cf4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cf4:	7135                	addi	sp,sp,-160
    80005cf6:	ed06                	sd	ra,152(sp)
    80005cf8:	e922                	sd	s0,144(sp)
    80005cfa:	e526                	sd	s1,136(sp)
    80005cfc:	e14a                	sd	s2,128(sp)
    80005cfe:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	c9e080e7          	jalr	-866(ra) # 8000199e <myproc>
    80005d08:	892a                	mv	s2,a0
  
  begin_op();
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	7c0080e7          	jalr	1984(ra) # 800044ca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d12:	08000613          	li	a2,128
    80005d16:	f6040593          	addi	a1,s0,-160
    80005d1a:	4501                	li	a0,0
    80005d1c:	ffffd097          	auipc	ra,0xffffd
    80005d20:	17e080e7          	jalr	382(ra) # 80002e9a <argstr>
    80005d24:	04054b63          	bltz	a0,80005d7a <sys_chdir+0x86>
    80005d28:	f6040513          	addi	a0,s0,-160
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	57e080e7          	jalr	1406(ra) # 800042aa <namei>
    80005d34:	84aa                	mv	s1,a0
    80005d36:	c131                	beqz	a0,80005d7a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	db6080e7          	jalr	-586(ra) # 80003aee <ilock>
  if(ip->type != T_DIR){
    80005d40:	04449703          	lh	a4,68(s1)
    80005d44:	4785                	li	a5,1
    80005d46:	04f71063          	bne	a4,a5,80005d86 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d4a:	8526                	mv	a0,s1
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	e64080e7          	jalr	-412(ra) # 80003bb0 <iunlock>
  iput(p->cwd);
    80005d54:	15893503          	ld	a0,344(s2)
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	f50080e7          	jalr	-176(ra) # 80003ca8 <iput>
  end_op();
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	7e8080e7          	jalr	2024(ra) # 80004548 <end_op>
  p->cwd = ip;
    80005d68:	14993c23          	sd	s1,344(s2)
  return 0;
    80005d6c:	4501                	li	a0,0
}
    80005d6e:	60ea                	ld	ra,152(sp)
    80005d70:	644a                	ld	s0,144(sp)
    80005d72:	64aa                	ld	s1,136(sp)
    80005d74:	690a                	ld	s2,128(sp)
    80005d76:	610d                	addi	sp,sp,160
    80005d78:	8082                	ret
    end_op();
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	7ce080e7          	jalr	1998(ra) # 80004548 <end_op>
    return -1;
    80005d82:	557d                	li	a0,-1
    80005d84:	b7ed                	j	80005d6e <sys_chdir+0x7a>
    iunlockput(ip);
    80005d86:	8526                	mv	a0,s1
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	fc8080e7          	jalr	-56(ra) # 80003d50 <iunlockput>
    end_op();
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	7b8080e7          	jalr	1976(ra) # 80004548 <end_op>
    return -1;
    80005d98:	557d                	li	a0,-1
    80005d9a:	bfd1                	j	80005d6e <sys_chdir+0x7a>

0000000080005d9c <sys_exec>:

uint64
sys_exec(void)
{
    80005d9c:	7145                	addi	sp,sp,-464
    80005d9e:	e786                	sd	ra,456(sp)
    80005da0:	e3a2                	sd	s0,448(sp)
    80005da2:	ff26                	sd	s1,440(sp)
    80005da4:	fb4a                	sd	s2,432(sp)
    80005da6:	f74e                	sd	s3,424(sp)
    80005da8:	f352                	sd	s4,416(sp)
    80005daa:	ef56                	sd	s5,408(sp)
    80005dac:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dae:	08000613          	li	a2,128
    80005db2:	f4040593          	addi	a1,s0,-192
    80005db6:	4501                	li	a0,0
    80005db8:	ffffd097          	auipc	ra,0xffffd
    80005dbc:	0e2080e7          	jalr	226(ra) # 80002e9a <argstr>
    return -1;
    80005dc0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dc2:	0c054b63          	bltz	a0,80005e98 <sys_exec+0xfc>
    80005dc6:	e3840593          	addi	a1,s0,-456
    80005dca:	4505                	li	a0,1
    80005dcc:	ffffd097          	auipc	ra,0xffffd
    80005dd0:	0ac080e7          	jalr	172(ra) # 80002e78 <argaddr>
    80005dd4:	0c054263          	bltz	a0,80005e98 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005dd8:	10000613          	li	a2,256
    80005ddc:	4581                	li	a1,0
    80005dde:	e4040513          	addi	a0,s0,-448
    80005de2:	ffffb097          	auipc	ra,0xffffb
    80005de6:	f3c080e7          	jalr	-196(ra) # 80000d1e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dee:	89a6                	mv	s3,s1
    80005df0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005df2:	02000a13          	li	s4,32
    80005df6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dfa:	00391513          	slli	a0,s2,0x3
    80005dfe:	e3040593          	addi	a1,s0,-464
    80005e02:	e3843783          	ld	a5,-456(s0)
    80005e06:	953e                	add	a0,a0,a5
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	fb4080e7          	jalr	-76(ra) # 80002dbc <fetchaddr>
    80005e10:	02054a63          	bltz	a0,80005e44 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e14:	e3043783          	ld	a5,-464(s0)
    80005e18:	c3b9                	beqz	a5,80005e5e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e1a:	ffffb097          	auipc	ra,0xffffb
    80005e1e:	cc6080e7          	jalr	-826(ra) # 80000ae0 <kalloc>
    80005e22:	85aa                	mv	a1,a0
    80005e24:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e28:	cd11                	beqz	a0,80005e44 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e2a:	6605                	lui	a2,0x1
    80005e2c:	e3043503          	ld	a0,-464(s0)
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	fde080e7          	jalr	-34(ra) # 80002e0e <fetchstr>
    80005e38:	00054663          	bltz	a0,80005e44 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e3c:	0905                	addi	s2,s2,1
    80005e3e:	09a1                	addi	s3,s3,8
    80005e40:	fb491be3          	bne	s2,s4,80005df6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e44:	f4040913          	addi	s2,s0,-192
    80005e48:	6088                	ld	a0,0(s1)
    80005e4a:	c531                	beqz	a0,80005e96 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e4c:	ffffb097          	auipc	ra,0xffffb
    80005e50:	b96080e7          	jalr	-1130(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e54:	04a1                	addi	s1,s1,8
    80005e56:	ff2499e3          	bne	s1,s2,80005e48 <sys_exec+0xac>
  return -1;
    80005e5a:	597d                	li	s2,-1
    80005e5c:	a835                	j	80005e98 <sys_exec+0xfc>
      argv[i] = 0;
    80005e5e:	0a8e                	slli	s5,s5,0x3
    80005e60:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005e64:	00878ab3          	add	s5,a5,s0
    80005e68:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e6c:	e4040593          	addi	a1,s0,-448
    80005e70:	f4040513          	addi	a0,s0,-192
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	172080e7          	jalr	370(ra) # 80004fe6 <exec>
    80005e7c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e7e:	f4040993          	addi	s3,s0,-192
    80005e82:	6088                	ld	a0,0(s1)
    80005e84:	c911                	beqz	a0,80005e98 <sys_exec+0xfc>
    kfree(argv[i]);
    80005e86:	ffffb097          	auipc	ra,0xffffb
    80005e8a:	b5c080e7          	jalr	-1188(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e8e:	04a1                	addi	s1,s1,8
    80005e90:	ff3499e3          	bne	s1,s3,80005e82 <sys_exec+0xe6>
    80005e94:	a011                	j	80005e98 <sys_exec+0xfc>
  return -1;
    80005e96:	597d                	li	s2,-1
}
    80005e98:	854a                	mv	a0,s2
    80005e9a:	60be                	ld	ra,456(sp)
    80005e9c:	641e                	ld	s0,448(sp)
    80005e9e:	74fa                	ld	s1,440(sp)
    80005ea0:	795a                	ld	s2,432(sp)
    80005ea2:	79ba                	ld	s3,424(sp)
    80005ea4:	7a1a                	ld	s4,416(sp)
    80005ea6:	6afa                	ld	s5,408(sp)
    80005ea8:	6179                	addi	sp,sp,464
    80005eaa:	8082                	ret

0000000080005eac <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eac:	7139                	addi	sp,sp,-64
    80005eae:	fc06                	sd	ra,56(sp)
    80005eb0:	f822                	sd	s0,48(sp)
    80005eb2:	f426                	sd	s1,40(sp)
    80005eb4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005eb6:	ffffc097          	auipc	ra,0xffffc
    80005eba:	ae8080e7          	jalr	-1304(ra) # 8000199e <myproc>
    80005ebe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ec0:	fd840593          	addi	a1,s0,-40
    80005ec4:	4501                	li	a0,0
    80005ec6:	ffffd097          	auipc	ra,0xffffd
    80005eca:	fb2080e7          	jalr	-78(ra) # 80002e78 <argaddr>
    return -1;
    80005ece:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ed0:	0e054063          	bltz	a0,80005fb0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ed4:	fc840593          	addi	a1,s0,-56
    80005ed8:	fd040513          	addi	a0,s0,-48
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	de6080e7          	jalr	-538(ra) # 80004cc2 <pipealloc>
    return -1;
    80005ee4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ee6:	0c054563          	bltz	a0,80005fb0 <sys_pipe+0x104>
  fd0 = -1;
    80005eea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eee:	fd043503          	ld	a0,-48(s0)
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	504080e7          	jalr	1284(ra) # 800053f6 <fdalloc>
    80005efa:	fca42223          	sw	a0,-60(s0)
    80005efe:	08054c63          	bltz	a0,80005f96 <sys_pipe+0xea>
    80005f02:	fc843503          	ld	a0,-56(s0)
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	4f0080e7          	jalr	1264(ra) # 800053f6 <fdalloc>
    80005f0e:	fca42023          	sw	a0,-64(s0)
    80005f12:	06054963          	bltz	a0,80005f84 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f16:	4691                	li	a3,4
    80005f18:	fc440613          	addi	a2,s0,-60
    80005f1c:	fd843583          	ld	a1,-40(s0)
    80005f20:	6ca8                	ld	a0,88(s1)
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	740080e7          	jalr	1856(ra) # 80001662 <copyout>
    80005f2a:	02054063          	bltz	a0,80005f4a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f2e:	4691                	li	a3,4
    80005f30:	fc040613          	addi	a2,s0,-64
    80005f34:	fd843583          	ld	a1,-40(s0)
    80005f38:	0591                	addi	a1,a1,4
    80005f3a:	6ca8                	ld	a0,88(s1)
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	726080e7          	jalr	1830(ra) # 80001662 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f46:	06055563          	bgez	a0,80005fb0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f4a:	fc442783          	lw	a5,-60(s0)
    80005f4e:	07e9                	addi	a5,a5,26
    80005f50:	078e                	slli	a5,a5,0x3
    80005f52:	97a6                	add	a5,a5,s1
    80005f54:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f58:	fc042783          	lw	a5,-64(s0)
    80005f5c:	07e9                	addi	a5,a5,26
    80005f5e:	078e                	slli	a5,a5,0x3
    80005f60:	00f48533          	add	a0,s1,a5
    80005f64:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f68:	fd043503          	ld	a0,-48(s0)
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	a26080e7          	jalr	-1498(ra) # 80004992 <fileclose>
    fileclose(wf);
    80005f74:	fc843503          	ld	a0,-56(s0)
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	a1a080e7          	jalr	-1510(ra) # 80004992 <fileclose>
    return -1;
    80005f80:	57fd                	li	a5,-1
    80005f82:	a03d                	j	80005fb0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f84:	fc442783          	lw	a5,-60(s0)
    80005f88:	0007c763          	bltz	a5,80005f96 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f8c:	07e9                	addi	a5,a5,26
    80005f8e:	078e                	slli	a5,a5,0x3
    80005f90:	97a6                	add	a5,a5,s1
    80005f92:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005f96:	fd043503          	ld	a0,-48(s0)
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	9f8080e7          	jalr	-1544(ra) # 80004992 <fileclose>
    fileclose(wf);
    80005fa2:	fc843503          	ld	a0,-56(s0)
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	9ec080e7          	jalr	-1556(ra) # 80004992 <fileclose>
    return -1;
    80005fae:	57fd                	li	a5,-1
}
    80005fb0:	853e                	mv	a0,a5
    80005fb2:	70e2                	ld	ra,56(sp)
    80005fb4:	7442                	ld	s0,48(sp)
    80005fb6:	74a2                	ld	s1,40(sp)
    80005fb8:	6121                	addi	sp,sp,64
    80005fba:	8082                	ret
    80005fbc:	0000                	unimp
	...

0000000080005fc0 <kernelvec>:
    80005fc0:	7111                	addi	sp,sp,-256
    80005fc2:	e006                	sd	ra,0(sp)
    80005fc4:	e40a                	sd	sp,8(sp)
    80005fc6:	e80e                	sd	gp,16(sp)
    80005fc8:	ec12                	sd	tp,24(sp)
    80005fca:	f016                	sd	t0,32(sp)
    80005fcc:	f41a                	sd	t1,40(sp)
    80005fce:	f81e                	sd	t2,48(sp)
    80005fd0:	fc22                	sd	s0,56(sp)
    80005fd2:	e0a6                	sd	s1,64(sp)
    80005fd4:	e4aa                	sd	a0,72(sp)
    80005fd6:	e8ae                	sd	a1,80(sp)
    80005fd8:	ecb2                	sd	a2,88(sp)
    80005fda:	f0b6                	sd	a3,96(sp)
    80005fdc:	f4ba                	sd	a4,104(sp)
    80005fde:	f8be                	sd	a5,112(sp)
    80005fe0:	fcc2                	sd	a6,120(sp)
    80005fe2:	e146                	sd	a7,128(sp)
    80005fe4:	e54a                	sd	s2,136(sp)
    80005fe6:	e94e                	sd	s3,144(sp)
    80005fe8:	ed52                	sd	s4,152(sp)
    80005fea:	f156                	sd	s5,160(sp)
    80005fec:	f55a                	sd	s6,168(sp)
    80005fee:	f95e                	sd	s7,176(sp)
    80005ff0:	fd62                	sd	s8,184(sp)
    80005ff2:	e1e6                	sd	s9,192(sp)
    80005ff4:	e5ea                	sd	s10,200(sp)
    80005ff6:	e9ee                	sd	s11,208(sp)
    80005ff8:	edf2                	sd	t3,216(sp)
    80005ffa:	f1f6                	sd	t4,224(sp)
    80005ffc:	f5fa                	sd	t5,232(sp)
    80005ffe:	f9fe                	sd	t6,240(sp)
    80006000:	c7bfc0ef          	jal	ra,80002c7a <kerneltrap>
    80006004:	6082                	ld	ra,0(sp)
    80006006:	6122                	ld	sp,8(sp)
    80006008:	61c2                	ld	gp,16(sp)
    8000600a:	7282                	ld	t0,32(sp)
    8000600c:	7322                	ld	t1,40(sp)
    8000600e:	73c2                	ld	t2,48(sp)
    80006010:	7462                	ld	s0,56(sp)
    80006012:	6486                	ld	s1,64(sp)
    80006014:	6526                	ld	a0,72(sp)
    80006016:	65c6                	ld	a1,80(sp)
    80006018:	6666                	ld	a2,88(sp)
    8000601a:	7686                	ld	a3,96(sp)
    8000601c:	7726                	ld	a4,104(sp)
    8000601e:	77c6                	ld	a5,112(sp)
    80006020:	7866                	ld	a6,120(sp)
    80006022:	688a                	ld	a7,128(sp)
    80006024:	692a                	ld	s2,136(sp)
    80006026:	69ca                	ld	s3,144(sp)
    80006028:	6a6a                	ld	s4,152(sp)
    8000602a:	7a8a                	ld	s5,160(sp)
    8000602c:	7b2a                	ld	s6,168(sp)
    8000602e:	7bca                	ld	s7,176(sp)
    80006030:	7c6a                	ld	s8,184(sp)
    80006032:	6c8e                	ld	s9,192(sp)
    80006034:	6d2e                	ld	s10,200(sp)
    80006036:	6dce                	ld	s11,208(sp)
    80006038:	6e6e                	ld	t3,216(sp)
    8000603a:	7e8e                	ld	t4,224(sp)
    8000603c:	7f2e                	ld	t5,232(sp)
    8000603e:	7fce                	ld	t6,240(sp)
    80006040:	6111                	addi	sp,sp,256
    80006042:	10200073          	sret
    80006046:	00000013          	nop
    8000604a:	00000013          	nop
    8000604e:	0001                	nop

0000000080006050 <timervec>:
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	e10c                	sd	a1,0(a0)
    80006056:	e510                	sd	a2,8(a0)
    80006058:	e914                	sd	a3,16(a0)
    8000605a:	6d0c                	ld	a1,24(a0)
    8000605c:	7110                	ld	a2,32(a0)
    8000605e:	6194                	ld	a3,0(a1)
    80006060:	96b2                	add	a3,a3,a2
    80006062:	e194                	sd	a3,0(a1)
    80006064:	4589                	li	a1,2
    80006066:	14459073          	csrw	sip,a1
    8000606a:	6914                	ld	a3,16(a0)
    8000606c:	6510                	ld	a2,8(a0)
    8000606e:	610c                	ld	a1,0(a0)
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	30200073          	mret
	...

000000008000607a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000607a:	1141                	addi	sp,sp,-16
    8000607c:	e422                	sd	s0,8(sp)
    8000607e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006080:	0c0007b7          	lui	a5,0xc000
    80006084:	4705                	li	a4,1
    80006086:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006088:	c3d8                	sw	a4,4(a5)
}
    8000608a:	6422                	ld	s0,8(sp)
    8000608c:	0141                	addi	sp,sp,16
    8000608e:	8082                	ret

0000000080006090 <plicinithart>:

void
plicinithart(void)
{
    80006090:	1141                	addi	sp,sp,-16
    80006092:	e406                	sd	ra,8(sp)
    80006094:	e022                	sd	s0,0(sp)
    80006096:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	8da080e7          	jalr	-1830(ra) # 80001972 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060a0:	0085171b          	slliw	a4,a0,0x8
    800060a4:	0c0027b7          	lui	a5,0xc002
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	40200713          	li	a4,1026
    800060ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060b2:	00d5151b          	slliw	a0,a0,0xd
    800060b6:	0c2017b7          	lui	a5,0xc201
    800060ba:	97aa                	add	a5,a5,a0
    800060bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret

00000000800060c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060c8:	1141                	addi	sp,sp,-16
    800060ca:	e406                	sd	ra,8(sp)
    800060cc:	e022                	sd	s0,0(sp)
    800060ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	8a2080e7          	jalr	-1886(ra) # 80001972 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060d8:	00d5151b          	slliw	a0,a0,0xd
    800060dc:	0c2017b7          	lui	a5,0xc201
    800060e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060e2:	43c8                	lw	a0,4(a5)
    800060e4:	60a2                	ld	ra,8(sp)
    800060e6:	6402                	ld	s0,0(sp)
    800060e8:	0141                	addi	sp,sp,16
    800060ea:	8082                	ret

00000000800060ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ec:	1101                	addi	sp,sp,-32
    800060ee:	ec06                	sd	ra,24(sp)
    800060f0:	e822                	sd	s0,16(sp)
    800060f2:	e426                	sd	s1,8(sp)
    800060f4:	1000                	addi	s0,sp,32
    800060f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	87a080e7          	jalr	-1926(ra) # 80001972 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006100:	00d5151b          	slliw	a0,a0,0xd
    80006104:	0c2017b7          	lui	a5,0xc201
    80006108:	97aa                	add	a5,a5,a0
    8000610a:	c3c4                	sw	s1,4(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret

0000000080006116 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006116:	1141                	addi	sp,sp,-16
    80006118:	e406                	sd	ra,8(sp)
    8000611a:	e022                	sd	s0,0(sp)
    8000611c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000611e:	479d                	li	a5,7
    80006120:	06a7c863          	blt	a5,a0,80006190 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006124:	0001d717          	auipc	a4,0x1d
    80006128:	edc70713          	addi	a4,a4,-292 # 80023000 <disk>
    8000612c:	972a                	add	a4,a4,a0
    8000612e:	6789                	lui	a5,0x2
    80006130:	97ba                	add	a5,a5,a4
    80006132:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006136:	e7ad                	bnez	a5,800061a0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006138:	00451793          	slli	a5,a0,0x4
    8000613c:	0001f717          	auipc	a4,0x1f
    80006140:	ec470713          	addi	a4,a4,-316 # 80025000 <disk+0x2000>
    80006144:	6314                	ld	a3,0(a4)
    80006146:	96be                	add	a3,a3,a5
    80006148:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000614c:	6314                	ld	a3,0(a4)
    8000614e:	96be                	add	a3,a3,a5
    80006150:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006154:	6314                	ld	a3,0(a4)
    80006156:	96be                	add	a3,a3,a5
    80006158:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000615c:	6318                	ld	a4,0(a4)
    8000615e:	97ba                	add	a5,a5,a4
    80006160:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006164:	0001d717          	auipc	a4,0x1d
    80006168:	e9c70713          	addi	a4,a4,-356 # 80023000 <disk>
    8000616c:	972a                	add	a4,a4,a0
    8000616e:	6789                	lui	a5,0x2
    80006170:	97ba                	add	a5,a5,a4
    80006172:	4705                	li	a4,1
    80006174:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006178:	0001f517          	auipc	a0,0x1f
    8000617c:	ea050513          	addi	a0,a0,-352 # 80025018 <disk+0x2018>
    80006180:	ffffc097          	auipc	ra,0xffffc
    80006184:	218080e7          	jalr	536(ra) # 80002398 <wakeup>
}
    80006188:	60a2                	ld	ra,8(sp)
    8000618a:	6402                	ld	s0,0(sp)
    8000618c:	0141                	addi	sp,sp,16
    8000618e:	8082                	ret
    panic("free_desc 1");
    80006190:	00002517          	auipc	a0,0x2
    80006194:	58850513          	addi	a0,a0,1416 # 80008718 <syscalls+0x348>
    80006198:	ffffa097          	auipc	ra,0xffffa
    8000619c:	3a2080e7          	jalr	930(ra) # 8000053a <panic>
    panic("free_desc 2");
    800061a0:	00002517          	auipc	a0,0x2
    800061a4:	58850513          	addi	a0,a0,1416 # 80008728 <syscalls+0x358>
    800061a8:	ffffa097          	auipc	ra,0xffffa
    800061ac:	392080e7          	jalr	914(ra) # 8000053a <panic>

00000000800061b0 <virtio_disk_init>:
{
    800061b0:	1101                	addi	sp,sp,-32
    800061b2:	ec06                	sd	ra,24(sp)
    800061b4:	e822                	sd	s0,16(sp)
    800061b6:	e426                	sd	s1,8(sp)
    800061b8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061ba:	00002597          	auipc	a1,0x2
    800061be:	57e58593          	addi	a1,a1,1406 # 80008738 <syscalls+0x368>
    800061c2:	0001f517          	auipc	a0,0x1f
    800061c6:	f6650513          	addi	a0,a0,-154 # 80025128 <disk+0x2128>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	9c8080e7          	jalr	-1592(ra) # 80000b92 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061d2:	100017b7          	lui	a5,0x10001
    800061d6:	4398                	lw	a4,0(a5)
    800061d8:	2701                	sext.w	a4,a4
    800061da:	747277b7          	lui	a5,0x74727
    800061de:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061e2:	0ef71063          	bne	a4,a5,800062c2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061e6:	100017b7          	lui	a5,0x10001
    800061ea:	43dc                	lw	a5,4(a5)
    800061ec:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061ee:	4705                	li	a4,1
    800061f0:	0ce79963          	bne	a5,a4,800062c2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061f4:	100017b7          	lui	a5,0x10001
    800061f8:	479c                	lw	a5,8(a5)
    800061fa:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061fc:	4709                	li	a4,2
    800061fe:	0ce79263          	bne	a5,a4,800062c2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006202:	100017b7          	lui	a5,0x10001
    80006206:	47d8                	lw	a4,12(a5)
    80006208:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000620a:	554d47b7          	lui	a5,0x554d4
    8000620e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006212:	0af71863          	bne	a4,a5,800062c2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006216:	100017b7          	lui	a5,0x10001
    8000621a:	4705                	li	a4,1
    8000621c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621e:	470d                	li	a4,3
    80006220:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006222:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006224:	c7ffe6b7          	lui	a3,0xc7ffe
    80006228:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000622c:	8f75                	and	a4,a4,a3
    8000622e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006230:	472d                	li	a4,11
    80006232:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006234:	473d                	li	a4,15
    80006236:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006238:	6705                	lui	a4,0x1
    8000623a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000623c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006240:	5bdc                	lw	a5,52(a5)
    80006242:	2781                	sext.w	a5,a5
  if(max == 0)
    80006244:	c7d9                	beqz	a5,800062d2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006246:	471d                	li	a4,7
    80006248:	08f77d63          	bgeu	a4,a5,800062e2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000624c:	100014b7          	lui	s1,0x10001
    80006250:	47a1                	li	a5,8
    80006252:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006254:	6609                	lui	a2,0x2
    80006256:	4581                	li	a1,0
    80006258:	0001d517          	auipc	a0,0x1d
    8000625c:	da850513          	addi	a0,a0,-600 # 80023000 <disk>
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	abe080e7          	jalr	-1346(ra) # 80000d1e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006268:	0001d717          	auipc	a4,0x1d
    8000626c:	d9870713          	addi	a4,a4,-616 # 80023000 <disk>
    80006270:	00c75793          	srli	a5,a4,0xc
    80006274:	2781                	sext.w	a5,a5
    80006276:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006278:	0001f797          	auipc	a5,0x1f
    8000627c:	d8878793          	addi	a5,a5,-632 # 80025000 <disk+0x2000>
    80006280:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006282:	0001d717          	auipc	a4,0x1d
    80006286:	dfe70713          	addi	a4,a4,-514 # 80023080 <disk+0x80>
    8000628a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000628c:	0001e717          	auipc	a4,0x1e
    80006290:	d7470713          	addi	a4,a4,-652 # 80024000 <disk+0x1000>
    80006294:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006296:	4705                	li	a4,1
    80006298:	00e78c23          	sb	a4,24(a5)
    8000629c:	00e78ca3          	sb	a4,25(a5)
    800062a0:	00e78d23          	sb	a4,26(a5)
    800062a4:	00e78da3          	sb	a4,27(a5)
    800062a8:	00e78e23          	sb	a4,28(a5)
    800062ac:	00e78ea3          	sb	a4,29(a5)
    800062b0:	00e78f23          	sb	a4,30(a5)
    800062b4:	00e78fa3          	sb	a4,31(a5)
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6105                	addi	sp,sp,32
    800062c0:	8082                	ret
    panic("could not find virtio disk");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	48650513          	addi	a0,a0,1158 # 80008748 <syscalls+0x378>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	270080e7          	jalr	624(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	49650513          	addi	a0,a0,1174 # 80008768 <syscalls+0x398>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	260080e7          	jalr	608(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	4a650513          	addi	a0,a0,1190 # 80008788 <syscalls+0x3b8>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	250080e7          	jalr	592(ra) # 8000053a <panic>

00000000800062f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062f2:	7119                	addi	sp,sp,-128
    800062f4:	fc86                	sd	ra,120(sp)
    800062f6:	f8a2                	sd	s0,112(sp)
    800062f8:	f4a6                	sd	s1,104(sp)
    800062fa:	f0ca                	sd	s2,96(sp)
    800062fc:	ecce                	sd	s3,88(sp)
    800062fe:	e8d2                	sd	s4,80(sp)
    80006300:	e4d6                	sd	s5,72(sp)
    80006302:	e0da                	sd	s6,64(sp)
    80006304:	fc5e                	sd	s7,56(sp)
    80006306:	f862                	sd	s8,48(sp)
    80006308:	f466                	sd	s9,40(sp)
    8000630a:	f06a                	sd	s10,32(sp)
    8000630c:	ec6e                	sd	s11,24(sp)
    8000630e:	0100                	addi	s0,sp,128
    80006310:	8aaa                	mv	s5,a0
    80006312:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006314:	00c52c83          	lw	s9,12(a0)
    80006318:	001c9c9b          	slliw	s9,s9,0x1
    8000631c:	1c82                	slli	s9,s9,0x20
    8000631e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006322:	0001f517          	auipc	a0,0x1f
    80006326:	e0650513          	addi	a0,a0,-506 # 80025128 <disk+0x2128>
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	8f8080e7          	jalr	-1800(ra) # 80000c22 <acquire>
  for(int i = 0; i < 3; i++){
    80006332:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006334:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006336:	0001dc17          	auipc	s8,0x1d
    8000633a:	ccac0c13          	addi	s8,s8,-822 # 80023000 <disk>
    8000633e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006340:	4b0d                	li	s6,3
    80006342:	a0ad                	j	800063ac <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006344:	00fc0733          	add	a4,s8,a5
    80006348:	975e                	add	a4,a4,s7
    8000634a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000634e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006350:	0207c563          	bltz	a5,8000637a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006354:	2905                	addiw	s2,s2,1
    80006356:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006358:	19690c63          	beq	s2,s6,800064f0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000635c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000635e:	0001f717          	auipc	a4,0x1f
    80006362:	cba70713          	addi	a4,a4,-838 # 80025018 <disk+0x2018>
    80006366:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006368:	00074683          	lbu	a3,0(a4)
    8000636c:	fee1                	bnez	a3,80006344 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000636e:	2785                	addiw	a5,a5,1
    80006370:	0705                	addi	a4,a4,1
    80006372:	fe979be3          	bne	a5,s1,80006368 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006376:	57fd                	li	a5,-1
    80006378:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000637a:	01205d63          	blez	s2,80006394 <virtio_disk_rw+0xa2>
    8000637e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006380:	000a2503          	lw	a0,0(s4)
    80006384:	00000097          	auipc	ra,0x0
    80006388:	d92080e7          	jalr	-622(ra) # 80006116 <free_desc>
      for(int j = 0; j < i; j++)
    8000638c:	2d85                	addiw	s11,s11,1
    8000638e:	0a11                	addi	s4,s4,4
    80006390:	ff2d98e3          	bne	s11,s2,80006380 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006394:	0001f597          	auipc	a1,0x1f
    80006398:	d9458593          	addi	a1,a1,-620 # 80025128 <disk+0x2128>
    8000639c:	0001f517          	auipc	a0,0x1f
    800063a0:	c7c50513          	addi	a0,a0,-900 # 80025018 <disk+0x2018>
    800063a4:	ffffc097          	auipc	ra,0xffffc
    800063a8:	cfa080e7          	jalr	-774(ra) # 8000209e <sleep>
  for(int i = 0; i < 3; i++){
    800063ac:	f8040a13          	addi	s4,s0,-128
{
    800063b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063b2:	894e                	mv	s2,s3
    800063b4:	b765                	j	8000635c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063b6:	0001f697          	auipc	a3,0x1f
    800063ba:	c4a6b683          	ld	a3,-950(a3) # 80025000 <disk+0x2000>
    800063be:	96ba                	add	a3,a3,a4
    800063c0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063c4:	0001d817          	auipc	a6,0x1d
    800063c8:	c3c80813          	addi	a6,a6,-964 # 80023000 <disk>
    800063cc:	0001f697          	auipc	a3,0x1f
    800063d0:	c3468693          	addi	a3,a3,-972 # 80025000 <disk+0x2000>
    800063d4:	6290                	ld	a2,0(a3)
    800063d6:	963a                	add	a2,a2,a4
    800063d8:	00c65583          	lhu	a1,12(a2)
    800063dc:	0015e593          	ori	a1,a1,1
    800063e0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800063e4:	f8842603          	lw	a2,-120(s0)
    800063e8:	628c                	ld	a1,0(a3)
    800063ea:	972e                	add	a4,a4,a1
    800063ec:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063f0:	20050593          	addi	a1,a0,512
    800063f4:	0592                	slli	a1,a1,0x4
    800063f6:	95c2                	add	a1,a1,a6
    800063f8:	577d                	li	a4,-1
    800063fa:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063fe:	00461713          	slli	a4,a2,0x4
    80006402:	6290                	ld	a2,0(a3)
    80006404:	963a                	add	a2,a2,a4
    80006406:	03078793          	addi	a5,a5,48
    8000640a:	97c2                	add	a5,a5,a6
    8000640c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000640e:	629c                	ld	a5,0(a3)
    80006410:	97ba                	add	a5,a5,a4
    80006412:	4605                	li	a2,1
    80006414:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006416:	629c                	ld	a5,0(a3)
    80006418:	97ba                	add	a5,a5,a4
    8000641a:	4809                	li	a6,2
    8000641c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006420:	629c                	ld	a5,0(a3)
    80006422:	97ba                	add	a5,a5,a4
    80006424:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006428:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000642c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006430:	6698                	ld	a4,8(a3)
    80006432:	00275783          	lhu	a5,2(a4)
    80006436:	8b9d                	andi	a5,a5,7
    80006438:	0786                	slli	a5,a5,0x1
    8000643a:	973e                	add	a4,a4,a5
    8000643c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006440:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006444:	6698                	ld	a4,8(a3)
    80006446:	00275783          	lhu	a5,2(a4)
    8000644a:	2785                	addiw	a5,a5,1
    8000644c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006450:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006454:	100017b7          	lui	a5,0x10001
    80006458:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000645c:	004aa783          	lw	a5,4(s5)
    80006460:	02c79163          	bne	a5,a2,80006482 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006464:	0001f917          	auipc	s2,0x1f
    80006468:	cc490913          	addi	s2,s2,-828 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000646c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000646e:	85ca                	mv	a1,s2
    80006470:	8556                	mv	a0,s5
    80006472:	ffffc097          	auipc	ra,0xffffc
    80006476:	c2c080e7          	jalr	-980(ra) # 8000209e <sleep>
  while(b->disk == 1) {
    8000647a:	004aa783          	lw	a5,4(s5)
    8000647e:	fe9788e3          	beq	a5,s1,8000646e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006482:	f8042903          	lw	s2,-128(s0)
    80006486:	20090713          	addi	a4,s2,512
    8000648a:	0712                	slli	a4,a4,0x4
    8000648c:	0001d797          	auipc	a5,0x1d
    80006490:	b7478793          	addi	a5,a5,-1164 # 80023000 <disk>
    80006494:	97ba                	add	a5,a5,a4
    80006496:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000649a:	0001f997          	auipc	s3,0x1f
    8000649e:	b6698993          	addi	s3,s3,-1178 # 80025000 <disk+0x2000>
    800064a2:	00491713          	slli	a4,s2,0x4
    800064a6:	0009b783          	ld	a5,0(s3)
    800064aa:	97ba                	add	a5,a5,a4
    800064ac:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064b0:	854a                	mv	a0,s2
    800064b2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064b6:	00000097          	auipc	ra,0x0
    800064ba:	c60080e7          	jalr	-928(ra) # 80006116 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064be:	8885                	andi	s1,s1,1
    800064c0:	f0ed                	bnez	s1,800064a2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064c2:	0001f517          	auipc	a0,0x1f
    800064c6:	c6650513          	addi	a0,a0,-922 # 80025128 <disk+0x2128>
    800064ca:	ffffb097          	auipc	ra,0xffffb
    800064ce:	80c080e7          	jalr	-2036(ra) # 80000cd6 <release>
}
    800064d2:	70e6                	ld	ra,120(sp)
    800064d4:	7446                	ld	s0,112(sp)
    800064d6:	74a6                	ld	s1,104(sp)
    800064d8:	7906                	ld	s2,96(sp)
    800064da:	69e6                	ld	s3,88(sp)
    800064dc:	6a46                	ld	s4,80(sp)
    800064de:	6aa6                	ld	s5,72(sp)
    800064e0:	6b06                	ld	s6,64(sp)
    800064e2:	7be2                	ld	s7,56(sp)
    800064e4:	7c42                	ld	s8,48(sp)
    800064e6:	7ca2                	ld	s9,40(sp)
    800064e8:	7d02                	ld	s10,32(sp)
    800064ea:	6de2                	ld	s11,24(sp)
    800064ec:	6109                	addi	sp,sp,128
    800064ee:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f0:	f8042503          	lw	a0,-128(s0)
    800064f4:	20050793          	addi	a5,a0,512
    800064f8:	0792                	slli	a5,a5,0x4
  if(write)
    800064fa:	0001d817          	auipc	a6,0x1d
    800064fe:	b0680813          	addi	a6,a6,-1274 # 80023000 <disk>
    80006502:	00f80733          	add	a4,a6,a5
    80006506:	01a036b3          	snez	a3,s10
    8000650a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000650e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006512:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006516:	7679                	lui	a2,0xffffe
    80006518:	963e                	add	a2,a2,a5
    8000651a:	0001f697          	auipc	a3,0x1f
    8000651e:	ae668693          	addi	a3,a3,-1306 # 80025000 <disk+0x2000>
    80006522:	6298                	ld	a4,0(a3)
    80006524:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006526:	0a878593          	addi	a1,a5,168
    8000652a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000652c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000652e:	6298                	ld	a4,0(a3)
    80006530:	9732                	add	a4,a4,a2
    80006532:	45c1                	li	a1,16
    80006534:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006536:	6298                	ld	a4,0(a3)
    80006538:	9732                	add	a4,a4,a2
    8000653a:	4585                	li	a1,1
    8000653c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006540:	f8442703          	lw	a4,-124(s0)
    80006544:	628c                	ld	a1,0(a3)
    80006546:	962e                	add	a2,a2,a1
    80006548:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000654c:	0712                	slli	a4,a4,0x4
    8000654e:	6290                	ld	a2,0(a3)
    80006550:	963a                	add	a2,a2,a4
    80006552:	058a8593          	addi	a1,s5,88
    80006556:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006558:	6294                	ld	a3,0(a3)
    8000655a:	96ba                	add	a3,a3,a4
    8000655c:	40000613          	li	a2,1024
    80006560:	c690                	sw	a2,8(a3)
  if(write)
    80006562:	e40d1ae3          	bnez	s10,800063b6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006566:	0001f697          	auipc	a3,0x1f
    8000656a:	a9a6b683          	ld	a3,-1382(a3) # 80025000 <disk+0x2000>
    8000656e:	96ba                	add	a3,a3,a4
    80006570:	4609                	li	a2,2
    80006572:	00c69623          	sh	a2,12(a3)
    80006576:	b5b9                	j	800063c4 <virtio_disk_rw+0xd2>

0000000080006578 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006578:	1101                	addi	sp,sp,-32
    8000657a:	ec06                	sd	ra,24(sp)
    8000657c:	e822                	sd	s0,16(sp)
    8000657e:	e426                	sd	s1,8(sp)
    80006580:	e04a                	sd	s2,0(sp)
    80006582:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006584:	0001f517          	auipc	a0,0x1f
    80006588:	ba450513          	addi	a0,a0,-1116 # 80025128 <disk+0x2128>
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	696080e7          	jalr	1686(ra) # 80000c22 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006594:	10001737          	lui	a4,0x10001
    80006598:	533c                	lw	a5,96(a4)
    8000659a:	8b8d                	andi	a5,a5,3
    8000659c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000659e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065a2:	0001f797          	auipc	a5,0x1f
    800065a6:	a5e78793          	addi	a5,a5,-1442 # 80025000 <disk+0x2000>
    800065aa:	6b94                	ld	a3,16(a5)
    800065ac:	0207d703          	lhu	a4,32(a5)
    800065b0:	0026d783          	lhu	a5,2(a3)
    800065b4:	06f70163          	beq	a4,a5,80006616 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065b8:	0001d917          	auipc	s2,0x1d
    800065bc:	a4890913          	addi	s2,s2,-1464 # 80023000 <disk>
    800065c0:	0001f497          	auipc	s1,0x1f
    800065c4:	a4048493          	addi	s1,s1,-1472 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800065c8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065cc:	6898                	ld	a4,16(s1)
    800065ce:	0204d783          	lhu	a5,32(s1)
    800065d2:	8b9d                	andi	a5,a5,7
    800065d4:	078e                	slli	a5,a5,0x3
    800065d6:	97ba                	add	a5,a5,a4
    800065d8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065da:	20078713          	addi	a4,a5,512
    800065de:	0712                	slli	a4,a4,0x4
    800065e0:	974a                	add	a4,a4,s2
    800065e2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065e6:	e731                	bnez	a4,80006632 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065e8:	20078793          	addi	a5,a5,512
    800065ec:	0792                	slli	a5,a5,0x4
    800065ee:	97ca                	add	a5,a5,s2
    800065f0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065f2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065f6:	ffffc097          	auipc	ra,0xffffc
    800065fa:	da2080e7          	jalr	-606(ra) # 80002398 <wakeup>

    disk.used_idx += 1;
    800065fe:	0204d783          	lhu	a5,32(s1)
    80006602:	2785                	addiw	a5,a5,1
    80006604:	17c2                	slli	a5,a5,0x30
    80006606:	93c1                	srli	a5,a5,0x30
    80006608:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000660c:	6898                	ld	a4,16(s1)
    8000660e:	00275703          	lhu	a4,2(a4)
    80006612:	faf71be3          	bne	a4,a5,800065c8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006616:	0001f517          	auipc	a0,0x1f
    8000661a:	b1250513          	addi	a0,a0,-1262 # 80025128 <disk+0x2128>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	6b8080e7          	jalr	1720(ra) # 80000cd6 <release>
}
    80006626:	60e2                	ld	ra,24(sp)
    80006628:	6442                	ld	s0,16(sp)
    8000662a:	64a2                	ld	s1,8(sp)
    8000662c:	6902                	ld	s2,0(sp)
    8000662e:	6105                	addi	sp,sp,32
    80006630:	8082                	ret
      panic("virtio_disk_intr status");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	17650513          	addi	a0,a0,374 # 800087a8 <syscalls+0x3d8>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f00080e7          	jalr	-256(ra) # 8000053a <panic>
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
