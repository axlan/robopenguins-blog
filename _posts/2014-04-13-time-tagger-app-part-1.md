---
title: Time Tagger App (Part 1)
date: 2014-04-13T20:52:07+00:00
author: jon
layout: post
categories:
  - Software
---
I’ve wanted to document my work from start to finish on a project for a while, so I decided to try a screen capture program. I’ve used a bunch of different programs in the past, but I found that I had good luck with one called “[Open Broadcaster Software](https://obsproject.com/)”. It took a little playing with to get the settings reasonable, but I eventually got it working pretty well, and recorded myself setting up the environment and creating a very simple Pebble app:

<iframe width="524" height="315" src="https://www.youtube.com/embed/MfjH1_98GBY?list=PL9wcCpA0sWryxZYWOKbGSKEL4gREna-5Y" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

The sound quality started off pretty poor before I realized that having my microphone go through a KVM was affecting the sound quality.

My goal with the app was to create an easy way to do a little data collection about my daily routines. My initial goal was just to have a way to time my daily commutes to get a better sense of exactly how long it would take on average.

After making the app I realized there was a much better way to go about this. Instead of timing things on my watch, I could have the watch (or phone, or PC) record the time of events in some central database. This would allow me to find out things like when commutes tend to be fastest, or what activities I spend most of my time on. It would also let me divide the programming into 3 somewhat independent pieces. This follows the [Model–view–controller (MVC)](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) programming pattern. Basically, I can separate the development of the programs to record, store, and display the data.

There are a lot of options for developing an app like this. The easiest way for me would have been to write a PC application in C#. Visual studio makes GUI driven application extremely straight forward. However I wanted to start off with a web based interface. This would allow the application to be run from any platform.

I’ve never spent a lot of time writing web interfaces before, so I decided to go all out and write a [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) interface with an SQL backend. I had a tough time deciding on the development framework to use for the HTTP server. I could have used something like PHP, or Ruby on Rails, but I wanted something that could be easily deployed to any machine with minimal dependencies. Based on this I decided to use the web server functionality built into the standard Java Runtime (com.sun.net.httpserver.HttpServer). This means that the server can be run in any environment with Java installed. Eventually I may want to make a PHP version since that’s probably the most typical language supported by cheap web hosting.

I decided not to use the Google Web Toolkit or any other Java based framework to avoid needing to run a Java web server like TomCat. I decided to go with Netbeans as my IDE and use Git for version control. I still haven’t spent a ton of time with Git, so I’m using it for practice.

Speaking of technologies I’m not used to, I decided to use Maven to manage my external dependencies. Specifically I decided to go with SQLJet to provide SQL functionality to the server. I’ve found both SQLJet and Maven to be incredibly easy to work with.

Here&#8217;s the repo I&#8217;m currently working on: [https://github.com/axlan/timetagger](https://github.com/axlan/timetagger "https://github.com/axlan/timetagger")

I&#8217;ve already got the basics working, but now I need to actual make it usable.