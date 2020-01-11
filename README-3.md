# Hello Operating System - Part III

## Creating the Operating System

### Introduction

In **[Hello, World - Part II](/README-2.md)**, we wrote a simple bootloader, which acts as the bridge between the computer’s built-in Basic Input/Output System (BIOS) and the BIOS of the operating system you will use. Now we are going to use that bootloader to load an operating system, known as a "kernel", into memory. While the purpose of most operating systems is to take control of the computer from its built-in BIOS, as well as to manage memory and calls to input/output (I/O) ports, our kernel will only do one thing: display the message, "Welcome to the Hello, World OS 1.0!"

### Step 1 - Write the Bootloader

Our first step is to go to the c:\hello_os directory, make a copy of "hello.asm", and rename it "bootloader.asm". This is the file we will modify, but before we make changes to the bootloader, we'll first review those changes. Immediately after identifying the bootloader's memory offset, we are going to jump to a "main" function, which will actually load the kernel:

    bits 16                                ;Let NASM know to use 16 bit mode
    org 0x7C00                             ;Bootloader memory offset
    boot: jmp main                         ;Jump over non-executable header info
    nop                                    ;Moves the BPB to 0x0703

However, the space in between the jump and the main function is not empty. The first part contains information about the "disk" that contains the operating system you wish to use; this is called the BIOS Parameter Block (BPB). By the way, if you do not include the BPB (i.e., you replace boot: jmp main with nop), you run the risk of the computer's BIOS incorrectly loading your operating system. This will cause a **"Halt and Catch Fire"** situation, where the computer will not operate until the bootloader is removed (by the way, while you may set the computer on fire in frustration, the computer itself WILL NOT catch fire if the kernel is loaded incorrectly). To avoid such a catastrophe, we will include the "geometry" of the physical memory we are using, in this case, a 1.44kB, 3.5-inch, 2-sided, 18-sector Floppy Disk (remember these?):

    ;*******************************************************************************
    ;Extended BIOS Parameter Block (BPB) for a DOS 4.0 File Allocation Table 12
    ;(FAT12) 1.44kB 3.5-inch, 2-sided, 18-sector Floppy Disk using common mnemonics
    ;names. Check out https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system
    ;*******************************************************************************

    bsOemName:            DB "Hello OS"    ;OEM identifier (8 BYTES)
    bpbBytesPerSector:    DW 0x0200        ;512 Bytes per logical sector (WORD)
    bpbSectorsPerCluster: DB 0x01          ;1 Logical sector per cluster (BYTE)
    bpbReservedSectors:   DW 0x0001        ;1 Reserved logical sector (WORD)
    bpbNumberOfFATs:      DB 0x02          ;2 FATs on the storage media (BYTE)
    bpbRootEntries:       DW 0x00E0        ;224 Root directory entries (WORD)
    bpbTotalSectors:      DW 0x0B40        ;2880 Total logical sectors in volume
                                           ;(WORD)
    bpbMedia:             DB 0xF0          ;Media Descriptor (BYTE): F0 = 1.44kB
                                           ;3.5-inch disk
    bpbSectorsPerFAT:     DW 0x0009        ;9 Logical sectors per FAT (WORD)
    bpbSectorsPerTrack:   DW 0x0012        ;18 Physical sectors per track (WORD)
    bpbHeadsPerCylinder:  DW 0x0002        ;2 Heads (WORD)
    bpbHiddenSectors:     DD 0x00000000    ;Hidden sectors (DWORD)
    bpbTotalSectorsBig:   DD 0x00000000    ;Large total logical sectors (DWORD)
    bsDriveNumber:        DB 0x00          ;Physical drive number (BYTE)
    bsUnused:             DB 0x00          ;ExtFlags (BYTE)
    bsExtBootSignature:   DB 0x29          ;Extended boot signature (BYTE). 0x29
                                           ;indicates that the EBPB has the
                                           ;following 3 entries:
    bsSerialNumber:       DD 0x00010203    ;Volume serial number (DWORD)
    bsVolumeLabel:        DB "HELLO_OS   " ;Volume label (11 BYTES)
    bsFileSystem:         DB "FAT12   "    ;File-system type (8 BYTES)

