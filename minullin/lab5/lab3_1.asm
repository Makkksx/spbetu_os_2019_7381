
testpc segment
	assume cs:testpc, ds: testpc, es:nothing, ss:nothing

org 100h

start: jmp begin

AVAILABLE_MEM 		db 'Available memory (B):        ', 10, 13, '$'
EXTENDED_MEM 		db 'Extended memory (KB):        ', 10, 13, '$'
TABLE_TITLE 		db '| MCB Type | PSP Address | Size | SC/SD |', 10, 13, '$'
TABLE_MCB_DATA  	db '                                                                    ', 10, 13, '$'

PRINT       proc    near
    push    ax
    mov 	ah, 09h
    int		21h
    pop     ax
    ret
PRINT       endp

TETR_TO_HEX proc    near
	and     al,0Fh
	cmp     al,09
	jbe     NEXT
	add     al,07
NEXT:	
	add     al,30h
	ret
TETR_TO_HEX endp

BYTE_TO_HEX proc    near
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

WRD_TO_HEX  proc    near
	push    BX
	mov     BH,ah
	call    BYTE_TO_HEX
	mov     [di], ah
	dec     di
	mov     [di], al
	dec     di
	mov     al, BH
	call    BYTE_TO_HEX
	mov     [di], ah
	dec     di
	mov     [di], al
	pop     BX
	ret
WRD_TO_HEX  endp

BYTE_TO_DEC proc near
	push    cx
	push    dx
	xor     ah, ah
	xor     dx, dx
	mov     cx, 10
loop_bd: 
    div     cx
	or      dl, 30h
	mov     [si], dl
	dec     si
	xor     dx, dx
	cmp     ax, 10
	jae loop_bd
	cmp     al, 00h
	je      end_l
	or      al, 30h
	mov     [si], al
end_l:	
    pop     dx
	pop     cx
	ret
BYTE_TO_DEC endp

WRD_TO_DEC  proc    near
	push    cx
	push    dx
	mov     cx, 10
loop_b: 
    div     cx
	or      dl, 30h
	mov     [si], dl
	dec     si
	xor     dx, dx
	cmp     ax, 10
	jae     loop_b
	cmp     al, 00h
	je      endl
	or      al, 30h
	mov     [si], al
endl:	
    pop     dx
	pop     cx
	ret
WRD_TO_DEC  endp

GET_AVAILABLE_MEM proc  near
	push    ax
	push    bx
	push    dx
	push    si
	xor     ax, ax
	mov     ah, 04Ah
	mov     bx, 0FFFFh
	int     21h
	mov     ax, 10h
	mul     bx
	mov     si, offset AVAILABLE_MEM
	add     si, 27
	call    WRD_TO_DEC
	mov     dx, offset AVAILABLE_MEM
	call    PRINT
	pop     si
	pop     dx
	pop     bx
	pop     ax
	ret
GET_AVAILABLE_MEM   endp

GET_EXTENDED_MEM    proc    near
	push    ax
	push    bx
	push    dx
	push    si
	xor     dx, dx
	mov     al, 30h
    out     70h, al
    in      al, 71h 
    mov     bl, al 
    mov     al, 31h  
    out     70h, al
    in      al, 71h
	mov     ah, al
	mov     al, bl
	mov     si, offset EXTENDED_MEM
	add     si, 26
	call    WRD_TO_DEC
	mov     dx, offset EXTENDED_MEM
	call    PRINT
	pop     si
	pop     dx
	pop     bx
	pop     ax
	ret
GET_EXTENDED_MEM endp

GET_MCB_TYPE proc near
	push    ax
	push    di
	mov     di, offset TABLE_MCB_DATA
	add     di, 5
	xor     ah, ah
	mov     al, es:[00h]
	call    BYTE_TO_HEX
	mov     [di], al
	inc     di
	mov     [di], ah
	pop     di
	pop     ax
	ret
GET_MCB_TYPE endp

GET_PSP_ADDRESS proc near
	push    ax
	push    di
	mov     di, offset TABLE_MCB_DATA
	mov     ax, es:[01h]
	add     di, 19
	call    WRD_TO_HEX
	pop     di
	pop     ax
	ret
GET_PSP_ADDRESS endp

GET_MCB_SIZE proc near
	push    ax
	push    bx
	push    di
	push    si
	mov     di, offset TABLE_MCB_DATA
	mov     ax, es:[03h]
	mov     bx, 10h
	mul     bx
	add     di, 29
	mov     si, di
	call    WRD_TO_DEC
	pop     si
	pop     di
	pop     bx
	pop     ax
	ret
GET_MCB_SIZE endp

GET_SC_SD proc near
	push    bx
	push    dx
	push    di
	mov     di, offset TABLE_MCB_DATA
	add     di, 33
    mov     bx, 0h
GET_8_BYTES:
    mov     dl, es:[bx + 8]
    mov     [di], dl
    inc     di
    inc     bx
    cmp     bx, 8h
	jne     GET_8_BYTES
	pop     di
	pop     dx
	pop	    bx
	ret
GET_SC_SD   endp

GET_MCB_DATA    proc    near
	mov     ah, 52h
	int     21h
	sub     bx, 2h
	mov     es, es:[bx]
FOR_EACH_MCB:
    call    GET_MCB_TYPE
    call    GET_PSP_ADDRESS
    call    GET_MCB_SIZE
    call    GET_SC_SD
    mov     ax, es:[03h]
    mov     bl, es:[00h]
    mov     dx, offset TABLE_MCB_DATA
    call    PRINT
    mov     cx, es
    add     ax, cx
    inc     ax
    mov     es, ax
    cmp     bl, 4Dh
    je      FOR_EACH_MCB

	ret
GET_MCB_DATA endp

begin:
    call    GET_AVAILABLE_MEM
	call    GET_EXTENDED_MEM
	mov     dx, offset TABLE_TITLE
	call    PRINT
	call    GET_MCB_DATA	
	xor     al, al
	mov     ah, 4ch
	int     21h
testpc ends

end start