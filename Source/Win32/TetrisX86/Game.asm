.model flat,C
option casemap:none
ExitProcess				  proto stdcall :DWORD
RegisterClassExA		  proto stdcall :DWORD
CreateWindowExA			  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DefWindowProcA			  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD
ShowWindow				  proto stdcall :DWORD,:DWORD
UpdateWindow			  proto stdcall :DWORD
GetMessageA				  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD
TranslateMessage		  proto stdcall :DWORD
DispatchMessageA		  proto stdcall :DWORD
BeginPaint				  proto stdcall :DWORD,:DWORD
EndPaint				  proto stdcall :DWORD,:DWORD
FillRect				  proto stdcall :DWORD,:DWORD,:DWORD
CreateSolidBrush		  proto stdcall :DWORD
SetPixel				  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD
QueryPerformanceCounter   proto stdcall :DWORD
QueryPerformanceFrequency proto stdcall :DWORD
SetTimer				  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD
InvalidateRect		      proto stdcall :DWORD,:DWORD,:DWORD
CreateCompatibleDC		  proto stdcall :DWORD
CreateCompatibleBitmap    proto stdcall :DWORD,:DWORD,:DWORD
SelectObject              proto stdcall :DWORD,:DWORD
BitBlt					  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
StretchBlt			      proto stdcall :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DeleteObject			  proto stdcall :DWORD
DeleteDC				  proto stdcall :DWORD
GetClientRect             proto stdcall :DWORD,:DWORD
DrawTextA				  proto stdcall :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
.stack 64

.data
WNDCLASSEXA STRUCT
   cbSize            DWORD      ?
   style             DWORD      ?
   lpfnWndProc       DWORD      ?
   cbClsExtra        DWORD      ?
   cbWndExtra        DWORD      ?
   hInstance         DWORD      ?
   hIcon             DWORD      ?
   hCursor           DWORD      ?
   hbrBackground     DWORD      ?
   lpszMenuName      DWORD      ?
   lpszClassName     DWORD      ?
   hIconSm           DWORD      ?
 WNDCLASSEXA ENDS

RECT STRUCT
  left    dd      ?
  top     dd      ?
  right   dd      ?
  bottom  dd      ?
RECT ENDS

PAINTSTRUCT STRUCT
  hdc           DWORD      ?
  fErase        DWORD      ?
  rcPaint       RECT       <>
  fRestore      DWORD      ?
  fIncUpdate    DWORD      ?
  rgbReserved   BYTE 32 dup(?)
PAINTSTRUCT ENDS

LARGE_INTEGER UNION
    STRUCT
      LowPart  DWORD ?
      HighPart DWORD ?
    ENDS
  QuadPart QWORD ?
LARGE_INTEGER ENDS

; Strings
MyWindowClassName	db "MyWindowClass", 0
MyWindowName		db "TetrixX86", 0
NextText			db "Next", 0
GameOverText		db "Game Over", 0

; Global variables
Hwnd				dd ?
PaintDC				dd ?
IntermediateDC		dd ?
BlackBrush			dd ?
OrangeBrush			dd ?
MagentaBrush		dd ?
Grid				db	200 dup (?)
GridRowStartIndices db  0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190
GridColors			dd  0FF0000h, 0FFh, 0FF00FFh, 0FFFFh, 0FFFF00h, 80FFh, 8F8F8Fh, 0FF00h
TickHi				dd	?
TickLo				dd	?
PerfFreqHi			dd  ?
PerfFreqLo			dd  ?

;						I					R					L					O
pieces1				db	4,2,5,2,6,2,7,2,	4,2,4,3,5,3,6,3,	6,2,4,3,5,3,6,3,	4,2,4,3

;						O, cont'd			Z					T					S
pieces2				db  5,2,5,3,4,			3,4,4,5,2,5,3,4,	3,5,2,5,3,6,3,		5,3,6,3,4,4,5,4

