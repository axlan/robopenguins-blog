---
title: OKCompute Analysis Framework
date: 2018-09-11T01:21:43+00:00
author: jon
layout: post
categories:
  - Software
  - Work
image: 2018/09/example_full_graph.webp
---
As part of my work at <a href="https://www.swiftnav.com/" target="_blank" rel="noopener">Swift Navigation</a> I&#8217;ve done a lot of work analyzing the results of test runs and building CI frameworks to generate metrics or raise alarms based on the results. One of the challenges is that since the analysis is being performed on devices that are under development, they often create results that violate assumptions made by the analysis code. It can also be hard to trace through the analysis code and come up with the initial failure that led to a missing downstream result.

[<img class="aligncenter size-full wp-image-606" src="{{ site.image_host }}/2018/09/example_full_graph.webp" alt="" width="483" height="443" srcset="{{ site.image_host }}/2018/09/example_full_graph.jpg 483w, {{ site.image_host }}/2018/09/example_full_graph-300x275.jpg 300w" sizes="(max-width: 483px) 100vw, 483px" />]({{ site.image_host }}/2018/09/example_full_graph.jpg)

I made a generic framework to try to help with this sort of analysis.

<!--more-->

Here&#8217;s the presentation I gave originally within the company (Note some of this may be out of date from the actual documentation): 

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vQNYi2wGXEcIZswRGTg_zpnLl-SCUx6JvOfGHVIJH9KACJBXYIwC7dO99431dOtjLjrClQQLhVMmLBe/embed?start=false&amp;loop=false&amp;delayms=3000" width="960" height="569" frameborder="0" allowfullscreen="allowfullscreen"></iframe>

To see the code for yourself here:

<a href="https://github.com/swift-nav/okcompute" target="_blank" rel="noopener">GitHub Page</a>  
<a href="http://okcompute.swiftnav.com" target="_blank" rel="noopener">Documentation</a>

This was the most effort I&#8217;ve spent in documenting a piece of code. I use Sphinx to generate the static HTML pages, which I then host from an S3 bucket (See <https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html> ).