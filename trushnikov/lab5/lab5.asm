
CODE	SEGMENT
		keep_09		dd 0 ;переменная для хранения сегмента и смещения старого прерывания 09
		keep_2f		dd 0 ;переменная для хранения сегмента и смещения старого прерывания 2f
		REQ_KEY_1   db 7h ;цифра 6 будет заменять на символ 'A'
		REQ_KEY_2   db 8h ;цифра 7 будет заменять на символ 'B'
		REQ_KEY_3   db 9h ;цифра 8 будет заменять на символ 'C'
		keep_PSP   	dw ? 
        ASSUME CS:CODE, DS:DATA, SS:AStack
		
	
;собственный обработчик прерывания для 2F
My_2F	PROC
		cmp	 AH, 080h ;сравниваем значение в AH с установленным ранее перед прерыванием 
		jne  not_loaded ;если значения не равны - программа не установлена резидентной в памяти
		mov  AL, 0FFh ;устанавливаем в AL значение FF, что на выходе из прерывания означает, что программа установлена 
	not_loaded:
		iret ;иначе просто возвращаемся в программу
My_2F	ENDP

;собственный обработчик прерывания для 1C
My_09	PROC
		push AX
		
		in AL, 60h ;читаем ключ
		cmp AL, REQ_KEY_1 ;проверяем, нужный ли нам ключ
		je key1 ;если да (цифра 6), то будем заменять её на 'A'
		
		cmp AL, REQ_KEY_2 ;проверяем, нужный ли нам ключ
		je 	key2 ;если да (цифра 7), то будем заменять её на 'B'

		cmp AL, REQ_KEY_3 ;проверяем, нужный ли нам ключ
		je 	key3 ;если да (цифра 8), то будем заменять её на 'C'
		
		pop AX
		jmp	 dword ptr cs:[keep_09] ;переходим на первоначальный обработчик
		
	key1:
		mov CL, 'A'
		jmp do_req
	key2:
		mov CL, 'B'
		jmp do_req
	key3:
		mov CL, 'C'
	do_req:
		in 	AL, 61h ;взять значение порта управления клаваиатурой
		mov AH, AL  ;сохранить его
		or 	AL, 80h ;установить бит разрешения для клавиатуры
		out 61h, AL ;и вывести его в управляющий порт
		xchg AH, AL ;извлечь исходное значение порта
		out 61h, AL ;и записать его обратно 
		mov AL, 20h ;послать сигнал "конец прерывания"
		out 20h, AL ;контроллеру прерываний 8259
		
		mov AH, 05h ;функция, позволяющуая записать символ в буфер клавиатуры
		mov CH, 00h ;символ в CL уже занесён ранее, осталось обнулить CH
		int 16h		;выполняем функцию
		or 	AL, AL	;проверка переполнения буфера
		jnz skip 	;если переполнен - идём в skip
		jmp return	;иначе подаём сигнал "конец прерывания" и выходим
	skip: 			;очищаем буфер
		push ES
		push SI
		mov AX, 0040h
		mov ES, AX
		mov SI, 001ah
		mov AX, ES:[SI] 
		mov SI, 001ch
		mov ES:[SI], AX	
		pop SI
		pop ES
	return:
		pop AX
		mov AL, 20h
		out 20h, AL
		iret 	
LAST_BYTE:
My_09 	ENDP

; функция проверки не ввёл ли пользователь команду /un
Un_check  PROC	FAR
		push AX
		
		mov	AX, Keep_PSP
		mov	ES, AX
		sub	AX, AX
		cmp	byte ptr es:[82h],'/'
		jne	not_un
		cmp	byte ptr es:[83h],'u'
		jne	not_un
		cmp	byte ptr es:[84h],'n'
		jne	not_un
		mov	flag,0
		
	not_un:
		pop	AX
		ret
Un_check  ENDP

;функция, сохраняющая стандартные обработчики прерываний
Keep_interr	 PROC
		push AX
		push BX
		push ES

		mov AH, 35h ;функция, выдающая значение сегмента в ES, смещение в BX
		mov AL, 09h ;для прерывания 09
		int 21h
		mov word ptr keep_09, BX
		mov word ptr keep_09+2, ES
		
		mov AH, 35h ;функция, выдающая значение сегмента в ES, смещение в BX
		mov AL, 2Fh ;для прерывания 2F
		int 21h	
		mov word ptr keep_2f, BX
		mov word ptr keep_2f+2, ES

		pop ES
		pop BX
		pop AX
		ret
