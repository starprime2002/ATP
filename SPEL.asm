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

; Screen constants
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

FRAMECOUNT EQU 1000

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

PROC printUnsignedInteger
	ARG	@@printval:dword    ; input argument
	USES eax, ebx, ecx, edx

	mov eax, [@@printval]
	mov	ebx, 10		; divider
	xor ecx, ecx	; counter for digits to be printed

	; Store digits on stack
	@@getNextDigit:
		inc	ecx         ; increase digit counter
		xor edx, edx
		div	ebx   		; divide by 10
		push dx			; store remainder on stack
		test eax, eax	; check whether zero?
		jnz	@@getNextDigit

		; Write all digits to the standard output
		mov	ah, 2h 		; Function for printing single characters.
	@@printDigits:		
		pop dx
		add	dl,'0'      	; Add 30h => code for a digit in the ASCII table, ...
		int	21h            	; Print the digit to the screen, ...
		loop @@printDigits	; Until digit counter = 0.
		
	ret
ENDP printUnsignedInteger

PROC updatecolorpallete ;moet nog veranderd worden in a loop

	USES eax, ebx, ecx, edx

	mov ebx, offset paletteperso

	mov ah, 0

	@@kleur:
		mov DX, 03C8h ; DAC write port
		push eax
		mov al, ah
		out DX, Al ; write to IO
		pop eax


		mov DX, 03C9h ; DAC data port

		mov AL, [ebx] ; load red value (6-bit)
		out DX, AL ; write red value

		add ebx, 4
		mov AL, [ebx] ; load green value (6-bit)
		out DX, AL ; write green value

		add ebx, 4
		mov AL, [ebx] ; load blue value (6-bit)
		out DX, AL ; write blue value

		add ebx, 4
		

		inc ah
		cmp ah, 5
		jne @@kleur

	ret
ENDP updatecolorpallete

; Fill the background (for mode 13h): blue sky with grass and a wall
PROC fillBackground
	USES 	eax, ecx, edi, edx, ebx

	; Initialize video memory address.
	mov	edi, VMEMADR ; edi is destination adress en is dus hier 0A0000h


	; lucht tekenen
	; Scan the whole video memory and assign the background colour.
	mov	ecx, SCRWIDTH*150 ; ecx = amount of elements = aantal pixels
	mov	al, 0	; indx of the first color to change
	rep	stosb			; stosb (byte) =transfer one byte from eax to edi so that edi increases/updates to point to the next datum(that is situated one byte next to the previous)
						;stosw (word) = transfer two byte (= word)
						;stosd (double word) = tranfer 4 bytes (= double word)

	;gras tekenen
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

	;muur tekenen
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
		add ebx, 299
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

	;doelwit tekenen
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
		add ebx, 297
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

PROC drawpixel
	ARG @@xcoord:dword ,@@ycoord:dword

	USES eax, ebx

	mov	edi, VMEMADR
	;write pixel in ycoord lines down and xcoord lines to the right
	mov eax, [@@ycoord]
	mov ebx, 149
	sub ebx, eax
	mov eax, 320
	imul ebx
	add edi, eax
	add edi, [@@xcoord]
	mov al, 4			; pick the color of the pallet
	
	mov [edi], al
	add edi, 1
	mov [edi], al
	add edi, 1
	mov [edi], al
	add edi, 318
	mov [edi], al
	add edi, 1
	mov [edi], al
	add edi, 1
	mov [edi], al
	add edi, 318
	mov [edi], al
	add edi, 1
	mov [edi], al
	add edi, 1
	mov [edi], al	
	
	ret
ENDP drawpixel

;procedure om de baan te berekenen
PROC kogelbaan
	ARG @@vxbegin:dword, @@vybegin:dword
	LOCAL @@tijd:dword, @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ax:dword, @@ay:dword
	USES eax, ebx

	mov [@@tijd], 0
	mov [@@dt], 1					; Eenheid:	[tijdseenheid]

	mov [@@xpos], 25				;		   	[2^(-5)-ste van een pixels]
	mov [@@ypos], 25				; 		        ""          ""
	mov eax, [@@vxbegin]			;          	[2^(-5)-ste van een pixels per tijdseenheid]
	mov [@@vx], eax
	mov eax, [@@vybegin]			; 		        ""          ""	
	mov [@@vy], eax
	mov [@@ax], 0					;          	[2^(-5)-ste van een pixels per tijdseenheid²]
	mov [@@ay], 9					; NEGATIEF valversnelling (geen 9.81 want FP)	   ""     ""

	call	waitForSpecificKeystroke, 001Bh	; ESC = 001Bh
	@@tijdsloop:
		mov eax, [@@dt]
		add [@@tijd], eax

		mov eax, [@@ax]				; ik weet dat ax toch nul is maar in toekomst zal ook windkracht komen
		mov ebx, [@@dt]				; ik weet ook dat dt toch 1 is (maar zou kunne veranderen) 
		mul ebx
		add [@@vx], eax
		mov eax, [@@ay]
		mov ebx, [@@dt]
		mul ebx
		sub [@@vy], eax

		mov eax, [@@vx]
		mov ebx, [@@dt]
		mul ebx
		add [@@xpos], eax
		mov eax, [@@vy]
		mov ebx, [@@dt]
		imul ebx
		add [@@ypos], eax
		

		mov eax, [@@ypos]
		mov ebx, [@@xpos]

		
		
		call printUnsignedInteger, ebx
		call	drawpixel, ebx, eax
		call wait_VBLANK, 50

		cmp eax, 3					; check grondlimiet
		jle @@einde					; (hou rekening met hoogte kogel)

		cmp ebx, 246				; check muur (zal ongeveer 200 pixels verder zijn) 
		jge @@einde			; (hou rekening met breedte kogel)

		jmp @@tijdsloop
			
		
		

		


	@@einde:

	ret
ENDP kogelbaan

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


PROC main
	sti
	cld
	
	push ds
	pop	es

	call	setVideoMode, 13h
	finit	; initialize FPU
	
	call	updatecolorpallete
	call	fillBackground  ; black = (0,0,0) en white = (63, 63, 63)

	call 	drawpixel, 25, 25

	call	kogelbaan, 45, 40


	call	waitForSpecificKeystroke, 001Bh	; ESC = 001Bh
	call	terminateProcess
ENDP main
; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	
	krachtwind dd 1		; de krachtwaarde van de wind
	hoekwind dd 1		; de hoek van de wind
	massa dd 1			; massa van voorwerp
	v0 dd 8				; beginsnelheid van de worp
	alpha dd 0.6 		; hoek van de worp
	g dd 9.81

	paletteperso dd 34, 52, 63, 31, 63, 0, 53, 26, 8, 55, 5, 15, 28, 32, 36				; lucht-gras-muur

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main



;mfg