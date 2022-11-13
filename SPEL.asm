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

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; Wait for a keystroke.
PROC waitForKeystroke
	ARG 	@@key:byte
	USES 	eax
	
	mov	ah,00h
	int	16h
	ret
ENDP waitForKeystroke

; Terminate the program.
PROC terminateProcess
	USES eax
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

PROC cos 										; cos(x) = 1 - x*x/2 + x*x*x*x/24 taylorbenadering cosinus
	ARG @@hoek:dword RETURNS eax
	USES ebx

	mov eax, 1
	mov ebx, [@@hoek]
	mul ebx, ebx
	push ebx
	push 2
	add
	pop eax

	ret
ENDP cos	

PROC landingshoogte
	ARG @@alpha: dword, @@v0: dword RETURNS eax
	LOCAL @@vx: dword, @@vy: dword, @@ax: dword, @@ay: dword 
	USES ebx

	mov ebx, [@@v0]
	mov ecx, cos(@@alpha)
	mul ebx, 



	mov eax, 128827
	ret

ENDP landingshoogte

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


PROC main
	sti
	cld
	
	call    cos, 0.8
	call printUnsignedInteger, eax
	call 	waitForKeystroke
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

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main

; here is a comment heehekbeb