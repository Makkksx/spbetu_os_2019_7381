STK segment stack 
	DB 400 dup(?)
STK ends

DATA segment
	string db 'Model of the IBM PC: ','$'
	PC	db	'PC',0DH,0AH,'$'
	PC_XT db 'PC/XT',0DH,0AH,'$'
	AT_or_PS2_50 db  'either AT or PS2 model 50\60',0DH,0AH,'$'
	PS2_30 db 'PS2 model 30',0DH,0AH,'$'
	PS2_80 db 'PS2 model 80',0DH,0AH,'$'
	PCjr   db 'PCjr',0DH,0AH,'$'
	PC_conv db 'PC convertible',0DH,0AH,'$'
	default db ' (undefined type)',0DH,0AH,'$'
	DOS_str db 'MS DOS version: ', '$'
	OEM_str db 'OEM serial: ', '$'
	ERR_MSG db 'Access to serial is not supported in your DOS.',0DH,0AH,'$'
	OS_str1 db 6 dup(?)
	OEM db 4 dup(?)
	serial_info db 'User serial-key: ', '$'
	serial db 10 dup(?)
DATA ends
;-----------------------------------------------------
TESTPC	SEGMENT
ASSUME	CS:TESTPC, DS:DATA, ES:NOTHING, SS:STK

TETR_TO_HEX	PROC	near
	and	AL,0Fh
	cmp	AL,09
	jbe	NEXT
	add	AL,07
NEXT:	
	add	AL,30h
	ret 
TETR_TO_HEX	ENDP
;-------------------------------
BYTE_TO_HEX	PROC	near 		;num stored in AL into ASCII in AX in hex
	push	CX
	mov	AH,AL
	call	TETR_TO_HEX
	xchg	AL,AH
	mov	CL,4
	shr	AL,CL
	call	TETR_TO_HEX
	pop	CX
	ret 
BYTE_TO_HEX	ENDP
;-------------------------------
BYTE_TO_DEC	PROC	near 	;num in AL into ASCII
	push	CX
	push	DX
	xor	AH,AH
	xor	DX,DX
	mov	CX,10
loop_bd:	
	div	CX
	or	DL,30h
	mov	[SI],DL
	dec	SI
	xor	DX,DX
	cmp	AX,10
	jae	loop_bd
	cmp	AL,00h
	je	end_l
	or	AL,30h
	mov	[SI],AL
end_l:	
	pop	DX
	pop	CX
	ret
BYTE_TO_DEC	ENDP
;-------------------------------

DET_TYPE PROC near
	cmp al, 0FFh
	jne cmp_1
	mov dx, offset PC
	ret
cmp_1:
	cmp al, 0FEh
	jne cmp_2
	mov dx, offset PC_XT
	ret
cmp_2:
	cmp al, 0FBh
	jne cmp_3
	mov dx, offset PC_XT
	ret
cmp_3:
	cmp al, 0FCh
	jne cmp_4
	mov dx, offset AT_or_PS2_50
	ret
cmp_4:
	cmp al, 0F9h
	jne cmp_5
	mov dx, offset PC_conv
	ret
cmp_5:
	cmp al, 0FAh
	jne cmp_6
	mov dx, offset PS2_30
	ret
cmp_6:
	cmp al, 0F8h
	jne cmp_7
	mov dx, offset PS2_80
	ret
cmp_7:
	cmp al, 0FDh
	jne undefined
	mov dx, offset PCjr
	ret
undefined:
	call BYTE_TO_HEX
	mov bh, al
	mov bl, ah
	mov dl, bh
	mov ah, 02h 		;char output
	int 21h
	mov dl, bl
	int 21h
	mov dx, offset default
	ret
DET_TYPE ENDP

DIV10 proc near
	mov cx, 10
	mov bx,ax
	xchg ax, dx
	xor dx, dx
	div cx
	xchg bx, ax
	div cx
	xchg dx, bx
	ret
DIV10 endp

DW_TO_ASCII proc near
	call DIV10
	mov si, dx
	or si, ax
	jz Done
	push bx
	call DW_TO_ASCII
	pop bx
Done:
	add bl, '0'
	mov [di], bl
	inc di
	ret
DW_TO_ASCII endp

WRITE_OS proc near
	mov si, offset OS_str1
	inc si
	call BYTE_TO_DEC
	add si, 4
	mov al, ah
	push bx
	call BYTE_TO_DEC
	pop bx
	dec si
	mov byte ptr [si], 46 			;dot
	mov byte ptr [si+3], '$'
	mov dx, offset OS_str1
	mov ah, 09h
	int 21h
	mov dl, 0Dh
	mov ah, 02h
	int 21h
	mov dl, 0Ah
	int 21h

check_a:				;in most DOS (30h, int 21h) returns 0 in bx & cx
	cmp bx, 0
	je check_b
	mov si, offset OEM
	inc si
	mov al, bh
	push bx
	call BYTE_TO_DEC
	pop bx
	mov dx, offset OEM_str
	mov ah, 09h
	int 21h
	mov si, offset OEM
	mov byte ptr [si+3], '$'
	mov dx, si
	int 21h
	mov dl, 0Dh
	mov ah, 02h
	int 21h
	mov dl, 0Ah
	int 21h

check_b:
	cmp cx, 0
	je print_err
	mov di, offset serial
	mov dl, bl
	mov ah, ch
	mov al, cl
	mov dh, 0
	call DW_TO_ASCII
	mov dx, offset serial_info
	mov ah, 09h
	int 21h 
	mov di, offset serial
	mov byte ptr [di+9], '$'
	mov dx, di	
	mov ah, 09h
	int 21h
	ret

print_err:
	mov dx, offset ERR_MSG
	mov ah, 09h
	int 21h
	ret
WRITE_OS endp

BEGIN:
	mov ax, DATA
	mov ds, ax
	mov dx, offset string
	mov ah, 09h
	int 21h

	mov ax, 0F000h
	mov es, ax
	mov di, 0FFFEh
	mov al, byte ptr es:di
	call DET_TYPE
	mov ah, 09h
	int 21h

	mov dx, offset DOS_str
	int 21h
	mov ah, 30h
	int 21h
	call WRITE_OS

	xor	al, al
	mov	ah, 4Ch
	int	21h
TESTPC	ENDS

END	BEGIN