.Model small

.DATA
HELLO db "Message:$"
IDENTSTR db 13, 10, "Resident loaded$", 13, 10
RESUNSTR db 13, 10, "Resident unloaded$"
RESLSTR db 13, 10, "Resident is already loaded$"
PSP dw ?
isUd db ?
isloaded db ?
count db 0
KEEP_CS DW ? ; для хранения сегмента
KEEP_IP DW ? ; для хранения смещения вектора прерывания

.STACK 400h

.CODE
int_vect dd ?
ID dw 0ff00h

ROUT PROC FAR
	push ax
	push es
	inc count
	cmp count, 10
	jne ifn
	mov count, 0
	ifn:
		mov al, count
		or al, 30h
		
		push ax

		push ax
		push bx
		push cx
		push dx
		
		mov ah, 03
		mov bh, 00
		int 10h
		mov es, dx
		
		pop dx
		pop cx
		pop bx 
		pop ax
		
		;set curs
		mov ah, 02
		mov bh, 00
		mov dh, 1
		mov dl, 40
		int 10h
		
		call outputAL

		mov ah, 02
		mov bh, 00
		mov dx, es
		int 10h
		pop ax

	pop es
	pop ax
	mov al, 20h
	out  20h, al
	iret			
ROUT  ENDP  

isunLoad PROC
	push es
	push ax
	mov ax, PSP
	mov es, ax
	mov cl, es:[80h]
	mov dl, cl
	xor ch, ch
	test cl, cl	
	jz ex2
	xor di, di
	readChar:
	inc di
	mov al, es:[81h+di]
	inc di

	cmp al, '/'
	jne ex2
	mov al, es:[81h+di]
	inc di
	cmp al, 'u'
	jne ex2
	mov al, es:[81h+di]
	cmp al, 'n'
	jne ex2
	mov isUd, 1

	ex2:
	pop ax
	pop es
	ret
isunLoad ENDP

outputAL PROC
	push ax
	push bx
	push cx
	mov ah, 09h   ;писать символ в текущей позиции курсора
	mov bh, 0     ;номер видео страницы
	mov cx, 1     ;число экземпляров символа для записи
	int 10h      ;выполнить функцию
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP

outputBP PROC
	push ax
	push bx
	push dx
	push cx
	mov cx, 8
	mov ah, 13h
	mov al, 1
	mov bh, 0
	mov dh, 22
	mov dl, 0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
outputBP  ENDP

isLoad PROC
	push es
	mov ax, 351Ch ; получение вектора
	int  21h
	mov  dx, es:[bx-2]
	pop es
	cmp dx, ID
	je ad
	jmp exd
	ad:
		mov isloaded, 1
	exd:
		ret
isLoad ENDP

unLoad PROC
	push es
	mov ax, 351Ch ; получение вектора
	int  21H
	mov dx, word ptr es:int_vect
	mov ax, word ptr es:int_vect+2
	mov KEEP_IP, dx
	mov KEEP_CS, ax
	pop es
	cli
	push ds
	mov  dx, KEEP_IP
	mov  ax, KEEP_CS
	mov  ds, ax
	mov  AH, 25H
	mov  AL, 1CH
	int  21H          ; восстанавление вектора
	pop  ds
	sti
	ret
unLoad ENDP

MakeResident PROC
	mov dx, offset IDENTSTR
	call WRITE
	mov dx, offset temp
	sub dx, PSP
	mov cl, 4
	shr dx, cl
	mov ax, 3100h
	int 21h
	ret
MakeResident ENDP

WRITE   PROC
        push ax
        mov ah, 09h
        int 21h
        pop ax
        ret
WRITE   ENDP

BEGIN   PROC  FAR 
	mov ax, ds
	mov ax, @DATA		  
	mov ds, ax
	mov ax, es
	mov PSP, ax ; save PSP addr to var

	call isLoad

	call isunLoad

	mov dx, offset HELLO
	call WRITE

	cmp isloaded, 1
	je a
	mov ax, 351Ch ; получение вектора
	int  21H
	mov  KEEP_IP, bx  ; запоминание смещения
	mov  KEEP_CS, es  ; запоминание сегмента вектора прерывания
	mov word ptr int_vect+2, es
	mov word ptr int_vect, bx

	push ds
	mov dx, OFFSET ROUT ; смещение для процедуры в dx
	mov ax, SEG ROUT    ; сегмент процедуры
	mov ds, ax          ; помещение в ds
	mov ax, 251Ch       ; установка вектора
	int 21h             ; замена прерывания
	pop  ds
	call MakeResident
	a:
		cmp isud, 1
		jne b
		call unLoad
		mov dx, offset RESUNSTR
		call WRITE
		mov ah, 4Ch                        
		int 21h   
	b:
		mov dx, offset RESLSTR
		call WRITE
		mov ah, 4Ch                        
		int  21h
BEGIN      ENDP

TEMP PROC
TEMP ENDP

END BEGIN