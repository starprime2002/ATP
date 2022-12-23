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
GRAVITY EQU -200*FRAQBIT
STARTINGX EQU 40*FRAQBIT
STARTINGY EQU 20*FRAQBIT
XCONV EQU 1                 ;converts de dx to vstart_x     (vx = x*XCONV)
YCONV EQU 1                 ;converts de dy to vstart_y     (vy = x*YCONV)

;--------------------------------------------------------------------------------------------------------
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

; Source: Assembling programming compendium
PROC displayString
    ARG @@row:DWORD, @@column:DWORD, @@offset:DWORD
    USES EAX, EBX, EDX

    mov edx, [@@row]            ; row in EDX
    mov ebx, [@@column]         ; column in EBX

    mov ah, 02h                 ; set cursor position
    shl edx, 08h                ; row in DH (00H is top)
    mov dl, bl                  ; column in DL (00H is left)
    mov bh, 0                   ; page number in BH
    int 10h                     ; raise interrupt

    mov ah, 09h                 ; write string to standard output
    mov edx, [@@offset]         ; offset of ’$’-terminated string in EDX
    int 21h                     ; raise interrupt

    RET
ENDP displayString

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

MACRO startscreen

    call processFile, offset StartSCR
    call displayString, 96, 106, offset msgStart
    call waitForSpecificKeystroke, 20h ; space bar = 001Bh

ENDM startscreen

; Fill the background (for mode 13h): blue sky with grass and a wall
PROC fillBackground
    USES    eax, ebx, ecx, edx, edi

    ; Initialize video memory address.
    mov edi, VMEMADR                ; edi is destination adress: 0A0000h

    ; Draw sky
    mov ecx, SCRWIDTH*SKYHEIGHT     ; ecx = amount of elements = amount of pixels
    mov al, 0                       ; index of the first color to change
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
        mov ebx, SCRWIDTH
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
        mov ebx, SCRWIDTH
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
    ;Change of coordinate system for y   y_draw = 149-y_phys/FRAQBIT = (SKYHEIGHT-1)-y_phys/FRAQBIT
    mov eax, [@@ycoord]                 ; Can be both positive or negative
    mov ebx, FRAQBIT
    xor edx, edx
    cmp eax, 0
    jge @@positive
    mov edx, ALLONES
    @@positive:
    idiv ebx
    mov ebx, SKYHEIGHT-1
    sub ebx, eax
    mov eax, SCRWIDTH
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
    ;Change of coordinate system for y   y_draw = 149-y_phys/FRAQBIT = (SKYHEIGHT-1)-y_phys/FRAQBIT
    mov eax, [@@ycoord]                 ; Can be both positive or negative
    mov ebx, FRAQBIT
    xor edx, edx
    cmp eax, 0
    jge @@positive
    mov edx, ALLONES
    @@positive:
    idiv ebx
    mov ebx, SKYHEIGHT-1
    sub ebx, eax
    mov eax, SCRWIDTH
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

PROC bullet_init
    USES eax

    call rand_init
    call rand
    call drawBullet, STARTINGX, STARTINGY, eax
    
    ret
ENDP bullet_init

