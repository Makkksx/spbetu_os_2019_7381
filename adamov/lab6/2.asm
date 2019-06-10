TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

START: JMP BEGIN

; ________________________________________
; Данные

SegmentAddressOfUnavailableMemory db 0dh,0ah,'Segment address of unavailable memory:     h',0dh,0ah,'$'
SegmentAddressOfEnvironment db 'Segment address of environment:     h',0dh,0ah,'$'
Tail db 'Tail:','$'
ContentOfEnvironment db 'Content of environment:$'
PathOfModule db 0dh,'Path of module:$'
EndOfString db 0dh,0ah,'$'
EndOfStringWithTab db 0dh,0ah,'    $'



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
    call TETR_TO_HEX ; 
    pop cx 			
    ret
BYTE_TO_HEX ENDP

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

PrintMsg PROC near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
PrintMsg ENDP


PrintSegmentAddressOfUnavailableMemory PROC near
    push ax
    push di
    push dx

    mov ax,es:[2]
    lea di,SegmentAddressOfUnavailableMemory
    mov dx,di
    add di,44
    call WRD_TO_HEX
    call PrintMsg

    pop dx
    pop di
    pop ax
    ret
PrintSegmentAddressOfUnavailableMemory ENDP


PrintSegmentAddressOfEnvironment PROC near
    push ax
    push di
    push dx

    mov ax,es:[2Ch]
    lea di,SegmentAddressOfEnvironment
    mov dx,di
    add di,35
    call WRD_TO_HEX
    call PrintMsg

    pop dx
    pop di
    pop ax
    ret
PrintSegmentAddressOfEnvironment ENDP


PrintCommandLineTail PROC near
    push ax
    push cx
    push dx
    push si

    lea dx,Tail
    call PrintMsg
    xor ax,ax
    mov al,es:[80h]
    add al,81h
    mov si,ax
    push es:[si]
    mov byte ptr es:[si+1],'$'
    push ds
    mov cx,es
    mov ds,cx
    mov dx,81h
    call PrintMsg
    lea dx,EndOfString
    call PrintMsg

    pop ds
    pop es:[si]
    pop si
    pop dx
    pop cx
    pop ax
    ret
PrintCommandLineTail ENDP


PrintEnvironmentContentAndModulePath PROC near
    push si
    push es
    push ax
    push bx
    push cx
    push dx

    lea dx,ContentOfEnvironment
    call PrintMsg
    mov bx,1
    mov es,es:[2ch]
    mov si,0
p_1:
    lea dx,EndOfStringWithTab
    call PrintMsg
    mov ax,si
p_2:
    cmp byte ptr es:[si],0
    je p_3
    inc si
    jmp p_2
p_3:
    push es:[si]
    mov byte ptr es:[si], '$'
    push ds
    mov cx,es
    mov ds,cx
    mov dx,ax
    call PrintMsg
    pop ds
    pop es:[si]
    cmp bx,0
    jz p_4
    inc si
    cmp byte ptr es:[si],01h
    jne p_1
    lea dx,PathOfModule
    call PrintMsg
    mov bx,0
    add si,2
    jmp p_1
p_4:
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop si
    ret
PrintEnvironmentContentAndModulePath ENDP



; ________________________________________
; Код

BEGIN:
    call PrintSegmentAddressOfUnavailableMemory
    call PrintSegmentAddressOfEnvironment
    call PrintCommandLineTail
    call PrintEnvironmentContentAndModulePath
    lea dx,EndOfString
    call PrintMsg
    call PrintMsg
    mov ah,01h
    int 21h
    mov ah,04Ch
    int 21h
    ret
TESTPC ENDS
    END START
