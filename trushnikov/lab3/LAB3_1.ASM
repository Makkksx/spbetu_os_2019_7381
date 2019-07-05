; Лабораторная работа 3
; Шаг 1
; Программа выводит 
;	1)Количество доступной памяти
;	2)Размер расширенной памяти
;	3)Выводит цепочку блоков управления памятью
TESTPC  SEGMENT
        ASSUME  CS:TESTPC,  DS:TESTPC,  ES:NOTHING, SS:NOTHING
        ORG     100H
START:  JMP     BEGIN
 
; ДАННЫЕ
AVAILABEL_M     db      'Amount of available memory:        bytes',0dh,0ah,'$'
EXTENDED_M      db      'Extended memory size:        kilobytes',0dh,0ah,'$'
MCB             db      'Chain of memory control units:',0dh,0ah,'$'
MCB_type        db      'MCB type:   h, $'
MCB_Seg         db      'Segment`s adress:     h, $'
MCB_Size        db      'MCB size:        b, $'
MCB_Tail        db      '               ',0dh,0ah,'$'
; ПРОЦЕДУРЫ
 
Write_msg       PROC    near
        mov     ah,09h
        int     21h
        ret
Write_msg       ENDP
 
TETR_TO_HEX     PROC    near
        and     al,0fh
        cmp     al,09
        jbe     NEXT
        add     al,07
NEXT:   add     al,30h
        ret
TETR_TO_HEX     ENDP
 
BYTE_TO_HEX     PROC near
; байт в AL переводится в два символа шестн. числа в AX
        push    cx
        mov     ah,al
        call    TETR_TO_HEX
        xchg    al,ah
        mov     cl,4
        shr     al,cl
        call    TETR_TO_HEX ; в AL старшая цифра
        pop     cx          ; в AH младшая
        ret
BYTE_TO_HEX     ENDP
 
WRD_TO_HEX      PROC    near
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
        push    bx
        mov     bh,ah
        call    BYTE_TO_HEX
        mov     [di],ah
        dec     di
        mov     [di],al
        dec     di
        mov     al,bh
        xor     ah,ah
        call    BYTE_TO_HEX
        mov     [di],ah
        dec     di
        mov     [di],al
        pop     bx
        ret
WRD_TO_HEX      ENDP
 
WRD_TO_DEC      PROC    near
; перевод 2 байтов в 10 с/с, SI - адрес поля младшей цифры
        push    cx
        push    dx
        push    ax
        mov     cx,10
    wrd_loop_bd:
        div     cx
        or      dl,30h
        mov     [si],dl
        dec     si
        xor     dx,dx
        cmp     ax,10
        jae     wrd_loop_bd
        cmp     ax,00h
        jbe     wrd_end_l
        or      al,30h
        mov     [si],al
    wrd_end_l: 
        pop     ax
        pop     dx
        pop     cx
        ret
WRD_TO_DEC      ENDP
 
DEFINE_AVAIL_M      PROC    near
        push    cx
        push    bx
        push    dx
        push    ax
		push	si
        mov     ah, 4ah   ; пытаемся освободить заведомо большой размер памяти
        mov     bx, 0ffffh ; неиспользуемый программой
        int     21h         ;в BX вернется размер доступной памяти в параграфах
        mov     ax, bx
        mov     cx, 10h  ;переводим параграфы в байты
        mul     cx
        mov     si, offset AVAILABEL_M + 33
        call    WRD_TO_DEC
        mov     dx, offset AVAILABEL_M
        call    Write_msg
        pop     si
        pop     ax
        pop     dx
        pop     bx
		pop		cx
        ret
DEFINE_AVAIL_M  ENDP
 
DEFINE_EXTENDED_M       PROC    near
        push    ax
        push    bx
        push    si
        push    dx
        mov     al, 30h ; Запись адреса ячейки CMOS
        out     70h, al
        in      al, 71h  ; чтение младшего байты
        mov     bl, ah  ; размера расширенной памяти
        mov     al, 31h ; запись адреса ячейки CMOS
        out     70h, al
        in      al, 71h ; чтение старшего байта
        mov     ah, al  ; размера расширенной памяти
        mov     al, bl ; в AX размер расширенной памяти
        sub     dx, dx
        mov     si, offset EXTENDED_M + 26
        call    WRD_TO_DEC
        mov     dx, offset EXTENDED_M
        call    Write_msg
        pop     dx
        pop     si
        pop     bx
        pop     ax     
        ret
DEFINE_EXTENDED_M   ENDP
 
 
PRINT_MCB   PROC  near
        mov     dx, offset MCB
        call    Write_msg
        mov     ah, 52h
        int     21h
        sub     ax, ax
        sub     cx, cx
        mov     es, es:[bx-2] ;сохраняем адрес первого mcb
        mov     bx, 1
       
        cycle:
        sub     ax, ax
        mov     al, es:[00h]
        call    BYTE_TO_HEX
        cmp     ax, 4135h ;проверяем является ли MCB последним
        jne     continue
        mov     bx, 0
        continue:
        mov     di, offset MCB_type + 10
        mov     [di], ax
        lea     di,MCB_Seg+21
        mov     ax,es:[0001h]
        call    WRD_TO_HEX
        mov     ax, es:[03h]
        mov     cx, 10h
        mul     cx
        mov     si, offset MCB_Size + 15
        call    WRD_TO_DEC
		mov		si, offset MCB_Tail
		mov		di,0008h
		mov		cx,4
		cycle1:
		mov		ax,es:[di]; сохраняем хвост
		mov		[si],ax
		add 	di,2h
		add		si,2h
		loop 	cycle1		
        mov     dx, offset MCB_type
        call    Write_msg
        mov     dx, offset MCB_Seg
        call    Write_msg
        mov     dx, offset MCB_Size
        call    Write_msg
		mov     dx, offset MCB_Tail
        call    Write_msg
        cmp     bx, 0
        je      _end
        mov     ax, es
        add     ax, es:[0003h]
        inc     ax
        mov     es, ax
        jmp     cycle
        _end:
        ret
PRINT_MCB   ENDP
 
BEGIN:
        call define_avail_m
        call DEFINE_EXTENDED_M
        call PRINT_MCB
       
; выход в DOS
        xor     al,al
        mov     ah,3Ch
        int     21h
        ret
TESTPC  ENDS
        END     START