
ASTACK	SEGMENT STACK
	DW 64 DUP(?)
ASTACK	ENDS

DATA	SEGMENT

	M_INT_NOT_SET	db "Resident wasn't loaded", 0dh, 0ah, '$'
	M_INT_RESTORED	db "Unloading resident", 0dh, 0ah, '$'
	M_INT_ISLOADED	db "Resident has been loaded already", 0dh, 0ah, '$'
	M_INT_ISLOADING	db "Loading resident", 0dh, 0ah, '$'
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:CODE, DS:DATA, SS:ASTACK
ROUT	PROC FAR
	jmp 	START_FUNC

	PSP_ADDR_0	dw 0
	PSP_ADDR_1	dw 0
	KEEP_CS	dw 0
	KEEP_IP	dw 0
	AINTERRUPT_SET	dw 0FEDCh

	SCAN_CODE	db 2h, 3h, 4h, 5h, 6h, 7h, 8h, 9h, 0Ah, 0Bh, 82h, 83h, 84h, 85h, 86h, 87h, 88h, 89h, 8Ah, 8Bh, 00
	NEWTABLE	db '  abcdefghij'

	SS_KEEP	dw 0
	SP_KEEP	dw 0
	AX_KEEP	dw 0
	AINTERRUPT_STACK	dw 64 dup (?)
	stack_top	dw 0

START_FUNC:
	mov 	SS_KEEP, ss
	mov 	SP_KEEP, sp
	mov 	AX_KEEP, ax
	mov 	ax, seg AINTERRUPT_STACK
	mov 	ss, ax
	mov 	sp, offset stack_top
	mov 	ax, AX_KEEP
	push	bx
	push	cx
	push	dx
	push	ax
	sub 	ax,ax

	in  	al, 60h
	push	ds
	push	ax
	mov 	ax, SEG SCAN_CODE
	mov 	ds, ax
	pop 	ax
	mov 	dx, offset SCAN_CODE
	push	bx
	push	cx
	mov 	bx, dx
	sub 	ah, ah
compare:
	mov 	cl, byte ptr [bx]
	cmp 	cl, 0h
	je  	end_compare
	cmp 	al, cl
	jne 	not_equal
	mov 	ah, 01h
not_equal:
	inc 	bx
	jmp 	compare
end_compare:
	pop 	cx
	pop 	bx
	pop 	ds
	cmp 	ah, 01h
	je  	process
	jmp 	skip

skip:
	pop 	ax
	mov 	ss, SS_KEEP
	mov 	sp, SP_KEEP
	pushf
	push	KEEP_CS
	push	KEEP_IP
	iret
process:
	push	bx
	push	cx
	push	dx

	cmp 	al,80h
	ja  	continue

	push	es
	push	ds
	push	ax

	mov 	ax, seg NEWTABLE
	mov 	ds, ax
	mov 	bx, offset NEWTABLE
	pop 	ax

	xlatb
	pop 	ds
write_to_buffer:
	mov 	ah, 05h
	mov 	cl, al
	sub 	ch, ch
	int 	16h
	or  	al, al
	jnz 	cleaning
	pop 	es
continue:
	jmp 	@ret
cleaning:
	push	ax
	mov 	ax, 40h
	mov 	es, ax
	mov 	word ptr es:[1Ah], 001Eh
	mov 	word ptr es:[1Ch], 001Eh
	pop 	ax
jmp write_to_buffer
	@ret:
	in  	al, 61h
	mov 	ah, al
	or  	al, 80h
	out 	61h, al
	xchg	ah, al
	out 	61h, al
	mov 	al, 20h
	out 	20h, al

	pop 	dx
	pop 	cx
	pop 	bx

	mov 	ax, SS_KEEP
	mov 	ss, ax
	mov 	ax, AX_KEEP
	mov 	sp, SP_KEEP

	iret
ROUT	ENDP

IS_INTERRUPTION_SET	PROC NEAR
	push	bx
	push	dx
	push	es

	mov 	ah, 35h
	mov 	al, 09h
	int 	21h

	mov 	dx, es:[bx + 11]
	cmp 	dx, 0FEDCh
	je  	INT_IS_SET
	mov 	al, 00h
	jmp 	POP_REG

