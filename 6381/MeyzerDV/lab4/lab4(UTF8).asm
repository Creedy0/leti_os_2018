﻿; Шаблон текста программы для модуля типа .COM
ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
; ПРОЦЕДУРЫ
;---------------------------------------
; Вызывает прерывание, печатающее строку.
PRINT PROC near
	push ax
	mov al,00h
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

;---------------------------------------
; Установка позиции курсора
setCurs PROC
	push ax
	push bx
	push dx
	push cx
	mov ah,02h
	mov bh,0
	;mov dh,22 ; DH, DL = строка, колонка
	;mov dl,0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
setCurs ENDP
;---------------------------------------
; Получение позиции курсора
; Вход: BH = видео страница
; Выход: DH, DL = текущие строка, колонка курсора
;		 CH, CL = текущие начальная, конечная строки
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
; Функция вывода символа из AL
outputAL PROC
	push ax
	push bx
	push cx
	mov ah,09h   ;писать символ в текущей позиции курсора
	mov bh,0     ;номер видео страницы
	mov bl,07h
	mov cx,1     ;число экземпляров символа для записи
	int 10h      ;выполнить функцию
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP
;---------------------------------------
; Процедура обработчика прерывания
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
	; Меняем стек, сохраняем регистры
	mov KEEP_AX, ax
	mov CS:KEEP_SS, ss
	mov CS:KEEP_SP, sp
	mov ax, ISTACK
	mov ss, ax
	mov sp, 100h
	push dx
	push ds
	push es
	
	; Устанавливаем курсор
	call getCurs
	push dx
	mov dx,0013h
	call setCurs
	
	; Печатаем цифру
	cmp COUNT,0AH
	jl rout_skip
	mov count,0h
	rout_skip:
	mov al,COUNT
	or al,30h
	call outputAL
	
	; Возвращаем курсор
	pop dx
	call setCurs
	inc COUNT

	; Возвращаем стек, восстанавливаем регистры
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
	; Проверка, установлено ли пользовательское прерывание с вектором 1ch
		mov ah,35h
		mov al,1ch
		int 21h ; Получаем в es сегмент прерывания, а в bx - смещение
	
	mov si, offset SIGNATURE
	sub si, offset ROUT ; В si хранится смещение сигнатуры относительно начала функции ROUT
	
	; Проверка сигнатуры ('AAAA'):
	; ES - сегмент функции прерывания
	; BX - смещение функции прерывания
	; SI - смещение сигнатуры относительно начала функции прерывания
		mov ax,'AA'
		cmp ax,es:[bx+si]
		jne LABEL_INT_IS_NOT_LOADED
		cmp ax,es:[bx+si+2]
		jne LABEL_INT_IS_NOT_LOADED
		jmp LABEL_INT_IS_LOADED 
	
	LABEL_INT_IS_NOT_LOADED:
	; Установка пользовательской функции прерывания
		lea dx, STR_INT_IS_LOADED
		call PRINT
		call SET_INT
		; Вычисление необходимого количества памяти для резидентной программы:
			mov dx,offset LAST_BYTE ; Кладём в dx размер части сегмента CODE с обработчиком прерывания
			mov cl,4
			shr dx,cl
			inc dx	; Перевели его в параграфы
			add dx,CODE ; Прибавляем адрес сегмента CODE
			sub dx,KEEP_PSP ; Вычитаем адрес сегмента PSP
		xor al,al
		mov ah,31h
		int 21h ; Оставляем нужное количество памяти(dx - кол-во параграфов) и выходим в DOS, оставляя программу в памяти резидентно
		
	LABEL_INT_IS_LOADED:
	; Смотрим, есть ли в хвосте /un
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
	
	; Убираем пользовательское прерывание
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
; Удаление написанного прерывания ROUT
DEL_INT PROC
		push ds
	; Восстанавливаем стандартный вектор прерывания:
		CLI
		mov dx,ES:[BX+SI+4] ; IP
		mov ax,ES:[BX+SI+6] ; CS
		mov ds,ax
		mov ax,251ch
		int 21h 
	; Освобождаем память:
		push es
		mov ax,ES:[BX+SI+8] ; PSP
		mov es,ax 
		mov es,es:[2Ch] ; Блока переменных среды
		mov ah,49h         
		int 21h
		pop es
		mov es,ES:[BX+SI+8] ; PSP ; Блока резидентной программы
		mov ah, 49h
		int 21h	
		STI
	pop ds
	ret
DEL_INT ENDP
;---------------------------------------
; Установка написанного прерывания ROUT
SET_INT PROC
	push ds
	mov ah,35h; Сохраняем старое прерывание
	mov al,1ch
	int 21h
	mov KEEP_IP,bx
	mov KEEP_CS,es

	mov dx,offset ROUT ; Устанавливаем новое
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