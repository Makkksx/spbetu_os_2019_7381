TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	org 100h
START:     JMP     BEGIN

ADRINACCESS db "Address inaccessible memory:        ", 10,13, '$'
ADRENVI        db "Environment adress:       ", 10,13, '$'
TAIL              db "Tail's symbols: $"
AREAENVI      db 10,13,"Area environment: $"
PATH             db 10,13,"Path: $"
NEWSTRING   db 10,13,'$'

;-----------------------------------------------Процедуры
;вывод на экран
PrintScreen PROC near
push ax
mov ah,09h
int 21h
pop ax
ret 
PrintScreen ENDP
;-------------------------------

PrintScreenSym PROC near
push ax
mov ah,02h
int 21h
pop ax
ret 
PrintScreenSym ENDP

;-------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP

BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; перевод в 10с/с, SI - адрес поля младшей цифры
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
; Определяет сегментный адрес недоступной памяти
SEG_ADR_MEM PROC near
mov ax, es:[0002]
mov di, offset ADRINACCESS
add di, 34
call WRD_TO_HEX
mov dx, offset ADRINACCESS
call PrintScreen
ret
SEG_ADR_MEM ENDP

ENV_ADR PROC near
; Сегментный адресс среды
mov ax, es:[002Ch]
mov di, offset ADRENVI
add di, 25
call WRD_TO_HEX
mov dx, offset ADRENVI
call PrintScreen
ret
ENV_ADR ENDP

WRITE_COMAND_SYM PROC near
mov dx, offset TAIL
call PrintScreen

mov si, 0081h
mov cl, byte ptr es:[0080h];Получим количество командной строки символов

cmp cl, 00
jg cycle
jmp miss ; если символов нет

cycle:
mov dl, byte ptr es:[si]
call PrintScreenSym
inc si
dec cl
cmp cl, 00
jg cycle
miss:
ret
WRITE_COMAND_SYM  ENDP

GET_CONTENT_ENVI PROC near
mov dx, offset AREAENVI 
call PrintScreen

mov es, es:[002Ch] ;получаем сегментный адресс среды, передаваемы программе
mov si, 0000h
;--------------------Выводим область среды вида имя=параметр
jmp next3
cycle2:
inc si
call PrintScreenSym
next3:

mov dl, byte ptr es:[si]
cmp dl,00h
jne cycle2
je loop1

loop1:
mov dx, offset NEWSTRING
call PrintScreen
inc si
mov dl, byte ptr es:[si]
cmp dl, 00h
jne cycle2
je show_path
;-----------------------Выводим путь к загрузочному модулю
show_path:
mov dx, offset PATH
call PrintScreen
add si, 0003h

jmp next2
cycle3:
inc si
call PrintScreenSym
next2:

mov dl, byte ptr es:[si]
cmp dl, 00h
jne cycle3 
ret
GET_CONTENT_ENVI ENDP
;---------------------Определим тип Р
BEGIN:
call SEG_ADR_MEM
call ENV_ADR
call WRITE_COMAND_SYM
call GET_CONTENT_ENVI
; Выход в DOS
	       xor	   AL,AL
	       mov	   AH,4Ch
	       int	   21H
TESTPC     ENDS
	       END	   START