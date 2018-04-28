
;��������
LR3_1	SEGMENT
		ASSUME	CS:LR3_1,	DS:LR3_1,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN

;����������
av_memory  db  'Available memory:          Bytes;',0dh,0ah,'$'
ext_memory  db  'Extended memory:           Kilobytes;',0dh,0ah,'$'
MCB_Capt  db  'List of MCB:',0dh,0ah,'$'
MCB_Type  db  'Type of MCB:   h; $'
MCB_Seg  db  'Segment`s adress:     h; $'
MCB_Size  db  'MCB size:       b$'
MCB_Tail  db  ';               ',0dh,0ah,'$'
IF_ERROR	db 	'ERROR!!!$'

;���������
; ����� �� �����
Write_msg	PROC	near
		mov	ah,09h
		int	21h
		ret
Write_msg	ENDP
; ������� �������� �� 2 �/� � 16 �������� �����
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near
; ���� � AL ����������� � ��� ������� �����. ����� � AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; � AL ������� �����
		pop		cx 			; � AH �������
		ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near
; ������ � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;----------------------------
BYTE_TO_DEC		PROC	near
; ������� ������ ����� � 10 �/�, SI - ����� ���� ������� �����
		push	cx
		push	dx
		push	ax
		xor		ah,ah
		xor		dx,dx
		mov		cx,10
	loop_bd:
		div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		loop_bd
		cmp		ax,00h
		jbe		end_l
		or		al,30h
		mov		[si],al
	end_l:	
		pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP
;---------------------------
WRD_TO_DEC		PROC	near
; ������� 2 ������ � 10 �/�, SI - ����� ���� ������� �����
		push	cx
		push	dx
		push	ax
		mov		cx,10
	wrd_loop_bd:
		div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		wrd_loop_bd
		cmp		ax,00h
		jbe		wrd_end_l
		or		al,30h
		mov		[si],al
	wrd_end_l:	
		pop		ax
		pop		dx
		pop		cx
		ret
WRD_TO_DEC		ENDP
; ����������� ��������� ������ ����� BEGIN
; ����������� ����������� ������
GET_EXT_MEMORY    PROC    near
	push ax
	push bx
	push si
	push dx
	mov	al, 30h ; ������ ������ ������ CMOS
	out	70h, al 
	in	al, 71h ; ������ �������� �����
	mov	bl, al ; ������� ����������� ������
	mov	al, 31h ; ������ ������ ������ CMOS
	out	70h, al
	in	al, 71h ; ������ �������� ����� ������� ����������� ������
	mov ah, al
	mov al, bl ; ������ � AX ������ ����������� ������
	sub dx, dx
	lea si, ext_memory+25
	call WRD_TO_DEC
	lea dx, ext_memory
	call write_msg
	pop	dx
	pop	si
	pop	bx
	pop	ax
	ret
GET_EXT_MEMORY    ENDP

; �������� ������������� ��������� �����
GET_TAIL	PROC	near
		push si
		push cx
		push bx
		push ax
		mov	bx,0008h
		mov	cx,4
	RE:
		mov	ax,es:[bx]
		mov	[si],ax
		add bx,2h
		add	si,2h
		loop RE
		pop	ax
    	pop	bx
    	pop	cx
		pop	si
		ret
GET_TAIL	ENDP
; ���������� � ������� ������� ������ ���������� �������
GET_MCB	PROC  near
	push ax
	push bx
	push cx
	push dx
	lea	dx, MCB_Capt
	call Write_msg
	mov	ah,52h
	int	21h
	mov	es,es:[bx-2]
	mov	bx,1
	REPEAT:
		sub	ax,ax
		sub	cx,cx
		sub	di,di
		sub	si,si
		mov	al,es:[0000h]
		call BYTE_TO_HEX
		lea	di,MCB_Type+13
		mov	[di],ax
		cmp	ax,4135h
		je 	MEN_BX
	STEP:
		lea	di,MCB_Seg+21
		mov	ax,es:[0001h]
		call WRD_TO_HEX
		mov	ax,es:[0003h]
		mov cx,10h
    	mul cx
    	lea	si,MCB_Size+15
		call WRD_TO_DEC
		lea	dx,MCB_Type
		call Write_msg
		lea	dx,MCB_Seg
		call Write_msg
		lea	dx,MCB_Size
		call Write_msg

		lea	si,MCB_Tail+2
		call GET_TAIl
		lea	dx,MCB_Tail
		call Write_msg

		cmp	bx,0
		jz	END_P
		xor ax, ax
    	mov ax, es
    	add ax, es:[0003h]
    	inc ax
    	mov es, ax
		jmp REPEAT
	END_P:
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret
	MEN_BX:
		mov	bx,0
		jmp STEP
GET_MCB		ENDP

BEGIN:
; ���������� ��������� �������
	push ax
	push bx
	push cx
	push dx
	mov ah, 4Ah
    mov bx, 0ffffh
    int 21h

    mov ax,bx
    mov cx,10h
    mul cx
    lea  si,av_memory+25
    call WRD_TO_DEC
	lea	dx,av_memory
	call Write_msg

    mov	bx, 4096h
	mov	ah, 48h
	int	21h
	
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	jc 	Y_ERROR ;�������� ����� CF
	jmp N_ERROR 
		
	Y_ERROR:
		lea 	dx,IF_ERROR
		call	Write_msg
		jmp 	END3
	N_ERROR:
		call	GET_EXT_MEMORY
		call	GET_MCB
		
; ����� � DOS
	END3:
		xor		al,al
		mov		ah,3Ch
		int		21h
		ret
LR3_1	ENDS
		END 	START