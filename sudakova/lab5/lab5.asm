EOL 	EQU 	'$'
CODE	SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack
;-------------------------------------------------------------------------
WRITE_LINE	PROC	NEAR
		push	AX
		mov		AH,09H
		int		21H
		pop		AX
		ret
WRITE_LINE	ENDP
;-------------------------------------------------------------------------
; Процедура обработчика прерывания
ROUT 		PROC 	FAR

jmp ROUT_CODE

;данные
SIGNATURE 		DB 'AAAA'
KEEP_IP 		DW 0
KEEP_CS 		DW 0
KEEP_PSP		DW 0
	
ROUT_CODE:
		push 	AX
		push 	DX
		push 	DS
		push 	ES
		
		;Проверяем scan-код
		in 		AL,60H
		cmp 	AL, 02H ; клавиша - 1
		jz 		USER_ROUT_1 
		cmp 	AL, 03H ; клавиша - 2
		jz 		USER_ROUT_2
		cmp 	AL, 04H ; клавиша - 3
		jz 		USER_ROUT_3
		
		;Если пришел другой скан-код, идём в стандартный обработчик
		jmp 	ROUT_STNDRD 

	USER_ROUT_1:
		mov 	CL,'A'
		call 	USER_ROUT
		jmp		R_END
	USER_ROUT_2:
		mov 	CL,'B'
		call 	USER_ROUT
		jmp		R_END
	USER_ROUT_3:
		mov 	CL,'C'
		call 	USER_ROUT
		jmp		R_END
	
	ROUT_STNDRD:
		pushf
		call DWORD PTR CS:KEEP_IP
				
R_END:
		pop 	ES
		pop 	DS
		pop 	DX
		pop 	AX 
		iret
ROUT 	ENDP
;-------------------------------------------------------------------------
;Пользовательский обработчик
USER_ROUT	PROC
	mov 	AX, 0040h
	mov 	ES, AX
		
	in 		AL, 61H   
	mov 	AH, AL     
	or 		AL, 80H    
	out 	61H, AL    
	xchg 	AH, AL    
	out 	61H, AL    
	mov 	AL, 20H     
	out 	20H, AL     

	ROUT_PUSH_TO_BUFF:
	mov 	AH,05H
	mov 	CH,00H
	int 	16H
	or 		AL, AL
	jz _END 
	
	CLI
		mov AX,ES:[1AH]
		mov ES:[1CH],AX 
	STI
	jmp ROUT_PUSH_TO_BUFF
_END: 	ret
USER_ROUT	ENDP
;-------------------------------------------------------------------------
; Установка прерывания 
SET_INT 	PROC
		push 	DS
		mov 	AH, 35H
		mov 	AL, 09H
		int 	21H
		
		mov 	KEEP_IP, BX
		mov 	KEEP_CS, ES
		
		;установка
		mov 	DX, OFFSET ROUT 
		mov 	AX, SEG ROUT
		mov 	DS, AX
		mov 	AH, 25H
		mov 	AL, 09H
		int 	21H
		pop 	DS
		ret
SET_INT 	ENDP 
;-------------------------------------------------------------------------
;восстановление стандартного вектора прерывания
RECOVER_ROUT PROC
		push 	DS
		CLI	
			mov 	DX, ES:[BX+SI+4] ;ip
			mov 	AX, ES:[BX+SI+6] ;cs
			mov 	DS, AX
			mov 	AX, 2509H
			int 	21H 			 ;восстанавливаем вектор
			push 	ES
			;Освобождаем память:
			;блока переменных среды
			mov 	ES, ES:[BX+SI+8] ;psp
			mov 	ES, ES:[2CH]
			mov 	AH, 49H         
			int 	21H
			pop 	ES
			;блока резидентной программы
			mov 	ES, ES:[BX+SI+8]
			mov 	AH, 49H
			int 	21H	
		STI
		pop 	DS
		ret
RECOVER_ROUT ENDP 
;-------------------------------------------------------------------------
CHECK_SIGNATURE 	PROC
		; Проверка 09h
		mov 	AH, 35H
		mov 	AL, 09H
		int 	21H 
	
		mov 	SI, OFFSET SIGNATURE
		sub 	SI, OFFSET ROUT 
	
		mov 	AX, 'AA'
		cmp 	AX, ES:[BX+SI]
		jne 	MARK_IS_NOT_LOADED
		cmp 	AX, ES:[BX+SI+2]
		jne 	MARK_IS_NOT_LOADED
		jmp 	MARK_IS_LOADED 
	
MARK_IS_NOT_LOADED:
		;Установка пользовательской функции прерывания
		mov 	DX, OFFSET IS_LOADED
		call 	WRITE_LINE
		call 	SET_INT
		;Вычисление необходимого количества памяти для резидентной программы:
		mov 	DX, OFFSET END_BYTE 
		mov 	CL, 4
		shr 	DX, CL
		inc 	DX	 				
		add 	DX, CODE 			
		sub 	DX, KEEP_PSP 		
		
		xor 	AL, AL
		mov 	AH, 31H
		int 	21H 
		
MARK_IS_LOADED:
		;Check for /un
		push 	ES
		push 	BX
		mov 	BX, KEEP_PSP
		mov 	ES, BX
		cmp 	BYTE PTR ES:[82H],'/'
		jne 	NO_DELETE
		cmp 	BYTE PTR ES:[83H],'u'
		jne 	NO_DELETE
		cmp 	BYTE PTR ES:[84H],'n'
		je 		DELETE
		
NO_DELETE:
		pop 	BX
		pop 	ES
	
		mov 	DX, OFFSET IS_ALR_LOADED
		call 	WRITE_LINE
		ret

;Если un - убираем пользовательское прерывание
DELETE:
		pop 	BX
		pop 	ES
		call	RECOVER_ROUT
		mov 	DX, OFFSET IS_UNLOADED
		call 	WRITE_LINE
		ret
CHECK_SIGNATURE 	ENDP
;-------------------------------------------------------------------------
DATA	SEGMENT
	IS_LOADED 		DB 'User interruption is loaded',0DH,0AH,'$'
	IS_ALR_LOADED 	DB 'User interruption is already loaded',0DH,0AH,'$'
	IS_UNLOADED 	DB 'User interruption is unloaded',0DH,0AH,'$'
DATA 	ENDS

AStack	SEGMENT  STACK
        DW 512 DUP(?)			
AStack  ENDS
;-------------------------------------------------------------------------
Main	PROC  	FAR
		mov 	AX, data
		mov 	DS, AX
		mov 	KEEP_PSP, ES
	
		call 	CHECK_SIGNATURE
	
		xor 	AL,AL
		mov 	AH,4CH
		int 	21H
	
END_BYTE:
		ret
Main    		ENDP
CODE			ENDS
				END Main