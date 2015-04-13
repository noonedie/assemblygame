
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
; 数据段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.data
playerPos  DWORD	playerNum	DUP(0) ;玩家的高度信息
personJumpTime DWORD playerNum    DUP(0) ;玩家跳到空中的时间
gndPos     DWORD	playerNum	DUP(?) ;地面的信息
wallPos	   DWORD	wallNum*playerNum		DUP(?) ;墙的水平位置信息
wallHeight DWORD	wallNum*playerNum		DUP(?) ;墙的高度信息

goldPos	   DWORD    goldNum DUP(0) 
ring	   DWORD    0					;人物动作标志
death	   DWORD	0					;死亡标志 
randomSeed DWORD    0  ;随机数种子
freq	   DWORD	0  ;更新的间隔

;score data
string	   BYTE		'Score:'			;提示字符串
scoreInfo  BYTE		20	DUP(0)			;转成字符串格式的得分值
len		   DWORD	0					;转成字符串的数字的实际格式

;pydata
gold	   DWORD    goldNum DUP(0)		;0表示不显示,1表示显示
ScoreFile  BYTE     "score.txt",0		;最高得分
sBuffer    BYTE		10 DUP(0)		;读取最高分的缓冲区
readLength DWORD	0
writeLength DWORD	0
fileHandle DWORD    0 
isScore    DWORD  playerNum	DUP(0)	;本次跳跃是否得分过	
score	   DWORD 0					;用户得分
		   BYTE  0
highScore  DWORD 0
		   BYTE 0
char	   WPARAM 20h
Click_X	   DWORD  0					;点击的x坐标
Click_Y    DWORD  0					;点击的y坐标
die_action DWORD  0					;死亡的动作
gameover   DWORD  0					;游戏结束
scene	   DWORD  0					;游戏场景，0为主菜单，1为游戏界面，2为帮助界面

;DC
Dc			DWORD	0
@hDC		DWORD	0
tmpBitmap	DWORD	0
bmp			DWORD	0

;music 
	Mp3Device				db			"MPEGVideo",0
	playTextBGM				db			"play bgm repeat", 0
	playOneTime				db			"play bgm",0 
	closeTextBGM			db			"close bgm",0
	pauseTextBGM			db			"pause bgm",0
	BGMName					db			"open backgroud_music.mp3 alias bgm", 0
	jumpSound				db		    "open jump.mp3 alias bgm",0
	dieSound				db			"open die_music.mp3 alias bgm", 0
;end data

.data?
hInstance	dd		?
hWinMain	dd		?
hDc         dd      ?
hCurrentBmp dd      ?
;hPen		dd		?
hBrush		dd		?
timeStamp   dd		?

.const
szClassName	db	'MyClass',0
szCaptionMain	db	'Escape',0
szText		db	0

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 代码段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.code

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 窗口过程
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
		local	@stPs:PAINTSTRUCT
		local	@stRect:RECT
		local	@hDc
		local   @stPos:POINT

		mov	eax,uMsg
;********************************************************************
;.if	eax ==	WM_PAINT
;			invoke GetTickCount
;			push eax
;			sub eax, timeStamp
;			.if eax > 50
;				invoke	getNextState, hWnd
;				pop timeStamp
;			.endif
;			invoke Draw, hWnd
;********************************************************************
		.IF uMsg == WM_TIMER
			invoke getNextState, hWnd
			invoke Draw, hWnd
			invoke getMousePos, hWnd
			invoke processMouseMove
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			invoke KillTimer,hWnd,ID_Timer
			invoke	DestroyWindow,hWinMain
			invoke	PostQuitMessage,NULL
;********************************************************************
		.elseif	eax ==	WM_CHAR
			push wParam
			pop char
			invoke	keydown_Proc, hWnd			
;********************************************************************
;		.elseif	eax ==	WM_KEYDOWN 
;			invoke	keydown_Proc, hWnd
;********************************************************************
		.elseif eax == WM_LBUTTONDOWN					;鼠标事件
			invoke processMouseEvent

;********************************************************************
		.else
			invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
;********************************************************************
		xor	eax,eax
		ret
		
