---
title: Site Moved to AWS / Jekyll
author: jon
layout: post
categories:
  - Software
---

I decided I should probably move my site to a less fragile platform. I've been using Wordpress on [000webhost](https://www.000webhost.com/). [000webhost](https://www.000webhost.com/) is fine for a free host, but about a year ago they started adding a few hours of downtime each day. I finally got around to dumping the contents of the site along with the database and exporting it to Jekyll. This turned out to be a bit more complicated then I hoped since I needed to stand up a whole local LAMP server to finally get [jekyll-exporter](https://wordpress.org/plugins/jekyll-exporter/) to work.

Jekyll has been pretty easy to work with, but since I didn't really want to check 100MB's of images into my github account, I decided to do a static site hosting in S3 [https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html) .

The contents of this site are now in GitHub!
[https://github.com/axlan/robopenguins-blog](https://github.com/axlan/robopenguins-blog)