Keep_interr	 ENDP

; функция, загружающая собственные обработчики прерывания
Load_interr	 PROC
		push DS
		push DX
		push AX

		call Keep_interr ;сохраняем старые обработчики прерываний

		push DS
		mov DX, offset My_09
		mov AX, seg My_09	    
		mov DS, AX
		mov AH, 25h		 ;функция, меняющая обработчик прерываний на указанный в DX и AX
		mov AL, 09h      ;для прерывания 1C         	
    	int 21h

    	mov DX, offset My_2F
		mov AX, seg My_2F	    
		mov DS, AX
		mov AH, 25h		 ;функция, меняющая обработчик прерываний на указанный в DX и AX   
		mov AL, 2Fh      ;для прерывания 2F       	
    	int 21h	
		pop DS
	
		pop AX
		pop DX
		pop DS
		ret
Load_interr  ENDP

; Выгружаем обработчики прерываний
Unload_interr  PROC
		push DS

		mov AH, 35h
		mov AL, 09h
		int 21h
		mov DX, word ptr es:keep_09
		mov AX, word ptr es:keep_09+2
		mov word ptr keep_09, DX
		mov word ptr keep_09+2, AX

		mov AH, 35h
		mov AL, 2Fh
		int 21h
		mov DX, word ptr es:keep_2f
		mov AX, word ptr es:keep_2f+2
		mov word ptr keep_2f, DX
		mov word ptr keep_2f+2, AX

		CLI
		mov DX, word ptr keep_09
		mov AX,	word ptr keep_09+2
		mov DS, AX
		mov AH, 25h	;выгружаем обработчик для 09
		mov AL, 09h
		int 21h
		
		mov DX, word ptr keep_2f
		mov AX,	word ptr keep_2f+2
		mov DS, AX
		mov AH, 25h	;выгружаем обработчик для 2F
		mov AL, 2Fh
		int 21h
		STI
		
		pop DS

		mov ES, ES:Keep_PSP
		mov AX, 4900h		;освобождаем память по адресу ES:Keep_PSP
		int 21h
		
		mov flag, 1			;запоминаем, что память была освобождена
		mov DX, offset Message2
		call Write_message  ;выводим соответствующее сообщение

		mov ES, ES:[2ch]	
		mov AX, 4900h		;освобождаем память по адресу ES:[2ch]
		int 21h

		mov AX, 4C00h		;выход из программы через функцию 4C
		int 21h
Unload_interr  ENDP

Make_resident  PROC
		mov AX, ES
		mov Keep_PSP, AX
		mov DX, offset LAST_BYTE
		add DX, 200h	
		
		mov AH, 31h ;31h завершает программу, оставляя её резидентной в памяти
		mov AL, 0 
		int 21h
Make_resident  ENDP

; функция вывода сообщения на экран
Write_message	PROC
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
Write_message		ENDP

; Главная функция
Main 	PROC  
		push DS
		xor AX, AX
		push AX
   		mov AX, DATA             
  		mov DS, AX
		mov Keep_PSP, ES 

		mov	AX, 8000h ;нам нужны номера в AH от 80h до 0FFh
		int 2Fh
		cmp	AL,0FFh	  ; 2fh возвращает 0FFh, если программа установлена резидентной в памяти
		jne loading

		call Un_check
		cmp flag, 0
		jne alr_loaded

		call Unload_interr	;пользователь ввёл /un и программа ещё не была выгружена
	loading:				;программа не является резидентной в памяти
		call Load_interr
		
		lea DX, Message1
		call Write_message
		
		call Make_resident
	alr_loaded:				;программа уже была резидентной
		lea dx, Message3
		call Write_message
		mov ax, 4C00h
		int 21h
Main 	ENDP
CODE    		ENDS

AStack		SEGMENT  STACK
        DW 256 DUP(?)			
AStack  	ENDS

DATA		SEGMENT
    flag			dw 1
    Message1        db 'Resident program has been loaded', 0dh, 0ah, '$'
    Message2	    db 'Resident program unloaded', 0dh, 0ah, '$'
    Message3		db 'Resident program is already loaded', 0dh, 0ah, '$'
DATA 		ENDS
        	END Main