code segment
	assume cs: code, ds: code, ss:Tstack
	
	block 		db 14 dup(0)   	
	path 		db 50 dup(0)  
	_ss 		dw 0
	_sp 		dw 0
	mem_error	db 'Error: Memory can not be allocated!$'
	lab2_name 	db 'lab2.com', 0
	mess 		db 'In lab6:$'
	error1 		db 'Error: invalid function number!$'
	error2 		db 'Error: file not found!$'
	error3 		db 'Error: disk error!$'
	error4 		db 'Error: not enought memory!$'
	error5 		db 'Error: wrong enviroment string!$'
	error6 		db 'Error: invalid format!$'
	error7 		db 'Error: unknown error!$'
	reason 		db 'Termination reason: $'
	reason1 	db 'normal termination$'
	reason2 	db 'Ctrl-Break termination$'
	reason3 	db 'device error termination$'
	reason4 	db '31h function termination$'
	reason5 	db 'unknown termination reason$'
	exit_code 	db 'Exit code: $'
	endl		db  13, 10, '$'
    teststr		db  4,' cmd tail to lab2 $',0	
print proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
   print endp	
	
print_symb proc near
	push	ax
	push	dx
	mov		ah, 02h
	int		21h
	pop		dx
	pop		ax
	ret
   print_symb endp	
	
main proc near	
	mov 	ax, seg code
	mov 	ds, ax
	
;free memory
	mov		bx, seg code
	add		bx, offset CodeSegEnd
	add		bx, 256 ;Stack
	mov 	cl, 4h
	shr 	bx, cl
	mov		ah, 4Ah
	int 	21h
	jnc		mem_ok
	mov		dx, offset mem_error
	call	print
	mov		dx,	offset endl
	call	print
	jmp		main_exit

mem_ok:	
	;path
	mov		es, es:[002Ch]
	xor		bx, bx

;мотаем до пути
next:
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je 		first_0
	inc 	bx
	jmp 	next
first_0:
	inc 	bx
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je 		second_0
	jmp 	next

second_0:		
	add		bx,3	
	
;переписываем путь	
	push	si
	mov		si, offset path
next1:	
	mov 	dl, byte PTR es:[bx]
	mov		[si], dl
	inc		si
	inc		bx
	cmp		dl, 0
	jne		next1
	
;удаляем имя файла
next2:
	mov		al, [si]
	cmp		al, '\'
	je		next3
	dec		si
	jmp		next2
	
next3:	
	inc		si
	
;дописываем имя файла lab2.com
	push	di
	mov		di, offset lab2_name
next4:
	mov		ah, [di]
	mov		[si], ah
	inc		si
	inc		di
	cmp		ah, 0
	jne		next4
	
	pop		di
	pop		si

;подготовка к вызову lab2
	mov		_sp, sp
	mov		_ss, ss
	mov		ax, ds
	mov		es, ax
	push 	ax
	mov		ax, seg teststr
	mov		[block+3], ah
	mov		[block+2], al
	pop		ax
	mov		[block+4], offset teststr
	mov		bx, offset block
	mov		dx, offset path
	mov		ax, 4B00h
	int 	21h
	
	mov		dx, offset endl
	call 	print
	call 	print
	mov		dx, offset mess
	call	print
	mov		dx, offset endl
	call 	print
	
	jc 		errors
	jmp		run_ok
	
errors:	
	cmp 	ax, 1
	jne 	err2
	mov 	dx, offset error1
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit
	
err2:	
	cmp 	ax, 2
	jne 	err3
	mov 	dx, offset error2
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit	
	
err3:	
	cmp 	ax, 5
	jne 	err4
	mov 	dx, offset error3
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit	
	
err4:	
	cmp 	ax, 8
	jne 	err5
	mov 	dx, offset error4
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit

err5:	
	cmp 	ax, 10
	jne 	err6
	mov 	dx, offset error5
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit

err6:	
	cmp 	ax, 11
	jne 	err7
	mov 	dx, offset error6
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit	

err7:	
	mov 	dx, offset error7
	call 	print
	mov		dx, offset endl
	call 	print
	jmp		main_exit	

run_ok:
	mov 	ax, seg code
	mov 	ds, ax
	mov 	ss, _ss
	mov 	sp, _sp

	mov 	ah, 4Dh
	int 	21h
	
	push 	ax
	mov 	dx, offset reason
	call 	print		
	
	cmp 	ah, 0
	jne 	reason_tag2
	mov		dx, offset reason1
	call	print
	mov		dx, offset endl
	call 	print	
	jmp 	print_exit_code	

reason_tag2:	
	cmp 	ah, 1
	jne 	reason_tag3
	mov		dx, offset reason2
	call	print
	mov		dx, offset endl
	call 	print
	jmp 	print_exit_code	

reason_tag3:	
	cmp 	ah, 2
	jne 	reason_tag4
	mov		dx, offset reason3
	call	print
	mov		dx, offset endl
	call 	print
	jmp 	print_exit_code	

reason_tag4:	
	cmp 	ah, 3
	jne 	reason_tag5
	mov		dx, offset reason4
	call	print
	mov		dx, offset endl
	call 	print	
	jmp 	print_exit_code	
	
reason_tag5:
	mov		dx, offset reason5
	call	print
	mov		dx, offset endl
	call 	print
	
print_exit_code:	
	mov		dx, offset exit_code
	call	print
	pop		ax
	mov 	dl, al
	call 	print_symb
	mov		dx, offset endl
	call	print

main_exit:	
	xor 	al, al
	mov 	ah, 4Ch
	int 	21h
	ret	
	main endp
	
CodeSegEnd:  
code ends

Tstack segment stack
	dw 128 dup (?)
Tstack ends

end main
