playerNum	=	2
wallNum	    =	3
winHeight	=	440
winWidth	=	620
wallThick	=	4
pWidth		=	32			;人物图片的宽度
pHeight		=	32
dieWidth	=   112
dieHeight   =   74

goldWidth   =   30
goldHeight  =   30
goldScore	equ  5			;每个金币的得分
goldUp		equ  50			;金币比wallMaxHeight高的高度
goldSpeed   equ  8
goldNum		equ	 6 


playerWidth equ  20          ;实际人物的宽度，用于碰撞检测
pPos		equ	150			;人物右下角的x坐标
PEOPLE_1	equ 101
PEOPLE_2	equ 103	
PEOPLE_3    equ 104
ID_Timer	equ 1	
DIE_1       equ 105
DIE_2       equ 106
DIE_3       equ 107
DIE_4       equ 108
GAME_OVER	equ	115
MAIN_MENU   equ 2
FREQUENCY   equ 40
TIMERID		equ 123
HELP		equ	112
GOLD		equ 117
HELP_REPLACE	equ	118
START_REPLCAE   equ 119
DIRECT_REPLACE  equ 65535
RESTART_REPLCAE equ 124
RETURN_REPLCAE  equ 125
MAIN_ICON		equ 7
;------------------------
wallMaxHeight = 40
moveSpeed	  =  6 
wallSafeDistance   = 150 
wallGenerateChance = 23
personJumpSpeed  =  20
accelerateSpeed  =  2
