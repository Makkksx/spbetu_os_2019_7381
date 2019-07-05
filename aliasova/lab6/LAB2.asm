PCinfo	segment
		assume cs:PCinfo, ds:PCinfo, es:nothing, ss:nothing
	org 	100h
	
start:		
	jmp		begin

	;data
	Inacc_mem	db	'Segment address of inaccessible memory: 0000$'
	Env_adr		db	'Segment address of environment: 0000$'
	Cmd_tail	db	'Tail of command line: $'
	Env_cont	db	'Contents of environment area: $'
	Load_path	db	'Path of loadable module: $'
	PressKey	db	'Press key $'
    endl 		db  13, 10, '$'

tetr_to_hex proc near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
   tetr_to_hex endp

;���� � al ��ॢ������ � ��� ᨬ���� 16-�筮�� �᫠ � ax
byte_to_hex proc near
    push 	cx
    mov 	ah, al
    call 	tetr_to_hex
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	tetr_to_hex ;� al ����� ���, � ah ������
    pop 	cx
    ret
   byte_to_hex endp

;��ॢ�� � 16 �� 16-� ࠧ�來��� �᫠
;ax - �᫮, di - ���� ��᫥����� ᨬ����
wrd_to_hex proc near
    push 	bx
    mov 	bh, ah
    call 	byte_to_hex
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    dec 	di
    mov 	al, bh
    call 	byte_to_hex
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    pop 	bx
    ret
   wrd_to_hex endp

;��ॢ�� � 10 ��, si - ���� ���� ����襩 ����
byte_to_dec proc near
    push 	cx
    push 	dx
    xor 	ah, ah
    xor 	dx, dx
    mov 	cx, 10
loop_bd:
    div 	cx
    or 		dl, 30h
    mov 	[si], dl
    dec 	si
    xor 	dx, dx
    cmp 	ax, 10
    jae 	loop_bd
    cmp 	al, 00h
    je 		end_l
    or 		al, 30h
    mov 	[si], al
end_l:
    pop 	dx
    pop 	cx
    ret
   byte_to_dec endp

;�뢮� ��ப�
print proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
   print endp

;�뢮� ᨬ����
print_symb proc near
	push	ax
	push	dx
	mov		ah, 02h
	int		21h
	pop		dx
	pop		ax
	ret
   print_symb endp

begin:

; �뢮� ᥣ���⭮�� ���� ������㯭�� �����
	mov 	ax, es:[0002h]
	mov 	di, offset Inacc_mem+43
	call 	wrd_to_hex
	mov 	dx, offset Inacc_mem
	call	print
	mov		dx, offset endl
	call	print

; �뢮� ᥣ���⭮�� ���� �।�
	mov 	ax, es:[002Ch]	
	mov 	di, offset Env_adr+35
	call 	wrd_to_hex
	mov 	dx, offset Env_adr
	call	print
	mov		dx, offset endl
	call	print	

; �뢮� 墮�� ��������� ��ப�
	mov		dx, offset Cmd_tail			
	call	print
	xor 	cx, cx
	xor 	bx, bx
	mov 	cl, byte PTR es:[80h]
	mov 	bx, 81h
loop1:
	cmp		cx, 0h
	je		next1
	mov 	dl, byte PTR es:[bx]
	call	print_symb
	inc		bx
	dec		cx
	jmp		loop1
next1:		
	mov		dx, offset endl
	call	print

; �뢮� ᮤ�ন���� ������ �।�
	mov		dx, offset Env_cont
	call	print
	mov		dx, offset endl
	call	print
	mov		bx, es:[002Ch]
	push	es
	mov		es, bx
	xor 	bx, bx
next2:
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je 		first_0
	call	print_symb
	inc 	bx
	jmp 	next2
first_0:
	mov		dx, offset endl
	call	print
	inc 	bx
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je 		second_0
	jmp 	next2
second_0:

	add 	bx, 3

; �뢮� ��� ����㦠����� �����				
	mov		dx, offset endl
	call	print	
	mov		dx, offset Load_path
	call	print	
	mov		dx, offset endl
	call	print	

loop2:
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je		next3
	call	print_symb 
	inc		bx
	jmp 	loop2
next3:	
	
;quit   
	mov		dx, offset endl
	call	print
	mov		dx, offset PressKey
	call	print
    xor 	ax, ax
    mov		ah, 01h
    int		21h
    mov 	ah, 4ch
    int 	21h
PCinfo	ENDS
		END    START