; Checks    if the bullet collided with wall, ground or target
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

    ; Hé Alec lees dit aub: dus ge zit kheb hier een paar deletebullets gecomment omda het misschien beter is om
    ; de gemiste bullet te laten zoda de missers ziet en de random kleure extra aandacht krijge
    ; als je de ";" weg haalt gaat er nx kapot (normaal gezien (¬‿¬ ))

    @@groundCase:
        call drawBullet, [@@Xpos], 1*FRAQBIT, [@@colorBullet]
        call displayString, 82, 108, offset msgGround
        call wait_VBLANK, [@@waittime]
        call displayString, 82, 108, offset BLANK
        ;call deleteBullet, [@@Xpos], 1*FRAQBIT
        jmp @@endReplacement
        
    @@targetCase:
        call drawBullet, (TARGETHORPOS-2)*FRAQBIT, [@@Ypos], [@@colorBullet]
        call displayString, 82, 108, offset msgSucces
        mov [@@waittime], 100
        call wait_VBLANK, [@@waittime]
        call deleteBullet, (TARGETHORPOS-2)*FRAQBIT, [@@Ypos]
        call processFile, offset WinSCR
        call displayString, 97, 106, offset msgWin
        jmp @@endNoReplacement

    @@wallCase:
        call drawBullet, (WALLHORPOS-2)*FRAQBIT, [@@Ypos], [@@colorBullet]
        call displayString, 82, 108, offset msgWall
        call wait_VBLANK, [@@waittime]
        call displayString, 82, 108, offset BLANK
        ;call deleteBullet, (WALLHORPOS-2)*FRAQBIT, [@@Ypos]
        jmp @@endReplacement
        
    @@onTheWallCase:
        call drawBullet, [@@Xpos], (149-WALLVERPOS+2)*FRAQBIT, [@@colorBullet]    
        call displayString, 82, 108, offset msgWall
        call wait_VBLANK, [@@waittime]
        call displayString, 82, 108, offset BLANK
        ;call deleteBullet, [@@Xpos], 101*FRAQBIT
        jmp @@endReplacement

    @@upperLimitCase:
        call drawBullet, [@@Xpos], 148*FRAQBIT, [@@colorBullet]
        call displayString, 82, 108, offset msgTooHigh
        call wait_VBLANK, [@@waittime]
        call displayString, 82, 108, offset BLANK
        call deleteBullet, [@@Xpos], 148*FRAQBIT
        jmp @@endReplacement
    
    @@leftLimitCase:
        call drawBullet, 1*FRAQBIT, [@@Ypos], [@@colorBullet]
        call displayString, 82, 108, offset msgOutOfBound
        call wait_VBLANK, [@@waittime]
        call displayString, 82, 108, offset BLANK
        call deleteBullet, 1*FRAQBIT, [@@Ypos]
        jmp @@endReplacement

    @@rightLimitCase:
        call drawBullet, 318*FRAQBIT, [@@Ypos], [@@colorBullet]
        call displayString, 82, 108, offset msgOutOfBound
        call wait_VBLANK, [@@waittime]
        call displayString, 82, 108, offset BLANK
        call deleteBullet, 318*FRAQBIT, [@@Ypos]
        jmp @@endReplacement

    @@endReplacement:
        call bullet_init
    @@endNoReplacement:

    ret
ENDP replaceBullet

;Initialize a throw
PROC bulletPath
    ARG @@vx_0:dword, @@vy_0:dword, @@colorBullet:dword
    LOCAL @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ay:dword
    USES eax, ebx, ecx, edx

    mov [@@dt], TIMESTEP            ; [1/time unit] we work with the inverse to dodge decimal points
	;Startingposition
    mov [@@xpos], STARTINGX        ;[distance unit] 
    mov [@@ypos], STARTINGY        ;[distance unit]
    mov eax, [@@vx_0]            ;[distance/time]
    mov [@@vx], eax                 ;[pixels/time]
    mov eax, [@@vy_0]            ;[distance/time]
    mov [@@vy], eax
    mov [@@ay], GRAVITY         	;[distance/time²] downward accelaration due to "gravity"

    ;Nodig om voor later
    mov eax, [@@xpos]
    mov ebx, [@@ypos]
    push eax
    push ebx

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

;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond
PROC drawCube                              ; input zijn in fractionele bits
    ARG @@xcoord:dword ,@@ycoord:dword
    USES eax, ebx, ecx

    mov ebx, [@@xcoord]
    mov ecx, [@@ycoord]

    call getColor, ebx, ecx
    cmp al, 0
    jne @@next1
	call drawPixel, ebx, ecx, 4

    @@next1:
    add ebx, 1*FRAQBIT
    call getColor, ebx, ecx
    cmp al, 0
    jne @@next2
	call drawPixel, ebx, ecx, 4
    
    @@next2:
    sub ecx, 1*FRAQBIT
    call getColor, ebx, ecx
    cmp al, 0
    jne @@next3
	call drawPixel, ebx, ecx, 4
    
    @@next3:
    sub ebx, 1*FRAQBIT
    call getColor, ebx, ecx
    cmp al, 0
    jne @@end
	call drawPixel, ebx, ecx, 4

    @@end:
    ret
ENDP drawCube

