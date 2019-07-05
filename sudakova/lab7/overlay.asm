CODE_OVERLAY SEGMENT
ASSUME CS:CODE_OVERLAY, DS:CODE_OVERLAY, ES:NOTHING, SS:NOTHING

OVER_LAY PROC far
	push ds
	sub dx, dx
	mov ax, cs
	mov bx, 10h
	mov cx, 4
Division:
	div bx
	push dx
	sub dx, dx
	loop Division
	mov cx, 4
Print:
	pop dx
	cmp dl, 09h
	jbe Add1
	add dl, 07h
Add1:  
	add dl, 30h
	mov ah, 02h
	int 21h
	loop Print
	pop ds
	retf
OVER_LAY ENDP

CODE_OVERLAY ENDS
	END 