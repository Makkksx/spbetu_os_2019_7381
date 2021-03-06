AStack SEGMENT  STACK
        DW 512 DUP(?)			
AStack ENDS


CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:AStack


DATA SEGMENT
	str_err_function_not_exist	DB 0DH, 0ah, 'Load Overlay Error: Non-existent function!', 0DH, 0ah, '$'   
	str_err_file_not_exist_1  	DB 0DH, 0ah, 'Load Overlay Error: File not found!', 0DH, 0ah, '$'
	str_err_path_not_exist_1  	DB 0DH, 0ah, 'Load Overlay Error: Path not found!', 0DH, 0ah, '$'
	str_err_many_files  		DB 0DH, 0ah, 'Load Overlay Error: Too many opened files!', 0DH, 0ah, '$'
	stt_err_no_access  			DB 0DH, 0ah, 'Load Overlay Error: No access!', 0DH, 0ah, '$'					
	str_err_not_enough_mem  	DB 0DH, 0ah, 'Load Overlay Error: Not enough memory!', 0DH, 0ah, '$'					
	str_err_env_incorrect 		DB 0DH, 0ah, 'Load Overlay Error: Incorrect environment!', 0DH, 0ah, '$'

	str_err_mcb_damaged        		DB 0DH, 0AH, 'Memory control unit has been damaged!',0DH,0AH,'$'
	str_err_not_enough_mem_func     DB 0DH, 0AH, 'Not enough memory to perform the function!',0DH,0AH,'$'
	str_err_addr_incorrect          DB 0DH, 0AH, 'Incorrect address of the memory block!',0DH,0AH,'$'				
	str_err_file_not_exist_2		DB 0DH, 0ah, 'Overlay Size Error: File not found!', 0DH, 0ah, '$'
	str_err_path_not_exist_2 		DB 0DH, 0ah, 'Overlay Size Error: Path not found!', 0DH, 0ah, '$'
	
	str_overlay1			DB 'OVER1.ovl', 0
	str_overlay2 			DB 'OVER2.ovl', 0
	DTA 					DB 43 dup (0), '$'
	OVERLAY_PATH 			DB 100h	dup (0), '$'
	OVERLAY_ADDR 			DD 0
	KEEP_PSP 				DW 0
	OVERLAY_ADDRESS 		DW 0
DATA 	ENDS


; Сокращение для функции вывода.
PRINT_DX proc near
	mov ah,09h
	int 21h
	ret
PRINT_DX endp


FREE_MEM proc 
	mov bx, offset LAST_BYTE
	mov ax, es
	sub bx, ax
	mov cl, 4h
	shr bx, cl

	mov ah,4Ah 
	int 21h
	jnc NO_ERROR 
	
	cmp ax, 7 
	mov dx, offset str_err_mcb_damaged
	je IS_ERROR
	cmp ax, 8 
	mov dx, offset str_err_addr_incorrect
	je IS_ERROR
	cmp ax, 9 
	mov dx, offset str_err_addr_incorrect
	
IS_ERROR:
	call PRINT_DX
	xor al,al
	mov ah,4Ch
	int 21H
NO_ERROR:
	ret
FREE_MEM endp


HANDLE_ERROR_OVERLAY_START proc
	cmp ax, 1
	mov dx, offset str_err_function_not_exist
	je 	IS_OVER_ERROR

	cmp ax, 2
	mov dx, offset str_err_file_not_exist_1
	je 	IS_OVER_ERROR

	cmp ax, 3
	mov dx, offset str_err_path_not_exist_1
	je 	IS_OVER_ERROR

	cmp ax, 4
	mov dx, offset str_err_many_files
	je 	IS_OVER_ERROR

	cmp ax, 5
	mov dx, offset stt_err_no_access
	je 	IS_OVER_ERROR

	cmp ax, 8
	mov dx, offset str_err_not_enough_mem
	je 	IS_OVER_ERROR

	cmp ax, 10
	mov dx, offset str_err_env_incorrect
	je 	IS_OVER_ERROR
	
IS_OVER_ERROR:
	call 	PRINT_DX	
	ret
HANDLE_ERROR_OVERLAY_START endp


SEARCH_PATH	proc
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es

	mov es, KEEP_PSP
	mov ax, es:[2Ch]
	mov es, ax
	mov bx, 0
	mov cx, 2

COOPY_LOOOP_cont:
	inc cx
	mov al, es:[bx]
	inc bx
	cmp al, 0
	jz 	STOOP_COOPY_LOOP_cont
	loop COOPY_LOOOP_cont