PROC deleteCube                              ; input zijn in fractionele bits
    ARG @@xcoord:dword ,@@ycoord:dword
    USES eax, ebx, ecx

    mov ebx, [@@xcoord]
    mov ecx, [@@ycoord]

    call getColor, ebx, ecx
    cmp al, 4
    jne @@next1
	call drawPixel, ebx, ecx, 0

    @@next1:
    add ebx, 1*FRAQBIT
    call getColor, ebx, ecx
    cmp al, 4
    jne @@next2
	call drawPixel, ebx, ecx, 0
    
    @@next2:
    sub ecx, 1*FRAQBIT
    call getColor, ebx, ecx
    cmp al, 4
    jne @@next3
	call drawPixel, ebx, ecx, 0
    
    @@next3:
    sub ebx, 1*FRAQBIT
    call getColor, ebx, ecx
    cmp al, 4
    jne @@end
	call drawPixel, ebx, ecx, 0

    @@end:
    ret
ENDP deleteCube

PROC drawTrajectory
	ARG @@x1:dword, @@y1:dword, @@dx:dword, @@dy:dword
    LOCAL @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ay:dword
	USES eax, ebx, ecx

	mov eax, [@@dx]
	mov ebx, [@@dy]

    mov [@@dt], TIMESTEP            ; [1/time unit] we work with the inverse to dodge decimal points
	;Startingposition
    mov [@@xpos], STARTINGX         ;[distance unit] 
    mov [@@ypos], STARTINGY         ;[distance unit]
    mov [@@vx], eax                 ;[pixels/time]
    mov [@@vy], ebx
    mov [@@ay], GRAVITY         	;[distance/time²] downward accelaration due to "gravity"

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
        call drawCube, eax, ebx

        pop ecx
        loop @@drawloop

    ret
ENDP drawTrajectory

PROC deleteTrajectory
	ARG @@x1:dword, @@y1:dword, @@dx:dword, @@dy:dword
    LOCAL @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ay:dword
	USES eax, ebx, ecx

	mov eax, [@@dx]
	mov ebx, [@@dy]

    mov [@@dt], TIMESTEP            ; [1/time unit] we work with the inverse to dodge decimal points
	;Startingposition
    mov [@@xpos], STARTINGX         ;[distance unit] 
    mov [@@ypos], STARTINGY         ;[distance unit]
    mov [@@vx], eax                 ;[pixels/time]
    mov [@@vy], ebx
    mov [@@ay], GRAVITY         	;[distance/time²] downward accelaration due to "gravity"

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
        call deleteCube, eax, ebx

        pop ecx
        loop @@drawloop

    ret
ENDP deleteTrajectory

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
    USES ebx, edx
	
	;dx = x2 - x1
	mov eax, [@@x2]
	sub eax, [@@x1]
	neg eax

    mov ebx, XCONV
    imul ebx


    cmp eax, -STARTINGX
    jge @@end
    mov eax, -STARTINGX

    @@end:
	ret
ENDP getDeltaX

PROC getDeltaY
	ARG @@y1:dword, @@y2:dword RETURNS eax
    USES ebx, edx

	;dy = y2 - y1
	mov eax, [@@y2]
	sub eax, [@@y1]
	neg eax

    mov ebx, YCONV
    imul ebx

	ret
ENDP getDeltaY

;When the list contains 12 elements, the 6 last elements are moved 3 elements to the front making the list a list of 9 elements
;For example: [boolean1, x1, y1, boolean2, x2, y2, boolean3, x3, y3, boolean4, x4, y4] => [boolean1, x1, y1, boolean3, x3, y3, boolean4, x4, y4]
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

