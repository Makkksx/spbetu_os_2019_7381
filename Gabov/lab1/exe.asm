.MODEL SMALL
.STACK 200h
.DATA

;������
IBMType 			db  'IMB PC type:        ', '$' ;��� PC � �������� ������ 
VersionOfPC			db	'Version of PC:	     .   ', 0dh, 0ah,'$' ;����� �������� ������ �������
OEMSerialNumber		db	'OEM serial number:       ', 0dh, 0ah, '$' ;�������� ����� OEM 
UserSerialNumber 	db	'User serial number:        ', 0dh, 0ah, '$' ;�������� ����� ������������

;������� ������������ ���� � ���� IBM PC
TypePC 				db 'PC', 0dh, 0ah,'$'
TypePCXT 			db 'PC/XT', 0dh, 0ah,'$'
TypeAT 				db 'AT', 0dh, 0ah,'$'
TypePS2_30 			db 'PS2 model 30', 0dh, 0ah,'$'
TypePS2_50_60 		db 'PS2 model 50 or 60', 0dh, 0ah,'$'
TypePS2_80 			db 'PS2 model 80', 0dh, 0ah,'$'
TypePCjr 			db 'PCjr', 0dh, 0ah,'$'
TypePC_Convertible 	db 'PC Convertible', 0dh, 0ah,'$'

.CODE
START: JMP	BEGIN
;���������
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;�������� ���� AL ����������� � ������ ������������������ ����� � AL
		and		al, 0Fh ;and 00001111 - ��������� ������ ������ �������� al
		cmp		al, 09 ;���� ������ 9, �� ���� ���������� � �����
		jbe		NEXT ;��������� �������� �������, ���� ������ ������� ������ ��� ����� ������� ��������
		add		al, 07 ;��������� ��� �� �����
	NEXT:	add		al, 30h ;16-������ ��� ����� ��� ����� � al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;���� AL ����������� � ��� ������� ������������������ ����� � AX
		push	cx
		mov		ah, al ;�������� al � ah
		call	TETR_TO_HEX ;��������� al � ������ 16-���.
		xchg	al, ah ;������ ������� al �  ah
		mov		cl, 4 
		shr		al, cl ;c���� ���� ����� al ������ �� 4
		call	TETR_TO_HEX ;��������� al � ������ 16-���.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near ;������� AX ����������� � ����������������� �������, DI - ����� ���������� �������
		push	bx
		mov		bh, ah ;�������� ah � bh, �.�. ah ���������� ��� ��������
		call	BYTE_TO_HEX ;��������� al � ��� ������� ������������������ ����� � AX
		mov		[di], ah ;��������� ����������� �������� ah �� ������, �������� � �������� DI
		dec		di 
		mov		[di], al ;��������� ����������� �������� al �� ������, �������� � �������� DI
		dec		di
		mov		al, bh ;�������� bh � al, ��������������� �������� ah
		xor		ah, ah ;������� ah
		call	BYTE_TO_HEX ;��������� al � ��� ������� ������������������ ����� � AX
		mov		[di], ah ;��������� ����������� �������� al �� ������, �������� � �������� DI
		dec		di
		mov		[di], al ;��������� ����������� �������� al �� ������, �������� � �������� DI
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_DEC		PROC	near ;���� AL ����������� � ���������� �������, SI - ����� ���� ������� �����
		push	cx
		push	dx
		push	ax
		xor		ah, ah ;������� ah
		xor		dx, dx ;������� dx
		mov		cx, 10 
	loop_bd:div		cx ;����� ax �� 10
		or 		dl, 30h ;���������� ��� 00110000
		mov 	[si], dl ;��������� ����������� �������� dl �� ������, �������� � �������� si
		dec 	si
		xor		dx, dx ;������� dx
		cmp		ax, 10 ;���������� ���������� ax � 10
		jae		loop_bd ;�������, ���� ������ ��� ����� 10
		cmp		ax, 00h ;���������� ax � 0
		jbe		end_l ;�������, ���� ������ ��� ����� 0
		or		al, 30h ;���������� ��� 00110000
		mov		[si], al ;��������� ����������� �������� dl �� ������, �������� � �������� si
	end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP	
