; ------------------------------------------------------------------- 
; 80386 
; 32-bit x86 assembly language 
; TASM 
; 
; author:   Stijn Bettens, David Blinder 
; date:     25/09/2017 
; program:  Hello World! 
; ------------------------------------------------------------------- 

IDEAL 
P386 
MODEL FLAT, C 
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT 

INCLUDE "rand.inc"
INCLUDE "mouse.inc"
INCLUDE "image.inc"

; Constants 
VMEMADR EQU 0A0000h     ; video memory address 
SCRWIDTH EQU 320        ; screen witdth 
SCRHEIGHT EQU 200       ; screen height
SKYHEIGHT EQU 150
WALLVERPOS EQU 50
WALLHORPOS EQU 300
WALLHEIGHT EQU 100
WALLWIDTH EQU 12
TARGETVERPOS EQU 80
TARGETHORPOS EQU 298
TARGETHEIGHT EQU 10
TARGETWIDTH EQU 4
ALLONES EQU 4294967295  ; needed for sign extension before dividing 
FRAQBIT EQU 128         ; fractionele bit  
TIMESTEP EQU 64
GRAVITY EQU -150*FRAQBIT
STARTINGX EQU 40*FRAQBIT
STARTINGY EQU 20*FRAQBIT
FULLPALLETESIZE EQU 768     ; bytes in palette
COLORCOUNT EQU 128          ; number of unique colors for palette cycling
PIXELCOUNT EQU 320*200	    ; pixel count

CODESEG 

; Set the video mode 
PROC setVideoMode 
    ARG     @@VM:byte 
    USES    eax 

    movzx ax,[@@VM] 
    int 10h 

    ret 
ENDP setVideoMode 

; Wait for a specific keystroke. 
PROC waitForSpecificKeystroke 
    ARG     @@key:byte 
    USES    eax 

    @@waitForKeystroke: 
        mov ah,00h 
        int 16h 
        cmp al,[@@key] 
    jne @@waitForKeystroke ;if the key u pressed is not @@key (hier ESC= 001Bh), dan zal het niet terminateProcess

    ret 
ENDP waitForSpecificKeystroke

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

PROC printString
    ARG @@string:dword
    USES eax, edx
        mov ah, 09h
        mov edx, [@@string]
        int 21h

	ret
ENDP printString

PROC printIntList
	ARG	@@arrayptr:dword
	USES eax, ebx, ecx, edx
	
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx

	cmp ecx, 0				; if length is 0, skip
	je @@endPrintIntList

	
	mov	ah, 2h 		; Function for printing single characters.
	@@printInt:
	add ebx, 4	; go to next integer
	call printSignedInteger, [dword ptr ebx]
	loop @@printInt	; loop over all integers
	
	mov	dl, 0Dh		; Carriage return.
	int	21h
	mov	dl, 0Ah		; New line.
	int 21h
	
	@@endPrintIntList:
	ret
ENDP printIntList

; Terminate the program. 
PROC terminateProcess
    USES eax 

    call setVideoMode, 03h 
    mov ax,04C00h 
    int 21h

    ret 
ENDP terminateProcess 

; Procedure wait_VBLANK van EXAMPLES\DANCER genomen 
; wait for @@framecount frames 
PROC wait_VBLANK
    ARG @@framecount: word 
    USES eax, ecx, edx 

    mov dx, 03dah                   		; Wait for screen refresh 
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
    ARG @@NumberOfColors:byte
    USES eax, ebx, edx

    mov ebx, offset palette 
	mov ah, 0 

    @@kleur: 
        mov DX, 03C8h                       ; DAC write port
        push eax 
        mov al, ah 
        out DX, Al                          ; write to IO
        pop eax 

        mov DX, 03C9h                       ; DAC data port
        mov AL, [ebx]                       ; load red value (6-bit)
        out DX, AL                          ; write red value
        add ebx, 4
        mov AL, [ebx]                       ; load green value (6-bit)
        out DX, AL                          ; write green value
        add ebx, 4
        mov AL, [ebx]                       ; load blue value (6-bit)
        out DX, AL                          ; write blue value
        add ebx, 4

        inc ah
        cmp ah, [@@NumberOfColors]
        jne @@kleur

    ret
