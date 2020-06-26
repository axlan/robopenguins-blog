---
title: Time Tagger App (Part 2)
date: 2014-04-27T15:17:53+00:00
author: jon
layout: post
categories:
  - Software
image: 2014/04/timetaggernewui.webp
---
After getting the most basic functionality working I realized I had hit a bit of a dead end. SQLJet was severely limited in how it could manipulate the data. I decided to take what I learned and start over. This time I decided to focus on the UI first, and then fill in the backend.

[<img class="aligncenter wp-image-423 size-full" src="{{ site.image_host }}/2014/04/timetaggernewui.webp" alt="timetaggernewui" width="476" height="428" />]({{ site.image_host }}/2014/04/timetaggernewui.png)

<!--more-->

Initially, I wanted to just swap out SQLJet and basically leave the Java code intact. I found HyperSQL <http://hsqldb.org/> which seemed like a good candidate. I then switched over to picking the framework I&#8217;d use to do the UI. I ended up putting so much of the logic into the Java script I realized that for this initial version, I didn&#8217;t even need a DB. I could capture the entire state as a simple JSON object.

I decided to start off by setting a reachable milestone for my current efforts. Instead of focusing on recording each time duration, I&#8217;d make an application that just tracked the total time spent on each category of activity. The initial UI would have:

  * Combobox with current categories and button to indicate that the activity has started.
  * Button and field to add new categories.
  * Table showing current ongoing categories along with button to stop
  * Table showing total and percent time for each category

One of the reasons I&#8217;ve disliked working with Javascript in the past, is the reliance on DOM manipulation to control the page behavior. Coming from a C++ background, markup languages have always been a bit frustrating for me to work with. I&#8217;m often especially frustrated when faced with 10 ways that seem like they would work, only to have none of them actually behave as I&#8217;d expect.

One of my coworkers suggested looking into AngularJS, and so far I&#8217;ve found that the best solution to my common complaints. As a novice at web development, working on a small project, I know that I typically only exercise a small piece of a framework. Even so I found that AngularJS provided a consistent set of tools to perform all of the UI processing I needed.

I decided to use IntelliJ Idea as my UI which worked out pretty well. I can&#8217;t say it blew NetBeans away, but it certainly performed better.

For learning Angular I mostly used:

<http://www.jetbrains.com/idea/webhelp/using-angularjs.html>

and

<http://www.revillweb.com/tutorials/angularjs-in-30-minutes-angularjs-tutorial/>

While there documentation is a bit sparse, it definetly gives at least a good idea of the frameworks capabilities.

I was able to get a version of the application that didn&#8217;t have any backend connections working pretty quickly. The limitation was that it could not persist if the browser window was closed, or it was accessed from a different location. I tried to reuse my HTTP server code, but I found that it actually would have issues when loading all the Javascript pieces. This made me decide to switch to JETTY. This worked out fine. While the server currently doesn&#8217;t do much aside from hosting the page, it could easily do a lot more.

In addition to JETTY, I grabbed another library to convert between JSON and Java objects. I found <http://www.mkyong.com/java/how-to-convert-java-object-to-from-json-jackson/> which gave a decent crash course but I had to read the first comment to realize the examples were incomplete.

I ended up deleting the original timetagger repo and starting from the ground up at the same address <https://github.com/axlan/timetagger>.

This got me to the point where I had accomplished what I set out to do. There are still a lot of pieces that I&#8217;d like to add to make it actually something I&#8217;d want to use:

Todo:

  * add automatic idle category when not engaged in other tasks
  * add better synchronization if using multiple clients (website accessed by different devices.)
  * add hierarchical categories
  * android app
  * multiuser
  * authentication
  * hooks to automatically log certain events like going to certain websites or running certain programs?
  * PHP/normal web hosting backend
  * Documentation
  * Pretty up UI
  * Add more precise event logging (start and stop of each event)
  * Add visualizations for more precise event logging (average commute time for each day of week/month of year, mean median mode etc.)

&nbsp;