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

PROC P_positive ;P = P + 2*dy - 2*dx
	ARG @@P: dword, @@dx: dword, @@dy: dword RETURNS eax
	USES ebx
	mov eax, [@@dy]					
	mov ebx, 2
	mul ebx
	add [@@P], eax

	mov eax, [@@dx]
	mov ebx, 2
	mul ebx
	sub [@@P], eax 

	mov eax, [@@P]
	
	ret
ENDP P_positive
	
PROC P_negative ;P = P + 2*dy 
	ARG @@P: dword, @@dy: dword	RETURNS eax
	USES ebx

	mov eax, [@@dy]
	mov ebx, 2
	mul ebx
	add [@@P], eax	

	mov eax, [@@P]
	;call printSignedInteger, eax

	ret
ENDP P_negative

PROC drawline
	ARG @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@color:dword
	LOCAL @@dx:dword, @@dy:dword, @@P:dword, @@count:dword, @@xoperator: dword, @@yoperator: dword
	USES eax, ebx,ecx, edx

	;Check if x2<=298, else x2 = 298
	@@Check_x2:
	cmp [@@x2], 298
	jle @@Check_y2
	mov [@@x2], 298

	@@Check_y2:
	;Check if y2>=0, else y2 = 0
	cmp [@@y2], 0
	jge @@continue
	mov [@@y2], 0

	@@continue:
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

		;dx pos: xoperator = +1
		mov [@@xoperator], 1
		;dy pos: operator = +1
		mov [@@yoperator], 1

		;Compare dx an dy	
		jmp @@compare_dx_and_dy


	;Case 2: dx negative and dy positive, then slope negative
	@@case2:
		cmp [@@dy],0
		jl @@case4

		;dx neg: xoperator = -1
		mov [@@xoperator], -1
		;dy pos: operator = +1
		mov [@@yoperator], 1

		;negate dx to make it positive
		neg [@@dx]

		;Compare dx an dy	
		jmp @@compare_dx_and_dy

	;Case 3: dx positive and dy negative, then slope negative
	@@case3:
		;dx pos: xoperator = +1
		mov [@@xoperator], 1
		;dy neg: operator = -1
		mov [@@yoperator], -1

		;negate dy to make it positive
		neg [@@dy]

		;Compare dx an dy	
		jmp @@compare_dx_and_dy

	;Case 4: dx negative and dy negative, then slope positive
	@@case4:
		;dx pos: xoperator = -1
		mov [@@xoperator], -1
		;dy pos: operator = -1
		mov [@@yoperator], -1

		;negate dx and dy to make them positive
		neg [@@dx]
		neg [@@dy]

		;Compare dx an dy	
		jmp @@compare_dx_and_dy

	;Compare dx an dy: if dx>=dy then slope<=1, if dx<dy then slope>1	
	@@compare_dx_and_dy:
		mov eax, [@@dx]
		mov ebx, [@@dy]
		cmp eax, ebx
		jge @@slope_less_or_equal_1
		jmp @@slope_greater_1 


	;a) slope<=1, dx>=dy
	@@slope_less_or_equal_1:
		;P = 2dy - dx
		mov eax, [@@dy]
		mov ebx, 2
		mul ebx
		sub eax, [@@dx]
		mov [@@P], eax

		;count = dx
		mov eax, [@@dx]
		mov [@@count], eax

		;initialize
		mov eax, [@@x1]
		mov ebx, [@@y1]
		mov ecx, [@@count]
		jcxz @@slope_greater_1 
		

		;---------------------------------------------------
		;bresenham's line algorithm:
		;This algorithm is used to draw a line between two points (x1, y1) and (x2, y2). 
		;If the slope <=1, xoperator (which can be +1 (increment) or -1 (decrement), dependent of dx) is added to x1.
		;if P<0: y1 = y1 and P = P + 2*dy 
		;if P>0: y1 = y1 + 1 and P = P + 2*dy - 2*dx
		; The loop goes on until x1 has reached x2 or until dx is zero.
		;---------------------------------------------------

		@@bl_loop1:
			call drawPixel, eax,ebx, [@@color]
			
			add eax, [@@xoperator]

			push eax
			push ebx

			cmp [@@P], 0					
			jl @@Pkleinerdan0_1
			
			call P_positive, [@@P], [@@dx], [@@dy]
			mov [@@P], eax
			
			pop ebx 
			pop eax 

			add ebx, [@@yoperator]

			loop @@bl_loop1
			jmp @@end

			@@Pkleinerdan0_1:
			call P_negative, [@@P], [@@dy]
			mov [@@P], eax

			pop ebx
			pop eax

			loop @@bl_loop1
			jmp @@end


	;b) slope>1, dx<dy
	@@slope_greater_1:
		;P = 2dx - dy
		mov eax, [@@dx]
		mov ebx, 2
		mul ebx
		sub eax, [@@dy]
		mov [@@P], eax

		;count = dy
		mov eax, [@@dy]
		mov [@@count], eax

		;initialize
		mov eax, [@@x1]
		mov ebx, [@@y1]
		mov ecx, [@@count]	
		;cmp ecx, 0
		jcxz @@end

		;---------------------------------------------------
		;bresenham's line algorithm:
		;This algorithm is used to draw a line between two points (x1, y1) and (x2, y2). 
		;If the slope >1, yoperator (which can be +1 (increment) or -1 (decrement), dependent of dy) is added to y1.
		;if P<0: x1 = x1 and P = P + 2*dx 
		;if P>0: x1 = x1 + 1 and P = P + 2*dx - 2*dy
		; The loop goes on until y1 has reached y2 or until dy is zero.
		;---------------------------------------------------
		@@bl_loop2:
			call drawPixel, eax,ebx, [@@color]

			add ebx, [@@yoperator]

			push eax
			push ebx

			cmp [@@P], 0					
			jl @@Pkleinerdan0_2
			
			call P_positive, [@@P], [@@dy], [@@dx]
			mov [@@P], eax
			
			pop ebx 
			pop eax 

			add eax, [@@xoperator]

			loop @@bl_loop2
			jmp @@end

			@@Pkleinerdan0_2:
			call P_negative, [@@P], [@@dx]
			mov [@@P], eax

			pop ebx
			pop eax

			loop @@bl_loop2
			jmp @@end


	@@end:

	ret
