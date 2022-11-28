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
	;call mouse_install, offset mouseHandler
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
	
	;@@mousepressed:
	;mov ecx, 0
	and bl, 1			; check if right button of mouse is clicked
	jz @@skipit			; only execute if a mousebutton is pressed
 
	
	call	bulletPath, 45, 45
	;check if mouse is still clicked
	;call wait_VBLANK,2
	;add ecx,1
	;call printUnsignedInteger,ecx
	;cmp ecx, 10
	;jle @@mousepressed


    ;movzx eax, dx		; get mouse height
	;mov edx, SCRWIDTH
	;mul edx				; obtain vertical offset in eax
	;sar cx, 1			; horizontal cursor position is doubled in input 
	;add ax, cx			; add horizontal offset

	;mov	edi, VMEMADR
	;add edi,eax	
	;mov al,3			;color kogel
	;mov [edi], al

	@@skipit:
    ret
ENDP mouseHandler
	

PROC getcoordmouse
	USES    eax, ebx, ecx, edx

	and bl, 2			; check if right button of mouse is clicked
	jz @@skip			; only execute if a mousebutton is pressed

	movzx eax, dx		; get mouse height
	mov edx, SCRWIDTH
	mul edx				; obtain vertical offset in eax
	sar cx, 1			; horizontal cursor position is doubled in input 
	add ax, cx			; add horizontal offset

	mov	edi, VMEMADR
	add edi,eax	
	mov al,3			;color kogel
	mov [edi], al
	
	@@skip:
    ret
ENDP getcoordmouse


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
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword
	LOCAL @@P: dword, @@dx:dword, @@dy:dword
	USES eax, ebx, edx

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

		
		mov eax, [@@dx]
		mov ebx, [@@dy]
		cmp eax, ebx
		jge @@slope_less_or_equal_1a
		jmp @@slope_greater_1a

		;a) slope<=1, then dx>=dy
		@@slope_less_or_equal_1a:
		;P = 2dy - dx
		mov eax, [@@dy]
		mov ebx, 2
		mul ebx
		sub eax, [@@dx]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case1a, [@@x1], [@@y1], [@@x2], [@@dx], [@@dy], [@@P]
		jmp @@end

		;b) slope>1, then dx<dy
		@@slope_greater_1a:
		;P = 2dx - dy
		mov eax, [@@dx]
		mov ebx, 2
		mul ebx
		sub eax, [@@dy]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case1b, [@@x1], [@@y1], [@@y2], [@@dx], [@@dy], [@@P]
		jmp @@end

	;Case 2: dx negative and dy positive, then slope negative
	@@case2:
	cmp [@@dy],0
	jl @@case4

	;first negate dx to make it positive
	neg [@@dx]

		mov eax, [@@dx]
		mov ebx, [@@dy]
		cmp eax, ebx
		jge @@slope_greater_or_equal_minus_1a
		jmp @@slope_less_minus_1a

		;a) slope>=-1, then dx>=dy
		@@slope_greater_or_equal_minus_1a:
		;P = 2dy - dx
		mov eax, [@@dy]
		mov ebx, 2
		mul ebx
		sub eax, [@@dx]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case2a, [@@x1], [@@y1], [@@x2], [@@dx], [@@dy], [@@P]
		jmp @@end

		;b) slope<-1, then dx<dy
		@@slope_less_minus_1a:
		;P = 2dx - dy
		mov eax, [@@dx]
		mov ebx, 2
		mul ebx
		sub eax, [@@dy]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case2b, [@@x1], [@@y1], [@@y2], [@@dx], [@@dy], [@@P]
		jmp @@end



	;Case 3: dx positive and dy negative, then slope negative
	@@case3:
	;first negate dy to make it positive
	neg [@@dy]

		mov eax, [@@dx]
		mov ebx, [@@dy]
		cmp eax, ebx
		jge @@slope_greater_or_equal_minus_1b
		jmp @@slope_less_minus_1b

		;a) slope>=-1, then dx>=dy
		@@slope_greater_or_equal_minus_1b:
		;P = 2dy - dx
		mov eax, [@@dy]
		mov ebx, 2
		mul ebx
		sub eax, [@@dx]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case3a, [@@x1], [@@y1], [@@x2], [@@dx], [@@dy], [@@P]
		jmp @@end

		;b) slope<-1, then dx<dy
		@@slope_less_minus_1b:
		;P = 2dx - dy
		mov eax, [@@dx]
		mov ebx, 2
		mul ebx
		sub eax, [@@dy]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case3b, [@@x1], [@@y1], [@@y2], [@@dx], [@@dy], [@@P]
		jmp @@end

	;Case 4: dx negative and dy negative, then slope positive
	@@case4:
	;first negate dx and dy to make them positive
	neg [@@dx]
	neg [@@dy]

		mov eax, [@@dx]
		mov ebx, [@@dy]
		cmp eax, ebx
		jge @@slope_less_or_equal_1b
		jmp @@slope_greater_1b

		;a) slope<=1, then dx>=dy
		@@slope_less_or_equal_1b:
		;P = 2dy - dx
		mov eax, [@@dy]
		mov ebx, 2
		mul ebx
		sub eax, [@@dx]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case4a, [@@x1], [@@y1], [@@x2], [@@dx], [@@dy], [@@P]
		jmp @@end

		;b) slope>1, then dx<dy
		@@slope_greater_1b:
		;P = 2dx - dy
		mov eax, [@@dx]
		mov ebx, 2
		mul ebx
		sub eax, [@@dy]
		mov [@@P], eax

		;draw line with bresenham's line algorithm 
		call bl_algorithm_case4b, [@@x1], [@@y1], [@@y2], [@@dx], [@@dy], [@@P]
		jmp @@end

	@@end:
	ret
