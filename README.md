<h3>Introduction</h3>
<p>
Ever since Brian Kernighan published "<a href="https://www.bell-labs.com/usr/dmr/www/ctut.pdf" target="_blank" rel="noopener noreferrer" title="Programming in C - A Tutorial">Programming in C - A Tutorial</a>" in 1974, the "Hello, World!" program has become the Lorem Ipsum of the computer world. Therefore, it would make sense to open this blog by saying "Hello" as well.
</p><p>
Now, I've written operating systems in Kali Linux using tools such as dd, qemu, and bochs, but I haven't found much literature for writing and running an OS in Windows. So, using Nick Blundell's wonderful paper, "<a href="https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf" target="_blank" rel="noopener noreferrer" title="Writing a Simple Operating System - from Scratch">Writing a Simple Operating System - from Scratch</a>", as a template, we'll write an OS, using Windows tools, that says, "Hello, World!" upon booting up. Let's get started!
</p><p>
<b>NOTE</b> - In order to create this operating system, you must have a basic knowledge of assembly language. If not, I suggest searching the Internet for "assembly language tutorial" or purchasing an introductory text from Amazon. Unfortunately, my favorite book, <em>Peter Norton's Assembly Language Book for the IBM PC</em>, is out of print.
</p><p>
<h3>Step 1 - Understanding the Boot Process</h3>
</p><p>
All x86-based computers start in Real Address Mode, which allows programs to directly access to all addressable memory (up to 1 MB) and input/output (I/O) ports. When you press the computer's power button, the Power Supply Unit (PSU) wakes up the computer's built-in Basic I/O System (BIOS). The BIOS uses Real Mode to test the computer's memory and peripherals devices and then looks for a bootloader. The purpose of a bootloader is to collect information about the computer and pass it on to the operating system, which will take control of the computer from the BIOS. The operating system, running in Protected Mode, "manages" calls between applications and hardware, preventing errors that may occur when applications directly access memory or hardware.
</p><p>
<h3>Step 2 - Getting the Tools</h3>
</p><p>
Real Mode uses a 16-bit data bus, which means it uses 16-bit registers, which means we will have to write our program in 16-bit assembly language. While many assemblers are capable of compiling 16-bit code, we are going to use Tatham and Co.'s <a href="http://www.nasm.us/" target="_blank" rel="noopener noreferrer" title="NASM">Netwide Assembler (NASM)</a> for our project. We will need Qbix and Co.'s <a href="https://www.dosbox.com/" target="_blank" rel="noopener noreferrer" title="DOSBox, an x86 emulator with DOS">DOSBox</a> as well. <b>Please click on the hyperlinks provided to download and install these programs now.</b>
</p><p>
<h3>Step 3 - Writing the Code</h3>
</p><p>
Open the Run dialog by pressing the Windows Logo Key <img src="hello-world-part-1-img-01.png" alt="hello-world-part-1-img-01.png" /> and <b>R</b> simultaneously. Type "cmd" in the box that appears and hit <b>Enter</b>.
</p><p>
<img src="https://github.com/garciart/hello-os/README/hello-world-part-1-img-02.png" alt="hello-world-part-1-img-02.png" />
</p><p>
Now, we will create a folder named "hello_os" under your local disk, usually Local Disk (C:), using <b>mkdir</b>. Not only is this the directory where we will be storing our code, but it will also act as a local drive for DOSBox later on.
</p><p>
<img src="/README/hello-world-part-1-img-03.png" alt="hello-world-part-1-img-03.png" />
</p><p>
Type in "notepad hello.asm" and hit <b>Enter</b>. If you are prompted to create a new file, click <b>Yes</b>:
</p><p>
<img src="hello-world-part-1-img-04.png" alt="hello-world-part-1-img-04.png" />
</p><p>
Enter in the text below in the Notepad window:
</p><p>
<pre>
BITS 16                   ;Let NASM know to use 16 bit mode
org 0x100                 ;.com files always start 256 bytes into the segment
mov si,msg                ;Move the address of msg into the SI register
mov ah,0x0e               ;Teletype function code for INT 10
startloop:                ;Loop start point label
lodsb                     ;Load the char at the SI address into AL and go to
                          ;the next char
