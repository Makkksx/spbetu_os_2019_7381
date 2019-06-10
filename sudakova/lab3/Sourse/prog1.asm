TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: JMP BEGIN  
AVAILABLE_STRING 	db 'Available memory (Bytes):$'
EXTENDED_STRING 	db 'Extended memory (KBytes):$'
CHAIN_STRING	db 'Chain of MCB:$'
TYPE_MCB		db 'Type MCB: 0000h$'
OWNER 		db 'Owner: 0000h$'
SIZE_SPACE 	db 'Size: $'
BYTE8	db '8byte: $'
EMPTY_SPACE	db '          $'
SPACE 		db ' $'
BYTES 		db ' b$'
KBYTES 		db ' Kb$'
nl		    db 13, 10, '$'
;-----------------------------------------
WRITE	PROC near
		call AVAILABLE_M  
		call EXTENDED_M 
		call PRINT_MCB
		ret		
WRITE 	ENDP
;-----------------------------------------
PRINT 	PROC NEAR
    	push ax
    	push dx
    	mov ah, 09h
    	int 21h
    	pop dx
    	pop ax
    	ret
PRINT 	ENDP
;-----------------------------------------  
END_LINE 	PROC NEAR
    	lea dx, nl
    	call PRINT
    	ret
END_LINE 	ENDP
;-----------------------------------------
FREE_M	PROC NEAR
		cld
		lea di, EMPTY_SPACE
		mov cx, 9
		sub al, al		
		rep stosb 		
		mov dx, 0
		ret	
FREE_M  	ENDP
;-----------------------------------------
TETR_TO_HEX		PROC	near
    	and	AL, 0Fh	
		cmp	AL, 09	
		jbe	NEXT	
		add	AL,07	
NEXT:	add	AL,30h	
		ret		
TETR_TO_HEX	ENDP		
;-----------------------------------------	
BYTE_TO_HEX	PROC	near	
; байт в AL переводится в два символа шестн. числа в AX
		push CX	
		mov	AH, AL	
		call TETR_TO_HEX	
		xchg AL, AH	
		mov	CL, 4	
		shr	AL, CL	
		call TETR_TO_HEX ;в AL старшая цифра
		pop	CX           ;в AH младшая
		ret		
BYTE_TO_HEX  ENDP		
;-----------------------------------------	
WRD_TO_HEX	PROC	near	
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
		push BX
		mov	BH, AH
		call BYTE_TO_HEX
		mov	[DI], AH
		dec	DI
		mov	[DI], AL
		dec	DI
		mov	AL, BH
		call BYTE_TO_HEX
		mov	[DI], AH
		dec	DI
		mov	[DI], AL
		pop	BX
		ret	
WRD_TO_HEX ENDP	
;-----------------------------------------		
BYTE_TO_DEC	PROC	near
		push CX
		push DX
		xor	AH, AH
		xor	DX, DX
		mov	CX, 10
loop_bd:div	CX
		or DL, 30h
		mov	[SI], DL
		dec	SI
		xor	DX, DX
		cmp	AX, 10
		jae	loop_bd
		cmp	AL, 00h
		je end_l
		or AL,30h
		mov	[SI], AL
end_l:	pop	DX
		pop	CX
		ret	
BYTE_TO_DEC	ENDP	
;-----------------------------------------
WRD_TO_DEC	PROC near	
  		push cx
    	push dx
    	mov  cx, 10
wloop:   
	    div cx
	    or  dl, 30h
	    mov [si], dl
	    dec si
		xor dx, dx
    	cmp ax, 10
    	jae wloop
    	cmp al, 00h
    	je wend
    	or al, 30h
    	mov [si], al
wend:      
    	pop dx
    	pop cx
    	ret	
WRD_TO_DEC 	ENDP
;-----------------------------------------
AVAILABLE_M PROC NEAR
		xor	dx,dx
		lea dx, AVAILABLE_STRING
		call PRINT
    	mov ah, 4Ah
    	mov bx, 0ffffh
    	int 21h
		xor	dx, dx
    	mov ax, bx
    	mov cx, 10h
    	mul cx
		lea	si, EMPTY_SPACE + 9
    	call WRD_TO_DEC
		lea dx, EMPTY_SPACE 
		call PRINT 
		call FREE_M
		lea dx, BYTES
		call PRINT 
    	call END_LINE
		ret
AVAILABLE_M ENDP
;-----------------------------------------
EXTENDED_M PROC NEAR
		lea dx, EXTENDED_STRING
		call PRINT
		mov AL, 30h 
		out 70h, AL
		in 	AL, 71h
		mov BL, AL 
		mov AL, 31h 
		out 70h, AL
		in AL, 71h
	    mov ah, al
		mov al, bl
		call FREE_M
		lea	si, EMPTY_SPACE + 9
		call WRD_TO_DEC
		lea	dx, EMPTY_SPACE
		call PRINT
		call FREE_M
		lea dx, KBYTES
		call PRINT
		call END_LINE
		ret
EXTENDED_M ENDP
;-----------------------------------------
PRINT_MCB PROC near
	    lea dx, CHAIN_STRING
    	call PRINT
    	call END_LINE
       	mov ah, 52h
    	int 21h
    	mov ax, es:[bx-2]
    	mov es, ax
@NextBlock:  
		mov al, es:[0000h]
	    call BYTE_TO_HEX
	    lea di, TYPE_MCB+ 12
	    mov [di], ax
	    lea dx, TYPE_MCB
	    call PRINT
	    lea dx, SPACE
	    call PRINT

    	mov ax, es:[0001h]
    	lea di, OWNER + 10
    	call WRD_TO_HEX
       	lea dx, OWNER
    	call PRINT
    	lea dx, SPACE
    	call PRINT

    	lea dx, SIZE_SPACE
    	call PRINT
       	mov ax, es:[0003h]
    	mov cx, 10h 
    	mul cx
	 	lea si, EMPTY_SPACE + 9
    	call WRD_TO_DEC
       	lea dx, EMPTY_SPACE
    	call PRINT
		push di
		push ax
		lea di, EMPTY_SPACE
		mov cx, 9
		pop	ax
		pop	di
       	lea dx, BYTES
    	call PRINT
		lea dx, SPACE
    	call PRINT
		lea dx, BYTE8
    	call PRINT

   		push ds
    	push es
    	pop ds
       	mov dx, 08h
   		mov di, dx
    	add di, 8
    	push [di]
    	mov BYTE PTR [di], '$'
    	call PRINT
    	pop [di]
    	pop ds
    	call END_LINE

    	cmp BYTE PTR es:[0000h], 5ah
   		je @EndBlock
    
    	xor ax, ax
    	mov ax, es
    	add ax, es:[0003h]
    	inc ax
    	mov es, ax
    	jmp @NextBlock 

@EndBlock:
		ret
       		
PRINT_MCB ENDP 
;-----------------------------------------
BEGIN:                    
		call WRITE
		xor 	AL,AL
		mov 	AH,4Ch
		int 	21H
TESTPC ENDS
END START