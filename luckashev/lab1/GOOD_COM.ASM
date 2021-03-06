TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG	100H
START:	JMP	BEGIN

PC_type				db  '��� IBM PC - PC', 						0DH, 0AH, '$'
XT_type				db  '��� IBM PC - PC/XT', 					0DH, 0AH, '$'
AT_type				db  '��� IBM PC - AT', 						0DH, 0AH, '$'
PS2_30_type			db  '��� IBM PC - PS2 ������ 30', 			0DH, 0AH, '$'
PS2_50_60_type		db  '��� IBM PC - PS2 ������ 50 ��� 60', 	0DH, 0AH, '$'
PS2_80_type			db  '��� IBM PC - PS2 ������ 80', 			0DH, 0AH, '$'
PCjr_type			db  '��� IBM PC - PCjr', 					0DH, 0AH, '$'
PC_Convertible_type	db  '��� IBM PC - PC Convertible', 			0DH, 0AH, '$'

Undef_type			db	'��� IBM PC - �� ⠡����. ���: ',					'$'
MSDOS_msg			db  '����� MS DOS: ', 									'$'
OEM_msg				db  '��਩�� ����� OEM: ', 							'$'
Serial_Number_msg	db  '��਩�� ����� ���짮��⥫�: ', 					'$'

Type_code			db	'  ', 									0DH, 0AH, '$'
MSDOS_Ver			db	'       ', 								0DH, 0AH, '$'
OEM_Serial_Number	db	'   ', 									0DH, 0AH, '$'
User_Serial_Number	db	'       ',								0DH, 0AH, '$'

Zero_code			db	'< 2.0',								0DH, 0AH, '$'

; ���������
; -----------------------------------------------------
TETR_TO_HEX PROC near
			 and	al,	0fh
			 cmp	al,	09
			 jbe	NEXT
			 add	al,	07
NEXT:
			 add	al,	30h
			 ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
; ���� AL ��ॢ������ � ��� ᨬ���� ���. �᫠ � AX
			 push	cx
			 mov	ah,	al
			 call	TETR_TO_HEX
			 xchg	al,	ah
			 mov	cl,	4
			 shr	al,	cl
			 call	TETR_TO_HEX  ;� AL - �����, � AH - ������
			 pop	cx
			 ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
; ��ॢ�� � 16 �/� 16-� ࠧ�來��� �᫠
; � AX - �᫮, DI - ���� ��᫥����� ᨬ����
			 push	bx
			 mov	bh,	ah
			 call	BYTE_TO_HEX
			 mov	[di],	ah
			 dec	di
			 mov	[di],	al
			 dec	di
			 mov	al,	bh
			 call	BYTE_TO_HEX
			 mov	[di],	ah
			 dec	di
			 mov	[di],	al
			 pop	bx
			 ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
; ��ॢ�� � 10�/�, SI - ���� ���� ����襩 ����
			 push	cx
			 push	dx
			 xor	ah,	ah
			 xor	dx,	dx
			 mov	cx,	10
loop_bd:
			 div	cx
			 or 	dl,	30h
			 mov	[si],	dl
			 dec	si
			 xor	dx,	dx
			 cmp	ax,	10
			 jae	loop_bd
			 cmp	al,	00h
			 je 	end_l
			 or 	al,	30h
			 mov	[si],	al
end_l:
			 pop	dx
			 pop	cx
			 ret
BYTE_TO_DEC ENDP

PRINT_STR	PROC	near
;���⠥� ��ப� �� ����� � dx
		 mov	ah,	09h
		 int	21h		 
		 ret
PRINT_STR	ENDP

PRINT_IBM_PC_TYPE	PROC	near
		 push	ax
		 push	dx
; ��।������ ⨯� I�� PC. ��� ⨯� ��᫥ �믮������ �࠭���� � AL
		 push	ds
		 mov	ax,	0f000h
		 mov	ds,	ax
		 mov	ax,	ds: [0fffeh]
		 pop	ds
; �뢮� ⨯� � ����ᨬ��� �� ��� ����
		 cmp	al,	0ffh
		 je 	case_PC
		 cmp	al,	0feh
		 je 	case_PC_XT
		 cmp	al,	0fbh
		 je 	case_PC_XT
		 cmp	al,	0fch
		 je 	case_AT
		 cmp	al,	0fah
		 je 	case_PS2_30
		 cmp	al,	0f8h
		 je 	case_PS2_80
; ��� PS2_50_60 ᮢ������ � ����� AT. ����⭮, ����⪠ � ⠡���, ��⠢�� ��� ����
		 cmp	al,	0fch
		 je 	case_PS2_50_60
		 cmp	al,	0fdh
		 je 	case_PCjr
		 cmp	al,	0f9h
		 je 	case_PC_Convertible
