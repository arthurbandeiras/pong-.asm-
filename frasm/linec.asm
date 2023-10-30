; vers�o de 10/05/2007
; corrigido erro de arredondamento na rotina line.
; circle e full_circle disponibilizados por Jefferson Moro em 10/2009
;
segment code
..start:
    		mov 		ax,data
    		mov 		ds,ax
    		mov 		ax,stack
    		mov 		ss,ax
    		mov 		sp,stacktop


; salvar modo corrente de video(vendo como est� o modo de video da maquina)
            mov  		ah,0Fh
    		int  		10h
    		mov  		[modo_anterior],al   


; alterar modo de video para gr�fico 640x480 16 cores
    	mov     	al,12h
   		mov     	ah,0
    	int     	10h



;***************************************************;
;			   definições pré código				;
;***************************************************;

;limpa si, di, e define onde a bolinha começa
		xor si, si
		xor di, di
		mov si, 319
		mov di, 240
		mov cx, 50000 ;define a quantidade de loops completos (tempo de jogo)
		call set_caracter1
desenha_cabecalho:
	mov		byte[cor],branco_intenso	;borda cabeçalho (x1, y1, x2, y2)
	mov		ax,0
	push		ax
	mov		ax,431
	push		ax
	mov		ax,640
	push		ax
	mov		ax,431
	push		ax
	call line
	pop ax
	pop ax
	pop ax

main:
	
	mov		byte[cor],branco_intenso	;raquete (x1, y1, x2, y2)
	mov		ax,599
	push		ax
	mov		ax,word[raqi]
	push		ax
	mov		ax,599
	push		ax
	mov		ax,word[raqf]
	push		ax
	call line
	pop ax
	pop ax
	pop ax

	;circulos vermelhos
	mov     byte[cor],vermelho  
	mov     ax, si
	push        ax
	mov     ax, di
	push        ax
	mov     ax,10
	push        ax
	call full_circle
	
	mov cx, 1
	push cx
	mov dx, 2
	push dx
	mov al, 0 
	mov ah, 86h
	int 15h		;função delay
	pop cx
	pop dx

	pop ax
	pop ax
	pop ax

	;apaga circulos (circulos pretos)
	mov     byte[cor],preto
	mov     ax, si
	push        ax
	mov     ax, di
	push        ax
	mov     ax,10
	push        ax
	call full_circle
	pop ax
	pop ax
	pop ax		


	add si, word[vx]
	add di, word[vy]


	cmp di, 20
	jle bate_baixo
volta1:
	cmp si, 620
	jge bate_direita 
volta2:
	cmp di, 405
	jge bate_cima
volta3:
	cmp si, 20
	jle	bate_esquerda
volta4:
	mov ah, 01h
	int 16h
	jnz tecla_clicada
	call bate_raquete
checagem:
loop main

bate_baixo:
	mov ax, word[vatual]
	push ax
	mov word[vy], ax
	pop ax  
jmp volta1

bate_direita:
	mov ax, -1
	push ax
	mul word[vatual]
	mov word[vx], ax
	pop ax
	call ponto_comp    
jmp volta2

bate_cima:
	mov ax, -1
	push ax
	mul word[vatual]
	mov word[vy], ax
	pop ax
jmp volta3

bate_esquerda:
	mov ax, word[vatual]
	push ax
	mov word[vx], ax
	pop ax
jmp volta4

bate_raquete:
	cmp si, 589
	jl checagem	
	cmp di, word[raqi]	;vê se x é menor
	jl checagem	
	cmp di, word[raqf]	;vê se x é maior
	jg checagem
	mov ax, -1		;passou na checagem, inverte vx
	push ax
	mul word[vatual]
	mov word[vx], ax 
	pop ax
	call ponto_player
jmp checagem

move_main:
	jmp main

tecla_clicada:
	mov ah, 08h
	int 21h
	cmp al, 's' ; 's'
	jz move_encerra
	cmp al, 'c' ; 'c'
	jz raquete_cima
	cmp al, 'b'	; 'b'
	jz raquete_baixo
	cmp al, 'm' ; 'm'
	jz reduz_velo
	cmp al, 'p' ; 'p'
	jz move_aumenta_velo
