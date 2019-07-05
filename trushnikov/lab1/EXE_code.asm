EOL EQU '$'

DATA	SEGMENT
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
DATA ENDS

CODE	SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:AStack

WRITE_MSG		PROC	FAR
		mov		ah,09h
		int		21h
		ret
WRITE_MSG		ENDP

AStack	SEGMENT  STACK
        DW 512 DUP(?)			
AStack  ENDS

TETR_TO_HEX		PROC	FAR
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC FAR
		push	cx
		mov		al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	FAR
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		xor		ah,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP

BYTE_TO_DEC		PROC	FAR
		push	cx
		push	dx
		push	ax
		xor		ah,ah
		xor		dx,dx
		mov		cx,10
loop_bd:div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		loop_bd
		cmp		ax,00h
		jbe		end_l
		or		al,30h
		mov		[si],al
end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP

GET_PC_NUMBER 	PROC	FAR
		push 	ES
		mov		BX,0f000h
		mov 	ES,BX
		mov		BX,0
		mov 	AX,ES:[0fffeh]
		pop		ES
		ret
GET_PC_NUMBER		ENDP

DEFINE_PC_TYPE 	PROC	FAR
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

GET_SYS_VER		PROC	FAR
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

GET_OEM_NUM		PROC	FAR
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

GET_SERIAL_NUM	PROC	FAR
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

Main      		PROC  FAR
		push  	DS
    	sub   	AX,AX
    	push  	AX
    	mov   	AX,DATA
    	mov   	DS,AX
    	sub   	AX,AX
		
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
		call	WRITE_MSG
		mov		dx, offset OEM_NUMBER
		call	WRITE_MSG
		mov		dx, offset SERIAL_NUMBER
		call	WRITE_MSG

		xor		al,al
		mov		ah,3Ch
		int		21h
		ret
Main    		ENDP
CODE			ENDS
				END Main