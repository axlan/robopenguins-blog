---
title: K40 Laser Cutter
author: jon
layout: post
categories:
  - Hardware
image: 2019/IMG_20190217_180557-thumb.jpg
---
Maria got me a k40 laser cutter for my birthday!

It was surprisingly easy to set up considering it probably had a pretty rough trip from China. I just followed the guide [here](https://k40laser.se/lens-mirrors/mirror-alignment-the-ultimate-guide/) to align the mirrors and I was ready to go.

To control the laser, I used InkScape to make the designs and [k40 whisperer](https://www.scorchworks.com/K40whisperer/k40w_manual.html) to connect to the laser.

Here's some pictures of the results:

[<img class="aligncenter size-large wp-image-602" src="{{ site.image_host }}/2019/IMG_20190209_132852.jpg" alt="" />]({{ site.image_host }}/2019/IMG_20190209_132852.jpg)

This dice tower was based on [these](https://www.thingiverse.com/thing:2925474) designs

[<img class="aligncenter size-large wp-image-602" src="{{ site.image_host }}/2019/IMG_20190210_004212-COLLAGE.jpg" alt="" />]({{ site.image_host }}/2019/IMG_20190210_004212-COLLAGE.jpg)

[<img class="aligncenter size-large wp-image-602" src="{{ site.image_host }}/2019/IMG_20190217_180557.jpg" alt="" />]({{ site.image_host }}/2019/IMG_20190217_180557.jpg)

[<img class="aligncenter size-large wp-image-602" src="{{ site.image_host }}/2019/52670786_10156769236727559_9052057490908250112_o.jpg" alt="" />]({{ site.image_host }}/2019/52670786_10156769236727559_9052057490908250112_o.jpg)

# K40WebServer

While K40whisperer is a totally functional tool, I thought it would be useful to be able to have a dedicated network accessible computer to be able to remotely run prints on to avoid needing to bring the computer you're creating the image on over to the printer. K40whisperer has a pretty gnarly codebase so I was pleased to find an active project that exposed the functionality as an API.

I created [K40WebServer](https://github.com/axlan/K40WebServer) based on [remi](https://github.com/dddomodossola/remi) to get the basic functionality I was interested in. I may come back to this when I have a chance.