ENDP drawline

PROC bl_algorithm_case1a
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	inc eax							;x1 = x1 + 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: y1 = y1 and P = P + 2*dy
	jl @@Pkleinerdan0
	
	mov eax, [@@dy]					;if P>0: y1 = y1 + 1 and P = P + 2*dy - 2*dx
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	sub [@@P], eax 
	
	pop ebx 
	pop eax 
	inc ebx
	
	cmp eax, [@@x2]
	jle @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	add [@@P], eax	
	pop ebx
	pop eax
	cmp eax, [@@x2]
	jle @@whileloop

	@@ending:
	ret
ENDP bl_algorithm_case1a

PROC bl_algorithm_case1b
	ARG @@x1:dword, @@y1:dword, @@y2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	inc ebx							;y1 = y1 + 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: x1 = x1 and P = P + 2*dx
	jl @@Pkleinerdan0
	
	mov eax, [@@dx]					;if P>0: x1 = x1 + 1 and P = P + 2*dx - 2*dy
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	sub [@@P], eax ; P=-2
	
	pop ebx ; 0
	pop eax ; 1
	inc eax
	
	cmp ebx, [@@y2]
	jle @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	add [@@P], eax
	pop ebx
	pop eax

	cmp ebx, [@@y2]
	jle @@whileloop
	

	@@ending:
	ret
ENDP bl_algorithm_case1b

PROC bl_algorithm_case2a
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	dec eax							;x1 = x1 - 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: y1 = y1 and P = P + 2*dy
	jl @@Pkleinerdan0
	
	mov eax, [@@dy]					;if P>0: y1 = y1 + 1 and P = P + 2*dy - 2*dx
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	sub [@@P], eax 
	
	pop ebx 
	pop eax 
	inc ebx
	
	cmp eax, [@@x2]
	jge @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	add [@@P], eax	
	pop ebx
	pop eax
	cmp eax, [@@x2]
	jge @@whileloop

	@@ending:
	ret
ENDP bl_algorithm_case2a

PROC bl_algorithm_case2b
	ARG @@x1:dword, @@y1:dword, @@y2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	inc ebx							;y1 = y1 + 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: x1 = x1 and P = P + 2*dx
	jl @@Pkleinerdan0
	
	mov eax, [@@dx]					;if P>0: x1 = x1 - 1 and P = P + 2*dx - 2*dy
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	sub [@@P], eax ; P=-2
	
	pop ebx ; 0
	pop eax ; 1
	dec eax
	
	cmp ebx, [@@y2]
	jle @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	add [@@P], eax
	pop ebx
	pop eax

	cmp ebx, [@@y2]
	jle @@whileloop
	

	@@ending:
	ret
ENDP bl_algorithm_case2b

