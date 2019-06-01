.MODEL SMALL
.DATA
;ДАННЫЕ
STRING0      db  '		Lab 5', 0DH, 0AH, '$'
STRING1      db  '		Process ended successful, code: ', 0DH, 0AH, '$'
STRING2      db  '		Error! No file', 0DH, 0AH, '$'
STRING3      db  '		Process ended with ctrl + c', 0DH, 0AH, '$'
FILENAME db 50 dup(0)
EOL db "$"
PARAM dw 7 dup(?)
VAR_SS dw ?
VAR_SP dw ?
MEMMORY db 0

.STACK 200h

.CODE
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX   PROC  near
	and      AL,0Fh
	cmp      AL,09
	jbe      NEXT
	add      AL,07
	NEXT:      add      AL,30h
	ret
TETR_TO_HEX   ENDP
;-----------------------------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
	push     CX
	mov      AH,AL
	call     TETR_TO_HEX
	xchg     AL,AH
	mov      CL,4
	shr      AL,CL
	call     TETR_TO_HEX ;в AL старшая цифра
	pop      CX          ;в AH младшая
	ret
BYTE_TO_HEX  ENDP
;-----------------------------------------------------
;Освобождение памяти
FREE PROC
	lea bx, TEMP
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov ah, 4Ah 
	int 21h
	jc err
	jmp noterr
	err:
		mov MEMMORY, 1
	noterr:
		ret
FREE ENDP
;-----------------------------------------------------
;Вывод на экран
PRINT_ON_SCREEN PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_ON_SCREEN ENDP
;-----------------------------------------------------
;Выход из программы
EXIT_PROGRAMM PROC
	mov ah, 4Dh
	int 21h
	cmp ah, 1
	je errchild
	lea bx, STRING1
	mov [bx], ax
	lea dx, STRING1
	push ax
	call PRINT_ON_SCREEN
	pop ax
	call BYTE_TO_HEX
	push ax
	mov dl, ' '
	mov ah, 2h
	int 21h
	pop ax
	push ax
	mov dl, al
	mov ah, 2h
	int 21h
	pop ax
	mov dl, ah
	mov ah, 2h
	int 21h
	jmp exget
	errchild:
		lea dx, STRING3
		call PRINT_ON_SCREEN
	exget:
		ret
EXIT_PROGRAMM ENDP
;-----------------------------------------------------
; КОД
BEGIN PROC FAR
	mov ax, @data
	mov ds, ax	   
;Вывод приветственной строки
  ;  lea     dx, STRING0
   ; call PRINT_ON_SCREEN
	
	push si
	push di
	push es
	push dx
	mov es, es:[2Ch]
	xor si, si
	lea di, FILENAME
	env_char: 
		cmp byte ptr es:[si], 00h
		je env_crlf
		inc SI
		jmp env_next
	env_crlf:   
		inc si
	env_next:       
		cmp word ptr es:[si], 0000h
		jne env_char
		add si, 4           
	abs_char:
		cmp byte ptr es:[si], 00h
		je vot
		mov dl, es:[si]
		mov [di], dl
		inc si
		inc di
		jmp abs_char        
	vot:
		sub di, 5
		mov dl, '2'
		mov [di], dl
		add di, 2
		mov dl, 'c'
		mov [di], dl
		inc di
		mov dl, 'o'
		mov [di], dl
		inc di
		mov dl, 'm'
		mov [di], dl
		inc di
		mov dl, 0h
		mov [di], dl
		inc di
		mov dl, EOL
		mov [di], dl
		pop dx
		pop es
		pop di
		pop si
		call FREE
		cmp MEMMORY, 0
		jne Exit
		push ds
		pop es
		lea dx, FILENAME 
		lea bx, PARAM 
		mov VAR_SS, ss
		mov VAR_SP, sp
		mov ax, 4b00h
		int 21h
		mov ss, VAR_SS
		mov sp, VAR_SP
		jc erld
		jmp noterld
	erld:
		lea dx, STRING2
		call PRINT_ON_SCREEN
		lea dx, FILENAME
		call PRINT_ON_SCREEN
		jmp Exit
	noterld:
		call EXIT_PROGRAMM
	Exit:
	; Выход в DOS
		mov ah, 4Ch
		int 21h
	   
BEGIN      ENDP
;-----------------------------------------------------
TEMP PROC
TEMP ENDP
;-----------------------------------------------------
END BEGIN
