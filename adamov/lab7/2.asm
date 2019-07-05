OVL SEGMENT
    ASSUME CS:OVL, DS:NOTHING, SS:NOTHING, ES:NOTHING


BEGIN PROC FAR
    push ds
    push ax
    push di
    push dx
    push bx
    mov ds,ax
    lea bx,cs:mes
    add bx,22
    mov di, bx
    mov ax, cs
    call WRD_TO_HEX
    lea dx, cs:mes
    call PrintMsg
    pop bx
    pop dx
    pop di
    pop ax
    pop ds
    retf
BEGIN ENDP


mes db '; Segment address:     h',0DH,0AH,'$'


PrintMsg PROC near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
PrintMsg ENDP


TETR_TO_HEX PROC NEAR
    and al,0Fh
    cmp al,09
    jbe NEXT
    add al,07
NEXT:
    add al,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR
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

WRD_TO_HEX PROC NEAR
    push bx
    mov bh,ah
    call BYTE_TO_HEX
    mov [di],ah
    dec di
    mov [di],al
    dec di
    mov al,bh
    call BYTE_TO_HEX
    mov [di],ah
    dec di
    mov [di],al
    pop bx
    ret
WRD_TO_HEX ENDP


OVL ENDS
    END BEGIN
