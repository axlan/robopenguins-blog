---
title: Fog of War Game
author: jon
layout: post
categories:
  - Software
image: 2019/fog_battle.png
featured: true
---

I made a tactics game with a gimmick of espionage in the [LibGDX Java framework](libgdx.badlogicgames.com). This is probably the most complete game I've put together.

Here's a demo of current state:
<iframe width="560" height="315" src="https://www.youtube.com/embed/40V8IQZcXz8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

The repo is at <https://github.com/axlan/gdx_tactics>

# Background

After getting to a stopping point with my [last project](http://www.robopenguins.com/sushi-go-arena/), I decided I wanted to start something a little more ambitious. I have a long list of game ideas, and I semi-annually put together some part of a prototype or mockup. However, I've never tried to actually taken one to the point where I'd say it was in a "alpha" state of having actual graphics and being mostly playable. In addition on wanted to focus on making it somewhat maintainable and easy to design levels for.

I went to my list of ideas and took this one off the top since it didn't seem over ambitious, but still had some meat on it. The original idea I had written down was: "Guess shots game like battleship, but with Intel of varying reliability. Moral and civilians. Commander, or Intel chief?". This evolved into more of a puzzle game idea, which eventually morphed into something in the tactics genre like Fire Emblem, Into the Breach, or Advanced Wars. Advanced wars is even the source for most of the sprites.

I started programming the project in [PyGame](https://www.pygame.org/). I've come to appreciate the development speed that python provides, and I wanted to give PyGame a shot, after being happy with my brief use in my last project. I forked a repo off of another project that was working on a civilization clone <https://github.com/axlan/Conqueror-of-Empires/tree/fog_war> for a starting point. However, I realized that I was probably going to be spending a large amount of time on GUI layout, and PyGame lacks fully featured GUI features. After a week or so going down this path, I decided to switch to a different tool set.

The obvious choice was [Unity](https://unity.com/), but I haven't had great experiences in the past. 2D was a bit of a second class citizen, and it tended to be very "heavy weight" in that I would spend more time learning the framework then actually coding. I was nervous about this since I would be spending much of my time with limited internet. I ended up going with [LibGDX](libgdx.badlogicgames.com) since it seemed to be the most feature complete of the alternative free frameworks, and I was relatively comfortable with it. I feel like the main cost of this decision is that it will be harder to get other contributors to the game in the future.

# Game Status

I implemented these high-level features for this alpha writeup:

  * Tactical map to engage in battle
  * Campaign menu to connect individual battles
  * Add win and loss mechanic to give the game a goal
  * Dialogue screen for story and instructions
  * Menu for deploying troops
  * Menu for buying resources
  * Basic functional enemy Ai
  * Playable in Android
  * UI with custom skin
  * Save/load to work for campaign or battles
  * Configuration for specifying units and maps
  * Packing and animating sprites

I kept a [journal](https://github.com/axlan/gdx_tactics/blob/master/DEV_JOURNAL.md) of what I was working on, and what obstacles I hit.

Initially, I wanted to target Desktop, Android, and HTML5, but I found that the HTML5 was being generated using [Google Web Toolkit](http://www.gwtproject.org/) which limited the Java features and libraries I could use. By the time I tried the HTML5 build it would have been too large a refactor so I decided to drop it as a target.

I'm not planning on taking things further unless I find other contributors. With the basic functionality in place, a lot of the work to go from an alpha, to a complete game would be refining the UI, generating the content, and making real assets.

# Code Overview

LibGDX projects are Gradle based, and define builds for the different platforms you're targeting. The vast majority of the code is shared between targets and is in <https://github.com/axlan/gdx_tactics/tree/master/core/src/>. I divided the code into two top level packages [gdxtactics](https://github.com/axlan/gdx_tactics/tree/master/core/src/com/axlan/gdxtactics) and [fogofwar](https://github.com/axlan/gdx_tactics/tree/master/core/src/com/axlan/gdxtactics).

## gdxtactics Package
The gdxtactics package has code that's somewhat generic and could be useful for a variety of tactics games. It contains classes for things like:
* Drawing maps, and animated sprites
* Loading configurations
* Reducing UI boilerplate
* Calculating ranges and paths
* Generic Java data structure utilities
This code does not reference the fogofwar package at all.

## fogofwar Package
This package actually implements the game. The Core class has it's entry point, and handles transitioning between screens. The rest of the logics is divided between the following packages:
* campaigns - code that provides content for a specific campaign (dialogue, items, enemy placement, etc.)
* logic - data processing code that doesn't fall into another category (AI, range calculations)
* models - classes that encode information about the game state and properties. This also includes some logic for loading and saving the game.
* screens - classes involved with the GUI and drawing things on the screen. **This accounts for the vast majority of the project code.**

The game game can be understood at a high level as a set of somewhat independent views. The Core class puts one of these views on the screen at a time and gives a callback to trigger when it's time to move to the next screen. There is a shared state that keeps track of any persistent information.

Here's the state diagram of how the game moves between the views:
[<img class="aligncenter size-large" src="{{ site.image_host }}/2019/Fog_Game_Screen_States.png" alt="State machine for game screens" />]({{ site.image_host }}/2019/Fog_Game_Screen_States.png)

# Assets Pipelines

One goal I had going into this project was that it would be designed in a way that would make adding levels, units, and other content as easy as possible.

The assets for the project can be found in <https://github.com/axlan/gdx_tactics/tree/master/android/assets>

Early on I tried to make as much of the configuration as possible specified in JSON files that are serialized at startup into Java classes. I did this using the [Gson](https://github.com/google/gson) library. I used this to specify settings, unit information, and even the game state used in saving and loading.

I initially encoded the descriptions of the levels this way too, but soon hit the issue that a decent amount of logic needed to be included (logic for choosing enemy deployment, win conditions, etc.). While I think the best solution would be to expand the configuration file specifications, and maybe add some Lua script or something, I decided that for the alpha I would capture this in an abstract java class <https://github.com/axlan/gdx_tactics/blob/master/core/src/com/axlan/fogofwar/campaigns/CampaignBase.java>. The full specification for the tutorial campaign is in <https://github.com/axlan/gdx_tactics/blob/master/core/src/com/axlan/fogofwar/campaigns/TutorialCampaign.java>

In addition I made use of three 3rd party tools.

## GDX Texture Packer

[GDX Texture Packer](https://github.com/crashinvaders/gdx-texture-packer-gui) takes a bunch of image files and packs them together into a single image and an atlas to the individual elements. It supports indexing the frames of an animation and it's how I made the sprite sheets for the units.

## Tiled

[Tiled](https://www.mapeditor.org/) is a visual map editor for laying out sprite based levels. I used it to lay out both the campaign map as well as the map used for battles. It lets you set attributes on tiles which I used to specify tiles that couldn't be move through. It also lets you add invisble shapes and information which I used to specify the connections between cities.

Here's a test campaign map I created along with the invisible city names and paths between cities:

[<img class="aligncenter size-large" src="{{ site.image_host }}/2019/fog_map.png" height="50%" width="50%" alt="Tiled map example" />]({{ site.image_host }}/2019/fog_map.png)

## Skin Composer

[Skin Composer](https://github.com/raeleus/skin-composer) is a tool for customizing UI elements. While it had some issues handling the UI package I was using, it made designing a UI much easier then it would be manually. It also includes a [gallery](https://ray3k.wordpress.com/artwork/) which I borrowed from heavily.

This tool is also a texture packer it takes a set of images and packs them together along with a description to be loaded in the game. The raw images and project file are in <https://github.com/axlan/gdx_tactics/tree/master/skin_composer/custom>
