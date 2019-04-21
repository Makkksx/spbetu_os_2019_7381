INT_STACK SEGMENT
	DW 100h DUP(?)
INT_STACK ENDS
;=======================================================
CODE SEGMENT	
ASSUME CS:CODE, DS:DATA, SS:STACK
;-------------------------------------------------------
setCurs PROC
	push ax
	push bx
	;push dx
	push cx
	mov ah,02h
	mov bh,0
	int 10h
	pop cx
	;pop dx
	pop bx
	pop ax
	ret
setCurs ENDP
;-------------------------------------------------------
getCurs PROC
	push ax
	push bx
	push cx
	mov ah,03h
	mov bh,0
	int 10h
	mov ah,8
	int 10h
	pop cx
	pop bx
	pop ax
getCurs ENDP
;-------------------------------------------------------
outputAL PROC
	push ax
	push bx
	push cx
	mov ah,09h  
	mov bh,0
	mov cx,1
	int 10h  
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP
;-------------------------------------------------------

;-------------------------------------------------------
INTER PROC FAR
	jmp INT_CODE
	KEY_WORD db 'MY_INT'
	KEEP_CS DW 0
	KEEP_IP DW 0
	KEEP_PSP DW 0
	COUNT db 0
	COUNT_1 db 0
	COUNT_2 db 0
	COUNT_3 db 0
	COUNT_4 db 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_DX dw 0
	INT_CODE:
	push ax
	mov KEEP_SS,ss
	mov KEEP_SP,sp
	mov ax, seg INT_STACK
	mov ss, ax
	mov sp, 100h
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	
	
	
	
	
	call getCurs	
	push dx
	mov dx,00130h
	call setCurs
	
	cmp COUNT,0AH
	jl rout_skip
	mov count,0h
rout_skip:
	mov al,COUNT
	or al,30h
	call outputAL
	
	pop dx
	call setCurs
	inc COUNT
	
	jmp int_end
	

	
	
	
	
	
	
	
	
	
	
	call getCurs
	push dx

	
	mov dh,22
	mov dl,40
	call setCurs
	
		
	cmp COUNT_1,10
	jl next_it
	mov COUNT_1,0
	add COUNT_2,1
	cmp COUNT_2,10
	jl next_it
	mov COUNT_2,0
	add COUNT_3,1
	cmp COUNT_3,10
	jl next_it
	mov COUNT_3,0
	add COUNT_4,1
	cmp COUNT_4,10
	jl next_it
	mov COUNT_4,0
	
next_it:
	
	mov al,COUNT_1    
	add al,30h
	call outputAL
	
	mov dl,39
	call setCurs
	
	
	mov al,COUNT_2    
	add al,30h
	call outputAL
	
	mov dl,38
	call setCurs
	
	mov al,COUNT_3    
	add al,30h
	call outputAL
	
	mov dl,37
	call setCurs
	
	mov al,COUNT_4    
	add al,30h
	call outputAL
	
	inc COUNT_1
	
	
	pop dx
	call setCurs
	
int_end:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax 
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov al,20h
	out 20h,al
	pop ax
	iret
end_inter:
INTER ENDP
;-------------------------------------------------------

;-------------------------------------------------------
LOAD_INT PROC near
	push ax
	push cx
	push bx
	push dx
	push ds
	mov ah, 35h
    mov al, 1Ch
    int 21h
    
    mov KEEP_IP, bx
    mov KEEP_CS, es
	mov ax, SEG INTER
	mov dx, OFFSET INTER
	mov ds,ax
	mov ah, 25h
    mov al, 1Ch
    int 21h
    
    mov dx, OFFSET end_inter
    mov cl,4
    shr dx,cl
    inc dx
    add dx, CODE
    sub dx, KEEP_PSP
    mov ah, 31h
    int 21h
    pop ds
	pop dx
	pop bx
	pop cx
	pop ax
	ret
LOAD_INT ENDP
;-------------------------------------------------------
IS_UNLOAD PROC near
	push di
	mov di, 81h
	cmp byte ptr [di+0], ' '
	jne bad_key
	cmp byte ptr [di+1], '/'
	jne bad_key
  	cmp byte ptr [di+2], 'u'
 	jne bad_key
  	cmp byte ptr [di+3], 'n'
  	jne bad_key
  	cmp byte ptr [di+4], 0Dh
  	jne bad_key
  	cmp byte ptr [di+5], 0h
  	jne bad_key
	pop di
	mov al,1
	ret
bad_key:
	pop di
	mov al,0
	ret
IS_UNLOAD ENDP
;-------------------------------------------------------
CHECK_INT PROC near
	push ax
	push bx
	push es
	mov ah, 35h
    mov al, 1ch
    int 21h	
    mov ax, OFFSET KEY_WORD
    sub ax, OFFSET INTER
	add bx, ax
	mov si,bx
	push ds 
	mov ax,es
	mov ds,ax
	cmp [si], 'YM'
    jne false
    add si,2
    cmp [si], 'I_'
    jne false
    add si,2
    cmp [si], 'TN'
    jne false
    pop ax
    mov ds,ax
    pop es
    pop bx
	pop ax
	mov al,1
	ret
	
false:
	pop ax
    mov ds,ax
    pop es
    pop bx
	pop ax
	mov al,0
	ret
CHECK_INT ENDP
;-------------------------------------------------------
UNLOAD_INT PROC near
	push ax
	push dx
	mov ah, 35h
    mov al, 1Ch
    int 21h
    cli
    push ds
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
	mov ds, ax
    mov ah, 25h
    mov al, 1Ch
    int 21h
    pop ds


	mov es, es:KEEP_PSP
	push es
    mov es, es:[2Ch] 
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

	sti	
	pop dx
	pop ax
	ret
UNLOAD_INT ENDP
;-------------------------------------------------------
MAIN PROC FAR
	push ds
    sub ax,ax
    push ax
    mov cs:KEEP_PSP, es
	
	call CHECK_INT
	cmp al, 1
	je int_loaded
	
	call IS_UNLOAD
	cmp al, 1
	je int_not_loaded
	
	
	mov dx, offset INTER_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	call LOAD_INT
	jmp end_prog
	
	
int_not_loaded:
	mov dx, offset INTER_NOT_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	jmp end_prog
	
	
int_loaded:
	call IS_UNLOAD
	cmp al, 1
	je need_to_unload
	
	mov dx, offset INTER_ALREADY
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	jmp end_prog
	
need_to_unload:
	call UNLOAD_INT
	mov dx, offset INTER_UNLOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	jmp end_prog	
	
end_prog:	
	xor al,al
	mov ah,4ch
	int 21h

MAIN ENDP	
CODE ENDS
;=======================================================
STACK SEGMENT
	DW 100h DUP(?)
STACK ENDS
;=======================================================
DATA SEGMENT
	INTER_ALREADY db 'Interruption is already loaded',13,10,36
	INTER_UNLOADED db 'Interruption is unloaded',13,10,36
	INTER_LOADED db 'Interruption is loaded',13,10,36
	INTER_NOT_LOADED db 'Interruption is not loaded',13,10,36
	
DATA ENDS
;=======================================================
END MAIN