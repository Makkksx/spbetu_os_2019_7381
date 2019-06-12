TESTPC 	SEGMENT
		ASSUME 	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG		100H
START:  JMP		BEGIN
		
;ДАННЫЕ
PC_TYPE			db		'PC TYPE:','$'
PC_UNDEFINED	db		'PC UNDEFINED:  ',0dh,0ah,'$'
SYSTEM_VERSION	db		'SYSTEM VERSION:  .  ',0dh,0ah,'$'
OEM_NUMBER		db		'OEM number:      ',0dh,0ah,'$'
SERIAL_NUMBER	db		'USER SERIAL NUMBER:    ',0dh,0ah,'$'
PC				db		'PC',0dh,0ah,'$'
PCXT			db		'PC/XT',0dh,0ah,'$'
AT				db		'AT',0dh,0ah,'$'
PS2_30			db		'PS2 MODEL 30',0dh,0ah,'$'
PS2_50			db		'PS2 MODEL 50 OR 60',0dh,0ah,'$'
PS2_80			db		'PS2 MODEL 80',0dh,0ah,'$'
PCjr			db		'PSjr',0dh,0ah,'$'
PC_Convertible	db		'PS Convertible',0dh,0ah,'$'



TETR_TO_HEX	PROC near
		and AL,0FH
		cmp	AL,09
		jbe NEXT
		add AL,07
NEXT:	add AL,30H
		ret 
TETR_TO_HEX ENDP

BYTE_TO_HEX	PROC near
;байт в AL переводится в два символа шестн. числа в AX
		push CX
		mov  AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov  CL,4
		shr  AL,CL
		call TETR_TO_HEX;в AL старшая цифра
		pop CX 			;в AH МЛАДШАЯ
		ret
BYTE_TO_HEX ENDP

WRITE_MSG		PROC	near
		mov		ah,09h
		int		21h
		ret
WRITE_MSG		ENDP

WRD_TO_HEX   PROC  near 
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес поселеднего символа
		push     BX
		mov      BH,AH
		call     BYTE_TO_HEX
		mov      [DI],AH
		dec      DI
		mov      [DI],AL
		dec      DI
		mov      AL,BH
		call     BYTE_TO_HEX
		mov      [DI],AH
		dec      DI
		mov      [DI],AL 
		pop      BX
		ret
WRD_TO_HEX ENDP

BYTE_TO_DEC   PROC  near
		 push     CX
		 push     DX
		 xor      AH,AH
		 xor      DX,DX 
		 mov      CX,10
loop_bd: div      CX
		 or       DL,30h
		 mov      [SI],DL
		 dec      SI
		 xor      DX,DX
		 cmp      AX,10
		 jae      loop_bd
		 cmp      AL,00h
		 je       end_l 
		 or       AL,30h
		 mov      [SI],AL
		 end_l:     pop      DX 
		 pop      CX
		 ret
BYTE_TO_DEC    ENDP

GET_PC_NUMBER 	PROC	near
; Функция определяющая тип PC
		push 	ES
		mov		BX,0f000h
		mov 	ES,BX
		mov		BX,0
		mov 	AX,ES:[0fffeh]
		pop		ES
		ret
GET_PC_NUMBER		ENDP

GET_SYS_VER		PROC	near
; Функция определяющая версию системы
		push	AX
		push 	SI
		lea		SI,SYSTEM_VERSION
		add		SI,16
		call	BYTE_TO_DEC
		add		SI,3
		mov 	AL,AH
		call	BYTE_TO_DEC
		pop 	SI
		pop 	AX
		ret
GET_SYS_VER		ENDP

GET_SERIAL_NUM	PROC	near
		push	AX
		push	BX
		push	CX
		push	SI
		mov		AL,BL
		call	BYTE_TO_HEX
		lea		DI,SERIAL_NUMBER
		add		DI,22
		mov		[DI],AX
		mov		AX,CX
		lea		DI,SERIAL_NUMBER
		add		DI,27
		call	WRD_TO_HEX
		pop		SI
		pop		CX
		pop		BX
		pop		AX
		ret
GET_SERIAL_NUM	ENDP

GET_OEM_NUM		PROC	near
; функция определяющая OEM
		push	AX
		push	BX
		push	SI
		mov 	AL,BH
		lea		SI,OEM_NUMBER
		add		SI,14
		call	BYTE_TO_DEC
		pop		SI
		pop		BX
		pop		AX
		ret
GET_OEM_NUM		ENDP

DEFINE_PC_TYPE 	PROC	near
; Функция, определяющая тип PC		
		cmp 	AL, 0FFh
		jne		cmp1
		mov 	DX, offset PC
		ret
	
cmp1:	cmp 	AL, 0FEh
		jne		cmp2
		mov 	DX, offset PCXT
		ret
	
cmp2:	cmp 	AL, 0FCh
		jne		cmp3
		mov 	DX, offset AT
		ret
		
cmp3:	cmp 	AL, 0FAh
		jne		cmp4
		mov 	DX, offset PS2_30
		ret

cmp4:	cmp 	AL, 0FCh
		jne		cmp5
		mov 	DX, offset PS2_50
		ret		
		
cmp5:	cmp 	AL, 0F8h
		jne		cmp6
		mov 	DX, offset PS2_80
		ret
		
cmp6:	cmp 	AL, 0FDh
		jne		cmp7
		mov 	DX, offset PCjr
		ret
		
cmp7:	cmp 	AL, 0F9h
		jne		cmp8
		mov 	DX, offset PC_Convertible
		ret

cmp8:	call 	BYTE_TO_HEX
		lea		BX,PC_UNDEFINED
		mov		[BX+14],AX
		mov 	DX, offset PC_UNDEFINED
		ret
		
DEFINE_PC_TYPE		ENDP

BEGIN:
		call 	GET_PC_NUMBER		
		mov  	DX, offset PC_TYPE
		call 	WRITE_MSG
		call 	DEFINE_PC_TYPE
		call 	WRITE_MSG
		xor 	ax,ax
		mov		ah,30h
		int		21h
		call	GET_SYS_VER
		call	GET_OEM_NUM
		call	GET_SERIAL_NUM
		mov		DX, offset SYSTEM_VERSION
		call	Write_msg
		mov		dx, offset OEM_NUMBER
		call	Write_msg
		mov		dx, offset SERIAL_NUMBER
		call	Write_msg		
		xor  	AL,AL
		mov  	AH,4Ch
		int  	21H 		
TESTPC	ENDS
		END 	START