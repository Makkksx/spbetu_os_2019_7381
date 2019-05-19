AStack SEGMENT STACK
    DW 100h DUP(?)
AStack ENDS

;________________________________________
DATA SEGMENT

ERRMEM db 'Error of clear memory: $'
MCB_ db 'MCB is destroyed$'
NOTMEM db 'Not enough memory$'
ERRADR db 'Error of the addres$'
ERRFUNCT db 'Error of function number$'
ERRFILE db 'Error of the file$'
ERRDISK db 'Error of the disk$'
NOTMEM_ db 'Not enough memory$'
ERRENV db 'Error of env$'
ERRFORM db 'Error of format$'
GOOD db 'All is good$'
END_CTRL db 'End ctrl$'
ERRDEVICE db 'Error of device$'
ERRRES db 'End 31h$'
CODEELEM db 'Code of finish: $'
STRING db 0DH,0AH,'$'
PARAM_S dw 0
    dd ?
    dd 0
    dd 0
_PATH db 50h dup ('$')
KEEP_SS dw 0
KEEP_SP dw 0
QQQ db 'qqqqqqqqqqqqq$'

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


TETR_TO_HEX PROC near
    and al,0fh
    cmp al,09
    jbe NEXT
    add al,07
NEXT:
    add al,30h
    ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC near
    push cx
    mov ah,al
    call TETR_TO_HEX
    xchg al,ah
    mov cl,4
    shr al,cl
    call TETR_TO_HEX
    pop cx
    ret
BYTE_TO_HEX ENDP


FUNC_ PROC
    mov ax,AStack
    sub ax,CODE
    add ax,100h
    mov bx,ax
    mov ah,4ah
    int 21h
    jnc stepF
    call DEAL
stepF:
    call PAR_BL
    push es
    push bx
    push si
    push ax
    mov es,es:[2ch]
    mov bx,-1
stepS:
    add bx,1
    cmp word ptr es:[bx],0000h
    jne stepS
    add bx,4
    mov si,-1
stepT:
    add si,1
    mov al,es:[bx+si]
    mov _PATH[si],al
    cmp byte ptr es:[bx+si],00h
    jne stepT
    add si,1
stepT2:
    mov _PATH[si],0
    sub si,1
    cmp byte ptr es:[bx+si],'\'
    jne stepT2
    add si,1
    mov _PATH[si],'2'
    add si,1
    mov _PATH[si],'.'
    add si,1
    mov _PATH[si],'C'
    add si,1
    mov _PATH[si],'O'
    add si,1
    mov _PATH[si],'M'
    pop ax
    pop si
    pop bx
    pop es
    ret
FUNC_ ENDP


MEMORY_ PROC
    mov ax,AStack
    mov bx,es
    sub ax,bx
    add ax,10h
    mov bx,ax
    mov ah,4Ah
    int 21h
    jnc FIN

    lea dx,ERRMEM
    call PrintMsg
    cmp ax,7
    lea dx,MCB_
    je MEM_PRINT
    cmp ax,8
    lea dx,NOTMEM
    je MEM_PRINT
    cmp ax,9
    lea dx,ERRADR

MEM_PRINT:
    call PrintMsg
    lea dx,STRING
    call PrintMsg

    xor AL,AL
    mov AH,4Ch
    int 21H
FIN:
    ret
MEMORY_ ENDP


PAR_BL PROC
    mov ax,es:[2Ch]
    mov PARAM_S,ax
    mov PARAM_S+2,es
    mov PARAM_S+4,80h
    ret
PAR_BL ENDP


DEAL PROC
    lea dx,_PATH
    xor ch,ch
    mov cl,es:[80h]
    cmp cx,0
    je UNTAIL
    mov si,cx
    push si
METOCHKA:
    mov al,es:[81h+si]
    mov [offset _PATH+si-1],al
    dec si
    loop METOCHKA
    pop si
    mov [_PATH+si-1],0
    mov dx,offset _PATH
UNTAIL:
    push ds
    pop es
    mov bx,offset PARAM_S
    mov KEEP_SP,sp
    mov KEEP_SS,ss
    mov ax,4b00h
    int 21h
    jnc FIN_
    push ax
    mov ax,DATA
    mov ds,ax
    pop ax
    mov SS,KEEP_SS
    mov SP,KEEP_SP
    cmp ax,1
    lea dx,ERRFUNCT
    je DEAL_PRINT
    cmp ax,2
    lea dx,ERRFILE
    je DEAL_PRINT
    cmp ax,5
    lea dx,ERRDISK
    je DEAL_PRINT
    cmp ax,8
    lea dx,NOTMEM_
    je DEAL_PRINT
    cmp ax,10
    lea dx,ERRENV
    je DEAL_PRINT
    cmp ax,11
    lea dx,ERRFORM
DEAL_PRINT:
    call PrintMsg
    lea dx,STRING
    call PrintMsg
    xor al,al
    mov ah,4Ch
    int 21H
FIN_:
    lea dx,STRING
    call PrintMsg
    call PrintMsg
    mov ax,4d00h
    int 21h
    cmp ah,0
    lea dx,GOOD
    je REASONS
    cmp ah,1
    lea dx,END_CTRL
    je REASONS
    cmp ah,2
    lea dx,ERRDEVICE
    je REASONS
    cmp ah,3
    lea dx,ERRRES
REASONS:
    call PrintMsg
    lea dx,STRING
    call PrintMsg
    lea dx,CODEELEM
    call PrintMsg
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
    lea dx,STRING
    call PrintMsg
    ret
DEAL ENDP



BEGIN:
    mov ax,DATA
    mov ds,ax
    call MEMORY_
    call FUNC_
    call DEAL
    xor AL,AL
    mov AH,4Ch
    int 21H
CODE ENDS
    END BEGIN
 
