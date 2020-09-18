---
title: Experimenting with GCC Linker
author: jon
layout: post
categories:
  - Software
image: 2020/cmodel.gif
---

I spent a little bit of time trying to expand my understanding of the GCC linker. I was a bit surprised the hoops I needed to jump through, but I think I have enough context to basically understand what's going on.

I continue to be interested in the mysteries of what's going on under the hood when you compile and run a program. One area I've found particularly murky, is the linker. The idea is simple enough, a stage that takes blocks of mostly compiled code and links them together to create the final output binary. However, figuring out exactly what's going on tends to get obscured by the complexity of modern operating systems and build tools.

Here's a some code I wrote to explore linking:

`hellolink.c`
```c
#include <string.h>

// Values not defined in this compilation unit (.c file)
extern void myPrintHelloLink(void);
extern char my_section_addr[];

int main() {
  // Call a function in another file
  myPrintHelloLink();
  // Overwrite the external memory values
  strcpy(my_section_addr, "dog");
  myPrintHelloLink();

  return(0);
}
```

`hellofunc.c`
```c
#include <stdio.h>
#include <string.h>

// Values not defined in this compilation unit (.c file)
extern char my_section_addr[];

// Constant string data
const char* HELLO_FUNC_ARRAY1 = "Hello";
// Initialized memory region
char HELLO_FUNC_ARRAY2[] = {[0 ... 1023] = '?'};
// Uninitialized memory region
char HELLO_FUNC_ARRAY3[1024];

void myPrintHelloLink(void) {
  // Stack memory
  char HELLO_FUNC_ARRAY4[sizeof(HELLO_FUNC_ARRAY1) + 
    sizeof(HELLO_FUNC_ARRAY2) + sizeof(HELLO_FUNC_ARRAY3)];

  // Some pointer craziness to make the function do something with all these
  // arrays
  int i;
  for (i = 0; i < sizeof(HELLO_FUNC_ARRAY2) - 1; i++) {
    if (HELLO_FUNC_ARRAY2[i] == '?') {
      HELLO_FUNC_ARRAY2[i] = '!';
      break;
    }
  }
  memcpy(HELLO_FUNC_ARRAY3, HELLO_FUNC_ARRAY2, i + 1);
  HELLO_FUNC_ARRAY3[i + 1] = '\0';
  sprintf(HELLO_FUNC_ARRAY4, "%s%s", HELLO_FUNC_ARRAY1, HELLO_FUNC_ARRAY3);
  printf("%s %s\n", HELLO_FUNC_ARRAY4, my_section_addr);

  // Print pointer addresses
  printf("HELLO_FUNC_ARRAY1: %p\n", HELLO_FUNC_ARRAY1);
  printf("HELLO_FUNC_ARRAY2: %p\n", HELLO_FUNC_ARRAY2);
  printf("HELLO_FUNC_ARRAY3: %p\n", HELLO_FUNC_ARRAY3);
  printf("HELLO_FUNC_ARRAY4: %p\n", HELLO_FUNC_ARRAY4);
  printf(".my_section: %p\n", my_section_addr);

  return;
}
```

In the above code I'm using the `extern` keyword to indicate that those variables will be resolved at link time. `hellolink.c` depends on a function in `hellofunc.c` and `hellofunc.c` references a value thats defined in the linker script below.

`hellolink.ld`
```
SECTIONS
{
  . = 0x8000000;
  .my_section : { my_section_addr = .; BYTE(0x63); BYTE(0x61); BYTE(0x74); BYTE(0x00); }
}
```

Basically, this script says to create a section at memory offset 0x8000000 and store the null terminated string "cat".

The simplest way to compile this is to just use gcc:

```bash
gcc -o hellolink *.c -Wl,hellolink.ld
```
It outputs `/usr/bin/ld: warning: hellolink.ld contains output sections; did you forget -T?` to warn me that my script hellolink.ld is being appended to the default linker script instead of replacing it. As far as I could tell, there's no way to avoid that warning.

I spent a good chunk of time trying to run the linker command explicitly. I ended up with:

```bash
gcc -O0 -c -o hellolink.o hellolink.c
gcc -O0 -c -o hellofunc.o hellofunc.c
ld -o hellolink -dynamic-linker /lib64/ld-linux-x86-64.so.2 \
                /usr/lib/x86_64-linux-gnu/crt1.o \
                /usr/lib/x86_64-linux-gnu/crti.o \
                -lc hellolink.ld hellofunc.o hellolink.o \
                /usr/lib/x86_64-linux-gnu/crtn.o
```

My understanding is that this is linking in binaries that handle the complexities of initializing on the OS and being able to make system calls. If you leave out the `-lc` the standard library isn't linked in, so all the `<stdio.h>` functions are undefined. Without the `crt1.o` there's no entry point, and without `crti.o` and `crtn.o` the program will segfault. See [this stackoverflow](https://stackoverflow.com/questions/3577922/how-to-link-a-gas-assembly-program-that-uses-the-c-standard-library-with-ld-with). This worked on Ubuntu 20.04.1 though I imagine it might be different on other systems.

Next I wanted to provide the entire linker script. You're able to see the default script if you pass `--verbose` to the linker command. I then went through and stripped out some extra sections (mostly that supported debugging) and added my section to the end.

```
OUTPUT_FORMAT("elf64-x86-64", "elf64-x86-64",
              "elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)
SEARCH_DIR("=/usr/local/lib/x86_64-linux-gnu"); SEARCH_DIR("=/lib/x86_64-linux-gnu"); SEARCH_DIR("=/usr/lib/x86_64-linux-gnu"); SEARCH_DIR("=/usr/lib/x86_64-linux-gnu64"); SEARCH_DIR("=/usr/local/lib64"); SEARCH_DIR("=/lib64"); SEARCH_DIR("=/usr/lib64"); SEARCH_DIR("=/usr/local/lib"); SEARCH_DIR("=/lib"); SEARCH_DIR("=/usr/lib"); SEARCH_DIR("=/usr/x86_64-linux-gnu/lib64"); SEARCH_DIR("=/usr/x86_64-linux-gnu/lib");
SECTIONS
{
  PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x400000)); . = SEGMENT_START("text-segment", 0x400000) + SIZEOF_HEADERS;
  .interp         : { *(.interp) }
  .note.gnu.build-id  : { *(.note.gnu.build-id) }
  .hash           : { *(.hash) }
  .gnu.hash       : { *(.gnu.hash) }
  .dynsym         : { *(.dynsym) }
  .dynstr         : { *(.dynstr) }
  .gnu.version    : { *(.gnu.version) }
  .gnu.version_d  : { *(.gnu.version_d) }
  .gnu.version_r  : { *(.gnu.version_r) }
  .rela.dyn       :
    {
      *(.rela.init)
      *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
      *(.rela.fini)
      *(.rela.rodata .rela.rodata.* .rela.gnu.linkonce.r.*)
      *(.rela.data .rela.data.* .rela.gnu.linkonce.d.*)
      *(.rela.tdata .rela.tdata.* .rela.gnu.linkonce.td.*)
      *(.rela.tbss .rela.tbss.* .rela.gnu.linkonce.tb.*)
      *(.rela.ctors)
      *(.rela.dtors)
      *(.rela.got)
      *(.rela.bss .rela.bss.* .rela.gnu.linkonce.b.*)
      *(.rela.ldata .rela.ldata.* .rela.gnu.linkonce.l.*)
      *(.rela.lbss .rela.lbss.* .rela.gnu.linkonce.lb.*)
      *(.rela.lrodata .rela.lrodata.* .rela.gnu.linkonce.lr.*)
      *(.rela.ifunc)
    }
  .rela.plt       :
    {
      *(.rela.plt)
      PROVIDE_HIDDEN (__rela_iplt_start = .);
      *(.rela.iplt)
      PROVIDE_HIDDEN (__rela_iplt_end = .);
    }
  . = ALIGN(CONSTANT (MAXPAGESIZE));
  .init           :
  {
    KEEP (*(SORT_NONE(.init)))
  }
  .plt            : { *(.plt) *(.iplt) }
.plt.got        : { *(.plt.got) }
.plt.sec        : { *(.plt.sec) }
  .text           :
  {
    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(SORT(.text.sorted.*))
    *(.text .stub .text.* .gnu.linkonce.t.*)
    /* .gnu.warning sections are handled specially by elf.em.  */
    *(.gnu.warning)
  }
  .fini           :
  {
    KEEP (*(SORT_NONE(.fini)))
  }
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  . = ALIGN(CONSTANT (MAXPAGESIZE));
  /* Adjust the address for the rodata segment.  We want to adjust up to
     the same address within the page on the next page up.  */
  . = SEGMENT_START("rodata-segment", ALIGN(CONSTANT (MAXPAGESIZE)) + (. & (CONSTANT (MAXPAGESIZE) - 1)));
  .rodata         : { *(.rodata .rodata.* .gnu.linkonce.r.*) }
  .rodata1        : { *(.rodata1) }
  .eh_frame_hdr   : { *(.eh_frame_hdr) *(.eh_frame_entry .eh_frame_entry.*) }
  .eh_frame       : ONLY_IF_RO { KEEP (*(.eh_frame)) *(.eh_frame.*) }
  .gcc_except_table   : ONLY_IF_RO { *(.gcc_except_table .gcc_except_table.*) }
  .gnu_extab   : ONLY_IF_RO { *(.gnu_extab*) }
  /* These sections are generated by the Sun/Oracle C++ compiler.  */
  .exception_ranges   : ONLY_IF_RO { *(.exception_ranges*) }
  /* Adjust the address for the data segment.  We want to adjust up to
     the same address within the page on the next page up.  */
  . = DATA_SEGMENT_ALIGN (CONSTANT (MAXPAGESIZE), CONSTANT (COMMONPAGESIZE));
  /* Exception handling  */
  .eh_frame       : ONLY_IF_RW { KEEP (*(.eh_frame)) *(.eh_frame.*) }
  .gnu_extab      : ONLY_IF_RW { *(.gnu_extab) }
  .gcc_except_table   : ONLY_IF_RW { *(.gcc_except_table .gcc_except_table.*) }
  .exception_ranges   : ONLY_IF_RW { *(.exception_ranges*) }
  /* Thread Local Storage sections  */
  .tdata          :
   {
     PROVIDE_HIDDEN (__tdata_start = .);
     *(.tdata .tdata.* .gnu.linkonce.td.*)
   }
  .tbss           : { *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon) }
  .preinit_array    :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  }
  .init_array    :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
  }
  .fini_array    :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  }
  .jcr            : { KEEP (*(.jcr)) }
  .data.rel.ro : { *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*) }
  .dynamic        : { *(.dynamic) }
  .got            : { *(.got) *(.igot) }
  . = DATA_SEGMENT_RELRO_END (SIZEOF (.got.plt) >= 24 ? 24 : 0, .);
  .got.plt        : { *(.got.plt) *(.igot.plt) }
  .data           :
  {
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  }
  .data1          : { *(.data1) }
  _edata = .; PROVIDE (edata = .);
  . = .;
  __bss_start = .;
  .bss            :
  {
   *(.dynbss)
   *(.bss .bss.* .gnu.linkonce.b.*)
   *(COMMON)
   /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.
      FIXME: Why do we need it? When there is no .bss section, we do not
      pad the .data section.  */
   . = ALIGN(. != 0 ? 64 / 8 : 1);
  }
  .lbss   :
  {
    *(.dynlbss)
    *(.lbss .lbss.* .gnu.linkonce.lb.*)
    *(LARGE_COMMON)
  }
  . = ALIGN(64 / 8);
  . = SEGMENT_START("ldata-segment", .);
  .lrodata   ALIGN(CONSTANT (MAXPAGESIZE)) + (. & (CONSTANT (MAXPAGESIZE) - 1)) :
  {
    *(.lrodata .lrodata.* .gnu.linkonce.lr.*)
  }
  .ldata   ALIGN(CONSTANT (MAXPAGESIZE)) + (. & (CONSTANT (MAXPAGESIZE) - 1)) :
  {
    *(.ldata .ldata.* .gnu.linkonce.l.*)
    . = ALIGN(. != 0 ? 64 / 8 : 1);
  }
  . = ALIGN(64 / 8);
  _end = .; PROVIDE (end = .);
  . = DATA_SEGMENT_END (.);
  . = 0x8000000;
  .my_section : { my_section_addr = .; BYTE(0x63); BYTE(0x61); BYTE(0x74); BYTE(0x00); }
}
```

I was able to compile with this and the previous commands if I added a -T in front of the script file to have it replace instead of append the default script. As far as I could tell, the only difference from the various ways I called the linker was that when I just used GCC the addresses in the elf didn't have an offset of 0x400000.

We can look at how this binary is organized with `readelf` or `objdump`. `objdump -s hellolink` shows the contents of the sections so you can see the `?` that fill HELLO_FUNC_ARRAY2 starting at address 0x404060 in the .data section. 

Looking in the output of `readelf -W -t hellolink` and `objdump -s hellolink`

| section     | address   | size  | description               |
|-------------|-----------|-------|---------------------------|
| .text       | 0x4010b0  | 601   | Machine code to run       |
| .rodata     | 0x402000  | 131   | Read only strings         |
| .data       | 0x404040  | 1064  | Initialized memory        |
| .bss        | 0x404480  | 1024  | Uninitialized memory      |
| .my_section | 0x8000000 | 4     | My custom section         |
{:.mbtablestyle}

One interesting thing I noticed is that the string "dog" gets stored in .text instead of .rodata. I'm guess this happens since it's 4 bytes including the null character and can fit as a hard coded parameter into a machine instruction and the pointer is never manipulated. I'm also not sure why the .data section is 1064 bytes instead of 1024. It might be that something needed to launch or exit the process is using those extra 40 bytes, or that they're some sort of padding.

Running the binary outputs:

```
Hello! cat
HELLO_FUNC_ARRAY1: 0x402004
HELLO_FUNC_ARRAY2: 0x404480
HELLO_FUNC_ARRAY3: 0x404060
HELLO_FUNC_ARRAY4: 0x7ffda18e21b0
.my_section: 0x8000000
Hello! dog
HELLO_FUNC_ARRAY1: 0x402004
HELLO_FUNC_ARRAY2: 0x404480
HELLO_FUNC_ARRAY3: 0x404060
HELLO_FUNC_ARRAY4: 0x7ffda18e21b0
.my_section: 0x8000000
```

This shows all the pointers in their expected locations:

| pointer             | section     |
|---------------------|-------------|
| HELLO_FUNC_ARRAY1   | .rodata     |
| HELLO_FUNC_ARRAY2   | .bss        |
| HELLO_FUNC_ARRAY3   | .data       |
| HELLO_FUNC_ARRAY4   | stack       |
| my_section          | .my_section |
{:.mbtablestyle}

The basics of what the linker does isn't that hard to understand, but even after looking at a lot of low level code, there's still a lot of complexity here that I'm just glossing over. I'm sure this would be a lot more straight forward on an embedded bare metal system without the additional complexity of running on an OS.
