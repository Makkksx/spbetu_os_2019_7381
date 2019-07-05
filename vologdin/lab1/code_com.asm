TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ÑÄççõÖ
OSTYPE db 'OS type: $'
OSTYPENOTDEF db 'not defined: $'
OSVER db 'OS version:   .  ',0DH,0AH,'$'
STR_OEM db 'OEM:    ',0DH,0AH,'$' ; additional 3 bytes for digits
SER_NUM db 'User serial number: ','$'
STR_HEX db '    $'
ENDL db 0DH,0AH,'$'

PC db 'PC',0DH,0AH,'$'
PCXT db 'PC/XT',0DH,0AH,'$'
STR_AT db 'AT',0DH,0AH,'$'
STR_PS2_30 db 'PS2 model 30',0DH,0AH,'$'
STR_PS2_80 db 'PS2 model 80',0DH,0AH,'$'
STR_PCjr db 'PCjr',0DH,0AH,'$'
STR_PC_Cnv db 'PC Convertible',0DH,0AH,'$'

PRINT PROC near
	mov AH,09h
	int 21h
	ret
PRINT ENDP
	
CHECK_OS_TYPE PROC near
	mov dx, OFFSET OSTYPE
	call PRINT
	mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh
	
	cmp al,0FFh
	je PC_
	cmp al,0FEh
	je PCXT_
	cmp al,0FBh
	je PCXT_
	cmp al,0FCh
	je lAT
	cmp al,0FAh
	je PS2_30
	cmp al,0F8h
	je PS2_80
	cmp al,0FDh
	je PCjr
	cmp al,0F9h
	je PC_Cnv
	jmp cot_err
	
	PC_:
		mov dx, OFFSET PC
		jmp cot_end
	PCXT_:
		mov dx, OFFSET PCXT
		jmp cot_end
	lAT:
		mov dx, OFFSET STR_AT
		jmp cot_end
	PS2_30:
		mov dx, OFFSET STR_PS2_30
		jmp cot_end
	PS2_80:
		mov dx, OFFSET STR_PS2_80
		jmp cot_end
	PCjr:
		mov dx, OFFSET STR_PCjr
		jmp cot_end
	PC_Cnv:
		mov dx, OFFSET STR_PC_Cnv
		jmp cot_end
	
	cot_end:
	call PRINT
	ret
	
	cot_err:
	mov dx, OFFSET OSTYPENOTDEF
	call PRINT
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl,bh
	int 21h
	ret
CHECK_OS_TYPE ENDP

CHECK_OS_VERSION PROC near
	xor ax,ax
	mov ah,30h
	int 21h
	
	mov si,offset OSVER
	add si,13
	push ax
	call BYTE_TO_DEC 
	
	pop ax
	mov al,ah
	add si,3
	cmp al,10
	jl cov_one_digit_l
	inc si
	cov_one_digit_l:
	call BYTE_TO_DEC
	
	mov dx,offset OSVER 
	call PRINT
	
	mov si,offset STR_OEM
	add si,7
	mov al,bh
	call BYTE_TO_DEC
	
	mov dx,offset STR_OEM
	call PRINT
	
	mov dx,offset SER_NUM
	call PRINT
	
	mov  al,bl
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl,bh
	int 21h
	
	mov di,offset STR_HEX
	add di,3
	mov ax,cx
	call WRD_TO_HEX
	mov dx,offset STR_HEX
	call PRINT
	
	mov dx,offset ENDL
	call PRINT
	
	ret
CHECK_OS_VERSION ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

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

BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

BEGIN:
	call CHECK_OS_TYPE
	call CHECK_OS_VERSION
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START