.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\gdiplus.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
; Initialized variables
dStr			db	"%d",13,10,0

.CODE
start:
	mov 	eax, MAX_PATH
	add		eax, WIN32_FIND_DATA
	push 	eax
	push	offset dStr
	call	crt_printf

	invoke	crt_system, offset strCommand	; Pause
	mov		eax, 0
	invoke	ExitProcess, eax
end start


