INT_STACK SEGMENT STACK
	DW 32 DUP (?)
INT_STACK ENDS

STACK SEGMENT STACK
	DW 256 DUP (?)
STACK ENDS

DATA SEGMENT
	str_loaded DB 'Interruption is loaded!',0DH,0AH,'$'
	str_already_loaded DB 'Interruption was loaded!',0DH,0AH,'$'
	str_unloaded DB 'Interruption is unloaded!',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN

PRINT proc near
	mov AH,09h
	int 21h
	ret
PRINT endp

; Обработчик прерывания
ROUT proc far 
	jmp ROUT_CODE

	FLAG DB 'ZZZZ' ; идентификатор (сигнатура)
	KEEP_CS DW 0 ; сегмент
	KEEP_IP DW 0 ; смещение
	KEEP_PSP DW 0 ; PSP
	IS_LOADED DB 0 ; флаг загрузки
	count DB 'Number of handler calls (00000)$' ;счётчик
	KEEP_SS DW 0
	KEEP_AX DW 0	
	KEEP_SP DW 0

ROUT_CODE:

	; сохраним чтобы восстановить позже
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	mov ax, seg INT_STACK 
	mov ss, ax
	mov sp, 32h
	mov ax, KEEP_ax
	
	push ax
	push dx
	push ds
	push es

	; переход к выводу обработчика
	cmp IS_LOADED, 1
	je ROUT_restore_default
	call GET_CURS
	push DX 
	mov DH, 0 ; строка
	mov DL, 0 ; столбик
	call SET_CURS

ROUT_count:	
	push ax
	push bx
	push si 
	push ds
	mov ax, SEG count
	mov ds, ax
	mov bx, offset count
	add bx, 26; к последней цифре
	mov si,3

next_number:
		mov ah, [bx+si]
		inc ah
		cmp ah, '9' 
	jne ROUT_add_1
		mov ah, '0' 
		mov [bx+si], ah
		dec si
		cmp si, 0
	jne next_number

ROUT_add_1:
	mov [bx+si],ah
    	pop ds
    	pop si
	pop bx
	pop ax

	push es 
	push bp
	mov ax, SEG count
	mov es, ax
	mov ax, offset count
	mov bp, ax
	mov ah, 13h 
	mov al, 0 
	mov cx, 31 ; длина строки
	mov bh, 0
	int 10h
	
	pop bp
	pop es
	
	;положение курсора
	pop dx
	call SET_CURS
	jmp ROUT_end

	; Восстановление дефолтного вектора и освобождение памяти
ROUT_restore_default:
	CLI ; команда игнорирования прерываний от внешних устройств
	mov dx,KEEP_IP
	mov ax,KEEP_CS
	mov ds,ax
	mov ah,25h 
	mov al,1Ch 
	int 21h

	mov es, KEEP_PSP
	mov es, es:[2Ch]
	mov ah, 49h
	int 21h 
	mov es, KEEP_PSP
	mov ah, 49h 
	int 21h	
	STI ; останов игнорирования прерываний

ROUT_end:
	pop es
	pop ds
	pop dx
	pop ax
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov ax, KEEP_AX	
	iret
ROUT endp

; Установка позиции курсора
SET_CURS PROC 
	push AX
	push BX
	push CX
	mov AH, 2
	mov BH, 0
	int 10h
	pop CX
	pop BX
	pop AX
	ret
SET_CURS ENDP

GET_CURS PROC
	push AX
	push BX
	push CX
	mov AH, 3
	mov BH, 0
	int 10h
	pop CX
	pop BX
	pop AX
	ret
GET_CURS ENDP

; Проверка состояния загрузки нового прерывания в память
INTERAPTION_STATE proc near

	;в es::bx получим адрес обработчика прерываний
	mov ah, 35h 
	mov al, 1Ch 
	int 21h; 
	
	; получаем в SI идентификатор нашего обработчика
	mov si, offset FLAG
	sub si, offset ROUT
	
	; проверяем какой обработчик получили
	mov ax, 'ZZ'
	cmp ax, es:[bx + si]
	jne load_interaption
	cmp ax, es:[bx + si + 2] 
	je already_loaded
	
	; Загружаем новый Обработчик
load_interaption:
	call SET_INTERAPTION
	mov dx, offset LAST_BYTE 
	mov cl, 4 
	shr dx, cl
	inc dx
	add dx, CODE ;прибавляем адрес code ceгмента
	sub dx, KEEP_PSP ;вычитаем адрес начала сегмента
	mov ah, 31h
	int 21h 

; проверяем на аргумент командной строки
already_loaded: 
	push es
	push ax
	mov ax, KEEP_PSP 
	mov es, ax
	cmp byte ptr es:[82h],'/' 
	jne no_args
	cmp byte ptr es:[83h],'u' 
	jne no_args
	cmp byte ptr es:[84h],'n'
	je unload_interaption

no_args:
	pop ax
	pop es
	mov dx, offset str_already_loaded
	call PRINT
	ret

; выгружаем реализованный обработчик
unload_interaption:
	pop ax
	pop es
	mov byte ptr es:[BX+SI+10], 1 ; флаг выгрузки обработчика

	mov dx, offset str_unloaded
	call PRINT
	ret
INTERAPTION_STATE endp

;установка реализованного прерывания 
SET_INTERAPTION proc near 
	push dx
	push ds

	; получаем адрес обработчика
	mov ah, 35h
	mov al, 1Ch
	int 21h; 

 	; сохраняем значения для востановления
	mov KEEP_IP, bx 
	mov KEEP_CS, es

	; установили своё прерывание
	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h

	pop ds
	mov dx, offset str_loaded
	call PRINT
	pop dx
	ret
SET_INTERAPTION ENDP 

MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP, ES
	call INTERAPTION_STATE
	mov AH, 4Ch  
	int 21H
LAST_BYTE:
	CODE ENDS	
END START