ENDP drawline

PROC printIntList
	ARG	@@arrayptr:dword
	USES eax, ebx, ecx, edx
	
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx

	cmp ecx, 0				; if length is 0, skip
	je @@end

	
	mov	ah, 2h 		; Function for printing single characters.
	@@printInt:
	add ebx, 4	; go to next integer
	call printSignedInteger, [dword ptr ebx]
	loop @@printInt	; loop over all integers
	
	mov	dl, 0Dh		; Carriage return.
	int	21h
	mov	dl, 0Ah		; New line.
	int 21h
	
	@@end:
	ret
ENDP printIntList

PROC appendList
	ARG @@arrayptr:dword, @@new_value: dword
	USES eax, ebx, ecx

	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	add  [dword ptr ebx], 1	; add 1 to the actual value of arrlen_mouse for the print procedure later
	add ecx, 1	;add 1 to counter of this loop
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop

	mov eax, [@@new_value]
	mov [dword ptr ebx], eax	; putting the new value after the last element of the list

	ret

ENDP appendList

;---------------------------------------------------------
;This is for boolean_mouse_dragged
PROC get_X1_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	;mov ecx, [ebx]			; get length counter in ecx
	add ebx, 8
	mov eax, [dword ptr ebx]

	ret
ENDP get_X1_ofBoolList

PROC get_X2_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx, ecx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop
	sub ebx, 4
	mov eax, [dword ptr ebx]

	ret
ENDP get_X2_ofBoolList

PROC get_Y1_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	;mov ecx, [ebx]			; get length counter in ecx
	add ebx, 12
	mov eax, [dword ptr ebx]

	ret
ENDP get_Y1_ofBoolList

PROC get_Y2_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx, ecx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop

	mov eax, [dword ptr ebx]

	ret
ENDP get_Y2_ofBoolList

PROC get_oldX_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx, ecx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop
	sub ebx, 16
	mov eax, [dword ptr ebx]

	ret
ENDP get_oldX_ofBoolList

PROC get_oldY_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx, ecx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop
	sub ebx, 12
	mov eax, [dword ptr ebx]

	ret
