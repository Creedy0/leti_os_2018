; ������ ⥪�� �ணࠬ�� ��� ����� ⨯� .COM
ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
; ���������
;---------------------------------------
; ��뢠�� ���뢠���, �����饥 ��ப�.
PRINT PROC near
	push ax
	mov al,00h
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

;---------------------------------------
; ��⠭���� ����樨 �����
setCurs PROC
	push ax
	push bx
	push dx
	push cx
	mov ah,02h
	mov bh,0
	;mov dh,22 ; DH, DL = ��ப�, �������
	;mov dl,0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
setCurs ENDP
;---------------------------------------
; ����祭�� ����樨 �����
; �室: BH = ����� ��࠭��
; ��室: DH, DL = ⥪�騥 ��ப�, ������� �����
;		 CH, CL = ⥪�騥 ��砫쭠�, ����筠� ��ப�
getCurs PROC
	push ax
	push bx
	;push dx
	push cx
	mov ah,03h
	mov bh,0
	int 10h
	pop cx
	;pop dx
	pop bx
	pop ax
	ret
getCurs ENDP

;---------------------------------------
; �㭪�� �뢮�� ᨬ���� �� AL
outputAL PROC
	push ax
	push bx
	push cx
	mov ah,09h   ;����� ᨬ��� � ⥪�饩 ����樨 �����
	mov bh,0     ;����� ����� ��࠭���
	mov bl,07h
	mov cx,1     ;�᫮ ������஢ ᨬ���� ��� �����
	int 10h      ;�믮����� �㭪��
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP
;---------------------------------------
; ��楤�� ��ࠡ��稪� ���뢠���
ROUT PROC FAR
	jmp INT_CODE
	SIGNATURE db 'AAAA'
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_PSP DW 0
	SHOULD_BE_DELETED DB 0
	COUNT DB 0
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
	INT_CODE:
	; ���塞 �⥪, ��࠭塞 ॣ�����
	mov KEEP_AX, ax
	mov CS:KEEP_SS, ss
	mov CS:KEEP_SP, sp
	mov ax, ISTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
	; ��⠭�������� �����
	call getCurs
	push dx
	mov dx,0013h
	call setCurs
	
	; ���⠥� ����
	cmp COUNT,0AH
	jl rout_skip
	mov count,0h
	rout_skip:
	mov al,COUNT
	or al,30h
	call outputAL
	
	; �����頥� �����
	pop dx
	call setCurs
	inc COUNT

	; �����頥� �⥪, ����⠭�������� ॣ�����
	pop es
	pop ds
	pop dx
	mov ax, KEEP_AX
	mov al,20h
	out 20h,al
	mov sp, KEEP_SP
	mov ss, KEEP_SS
	
	iret
ROUT ENDP
LAST_BYTE:
;---------------------------------------
;
CHECK_INT PROC
	; �஢�ઠ, ��⠭������ �� ���짮��⥫�᪮� ���뢠��� � ����஬ 1ch
		mov ah,35h
		mov al,1ch
		int 21h ; ����砥� � es ᥣ���� ���뢠���, � � bx - ᬥ饭��
	
	mov si, offset SIGNATURE
	sub si, offset ROUT ; � si �࠭���� ᬥ饭�� ᨣ������ �⭮�⥫쭮 ��砫� �㭪樨 ROUT
	
	; �஢�ઠ ᨣ������ ('AAAA'):
	; ES - ᥣ���� �㭪樨 ���뢠���
	; BX - ᬥ饭�� �㭪樨 ���뢠���
	; SI - ᬥ饭�� ᨣ������ �⭮�⥫쭮 ��砫� �㭪樨 ���뢠���
		mov ax,'AA'
		cmp ax,es:[bx+si]
		jne LABEL_INT_IS_NOT_LOADED
		cmp ax,es:[bx+si+2]
		jne LABEL_INT_IS_NOT_LOADED
		jmp LABEL_INT_IS_LOADED 
	
	LABEL_INT_IS_NOT_LOADED:
	; ��⠭���� ���짮��⥫�᪮� �㭪樨 ���뢠���
		lea dx, STR_INT_IS_LOADED
		call PRINT
		call SET_INT
		; ���᫥��� ����室����� ������⢠ ����� ��� १����⭮� �ணࠬ��:
			mov dx,offset LAST_BYTE ; ����� � dx ࠧ��� ��� ᥣ���� CODE � ��ࠡ��稪�� ���뢠���
			mov cl,4
			shr dx,cl
			inc dx	; ��ॢ��� ��� � ��ࠣ���
			add dx,CODE ; �ਡ���塞 ���� ᥣ���� CODE
			sub dx,KEEP_PSP ; ���⠥� ���� ᥣ���� PSP
		xor al,al
		mov ah,31h
		int 21h ; ��⠢�塞 �㦭�� ������⢮ �����(dx - ���-�� ��ࠣ�䮢) � ��室�� � DOS, ��⠢��� �ணࠬ�� � ����� १����⭮
		
	LABEL_INT_IS_LOADED:
	; ����ਬ, ���� �� � 墮�� /un
		push es
		push bx
		mov bx,KEEP_PSP
		mov es,bx
		cmp byte ptr es:[82h],'/'
		jne CI_DONT_DELETE
		cmp byte ptr es:[83h],'u'
		jne CI_DONT_DELETE
		cmp byte ptr es:[84h],'n'
		je CI_DELETE
		CI_DONT_DELETE:
		pop bx
		pop es
	
	mov dx,offset STR_INT_IS_ALR_LOADED
	call PRINT
	ret
	
	; ���ࠥ� ���짮��⥫�᪮� ���뢠���
		CI_DELETE:
		pop bx
		pop es
		; mov byte ptr es:[bx+si+10],1
		call DEL_INT
		mov dx,offset STR_INT_IS_UNLOADED
		call PRINT
		ret
CHECK_INT ENDP
;---------------------------------------
; �������� ����ᠭ���� ���뢠��� ROUT
DEL_INT PROC
		push ds
	; ����⠭�������� �⠭����� ����� ���뢠���:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		mov ax,251ch
		int 21h 
	; �᢮������� ������:
		push es
		mov ax,ES:[BX+SI+8] ; PSP
		mov es,ax 
		mov es,es:[2Ch] ; ����� ��६����� �।�
		mov ah,49h         
		int 21h
		pop es
		mov es,ES:[BX+SI+8] ; PSP ; ����� १����⭮� �ணࠬ��
		mov ah, 49h
		int 21h	
		STI
	pop ds
	ret
DEL_INT ENDP
;---------------------------------------
; ��⠭���� ����ᠭ���� ���뢠��� ROUT
SET_INT PROC
	push ds
	mov ah,35h; ���࠭塞 ��஥ ���뢠���
	mov al,1ch
	int 21h
	mov KEEP_IP,bx
	mov KEEP_CS,es

	mov dx,offset ROUT ; ��⠭�������� �����
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,1ch
	int 21h
	pop ds
	ret
SET_INT ENDP 
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	mov KEEP_PSP,es
	
	call CHECK_INT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
	
CODE ENDS

STACK SEGMENT STACK
	dw 100h dup (?)
STACK ENDS

DATA SEGMENT
	STR_INT_IS_ALR_LOADED DB 'User interruption is already loaded',0DH,0AH,'$'
	STR_INT_IS_UNLOADED DB 'User interruption is successfully unloaded',0DH,0AH,'$'
	STR_INT_IS_LOADED DB 'User interruption is loaded',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS
 END START