; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Stijn Bettens, David Blinder
; date:		25/09/2017
; program:	Hello World!
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "mouse.inc"

; Screen constants
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height


; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; Set the video mode
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode

; Wait for a specific keystroke.
PROC waitForSpecificKeystroke
	ARG 	@@key:byte
	USES 	eax

	@@waitForKeystroke:
		mov	ah,00h
		int	16h
		cmp	al,[@@key]
	jne	@@waitForKeystroke ; if the key u pressed is not @@key (hier ESC= 001Bh), dan zal het niet terminateProcess

	ret
ENDP waitForSpecificKeystroke

; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

; Procedure wait_VBLANK van EXAMPLES\DANCER genomen
; wait for @@framecount frames
PROC wait_VBLANK
	ARG @@framecount: word
	USES eax, ecx, edx
	mov dx, 03dah 					; Wait for screen refresh
	movzx ecx, [@@framecount]
	
		@@VBlank_phase1:
		in al, dx 
		and al, 8
		jnz @@VBlank_phase1
		@@VBlank_phase2:
		in al, dx 
		and al, 8
		jz @@VBlank_phase2
	loop @@VBlank_phase1
	
	ret 
ENDP wait_VBLANK

PROC updateColorpallete

	USES eax, ebx, ecx, edx

	mov ebx, offset palette

	mov ah, 0

	@@kleur:
		mov DX, 03C8h 						; DAC write port
		push eax
		mov al, ah
		out DX, Al 							; write to IO
		pop eax


		mov DX, 03C9h 						; DAC data port

		mov AL, [ebx] 						; load red value (6-bit)
		out DX, AL 							; write red value
		add ebx, 4
		mov AL, [ebx] 						; load green value (6-bit)
		out DX, AL 							; write green value
		add ebx, 4
		mov AL, [ebx] 						; load blue value (6-bit)
		out DX, AL 							; write blue value
		add ebx, 4
		
		inc ah
		cmp ah, 5
		jne @@kleur

	ret
ENDP updateColorpallete

; Fill the background (for mode 13h): blue sky with grass and a wall
PROC fillBackground
	USES 	eax, ecx, edi, edx, ebx

	; Initialize video memory address.
	mov	edi, VMEMADR 						; edi is destination adress en is dus hier 0A0000h


	; Draw sky
	mov	ecx, SCRWIDTH*150 					; ecx = amount of elements = aantal pixels
	mov	al, 0								; indx of the first color to change
	rep	stosb			; stosb (byte) =transfer one byte from eax to edi so that edi increases/updates to point to the next datum(that is situated one byte next to the previous)
						;stosw (word) = transfer two byte (= word)
						;stosd (double word) = tranfer 4 bytes (= double word)

	; Draw grass
	mov	edi, VMEMADR
	add edi, 150*320
	mov al, 1

	mov edx, 50
	@@hoogte:
		mov ecx, 320
		@@breedte:
			mov [edi], al
			inc edi
			dec ecx
			cmp ecx, 0
			jne @@breedte
		dec edx
		cmp edx, 0
		jne @@hoogte

	; Draw wall
	mov edx, 1
	@@hoogtemuur:
		xor ebx, ebx	
		mov ebx, 50
		add ebx, edx
		mov eax, 320
		push edx
		mul ebx
		pop edx
		mov ebx, eax
		add ebx, 300
		mov	edi, VMEMADR
		add edi, ebx
		mov al, 2
		mov ecx, 10
			@@breedtemuur:
				mov [edi], al
				inc edi
				dec ecx
				cmp ecx, 0
				jne @@breedtemuur
		inc edx
		cmp edx, 100
		jne @@hoogtemuur

	; Draw target
	mov edx, 1
	@@hoogtedoel:
		xor ebx, ebx	
		mov ebx, 100
		add ebx, edx
		mov eax, 320
		push edx
		mul ebx
		pop edx
		mov ebx, eax
		add ebx, 298
		mov	edi, VMEMADR
		add edi, ebx
		mov al, 3
		mov ecx, 2
			@@breedtedoel:
				mov [edi], al
				inc edi
				dec ecx
				cmp ecx, 0
				jne @@breedtedoel
		inc edx
		cmp edx, 10
		jne @@hoogtedoel
	ret
