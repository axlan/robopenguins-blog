---
title: Printing Custom Magic Card Proxies With MPC
author: jon
layout: post
categories:
  - Personal
  - Magic the Gathering
image: 2021/mtg/misc_thumb.webp
---

After playing a game of Magic the Gathering with a friends kids, I decided to see if there was a way to get back in the game without taking out a second mortgage.

I've been playing Magic in some capacity since I was 10 years old. As a kid I just liked the big monsters and didn't really understand the rules. I started again a bit in college, where I learned enough to play properly with other peoples decks. After moving to SF I would occasionally play with some friends who had a game group or do drafts. I enjoyed the digital version of the game, Magic Arena, for awhile when it came out. I eventually quit because of the predatory pricing model.

I have a decent sized collection, but even with cards collected over two decades, I would need to buy new cards to have anything but the most casual deck. To get a lot of the fun interactions you either need multiples of cards, or a large set of synergistic cards. This would be difficult to collect without a lot of trading or shopping.

Aside from just playing the game, I was also interested in getting cards with custom art. I had heard of making "alters" of cards or proxies: <https://www.etsy.com/market/mtg_alter> . Recently, Wizards of the Coast (the makers of Magic) started selling small sets of cards with custom art as well.

So I set out in my search to get an affordable set of cards. I was looking either to make a [cube](https://magic.wizards.com/en/articles/archive/how-build/building-your-first-cube-2016-05-19) or a set of [commander decks](https://magic.wizards.com/en/content/commander-format).

### Update
I made a follow up article more focussed on making a deck with entirely custom art. I discuss a better pipeline for making cards with custom art there:
[Making a Custom Hellboy Magic Deck]({% post_url 2022-01-26-even-more-custom-mtg-cards %})

**Also, it's worth noting that MPC Autofill appears to have gone down and replaced by a fork.** Instead of the links mentioned in this article, the site is now hosted at <https://mpcfill.com/> and the most active github repo is <https://github.com/MrTeferi/mpc-fill>.

# Bootlegs

When looking to buy large sets of proxies, I first stumbled on <https://www.reddit.com/r/bootlegmtg/>. This subreddit mostly discusses the process of buying counterfeit cards from Chinese manufacturers. There are a bunch of sellers on Ali Express, as well as direct contacts. This is very blatantly illegal, so there's a lot of opaqueness around the sellers since they constantly need to make new listings as old ones are shut down. It appears you can get full sets, and extremely valuable rare cards at a fraction of the retail price but:

1. I Had no desire for the cards to appear official. I actually would prefer cards with non-standard appearance.
2. This required building knowledge and participating in a pretty shady marketplace.
3. It's not that cheap.

# Custom Printing

While I was searching I eventually found <https://www.reddit.com/r/mpcproxies/>. This subreddit is subtly different in that they don't want to make cards that could pass as official. They had lots of people showing large sets of good looking cards. Eventually, I realized that pretty much the universal source was the website <https://www.makeplayingcards.com/> (MPC).

MPC lets you make pretty much any kind of card, from small customizations to a standard poker deck, to completely custom cards of various sizes. They print out a sheet of cards on a selected paper stock, then cut them out (you can actually order the uncut sheets as well). Because of this, there are fixed sizes of decks you can order with the more cards the cheaper. You also get price breaks if you order multiple copies of the same deck, but that was less relevant for me. In the end I spent $130 to have 640 cards printed and shipped, or about $0.20 a card. I even considered printing full art basic land, but you can normal lands on Amazon for under $0.05/card if you're getting them in bulk and I didn't need the extra bling.

Using MPC isn't entirely straight forward. There are some guides online like <https://www.reddit.com/r/bootlegmtg/comments/7vgq9w/another_step_by_step_guide_for_mpccom/>, and the basic process is:
1. Choose images for all the card front and backs.
2. Make sure to size the images so that the boarders are big enough to ensure none of the card content is cut off.
3. Create a MPC order and upload all the card images.
4. Finish the order and select things like card stock, packaging, etc.

For a big order this would be extremely time consuming. You'd need to find 100's of high quality images, do the proper formatting, and spend hours manually dragging them into the MPC order. Fortunately, there's a better way.

## MPC Auto Fill

To streamline this whole process, a generous group of people have made a set of tools to automate these steps.

They provide the full source code at: <https://github.com/ndepaola/mpc-autofill>.

You start with <https://www.mpcautofill.com/> which has a web frontend to import and edit deck lists from the standards used by other MtG clients and deck tracking sites. It has a database of different art you can choose from for each card. Once you've made your selections you download an XML file for your order.

Next you need to download the desktop client <https://github.com/ndepaola/mpc-autofill/releases> to actual send the order to MPC. This is a Python script that runs a browser with [Selenium](https://www.selenium.dev/) automation. This will create the order, just like you would if you were doing it manually, but the mouse is controlled by the script, and it will go through the whole process of setting up your order.

While the auto fill tool worked perfectly I did hit a couple issues. The process of uploading the images for the 640 cards took about 4 hours, and I repeatedly had the MPC website hang when it would try to load the checkout page. Eventually, I ran mpc-autofill directly from the script so I could pause it to log in, and then to save the order when I was done to avoid this issue.

## Making Custom Cards

While the selection of cards and images on <https://www.mpcautofill.com/> is really good, a few of the newer cards were missing, and for some cards I wanted to use my own images. This [Youtube video](https://www.youtube.com/watch?v=zYAENUo-w4o) gives a guide for taking an image from a card database, and formatting it for MPC. MPC expects a certain amount of boarder to allow for inconsistencies in where exactly the card will be cut. I successfully followed this process and ended up with great looking cards. For example, MPC Autofille was missing the art for the card [The Biblioplex](https://scryfall.com/card/stx/264/the-biblioplex), so I downloaded the art and followed the video (using GIMP instead of photoshop) and wound up with:

[<img class="center" src="{{ site.image_host }}/2021/mtg/bilioplex_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/bilioplex.jpg)

MPC Autofill only had art I liked for a couple of the commanders I wanted to run. I started by looking for full card art alternatives. The challenge is that the image has to be pretty high resolution digital image, and there aren't that many of those for reasons I'd soon find out. Next I started looking into tools for making my own card designs.

* I'd seen <https://mtgcardsmith.com/> before, but it was pretty limited in allowing non-standard layouts.
* There was <https://artificer.app/> which is in a mobile beta. It seems promising, but being on my phone, and having a couple gaps in functionality (no hybrid mana on full art) made me keep looking.
* <https://magicseteditor.boards.net/> is a desktop client that has a huge array of templates and features, but seems to be limited to low resolution output.
* The best I found was the online editor <https://mtg.design/> which was a decent compromise of the complaints I had for the other tools, but still not near perfect.

Going with <https://mtg.design/> I still needed to actually make the cards. To do this I found images that were consistent with the theme of the commander and did minor edits.

For instance I used an [image](https://www.artstation.com/artwork/qaBYz) fairly directly for Lazav:

[<img class="center" src="{{ site.image_host }}/2021/mtg/lazav_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/lazav.png)

I did some moderate editing on [this](https://www.deviantart.com/zoestead/art/Steampunk-Girl-111336250) for braids:

[<img class="center" src="{{ site.image_host }}/2021/mtg/braids_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/braids.png)

And I combined two [images by PonkichiM](https://www.boredpanda.com/dog-cat-knights-art-ponkichi/) for Rin and Seri:

[<img class="center" src="{{ site.image_host }}/2021/mtg/rin_and_seri_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/rin_and_seri.png)

While all these cards came out fine, I think I'd change a few things in the future.
 * I tried to fit the `Full Art Promo` frame from <https://mtg.design/> into the boarder template, but I think I was a bit too conservative, and could have made the content a little bigger. You can see the boarder in the images above, and how they turned out at the end of the article.
 * While the text was readable, the text on Rin and Seri was a little blurry between the image behind the text and the small font size.
 * It would probably be worth making a higher DPI template to get closer to the quality of the other cards on MPC Autofill.

I didn't find out how the MPC-Autofill contributors were making their cards. It seems like it's probably something like the template shown off in [this video](https://www.youtube.com/watch?v=Stu6UBb8eEU). I'd probably try next time, my only concern is that the 700MB psd file seemed to be too much for GIMP. 

## My Order

I decided to go for value and get a max sized deck of 640 cards. I ended up mostly looking at <https://tappedout.net/> for deck list ideas, and ended up using <https://deckbox.org/> to have a searchable list of all the cards I was going to print. In retrospect, I probably should have just done that with a spreadsheet, since <https://deckbox.org/>'s search was slow enough to be annoying especially when I was trying to actually put together the decks.

Since I didn't order any basic lands, I was able to fit 7 commander decks into the order with a few cards left over for odds and ends. Using the MPC-Autofill website was super straightforward, though I mentioned the issues I had actually making the order above. I ended up needing to manually add my custom cards after the script was done, but once I managed to save my order on MPC, this was pretty easy.

I went with a nice Black Lotus card back so these are all unmistakeably proxies. When sleeved up, it's impossible to tell the "real" basic land cards from the "fake" printed cards by feel.

Here's some pictures of the results (click for bigger)!

The full stack:
[<img class="center" src="{{ site.image_host }}/2021/mtg/stack_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/stack.jpg)

A sample of C-D cards:
[<img class="center" src="{{ site.image_host }}/2021/mtg/card_sample_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/card_sample.jpg)

Some of the miscellaneous cards I through onto the end of the order:
[<img class="center" src="{{ site.image_host }}/2021/mtg/misc_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/misc.jpg)

The Commanders:
[<img class="center" src="{{ site.image_host }}/2021/mtg/commanders_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/commanders.jpg)

I intentionally left the companion text off Yorion, but accidently removed the `flying` keyword as well:
[<img class="center" src="{{ site.image_host }}/2021/mtg/typo_thumb.webp" alt="agent link">]({{ site.image_host }}/2021/mtg/typo.jpg)

So far it's been a lot of fun having a set of decks to cycle through and seeing a huge swath of what MtG has to offer. My wife and I have been working through the combinations and she even started a spreadsheet to track the match up favorability ranking.