_ProcWinMain	endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_WinMain	proc
		local	@stWndClass:WNDCLASSEX
		local	@stMsg:MSG

		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
;********************************************************************
; 注册窗口类
;********************************************************************
		invoke	LoadCursor,0,IDC_ARROW
		mov	@stWndClass.hCursor,eax
		push	hInstance
		pop	@stWndClass.hInstance
		mov	@stWndClass.cbSize,sizeof WNDCLASSEX
		mov	@stWndClass.style,CS_HREDRAW or CS_VREDRAW
		mov	@stWndClass.lpfnWndProc,offset _ProcWinMain
		mov	@stWndClass.hbrBackground,COLOR_WINDOW + 1
		mov	@stWndClass.lpszClassName,offset szClassName
		invoke	RegisterClassEx,addr @stWndClass
;********************************************************************
; 建立并显示窗口
;********************************************************************
		invoke	CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,\
			WS_OVERLAPPED+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX,\
			100,100,winWidth,winHeight,\
			NULL,NULL,hInstance,NULL
		mov	hWinMain,eax
		invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke	UpdateWindow,hWinMain
;********************************************************************
; 初始化数据,读取最高分
;********************************************************************
		
		INVOKE CreateFile, 
			ADDR ScoreFile, 
			GENERIC_WRITE+GENERIC_READ,
			0,
			NULL,
			OPEN_ALWAYS,
			FILE_ATTRIBUTE_NORMAL,
			0
		mov fileHandle, eax
		invoke _init
;********************************************************************
;设置定时器
;********************************************************************
		invoke SetTimer, hWinMain, TIMERID,freq,NULL
;********************************************************************
; 消息循环
;********************************************************************
		.while	TRUE
			invoke	GetMessage,addr @stMsg,NULL,0,0
			.break	.if eax	== 0
			invoke	TranslateMessage,addr @stMsg
			invoke	DispatchMessage,addr @stMsg
		.endw
		ret

_WinMain	endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Draw PROC, hWnd:HWND

;********************************************************************
; 主菜单页面
;********************************************************************
MainMenu:
	.if scene == 0
		invoke DrawMainMenu, hWnd

	.elseif scene == 1
		invoke DrawPlayProc, hWnd
	.else
		invoke DrawHelp, hWnd
	.endif
	ret
Draw ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
getMousePos PROC, hWnd:DWORD
	local	@stRect:RECT
	local   @stPos:POINT

	invoke GetWindowRect, hWnd, ADDR @stRect
	invoke GetCursorPos, ADDR @stPos
	
	;获取鼠标点击的x坐标
	mov edx, @stPos.x
	sub edx, @stRect.left
	mov Click_X, edx
	.if Click_X > winWidth
		mov Click_X, 0
	.endif
	
	;获取鼠标点击的y坐标
	mov edx, @stPos.y
	sub edx, @stRect.top
	mov Click_Y, edx
	inc eax	
	ret
getMousePos ENDP
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
processMouseMove PROC
	pusha
	.if scene == 0 ;主菜单界面
		invoke clickPosition, 140,164,413,243
		.if eax == 1
			invoke AddMask, @hDC, 140,164,413,243
		.endif
		invoke clickPosition, 140,273,413,349
		.if  eax == 1
			invoke AddMask, @hDC,140,273,413,349
		.endif
	.elseif scene == 1
		.if death == 1;死亡界面的处理
			invoke clickPosition, 165, 310, 250, 335
			.if eax == 1;点击了“重新开始”
				invoke AddMask, @hDC,165, 310, 250, 335
			.endif
			invoke clickPosition, 330, 310, 435, 335
			.if eax == 1;点击了“返回主菜单”
				invoke AddMask, @hDC,330, 310, 435, 335
			.endif
		.endif	
	.elseif scene == 2;帮助界面
		invoke clickPosition, 365,320,480,360
		.if eax == 1
			invoke AddMask, @hDC,365,320,480,360
		.endif
	.endif
	popa
	ret
