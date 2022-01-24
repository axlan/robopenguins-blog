---
title: Understanding C Struct Binary Representation
author: jon
layout: post
categories:
  - Software
image: 2022/c_struct.webp
---

While C structures seem very straightforward, there are some surprising behaviors if you need to get consistent binary representations across different processors and compilers.

While I'm focussing on this from the perspective of handling structures in C, this goes for any language where the raw memory representation of data is important. Be this the Python struct library, or binary data sent over a network interface. Also, pretty much everything I discuss here is the same for POD structs in C++.

I'm also only going to be discussing packing and alignment behaviors rather then how the data primitives are encoded. While floats and integers might not always be represented the same way on certain systems, `IEEE 754` floating point and little endian is typically a safe assumption for many processors. If you're writing code that doesn't assume the structure of primitives, you'll either need to avoid doing computations or convert the data for each computation. 

# Background

One of the perceived benefits of the C language is that the code more closely represents what actually gets executed in the processor. However, there are many areas where the compiler will deviate from the naive implementation that one might expect. One of these areas is in how the memory is laid out when defining structures.

This video [Structure Padding in C](https://www.youtube.com/watch?v=aROgtACPjjg) and this blog post [Structures and Padding in C](https://www.edureka.co/blog/understanding-structures-and-padding-in-c/) do a decent job of explaining the basics.

Somewhat deeper dives are done in this stack overflow [C struct size alignment](https://stackoverflow.com/questions/11130109/c-struct-size-alignment) and this article <http://www.catb.org/esr/structure-packing/>.

Even looking at all these articles, they often are simplifying or conflating the different reasons that come together to determine how a struct gets represented. Here are the attributes I'm aware of that can effect this:
 * The compiler
   * Packing behavior
   * Alignment behavior
   * Definition for the primitive types (e.g. the size of `int`) 
 * The processor instruction set
   * 32 vs 64 bit
   * ARM vs Intel vs other

Basically, there are many reasons that a difference in the compiler, or a difference in the processor the program is being generated for might result in the incompatibilities in the binary representation.

This also isn't getting into vector instruction sets like SIMD or AVX which have their own additional layers of complexity.

# Why Would One Care?

For most programs this complexity can be totally ignored. As long as you reference structures in a type safe way and the program is self contained, the compiler will treat the structs consistently regardless of how they're actually stored in memory.

There are two main reasons why this may become relevant:
 1. You are trying to optimize your program.
 2. The data is going to be shared between different applications and they need to agree on the binary representation.

Most of my professional career has had me dealing with embedded systems. Here both of these factors are often relevant. Processors are slow and memory constrained requiring optimization. In addition you're often communicating between different devices with vastly different architectures.

# Nuance When Setting Packing and Alignment

It was only fairly recently that I learned how these attributes interact in C. The basic idea is that by default structures will be represented in a way that is efficient to process. This means inserting padding so that each member of a struct is aligned based on that members alignment. For instance:

```c
// This struct is will be 8 byte aligned when declared on the stack to match the largest alignment of its members
struct Foo {
  uint8_t a;
  // Implicitly adds 3 bytes of padding so that the offset of b is a multiple of 4
  uint32_t b;
  uint8_t c;
  // Implicitly adds 7 bytes of padding so that the offset of d is a multiple of 8
  uint64_t d;
  uint8_t e;
  // Implicitly add 7 bytes of padding so the struct size is a multiple of its alignment
} foo;
// The size of foo is 32 bytes
```

This of course is assuming the alignment for `uint8_t`=1, `uint32_t`=4, and `uint64_t`=8. This is true on my x64 GCC, but isn't necessarily true for other compilers. The C11 standard introduced the [alignof(type-name)](http://ld2014.scusa.lsu.edu/cppreference/en/c/align/alignof.html) function to programmatically query the alignment of a type. Also, note that I'm using types that have fixed cross platform sizes (i.e. not `int`). If the actual size of the underlying types change, none of this futzing about with padding will actually make the structs consistent.

In GCC you can use attributes to modify the packing and alignment of a struct explicitly (See <https://gcc.gnu.org/onlinedocs/gcc-3.3/gcc/Type-Attributes.html>). MSVC has similar settings with [__declspec](https://docs.microsoft.com/en-us/cpp/cpp/declspec?view=msvc-170) and packing can also be controlled on most compilers with [#pragma pack](https://docs.microsoft.com/en-us/cpp/preprocessor/pack?view=msvc-170).

## Alignment

First you can set the minimum alignment. Note, that since this is a minimum, this attribute has no effect unless it's larger then the alignment the structure was going to have anyway.

```c
// This struct is will be 16 byte aligned when declared on the stack to match its attribute
struct Foo2 {
  uint8_t a;
  // Implicitly adds 3 bytes of padding so that the offset of b is a multiple of 4
  uint32_t b;
  uint8_t c;
  // Implicitly adds 7 bytes of padding so that the offset of d is a multiple of 8
  uint64_t d;
  uint8_t e;
  // Implicitly add 7 bytes of padding so the struct size is a multiple of its alignment
} __attribute__ ((aligned (16))) foo2;
// The size of foo2 is 32 bytes

// This struct is will be 64 byte aligned when declared on the stack to match its attribute
struct Foo3 {
  uint8_t a;
  // Implicitly adds 3 bytes of padding so that the offset of b is a multiple of 4
  uint32_t b;
  uint8_t c;
  // Implicitly adds 7 bytes of padding so that the offset of d is a multiple of 8
  uint64_t d;
  uint8_t e;
  // Implicitly add 39 bytes of padding so the struct size is a multiple of its alignment
} __attribute__ ((aligned (64))) foo2;
// The size of foo3 is 64 bytes
```

The layout and size of `Foo` and `Foo2` are exactly the same, so what's the difference? The difference is that the compiler will add padding where appropriate to put instances of `Foo2` on 16 byte offsets when needed. For instance:

```c
// This struct is will be 8 byte aligned when declared on the stack to match the largest alignment of its members
struct Bar {
  uint8_t a;
  // Implicitly adds 7 bytes of padding so that the offset of foo is a multiple of 8
  struct Foo foo;
} bar;
// The size of bar is 40 bytes

// This struct is will be 16 byte aligned when declared on the stack to match the largest alignment of its members
struct Bar2 {
  uint8_t a;
  // Implicitly adds 15 bytes of padding so that the offset of foo2 is a multiple of 16
  struct Foo2 foo2;
} bar2;
// The size of bar2 is 48 bytes
```

In addition to specifying alignment at the struct declaration, C11 introduced `alignas(size)` to specify the alignment for a specific variable:

```c
alignas(32) char alignedMemory[DATA_LEN];
assert(((size_t)alignedMemory) % 32 == 0);
```

Before this you needed to use special `malloc` commands or do something like:

```c
char unalignedMemory[DATA_LEN + ALIGNMENT];
size_t offset = ALIGNMENT - (((size_t)unalignedMemory) % ALIGNMENT);
char* alignedMemory = unalignedMemory + offset;
```

## Packed

The packed attribute indicates that a struct should remove all padding so that it takes the minimum space in memory.

```c
// This struct is 1 byte aligned since its packed
struct Foo4 {
  uint8_t a;
  uint32_t b;
  uint8_t c;
  uint64_t d;
  uint8_t e;
} __attribute__ ((packed)) foo4;
// The size of foo4 is 15 bytes
```

With packing we can get around the implicit padding being added by the compiler. By using the `packed` attribute we can be sure that the size of the struct is 15 bytes regardless of the processor being targeted.

If we wanted to preserved the original padding, all we'd need to do is add it back in explicitly.

```c
// This struct is 1 byte aligned since its packed
struct Foo5 {
  uint8_t a;
  uint8_t padding1[3];
  uint32_t b;
  uint8_t c;
  uint8_t padding2[7];
  uint64_t d;
  uint8_t e;
  uint8_t padding3[7];
} __attribute__ ((packed))  foo5;
// The size of foo5 is 32 bytes
```

## Combining Packed and Aligned

Combining these attributes causes the members to be packed, but with the struct as a whole aligned to the given size. 

```c
// This struct is will be 8 byte aligned when declared on the stack to match its attribute
struct Foo6 {
  uint8_t a;
  uint32_t b;
  uint8_t c;
  uint64_t d;
  uint8_t e;
  // Implicitly add 1 bytes of padding so the struct size is a multiple of its alignment
} __attribute__ ((aligned (8), packed)) foo6;
// The size of foo6 is 16 bytes
```

If we wanted to explicitly declare a struct that matched the implicit structure and alignment of the original `Foo` we would need to do:

```c
// This struct is will be 8 byte aligned when declared on the stack to match its attribute
struct Foo7 {
  uint8_t a;
  uint8_t padding1[3];
  uint32_t b;
  uint8_t c;
  uint8_t padding2[7];
  uint64_t d;
  uint8_t e;
  uint8_t padding3[7];
} __attribute__ ((aligned (8), packed)) foo7;
// The size of foo7 is 32 bytes
```

The difference now is that this isn't affected at all by compiler's default alignment of the member variables.

# My Best Practices

Based on needing to write and debug code in this space I've developed "opinions®ᵀᴹ" on how to approach the challenges.

## Opinion 1: Avoid Writing Code With Binary Compatibility Constraints if Possible

This is easier said then done since it isn't always obvious what sort of code can require binary compatibility. Here are some situations that may make assumptions on binary layout:

1. Writing data to an IO interface (file, network, etc.)
2. Type casting
3. Using bit operations
4. Doing pointer arithmetic

It's entirely possible to write code that does some of the above without issue. Often if you're only running on one processor with one compiler you may still never run into issues. However, some fairly innocent looking code like:

```c
char buffer[256]
double* double_ptr = (double*)buffer;
double_ptr[0] = 1.1;
```

Might run into issues on systems that can only process doubles on 8 byte aligned data. In this example `buffer` might not have been allocated with 8 byte alignment, so some processors might throw exceptions when trying to do double operations on this unaligned data.

## Opinion 2: Isolate Code that Requires Binary Compatibility into Libraries

This can be as simple as using a third party serialization library like Protobufs for formatting data for IO, or having the code that deals with potentially unsafe type conversion in a well documented helper function.

## Opinion 3: If All Else Fails, Be as Explicit as Possible

Sometimes for efficiency, you need to do operations that make assumptions about binary layout of structs throughout your entire application. In this case the structs should be declared in a way that leaves as little to the compilers discretion as possible. Typically, this would mean adding the `packed` attribute and explicitly aligning and adding padding as needed. Also, ambiguously sized types (like `int` or `size_t`) should be avoided.

In addition, it may be necessary to limit the programs compatibility to the subset of processors that match assumptions in your code, or use multiple, processor specific implementations. These assumptions should be thoroughly documented where relevant.

Ideally, CI systems should unit test generated data matches reference examples for each supported architecture.
