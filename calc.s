cSTACK_SIZE EQU 5
cMAX_INPUT_SIZE EQU 82
cMALLOC_ARG EQU 9
%macro PRINT_ERROR 1
	pushad
	push %1
	call printf
	add esp, 4
	popad
%endmacro

section	.rodata
DEBUG_INPUT_FORMAT:
	DB 	"DEBUG - User input: %s", 0
DEBUG_RESULT_FORMAT:
	DB 	"DEBUG - Result pushed: %x", 0
STACK_OVERFLOW:
	DB	">>Error: Operand Stack Overflow", 10, 0
NOT_ENOUGH_ARGS:
	DB	">>Error: Insufficient Number of Arguments on Stack", 10, 0
PROMPT:
	DB	">>calc: ", 0
FORMAT_NOZERO:
	DB 	">>%x", 0
FORMAT_ZERO:
	DB 	"%02x", 0
EXITFORMAT:
	DB 	"%d", 10, 0
NEWLINE_CHAR:
	DB 	10
section .data
	debugFlag DB 0
	stackIndex DB 0
	operationCount DB 0
	headLinkPtr DD 0
	regularLinkPtr DD 0
section .bss
inputBuffer:
	RESB	cMAX_INPUT_SIZE
tempBuffer:
	RESB	cMAX_INPUT_SIZE
operandStack:
	RESD cSTACK_SIZE
tempPtr:
	RESB 4
tempPtr2:
	RESB 4

section .text
	align 16
	global main
	extern printf
	extern fprintf
	extern malloc
	extern free
	extern fgets
	extern stderr
	extern stdin
	extern stdout

main:
	push	ebp
	mov	ebp, esp
	pushad
	mov ecx, dword [ebp+8]
	cmp ecx, 2
	je set_debug_mode
start_my_calc:
	call my_calc
print_num_of_ops:
	push eax
	push EXITFORMAT
	call printf
	add esp, 8
leave_main:
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret
set_debug_mode:
	mov ecx, dword [ebp+12]			; ecx = argv
	mov ebx, dword [ecx+4]			; ebx = *argv+1
	mov ecx, ebx
	cmp byte [ecx], '-'
	jne start_my_calc
	cmp byte [ecx+1], 'd'
	jne start_my_calc
	cmp byte [ecx+2], 0
	inc byte [debugFlag]
	jmp start_my_calc
my_calc:
	push	ebp
	mov	ebp, esp
	pushad
	
CALC_LOOP: 						; most external loop
	call GET_INPUT
	cmp byte [inputBuffer], 'q'	; check if user wants to quit 
	je END_PROG
	cmp byte [inputBuffer], 'd'	; check if user wants to duplicate 
	je call_DUPLICATE
	cmp byte [inputBuffer], '+'	; check if user wants to add 
	je call_ADDITION
	cmp byte [inputBuffer], '&'	; check if user wants to bitwise and 
	je call_BITWISE_AND
	cmp byte [inputBuffer], 'p'	; check if user wants to pop and print 
	je call_POP_AND_PRINT
	call PUSH_TO_OPERAND_STACK
	
	jmp CALC_LOOP

GET_INPUT:						; receives input and saves it in inputBuffer
	push	ebp
	mov	ebp, esp
	pushad
	
	push PROMPT
	call printf
	add esp, 4
	
	push dword [stdin]
	push dword cMAX_INPUT_SIZE
	push inputBuffer
	call fgets
	add esp, 12
		
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret

call_DUPLICATE:
	call DUPLICATE
	jmp CALC_LOOP
call_ADDITION:
	call ADDITION
	jmp CALC_LOOP
call_BITWISE_AND:
	call BITWISE_AND
	jmp CALC_LOOP
call_POP_AND_PRINT:
	call POP_AND_PRINT
	jmp CALC_LOOP

not_enough_arguments:
	PRINT_ERROR NOT_ENOUGH_ARGS
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret
	
stack_overflow_error:
	PRINT_ERROR STACK_OVERFLOW
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret
	
DUPLICATE:
	push	ebp
	mov	ebp, esp
	pushad
	cmp byte [inputBuffer+1], 10
	jne finish_duplicate
	cmp byte [stackIndex], 0
	je not_enough_arguments
	cmp byte [stackIndex], 5
	je stack_overflow_error
	mov ebx, 0
	mov bl, byte [stackIndex]
	dec bl
	shl bl, 2
	mov edx, dword [operandStack + ebx]		; edx holds highest pointer in the stack
