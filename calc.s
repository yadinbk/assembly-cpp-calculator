section	.rodata			; we define (global) read-only variables in .rodata section
    format_string: db "%s", 10, 0	; format string sor fprinf
    format_number: db "%d", 10, 0	; format string sor fprinf
    calc: db "calc: ", 0 ; for printf
    link_size: db 5

section .bss
    OP_STACK: resd 1
    STACK_SIZE: resd 1              ; getting wantef stack size
    STACK_PTR: resd 1
    COUNTER: resb 1
    
    CHAR_COUNTER: resb 1
    NEXT: resb 1
    even_count: resd 1

    IN_BUFF:        resb 80             ; input buffer
    OUT_BUFF:        resb 81             ; output buffer

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern gets 
  extern getchar 
  extern fgets
  extern stdin 

%macro decstr_to_int 1  ; (char*)
    mov ecx, %1         ; ecx point to char*
    mov eax, 0
    mov ebx, 0
    mov bl, [ecx]		; geting only first char (byte) from pointer so sreing

dec_str_to_int:
	sub bl, '0'			; getting numeric value of char
	add eax, ebx 		; accunulating the resuly to eax
	inc ecx				; moving to the next char
	mov bl, [ecx]		; geting only first char (byte) from pointer so sreing
	cmp bl, 10			; "\n"
	jz end_dec_str_to_int		; if "\n" bl its unit and no need to multiply by 10
    cmp bl, 0			; "\0"
	jz end_dec_str_to_int		; if "\n" bl its unit and no need to multiply by 10
	mov edx, 10			; multyply by 10 the accumulating result
	mul edx				; for exampleL 479 = (((4*10)+7)*10)+9)
	jmp dec_str_to_int
end_dec_str_to_int:
%endmacro


%macro create_link 2
	push 5         			; push amount of bytes malloc should allocate -> 1 for data 4 for next adress
	call calloc           		; call malloc	
	add esp, 4
    mov [NEXT], eax    ; backup the adress gor 'next' link
	mov [eax], %1		; Insert the value to the first byte in eax
    mov [eax+1], %2
%endmacro

checker:
    mov eax , [IN_BUFF]         
    cmp eax , 0xA71            ; check if 'q' and \n
    je end2

    cmp eax , 0xA2B                 ; check if '+' and \n
    je addition_op                    

    cmp eax , 0xA70                 ; check if 'p' and \n
    je pop_and_print

    cmp eax , 0xA64                 ;check if 'd' and \n
    je duplicate_op

    cmp eax , 0xA26                 ; check if '&' and \n
    je and_op

    cmp eax , 0xA7C                ; check if '|' and \n
    je or_op

    cmp eax , 0xA6E                 ; check if 'n' and \n
    je countERer_op
    ret

main:
	push ebp
	mov ebp, esp	
	pushad

    mov dword [COUNTER], 0
    mov dword [STACK_PTR], 0
    mov dword [CHAR_COUNTER], 0
    ; mov dword [even_count], 0
	; ////////////////////////////////////////////////////////////////////////

define_stack:
    mov eax , [ebp + 8]
    cmp eax , 2
    je specified_size_stack

default_size_stack:
    mov dword [STACK_SIZE] , 5
    jmp initialize_stack


specified_size_stack:   
    mov eax , [ebp + 12]
    add eax , 4
    mov ebx , [eax]
    decstr_to_int ebx
    mov [STACK_SIZE], eax
    
initialize_stack:
    mov eax, [STACK_SIZE]
    push eax
    call calloc                     ; the pointer to stack on eax
    mov [OP_STACK], eax
    mov dword [STACK_PTR], 0
    add esp, 4

calculator:
    
    ; ; test
    ; push eax
    ; push format_number
    ; call printf
    ; add esp, 8


input_req:
    push calc                       ; push string to stuck
    call printf             
    add esp, 4                      ; remove pushed argument

    mov dword [IN_BUFF] , 0
    push dword [stdin]              ; fgets: stdin
    push dword 80                   ; ..max lenght
    push dword IN_BUFF              ; ..input IN_BUFFfer
    call fgets                      ; pointer to buff in eax
    add esp, 12                     ; remove 3 push from stack

    call checker

    ; mov eax, [IN_BUFF]                ; pointer to IN_BUFFfer
    ; mov [OP_STACK + STACK_PTR], eax 
    ; add dword [STACK_PTR], 4
    ; mov ebx, [OP_STACK]
    ; push ebx
    ; push format_number
    ; call printf
    ; add esp, 8  

chain_number:
    mov eax, 0
    mov al, [IN_BUFF]
    cmp al, 10                     ; '\n'
    je done
    cmp al, 0                     ; '\0'
    je done
    inc dword [CHAR_COUNTER]
convert_hex_to_int:
    cmp al, 9
    jle unit_to_int
    sub al, 55
    jmp sum
unit_to_int:
    sub al, '0'
sum:
    add eax, ebx                
    cmp dword [CHAR_COUNTER], 1     ;so first link->next point to 0
; chain_first_link:
    mov ecx, 0
    create_link al, ecx
    jmp next
chain_sec_and_on:
    mov edx, [NEXT]
    create_link al, edx
next:
    mov edx, [CHAR_COUNTER]
    mov al, [IN_BUFF + edx] ;;;;?????
    jmp chain_number

done:
    mov edx, [NEXT]
    mov [STACK_PTR], edx ; push NEXT to stack
    inc dword [COUNTER]
    add dword [STACK_PTR], 4
    mov dword [CHAR_COUNTER], 0
    
; /////////////////////////////////////////////////////

    mov eax, 0
    mov al, [OP_STACK]
pre_int_to_hex:
	mov ecx, 0
	mov ebx, 16			; for %16 to hexa value
int_to_hex:
	mov edx, 0
	div ebx				; %16
	cmp edx, 9			; ck if edx in [0-9] | [10-15]
	jle units_to_hex
							; else greater than 9 
	add edx, 55

	jmp chain_to_stack
units_to_hex:
	add edx, '0'

chain_to_stack:
	push edx			; the value is back order
	inc ecx				; in result.length by 1 (char)
	cmp eax, 0			; if eax=0 we convert the whole word
	je pre_end
	jmp int_to_hex

pre_end:
	mov ebx, 0
	mov [OUT_BUFF], ebx		; [an] = 0
end:
	pop edx				; by poping from stach change the char's order
	mov byte [OUT_BUFF + ebx], dl    ; chaing thr result char by char [an + (sizeof(char)*counter)]
	inc ebx
	dec ecx				; loop counter i<result.length
	cmp ecx, 0			
	jnz end;

	; ////////////////////////////////////////////////////////////////////////
	push OUT_BUFF			; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call


addition_op:

pop_and_print:

duplicate_op:

and_op:

or_op:

countERer_op:

end2:

	; ////////////////////////////////////////////////////////////////////////

	popad			
	mov esp, ebp	
	pop ebp
    mov eax, 1                      ; call exit
    int 0x80    