processMouseMove ENDP


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
processMouseEvent PROC
	pusha
	.if scene == 0 ;主菜单界面
		invoke clickPosition, 140,164,413,243
		.if eax == 1
			mov scene,1;点击游戏开始
		.endif
		invoke clickPosition, 140,273,413,349
		.if  eax == 1
			mov scene,2;点击帮助界面
		.endif
	.elseif scene == 1
		.if death == 1;死亡界面的处理
			invoke clickPosition, 165, 310, 250, 335
			.if eax == 1;点击了“重新开始”
				invoke _init
				mov scene, 1
			.endif
			invoke clickPosition, 330, 310, 435, 335
			.if eax == 1;点击了“返回主菜单”
				invoke _init
				mov scene, 0
			.endif
		.endif	
	.elseif scene == 2;帮助界面
		invoke clickPosition, 365,320,480,360
		.if eax == 1
			mov scene, 0
		.endif
	.endif
	popa
	ret
processMouseEvent ENDP

clickPosition PROC left: DWORD, top: DWORD, right: DWORD, bottom: DWORD
	mov eax, 0
	mov ebx, left
	mov ecx, right
	.IF Click_X > ebx && Click_X < ecx
		mov ebx, top
		mov ecx, bottom
		.IF Click_Y > ebx && Click_Y < ecx
			mov eax, 1
		.ENDIF
	.ENDIF
	ret
clickPosition ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawMainMenu PROC, hWnd:HWND

	LOCAL hDcPlayer:DWORD
	;LOCAL hBmpPlayer:DWORD
	LOCAL hBmpObj:DWORD

;clear background
	invoke DeleteObject, hBrush
	invoke CreateSolidBrush, WHITE_BRUSH
	mov hBrush, eax
	invoke Rectangle, Dc, 0, 0, winWidth, winHeight
;Draw MainMenu 
;********************************************************************
	mov bmp, MAIN_MENU

	invoke CreateCompatibleDC, Dc
	mov hDcPlayer, eax
	invoke LoadBitmap, hInstance, bmp
	mov hBmpObj, eax

	invoke SelectObject, hDcPlayer, hBmpObj

	invoke BitBlt, Dc, 0, 0, winWidth, winHeight, hDcPlayer, 0, 0,SRCCOPY;636,570, SRCCOPY
	invoke DeleteObject, hBmpObj
	invoke DeleteDC, hDcPlayer


	invoke BitBlt, @hDC, 0, 0, winWidth, winHeight, Dc, 0, 0, SRCCOPY 
	ret
DrawMainMenu ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawPlayProc PROC, hWnd:HWND
	
;clear background
	invoke DeleteObject, hBrush
	invoke CreateSolidBrush, WHITE_BRUSH
	mov hBrush, eax

	invoke Rectangle, Dc, 0, 0, winWidth, winHeight

;Draw ground
;********************************************************************
	invoke DrawGND, Dc, gndPos
	invoke DrawGND, Dc, gndPos+4
;Draw wall
;********************************************************************
	invoke DrawAllWall, Dc
;********************************************************************
;Draw gold
	mov bmp, GOLD
	pusha 
	mov ecx, goldNum
	mov eax, ecx

GOLD1:
	push ecx
	.if ecx < 4 && gold[ecx*4-4] == 1; 上面的金币
		invoke DrawPlayer, hInstance, Dc, goldPos[ecx*4-4], wallMaxHeight+goldUp, gndPos, bmp, goldWidth, goldHeight
	.elseif gold[ecx*4-4] == 1
		invoke DrawPlayer, hInstance, Dc, goldPos[ecx*4-4], wallMaxHeight+goldUp, gndPos+4, bmp, goldWidth, goldHeight 
	.endif
	pop ecx
	loop GOLD1
	popa