get_to_last_link:
	cmp dword [edx+1], 0
	je copy_to_buffer						; edx holds last link
	mov ebx, dword [edx+1]
	mov edx, ebx
	jmp get_to_last_link
copy_to_buffer:
	mov ebx, 0
copy_to_buffer_loop:										 
	mov al, byte [edx]						; al holds value of link in edx
	shr al, 4
	add al, 48
	mov byte [inputBuffer + ebx], al
	inc ebx
	mov al, byte [edx]
	and al, 0x0F
	add al, 48
	mov byte [inputBuffer + ebx], al
	mov ecx, dword [edx+5]
	inc ebx
	cmp ecx, 0
	je finish_copy_loop
	mov edx, ecx
	jmp copy_to_buffer_loop
finish_copy_loop:
	mov byte [inputBuffer + ebx], 10
	inc byte [operationCount]
	call PUSH_TO_OPERAND_STACK
finish_duplicate:
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret

	
BITWISE_AND:
	push	ebp
	mov	ebp, esp
	pushad
	cmp byte [inputBuffer+1], 10
	jne finish_AND_procedure
	mov eax, 0
	mov al, 1
	mov ah, 1
	mov ebx, 0
	cmp byte [stackIndex], 2
	jl not_enough_arguments
	mov bl, byte [stackIndex]
	sub bl, 1
	shl bl, 2
	mov edx, dword [operandStack + ebx]		; edx now holds highest stack element
	mov dword [tempPtr], edx
	mov bl, byte [stackIndex]
	sub bl, 2
	shl bl, 2
	mov ecx, dword [operandStack + ebx]		; ecx now holds second highest stack element
	mov dword [tempPtr2], ecx
BitwiseAnd_get_edx_last_link_loop:
	cmp dword [edx+1], 0
	je BitwiseAnd_get_ecx_last_link_loop
	inc ah									; ah = number of links in edx list
	mov ebx, dword [edx+1]
	mov edx, ebx
	jmp BitwiseAnd_get_edx_last_link_loop
BitwiseAnd_get_ecx_last_link_loop:
	cmp dword [ecx+1], 0
	je BitwiseAnd_compare_edx_ecx
	inc al									; al = number of links in ecx list
	mov ebx, dword [ecx+1]
	mov ecx, ebx
	jmp BitwiseAnd_get_ecx_last_link_loop
BitwiseAnd_compare_edx_ecx:
	mov bh, ah
	sub bh, al								; (bh < 0) ==> have to switch, (bh >= 0) ==> no problem
	mov edx, dword [tempPtr]
	mov ecx, dword [tempPtr2]
	cmp bh, 0
	jl BitwiseAnd_switch_ecx_edx			; highest element is shorter than the previous element
	jge compute_AND	
BitwiseAnd_switch_ecx_edx:
	mov ebx, 0
	mov bl, byte [stackIndex]
	sub bl, 1
	shl bl, 2
	mov dword [operandStack + ebx], ecx
	mov bl, byte [stackIndex]
	sub bl, 2
	shl bl, 2
	mov dword [operandStack + ebx], edx
	xchg ecx, edx							; ecx is now the shorter one
	mov dword [tempPtr], edx
	mov dword [tempPtr2], ecx
compute_AND:								; now the highest element in the stack is longer or equal to the previous element
iterate_AND:
	mov bl, byte [ecx]
	mov bh, byte [edx]
	and bl, bh
	mov byte [ecx], bl
	cmp dword [ecx+1], 0
	je finish_AND
	mov eax, dword [ecx+1]
	mov ecx, eax							; ecx is at the next link
	mov eax, dword [edx+1]					
	mov edx, eax							; edx is at the next link
	jmp iterate_AND
finish_AND:
	dec byte [stackIndex]
	inc byte [operationCount]
	mov edx, dword [tempPtr]
	push edx
	call FREE_PTR
	add esp, 4
finish_AND_procedure:
	cmp byte [debugFlag], 1
	jne exit_AND_procedure
	;==============================================================================================
	mov eax, 0
	mov edx, ecx
