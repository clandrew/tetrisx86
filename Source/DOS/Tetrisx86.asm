	jmp start

vidmem	dw	0a000h
grid	db	512 dup (?)
active	db	8 dup (?)
;active	db	1,1,2,2,3,3,4,4
next	db	8 dup (?)
predict	db	8 dup (?)
tickhi	dw	?
ticklo	dw	?
pieces	db	1,4,2,4,3,4,4,4,1,4,1,5,2,5,3,5,3,4,1,5,2,5,3,5,1,4,1,5,2,4,2,5,1,5,1,6,2,4,2,5,1,5,2,4,2,5,3,5,1,4,2,4,2,5,3,5
axisx	db	1
axisy	db	1
topext	dw	30
leftext	dw	120
gameover db	?

drawsquare proc
;colour in al, screen coords in (bx,dx)
	push ax
	push cx
	push es
	push di

	mov es, vidmem
	mov di,0
	mov cx,dx
drawsquare_rowshift:
	add di,320
	loop drawsquare_rowshift
	
	add di,bx
	
	mov cx,4
drawsquare_pxdown:
	push cx
	mov cx,4

drawsquare_pxacross:
	mov es:[di],al
	inc di
	loop drawsquare_pxacross
	
	pop cx
	add di,316
	loop drawsquare_pxdown
	
	pop di
	pop es
	pop cx
	pop ax
	ret
drawsquare endp

drawgrid proc
	push ax
	push bx
	push cx
	push dx
	
	mov al,1
	mov cx,512
	mov bx,0 ;x count
	mov dx,0 ;y count
	
drawgrid_eachindex:
	push bx
	mov bx,512
	sub bx,cx
	mov al, grid[bx]
	pop bx	
	push bx ;stay 0-aligned
	push dx
	add bx,leftext
	add dx,topext
	call drawsquare
	pop dx
	pop bx
	add bx,4
	cmp bx,64
	jne drawgrid_noshift
	mov bx,0
	add dx,4
drawgrid_noshift:
	loop drawgrid_eachindex
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
drawgrid endp

drawactive proc
	push ax
	push bx
	push cx
	push dx
	
	mov al,3
	mov cx,8
drawactive_eachblock:
	mov bx,cx
	dec bx
	mov dl,active[bx]
	mov dh,0
	dec cx
	dec bx
	mov bl,active[bx]
	mov bh,0
	shl bx,2
	add bx,leftext
	shl dx,2
	add dx,topext
	call drawsquare	
	loop drawactive_eachblock
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
drawactive endp

moveleft proc
	push ax
	push cx
	push dx
	call leftpredict
	cmp al,0
	jne moveleft_barrier
	dec active[0]
	dec active[2]
	dec active[4]
	dec active[6]
	dec axisx
moveleft_barrier:
	pop dx
	pop cx
	pop ax
	ret
moveleft endp

movedown proc
	push ax
	push cx
	push dx
	call downpredict
	cmp al,0
	jne movedown_set
	inc active[1]
	inc active[3]
	inc active[5]
	inc active[7]
	inc axisy
	jmp movedown_done
movedown_set:
	call setblock
	call checktoclear
	call newblock
movedown_done:
	pop dx
	pop cx
	pop ax
	ret
movedown endp

moveright proc
	push ax
	push cx
	push dx
	call rightpredict
	cmp al,0
	jne moveright_barrier
	inc active[0]
	inc active[2]
	inc active[4]
	inc active[6]
	inc axisx
moveright_barrier:
	pop dx
	pop cx
	pop ax
	ret
moveright endp

rotate proc
	push ax
	call rotatepredict
	cmp al,0
	jne rotate_barrier
	mov al,predict[0]
	mov active[0],al
	mov al,predict[1]
	mov active[1],al
	mov al,predict[2]
	mov active[2],al
	mov al,predict[3]
	mov active[3],al
	mov al,predict[4]
	mov active[4],al
	mov al,predict[5]
	mov active[5],al
	mov al,predict[6]
	mov active[6],al
	mov al,predict[7]
	mov active[7],al
rotate_barrier:
	pop ax
	ret
rotate endp