;********************************************************************
;Draw player
;********************************************************************
	.if death == 1
		.if die_action == 0
			mov bmp, DIE_1
		.elseif die_action == 1
			mov bmp, DIE_2
		.elseif die_action == 2
			mov bmp, DIE_3
		.else
			mov bmp, DIE_4
		.endif
		invoke DrawPlayer, hInstance, Dc, pPos+(dieWidth-pWidth)/2, playerPos, gndPos, bmp, dieWidth, dieHeight
		invoke DrawPlayer, hInstance, Dc, pPos+(dieWidth-pWidth)/2, playerPos+4, gndPos+4, bmp, dieWidth, dieHeight
		invoke DrawDeath, Dc
		;死亡音效
		;.if gameover == 0
		INVOKE mciSendString,ADDR closeTextBGM,NULL, 0 ,NULL
		;INVOKE mciSendString,ADDR dieSound, NULL, 0, NULL
		;INVOKE mciSendString,ADDR playOneTime, NULL, 0, NULL
		;.endif
	.else
		.if ring == 0
			mov bmp, PEOPLE_1
		.elseif ring == 1
			mov bmp, PEOPLE_2
		.elseif ring == 2
			mov bmp, PEOPLE_3
		.endif
		invoke DrawPlayer, hInstance, Dc, pPos, playerPos, gndPos, bmp, pWidth, pHeight
		invoke DrawPlayer, hInstance, Dc, pPos, playerPos+4, gndPos+4, bmp, pWidth, pHeight
	.endif	

	invoke scoreTrans,score
	.if death != 1	
		invoke TextOut,Dc, 400, 10, ADDR string, LENGTHOF string
		invoke TextOut,Dc, 450, 10, ADDR scoreInfo, len
	.else ;取出最高得分，统计最高得分
		invoke TextOut,Dc, 280, 161, ADDR scoreInfo, len
		INVOKE ReadFile, fileHandle, OFFSET highScore, 4, ADDR readLength, NULL
		invoke SetFilePointer, fileHandle, 0, 0, FILE_BEGIN
		push eax
		mov eax, highScore
		.if readLength == 0 || eax < score
			invoke WriteFile,
				fileHandle,
				OFFSET score,
				4,
				ADDR writeLength,
				NULL
			invoke SetFilePointer, fileHandle, 0, 0, FILE_BEGIN
			invoke TextOut,Dc, 280, 206, ADDR scoreInfo, len	
		.else
			invoke scoreTrans, highScore	
			invoke TextOut,Dc, 280, 206, ADDR scoreInfo, len	
		.endif
		pop eax
	.endif

	invoke BitBlt, @hDC, 0, 0, winWidth, winHeight, Dc, 0, 0, SRCCOPY 
	ret
DrawPlayProc ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawHelp PROC, hWnd:HWND
	LOCAL hDcPlayer:DWORD
	LOCAL hBmpObj:DWORD

;clear background
	invoke DeleteObject, hBrush
	invoke CreateSolidBrush, WHITE_BRUSH
	mov hBrush, eax
	invoke Rectangle, Dc, 0, 0, winWidth, winHeight
;Draw MainMenu 
;********************************************************************
	mov bmp, HELP

	invoke CreateCompatibleDC, Dc
	mov hDcPlayer, eax
	invoke LoadBitmap, hInstance, bmp
	mov hBmpObj, eax

	invoke SelectObject, hDcPlayer, hBmpObj

	invoke BitBlt, Dc, 0, 0, winWidth, winHeight, hDcPlayer, 0, 0,SRCCOPY;636,570, SRCCOPY
	invoke DeleteObject, hBmpObj
	invoke DeleteDC, hDcPlayer

	invoke BitBlt, @hDC, 0, 0, winWidth, winHeight, Dc, 0, 0, SRCCOPY 
	ret
DrawHelp ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_init PROC
	INVOKE mciSendString,ADDR BGMName, NULL, 0, NULL
	INVOKE mciSendString,ADDR playTextBGM, NULL, 0, NULL
	mov gndPos, (winHeight - 100)/2
	mov gndPos+4, winHeight - 100
	mov ring, 0
	mov death, 0
	mov readLength, 0
	mov writeLength, 0
	mov ecx, wallNum*playerNum

	pusha
	mov ecx, goldNum
CG:
	mov goldPos[ecx*4-4],0
	mov gold[ecx*4-4], 0
		loop CG
	popa
L1:
	mov wallPos[ecx*4-4], 0
	mov wallHeight[ecx*4-4], 0
	Loop L1

	mov ecx, playerNum
