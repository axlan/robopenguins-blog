---
title: Unity Cat Stopwatch Game
author: jon
layout: post
categories:
  - Software
image: 2020/cat_game_pic.webp
---

I wanted to make a very basic game to get a bit more experience with Unity, so I made a game base on how our cat stakes out her food bowl to strike as soon as the auto-feeder goes off.

You can play the game [Here](https://www.robopenguins.com/assets/wp-content/pages/WatchedCatFood/)

The source code is available at <https://github.com/axlan/WatchedCatfood>

Picture of the inspiration:

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/cat_waiting_thumb.webp" alt="real life">]({{ site.image_host }}/2020/cat_waiting.jpg)

# Why Unity?

While there was a lot I liked about LibGDX which I used for my last game ([Fog of War]({% post_url 2019-12-17-fog-of-war-game %})), I decided to switch to Unity for my next game for two reasons:

 * Since it's so much more popular there's a lot more tutorials and answers to questions
 * As a major commercial effort it has a lot more polish

The last few times I've looked at Unity I had trouble getting over the learning curve. I was frustrated by the overall design that favored the GUI over code, spread logic and into many hard to trace pieces, and had abstractions meant to support 3D as well as 2D.

This attempt was pretty much the same. However, I found my experience really digging into game UI design in my last game gave me a bit more context to piece together what Unity was doing.

In making this game I wanted to really understand what I was doing. In order to complete this fairly basic game, I ended up working on the following skills:

 * Have dynamic text integrated into the scene
 * Understand how to control the ordering of sprites on the screen
 * Understand the basic static camera
 * Understand how the UI elements are drawn versus the objects "in the world"
 * The basics of how particle effects work
 * How to use the animator to do animated sprites and motion tweens
 * Get a better handle on how to organize the my scripts
 * Cleanly reference objects in my scripts without a lot of redundant strings
 * Understand how to deal with pixelated textures

# Pain Points

I initially tried to go off of one of the built in tutorials, but these had a lot going on, and didn't really start from first principles. I had more luck initially starting with this tutorial on making a version of snake <https://unitycodemonkey.com/video.php?v=Iz22-o7l6bc>. When I got to the point where I wanted to figure out how to make a dialogue box I used <https://github.com/Brackeys/Dialogue-System> for reference.

I hit a lot of little gotchas and pain points dealing with Unity. It's not really worth mentioning each one since they are very specific to what I was doing. Some points of particular frustration were:

 * Dealing with the layers and z value which determine the order objects are drawn on the screen and whether the camera will show them. It took a lot of fiddling to figure out how to control the UI versus the objects and some of this reflects that the framework isn't 2D focused. 
 * Another area that was a bit confusing was the game object system. It is both the best and worst part of Unity. It's great to be able to reference other objects so universally, but there's a lot of hidden magic in how these work. This is especially true as someone who prefers to focus on the code side of things. I liked the pattern from the snake game example of pulling all the references into a singleton object to make them compile time checks. This probably wouldn't work great when dealing with modular components. It's also a bit unclear what the best practice is in terms of which objects should be the parents of scripts, and which objects should be children of each other. This is a vague complaint and is probably more to do with my unfamiliarity than anything else. Learning good design practices would probably fix this, but the tool gives you such a flexible structure that it's easy to make a confusing mess.
 * I hit a lot of issues working with pixel art. Some obscure compression settings, and just a lot of challenges in where to control scaling and pixels per unit. This I think is mostly just that the default settings were not optimized for these kinds of assets.
 * I actually lost work a few times if I edited properties in the GUI while the game preview was running. This coupled with the non-human readable output files made me wish for a cleaner text based representation of some of these features. It's also not great that since all this configuration is so wrapped up in the IDE, the knowledge is not really transferable to other frameworks, and makes UI changes between versions particularly disruptive. If a button isn't in the right place, it's hard to figure out where that setting is now controlled. Also, it took awhile to figure out which windows were sensitive to selecting objects in other parts of the UI. For instance it took a while to realize that the animation window didn't care about an animation file you selected, but it did need you to select an object with a child animator.

# Positives

The animation system is pretty great. It's was great for both the sprite animation, and the motion tweens. Once I wrapped my head around a editing process that worked, it was very easy to get into a loop of quickly iterating and checking the effect of my changes.

The debugger "just worked". It was nice to be able to both use the code debugger in Visual Studio, while at the same time inspect the elements in the game through the Unity GUI.

My pixel art skills aren't great. I mostly used sprites I found on Google as a base and made minor tweaks. I was happy that I was able to use my experience with 9slice and create custom UI windows to look a little more pixelly. The flexibility of the sprite editor made this all very seamless once you get over the initial lack of discoverability.

[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/cat_game_pic.webp" alt="screen shot">]({{ site.image_host }}/2020/cat_game_pic.jpg)
