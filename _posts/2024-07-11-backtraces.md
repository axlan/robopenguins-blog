---
title: Backtrace
author: jon
layout: post
categories:
  - Software
  - Work
image: 2024/crash_handling/bt_hl_flow.png
---

My battles with trying to generate useful backtraces. Follow up article to [Making Linux C++ Crashes Less Chaotic]({% post_url 2024-07-09-less-crashy-crashes %}).

Backtraces are an extremely handy way to get an idea of "where" a crash occurred. Having experience in many other programming languages (Java, Python, Javascript for starters), I always assumed getting a backtrace isn't super complicated. When it comes to C/C++, boy was I wrong. The best experiences I've had generating backtraces have been from core dumps. See [Using Core Dumps]({% post_url 2024-07-10-core-dumps %}) for more details. Regardless, there's situations where getting a reasonable crash trace as text is really the only option to have some idea of what caused a crash.

There's two pieces to generating a backtrace in C++:
 1. Unwinding the stack and getting the memory offsets of the function calls
 2. Translating the memory addresses to functions names and source files and line numbers. This can potentially be done after the fact to make the error reporting code more robust, or because the application didn't include the debug symbols.

One relevant thing to mention is this snippet from the boost's documentation <https://www.boost.org/doc/libs/master/doc/html/stacktrace/getting_started.html#stacktrace.getting_started.handle_terminates>

