TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG	100H

START: JMP BEGIN

; ________________________________________
; Данные

PC_type db 'PC type: $'
PCtype_PC db 'PC',0DH,0AH,'$'
PCtype_PCXT db 'PC/XT',0DH,0AH,'$'
PCtype_AT db 'AT',0DH,0AH,'$'
PCtype_PS2_30 db 'PS2 model 30',0DH,0AH,'$'
PCtype_PS2_50_or_60 db 'PS2 model 50 or 60',0DH,0AH,'$'
PCtype_PS2_80 db 'PS2 model 80',0DH,0AH,'$'
PCtype_PCjr db 'PCjr',0DH,0AH,'$'
PCtype_PC_Convertible db 'PC Convertible',0DH,0AH,'$'

System_version db 'System version:  . ',0DH,0AH,'$'
OEM db 'OEM:   ',0DH,0AH,'$'
Serial_number db 'Serial number:       ',0DH,0AH,'$'


; ________________________________________
; Процедуры

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шестн. числа в AX 
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
; перевод в 16 с/c 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
; перевод в 10с/с, SI - адрес поля младшей цифры
    push AX
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
	pop AX
	ret
BYTE_TO_DEC ENDP

PrintMsg PROC near
	mov AH,09h
	int 21h
	ret
PrintMsg ENDP


PRINT_PC_TYPE PROC near
    push ax
	lea dx,PC_type
	call PrintMsg
    mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh

	cmp al,0FFh
	je PC_metka
	cmp al,0FEh
	je PCXT_metka
	cmp al,0FBh
	je PCXT_metka
	cmp al,0FCh
	je AT_metka
	cmp al,0FAh
	je PS2_30_metka
	cmp al,0FCh
	je PS2_50_or_60_metka
	cmp al,0F8h
	je PS2_80_metka
	cmp al,0FDh
	je PCjr_metka
	cmp al,0F9h
	je PC_Convertible_metka

	PC_metka:
		lea dx,PCtype_PC
		jmp end_of_print_PC_type
	PCXT_metka:
		lea dx,PCtype_PCXT
		jmp end_of_print_PC_type
	AT_metka:
		lea dx,PCtype_AT
		jmp end_of_print_PC_type
	PS2_30_metka:
		lea dx,PCtype_PS2_30
		jmp end_of_print_PC_type
	PS2_50_or_60_metka:
		lea dx,PCtype_PS2_50_or_60
		jmp end_of_print_PC_type
	PS2_80_metka:
		lea dx,PCtype_PS2_80
		jmp end_of_print_PC_type
	PCjr_metka:
		lea dx,PCtype_PCjr
		jmp end_of_print_PC_type
	PC_Convertible_metka:
		lea dx,PCtype_PC_Convertible
		jmp end_of_print_PC_type

	end_of_print_PC_type:
	call PrintMsg
	pop ax
	ret
PRINT_PC_TYPE ENDP


PRINT_SYSTEM_VERSION PROC near
	mov ah,30h
	int 21h

    ; System version
    
	lea dx,System_version
	mov si,dx
	add si,16
	call BYTE_TO_DEC
	add si,3
	mov al,ah
	call BYTE_TO_DEC
	call PrintMsg


    ; OEM

	lea dx,OEM
	mov si,dx
	add si,7
	mov al,bh
	call BYTE_TO_DEC
	call PrintMsg


    ; Serial number
    
	lea dx,Serial_number
	mov di,dx
	mov al,bl
	call BYTE_TO_HEX
	add di,15
	mov [di],ax
	mov ax,cx
	mov di,dx
	add di,20
	call WRD_TO_HEX
	call PrintMsg

	ret
PRINT_SYSTEM_VERSION ENDP

; ________________________________________
; Код

BEGIN:
    call PRINT_PC_TYPE
	call PRINT_SYSTEM_VERSION
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
    END START
