---
title: Version Control Game
date: 2017-05-08T02:14:20+00:00
author: jon
layout: post
categories:
  - Personal
  - Software
image: 2017/05/start-1-300x230.png
---

I often get ideas to make games, but rarely have the time needed. I had an idea for a game mechanic based on version control, and thought it would be a good candidate for a small demo.

Source code here: <https://github.com/axlan/VersionControlGame>

[<img class="aligncenter size-medium wp-image-543" src="{{ site.image_host }}/2017/05/start-1-300x230.png" alt="" width="300" height="230" srcset="{{ site.image_host }}/2017/05/start-1-300x230.png 300w, {{ site.image_host }}/2017/05/start-1-768x589.png 768w, {{ site.image_host }}/2017/05/start-1-1024x786.png 1024w, {{ site.image_host }}/2017/05/start-1.png 1031w" sizes="(max-width: 300px) 100vw, 300px" />]({{ site.image_host }}/2017/05/start-1.png)

<!--more-->

The idea was for a puzzle game in which the state of the game could &#8220;committed&#8221; and then multiple commits could be &#8220;merged&#8221; in order to solve the puzzle. The game I made involved 4 UI elements:

  1. The yellow game screen that shows a commit to consider merging with. This is view only.
  2. The magenta game screen that shows the current state. Moving the character around updates this view.
  3. The box with the merge button and the radio box that selects what action will be performed by clicking on a node in the graph
  4. The graph of states. Each movement adds a commit to this view. Based on the action selected in the radio box click on a node will: 
      1. Show it in the yellow view
      2. Select it in the magenta view
      3. Delete it

When a previous state is selected, moving will cause a branch.

When a branch is being viewed, and another is selected pressing merge will start a process of combining the two states. The player is prompted to select the elements of each state that should be use to &#8220;resolve the conflicts&#8221;

The particular level I made using the tool Tiled. I wrote a simple pseudo scripting language to describe how objects on top of buttons controls the doors.

I decided to use Cocos2d-x as the engine since it has multi-platform support and seemed to have less abstraction from the code then Unity which I&#8217;d briefly used in the past. It also had a focus on 2D which made things a little simpler for my needs. I was pretty happy with the framework, though it turned out the android code generation had some hiccups for me. I did most of my development in Visual Studio, and mostly ran it on a Windows machine

It seems like the Android SDK had changed some of the command line tools and Cocos2d-x was still adjusting. In the end I managed to get things to build for the android simulator and my phone, but I didn&#8217;t go through the effort of getting everything to sensibly fit on the smaller screens.

See the video below for a short demo on how branching and merging can be used to get to an end goal