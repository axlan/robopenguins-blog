---
title: x86 Boot Loading
author: jon
layout: post
categories:
  - Software
image: 2020/x86_reg.png
---

In my previous careers, I've spent a decent amount of time involved with bringing up processors in embedded platforms. However, despite spending a decent amount of time working with bootloaders and bare metal processors, I still don't have a great sense of exactly what they do and how software is built for them. As a learning exercise, I'm in the process of going from the lowest level with the goal of having a loose understanding of most of what it takes to bring up a Linux OS.

# Choosing My Initial Approach

There's a lot of moving parts when booting a processor. I spent a couple days digging into the following areas:

 * PXE - This is a protocol for having the boot process pull the images over the network
 * BIOS Protected Mode Programming - This is the environment you are programming in when you run code before any other boot loader
 * Cross Compiling Linux - This is my end goal. I could either build the pieces from individual source repos, or use a framework like BuildRoot.
 * QEMU - This is an emulator that can make testing development a lot simpler by removing hardware from the equation
 * Asm Programming - I've done a tiny bit of assembly programming, but have very limited x86 knowledge.
 * GDB - Good for inspecting the code running in QEMU

## PXE

I had two old laptops to play around with. I thought that if I could set up network boot, it would make testing builds on the actual hardware fairly easy. One laptop didn't support network boot, but the other did have PXE 2.0 built in.

I used [tftpd32](http://tftpd32.jounin.net/tftpd32.html) on a windows machine connected by a USB-Ethernet dongle to the laptop. It configures a DHCP server to give the laptop an address, and a TFTP server to host the image files. For some reason the built in PXE wasn't correctly getting the DHCP leases. Eventually, booted a USB image with [iPXE](https://ipxe.org/download) which was able to boot from my TFTP server.

I was testing with CentOS images. It would start by loading a `vmlinuz` (Linux kernel) and `initrd.img` (root file system). This would then bootstrap a larger image with the live OS.

It wasn't entirely clear how I would need to package any code I built do be able to be loaded through PXE, so I decided to move on to testing with QEMU

## QEMU

Since I had some issues with netboot on my real hardware, I decided to try it with QEMU. This turned out to be especially complicated since I was running QEMU in a Linux VM, and the networking was pretty complicated. I did find this [article](https://www.saminiir.com/debugging-pxe-boot/) on how to do it, but network challenges with the VM, made me give up and move on to testing with a disk image.

The main other functionality I needed to look up, was [starting a debugging session in QEMU](https://en.wikibooks.org/wiki/QEMU/Debugging_with_QEMU).

## Cross Compiling Linux

To try to test the PXE boot with a custom image, I decided to build a full custom Linux image. I figured I could look at how the images were being packaged, and see if I could figure out how to just build a custom boot loader. I looked at [Yocto](https://www.yoctoproject.org/) and [Buildroot](https://buildroot.org/). I went with Buildroot since the internet described it as the simpler option, and I had some familiarity with it.

Here's how I build it:

```bash
git clone https://github.com/buildroot/buildroot.git
cd buildroot 
make qemu_x86_defconfig
sudo apt-get install libncurses-dev
make menuconfig # set desired build output
make
```

It took a few hours to build, but I had an image. I was able to load it into QEMU fairly easily, but I had trouble getting the networking working.

```bash
qemu-system-x86_64 -kernel buildroot/output/images/bzImage \
  -initrd buildroot/output/images/rootfs.cpio \
  -append "console=ttyS0"
```

I decided to give up on PXE for the time being, and move on.

## Asm Programming

Finally I moved on to actually writing some bare metal code. I primarily followed along with the tutorial in <http://3zanders.co.uk/2017/10/13/writing-a-bootloader/>. I had to do a lot of research on the side to actually understand everything in the assembly.

* <https://en.wikipedia.org/wiki/BIOS_interrupt_call>
* <https://riptutorial.com/x86>
* <https://en.wikibooks.org/wiki/X86_Assembly/16,_32,_and_64_Bits#64-bit>
* <https://en.wikipedia.org/wiki/FLAGS_register>
* <https://www.felixcloutier.com/x86/>
* <https://www.nasm.us/doc/>
* <https://wiki.osdev.org/GDT>

There's a lot of "magic" that needs to be performed to enable progressively more of the processors functionality. Things like [enabling the A20 line](http://www.independent-software.com/operating-system-development-enabling-a20-line.html), or setting up the [GDT](https://wiki.osdev.org/GDT) seem like things you just need to know to do.

For the most part, things just worked. The only major change I had to make was to use:

```
nasm -f elf32 boot4.asm -o boot4.o 
boot4: boot4.o kmain.cpp 
	g++ -m32 kmain.cpp boot4.o -o kernel.bin -nostdlib  -fno-pie -ffreestanding -std=c++11 -mno-red-zone -fno-exceptions -nostdlib -fno-rtti -Wall -Wextra -Werror -T linker.ld
```

To build the final example, since I got linker errors.

I tried running these on my laptops by dd'ing the images onto a USB, but couldn't get them to boot. Eventually I switched to a [different tutorial](https://github.com/cirosantilli/x86-bare-metal-examples#bios-hello-world). I was able to actually get a hello world USB to run

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/IMG_20200116_221218_thumb.jpg" alt="laptop hello world">]({{ site.image_host }}/2020/IMG_20200116_221218.jpg)

## Debugging with GDB

To get a better understanding of what I was doing, I would use GDB. Unfortunately, I couldn't figure out how to give it debugging symbols, so I would have to step through instruction by instruction, and set breakpoints by the instruction address. I could match up the instructions with the lines in the binary by decompiling with `objdump -b binary -m i386:x86-64 -D BIN_FILE`.

Some other useful commands:

* layout asm - make a TUI window showing the upcoming assembly instructions
* info registers - get the register states
* disas $pc,+32 - get the next lines of assembly
* x/1s 0x555555554284 - show a string in memory
