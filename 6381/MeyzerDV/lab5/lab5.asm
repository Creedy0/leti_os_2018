ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
; ���������
;---------------------------------------
; ��楤�� ��ࠡ��稪� ���뢠���
ROUT PROC FAR
	jmp INT_CODE
	SIGNATURE db 'AAAB'
	KEEP_IP DW 0
	KEEP_CS DW 0 ; ��६���� ��� �࠭���� CS � IP ��ண� ��ࠡ��稪�
	KEEP_PSP DW 0 ; ��६����� ��� �࠭���� ���� PSP � ���짮��⥫�᪮�� ��ࠡ��稪�
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
	INT_CODE:
	
	mov CS:KEEP_AX, ax
	mov CS:KEEP_SS, ss
	mov CS:KEEP_SP, sp
	mov ax, ISTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
			; ����� 28 �㤠���
	; �஢��塞 ��襤訩 scan-���
		in al,60h
		cmp al,11h ; 11h - ������ w
		jne ROUT_STNDRD ; �᫨ ��襫 ��㣮� ᪠�-���, ��� � �⠭����� ��ࠡ��稪
	; �஢��塞, ����� �� ���� Alt(12 ��� ���ﭨ�)
		mov ax,0040h
		mov es,ax
		mov al,es:[18h]
		and al,00000010b
		jz ROUT_STNDRD ; �᫨ �� �����, ���� � �⠭����� ��ࠡ��稪
	jmp ROUT_USER

	
	ROUT_STNDRD:
	; ���室�� � �⠭����� ��ࠡ��稪 ���뢠���:
		pop es
		pop ds
		pop dx
		mov ax, CS:KEEP_AX
		mov sp, CS:KEEP_SP
		mov ss, CS:KEEP_SS
		jmp dword ptr CS:KEEP_IP
		; jmp ROUT_END
	
	ROUT_USER:
	; ���짮��⥫�᪨� ��ࠡ��稪:
	push ax
	;᫥���騩 ��� ����室�� ��� ��ࠡ�⪨ �����⭮�� ���뢠���
		in al, 61h   ;����� ���祭�� ���� �ࠢ����� ��������ன
		mov ah, al     ; ��࠭��� ���
		or al, 80h    ;��⠭����� ��� ࠧ�襭�� ��� ����������
		out 61h, al    ; � �뢥�� ��� � �ࠢ���騩 ����
		xchg ah, al    ;������� ��室��� ���祭�� ����
		out 61h, al    ;� ������� ��� ���⭮
		mov al, 20h     ;��᫠�� ᨣ��� "����� ���뢠���"
		out 20h, al     ; ����஫���� ���뢠��� 8259
	pop ax

	ROUT_PUSH_TO_BUFF:
	; ������ ᨬ���� � ���� ����������:
		mov ah,05h
		mov cl,'D'
		mov ch,00h
		int 16h
		or al,al
		jz ROUT_END ; �஢��塞 ��९������� ���� ����������
		; ��頥� ���� ����������:
			CLI
			mov ax,es:[1Ah]
			mov es:[1Ch],ax ; ����頥� ���� ��砫� ���� � ���� ����
			STI
			jmp ROUT_PUSH_TO_BUFF
		
	ROUT_END:
	pop es
	pop ds
	pop dx
	mov ax, CS:KEEP_AX
	mov al,20h
	out 20h,al
	mov sp, CS:KEEP_SP
	mov ss, CS:KEEP_SS
	iret
ROUT ENDP
	LAST_BYTE:
