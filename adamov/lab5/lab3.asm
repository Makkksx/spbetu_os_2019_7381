TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

START: JMP BEGIN

; ________________________________________
; Данные


AvailableMemory db 0dh,0ah,'Amount of available memory:        B',0dh,0ah,'$'
ExtendedMemorySize db 'Extended memory size:       KB',0dh,0ah,'$'
TableHead db 0dh,0ah,'  MCB Adress   MCB Type   Owner     	 Size        Name    ',0dh,0ah,'$'
MCB db '                                                             ',0dh,0ah,'$'


; ________________________________________
; Процедуры

TETR_TO_HEX PROC near
    and al,0fh
    cmp al,09
    jbe NEXT
    add al,07
NEXT: add al,30h
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
BYTE_TO_HEX		ENDP

WRD_TO_HEX PROC near
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

BYTE_TO_DEC PROC near
    push cx
    push dx
    xor ah,ah
    xor dx,dx
    mov cx,10
loop_bd: div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_bd
    cmp al,00h
    je end_l
    or al,30h
    mov [si],al
end_l: pop dx
    pop cx
    ret
BYTE_TO_DEC ENDP

WRD_TO_DEC PROC near
    push cx
    push dx
    push ax
    mov cx,10
loop_wd:
    div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_wd
    cmp ax,00h
    jbe end_l_2
    or al,30h
    mov [si],al
end_l_2:
    pop ax
    pop dx
    pop cx
    ret
WRD_TO_DEC ENDP

PrintMsg PROC near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
PrintMsg ENDP


PrintAvailableMemory PROC near
    push ax
    push bx
    push dx
    push si

    mov ah,04Ah
    mov bx,0FFFFh
    int 21h
    mov ax,10h
    mul bx
    lea si,AvailableMemory
    add si,35
    call WRD_TO_DEC
    lea dx,AvailableMemory
    call PrintMsg

    pop si
    pop dx
    pop bx
    pop ax
    ret
PrintAvailableMemory ENDP


PrintExtendedMemorySize PROC near
    push ax
    push bx
    push dx
    push si

    mov al,30h
    out 70h,al 
    in al,71h
    mov bl,al
    mov al,31h
    out 70h,al
    in al,71h
    mov ah,al
    mov al,bl
    sub dx,dx
    lea si,ExtendedMemorySize
    add si,26
    call WRD_TO_DEC
    lea dx,ExtendedMemorySize
    call PrintMsg

    pop si
    pop dx
    pop bx
    pop ax
    ret
PrintExtendedMemorySize ENDP


PrintMCB PROC near
    ; Address
    lea di,MCB
    mov ax,es
    add di,5
    call WRD_TO_HEX

    ; Type
    lea di,MCB
    add di,15
    xor ah,ah
    mov al,es:[0]
    call BYTE_TO_HEX
    mov [di],al
    inc di
    mov [di],ah

    ; Owner
    lea di,MCB
    mov ax,es:[1]
    add di,29
    call WRD_TO_HEX

    ; Size
    lea di,MCB
    mov ax,es:[3]
    mov bx,10h
    mul bx
    add di,46
    push si
    mov si,di
    call WRD_TO_DEC
    pop si

    ; Name
    lea di,MCB
    add di,53
    mov bx,0
print_:
    mov dl,es:[bx+8]
    mov [di],dl
    inc di
    inc bx
    cmp bx,8
    jne print_
    mov ax,es:[3]
    mov bl,es:[0]
    ret
PrintMCB ENDP


PrintMemoryManagementUnits PROC near
    lea dx,TableHead
    call PrintMsg
    mov ah,52h
    int 21h
    sub bx,2h
    mov es,es:[bx]
metka_1:
    call PrintMCB
    lea dx,MCB
    call PrintMsg
    mov cx,es
    add ax,cx
    inc ax
    mov es,ax
    cmp bl,4Dh
    je metka_1
    ret
PrintMemoryManagementUnits ENDP


; ________________________________________
; Код

BEGIN:
    call PrintAvailableMemory
    call PrintExtendedMemorySize
    call PrintMemoryManagementUnits

    xor al,al
    mov ah,4ch
    int 21h

TESTPC ENDS
    END START