ENDP fillBackground

;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond 
PROC drawPixel
	ARG @@xcoord:dword ,@@ycoord:dword, @@color:byte
	USES eax, ebx

	mov	edi, VMEMADR
	mov eax, [@@ycoord]
	mov ebx, 149
	sub ebx, eax
	mov eax, 320
	imul ebx
	add edi, eax
	add edi, [@@xcoord]
	
	mov al, [@@color]						; pick the color of the pallet
	mov [edi], al

	ret
ENDP drawPixel

; deletes previous bullet and draws a new one
PROC moveBullet
	ARG @@oldXpos:dword, @@oldYpos:dword, @@newXpos:dword, @@newYpos:dword
	USES ebx, ecx


	;Delete previous bullet
	mov ebx, [@@oldXpos]
	mov ecx, [@@oldYpos]

	call drawPixel, ebx, ecx, 0
	inc ebx
	call drawPixel, ebx, ecx, 0
	inc ebx
	call drawPixel, ebx, ecx, 0
	sub ebx, 2
	dec ecx
	call drawPixel, ebx, ecx, 0
	inc ebx
	call drawPixel, ebx, ecx, 0
	inc ebx
	call drawPixel, ebx, ecx, 0
	sub ebx, 2
	dec ecx
	call drawPixel, ebx, ecx, 0
	inc ebx
	call drawPixel, ebx, ecx, 0
	inc ebx
	call drawPixel, ebx, ecx, 0


	;Draw new bullet
	mov ebx, [@@newXpos]
	mov ecx, [@@newYpos]

	call drawPixel, ebx, ecx, 4
	inc ebx
	call drawPixel, ebx, ecx, 4
	inc ebx
	call drawPixel, ebx, ecx, 4
	sub ebx, 2
	dec ecx
	call drawPixel, ebx, ecx, 4
	inc ebx
	call drawPixel, ebx, ecx, 3
	inc ebx
	call drawPixel, ebx, ecx, 4
	sub ebx, 2
	dec ecx
	call drawPixel, ebx, ecx, 4
	inc ebx
	call drawPixel, ebx, ecx, 4
	inc ebx
	call drawPixel, ebx, ecx, 4

	ret
ENDP moveBullet

