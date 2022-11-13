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

PROC landingshoogte
	ARG @@alpha: dword, @@v0: dword 
	RETURNS eax
	LOCAL @@vx: dword, @@vy: dword, @@ax: dword, @@ay: dword 
	USES 

	mov eax, 1
	ret

ENDP landingshoogte



PROC main
	sti
	cld
	

		
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

END start

; here is a comment heehekbeb