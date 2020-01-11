# Hello Operating System - Part II

## Creating a Bootloader

### Introduction

In **[Hello, World - Part I](/README.md)**, we wrote a simple 16-bit program in assembly language to use as the basis of our operating system. Now, we will create a simple bootloader, the bridge between the computer’s built-in Basic Input/Output System (BIOS) and the BIOS of the operating system you will use, whether it's Windows, OSX, Linux, or one you wrote yourself, as we will do in **[Hello, World - Part III](/README-3.md)**.

### Step 1 - Modify the Code

For this, we will need to make two modifications to the beginning and end of our hello.asm file:

1. While .com files are loaded 256 bytes (i.e., 0x100) into the segment, the computer's BIOS searches for bootloaders at the 31744 byte mark (i.e., 0x7C00). This is a leftover from IBM PC DOS, which no one has bothered to change since 1981! Therefore, we need to change the first line from:

        org 0x100

    to:

        org 0x7C00

2. Each bootloader is 512 bytes long (i.e., 0x200). When the BIOS detects a possible bootloader, it then checks 510 bytes after the origin for a boot signature (AA 55). If it finds the code, the BIOS then executes the bootloader. Therefore, we need to add the following code to the end of hello.asm:

        times 510 - ($-$$) db 0  ;Pad the rest of the bootloader with zeros
        dw 0xAA55                ;Add the Boot signature

So, once again, open the Run dialog by pressing the Windows Key ![⊞](README/hello-world-part-1-img-01.png) and <kbd>R</kbd> simultaneously. Type "cmd" in the box that appears and hit <kbd>Enter</kbd>, then go to the hello_os folder by inputing "cd\hello_os":

<p align="center"><img src="/README/hello-world-part-2-img-02.png" alt="Command Prompt" /></p>

Now, input "notepad hello.asm" and when Notepad opens, make the two modifications to hello.asm we spoke of earlier:

    BITS 16                   ;Let NASM know to use 16 bit mode
    org 0x7C00                ;**Bootloader memory offset**
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
    times 510 - ($-$$) db 0   ;**Pad the rest of the bootloader with zeros**
    dw 0xAA55                 ;**Add the Boot signature**

### Step 2 - Create a Disk Image

Right now, save the file as "hello.asm" in the c:\hello_os folder and close Notepad. Now, input the following command:

    c:\nasm\nasm.exe -f bin -o hello.img hello.asm

NASM will compile and link our code into a disk image file (i.e., a bootable disk). Once NASM is complete, you should see the following list of files if you input "dir" (Notice the size of hello.img is exactly 512 bytes):

<p align="center"><img src="/README/hello-world-part-2-img-03.png" alt="NASM Results" /></p>

### Step 3 - Create the Virtual Machine

Our next step is to download a hypervisor capable of running virtual machines. The two top picks are [Workstation for Windows - VMware Products](http://www.vmware.com/products/player.html) and [Oracle VM VirtualBox](https://www.virtualbox.org/). VMware is free for non-commercial use, while VirtualBox is free and open-source. For this demonstration, we will use VirtualBox. So, go to the [Oracle VM VirtualBox](https://www.virtualbox.org/) web site, download and install the latest version, and start it up.

<p align="center"><img src="/README/hello-world-part-2-img-04.png" alt="Welcome to VirtualBox!" /></p>

Click on the **New** icon in the upper left corner. Enter "Hello" for the **Name**, "Other" for the **Type**, and "Other/Unknown" for the **Version**:

<p align="center"><img src="/README/hello-world-part-2-img-05.png" alt="Create a Virtual Machine" /></p>

Select **Next**, and then select the default setting on the following screens by clicking **Next** or **Create** until you return to the main screen:

<p align="center"><img src="/README/hello-world-part-2-img-06.png" alt="Main Menu with Your Virtual Machine" /></p>

Then click on **Settings**, followed by **Storage**:

<p align="center"><img src="/README/hello-world-part-2-img-07.png" alt="Storage Settings" /></p>

Right click anywhere in the Storage Tree's blank area and select **Add Floppy Controller**. You should now see a floppy controller in the Storage Tree:

<p align="center"><img src="/README/hello-world-part-2-img-08.png" alt="Add a Floppy Controller" /></p>

Right click on the floppy controller and select **Add Floppy Drive**. VirtualBox will ask you would like to choose a floppy disk: click **Choose disk**:

<p align="center"><img src="/README/hello-world-part-2-img-09.png" alt="Add a Floppy Drive" /></p>

When the Explorer window appears, navigate to c:\hello_os and select hello.img:

<p align="center"><img src="/README/hello-world-part-2-img-10.png" alt="Select a Virtual Disk Image" /></p>

Click **OK**. Once you are back at the main screen, click on the **Start** arrow. Your bootloader appears!

<p align="center"><img src="/README/hello-world-part-2-img-11.png" alt="Your bootloader appears" /></p>

Congratulations! You have created a bootable disk! Our next step will be to write a small operating system, then use the bootloader to link our OS with the computer's built-in BIOS, but we'll save that for **[Hello, World - Part III](/README-3.md)**.
