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


PrintMsg PROC near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
PrintMsg ENDP



ROUT PROC far
    jmp ROUT_
_DATA:
    STACK_ dw 64 DUP (?)
    SIGN db '0000'
    KEEP_IP dw 0
    KEEP_CS dw 0
    KEEP_PSP dw 0
    KEEP_SS dw 0
    KEEP_AX dw 0
    KEEP_SP dw 0
    _TILD db 29h
    _OTHERSYM db 01h

ROUT_:
    mov KEEP_SS,ss
    mov KEEP_AX,ax
    mov KEEP_SP,sp
    mov ax,seg STACK_
    mov ss,ax
    mov sp,0
    mov ax,KEEP_AX

    mov al,0
	in al,60h
	cmp al,_TILD
	je DO_REQ
	
	pushf
	call dword ptr CS:KEEP_IP
	jmp ROUT_END

DO_REQ:
    push ax
    in al,61h
    mov ah,al
    or al,80h
    out 61h,al
    xchg ah,al
    out 61h,al
    mov al,20h
    out 20h,al
    pop ax

ADDSYMB:
    mov al,0
    mov ah,05h
    mov cl,_OTHERSYM
    mov ch,00h
    int 16h
    or al,al
    jz ROUT_END
    mov ax,0040h
    mov es,ax
    mov ax,es:[1Ah]
    mov es:[09h],ax
    jmp ADDSYMB

ROUT_END:
    pop es
    pop ds
    pop dx
    mov al,20h
	out 20h,al
    pop ax
    mov ax,KEEP_SS
    mov ss,ax
    mov sp,KEEP_SP
    mov ax,KEEP_AX
    iret
ROUT ENDP



CHECKING PROC
    mov ah,35h
    mov al,09h
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
    sub dx,CS:KEEP_PSP
    xor al,al
    mov ah,31h
    int 21h

LOAD:
    push es
    push ax
    mov ax,KEEP_PSP
    mov es,ax
    cmp byte ptr es:[82h],'/'
    jne BACK
    cmp byte ptr es:[83h],'u'
    jne BACK
    cmp byte ptr es:[84h],'n'
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
    call DELETE_INTERRUPT
    mov dx,offset unloaded
    call PrintMsg
    ret
CHECKING ENDP



SET_INTERRUPT PROC
    push dx
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
    mov dx,offset loading
    call PrintMsg
    pop dx
    ret
SET_INTERRUPT ENDP



DELETE_INTERRUPT PROC
    push ds
    cli
    mov dx,es:[bx+si+4]
    mov ax,es:[bx+si+6]
    mov ds,ax
    mov ax,2509h
    int 21h
    push es
    mov ax,es:[bx+si+8]
    mov es,ax
    mov es,es:[2Ch]
    mov ah,49h
    int 21h
    pop es
    mov es,es:[bx+si+8]
    mov ah,49h
    int 21h
    sti
    pop ds
    ret
DELETE_INTERRUPT ENDP




BEGIN:
    mov ax,DATA
    mov ds,ax
    mov KEEP_PSP,es
    call CHECKING
    xor al,al
    mov ah,4Ch
    int 21h

LAST_BYTE:

CODE ENDS
    END BEGIN