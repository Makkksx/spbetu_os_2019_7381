TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H 
START: JMP BEGIN

SAofInaccessibleMemory	db 'The segment address of the inaccessible memory (from PSP):     ', 0DH, 0AH, '$'
SAofEnvironment			db 0DH, 0AH, 'The segment address of the environment passed to the program:     ', 0DH, 0AH, '$'
TailOfComandLine		db 0DH, 0AH,'The tail of comand line:                                                   ', 0DH, 0AH, '$'
ContentsOfEnvironment 	db 0DH, 0AH, 'The contents of the environment:', 0DH, 0AH, '$'
PathOfModule			db 0DH, 0AH, 0AH, 'The path of the loaded module:', 0DH, 0AH, '$'

;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------
TETR_TO_HEX	PROC near
	and	al, 0Fh
	cmp	al, 09
	jbe	NEXT
	add	al, 07
	NEXT:
	add	al, 30h
	ret
TETR_TO_HEX	ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX	PROC near
	push cx
	mov	ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov	cl, 4 
	shr	al, cl
	call TETR_TO_HEX
	pop	cx 			
	ret
BYTE_TO_HEX	ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX PROC	near
	push bx
	mov	bh, ah
	call BYTE_TO_HEX
	mov	[di], ah
	dec	di 
	mov	[di], al
	dec	di
	mov	al, bh
	xor	ah, ah
	call BYTE_TO_HEX
	mov	[di], ah
	dec	di
	mov	[di], al
	pop	bx
	ret
WRD_TO_HEX ENDP
;--------------------------------------------------------------------------------
BYTE_TO_DEC	PROC near
	push cx
	push dx
	push ax
	xor	ah, ah
	xor	dx, dx
	mov	cx, 10 
	loop_bd:
	div	cx
	or dl, 30h
	mov [si], dl
	dec si
	xor	dx, dx
	cmp	ax, 10
	jae	loop_bd
	cmp	ax, 00h
	jbe	end_l
	or al, 30h
	mov	[si], al
	end_l:
	pop	ax
	pop	dx
	pop	cx
	ret
BYTE_TO_DEC	ENDP	
;--------------------------------------------------------------------------------
;ПРОЦЕДУРЫ ДЛЯ ОПРЕДЕЛЕНИЯ ДАННЫХ
;--------------------------------------------------------------------------------
FindSAofInaccessibleMemory PROC NEAR
	push ax
	push di
	mov ax, ds:[02h]
	mov di, offset SAofInaccessibleMemory
	add di, 3Eh 
	call WRD_TO_HEX
	pop di
	pop ax
	ret
FindSAofInaccessibleMemory ENDP
;--------------------------------------------------------------------------------
FindSAofEnvironment PROC NEAR
	push ax
	push di
	mov ax, ds:[02Ch]
	mov di, offset SAofEnvironment
	add di, 43h 
	call WRD_TO_HEX
	pop di
	pop ax
	ret
FindSAofEnvironment ENDP
;--------------------------------------------------------------------------------
FindTailOfComandLine PROC NEAR
	push ax
	push cx
	push dx	
	push si
	push di
	xor cx, cx
	mov si, 80h
	mov ch, byte ptr cs:[si]
	mov di, offset TailOfComandLine
	add di, 1Bh
	inc si
	Copy:
	cmp ch, 0h
	je StopCopy
	xor ax, ax
	mov al, byte ptr cs:[si]
	mov [di], al
	inc di
	inc si
	dec ch
	jmp Copy
	StopCopy:
	xor ax, ax
	mov al, 0Ah
	mov [di], al
	inc di
	mov al, '$'
	mov [di], al
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	ret
FindTailOfComandLine ENDP
;--------------------------------------------------------------------------------
FindContOfEnvirAndPathOfMod PROC NEAR
	push ax
	push dx
	push ds
	push es
	mov dx, offset ContentsOfEnvironment 
	call PRINT
	mov ah, 02h
	mov es, ds:[02Ch]
	xor si, si
	CopyContents:
	mov dl, es:[si]
	int 21h
	cmp dl, 0h
	je	StopCopyContents
	inc si
	jmp CopyContents
	StopCopyContents:
	inc si
	mov dl, es:[si]
	cmp dl, 0h
	jne CopyContents
	mov dx, offset PathOfModule
	call PRINT
	add si, 3h
	mov ah, 02h
	mov es, ds:[2Ch]
	CopyPath:
	mov dl, es:[si]
	cmp dl, 0h
	je StopCopyPath
	int 21h
	inc si
	jmp CopyPath
	StopCopyPath:
	pop es
	pop ds
	pop dx
	pop ax
	ret
FindContOfEnvirAndPathOfMod ENDP
;--------------------------------------------------------------------------------
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
BEGIN:
	;1) Сегментный адрес недоступной памяти, взятый из PSP
	call FindSAofInaccessibleMemory
	mov dx, offset SAofInaccessibleMemory
	call PRINT
	;2) Сегментный адрес среды, передаваемой программе
	call FindSAofEnvironment
	mov dx, offset SAofEnvironment
	call PRINT
	;3) Хвост командной строки 
	call FindTailOfComandLine
	mov dx, offset TailOfComandLine
	call PRINT
	;4) Содержимое области среды в символьном виде и 5) Путь загружаемого модуля
	call FindContOfEnvirAndPathOfMod
					
	xor al, al
	mov ah, 4ch
	int 21h
	
TESTPC ENDS
END START