TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
org 100h
START: JMP BEGIN

TYPEPC db "Type IBM PC: $"
TYPE_1 db  "PC $" 
TYPE_2 db  "PC/XT $"
TYPE_3 db   "AT or PS2 model 50 or 60 $" 
TYPE_4 db  "PS2 model 30 $"
TYPE_5 db  "PS2 model 80 $"
TYPE_6 db  "PCjr $"
TYPE_7 db  "PC Convertible $"
ERR 	   db "Noname (  )$"

VERS     db 13,10,"System version:      $"  ; 17cимволов
MODIF   db 13,10,"Modification:    $"  ;  15 символов
OEM		db 13,10,"OEM:     $"  ; 6 символов
SERNUM db 13,10,"Serial number of user:       $" ; 24 cимвола

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

;---------------------Определим тип Р
BEGIN:
 
mov bx, 0F000h
mov es,bx
mov bl,es:[0FFFEh]; используем прямую адресацию
mov dx, offset TYPEPC
call PrintScreen

cmp bl, 0FFh 
je TYPE1

cmp bl, 0FEh
je TYPE2

cmp bl, 0FBh
je TYPE2

cmp bl, 0FCh
je TYPE3

cmp bl, 0FAh
je TYPE4

cmp bl, 0F8h
je TYPE5

cmp bl, 0FDh
je TYPE6

cmp bl, 0F9h
je TYPE7

mov si, offset ERR
add si,8
mov al,bl
call BYTE_TO_DEC
mov [si],ax
mov dx, offset ERR
call PrintScreen
jmp MISS

TYPE1:
mov dx, offset TYPE_1
call PrintScreen
jmp MISS

TYPE2:
mov dx, offset TYPE_2
call PrintScreen
jmp MISS

TYPE3:
mov dx, offset TYPE_3
call PrintScreen
jmp MISS

TYPE4:
mov dx, offset TYPE_4
call PrintScreen
jmp MISS

TYPE5:
mov dx, offset TYPE_5
call PrintScreen
jmp MISS

TYPE6:
mov dx, offset TYPE_6
call PrintScreen
jmp MISS

TYPE7:
mov dx, offset TYPE_7
call PrintScreen
jmp MISS

MISS:
;--------------Определим номер основной версии
mov ah,30h
int 21h

push ax
mov si, offset VERS
add si, 21
mov al, ah
call BYTE_TO_DEC
dec si
mov dl, '.'
mov [si], dl
dec si
pop ax
call BYTE_TO_DEC
mov dx, offset VERS
call PrintScreen

mov ah,30h
int 21h

mov si, offset OEM
add si, 10
mov al, bh
call BYTE_TO_DEC
mov dx, offset OEM
call PrintScreen

mov di, offset SERNUM
add di, 30
mov ax,cx
call WRD_TO_HEX
mov al, bl
call BYTE_TO_HEX
sub di, 0002h
mov [di],ax
mov dx, offset SERNUM
call PrintScreen

; Выход в DOS
	       xor	   AL,AL
	       mov	   AH,4Ch
	       int	   21H
TESTPC     ENDS
	       END	   START

 
