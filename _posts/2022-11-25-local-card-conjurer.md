---
title: Running Card Conjurer Locally
author: jon
layout: post
categories:
  - Personal
  - Software
image: 2022/urzaBlank.webp
---

Unfortunately, the custom magic card creation tool Card Conjurer has been taken down by Wizards of the Coast. However, you can still use the tool if you run it locally.

After making my [Custom Hellboy Deck]({% post_url 2022-01-26-even-more-custom-mtg-cards %}) I was so impressed by by the site that I joined the creator's Patreon. Recently, he posted an update that Wizard's of the coast was taking legal action and he had to shutdown the site.

I had already set up the site to run locally, so I was starting to see if there was anything I could do to save the code, but I've had extremely little time lately so I was soundly beaten to the punch.

<https://www.reddit.com/r/magicproxies/comments/yyzfd5/how_to_run_cardconjurer_locally_on_windows/>
<https://github.com/MrTeferi/cardconjurer>

This is a Github repo with the website source along with the image files for the card boarders, symbols, etc.

Originally, you had to setup a PHP server to run it, and I was going to explain how to run it with a Docker command. However, the repos owner already vastly simplified the process so it's now pretty fool proof. I figure it's still worth adding a few details.

If anyone is curious, the way that the way the launchers work is that they're based on the Python script that runs the simple web server built into Python. This script is packaged for the various platforms using [PyInstall](https://pyinstaller.org/en/stable/#).

Also, since there's now an actual repo of source code, I submitted a PR for the modifcation I made to make using a large number of local images easier: <https://github.com/MrTeferi/cardconjurer/pull/2>