ENDP updateColorpallete

;PROC startscreen
;    USES   eax 
;
;    ret
;ENDP startscreen

; Fill the background (for mode 13h): blue sky with grass and a wall
PROC fillBackground
    USES    eax, ebx, ecx, edx, edi

    ; Initialize video memory address.
    mov edi, VMEMADR                ; edi is destination adress en is dus hier 0A0000h

    ; Draw sky
    mov ecx, SCRWIDTH*SKYHEIGHT     ; ecx = amount of elements = aantal pixels
    mov al, 0                       ; indx of the first color to change
    rep stosb                       ;stosb (byte) =transfer one byte from eax to edi so that edi increases/updates to point to the next datum(that is situated one byte next to the previous)

    ; Draw grass 
    add edi, ecx
    mov ecx, SCRWIDTH*(SCRHEIGHT-SKYHEIGHT)
    mov al, 1
    rep stosb
    
    ; Draw Wall = rectangle (300, 50)-(309, 149)
    mov edx, 0                                  ; Layer of wall 0-99
    @@drawWall:
        mov eax, WALLVERPOS 
        add eax, edx
        mov ebx, 320
        push edx
        mul ebx
        pop edx
        add eax, WALLHORPOS

        mov edi, VMEMADR
        add edi, eax
        mov ecx, WALLWIDTH
        mov al, 2
        rep stosb

        inc edx
        cmp edx, WALLHEIGHT
        jne @@drawWall

    ; Draw target = rectangle (300, 50)-(309, 149)
    mov edx, 0                                  ; Layer of Target
    @@drawTarget:
        mov eax, TARGETVERPOS
        add eax, edx
        mov ebx, 320
        push edx
        mul ebx
        pop edx
        add eax, TARGETHORPOS

        mov edi, VMEMADR
        add edi, eax
        mov ecx, TARGETWIDTH
        mov al, 3
        rep stosb

        inc edx
        cmp edx, TARGETHEIGHT
        jne @@drawTarget

    ret
ENDP fillBackground

;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond
PROC drawPixel                              ; input zijn in fractionele bits
    ARG @@xcoord:dword ,@@ycoord:dword, @@color:byte
    USES eax, ebx, edx, edi

    mov edi, VMEMADR
    ;Change of coordinate system for y   y_draw = 149-y_phys/FRAQBIT
    mov eax, [@@ycoord]                 ; Can be both positive or negative
    mov ebx, FRAQBIT
    xor edx, edx
    cmp eax, 0
    jge @@positive
    mov edx, ALLONES
    @@positive:
    idiv ebx
    mov ebx, 149
    sub ebx, eax
    mov eax, 320
    imul ebx
    add edi, eax
    ;Change of coordinate system for x   x_draw = x_phys/FRAQBIT
    mov eax, [@@xcoord]                     ;can only be positive
    mov ebx, FRAQBIT
    div ebx
    add edi, eax
    mov al, [@@color]                       ; pick the color of the pallet
    mov [edi], al

    ret
ENDP drawPixel

PROC getColor                              ; input zijn in fractionele bits
    ARG @@xcoord:dword ,@@ycoord:dword RETURNS al
    USES ebx, edx, edi

    mov edi, VMEMADR
    ;Change of coordinate system for y   y_draw = 149-y_phys/FRAQBIT
    mov eax, [@@ycoord]                 ; Can be both positive or negative
    mov ebx, FRAQBIT
    xor edx, edx
    cmp eax, 0
    jge @@positive
    mov edx, ALLONES
    @@positive:
    idiv ebx
    mov ebx, 149
    sub ebx, eax
    mov eax, 320
    imul ebx
    add edi, eax
    ;Change of coordinate system for x   x_draw = x_phys/FRAQBIT
    mov eax, [@@xcoord]                     ;can only be positive
    mov ebx, FRAQBIT
    div ebx
    add edi, eax

    xor eax, eax
    mov al, [edi]

    ret