> Warning
>
> There's a temptation to write a signal handler that prints the stacktrace on SIGSEGV or abort. Unfortunately, there's no cross platform way to do that without a risk of deadlocking. Not all the platforms provide means for even getting stacktrace in async signal safe way.
> Signal handler is often invoked on a separate stack and trash is returned on attempt to get a trace!
> Generic recommendation is to avoid signal handlers! Use platform specific ways to store and decode core files. 
> See ["Theoretical async signal safety"](https://www.boost.org/doc/libs/master/doc/html/stacktrace/theoretical_async_signal_safety.html) for more info. 

**In writing this article, I found an amazing stackoverflow answer:**
<https://stackoverflow.com/a/54365144>

If I had seen this answer before I started writing this, I probably would have just pointed here and skipped the effort. It is much more extensive then my write up here, so definitely give it a look.

# Options

## C++23 basic_stacktrace

I haven't actually had a chance to develop using the C++23 standard, but I thought it would be worth highlighting that these is a newly added feature: <https://en.cppreference.com/w/cpp/utility/basic_stacktrace> 

For versions of gcc before 14, you need to link with `-lstdc++_libbacktrace` ([as documented here](https://gcc.gnu.org/onlinedocs/gcc-12.3.0/libstdc++/manual/manual/using.html#manual.intro.using.flags)). For newer versions you need `-lstdc++exp` instead ([as documented here](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using.html#manual.intro.using.flags)). gcc needs to have been configured with `--enable-libstdcxx-backtrace` when it was compiled.

I did a quick test with Compiler Explorer:

Test of STD stacktrace with symbols: <https://godbolt.org/z/9WT8Mqzhe>

```
0# nested_func(int) at /app/example.cpp:6
1# func(int) at /app/example.cpp:12
2#      at :0
3# __libc_start_main at :0
4# _start at :0
5# 
```

Test of STD stacktrace without symbols: <https://godbolt.org/z/YYYncjrh9>

```
0#      at :0
1#      at :0
2#      at :0
3# __libc_start_main at :0
4#      at :0
5# 
```

So, in summery, it takes a small amount of setup to work if you're on a newish version of gcc, and it appears to do a reasonable job on a basic example. The thing that is absent though, is that:
1. It doesn't work at all if the debug symbols aren't present
2. It doesn't appear to provide a way to get the memory addresses to allow for generating the backtrace in post processing with a separate symbol file.

# execinfo

This appears to be the most "basic" way of generating backtraces: <https://man7.org/linux/man-pages/man3/backtrace_symbols.3.html>

It doesn't provide source file:line, but displays memory address along with function names if they are available. An example output is:

```
$ cc -rdynamic prog.c -o prog
$ ./prog 3
backtrace() returned 8 addresses
./prog(myfunc3+0x5c) [0x80487f0]
./prog [0x8048871]
./prog(myfunc+0x21) [0x8048894]
./prog(myfunc+0x1a) [0x804888d]
./prog(myfunc+0x1a) [0x804888d]
./prog(main+0x65) [0x80488fb]
/lib/libc.so.6(__libc_start_main+0xdc) [0xb7e38f9c]
./prog [0x8048711]
```

Breaking down one of these lines: `/lib/libc.so.6(__libc_start_main+0xdc) [0xb7e38f9c]`
 * `./prog` - The binary or library the code originated from.
 * `(myfunc+0x1a)` - If the binary was built with `-rdynamic`, this will give the function and the memory offset into the function for trace point. Otherwise this give the offset from the start of the binary.
 * `[0x804888d]` - The location in virtual memory of that trace point

This pretty much will always "work" to some extent with two big caveats.
1. You won't get the function name unless you include the `-rdynamic` gcc build flag.
2. There's a feature called [Address space layout randomization](https://en.wikipedia.org/wiki/Address_space_layout_randomization), that can make the virtual memory locations useless for resolving to source code locations. This feature can be avoided by compiling with the `-no-pie` flag, or by also logging process base address in `/proc/self/maps` and subtracting it from the reported addresses.

This means that we basically have 4 cases we might need to handle to translate this output to source code locations. With and without the dynamic symbols (`-rdynamic`) and with and without address randomization (`-no-pie`).

The basic tool for translating the backtrace output are `gdb` and `addr2line`. You need access to the debug symbols to use these tools. This can be the original binary, or a separate binary that saved the symbols, if they weren't included, or stripped off in realtime (See [Using Core Dumps]({% post_url 2024-07-10-core-dumps %}) for more details on including debug symbols). If I'm doing this regularly I usually write a script to automate the processing. Both of these tools also allow multiple addresses to be passed in at the same time which speeds up the conversion.

## addr2line

[addr2line](https://linux.die.net/man/1/addr2line) is a fairly simply tool that just goes from memory locations in a binary to the source file. You can get this address from the last field (in the square brackets) if address randomization is turned off, or the value in the parentheses if dynamic symbols are turned off. See the man page for an explanation of the flags I'm using.

Example code from <https://github.com/axlan/crash_tutorial/blob/master/src/example2/handle_signal.cpp>

For example with dynamic symbols and no address randomization:
```
> build/example2   
...
build/example2(main+0xb3)[0x402697]
...

> addr2line -f -C -i -e build/example2 0x402697
main
/src/crash_tutorial/src/example2/handle_signal.cpp:61
```

For example with no dynamic symbols and address randomization:
```
> build/example2   
...
./example2-strip(+0x26ab)[0x5f930f25f6ab]
...

> addr2line -f -C -i -e build/example2 +0x26ab
main
/src/crash_tutorial/src/example2/handle_signal.cpp:61
```

The only case that `addr2line` doesn't work with is if address randomization is on, and dynamic symbols are present: `./example2(main+0xb3)[0x5ce6d09226ab]`

## gdb

The GDB debugger can translate memory addresses to file and lines as well. with the `info line` command. The main advantage is that it can take either be given the same memory addresses as `addr2line`, or it can alternatively take the function names plus an offset as well:

```
> gdb -nh -batch -ex 'info line *(main+0xb3)' build/example2 
Line 61 of "/src/crash_tutorial/src/example2/handle_signal.cpp" starts at address 0x26ab <main()+179> and ends at 0x26b3 <main()+187>.

> gdb -nh -batch -ex 'info line *(0x26ab)' build/example2
Line 61 of "/src/crash_tutorial/src/example2/handle_signal.cpp" starts at address 0x26ab <main()+179> and ends at 0x26b3 <main()+187>.
```

# Boost
<https://www.boost.org/doc/libs/master/doc/html/stacktrace/>

Boost provides an abstraction layer around the concept of stack traces, and gives you some options to customize what's mechanism is being used under the hood <https://www.boost.org/doc/libs/master/doc/html/stacktrace/configuration_and_build.html>.

Like most boost libraries it's fairly complicated, but at least has reasonable detailed documentation. If you're already using boost, or you need to support a wide variety of build configurations, it's worth checking out.
