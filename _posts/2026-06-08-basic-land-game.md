---
title: "Making the Basic Land Game"
author: jon
layout: post
categories:
  - Software
image: 2026/land_game/game_screen.webp
---

I made a digital version of the Basic Land Game. I built it over the course of about three, three-hour days using the free tier of several AI tools.

You can try yourself at <https://basic-land-game.robopenguins.com/>

[<img class="center" src="{{ site.image_host }}/2026/land_game/game_screen.webp">](https://basic-land-game.robopenguins.com/)

All code for this project can be found at <https://github.com/axlan/basic-land-game>

# Why Use AI Coding Assistance?

I recently learned about "The Basic Land Game". It's meant to encapsulate the feel of playing magic while being simpler and without collectable cards.

- [Blog Post Describing game](https://ultimateguard.com/en/blog/basic-land-game-rules-gameplay-strategy-magic-the-gathering-skura)
- [Video Introduction](https://www.youtube.com/watch?v=icr40GWNScQ)

I wanted to give it a try, and I was surprised no one had set up a digital version. It seemed like the kind of thing that would be pretty trivial to knock out.

What made me interested in making it myself, is that I thought I could design the backend very easily, but would need to slog through creating what would probably end up to be a very mediocre frontend. This seemed like the kind of thing an AI would be good at, so I figured I'd give it a try. It would give me a chance to first work on the infrastructure I was familiar with before taking the leap of face for a tech stack I didn't know at all.

The game has a lot of rules variations, so look at <https://github.com/axlan/basic-land-game> for the rule set I ended up using.

# The Process

I started off using Claude Sonnet 4.6 for the high level design.

I wanted Python for the backend and Claude suggested the FastAPI library with Phaser for the frontend. I had never used Phaser, but it seemed reasonable. 

To get started I wanted to generate something very well defined, that was in my wheelhouse. So I had Claude generate a game board class that encapsulates the game state and the valid actions that each player could make. I did this by creating a prompt describing the game rules and state to track and asking for a Python class that's agnostic to the input and output that will be added separately.

This makes it easy to unit test, and sets up a very clear interface for the API. The tradeoff is that this is probably less scalable since the shared state is a big python object, but for this project that shouldn't be an issue. In theory, this would also make tweaking the rules simple since they all live in this class fairly cleanly. Unfortunately, the UI ends up indirectly changing based on the rules quite a bit (which cards to target for example).

Claude got the majority of the logic working on the first try, but there were a few issues:

  - Bug where the plains effect wouldn't transition to the next state when used on islands. This let you draw infinite cards or lock up the game.
  - The revealed hand mechanic didn't work right since it would reset it at the end of the swamps effect. It also wouldn't show the cards returned by forest as revealed.
  - It misunderstood the rule I described for forests and allowed grabbing from either graveyard. 
  - It only allowed counters to be played against a land, it didn't allow countering counters.

The code was quite messy. I cleaned up some unnecessary state variables but gave up after I fully absorbed that it was basically a reasonable approach. I did appreciate the unit tests it generated, since it made editing the code myself much less daunting.

While I used AI to fix most of these problems, I got tired of iterating with it on the counter spell logic. I only realized this bug after I implemented the rest of the UI, so I had to make this change across the whole stack. It would eat up over half the Claude free session on each prompt, so I had to wait to retry. The first fix it tried was to add a dedicated second round for counter spells, but that wouldn't support a third counter. It then tried to dramatically overcompensate things which also increased downstream complexity. It probably took me an hour to fix, but I was much happier with the simplicity of my implementation.

Claude was able to  one shot the FastAPI wrapper. I just told it to wrap the game class and add a rudimentary lobby system. I didn't even bother checking this part, and it had no issue.

When it came to the frontend, I had the models infer the correct behavior from the API. This had some issues, so I think I should have spent more time crafting the prompt for the frontend covering more of the corner cases.

I tried to use Claude Haiku through copilot extension in vscode. This burned through month allotment of tokens only resulting in a very poorly designed frontend. The styling was terrible with lots of elements overlapping making basic testing a challenge.

Since I was waiting on the Claude quota to refresh, I tried the Google Antigravity CLI. It one shot the Phaser frontend MVP. It had a few bugs like:

- No way to reconnect or exit game.
- Graveyard wouldn't update after returning card with forest.
- Graveyard would only show the last card added.

However, since it kept the full project in context, the debugging process was much smoother than using the Claude website. I'm sure Claude code CLI would be similar, but there's no free tier.

I had a working MVP, but I had used up the monthly free Antigravity credits. 

I still had some features, so I tried ChatGPT, but found it completely useless. Even creating a project with the files uploaded, it would constantly loose context.

I mostly went back to Claude, but I would have to start a new chat session for each change, since it seemed to fill up it's context window and confuse the previous changes it had already made.

The feature that was most tedious was getting the display to support resizing for a phone display. Since this required keeping the full design in mind at once, it would end up with only some of the elements being updated. Claude was much better at adding/fixing features where the code was more isolated.
 
Each feature and fix became painful to use AI with, and I found myself doing more and more of the coding manually since it was easier than trying to capture the necessary context for the AI.

When it came to making a single player mode, I wrote the whole thing myself since I really didn't want AI code to increase the projects complexity.

# Conclusion

For generating code I understood, my feelings are mixed. I was able to get the initial version up and running very quickly. However, the code is much less readable or reusable then I'd like, so the speed up might be lost if it needed to be maintained. Since the code is more painful to understand, it encourages subsequent edits to be done with AI as well making a vicious cycle.

For code I'm unfamiliar with, I really got the slot machine feeling I've heard when people describe using AI. It was amazing when a good looking functional result popped out. However, since I couldn't clean things up, the AI would churn would reintroduce bugs, accumulating cruft, and not separate functionality logically. I have no idea how well architected it was and hit landmines constantly when adding additional features. I learned basically nothing about Phaser and am no better off for using it in the future.

Having the strict token limit did help me have discipline on using AI efficiently. I think it ended up looking way nicer than if I had done it myself and probably took half the time it would without AI (writing frontend is slow going for me). 

This game was slightly pushing what can easily be made within the free tier, but now I've set my expectations for the current crop of models. 

Using Google's antigravity felt much better than either free Copilot integration or the web chats. Even though they all had the full files for context, antigravity did a much better job at keeping everything in mind. This might just be showing me the value of a harness when using models. 

This project is pretty different from most I do since there's nothing weird or novel. I've heard it said that people who are most gung ho about AI just want a final black box with out needing to care how it's made. This kind of project is an example of that for me. 

While I made this pretty quickly, it took longer than I was expecting. As usual the last 10% took 90% the time. For better or for worse the AI use encouraged scope creep, mostly to raise the bar on the games usability. This will only be relevant if anyone plays it, so we'll see.
