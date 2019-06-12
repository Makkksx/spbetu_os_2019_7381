CSEG	SEGMENT
ASSUME	CS:CSEG, DS:CSEG, ES:NOTHING, SS:NOTHING 
ORG	100H
START:	JMP	BEGIN

str1 db 'Unaccessable memory starts from: ', '$'
mem_addr db 5 dup(?)
str2 db 'Segment adress provided to the program: ', '$'
seg_addr db 5 dup(?)
tail_msg db 'Tail of the command line: ', '$'
tail db 50 dup(?)
content_msg db 'Enviroment content: ', 0Dh, 0Ah, '$'
content db 256 dup(?)
path_msg db 'Path of the program: ', '$'
path db 50 dup(?)

TETR_TO_HEX	PROC	near
	and	AL,0Fh
	cmp	AL,09
	jbe	NEXT
	add	AL,07
NEXT:	
	add	AL,30h
	ret 
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC	near 		;num stored in AL into ASCII in AX in hex
	push CX
	mov	AH, AL
	call TETR_TO_HEX
	xchg AL,AH
	mov	CL, 4
	shr	AL, CL
	call TETR_TO_HEX
	pop	CX
	ret 
BYTE_TO_HEX	ENDP

WRITE proc near
	mov cx, 2
cycle:
	xchg al, ah
	push ax
	call BYTE_TO_HEX
	mov [si], al
	inc si
	mov [si], ah
	inc si
	pop ax
	loop cycle

	mov byte ptr [si], '$'
	ret
WRITE endp

WRT_CONTENT proc near
	mov bx, 2Ch
	mov ax, es:bx
	mov es, ax
	xor si, si 				;moving in enviroment
search:
	cmp byte ptr [es:si], 0 			;EOL
	jne wrt
	mov byte ptr [di], 0Dh
	mov byte ptr [di+1], 0Ah
	add di, 2
	inc si
	cmp byte ptr [es:si], 0 			;end of table
	je end_table
wrt:
	mov al, [es:si]
	mov [di], al
	inc di
	inc si
	jmp search

end_table:
	add si, 3
	mov byte ptr [di], '$'
	mov di, offset path
wrt_path:
	cmp byte ptr [es:si], 0
	je done
	mov bl, [es:si]
	mov [di], bl
	inc di
	inc si
	jmp wrt_path
done:
	mov byte ptr [di], 0Dh
	mov byte ptr [di+1], 0Ah
	mov byte ptr [di+2], '$'
	ret
WRT_CONTENT endp

BEGIN:
	mov bx, 2
	mov ax, es:bx
	mov si, offset mem_addr
	call WRITE

	mov ah, 09h
	mov dx, offset str1
	int 21h

	mov dx, offset mem_addr
	int 21h

	mov dl, 0Dh				;new line
	mov ah, 02h
	int 21h
	mov dl, 0Ah
	int 21h

	mov bx, 2Ch
	mov ax, es:bx
	mov si,	offset seg_addr
	call WRITE

	mov ah, 09h
	mov dx, offset str2
	int 21h 

	mov dx, offset seg_addr
	int 21h

	mov dl, 0Dh				;new line
	mov ah, 02h
	int 21h
	mov dl, 0Ah
	int 21h

	mov bx, 80h
	xor ch, ch
	mov cl, es:bx 			;how long is the tail
	mov bx, 81h
	add bx, cx 				;starting from the end
	dec bx
	mov si, offset tail
	add si, cx
	mov byte ptr [si], '$' 
	dec si
wrt_tail:
	cmp cx, 0
	je skip
	mov ah, es:bx
	mov [si], ah
	dec si
	dec bx
	dec cx
	jmp wrt_tail

skip:
	mov dx, offset tail_msg
	mov ah, 09h
	int 21h

	mov dx, offset tail
	int 21h

	mov dl, 0Dh				;new line
	mov ah, 02h
	int 21h
	mov dl, 0Ah
	int 21h

	mov di, offset content
	call WRT_CONTENT
	mov dx, offset content_msg
	mov ah, 09h
	int 21h
	mov dx, offset content
	int 21h
	mov dx, offset path_msg
	int 21h
	mov dx, offset path
	int 21h

	xor	al, al
	mov	ah, 4Ch
	int	21h
CSEG	ENDS

END	START