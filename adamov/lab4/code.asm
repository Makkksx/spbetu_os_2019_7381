AStack SEGMENT STACK
	DW 100h DUP(?)
AStack ENDS

;________________________________________
DATA SEGMENT

wasloaded db 'Interruption had already been loaded.',0DH,0AH,'$'
unloaded db 'Interruption is restored.',0DH,0AH,'$'
loading db 'Interruption is loaded.',0DH,0AH,'$'

DATA ENDS


;________________________________________
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack


PrintMsg PROC NEAR
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
PrintMsg ENDP


setCurs PROC
    push ax
    push bx
    push cx

    mov ah,02h
    mov bh,00h
    int 10h

    pop cx
    pop bx
    pop ax
    ret
setCurs ENDP


getCurs PROC
    push ax
    push bx
    push cx

    mov ah,03h
    mov bh,00h
    int 10h

    pop cx
    pop bx
    pop ax
    ret
getCurs ENDP


ROUT PROC FAR
    jmp ROUT_
_DATA:
    SIGN db '0000'
    KEEP_CS dw 0
    KEEP_IP dw 0
    KEEP_PSP dw 0
    VALUE db 0
    COUNTER db '    Number of calls: 00000    $'
    STACK_	dw 	64 dup (?)
    KEEP_SS dw 0
    KEEP_AX	dw ?
    KEEP_SP dw 0

ROUT_:
    mov KEEP_SS,ss
    mov KEEP_AX,ax
    mov KEEP_SP,sp
    mov ax,seg STACK_
    mov ss,ax
    mov sp,0
    mov ax,KEEP_AX

    push ax
    push dx
    push ds
    push es
    cmp VALUE,1
    je ROUT_RES
    call getCurs
    push dx
    mov dh,22
    mov dl,45
    call setCurs

ROUT_SUM:
    push si
    push cx 
    push ds
    push ax
    mov ax,SEG COUNTER
    mov ds,ax
    mov bx,offset COUNTER
    add bx,22
    mov si,3
next_:
    mov ah,[bx+si]
    inc ah
    cmp ah,58
    jne ROUT_NEXT
    mov ah,48
    mov [bx+si],ah
    dec si
    cmp si,0
    jne next_
ROUT_NEXT:
    mov [bx+si],ah
    pop ds
    pop si
    pop bx
    pop ax
    push es 
    push bp
    mov ax,SEG COUNTER
    mov es,ax
    mov ax,offset COUNTER
    mov bp,ax
    mov ah,13h 
    mov al,0 
    mov cx,30
    mov bh,0
    int 10h
    pop bp
    pop es
    pop dx
    call setCurs
    jmp ROUT_END

ROUT_RES:
    cli
    mov dx,KEEP_IP
    mov ax,KEEP_CS
    mov ds,ax
    mov ah,25h 
    mov al,1Ch 
    int 21h 
    mov es,KEEP_PSP 
    mov es,es:[2Ch]
    mov ah,49h  
    int 21h
    mov es,KEEP_PSP
    mov ah,49h
    int 21h
    sti

ROUT_END:
    pop es
    pop ds
    pop dx
    pop ax 

    mov ax,KEEP_SS
    mov ss,ax
    mov sp,KEEP_SP
    mov ax,KEEP_AX

    iret
ROUT ENDP


CHECKING PROC
    mov ah,35h 
    mov al,1Ch 
    int 21h 		
    mov si,offset SIGN 
    sub si,offset ROUT 
    mov ax,'00'
    cmp ax,es:[bx+si] 
    jne UNLOAD 
    cmp ax,es:[bx+si+2] 
    je LOAD

UNLOAD:
    call SET_INTERRUPT
    mov dx,offset LAST_BYTE
    mov cl,4
    shr dx,cl
    inc dx
    add dx,CODE
    sub dx,KEEP_PSP
    xor al,al
    mov ah,31h 
    int 21h
LOAD:
    push es
    push ax
    mov ax,KEEP_PSP 
    mov es,ax
    cmp byte ptr ES:[82h],'/'
    jne BACK 
    cmp byte ptr ES:[83h],'u'
    jne BACK 
    cmp byte ptr ES:[84h],'n' 
    je UNLOAD_
BACK:
    pop ax
    pop es
    mov dx,offset wasloaded
    call PrintMsg
    ret
UNLOAD_:
    pop ax
    pop es
    mov byte ptr ES:[BX+SI+10],1
    mov dx,offset unloaded
    call PrintMsg
    ret
CHECKING ENDP


SET_INTERRUPT PROC
    push dx
    push ds
    mov ah,35h
    mov al,1Ch
    int 21h
    mov KEEP_IP,bx 
    mov KEEP_CS,es 
    mov dx,offset ROUT 
    mov ax,seg ROUT 
    mov ds,AX 
    mov ah,25h 
    mov al,1Ch 
    int 21h
    pop ds
    mov dx,offset loading 
    call PrintMsg
    pop dx
    ret
SET_INTERRUPT ENDP 


BEGIN:
    mov ax,DATA
    mov ds,ax
    mov KEEP_PSP,es
    call CHECKING
    xor al,al
    mov ah,4Ch
    int 21H

LAST_BYTE:

CODE ENDS
    END BEGIN
