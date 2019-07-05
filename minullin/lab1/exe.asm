
AStack      SEGMENT STACK
AStack      ENDS

DATA        SEGMENT

TypePC_Unknown  db  'PC Type: Unknown', 0dh, 0ah, '$'
TypePC_PC       db  'PC Type: PC', 0dh, 0ah, '$'
TypePC_PCXT     db  'PC Type: PC/XT', 0dh, 0ah,'$'
TypePC_AT       db  'PC Type: AT', 0dh, 0ah, '$'
TypePC_230PS    db  'PC Type: PC2 model 30', 0dh, 0ah, '$'
TypePC_280PS    db  'PC Type: PS2 model 80', 0dh, 0ah, '$'
TypePC_PCjr     db  'PC Type: PCjr', 0dh, 0ah, '$'
TypePC_PCC      db  'PC Type: PC Convertible', 0dh, 0ah, '$'

ModifyNumber	db	'Modify number:   .  ', 0dh, 0ah, '$'
OEM_Code		db	'OEM Code:   ', 0dh, 0ah, '$'
UserSN	        db	'User Serial Number:       ', 0dh, 0ah, '$'

DATA        ENDS

CODE        SEGMENT
    ASSUME  CS:CODE, DS:DATA, SS:AStack

PRINT_STRING PROC near
    mov 	ah, 09h
    int		21h
    ret
PRINT_STRING ENDP

TETR_TO_HEX		PROC	near
    and		al, 0fh
    cmp		al, 09
    jbe		NEXT
    add		al, 07
NEXT:	
    add		al, 30h
    ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC near
    push	cx
    mov		al, ah
    call	TETR_TO_HEX
    xchg	al, ah
    mov		cl, 4
    shr		al, cl
    call	TETR_TO_HEX 
    pop		cx 			
    ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	near
    push	bx
    mov		bh, ah
    call	BYTE_TO_HEX
    mov		[di], ah
    dec		di
    mov		[di], al
    dec		di
    mov		al, bh
    xor		ah, ah
    call	BYTE_TO_HEX
    mov		[di], ah
    dec		di
    mov		[di], al
    pop		bx
    ret
WRD_TO_HEX		ENDP

BYTE_TO_DEC		PROC	near
    push	cx
    push	dx
    push	ax
    xor		ah, ah
    xor		dx, dx
    mov		cx, 10
loop_bd:
    div		cx
    or 		dl, 30h
    mov 	[si], dl
    dec 	si
    xor		dx, dx
    cmp		ax, 10
    jae		loop_bd
    cmp		ax, 00h
    jbe		end_l
    or		al, 30h
    mov		[si], al
end_l:	
    pop		ax
    pop		dx
    pop		cx
    ret
BYTE_TO_DEC		ENDP

Main:
    push    ds
    xor     ax, ax
    push    ax
    mov     ax, DATA
    mov     ds, ax
    
    ; здесь определяем тип ПК
    push	es
    push	bx
    push	ax
    mov 	bx, 0F000h
    mov 	es, bx
    
    ; предпоследний байт ROM BIOS
    mov 	ax, es:[0FFFEh]
    ; PC
    cmp     al, 0FFh
    je      MVPC
    ; PC/XT
    cmp     al, 0FEh
    je      MVPCXT
    cmp     al, 0FBh
    je      MVPCXT
    ; AT
    cmp     al, 0FCh
    je      MVAT
    ; PS2/30
    cmp     al, 0FAh
    je      MV230PS
    ; коды для AT и PS2/50-60 совпадают, поэтому не обрабатываем (ну или что делать?)

    ; PS2/80
    cmp     al, 0F8h
    je      MV280PS
    ; PCjr
    cmp     al, 0FDh
    je      MVPCjr
    ; PC Convertible
    cmp     al, 0F9h
    je      MVPCC
    ; PC Unknown
    lea     dx, TypePC_Unknown
    jmp     MVEND
MVPC:
    lea		dx, TypePC_PC
    jmp     MVEND
MVPCXT:
    lea		dx, TypePC_PCXT
    jmp     MVEND
MVAT:
    lea		dx, TypePC_AT
    jmp     MVEND
MV230PS:
    lea		dx, TypePC_230PS
    jmp     MVEND
MV280PS:
    lea		dx, TypePC_280PS
    jmp     MVEND
MVPCjr:
    lea		dx, TypePC_PCjr
    jmp     MVEND
MVPCC:
    lea		dx, TypePC_PCC
MVEND:
    call	PRINT_STRING
    pop		ax
    pop 	bx
    pop 	es

    ; здесь определяем версию системы
    mov 	ah, 30h
    int		21h

    push	ax
    push	si
    lea		si, ModifyNumber
    add		si, 16
    call	BYTE_TO_DEC
    add		si, 3
    mov 	al, ah
    call   	BYTE_TO_DEC
    pop 	si
    pop 	ax

    ; здесь определяем серийный номер OEM
    mov 	al, bh
    lea		si, OEM_Code
    add		si, 12
    call	BYTE_TO_DEC

    ; здесь определяем серийный номер пользователя
    mov 	al, bl
    call	BYTE_TO_HEX
    lea		di, UserSN
    add		di, 20
    mov 	[di], ax
    mov 	ax, cx
    lea		di, UserSN
    add		di, 25
    call	WRD_TO_HEX

    ; выводим все определённые данные
    lea		dx, ModifyNumber
    call	PRINT_STRING
    lea		dx, Oem_Code
    call 	PRINT_STRING
    lea		dx, UserSN
    call	PRINT_STRING

    ; выходим из программы
    xor		al, al
    mov 	ah, 4ch
    int		21h

    ret
CODE 	    ENDS
    END  	Main