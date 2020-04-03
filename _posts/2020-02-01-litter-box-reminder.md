---
title: Litter Box Reminder
author: jon
layout: post
categories:
  - Hardware
  - Personal
image: 2020/litter_butterfly_thumb.jpg
---

Another simple "home automation" project. My wife mentioned it would be nice to have a way to keep track of when the cat litter was last cleaned. This is a pretty straight forward microcontroller project, but I made it much harder by trying to use a very old dev board I had lying around.

Here's the final project. I just soldered an RGB LED to the front, and attached AA batteries instead of the original coin cell.

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/litter_butterfly.jpg" alt="Finished Product">]({{ site.image_host }}/2020/litter_butterfly.jpg)

All it does, is count the hours since the button was last pressed, and turn the LED orange, then red as the time approaches 24 hours.

I thought this dev board would be the perfect form factor since it already had the LED and a RTC (real time clock). However, I underestimated the difficulties in resurrecting the ancient example codebase.

The board is the [Atmel AVR Butterfly](https://www.microchip.com/DevelopmentTools/ProductDetails/PartNO/ATAVRBFLY). Looking just now I'm actually amazed it's still on sale. It's a neat little form factor with a decent set of functionality (4 direction joystick, audio, basic LCD).


There's a really great demo program with all the boards features, but the source they provide was written in 2003. Since then the dev tools have changed radically, and porting the code over would be an extremely painful process. It doesn't help that I haven't programmed a microcontroller directly (without an abstraction layer like the arduino framework) in a few years.

I made a few failed attempts to get the LCD displaying something, either by porting code, or writing something from scratch, but wasn't making much progress. I could compile and load programs, but I was missing something for actually getting the LCD up and running.

There was actually a lot of useful articles and PDFs about the butterfly. It just was mostly written 10 or more years ago. The [AVR Freaks](https://www.avrfreaks.net/) forum was one of the main sources, and one project that came up pretty frequently was <https://github.com/abcminiuser/buttload>. It was a project to use the butterfly as a programmer to load code onto other microcontrollers. Even though the code is 12 years old, it was written after some of the bigger code structure changes from Atmels GCC compiler.

I was able to debug the makefile and eventually get this codebase to compile. From there I could create a Atmel Studio 7 (the current IDE) project around the makefile. From there it was pretty easy to add in my desired functionality. 

Here's the completed project: <https://github.com/axlan/buttload/tree/cat-litter>
