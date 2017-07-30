kernel: jmp k_main                     ; Jump to k_main
 
; ******************************************************************************
; Messages
; ******************************************************************************
 
kernel_msg db "Welcome to the Hello, World OS 1.0!", 0x0D, 0x0A, 0
 
; ******************************************************************************
; Functions
; ******************************************************************************

; Print message located at the address stored in the SI register
print_msg:
    mov ah,0x0E                        ; Teletype function code for INT 10
.start_loop:                           ; Loop start point label
    lodsb                              ; Load the char at the SI address
                                       ; into AL and go to the next char
    cmp al,0x00                        ; Compare AL to 0
    je .end_loop                       ; Jump to end_loop if AL equals 0
    int 0x10                           ; Call INT 10 to print the char
                                       ; in AL to the screen
    jmp .start_loop                    ; Jump back to the loop start point
.end_loop:                             ; End of the loop label
    ret                                ; return control to the caller

; ******************************************************************************
; Main function
; ******************************************************************************
 
k_main:
    push cs                            ; Save the value of the Code Segment (CS)
                                       ; register to the stack
    pop ds                             ; Pop the CS value into the Data Segment
                                       ; (DS) register
                                       ; This offsets the location of the
                                       ; kernel's welcome message
    mov si, kernel_msg                 ; Move the address of msg into the
                                       ; SI register
    call print_msg                     ; call the output subroutine
.k_main_loop:
    jmp .k_main_loop                   ; Start a continuous loop
 
; Fill up the rest of the sector. No Boot signature needed
times 512-($-$$) db 0