---
title: Trying Out Rust
author: jon
layout: post
categories:
  - Software
  - Work
image: 2024/zen-47-hedron-crab.webp
---

For some inexplicable reason, I had a whim to try out Rust. I wanted a project that was very limited on scope, but still "real". I decided to port the code for indexing data from my company's binary data format.

Awhile ago I spent some time trying to speed up this process in Python and managed improving it by a couple orders of magnitude using multiprocess parallelism and careful numpy optimizing. See: [Optimizing Searching a File for a Binary Sequence in Python]({% post_url 2023-10-03-python-optimization %})

I wanted to see how the optimized Python would compare to rust, starting from a naive implementation and doing a few rounds of optimizations.

I'm basically a complete rust newbie, and had to start by just reviewing the basic syntax.

The absolute simplest implementation would be to read the whole file in memory and iterate through it.

From there I could try separating file reading, processing, and output into separate threads. Another approach would be to use SIMD to vectorize searching for preambles which was expensive in Python.

I spent a little time looking into this:

 * <https://users.rust-lang.org/t/memory-alignment-for-vectorized-code/53640>
 * <https://users.rust-lang.org/t/understanding-rusts-auto-vectorization-and-methods-for-speed-increase/84891/2>

Since I was really getting into the weeds (since I had a decent amount of time to hypothesize, and not much time to code) I decided to just give it a shot and see how it went.

The main goal of the program would be to do the following:
 * Find the occurrences of the preamble sequence in the file.
 * Deserialize the header data to get the payload size and CRC.
 * Compute the checksum on the data and see if it matched the header CRC.
 * Write out the message offsets to a new file.

# CRC Algorithm

The only thing here that's a bit complicated is the CRC computation algorithm.

The first "real" code I wrote in rust was porting the C version of this CRC:

The C++ code I ported:
```cpp
const uint32_t* GetCRCTable() {
  static constexpr uint32_t polynomial = 0xEDB88320;

  static bool is_initialized = false;
  static uint32_t crc_table[256];

  if (!is_initialized) {
    for (uint32_t i = 0; i < 256; i++) {
      uint32_t c = i;
      for (size_t j = 0; j < 8; j++) {
        if (c & 1) {
          c = polynomial ^ (c >> 1);
        } else {
          c >>= 1;
        }
      }
      crc_table[i] = c;
    }

    is_initialized = true;
  }

  return crc_table;
}

uint32_t CalculateCRC(const void* buffer, size_t length, uint32_t initial_value = 0) {
  static const uint32_t* crc_table = ::GetCRCTable();
  uint32_t c = initial_value ^ 0xFFFFFFFF;
  const uint8_t* u = static_cast<const uint8_t*>(buffer);
  for (size_t i = 0; i < length; ++i) {
    c = crc_table[(c ^ u[i]) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
```

```rust
// As someone who likes constexpr in C++, I was pretty happy with how straightforward this was in rust.
// The main "weird" limitation was needing to use a while loop since for loops aren't supported.
const CRC_TABLE: [u32; 256] = {
    const POLYNOMIAL: u32 = 0xEDB88320;
    let mut a: [u32; 256] = [0; 256];

    let mut i: u32 = 0;
    while i < 256 {
        let mut c: u32 = i;
        let mut j: u32 = 0;
        while j < 8 {
            if (c & 1) != 0 {
                c = POLYNOMIAL ^ (c >> 1);
            } else {
                c >>= 1;
            }
            j += 1;
        }
        a[i as usize] = c;
        i += 1;
    }
    a
};

// I was a bit surprised by the casting needed to use explicit byte sized integers as indexes.
// Makes sense, but very surprising coming from C/C++.
fn calculate_crc_with_init(data: &[u8], initial_value: u32) -> u32 {
    let mut c: u32 = initial_value ^ 0xFFFFFFFF;
    for byte in data {
        let idx: usize = (c as u8 ^ *byte) as usize;
        c = CRC_TABLE[idx] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
}

fn calculate_crc(data: &[u8]) -> u32 {
    return calculate_crc_with_init(data, 0);
}
```

Of course, this is totally unnecessary since there's already way better existing implementations in Rust. I decided to use one of the popular ones "crc32fast" and verified it matched my implementation.

# Naive Implementation

With that out of the way I was able to pretty quickly bang this out. Note, I didn't do any of the error handling, so it just panics on invalid files and the like.

