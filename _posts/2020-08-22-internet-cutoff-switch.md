---
title: Internet Cutoff Switch
author: jon
layout: post
categories:
  - Software
  - Hardware
  - Personal
image: 2020/pi-logo.svg
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

I had actually made a somewhat similar framework for my wreath project way back when INSERT LINK, but it isn't nearly as slick or well tested. I haven't found any other library that offers this great base out of the box. It would be possible to make a fork that strips out everything else, but until I hit a resource limit, there isn't much point. 

I was able to pretty quickly get a Python script that could control the PiHole, and after a bit of finagling I was able to get it working on the ESP8266 <https://github.com/axlan/ArduinoPiHole>. However, I was hitting some annoying issues. Parsing the data requested from the PiHole interface would fail fairly regularly. The page is 25kB so I needed to read it in line by line, so I'm not sure if I was hitting some sort of timeout. Alternatively, I'm not sure if spending so long handling a request was causing the ESP8266 issues.

Things got worse when I got to the stage where I was trying to parse the JSON responses. Even for the ~300 byte response, my initial approaches gave memory errors pretty consistently. I should have a decent amount of memory, something like 4kB for a stack and 30kB heap, but it looked like I would need to be much more careful with how I was handling memory, and actually dig a lot deeper into how the HTTP library worked. Since I was manually managing cookies and headers anyway it might make more sense to go from the TCP level.

Rather then go down this rabbit hole, I decided to step back and reassess.

