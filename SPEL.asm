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


;PROC cos 							;taylorbenadering cosinus
;	ARG @@hoek:dword RETURNS ecx
;	USES eax, ebx, edx
;
;	mov ecx, 1						;cos(x) = 1 - x*x/2 + x*x*x*x/24 
;
;	mov eax, [@@hoek]
;	mul eax
;	mul eax
;	mul eax
;	mov ebx, 24
;	div ebx
;	add ecx, eax
;
;	mov eax, [@@hoek]
;	mul eax
;	mov ebx, 2
;	div ebx
;	sub ecx, eax
;		
;	ret
;ENDP cos	

;PROC landingshoogte
;	ARG @@alpha:dword, @@v0:dword RETURNS eax
;	LOCAL @@vx:dword, @@vy:dword, @@ax:dword, @@ay:dword 
;	USES ebx
;
;	;vx
;	call cos, [@@alpha]	       ;retwaarde is in ecx
;	mov eax, ecx
;	mov ebx, [@@v0]
;	mul ebx, 
;	mov [@@vx], eax
;
;	;vy
;	mov ebx, [@@alpha]			; sin(hoek) = cos(hoek - pi/2)
;	sub ebx, 1.570796
;	call cos, ebx	       
;	mov eax, ecx
;	mov ebx, [@@v0]
;	mul ebx, 
;	mov [@@vy], eax

	;ax
;	call cos, hoekwind
;	mov eax, ecx
;	mov ebx, krachtwind
;	mul ebx
;	mov ebx, massa
;	div ebx
;	mov [@@ax], eax

	;ay
;	mov ebx, hoekwind
;	sub ebx, 1.570796
;	call cos, ebx
;	mov eax, ecx
;	mov ebx, krachtwind
;	mul ebx
;	mov ebx, massa
;	div ebx
;	sub eax, g
;	mov [@@ay], eax

	
;	ret

;ENDP landingshoogte

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
		mov ecx, [ebx]
		call printUnsignedInteger, ecx

		add ebx, 4
		mov AL, [ebx] ; load green value (6-bit)
		out DX, AL ; write green value
		mov ecx, [ebx]
		call printUnsignedInteger, ecx

		add ebx, 4
		mov AL, [ebx] ; load blue value (6-bit)
		out DX, AL ; write blue value
		mov ecx, [ebx]
		call printUnsignedInteger, ecx

		add ebx, 4
		
		inc ah
		cmp ah, 4	;4 is aantal kleuren die we hebben in pallet
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
		add ebx, 249
		mov	edi, VMEMADR
		add edi, ebx
		mov al, 2
		mov ecx, 20
			@@breedtemuur:
				mov [edi], al
				inc edi
				dec ecx
				cmp ecx, 0
				jne @@breedtemuur
		inc edx
		cmp edx, 100
		jne @@hoogtemuur

	ret
ENDP fillBackground

PROC drawpixel
	ARG @@ycoord:dword ,@@xcoord:dword
	USES eax, ebx

	mov	edi, VMEMADR
	;write pixel in ycoord lines down and xcoord lines to the right
	mov ebx, [@@ycoord]
	mov eax, 320
	mul ebx
	add edi, eax
	add edi, [@@xcoord]
	mov al, 3			; pick the color of the pallet
	mov [edi], al

	ret
ENDP drawpixel

PROC main
	sti
	cld
	
	push ds
	pop	es

	call	setVideoMode, 13h
	finit	; initialize FPU

	call	updatecolorpallete
	call	fillBackground  ; black = (0,0,0) en white = (63, 63, 63)
	call 	drawpixel, 1, 1 ; limits are: (0,0) to (199,319)

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

	paletteperso dd 34, 52, 63, 31, 63, 0, 53, 26, 8, 0, 0, 0			; lucht-gras-muur
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main

; here is a comment heehekbeb
;another comment hihihihi