L2:
	mov personJumpTime[ecx*4-4], 0
	mov playerPos[ecx*4-4], 0
	mov isScore[ecx*4-4], 0
	Loop L2

	mov score, 0
	mov char, 20h
	mov die_action, 0
	mov gameover, 0
	mov scene, 0
	mov freq, FREQUENCY

	INVOKE GetTickCount
	mov randomSeed, eax
	invoke CreateSolidBrush, WHITE_BRUSH
	mov hBrush, eax

	invoke GetDC, hWinMain
	mov @hDC, eax
	invoke CreateCompatibleDC, @hDC
	mov Dc, eax
	invoke CreateCompatibleBitmap,@hDC, winWidth, winHeight
	mov tmpBitmap, eax
	invoke SelectObject,Dc, tmpBitmap

	ret
_init ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
getNextState PROC, hWnd:DWORD
;逻辑代码安排在这部分
LOCAL wallInx:DWORD, personInx:DWORD, goldInx:DWORD
;-------------------------------------------------
;generate wall randomly
;-------------------------------------------------	
	.if scene != 1
		ret
	.endif
	.if death == 1 && die_action >= 3
		ret
	.endif
	mov wallInx, 0
	mov ecx, wallNum
	add ecx, wallNum

	push ecx
	mov ecx,goldNum
GR1:
	push ecx
	mov eax, goldNum
	sub eax, ecx
	mov ebx, eax
	.IF goldPos[ebx*4] <= 8
		invoke randomGenerate, randomSeed
		mov eax, randomSeed
		mov edx, 0
		mov ecx, winWidth
		div ecx
		add edx, winWidth
		mov goldPos[ebx*4], edx
		mov gold[ebx*4], 1
	.ELSE
		sub goldPos[ebx*4], goldSpeed
	.ENDIF
	pop ecx
	loop GR1
	pop ecx
W1:
	push ecx
	mov eax, wallNum
	add eax, wallNum
	sub eax, ecx
	mov wallInx, eax
	.IF wallHeight[4*eax] == 0 
		.IF wallInx == 0 || wallInx == wallNum
			INVOKE randomGenerate, randomSeed
			mov eax, randomSeed
			mov edx, 0
			mov ecx, wallGenerateChance   ;randomly generate wall
			div	ecx
			.IF edx == 0
				mov eax, wallInx
				mov wallPos[eax*4], winWidth
				INVOKE randomGenerate, randomSeed
				mov eax, randomSeed
				mov edx, 0
				mov ecx, wallMaxHeight
				div	ecx
				mov eax, wallInx
				add edx, 20
				mov wallHeight[eax*4], edx
			.ENDIF
		.ELSE
			mov eax, wallInx
			dec eax
			.IF wallHeight[eax*4] > 0 && wallPos[eax*4] < (winWidth - wallSafeDistance)
				INVOKE randomGenerate, randomSeed
				mov eax, randomSeed
				mov edx, 0
				mov ecx, wallGenerateChance   ;randomly generate wall
				div	ecx
				.IF edx == 0 
					mov eax, wallInx
					mov wallPos[eax*4], winWidth
					INVOKE randomGenerate, randomSeed
					mov eax, randomSeed
					mov edx, 0
					mov ecx, wallMaxHeight      
					div	ecx
					mov eax, wallInx
					add edx, 20
					mov wallHeight[eax*4], edx
				.ENDIF
			.ENDIF
		.ENDIF
	.ENDIF
	pop  ecx
	loop TEMP1
	jmp  TEMP2
TEMP1:
	jmp	W1
TEMP2:


;-------------------------------------------------
;live or death and take movement
;-------------------------------------------------
;先检测后移动
	mov wallInx, 0
	mov ecx, wallNum
	add ecx, wallNum