ENDP getColor

;Mandatory for physics simulation
PROC updateValue
    ARG @@value:dword, @@velocity:dword, @@deltat:dword RETURNS eax
    USES ebx, edx

    mov eax, [@@velocity]
    mov ebx, [@@deltat]
    mov edx, 0
    cmp eax, 0
    jge @@positive
    mov edx, ALLONES
    @@positive:
    idiv ebx
    add eax, [@@value]

    ret
ENDP updateValue

PROC deleteBullet                             ; input zijn in fractionele bits
    ARG @@Xpos:dword, @@Ypos:dword
    USES eax, ebx

    mov eax, [@@Xpos]
    mov ebx, [@@Ypos]

    call drawPixel, eax, ebx, 0
    add eax, FRAQBIT
    call drawPixel, eax, ebx, 0
    sub eax, FRAQBIT
    add ebx, FRAQBIT
    call drawPixel, eax, ebx, 0
    sub ebx, FRAQBIT
    sub eax, FRAQBIT
    call drawPixel, eax, ebx, 0
    add eax, FRAQBIT
    sub ebx, FRAQBIT
    call drawPixel, eax, ebx, 0

    ret
ENDP deleteBullet

PROC drawBullet                             ; input zijn in fractionele bits
    ARG @@Xpos:dword, @@Ypos:dword, @@colorBullet:dword
    USES eax, ebx

    ;Delete previous bullet
    mov eax, [@@Xpos]
    mov ebx, [@@Ypos]

    call drawPixel, eax, ebx, [@@colorBullet]
    add eax, FRAQBIT
    call drawPixel, eax, ebx, 5
    sub eax, FRAQBIT
    add ebx, FRAQBIT
    call drawPixel, eax, ebx, 5
    sub ebx, FRAQBIT
    sub eax, FRAQBIT
    call drawPixel, eax, ebx, 5
    add eax, FRAQBIT
    sub ebx, FRAQBIT
    call drawPixel, eax, ebx, 5

    ret
ENDP drawBullet

; Checks    if the bullet collided with wall or ground
;           if the bullet is out of border
PROC checkCollision                                     ;te optimisere
    ARG @@xpos:dword, @@ypos:dword RETURNS ecx
    USES eax, ebx, edx

    xor ecx, ecx

    @@groundCheck:
        mov ebx, [@@xpos]
        mov edx, [@@ypos]
        mov eax, 1*FRAQBIT
        sub edx, eax
        call getColor, ebx, edx
        cmp eax, 1
        jne @@targetCheck
        mov ecx, 1
        jmp @@collisionEnd

    @@targetCheck:                        ; Wall = (300,0)-(309,99)
        mov ebx, [@@xpos]
        mov edx, [@@ypos]
        mov eax, 1*FRAQBIT
        add ebx, eax
        call getColor, ebx, edx
        cmp eax, 3
        jne @@wallCheck
        call printSignedInteger, eax
        mov ecx, 2
        jmp @@collisionEnd

    @@wallCheck:                        ; Wall = (300,0)-(309,99)
        mov ebx, [@@xpos]
        mov edx, [@@ypos]
        mov eax, 1*FRAQBIT
        add ebx, eax
        call getColor, ebx, edx
        cmp eax, 2
        jne @@onTheWallCheck
        mov ecx, 3
        jmp @@collisionEnd

    @@onTheWallCheck:                        ; Wall = (300,0)-(309,99)
        mov ebx, [@@xpos]
        mov edx, [@@ypos]
        mov eax, 1*FRAQBIT
        sub edx, eax
        call getColor, ebx, edx
        cmp eax, 2
        jne @@upperCheck
        mov ecx, 4
        jmp @@collisionEnd

    mov ebx, [@@xpos]
    mov edx, [@@ypos]
    @@upperCheck:
        cmp edx, 148*FRAQBIT
        jle @@leftBoundCheck
        mov ecx, 5
        jmp @@collisionEnd

    @@leftBoundCheck:
        cmp ebx, 1*FRAQBIT
        jge @@rightBoundCheck
        mov ecx, 6
        jmp @@collisionEnd

    @@rightBoundCheck:
        cmp ebx, 318*FRAQBIT
        jle @@noCollision
        mov ecx, 7
        jmp @@collisionEnd

    @@noCollision:
        mov ecx, 0
        jmp @@collisionEnd

    @@collisionEnd:
    ret
