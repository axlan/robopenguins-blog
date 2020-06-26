---
title: Outlaw Star Gillium II Clock
date: 2012-12-24T19:17:38+00:00
author: jon
layout: post
categories:
  - Hardware
  - Personal
image: 2012/12/2012-12-16-21.51.22-265x300.webp
---
My brother and I used to watch the anime Outlaw Star together as kids, so I decided to get him something based on the show as a gift this year. Being a relatively unpopular show that hasn&#8217;t been on the air in years, there was basically no merchandise available. So I decided to make my own. This is a clock made to look like the computer Gillium II from the show.

[<img class="alignleft size-medium wp-image-301" title="finished clock front" src="{{ site.image_host }}/2012/12/2012-12-16-21.51.22-265x300.webp" alt="" width="265" height="300" />]({{ site.image_host }}/2012/12/2012-12-16-21.51.22.jpg)  
Vs  
[<img class="alignleft size-full wp-image-305" title="gillum" src="{{ site.image_host }}/2012/12/gillum.webp" alt="" width="300" height="215" />]({{ site.image_host }}/2012/12/gillum.png)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

<!--more-->

Parts list:

  * Fruit Cake Tin &#8211; Any round tin would work for the enclosure, I got this one from the thrift store for 50 cents
  * Clock Radio &#8211; Something that is reasonably close to being able to fit in the tin. I also got mine from the thrift store for $3
  * Piece of Plastic &#8211; I bought a 11&#8243;x14&#8243; piece from home depot, for $4 making this the most expensive component

<div>
  The hardest part of this project was making the blank face of the clock. I should have spent more time trying to find a tin with a clear plastic front and saved myself a whole bunch of effort, but I ended up making one myself. First, I cut a large circle out of the top of the tin. Next I cut the piece of plastic into a rough circle that I could fit into the top of the tin and glued it into place.
</div>

Next I dissected the clock radio. Originally I was hoping to drive some blinking lights with some of the clocks circuitry, but it turns out that the clock that I found used a fairly interesting scheme for controlling the LEDs. The clock chip was a lm8560. The AC power coming in goes through a transformer which steps the voltage down to 20V peak-to-peak. As the power oscillates from +10 to -10 the controller switches which segments of the display are being powered. In any case I decided that I would leave well enough alone and concentrate on fitting the circuit into the tin.

The clock radio I used looked like this

[<img class="alignleft  wp-image-312" title="Digital-clock-radio-basic" src="{{ site.image_host }}/2012/12/Digital-clock-radio-basic.webp" alt="" width="600" height="400" />]({{ site.image_host }}/2012/12/Digital-clock-radio-basic.jpg)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

In order to fit the board into the tin I needed to rotate the display 90 degrees so that it faced upward. This meant that there was no way that I could reuse the original set of controls. I didn&#8217;t feel the need to preserve all of the radio and alarm functionality so I decided to make the only input the time setting controls.

[<img class="alignleft size-medium wp-image-304" title="inside clock" src="{{ site.image_host }}/2012/12/inside-clock-300x268.webp" alt="" width="300" height="268" />]({{ site.image_host }}/2012/12/inside-clock.jpg)

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

First I removed a four position switch that was used to change the alarm/radio mode and hard wired the connections to the position that disabled the alarm. Next I spent some time figuring out how the buttons on the original panned were used to set the time. This clock had the scheme where you hold down a &#8220;time&#8221; button and then press a minute or hour button. Turns out the time button just connected the hour and minute buttons to their common ground. I ended up wiring the switch so it would switch between no connections, and connecting the minute and hour inputs to ground so you could get the original controls but in switch form.

Before I mounted the clock circuit into the tin I desoldered some of the extra parts like the speaker and the original input circuitry. The clock circuit was just barely to big to fit, so I had to cut off some of the corners which fortunately didn&#8217;t contain anything important. I screwed the clock circuit back onto the plastic bottom of the clock which I cut down to a size that would fit. To put everything together I had to I ended up gluing the switch, cables, and circuitry in place with epoxy. I cut a little chunk out of the tin for the cable to fit through and bent back the metal so the cord wouldn&#8217;t be sitting on a sharp edge. With all the done the tins lid could still be taken off and on giving access to the inner side of the plastic and the clock circuitry.

I painted the colored parts of the clock face on the inside of the plastic, and doing the black sections on the outside with a sharpy. I&#8217;m sure there&#8217;s a better way since the paint I used could be easily be chipped off if it rubbed against anything sharp, but still it ended up looking pretty nice.  
[<img class="alignleft size-medium wp-image-302" title="finished clock side" src="{{ site.image_host }}/2012/12/2012-12-16-21.51.29-257x300.webp" alt="" width="257" height="300" />]({{ site.image_host }}/2012/12/2012-12-16-21.51.29.jpg)