;---------------------------------------
; ��뢠�� ���뢠���, �����饥 ��ப�.
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
;
CHECK_INT PROC
	; �஢�ઠ, ��⠭������ �� ���짮��⥫�᪨� ��ࠡ��稪 ���뢠��� � ����஬ 09h
		mov ah,35h
		mov al,09h
		int 21h ; ����砥� � es ᥣ���� ���뢠���, � � bx - ᬥ饭��
	
	mov si, offset SIGNATURE
	sub si, offset ROUT ; � si �࠭���� ᬥ饭�� ᨣ������ �⭮�⥫쭮 ��砫� �㭪樨 ROUT
	
	; �஢�ઠ ᨣ������ ('AAAB'):
	; ES - ᥣ���� �㭪樨 ���뢠���
	; BX - ᬥ饭�� �㭪樨 ���뢠���
	; SI - ᬥ饭�� ᨣ������ �⭮�⥫쭮 ��砫� �㭪樨 ���뢠���
		mov ax,'AA'
		cmp ax,es:[bx+si]
		jne LABEL_INT_IS_NOT_LOADED
		mov ax,'BA'
		cmp ax,es:[bx+si+2]
		jne LABEL_INT_IS_NOT_LOADED
		jmp LABEL_INT_IS_LOADED 
	
	LABEL_INT_IS_NOT_LOADED:
	; ��⠭���� ���짮��⥫�᪮� �㭪樨 ���뢠���
		mov dx,offset STR_INT_IS_LOADED
		call PRINT
		call SET_INT ; ��⠭����� ���짮��⥫�᪮� ���뢠���
		; ���᫥��� ����室����� ������⢠ ����� ��� १����⭮� �ணࠬ��:
			mov dx,offset LAST_BYTE ; ����� � dx ࠧ��� ��� ᥣ���� CODE, ᮤ�ঠ饩 ���짮��⥫�᪮� ���뢠��� � ����室��� ��� � ����� ��� ����
			mov cl,4
			shr dx,cl
			inc dx	; ��ॢ��� ��� � ��ࠣ���
			add dx,CODE ; �ਡ���塞 ���� ᥣ���� CODE
			sub dx,CS:KEEP_PSP ; ���⠥� ���� ᥣ���� PSP, ��࠭������ � KEEP_PSP
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
		je CI_DELETE ; �᫨ ����, ����� ���� 㤠���� ��� ��ࠡ��稪
		CI_DONT_DELETE:
		pop bx
		pop es
	
	mov dx,offset STR_INT_IS_ALR_LOADED
	call PRINT
	ret
	
	; ���ࠥ� ���짮��⥫�᪨� ��ࠡ��稪 ���뢠���
		CI_DELETE:
		pop bx
		pop es
		; ES - ᥣ���� �㭪樨 ���뢠���
		; BX - ᬥ饭�� �㭪樨 ���뢠���
		; SI - ᬥ饭�� ᨣ������ �⭮�⥫쭮 ��砫� �㭪樨 ���뢠���
		call DELETE_INT
		mov dx,offset STR_INT_IS_UNLOADED
		call PRINT
		ret
CHECK_INT ENDP
;---------------------------------------
; ��⠭���� ���짮��⥫�᪮�� ��ࠡ��稪� ���뢠��� ROUT
SET_INT PROC
	push ds
	mov ah,35h; ���࠭塞 ���� ��ࠡ��稪
	mov al,09h
	int 21h
	mov CS:KEEP_IP,bx
	mov CS:KEEP_CS,es
	
	mov dx,offset ROUT ; ��⠭�������� ����
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h
	pop ds
	ret
SET_INT ENDP 
;---------------------------------------
; �������� ���짮��⥫�᪮�� ��ࠡ��稪� ���뢠��� ROUT
DELETE_INT PROC
	push ds
	; ����⠭�������� �⠭����� ����� ���뢠���:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		
		mov ax,2509h
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
DELETE_INT ENDP 
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	mov CS:KEEP_PSP,es
	
	call CHECK_INT
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
	STR_INT_IS_ALR_LOADED DB 'User interruption is already loaded',0DH,0AH,'$'
	STR_INT_IS_UNLOADED DB 'User interruption is successfully unloaded',0DH,0AH,'$'
	STR_INT_IS_LOADED DB 'User interruption is loaded',0DH,0AH,'$'
	STRENDL db 0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	dw 50 dup (?)
STACK ENDS
 END START