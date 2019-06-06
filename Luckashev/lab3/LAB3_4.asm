TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: JMP BEGIN
;DATA SEGMENT
available_memory	db 'Accesible memory size - $'
extended_memory		db 'Extended  memory size - $'
mem_request_error 	db 'Error occured during memory request. Error code:     $'
MCB_table		db 'MCB table:', 13, 10, ' Address|    Type|   Owner|    Size| Name$'
string	db '        |$'
;DATA ENDS
;-----------------------------------------
printstr	Proc near
	push	ax
	mov 	ah, 09h
	int 	21h
	call	reset_str
	pop 	ax
	ret
printstr endp

reset_str	PROC near
	cld
	lea 	di, string
	add 	di, 08h
	mov 	ah, '|'
	mov 	[di], ah
	mov 	ah, ' '
	mov 	cl, 0fh
	@loop:
		dec 	cl
		dec 	di
		mov 	[di], ah
		cmp 	cl, 00h
		je  	@endloop
	loop @loop
	@endloop:
	ret
reset_str	ENDP

newline	PROC near
	xor 	ax, ax
	mov 	dl, 13
	mov 	ah, 02h
	int 	21h
	mov 	dl, 10
	int 	21h
	ret
newline	ENDP

print_accesible_mem	PROC near
	lea 	dx, available_memory
	call	printstr
	mov 	ah, 4ah
	mov 	bx, 0ffffh
	int 	21h
	mov 	ax, 10h
	mul 	bx
	lea 	si, string
	add 	si, 08h
	call 	WRD_TO_DEC
	lea 	dx, string
	call 	printstr
	mov 	ah, 02h	
	mov 	dl, ' '
	int 	21h	
	mov 	dl, 'B'
	int 	21h	

	call 	newline
	ret
print_accesible_mem ENDP

print_extended_mem	PROC near
	lea 	dx, extended_memory
	call 	printstr
	mov 	AL, 30h
	out 	70h, AL
	in  	AL, 71h
	mov 	BL, AL
	mov 	AL, 31h
	out 	70h, AL
	in  	AL, 71h
	mov 	ah, al
	mov 	al, bl
	lea 	si, string
	add 	si, 08h
	xor 	dx, dx
	call 	WRD_TO_DEC
	lea 	dx, string
	call	printstr
	xor 	ax, ax
	mov 	ah, 02h
	mov 	dl, ' '
	int 	21h	
	mov 	dl, 'K'
	int 	21h	
	mov 	dl, 'B'
	int 	21h	
	call 	newline
	ret
print_extended_mem	ENDP

print_mcb 	PROC near
	lea 	dx, MCB_table
	call	printstr
	call	newline
	mov 	ah, 52h
	int 	21h
	mov 	ax, es:[bx - 2]
	mov 	es, ax
@print_block:
;adress
	lea 	di, string
	mov 	ax, es
	add 	di, 7
	call 	WRD_TO_HEX
	lea 	dx, string
	call 	printstr
;type
	mov 	al, es:[0]
	call 	BYTE_TO_HEX
	lea 	di, string
	add 	di, 6
	mov 	[di], ax
	lea 	dx, string
	call 	printstr
;owner
	lea 	di, string
	mov 	ax, es:[1]
	add 	di, 7
	call 	WRD_TO_HEX
	call	printstr
;size
	lea 	di, string
	add 	di, 7
	mov 	ax, es:[3]
	mov 	bx, 16
	mul 	bx
	mov 	si, di
	call	WRD_TO_DEC
	lea 	dx, string
	call 	printstr
;name
	xor 	bx, bx
	mov 	ah, 02h
	mov 	dl, ' '
	int 	21h		
@name_loop:
	cmp 	bx, 8
	je  	end_name_loop
	mov 	dl, es:[8 + bx]
	int 	21h
	inc 	bx
	loop	@name_loop
end_name_loop:
	cmp 	BYTE PTR es:[0], 5ah
	je  	end_mcb
	call	newline
	mov 	ax, es
	add 	ax, es:[3]
	inc 	ax
	mov 	es, ax
	loop @print_block
end_mcb:
	ret
print_mcb	ENDP

TETR_TO_HEX		PROC	near
    and	 AL, 0Fh
		cmp	 AL, 09
		jbe	 NEXT
		add	 AL,07
NEXT:
		add	 AL,30h
    ret
TETR_TO_HEX	ENDP
;-----------------------------------------
BYTE_TO_HEX	PROC	near
; байт в AL переводится в два символа шестн. числа в AX
    push CX
		mov	 AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov	 CL, 4
		shr	 AL, CL
		call TETR_TO_HEX ;в AL старшая цифра
		pop	 CX           ;в AH младшая
		ret
BYTE_TO_HEX  ENDP
;-----------------------------------------
WRD_TO_HEX	PROC	near
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
    push BX
		mov	 BH, AH
		call BYTE_TO_HEX
		mov	 [DI], AH
		dec	 DI
		mov	 [DI], AL
		dec	 DI
		mov	 AL, BH
		call BYTE_TO_HEX
		mov	 [DI], AH
		dec	 DI
		mov	 [DI], AL
		pop	 BX
		ret
WRD_TO_HEX ENDP
;-----------------------------------------
BYTE_TO_DEC	PROC	near
    push CX
		push DX
		xor	 AH, AH
		xor	 DX, DX
		mov	 CX, 10
loop_bd:
    div	 CX
		or   DL, 30h
		mov	 [SI], DL
		dec	 SI
		xor	 DX, DX
		cmp	 AX, 10
		jae	 loop_bd
		cmp	 AL, 00h
		je   end_l
		or   AL,30h
		mov	 [SI], AL
end_l:
		pop	 DX
		pop	 CX
		ret
BYTE_TO_DEC	ENDP
;-----------------------------------------
WRD_TO_DEC	PROC near
    push cx
    push dx
    mov  cx, 10
wloop:
	  div  cx
	  or   dl, 30h
	  mov  [si], dl
	  dec  si
		xor  dx, dx
    cmp  ax, 10
    jae  wloop
    cmp  al, 00h
  	je   wend
    or   al, 30h
    mov  [si], al
wend:
    pop  dx
    pop  cx
    ret
WRD_TO_DEC 	ENDP
;-----------------------------------------

shrink_mem	PROC near
	mov 	ah, 4ah
	lea 	bx, eob
	int 	21h
	ret
shrink_mem	ENDP

request_mem	PROC near
	mov 	ah, 48h
	mov 	bx, 1000h
	int 	21h
	jc  	case_err
	jmp 	end_request
case_err:
	lea 	dx, mem_request_error
	lea 	di, mem_request_error
	add 	di, 52
	call	WRD_TO_HEX
	call	printstr
	call 	newline
end_request:
	ret
request_mem	ENDP

BEGIN:
		call	print_accesible_mem
		call 	request_mem				
		call 	print_extended_mem	
		call 	print_mcb
		xor 	AL,AL
		mov 	AH,4Ch
		int 	21H
eob:
TESTPC ENDS
END START