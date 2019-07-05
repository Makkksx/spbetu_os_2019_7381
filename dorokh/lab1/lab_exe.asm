EOL EQU '$'
AStack SEGMENT STACK
		DW 512 DUP(?)
AStack ENDS


DATA 	SEGMENT
	
	str_type 	db 'PC type is ','$'
	ModifNum	db	'Modification number:   .   ',0dh,0ah,'$'
	OEM		db	'OEM:    ',0dh,0ah,'$'
	SerialNum	db	'Version number:       ',0dh,0ah,'$'


	str_PC 		db 'PC',0DH,0AH,'$'
	str_PC_XT 	db 'PC/XT',0DH,0AH,'$'
	str_AT 		db 'AT',0DH,0AH,'$'
	str_PC2_30 	db 'PC2 model 30',0DH,0AH,'$'
	str_PC2_50 	db 'PC2 model 50 or 60',0DH,0AH,'$'
	str_PC2_80 	db 'PC2 model 80',0DH,0AH,'$'
	str_PCjr 	db 'PCjr',0DH,0AH,'$'
	str_PC_Conv db 'PC Convertible',0DH,0AH,'$'

DATA	ENDS


CODE	SEGMENT
		ASSUME CS:CODE,	DS:DATA, SS:AStack


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

WRD_TO_HEX PROC near

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
WRD_TO_HEX ENDP


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

TYPE_PC PROC NEAR

		mov ax, 0F000h		
		mov es, ax			
		sub bx, bx
		mov bh, es:[0FFFEh]	
		ret

TYPE_PC ENDP

MOD_PC  PROC near
		push ax
		push si
		mov si, offset ModifNum
		add si, 22
		call BYTE_TO_DEC
		add si, 3
		mov al, ah
		call BYTE_TO_DEC
		pop si
		pop ax
		ret
	                                     
MOD_PC  ENDP

OEM_PC  PROC near
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

SER_PC	PROC near

		push	ax
		push	bx
		push	cx
		push	si
		mov 	al,bl
		call	BYTE_TO_HEX
		lea		di,SerialNum
		add		di,17
		mov 	[di],ax
		mov 	ax,cx
		lea		di,SerialNum
		add		di,22
		call	WRD_TO_HEX
		pop		si
		pop		cx
		pop		bx
		pop 	ax
		ret	                                     
SER_PC	ENDP 


PRINT	PROC near
		mov 	ah,09h
		int		21h
		ret
PRINT		ENDP


MAIN 	PROC near
		
		push 	ds
		sub		ax,ax
		push	ax
		mov 	ax,DATA
		mov 	ds,ax
		sub		ax,ax

		call 	TYPE_PC
		
		mov dx, offset str_type
		call PRINT
		
		mov dx, offset str_PC_XT
		cmp bh, 0FEh
		je	to_print
	
		mov dx, offset str_AT
		cmp bh, 0FCh
		je	to_print
	
		mov dx, offset str_PC2_30
		cmp bh, 0FAh
		je	to_print

	
		mov dx, offset str_PC2_80
		cmp bh, 0F8h
		je	to_print
	
		mov dx, offset str_PCjr
		cmp bh, 0FDh
		je	to_print
	
		mov dx, offset str_PC_Conv
		cmp bh, 0F9h
		je	to_print
		
		mov dx, offset str_PC2_50
		cmp bh, 0FCh
		je	to_print

		mov dx, offset str_PC
		cmp bh, 0FFh
		je	to_print
	
to_print:
	call	PRINT

		mov ah, 30h
		int 21h
		call	MOD_PC
		call    OEM_PC
		call 	SER_PC
		


		lea dx, ModifNum
		call PRINT
		lea dx, OEM
		call PRINT
        lea dx, SerialNum
		call PRINT

		xor		al,al
		mov 	ah,4ch
		int		21h
		ret
MAIN 	ENDP
CODE ENDS
		END MAIN