---
title: Internet Cutoff Switch
author: jon
layout: post
categories:
  - Software
  - Hardware
  - Personal
image: 2020/pi_switch_box_thumb.webp
---

I had a really cool 3 position key switch that I've been trying to come up for a use for. I decided to make an IoT controller that could turn parts of the internet on or off.

I thought it would be neat to turn time wasting sites on or off with this very physical interface, or alternatively turn work related stuff (Slack, VPNs, etc.).

I got this switch while in an electronics market in Thailand. There were so many neat components, and I got this as a keep sake.

For the mechanism to control the internet, I initially went with [PiHole](https://pi-hole.net/). This is a relatively popular project mostly used for add blocking. You set it as your router DNS and it controls what domains will be blocked out. Unfortunately, it doesn't have great automation support. The API is read only so I needed to do something more complicated to allow IoT access. I explored 3 options:

	1. Create code to automate requesting changes through the web admin GUI site
	2. Create a new server on the same host as the PiHole to modify it's settings through the CLI
	3. Modify the source to add a richer API 

While none of these are ideal, I decided to go with 1. since it was the easiest and had the least moving parts. The downside is that this is fairly brittle to future changes to the web admin php interface, and it offloads some complexity to the client.

Since the logic To connect the IoT device to the PiHole was going to be a bit complicated I had to decide whether I wanted to make the requests directly, or add some sort of broker. I could used a cloud solution like Blynk or AWS IoT, but wanted to keep everything on my LAN. Once again I decided to just keep it simple and add all the logic to the client. This is a little annoying since it would mean modifying the IoT device to update the behavior, but it seemed a lot easier then adding additional servers.

Lately I've been using WLED as the base for my projects. It might seem a little weird since this doesn’t have LED's, but the killer features it brings are:
 * Nice persistent settings management
 * Really nice bootstrapping to set up networking config (falls back to ad hoc network)
 * Slick web UI
 * Handles OTA updates
 * Already integrated with many API's
 * Support for user mods to add features without needing to modify core functionality.

I had actually made a somewhat similar framework for my wreath project way back when [Pixel Wreath]({% post_url 2017-07-04-wreath-pixel-display %}), but it isn't nearly as slick or well tested. I haven't found any other library that offers this great base out of the box. It would be possible to make a fork that strips out everything else, but until I hit a resource limit, there isn't much point. 

I was able to pretty quickly get a Python script that could control the PiHole, and after a bit of finagling I was able to get it working on the ESP8266 <https://github.com/axlan/ArduinoPiHole>. However, I was hitting some annoying issues. Parsing the data requested from the PiHole interface would fail fairly regularly. The page is 25kB so I needed to read it in line by line, so I'm not sure if I was hitting some sort of timeout. Alternatively, I'm not sure if spending so long handling a request was causing the ESP8266 issues. I ended up just pointing my script at a different page (of similar size) and had things just work. I still got hung up a bit needing to handle encoding characters, but eventually I got it working. Unfortunately, it's extremely fragile and the only somewhat robust part (the Json parsing) uses relatively large amount of memory.

One tool I found particularly useful for debugging was tcpdump. I've had a few occasions to use Wireshark, but this was one of the first times I've used it's CLI brother. Mostly just SSHing into the PiHole server and running something like:

`sudo tcpdump -i eno1 -A '(dst 192.168.1.143 or src 192.168.1.143) and port 80'`

The next issue is that it's a bit annoying to have to configure a set of Blacklists on the device. I was already concerned that handling the Json describing the blacklists might use up too much memory. I would need to hard code the ID's for the blacklists instead of being able to reference them by their comment text. I looked into using the PiHole group policy which would be able to enable or disable a set of blacklists by enabling the group <https://docs.pi-hole.net/database/gravity/groups/>. The main problem here is that you need to manually add clients to a group, but it seemed easier to manage the clients that are being controlled on the web UI then having to have the client deal with multiple black list entries.

Finally as predicted integrating into WLED was a fairly painless process. Here's my fork with the full functionality <https://github.com/axlan/WLED/tree/pi_hole_ctrl>. Just needed to remember all the places I needed to add the new variables to get them to appear in the web UI. Doing a quick mock up mostly worked on the first shot, though I quickly realized I needed pull-down resistors.

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/IMG_20200828_171324_thumb.webp" alt="real life">]({{ site.image_host }}/2020/IMG_20200828_171324.jpg)

Awhile later I took the time to make an enclosure and add an indicator LED. I took this design https://www.thingiverse.com/thing:619365 and drilled out holes with a dremel. The LED is controlled by the normal WLED firmware.

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/pi_switch_box_thumb.webp" alt="switch box">]({{ site.image_host }}/2020/pi_switch_box.jpg)