Next, we will add a message block, as well as several subroutines the main function will call:

    ;*******************************************************************************
    ;Messages
    ;*******************************************************************************

    bootloader_started_msg db "Boot loader started...", 0x0D, 0x0A, 0
    floppy_reset_msg db "Floppy disk reset...", 0x0D, 0x0A, 0
    kernel_loaded_msg db "Kernel loaded...", 0x0D, 0x0A, 0

    ;The following message should never appear
    bootloader_complete_msg db "Bootloader complete.", 0x0D, 0x0A, 0

    ;*******************************************************************************
    ;Functions
    ;*******************************************************************************

    ;Print message located at the address stored in the SI register
    print_msg:
        mov ah,0x0E                        ;Teletype function code for INT 10
    .start_loop:                           ;Loop start point label
        lodsb                              ;Load the char at the SI address
                                           ;into AL and go to the next char
        cmp al,0x00                        ;Compare AL to 0
        je .end_loop                       ;Jump to end_loop if AL equals 0
        int 0x10                           ;Call INT 10 to print the char
                                           ;in AL to the screen
        jmp .start_loop                    ;Jump back to the loop start point
    .end_loop:                             ;End of the loop label
        ret                                ;return control to the caller

    ;Reset the floppy controller to the first sector on the disk
    reset_floppy:
        mov ah,0x00                        ;Reset Disk Drives function code for
                                           ;INT 13
        mov dl,0x00                        ;Set 1st floppy drive as drive to reset
        int 0x13                           ;Call INT 13 to reset the drive
        jc reset_floppy                    ;Try again if carry flag (CF) is set
                                           ;(indicates an error)
        mov si, floppy_reset_msg           ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine
        ret                                ;return control to the caller

    ;Load the kernel 
    read_kernel:
        mov ax,0x1000
        mov es,ax                          ;Set the Extra Segment (ES) value to
                                           ;4096
        xor bx,bx                          ;Set the BX register to 0
                                           ;The kernel's address will be 1000:0000
        mov ah,0x02                        ;Read Sectors From Drive function code
                                           ;for INT 13
        mov al,0x01                        ;Sectors to read count
        mov ch,0x00                        ;Cylinder
        mov cl,0x02                        ;Sector to read
        mov dh,0x00                        ;Head number
        mov dl,0x00                        ;Drive number
        int 0x13                           ;BIOS Interrupt Call
        jc read_kernel                     ;Try again if carry flag (CF) is set
                                           ;(indicates an error)
        mov si, kernel_loaded_msg          ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine 
        jmp 0x1000:0x0000                  ;Jump to kernel

Once that is complete, we will add the main function, which calls the subroutines to load the kernel:

    ;*******************************************************************************
    ;Main function
    ;*******************************************************************************

    main:
        mov si, bootloader_started_msg     ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine
        call reset_floppy                  ;call the reset subroutine 
        call read_kernel                   ;call the load kernel subroutine 

        ;Bootloader is complete at this time and this message should never appear
        mov si, bootloader_complete_msg    ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine

Finally, we will close the bootloader by adding the boot signature:

    ;*******************************************************************************
    ;Boot signature
    ;*******************************************************************************

    times 510 - ($-$$) db 0                ;Pad the rest of the bootloader with
                                           ;zeros
    dw 0xAA55                              ;Add the Boot signature

