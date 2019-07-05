TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: 	JMP	BEGIN

MemAvl			db		'Available memory:        B', 0dh, 0ah, '$'
ExtMem			db		'Extended memory:       KB', 0dh, 0ah, '$'
TableHead 		db 		'MCB Address | MCB Type  |  Owner | 	 Size    |    Name    ', 0dh, 0ah, '$'
MCBInfo 		db 		'                                                            ', 0dh, 0ah, '$'


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
		mov		ah,al
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

WRD_TO_DEC PROC NEAR
		push 	cx
		push 	dx
		mov 	cx,10
loop_b: div 	cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor 	dx,dx
		cmp 	ax,10
		jae 	loop_b
		cmp 	al,00h
		je 		endl
		or 		al,30h
		mov 	[si],al
endl:	pop 	dx
		pop 	cx
		ret
WRD_TO_DEC ENDP

PRINT	PROC 	near
		push 	ax
		mov 	ah,09h
		int		21h
		pop 	ax
		ret
PRINT	ENDP	

BEGIN:	
		;Get available memory
		mov 	ah, 4ah
		mov 	bx, 0ffffh
		int 	21h
		mov 	ax, bx
		inc 	ax
		mov 	bx, 16
		mul 	bx
		lea 	si, MemAvl + 23
		call 	WRD_TO_DEC
		lea		dx, MemAvl
		call	PRINT
		
		;Freeing up extra memory
		mov 	ah, 4ah
		lea 	bx, EndofProgram
		int 	21h

		mov 	ah, 48h
		mov 	bx, 1000h
		int 	21h
		
		;Get extended memory
		sub 	ax, ax
		sub		dx, dx
		mov 	al, 30h
		out 	70h, al
		in 		al, 71h 
		mov 	bl, al 
		mov 	al, 31h  
		out 	70h, al
		in 		al, 71h
		mov 	ah, al
		mov 	al, bl
		lea		si, ExtMem + 21
		call 	WRD_TO_DEC
		lea 	dx, ExtMem
		call 	PRINT
		
		;Get MCB chain
		sub		ax, ax
		sub		dx, dx
		lea		dx, TableHead
		call	PRINT
		mov 	ah, 52h
		int 	21h
		sub 	bx, 2h
		mov 	es, es:[bx]
ForEachMCB:
		;Address of MCB
		lea 	di, MCBInfo
		mov 	ax, es
		add 	di, 7
		call 	WRD_TO_HEX

		;Type of MCB
		lea 	di, MCBInfo
		add 	di, 16
		sub 	ah, ah
		mov 	al, es:[0]
		call 	BYTE_TO_HEX
		mov 	[di], al
		inc 	di
		mov 	[di], ah

		;Owner
		lea 	di, MCBInfo
		mov 	ax, es:[1]
		add 	di, 29
		call 	WRD_TO_HEX

		;Size of MCB
		lea 	di, MCBInfo
		mov 	ax, es:[3]
		mov 	bx, 10h
		mul 	bx
		add 	di, 44
		push 	si
		mov 	si, di
		call 	WRD_TO_DEC
		pop 	si

		;Name of owner
		lea 	di, MCBInfo
		add 	di, 53
		mov 	bx, 0
Last8Bytes:
		mov 	dl, es:[bx+8]
		mov 	[di], dl
		inc 	di
		inc 	bx
		cmp 	bx, 8
		jne		Last8Bytes
		mov 	ax, es:[3]
		mov 	bl, es:[0]
		
		lea 	dx, MCBInfo
		call	PRINT
		
		mov 	cx, es
		add 	ax, cx
		inc 	ax
		mov 	es, ax

		cmp 	bl, 4Dh
		je 		ForEachMCB
		
		;Exit in DOS
		mov ax, 4C00h
		int 21h
EndofProgram 	db	0
TESTPC 	ENDS
		END  	START