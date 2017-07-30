BITS 16                   ;Let NASM know to use 16 bit mode
org 0x7C00                ;Bootloader memory offset
mov si,msg                ;Move the address of msg into the SI register
mov ah,0x0e               ;Teletype function code for INT 10
startloop:                ;Loop start point label
lodsb                     ;Load the char at the SI address into AL and go to
                          ;the next char
cmp al,0x00               ;Compare AL to 0
je endloop                ;Jump to endloop if AL equals 0
int 0x10                  ;Call INT 10 to print the char in AL to the screen
jmp startloop             ;Jump back to the loop start point
endloop:                  ;End of the loop label
ret                       ;Quit the program
msg: db 'hello, world',0  ;Bytes to print
times 510 - ($-$$) db 0   ;Pad the rest of the bootloader with zeros
dw 0xAA55                 ;Add the Boot signature