newblock proc
	push ax
	push bx
	push cx
	push dx
	mov ah,0
	int 1Ah ;system clock int
	mov ax,dx
	mov ah,0
	mov bl,7
	div bl
	mov al,ah
	mov ah,0
	shl ax,3
	
	mov bx,offset pieces
	add bx,ax
	mov cx,8

newblock_eachblock:
	mov al,[bx]
	push bx
	mov bx,8
	sub bx,cx
	mov active[bx],al
	pop bx
	inc bx                                          
	loop newblock_eachblock
	
	mov axisx,2
	mov axisy,5
	
	pop dx
	pop cx
	pop bx
	pop ax	
	ret
newblock endp

copyactivetopredict proc
	push bx
	push cx
	push dx
	
;	mov cx,7
;copy_iterate:
;	mov bx,cx
;	mov dh,active[bx]
;	mov predict[bx],dh
;	loop copy_iterate

	mov bl,active[0]
	mov predict[0],bl
	mov bl,active[1]
	mov predict[1],bl
	mov bl,active[2]
	mov predict[2],bl
	mov bl,active[3]
	mov predict[3],bl
	mov bl,active[4]
	mov predict[4],bl
	mov bl,active[5]
	mov predict[5],bl
	mov bl,active[6]
	mov predict[6],bl
	mov bl,active[7]
	mov predict[7],bl

	pop dx
	pop cx
	pop bx
	ret
copyactivetopredict endp

leftpredict proc ;al zero if possible, nonzero otherwise
	call copyactivetopredict
	dec predict[0]
	dec predict[2]
	dec predict[4]
	dec predict[6]
	call checkpredict
	ret
leftpredict endp

downpredict proc
	call copyactivetopredict
	inc predict[1]
	inc predict[3]
	inc predict[5]
	inc predict[7]
	call checkpredict
	ret
downpredict endp

rightpredict proc
	call copyactivetopredict
	inc predict[0]
	inc predict[2]
	inc predict[4]
	inc predict[6]
	call checkpredict
	ret
rightpredict endp

rotatepredict proc ;set result in predict[]
	push bx
	mov bl,active[0]
	mov bh,active[1]
	sub bl,axisx
	sub bh,axisy
	neg bl
	add bl,axisy
	add bh,axisx
	mov predict[0],bh
	mov predict[1],bl
	mov bl,active[2]
	mov bh,active[3]
	sub bl,axisx
	sub bh,axisy
	neg bl
	add bl,axisy
	add bh,axisx
	mov predict[2],bh
	mov predict[3],bl	
	mov bl,active[4]
	mov bh,active[5]
	sub bl,axisx
	sub bh,axisy
	neg bl
	add bl,axisy
	add bh,axisx
	mov predict[4],bh
	mov predict[5],bl
	mov bl,active[6]
	mov bh,active[7]
	sub bl,axisx
	sub bh,axisy
	neg bl
	add bl,axisy
	add bh,axisx
	mov predict[6],bh
	mov predict[7],bl
	call checkpredict
	pop bx
	ret
rotatepredict endp

setblock proc
	push bx
	push cx
	push dx
	mov ch,0
	mov dh,0
	mov dl,active[7]
	shl dx,4
	mov cl,active[6]
	mov bx,dx
	add bx,cx
	cmp grid[bx],2
	je set_gameover
	mov grid[bx],2
	mov dh,0
	mov dl,active[5]
	shl dx,4
	mov cl,active[4]
	mov bx,dx
	add bx,cx
	cmp grid[bx],2
	je set_gameover
	mov grid[bx],2
	mov dh,0
	mov dl,active[3]
	shl dx,4
	mov cl,active[2]
	mov bx,dx
	add bx,cx
	cmp grid[bx],2
	je set_gameover
	mov grid[bx],2
	mov dh,0
	mov dl,active[1]
	shl dx,4
	mov cl,active[0]
	mov bx,dx
	add bx,cx
	cmp grid[bx],2
	je set_gameover
	mov grid[bx],2
	jmp setblock_done
set_gameover:
	mov gameover, 1
	
setblock_done:
	pop dx
	pop cx
	pop bx
	ret
setblock endp