ENDP checkCollision

; To replace bulllet once collided
PROC replaceBullet
    ARG @@collisionType:dword, @@Xpos:dword, @@Ypos:dword, @@colorBullet:dword
    LOCAL @@waittime:dword
    USES ecx

    mov [@@waittime], 50
    call deleteBullet, [@@Xpos], [@@Ypos]

    mov ecx, [@@collisionType]

    cmp ecx, 1
    je @@groundCase
    cmp ecx, 2
    je @@targetCase
    cmp ecx, 3
    je @@wallCase
    cmp ecx, 4
    je @@onTheWallCase
    cmp ecx, 5
    je @@upperLimitCase
    cmp ecx, 6
    je @@leftLimitCase
    cmp ecx, 7
    je @@rightLimitCase

    @@groundCase:
        call drawBullet, [@@Xpos], 1*FRAQBIT, [@@colorBullet]
        call printString, offset msgGround
        call wait_VBLANK, [@@waittime]
        call deleteBullet, [@@Xpos], 1*FRAQBIT
        jmp @@endReplacement
        
    @@targetCase:
        call drawBullet, (TARGETHORPOS-2)*FRAQBIT, [@@Ypos], [@@colorBullet]
        call printString, offset msgSucces
        call wait_VBLANK, [@@waittime]
        call deleteBullet, (TARGETHORPOS-2)*FRAQBIT, [@@Ypos]
        jmp @@endReplacement

    @@wallCase:
        call drawBullet, (WALLHORPOS-2)*FRAQBIT, [@@Ypos], [@@colorBullet]
        call printString, offset msgWall
        call wait_VBLANK, [@@waittime]
        call deleteBullet, (WALLHORPOS-2)*FRAQBIT, [@@Ypos]
        jmp @@endReplacement
        
    @@onTheWallCase:
        call drawBullet, [@@Xpos], (149-WALLVERPOS+2)*FRAQBIT, [@@colorBullet]    
        call printString, offset msgWall
        call wait_VBLANK, [@@waittime]
        call deleteBullet, [@@Xpos], 101*FRAQBIT
        jmp @@endReplacement

    @@upperLimitCase:
        call drawBullet, [@@Xpos], 148*FRAQBIT, [@@colorBullet]
        call printString, offset msgTooHigh
        call wait_VBLANK, [@@waittime]
        call deleteBullet, [@@Xpos], 148*FRAQBIT
        jmp @@endReplacement
    
    @@leftLimitCase:
        call drawBullet, 1*FRAQBIT, [@@Ypos], [@@colorBullet]
        call printString, offset msgOutOfBound
        call wait_VBLANK, [@@waittime]
        call deleteBullet, 1*FRAQBIT, [@@Ypos]
        jmp @@endReplacement

    @@rightLimitCase:
        call drawBullet, 318*FRAQBIT, [@@Ypos], [@@colorBullet]
        call printString, offset msgOutOfBound
        call wait_VBLANK, [@@waittime]
        call deleteBullet, 318*FRAQBIT, [@@Ypos]
        jmp @@endReplacement

    @@endReplacement:
        call drawBullet, STARTINGX, STARTINGY, [@@colorBullet]

    ret
ENDP replaceBullet