debugAND_print:
	mov al, byte [edx]
	cmp al, 0
	je debugAND_skip_link
	pushad
	push eax
	push DEBUG_RESULT_FORMAT
	push dword [stderr]
	call fprintf
	add esp, 12
	popad
	mov ebx, dword [edx+5]
	mov edx, ebx
	cmp edx, 0
	je debugAND_finish_print
	jne debugAND_print_loop
debugAND_skip_link:
	mov ebx, dword [edx+5]
	mov edx, ebx
	cmp edx, 0
	je debugAND_print_zero
	jne debugAND_print
debugAND_print_zero:
	pushad
	push eax
	push DEBUG_RESULT_FORMAT
	push dword [stderr]
	call fprintf
	add esp, 12
	popad
	jmp debugAND_finish_print
debugAND_print_loop:
	mov al, byte [edx]
	pushad
	push eax
	push FORMAT_ZERO
	push dword [stderr]
	call fprintf
	add esp, 12
	popad
	mov ebx, dword [edx+5]				; ebx = previous link
	mov edx, ebx
	cmp edx, 0
	jne debugAND_print_loop
debugAND_finish_print:
	push NEWLINE_CHAR
	push dword [stderr]
	call fprintf
	add esp, 8
	;==============================================================================================
exit_AND_procedure:
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret	
	
ADDITION:
	push	ebp
	mov	ebp, esp
	pushad
	cmp byte [inputBuffer+1], 10
	jne finish_ADDITION_procedure
	mov eax, 0
	mov al, 1
	mov ah, 1
	mov ebx, 0
	cmp byte [stackIndex], 2
	jl not_enough_arguments
	mov bl, byte [stackIndex]
	sub bl, 1
	shl bl, 2
	mov edx, dword [operandStack + ebx]		; edx now holds highest stack element
	mov dword [tempPtr], edx
	mov bl, byte [stackIndex]
	sub bl, 2
	shl bl, 2
	mov ecx, dword [operandStack + ebx]		; ecx now holds second highest stack element
	mov dword [tempPtr2], ecx
Addition_get_edx_last_link_loop:
	cmp dword [edx+1], 0
	je Addition_get_ecx_last_link_loop
	inc ah									; ah = number of links in edx list
	mov ebx, dword [edx+1]
	mov edx, ebx
	jmp Addition_get_edx_last_link_loop
Addition_get_ecx_last_link_loop:
	cmp dword [ecx+1], 0
	je Addition_compare_edx_ecx
	inc al									; al = number of links in ecx list
	mov ebx, dword [ecx+1]
	mov ecx, ebx
	jmp Addition_get_ecx_last_link_loop
Addition_compare_edx_ecx:
	mov bh, ah								; (bh > 0) ==> (edx > ecx) ==> must switch
	sub bh, al								; (bh <= 0) ==> (edx <= ecx) ==> no problem
	mov edx, dword [tempPtr]
	mov ecx, dword [tempPtr2]
	cmp bh, 0
	jg Addition_switch_ecx_edx				; highest element is shorter than the previous element (not a problem)
	jle exchange_ecx_edx
Addition_switch_ecx_edx:
	mov ebx, 0
	mov bl, byte [stackIndex]
	sub bl, 1
	shl bl, 2
	mov dword [operandStack + ebx], ecx
	mov bl, byte [stackIndex]
	sub bl, 2
	shl bl, 2
	mov dword [operandStack + ebx], edx
	jmp compute_ADDITION
exchange_ecx_edx:
	xchg ecx, edx
	mov dword [tempPtr], edx
	mov dword [tempPtr2], ecx
compute_ADDITION:							; edx is now the longer one (in all cases) and the second highest element
	clc										; clear carry flag (CF = 0)
	mov eax, 0
	jmp iterate_ADDITION
add_with_carry:
	cmp dword [edx+1], 0
	je add_carry_link
add_carry:
	mov al, 1
	jmp next_two_links
add_carry_link:
	pushad
	push dword cMALLOC_ARG					; push 9
	call malloc 							; eax = pointer to memory
	add esp, 4
	mov dword [regularLinkPtr], eax
	popad
	mov eax, dword [regularLinkPtr]
	mov dword [eax+1], 0		; current.next = null
	mov dword [edx+1], eax		; prev.next = current
	mov dword [eax+5], edx		; current.prev = prev
	mov edx, eax
	mov byte [edx], 1
	jmp finish_ADDITION
