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


PROC main
	sti
	cld
	
	push ds
	pop	es

	call	setVideoMode, 13h
	finit	; initialize FPU
	
	call	updateColorpallete
	call	fillBackground

	call	bulletPath, 45, 45
	call	bulletPath, 25, 26

	call	waitForSpecificKeystroke, 001Bh	; ESC = 001Bh
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