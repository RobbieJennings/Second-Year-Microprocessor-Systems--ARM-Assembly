; Definitions  -- references to 'UM' are to the User Manual.

; Timer Stuff -- UM, Table 173

T0	equ	0xE0004000		; Timer 0 Base Address
T1	equ	0xE0008000

IR	equ	0			; Add this to a timer's base address to get actual register address
TCR	equ	4
MCR	equ	0x14
MR0	equ	0x18

TimerCommandReset	equ	2
TimerCommandRun	equ	1
TimerModeResetAndInterrupt	equ	3
TimerResetTimer0Interrupt	equ	1
TimerResetAllInterrupts	equ	0xFF

; VIC Stuff -- UM, Table 41
VIC	equ	0xFFFFF000		; VIC Base Address
IntEnable	equ	0x10
VectAddr	equ	0x30
VectAddr0	equ	0x100
VectCtrl0	equ	0x200

Timer0ChannelNumber	equ	4	; UM, Table 63
Timer0Mask	equ	1<<Timer0ChannelNumber	; UM, Table 63
IRQslot_en	equ	5		; UM, Table 58

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN	EQU	0xE0028010

	AREA	InitialisationAndMain, CODE, READONLY
	IMPORT	main

; (c) Mike Brady, 2014–2016.

	EXPORT	start
start
	
; Initialise the code
	ldr r3,=thread1Pointer
	ldr r4,=threadOne
	str r4, [r3]
	
	ldr r3,=thread2Pointer
	ldr r4,=threadTwo
	str r4, [r3]
	
	ldr r3,=threadRunning
	ldr r4,=0
	str r4, [r3]

; Initialise the VIC
	ldr	r0,=VIC			; looking at you, VIC!

	ldr	r1,=irqhan
	str	r1,[r0,#VectAddr0] 	; associate our interrupt handler with Vectored Interrupt 0

	mov	r1,#Timer0ChannelNumber+(1<<IRQslot_en)
	str	r1,[r0,#VectCtrl0] 	; make Timer 0 interrupts the source of Vectored Interrupt 0

	mov	r1,#Timer0Mask
	str	r1,[r0,#IntEnable]	; enable Timer 0 interrupts to be recognised by the VIC

	mov	r1,#0
	str	r1,[r0,#VectAddr]   	; remove any pending interrupt (may not be needed)

; Initialise Timer 0
	ldr	r0,=T0			; looking at you, Timer 0!

	mov	r1,#TimerCommandReset
	str	r1,[r0,#TCR]

	mov	r1,#TimerResetAllInterrupts
	str	r1,[r0,#IR]

	ldr	r1,=(14745600/200)-1	 ; 5 ms = 1/200 second
	str	r1,[r0,#MR0]

	mov	r1,#TimerModeResetAndInterrupt
	str	r1,[r0,#MCR]

	mov	r1,#TimerCommandRun
	str	r1,[r0,#TCR]

initEnd
	b initEnd
	


threadOne
	
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
	; r1 points to the SET register
	; r2 points to the CLEAR register

wloop1
	ldr r0,=0x00020000
	str r0, [r1]
	
	ldr r0,=0x00010000
	str r0,[r2] 
	
	;delay for about a half second
	ldr	r0,=1000000
dloop1
	subs	r0,r0,#1
	cmp r0, #0
	bne	dloop1
	
	ldr r0,=0x00010000
	str r0, [r1]
	
	ldr r0,=0x00020000
	str r0, [r2]
	
	;delay for about a half second
	ldr	r0,=1000000
dloop2	
	subs	r0,r0,#1
	cmp r0, #0
	bne dloop2
	
	b wloop1



threadTwo

	
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
	; r1 points to the SET register
	; r2 points to the CLEAR register

wloop2
	ldr r0,=0x00040000
	str r0, [r1]
	
	ldr r0,=0x00080000
	str r0,[r2] 
	
	;delay for about a half second
	ldr	r0,=1000000
dloop3
	subs	r0,r0,#1
	cmp r0, #0
	bne	dloop3
	
	ldr r0,=0x00080000
	str r0, [r1]
	
	ldr r0,=0x00040000
	str r0, [r2]
	
	;delay for about a half second
	ldr	r0,=1000000
dloop4	
	subs	r0,r0,#1
	cmp r0, #0
	bne dloop4
	
	b wloop2

wloop	b	wloop  		; branch always
;main program execution will never drop below the statement above.

	AREA	InterruptStuff, CODE, READONLY
irqhan	
	stmfd sp!,{r0-r2}

	ldr r3,=threadRunning
	ldr r4, [r3]
	
	cmp r4, #0
	beq firstRun
	
	cmp r4, #1
	beq thread2Start
	
	cmp r4, #2
	beq thread1Start
	
	b dispatch
	
firstRun

	ldr r3,=thread1Pointer
	ldr lr, [r3]
	ldr sp,=thread1Stack
	ldr r3,=threadRunning
	ldr r4,=1
	str r4, [r3]
	b dispatch

thread1Start
	
	ldr r3,=thread1Pointer
	ldr r4,=thread2Pointer
	str lr, [r4]
	ldr lr, [r3]
	ldr sp,=thread1Stack
	ldr r3,=threadRunning
	ldr r4,=1
	str r4, [r3]
	b dispatch
	
thread2Start
	
	ldr r3,=thread2Pointer
	ldr r4,=thread1Pointer
	str lr, [r4]
	ldr lr, [r3]
	ldr sp,=thread2Stack
	ldr r3,=threadRunning
	ldr r4,=2
	str r4, [r3]
	b dispatch
	
dispatch

;this is where we stop the timer from making the interrupt request to the VIC
;i.e. we 'acknowledge' the interrupt
	ldr	r0,=T0
	mov	r1,#TimerResetTimer0Interrupt
	str	r1,[r0,#IR]	   	; remove MR0 interrupt request from timer

;here we stop the VIC from making the interrupt request to the CPU:
	ldr	r0,=VIC
	mov	r1,#0
	str	r1,[r0,#VectAddr]	; reset VIC

	ldmfd	sp!, {r0-r2}
	stmfd	sp!, {lr}
	ldmfd 	sp!, {pc}^

	AREA	Subroutines, CODE, READONLY

	AREA	Stuff, DATA, READWRITE
		
;temp SPACE 32

threadRunning	 space 4
thread1Pointer space 4
thread2Pointer space 4
thread1Stack space 16
thread2Stack space 16
	

	END