PROC bl_algorithm_case3a
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	inc eax							;x1 = x1 + 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: y1 = y1 and P = P + 2*dy
	jl @@Pkleinerdan0
	
	mov eax, [@@dy]					;if P>0: y1 = y1 - 1 and P = P + 2*dy - 2*dx
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	sub [@@P], eax 
	
	pop ebx 
	pop eax 
	dec ebx
	
	cmp eax, [@@x2]
	jle @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	add [@@P], eax	
	pop ebx
	pop eax
	cmp eax, [@@x2]
	jle @@whileloop

	@@ending:
	ret
ENDP bl_algorithm_case3a

PROC bl_algorithm_case3b
	ARG @@x1:dword, @@y1:dword, @@y2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	dec ebx							;y1 = y1 - 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: x1 = x1 and P = P + 2*dx
	jl @@Pkleinerdan0
	
	mov eax, [@@dx]					;if P>0: x1 = x1 + 1 and P = P + 2*dx - 2*dy
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	sub [@@P], eax ; P=-2
	
	pop ebx ; 0
	pop eax ; 1
	inc eax
	
	cmp ebx, [@@y2]
	jge @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	add [@@P], eax
	pop ebx
	pop eax

	cmp ebx, [@@y2]
	jge @@whileloop
	

	@@ending:
	ret
ENDP bl_algorithm_case3b

PROC bl_algorithm_case4a
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	dec eax							;x1 = x1 - 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: y1 = y1 and P = P + 2*dy
	jl @@Pkleinerdan0
	
	mov eax, [@@dy]					;if P>0: y1 = y1 - 1 and P = P + 2*dy - 2*dx
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	sub [@@P], eax 
	
	pop ebx 
	pop eax 
	dec ebx
	
	cmp eax, [@@x2]
	jge @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	add [@@P], eax	
	pop ebx
	pop eax
	cmp eax, [@@x2]
	jge @@whileloop

	@@ending:
	ret
ENDP bl_algorithm_case4a

PROC bl_algorithm_case4b
	ARG @@x1:dword, @@y1:dword, @@y2:dword, @@dx:dword, @@dy:dword, @@P:dword
	USES eax, ebx, edx

	mov eax, [@@x1]
	mov ebx, [@@y1]

	@@whileloop:
	call drawPixel, eax,ebx, 3
	dec ebx							;y1 = y1 - 1
	
	push eax
	push ebx
	cmp [@@P], 0					;if P<0: x1 = x1 and P = P + 2*dx
	jl @@Pkleinerdan0
	
	mov eax, [@@dx]					;if P>0: x1 = x1 - 1 and P = P + 2*dx - 2*dy
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	sub [@@P], eax ; P=-2
	
	pop ebx ; 0
	pop eax ; 1
	dec eax
	
	cmp ebx, [@@y2]
	jge @@whileloop
	jmp @@ending

	@@Pkleinerdan0:
	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	add [@@P], eax
	pop ebx
	pop eax

	cmp ebx, [@@y2]
	jge @@whileloop
	

	@@ending:
	ret
ENDP bl_algorithm_case4b

PROC main
	sti
	cld
	
	push ds
	pop	es

	call    mouse_present

	call	setVideoMode, 13h
	finit	; initialize FPU

	;call mouse_install, offset mouseHandler
	;call mouse_install, offset getcoordmouse
	
	
	call	updateColorpallete
	call	fillBackground

	call drawline, 25, 25, 100, 25 
	call drawline, 25, 25, 50, 100
	call drawline, 25, 25, 100, 50  
	call drawline, 25, 25, 100, 100 
	call drawline, 25, 25, 25, 100
	call drawline, 25, 25, -75, 50
	call drawline, 25, 25, -25, 100
	call drawline, 25, 25, 100, -25
	call drawline, 25, 25, 50, -25
	call drawline, 25, 25, -25, 0
	call drawline, 25, 25, 0, -25






	;call	bulletPath, 45, 45
	;call	bulletPath, 25, 25

	call	waitForSpecificKeystroke, 001Bh	; ESC = 001Bh
	call mouse_uninstall
	call	terminateProcess
ENDP main
; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

	palette dd 34, 52, 63, 31, 63, 0, 53, 26, 8, 55, 5, 15, 28, 32, 36				; lucht-gras-muur-doelwit-kogel

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main