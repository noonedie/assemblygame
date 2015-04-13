
		.386
		.model flat,stdcall
		option casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include 文件定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include		windows.inc
include		gdi32.inc
includelib	gdi32.lib
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
include        winmm.inc
includelib    winmm.lib
include escape.inc
include data.inc
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.code
DrawGND PROC, Dc:DWORD, gnd:DWORD
	LOCAL hPen:DWORD
	invoke CreatePen, PS_SOLID, 3, BLACK_PEN
	mov hPen, eax
	invoke SelectObject, Dc, hPen
	invoke DeleteObject, eax
	invoke MoveToEx, Dc, 0, gnd, NULL
	invoke LineTo, Dc, winWidth, gnd
	ret
DrawGND ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawWall PROC, @Dc:DWORD, Height:DWORD, Wid:DWORD, Pos:DWORD, GNDPOS:DWORD
	LOCAL start_x
	LOCAL start_y
	LOCAL end_x
	LOCAL end_y
	LOCAL hBrush
	LOCAL hOld
	
	pushad

	mov eax, Pos
	mov start_x, eax
	
	add eax, Wid
	mov end_x, eax

	mov ebx, GNDPOS
	mov end_y, ebx

	sub ebx, Height
	mov start_y, ebx

	invoke CreateSolidBrush, BLACK_BRUSH
	mov hBrush, eax
	invoke SelectObject, @Dc, hBrush
	mov hOld, eax
	invoke Rectangle, @Dc, start_x, start_y, end_x, end_y
	invoke SelectObject, @Dc, hOld
	invoke DeleteObject, hBrush
	popad
	ret
DrawWall ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawPlayer PROC, hInst:DWORD, Dc:DWORD, PlayerPosX:DWORD, PlayerPosY:DWORD, GNDPOS:DWORD, hBitMap:DWORD, bWidth:DWORD, bHeight:DWORD
	LOCAL hDcPlayer:DWORD
	LOCAL hBmpObj:DWORD

	invoke CreateCompatibleDC, Dc
	mov hDcPlayer, eax

	invoke LoadBitmap, hInst, hBitMap
	mov hBmpObj, eax

	invoke SelectObject, hDcPlayer, hBmpObj
	mov ebx, PlayerPosX

	mov eax, bWidth
	sub ebx, eax
	mov eax, GNDPOS
	sub eax, bHeight
	sub eax, PlayerPosY
	invoke BitBlt, Dc, ebx, eax, bWidth, bHeight, hDcPlayer, 0, 0, SRCAND
	invoke DeleteDC, hDcPlayer
	invoke DeleteObject, hBmpObj

	ret
DrawPlayer ENDP

AddMask PROC, DC: DWORD, left:DWORD, top:DWORD, right:DWORD, bottom:DWORD
	LOCAL hDcMask:DWORD
	LOCAL hBmp:DWORD
	LOCAL rect_width:DWORD
	LOCAL rect_height:DWORD
	LOCAL hBrush:DWORD

	invoke CreateCompatibleDC, DC
	mov hDcMask, eax
	mov eax, right
	sub eax, left
	mov rect_width, eax
	mov eax, bottom
	sub eax, top
	mov rect_height, eax

	invoke CreateCompatibleBitmap, DC, rect_width, rect_height
	mov hBmp, eax
	invoke SelectObject, hDcMask, hBmp
	invoke CreateSolidBrush, 0ff0fh
	mov hBrush, eax
	invoke SelectObject, hDcMask, hBrush
	invoke Rectangle, hDcMask, 0, 0, rect_width, rect_height
	invoke BitBlt, DC, left, top, rect_width, rect_height, hDcMask, 0, 0, SRCAND
	
	ret
AddMask ENDP

end