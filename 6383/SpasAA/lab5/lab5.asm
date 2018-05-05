; ������ ⥪�� �ணࠬ�� ��� ����� ⨯� .COM
; ����
ASTACK SEGMENT STACK
	dw 100h dup (?)
ASTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
; ���������
;---------------------------------------
; ��� ��ࠡ��稪 ���뢠��� 
ROUT PROC FAR
	
	jmp go_
	SIGNATURA dw 0ABCDh
	KEEP_PSP dw 0 ; ��� �࠭���� psp ��襣� ��ࠡ��稪�
	KEEP_IP dw 0 ; ��६����� ��� �࠭���� ᬥ饭�� �⠭���⭮�� ��ࠡ��稪� ���뢠���
	KEEP_CS dw 0 ; ��� �࠭���� ��� ᥣ���� 
	INT_STACK		DW 	100 dup (?)
	KEEP_SS DW 0
	KEEP_AX	DW 	?
    KEEP_SP DW 0
	; ��࠭塞 �ᯮ��㥬� ॣ�����:
	go_:
	mov KEEP_SS, SS 
	mov KEEP_SP, SP 
	mov KEEP_AX, AX 
	mov AX,seg INT_STACK 
	mov SS,AX 
	mov SP,0 
	mov AX,KEEP_AX
	
	; ��࠭塞 �ᯮ��㥬� ॣ�����:
	push ax
	push es
	push ds
	push dx
	push di
	push cx
	mov al,0
	in al,60h
	cmp al,11h ; �᫨ ����� w
	je do_req
	
	pushf
	call dword ptr cs:KEEP_IP ; ���室 �� ��ࢮ��砫�� ��ࠡ��稪
	jmp skip ; �ய�᪠�� ���짮��⥫���� ���� ��ࠡ��稪�
	
	do_req:
	; �믮��塞 ��ࠡ��� ᪠�-����:
	; ��� ��� ��ࠡ�⪨ �����⭮�� ���뢠���:
	; push ax
	in al, 61h   ;����� ���祭�� ����  �ࠢ����� ��������ன
	mov ah, al     ; ��࠭��� ���
	or al, 80h    ;��⠭����� ��� ࠧ�襭�� ��� ����������
	out 61h, al    ; � �뢥�� ��� � �ࠢ���騩 ����
	xchg ah, al    ;������� ��室��� ���祭�� ����
	out 61h, al    ;� ������� ��� ���⭮
	mov al, 20h     ;��᫠�� ᨣ��� "����� ���뢠���"
	out 20h, al     ; ����஫���� ���뢠��� 8259
	; pop ax
	; ����� ��� ᨬ��� � ���� ����������:
	buf_push:
	mov al,0
	mov ah,05h ; ��� �㭪樨
	mov cl,03h ; ��� ᨬ����
	mov ch,00h
	int 16h
	or al,al
	jz skip
	mov ax,0040h
	mov es,ax
	mov ax,es:[1Ah]
	mov es:[09h],ax
	jmp buf_push
	skip:

	; ����⠭�������� ॣ�����:
	pop cx
	pop di
	pop dx
	pop ds
	pop es
	mov al,20h
	out 20h,al
	pop ax
	
	mov 	AX,KEEP_SS
 	mov 	SS,AX
 	mov 	AX,KEEP_AX
 	mov 	SP,KEEP_SP
	
	iret
ROUT ENDP 
LAST_BYTE:
;---------------------------------------
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
; �஢�ઠ, ��⠭����� �� ��� ��ࠡ��稪 ���뢠���:
PROV_ROUT PROC
	mov ah,35h
	mov al,09h
	int 21h ; ����稫� � ES:BX ���� ��ࠡ��稪� ���뢠���
	mov si,offset SIGNATURA
	sub si,offset ROUT ; � SI - ᬥ饭�� ᨣ������ �⭮�⥫쭮 ��砫� ��ࠡ��稪�
	mov ax,0ABCDh
	cmp ax,ES:[BX+SI] ; �ࠢ������ ᨣ������
	je ROUT_EST
		call SET_ROUT
		jmp PROV_KONEC
	ROUT_EST:
		call DEL_ROUT
	PROV_KONEC:
	ret
