ASSUME CS:CODE, DS:DATA, SS:AStack
AStack SEGMENT STACK 
	DW 64 DUP(?)
AStack ENDS
 
CODE SEGMENT

MY_INT PROC FAR
	jmp FUNCT

	AD_PSP dw ?     
	SR_PSP dw ?	
	KEEP_CS dw ?   
	KEEP_IP dw ?    
	MY_INT_SET dw 0FFDAh   
	INT_NUM db 'Interrupts 0000 $' 

FUNCT:

	
	push ax
	push bx
	push cx
	push dx

	mov ah,3h
	mov bh,0h
	int 10h
	push dx 
	
	mov ah,02h
	mov bh,0h
	mov dx,0214h
	int 10h
	
	push si
	push cx
	push ds
	mov ax,SEG INT_NUM
	mov ds,ax
	mov si,offset INT_NUM
	add si,0Eh

	mov ah,[si]
	inc ah
	mov [si],ah
	cmp ah,3Ah
	jne NOT0
	mov ah,30h
	mov [si],ah	

	mov bh,[si-1] 
	inc bh
	mov [si-1],bh
	cmp bh,3Ah                    
	jne NOT0
	mov bh,30h
	mov [si-1],bh

	mov ch,[si-2]
	inc ch
	mov [si-2],ch
	cmp ch,3Ah
	jne NOT0
	mov ch,30h
	mov [si-2],ch

	mov dh,[si-3]
	inc dh
	mov [si-3],dh
	cmp dh,3Ah
	jne NOT0
	mov dh,30h
	mov [si-3],dh
	
NOT0:
    pop ds
    pop cx
	pop si
	push es
	push bp
	mov ax,SEG INT_NUM
	mov es,ax
	mov ax,offset INT_NUM
	mov bp,ax
	mov ah,13h
	mov al,00h
	mov cx,0Fh
	mov bh,0
	int 10h
	pop bp
	pop es
	
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax     

	iret
MY_INT ENDP

END_MY_INT PROC
END_MY_INT ENDP

IS_SET PROC near
	push dx
    push es
	push bx

	mov ax,351Ch 	 
	int 21h         

	mov dx,es:[bx+11]
	cmp dx,0FFDAh 
	je INT_IS_SET
	mov al,0h
	pop bx
	pop es
	pop dx
	ret	
INT_IS_SET:
	mov al,01h  
    pop bx
	pop es
	pop dx
	ret
IS_SET ENDP

UNSET PROC near
	push es
	mov ax,AD_PSP
	mov es,ax
	xor bx,bx
	inc bx


	mov al,es:[81h+bx]
	inc bx
	cmp al,'/'
	jne UNSET_END

	mov al,es:[81h+bx]
	inc bx
	cmp al,'u'
	jne UNSET_END

	mov al,es:[81h+bx]
	inc bx
	cmp al,'n'
	jne UNSET_END

	mov al,1h

UNSET_END:		
	pop es
	ret
UNSET ENDP

DOWNLOAD PROC near
	push ax
	push bx
	push dx
	push es



	mov ax,351Ch    	 
	int 21h         
	mov KEEP_IP,bx  
	mov KEEP_CS,es  
	 
	push ds               
	mov dx,offset MY_INT  
	mov ax,seg MY_INT     
	mov ds,ax             
	mov ax,251Ch          
	int 21h               
	pop ds                

	mov dx,offset UPLOAD_MSG
	mov ah,09h
	int 21h
	
	pop es
	pop dx
	pop bx
	pop ax
	ret
DOWNLOAD ENDP

UPLOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,351Ch
	int 21h
	
	cli                   
	push ds               
	mov dx,es:[bx+9]  
	mov ax,es:[bx+7]   
	mov ds,ax                        
	mov ax,251Ch          
	int 21h
	pop ds                
	sti                   
	
	mov dx,offset UNLOAD_MSG  
	mov ah,09h
	int 21h


	push es
		
	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h
	int 21h
	
	pop es
	mov cx,es:[bx+5]
	mov es,cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
UPLOAD ENDP

MAIN PROC far

	mov bx,02Ch
	mov ax,[bx]
	mov SR_PSP,ax
	mov AD_PSP,ds 
	sub ax,ax    
	xor bx,bx

	mov ax,DATA  
	mov ds,ax    

	call UNSET  
	cmp al,1h
	je UNLOAD

	call IS_SET  
	cmp al,01h
	jne WAS_UPLOAD
	
	mov dx,offset WAS_RES_MSG	
	mov ah,09h
	int 21h
       
	mov ah,4Ch
	int 21h

WAS_UPLOAD:
        

	call DOWNLOAD	
	mov dx,offset END_MY_INT
	mov cl,4h
	shr dx,cl
	inc dx
	add dx,1Ah

	mov ax,3100h
	int 21h
         
UNLOAD:
	
	call IS_SET
	cmp al,0h
	je NOT_SET2
	
    call UPLOAD

	mov ax,4C00h
	int 21h

NOT_SET2:
	mov dx,offset NO_RES_MSG      
	mov ah,09h
	int 21h
        
	mov ax,4C00h
	int 21h


MAIN ENDP
CODE ENDS

DATA SEGMENT
	NO_RES_MSG db 'Resident didnt download',13,10,'$'
	WAS_RES_MSG db 'Resident is already download',13,10,'$'
	UPLOAD_MSG db 'Resident is download',13,10,'$'	
	UNLOAD_MSG db 'Vector restored',13,10,'$'
DATA ENDS
END MAIN