INT_IS_SET:
	mov 	al, 01h
	jmp 	POP_REG

POP_REG:
	pop 	es
	pop 	dx
	pop 	bx

	ret
IS_INTERRUPTION_SET	ENDP

CHECK_COMMAND_PROMT	PROC NEAR
	push	es

	mov 	ax, PSP_ADDR_0
	mov 	es, ax

	mov 	bx, 0082h

	mov 	al, es:[bx]
	inc 	bx
	cmp 	al, '/'
	jne 	NULL_CMD

	mov 	al, es:[bx]
	inc 	bx
	cmp 	al, 'u'
	jne 	NULL_CMD

	mov 	al, es:[bx]
	inc 	bx
	cmp 	al, 'n'
	jne 	NULL_CMD

	mov 	al, 0001h
NULL_CMD:
	pop 	es

	ret
CHECK_COMMAND_PROMT	ENDP

LOAD_INTERRUPTION	PROC NEAR
	push	ax
	push	bx
	push	dx
	push	es

	mov 	ah, 35h
	mov 	al, 09h
	int 	21h

	mov 	KEEP_IP, bx
	mov 	KEEP_CS, es

	push	ds
	mov 	dx, offset ROUT
	mov 	ax, seg ROUT
	mov 	ds, ax

	mov 	ah, 25h
	mov 	al, 09h
	int 	21h
	pop 	ds

	mov 	dx, offset M_INT_ISLOADING
	call	PRINT_STRING

	pop 	es
	pop 	dx
	pop 	bx
	pop 	ax

	ret
LOAD_INTERRUPTION	ENDP

UNLOAD_INTERRUPTION	PROC NEAR
	push	ax
	push	bx
	push	dx
	push	es

	mov 	ah, 35h
	mov 	al, 09h
	int 	21h

	cli
	push	ds
	mov 	dx, es:[bx + 9]
	mov 	ax, es:[bx + 7]

	mov 	ds, ax
	mov 	ah, 25h
	mov 	al, 09h
	int 	21h
	pop 	ds
	sti

	mov 	dx, offset M_INT_RESTORED
	call	PRINT_STRING

	push	es
	mov 	cx, es:[bx + 3]
	mov 	es, cx
	mov 	ah, 49h
	int 	21h
	pop 	es

	mov		cx, es:[bx + 5]
	mov 	es, cx
	int 	21h

	pop		es
	pop 	dx
	pop 	bx
	pop 	ax

	ret
UNLOAD_INTERRUPTION	ENDP

PRINT_STRING	PROC NEAR
	push	ax
	mov 	ah, 09h
	int		21h
	pop 	ax
	ret
PRINT_STRING	ENDP

MAIN_PROGRAM	PROC FAR
	mov 	bx, 02Ch
	mov 	ax, [bx]
	mov 	PSP_ADDR_1, ax
	mov 	PSP_ADDR_0, ds
	sub 	ax, ax
	xor 	bx, bx

	mov 	ax, DATA
	mov 	ds, ax

	call	CHECK_COMMAND_PROMT
	cmp 	al, 01h
	je  	UNLOAD_START

	call	IS_INTERRUPTION_SET
	cmp 	al, 01h
	jne 	INTERRUPTI0N_IS_NOT_LOADED

	mov 	dx, offset M_INT_ISLOADED
	call	PRINT_STRING
	jmp 	EXIT_PROGRAM

	mov 	ah,4Ch
	int 	21h

INTERRUPTI0N_IS_NOT_LOADED:
	call	LOAD_INTERRUPTION

	mov 	ax, 3100h
	int 	21h

UNLOAD_START:
	call	IS_INTERRUPTION_SET
	cmp 	al, 00h
	je  	INT_IS_NOT_SET
	call	UNLOAD_INTERRUPTION
	jmp 	EXIT_PROGRAM

INT_IS_NOT_SET:
	mov 	dx, offset M_INT_NOT_SET
	call	PRINT_STRING
	jmp 	EXIT_PROGRAM

EXIT_PROGRAM:
	mov 	ah, 4Ch
	int 	21h
MAIN_PROGRAM	ENDP
;------------------------------------
CODE	ENDS
	END	MAIN_PROGRAM