PROV_ROUT ENDP
;---------------------------------------
; ��⠭���� ��襣� ��ࠡ��稪�:
SET_ROUT PROC
	mov ax,KEEP_PSP 
	mov es,ax ; ����� � es PSP ��襩 �ணࠬ�
	cmp byte ptr es:[80h],0
		je UST
	cmp byte ptr es:[82h],'/'
		jne UST
	cmp byte ptr es:[83h],'u'
		jne UST
	cmp byte ptr es:[84h],'n'
		jne UST
	
	mov dx,offset PRER_NE_SET_VIVOD
	call PRINT
	ret
	
	UST:
	; ��࠭塞 �⠭����� ��ࠡ��稪:
	call SAVE_STAND
	
	mov dx,offset PRER_SET_VIVOD
	call PRINT
	
	push ds
	; ����� � ds:dx ���� ��襣� ��ࠡ��稪�:
	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	
	; ���塞 ���� ��ࠡ��稪� ���뢠��� 09h:
	mov ah,25h
	mov al,09h
	int 21h
	pop ds
	
	; ��⠢�塞 �ணࠬ�� १����⭮:
	mov dx,offset LAST_BYTE
	mov cl,4
	shr dx,cl ; ����� dx �� 16
	add dx,1
	add dx,40h
	
	mov al,0
	mov ah,31h
	int 21h ; ��⠢�塞 ��� ��ࠡ��稪 � �����
	
	ret
SET_ROUT ENDP
;---------------------------------------
; 㤠����� ��襣� ��ࠡ��稪�:
DEL_ROUT PROC
	push dx
	push ax
	push ds
	push es
	
	
	mov ax,KEEP_PSP 
	mov es,ax ; ����� � es PSP ��襩 �ணࠬ�
	cmp byte ptr es:[82h],'/'
		jne UDAL_KONEC
	cmp byte ptr es:[83h],'u'
		jne UDAL_KONEC
	cmp byte ptr es:[84h],'n'
		jne UDAL_KONEC
	
	mov dx,offset PRER_DEL_VIVOD
	call PRINT
	
	CLI
	
	mov ah,35h
	mov al,09h
	int 21h ; ����稫� � ES:BX ���� ��襣� ��ࠡ��稪�
	mov si,offset KEEP_IP
	sub si,offset ROUT
	
	; �����頥� �⠭����� ��ࠡ��稪:
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h
	
	; 㤠�塞 �� ����� ��� ��ࠡ��稪:
	mov ax,es:[bx+si-2] ; ����稫� psp ��襣� ��ࠡ��稪�
	mov es,ax
	mov ax,es:[2ch] ; ����稫� ᥣ����� ���� �।�
	push es
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	mov ah,49h
	int 21h
	
	STI
	jmp UDAL_KONEC2
	
	UDAL_KONEC:
	mov dx,offset PRER_UZHE_SET_VIVOD
	call PRINT
	UDAL_KONEC2:
	
	pop es
	pop ds
	pop ax
	pop dx
	ret
DEL_ROUT ENDP
;---------------------------------------
; ��࠭���� ���� �⠭���⭮�� ��ࠡ��稪� � KEEP_IP � KEEP_CS:
SAVE_STAND PROC
	push ax
	push bx
	push es
	mov ah,35h
	mov al,09h
	int 21h ; ����稫� � ES:BX ���� ��ࠡ��稪� ���뢠���
	mov KEEP_CS, ES
	mov KEEP_IP, BX
	pop es
	pop bx
	pop ax
	ret
SAVE_STAND ENDP
;---------------------------------------
BEGIN:
	mov ax,DATA
	mov ds,ax
	mov KEEP_PSP, es
	call PROV_ROUT
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

; ������
DATA SEGMENT
	PRER_SET_VIVOD db '��⠭���� ��ࠡ��稪� ���뢠���',0DH,0AH,'$'
	PRER_DEL_VIVOD db '�������� ��ࠡ��稪� ���뢠���',0DH,0AH,'$'
	PRER_UZHE_SET_VIVOD db '��ࠡ��稪 ���뢠��� 㦥 ��⠭�����',0DH,0AH,'$'
	PRER_NE_SET_VIVOD db '��ࠡ��稪 ���뢠��� �� ��⠭�����',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS
 END BEGIN