---
title: Custom Sound Board for Pixel Dice Using QPython
author: jon
layout: post
categories:
  - Hardware
  - Software
image: 2024/python-dice/py-dice.webp
---

Well the Pixels Dice KickStarter I supported like 3 years ago finally came in. I wanted to do something fun with them before I played my next TTRPG session, so I made a Rube Goldberg device to get 1's and 20's to play sound clips on my phone.

[Pixels dice](https://gamewithpixels.com/) are light up dice with an IoT component. They connect over bluetooth to report the value of dice rolls and control the LEDs.

There is a pretty good Android app, but it doesn't have much in the way of advanced capabilities. It can set up animations to respond to different dice rolls and trigger text to speech prompts, but that's about it.

They are working on additional features, but what I want is to have dice rolls trigger arbitrary "effects" (opening a door, lighting a fire, that sort of thing).

I figured a simple project would be to play a sound from a list of effects to celebrate critical success and failure.

Here's the demo:

<iframe width="1583" height="620" src="https://www.youtube.com/embed/oZFggJm8ZQ4" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

# Planning the Approach

The first thing to decide is what I would use to connect to the die.

Their github page <https://github.com/GameWithPixels> gives SDKs in several languages to connect to the die over Bluetooth. This is absolutely the way one should build a project with them if you want it to be reliable. However, I 
  1. Wanted to do this as quickly as possible.
  2. Didn't want to bring a laptop to the game.

The other way to get a custom integration is to use the web request effect in their official app.

This lets you post a json string with the die info including the roll, to an arbitrary URL. The drawback is that this only works if the die is connected to your phone and the app is running. This wouldn't be a big deal, but as far as I can tell, the dice app doesn't do any tricks to keep running in the background and will off be killed if it is out of focus for too long.

With the web request approach, I need a server somewhere to receive the request and trigger the effect. The easiest thing would be to run a small server in the cloud and control something also hooked up to the web. However, I to have the fewest moving parts, I wanted the server on my phone as well to be able to use the phone's speakers directly.

I explored a few options for this. On one end there are automation apps like Tasker and Automate. These could hypothetically work, but it would be stretching their "no code" capabilities pretty far.

The next thing I considered was running a Python based web server on my phone. I was vaguely aware there were apps that let you run Python, but I'd never done it before.

The capabilities I was looking for was
  • Could run a web server.
  • Could play a sound on the phone.

The top hits I came across we're Pydroid an QPython.

Pydroid seemed more focused on the IDE and learning experience, while QPython prominently advertised supporting a web server, so that's the one I decided to try.

Getting my proof of concept only took a few minutes. Since I hate typing I'm my phone, I was happy to see QPython had a built in FTP server. This let me use WinSCP to edit files directly with VSCode.

The built in QPython web server and Android interface were very straightforward, and everything pretty much just worked. Here's the quick and dirty proof of concept code I ended up with:

<https://gist.github.com/axlan/416ba0560db02552b700c8d49c6bc98c>

What I ended up spending time on, was trying to stop Android killing the apps if they weren't in the foreground. If I kept my phone awake and didn't use anything besides QPython, and the dice app, everything was pretty stable. But if I did anything else, or let the phone sleep, it would stop working and I'd need to restart the QPython script.

I spent a bit of time trying to fix this, QPython had a bunch of settings that claim to keep it running, but they didn't seem to work on my Android 14 pixel 5. I even looked at the background task developer settings, but nothing seemed to help. Generally, background tasks seem to need a persistent notification which these apps didn't offer.

Since this really doesn't need to be bullet proof I decided it was good enough, and recorded the demo.
