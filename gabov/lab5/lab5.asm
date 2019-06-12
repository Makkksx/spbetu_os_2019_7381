INT_STACK SEGMENT STACK
	DW 32 DUP (?)
INT_STACK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN

DATA SEGMENT
	str_loaded DB 'Interruption is  loaded!',0DH,0AH,'$'
	str_already_loaded DB 'Interruption was already loaded!',0DH,0AH,'$'
	str_unloaded DB 'Interruption is unloaded!',0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	DW 256 DUP (?)
STACK ENDS

; Обработчик прерывания
ROUT proc far
	jmp ROUT_begin
ROUT_DATA:
	FLAG DB 'ZZZZ' ; дает понять, что это нужный обработчик
	KEEP_IP DW 0 
	KEEP_CS DW 0 
	KEEP_PSP DW 0 
	KEEP_SS DW 0
	KEEP_AX DW 0	
	KEEP_SP DW 0 
ROUT_begin:
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	mov ax, seg INT_STACK ;устанавливаем собственный стек
	mov ss, ax
	mov sp, 32h
	mov ax, KEEP_ax

	push ax
	push dx
	push ds
	push es
	
	;проверяем скан-код far
	in al, 60H ;читать ключ
	cmp al, 02h; 1
	je DO_REQ ;получили требуемый скан-код
	
	;стандартный обработчик прерывания
	pushf
	call dword ptr CS:KEEP_IP ;переход на первоначальный обработчик
	jmp ROUT_END
	
; собственный обработчик
DO_REQ:
	push ax
	in al, 61h  ;взять значение порта управления клавиатурой
	mov ah, al  ;сохранить его
	or al, 80h  ;установить бит разрешения для клавиатуры
	out 61h, al ;и вывести его в управляющий порт
	xchg ah, al ;извлечь исходное значение порта
	out 61h, al ;и записать его обратно
	mov al, 20h ;послать сигнал "конец прерывания"
	out 20h, al ;контроллеру прерываний 8259
	pop ax
	
ADD_TO_BUFF: ;запись символа в буфер клавиатуры
	mov ah, 05h ;код функции
	mov cl, 'X' ;пишем символ в буфер клавиатуры
	mov ch, 00h	
	int 16h
	or al, al 
	jz ROUT_END ; если переполненение
	;oчистка буфера
	CLI 
	mov ax,es:[1Ah] ; адрес начала буфера
	mov es:[1Ch],ax ; помещаем его в адрес конца
	STI
	jmp ADD_TO_BUFF

ROUT_END:
	pop es
	pop ds
	pop dx
	pop ax 
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov ax, KEEP_AX
	mov al, 20h
	out 20h, al
	iret
LAST_BYTE:
ROUT ENDP
	
PRINT_DX proc near
	mov ah,09h
	int 21h
	ret
PRINT_DX endp


CHECK_HANDLER proc near

	; получаем адрес обработчика по номеру
	mov ah, 35h 
	mov al, 09h 
	int 21h ;
 
	mov si, offset FLAG
	sub si, offset ROUT ; в si смещение сигнатуры от начала функции
	
	mov ax, 'ZZ'
	cmp ax, es:[bx+si]
	jne not_loaded
	mov ax, 'ZZ'
	cmp ax, es:[bx+si+2] 
	je loaded

	; Загружаем новый Обработчик
not_loaded:
	call SET_HANDLER
	mov dx, offset LAST_BYTE ; в байтах
	mov cl, 4 ;в параграфы в dx
	shr dx, cl
	inc dx
	add dx, CODE ;прибавляем адрес code 
	sub dx, CS:KEEP_PSP 
	xor al, al
	mov ah, 31h
	int 21h 

;проверка агрумента командной строки
loaded: 
	push es
	push ax
	mov ax, KEEP_PSP 
	mov es, ax
	cmp byte ptr es:[82h],'/' 
	jne args_false
	cmp byte ptr es:[83h],'u' 
	jne args_false
	cmp byte ptr es:[84h],'n'
	je do_unload

args_false:
	pop ax
	pop es
	mov dx, offset str_already_loaded
	call PRINT_DX
	ret

; Выгружаем свой Обработчик
do_unload:
	pop ax
	pop es
	call DELETE_HANDLER
	mov dx,offset str_unloaded
	call PRINT_DX
	ret
CHECK_HANDLER endp

;установка написанного прерывания в поле векторов прерываний
SET_HANDLER proc near
	push dx
	push ds

	mov ah, 35h
	mov al, 09h
	int 21h; es:bx
	mov CS:KEEP_IP,bx 
	mov CS:KEEP_CS,es

	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h

	pop ds
	mov dx, offset str_loaded
	call PRINT_DX
	pop dx
	ret
SET_HANDLER ENDP

DELETE_HANDLER proc
	push ds
	; Восстанавливаем стандартный вектор прерывания:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		
		mov ax, 2509h
		int 21h 
	; Освобождаем память:
		push es
		mov ax, ES:[BX+SI+8] ; PSP
		mov es, ax 
		mov es, es:[2Ch] ; Блока переменных среды
		mov ah, 49h         
		int 21h
		pop es
		mov es, ES:[BX+SI+8] ; PSP ; Блока резидентной программы
		mov ah, 49h
		int 21h	
		STI
	pop ds
	ret
DELETE_HANDLER ENDP 


MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP, ES
	
	call CHECK_HANDLER

	xor AL, AL
	mov AH, 4Ch
	int 21H
	CODE ENDS	

END START