;--------------------------------------------------------------------------------
;��������� ��� ����������� ������
;--------------------------------------------------------------------------------
FindIBMType  PROC NEAR ;����������� ���� PC
	push es
	mov ax, 0F000h		
	mov es, ax			
	sub bx, bx
	mov bh, es:[0FFFEh]
	pop es
	ret
FindIBMType ENDP
;--------------------------------------------------------------------------------
FindVersion PROC NEAR ;AL � ����� �������� ������. ���� 0, �� <2.0;
	push ax					
	push si					
	mov si, offset VersionOfPC		
	add si, 13h			
	call BYTE_TO_DEC			
	pop si					
	pop ax					
	ret
FindVersion ENDP
;--------------------------------------------------------------------------------
FindModification PROC NEAR ;AH � ����� �����������;
	push ax					
	push si					
	mov si, offset VersionOfPC		
	add si, 15h	
	mov al, ah
	call BYTE_TO_DEC		
	pop si					
	pop ax					
	ret
FindModification ENDP
;--------------------------------------------------------------------------------
FindOEM PROC NEAR ;BH � �������� ����� OEM (Original Equipment Manufacturer);
	push ax					
	push bx					
	push si					
	mov si, offset OEMSerialNumber		
	add si, 16h 		
	mov al, bh
	call BYTE_TO_DEC		
	pop si					
	pop bx					
	pop ax					
	ret
FindOEM ENDP
;--------------------------------------------------------------------------------
FindUserNumber PROC NEAR ;BL:CX � 24-������� �������� ����� ������������;
	push bx					
	push cx					
	push di
	push ax	
	mov di, offset UserSerialNumber
	add di, 17h 
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	mov di, offset UserSerialNumber
	add di, 18h
	mov [di], ax
	pop ax
	pop di					
	pop cx					
	pop bx	
	ret	
FindUserNumber ENDP
;--------------------------------------------------------------------------------
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
;���
BEGIN:
	mov ax, @data
	mov ds, ax
	mov bx, ds
	
	;����������� ���� PC
	call FindIBMType
	mov dx, offset IBMType
	call PRINT

	;������� ��� �� �����
	mov dx, offset TypePC
	cmp bh, 0FFh
	je	PrintType
	
	mov dx, offset TypePCXT
	cmp bh, 0FEh
	je	PrintType
	
	mov dx, offset TypeAT
	cmp bh, 0FCh
	je	PrintType
	
	mov dx, offset TypePS2_30
	cmp bh, 0FAh
	je	PrintType

	mov dx, offset TypePS2_50_60 
	cmp bh, 0FCh
	je	PrintType
	
	mov dx, offset TypePS2_80
	cmp bh, 0F8h
	je	PrintType
	
	mov dx, offset TypePCjr
	cmp bh, 0FDh
	je	PrintType
	
	mov dx, offset TypePC_Convertible
	cmp bh, 0F9h
	je	PrintType
	
	mov al, bh
	call BYTE_TO_HEX
	mov dx, ax
	
	;����� �� ����� ���
PrintType:
	call PRINT

	;���������� ������ MS DOS
	mov ah, 30h
	int 21h
	
	;������� ��������� �������� � ������ 
	call FindVersion
	call FindModification
	call FindOEM
	call FindUserNumber
	
	;������� ���������� ��������
	mov dx, offset VersionOfPC	
	call PRINT
	mov dx, offset OEMSerialNumber
	call PRINT
	mov dx, offset UserSerialNumber
	call PRINT			
	
; ����� � DOS
	xor al, al
	mov ah, 4ch
	int 21h
	
END START	; ����� ������