---
title: Autonomous Drifting RC Car
date: 2012-04-08T21:05:03+00:00
author: jon
layout: post
categories:
  - Academic
  - Hardware
  - Reverse Engineering
image: 2012/CIMG0108-thumb.webp
---
  
As part of a project for the machine learning lab at Cornell, I did the hardware and some of the software to make a stock RC car autonomously drift though a track.

<iframe width="1506" height="663" src="https://www.youtube.com/embed/gukGtPFQltE?list=PL12E054C7D140E6BE" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

The microcontroller that drove the car from the remote control was put on a switch with an Arduino. The Arduino was connected to an XBEE wireless transceiver. The Arduino would process the sensor data and control the motors, relaying the information to a PC. The Arduino used a PID controller to navigate a pre-mapped course.

Here are some more pictures

<img src="{{ site.image_host }}/2012/CIMG0107.webp" />

<img src="{{ site.image_host }}/2012/CIMG0108.webp" />

<img src="{{ site.image_host }}/2019/DSCN1311.webp" />

<img src="{{ site.image_host }}/2019/DSCN1312.webp" />

<img src="{{ site.image_host }}/2019/DSCN1315.webp" />