jmp main

raquete_cima:
	cmp word[raqf], 415
	jge move_main
	mov		byte[cor],preto		;apaga raquete antiga;
	mov		ax,599
	push		ax
	mov		ax,word[raqi]
	push		ax
	mov		ax,599
	push		ax
	mov		ax,word[raqf]
	push		ax
	call line
	pop ax
	pop ax
	pop ax
	add word[raqi], 15		;aumenta raqi e raqf;
	add word[raqf], 15
jmp main

raquete_baixo:
	cmp word[raqi], 15
	jle move_main
	mov		byte[cor],preto		;apaga raquete antiga;
	mov		ax,599
	push		ax
	mov		ax,word[raqi]
	push		ax
	mov		ax,599
	push		ax
	mov		ax,word[raqf]
	push		ax
	call line
	pop ax
	pop ax
	pop ax
	add word[raqi], -15		;aumenta raqi e raqf;
	add word[raqf], -15
jmp main

move_main2:
	jmp main
move_encerra:
	jmp encerra
move_aumenta_velo:
	jmp aumenta_velo

reduz_velo:					;função chamada com 'm'
	cmp word[vatual], 4
	jle move_main2
	add word[vatual], -4
	add byte[v_printa_int], -1
	call altera_v_printa
	
	cmp word[vx], 0
	jl reduz_vx_neg
	jg reduz_vx_pos
vy_reduz:					;tag para os casos de mudança
	cmp word[vy], 0
	jl reduz_vy_neg
	jg reduz_vy_pos
	jmp move_main

aumenta_velo:				;função chamada com 'p'
	cmp word[vatual], 12
	jge move_main2
	add word[vatual], 4
	add byte[v_printa_int], 1
	call altera_v_printa
	
	cmp word[vx], 0
	jl aumenta_vx_neg
	jg aumenta_vx_pos
vy_aumenta:					;tag para os casos de mudança
	cmp word[vy], 0
	jl aumenta_vy_neg
	jg aumenta_vy_pos
	jmp move_main

reduz_vx_neg:			;casos de mudança de velocidade
	add word[vx], 4
	jmp vy_reduz
reduz_vx_pos:
	add word[vx], -4
	jmp vy_reduz
aumenta_vx_neg:
	add word[vx], -4
	jmp vy_aumenta
aumenta_vx_pos:
	add word[vx], 4
	jmp vy_aumenta
reduz_vy_neg:
	add word[vy], 4
	jmp move_main
reduz_vy_pos:
	add word[vy], -4
	jmp move_main
aumenta_vy_neg:
	add word[vy], -4
	jmp move_main
aumenta_vy_pos:
	add word[vy], 4
	jmp move_main


ponto_player:
	xor ax, ax
	xor dx, dx
	add word[ponto_play], 1
	mov ax, word[ponto_play]
	push ax
	mov cx, 10
	push cx
	div cx
	add dl, '0'
	mov byte[pnt_play_str + 1], dl
	add al, '0'
	mov byte[pnt_play_str], al
	pop cx
	pop ax
set_ponto_player:
	mov     	cx,2			;n�mero de caracteres
    mov     	bx,0
    mov     	dh,1			;linha 0-29
    mov     	dl,25			;coluna 0-79
	mov		byte[cor],branco_intenso
