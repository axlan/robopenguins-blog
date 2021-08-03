---
title: Logging a Cheap Air Quality Monitor
author: jon
layout: post
categories:
  - Software
  - Hardware
  - Reverse Engineering
  - IoT
image: 2021/air_monitor/air_monitor_thumb.webp
---

With fire season approaching in California I wanted to get a air quality monitor to see how bad the air is over time. I thought I'd do another reverse engineering project to add logging to a PC.

I got a cheap JSM-131 SE from Amazon. The listings are terrible and don't even have the model mentioned anywhere. I have doubts over it's accuracy, but I figure it would be at least interesting to monitor over time.

This is a bit of a placeholder, since I didn't get too far before deciding to focus on other projects.

Nothing surprisingly inside:

[<img class="center" src="{{ site.image_host }}/2021/air_monitor/inside_board_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/air_monitor/inside_board.jpg)

There are the the connections for the sensors themselves, power conditioning, and the two main IC's:

 * Sino Wealth SH79F166A microcontroller
 * TM1622 2033BF3027XT LCD driver

 The microcontroller collects the data from the sensors, then sets the LCD segments by sending data over a serial connection.

 The path forward here would be to tap off this data line, and decode the data for transmission to a PC.
