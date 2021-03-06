CODE	SEGMENT
	ASSUME	CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	ORG	100H

START:	jmp	BEGIN

;�����

INACCESS_MEM_MSG	db '�������� ���� ������㯭�� �����: $'
ENV_SEG_ADR_MSG	db '�������� ���� �।�: $'
COM_PROMPT_TAIL_MSG	db '����� �������� ��ப�: $'
ENV_CONTENTS_MSG	db '����ন��� ������ �।�: $'
MOD_PATH_MSG	db '���� ����㦠����� �����: $'
no_tail_msg 	db '�� ������$'
endl	db 0DH, 0AH, '$'

inaccesable_mem	db 5 dup (?), '$'
environment_adr	db 5 dup (?), '$'
;��楤���

;�뢮� ��ப�
output	PROC near
	push 	ax
	mov 	ah,	09h
	int 	21h
	pop 	ax
	ret
output	ENDP

;-------------------------------------------------------------------------


;-------------------------------------------------------------------------
;��ॢ��  � 16-��� ��⥬�
TETR_TO_HEX	PROC near
	and	 al,0Fh
	cmp	 al,09h
	jbe	 next
	add	 al,07h
next:
	add	 al,30h
	ret
TETR_TO_HEX	ENDP

;-------------------------------------------------------------------------
;��室��� �᫮ ��室���� � AL
;������� - ��� ᨬ���� 16-��� �᫠ � AX
BYTE_TO_HEX	PROC near
	push cx
	mov	 ah,al
	call TETR_TO_HEX
	xchg al,ah
	mov	 cl,04h
	shr	 al,cl
	call TETR_TO_HEX
	pop	 cx
	ret
BYTE_TO_HEX	ENDP

;-------------------------------------------------------------------------
;��ॢ��  � 16-��� ��⥬� 16-� ࠧ�來��� �᫠
;��室��� �᫮ ��室���� � ॣ���� AX
;DI - ���� ��᫥����� ᨬ����
WRD_TO_HEX PROC	near
	push	bx
	mov	bh,ah
	call	BYTE_TO_HEX
	mov	[di],ah
	dec	di
	mov	[di],al
	dec	di
	mov	al,bh
	call	BYTE_TO_HEX
	mov	[di],ah
	dec	di
	mov	[di],al
	pop	bx
	ret
WRD_TO_HEX	ENDP

;����祭�� ᥣ���⭮�� ���� ��ࢮ�� ���� ������㯭�� �����
Inaccessible_memory_adress	PROC near
	lea 	dx, INACCESS_MEM_MSG
	call 	output
	mov 	ax,	ds:[2]
	lea 	di,	inaccesable_mem
	add 	di, 3
	call 	WRD_TO_HEX
	lea 	dx,	inaccesable_mem
	call 	output
	lea 	dx,	endl
	call 	output
	ret
Inaccessible_memory_adress	ENDP

  ;����祭�� ᥣ���⭮�� ���� �।�, ��।������� �ணࠬ��
Environment_adress	PROC near
	lea 	dx,	ENV_SEG_ADR_MSG
	call 	output
	mov 	ax,	ds:[02Ch]	
	lea 	di,	environment_adr
	add 	di,	3
	call 	WRD_TO_HEX
	lea 	dx,	environment_adr
	call 	output
	lea 	dx,	endl
	call 	output
	ret
Environment_adress	ENDP

 ;����祭�� 墮�� ��������� ��ப�
Print_command_prompt_tail	PROC near
	lea 	dx,	COM_PROMPT_TAIL_MSG
	call 	output
	xor 	cx,	cx	
	mov 	cl,	ds:[080h]
	mov 	si,	081h
	mov 	ah,	02h
	cmp 	cx, 0
	je  	no_tail
cycle:
	cmp 	cx,	0
	jz  	end_loop
	mov 	dl, ds:[si]
	int 	21h
	add 	si, 1
	dec 	cx	
loop	cycle
no_tail:
	lea 	dx, no_tail_msg
	call 	output
end_loop:
	lea 	dx,	endl
	call 	output
	ret
Print_command_prompt_tail	ENDP

;�����祭�� ᮤ�ন���� ������ �।�
Print_environment_and_path	PROC near
	lea 	dx,	ENV_CONTENTS_MSG
	call 	output
	lea 	dx,	endl
	call 	output
	
	mov 	es,	es:[02Ch]

	xor 	si,	si
	
main_cycle:
	cmp 	word ptr es:[si],	0000h
	je  	end_env
	cmp 	byte ptr es:[si],	00h
	jne 	no_endl
	lea 	dx, endl
	call 	output
	inc 	si
no_endl:
	mov 	dl,	es:[si]
	mov 	ah,	02h
	int 	21h
	inc 	si
loop	main_cycle

end_env:
	lea 	dx,	endl
	call 	output
	
	lea 	dx,	MOD_PATH_MSG
	call	output
	add 	si, 4
	
path_cycle:
	cmp 	byte ptr es:[si],	00h
	je  	end_path_cycle
	mov 	dl,	es:[si]
	mov 	ah,	02h
	int 	21h
	inc 	si
loop 	path_cycle

end_path_cycle:
	ret
Print_environment_and_path ENDP

; ���
BEGIN:
	call 	Inaccessible_memory_adress
	call 	Environment_adress
	call 	Print_command_prompt_tail
	call 	Print_environment_and_path
	lea 	dx,	endl
	call 	output
	xor 	al, al
	mov 	ah,01h
	int 	21h
	mov 	ah,	4Ch
	int 	21h
CODE	ENDS
	END	START
