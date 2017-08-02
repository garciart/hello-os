<h1>Hello Operating System - Part II</h1>
<h2>Creating a Bootloader</h3>
<h3>Introduction</h3>
<p>
In <a href="/README.md" title="Hello, World - Part I"><b>Hello, World - Part I</b></a>, we wrote a simple 16-bit program in assembly language to use as the basis of our operating system. Now, we will create a simple bootloader, the bridge between the computer’s built-in Basic Input/Output System (BIOS) and the BIOS of the operating system you will use, whether it's Windows, OSX, Linux, or one you wrote yourself, as we will do in <a href="hello-world-part-3.html" rel="noopener noreferrer" title="Hello, World - Part III"><b>Hello, World - Part III</b></a>.
</p><p>
<h3>Step 1 - Modify the Code</h3>
</p><p>
For this, we will need to make two modifications to the beginning and end of our hello.asm file:
</p><p>
<ol>
 	<li>While .com files are loaded 256 bytes (i.e., 0x100) into the segment, the computer's BIOS searches for bootloaders at the 31744 byte mark (i.e., 0x7C00). This is a leftover from IBM PC DOS, which no one has bothered to change since 1981! Therefore, we need to change the first line from <pre>org 0x100</pre> to <pre>org 0x7C00</pre></li>
 	<li>Each bootloader is 512 bytes long (i.e., 0x200). When the BIOS detects a possible bootloader, it then checks 510 bytes after the origin for a boot signature (AA 55). If it finds the code, the BIOS then executes the bootloader. Therefore, we need to add the following code to the end of hello.asm:
	<pre>times 510 - ($-$$) db 0  ;Pad the rest of the bootloader with zeros
dw 0xAA55                ;Add the Boot signature</pre></li>
</ol>
</p><p>
So, once again, open the Run dialog by pressing the Windows Logo Key <img src="/README/hello-world-part-2-img-01.png" alt="" /> and <b>R</b> simultaneously. Type "cmd" in the box that appears and hit <b>Enter</b>, then go to the hello_os folder by inputing "cd\hello_os":
</p><p>
<img src="/README/hello-world-part-2-img-02.png" alt="Command Prompt" />
</p><p>
Now, input "notepad hello.asm" and when Notepad opens, make the two modifications to hello.asm we spoke of earlier:
</p><p>
<pre>
BITS 16                   ;Let NASM know to use 16 bit mode
<b style="background-color: yellow; color: black;">org 0x7C00                ;Bootloader memory offset</b>
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
<b style="background-color: yellow; color: black;">times 510 - ($-$$) db 0   ;Pad the rest of the bootloader with zeros</b>
<b style="background-color: yellow; color: black;">dw 0xAA55                 ;Add the Boot signature</b>
</pre>
</p><p>
<h3>Step 2 - Create a Disk Image</h3>
</p><p>
Right now, save the file as "hello.asm" in the c:\hello_os folder and close Notepad. Now, input the following command:
</p><p>
<pre>c:\nasm\nasm.exe -f bin -o hello.img hello.asm</pre>
</p><p>
NASM will compile and link our code into a disk image file (i.e., a bootable disk). Once NASM is complete, you should see the following list of files if you input "dir" (Notice the size of hello.img is exactly 512 bytes):
</p><p>
<img src="/README/hello-world-part-2-img-03.png" alt="NASM Results" />
</p><p>
<h3>Step 3 - Create the Virtual Machine</h3>
</p><p>
Our next step is to download a hypervisor capable of running virtual machines. The two top picks are <a href="http://www.vmware.com/products/player.html" target="_blank" rel="noopener noreferrer" title="Workstation for Windows - VMware Products">VMware Workstation Player</a> and <a href="https://www.virtualbox.org/" target="_blank" rel="noopener noreferrer" title="Oracle VM VirtualBox">Oracle VM VirtualBox</a>. VMware is free for non-commercial use, while VirtualBox is free and open-source. For this demonstration, we will use VirtualBox. So, go to the <a href="https://www.virtualbox.org/" target="_blank" rel="noopener noreferrer" title="Oracle VM VirtualBox">VirtualBox</a> web site, download and install the latest version, and start it up.
</p><p>
<img src="/README/hello-world-part-2-img-04.png" alt="Welcome to VirtualBox!" />
</p><p>
Click on the <b>New</b> icon in the upper left corner. Enter "Hello" for the <b>Name</b>, "Other" for the <b>Type</b>, and "Other/Unknown" for the <b>Version</b>:
</p><p>
<img src="/README/hello-world-part-2-img-05.png" alt="Create a Virtual Machine" />
</p><p>
Select <b>Next</b>, and then select the default setting on the following screens by clicking <b>Next</b> or <b>Create</b> until you return to the main screen:
</p><p>
<img src="/README/hello-world-part-2-img-06.png" alt="Main Menu with Your Virtual Machine" />
</p><p>
Then click on <b>Settings</b>, followed by <b>Storage</b>:
</p><p>
<img src="/README/hello-world-part-2-img-07.png" alt="Storage Settings" />
</p><p>
Right click anywhere in the Storage Tree's blank area and select <b>Add Floppy Controller</b>. You should now see a floppy controller in the Storage Tree:
</p><p>
<img src="/README/hello-world-part-2-img-08.png" alt="Add a Floppy Controller" />
</p><p>
Right click on the floppy controller and select <b>Add Floppy Drive</b>. VirtualBox will ask you would like to choose a floppy disk: click <b>Choose disk</b>:
</p><p>
<img src="/README/hello-world-part-2-img-09.png" alt="Add a Floppy Drive" />
</p><p>
When the Explorer window appears, navigate to c:\hello_os and select hello.img:
</p><p>
<img src="/README/hello-world-part-2-img-10.png" alt="Select a Virtual Disk Image" />
</p><p>
Click <b>OK</b>. Once you are back at the main screen, click on the <b>Start</b> arrow. Your bootloader appears!
</p><p>
<img src="/README/hello-world-part-2-img-11.png" alt="Your bootloader appears" />
</p><p>
Congratulations! You have created a bootable disk! Our next step will be to write a small operating system, then use the bootloader to link our OS with the computer's built-in BIOS, but we'll save that for <a href="/README-3.md" title="Hello, World - Part III"><b>Hello, World - Part III</b></a></p>
