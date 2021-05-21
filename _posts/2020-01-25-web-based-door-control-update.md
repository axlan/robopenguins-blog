---
title: Web Based Door Control Update
author: jon
layout: post
categories:
  - Software
  - Hardware
  - IoT
image: 2020/uptime.webp
---

Another update to [Web Based Door Control]({% post_url 2014-09-01-web-based-door-control %}). Here I take the path of least resistance to add Google Assistant integration and uptime monitoring by integrating with [Blynk](https://blynk.io/), [IFTTT](https://platform.ifttt.com/), and [UptimeRobot](https://uptimerobot.com/).

After the last few IoT projects, I thought this would be a quick way to combine some of what I learned over some of my recent projects:

* [AWS IoT Setup]({% post_url 2020-01-04-aws-iot-setup %})
* [NodeMCU Dev]({% post_url 2020-01-03-nodemcu-dev %})
* [Fire Emblem Lights]({% post_url 2020-01-14-fire-emblem-lights %})

My goal was to add the OTA and configurability from the [WLED](https://github.com/Aircoookie/WLED) project, and have it receive requests from AWS forwarding Google Assistant queries. This would certainly be possible, but it turned out that there were so many hurdles, I decided to take a much easier approach.

The first huge issue is that I hadn't realized that the ESP8266 in my door buzzer, was an old [Sparkfun Thing Dev](https://www.sparkfun.com/products/13711) which only has 512KB of flash to store your program. In fact I initially thought I bricked the board, and spent a lot of time getting it back to being programmable. [WLED](https://github.com/Aircoookie/WLED) can technically fit in this with most of it's features disabled, but I was still seeing it crash when it tried to start up, so it seems like the board would not be up for running a wider feature suite.

While I was doing this, I added the relay control functionality to [WLED](https://github.com/Aircoookie/WLED) as a usermod. Basically some code anyone can stick in to add functionality. Here's my [commit](https://github.com/Aircoookie/WLED/commit/0e82f2a02f49301ed21d2c07923596480258903f). I decided to use [Blynk](https://blynk.io/) as the easiest way to forward commands to the board. It basically does a lot of the same stuff as the AWS IoT, but much simpler and more limited. It's all managed through an app which isn't great, but keeps things simple. It's also free as long as you only have a very basic dashboard.

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/blynk_app.webp" alt="Blynk App">]({{ site.image_host }}/2020/blynk_app.jpg)

Since I couldn't use [WLED](https://github.com/Aircoookie/WLED) directly, I combined the user_mod I made with the old code into it's own [project](https://github.com/axlan/door-buzzer/). This was a bit quick and dirty, but I was getting tired of using process of elimination to figure out what would work on my board.

The second problem is getting Google Assistant to work for a hobbyist like me. You can create your own google assistant function at <https://console.actions.google.com/>, but this is more focused toward publishing. You can also make functions [discoverable by Google Home](https://developers.google.com/assistant/smarthome/concepts/local), but this isn't a complete feature yet, and I don't have a Google Home hub.

Fist I considered using [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm&hl=en_US), and Android automation app. Unfortunately, it can't be triggered by voice commands. Later I found [AutoVoice](https://play.google.com/store/apps/details?id=com.joaomgcd.autovoice&hl=en_US) which seems like it could do the job, but at this point I didn't want to deal with another app.

Instead I found <https://platform.ifttt.com/>. It allows you to create free applets for private use, and basically acts like glue logic between different web services. In my case I added a Google Assistant trigger with the voice commands I wanted, then had the resulting action be a call to a webhook. Initially this was the gateway to my AWS API. I realized using AWS for this was unnecessarily complicated at this point, since I could just call the device directly. Once I created the applet I could add it to my <ifttt.com> non-dev account which wires up the Google authentication.

To connect the pieces I found the [Blynk web API](https://blynkapi.docs.apiary.io/#reference/0/write-pin-value-via-put/write-pin-value-via-get?console=1) which gives you URLs to control the device. I ended up using `http://blynk-cloud.com/MY_AUTH_TOKEN/update/V9?value=1`.

Seeing that this API could also tell you if a device was connected, I decided to add a monitoring service. [UptimeRobot](https://uptimerobot.com/), can monitor a URL for free and notify you if there's a problem. I set it up to do a keyword monitor on `http://blynk-cloud.com/MY_AUTH_TOKEN/isHardwareConnected`. It alerts me if that URL doesn't return the string `true`.

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/uptime.webp" alt="uptime screenshot">]({{ site.image_host }}/2020/uptime.png)