;Initialize a throw
PROC bulletPath
    ARG @@vxbegin:dword, @@vybegin:dword, @@colorBullet:dword
    LOCAL @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ay:dword
    USES eax, ebx, ecx, edx

    mov [@@dt], TIMESTEP            ; [1/time unit] we work with the inverse to dodge decimal points
	;Startingposition
    mov [@@xpos], STARTINGX        ;[distance unit] 
    mov [@@ypos], STARTINGY        ;[distance unit]
    mov eax, [@@vxbegin]            ;[distance/time]
    mov [@@vx], eax                 ;[pixels/time]
    mov eax, [@@vybegin]            ;[distance/time]
    mov [@@vy], eax
    mov [@@ay], GRAVITY         	;[distance/time²] downward accelaration due to "gravity"

    xor ecx, ecx
    @@tijdsloop: 

        ;xpos += vx*dt
        call updateValue, [@@xpos], [@@vx], [@@dt]
        mov [@@xpos], eax
        ;ypos += vy*dt
        call updateValue, [@@ypos], [@@vy], [@@dt]
        mov [@@ypos], eax
        ;vy += ay*dt 
        call updateValue, [@@vy], [@@ay], [@@dt]
        mov [@@vy], eax

        call checkCollision, [@@xpos], [@@ypos]
        cmp ecx, 0
        jne @@endPath

    
        ;Bring back old coordinations
        pop ebx
        pop eax
        call deleteBullet, eax, ebx
        call drawBullet, [@@xpos], [@@ypos], [@@colorBullet]
        
        ;Store new coordinations for next loop
        mov eax, [@@xpos]
        mov ebx, [@@ypos]
        push eax
        push ebx

        ;Animation
        call wait_VBLANK, 1                     ; [*10ms] animation purposes
                                                ; = FRAQBITS time unit
        jmp @@tijdsloop 

        @@endPath:
        ;Bring back old coordinations
        pop ebx
        pop eax
        call replaceBullet, ecx, eax, ebx, [@@colorBullet]
    ret 
ENDP bulletPath 

PROC drawTrajectory
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@color:dword
    LOCAL @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ay:dword
	USES eax, ebx, ecx


	mov eax, [@@y2]
	mov ebx, [@@y1]
	sub eax, ebx
	push eax
	mov eax, [@@x2]
	mov ebx, [@@x1]
	sub eax, ebx
	push eax

    mov [@@dt], TIMESTEP            ; [1/time unit] we work with the inverse to dodge decimal points
	;Startingposition
    mov [@@xpos], STARTINGX        ;[distance unit] 
    mov [@@ypos], STARTINGY        ;[distance unit]
	pop eax
    mov [@@vx], eax                 ;[pixels/time]
	pop eax
    mov [@@vy], eax
    mov [@@ay], GRAVITY         	;[distance/timeÂ²] downward accelaration due to "gravity" -9.81 = -10 here

    mov ecx, 4
    @@drawloop:
        push ecx
	    mov ecx, TIMESTEP/16
		@@tijdsloop:
			;xpos += vx*dt
			call updateValue, [@@xpos], [@@vx], [@@dt]
			mov [@@xpos], eax
			;ypos += vy*dt
			call updateValue, [@@ypos], [@@vy], [@@dt]
			mov [@@ypos], eax
			;vy += ay*dt 
			call updateValue, [@@vy], [@@ay], [@@dt]
			mov [@@vy], eax

			loop @@tijdsloop

		mov eax, [@@xpos]
		mov ebx, [@@ypos]
		call drawPixel, eax, ebx, [@@color]
        add eax, FRAQBIT
		call drawPixel, eax, ebx, [@@color]
        sub ebx, FRAQBIT
		call drawPixel, eax, ebx, [@@color]

        pop ecx
        loop @@drawloop

	ret
ENDP drawTrajectory

