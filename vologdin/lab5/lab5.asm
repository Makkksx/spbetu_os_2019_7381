ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
;---------------------------------------
ROUT PROC FAR
	jmp INT_CODE
	SIGNATURE db 'AAAB'
	KEEP_IP DW 0
	KEEP_CS DW 0 
	KEEP_PSP DW 0 
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
	INT_CODE:
	
	mov CS:KEEP_AX, ax
	mov CS:KEEP_SS, ss
	mov CS:KEEP_SP, sp
	mov ax, ISTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
		in al,60h
		cmp al,11h 
		jne ROUT_STNDRD 
		mov ax,0040h
		mov es,ax
		mov al,es:[18h]
		and al,00000010b
		jz ROUT_STNDRD 
	jmp ROUT_USER

	
	ROUT_STNDRD:
		pop es
		pop ds
		pop dx
		mov ax, CS:KEEP_AX
		mov sp, CS:KEEP_SP
		mov ss, CS:KEEP_SS
		jmp dword ptr CS:KEEP_IP
	
	ROUT_USER:

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

	ROUT_PUSH_TO_BUFF:
		mov ah,05h
		mov cl,'#'
		mov ch,00h
		int 16h
		or al,al
		jz ROUT_END 
		
			CLI
			mov ax,es:[1Ah]
			mov es:[1Ch],ax 
			STI
			jmp ROUT_PUSH_TO_BUFF
		
	ROUT_END:
	pop es
	pop ds
	pop dx
	mov ax, CS:KEEP_AX
	mov al,20h
	out 20h,al
	mov sp, CS:KEEP_SP
	mov ss, CS:KEEP_SS
	iret
ROUT ENDP
	LAST_BYTE:
;---------------------------------------
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
;
CHECK_INT PROC
		mov ah,35h
		mov al,09h
		int 21h 
	
	mov si, offset SIGNATURE
	sub si, offset ROUT 
	
		mov ax,'AA'
		cmp ax,es:[bx+si]
		jne LABEL_INT_IS_NOT_LOADED
		mov ax,'BA'
		cmp ax,es:[bx+si+2]
		jne LABEL_INT_IS_NOT_LOADED
		jmp LABEL_INT_IS_LOADED 
	
	LABEL_INT_IS_NOT_LOADED:
		mov dx,offset STR_INT_IS_LOADED
		call PRINT
		call SET_INT 
		
			mov dx,offset LAST_BYTE
			mov cl,4
			shr dx,cl
			inc dx	
			add dx,CODE 
			sub dx,CS:KEEP_PSP 
		xor al,al
		mov ah,31h
		int 21h 
		
	LABEL_INT_IS_LOADED:
		push es
		push bx
		mov bx,KEEP_PSP
		mov es,bx
		cmp byte ptr es:[82h],'/'
		jne CI_DONT_DELETE
		cmp byte ptr es:[83h],'u'
		jne CI_DONT_DELETE
		cmp byte ptr es:[84h],'n'
		je CI_DELETE 
		CI_DONT_DELETE:
		pop bx
		pop es
	
	mov dx,offset STR_INT_IS_ALR_LOADED
	call PRINT
	ret
	
		CI_DELETE:
		pop bx
		pop es
		
		call DELETE_INT
		mov dx,offset STR_INT_IS_UNLOADED
		call PRINT
		ret
CHECK_INT ENDP
;---------------------------------------

SET_INT PROC
	push ds
	mov ah,35h
	mov al,09h
	int 21h
	mov CS:KEEP_IP,bx
	mov CS:KEEP_CS,es
	
	mov dx,offset ROUT 
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h
	pop ds
	ret
SET_INT ENDP 
;---------------------------------------
DELETE_INT PROC
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
DELETE_INT ENDP 
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	mov CS:KEEP_PSP,es
	
	call CHECK_INT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
	STR_INT_IS_ALR_LOADED DB 'User interruption is already loaded',0DH,0AH,'$'
	STR_INT_IS_UNLOADED DB 'User interruption is successfully unloaded',0DH,0AH,'$'
	STR_INT_IS_LOADED DB 'User interruption is loaded',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	dw 50 dup (?)
STACK ENDS
 END START