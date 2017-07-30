bits 16                                ; Let NASM know to use 16 bit mode
org 0x7C00                             ; Bootloader memory offset
boot: jmp main                         ; Jump over non-executable header info
nop                                    ; Moves the BPB to 0x0703

; ******************************************************************************
; Extended BIOS Parameter Block (BPB) for a DOS 4.0 File Allocation Table 12
; (FAT12) 1.44kB 3.5-inch, 2-sided, 18-sector Floppy Disk using common mnemonics
; names. Check out https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system
; ******************************************************************************

bsOemName:            DB "Hello OS"    ; OEM identifier (8 BYTES)
bpbBytesPerSector:    DW 0x0200        ; 512 Bytes per logical sector (WORD)
bpbSectorsPerCluster: DB 0x01          ; 1 Logical sector per cluster (BYTE)
bpbReservedSectors:   DW 0x0001        ; 1 Reserved logical sector (WORD)
bpbNumberOfFATs:      DB 0x02          ; 2 FATs on the storage media (BYTE)
bpbRootEntries:       DW 0x00E0        ; 224 Root directory entries (WORD)
bpbTotalSectors:      DW 0x0B40        ; 2880 Total logical sectors in volume
                                       ; (WORD)
bpbMedia:             DB 0xF0          ; Media Descriptor (BYTE): F0 = 1.44kB
                                       ; 3.5-inch disk
bpbSectorsPerFAT:     DW 0x0009        ; 9 Logical sectors per FAT (WORD)
bpbSectorsPerTrack:   DW 0x0012        ; 18 Physical sectors per track (WORD)
bpbHeadsPerCylinder:  DW 0x0002        ; 2 Heads (WORD)
bpbHiddenSectors:     DD 0x00000000    ; Hidden sectors (DWORD)
bpbTotalSectorsBig:   DD 0x00000000    ; Large total logical sectors (DWORD)
bsDriveNumber:        DB 0x00          ; Physical drive number (BYTE)
bsUnused:             DB 0x00          ; ExtFlags (BYTE)
bsExtBootSignature:   DB 0x29          ; Extended boot signature (BYTE). 0x29
                                       ; indicates that the EBPB has the
                                       ; following 3 entries:
bsSerialNumber:       DD 0x00010203    ; Volume serial number (DWORD)
bsVolumeLabel:        DB "HELLO_OS"    ; Volume label (11 BYTES)
bsFileSystem:         DB "FAT12   "    ; File-system type (8 BYTES)

; ******************************************************************************
; Messages
; ******************************************************************************

bootloader_started_msg db "Boot loader started...", 0x0D, 0x0A, 0
floppy_reset_msg db "Floppy disk reset...", 0x0D, 0x0A, 0
kernel_loaded_msg db "Kernel loaded...", 0x0D, 0x0A, 0

; The following message should never appear
bootloader_complete_msg db "Bootloader complete.", 0x0D, 0x0A, 0

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

; Reset the floppy controller to the first sector on the disk
reset_floppy:
    mov ah,0x00                        ; Reset Disk Drives function code for
                                       ; INT 13
    mov dl,0x00                        ; Set 1st floppy drive as drive to reset
    int 0x13                           ; Call INT 13 to reset the drive
    jc reset_floppy                    ; Try again if carry flag (CF) is set
                                       ; (indicates an error)
    mov si, floppy_reset_msg           ; Move the address of msg into the
                                       ; SI register
    call print_msg                     ; call the output subroutine
    ret                                ; return control to the caller

; Load the kernel 
read_kernel:
    mov ax,0x1000
    mov es,ax                          ; Set the Extra Segment (ES) value to
                                       ; 4096
    xor bx,bx                          ; Set the BX register to 0
                                       ; The kernel's address will be 1000:0000
    mov ah,0x02                        ; Read Sectors From Drive function code
                                       ; for INT 13
    mov al,0x01                        ; Sectors to read count
    mov ch,0x00                        ; Cylinder
    mov cl,0x02                        ; Sector to read
    mov dh,0x00                        ; Head number
    mov dl,0x00                        ; Drive number
    int 0x13                           ; BIOS Interrupt Call
    jc read_kernel                     ; Try again if carry flag (CF) is set
                                       ; (indicates an error)
    mov si, kernel_loaded_msg          ; Move the address of msg into the
                                       ; SI register
    call print_msg                     ; call the output subroutine 
    jmp 0x1000:0x0000                  ; Jump to kernel

; ******************************************************************************
; Main function
; ******************************************************************************

main:
    mov si, bootloader_started_msg     ; Move the address of msg into the
                                       ; SI register
    call print_msg                     ; call the output subroutine
    call reset_floppy                  ; call the reset subroutine 
    call read_kernel                   ; call the load kernel subroutine 

    ; Bootloader is complete at this time and this message should never appear
    mov si, bootloader_complete_msg    ; Move the address of msg into the
                                       ; SI register
    call print_msg                     ; call the output subroutine

; ******************************************************************************
; Boot signature
; ******************************************************************************

times 510 - ($-$$) db 0                ; Pad the rest of the bootloader with
                                       ; zeros
dw 0xAA55                              ; Add the Boot signature