DANDM:
	push ecx
	mov eax, wallNum
	add eax, wallNum
	sub eax, ecx
	mov wallInx, eax
	;检测碰撞，需要修改为两个不同的人
	.IF wallInx < 3
		;和第一个人进行碰撞检测

		mov ebx, playerPos[0]
		mov edx, pPos
		mov ecx, pPos
		sub ecx, wallThick+playerWidth; ecx = pPos - wallThick
		.IF edx > wallPos[eax*4] && ecx < wallPos[eax*4] ;  && ebx < wallHeight[eax*4]
			.IF ebx < wallHeight[eax*4]
				mov death, 1
			.ENDIF
			.IF ebx >= wallHeight[eax*4] && isScore[0] == 0 && wallHeight[eax*4] != 0; 高度为0表示墙还未出现
				inc score
				mov isScore[0], 1
			.ENDIF
		.ENDIF
	.ELSE
		;和第二个人进行碰撞检测
		mov ebx, playerPos[4]
		mov edx, pPos
		mov ecx, pPos
		sub ecx, wallThick+playerWidth ; ecx = pPos - wallThick
		.IF edx > wallPos[eax*4] && ecx < wallPos[eax*4] ;;;&& ebx < wallHeight[eax*4]
			.IF ebx < wallHeight[eax*4]
				mov death, 1
			.ENDIF
			.IF ebx >= wallHeight[eax*4] && isScore[4] == 0 && wallHeight[eax*4] != 0
				inc score
				mov isScore[4], 1
			.ENDIF
		.ENDIF
	.ENDIF
	;移除超出屏幕的方块
	.IF wallPos[eax * 4] > winWidth
		mov	wallHeight[eax * 4], 0
	.ENDIF
	sub wallPos[4*eax], moveSpeed
	pop ecx
	loop TEMP3
	jmp TEMP4
TEMP3:
	jmp DANDM
TEMP4:

;-------------------------------------------------------------
;检测是否吃到金币
	pusha
	mov ecx, goldNum
GTEMP:
	push ecx
	.if ecx > 3
		mov eax, 1;第二个人
	.else
		mov eax, 0;第一个人
	.endif
	mov ebx, playerPos[eax*4]
	mov edx, pPos
	mov eax, ecx
	mov ecx, pPos
	sub ecx, playerWidth
	add edx, goldWidth 
	dec eax
	.IF gold[eax*4] == 1 && edx > goldPos[eax*4] && ecx < goldPos[eax*4] && ebx <= (wallMaxHeight+goldUp+goldHeight) &&  ebx >= (wallMaxHeight+goldUp-goldHeight-pHeight)
			add score, goldScore
			mov gold[eax*4], 0		;金币消失
	.ENDIF
	pop ecx
	dec ecx
	jne GTEMP
	popa

;move person
;-------------------------------------------------------------
;move person height
;-------------------------------------------------------------
	mov ecx, playerNum
PM:
	push ecx
	mov eax, playerNum
	sub eax, ecx
	mov personInx, eax
	.IF personJumpTime[eax*4] != 0; y = ut - at*t/2
		add personJumpTime[eax*4], 1
		
		mov ebx,personInx
		mov eax, personJumpTime[ebx*4]
		mov ebx, accelerateSpeed
		mul ebx
		;mov ebx, 2
		;mul ebx
		.IF eax >= 2*personJumpSpeed   ; person has touch ground
			mov ebx, personInx
			mov personJumpTime[ebx*4], 0
			mov playerPos[ebx*4], 0
		.ELSE                         ;person is in the sky,  y = ut - at*t/2
			mov eax, personJumpSpeed
			mov ebx, personInx
			mov ecx, personJumpTime[ebx*4]
			mul ecx
			mov ebx, eax
			mov ecx, personInx
			mov eax, personJumpTime[ecx*4]
			mov edx, eax
			mul edx ; t^2
			mov ecx, accelerateSpeed
			mul ecx
			mov edx, 0
			mov ecx, 2
			div ecx
			sub ebx, eax
			mov eax, personInx
			mov playerPos[eax*4], ebx
		.ENDIF
	.ELSEIF personJumpTime[eax*4] == 0
		mov isScore[eax*4],0	;为下次跳跃计分做初始化
	.ENDIF
	pop ecx
	dec ecx
	jnz PM

