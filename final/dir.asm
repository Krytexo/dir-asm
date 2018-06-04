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



; --------------------------------------------- ;
; 	DIR.exe										;
; Clone of Windows' dir /s which performs a		;
; recursive listing of every file and directory	;
; in a given path.								;
; --------------------------------------------- ;


.DATA
; Initialized variables
pathSuffix	db	"\*",0
dot			db	".",0
ddot		db	"..",0
pathFormat	db	"%s\%s",0
errStr		db	"Error, stoping program...",13,10,0
pauseStr	db	"pause",13,10,0	
clearStr	db	"cls",13,10,0	
scanfStr	db	"%s",0
promtStr	db	"Path:",13,10,">>> ",0
printFormat	db	"dir /s %s",13,10,0

; strings for printing purposes
tabIndent	db	"    ",0
fileStr		db	"<FILE>",0
dirStr		db	"<DIR>",0
formatStr	db	"%s %s",13,10,0

; Variables for tests purposes
defaultPath	db	".",0
projectPath	db	"C:\Users\leo\Desktop\Projet",0



.DATA?
; Non-initialized variables
depth	 DWORD	?



.CODE
; Functions and main
; ------------------

; REMINDER:
; 	WIN32_FIND_DATA = 	318o	--> [ebp - WIN32_FIND_DATA]
; 	PATH			=	260o	--> [ebp - 578]
; 	HANDLE			= 	4o		--> [ebp - 582]
; 	new PATH		=	260o	--> [ebp - 842]
; 	Total			=	842o


list PROC
	; -------------------------------
	; List the content of a directory
	; -------------------------------
	; Parameters
	; 	[ebp + 8]:		address for the given path
	; Variables
	; 	[ebp - 318]: 	struct that recieves the current file data
	;	[ebp - 578]: 	current path
	;	[ebp - 582]:	space for the handle returned by FindFirstFile
	; 	[ebp - 842]: 	new path
	
	push	ebp
	mov		ebp, esp
	sub		esp, 842			; save space for the variables

	inc		depth				; increment the depth
								; this value will be used during printing
	
	
	; Prepare the path so it fits the program's conditions.
	; ----------------------------------------------------

	; Copy the path into the stack so it can be modified
	push 	MAX_PATH			; maximum path size
	push 	[ebp + 8]			; address of the string passed in argument
	lea 	ebx, [ebp - 578]	; address of the path
	push	ebx
	call	crt_strncpy
	
	; Concatenate the path in parameter with "\*" to list
	; every file in the directory.
	push	MAX_PATH
	push	offset pathSuffix
	push	ebx					; address of the path
								; crt_strncpy does not modify %ebx
	call	crt_strncat
	
	
	; Call FindFirstFile.
	; ------------------
	
	; The fonction returns the first file's
	; data in the struct passed in parameter.
	lea		ebx, [ebp - WIN32_FIND_DATA]
	push 	ebx					; %ebx contains the address of the file data
	sub		ebx, MAX_PATH
	push	ebx					; %ebx now contains the address of the path
	call	FindFirstFile
	mov		[ebp - 582], eax	; save the handler in the stack
	
	; If anything goes wrong, signal error and quit.
	cmp 	eax, INVALID_HANDLE_VALUE 
	jne		no_error
	push	offset errStr
	call	crt_printf
	je 		error
	no_error:
	
	
	; Print the file/dir name and call FindNextFile
	; while theres entries in the given path.
	; --------------------------------------
	
	; do ... while()
	do:
		push    ecx				; save the value of %ecx
		
		; Get rid of the the dots so the program
		; does not start looping on the current file (.).
		; ----------------------------------------------
		
		; Call to ctr_strcmp to compare the
		; file name with "." and "..".
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		
		push	ebx				; file name, e.g. "."
		push 	offset dot		; %s: "."
		call 	crt_strcmp		; strcmp() returns 0 if the strings are the same
		add		esp, 8
		cmp 	eax, NULL
		je		skip			; jump to the end of the function
		
		push	ebx
		push	offset ddot		; %s: ".."
		call 	crt_strcmp
		add		esp, 8
		cmp 	eax, NULL
		je		skip
		
		
		; Call the `print` function to display
		; the file/dir name.
		push 	[ebp - WIN32_FIND_DATA]
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		call	print
		add		esp, 8
		
		; If object is directory, call the list function
		; again, else skip to the next file.
		lea		ebx, [ebp - WIN32_FIND_DATA]
		cmp 	DWORD PTR [ebx], FILE_ATTRIBUTE_DIRECTORY
		jne 	nodir
		
		; Format the new path so it can be
		; understood by th OS.
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		push	[ebp + 8]		; current path
		push 	offset pathFormat
		lea		ebx, [ebp - 842]
		push	ebx
		call	crt_sprintf
		add		esp, 16
		
		; Call the function with the new path
		push 	ebx 			; %ebx contains the adress of the path
		call	list
		nodir:
	
	
	skip:
		; Call FindNextFile on the handler given by
		; the FindFirstFile function.
		; --------------------------
		
		lea		ebx, [ebp - WIN32_FIND_DATA] 
		push 	ebx 			; %ebx contains the address of the struct
		push 	[ebp - 582]		; result of FindFirstFile
		call	FindNextFile
		
		pop 	ecx
		cmp 	eax, NULL 
	jne	do
	
	error:
	dec 	depth				; decrement the depth to restore it previous state
	
	mov		esp, ebp
	pop		ebp
	ret
list ENDP


print PROC
	; --------------------------------
	; Display a file/dir name with the
	; correct indentation.
	; --------------------------------
	; Parameters
	; 	[ebp + 8]: address for the file name
	; 	[ebp + 12]: object type
	
	push	ebp
	mov		ebp, esp
	
	; Print as many tabs its required.
	; for(i = 0; i < depth; i++)
	mov		ecx, depth
	next:
		push 	ecx				; save ecx on the stack
	
		push 	offset tabIndent
		call 	crt_printf
		
		add 	esp, 4
		pop 	ecx
		loop 	next
	
	; Chose the right prefix according to the
	; value of dwFileAttributes.
	mov 	edx, offset fileStr
	cmp 	DWORD PTR [ebp + 12], FILE_ATTRIBUTE_DIRECTORY
	jne 	file
	mov 	edx, offset dirStr
	file:
	
	
	; Print object's type and name
	push	[ebp + 8] ; file name
	push	edx; register for type
	push	offset formatStr
	call	crt_printf
	
	mov		esp, ebp
	pop		ebp
	ret
print ENDP

start:
	sub		esp, MAX_PATH		; save space for the input path
	mov 	depth, 0 			; set depth to zero
	
	push 	offset promtStr		; display the prompt
	call	crt_printf
	
	; Call scanf() to get the user input
	lea 	ebx, [ebp - MAX_PATH]
	push	ebx					; address where to store the path
	push 	offset scanfStr		; format
	call	crt_scanf
	add		esp, 8				; restore stack
	
	invoke	crt_system, offset clearStr
								; clear the window
	
	push	ebx
	push	offset printFormat
	call	crt_printf			; print the given path
	
	push	ebx					; push given path
	call	list
	
	invoke	crt_system, offset pauseStr
	mov		eax, 0
	invoke	ExitProcess,eax
end start