TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

START: JMP BEGIN

; ________________________________________
; Данные


AvailableMemory db 0dh,0ah,'Available memory:        B',0dh,0ah,'$'
ExtendedMemory db 'Extended memory:       KB',0dh,0ah,'$'
TableHead db 0dh,0ah,'MCB Adress   MCB Type   Owner     	 Size        Name    ',0dh,0ah,'$'
MCB db '                                                             ',0dh,0ah,'$'
error_m db 'Failed!',0dh,0ah,'$'

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

Print PROC near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
Print ENDP


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
    add si,25 
    call WRD_TO_DEC
	lea dx,AvailableMemory
	call Print

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

    mov al,30h ;чтение младшего байта
    out 70h,al 
    in al,71h	;чтение младшего байта
    mov bl,al	;размера расширенной памяти
    mov al,31h	;запись адреса ячейки CMOS
    out 70h,al
    in al,71h	;стение старшего байта размера расширенной памяти
    mov ah,al
    mov al,bl
    sub dx,dx
    lea si,ExtendedMemory
    add si,21
    call WRD_TO_DEC
	lea dx,ExtendedMemory
    call Print

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
    add di,3
    call WRD_TO_HEX

    ; Type
    lea di,MCB
    add di,13
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
case_print:
    mov dl,es:[bx+8]
    mov [di],dl
    inc di
    inc bx
    cmp bx,8
    jne case_print
    mov ax,es:[3]
    mov bl,es:[0]
    ret
PrintMCB ENDP


PrintMemoryManagementUnits PROC near
    lea dx,TableHead
    call Print
    mov ah,52h
    int 21h
    sub bx,2h
    mov es,es:[bx]
case:
    call PrintMCB
    lea dx,MCB
    call Print
    mov cx,es
    add ax,cx
    inc ax
    mov es,ax
    cmp bl,4Dh
    je case
    ret
PrintMemoryManagementUnits ENDP


; ________________________________________
; Код

BEGIN:


    call PrintAvailableMemory
    call PrintExtendedMemorySize
	
	mov ah,48h
    mov bx,1000h
    int 21h
	
	jc case_error
	jmp case_alright
case_error:
	lea dx,error_m
	call Print
case_alright:
	mov ah,4ah
	lea bx,progs_end
    int 21h
	

	
    call PrintMemoryManagementUnits

    xor al,al
    mov ah,4ch
    int 21h
	
	progs_end db 0

TESTPC ENDS
    END START