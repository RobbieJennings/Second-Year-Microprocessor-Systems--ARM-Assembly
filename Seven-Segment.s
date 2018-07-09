	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011.

	EXPORT	start
start

;P0.*
IO0DIR	EQU	0xE0028008
IO0SET	EQU	0xE0028004
IO0CLR	EQU	0xE002800C

;P1.*
IO1DIR	EQU 0xE0028018
IO1PIN	EQU 0xE0028010

	ldr	r1,=IO0DIR
	ldr	r2,=0x0000ff00	;select P0.15--P0.8
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO0CLR
	str	r2,[r1]		;clear them to turn the LEDs off
	ldr	r2,=IO0SET
; r1 points to the CLEAR register
; r2 points to the SET register

	ldr r7,=IO1DIR			
	ldr r8,=0xff0fffff		;select p1.23--P1.20
	str r8, [r7]			;Sets all buttons in P1.* for input.
	ldr r8,=0   			;clear r8 for use
	ldr r7,=0				;clear r7 for use
	
	ldr r9,= IO1PIN
	
wloop
	ldr r8,[r9]
	and r7, r8, #0x00f00000
	cmp r7,#0x00f00000	
	beq wloop
	
	;delay for very small time (to allow user time to press multiple buttons)
	ldr	r4,=2000000
dloop1	
	subs	r4,r4,#1
	bne	dloop1
	
	ldr r8,[r9]
	and r7, r8, #0x00f00000
	cmp r7,#0x00f00000	
	beq wloop
	
	ldr r10,=4
floop1	
	movs r7, r7, lsr #1
	bcs press
	b floop1
press
	sub r10, r10, #1
	cmp r7, #0
	bne floop1
	
	cmp r10, #2
	bgt upCount
	
	ldr	r5,=numbers	; point to the digits table
	ldr r6,=15 ; count = end of table
		
floop2	
	ldr r3, [r5, r6, LSL #2]
	str	r3,[r2]	   	; clear the bit -> turn on the LED     				;Switches on number
	sub r6, r6, #1 ; count--
		
;delay for about a half second
	ldr	r4,=20000000
dloop2	
	subs	r4,r4,#1
	bne	dloop2

	str	r3,[r1]		;set the bit -> turn off the LED						;Removes Number
	mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
	cmp	r6, #0	; check if end of table
	bge	floop2
	
	b	wloop
	
upCount
	ldr	r5,=numbers	; point to the digits table
	ldr r6,=0 ; count = 0
		
floop3	
	ldr r3, [r5, r6, LSL #2]
	str	r3,[r2]	   	; clear the bit -> turn on the LED     				;Switches on number
	add r6, r6, #1 ; count++
		
;delay for about a half second
	ldr	r4,=20000000
dloop3	
	subs	r4,r4,#1
	bne	dloop3

	str	r3,[r1]		;set the bit -> turn off the LED						;Removes Number
	mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
	cmp	r6, #16	; check if end of table
	blo	floop3
	
	b	wloop
	
	
stop	B	stop
	
	AREA	table, DATA, READONLY

numbers DCD 0x00003f00, 0x00000600, 0x00005b00, 0x00004f00, 0x00006600, 0x00006d00, 0x00007d00, 0x00000700, 0x00007f00, 0x00006f00, 0x00007700, 0x00007c00, 0x00003900, 0x00005e00, 0x00007900, 0x00007100

	END