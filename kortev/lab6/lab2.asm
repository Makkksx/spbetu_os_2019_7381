TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN

unavailableMemAdr db 'Unavailable mem adr: $'
UnavMemAdr db '    $'
EnvirAdr db 'Segm Envir Adr: $'
EnvAdr db '    $'
PrintTail db 'Tail:$'
TAIL db 50h DUP(' '),'$'
NoTail db 'No Tail$'
EnvCont db 'Envir content:',0DH,0AH,'$'
ModulePath db 'Programs path:','$'
ENDL db 0DH,0AH,'$'
	
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
;байт в AL переводится в два символа шестн. числа в AX 
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX; в AL старшая цифра
	pop CX          ; в AH младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; перевод в 16 с/c 16-ти разрядного числа
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
; перевод в 10с/с, SI - адрес поля младшей цифры
    push AX
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
	pop AX
	ret
BYTE_TO_DEC ENDP
;-------------------------------

Print PROC near
	mov AH,09h
	int 21h
	ret
Print ENDP

Unavailable_memory_adress PROC near
	mov ax,ds:[2] 		;адрес недоступной памяти
	mov es,ax
	mov di,offset UnavMemAdr+3

	call WRD_TO_HEX
	lea dx, unavailableMemAdr
	call Print
	lea dx, UnavMemAdr
	call Print
	lea dx, ENDL
	call Print
	ret
Unavailable_memory_adress ENDP

Environment_adress PROC near 
	mov ax,ds:[2Ch] ;адрес среды
	mov di,offset EnvAdr+3

	call WRD_TO_HEX
	lea dx, EnvirAdr
	call Print
	lea dx, EnvAdr
	call Print
	lea dx, ENDL
	call Print
	ret
Environment_adress ENDP

Print_tail PROC near ; хвост командной строки в символьном виде
	xor ch,ch
	mov cl,ds:[80h] ; число символов в хвосте командной строки
	
	cmp cl,0		;если 0-нет хвоста
	jne case_tail
	mov dx,offset NoTail
	call Print
	mov dx,offset ENDL
	call Print
	ret
	case_tail:
	
		lea dx, PrintTail
		call Print
	
		lea bp, TAIL
		cycle:
			mov di,cx
			mov bl,ds:[di+80h]
			mov ds:[bp+di-1],bl
		loop cycle
	
		lea dx, TAIL
		call Print
		lea dx, ENDL
		call Print
		ret
Print_tail ENDP

Print_environment PROC near 
	lea dx, EnvCont
	call Print

	mov ax,ds:[2ch]
	mov es,ax
	
	xor bp,bp
	cycle1:			;печать содержимого среды
		cmp word ptr es:[bp],0001h 
		je case_exit1
		cmp byte ptr es:[bp],00h 
		jne noendl
		mov dx,offset ENDL
		call Print
		inc bp
		noendl:
			mov dl,es:[bp]
			mov ah,02h
			int 21h
			inc bp
			jmp cycle1
	case_exit1:
	add bp,2
	
	lea dx, ENDL
	call Print
	lea dx, ModulePath
	call Print
	
	cycle2:	;печать расположения модуля
		cmp byte ptr es:[bp],00h
		je case_exit2
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp cycle2
	case_exit2:
	
	ret
Print_environment ENDP

BEGIN:
	call Unavailable_memory_adress
	call Environment_adress
	call Print_tail
	call Print_environment
	
	mov ah, 01h
	int 21h
	
	;xor AL,AL  ;|
	mov AH,4Ch ;| exit to dos
	int 21H    ;|
TESTPC ENDS
 END START