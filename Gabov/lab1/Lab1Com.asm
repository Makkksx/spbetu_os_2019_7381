TESTPC	SEGMENT
ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING 
ORG	100H
START:	JMP	BEGIN

PC_TYPE db ' type is:  ', '$'
PC db 'PC', 0dh, 0ah, '$'
PCXT db 'PC/XT', 0dh, 0ah, '$'
AT db 'AT', 0dh, 0ah, '$'
Ps2_30 db 'Ps2_30', 0dh, 0ah, '$'
Ps2_50_60 db 'Ps2_50_60', 0dh, 0ah, '$'
Ps2_80 db 'ps2_80', 0dh, 0ah, '$'
PCjr db 'PCjr', 0dh, 0ah, '$'
PC_Convertible db 'PC Conventible', 0dh, 0ah, '$'
V_NUMBER db 'VERSION NUMBER:               ', 0dh, 0ah, '$'
M_NUMBER db 'MODIFICATION NUMBER:          ', 0dh, 0ah, '$'
S_NUMBER db 'SERIES NUMBER:                ', 0dh, 0ah, '$'
USER_NUMBER db 'USER NUMBER:               ', 0dh, 0ah, '$'
DEFAULT db 'DONT EQUAL ANYONE              ', 0dh, 0ah, '$'


PRINT PROC NEAR ; print by offset which contain in dx
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

TETR_TO_HEX	PROC	near ; only half part of al convert to ASII
	and	AL,0Fh
	cmp	AL,09
	jbe	NEXT
	add	AL,07
NEXT:	
	add	AL,30h
	ret 
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC	near ; al convert to ASII		
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

BYTE_TO_DEC	PROC	near 	
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


DEFINE_PCTYPE PROC NEAR
	push es
	mov bx, 0F000h
	mov es, bx
	sub bx, bx
	mov bh, es:[0FFFEh] ; bh contain type of PC
	pop es
	ret	
DEFINE_PCTYPE ENDP


DefineVersion PROC NEAR ;AL
	push ax					
	push si					
	mov si, offset V_NUMBER		
	add si, 10h			
	call BYTE_TO_DEC			
	pop si					
	pop ax					
	ret
DefineVersion ENDP

DefineModification PROC NEAR ;AH
	push ax					
	push si					
	mov si, offset M_NUMBER		
	add si, 17h	
	mov al, ah
	call BYTE_TO_DEC		
	pop si					
	pop ax					
	ret
DefineModification ENDP

DefineOEM PROC NEAR ;BH
	push ax					
	push bx					
	push si					
	mov si, offset S_NUMBER		
	add si, 11h 		
	mov al, bh
	call BYTE_TO_DEC		
	pop si					
	pop bx					
	pop ax					
	ret
DefineOEM ENDP

DefineUNumber PROC NEAR ;BL:CX
	push bx					
	push cx					
	push di	
	push ax	
	mov si, offset USER_NUMBER
	add si, 13 
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	mov si, offset USER_NUMBER
	add si, 14
	mov [si], ax	
	pop ax
	pop di					
	pop cx					
	pop bx		
	ret
DefineUNumber ENDP

BEGIN:
	call DEFINE_PCTYPE
	push dx
	mov dx, offset PC_TYPE
	call PRINT
	pop dx

	mov dx, offset PC
	cmp bh, 0FFh
	je	PrintType
	
	mov dx, offset PCXT
	cmp bh, 0FEh
	je	PrintType
	
	mov dx, offset AT
	cmp bh, 0FCh
	je	PrintType
	
	mov dx, offset Ps2_30
	cmp bh, 0FAh
	je	PrintType

	mov dx, offset Ps2_50_60 
	cmp bh, 0FCh
	je	PrintType
	
	mov dx, offset Ps2_80
	cmp bh, 0F8h
	je	PrintType
	
	mov dx, offset PCjr
	cmp bh, 0FDh
	je	PrintType
	
	mov dx, offset PC_Convertible
	cmp bh, 0F9h
	je	PrintType
	
	mov al, bh
	call BYTE_TO_HEX 
	mov dx, offset DEFAULT

PrintType:
	call PRINT	
	call DefineVersion
	call DefineModification
	call DefineOEM
	call DefineUNumber
	
	mov dx, offset V_NUMBER	
	call PRINT
	mov dx, offset M_NUMBER	
	call PRINT
	mov dx, offset S_NUMBER
	call PRINT
	mov dx, offset USER_NUMBER
	call PRINT

	xor	al, al
	mov	ah, 4Ch
	int	21h
TESTPC	ENDS

END	START