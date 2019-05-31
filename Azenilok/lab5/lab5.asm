INT_STACK SEGMENT STACK
	DW 32 DUP (?)
INT_STACK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN

DATA SEGMENT
	str_loaded DB 'New interruption',0DH,0AH,'$'
	str_already_loaded DB 'interruption has been loaded yet!',0DH,0AH,'$'
	str_unloaded DB 'Unloaded!',0DH,0AH,'$'
	endl db 0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	DW 256 DUP (?)
STACK ENDS

; Обработчик прерывания
ROUT proc far
	jmp ROUT_begin
ROUT_DATA:
	SIGNATURE DB 'UGAY' 
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
	mov ax, seg INT_STACK 
	mov ss, ax
	mov sp, 32h
	mov ax, KEEP_ax

	push ax
	push dx
	push ds
	push es
	in al, 60H ;читаем ключ для скан-кода
	cmp al, 0Eh 
	je DO_REQ 
	
	pushf
	call dword ptr CS:KEEP_IP 
	jmp ROUT_END
	
; собственный обработчик
DO_REQ:
	push ax
	in al, 61h 
	mov ah, al  
	or al, 80h 
	out 61h, al 
	xchg ah, al 
	out 61h, al 
	mov al, 20h 
	out 20h, al 
	pop ax
	
ADD_TO_BUFF: 
	mov ah, 05h 
	mov cl, 'X' 
	mov ch, 00h	
	int 16h
	or al, al 
	jz ROUT_END 

	CLI 
	mov ax,es:[1Ah] 
	mov es:[1Ch],ax 
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
	mov al,20h
	out 20h,al
	iret
LAST_BYTE:
ROUT ENDP
	
PRINT_DX proc near
	mov ah,09h
	int 21h
	ret
PRINT_DX endp

CHECK_HANDLER proc near
	mov ah,35h 
	mov al,09h 
	int 21h 
	mov si, offset SIGNATURE 
	sub si, offset ROUT 
	mov ax,'GU'
	cmp ax,es:[bx+si]
	jne not_loaded
	mov ax, 'YA'
	cmp ax,es:[bx+si+2] 
	je loaded
not_loaded:
	call SET_HANDLER
	mov dx,offset LAST_BYTE 
	mov cl,4 
	shr dx,cl
	inc dx
	add dx,CODE 
	sub dx,CS:KEEP_PSP 
	xor al,al
	mov ah,31h
	int 21h 

loaded: 
	push es
	push ax
	mov ax,KEEP_PSP 
	mov es,ax
	cmp byte ptr es:[82h],'/' 
	je next_symbol
	cmp byte ptr es:[82h],'|' 
	jne args_false
next_symbol:
	cmp byte ptr es:[83h],'u' 
	jne args_false
	cmp byte ptr es:[84h],'n'
	je do_unload

args_false:
	pop ax
	pop es
	mov dx,offset str_already_loaded
	call PRINT_DX
	ret

do_unload:
	pop ax
	pop es
	call DELETE_HANDLER
	mov dx,offset str_unloaded
	call PRINT_DX
	ret
CHECK_HANDLER endp

SET_HANDLER proc near
	push dx
	push ds

	mov ah,35h
	mov al,09h
	int 21h; es:bx
	mov CS:KEEP_IP,bx 
	mov CS:KEEP_CS,es

	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h

	pop ds
	mov dx,offset str_loaded
	call PRINT_DX
	pop dx
	ret
SET_HANDLER ENDP

DELETE_HANDLER proc
	push ds
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		
		mov ax,2509h
		int 21h 
		push es
		mov ax,ES:[BX+SI+8]
		mov es,ax 
		mov es,es:[2Ch] 
		mov ah,49h         
		int 21h
		pop es
		mov es,ES:[BX+SI+8] 
		mov ah, 49h
		int 21h	
		STI
	pop ds
	ret
DELETE_HANDLER ENDP 


MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP,ES
	
	call CHECK_HANDLER

	xor AL,AL
	mov AH,4Ch
	int 21H
	CODE ENDS	

END START