iterate_ADDITION:
	add al, byte [ecx]
	add al, byte [edx]
	daa
	mov byte [edx], al
	jc add_with_carry
	mov al, 0
	cmp dword [ecx+1], 0
	je finish_ADDITION
next_two_links:
	cmp dword [ecx+1], 0
	je only_edx
	mov ebx, dword [ecx+1]
	mov ecx, ebx							; ecx is at the next link
	mov ebx, dword [edx+1]					
	mov edx, ebx							; edx is at the next link
	jmp iterate_ADDITION
only_edx:
	mov byte [ecx], 0
	mov ebx, dword [edx+1]
	mov edx, ebx
	jmp iterate_ADDITION
finish_ADDITION:
	cmp dword [edx+1], 0
	je finish_ADDITION_2
	mov ebx, dword [edx+1]
	mov edx, ebx
	jmp finish_ADDITION
finish_ADDITION_2:
	dec byte [stackIndex]
	inc byte [operationCount]
	mov ecx, dword [tempPtr2]
	push ecx
	call FREE_PTR
	add esp, 4
finish_ADDITION_procedure:
	cmp byte [debugFlag], 1
	jne exit_ADDITION
	;==============================================================================================
	mov eax, 0
debugADDITION_print:
	mov al, byte [edx]
	cmp al, 0
	je debugADDITION_skip_link
	pushad
	push eax
	push DEBUG_RESULT_FORMAT
	push dword [stdout]
	call fprintf
	add esp, 12
	popad
	mov ebx, dword [edx+5]
	mov edx, ebx
	cmp edx, 0
	je debugADDITION_finish_print
	jne debugADDITION_print_loop
debugADDITION_skip_link:
	mov ebx, dword [edx+5]
	mov edx, ebx
	cmp edx, 0
	je debugADDITION_print_zero
	jne debugADDITION_print
debugADDITION_print_zero:
	pushad
	push eax
	push DEBUG_RESULT_FORMAT
	push dword [stdout]
	call fprintf
	add esp, 12
	popad
	jmp debugADDITION_finish_print
debugADDITION_print_loop:
	mov al, byte [edx]
	pushad
	push eax
	push FORMAT_ZERO
	push dword [stdout]
	call fprintf
	add esp, 12
	popad
	mov ebx, dword [edx+5]				; ebx = previous link
	mov edx, ebx
	cmp edx, 0
	jne debugADDITION_print_loop
debugADDITION_finish_print:
	push NEWLINE_CHAR
	push dword [stdout]
	call fprintf
	add esp, 8
	;==============================================================================================
exit_ADDITION:
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret	
	
PUSH_TO_OPERAND_STACK:
	push	ebp
	mov	ebp, esp
	pushad
	cmp byte [stackIndex], 5
	je stack_overflow_error
	mov esi, inputBuffer
iterate_buffer: 				; iterate over the input buffer to reach its end
	cmp byte [esi], 10 			; check if newline
	je MAKE_LINKED_LIST
	inc esi
	jmp iterate_buffer

MAKE_LINKED_LIST:				; create linked list for the input received
	cmp esi, inputBuffer		; check if input was empty
	je exit_push
	mov ebx, 0
	mov ecx, 0
add_link:
	mov ecx, inputBuffer
	mov edi, esi
	sub edi, ecx 				; edi = length of inputBuffer
	cmp edi, 1
	jl PUSH_NUMBER				; if we finished (no digits remain)					
	je odd_length				; else if one digit remains (odd length)
	sub esi, 2					; else, add link for last two digits
	jmp allocate_memory
odd_length:
	sub esi, 1
allocate_memory:
	pushad
	push dword cMALLOC_ARG		; push 9
	call malloc 				; eax = pointer to memory
	add esp, 4
	cmp dword [headLinkPtr], 0
	jne not_first_2digit_link
first_2digit_link:
	mov dword [headLinkPtr], eax
	popad
	mov edx, dword [headLinkPtr]
	mov dword [edx+1], 0		; initialize the 'next' pointer to be null
	mov dword [edx+5], 0		; initialize the 'prev' pointer to be null
	mov ebx, edx				; ebx = prev = head
	jmp ascii_to_number
not_first_2digit_link:
	mov dword [regularLinkPtr], eax
	popad
	mov edx, dword [regularLinkPtr]
	mov dword [edx+1], 0		; current.next = null
	mov dword [ebx+1], edx		; prev.next = current
	mov dword [edx+5], ebx		; current.prev = prev
	mov ebx, edx