```rust
use std::env;
use std::fs::File;
use std::io;
use std::io::BufWriter;
use std::io::Read;
use std::io::Write;

const MAX_MESSAGE_SIZE: usize = 32768;

const HEADER_SIZE: usize = 24;
const PREFIX: &[u8; 4] = b".1\x00\x00";

// I was really happy to find this build in algorithm, since this is probably the most performance
// intensive part of this code.
fn find_preamble(haystack: &[u8]) -> Option<usize> {
    haystack
        .windows(PREFIX.len())
        .position(|window| window == PREFIX)
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    let mut match_count = 0;
    let mut parse_count = 0;

    // Open the file passed in the first command line argument.
    let mut file = File::open(args[1].clone())?;
    // Read the whole file into a vector.
    let mut contents = Vec::new();
    file.read_to_end(&mut contents)?;

    // Tracks progress into file.
    let mut offset = 0;
    // File to write message indexes to.
    let mut stream = BufWriter::new(File::create("out.bin")?);
    loop {
        // Find the candidate start of the next message.
        let idx = find_preamble(&contents[offset..]);
        match idx {
            // If a preamble was found:
            Some(_) => {
                match_count += 1;
                offset += idx.unwrap();

                let remaining = &contents[offset..];
                if remaining.len() < HEADER_SIZE {
                    break;
                }

                // Decode the u32 16 byte into the message as the payload size.
                let byte_len = u32::from_ne_bytes(remaining[16..20].try_into().unwrap()) as usize;

                if byte_len > MAX_MESSAGE_SIZE {
                    offset += 4;
                    continue;
                }

                // Might miss last message if false positive with large size found near end.
                if byte_len + HEADER_SIZE > remaining.len() {
                    break;
                }

                // Decode the u32 4 byte into the message as the CRC.
                let crc = u32::from_ne_bytes(remaining[4..8].try_into().unwrap());
                // Compute the CRC of the remainder of the message.
                let calc_crc = crc32fast::hash(&remaining[8..(byte_len + HEADER_SIZE)]);

                if crc == calc_crc {
                    offset += HEADER_SIZE + byte_len;
                    parse_count += 1;
                    stream.write_all(&(offset as u32).to_le_bytes())?;
                } else {
                    offset += 4;
                    continue;
                }
            }
            // Otherwise it reached the end of the data and should exit.
            None => break,
        }
    }

    println!("match_count: {match_count}");
    println!("parse_count: {parse_count}");
    Ok(())
}
```

This worked surprisingly well. The 1.5GB files I had processed in about 2 seconds on my machine which was already faster then the optimized python. I was loading the whole file into memory, but this wasn't too bad in Rust unlike Python.

# Memory Map

The naive approach worked so well, that really the only thing I wanted to fix was avoiding reading the whole file into memory so it could work with arbitrarily large files. I figured the simplest way to accomplish this would be a memory map.

Now the memory map libraries are marked as "unsafe". My understanding is that since my use case is real only on a file that is not being modified, it's not much of a concern.

```rust
use std::env;
use std::fs::File;
use std::io::BufWriter;
use std::io::{self, Write};

const MAX_MESSAGE_SIZE: usize = 32768;

const HEADER_SIZE: usize = 24;
const PREFIX: &[u8; 4] = b".1\x00\x00";

fn find_preamble(haystack: &[u8]) -> Option<usize> {
    haystack
        .windows(PREFIX.len())
        .position(|window| window == PREFIX)
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    let mut match_count = 0;
    let mut parse_count = 0;

    let file = File::open(args[1].clone())?;
    let mmap = unsafe { memmap2::Mmap::map(&file)? };

    let mut offset = 0;

    let mut stream = BufWriter::new(File::create("out.bin")?);

    loop {
        let idx = find_preamble(&mmap[offset..]);
        match idx {
            Some(_) => {
                match_count += 1;
                offset += idx.unwrap();

                let remaining = &mmap[offset..];
                if remaining.len() < HEADER_SIZE {
                    break;
                }

                let byte_len = u32::from_ne_bytes(remaining[16..20].try_into().unwrap()) as usize;

                if byte_len > MAX_MESSAGE_SIZE {
                    offset += 4;
                    continue;
                }

                // Might miss last message if false positive with large size found near end.
                if byte_len + HEADER_SIZE > remaining.len() {
                    break;
                }

                let crc = u32::from_ne_bytes(remaining[4..8].try_into().unwrap());
                let calc_crc = crc32fast::hash(&remaining[8..(byte_len + HEADER_SIZE)]);

                if crc == calc_crc {
                    offset += HEADER_SIZE + byte_len;
                    parse_count += 1;
                    stream.write_all(&(offset as u32).to_le_bytes())?;
                } else {
                    offset += 4;
                    continue;
                }
            }
            None => break,
        }
    }
    println!("match_count: {match_count}");
    println!("parse_count: {parse_count}");
    Ok(())
}
```

Pretty much the exact same thing, except using the mmap instead of preloading the file. Not only does this barely use and memory, but it also ran four times faster.

# Conclusion

At this point, I had lost motivation to improve this further. It was so fast it didn't really matter. It would only take 4 minutes to process a terabyte of data.

After having to jump through so many hoops to get the Python speed up, this was a refreshing change of pace.

More generally, I was pretty with the Rust I've experienced so far. I definitely had flashbacks of when I was learning C++ and had to cycle through trying every iteration of `const int`, `const *int`, `const **int`, etc. This time though I was a bit more confident the compiler would catch anything stupid I mixed up.

I was generally impressed with the standard library API design. It was different enough from the familiar syscall wrappers that I needed to spend a lot of time in the documentation, but most of the changes were clear improvements.

For the most part I liked the ways it diverged from C++. Traits seemed like an improvement over classes/inheritance and matching seemed like an elegant way to handle a lot of common design patterns.

I was much slower in rust due to these differences, but it did force me to think through what I was writing more thoroughly. I still managed to make mistakes, but the possible set of mistakes was much smaller. This was especially useful as a beginner since it typically added an extra check that I was using an interface correctly.

I do want to try something multi-threaded at some point, but I would definitely want to consider rust for any future greenfield system programming I get up to.