PROC appendList
	ARG @@arrayptr:dword, @@newB:dword, @@newX:dword, @@newY:dword
	USES eax, ebx, ecx

	;Coordinates transformation from video mode to our base
	; x-coordinate
	mov eax, [@@newX]
    mov ebx, FRAQBIT/2
    mul ebx
	push eax
	; y-coordinate
	mov eax, [@@newY]
	mov ebx, 149
	sub ebx, eax
	mov eax, ebx
    mov ebx, FRAQBIT
    mul ebx
	push eax

	mov eax, [@@arrayptr]			; store pointer in ebx
	add [dword ptr eax], 3			; add 1 to the actual value of arrlen_mouse for the print procedure later
	mov ecx, [eax]					; get length counter in ecx

	@@arrayloop:
		add eax, 4
		loop @@arrayloop

	pop ebx 
	mov [dword ptr eax], ebx
	sub eax, 4
	pop ebx
	mov [dword ptr eax], ebx
	sub eax, 4
	mov ebx, [@@newB]
	mov [dword ptr eax], ebx

	ret
ENDP appendList

;---------------------------------------------------------
;This is for boolean_mouse_dragged

PROC getOfList
	ARG @@arrayptr:dword, @@index:dword RETURNS eax
	USES ebx

	mov eax, [@@index]
	mov ebx, 4
	mul ebx

	mov ebx, [@@arrayptr]	; store pointer in ebx
	add ebx, eax
	mov eax, [dword ptr ebx]

	ret
ENDP getOfList

PROC getDeltaX
	ARG @@x1:dword, @@x2:dword RETURNS eax
	LOCAL @@dx: dword
	
	;dx = x2 - x1
	mov eax, [@@x2]
	sub eax, [@@x1]
	mov [@@dx], eax

	mov eax, STARTINGX
	sub eax, [@@dx]

    @@end:
	ret
ENDP getDeltaX

PROC getDeltaY
	ARG @@y1:dword, @@y2:dword RETURNS eax
	LOCAL @@dy: dword

	;dy = y2 - y1
	mov eax, [@@y2]
	sub eax, [@@y1]
	mov [@@dy], eax

	mov eax, STARTINGY
	sub eax, [@@dy]

    cmp eax, -15*STARTINGY/8
    jge @@end
    mov eax, -15*STARTINGY/8

    @@end:
	ret
ENDP getDeltaY

PROC moveElementsOfList
	ARG @@arrayptr:dword
	USES eax, ebx, ecx
	
	mov ebx, [@@arrayptr]	; store pointer of arrlen in ebx

	sub  [dword ptr ebx], 3	; sub 3 to the actual value of arrlen_mouse so the length becomes 9 for the print procedure later

	add ebx, 12		;Go to the 3rd element
	mov ecx, 6		; counter for the loop

	@@arrayloop:
		add ebx, 16					;go 4 elements further
		mov eax, [ebx]				;store this element in eax
		sub ebx, 12					;go 3 elements back
		mov [dword ptr ebx], eax 	;replace this element with the element in eax	
		loop @@arrayloop
	
	ret
ENDP moveElementsOfList