active				db	8 dup (?)
activeColorIndex	db  ?
nextBlockIndex      db  ?
Pieces				db 56 dup (0dah)
axisx				db	1
axisy				db	1
topext				dd	30
leftext				dd	30
predict				db	8 dup (?)
gameover		    db	?
running				db  1

.code


drawsquare proc
;colour in al, screen coords in (bx,dx)
	local currentX, currentY, colorRef, rowCount : DWORD

	push eax
	push ebx
	mov colorRef, 0
	mov ebx, 0
	mov bl, al	
	shl ebx, 2
	mov eax, GridColors[ebx]
	mov colorRef, eax
	pop ebx
	pop eax

	mov rowCount, 0
	mov currentX, ebx
	mov currentY, edx

drawsquare_doRow:
	mov currentX, ebx

	; Accounts for the fact that SetPixel will scramble basically every all purpose register.
	push eax
	push ebx
	push ecx
	push edx
	invoke SetPixel,				IntermediateDC, currentX, currentY, colorRef
	inc currentX
	invoke SetPixel,				IntermediateDC, currentX, currentY, colorRef
	inc currentX
	invoke SetPixel,				IntermediateDC, currentX, currentY, colorRef
	inc currentX
	invoke SetPixel,				IntermediateDC, currentX, currentY, colorRef
	inc currentX
	pop edx
	pop ecx
	pop ebx
	pop eax

	inc currentY
	inc rowCount
	cmp rowCount, 4
	jne drawsquare_doRow

	ret
drawsquare endp

drawgrid proc
	push ax
	push bx
	push cx
	push dx
	
	mov al,1
	mov ecx,200
	mov ebx,0 ;x count
	mov edx,0 ;y count
	
drawgrid_eachindex:
	push ebx
	mov ebx,200
	sub ebx,ecx
	mov al, Grid[bx]
	pop ebx	
	push ebx ;stay 0-aligned
	push edx
	add ebx,leftext
	add edx,topext
	call drawsquare
	pop edx
	pop ebx
	add bx,4  ; y+=SizePerSquare
	cmp bx,40 ; if y == Width * SizePerSquare
	jne drawgrid_noshift
	mov bx,0
	add dx,4  ; x+=SizePerSquare
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
	
	mov al,activeColorIndex
	mov cx,8
drawactive_eachblock:
	mov ebx, 0
	mov bx,cx
	dec bx
	mov edx, 0
	mov dl,active[bx]
	mov dh,0
	dec cx
	dec bx
	mov bl,active[bx]
	mov bh,0
	shl bx,2
	add ebx,leftext
	shl dx,2
	add edx,topext
	call drawsquare	
	loop drawactive_eachblock
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
drawactive endp


drawnext proc
	push ax
	push bx
	push cx
	push dx
		
	mov al,nextBlockIndex
	inc al ; Store the color index here

	mov ebx, 0
	mov bl, nextBlockIndex
	shl bl, 3

	mov ecx, 4

drawnext_eachCoordinatePair:
	mov al, Pieces[ebx] ; X coordinate
	shl al,2
	inc ebx
	mov dl, Pieces[ebx] ; Y coordinate
	shl dl, 2
	inc ebx
	push ebx
	mov bl, al
	mov al, nextBlockIndex
	inc al
	add bl, 90
	add dl, 16
	call drawsquare	
	pop ebx
loop drawnext_eachCoordinatePair
			
	pop dx
	pop cx
	pop bx
	pop ax
	ret
drawnext endp

MyWindowProc proc 
	local localHwnd, message, wParam, lParam: DWORD
	local paintStruct : PAINTSTRUCT
	local paintStructAddress : DWORD
	local fillRect : RECT
	local clientRect : RECT
	local fillRectAddress : DWORD
	local bitmap, oldBitmap : DWORD
	local clientWidth, clientHeight : DWORD
	mov eax,						[ebp + 8]
	mov localHwnd,					eax
	mov eax,						[ebp + 12]
	mov message,					eax
	mov eax,						[ebp + 16]
	mov wParam,						eax
	mov eax,						[ebp + 20]
	mov lParam,						eax

	cmp message, 15
	je paintMessage

	cmp message, 16
	je closeMessage

	cmp message, 20
	je eraseBackgroundMessage

	cmp message, 257
	je keyupMessage

	jmp defaultWindowHandler

