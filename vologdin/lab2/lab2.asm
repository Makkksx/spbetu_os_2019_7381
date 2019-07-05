TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
INACCESSMEMADDRINFO db 'Addres of a segment with first byte of inaccesible memory: $'
ACCESSMEMADDR db '    $'
ENVADDRINFO db 'Address of an environment segment: $'
ENVADDR db '    $'
TAILPRNTINFO db 'Tail:$'
TAIL db 50h DUP(' '),'$'
NOTAIL db 'No tail$'
ENVCONTENTINFO db 'Environment contents:',0DH,0AH,'$'
PRGRMPATHINFO db 'App path:',0DH,0AH,'$'
_ENDL db 0DH,0AH,'$'
PRINT PROC near
	mov AH,09h
	int 21h
	ret
PRINT ENDP
	
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

BYTE_TO_DEC PROC near
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

GET_INACCESS_MEM_ADDR PROC near
	mov ax,ds:[2]
	mov es,ax
	mov di,offset ACCESSMEMADDR+3
	call WRD_TO_HEX
	mov dx,offset INACCESSMEMADDRINFO
	call PRINT
	mov dx,offset ACCESSMEMADDR
	call PRINT
	mov dx,offset _ENDL
	call PRINT
	;mov ax,01000h 
	;mov es:[0h],ax ; works in dos
	ret
GET_INACCESS_MEM_ADDR ENDP

GET_ENV_ADDR PROC near
	mov ax,ds:[2Ch]
	mov di,offset ENVADDR+3
	call WRD_TO_HEX
	mov dx,offset ENVADDRINFO
	call PRINT
	mov dx,offset ENVADDR
	call PRINT
	mov dx,offset _ENDL
	call PRINT
	ret
GET_ENV_ADDR ENDP

PRINT_TAIL PROC near
	xor ch,ch
	mov cl,ds:[80h]
	
	cmp cl,0
	jne notnil
		mov dx,offset NOTAIL
		call PRINT
		mov dx,offset _ENDL
		call PRINT
		ret
	notnil:
	
	mov dx,offset TAILPRNTINFO
	call PRINT
	
	mov bp,offset TAIL
	cycle:
		mov di,cx
		mov bl,ds:[di+80h]
		mov ds:[bp+di-1],bl
	loop cycle
	
	mov dx,offset TAIL
	call PRINT
	ret
PRINT_TAIL ENDP

PRINT_ENV PROC near
	mov dx, offset _ENDL
	call PRINT
	mov dx, offset ENVCONTENTINFO
	call PRINT

	mov ax,ds:[2ch]
	mov es,ax
	
	xor bp,bp
	PE_cycle1:
		cmp word ptr es:[bp],0001h
		je PE_exit1
		cmp byte ptr es:[bp],00h
		jne PE_noendl
			mov dx,offset _ENDL
			call PRINT
			inc bp
		PE_noendl:
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp PE_cycle1
	PE_exit1:
	add bp,2
	
	mov dx, offset _ENDL
	call PRINT
	mov dx, offset PRGRMPATHINFO
	call PRINT
	
	PE_cycle2:
		cmp byte ptr es:[bp],00h
		je PE_exit2
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp PE_cycle2
	PE_exit2:
	
	ret
PRINT_ENV ENDP

BEGIN:
	call GET_INACCESS_MEM_ADDR
	call GET_ENV_ADDR
	call PRINT_TAIL
	call PRINT_ENV
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START