print_player:
		call	cursor
    	mov     al,[bx+pnt_play_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    print_player
	ret

ponto_comp:
	xor ax, ax
	xor dx, dx
	add word[ponto_pc], 1
	mov ax, word[ponto_pc]
	push ax
	mov cx, 10
	push cx
	div cx
	add dl, '0'
	mov byte[pnt_pc_str + 1], dl
	add al, '0'
	mov byte[pnt_pc_str], al
	pop cx
	pop ax
set_ponto_comp:
	mov     	cx,2			;n�mero de caracteres
    mov     	bx,0
    mov     	dh,1			;linha 0-29
    mov     	dl,30			;coluna 0-79
	mov		byte[cor],branco_intenso
print_comp:
		call	cursor
    	mov     al,[bx+pnt_pc_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    print_comp
	ret

set_caracter1:
    mov     	cx,58			;n�mero de caracteres
    mov     	bx,0
    mov     	dh,0			;linha 0-29
    mov     	dl,0			;coluna 0-79
	mov		byte[cor],branco_intenso
l4:
		call	cursor
    	mov     al,[bx+mens1]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    l4
set_caracter2:
	mov     	cx,62			;n�mero de caracteres
    mov     	bx,0
    mov     	dh,1			;linha 0-29
    mov     	dl,0			;coluna 0-79
	mov		byte[cor],branco_intenso
write_name:
		call	cursor
    	mov     al,[bx+mens2]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_name

jmp desenha_cabecalho

altera_v_printa:
	mov ax, 0
	mov al, byte[v_printa_int]
	add al, 30h
	mov byte[v_printa_str], al

	mov     	cx,1			;n�mero de caracteres
    mov     	bx,0
    mov     	dh,1			;linha 0-29
    mov     	dl,58			;coluna 0-79
	mov		byte[cor],branco_intenso
print_v:
		call	cursor
    	mov     al,[bx+v_printa_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    print_v
	ret
encerra:
	mov  	ah,0   			; set video mode
	mov  	al,[modo_anterior]   	; modo anterior
	int  	10h
	mov 	ax, 4c00h
	int 	21h
;***************************************************************************
;
;   fun��o cursor
;
; dh = linha (0-29) e  dl=coluna  (0-79)
cursor:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
		mov     	ah,2
		mov     	bh,0
		int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;_____________________________________________________________________________
;
;   fun��o caracter escrito na posi��o do cursor
;
; al= caracter a ser escrito
; cor definida na variavel cor
caracter:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
    		mov     	ah,9
    		mov     	bh,0
    		mov     	cx,1
   		mov     	bl,[cor]
    		int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;_____________________________________________________________________________
;
;   fun��o plot_xy
;
; push x; push y; call plot_xy;  (x<639, y<479)
; cor definida na variavel cor
plot_xy:
		push		bp
		mov		bp,sp
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
	    mov     	ah,0ch
	    mov     	al,[cor]
	    mov     	bh,0
	    mov     	dx,479
		sub		dx,[bp+4]
	    mov     	cx,[bp+6]
	    int     	10h
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		4
;_____________________________________________________________________________
;    fun��o circle
;	 push xc; push yc; push r; call circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor
circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	
	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov 	dx,bx	
	add		dx,cx       ;ponto extremo superior
	push    ax			
	push	dx
	call plot_xy
	
	mov		dx,bx
	sub		dx,cx       ;ponto extremo inferior
	push    ax			
	push	dx
	call plot_xy
	
	mov 	dx,ax	
	add		dx,cx       ;ponto extremo direita
	push    dx			
	push	bx
	call plot_xy
	
	mov		dx,ax
	sub		dx,cx       ;ponto extremo esquerda
	push    dx			
	push	bx
	call plot_xy
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay:				;loop
	mov		si,di
	cmp		si,0
	jg		inf       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar
inf:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar:	
	mov		si,dx
	add		si,ax
	push    si			;coloca a abcisa x+xc na pilha
	mov		si,cx
	add		si,bx
	push    si			;coloca a ordenada y+yc na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,dx
	push    si			;coloca a abcisa xc+x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do s�timo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc+x na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do oitavo octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	add		si,cx
	push    si			;coloca a ordenada yc+y na pilha
	call plot_xy		;toma conta do terceiro octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do sexto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quinto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quarto octante
	
	cmp		cx,dx
	jb		fim_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;    fun��o full_circle
;	 push xc; push yc; push r; call full_circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor					  
full_circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov		si,bx
	sub		si,cx
	push    ax			;coloca xc na pilha			
	push	si			;coloca yc-r na pilha
	mov		si,bx
	add		si,cx
	push	ax		;coloca xc na pilha
	push	si		;coloca yc+r na pilha
	call line
	
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay_full:				;loop
	mov		si,di
	cmp		si,0
	jg		inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar_full
inf_full:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar_full:	
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call 	line
	
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call	line
	
	cmp		cx,dx
	jb		fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay_full		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_full_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;
;   fun��o line
;
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
		push		bp
		mov		bp,sp
		pushf                        ;coloca os flags na pilha
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		mov		ax,[bp+10]   ; resgata os valores das coordenadas
		mov		bx,[bp+8]    ; resgata os valores das coordenadas
		mov		cx,[bp+6]    ; resgata os valores das coordenadas
		mov		dx,[bp+4]    ; resgata os valores das coordenadas
		cmp		ax,cx
		je		line2
		jb		line1
		xchg		ax,cx
		xchg		bx,dx
		jmp		line1
line2:		; deltax=0
		cmp		bx,dx  ;subtrai dx de bx
		jb		line3
		xchg		bx,dx        ;troca os valores de bx e dx entre eles
line3:	; dx > bx
		push		ax
		push		bx
		call 		plot_xy
		cmp		bx,dx
		jne		line31
		jmp		fim_line
line31:		inc		bx
		jmp		line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
	; cx > ax
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		ja		line32
		neg		dx
line32:		
		mov		[deltay],dx
		pop		dx

		push		ax
		mov		ax,[deltax]
		cmp		ax,[deltay]
		pop		ax
		jb		line5

	; cx > ax e deltax>deltay
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx

		mov		si,ax
line4:
		push		ax
		push		dx
		push		si
		sub		si,ax	;(x-x1)
		mov		ax,[deltay]
		imul		si
		mov		si,[deltax]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar1
		add		ax,si
		adc		dx,0
		jmp		arc1
ar1:		sub		ax,si
		sbb		dx,0
arc1:
		idiv		word [deltax]
		add		ax,bx
		pop		si
		push		si
		push		ax
		call		plot_xy
		pop		dx
		pop		ax
		cmp		si,cx
		je		fim_line
		inc		si
		jmp		line4

line5:		cmp		bx,dx
		jb 		line7
		xchg		ax,cx
		xchg		bx,dx
line7:
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx



		mov		si,bx
line6:
		push		dx
		push		si
		push		ax
		sub		si,bx	;(y-y1)
		mov		ax,[deltax]
		imul		si
		mov		si,[deltay]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar2
		add		ax,si
		adc		dx,0
		jmp		arc2
ar2:		sub		ax,si
		sbb		dx,0
arc2:
		idiv		word [deltay]
		mov		di,ax
		pop		ax
		add		di,ax
		pop		si
		push		di
		push		si
		call		plot_xy
		pop		dx
		cmp		si,dx
		je		fim_line
		inc		si
		jmp		line6

fim_line:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		8

;*******************************************************************
segment data

cor		db		branco_intenso

;	I R G B COR
;	0 0 0 0 preto
;	0 0 0 1 azul
;	0 0 1 0 verde
;	0 0 1 1 cyan
;	0 1 0 0 vermelho
;	0 1 0 1 magenta
;	0 1 1 0 marrom
;	0 1 1 1 branco
;	1 0 0 0 cinza
;	1 0 0 1 azul claro
;	1 0 1 0 verde claro
;	1 0 1 1 cyan claro
;	1 1 0 0 rosa
;	1 1 0 1 magenta claro
;	1 1 1 0 amarelo
;	1 1 1 1 branco intenso

preto		equ		0
azul		equ		1
verde		equ		2
cyan		equ		3
vermelho	equ		4
magenta		equ		5
marrom		equ		6
branco		equ		7
cinza		equ		8
azul_claro	equ		9
verde_claro	equ		10
cyan_claro	equ		11
rosa		equ		12
magenta_claro	equ		13
amarelo		equ		14
branco_intenso	equ		15

modo_anterior	db		0
linha   	dw  		0
coluna  	dw  		0
deltax		dw		0
deltay		dw		0	
mens1    	db  'Exercicio de Programacao de Sistemas Embarcados 1 - 2023/2'
mens2		db	'Arthur Bandeira Salvador 00 X 00 Computador   Velocidade (1/3)'

vx			dw	4
vy			dw	4
vatual 		dw	4
v_printa_int	db	1
v_printa_str	db	'1', '$'
raqi		dw	214
raqf		dw	254

ponto_play	dw	0
ponto_pc	dw	0

pnt_play_str	db	'00'
pnt_pc_str		db	'00'
;*************************************************************************
segment stack stack
    		resb 		512
stacktop:

