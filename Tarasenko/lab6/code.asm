.model small

text segment
	assume cs:text, ds:data, ss:stk
TETR_TO_HEX   PROC  near
	and      AL,0Fh
	cmp      AL,09
	jbe      NEXT
	add      AL,07
	NEXT:    add AL,30h
	ret
TETR_TO_HEX   ENDP

BYTE_TO_HEX   PROC  near
	push     CX
	mov      AH,AL
	call     TETR_TO_HEX
	xchg     AL,AH
	mov      CL,4
	shr      AL,CL
	call     TETR_TO_HEX
	pop      CX
	ret
BYTE_TO_HEX  ENDP

WRITE PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP

freeMem PROC
	lea bx, PROGRAM
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov ah, 4Ah
	int 21h
	jnc Not_error
	
	mov memoryError, 1
	
	Not_error:
		ret
freeMem ENDP

exitProgram PROC
	mov ah, 4Dh
	int 21h
	cmp ah, 1
	je Child_error
	
	lea bx, SUCCESFULL_PROCESS_AND_CODE
	mov [bx], ax
	lea dx, SUCCESFULL_PROCESS_AND_CODE
	push ax
	call WRITE
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
	jmp Quit
	
	Child_error:
		lea dx, END_WITH_CTRL_C
		call WRITE
		
	Quit:
		ret
exitProgram ENDP

main proc
	mov ax, @data
	mov ds, ax

	push si
	push di
	push es
	push dx
	mov es, es:[2Ch]
	xor si, si
	lea di, filename
	Environment: 
		cmp byte ptr es:[si], 00h
		je Crlf
		
		inc si
		jmp Environment_next
	Crlf:   
		inc si
	Environment_next:       
		cmp word ptr es:[si], 0000h
		jne Environment
		add si, 4
		
	Abs_path:
		cmp byte ptr es:[si], 00h
		je Check_end
		mov dl, es:[si]
		mov [di], dl
		inc si
		inc di
		jmp Abs_path
		
	Check_end:
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
	
		call freeMem
		cmp memoryError, 0
		jne Exit
		
		push ds
		pop es
		lea dx, filename
		lea bx, param
		mov _ss, ss
		mov _sp, sp
		mov ax, 4b00h
		int 21h
		mov ss, _ss
		mov sp, _sp
		jnc Close_module
		
		lea dx, NO_FILE
		call WRITE
		
		lea dx, filename
		call WRITE
		jmp Exit
		
	Close_module:
		call exitProgram
		
	Exit:
		mov ah, 4Ch
		int 21h
main ENDP

PROGRAM PROC
PROGRAM ENDP

text ends

data segment
	SUCCESFULL_PROCESS_AND_CODE db 13, 10, "Process was end successfully, code: $"
	NO_FILE db 13, 10, "ERROR: No file", 13, 10, "$"
	END_WITH_CTRL_C db 13, 10, "Process was end with ctrl+c$"
	psp dw ?
	filename db 50 dup(0)
	EOL db "$"
	param dw 7 dup(?)
	_ss dw ?
	_sp dw ?
	memoryError db 0
data ends

stk segment stack
	dw 128 dup (?)
stk ends
end main