ENDP get_oldY_ofBoolList

PROC get_B1_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	;mov ecx, [ebx]			; get length counter in ecx
	add ebx, 4
	mov eax, [dword ptr ebx]

	ret
ENDP get_B1_ofBoolList

PROC get_B2_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx, ecx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov ecx, [ebx]			; get length counter in ecx
	@@arrayloop:
		add ebx, 4
		loop @@arrayloop
	sub ebx, 8
	mov eax, [dword ptr ebx]

	ret
ENDP get_B2_ofBoolList

PROC get_oldB_ofBoolList
	ARG @@arrayptr:dword RETURNS eax
	USES ebx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	;mov ecx, [ebx]			; get length counter in ecx
	add ebx, 16
	mov eax, [dword ptr ebx]

	ret
ENDP get_oldB_ofBoolList

PROC trajectory_x
	ARG @@x1:dword, @@x2:dword RETURNS eax
	LOCAL @@dx: dword
	
	;dx = x2 - x1
	mov eax, [@@x2]
	sub eax, [@@x1]
	mov [@@dx], eax

	mov eax, 25
	sub eax, [@@dx]

	;Chech if eax is greater than 0, else put it on 0
	cmp eax, 0
	jge @@skip
	mov eax, 0

	@@skip:
	ret
ENDP trajectory_x

PROC trajectory_y
	ARG @@y1:dword, @@y2:dword RETURNS eax
	LOCAL @@dy: dword

	;dy = y2 - y1
	mov eax, [@@y2]
	sub eax, [@@y1]
	mov [@@dy], eax

	mov eax, 25
	sub eax, [@@dy]

	ret
ENDP trajectory_y

;-------------------------------------------
;This is for boolean_mouse_dragged
PROC undraw_last_bool_trajectoryline
	LOCAL @@x1: dword, @@y1: dword, @@x2: dword, @@y2: dword, @@a: dword, @@b: dword
	USES eax

	call get_X1_ofBoolList, offset arrlen_mousecoord
	mov [@@x1], eax

	call get_Y1_ofBoolList, offset arrlen_mousecoord
	mov [@@y1], eax

	call get_X2_ofBoolList, offset arrlen_mousecoord
	mov [@@x2], eax

	call get_Y2_ofBoolList, offset arrlen_mousecoord
	mov [@@y2], eax

	call trajectory_x, [@@x1], [@@x2]
	mov [@@a], eax

	call trajectory_y, [@@y1], [@@y2]
	mov [@@b], eax

	call drawline, 25*FRAQBIT, 25*FRAQBIT, [@@a], [@@b], 0

	call drawPixel, [@@x1], [@@y1], 0

	

	ret
ENDP undraw_last_bool_trajectoryline
;-------------------------------------------

PROC reset
	ARG	@@arrayptr:dword
	USES eax, ebx, ecx, edx
	mov ebx, [@@arrayptr]	; store pointer in ebx
	mov [dword ptr ebx], 0	; add 1 to the actual value of arrlen_mouse for the print procedure later

	ret
ENDP reset

PROC moveBoolElementofList
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
	
	
	@@skip:
	ret

ENDP moveBoolElementofList