PROC mouseAim
	USES eax, ebx, ecx, edx
	LOCAL @@x1: dword, @@y1: dword, @@oldx2: dword, @@oldy2: dword, @@b2: dword, @@x2: dword, @@y2: dword, @@dx:dword, @@dy:dword, @@colorBullet:dword

	;Show mouse pointer
	mov ax, 1
	int 33h



    ;Check if array of mouse coordinates is not empty
	mov eax, offset arrlen_mousecoord
	cmp [dword ptr eax], 0
	jne @@start

    ;Check if mouse is not clicked
    cmp bl, 1
    jne @@return

    @@start:
        ;We will make a list containing boolean, xcoord and ycoord: 
        ;[boolean1, x1, y1, oldboolean2, oldx2, oldy2, boolean2, x2, y2]
        movzx ebx, bl	                        ; mouse clickstate (1 or 0)
        movzx ecx, cx                           ; horizontal cursor position
        movzx edx, dx                           ; vertical cursor position
        call appendList, offset arrlen_mousecoord, ebx, ecx, edx
        
        

        ;First check if it's an array of 12 elements
        mov ecx, offset arrlen_mousecoord
        cmp [dword ptr ecx], 12
        jne @@return

        call moveElementsOfList, offset arrlen_mousecoord

        ;Get elements of list
        call getOfList, offset arrlen_mousecoord, 2
        mov [@@x1], eax
        call getOfList, offset arrlen_mousecoord, 3
        mov [@@y1], eax
        call getOfList, offset arrlen_mousecoord, 5
        mov [@@oldx2], eax
        call getOfList, offset arrlen_mousecoord, 6
        mov [@@oldy2], eax
        call getOfList, offset arrlen_mousecoord, 7
        mov [@@b2], eax
        call getOfList, offset arrlen_mousecoord, 8
        mov [@@x2], eax
        call getOfList, offset arrlen_mousecoord, 9
        mov [@@y2], eax

        ;Draw a pixel on the place where the mouse has first clicked
        call drawPixel, [@@x1], [@@y1], 200

        ;Tranfrom the mousecoordinates into coordinates for the trajectory of the throw
        call getDeltaX, [@@x1], [@@oldx2]
        mov [@@dx], eax
        call getDeltaY, [@@y1], [@@oldy2]
        mov [@@dy], eax
        call deleteTrajectory, STARTINGX, STARTINGY, [@@dx], [@@dy]

        call getDeltaX, [@@x1], [@@x2]
        mov [@@dx], eax
        call getDeltaY, [@@y1], [@@y2]
        mov [@@dy], eax
        call drawTrajectory, STARTINGX, STARTINGY, [@@dx], [@@dy]

        ;The state where the mouse is released: [boolean2 back to 0]
        cmp [@@b2], 1
        je @@return

        @@throw:
            ;Hide visible mouse pointer
            mov ax, 2
            int 33h 

            ;Hide trajectoryline + hide startpoint 
            call deleteTrajectory, STARTINGX, STARTINGY, [@@dx], [@@dy]
            call drawPixel, [@@x1], [@@y1], 0

            ;get color of bullet
            call getColor, STARTINGX, STARTINGY
            mov [@@colorBullet], eax

            ;Throw bullet
            call bulletPath, [@@dx], [@@dy], eax

            ;Reset the array of the mouse coordinates
            mov ebx, offset arrlen_mousecoord
            mov [dword ptr ebx], 0
	@@return:
	ret
ENDP mouseAim


PROC main
    sti
    cld

    push ds
    pop es

    call    setVideoMode, 13h

    call    updateColorpallete, 6
    startscreen
    call    fillBackground

    call    drawCursor, 25*FRAQBIT, 25*FRAQBIT, 200
    call    bullet_init
	call 	mouse_install, offset mouseAim

    call    waitForSpecificKeystroke, 001Bh ; ESC = 001Bh
    call    mouse_uninstall
    call    terminateProcess

ENDP main 

; -------------------------------------------------------------------
; DATA
; ------------------------------------------------------------------- 
DATASEG
    palette         dd 34, 52, 63                           ;sky
                    dd 31, 63, 0                            ;grass
                    dd 53, 26, 8                            ;wall
                    dd 55, 5, 15                            ;target
                    dd 127, 63, 40                          ;Aimline
                    dd 32, 32, 32                           ;Bullet
    StartSCR        db "startscr.bin", 0
    WinSCR          db "winscr.bin", 0
    msgStart        db " Press space to play!", 13, 10, '$'
	msgGround	    db "On the ground!", 13, 10, '$'
	msgWall	        db "    Miss!     ", 13, 10, '$'
	msgSucces	    db "   Succes!    ", 13, 10, '$'
	msgTooHigh	    db "  Too high!   ", 13, 10, '$'
    msgOutOfBound   db "Out of bound! ", 13, 10, '$'
    msgWin          db " Press esc to exit", 13, 10, '$'
    BLANK           db "              ", 13, 10, '$'
	openErrorMsg    db "could not open file", 13, 10, '$'
	readErrorMsg    db "could not read data", 13, 10, '$'
	closeErrorMsg   db "error during file closing", 13, 10, '$'
    arrlen_mousecoord dd 0
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h


END main