checkpredict proc ;zero in al if possible, nonzero otherwise
	push bx	
	push cx
	push dx
;	mov cx,7

;checkpredict_eachblockcoor:	
;	mov bx,cx
;	mov dh,0
;	mov dl,predict[bx]
;	shl dx,4
;	dec bx
;	dec cx
;	add dl,predict[bx]
;	push bx
;	mov bx,dx
;	mov al, grid[bx]
;	pop bx
;	cmp al,1
;	jne checkpredict_misfit
;	loop checkpredict_eachblockcoor	
;	mov al,0
;	jmp checkpredict_done
;checkpredict_misfit:
;	mov al,1

	mov ch,0
	mov dh,0
	mov dl,predict[7]
	shl dx,4
	mov cl,predict[6]
	mov bx,dx
	add bx,cx
	cmp grid[bx],1
	jne checkpredict_misfit
	mov dh,0
	mov dl,predict[5]
	shl dx,4
	mov cl,predict[4]
	mov bx,dx
	add bx,cx
	cmp grid[bx],1	
	jne checkpredict_misfit
	mov dh,0
	mov dl,predict[3]
	shl dx,4
	mov cl,predict[2]
	mov bx,dx
	add bx,cx
	cmp grid[bx],1	
	jne checkpredict_misfit
	mov dh,0
	mov dl,predict[1]
	shl dx,4
	mov cl,predict[0]
	mov bx,dx
	add bx,cx
	cmp grid[bx],1	
	jne checkpredict_misfit
	mov al,0
	jmp checkpredict_done
checkpredict_misfit:
	mov al,1
checkpredict_done:
	pop dx
	pop cx
	pop bx
	ret
checkpredict endp

checktoclear proc ;uses active
	push ax
	push bx
	push cx
	push dx
	;mov cl,0
	;mov ch,0
	mov dl,0
	mov dh,0

	mov cl,0
	push cx
	mov al,active[1]
	cmp al,active[3]
	je check_block1_duplicate
	cmp al,active[5]
	je check_block1_duplicate
	cmp al,active[7]
	je check_block1_duplicate
	
check_block1_duplicate:
	mov al,0
	jmp check_block1_done
check_block1_noduplicate:	
	mov cx,16
	mov bh,0
	mov bl,active[1]
	shl bx,4
	mov al,0
	
check_block1_iterate:
	cmp grid[bx],1
	je check_block1_done
	inc bx
	loop check_block1_iterate
	;row ready to be cleared
	mov al,active[1]
check_block1_done:
	pop cx
	mov cl,al
check_block2:
	mov ch,0
	push cx
	mov al,active[3]
	cmp al,active[5]
	je check_block2_duplicate
	cmp al,active[7]
	je check_block2_duplicate
	jmp check_block2_noduplicate
check_block2_duplicate:
	mov al,0
	jmp check_block2_done
check_block2_noduplicate:
	mov cx,16
	mov bh,0
	mov bl,active[3]
	shl bx,4
	mov al,0
check_block2_iterate:
	cmp grid[bx],1
	je check_block2_done
	inc bx
	loop check_block2_iterate
	;row ready to be cleared
	mov al,active[3]
check_block2_done:
	pop cx
	mov ch,al
check_block3:
	push cx
	mov dl,0
	mov al,active[5]
	cmp al,active[7]
	je check_block3_done
	mov cx,16
	mov bh,0
	mov bl,active[5]
	shl bx,4
check_block3_iterate:
	cmp grid[bx],1
	je check_block3_done
	inc bx
	loop check_block3_iterate
	;row ready to be cleared
	mov dl,active[5]
check_block3_done:
	pop cx
check_block4:
	push cx
	mov dh,0
	mov cx,16
	mov bh,0
	mov bl,active[7]
	shl bx,4
check_block4_iterate:
	cmp grid[bx],1
	je check_block4_done
	inc bx
	loop check_block4_iterate
	;row ready to be cleared
	mov dh,active[7]	

check_block4_done:
	pop cx	
	call clearrows
	pop dx
	pop cx
	pop bx
	pop ax
	ret
checktoclear endp

