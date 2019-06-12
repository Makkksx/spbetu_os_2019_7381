STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
ParameterBlock dw ?
	dd ?
	dd ?
	dd ?
	Mem_7    DB 0DH, 0AH,'Memory control unit destroyed!',0DH,0AH,'$'
	Mem_8    DB 0DH, 0AH,'Not enough memory to perform the function!',0DH,0AH,'$'
	Mem_9    DB 0DH, 0AH,'Wrong address of the memory block!',0DH,0AH,'$'
	Err_1    DB 0DH, 0AH,'The number of function is wrong!',0DH,0AH,'$'
	Err_2    DB 0DH, 0AH,'File not found!',0DH,0AH,'$'
	Err_5    DB 0DH, 0AH,'Disk error!',0DH,0AH,'$'
	Err_8    DB 0DH, 0AH,'Insufficient value of memory!',0DH,0AH,'$'
	Err_10   DB 0DH, 0AH,'Incorrect environment string!',0DH,0AH,'$'
	Err_11   DB 0DH, 0AH,'Wrong format!',0DH,0AH,'$'
	End_0    DB 0DH, 0AH,'Normal termination!',0DH,0AH,'$'
	End_1    DB 0DH, 0AH,'End by Ctrl-Break!',0DH,0AH,'$'
	End_2    DB 0DH, 0AH,'The completion of the device error!',0DH,0AH,'$'
	End_3    DB 0DH, 0AH,'Completion by function 31h!',0DH,0AH,'$'
	PATH 	 DB '                                               ',0DH,0AH,'$',0
	KEEP_SS  DW 0
	KEEP_SP  DW 0
	END_CODE DB 'End code:   ',0DH,0AH,'$'
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN
;ПРОЦЕДУРЫ
;---------------------------------------------------------------
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX	PROC near ;половина байт AL переводится в символ шестнадцатиричного числа в AL
	and	al, 0Fh ;and 00001111 - оставляем только вторую половину al
	cmp	al, 09 ;если больше 9, то надо переводить в букву
	jbe	NEXT ;выполняет короткий переход, если первый операнд МЕНЬШЕ или РАВЕН второму операнду
	add	al, 07 ;дополняем код до буквы
	NEXT:
	add	al, 30h ;16-ричный код буквы или цифры в al
	ret
TETR_TO_HEX	ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX	PROC near ;байт AL переводится в два символа шестнадцатиричного числа в AX
	push cx
	mov	ah, al ;копируем al в ah
	call TETR_TO_HEX ;переводим al в символ 16-рич.
	xchg al, ah ;меняем местами al и  ah
	mov	cl, 4 
	shr	al, cl ;cдвиг всех битов al вправо на 4
	call TETR_TO_HEX ;переводим al в символ 16-рич.
	pop	cx 			
	ret
BYTE_TO_HEX	ENDP
;---------------------------------------------------------------
FreeSpaceInMemory PROC
	mov bx, offset LAST_BYTE
	mov ax, es
	sub bx, ax
	mov cl, 4h
	shr bx, cl
	mov ah, 4Ah
	int 21h
	jnc NO_ERROR
	
	cmp ax, 7
	mov dx, offset Mem_7
	je YES_ERROR
	cmp ax, 8
	mov dx, offset Mem_8
	je YES_ERROR
	cmp ax, 9
	mov dx, offset Mem_9
	
	YES_ERROR:
	call PRINT
	xor al, al
	mov ah, 4Ch
	int 21H
	NO_ERROR:
	ret
FreeSpaceInMemory ENDP
;---------------------------------------------------------------
CreateBlockOfParameter PROC
	mov ax, es
	mov ParameterBlock, 0
	mov ParameterBlock + 2, ax
	mov ParameterBlock + 4, 80h
	mov ParameterBlock + 6, ax
	mov ParameterBlock + 8, 5Ch
	mov ParameterBlock + 10, ax
	mov ParameterBlock + 12, 6Ch
	ret
CreateBlockOfParameter ENDP
;---------------------------------------------------------------
Calling PROC 	
	mov es, es:[2Ch]
	mov si, 0
	env:
	mov dl, es:[si]
	cmp dl, 00h
	je EOL_	
	inc si
	jmp env
	EOL_:
	inc si
	mov dl, es:[si]
	cmp dl, 00h
	jne env
	
	add si, 03h
	
	push di
	lea di, PATH
	path_:
	mov dl, es:[si]
	cmp dl, 00h
	je EOL2	
	mov [di], dl	
	inc di			
	inc si			
	jmp path_
	EOL2:
	sub di, 05h	
	mov [di], byte ptr '2'	
	mov [di+2], byte ptr 'C'
	mov [di+3], byte ptr 'O'
	mov [di+4], byte ptr 'M'
	mov [di+5], byte ptr 0h
	
	pop di
;-----------------------------------------
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	
	push ds
	pop es
	mov bx, offset ParameterBlock
	
	mov dx, offset PATH
	
	mov ax, 4B00h
	int 21h
	jnc IS_LOADED
	
	push ax
	mov ax, DATA
	mov ds,ax
	pop ax
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	
	cmp ax, 1
	mov dx, offset Err_1
	je EXIT1
	cmp ax, 2
	mov dx, offset Err_2
	je EXIT1
	cmp ax, 5
	mov dx, offset Err_5
	je EXIT1
	cmp ax, 8
	mov dx, offset Err_8
	je EXIT1
	cmp ax, 10
	mov dx, offset Err_10
	je EXIT1
	cmp ax, 11
	mov dx, offset Err_11
	
	EXIT1:
	call PRINT
	
	xor al, al
	mov ah, 4Ch
	int 21h
		
	IS_LOADED:
	mov ax, 4d00h
	int 21h
	
	cmp ah, 0
	mov dx, offset End_0
	je EXIT2
	cmp ah, 1
	mov dx, offset End_1
	je EXIT2
	cmp ah, 2
	mov dx, offset End_2
	je EXIT2
	cmp ah, 3
	mov dx, offset End_3

	EXIT2:
	call PRINT

	mov di, offset END_CODE
	call BYTE_TO_HEX
	add di, 0Ah
	mov [di], al
	add di, 1h
	xchg ah, al
	mov [di], al
	mov dx, offset END_CODE
	call PRINT
	ret
Calling ENDP
;---------------------------------------------------------------
MAIN:
	mov AX, DATA
	mov DS, AX
	call FreeSpaceInMemory 
	call CreateBlockOfParameter
	call Calling
	xor al, al
	mov ah, 4Ch
	int 21h
	LAST_BYTE:
CODE ENDS
END START