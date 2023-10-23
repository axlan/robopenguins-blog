---
title: Speeding Search a File for a Binary Sequence in Python
author: jon
layout: post
categories:
  - Software
  - Work
image: 2023/python_time_thumb.webp
---

I recently spent some time optimizing a deserialization tool at work. I wanted to walk through my process for optimizing this Python code.

It's a truism that if you want speed, Python is probably not the right language to be using. However, that doesn't mean there aren't situations where Python optimization is useful.

My employer, PointOne Navigation, provides open source Python library for processing data from our GPS receivers <https://github.com/PointOneNav/fusion-engine-client>. It's a proprietary protocol that's meant to support lossy transports like an RS232 connection. While we also provide C++ tools, the graphical analysis is all Python based. We're a small team and don't have the resources to manage generating compiled wheels, so our Python package is pure Python code.

# "Framing" the Problem

The [protocol](https://pointonenav.com/wp-content/uploads/2023/10/FusionEngine-Message-Specification-v0.19.pdf) is pretty straightforward:

| Field             | Data Type | Description                                                                                                                                                                                                                  |
|-------------------|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Sync Byte 0       | u8        | Always 0x2E (ASCII ".")                                                                                                                                                                                                      |
| Sync Byte 1       | u8        | Always 0x31 (ASCII "1")                                                                                                                                                                                                      |
| Reserved          | u8[2]     | Reserved for future use.                                                                                                                                                                                                     |
| CRC               | u32       | The 32-bit CRC of all bytes from and including the protocol version field to the last byte in the message, including the message payload. This uses the standard CRC-32 generator polynomial in reversed order (0xEDB88320). |
| Protocol Version  | u8        | The version of the FusionEngine Protocol.                                                                                                                                                                                    |
| Message Version   | u8        | The version of this message.                                                                                                                                                                                                 |
| Message Type      | u16       | Uniquely identifies each message type. The combination of Version and Type should be used to know how to decode the payload.                                                                                                 |
| Sequence Number   | u32       | A sequence number that is incremented with each message.                                                                                                                                                                     |
| Payload Size      | u32       | Size of the payload to follow in bytes.                                                                                                                                                                                      |
| Source Identifier | u32       | Identifies the source of the message when applicable. This definition can change depending on the message type.                                                                                                              |
| Payload           | u8[N]     | "Payload Size" bytes making up the contents of the "Message Type"  message.                                                                                                                                                  |
{:.mbtablestyle}

The typical use case for our tools is to analyze data captured from a serial port and logged directly to a file. This data is typically a mix of our FusionEngine (FE) protocol, along with types of data.

Our tools work by building and caching an index of the FE messages in the log to speed up subsequent runs.

While it can vary a lot, we can generate up to about 250MB an hour. This adds challenges when dealing with 24hour data collections since Python would struggle to manipulate 8GB data objects in memory (Python will often generate multiple copies of the same data).

Since the indexing time was becoming a pain point, and was very well defined, I decided it would be a good target for optimization.

# The original approach

Here's a simplified form of the original code:
```python
while True:
    start_offset_bytes = self.input_file.tell()
    byte0 = self.input_file.read(1)[0]
    while True:
        if byte0 == MessageHeader.SYNC0:
            byte1 = self.input_file.read(1)[0]
            if byte1 == MessageHeader.SYNC1:
                header = MessageHeader()
                data self.input_file.read(header.calcsize())
                header.unpack(data)
                data += self.input_file.read(header.payload_size_bytes)
                if header.validate_crc(data):
                    # Message Found!
                else:
                    read_size = header.payload_size_bytes + header.calcsize()
                    self.input_file.seek(start_offset_bytes, os.SEEK_SET)
            byte0 = byte1
        else:
            break
```

Effectively, this would read through the file byte by byte trying to find a match to the preamble. Then check if the corresponding data passed a CRC check.

There's many ways to speed this up (besides just switching to another language):
 1. System calls can be expensive. Generally, it's faster if you can read a file in large chunks.
 2. Pure Python is slow. Using a library with native code optimizations can improve speed.
 3. While Python only recently is starting to support true parallel multi-threading, parallelizing the processing can provide speed ups.
 4. Avoiding the more expensive CRC could speed things up depending on how often the preamble appears in the data contents. Adding more checks like requiring 0 in the reserved data, or only processing messages with known message ID's could reduce the number of CRC checks needed.
 5. Instead of checking every offset, I could use something like the [Boyer-Moore strstr](https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore_string-search_algorithm) algorithm.
 6. While I didn't explore it here, I could potentially use a GPU for speed up.

# Optimization process

The basic problem of finding all instances of a byte sequence in a file seemed like something that should be a solved problem.

My first thought was to leverage existing linux tools. `grep` and `ripgrep` can be surprisingly fast even for binary data, and can be used process a file in parallel. However, since this library needs to support Windows and only have Python as a dependency, these were off the table.

Finding a somewhat applicable Stack Overflow answer was also surprisingly unhelpful: <https://stackoverflow.com/questions/37078978/the-fastest-way-to-find-a-string-inside-a-file>. While not bad advice for a small file, it didn't really get into the space I was working in.

So I decided to get to the fundamentals and try to do some profiling to figure out the bottleneck.

A quick note for profiling, I'm using a relatively powerful laptop with an SSD, 40GB of memory, and 16 cores. The details of the workload, and the specs of the machine could definitely have changed the results of what turned out to be the most fruitful optimizations.

```python
from datetime import datetime
import struct
import os

file_path = '/logs/input.raw'
file_size = os.stat(input_path).st_size

READ_SIZE = 80 * 1024
READ_WORDS = int(READ_SIZE/2)

PREAMBLE = 0x312E

########################### Un-optimized Speed (6.4 MB/s)

########################### READ ONLY (2259.7 MB/s)
with open(file_path, 'rb') as fd:
  start_time = datetime.now()
  while True:
    data = fd.read(READ_SIZE)
    if len(data) == 0:
       break
elapsed_sec = (datetime.now() - start_time).total_seconds()
print(f'Read only rate: {file_size / elapsed_sec / 1e6} MB/s')

########################### V1 (12.5 MB/s)
offsets = []
total_bytes_read = 0
with open(file_path, 'rb') as fd:
  start_time = datetime.now()
  while True:
    data = fd.read(READ_SIZE)
    if len(data) == 0:
       break
    for i in range(len(data)-1):
        if data[i:i+1] == b'.1':
        offsets.append(total_bytes_read + i)
    total_bytes_read += len(data)
elapsed_sec = (datetime.now() - start_time).total_seconds()
print(f'Read only rate: {file_size / elapsed_sec / 1e6} MB/s')

########################### V2 (18.0 MB/s)
offsets = []
total_bytes_read = 0
with open(file_path, 'rb') as fd:
  start_time = datetime.now()
  while True:
    data = fd.read(READ_SIZE)
    if len(data) == 0:
       break
    # Check the even offsets
    words0 = struct.unpack(f'{READ_WORDS}H', data)
    for i in range(len(words0)):
      if words0[i] == PREAMBLE:
        offsets.append(total_bytes_read + i*2)
    # Check the odd offsets
    words1 = struct.unpack(f'{READ_WORDS-1}H', data[1:-1])
    for i in range(len(words1)):
      if words1[i] == PREAMBLE:
        offsets.append(total_bytes_read + i*2 + 1)
    total_bytes_read += len(data)
elapsed_sec = (datetime.now() - start_time).total_seconds()
print(f'Read only rate: {file_size / elapsed_sec / 1e6} MB/s')
```

I spent some time experimenting with the `READ_SIZE` to find a size that worked best on my system.

This was a very informative initial test. First, it showed that when reading in chunks, the disk IO was not a concern at all. Second, it showed that the CRC checks were not dominating the processing time. Even without them I could only get a 2x-3x speed up.

If I was going to get more significant speed ups, I'd need to keep focussing on speeding up the preamble search step.

My next set of tests looked at pushing the processing into Numpy which uses native optimized code:

```python
from datetime import datetime
import os

import numpy as np

file_path = '/logs/input.raw'
file_size = os.stat(input_path).st_size

READ_SIZE = 80 * 1024
READ_WORDS = int(READ_SIZE/2)

PREAMBLE = 0x312E

########################### V3 (1444.5 MB/s)
offsets = []
total_bytes_read = 0
with open(file_path, 'rb') as fd:
  start_time = datetime.now()
  while True:
    data = np.fromfile(fd, dtype=np.uint16, count=READ_WORDS)
    if len(data) == 0:
       break
    offsets += (np.where(data==PREAMBLE)[0] + total_bytes_read).tolist()
    # AA 31, 2E AA
    data = (data[:-1] << 8) | (data[1:] >> 8)
    offsets += (np.where(data==PREAMBLE)[0] + 1 + total_bytes_read).tolist()
    total_bytes_read += len(data)
elapsed_sec = (datetime.now() - start_time).total_seconds()
print(f'Read only rate: {file_size / elapsed_sec / 1e6} MB/s')

########################### V4 (2420.5 MB/s)
offsets = []
total_bytes_read = 0
with open(file_path, 'rb') as fd:
  start_time = datetime.now()
  while True:
    data = fd.read(READ_SIZE)
    if len(data) == 0:
       break
    sync_matches = (2 * np.where(np.frombuffer(data, dtype=np.uint16) == PREAMBLE)[0]).tolist()
    # AA 31, 2E AA
    sync_matches += (2 * np.where(np.frombuffer(data[1:-1], dtype=np.uint16) == PREAMBLE)[0] + 1).tolist()
    total_bytes_read += len(data)
elapsed_sec = (datetime.now() - start_time).total_seconds()
print(f'Read only rate: {file_size / elapsed_sec / 1e6} MB/s')
```

These tests are a great advertisement for `Numpy`. Even though this wasn't a typical numeric analysis tasks, I could still get an incredible speed up from going to native (presumably vector instruction optimized) code.

Even going back and testing with the CRC check, the Numpy code was running at about 232 MB/s.

But why stop there? I should be able to get some significant speed ups with parallelism. When I was doing this project, Python still hadn't introduced parallel multi-threading. This means that I needed to use the `multiprocessing` library to get the full impact of parallel execution.

```python
from datetime import datetime
from multiprocessing import Pool
import os
from typing import List

import numpy as np

from fusion_engine_client.messages.defs import MessageHeader

file_path = '/logs/input.raw'

MAX_MSG_SIZE = 1024 * 12

READ_SIZE = 80 * 1024
READ_WORDS = int(READ_SIZE / 2)

PREAMBLE = 0x312E
NUM_THREADS = 8

def process_func(block_starts: List[int]):
    offsets = []
    header = MessageHeader()
    with open(file_path, 'rb') as fd:
        for i in range(len(block_starts)):
            block_offset = block_starts[i]
            fd.seek(block_offset)
            data = fd.read(READ_SIZE + MAX_MSG_SIZE)
            if len(data) == READ_SIZE + MAX_MSG_SIZE:
                word_count = READ_WORDS
            else:
                word_count = int(len(data)/2)
            sync_matches = (2 * np.where(np.frombuffer(data, dtype=np.uint16, count=word_count) == PREAMBLE)[0]).tolist()
            # AA 31, 2E AA
            sync_matches += (2 * np.where(np.frombuffer(data[1:], dtype=np.uint16, count=word_count-1) == PREAMBLE)[0] + 1).tolist()

            for i in sync_matches:
                try:
                    header.unpack(buffer=data[i:], validate_crc=True, warn_on_unrecognized=False)
                    offsets.append(i + block_offset)
                except:
                    pass
    return offsets

def main():
    file_size = os.stat(input_path).st_size

    print(f'File size: {int(file_size/1024/1024)}MB')

    block_starts = []
    num_blocks = int(np.ceil(file_size / READ_SIZE))
    chunks, chunk_remainder = divmod(num_blocks, NUM_THREADS)
    byte_offset = 0
    for i in range(NUM_THREADS):
        blocks = chunks
        if i < chunk_remainder:
            blocks += 1
        block_starts.append(list(range(byte_offset, byte_offset + blocks * READ_SIZE, READ_SIZE)))
        byte_offset += blocks * READ_SIZE

    print(f'Reads/thread: {len(block_starts[0])}')

    offsets = []
    with Pool(NUM_THREADS) as p:
        for o in p.map(process_func, block_starts):
            offsets += o

    print(f'Preamble found: {len(offsets)}')

main()
```

This brought the speed with the CRC checks up to about 900MB/s. This would actually probably improve with longer logs. I'd been testing with a 1.3GB log and at this speed, a large portion of the time is probably spent on initializing the processes.

Of course these were all simplified test applications, and actually all have some subtle bugs (mostly concerning messages that span from one read to the next).

You can see the final code at <https://github.com/PointOneNav/fusion-engine-client/blob/master/python/fusion_engine_client/parsers/fast_indexer.py>
