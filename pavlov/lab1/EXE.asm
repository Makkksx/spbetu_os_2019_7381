_STACK	SEGMENT	STACK
		db	512	dup(0)
_STACK	ENDS
		

_DATA	SEGMENT
		ModifNum		db		'Modification number:   .   ', 0dh, 0ah, '$'
		OEM				db		'OEM:    ',0dh,0ah,'$'
		UserSerialNum	db		'User serial number:       ', 0dh, 0ah, '$'

		Type_PC_Other	db		2 dup ('?'), 'h$'
		Type_PC 		db 		'TypePC: PC', 0DH, 0AH, '$'
		Type_PC_XT 		db 		'TypePC: PC/XT', 0DH, 0AH, '$'
		Type_AT 		db 		'TypePC: AT', 0DH, 0AH, '$'
		Type_PS2_30 	db 		'TypePC: PC2 model 30', 0DH, 0AH,'$'
		Type_PS2_50 	db 		'TypePC: PC2 model 50 or 60', 0DH, 0AH,'$'
		Type_PS2_80 	db 		'TypePC: PC2 model 80', 0DH, 0AH, '$'
		Type_PCjr 		db 		'TypePC: PCjr', 0DH, 0AH, '$'
		Type_PC_Conv 	db 		'TypePC: PC Convertible', 0DH, 0AH, '$'
_DATA 	ENDS
_CODE SEGMENT
		ASSUME CS:_CODE, DS:_DATA, ES:NOTHING, SS:_STACK

TETR_TO_HEX	PROC near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC near

		push	cx
		mov		al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX 
		pop		cx 			
		ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX	PROC near

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
WRD_TO_HEX	ENDP

BYTE_TO_DEC	PROC near

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
BYTE_TO_DEC	ENDP

PRINT	PROC 	near
		push 	ax
		mov 	ah,09h
		int		21h
		pop 	ax
		ret
PRINT	ENDP

MOD_PC	PROC near
		push 	ax
		push 	si
		mov 	si, offset ModifNum
		add 	si, 22
		call 	BYTE_TO_DEC
		add 	si, 3
		mov 	al, ah
		call 	BYTE_TO_DEC
		pop 	si
		pop 	ax
		ret
	                                     
MOD_PC	ENDP


OEM_PC	PROC near
		push	ax
		push	bx
		push	si
		mov 	al,bh
		lea		si, OEM
		add		si, 6
		call	BYTE_TO_DEC
		pop		si
		pop		bx
		pop		ax
		ret
	                                     
OEM_PC	ENDP

SER_PC	PROC	near
		push 	ax
		push	bx
		push	cx
		push	si
		mov 	al,bl
		call	BYTE_TO_HEX
		lea		di,UserSerialNum
		add		di,20
		mov 	[di],ax
		mov 	ax,cx
		lea		di,UserSerialNum
		add		di,25
		call	WRD_TO_HEX
		pop		si
		pop		cx
		pop		bx
		pop 	ax
		ret	   
SER_PC	ENDP		

MAIN 	PROC	near
		mov 	ax, _DATA
		mov 	ds, ax
		sub 	ax, ax
		mov 	bx, 0F000h
		mov 	es, bx
		mov 	ax, es:[0FFFEh]
		;PC
		cmp 	al, 0FFh
		je 		_PC
		;PC/XT
		cmp 	al, 0FEh
		je 		_PC_XT
		cmp 	al, 0FBh
		je 		_PC_XT
		;AT
		cmp 	al, 0FCh
		je		_AT
		;PS2 model 30
		cmp 	al, 0FAh
		je		_PS2_30
		;PS2 model 80
		cmp 	al, 0F8h
		je		_PS2_80
		;PCjr
		cmp		al, 0FDh
		je		_PCjr
		;PC Convertible
		cmp 	al, 0F9h
		je		_PC_Conv
		;unknown type
		call 	BYTE_TO_HEX		
		lea 	di, Type_PC_Other
		mov 	[di], ax
		lea 	dx, Type_PC_Other
		jmp 	_EndPC
			
_PC:	lea 	dx, Type_PC
		jmp		_EndPC
_PC_XT:	lea 	dx, Type_PC_XT
		jmp		_EndPC	
_AT:	lea 	dx, Type_AT
		jmp		_EndPC
_PS2_30:lea 	dx, Type_PS2_30
		jmp		_EndPC
_PS2_80:lea 	dx, Type_PS2_80
		jmp		_EndPC
_PCjr:	lea 	dx, Type_PCjr
		jmp		_EndPC
_PC_Conv:lea 	dx, Type_PC_Conv
		
_EndPC: call PRINT
	
		sub 	ax, ax
		mov 	ah, 30h
		int 	21h
		call	MOD_PC
		call    OEM_PC
		call 	SER_PC
		
		;print results
		lea 	dx, ModifNum
		call 	PRINT
		lea 	dx, OEM
		call 	PRINT
        lea		dx, UserSerialNum
		call 	PRINT
		
		mov ax, 4C00h
		int 21h
		ret
MAIN	ENDP
_CODE 	ENDS
		END  	MAIN