paintMessage:
	lea eax,						clientRect
	invoke GetClientRect,			Hwnd, eax
	mov eax,						clientRect.right
	sub eax,						clientRect.left
	mov clientWidth,				eax
	mov eax,						clientRect.bottom
	sub eax,						clientRect.top
	mov clientHeight,				eax

	lea eax,						paintStruct
	mov paintStructAddress,			eax
	invoke BeginPaint,				localHwnd, paintStructAddress
	mov PaintDC,					eax
	invoke CreateCompatibleDC,		PaintDC
	mov IntermediateDC,				eax
	invoke CreateCompatibleBitmap,	PaintDC, 200, 200
	mov bitmap,						eax
	invoke SelectObject,			IntermediateDC, bitmap
	mov oldBitmap,					eax
	
	lea eax,						fillRect
	mov fillRectAddress,			eax

	mov fillRect.left,				0
	mov fillRect.top,				0
	mov fillRect.right,				800
	mov fillRect.bottom,			800
	invoke FillRect,				IntermediateDC, fillRectAddress, BlackBrush
	
	mov fillRect.left,				26
	mov fillRect.top,				26
	mov fillRect.right,				74
	mov fillRect.bottom,			114
	invoke FillRect,				IntermediateDC, fillRectAddress, OrangeBrush

	call drawgrid
	call drawactive
	call drawnext
		
	mov fillRect.left,				100
	mov fillRect.top,				0
	mov fillRect.right,				200
	mov fillRect.bottom,			200
	invoke DrawTextA,			    IntermediateDC, offset NextText, 4, fillRectAddress, 0
	
	cmp gameover, 1
	jne drawgameover_done
	mov fillRect.left,				15
	mov fillRect.top,				50
	mov fillRect.right,				200
	mov fillRect.bottom,			200
	invoke DrawTextA,			    IntermediateDC, offset GameOverText, 9, fillRectAddress, 0
drawgameover_done:

	invoke StretchBlt,				PaintDC, 0, 0, clientWidth, clientHeight, IntermediateDC, 0, 0, 200, 200, 0CC0020h 
	invoke SelectObject,			IntermediateDC, oldBitmap
	invoke DeleteObject,			bitmap
	invoke DeleteDC,				IntermediateDC

	invoke EndPaint,				localHwnd, paintStructAddress
	mov eax,						0
	jmp MyWindowProc_done
	 
closeMessage:
	mov running,					0
	mov eax,						0
	jmp MyWindowProc_done	

eraseBackgroundMessage:
	mov eax,						1
	jmp MyWindowProc_done

keyupMessage:
	cmp gameover, 1
	je checkForEscape

	cmp wParam, 37
	je pressKeyLeft
	cmp wParam, 74
	je pressKeyLeft
	
	cmp wParam, 38
	je pressKeyUp
	cmp wParam, 73
	je pressKeyUp

	cmp wParam, 39
	je pressKeyRight
	cmp wParam, 76
	je pressKeyRight

	cmp wParam, 40
	je pressKeyDown
	cmp wParam, 75
	je pressKeyDown

	jmp defaultWindowHandler

checkForEscape:	
	cmp wParam, 27
	jne defaultWindowHandler ; 
	call InitializeGame
	mov eax,						0
	jmp MyWindowProc_done	


pressKeyLeft:
	call MoveLeft
	invoke InvalidateRect, Hwnd, 0, 0
	mov eax,						0
	jmp MyWindowProc_done	

pressKeyUp:
	call Rotate
	invoke InvalidateRect, Hwnd, 0, 0
	mov eax,						0
	jmp MyWindowProc_done

