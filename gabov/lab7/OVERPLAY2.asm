ASSUME CS:OVL2,DS:OVL2,SS:NOTHING,ES:NOTHING
OVL2 SEGMENT
;---------------------------------------------------------------
MAIN2 PROC FAR 
	push ds
	push dx
	push di
	push ax
	mov ax,cs
	mov ds,ax
	mov bx, offset ForPrint
	add bx, 47h			
	mov di, bx		
	mov ax, cs			
	call WRD_TO_HEX
	mov dx, offset ForPrint	
	call PRINT
	pop ax
	pop di
	pop dx	
	pop ds
	retf
MAIN2 ENDP
;---------------------------------------------------------------
PRINT PROC NEAR ;ia?aou ia ye?ai 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;iieiaeia aaeo AL ia?aaiaeony a neiaie oanoiaaoaoe?e?iiai ?enea a AL
		and		al, 0Fh ;and 00001111 - inoaaeyai oieuei aoi?o? iieiaeio al
		cmp		al, 09 ;anee aieuoa 9, oi iaai ia?aaiaeou a aoeao
		jbe		NEXT ;auiieiyao ei?ioeee ia?aoia, anee ia?aue iia?aia IAIUOA eee ?AAAI aoi?iio iia?aiao
		add		al, 07 ;aiiieiyai eia ai aoeau
	NEXT:	add		al, 30h ;16-?e?iue eia aoeau eee oeo?u a al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;aaeo AL ia?aaiaeony a aaa neiaiea oanoiaaoaoe?e?iiai ?enea a AX
		push	cx
		mov		ah, al ;eiie?oai al a ah
		call	TETR_TO_HEX ;ia?aaiaei al a neiaie 16-?e?.
		xchg	al, ah ;iaiyai ianoaie al e  ah
		mov		cl, 4 
		shr		al, cl ;caaea anao aeoia al ai?aai ia 4
		call	TETR_TO_HEX ;ia?aaiaei al a neiaie 16-?e?.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near ;?aaeno? AX ia?aaiaeony a oanoiaaoaoa?e?io? nenoaio, DI - aa?an iineaaiaai neiaiea
		push	bx
		mov		bh, ah ;eiie?oai ah a bh, o.e. ah enii?oeony i?e ia?aaiaa
		call	BYTE_TO_HEX ;ia?aaiaei al a aaa neiaiea oanoiaaoaoe?e?iiai ?enea a AX
		mov		[di], ah ;ia?anueea niaa??eiiai ?aaeno?a ah ii aa?ano, ea?auaio a ?aaeno?a DI
		dec		di 
		mov		[di], al ;ia?anueea niaa??eiiai ?aaeno?a al ii aa?ano, ea?auaio a ?aaeno?a DI
		dec		di
		mov		al, bh ;eiie?oai bh a al, ainnoaiaaeeaaai cia?aiea ah
		xor		ah, ah ;i?euaai ah
		call	BYTE_TO_HEX ;ia?aaiaei al a aaa neiaiea oanoiaaoaoe?e?iiai ?enea a AX
		mov		[di], ah ;ia?anueea niaa??eiiai ?aaeno?a al ii aa?ano, ea?auaio a ?aaeno?a DI
		dec		di
		mov		[di], al ;ia?anueea niaa??eiiai ?aaeno?a al ii aa?ano, ea?auaio a ?aaeno?a DI
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
ForPrint  DB 0DH,0AH, 'The address of the segment to which the second overlay is loaded:                 ',0DH,0AH,'$'
;--------------------------------------------------------------------------------
OVL2 ENDS
END