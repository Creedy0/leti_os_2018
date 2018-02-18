TESTPC	SEGMENT
        ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        org 100H	; �ᯮ�짮���� ᬥ饭�� 100h (256 ����) �� ��砫�
				; ᥣ����, � ����� ����㦥�� ��� �ணࠬ��
START:  JMP BEGIN	; START - �窠 �室�

; ������:
; �������⥫�� �����
EOF	EQU '$'
_endl	db ' ',0DH,0AH,'$' ; ����� ��ப�

_seg_inaccess	db '�������� ���� ������㯭�� �����:     ',0DH,0AH,EOF
_seg_env		db '�������� ���� �।�:    ',0DH,0AH,EOF
_tail		db '����� ��������� ��ப�: ', EOF
_env 		db '����ন��� ������ �।�:',0DH,0AH,EOF
_dir	db '���� ����㦠����� �����:',0DH,0AH,EOF
_symb  db '��� ᨬ�����',0DH,0AH,EOF

; ���������:
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP

;���� AL ��ॢ������ � ��� ᨬ���� ���. �᫠ � AX
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  ;� AL - �����, � AH - ������
	pop CX
	ret
BYTE_TO_HEX ENDP

;��ॢ�� � 16 �/� 16-� ࠧ�來��� �᫠
;� AX - �᫮, DI - ���� ��᫥����� ᨬ����
WRD_TO_HEX PROC near
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

;��ॢ�� � 10�/�, SI - ���� ���� ����襩 ����
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

; �㭪�� ��।������ ᥣ���⭮�� ���� ������㯭�� �����
SEGMENT_INACCESS PROC NEAR
	push ax
	push di

	mov ax, ds:[02h] ; ����㦠�� ����
	mov di, offset _seg_inaccess
	add di, 40 ; ����㦠�� ���� ��᫥����� ᨬ���� _seg_inacces
	call WRD_TO_HEX ; ��ॢ���� ax � 16��

	pop di
	pop ax
	ret
SEGMENT_INACCESS ENDP

; �㭪�� ��।������ ᥣ���⭮�� ���� �।�, ��।�������� �ணࠬ��
SEGMENT_ENVIRONMENT PROC NEAR
	push ax
	push di

	mov ax, ds:[2Ch] ; ����㦠�� ����
	mov di, offset _seg_env
	add di, 27 ; ����㦠�� ���� ��᫥����� ᨬ���� _seg_env
	call WRD_TO_HEX

	pop di
	pop ax
	ret
SEGMENT_ENVIRONMENT ENDP

; �㭪�� ��।���� 墮�� �ணࠬ���� ��ப� � ᨬ���쭮� ����
TAIL PROC NEAR
	push ax
	push cx
	push dx
	push si
	push di

	mov ch, ds:[80h] ; ����㦠�� � ch �᫮ ᨬ����� � ���� ��������� ��ப�
	mov si, 81h
	mov di, offset _tail
	add di, 20
CopyCmd:
	cmp ch, 0h
	je NoCmd ; �᫨ �᫮ ᨬ����� � 墮�� ��������� ��ப� = 0
;No NoCmd
	mov al, ds:[si] ; �����㥬 � di ��।��� ����� (�� ����� si)
	mov [di], al    ; 墮�� ��������� ��ப�
	inc di ; ᬥ頥� ���� si � di
	inc si ;  �� ���� ᨬ��� ��ࠢ�
	dec ch ; --ch
	jmp CopyCmd ; 横���᪨ �����㥬 ��������� ��ப�
NoCmd:
  mov al, 0h
  mov [di], al
	mov dx, offset _symb
	call PRINT

	pop di
	pop si
	pop dx
	pop cx
	pop ax
	ret
TAIL ENDP

; �㭪�� ��।���� ᮤ�ন��� ������ �।�
CONTENT PROC NEAR
	push ax
	push dx
	push ds
	push es

	; �뢮� ᮤ�ন���� ������ �।�
	mov dx, offset _env
	call PRINT

	mov ah, 02h ; �㤥� �뢮���� ��ᨬ���쭮 dl
	mov es, ds:[2Ch]
	xor si, si
WriteCont:
	mov dl, es:[si]
	int 21h			; �뢮�
	cmp dl, 0h		; �஢��塞 �� ����� ��ப�
	je	EndOfLine
	inc si			; ���室�� � ��ᬮ�७�� ᫥�. ᨬ����
	jmp WriteCont
EndOfLine:
	mov dx, offset _endl ; ��릮� �� ����� �����
	call PRINT
	inc si
	mov dl, es:[si]
	cmp dl, 0h		; �஢��塞 �� ����� ᮤ�ন���� ������ �।� (�᫨ ��� ����� 0 ����)
	jne WriteCont

	mov dx, offset _endl
	call PRINT

	pop es
	pop ds
	pop dx
	pop ax
	ret
CONTENT ENDP

; �뢮� ��� ����㦠����� �����
PATH PROC NEAR
	push ax
	push dx
	push ds
	push es
	mov dx, offset _dir
	call PRINT

	add si, 3h
	mov ah, 02h
	mov es, ds:[2Ch]
	WriteDir:
	mov dl, es:[si]
	cmp dl, 0h
	je EndOfDir
	int 21h
	inc si
	jmp WriteDir
	EndOfDir:

	pop es
	pop ds
	pop dx
	pop ax
	ret
PATH ENDP

; �㭪�� �뢮�� �� �࠭
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

; ���
BEGIN:
	call SEGMENT_INACCESS
  mov dx, offset _seg_inaccess
	call PRINT
	call SEGMENT_ENVIRONMENT
  mov dx, offset _seg_env
	call PRINT
  mov dx, offset _tail
	call PRINT
	call TAIL
  mov dx, offset _endl
	call PRINT
	call CONTENT
	call PATH
	mov dx, offset _endl
	call PRINT

; ��室 � DOS
	xor al, al
	mov ah, 4ch
	int 21h

TESTPC 	ENDS
		END START	; ����� �����
