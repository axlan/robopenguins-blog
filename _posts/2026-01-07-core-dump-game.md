---
title: Fatal Core Dump Game
author: jon
layout: post
categories:
  - Software
  - "Game Dev"
image: 2026/fatal_core_dump/fatal_core_dump.png
---

I decided to make a somewhat educational murder mystery game, with debugging a core dump as the main piece of evidence.

---
**!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!**<br>
**THIS ARTICLE HAS SPOILERS! IF YOU'RE INTERESTED, PLAY THE GAME HERE FIRST:**<br>
**<https://www.robopenguins.com/fatal_core_dump/>**

---

All the code for this game can be found at: <https://github.com/axlan/fatal_core_dump>

Over the years, I've seen a couple of murder mysteries used to teach the basics of different software skills:
 - [CLI Murder Mystery]({% post_url 2023-07-26-cli-murder %})
 - [SQL Murder Mystery]({% post_url 2019-12-29-sql-murder-mystery %})
 - I never wrote it up, but <https://deadlockempire.github.io/> is another fun entry in this genre

As a thought experiment, I tried to come up with the most esoteric computer skill I could package into a murder mystery. I came up with debugging a core dump.

# Brainstorming

I've talked about core dumps before: [Making Core Dumps Useful]({% post_url 2024-07-10-core-dumps %}). I found the idea that an entire mystery's worth of twists and turns could be captured in a program's dying breath to be compelling.

Initially, I wasn't sure what kind of clues could be hidden. If the killer's name was just sitting in an access log, that wouldn't be particularly interesting. I knew I would need some sort of framing around the game so I could split information between the core dump itself and other sources.

One of my first thoughts was that as you found answers to certain questions, you might gain access to additional source code or databases to query.

My main inspiration was the way the mysteries worked in the games [Return of the Obra Dinn](https://obradinn.com/) and [The Case of the Golden Idol](https://www.thegoldenidol.com/). Both have you exploring frozen scenes and uncovering clues that reframe the evidence you've already collected.

Pretty early on, I settled on an airlock door controller as the program at the center of the mystery. It had a reasonable amount of complexity while also having obvious potential for murder.

From there, I decided to use a sci-fi setting. The idea of a "company town" in space, using third party arbitration, jumped to mind. This helped provide motivations and justified limiting the player's access to information.

# Writing the Airlock Controller

Once I had the basic idea, I decided to actually write a simple airlock controller. I wanted to keep things as minimal as possible, so I wrote a C library with minimal dependencies. This may seem backwards, since I hadn't decided on all the details of the mystery yet, but I felt it would be easier to make something feel realistic if the software wasn't designed primarily as a puzzle.

One challenge I realized right away was that I needed a way to set up the program state so it would look exactly the way I wanted when it generated the core dump.

Initially, I considered having the process communicate with various sensors and servers. After some thought, though, I realized it would be simpler to send all external interactions through a library whose internals I could hide. Any dynamically linked libraries would be unavailable to the debugger unless I explicitly included them.

In this project, the libraries used to generate fake interfaces that I didn't want the player to see live in <https://github.com/axlan/fatal_core_dump/tree/v0.1.2/lib>, while the only source code I intended players to examine is <https://github.com/axlan/fatal_core_dump/blob/v0.1.2/src/airlock_ctrl.c>.

I think I went a bit overboard with the communication interface. I ended up writing an entire binary protocol for an imaginary "Station Device Network" (SDN) used for inter-device communication. In retrospect, I probably should have planned this better. It made some things needlessly complicated since I didn't yet know the extent of what I'd want it to do.

That said, this approach let me write the main controller as a loop waiting for messages on the SDN interface. I could then write the SDN library to generate the precise sequence of messages needed to set up the murder. While I considered reading these sequences from a text file, I ultimately cut out the middleman and hard coded them directly in C. See: <https://github.com/axlan/fatal_core_dump/blob/v0.1.2/lib/sdn_interface.c#L523>

This let me create test scenarios to validate "normal" behavior, as well as capture the exact state I wanted in the core dump.

# Figuring Out the Mystery

At some point while writing the controller, I decided I wanted the murder to be committed by abusing a buffer overflow to trigger the airlock.

I wanted a balance between negligence on the part of the software designer and the cleverness of the murderer.

This sent me down a series of twists and turns to make the attack plausible while still being solvable via a core dump.

The first challenge was making the buffer overflow less obvious. I solved this in two ways:
 1. Obfuscating the buffer size check
 2. Having the attack "hide" in memory until a separate trigger was reached

To obscure the bounds check failure, I made the buffer size a configuration parameter used at startup to allocate the buffer. I then added a debug command that could modify the configuration variable without resizing the buffer. I gated this behind multiple debug options to justify why it wouldn't be enabled in production.

From there, I wrote a series of small test programs to prototype the exploit: <https://github.com/axlan/fatal_core_dump/tree/v0.1.2/minimal_example>

To keep the exploit dormant until later, I initially explored self-modifying code (see <https://ephemeral.cx/2013/12/writing-a-self-mutating-x86_64-c-program/> for a basic example). This approach had several drawbacks. First, it would cause the binary seen in the debugger to differ from the runtime version. While the core dump could technically capture this, I wanted to keep things as realistic as possible. Second, it would require making program memory writable via a system call (see <https://github.com/axlan/fatal_core_dump/blob/v0.1.2/minimal_example/vuln_test3.py>). At that point, I realized there was a more fundamental problem.

My initial idea involved return-oriented programming (ROP): <https://tc.gts3.org/cs6265/tut/tut06-01-rop.html>. This relies on overwriting a return address on the stack, which only works if the stack is executable and other defenses are disabled. However, this is totally a non-starter for overflows on the heap. I couldn't easily justify a stack overflow in an otherwise competently written program.

However, I realized that if a heap overflow corrupted a callback pointer stored on the heap and pointed it to attack code stored on the stack, I could get the effect I wanted. If the stack memory persisted across messages, I wouldn't need to write into program memory at all. After some experimentation, I arrived at <https://github.com/axlan/fatal_core_dump/blob/v0.1.2/minimal_example/min_poc.c> paired with <https://github.com/axlan/fatal_core_dump/blob/v0.1.2/minimal_example/vuln_test5.py>.

In the end, the attack looked like this:

```nasm
    ; This is needed to align the stack to a 16 byte offset.
    ; I don't update the rbp since it interferes with the core dump's backtrace.
    push    rbp
    movabs  r15, ADDRESS_OF_HANDLE_MESSAGE_CALLBACK
    mov     r12, rdi
    add     r12, OFFSET_TO_USER_ID_VALUE
    ; Check if the message was sent by the murder target
    ; If it's not from the target skip to ".L_skip"
    cmp     DWORD PTR [r12], USER_ID_OF_TARGET_FOR_MURDER
    jne     .L_skip
    ; Save the parameters passed to this function
    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx
    ; Call the ControlDoor function to open the outside door
    movabs  rax, ADDRESS_OF_DOOR_OPEN_FUNCTION
    mov     edi, DEVICE_ID_FOR_AIRLOCK_CONTROLLER
    mov     esi, DEVICE_ID_FOR_OUTSIDE_DOOR
    mov     edx, 1
    call    rax
    ; Restore the original callback to erase this hack
    mov     rax, THE_HEAP_ADDRESS_FOR_CALLBACK_POINTER
    mov     qword ptr [rax], r15
    ; Restore the parameters to call the message handler normally
    mov     rdi, r12
    mov     rsi, r13
    mov     rdx, r14
.L_skip:
    call    r15
    pop     rbp
    ret
```

While it would have been ideal to make this work under fully realistic OS protections, I chose simplicity. I built the binary with extra compiler flags `-fcf-protection=none -z execstack` to make the stack executable and turn off some protections. Second, when I ran the executable I would do so like: `env -i setarch $(uname -m) -R $PWD/bin/min_poc` .
 - `env -i` cleared the environment variables so the memory offsets weren't affected by them
 - `setarch $(uname -m) -R` turned off the [address space layout randomization](https://en.wikipedia.org/wiki/Address_space_layout_randomization) so memory would be laid out consistently
 - Calling the executable with the absolute path also helped keep the memory offsets consistent between calling from the shell, and calling in GDB.

On the GDB side I just needed to call `set exec-wrapper env -i` to clear the environment variables. I would use GDB to find the memory offsets I'd be using in the hack, and hard code them.

Once the mechanics were settled, I refactored the airlock controller to support this scenario. This required a few unrealistic memory layout decisions, but nothing too too crazy.

The final piece was justifying the crash that produced the core dump. I decided the murderer would trick another person into loading malicious data into their spacesuit. If the data payload was unusually large, it wouldn't be overwritten by subsequent users. I justified copying this data to the stack by having the airlock forward this data to the suit. Because the stack buffer didn't go out of scope, it was suitable for storing the attack.

To create an in-fiction reason for the crash, the patsy unexpectedly modifies the data, overwriting the code with actual settings data. I spent far more time than was justified making this feel plausible.

I wrote a final script to generate the attack payload: <https://github.com/axlan/fatal_core_dump/blob/v0.1.2/scripts/generate_shellcode.py> . The exploit is appended to a settings string and partially corrupted by the overridden field.

Here you can see the intact payload and the version overridden by a "bass volume" setting:

[<img class="center" src="{{ site.image_host }}/2026/fatal_core_dump/user_settings_thumb.webp">]({{ site.image_host }}/2026/fatal_core_dump/user_settings.png)


# Making an RPG Maker Simulation

I originally wanted the game to be more interactive, with dialogue trees and a graphical interface. While a website was the most accessible way to present the puzzle, I still wanted a small visual component. I ended up creating a simple pixel-art demo to illustrate the airlock and sequence of events of the murder.

You can play this "game" at <https://www.robopenguins.com/fatal_core_dump/rpg_maker/index.html> and the source code is available at <https://github.com/axlan/fatal_core_dump/tree/v0.1.2/rpg_maker_project>.


I had a free copy of RPG Maker and thought it would be a good tool too make this. It was, but it has a strange learning curve. It's trivial to make a basic RPG with the built-in assets, but trying to program complicated events or making your own assets introduces a lot of gotchas. Overall, it was probably slightly easier than using a general-purpose engine. I used a single plugin <https://someran.dev/rpgmaker/plugins/mz/SRD_HUDMakerUltra.js/> to display console logs.

Most of the logic lives in the event system, which took some time to understand. Events are tied to map tiles, and behavior is controlled via event pages with AND-ed conditions. The highest-numbered matching page wins. It was oddly reminiscent of a Zachtronics game.

I spent the bulk of my time here on pixel editing. I started from <https://pvgames.itch.io/pvgames-sci-fi> tile assets, but had trouble finding "compatible" pixel art. I ended up making a whole sprite sheet for a [space suit](https://feros32.itch.io/space-suit-sprite-sheet) using [aseprite](https://www.aseprite.org/) along with a bunch of other small tweaks.

[<img class="center" src="{{ site.image_host }}/2026/fatal_core_dump/rpg_pic_thumb.webp">]({{ site.image_host }}/2026/fatal_core_dump/rpg_pic.png)

# Debugging Without GDB on Your PC

One stretch goal was allowing the puzzle to be solved entirely in the browser. That required running GDB on the core dump in a web environment.

I found <https://github.com/leaningtech/webvm> which let's you emulate a full virtual machine in the browser. I forked it and modified a Dockerfile to include the core dump and install GDB: <https://github.com/axlan/webvm/blob/fatal_core_dump/dockerfiles/debian_mini>.

You can try it out here <https://axlan.github.io/webvm/>.

# Putting It All Together

With the main artifacts done, I had to put it together into a playable puzzle.

I initially tried to put the information together diegetically. I presented the information through things like emails or data sheets. Eventually, I ran out of steam and most of the evidence is simply presented as downloadable files.

To be able to consistently generate the logs and core dump, I ended up wrapping the build and runtime scripts in docker containers. That way I could just run the <https://github.com/axlan/fatal_core_dump/tree/v0.1.2/scripts/docker_generate_site.sh> to generate all the programmatic clues for the project. I considered using a GitHub action, but stuck with just running the scripts locally.

I ended up writing a lot of filler to act as red herrings. I'm not sure I made enough though, since pretty much all the logs are relevant to the murder. It was hard to balance forcing the player to sift through a bunch of pointless filler and effectively hiding the evidence.

One especially tricky page to design was the one used to validate whether the player had solved the puzzle. I wanted a series of questions that would demonstrate the player's understanding of the technical mechanisms behind the murder. I implemented this as a set of fill-in-the-blank questions, populated via an autocomplete dictionary. My concern is that this approach may require players to phrase their answers in their minds too similarly to my own in order to fill in the blanks correctly. I'm hoping to get feedback on whether these questions are easy to complete once the puzzle has been solved.

I'm not a frontend guy, so that's probably the weakest part of this project. With more time I could probably improve the presentation of the clues and the solutions entry. If I manage to get sufficient interest in this, maybe I'll go back and try to polish things up.