; � ��砥, �᫨ ��� �� ⠡����, �뢥�� ��� � ��⭠����筮� �ଠ�
		 lea	di,	Type_code
		 call	BYTE_TO_HEX
		 mov	[di],	ax
; �뢮��� ᮮ�饭��, � ��⥬ ���⠥� ���
		 lea	dx,	Undef_type
		 mov	ah,	09h
   		 int	21h
		 lea	dx,	Type_code
		 jmp	Print

case_PC:
		 lea	dx,	PC_type
		 jmp	Print

case_PC_XT:
		 lea	dx,	XT_type
		 jmp	Print

case_AT:
		 lea	dx,	AT_type
		 jmp	Print

case_PS2_30:
		 lea	dx,	PS2_30_type
		 jmp	Print

case_PS2_50_60:
		 lea	dx,	PS2_50_60_type
		 jmp	Print

case_PS2_80:
		 lea	dx,	PS2_80_type
		 jmp	Print

case_PCjr:
		 lea	dx,	PCjr_type
		 jmp	Print

case_PC_Convertible:
		 lea	dx,	PC_Convertible_type
		 jmp	Print

Print:
		 call	PRINT_STR
		
		 pop	dx
		 pop	ax
		 ret
PRINT_IBM_PC_TYPE	ENDP

GET_MSDOS_VER	PROC	near
; al - ����� �᭮���� ���ᨨ. �᫨ 0, � < 2.0
; ah - ����� ����䨪�樨		 
		 push	dx
		 push	si
		 push	di
; ��।������ ���ᨨ MS DOS
		 lea	si,	MSDOS_Ver
; �᫨ ����� �᭮���� ����䨪�樨 ࠢ�� 0, ��ப� ࠢ�� < 2.0
		 push	ax
		 xor	ah,	ah
		 cmp	al,	ah
		 je 	Copy_zero
; ���� ᮧ���� ��ப� xx.yy
		 pop	ax
		 mov	dx,	'0'
		 mov	[si],	dx
		 inc	si
		 push	ax
		 call	BYTE_TO_DEC
		 pop	ax
		 lea	si,	MSDOS_Ver
		 add	si,	2
		 mov	dx,	'.'
		 mov	[si],	dx
		 inc	si
		 mov	dx,	'0'
		 mov	[si],	dx
		 inc	si
		 mov	al,	ah
		 call	BYTE_TO_DEC
		 jmp	RETURN
		 
Copy_zero:
		 pop	ax
		 lea	si,	Zero_code
		 lea	di,	MSDOS_Ver
		 push	cx
		 xor	cx,	cx
		 mov	cx,	5
		 rep	movsb
		 pop	cx
		 
RETURN:
		 pop	di
		 pop	si
		 pop	dx
		 ret
GET_MSDOS_VER	ENDP

GET_OEM	PROC	near
		 push	si
		 push	ax
; bh - �਩�� ����� OEM
		 lea	si,	OEM_Serial_Number
		 add	si,	2
		 mov	al,	bh
		 call	BYTE_TO_DEC
		 
		 pop	ax
		 pop	si
		 ret
GET_OEM	ENDP

GET_USER_SERIAL	PROC	near
		 push	di
		 push	ax
; bl:cx - 24-��⮢� �਩�� ����� ���짮��⥫�
		 lea	di,	User_Serial_Number
		 mov	al,	bl
		 call	BYTE_TO_HEX
		 mov	[di],	ax
		 
		 add	di,	5
		 mov	ax,	cx
		 call	WRD_TO_HEX

		 pop	ax
		 pop	di
		 ret
GET_USER_SERIAL	ENDP

; -------------------------------
; ���
BEGIN:
		 call	PRINT_IBM_PC_TYPE
		 
		 mov	ah, 30h
		 int	21h	
		 
		 call	GET_MSDOS_VER
		 call	GET_OEM
		 call	GET_USER_SERIAL

		 lea	dx, MSDOS_msg
		 call	PRINT_STR
		 lea	dx,	MSDOS_Ver
		 call	PRINT_STR	 
		 lea	dx, OEM_msg
		 call	PRINT_STR
		 lea	dx,	OEM_Serial_Number
		 call	PRINT_STR
		 lea	dx,	Serial_Number_msg
		 call	PRINT_STR
		 lea	dx,	User_Serial_Number
		 call	PRINT_STR
		 
	   	 mov	al,	0
	   	 mov	ah,	4ch
	   	 int	21h
TESTPC	 ENDS
		 END	START
