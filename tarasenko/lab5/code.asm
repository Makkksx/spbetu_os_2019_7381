.286
text segment
	assume cs:text, ds:data, ss:stk
	
Start:
	PSP dw 0
	KEEP_CS dw 0
	KEEP_IP dw 0
	int9h dd 0
    scanСode_1 db 3
    scanСode_2 db 4
    scanСode_3 db 5
    scanСode_4 db 6

	_ax dw ?
	_es dw ?
	_ss dw ?
	_sp dw ?
		
	stbl dw 64 dup(?)

my_int proc far
	jmp body_my_int_m
	INT_SET_FLAG dw 1111h
body_my_int_m:
	mov cs:_ax, ax
	mov cs:_ss, ss
	mov cs:_sp, sp
	mov ax, cs
	mov ss, ax
	mov sp, offset stbl + 128
	mov ax, cs:_ax
	pusha
	push es
	push ds
	
	in		al, 60h
	
	mov		ch, 00h
	
	cmp		al, cs:[scanСode_1]
	jne		next1
	mov		cl, '@'
	jmp		do_req
next1:	
	cmp		al, cs:[scanСode_2]
	jne		next2
	mov		cl, '#'
	jmp		do_req
next2:	
	cmp		al, cs:[scanСode_3]
	jne		next3
	mov		cl, '$'
	jmp		do_req
next3:	
	cmp		al, cs:[scanСode_4]
	jne		int9do
	mov		cl, '%'
	jmp		do_req
	
int9do:
	pop ds
	pop es
	popa
	
	mov ss, cs:_ss
	mov sp, cs:_sp
	jmp		cs:[int9h]

do_req:
	in 		al, 61h
	mov 	ah, al
	or 		al, 80h
	out 	61h, al
	xchg 	ah, al
	out 	61H, al
	mov 	al, 20h
	out 	20h, al
	
	mov 	ah, 05h
	int 	16h 
	or 		al, al 
	jz 	Quit 
	
	push 	es
	push 	si
	mov 	ax, 0040h
	mov 	es, ax
	mov 	si, 001ah
	mov 	ax, es:[si] 
	mov 	si, 001ch
	mov 	es:[si], ax	
	pop		si
	pop		es

Quit:	
	pop ds
	pop es
	popa
	
	mov ss, cs:_ss
	mov sp, cs:_sp
	mov 	al, 20h
	out 	20h, al
	iret
my_int endp
End_resident:

print macro strParam
	push dx
	push ax
	xor ax, ax
	xor dx, dx
	
	lea dx, strParam
    mov ah,09h
    int 21h
	
	pop ax
	pop dx
endm

TETR_TO_HEX PROC near
	and AL,0Fh 
	cmp AL,09 
	jbe NEXT 
	add AL,07 
NEXT: 
	add AL,30h 
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
	xor DX,DX 
	mov CX,10 
loop_bd: 
	div CX 
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
end_l: 
	pop DX 
	pop CX 
	ret 
BYTE_TO_DEC ENDP 

old_int_save proc near
	pusha
	push es
	push di
	mov ax, 3509h
	int 21h
	mov cs:KEEP_IP, bx
	mov cs:KEEP_CS, es
	mov word ptr int9h+2, es
	mov word ptr int9h, bx
	pop di
	pop es
	popa
	ret
old_int_save endp
	
set_new_int proc near
	pusha
	push ds
	mov dx, offset my_int
	mov ax, seg my_int
	push ax
	push dx

    print MY_INT_INST
	
	pop dx
	pop ax
	mov ds, ax
	mov ax, 2509h
	int 21h
	pop ds
	popa
	ret
set_new_int endp
	
load_my_int proc near	
	mov dx, seg text	
	add dx, (End_resident-Start)
	mov cl, 4
	shr dx, cl
	inc dx
	mov ah, 31h
	int 21h
	ret
load_my_int endp
	
delete_my_int proc near	
	cli
	pusha
	push ds
	push es
	
	mov ax, 3509h
	int 21h
	mov ax, es:[2]
	mov cs:KEEP_CS, ax
	mov ax, es:[4]
	mov cs:KEEP_IP, ax
	
	mov ax, cs:KEEP_CS
	mov dx, cs:KEEP_IP
	lea di, DELETE_OLD_INT
	add di, 60
	mov ax, cs:KEEP_CS
	call WRD_TO_HEX
	add di, 8
	mov ax, cs:KEEP_IP
	call WRD_TO_HEX

	print DELETE_OLD_INT
	
	mov ax, es:[0]
	mov cx, ax
	mov es, ax
	mov ax, es:[2Ch]
	mov es, ax
	xor ax, ax
	mov ah, 49h
	int 21h
	mov es, cx
	xor ax, ax
	mov ah, 49h
	int 21h
	mov dx, cs:KEEP_IP
	mov ax, cs:KEEP_CS
	mov ds, ax
	mov ax, 2509h	
	int 21h
	
	pop es
	pop ds
	popa
	sti
	
	ret
delete_my_int endp

main proc near
	push ds
	mov ax, seg data
	mov ds, ax
	pop cs:PSP
	
	mov es, cs:PSP
	mov al, es:[80h]
	cmp al, 4
	jnz Next_main

	mov ax, es:[82h]
	cmp al, '/'
	jnz Next_main
	cmp ah, 'u'
	jnz Next_main
	mov ah, es:[84h]
	cmp ah, 'n'
	jnz Next_main
	mov DEL_FLAG, 1
	
Next_main:
	mov ax, 3509h
	int 21h
	mov ax, es:[bx+3]
	cmp ax, 1111h
	jz Int_has_been_installed
	
	cmp DEL_FLAG, 1
	jz Int_hasnt_been_installed
	
	call old_int_save
	call set_new_int
	call load_my_int
	
	jmp Exit
	
Int_has_been_installed:
	cmp DEL_FLAG, 1	
	jz Delete_int
	
	print MY_INT_ALREADY_INSTALL
	jmp Exit
	
Delete_int:
	call delete_my_int
	jmp Exit
	
Int_hasnt_been_installed:
	print INT_NOT_INST
	
Exit:
	xor al, al
	mov ah, 4Ch
	int 21h
	ret

main endp

text ends

data segment
	DEL_FLAG db 0
	NEXT_LINE db	10, 13, '$'
	SPACE db ' $'
	DEFAULT_INT	db 'Default interrupt installed', 10, 13, '$'
	MY_INT_INST	db 'Interruption has been installed', 10, 13, '$'
	MY_INT_ALREADY_INSTALL	db 'Interruption has been already installed', 10, 13, '$'
	DELETE_OLD_INT db 'Interruption was deleted', 10, 13, '$'
	INT_NOT_INST db 'Interruption has not been installed ', 10, 13, '$'
	
data ends

stk segment stack
	dw 128 dup (?)
stk ends

end main