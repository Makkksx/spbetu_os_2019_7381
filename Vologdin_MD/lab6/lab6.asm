CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:SSTACK
START: JMP BEGIN

PRINT PROC near
		mov AH,09h
		int 21h
		ret
PRINT ENDP

TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC near
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP

PREP PROC
	mov ax,SSTACK
	sub ax,CODE
	add ax,100h
	mov bx,ax
	mov ah,4ah
	int 21h
	jnc PREP_SKIP
	call RUN_MODULE
	PREP_SKIP:
	call PARMS_CREATE
	push es
	push bx
	push si
	push ax
	mov es,es:[2ch] 
	mov bx,-1
	ENV:
		add bx,1
		cmp word ptr es:[bx],0000h
		jne ENV
	add bx,4
	mov si,-1
	STEP1:
		add si,1
		mov al,es:[bx+si]
		mov MODULE_PATH[si],al
		cmp byte ptr es:[bx+si],00h
		jne STEP1
	
	add si,1
	STEP2:
		mov MODULE_PATH[si],0
		sub si,1
		cmp byte ptr es:[bx+si],'\'
		jne STEP2
	add si,1
	mov MODULE_PATH[si],'L'
	add si,1
	mov MODULE_PATH[si],'A'
	add si,1
	mov MODULE_PATH[si],'B'
	add si,1
	mov MODULE_PATH[si],'2'
	add si,1
	mov MODULE_PATH[si],'.'
	add si,1
	mov MODULE_PATH[si],'C'
	add si,1
	mov MODULE_PATH[si],'O'
	add si,1
	mov MODULE_PATH[si],'M'
	pop ax
	pop si
	pop bx
	pop es	
	
	ret
PREP ENDP

FREE_MEM PROC
		mov ax,SSTACK
		mov bx,es
		sub ax,bx 
		add ax,10h 
		mov bx,ax
		mov ah,4Ah
		int 21h
		jnc FREE_MEM_FINISH
	
		mov dx,offset STR_ERR_FREE_MEM
		call PRINT
		cmp ax,7
		mov dx,offset STR_ERR_MCB_DESTROYED
		je FREE_MEM_PRINT
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM
		je FREE_MEM_PRINT
		cmp ax,9
		mov dx,offset STR_ERR_WRNG_MEM_BL_ADDR
		
FREE_MEM_PRINT:
		call PRINT
		mov dx,offset ENDL
		call PRINT
	
		xor AL,AL
		mov AH,4Ch
		int 21H
FREE_MEM_FINISH:
		ret
FREE_MEM ENDP

PARMS_CREATE PROC
		mov ax, es:[2Ch]
		mov PARMS,ax 
		mov PARMS+2,es 
		mov PARMS+4,80h
		ret
PARMS_CREATE ENDP

RUN_MODULE PROC
		mov dx,offset ENDL
		call PRINT
		mov dx,offset MODULE_PATH
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je RUN_MODULE_NO_TAIL
		mov si,cx
		push si 
RUN_MODULE_LOOP:
		mov al,es:[81h+si]
		mov [offset MODULE_PATH+si-1],al			
		dec si
		loop RUN_MODULE_LOOP
		pop si
		mov [MODULE_PATH+si-1],0 
		mov dx,offset MODULE_PATH 
RUN_MODULE_NO_TAIL:
		push ds
		pop es
		mov bx,offset PARMS
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		mov ax,4b00h
		int 21h
		jnc RUN_MODULE_FINISH
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
		cmp ax,1
		mov dx,offset STR_ERR_WRNG_FNCT_NUMB
		je RUN_MODULE_PRINT
		cmp ax,2
		mov dx,offset STR_ERR_FL_NOT_FND
		je RUN_MODULE_PRINT
		cmp ax,5
		mov dx,offset STR_ERR_DISK_ERR
		je RUN_MODULE_PRINT
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM2
		je RUN_MODULE_PRINT
		cmp ax,10
		mov dx,offset STR_ERR_WRONG_ENV_STR
		je RUN_MODULE_PRINT
		cmp ax,11
		mov dx,offset STR_ERR_WRONG_FORMAT
RUN_MODULE_PRINT:
		call PRINT
		mov dx,offset ENDL
		call PRINT
		xor AL,AL
		mov AH,4Ch
		int 21H
RUN_MODULE_FINISH:
		mov dx,offset ENDL
		call PRINT
		mov ax,4d00h
		int 21h
		cmp ah,0
		mov dx,offset STR_NRML_END
		je RUN_MODULE_PRINT_END
		cmp ah,1
		mov dx,offset STR_CTRL_BREAK
		je RUN_MODULE_PRINT_END
		cmp ah,2
		mov dx,offset STR_DEVICE_ERROR
		je RUN_MODULE_PRINT_END
		cmp ah,3
		mov dx,offset STR_RSDNT_END
RUN_MODULE_PRINT_END:
		call PRINT
		mov dx,offset ENDL
		call PRINT
		mov dx,offset STR_END_CODE
		call PRINT
		call BYTE_TO_HEX
		push ax
		mov ah,02h
		mov dl,al
		int 21h
		pop ax
		xchg ah,al
		mov ah,02h
		mov dl,al
		int 21h
		mov dx,offset ENDL
		call PRINT
	ret
RUN_MODULE ENDP

BEGIN:
	mov ax,DATA
	mov ds,ax
	call FREE_MEM
	call PREP
	call RUN_MODULE
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
	STR_ERR_FREE_MEM	 		db 'Error when freeing memory: $'
	STR_ERR_MCB_DESTROYED 		db 'MCB is destroyed$'
	STR_ERR_NOT_ENOUGH_MEM 		db 'Not enough memory for function processing$'
	STR_ERR_WRNG_MEM_BL_ADDR 	db 'Wrong addres of memory block$'
	
	STR_ERR_WRNG_FNCT_NUMB		db 'Function number is wrong$'
	STR_ERR_FL_NOT_FND			db 'File is not found$'
	STR_ERR_DISK_ERR			db 'Disk error$'
	STR_ERR_NOT_ENOUGH_MEM2		db 'Not enough memory$'
	STR_ERR_WRONG_ENV_STR		db 'Wrong environment string$'
	STR_ERR_WRONG_FORMAT		db 'Wrong format$'
	
	STR_NRML_END				db 'Normal end$'
	STR_CTRL_BREAK				db 'End by Ctrl-Break$'
	STR_DEVICE_ERROR			db 'End by device error$'
	STR_RSDNT_END				db 'End by 31h function$'
	STR_END_CODE				db 'End code: $'
	ENDL 						db 0DH,0AH,'$'
	PARMS 						dw 0 
								dd ? 
								dd 0 
								dd 0  
	MODULE_PATH  				db 50h dup (0)
	KEEP_SS 					dw 0
	KEEP_SP 					dw 0
DATA ENDS

SSTACK SEGMENT STACK
	dw 64h dup (?)
SSTACK ENDS
 END START