---
title: Added SSL to Blog
author: jon
layout: post
categories:
  - Software
  - Blogging
image: 2020/ssl-certificate.webp
---

I finally decided to go through the hassle of setting this blog up with SSL. While normally this wouldn't be too hard with <https://letsencrypt.org/>, since I'm using S3 bucket based hosting, there wasn't a super simple option. The easiest path was to use Cloudfront to host the S3 files, instead of serving them directly. I followed the instructions in <https://medium.com/@channaly/how-to-host-static-website-with-https-using-amazon-s3-251434490c59> and after a few hours of trial and error (deploying to Cloudfront takes forever), eventually got it to work.

I then realized that a lot of the links generated by Jekyll were still HTTP, and so were some random images I was linking to. I had to hunt down those remaining references to finally get the little lock in the corner of the browser bar.
