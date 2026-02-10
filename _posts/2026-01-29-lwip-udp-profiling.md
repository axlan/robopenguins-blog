---
title: "Profiling ESP32 UDP Sends"
author: jon
layout: post
categories:
  - Software
  - IoT
image: 2026/lwip_udp/lwip.jpg
---

With my new profiling setup, I decided to test efficiently sending UDP data logs.

With my findings from [Making an Embedded Profiler 3: ESP IDF Tools]({% post_url 2026-01-27-making-a-tracing-profiler-pt3 %}), I decided to stick with using [MabuTrace](https://github.com/mabuware/MabuTrace). While it isn't exactly what I wanted for profiling, it covers all the key features, and in many ways is better than anything I'd end up making.

However, it doesn't cover the continuous logging use case. While it would generally make more sense to use MQTT, ESP-IDF logging, or some other existing protocol, I wanted to try using my <https://github.com/axlan/min-logger> since I made it with the exact features I wanted.

For the ESP32, [min-logger](https://github.com/axlan/min-logger) was still missing a backend for buffering logged data and sending it to the host.

I quickly setup a ESP-IDF framework test application, and began to experiment with different approaches. [MabuTrace](https://github.com/mabuware/MabuTrace) was great in letting me see exactly what was happening with each approach.

My goal was to set up a system where multiple tasks on multiple cores could write data simultaneously with minimal latency. This data would be buffered and periodically sent to the host over UDP. Since I don't care about latency and each send has overhead, each send would be the maximum UDP packet size. I wanted to find a way to do this while being efficient with CPU and memory usage.

Code for these tests is found at: <https://github.com/axlan/esp32-idf-udp-send-profiling>

While this article is about figuring out how to efficiently send UDP data, based on these results I added a [buffered UDP output option to min-logger](https://github.com/axlan/min-logger/tree/master?tab=readme-ov-file#esp32-buffered-platform-min_logger_buffered_esp32h). I fell down a bit of a rabbit hole making a custom ring buffer for the use case: <https://github.com/axlan/min-logger/blob/master/src/min_logger/platform_implementations/lock_free_ring_buffer.h>.

# Data Synchronization

After reading the [ESP-IDF documentation](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/index.html), I found the [FreeRTOS ring buffer addition](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/system/freertos_additions.html#ring-buffers). Specifically, I could use it in "byte buffer" mode. This meant I could efficiently write arbitrarily sized chunks from multiple tasks and combine them into a single large read for sending over UDP. Initially, I set it up to drain the ring buffer into an array in the UDP send task. However, I realized that by sizing the buffer to be twice the desired UDP write size, I could effectively double-buffer the data and not need to worry about tearing on the consumer side.

Here's a little demo below. Note that as long as each read is half the buffer size, the data will always be contiguous.

<style>
    .buffer-container {
        max-width: 800px;
        margin: 0 auto;
    }
    .step {
        background: white;
        padding: 20px;
        margin: 20px 0;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .step-title {
        font-size: 18px;
        font-weight: bold;
        margin-bottom: 15px;
        color: #2c3e50;
    }
    .buffer {
        display: flex;
        gap: 2px;
        margin: 15px 0;
        flex-wrap: nowrap;
    }
    .cell {
        width: 32px;
        height: 32px;
        border: 2px solid #333;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 9px;
        font-weight: bold;
        position: relative;
        background: white;
        flex-shrink: 0;
    }
    .cell.filled {
        background: #4CAF50;
        color: white;
    }
    .cell.empty {
        background: #e0e0e0;
        color: #999;
    }
    .pointer {
        font-size: 10px;
        position: absolute;
        font-weight: bold;
    }
    .read-ptr {
        top: -18px;
        color: #e74c3c;
    }
    .write-ptr {
        bottom: -18px;
        color: #3498db;
    }
    .info {
        margin-top: 10px;
        padding: 10px;
        background: #f8f9fa;
        border-left: 4px solid #3498db;
        font-size: 14px;
    }
    .legend {
        display: flex;
        gap: 20px;
        margin: 20px 0;
        justify-content: center;
        flex-wrap: wrap;
    }
    .legend-item {
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .legend-box {
        width: 20px;
        height: 20px;
        border: 2px solid #333;
    }
</style>
<div class="buffer-container">
    <h1>Ring Buffer Operations (Size: 20)</h1>

    <div class="legend">
        <div class="legend-item">
            <div class="legend-box" style="background: #4CAF50;"></div>
            <span>Filled</span>
        </div>
        <div class="legend-item">
            <div class="legend-box" style="background: #e0e0e0;"></div>
            <span>Empty</span>
        </div>
        <div class="legend-item">
            <span style="color: #e74c3c; font-weight: bold;">↓ Read Pointer</span>
        </div>
        <div class="legend-item">
            <span style="color: #3498db; font-weight: bold;">↑ Write Pointer</span>
        </div>
    </div>

    <!-- Initial State -->
    <div class="step">
        <div class="step-title">Initial State</div>
        <div class="buffer">
            <div class="cell empty">
                <span class="pointer read-ptr">R</span>
                <span class="pointer write-ptr">W</span>
                0
            </div>
            <div class="cell empty">1</div>
            <div class="cell empty">2</div>
            <div class="cell empty">3</div>
            <div class="cell empty">4</div>
            <div class="cell empty">5</div>
            <div class="cell empty">6</div>
            <div class="cell empty">7</div>
            <div class="cell empty">8</div>
            <div class="cell empty">9</div>
            <div class="cell empty">10</div>
            <div class="cell empty">11</div>
            <div class="cell empty">12</div>
            <div class="cell empty">13</div>
            <div class="cell empty">14</div>
            <div class="cell empty">15</div>
            <div class="cell empty">16</div>
            <div class="cell empty">17</div>
            <div class="cell empty">18</div>
            <div class="cell empty">19</div>
        </div>
        <div class="info">Read = 0, Write = 0, Count = 0</div>
    </div>

    <!-- After Write 5 -->
    <div class="step">
        <div class="step-title">Step 1: Write 5 elements</div>
        <div class="buffer">
            <div class="cell filled">
                <span class="pointer read-ptr">R</span>
                0
            </div>
            <div class="cell filled">1</div>
            <div class="cell filled">2</div>
            <div class="cell filled">3</div>
            <div class="cell filled">4</div>
            <div class="cell empty">
                <span class="pointer write-ptr">W</span>
                5
            </div>
            <div class="cell empty">6</div>
            <div class="cell empty">7</div>
            <div class="cell empty">8</div>
            <div class="cell empty">9</div>
            <div class="cell empty">10</div>
            <div class="cell empty">11</div>
            <div class="cell empty">12</div>
            <div class="cell empty">13</div>
            <div class="cell empty">14</div>
            <div class="cell empty">15</div>
            <div class="cell empty">16</div>
            <div class="cell empty">17</div>
            <div class="cell empty">18</div>
            <div class="cell empty">19</div>
        </div>
        <div class="info">Read = 0, Write = 5, Count = 5</div>
    </div>

    <!-- After Write 6 -->
    <div class="step">
        <div class="step-title">Step 2: Write 6 elements</div>
        <div class="buffer">
            <div class="cell filled">
                <span class="pointer read-ptr">R</span>
                0
            </div>
            <div class="cell filled">1</div>
            <div class="cell filled">2</div>
            <div class="cell filled">3</div>
            <div class="cell filled">4</div>
            <div class="cell filled">5</div>
            <div class="cell filled">6</div>
            <div class="cell filled">7</div>
            <div class="cell filled">8</div>
            <div class="cell filled">9</div>
            <div class="cell filled">10</div>
            <div class="cell empty">
                <span class="pointer write-ptr">W</span>
                11
            </div>
            <div class="cell empty">12</div>
            <div class="cell empty">13</div>
            <div class="cell empty">14</div>
            <div class="cell empty">15</div>
            <div class="cell empty">16</div>
            <div class="cell empty">17</div>
            <div class="cell empty">18</div>
            <div class="cell empty">19</div>
        </div>
        <div class="info">Read = 0, Write = 11, Count = 11</div>
    </div>

    <!-- After Read 10 -->
    <div class="step">
        <div class="step-title">Step 3: Read 10 elements</div>
        <div class="buffer">
            <div class="cell empty">0</div>
            <div class="cell empty">1</div>
            <div class="cell empty">2</div>
            <div class="cell empty">3</div>
            <div class="cell empty">4</div>
            <div class="cell empty">5</div>
            <div class="cell empty">6</div>
            <div class="cell empty">7</div>
            <div class="cell empty">8</div>
            <div class="cell empty">9</div>
            <div class="cell filled">
                <span class="pointer read-ptr">R</span>
                10
            </div>
            <div class="cell empty">
                <span class="pointer write-ptr">W</span>
                11
            </div>
            <div class="cell empty">12</div>
            <div class="cell empty">13</div>
            <div class="cell empty">14</div>
            <div class="cell empty">15</div>
            <div class="cell empty">16</div>
            <div class="cell empty">17</div>
            <div class="cell empty">18</div>
            <div class="cell empty">19</div>
        </div>
        <div class="info">Read = 10, Write = 11, Count = 1</div>
    </div>

    <!-- After Write 12 -->
    <div class="step">
        <div class="step-title">Step 4: Write 12 elements (wraps around)</div>
        <div class="buffer">
            <div class="cell filled">0</div>
            <div class="cell filled">1</div>
            <div class="cell filled">2</div>
            <div class="cell empty">3</div>
            <div class="cell empty">4</div>
            <div class="cell empty">5</div>
            <div class="cell empty">6</div>
            <div class="cell empty">7</div>
            <div class="cell empty">8</div>
            <div class="cell empty">9</div>
            <div class="cell filled">
                <span class="pointer read-ptr">R</span>
                10
            </div>
            <div class="cell filled">11</div>
            <div class="cell filled">12</div>
            <div class="cell filled">13</div>
            <div class="cell filled">14</div>
            <div class="cell filled">15</div>
            <div class="cell filled">16</div>
            <div class="cell filled">17</div>
            <div class="cell filled">18</div>
            <div class="cell filled">19</div>
        </div>
        <div class="info">Read = 10, Write = 3 (wrapped), Count = 13</div>
    </div>

    <!-- After Read 10 -->
    <div class="step">
        <div class="step-title">Step 5: Read 10 elements</div>
        <div class="buffer">
            <div class="cell filled">
                <span class="pointer read-ptr">R</span>
                0
            </div>
            <div class="cell filled">1</div>
            <div class="cell filled">2</div>
            <div class="cell empty">
                <span class="pointer write-ptr">W</span>
                3
            </div>
            <div class="cell empty">4</div>
            <div class="cell empty">5</div>
            <div class="cell empty">6</div>
            <div class="cell empty">7</div>
            <div class="cell empty">8</div>
            <div class="cell empty">9</div>
            <div class="cell empty">10</div>
            <div class="cell empty">11</div>
            <div class="cell empty">12</div>
            <div class="cell empty">13</div>
            <div class="cell empty">14</div>
            <div class="cell empty">15</div>
            <div class="cell empty">16</div>
            <div class="cell empty">17</div>
            <div class="cell empty">18</div>
            <div class="cell empty">19</div>
        </div>
        <div class="info">Read = 0 (wrapped), Write = 3, Count = 3</div>
    </div>
</div>

The issue with implementing this approach is that the [FreeRTOS ring buffer addition](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/system/freertos_additions.html#ring-buffers) doesn't have a way to wait for a certain threshold of data to be available. This meant I needed to poll the buffer to determine when it was full enough to read from.

# lwIP UDP Send Options

The first place I looked for an example of efficiently sending UDP packets was the ESP32 Arduino library. It has the [AsyncUDP](https://github.com/espressif/arduino-esp32/blob/master/libraries/AsyncUDP/) library. This library introduced me to an API I hadn't seen before: the [lwIP raw/callback-style API](https://www.nongnu.org/lwip/2_0_x/group__udp__raw.html). I spent considerable time trying to unravel this poorly documented interface. Once I started to understand it, I noticed the [esp32-idf lwIP documentation](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-guides/lwip.html) mentioned that this API is not supported and to instead use a similar [netconn API](https://www.nongnu.org/lwip/2_0_x/api_8h.html). Additionally, even this netconn API is only unofficially supported, and the BSD sockets are the recommended interface.

Regardless, I completed a basic test application with both the BSD and raw APIs:

Raw:
[<img class="center" src="{{ site.image_host }}/2026/mabu_trace.png">]({{ site.image_host }}/2026/mabu_trace.png)

BSD:
[<img class="center" src="{{ site.image_host }}/2025/profiling/gen_trace2_open.png">]({{ site.image_host }}/2025/profiling/gen_trace2_open.png)

Even looking at heap usage it isn't obvious that the raw API has any advantage over the BSD.

This was somewhat surprising since I set up the raw API to perform zero-copy operations:

```cpp
static void udp_client_task_raw(void *pvParameters)
{
  struct udp_pcb *pcb;
  pcb = udp_new();
  udp_bind(pcb, IP_ADDR_ANY, 0);

  ip_addr_t dest_ip;
  dest_ip.type = IPADDR_TYPE_V4;
  IP4_ADDR(&dest_ip.u_addr.ip4, 192, 168, 1, 111);

  // Allocate a pbuf that will point to a block of read only memory. In this case it will point to a half of the ring buffer being held.
  struct pbuf *pbuf = pbuf_alloc(PBUF_TRANSPORT, UDP_MESSAGE_SIZE, PBUF_ROM);
  assert(pbuf != NULL);

  // This is effectively const, but needs to be mutable to match pbuf typing since it's used for receive calls as well as send.
  void *held_data = NULL;

  while (1)
  {
    // Check if UDP send is done. If so return data to ring buffer.
    if (held_data != NULL && pbuf->ref == 1)
    {
      vRingbufferReturnItem(buf_handle, held_data);
      held_data = NULL;
    }

    // Check if a UDP packet's worth of data is ready to send.
    if (xRingbufferGetCurFreeSize(buf_handle) <= UDP_MESSAGE_SIZE)
    {
      size_t read_size = 0;
      // By always reading half the buffer size, the read will never be limited by rolling over the end of the buffer.
      held_data = xRingbufferReceiveUpTo(buf_handle, &read_size, pdMS_TO_TICKS(portMAX_DELAY), UDP_MESSAGE_SIZE);
      assert(read_size == UDP_MESSAGE_SIZE);
      pbuf->payload = held_data;
      pbuf->tot_len = UDP_MESSAGE_SIZE;
      udp_sendto(pcb, pbuf, &dest_ip, PORT);
    }
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}
```

It's also surprising that for both implementations, the send call usually blocks for 3.5ms with just a single send every couple of seconds.

There are several possibilities for this result:
 - As mentioned, the raw API isn't maintained, so it may be doing something less efficient than the better-supported BSD sockets.
 - Since no other data is being sent, each send call transmits the packet immediately. The behavior might be different if data was being queued.
 - The BSD socket appears to leverage the tiT (the lwIP background) task. It's possible it's using resources that are already allocated there.
 - The expected behavior may be for these functions to block to reduce buffer usage.
 - There may be more optimal compile-time configuration settings that would improve the raw interface if sockets weren't being used anywhere.

As a final test, I also implemented this with the netconn API. It ended up performing being fairly similar to the BSD code, passing off the processing to the tiT task.

Here are the three implementations:
 - bsd: <https://github.com/axlan/esp32-idf-udp-send-profiling/blob/f92c54270bbf05a5d4f08c3ff62366de2720ff9a/src/main.cpp#L226>
 - netconn: <https://github.com/axlan/esp32-idf-udp-send-profiling/blob/f92c54270bbf05a5d4f08c3ff62366de2720ff9a/src/main.cpp#L173>
 - raw: <https://github.com/axlan/esp32-idf-udp-send-profiling/blob/f92c54270bbf05a5d4f08c3ff62366de2720ff9a/src/main.cpp#L124>

In the end, for this use case, the BSD sockets make the most sense since they are the simplest and best documented. The only real behavioral advantage I could identify is that the raw implementation spends more time in the user task instead of the lwIP task. This could potentially help the latency of other user tasks since they could more easily preempt it.
