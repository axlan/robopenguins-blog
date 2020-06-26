---
title: Pong Clock
date: 2017-01-16T08:16:13+00:00
author: jon
layout: post
categories:
  - Electronic Art
  - Hardware
  - Software
  - Personal
image: 2017/01/DSCN0632-300x225.webp
---
Wow this is an old one. I&#8217;ve decided to go back and write up some of the first projects I did.

<iframe width="524" height="394" src="https://www.youtube.com/embed/XpvfNEkLs1g" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

The code and pictures of the final hardware are lost to time. The whole thing was suspended dead bug style in a plastic jar. I actually had to find an extra old monitor since the more modern one didn&#8217;t like the liberties I was taking in the name of shaving off clock cycles.

I did remember that I found a tutorial and actually contacted the creator and was happy to dig up those emails. I followed [http://www.pyroelectro.com/projects/vga\_test\_box/index.html](http://www.pyroelectro.com/projects/vga_test_box/index.html) though he now has write ups for the arduino and other systems as well.

In his words:

> The best advice I can give you is (after tweaking the hell out of the <span class="il">VGA</span> box to get it to work), don&#8217;t punish yourself and try to create a <span class="il">VGA</span> controller with a clock frequency <20MHz. The 640&#215;480 timing signals just weren&#8217;t created for it. Get a standard <span class="il">VGA</span> 27.175 MHz clock and make your life significantly easier.

I think I ended up punishing myself anyway.

Here&#8217;s some early test images and the board itself:  
[<img class="alignnone wp-image-503 size-full" src="{{ site.image_host }}/2017/01/vga_schem-e1484813729723.webp" width="658" height="311" srcset="{{ site.image_host }}/2017/01/vga_schem-e1484813729723.png 658w, {{ site.image_host }}/2017/01/vga_schem-e1484813729723-300x142.png 300w" sizes="(max-width: 658px) 100vw, 658px" />]({{ site.image_host }}/2017/01/vga_schem-e1484813729723.png)  
[<img class="alignnone size-medium wp-image-504" src="{{ site.image_host }}/2017/01/DSCN0632-300x225.webp" alt="" width="300" height="225" srcset="{{ site.image_host }}/2017/01/DSCN0632-300x225.jpg 300w, {{ site.image_host }}/2017/01/DSCN0632-768x576.jpg 768w, {{ site.image_host }}/2017/01/DSCN0632-1024x768.jpg 1024w" sizes="(max-width: 300px) 100vw, 300px" />]({{ site.image_host }}/2017/01/DSCN0632.jpg)

[<img class="alignnone size-medium wp-image-505" src="{{ site.image_host }}/2017/01/DSCN0633-300x225.webp" alt="" width="300" height="225" srcset="{{ site.image_host }}/2017/01/DSCN0633-300x225.jpg 300w, {{ site.image_host }}/2017/01/DSCN0633-768x576.jpg 768w, {{ site.image_host }}/2017/01/DSCN0633-1024x768.jpg 1024w" sizes="(max-width: 300px) 100vw, 300px" />]({{ site.image_host }}/2017/01/DSCN0633.jpg)

[<img class="alignnone size-medium wp-image-506" src="{{ site.image_host }}/2017/01/DSCN0640-300x225.webp" alt="" width="300" height="225" srcset="{{ site.image_host }}/2017/01/DSCN0640-300x225.jpg 300w, {{ site.image_host }}/2017/01/DSCN0640-768x576.jpg 768w, {{ site.image_host }}/2017/01/DSCN0640-1024x768.jpg 1024w" sizes="(max-width: 300px) 100vw, 300px" />]({{ site.image_host }}/2017/01/DSCN0640.jpg)

[<img class="alignnone size-medium wp-image-507" src="{{ site.image_host }}/2017/01/DSCN0641-300x225.webp" alt="" width="300" height="225" srcset="{{ site.image_host }}/2017/01/DSCN0641-300x225.jpg 300w, {{ site.image_host }}/2017/01/DSCN0641-768x576.jpg 768w, {{ site.image_host }}/2017/01/DSCN0641-1024x768.jpg 1024w" sizes="(max-width: 300px) 100vw, 300px" />]({{ site.image_host }}/2017/01/DSCN0641.jpg)