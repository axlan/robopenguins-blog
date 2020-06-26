---
title: Lying Game with React and Websockets 
author: jon
layout: post
categories:
  - Software
image: 2020/lying_game/vote_after_page.webp
---

With the current call for social isolation, online games have been a way to get some level of socialization. Since a lot of the people I want to play with aren't gamers, the [JackBox](https://jackboxgames.com/) games have been especially popular.

They have an interesting setup, where a screen shows the main informatino on a TV or computer, and everyone uses their phone as a controller. One limitation with this, is that if people aren't co-located, they can't see the main screen. You need to use a screen share in order to play. This is most likely to reduce the server cost with the graphics and audio and to tie the product more closely to the individual installs, making it harder to lend to a friend.

As an excercise in web developement, I decided to try to make a clone of one of their games [Fibbage](https://jackboxgames.com/fibbage/).

Here's the source code <https://github.com/axlan/jill_box>

Initially I wanted to make the backend in Rust, but I haven't had as much time lately, so I decided to just bang it out in Python to be able to make some progress.

Initially I coded the game logic without a UI, writing a test class to excercise the logic.

Next I played around with making the frontend as a Flask app, but eventually decided to make the frontend in React and connect it to the Python code over websockets.

I was pretty happy with both React and websockets. The I used both websockets and asyncio for the first time in Python, and I was impressed by the libraries. While I was able to create what I needed in React without too much trouble, it still felt fairly unwieldy to me. This is probably just trying to learn it as I went and not using best practices, but it seemed fairly difficult to keep organized in a sane and easy to change way.

Here's some screenshots:

Login:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/login_page.webp" alt="login">]({{ site.image_host }}/2020/lying_game/login_page.png)

Login failed:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/login_failed.webp" alt="login failed">]({{ site.image_host }}/2020/lying_game/login_failed.png)

Waiting room:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/waiting_room.webp" alt="waiting">]({{ site.image_host }}/2020/lying_game/waiting_room.png)

Entering a lie:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/prompt_page.webp" alt="prompt">]({{ site.image_host }}/2020/lying_game/prompt_page.png)

Preparing to vote:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/vote_before_page.webp" alt="voting before">]({{ site.image_host }}/2020/lying_game/vote_before_page.png)

After voting waiting for others:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/vote_after_page.webp" alt="voting after">]({{ site.image_host }}/2020/lying_game/vote_after_page.png)

Round score screen:
[<img class="aligncenter wp-image-373 size-medium" src="{{ site.image_host }}/2020/lying_game/results_page.webp" alt="results">]({{ site.image_host }}/2020/lying_game/results_page.png)