;*******************************************************************
;提高速度
;*******************************************************************
	.if isScore[0] == 1 || isScore[4] == 1
		mov eax, score
		mov edx, 0
		mov ebx, 10
		div ebx
		.if edx == 0 && freq > 10
			sub freq, 1
			invoke KillTimer, hWnd, TIMERID
			invoke SetTimer, hWnd, TIMERID, freq, NULL
			mov isScore[0], 0
			mov isScore[1], 0
		.endif
	.endif

	.if ring == 0
		mov ring, 1
	.elseif ring == 1
		mov ring, 2
	.else
		mov ring, 0
	.endif
	;死亡动画
	.if death == 1
		mov eax, die_action
		inc eax
		mov die_action, eax
		.if die_action >= 3 
		mov die_action, 3
		.endif
	.endif
	ret
getNextState ENDP

;transfer score to scoreString
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
scoreTrans	PROC, myScore:DWORD
	pushad
	mov eax, myScore
	mov ecx, 0
	mov ebx, 10
L1:
	mov edx, 0
	div ebx
	push edx
	inc ecx
	.if ecx == LENGTHOF scoreInfo
		jmp NEXT
	.endif
	cmp eax, 0
	jnz L1

NEXT:
	mov edx, 0
	mov len, ecx
L2:
	pop eax
	add al, '0'
	mov scoreInfo[edx], al
	inc edx
	Loop L2
	popad
	ret
scoreTrans	ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
keydown_Proc PROC, hWnd:DWORD
;逻辑代码安排在这部分
	.IF char == 'w' && personJumpTime[0] == 0	
		mov personJumpTime[0], 1
	.ENDIF
	.IF char == 'i'	&& personJumpTime[4] == 0
		mov personJumpTime[4], 1
	.ENDIF
	.IF char == ' ' && death == 1
		invoke _init
		mov scene, 1
		invoke KillTimer, hWnd, TIMERID
		invoke SetTimer, hWnd, TIMERID, freq, NULL
	.ENDIF
	;测试代码
;********************************************************************

	;跳跃音效的播放
;	pusha
;	invoke    PlaySound,addr jumpSound,NULL,SND_ASYNC
;	popa

;L1:
;	inc wallPos[ecx*4-4]
;	Loop L1
;	mov ecx, wallNum
;L2:
;	sub wallPos[ecx*TYPE wallPos+8], 1
;	Loop L2
;
;	.if ring == 0
;		mov ring, 1
;	.elseif ring == 1
;		mov ring, 2
;	.else
;		mov ring, 0
;	.endif
;********************************************************************
	invoke UpdateWindow, hWnd
	ret
keydown_Proc ENDP




;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
randomGenerate PROC, seed:DWORD
	pushad
	mov eax, seed
	mov ecx, 25173
	mul ecx
	mov randomSeed, eax
	add randomSeed, 13849
	popad
	ret
randomGenerate ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawDeath PROC, @Dc:DWORD
	LOCAL hDcPlayer:DWORD
	LOCAL hBmpObj:DWORD

	mov bmp, GAME_OVER
	invoke CreateCompatibleDC, @Dc
	mov hDcPlayer, eax
	invoke LoadBitmap, hInstance, bmp
	mov hBmpObj, eax

	invoke SelectObject, hDcPlayer, hBmpObj

	invoke BitBlt, @Dc, 0, 0, winWidth, winHeight, hDcPlayer, 0, 0,SRCCOPY;636,570, SRCCOPY
	invoke DeleteObject, hBmpObj
	invoke DeleteDC, hDcPlayer
	ret
DrawDeath ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DrawAllWall PROC, @Dc:DWORD
	mov ecx, playerNum
L1:
	push ecx
	mov eax, ecx
	sub eax, 1
	mov ecx, wallNum
L2:
	push ecx
	sub ecx, 1
	imul ebx, ecx, TYPE wallHeight
	imul edx, eax, TYPE wallHeight * wallNum
	add ebx, edx
	invoke DrawWall, @Dc, wallHeight[ebx], wallThick, wallPos[ebx], gndPos[eax*4]
	pop ecx
	Loop L2
	pop ecx
	Loop L1
	ret
DrawAllWall ENDP
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
		call	_WinMain
		invoke	ExitProcess,NULL

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		end	start