pressKeyRight:
	call MoveRight
	invoke InvalidateRect, Hwnd, 0, 0
	mov eax,						0
	jmp MyWindowProc_done	

pressKeyDown:
	call MoveDown
	invoke InvalidateRect, Hwnd, 0, 0
	mov eax,						0
	jmp MyWindowProc_done	
	
defaultWindowHandler:
	invoke DefWindowProcA,			localHwnd, message, wParam, lParam
	; Return the result up to the caller of this by preserving eax.
MyWindowProc_done:
	ret
MyWindowProc endp

RegisterMyWindow proc
	local windowclass: WNDCLASSEXA
	mov windowclass.cbSize,			48		; 12 times 4, see declaration
	mov windowclass.style,			3		; CS_HREDRAW | CS_VREDRAW
	lea eax,						MyWindowProc
	mov windowclass.lpfnWndProc,	eax
	mov windowclass.cbClsExtra,		0
	mov windowclass.cbWndExtra,		0
	mov windowclass.hInstance,		5		; Picked arbitrarily.
	mov windowclass.hIcon,			0
	mov windowclass.hCursor,		0
	mov windowclass.hbrBackground,	0
	mov windowclass.lpszMenuName,	0
	lea eax,						MyWindowClassName
	mov windowclass.lpszClassName,	eax
	mov windowclass.hIconSm,		0
	lea eax,						windowclass
	invoke RegisterClassExA,		eax		; Returns a WORD
	ret
RegisterMyWindow endp

CreateMyWindow proc
	local className : DWORD
	local windowName : DWORD

	lea eax, MyWindowClassName
	mov className, eax

	lea eax, MyWindowName
	mov windowName, eax

	;								extStyle	class		window			style		x(default)	y	width	height	parent	menu	instance	lpParam
	invoke CreateWindowExA,			0,			className,	windowName,		0cf0000h,	080000000h, 0,	800,	800,	0,		0,		5,			0
	mov Hwnd, eax

	invoke CreateSolidBrush,		0 ; Black
	mov BlackBrush, eax

	invoke CreateSolidBrush,		55AAh ;
	mov OrangeBrush, eax
	
	invoke CreateSolidBrush,		0ff00ffh ; Black
	mov MagentaBrush, eax

	ret
CreateMyWindow endp

ShowMyWindow proc
	invoke ShowWindow,				Hwnd, 10 ; SW_SHOWDEFAULT
	invoke UpdateWindow,			Hwnd
	ret
ShowMyWindow endp

GetRandomBlockIndex proc ; Stores result in al
	local performanceCount : LARGE_INTEGER

	lea eax, performanceCount
	invoke QueryPerformanceCounter,		eax
	mov ebx, performanceCount.LowPart
	mov ax, bx
	mov ah,0 
	mov bl,7
	div bl
	mov al,ah 
	mov ah,0
	ret
GetRandomBlockIndex endp

NewBlock proc
	local thisIndex : BYTE
	push ax
	push bx
	push cx
	push dx
	
	mov ax, 0
	mov al, nextBlockIndex
	mov thisIndex, al
	
	mov ax, 0
	call GetRandomBlockIndex
	mov nextBlockIndex, al
	
	mov al, thisIndex
	mov activeColorIndex, al
	inc activeColorIndex
	shl ax,3
	
	mov ebx, offset Pieces
	add ebx,eax
	mov ecx,8 ; Loops 8 times because there are four (x,y) coordinates.

newblock_eachblock:
	mov al,[ebx]
	push ebx
	mov ebx,8
	sub bx,cx
	mov active[ebx],al
	pop ebx
	inc bx                                          
	loop newblock_eachblock

	dec active[1]
	dec active[3]
	dec active[5]
	dec active[7]
	
	mov axisx,5
	mov axisy,2
	
	pop dx
	pop cx
	pop bx
	pop ax	
	ret
NewBlock endp

InitializePieces proc
	mov ecx, 0