;procedure om de baan te berekenen
PROC bulletPath
	ARG @@vxbegin:dword, @@vybegin:dword
	LOCAL @@tijd:dword, @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ax:dword, @@ay:dword
	USES eax, ebx

	mov [@@tijd], 0
	mov [@@dt], 1					; [time unit]

	mov eax, 25
	mov ebx, 25

	push eax
	push ebx

	mov [@@xpos], eax				;[pixels]
	mov [@@ypos], ebx				;[pixels]
	mov eax, [@@vxbegin]			;[pixels/time unit]
	mov [@@vx], eax
	mov eax, [@@vybegin]			;[pixels/time unit]
	mov [@@vy], eax
	mov [@@ax], 0					;[pixels/time unit²]
	mov [@@ay], -10					;[pixels/time unit²] downward accelaration due to "gravity"


	call moveBullet, [@@xpos], [@@ypos], [@@xpos], [@@ypos] 
	call	waitForSpecificKeystroke, 001Bh

	@@tijdsloop:
		mov eax, [@@dt]
		add [@@tijd], eax

		;vx += ax*dt
		mov eax, [@@ax]				; ik weet dat ax toch nul is maar in toekomst zal ook windkracht komen
		mov ebx, [@@dt]				; ik weet ook dat dt toch 1 is (maar zou kunne veranderen) 
		mul ebx
		add [@@vx], eax
		;vy += ay*dt
		mov eax, [@@ay]
		mov ebx, [@@dt]
		mul ebx
		add [@@vy], eax
		;xpos += vx*dt 
		mov eax, [@@vx]
		mov ebx, [@@dt]
		mul ebx
		add [@@xpos], eax
		;ypos += vy*dt
		mov eax, [@@vy]
		mov ebx, [@@dt]
		imul ebx
		add [@@ypos], eax
		
		;Bring back old coordinations
		pop ebx						
		pop eax

		;bring back old coordinations
		call moveBullet, eax, ebx, [@@xpos], [@@ypos] 

		mov eax, [@@xpos]
		mov ebx, [@@ypos]
		
		;Store new coordinations for next loop
		push eax
		push ebx

		;Checks wall collision
		cmp eax, 297							; (hou rekening met breedte kogel)
		jge @@endWall
		
		;Checks ground collision
		cmp ebx, 3								; (hou rekening met hoogte kogel)								
		jle @@endGround

		call wait_VBLANK, 15					; [*10ms] animation purposes

		jmp @@tijdsloop

	@@endWall:
			call moveBullet, eax, ebx, 297, ebx
			jmp @@end
	@@endGround:
			call moveBullet, eax, ebx, eax, 2

	@@end:
	ret
ENDP bulletPath


