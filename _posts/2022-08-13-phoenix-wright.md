---
title: Phoenix Wright Reenactment of Alex Jones Trial
author: jon
layout: post
categories:
  - Personal
  - Software
image: 2022/trial/thumbnail_thumb.webp
---

After watching a clip from the insane Alex Jones Cross trial, I thought it would be funny to make a Phoenix Wright reenactment.

Unfortunately, by the time I had a chance to make this, I had been beaten to the punch. However, it was still fun to make. Here's my version.

<iframe width="1583" height="620" src="https://www.youtube.com/embed/uZz5V28u5H8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

I originally saw the clip on a humorous legal edutainment Youtube channel [Legal Eagle](https://www.youtube.com/watch?v=x-QcbOphxYs&t). What was nice was that this video had a manually generated transcript, including the clips from the trial. I was able to copy that from Youtube and make my own "script".

With the dialogue in a usable form, I needed to figure out how I wanted to do the animation. For the most flexible results I could have manually edited the sprites in a generic video editor, but I didn't have the time for that. This Wiki <https://aceattorney.fandom.com/wiki/List_of_Ace_Attorney_case_makers> has a pretty good list of some of the tools people made for doing this very thing. They vary a lot in features and some are more focussed on being able to make actual games. I ended up choosing <https://objection.lol/maker> since it had the right balance of features and ease of use for my taste.

I was now faced with the data entry challenge of copying my script into the [objection.lol](https://objection.lol/maker) GUI. As a programmer I of course balked at this and wrote a program to do it instead. [objection.lol](https://objection.lol/maker) is pretty slick and actually has a lot in common with the [Card Conjurer](https://cardconjurer.com/) site I used to make my [custom magic card deck](({% post_url 2022-01-26-even-more-custom-mtg-cards %})). [objection.lol](https://objection.lol/maker) has a import/export function that saves your "trial" to your local machine. However, it slightly obfuscates it's format by converting it with base64 encoding. I literally just copied and pasted the text from the saved file into <https://www.rapidtables.com/web/tools/base64-decode.html> to see that it was a fairly straightforward JSON format.

I made a simple script to generate the JSON for the frames from my transcript: <https://gist.github.com/axlan/426bf6cf54cb07629af6651a5bfc94c8>. This inserts the characters I chose for each of the "actors" along with their name and their dialogue.

I could have automated the base64 decode, JSON update, base64 encode, but this was a one off so I just manually updated and encoded the files.

With this imported into [objection.lol](https://objection.lol/maker). I was able to manually set the poses, music, actions, pauses, etc.

The only additional step I took outside of the GUI was to make the "evidence" to be presented as pop ups in the trial. I took screenshots of the evidence from the original video and fit them in pixilated boarders:

<img class="center" width="25%" src="{{ site.image_host }}/2022/trial/evidence.png">

<img class="center" width="25%" src="{{ site.image_host }}/2022/trial/website.png">

Once I was done, I just submitted my case and generated the video.

Here's my shared result on objection.lol: <https://objection.lol/objection/4165720>
