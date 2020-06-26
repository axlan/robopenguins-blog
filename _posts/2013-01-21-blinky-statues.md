---
title: Blinky Statues
date: 2013-01-21T23:09:08+00:00
author: jon
layout: post
categories:
  - Hardware
  - Personal
image: 2013/01/golem2-289x300.webp
---
Over the holidays I wanted to come up with a simple project that could be somewhat streamlined for &#8220;mass production&#8221;. I&#8217;ve always liked working with clay and decided to make figurines with some circuitry embedded in them. Of course the circuit had to be functional , so I decided to go with a simple breathing LED controlled with a 555 timer.

<iframe width="524" height="295" src="https://www.youtube.com/embed/-osvq248tfs" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

I&#8217;ve wanted to do a 555 timer project for awhile since they&#8217;re cheap and it&#8217;s been a long while since I&#8217;ve done a project with absolutely no programming. After looking at a few circuits online and messing around with the parts that I had on hand I ended up making the following schematic:

[<img class="alignleft size-medium wp-image-340" title="schematic" src="{{ site.image_host }}/2013/01/schematic-300x233.webp" alt="" width="300" height="233" />]({{ site.image_host }}/2013/01/schematic.png)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

The parts list is:

  * R1 &#8211; 47 ohm resistor
  * R2 &#8211; 4700 ohm resistor
  * C2 &#8211; 470 micro-farad capacitor
  * U1 &#8211; 555 timer
  * Q1 &#8211; BC547C NPN transistor
  * D1 &#8211; an LED
  * V1 &#8211; a 5 volt power source. I made some figures powered by 5V wall warts, and others I made USB powered.

<div>
  The circuit prototyped on the breadboard is shown below
</div>

[<img class="alignleft size-medium wp-image-334" title="breadboard" src="{{ site.image_host }}/2013/01/breadboard-300x178.webp" alt="" width="300" height="178" />]({{ site.image_host }}/2013/01/breadboard.jpg)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

Here&#8217;s a video of it in action



Once the circuit was tested and working I had to figure out how to stick it into a clay figure. As I saw it there were two options. I could build the circuit and then cover it in clay, or I could build the clay figure and then stick the components into it. I ended up having better luck building the circuit first, since it was easier to test that it was working before sticking it in the clay. To do this I soldered all the components together &#8220;dead bug style&#8221;. This entails soldering the components together without using any sort of circuit board as a base. Here are a few examples:

[<img class="alignleft size-medium wp-image-335" title="deadbug2" src="{{ site.image_host }}/2013/01/deadbug2-300x195.webp" alt="" width="300" height="195" />]({{ site.image_host }}/2013/01/deadbug2.jpg)[<img class="alignleft size-medium wp-image-327" title="deadbugwithusb" src="{{ site.image_host }}/2013/01/deadbugwithusb-300x175.webp" alt="" width="300" height="175" />]({{ site.image_host }}/2013/01/deadbugwithusb.jpg)[<img class="alignleft size-medium wp-image-325" title="deadbug3" src="{{ site.image_host }}/2013/01/deadbug3-300x181.webp" alt="" width="300" height="181" />]({{ site.image_host }}/2013/01/deadbug3.jpg)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

I then built the clay figures around these circuits taking care not to short anything. I used a cheap skulpty like material that dried in air without the need for a kiln. Initially, I found that the circuits would stop working when encased in clay. It appears that the wet clay is a weak conductor, and that these &#8220;shorts&#8221; were enough to prevent the circuits from functioning correctly. I even tried to encase the entire circuit in heat shrink and insulation, but not even that worked.

[<img class="alignleft size-medium wp-image-326" title="deadbug4" src="{{ site.image_host }}/2013/01/deadbug4-300x256.webp" alt="" width="300" height="256" />]({{ site.image_host }}/2013/01/deadbug4.jpg)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

It turned out that I just needed to be patient, after waiting about a week the clay dried and my figures worked perfectly. Here are a few more pictures and videos of the results.

[<img class="alignleft size-medium wp-image-328" title="golem2" src="{{ site.image_host }}/2013/01/golem2-289x300.webp" alt="" width="289" height="300" />]({{ site.image_host }}/2013/01/golem2.jpg)

[<img class="alignleft size-medium wp-image-329" title="golemfig" src="{{ site.image_host }}/2013/01/golemfig-223x300.webp" alt="" width="223" height="300" />]({{ site.image_host }}/2013/01/golemfig.jpg)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

[<img class="alignleft size-medium wp-image-330" title="groupback" src="{{ site.image_host }}/2013/01/groupback-300x196.webp" alt="" width="300" height="196" />]({{ site.image_host }}/2013/01/groupback.jpg)[<img class="alignleft size-medium wp-image-333" title="bearfig" src="{{ site.image_host }}/2013/01/bearfig-300x289.webp" alt="" width="300" height="289" />]({{ site.image_host }}/2013/01/bearfig.jpg)[<img class="alignleft size-medium wp-image-331" title="penguinfig" src="{{ site.image_host }}/2013/01/penguinfig-248x300.webp" alt="" width="248" height="300" />]({{ site.image_host }}/2013/01/penguinfig.jpg)[<img class="alignleft size-medium wp-image-332" title="quokkafig" src="{{ site.image_host }}/2013/01/quokkafig-201x300.webp" alt="" width="201" height="300" />]({{ site.image_host }}/2013/01/quokkafig.jpg)