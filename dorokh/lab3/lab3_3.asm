TESTPC	SEGMENT 
        ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING 
        org 100H	
				
START:  JMP BEGIN	

A_MEMORY db 'Availible memory:        B         ',0Dh,0Ah,'$'
E_MEMORY db 'Extended memory :        KB         ',0Dh,0Ah,'$'
TITLE_LINE db ' Address | MCB Type | PSP Address  |   Size   |    SD/SC               ',0Dh,0Ah,'$'
LINE  db '                                                                                   ',0Dh,0Ah,'$'

TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ;в AL - старшая, в AH - младшая
	pop CX
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
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

WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX,10
loop_b: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_b
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
endl:	pop DX
	pop CX
	ret
WRD_TO_DEC ENDP

BYTE_TO_DEC PROC near
;перевод в 10с/с, SI - адрес поля младшей цифры
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
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP


A_MEM		PROC near
	mov ah, 4ah
	mov bx, 0ffffh
	int 21h
	mov ax, 10h
	mul bx
	mov si, offset A_MEMORY
	add si, 23
	call WRD_TO_DEC
		ret
A_MEM		ENDP

E_MEM		PROC near
	xor dx,dx
	mov al,30h
    out 70h,al
    in al,71h 
    mov bl,AL 
    mov al,31h  
    out 70h,al
    in al,71h

	mov ah, al
	mov al, bl

	mov si, offset E_MEMORY
	add si, 23
	call WRD_TO_DEC
	ret
E_MEM		ENDP

MCB_BLOCK PROC near

	mov di, offset LINE
	add di, 5
	mov ax, es
	call WRD_TO_HEX

	add di,13
	xor ah,ah
	mov al,es:[0]
	call WRD_TO_HEX
	mov al,20h
	mov [di],al
	inc di
	mov [di],al

	mov ax, es:[1]
	add di, 16
	call WRD_TO_HEX

	add di, 17
	mov ax,es:[3]
	mov bx,10h
	mul bx
	push si
	mov si,di
	call WRD_TO_DEC
	pop si

	add di, 10
	mov bx, 0h
metka:
	mov dl, es:[8+bx]
	mov [di], dl
	inc di
	inc bx
	cmp bx, 8h
	jne metka
	mov ax, es:[3]
	mov bl, es:[0]
	ret
MCB_BLOCK ENDP

PRINT	PROC near
	push ax
	mov ah,09h
	int	21h
	pop ax
	ret
PRINT	ENDP

BEGIN:
	call A_MEM
	mov dx, offset A_MEMORY
	call PRINT
	
	mov ah, 4ah
	mov bx, offset end_size
	int 21h

	mov ah, 48h
	mov bx, 1000h
	int 21h

	call E_MEM
	mov dx, offset E_MEMORY
	call PRINT
	
	mov dx, offset TITLE_LINE
	call PRINT
	mov ah, 52h
	int 21h
	sub bx, 2h
	mov  es, es:[bx]

OUTPUT_LINE:
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx
	xor di,di

	call MCB_BLOCK
	mov dx, offset LINE
	call PRINT
	mov cx,es
	add ax,cx
	inc ax
	mov es,ax
	cmp bl,4Dh
	je OUTPUT_LINE
	
	
; выход в DOS
	xor al, al
	mov ah, 4ch
	int 21h
end_size db 0	
TESTPC 	ENDS
		END START	; конец модуля