STOOP_COOPY_LOOP_cont:
	cmp byte PTR es:[bx], 0
	jnz COOPY_LOOOP_cont
	add bx, 3
	mov si, offset OVERLAY_PATH
	
COOPY_LOOOP_path:
	mov al, es:[bx]
	mov [si], al
	inc si
	inc bx
	cmp al, 0
	jz 	STOOP_COOPY_LOOOP_path
	jmp COOPY_LOOOP_path

STOOP_COOPY_LOOOP_path:	
	sub si, 9
	mov di, bp
	
MOV_ROUTE:
	mov ah, [di]
	mov [si], ah
	cmp ah, 0
	jz 	STOOP_MOV_ROUTE
	inc di
	inc si
	jmp MOV_ROUTE
	
STOOP_MOV_ROUTE:
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
SEARCH_PATH	endp


SIZE_OF_OVERLAY	 proc
	push bx
	push es
	push si

	push ds
	push dx
	mov dx, SEG DTA
	mov ds, dx
	mov dx, offset DTA	
	mov ax, 1A00h		
	int 21h
	pop dx
	pop ds
	
	push ds
	push dx
	xor cx, cx			
	mov dx, SEG OVERLAY_PATH	
	mov ds, dx
	mov dx, offset OVERLAY_PATH	
	mov ax, 4E00h
	int 21h
	pop dx
	pop ds

	jnc no_err_size 		
	cmp ax, 2
	je 	ERR_FILE_NOT			
	cmp ax, 3
	je 	ERR_PATH_NOT
	jmp no_err_size
			
ERR_FILE_NOT:
	mov dx, offset str_err_file_not_exist_2
	call PRINT_DX
	jmp EXIT
	
ERR_PATH_NOT:
	mov dx, offset str_err_path_not_exist_2
	call PRINT_DX
	jmp EXIT
		
no_err_size:
	push es
	push bx
	push si
	mov si, offset DTA
	add si, 1Ch		
	mov bx, [si]
	
	sub si, 2	
	mov bx, [si]	
	push cx
	mov cl, 4
	shr bx, cl 
	pop cx
	mov ax, [si+2] 
	push cx
	mov cl, 12
	sal ax, cl	
	pop cx
	add bx, ax	
	inc bx
	inc bx
	mov ax, 4800h	
	int 21h			
	mov OVERLAY_ADDRESS, ax	
	pop si
	pop bx
	pop es

EXIT:
	pop si
	pop es
	pop bx
	ret
SIZE_OF_OVERLAY  endp


RUUUN_OVERLAY proc
		push bp
		push ax
		push bx
		push cx
		push dx
			
		mov bx, SEG OVERLAY_ADDRESS
		mov es, bx
		mov bx, offset OVERLAY_ADDRESS	
			
		mov dx, SEG OVERLAY_PATH
		mov ds, dx	
		mov dx, offset OVERLAY_PATH
			
		push ss
		push sp
			
		mov ax, 4B03h	
		int 21h
		jnc NO_ERROR_RUN
		
		call HANDLE_ERROR_OVERLAY_START
		jmp	ERROR_CATCHED_RUN
NO_ERROR_RUN:
		mov ax, SEG DATA
		mov ds, ax	
		mov ax, OVERLAY_ADDRESS
		mov WORD PTR OVERLAY_ADDR+2, ax
		call OVERLAY_ADDR
		mov ax, OVERLAY_ADDRESS
		mov es, ax
		mov ax, 4900h
		int 21h
		mov ax, SEG DATA
		mov ds, ax
ERROR_CATCHED_RUN:
		pop sp
		pop ss
		mov es, KEEP_PSP
		pop dx
		pop cx
		pop bx
		pop ax	
		pop bp
		ret
RUUUN_OVERLAY endp	


MAIN proc far
	mov ax, seg DATA
	mov ds, ax
	mov KEEP_PSP, es
	call FREE_MEM

	mov bp, offset str_overlay1
	call SEARCH_PATH
	call SIZE_OF_OVERLAY
	call RUUUN_OVERLAY
	
	mov bp, offset str_overlay2
	call SEARCH_PATH
	call SIZE_OF_OVERLAY
	call RUUUN_OVERLAY

	xor al, al
	mov ah, 4Ch
	int 21H 
	ret
MAIN endp
CODE ENDS

LAST_BYTE SEGMENT	
LAST_BYTE ENDS	

END MAIN