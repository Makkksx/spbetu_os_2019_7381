ASSUME CS:OSEG,DS:OSEG
	
OSEG segment
	push ds
	mov ax,cs
	mov ds,ax
	mov di, offset str_output_2+3
	call WRD_TO_HEX
	mov dx, offset str_output_1
	mov ax, 0900h
	int 21h
	pop ds
	retf

	str_output_1 	DB 'The SECOND overlay segment address: '
	str_output_2 	DB '     ', 0DH, 0AH, 0DH, 0AH,'$'


BYTE_TO_HEX proc near
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

TETR_TO_HEX proc near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:
	add AL,30h
	ret
TETR_TO_HEX ENDP


WRD_TO_HEX proc near
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

OSEG ENDS
END