; ----------------------------------------------------------------------------
; Mouse function
; AX = condition mask causing call
; CX = horizontal cursor position
; DX = vertical cursor position
; DI = horizontal counts
; SI = vertical counts
; BX = button state:
;      |F-2|1|0|
;        |  | `--- left button (1 = pressed)
;        |  `---- right button (1 = pressed)
;        `------ unused
; DS = DATASEG
; ES = DATASEG
; ----------------------------------------------------------------------------
PROC mouseHandler
    USES    eax, ebx, ecx, edx
	LOCAL @@oldXpos: dword, @@oldYpos: dword, @@newXpos: dword, @@newYpos: dword

	@@mousepressed:
	and bl, 1			; check if right button of mouse is clicked
	jz @@skipit			; only execute if a mousebutton is pressed

	;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond 
    movzx eax, dx		; get mouse height
	mov ebx, 149
	sub ebx, eax
	mov eax, ebx

	mov ebx,0
	sar cx, 1			; horizontal cursor position is doubled in input 
	movzx ebx, cx



	mov [@@newXpos], ebx
	mov [@@newYpos], eax
	;call printSignedInteger, ebx
	;call printSignedInteger, eax

	pop ebx
	pop eax

	;call printSignedInteger, ebx
	;call printSignedInteger, eax

	mov [@@oldXpos], ebx
	mov [@@oldYpos], eax
	
	
	call moveline, ebx, eax, [@@newXpos], [@@newYpos]

	;store old mouse coordinates
	push eax
	push ebx


	

	@@skipit:

    ret
ENDP mouseHandler

PROC save_mousecoord
	USES eax, ebx

	@@mousepressed:
	and bl, 1			; check if right button of mouse is clicked
	jz @@skipit			; only execute if a mousebutton is pressed

	;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond 
    movzx eax, dx		; get mouse height
	mov ebx, 149
	sub ebx, eax
	mov eax, ebx

	mov ebx,0
	sar cx, 1			; horizontal cursor position is doubled in input 
	movzx ebx, cx

	;call printSignedInteger, eax
	;call printSignedInteger, ebx
	call appendList,offset arrlen_mousecoord, eax
	call appendList, offset arrlen_mousecoord, ebx
	;call printIntList, offset arrlen_mousecoord

	@@skipit:
	
	
	ret


ENDP save_mousecoord

PROC Hello
	;RETURNS eax, ebx
	
	mov ebx, 1
	mov eax, 10
	add eax, ebx

	ret
ENDP Hello


PROC printSignedInteger
	ARG	@@printval:dword
	USES eax, ebx, ecx, edx

	mov eax, [@@printval]
    test eax, eax	; Check for sign
	jns skipSign
	push eax
	mov	ah, 2h     	; Print '-' if the sign is set.
    mov dl, '-'
	int	21h
	pop eax
	neg eax	; negate eax
	
	skipSign:
	mov	ebx, 10		; divider
	xor ecx, ecx	; counter for digits to be printed

	; Store digits on stack
	getNextDigit:
	inc	ecx         ; increase digit counter
	xor edx, edx
	div	ebx   		; divide by 10
	push dx			; store remainder on stack
	test eax, eax	; check whether zero?
	jnz	getNextDigit

    ; Write all digits to the standard output
	mov	ah, 2h 		; Function for printing single characters.
	printDigits:		
	pop dx
	add	dl,'0'      	; Add 30h => code for a digit in the ASCII table, ...
	int	21h            	; Print the digit to the screen, ...
	loop printDigits	; Until digit counter = 0.
	
	mov	dl, 0Dh		; Carriage return.
	int	21h
	mov	dl, 0Ah		; New line.
	int 21h

	ret
ENDP printSignedInteger


PROC drawline
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@color:dword
	LOCAL @@dx:dword, @@dy:dword, @@P:dword, @@count:dword, @@xoperator: dword, @@yoperator: dword
	USES eax, ebx,ecx, edx

	;dx = x2 - x1
	mov eax, [@@x2]
	sub eax, [@@x1]
	mov [@@dx], eax

	;dy = y2 - y1
	mov eax, [@@y2]
	sub eax, [@@y1]
	mov [@@dy], eax


	;Case 1: dx positive and dy positive, then slope positive 
	@@case1:
		cmp [@@dx], 0
		jl @@case2
		cmp [@@dy],0
		jl @@case3

		;dx pos: xoperator = +1
		mov [@@xoperator], 1
		;dy pos: operator = +1
		mov [@@yoperator], 1

		;Compare dx an dy	
		jmp @@compare_dx_and_dy


	;Case 2: dx negative and dy positive, then slope negative
	@@case2:
		cmp [@@dy],0
		jl @@case4

		;dx neg: xoperator = -1
		mov [@@xoperator], -1
		;dy pos: operator = +1
		mov [@@yoperator], 1

		;negate dx to make it positive
		neg [@@dx]

		;Compare dx an dy	
		jmp @@compare_dx_and_dy

	;Case 3: dx positive and dy negative, then slope negative
	@@case3:
		;dx pos: xoperator = +1
		mov [@@xoperator], 1
		;dy neg: operator = -1
		mov [@@yoperator], -1

		;negate dy to make it positive
		neg [@@dy]

		;Compare dx an dy	
		jmp @@compare_dx_and_dy

	;Case 4: dx negative and dy negative, then slope positive
	@@case4:
		;dx pos: xoperator = -1
		mov [@@xoperator], -1
		;dy pos: operator = -1
		mov [@@yoperator], -1

		;negate dx and dy to make them positive
		neg [@@dx]
		neg [@@dy]

		;Compare dx an dy	
		jmp @@compare_dx_and_dy

	;Compare dx an dy: if dx>=dy then slope<=1, if dx<dy then slope>1	
	@@compare_dx_and_dy:
		mov eax, [@@dx]
		mov ebx, [@@dy]
		cmp eax, ebx
		jge @@slope_less_or_equal_1
		jmp @@slope_greater_1 


	;a) slope<=1, dx>=dy
	@@slope_less_or_equal_1:
		;P = 2dy - dx
		mov eax, [@@dy]
		mov ebx, 2
		mul ebx
		sub eax, [@@dx]
		mov [@@P], eax

		;count = dx
		mov eax, [@@dx]
		mov [@@count], eax

		;initialize
		mov eax, [@@x1]
		mov ebx, [@@y1]
		mov ecx, [@@count]

		;---------------------------------------------------
		;bresenham's line algorithm:
		;This algorithm is used to draw a line between two points (x1, y1) and (x2, y2). 
		;If the slope <=1, xoperator (which can be +1 (increment) or -1 (decrement), dependent of dx) is added to x1.
		;if P<0: y1 = y1 and P = P + 2*dy 
		;if P>0: y1 = y1 + 1 and P = P + 2*dy - 2*dx
		; The loop goes on until x1 has reached x2 or until dx is zero.
		;---------------------------------------------------

		@@bl_loop1:
			call drawPixel, eax,ebx, [@@color]
			
			add eax, [@@xoperator]

			push eax
			push ebx

			cmp [@@P], 0					
			jl @@Pkleinerdan0_1
			
			call P_positive, [@@P], [@@dx], [@@dy]
			mov [@@P], eax
			
			pop ebx 
			pop eax 

			add ebx, [@@yoperator]

			loop @@bl_loop1
			jmp @@end

			@@Pkleinerdan0_1:
			call P_negative, [@@P], [@@dy]
			mov [@@P], eax

			pop ebx
			pop eax

			loop @@bl_loop1
			jmp @@end


	;b) slope>1, dx<dy
	@@slope_greater_1:
		;P = 2dx - dy
		mov eax, [@@dx]
		mov ebx, 2
		mul ebx
		sub eax, [@@dy]
		mov [@@P], eax

		;count = dy
		mov eax, [@@dy]
		mov [@@count], eax

		;initialize
		mov eax, [@@x1]
		mov ebx, [@@y1]
		mov ecx, [@@count]	

		;---------------------------------------------------
		;bresenham's line algorithm:
		;This algorithm is used to draw a line between two points (x1, y1) and (x2, y2). 
		;If the slope >1, yoperator (which can be +1 (increment) or -1 (decrement), dependent of dx) is added to y1.
		;if P<0: x1 = x1 and P = P + 2*dx 
		;if P>0: x1 = x1 + 1 and P = P + 2*dx - 2*dy
		; The loop goes on until y1 has reached y2 or until dy is zero.
		;---------------------------------------------------
		@@bl_loop2:
			call drawPixel, eax,ebx, [@@color]

			add ebx, [@@yoperator]

			push eax
			push ebx

			cmp [@@P], 0					
			jl @@Pkleinerdan0_2
			
			call P_positive, [@@P], [@@dy], [@@dx]
			mov [@@P], eax
			
			pop ebx 
			pop eax 

			add eax, [@@xoperator]

			loop @@bl_loop2
			jmp @@end

			@@Pkleinerdan0_2:
			call P_negative, [@@P], [@@dx]
			mov [@@P], eax

			pop ebx
			pop eax

			loop @@bl_loop2
			jmp @@end


	@@end:

	ret
ENDP drawline


PROC P_positive ;P = P + 2*dy - 2*dx
	ARG @@P: dword, @@dx: dword, @@dy: dword RETURNS eax
	USES ebx
	mov eax, [@@dy]					
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	sub [@@P], eax 

	mov eax, [@@P]
	
	ret
ENDP P_positive
	
PROC P_negative ;P = P + 2*dy 
	ARG @@P: dword, @@dy: dword	RETURNS eax
	USES ebx

	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	add [@@P], eax	

	mov eax, [@@P]
	;call printSignedInteger, eax

	ret
ENDP P_negative


PROC moveline
	ARG @@oldXpos:dword, @@oldYpos:dword, @@newXpos:dword, @@newYpos: dword
	USES eax, ebx, ecx, edx
	mov eax, [@@newXpos]
	mov ebx, [@@newYpos]
	mov ecx, [@@oldXpos]
	mov edx, [@@oldYpos]
	call fillBackground
	;call drawline, 25, 25, ecx, edx, 0
	call drawline, 25, 25, eax, ebx, 99

	ret
ENDP moveline

PROC printIntList
	ARG	@@arrayptr:dword
	USES eax, ebx, ecx, edx
	
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx

	cmp ecx, 0				; if length is 0, skip
	je @@end

	
	mov	ah, 2h 		; Function for printing single characters.
@@printInt:
	add ebx, 4	; go to next integer
	call printSignedInteger, [dword ptr ebx]
	loop @@printInt	; loop over all integers
	
	mov	dl, 0Dh		; Carriage return.
	int	21h
	mov	dl, 0Ah		; New line.
	int 21h
	
	@@end:
	ret
ENDP

PROC appendList
	ARG @@arrayptr:dword, @@new_value: dword
	USES eax, ebx, ecx, edx

	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	add  [dword ptr ebx], 1	; add 1 to the actual value of arrlen_mouse for the print procedure later
	add ecx, 1	;add 1 to counter of this loop
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop

	mov eax, [@@new_value]
	mov [dword ptr ebx], eax	; putting the new value after the last element of the list

	ret

ENDP appendList

PROC get_X1_ofList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	;mov ecx, [ebx]			; get length counter in ecx
	add ebx, 4
	mov eax, [dword ptr ebx]

	ret
ENDP get_X1_ofList

PROC get_X2_ofList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop
	sub ebx, 4
	mov eax, [dword ptr ebx]

	ret
ENDP get_X2_ofList

PROC get_Y1_ofList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	;mov ecx, [ebx]			; get length counter in ecx
	add ebx, 8
	mov eax, [dword ptr ebx]

	ret
ENDP get_Y1_ofList

PROC get_Y2_ofList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop

	mov eax, [dword ptr ebx]

	ret
ENDP get_Y2_ofList



PROC main
	sti
	cld
	
	push ds
	pop	es

	call    mouse_present

	call	setVideoMode, 13h
	finit	; initialize FPU
	
	call	updateColorpallete
	call	fillBackground
	call drawPixel, 0, 300, 99
	;call	bulletPath, 45, 45
	;call	bulletPath, 25, 25
	
	;call 	printIntList, offset arrlen_mousecoord

	;Create a list starting from the adress after the adress of arrlen_mousecoord
	call	appendList, offset arrlen_mousecoord, 20
	call	appendList, offset arrlen_mousecoord, 39
	call	appendList, offset arrlen_mousecoord, 44
	call	appendList, offset arrlen_mousecoord, 7
	call	appendList, offset arrlen_mousecoord, 56
	call	appendList, offset arrlen_mousecoord, 92
	call	appendList, offset arrlen_mousecoord, 43
	call	appendList, offset arrlen_mousecoord, 78
	call	appendList, offset arrlen_mousecoord, 67
	call 	printIntList, offset arrlen_mousecoord

	;X1 is the first element of the list
	call get_X1_ofList, offset arrlen_mousecoord
	call printSignedInteger, eax

	;X2 is the second last element of the list
	call get_X2_ofList, offset arrlen_mousecoord
	call printSignedInteger, eax

	;Y1 is the second element of the list
	call get_Y1_ofList, offset arrlen_mousecoord
	call printSignedInteger, eax

	;Y2 is the last element of the list
	call get_Y2_ofList, offset arrlen_mousecoord
	call printSignedInteger, eax



	;call 	mouse_install, offset save_mousecoord
	;call 	printIntList, offset arrlen_mousecoord
	






	call	waitForSpecificKeystroke, 001Bh	; ESC = 001Bh
	call 	mouse_uninstall
	call	terminateProcess
ENDP main
; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

	palette dd 34, 52, 63, 31, 63, 0, 53, 26, 8, 55, 5, 15, 28, 32, 36				; lucht-gras-muur-doelwit-kogel
	arrlen_mousecoord dd 0
	;arr_mousecoord dd 0

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main