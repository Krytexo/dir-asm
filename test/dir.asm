.386
.model flat,stdcall
option casemap:none

__UNICODE__=1
include \masm32\MasmBasic\MasmBasic.inc
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
|-
`-

.DATA
; Initialized variables
strCommand		db	"Pause",13,10,0
pathSuffix		db	"\*",0
formatStr		db	"%ls",0

; Prefixes for printing purposes
filePrefix		db	"├── ",0
lastFilePrefix	db	"└── ",0
recursivePrefix db	"│   ",0
tabIndent		db	"    ",0

; Variables for tests purposes
defaultPath		db	"C:\Users\leo\Desktop\Projet",0



.DATA?
; Not-initialized variables
level	DWORD ?


.CODE
list PROC
	; List the content of a directory
	; [ebp + 8]: address for the path of the directory.
	; [ebp + 12]: address of the return struct.
	
	push	ebp
	mov		ebp, esp
	
	; Locale variables
	; Save space for the result of FindFirstFile & Co.
	sub		esp, WIN32_FIND_DATA
	
	; Concatenate the path in parameter with "\*" to list
	; every file in the directory.
	push	MAX_PATH
	push	offset pathSuffix
	push	[ebp + 8]
	call	crt_strcat
	
	; Call FindFirstFile
	lea		ebx, [ebp - WIN32_FIND_DATA]
	push 	ebx
	push 	[ebp + 8]
	call	FindFirstFile
	
	;cmp 	eax
	
	add 	ebx, 44
	push	ebx
	push 	offset formatStr
	call	crt_printf
	
	mov		esp, ebp
	pop		ebp
	ret
list ENDP

start:
	;push 	offset defaultPath
	;call	list
	
	push	offset formatStr
	push 	offset filePrefix
	call	crt_wprintf
	
	invoke	crt_system, offset strCommand	; Pause
	mov		eax, 0
	invoke	ExitProcess,eax

end start


