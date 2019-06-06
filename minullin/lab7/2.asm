CODE segment
	assume  CS:CODE, DS:CODE

START:
	push    ds
    push    cs
    pop     ds
	mov     di, offset ADDR_STRING + 51
    mov     ax, cs
	call    WRD_TO_HEX
	mov     dx, offset ADDR_STRING 
	mov     ah, 09h
	int     21h
	pop     ds
	retf
	
TETR_TO_HEX proc near
    and     al, 0Fh
    cmp     al, 09
    jbe     NEXT
    add     al, 07
NEXT: 
    add     al, 30h
    ret
TETR_TO_HEX endp
	
BYTE_TO_HEX proc near
    push    cx
    mov     ah, al
    call    TETR_TO_HEX
    xchg    al, ah
    mov     cl, 4
    shr     al, cl
    call    TETR_TO_HEX
    pop     cx
    ret
BYTE_TO_HEX endp

WRD_TO_HEX proc near
    push    bx
    mov     bh, ah
    call    BYTE_TO_HEX
    mov     [di], ah
    dec     di
    mov     [di], al
    dec     di
    mov     al, bh
    call    BYTE_TO_HEX
    mov     [di], ah
    dec     di
    mov     [di], al
    pop     bx
    ret
WRD_TO_HEX endp
	ADDR_STRING 	DB 'I am a second overlay: Segment address of CODE:     ',0DH,0AH,'$'
CODE ends

end START