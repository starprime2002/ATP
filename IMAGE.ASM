; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	David Blinder
; date:		20/10/2021
; program:	Simple image load and display for mode 13h
;
; image source: https://www.pxfuel.com/en/free-photo-xpoec
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "image.inc"

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
FULLPALLETESIZE EQU 768 ; bytes in palette
COLORCOUNT EQU 128 ; number of unique colors for palette cycling
PIXELCOUNT EQU 320*200	; pixel count

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

; Halt program until keystroke is pressed.
MACRO waitForKeystroke
	mov	ah,00h
	int	16h
ENDM waitForKeystroke

; terminate if key is pressed
PROC terminateAfterKeystroke
	USES eax
	mov	ah, 01h
	int	16h
	jz @@charfound
	ret
	
	@@charfound:
		call terminateProcess
ENDP terminateAfterKeystroke

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

; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

; -------------------------------------------------------------------

; opens file, read contents to palette + imagedata, closes file
PROC processFile
	ARG	 @@filepathptr:dword
	USES eax, ebx, ecx, edx, esi, edi
	
	; open file, get filehandle in AX
	mov al, 0 ; read only
	mov edx, [@@filepathptr]
	mov ah, 3dh
	int 21h
	
	mov  edx, offset openErrorMsg
	jc @@print_error ; carry flag is set if error occurs

	; read file data
	mov bx, ax ; move filehandle to bx
	mov ecx, PIXELCOUNT
	mov edx, offset imagedata
	mov ah, 3fh
	int 21h


	mov  edx, offset readErrorMsg
	jc @@print_error
	
	; close file
	mov ah, 3Eh
	int 21h
	
	mov  edx, offset closeErrorMsg
	jc @@print_error
	
	; copy to video buffer, update palette
	mov eax, offset imagedata
	add eax, 5
	mov esi, eax
	mov edi, VMEMADR
	mov ecx, PIXELCOUNT
	rep movsb

	ret

	@@print_error:
		call setVideoMode, 03h
		mov  ah, 09h
		int  21h
		
		mov	ah,00h
		int	16h
		call terminateProcess	
ENDP processFile


DATASEG
    StartSCR db "smiley.bin", 0
    Back            db "back.bin", 0
	WinSCR db "winscr.bin", 0
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
; -------------------------------------------------------------------
UDATASEG
	palette	db FULLPALLETESIZE dup (?)
	imagedata db PIXELCOUNT dup (?)
; -------------------------------------------------------------------
STACK 100h

END
