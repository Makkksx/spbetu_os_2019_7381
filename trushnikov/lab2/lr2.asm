TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN

; ДАННЫЕ
UNAVAILABLE_M	db		'Segment address of unavailable memory:      ',0dh,0ah,'$'
ENVIRONMENT_A	db		'Segment address of environment:     ',0dh,0ah,'$'
TAIL			db		'Tail:',0dh,0ah,'$'
SOD_SRED		db		'Content of the environment: ' , '$'
PATH			db		'Way to module: ' , '$'
ENDL			db		0dh,0ah,'$'

NEW_LINE		PROC	near
		lea		dx,ENDL
		call	Write_msg
		ret
NEW_LINE		ENDP

Write_msg		PROC	near
		mov		ah,09h
		int		21h
		ret
Write_msg		ENDP

TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC near
; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	near
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP

; определяем сегментный адрес недоступной памяти
DEFINE_UN_MEMORY		PROC	near
		push	ax
		mov 	ax,es:[2]
		lea		di,UNAVAILABLE_M
		add 	di,42
		call	WRD_TO_HEX
		pop		ax
		ret
DEFINE_UN_MEMORY		ENDP

;определяем сегментый адрес среды, передаваемой программе
DEFINE_EN_A		PROC	near
		push	ax
		mov 	ax,es:[2Ch]
		lea		di,ENVIRONMENT_A
		add 	di,34
		call	WRD_TO_HEX
		pop		ax
		ret
DEFINE_EN_A		ENDP

;выводим хвост командной строки в символьном виде
DEFINE_TAIL		PROC	near
		push	ax
		push	cx
    	xor 	ax, ax
    	mov 	al, es:[80h]
    	add 	al, 81h
    	mov 	si, ax
    	push 	es:[si]
    	mov 	byte ptr es:[si+1], '$'
    	push 	ds
    	mov 	cx, es
    	mov 	ds, cx
    	mov 	dx, 81h
    	call	Write_msg
   	 	pop 	ds
    	pop 	es:[si]
    	pop		cx
    	pop		ax
		ret
DEFINE_TAIL		ENDP

; Определяем содержимое области среды и путь к модулю
DEFINE_SODOS	PROC	near
		push 	es 
		push	ax 
		push	bx 
		push	cx 
		mov		bx,1 
		mov		es,es:[2ch] 
		mov		si,0 
	RE1:
		call	NEW_LINE 
		mov		ax,si 
	RE:
		cmp 	byte ptr es:[si], 0 
		je 		NEXT2 
		inc		si 
		jmp 	RE 
	NEXT2:
		push	es:[si] 
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx,es 
		mov		ds,cx 
		mov		dx,ax 
		call	Write_msg 
		pop		ds 
		pop		es:[si] 
		cmp		bx,0 
		jz 		LAST 
		inc		si 
		cmp 	byte ptr es:[si], 01h 
    	jne 	RE1 
    	call	NEW_LINE 
    	lea		dx,PATH 
    	call	Write_msg 
    	mov		bx,0 
    	add 	si,2 
    	jmp 	RE1 
    LAST:
    	call	NEW_LINE 
		pop		cx 
		pop		bx 
		pop		ax 
		pop		es 
		ret
DEFINE_SODOS	ENDP

BEGIN:
		call	DEFINE_UN_MEMORY
		call	DEFINE_EN_A
		mov		dx, offset UNAVAILABLE_M   
		call	Write_msg  
		mov		dx, offset ENVIRONMENT_A  
		call	Write_msg
		mov 	dx, offset TAIL
		call	Write_msg
		call	DEFINE_TAIL
		call	NEW_LINE 
		mov		dx, offset SOD_SRED 
		call	Write_msg
		call	DEFINE_SODOS
		
		; выход в DOS
		xor		al,al
		mov 	ah, 01h
		int		21h
		mov 	ah, 04Ch
		int 	21h
		ret
TESTPC	ENDS
		END 	START