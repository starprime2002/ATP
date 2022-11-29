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

; Screen constants 
VMEMADR EQU 0A0000h     ; video memory address 
SCRWIDTH EQU 320        ; screen witdth 
SCRHEIGHT EQU 200       ; screen height 
ALLONES EQU 4294967295  ; needed for sign extension before dividing 
FRAQBIT EQU 128         ; fractionele bit  


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
    ARG @@printval:dword
    USES eax, ebx, ecx, edx 

    ; Check for sign 
    mov eax, [@@printval] 
    test eax, eax 
    jns @@skipSign 
    push eax 
    mov ah, 2h      ; Print '-' if the sign is set. 
    mov dl, '-' 
    int 21h 
    pop eax 
    neg eax

    @@skipSign: 
        mov ebx, 10     ; divider
        xor ecx, ecx    ; counter for digits to be printed 

    ; Store digits on stack 
    @@getNextDigit: 
        inc ecx         ; increase digit counter 
        xor edx, edx 
        div ebx         ; divide by 10 
        push dx         ; store remainder on stack 
        test eax, eax   ; check whether zero? 
        jnz @@getNextDigit 

        ; Write all digits to the standard output 
        mov ah, 2h      ; Function for printing single characters. 

    @@printDigits:       
        pop dx 
        add dl,'0'          ; Add 30h => code for a digit in the ASCII table, ... 
        int 21h             ; Print the digit to the screen, ... 
        loop @@printDigits  ; Until digit counter = 0. 

    ret
ENDP printSignedInteger 

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
    USES eax, ebx, ecx, edx 

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
        cmp ah, 5
        jne @@kleur

    ret
ENDP updateColorpallete

; Fill the background (for mode 13h): blue sky with grass and a wall
PROC fillBackground
    USES    eax, ebx, ecx, edx, edi

    ; Initialize video memory address.
    mov edi, VMEMADR                        ; edi is destination adress en is dus hier 0A0000h

    ; Draw sky
    mov ecx, SCRWIDTH*150                   ; ecx = amount of elements = aantal pixels
    mov al, 0                               ; indx of the first color to change
    rep stosb           ; stosb (byte) =transfer one byte from eax to edi so that edi increases/updates to point to the next datum(that is situated one byte next to the previous)
                        ;stosw (word) = transfer two byte (= word)
                        ;stosd (double word) = tranfer 4 bytes (= double word)

    ; Draw grass 
    mov edi, VMEMADR
    add edi, 150*320
    mov al, 1
    mov edx, 50
    @@heigtWall:
        mov ecx, 320
        @@widthWall:
            mov [edi], al
            inc edi
            dec ecx
            cmp ecx, 0
            jne @@widthWall
        dec edx
        cmp edx, 0
        jne @@heigtWall

    ; Draw wall
    mov edx, 1
    @@heigthWall:
        xor ebx, ebx
        mov ebx, 50
        add ebx, edx
        mov eax, 320
        push edx
        mul ebx
        pop edx
        mov ebx, eax
        add ebx, 300
        mov edi, VMEMADR
        add edi, ebx
        mov al, 2
        mov ecx, 10
            @@WidthWall:
                mov [edi], al
                inc edi
                dec ecx
                cmp ecx, 0
                jne @@WidthWall
        inc edx
        cmp edx, 100
        jne @@heigthWall
    ; Draw target 
    mov edx, 1 
    @@heigthTarget: 
        xor ebx, ebx
        mov ebx, 100
        add ebx, edx
        mov eax, 320
        push edx
        mul ebx
        pop edx
        mov ebx, eax
        add ebx, 298
        mov edi, VMEMADR
        add edi, ebx
        mov al, 3
        mov ecx, 2
            @@WidthTarget:
                mov [edi], al
                inc edi
                dec ecx
                cmp ecx, 0
                jne @@WidthTarget
        inc edx
        cmp edx, 10
        jne @@heigthTarget

    ret
ENDP fillBackground

;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond
PROC drawPixel                              ; input zijn in fractionele bits
    ARG @@xcoord:dword ,@@ycoord:dword, @@color:byte
    USES eax, ebx

    mov edi, VMEMADR
    mov eax, [@@ycoord]                 ; Can be both positive or negative
    mov ebx, FRAQBIT
    mov edx, 0
    cmp eax, 0
    jge @@positivevy
    mov edx, ALLONES
    @@positivevy:
    idiv ebx
    mov ebx, 149
    sub ebx, eax
    mov eax, 320
    imul ebx
    add edi, eax
    mov eax, [@@xcoord]                     ;can only be positive
    mov ebx, FRAQBIT
    div ebx
    add edi, eax
    mov al, [@@color]                       ; pick the color of the pallet
    mov [edi], al

    ret
ENDP drawPixel

; deletes previous bullet and draws a new one
PROC moveBullet                             ; input zijn in fractionele bits
    ARG @@oldXpos:dword, @@oldYpos:dword, @@newXpos:dword, @@newYpos:dword
    USES ebx, ecx

    ;Delete previous bullet
    mov ebx, [@@oldXpos]
    mov ecx, [@@oldYpos]

    call drawPixel, ebx, ecx, 0
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    sub ebx, 2*FRAQBIT
    sub ecx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    sub ebx, 2*FRAQBIT
    sub ecx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 0
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 0

    ;Draw new bullet
    mov ebx, [@@newXpos]
    mov ecx, [@@newYpos]

    call drawPixel, ebx, ecx, 4 
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 4
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 4
    sub ebx, 2*FRAQBIT
    sub ecx, FRAQBIT
    call drawPixel, ebx, ecx, 4
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 128
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 4
    sub ebx, 2*FRAQBIT
    sub ecx, FRAQBIT
    call drawPixel, ebx, ecx, 4
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 4
    add ebx, FRAQBIT
    call drawPixel, ebx, ecx, 4

    ret