ascii_to_number:
	cmp edi, 1
	je single_ascii_char
	mov cl, byte [esi]			; cl = first digit
	sub cl, 48
	shl cl, 4
	mov ch, byte [esi+1]		; ch = second digit
	sub ch, 48
	or cl, ch					; cl = both digits are now in one byte (not ascii)
	mov byte [edx], cl			; link is now ready
	jmp add_link
single_ascii_char:
	mov cl, byte [esi]
	sub cl, 48
	mov byte [edx], cl
	jmp add_link
exit_push:
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret	

PUSH_NUMBER:
	cmp byte [debugFlag], 1
	jne finish_push
	pushad
	push inputBuffer
	push DEBUG_INPUT_FORMAT
	push dword [stderr]
	call fprintf
	add esp, 12
	popad
finish_push:
	mov ebx, 0
	mov bl, byte [stackIndex]
	shl bl, 2
	mov edx, dword [headLinkPtr]
	mov dword [operandStack + ebx], edx
	inc byte [stackIndex]
	mov dword [headLinkPtr], 0
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret	

POP_AND_PRINT:
	push	ebp
	mov	ebp, esp
	pushad
	cmp byte [inputBuffer+1], 10
	jne exit_pop
	cmp byte [stackIndex], 0
	je cancel_pop
	inc byte [operationCount]
	jmp POP_FROM_OPERAND_STACK
cancel_pop:
	PRINT_ERROR NOT_ENOUGH_ARGS
exit_pop:
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret		
POP_FROM_OPERAND_STACK:
	mov ecx, 0
	mov eax, 0
	mov ebx, 0
	dec byte [stackIndex]
	mov bl, byte [stackIndex]
	shl bl, 2
	mov edx, dword [operandStack + ebx] ; edx = pointer popped from stack
move_to_last_link:
	cmp dword [edx+1], 0
	je print
	mov ebx, dword [edx+1]
	mov edx, ebx
	jmp move_to_last_link
print:
	mov al, byte [edx]
	cmp al, 0
	je skip_link
	pushad
	push eax
	push FORMAT_NOZERO
	call printf
	add esp, 8
	popad
	mov ebx, dword [edx+5]
	pushad								;---------
	push edx	
	call free							; free edx
	add esp, 4
	popad								;---------
	mov edx, ebx
	cmp edx, 0
	je finish_print
	jne print_loop
skip_link:
	mov ebx, dword [edx+5]
	pushad								;---------
	push edx	
	call free							; free edx
	add esp, 4
	popad								;---------
	mov edx, ebx
	cmp edx, 0
	je print_zero
	jne print
print_zero:
	pushad
	push eax
	push FORMAT_NOZERO
	call printf
	add esp, 8
	popad
	jmp finish_print
print_loop:
	mov al, byte [edx]
	pushad
	push eax
	push FORMAT_ZERO
	call printf
	add esp, 8
	popad
	mov ebx, dword [edx+5]				; ebx = previous link
	pushad								;---------
	push edx	
	call free							; free edx
	add esp, 4
	popad								;---------
	mov edx, ebx
	cmp edx, 0
	jne print_loop
finish_print:
	push NEWLINE_CHAR
	call printf
	add esp, 4
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret	

FREE_PTR:
	push	ebp
	mov	ebp, esp
	pushad
lab:
	mov edx, [ebp+8]
free_loop:
	mov ebx, dword [edx+1]
	pushad								;---------
	push edx	
	call free							; free edx
	add esp, 4
	popad								;---------
	mov edx, ebx
	cmp edx, 0
	jne free_loop
	popad
	mov eax, 0
	mov	esp, ebp
	pop	ebp
	ret	
	
END_PROG:
	cmp byte [inputBuffer+1], 10
	jne CALC_LOOP
	mov ebx, 0
exit_loop: 
	cmp byte [stackIndex], 0
	je exit_prog
	dec byte [stackIndex]
	mov bl, byte [stackIndex]
	shl bl, 2
	push dword [operandStack + ebx]
	call FREE_PTR
	add esp, 4
	jmp exit_loop
exit_prog:
	popad
	mov eax, 0
	mov al, byte [operationCount]
	mov	esp, ebp
	pop	ebp
	ret