clearrows proc ;uses cl, ch, dl, dh
	push ax
	push bx
	
	;al - counter for current row index
	;ah - row difference
	mov al,30

clearrows_foreachrow:
	;grid[bx]contains current grid elem index
	mov ah,0
	cmp al, cl
	ja clear1noinc
	inc ah	
clear1noinc:
	cmp al,ch
	ja clear2noinc
	inc ah
clear2noinc:
	cmp al,dl
	ja clear3noinc
	inc ah
clear3noinc:
	cmp al, dh
	ja clear4noinc
	inc ah
clear4noinc:

	push cx
	push dx ;let loop scramble cx, dx
	mov dh, 16
	mov bh,0
	mov bl,al
	shl bx,4
clearrows_foreacheleminrow:
	mov ch,0
	mov cl,ah
	shl cx,4
	sub bx, cx
	mov dl, grid[bx]
	add bx, cx
	mov grid[bx],dl
	inc bx
	dec dh
	cmp dh,0
	jne clearrows_foreacheleminrow	
	
	pop dx
	pop cx
	
	dec al
	cmp al,3
	jne clearrows_foreachrow
	
	;set all grid[item] in each row to 1
	;for each row in grid, starting at the lowest,
	;how many of cl,ch,dl,dh are below?
	;for each of them, take on the value of that many rows above
	pop bx
	pop ax
	ret
clearrow endp

checktime proc ;return al zero if tick, 1 otherwise
	push cx
	push dx
	
	mov ah,0
	int 1Ah ;system clock int
	cmp cx,tickhi
	jb checktime_notick
	cmp dx,ticklo
	jb checktime_notick
	;tick
	add dx,10
	;carry?
	jnc checktime_nocarry
	inc cx
checktime_nocarry:
	mov tickhi,cx
	mov ticklo,dx
	mov al,0
	jmp checktime_done
checktime_notick:
	mov al,1
checktime_done:	
	pop dx
	pop cx
	ret
checktime endp

start:
	push ax
	push bx
	push cx
	push dx
	
	mov ah,0
	mov al,19
	int 10h ;graphics
	
	mov gameover,0 ;flag
	
	mov cx,512
	mov bx, offset grid
iterate_init:
	cmp cx,17
	jb iterate_init_border ;top
	cmp cx,496
	ja iterate_init_border ;bottom
	mov dx,cx
	shr dx,4
	shl dx,4
	cmp dx,cx
	je iterate_init_border ;left
	mov dx,cx
	dec dx
	shr dx,4
	shl dx,4
	inc dx
	cmp dx,cx
	je iterate_init_border	;right
	mov al, 1 ;otherwise
	mov [bx],al
	jmp iterate_init_enditer
iterate_init_border:
	mov al,6
	mov [bx],al
iterate_init_enditer:
	inc bx
	loop iterate_init
	
	;init timer
	mov ah, 0
	int 1Ah
	mov tickhi,cx
	mov ticklo,dx
	
	call newblock
	call drawgrid
	call drawactive
main:
	;mov ah,0
	;int 16h
	call checktime
	cmp al,1
	je notick
	call movedown
	cmp gameover,1
	je end
	call drawgrid
	call drawactive	
notick:
	mov ah,1
	int 16h
	jz main		
	cmp al,27
	je end
	cmp al,"j"
	je keyleft
	cmp al,"k"
	je keydown
	cmp al,"l"
	je keyright
	cmp al,"i"
	je keyrotate
	mov ah,0
	int 16h
	jmp main
keyleft:
	call moveleft
	mov ah,0
	int 16h
	call drawgrid
	call drawactive
	jmp main
keydown:
	call movedown
	cmp gameover,1
	je end
	mov ah,0
	int 16h
	call drawgrid
	call drawactive
	jmp main
keyright:
	call moveright
	mov ah,0
	int 16h
	call drawgrid
	call drawactive
	jmp main
keyrotate:
	call rotate
	mov ah,0
	int 16h
	call drawgrid
	call drawactive
	jmp main
end:
	mov ah,0
	mov al,3
	int 10h ;text
	pop dx
	pop cx
	pop bx
	pop ax
	mov ah,4Ch
	mov al,0
	int 21h