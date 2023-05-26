---
title: Toy Controller WiFi
author: jon
layout: post
categories:
  - IoT
  - Hardware
  - WLED
image: 2023/toy_controller/front_wires_thumb.webp
---

A friend of mine gave me a baby toy to hack awhile back, and I finally got a chance to take a crack at it.

[<img class="center" src="{{ site.image_host }}/2023/toy_controller/controller_thumb.webp" height="50%" width="50%">]({{ site.image_host }}/2023/toy_controller/controller.webp)

# Hardware

When I initially opened up the toy, I was overjoyed that:
1. It was made in a way that very easy to take apart and put back together. Very little glue, decent connectors, and everything well designed.
2. The circuit board had test points! It was basically the best case scenario for soldering wire that had access to all the features.

I've done enough of these (see <https://www.robopenguins.com/categories.html#IoT>) that I had a pretty good idea going in what I wanted to do. My original design would be to embed a [PCF8575 IO expander](https://www.ti.com/lit/ds/symlink/pcf8575.pdf) into the case with a connector that would let me attach an ESP8266 WiFi microcontroller. The IO expander would connect to all the buttons and let the microcontroller read them with just 2 data pins over I2C.

This would let me wire up all the buttons and have direct access to the ESP8266 if I needed to debug it. It would also let me use a cheaper ESP8266 breakout board that only used a few pins and didn't have a voltage regulator.

Unfortunately, after poking around with the controller a bit, I realized that pushing buttons on the controller worked by pulling them to Vcc. The PCF8575 works by also applying a pull up when reading pins, so would not be able to accurately read the button pushes on the controller.

[<img class="center" src="{{ site.image_host }}/2023/toy_controller/front_wires_thumb.webp">]({{ site.image_host }}/2023/toy_controller/front_wires.jpg)

That wasn't too big a problem, since I could just use a bigger ESP8266 breakout board, the [Wemos D1 Mini](https://randomnerdtutorials.com/esp8266-pinout-reference-gpios/#:~:text=is%20shown%20below.-,Wemos,-D1%20Mini%20Pinout). This would also mean I could seal the whole project into the controller so it would stay baby safe.

This also meant I would need the toy to be powered normally while my own controller was running (unless I wanted to permanently cut some traces). I was a little bummed I wouldn't be able to play my own sound effects or control the LED, but it simplified things quite a bit. If its sound effects were really too obnoxious I could alway leave that connector unplugged.

After some initial testing I confirmed that the board appeared to be able to be powered straight from the toys 3 AAA batteries, and the voltage levels from the button presses were being read correctly. Initially, I tried to hook up the board's 9 GPIO pins, but realized that two of these have pull ups that are required for the board to boot. I switched to using the other 7 GPIO pins, and the analog converter pin to monitor the toy's main 8 buttons.

With the electronics all figured out, I soldered all the connections and cut out some of the supports inside the toy to give the chip somewhere to fit. Then I just hot glued it in place and reassembled.

[<img class="center" src="{{ site.image_host }}/2023/toy_controller/back_cut_thumb.webp">]({{ site.image_host }}/2023/toy_controller/back_cut.jpg)
[<img class="center" src="{{ site.image_host }}/2023/toy_controller/front_cut_thumb.webp">]({{ site.image_host }}/2023/toy_controller/front_cut.jpg)
[<img class="center" src="{{ site.image_host }}/2023/toy_controller/front_placement_thumb.webp">]({{ site.image_host }}/2023/toy_controller/front_placement.jpg)

# Software

All the code mentioned can be found at: <https://github.com/axlan/toy_controller>

The software side of things mostly just incorporates things I've learned from my previous IoT projects. Since this was going to be sealed inside a toy I didn't want to disassemble, I wanted to make sure I could reprogram it over WiFi, and I could update the WiFi settings without physical access. I did this with the standard ArdiunoOTA and [WiFiManager](https://github.com/tzapu/WiFiManager) libraries.

To report the button presses I used MQTT which made it very easy to integrate it with a variety of applications.

It only took a few minutes to throw together this PyGame demo:

<iframe width="455" height="809" src="https://www.youtube.com/embed/W4YEOwaM-SE" title="Demo of Toy Controller Sending MQTT to PyGame." frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

and to integrate it with [one of my previous projects]({% post_url 2020-01-14-fire-emblem-lights %}):

<iframe width="1583" height="620" src="https://www.youtube.com/embed/oS_-zvyJSHY" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

For this I wrote a little Python script that listens for updates over MQTT and based on the button presses sends JSON updates to the WLED software on the LED sculpture. It would have been easy enough to control the sculpture directly with MQTT, but no reason to make the demo more complicated.

Awhile later I also added a server for controlling a Sonos:

<iframe width="1583" height="620" src="https://www.youtube.com/embed/QLYZzVxPUkU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

I did this with a Python Sonos control library <https://github.com/SoCo/SoCo>.
