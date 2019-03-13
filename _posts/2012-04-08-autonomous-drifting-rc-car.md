---
title: Autonomous Drifting RC Car
date: 2012-04-08T21:05:03+00:00
author: jon
layout: post
categories:
  - Academic
  - Hardware
image: 2012/CIMG0108-thumb.jpg
---
  
As part of a project for the machine learning lab at Cornell, I did the hardware and some of the software to make a stock RC car autonomously drift though a track.

<iframe width="524" height="295" src="https://www.youtube.com/embed/gukGtPFQltE?list=PL12E054C7D140E6BE" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

The microcontroller that drove the car from the remote control was put on a switch with an Arduino. The Arduino was connected to an XBEE wireless transceiver. The Arduino would process the sensor data and control the motors, relaying the information to a PC. The Arduino used a PID controller to navigate a pre-mapped course.

Here are some more pictures

<img src="{{ site.image_host }}/2012/CIMG0107.jpg" />

<img src="{{ site.image_host }}/2012/CIMG0108.jpg" />