Here is the completed bootloader. Open "bootloader.asm" in Notepad, enter the following code, and save the file:

    bits 16                                ;Let NASM know to use 16 bit mode
    org 0x7C00                             ;Bootloader memory offset
    boot: jmp main                         ;Jump over non-executable header info
    nop                                    ;Moves the BPB to 0x0703

    ;*******************************************************************************
    ;Extended BIOS Parameter Block (BPB) for a DOS 4.0 File Allocation Table 12
    ;(FAT12) 1.44kB 3.5-inch, 2-sided, 18-sector Floppy Disk using common mnemonics
    ;names. Check out https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system
    ;*******************************************************************************

    bsOemName:            DB "Hello OS"    ;OEM identifier (8 BYTES)
    bpbBytesPerSector:    DW 0x0200        ;512 Bytes per logical sector (WORD)
    bpbSectorsPerCluster: DB 0x01          ;1 Logical sector per cluster (BYTE)
    bpbReservedSectors:   DW 0x0001        ;1 Reserved logical sector (WORD)
    bpbNumberOfFATs:      DB 0x02          ;2 FATs on the storage media (BYTE)
    bpbRootEntries:       DW 0x00E0        ;224 Root directory entries (WORD)
    bpbTotalSectors:      DW 0x0B40        ;2880 Total logical sectors in volume
                                           ;(WORD)
    bpbMedia:             DB 0xF0          ;Media Descriptor (BYTE): F0 = 1.44kB
                                           ;3.5-inch disk
    bpbSectorsPerFAT:     DW 0x0009        ;9 Logical sectors per FAT (WORD)
    bpbSectorsPerTrack:   DW 0x0012        ;18 Physical sectors per track (WORD)
    bpbHeadsPerCylinder:  DW 0x0002        ;2 Heads (WORD)
    bpbHiddenSectors:     DD 0x00000000    ;Hidden sectors (DWORD)
    bpbTotalSectorsBig:   DD 0x00000000    ;Large total logical sectors (DWORD)
    bsDriveNumber:        DB 0x00          ;Physical drive number (BYTE)
    bsUnused:             DB 0x00          ;ExtFlags (BYTE)
    bsExtBootSignature:   DB 0x29          ;Extended boot signature (BYTE). 0x29
                                           ;indicates that the EBPB has the
                                           ;following 3 entries:
    bsSerialNumber:       DD 0x00010203    ;Volume serial number (DWORD)
    bsVolumeLabel:        DB "HELLO_OS   " ;Volume label (11 BYTES)
    bsFileSystem:         DB "FAT12   "    ;File-system type (8 BYTES)

    ;*******************************************************************************
    ;Messages
    ;*******************************************************************************

    bootloader_started_msg db "Boot loader started...", 0x0D, 0x0A, 0
    floppy_reset_msg db "Floppy disk reset...", 0x0D, 0x0A, 0
    kernel_loaded_msg db "Kernel loaded...", 0x0D, 0x0A, 0

    ;The following message should never appear
    bootloader_complete_msg db "Bootloader complete.", 0x0D, 0x0A, 0

    ;*******************************************************************************
    ;Functions
    ;*******************************************************************************

    ;Print message located at the address stored in the SI register
    print_msg:
        mov ah,0x0E                        ;Teletype function code for INT 10
    .start_loop:                           ;Loop start point label
        lodsb                              ;Load the char at the SI address
                                           ;into AL and go to the next char
        cmp al,0x00                        ;Compare AL to 0
        je .end_loop                       ;Jump to end_loop if AL equals 0
        int 0x10                           ;Call INT 10 to print the char
                                           ;in AL to the screen
        jmp .start_loop                    ;Jump back to the loop start point
    .end_loop:                             ;End of the loop label
        ret                                ;return control to the caller

    ;Reset the floppy controller to the first sector on the disk
    reset_floppy:
        mov ah,0x00                        ;Reset Disk Drives function code for
                                           ;INT 13
        mov dl,0x00                        ;Set 1st floppy drive as drive to reset
        int 0x13                           ;Call INT 13 to reset the drive
        jc reset_floppy                    ;Try again if carry flag (CF) is set
                                           ;(indicates an error)
        mov si, floppy_reset_msg           ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine
        ret                                ;return control to the caller

    ;Load the kernel 
    read_kernel:
        mov ax,0x1000
        mov es,ax                          ;Set the Extra Segment (ES) value to
                                           ;4096
        xor bx,bx                          ;Set the BX register to 0
                                           ;The kernel's address will be 1000:0000
        mov ah,0x02                        ;Read Sectors From Drive function code
                                           ;for INT 13
        mov al,0x01                        ;Sectors to read count
        mov ch,0x00                        ;Cylinder
        mov cl,0x02                        ;Sector to read
        mov dh,0x00                        ;Head number
        mov dl,0x00                        ;Drive number
        int 0x13                           ;BIOS Interrupt Call
        jc read_kernel                     ;Try again if carry flag (CF) is set
                                           ;(indicates an error)
        mov si, kernel_loaded_msg          ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine 
        jmp 0x1000:0x0000                  ;Jump to kernel

    ;*******************************************************************************
    ;Main function
    ;*******************************************************************************

    main:
        mov si, bootloader_started_msg     ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine
        call reset_floppy                  ;call the reset subroutine 
        call read_kernel                   ;call the load kernel subroutine 

        ;Bootloader is complete at this time and this message should never appear
        mov si, bootloader_complete_msg    ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine

    ;*******************************************************************************
    ;Boot signature
    ;*******************************************************************************

    times 510 - ($-$$) db 0                ;Pad the rest of the bootloader with
                                           ;zeros
    dw 0xAA55                              ;Add the Boot signature

### Step 2 - Write the Kernel

Now we are going to write the kernel. You can make the kernel as complicated as you like (e.g., adding code to load utility files, etc.), but as I said before, ours will only display a simple message. Once again, we are going to start with a jump to the main function, known as "k_main" (i.e., kernel main):

    kernel: jmp k_main                     ;Jump to k_main

Next, we will add a message block, as well as several subroutines the k_main function will call:

    ;*******************************************************************************
    ;Messages
    ;*******************************************************************************
    
    kernel_msg db "Welcome to the Hello, World OS 1.0!", 0x0D, 0x0A, 0
    
    ;*******************************************************************************
    ;Functions
    ;*******************************************************************************

    ;Print message located at the address stored in the SI register
    print_msg:
        mov ah,0x0E                        ;Teletype function code for INT 10
    .start_loop:                           ;Loop start point label
        lodsb                              ;Load the char at the SI address
                                           ;into AL and go to the next char
        cmp al,0x00                        ;Compare AL to 0
        je .end_loop                       ;Jump to end_loop if AL equals 0
        int 0x10                           ;Call INT 10 to print the char
                                           ;in AL to the screen
        jmp .start_loop                    ;Jump back to the loop start point
    .end_loop:                             ;End of the loop label
        ret                                ;return control to the caller

