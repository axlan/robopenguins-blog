---
title: Webcomic Viewer
date: 2012-03-22T22:37:45+00:00
author: jon
layout: post
categories:
  - Android Apps
  - Software
image: 2012/03/webcomicviewer.webp
---
This was another app made to add a specific function I couldn&#8217;t find elsewhere. This apps purpose is to view the title text associated with an image. Specifically for webcomics where there is an additional punchline in this text.  

[Google Play Link](https://play.google.com/store/apps/details?id=com.robopenguins.webcomicviewer)

[<img class="alignleft size-thumbnail wp-image-73" title="webcomicviewer" src="{{ site.image_host }}/2012/03/webcomicviewer-150x150.webp" alt="" width="150" height="150" />]({{ site.image_host }}/2012/03/webcomicviewer.png)

The webcomic viewer uses a webview to render the page. When a page loads It caches the HTML content of the page. On a touch event it checks to see if an image is touched and if so it searches the cached HTML for title text associated with the image. It then displays the text if found at the bottom of the screen.

## ToDo:

  * Add a favorites list and integrate it with the autocomplete search box.
  * Add user generated comic suggestions
  * Use javascript instead of regex for finding title text, or HTML parser
  * Add optimized loading for select comics be able to turn on and off(user suggested?)