ENDP moveBullet

; Checks    if the bullet collided with wall or ground
;           if the bullet is out of border
PROC checkCollision
    ARG @@xpos:dword, @@ypos:dword RETURNS cl
    USES eax, ebx

    mov eax, [@@xpos]
    mov ebx, [@@ypos]
    xor ecx, ecx

    @@groundCheck:
        cmp ebx, 2*FRAQBIT
        jg @@wallCheck
        mov cl, 1
        jmp @@collisionEnd

    @@wallCheck:                        ; Wall = (300,0)-(309,99)
        cmp eax, 297*FRAQBIT
        jl @@upperCheck
        cmp eax, 319*FRAQBIT
        jg @@upperCheck
        cmp ebx, 101*FRAQBIT
        jg @@upperCheck
        mov cl, 2
        jmp @@collisionEnd

    @@upperCheck:
        cmp ebx, 150*FRAQBIT
        jl @@leftBoundCheck
        mov cl, 3
        jmp @@collisionEnd
    
    @@leftBoundCheck:
        cmp eax, 0*FRAQBIT
        jge @@rightBoundCheck
        mov cl, 4
        jmp @@collisionEnd

    @@rightBoundCheck:
        cmp eax, 320*FRAQBIT
        jl @@noCollision
        mov cl, 5
        jmp @@collisionEnd

    @@noCollision:
        mov cl, 0
        jmp @@collisionEnd

    @@collisionEnd:
    ret
ENDP checkCollision

;Initialize a throw
PROC bulletPath
    ARG @@vxbegin:dword, @@vybegin:dword
    LOCAL @@dt:dword, @@xpos:dword, @@ypos:dword, @@vx:dword, @@vy:dword, @@ax:dword, @@ay:dword
    USES eax, ebx, ecx, edx

    mov [@@dt], 16                  ; [1/time unit] we work with the inverse to dodge decimal points
    mov eax, 25*FRAQBIT             ; startingposition
    mov ebx, 25*FRAQBIT             ; [pixels * distance/pixels]
    push eax
    push ebx
    mov [@@xpos], eax               ;[distance unit]
    mov [@@ypos], ebx               ;[distance unit]
    mov ebx, FRAQBIT
    mov eax, [@@vxbegin]            ;[distance/time]
    mul ebx
    mov [@@vx], eax                 ;[pixels/time]
    mov eax, [@@vybegin]            ;[distance/time]
    mul ebx
    mov [@@vy], eax
    mov [@@ax], 0                   ;[distance/time²]
    mov [@@ay], -10*FRAQBIT         ;[distance/time²] downward accelaration due to "gravity" -9.81 = -10 here

    call moveBullet, [@@xpos], [@@ypos], [@@xpos], [@@ypos]

    xor ecx, ecx
    @@tijdsloop: 

        ;xpos += vx*dt
        mov eax, [@@vx]
        mov ebx, [@@dt]
        mov edx, 0
        cmp eax, 0
        jge @@positivevx
        mov edx, ALLONES
        @@positivevx:
        mov edx, 0
        idiv ebx
        add [@@xpos], eax
        ;ypos += vy*dt
        mov eax, [@@vy]
        mov ebx, [@@dt]
        mov edx, 0
        cmp eax, 0
        jge @@positivevy
        mov edx, ALLONES
        @@positivevy:
        idiv ebx
        add [@@ypos], eax

        ;vx += ax*dt
        mov eax, [@@ax]             ; required for wind later
        mov ebx, [@@dt]
        mov edx, 0
        cmp eax, 0
        jge @@positiveax
        mov edx, ALLONES
        @@positiveax:
        mov edx, 0 
        idiv ebx
        add [@@vx], eax
        ;vy += ay*dt 
        mov eax, [@@ay]
        mov ebx, [@@dt]
        mov edx, 0
        cmp eax, 0
        jge @@positiveay
        mov edx, ALLONES
        @@positiveay:
        mov edx, ALLONES
        idiv ebx
        add [@@vy], eax
 

        call checkCollision, [@@xpos], [@@ypos]
        call printSignedInteger, ecx
        cmp ecx, 0
        jg @@endPath

        
        ;Bring back old coordinations
        pop ebx
        pop eax
        ; displace bullet
        call moveBullet, eax, ebx, [@@xpos], [@@ypos]
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
    ret 
ENDP bulletPath 

PROC main
    sti
    cld

    push ds
    pop es

    call    setVideoMode, 13h
    finit   ; initialize FPU

    call    updateColorpallete
    call    fillBackground


    call    bulletPath, 10, 40

    call    waitForSpecificKeystroke, 001Bh ; ESC = 001Bh
    call    terminateProcess

ENDP main 

; -------------------------------------------------------------------
; DATA
; ------------------------------------------------------------------- 
DATASEG 
    palette dd 34, 52, 63, 31, 63, 0, 53, 26, 8, 55, 5, 15, 28, 32, 36              ; lucht-gras-muur-doelwit-kogel

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h


END main 