InitializePieces_loop:
	mov al, pieces1[ecx]
	mov Pieces[ecx], al
	mov ah, pieces2[ecx]
	mov Pieces[ecx+28], ah
	inc ecx
	cmp ecx, 28
	jne InitializePieces_loop

	ret
InitializePieces endp

InitializeGame proc
	mov gameover, 0

	call InitializePieces

	mov cx,200
	lea ebx, Grid
InitializeGame_forEachCell:
	mov eax, 0
	mov [ebx], eax ;otherwise
	inc ebx
	loop InitializeGame_forEachCell

iterate_init_enditer:
	
	call GetRandomBlockIndex
	mov ah, 6
	sub ah, al
	mov al, ah
	mov nextBlockIndex, al

	call NewBlock

	ret
InitializeGame endp

copyactivetopredict proc
	push bx
	push cx
	push dx

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

GetGridValueAtPosition proc ; x coordinate in cl, y coordinate in dl. result in al
	mov eax, 0
	mov ebx, 0
	mov bl, dl
	mov al, GridRowStartIndices[ebx]
	add al, cl
	mov al, Grid[eax]
	ret
GetGridValueAtPosition endp

IsValidSpace proc ; x coordinate in cl, y coordinate in dl. Boolean result in eax
	cmp cl, 9 ; 10-1
	ja invalidSpace
	cmp dl, 19 ; 20 - 1
	ja invalidSpace

	; Look up into the grid at this position
	call GetGridValueAtPosition
	cmp eax, 0 ; 0 means empty space
	jne invalidSpace
	mov eax, 1
	ret	
invalidSpace:
	mov eax, 0
	ret
IsValidSpace endp

checkpredict proc ;zero in al if possible, nonzero otherwise
	push ebx	
	push ecx
	push edx
	
	mov cl, predict[0]
	mov dl, predict[1]
	call IsValidSpace
	test eax, eax
	je checkpredict_misfit
	
	mov cl, predict[2]
	mov dl, predict[3]
	call IsValidSpace
	test eax, eax
	je checkpredict_misfit
	
	mov cl, predict[4]
	mov dl, predict[5]
	call IsValidSpace
	test eax, eax
	je checkpredict_misfit

	mov cl, predict[6]
	mov dl, predict[7]
	call IsValidSpace
	test eax, eax
	je checkpredict_misfit

	mov al, 0
	jmp checkpredict_done

checkpredict_misfit:
	mov al,1
checkpredict_done:
	pop edx
	pop ecx
	pop ebx
	ret
checkpredict endp

ClearRow proc
	; Argument: eax contains index of which row to clear
	local currentRowIndex, aboveRowIndex, currentColumnIndex, rowToClear : DWORD
	push eax
	push ebx
	mov rowToClear, eax
	mov currentColumnIndex, 0

ClearRow_perColumn:
	mov eax, rowToClear
	mov currentRowIndex, eax
	mov aboveRowIndex, eax
	dec aboveRowIndex

ClearRow_perCell:

	; Source- above cell indexed by ebx
	mov ebx, aboveRowIndex
	mov bl, GridRowStartIndices[ebx]
	mov bh, 0
	add ebx, currentColumnIndex

	; Dest- below cell, indexed by eax
	mov eax, currentRowIndex
	mov al, GridRowStartIndices[eax]
	mov ah, 0
	add eax, currentColumnIndex

	mov bl, Grid[ebx]
	mov Grid[eax], bl
	
	cmp aboveRowIndex, 1
	je ClearRow_GoToNextColumn
	dec currentRowIndex
	dec aboveRowIndex
	jmp ClearRow_perCell

ClearRow_GoToNextColumn:
	inc currentColumnIndex	
	cmp currentColumnIndex, 10
	jne ClearRow_perColumn
	
ClearRow_done:
	pop ebx
	pop eax
	ret
ClearRow endp