Once that is complete, we will add the k_main function, which displays our message:

    ;*******************************************************************************
    ;Main function
    ;*******************************************************************************

    k_main:
        push cs                            ;Save the value of the Code Segment (CS)
                                           ;register to the stack
        pop ds                             ;Pop the CS value into the Data Segment
                                           ;(DS) register
                                           ;This offsets the location of the
                                           ;kernel's welcome message
        mov si, kernel_msg                 ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine
    .k_main_loop:
        jmp .k_main_loop                   ;Start a continuous loop

Finally, we'll close the kernel, padding the rest of the sector with zeros:

    ;Fill up the rest of the sector. No Boot signature needed
    times 512-($-$$) db 0

Here is the completed kernel. Create a file named "kernel.asm" in the c:\hello_os directory. Open the file in Notepad, enter the following code, and save the file:

    kernel: jmp k_main                     ;Jump to k_main
    
    ;*******************************************************************************
    ;Messages
    ;*******************************************************************************
    
    kernel_msg db "Welcome to the Hello, World OS 1.0!", 0x0D, 0x0A, 0
    
    ;*******************************************************************************
    ;Functions
    ;*******************************************************************************

    ;Print message located at the address stored in the SI register
    print_msg:
        mov ah,0x0E                        ;Teletype function code for INT 10
    .start_loop:                           ;Loop start point label
        lodsb                              ;Load the char at the SI address
                                           ;into AL and go to the next char
        cmp al,0x00                        ;Compare AL to 0
        je .end_loop                       ;Jump to end_loop if AL equals 0
        int 0x10                           ;Call INT 10 to print the char
                                           ;in AL to the screen
        jmp .start_loop                    ;Jump back to the loop start point
    .end_loop:                             ;End of the loop label
        ret                                ;return control to the caller

    ;*******************************************************************************
    ;Main function
    ;*******************************************************************************
    
    k_main:
        push cs                            ;Save the value of the Code Segment (CS)
                                           ;register to the stack
        pop ds                             ;Pop the CS value into the Data Segment
                                           ;(DS) register
                                           ;This offsets the location of the
                                           ;kernel's welcome message
        mov si, kernel_msg                 ;Move the address of msg into the
                                           ;SI register
        call print_msg                     ;call the output subroutine
    .k_main_loop:
        jmp .k_main_loop                   ;Start a continuous loop
    
    ;Fill up the rest of the sector. No Boot signature needed
    times 512-($-$$) db 0

### Step 3 - Put It All Together

Now that our bootloader and kernel are complete, we will use NASM to compile and link our code into a disk image file (i.e., a bootable disk). Follow the instructions in [Hello, World - Part II](/README-2.md) to open a command window in the c:\hello_os directory and input the following commands:

    c:\nasm\nasm.exe -f bin -o bootloader.img bootloader.asm
    c:\nasm\nasm.exe -f bin -o kernel.img kernel.asm
    copy bootloader.img /b + kernel.img hello_os.img (or cmd /c copy bootloader.img /b + kernel.img hello_os.img if you are using Powershell)

Once NASM is complete, you should see the following list of files if you input "dir" (Notice the size of hello_os.img is exactly 1024 bytes):

<p align="center"><img src="/README/hello-world-part-3-img-01.png" alt="NASM Results" /></p>

Once again, follow the instructions in [Hello, World - Part II](/README-2.md) to upload a disk image in VirtualBox, but name the virtual machine "Hello OS" and use hello_os.img instead of hello.img:

<p align="center"><img src="/README/hello-world-part-3-img-02.png" alt="Create the Virtual Machine" /></p>

<p align="center"><img src="/README/hello-world-part-3-img-03.png" alt="Select the Disk Image" /></p>

Click **OK**. Once you are back at the main screen, click on the **Start** arrow. Your bootloader will run first and load the kernel, and then your operating system will appear!

<p align="center"><img src="/README/hello-world-part-3-img-04.png" alt="Welcome to the Hello, World OS 1.0!" /></p>

Congratulations! You have created an operating system! Using an BIOS interrupt list, such as the one at [OSDev.org](http://wiki.osdev.org/BIOS), you can expand your operating system by adding commands, functions, and applications. Good luck and have fun!
