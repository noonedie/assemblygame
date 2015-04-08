Draw PROTO, hWnd:HWND
_init PROTO
getNextState PROTO, hWnd:HWND
DrawGND PROTO, Dc:DWORD, gnd:DWORD
DrawWall PROTO, Dc:DWORD, Height:DWORD, Wid:DWORD, Pos:DWORD, GNDPOS_Y:DWORD
DrawPlayer PROTO, hInst:DWORD, Dc:DWORD, PlayerPos:DWORD, GNDPOS:DWORD, hBitMap:DWORD, bWidth:DWORD, bHeight:DWORD
keydown_Proc PROTO, hWnd:DWORD
DrawDeath PROTO, hWnd:HWND
DrawMainMenu PROTO, hWnd:HWND
randomGenerate PROTO, seed:DWORD
processMouseEvent PROTO
clickPosition PROTO left: DWORD, top: DWORD, right: DWORD, bottom: DWORD