cmp al,0x00               ;Compare AL to 0
je endloop                ;Jump to endloop if AL equals 0
int 0x10                  ;Call INT 10 to print the char in AL to the screen
jmp startloop             ;Jump back to the loop start point
endloop:                  ;End of the loop label
ret                       ;Quit the program
msg: db 'hello, world',0  ;Bytes to print
</pre>
</p><p>
Notice that we are using INT 10 and a loop to print one character at a time to the screen, instead of using INT 21 or INT 80 to print the whole "hello, world" string. The reason is that INT 21 is a call to the MS-DOS API and INT 80 is a call to the UNIX API, neither of which are available to the BIOS, unlike INT 10.
</p><p>
Save the file as "hello.asm" in the c:\hello_os folder and close Notepad. Now, input in the following command:
</p><p>
<pre>c:\nasm\nasm.exe -f bin -o hello.com hello.asm</pre>
</p><p>
NASM will compile and link our code into an executable COM file. Once NASM is complete, you should see the following list of files if you input "dir":
</p><p>
<img src="hello-world-part-1-img-05.png" alt="hello-world-part-1-img-05.png" />
</p><p>
<h3>Step 4 - Running the Program</h3>
</p><p>
Input "hello.com" at the prompt and you should get an error, similar to the one below:
</p><p>
<img src="hello-world-part-1-img-06.png" alt="hello-world-part-1-img-06.png" />
</p><p>
This is because modern Windows runs in 32-bit Protected Mode or greater. Click <b>OK</b> and exit the command prompt by typing in "exit". Start DOSBox and input "mount c c:\hello_os" at the Z prompt and hit <b>Enter</b>:
</p><p>
<img src="hello-world-part-1-img-07.png" alt="hello-world-part-1-img-07.png" />
</p><p>
Input "C:" to get to the hello_os directory, and then input "dir" to see the files and their sizes. Now, when you input "hello", you will see our greeting!
</p><p>
<img src="hello-world-part-1-img-08.png" alt="hello-world-part-1-img-08.png" />
</p><p>
Notice the size of hello.com. It is only 28 bytes; smaller than hello.asm. That is because NASM removed all the comments and left only the machine code:
</p><p>
<pre>BE 0F 01 B4 0E AC 3C 00 74 04 CD 10 EB F7 C3 68 65 6C 6C 6F 2C 20 77 6F 72 6C 64 00</pre>
</p><p>
Which means:
</p><p>
<pre>
0000:0100  BE0F01                      MOV    SI,010F
0000:0103  B40E                        MOV    AH,0E
0000:0105  AC                          LODSB
0000:0106  3C00                        CMP    AL,00
0000:0108  7404                        JE     E
0000:010A  CD10                        INT    10
0000:010C  EBF7                        JMP    5
0000:010E  C3                          RET
0000:010F  68656C6C6F2C20776F726C6400  hello,world
</pre>
</p><p>
For those of you new to assembly language programming, note the commands at addresses 0108 and 010C. 74 is the machine code for Jump-If-Equal (JE). If the following hexadecimal number is less than 0x80, the processor jumps forwards. If the number is greater than or equal to 0x80, the processor jumps backwards. Since 0x04 is less than 0x80, the processor will jump forward 4 bytes FROM THAT POINT, not from 0108, i.e., address 0108 + 2 bytes for JE = Jump 4 bytes from 010A = address 010E.
</p><p>
At 010C, EB is the machine code for Jump. Since 0xF7 is greater than 0x80, the jump will be backwards. However, if 0x00 is 0, then 0xFF is -1, so F7 is -9. Therefore, the processor will jump 9 bytes backwards FROM THAT POINT, not 010C, i.e., address 010C + 2 bytes for JMP = Jump backwards 9 bytes from 010E = address 0105. Daniel Sedory provides a great explanation of this process; <a href="http://thestarman.pcministry.com/asm/2bytejumps.htm" target="_blank" rel="noopener noreferrer" title="Using SHORT (Two-byte)
Relative Jump Instructions">check it out here</a>.
</p><p>
Input "exit" to leave DOSBox.
</p><p>
Yay! You have created and executed a 16-bit program using Windows tools! Our next step will be to use this code as a basis for our bootloader, but we'll save that for <a href="hello-world-part-2.html" rel="noopener noreferrer" title="Hello, World - Part II"><b>Hello, World - Part II</b></a></p>
