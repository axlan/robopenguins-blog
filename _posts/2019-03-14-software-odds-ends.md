---
title: Programming Odds and Ends
author: jon
layout: post
categories:
  - Software
image: 2019/pigsim.png
---

Here's a bunch of other old projects I dug up while updating the site that I'm throwing together into a pile. This time programming!

I really like the idea of video game development, but since I've never done it seriously, I don't have expertise with a specific platform. Over the years I've actually played around with a lot of different frameworks including Unity, pygame, libGDX, cocos2d, and probably a others I'm forgetting. I've mainly looked for the ease of integrating actual coding, and cross platform builds.

# LibGDX "Games"

## LibGDX Chess

What can I say? Chess is a good starter project for learning some 2D game dev. There's no AI, so you can just plan shared screen multiplayer.

<iframe width="560" height="315" src="https://www.youtube.com/embed/1nRo-ucrgkk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<https://github.com/axlan/libgdx-chess>

## LibGDX Pig

Very basic app for playing around with making an isometric sprite in a 3D drawing program. It simulates the basic Guinea pig behavior of running around randomly.

<iframe width="560" height="315" src="https://www.youtube.com/embed/UpfYPq4qV44" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<https://github.com/axlan/libgdx-pigsim>

## Time3D

This was a demo playing with the idea for a puzzle game where you first solve a 2D puzzle, that then uses the "time" you spent at each position to add a third dimension.

<iframe width="560" height="315" src="https://www.youtube.com/embed/TuVX_qIteIM" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<https://github.com/axlan/time3d>

# Web Apps

Aside from these little demo exercises, I've also done a few web app projects.

## Literary Chat

The first is a "chat" app where the participants feed in a text file as a [one time pads](https://en.wikipedia.org/wiki/One-time_pad) to encrypt the conversation. The idea is that as you type, you'd see the source text and know the other participant is seeing the same thing. You could use classics works of literature to encrypt your conversation. NOTE, this is obviously not a great design from a security stand point.

<https://github.com/axlan/literary-chat>

[<img class="aligncenter size-large" src="{{ site.image_host }}/2019/chat-window.png" height="50%" width="50%" alt="" />]({{ site.image_host }}/2019/chat-window.png)

Here's what the server sees:

```
client Alice created room TestRoom
client Bob joined room TestRoom
Alice sent msg ± to Bob
Bob sent msg ·¸wÇe»i­ÝÞ­ to Alice
Alice sent msg wÁe¶²{q-p³½³mtÁ°Ã_ to Bob
Bob sent msg eÜ
ºÊÐÉÜäØÉ-lr*£ÑÝ×Ê to Alice
Alice sent msg ©r¿­³jÃÄÁn£­q to Bob
Bob sent msg ÐÆÔ®ßÓËÓÌÕÎÍèäÌÚ@×ÛáÈÓ
                                   ØÒ
ÒâÚÎáÛÑç to Alice
Alice sent msg Yu+H³³ÆäØãçÛäãÝÈÖ to Bob
Bob sent msg eÐØÔàÑÐä
×Ú*ÅÉÏ×
ÏÕÉ to Alice
Alice sent msg vÀt*vx-~Ç² to Bob
Bob sent msg ¸ÔØÎ¶kí×ÞÌÙá@ÊØ¨
                             âËÆåéåÔ¢ to Alice
Alice sent msg °áZ@°ÊÛ Òè¥À MÀÔÕ
                                ²ÚÞÌÖ@ÕÜ
X©³Z@N ØÜQÜèGÀìçâ××ÐÍÙtkÂÌÏÛÃÎÏÙëÜÌãÚÓÛÓ to Bob
```

## Nightvale Puzzle

Here's another puzzle box style project I made. It pulls text from transcripts of the "Welcome to Nightvale" podcast, and redacts certain words. The player enters search terms in the faux terminal forked from <https://uni.xkcd.com/> to try to solve the puzzle

<https://github.com/axlan/nightvalue_puzzle>

[<img class="aligncenter size-large" src="{{ site.image_host }}/2019/nightvale-console.png" height="50%" width="50%" alt="" />]({{ site.image_host }}/2019/nightvale-console.png)
