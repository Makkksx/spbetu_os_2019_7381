SSEG SEGMENT stack
db 100 dup(?)
SSEG ENDS

DATA SEGMENT
	DOS_V			db		'DOS VER: '
	DOS_F			db		' .'
	END_DOS_V		db		' ', 0AH, 0DH,'$'
	OEM				db		'OEM:  '
	ENDOEM 			db		' ', 0AH, 0DH,'$'
	USERN			db		'USER NUMBER:      '
	USERNEND 		db		' ', 0AH, 0DH,'$'
	
	TYPE_PC 		db		'PC type: PC', 0AH, 0DH,'$'
	TYPE_PC_XT		db		'PC type: PC/XT', 0AH, 0DH,'$'
	TYPE_AT 		db		'PC type: AT', 0AH, 0DH,'$'
	TYPE_PS2_M30	db		'PC type: model 30', 0AH, 0DH,'$'
	TYPE_PS2_M50_60 db		'PC type: model 50 or 60', 0AH, 0DH,'$'
	TYPE_PS2_M80 	db		'PC type: model 80', 0AH, 0DH,'$'
	TYPE_PSjr 		db		'PC type: PCjr', 0AH, 0DH,'$'
	TYPE_PC_CONV 	db		'PC type: PC Convertible', 0AH, 0DH,'$'
	TYPE_UNKNOWN 	db		'PC type code: '
	TYPE_CODE 		db		'  ', 0AH, 0DH, '$'
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:DATA, SS:SSEG
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
	NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ; в AL старшая цифра
	pop CX ; в AH младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; перевод в 16 с/с с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP
;--------------------------------------------------

BYTE_TO_DEC PROC near
; перевод в 10 с/с, SI - адрес поля младшей цифры
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
	end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;-------------------------------


GET_PC_CODE PROC near
	push BX
	push ES
	mov	BX,0F000H
	mov	ES,BX
	mov	AL,ES:[0FFFEH]
	pop	ES
	pop	BX
	ret
GET_PC_CODE	ENDP

PRINT_PC_TYPE PROC near
	push AX
	push DX
	push DI
		
	T0: cmp AL, 0FFh
	jne T1
	mov DX, offset TYPE_PC;
	jmp print
		
	T1: cmp AL, 0FEh
	jne T2
	mov DX, offset TYPE_PC_XT;
	jmp print
		
	T2: cmp AL, 0FBh
	jne T3
	mov DX, offset TYPE_PC_XT;
	jmp print
		
	T3: cmp AL, 0FCh
	jne T4
	mov DX, offset TYPE_AT;
	jmp print
		
	T4: cmp AL, 0FAh
	jne T5
	mov DX, offset TYPE_PS2_M30;
	jmp print
		
	T5: cmp AL, 0FCh
	jne T6
	mov DX, offset TYPE_PS2_M50_60;
	jmp print
	
	T6: cmp AL, 0F8h
	jne T7
	mov DX, offset TYPE_PS2_M80;
	jmp print
	
	T7: cmp AL, 0FDh
	jne T8
	mov DX, offset TYPE_PSjr
	jmp print
	
	T8: cmp AL, 0F9h
	jne T9
	mov DX, offset TYPE_PC_CONV
	jmp print
	
	T9: 
	call BYTE_TO_HEX
	mov DI, OFFSET TYPE_CODE
	mov [DI], AX
	mov DX, offset TYPE_UNKNOWN;
	
	print:
	mov AH, 09h                          
	int 21h
	pop DI
	pop DX
	pop AX
	ret
PRINT_PC_TYPE ENDP

START:
	push DS 
	mov AX, 0
	push AX 

	mov DX, DATA
	mov DS, DX

	; PC TYPE
	call GET_PC_CODE
	call PRINT_PC_TYPE
	
	
	mov	AH,30H
	INT	21H
	
	; DOS
	push AX
	mov SI, offset DOS_F
	call BYTE_TO_DEC
	pop AX
	mov AL,AH
	mov SI, offset END_DOS_V
	call BYTE_TO_DEC
	mov DX, offset DOS_V;
	mov AH,9                          
	int 21h

	; OEM
	mov AL,BH
	call BYTE_TO_HEX
	mov DI, offset ENDOEM
	mov [DI-1], AX
	mov DX, offset OEM;
	mov AH, 09h                          
	int 21h

	; USER NUMBER
	mov AX,CX
	mov DI, offset USERNEND
	call WRD_TO_HEX
	mov AL,BL
	call BYTE_TO_HEX
	mov [DI-2], AX

	mov DX, offset USERN
	mov AH, 09h                      
	int 21h

	; выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
END START