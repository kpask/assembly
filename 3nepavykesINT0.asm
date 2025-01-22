.model small
.stack 100h
.data
    INT_message	db "Dalyba is 0: $"
    enteris db 13,10,"$"
    senasCS dw ?
    senasIP dw ?
    divMessage db "div $"
    regAX dw ?
	regBX dw ?
	regCX dw ?
	regDX dw ?
	regSP dw ?
	regBP dw ?
	regSI dw ?
	regDI dw ?
	msg_al DB "al $"     ;registro zinute
    msg_ah DB "ah $"
    msg_bl DB "bl $"
    msg_bh DB "bh $"
    msg_cl DB "cl $"
    msg_ch DB "ch $"
    msg_dl DB "dl $"
    msg_dh DB "dh $"
    msg_ax DB "ax $"
    msg_bx DB "bx $"
    msg_cx DB "cx $"
    msg_dx DB "dx $"
    msg_sp DB "sp $"
    msg_bp DB "bp $"
    msg_si DB "si $"
    msg_di DB "di $"

.code
    pradzia:
    
        mov ax, @data
        mov ds, ax
        
        mov ax, 0
        mov es, ax

        mov ax, es:[0]
	    mov bx, es:[2]
        mov senasCS, bx
	    mov senasIP, ax

    	MOV	word ptr es:[0], offset ApdorokPertr	;i pertraukimu vektoriu lentele irasau pertraukimo apdorojimo proceduros poslinki nuo CS pradzios
	    MOV	es:[2], cs	;i pertraukimu vektoriu lentele irasau pertraukimo apdorojimo proceduros segmenta (CS)

        xor dx, dx
        mov ax, 1
        mov bx, 0
        div bl

        mov ah, 09h
        lea dx, INT_message
        int 21h

        mov ax, senasIP
	    mov bx, senasCS
	    mov es:[0], ax
	    mov es:[2], bx


    uzdaryti_programa:
	    mov ah, 4Ch
	    int 21h

    ApdorokPertr proc
        ; Į ekraną išvedama informacija galėtų atrodyti taip: Dalyba is nulio! 0000:0128  F7F3   div bx ; dx= 0001, ax= 2532, bx = 0000
        ; segment : offset (cs : ip)

    	mov regAX, ax				
		mov regBX, bx
		mov regCX, cx
		mov regDX, dx
		mov regSP, sp
		mov regBP, bp
		mov regSI, si
		mov regDI, di

        mov ah, 09h
        lea dx, INT_message
        int 21h

        pop si ;pasiimam IP reiksme (kvieciant pertraukima ji buvo i steka padeta paskutine)
		pop di ;pasiimam CS reiksme
		push di ;padedam CS reiksme
		push si ;vel padedam atgal - nagrinejama komanda esancia CS:IP (naudosime DI:SI)

        
        ; spausdinam cs
        mov ax, di
        call printAX
        
        mov dl, ":"
        mov ah, 2
        int 21h

        ; spausdinam ip
        mov ax, si
        call printAX

        mov dl, " "
        mov ah, 2
        int 21h

        mov ax, cs:[si] ; Nuskaitome F7F3
        call printAL    ; Spaudiname F7
        push ax

        ; Spaudiname baitus atvirkščia tvarka
        mov al, ah
        call printAL    ; Spaudiname F3

        mov dl, " "
        mov ah, 2
        int 21h

        mov ah, 09h
        lea dx, divMessage
        int 21h

        pop ax
        call printOperation

        mov dl, ";"
        mov ah, 2
        int 21h

        mov ah, 09h
        lea dx, msg_dx
        int 21h
        mov dl, "="
        mov ah, 2
        int 21h
        mov dl, " "
        mov ah, 2
        int 21h

        mov ax, regDX
        MOV al, ah
        call printAL
        mov ax, regDX
        call printAL

        mov dl, " "
        mov ah, 2
        int 21h

        mov ah, 09h
        lea dx, msg_ax
        int 21h
        mov dl, "="
        mov ah, 2
        int 21h
        mov dl, " "
        mov ah, 2
        int 21h

        mov ax, regAX
        MOV al, ah
        call printAL
        mov ax, regAX
        call printAL

        mov ah, 09h
        lea dx, enteris
        int 21h

        mov ax, senasIP
	    mov bx, senasCS
	    mov es:[0], ax
	    mov es:[2], bx

	    IRET
    ApdorokPertr endp

printOperation:
    cmp al, 247 ; F7 w = 1?
    JE W1
    cmp ah, 243
    JE printBL
    ret
W1:
    cmp ah, 243 ; F3 ; BX
    JE printBX
    ret

printBL:
    mov ah, 09h
    lea dx, msg_bl
    int 21h
    ret

printBX:
    mov ah, 09h
    lea dx, msg_bx
    int 21h
    mov dl, ";"
    mov ah, 2
    int 21h
    mov ah, 09h
    lea dx, msg_bx
    int 21h
    mov dl, "="
    mov ah, 2
    int 21h
    mov ax, regBX
    call printAX
    ret

printAX:
	push ax
	mov al, ah
	call printAL
	pop ax
	call printAL
RET

;>>>>Spausdink tarpa
printSpace:
	push ax
	push dx
		mov ah, 2
		mov dl, " "
		int 21h
	pop dx
	pop ax
RET

;>>>Spausdinti AL reiksme
printAL:
	push ax
	push cx
		push ax
		mov cl, 4
		shr al, cl
		call printHexSkaitmuo
		pop ax
		call printHexSkaitmuo
	pop cx
	pop ax
RET

;>>>Spausdina hex skaitmeni pagal AL jaunesniji pusbaiti (4 jaunesnieji bitai - > AL=72, tai 0010)
printHexSkaitmuo:
	push ax
	push dx
	
	and al, 0Fh ;nunulinam vyresniji pusbaiti AND al, 00001111b
	cmp al, 9
	jbe PrintHexSkaitmuo_0_9
	jmp PrintHexSkaitmuo_A_F
	
	PrintHexSkaitmuo_A_F: 
	sub al, 10 ;10-15 ===> 0-5
	add al, 41h
	mov dl, al
	mov ah, 2; spausdiname simboli (A-F) is DL'o
	int 21h
	jmp PrintHexSkaitmuo_grizti
	
	PrintHexSkaitmuo_0_9: ;0-9
	mov dl, al
	add dl, 30h
	mov ah, 2 ;spausdiname simboli (0-9) is DL'o
	int 21h
	jmp printHexSkaitmuo_grizti
	
	printHexSkaitmuo_grizti:
	pop dx
	pop ax
RET

    end pradzia