PROC boolean_mouse_dragged
	USES eax, ebx, ecx, edx
	LOCAL @@result: dword, @@boolean1:dword, @@x1: dword, @@y1: dword, @@boolean2: dword, @@x2: dword, @@y2: dword, @@oldBoolean: dword, @@oldXpos: dword, @@oldYpos: dword, @@a: dword, @@b: dword

	;Put initially result on 0
	mov [@@result], 0

	;Show mouse pointer
	mov ax, 1
	int 33h 
	
	;Boolean mouse clicked or unclicked
	movzx eax, bl
	;cmp eax, 0
	;je @@skipit
	
	;Getting xcoord and ycoord
	;write pixel in a standard (x,y) cartesian coordinate system with the origin far left above grond 
   	movzx edx, dx		; get mouse height
	mov ebx, 149
	sub ebx, edx
	mov edx, ebx*FRAQBIT

	mov ebx,0			;moet niet ?
	sar cx, 1			; horizontal cursor position is doubled in input 
	movzx ebx, cx*FRAQBIT		

	;We will make a list containing boolean, xcoord and ycoord: [boolean1, x1, y1, oldBoolean, oldXpos, oldYpos, boolean2, x2, y2]
	call appendList, offset arrlen_mousecoord, eax	;boolean
	call appendList, offset arrlen_mousecoord, ebx	;xcoord
	call appendList, offset arrlen_mousecoord, edx	;ycoord
	

	;First check if it's an array of 12 elements
	; if arrlen_mousecoord >=3:
	mov ecx, [offset arrlen_mousecoord]
	cmp ecx, 12
	jl @@skipit
	call moveBoolElementofList, offset arrlen_mousecoord
	;call printIntList, offset arrlen_mousecoord	

	;Get first boolean
	call get_B1_ofBoolList, offset arrlen_mousecoord
	mov [@@boolean1], eax

	;Get old boolean
	call get_oldB_ofBoolList, offset arrlen_mousecoord
	mov [@@oldBoolean], eax

	;Get new boolean
	call get_B2_ofBoolList, offset arrlen_mousecoord
	mov [@@boolean2], eax

	;Get x1
	call get_X1_ofBoolList, offset arrlen_mousecoord
	mov [@@x1], eax
	
	;Get y1
	call get_Y1_ofBoolList, offset arrlen_mousecoord
	mov [@@y1], eax

	;Get x2
	call get_X2_ofBoolList, offset arrlen_mousecoord
	mov [@@x2], eax

	;Get y2
	call get_Y2_ofBoolList, offset arrlen_mousecoord
	mov [@@y2], eax
	;call printSignedInteger, [@@y2]

	;Get oldXpos
	call get_oldX_ofBoolList, offset arrlen_mousecoord
	mov [@@oldXpos], eax

	;Get oldYpos
	call get_oldY_ofBoolList, offset arrlen_mousecoord
	mov [@@oldYpos], eax

	;if boolean1 is 1 do this
	cmp [@@boolean1], 1
	jne @@reset

	;Draw a pixel on the place where the mouse has first clicked
	call drawPixel, [@@x1], [@@y1], 99

	;Tranfrom the mousecoordinates into coordinates for the trajectory of the throw
	call trajectory_x, [@@x1], [@@oldXpos]
	mov [@@a], eax

	call trajectory_y, [@@y1], [@@oldYpos]
	mov [@@b], eax

	call drawline, 25, 25, [@@a], [@@b], 0


	call trajectory_x, [@@x1], [@@x2]
	mov [@@a], eax


	call trajectory_y, [@@y1], [@@y2]
	mov [@@b], eax


	call drawline, 25, 25, [@@a], [@@b], 99




	;The state where the mouse is let go is: [oldBoolean = 1 and boolean2 = 0]
	cmp [@@oldBoolean], 1
	jne @@skipit
	cmp [@@boolean2], 0
	jne @@skipit
	mov [@@result], 1



	@@skipit:
	
	;call printSignedInteger, [@@result]


	cmp [@@result], 1
	jne @@return

	;Hide visible mouse pointer
	mov ax, 2
	int 33h 

	;Hide trajectoryline + hide startpoint 
	call undraw_last_bool_trajectoryline

	;Throw bullet

	mov eax ,25*FRAQBIT
	sub eax, [@@a]
	mov ebx ,25*FRAQBIT
	sub ebx, [@@b]
	call printSignedInteger, [@@a]
	call bulletPath, eax, ebx


	@@reset:
	call reset, offset arrlen_mousecoord
	
	@@return:

	ret

	
ENDP boolean_mouse_dragged



PROC main
	sti
	cld
	
	push ds
	pop	es

	call	setVideoMode, 13h
	finit	; initialize FPU
	
	call	updateColorpallete
	call	fillBackground
	
	call 	mouse_install, offset boolean_mouse_dragged






	call	waitForSpecificKeystroke, 001Bh	; ESC = 001Bh
	call 	mouse_uninstall
	call	terminateProcess
ENDP main
; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

	palette dd 34, 52, 63, 31, 63, 0, 53, 26, 8, 55, 5, 15, 28, 32, 36				; lucht-gras-muur-doelwit-kogel
	arrlen_mousecoord dd 0
	


; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main