checktoclear proc
	local currentRowIndex, currentColumnIndex : DWORD
	push eax
	push ebx
	push ecx
	push edx

	; Assess which rows need to be cleared, and clear them. In theory if we wanted to be super optimized
	; we could just check the rows that are involved with the active piece. This is a super lazy approach

	mov currentRowIndex, 19 ; 20 - 1

	mov currentColumnIndex, 0
	
checkRow:
	mov ebx, currentRowIndex
	mov bl, GridRowStartIndices[ebx]
	mov bh, 0
	add ebx, currentColumnIndex
	cmp Grid[ebx], 0
	je foundAGap
	inc currentColumnIndex
	cmp currentColumnIndex, 10 ; Did we get to the last column?
	je clearThisRow
	jmp checkRow

clearThisRow:
	; Actual clearing of the row, then
	mov eax, currentRowIndex
	call ClearRow
	; Don't decrement currentRowIndex, need to check it again
	cmp currentRowIndex, 1
	je checktoclear_done
	mov currentColumnIndex, 0
	jmp checkRow

foundAGap:
	; Don't clear this row
	
	cmp currentRowIndex, 1
	je checktoclear_done
	dec currentRowIndex
	mov currentColumnIndex, 0
	jmp checkRow

checktoclear_done:
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
checktoclear endp

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
	push eax
	push ebx
	push ecx
	push edx
	mov ch,0
	mov dh,0
	mov al, activeColorIndex
	mov dl,active[7] 
	mov ebx, 0
	mov bx, dx
	mov dl,GridRowStartIndices[bx]
	mov cl,active[6]
	mov ebx, 0
	mov bx,dx
	add bx,cx   ; Bx contains grid index for coordinate {active[6], active[7]}
	cmp Grid[bx],0
	jne set_gameover
	mov Grid[bx],al
	mov dh,0
	mov dl,active[5]
	mov bx, dx
	mov dl,GridRowStartIndices[bx]
	mov cl,active[4]
	mov bx,dx
	add bx,cx
	cmp Grid[bx],0
	jne set_gameover
	mov Grid[bx],al
	mov dh,0
	mov dl,active[3]
	mov bx, dx
	mov dl,GridRowStartIndices[bx]
	mov cl,active[2]
	mov bx,dx
	add bx,cx
	cmp Grid[bx],0
	jne set_gameover
	mov Grid[bx],al
	mov dh,0
	mov dl,active[1]
	mov bx, dx
	mov dl,GridRowStartIndices[bx]
	mov cl,active[0]
	mov bx,dx
	add bx,cx
	cmp Grid[bx],0
	jne set_gameover
	mov Grid[bx],al
	jmp setblock_done
set_gameover:
	mov gameover, 1
	
setblock_done:
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
setblock endp

MoveLeft proc
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
MoveLeft endp

MoveDown proc
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
	call NewBlock
movedown_done:
	pop dx
	pop cx
	pop ax
	ret
MoveDown endp

MoveRight proc
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
MoveRight endp

Rotate proc
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
Rotate endp

Update proc
	cmp gameover, 1
	je Update_done
	call MoveDown
Update_done:
	invoke InvalidateRect, Hwnd, 0, 0
	ret
Update endp


MyTimerProc proc
	call Update
	ret
MyTimerProc endp

WindowMessageLoop proc
	local message : DWORD
	local messageAddress : DWORD

	lea eax,						message
	mov messageAddress,				eax

getMessage: ; loop
	invoke GetMessageA,				messageAddress, 0, 0, 0
	cmp eax, 0
	je quitMessage
	invoke TranslateMessage,		messageAddress
	invoke DispatchMessageA,		messageAddress
	cmp running, 0
	jne getMessage
	
quitMessage:
	invoke ExitProcess, 0

	ret
WindowMessageLoop endp

main:
	call InitializeGame
	
	mov eax, MyTimerProc
	invoke SetTimer, Hwnd, 0, 1000, eax

	call RegisterMyWindow
	call CreateMyWindow
	call ShowMyWindow
	call WindowMessageLoop
end main