PROC boolean_mouse_dragged
	USES eax, ebx, ecx, edx
	LOCAL @@result: dword, @@boolean1:dword, @@x1: dword, @@y1: dword, @@boolean2: dword, @@x2: dword, @@y2: dword, @@oldBoolean: dword, @@oldXpos: dword, @@oldYpos: dword, @@a: dword, @@b: dword, @@colorBullet:dword

	;Put initially result on 0
	mov [@@result], 0

	;Show mouse pointer
	mov ax, 1
	int 33h


	movzx ebx, bl
	movzx ecx, cx
   	movzx edx, dx

	call appendList, offset arrlen_mousecoord, ebx, ecx, edx


	;First check if it's an array of 12 elements
	; if arrlen_mousecoord >=3:
	mov ecx, [offset arrlen_mousecoord]
	cmp ecx, 12
	jl @@skipit
	call moveElementsOfList, offset arrlen_mousecoord
	;call printIntList, offset arrlen_mousecoord	

	;Get first boolean
	call getOfList, offset arrlen_mousecoord, 1
	mov [@@boolean1], eax

	;Get old boolean
	call getOfList, offset arrlen_mousecoord, 4
	mov [@@oldBoolean], eax

	;Get new boolean
	call getOfList, offset arrlen_mousecoord, 7
	mov [@@boolean2], eax

	;Get x1
	call getOfList, offset arrlen_mousecoord, 2
	mov [@@x1], eax
	
	;Get y1
	call getOfList, offset arrlen_mousecoord, 3
	mov [@@y1], eax

	;Get x2
	call getOfList, offset arrlen_mousecoord, 8
	mov [@@x2], eax

	;Get y2
	call getOfList, offset arrlen_mousecoord, 9
	mov [@@y2], eax

	;Get oldXpos
	call getOfList, offset arrlen_mousecoord, 5
	mov [@@oldXpos], eax

	;Get oldYpos
	call getOfList, offset arrlen_mousecoord, 6
	mov [@@oldYpos], eax

	;if boolean1 is 1 do this
	cmp [@@boolean1], 1
	jne @@reset

	;Draw a pixel on the place where the mouse has first clicked
	call drawPixel, [@@x1], [@@y1], 70

	;Tranfrom the mousecoordinates into coordinates for the trajectory of the throw
	call getDeltaX, [@@x1], [@@oldXpos]
	mov [@@a], eax

	call getDeltaY, [@@y1], [@@oldYpos]
	mov [@@b], eax

	call drawTrajectory, STARTINGX, STARTINGY, [@@a], [@@b], 0


	call getDeltaX, [@@x1], [@@x2]
	mov [@@a], eax
	call getDeltaY, [@@y1], [@@y2]
	mov [@@b], eax


	call drawTrajectory, STARTINGX, STARTINGY, [@@a], [@@b], 4

	;The state where the mouse is let go is: [oldBoolean = 1 and boolean2 = 0]
	cmp [@@oldBoolean], 1
	jne @@skipit
	cmp [@@boolean2], 0
	jne @@skipit
	mov [@@result], 1

	@@skipit:

	cmp [@@result], 1
	jne @@return

	;Hide visible mouse pointer
	mov ax, 2
	int 33h 

	;Hide trajectoryline + hide startpoint 
	call drawTrajectory, STARTINGX, STARTINGY, [@@a], [@@b], 0

    ;Color bullet
    call rand_init
    call rand
    mov [@@colorBullet], eax
    call drawBullet, STARTINGX, STARTINGY, [@@colorBullet]

	;Throw bullet
	call bulletPath, [@@a], [@@b], [@@colorBullet]

	@@reset:
		mov ebx, offset arrlen_mousecoord
		mov [dword ptr ebx], 0
	@@return:

	ret

	
ENDP boolean_mouse_dragged

PROC main
    sti
    cld

    push ds
    pop es

    call    setVideoMode, 13h
    finit   ; initialize FPU

    call    updateColorpallete, 6
    call    fillBackground

	call 	mouse_install, offset boolean_mouse_dragged
    call    waitForSpecificKeystroke, 001Bh ; ESC = 001Bh
    call    processFile, offset image_file
    call    waitForSpecificKeystroke, 001Bh ; ESC = 001Bh
    call    terminateProcess

ENDP main 

; -------------------------------------------------------------------
; DATA
; ------------------------------------------------------------------- 
DATASEG
	msgGround	    db "On the ground!", 13, 10, '$'
	msgWall	        db "Miss!", 13, 10, '$'
	msgSucces	    db "Succes!", 13, 10, '$'
	msgTooHigh	    db "Too high!", 13, 10, '$'
    msgOutOfBound   db "Out of bound!", 13, 10, '$'
    palette         dd 34, 52, 63                           ;sky
                    dd 31, 63, 0                            ;grass
                    dd 53, 26, 8                            ;wall
                    dd 55, 5, 15                            ;target
                    dd 127, 63, 40                           ;Aimline
                    dd 32, 32, 32                           ;Bullet
	image_file db "winscr.bin", 0
	image_fill db "win.bin", 0
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
    arrlen_mousecoord dd 0
    
; -------------------------------------------------------------------
UDATASEG
	imagedata db PIXELCOUNT dup (?)
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h


END main 