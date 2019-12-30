---
title: Sushi Go Arena
author: jon
layout: post
categories:
  - Software
image: 2019/sushi_go_gui.png
---

I made a framework for testing AI's made to play the card game "Sushi Go". Source at <https://github.com/axlan/sushi_go_ai> . It included a GUI to allow a human to play against an AI, and for playing back the gamestate from a recorded game.

# Background

I just got back from an extended vacation travelling the world. One thing we learned while travelling for months is that sometimes we needed some downtime to recover. Other times we would be stuck on transit for hours, or need to wait for some other reason. Eventually, with all this free time, I got the itch to do some programming.

Initially, I had some lofty aspirations to study some math or CS concept, but the time that I had was in bursts and wasn't necessarily conducive to studying. This project was a short achievable programming exercise to scratch an itch to make something.

The basic idea for building an arena like this came from this Youtube video about testing weird chess AI <https://www.youtube.com/watch?v=DpXy041BIlA>

# Sushi Go

Sushi Go is a fairly short and simple card game <https://gamewright.com/product/Sushi-Go> . The relative simplicity and mostly known information, made it seem like a simple starter AI project. The idea is that the players are taking turns grabbing items off of a sushi conveyor belt and want to get the best set of items possible. This is done by passing hands of cards around a circle and each playing a single card a turn. Different types of cards follow different scoring rules and may depend on getting sets of cards, or having the most of a cards among the players.

# Python Code

## sushi_arena.py

This is the main loop for running a series of games between AI and/or human players. Sushi Go is 2-4 players so this program takes the set of players as it's main argument. For instance:

`./sushi_arena.py -p rand1 rand2 human_cli`

Would start a series of games with 3 players. The AI's rand1 and rand2 along with a human player using a command line interface.

The results of this program are the stats of win rates between the players. For instance pitting the dumb AI rand1 against the slightly smarter AI minmax1 would produce the results:
```
           rand1_0  minmax1_1
rand1_0        0.0       85.0
minmax1_1     13.0        0.0
          rand1_0   minmax1_1
count  100.000000  100.000000
mean    40.970000   51.850000
std      7.261988    6.561866
min     23.000000   37.000000
25%     36.000000   48.000000
50%     41.500000   52.000000
75%     46.000000   56.000000
max     63.000000   68.000000
```
This shows that out of the 100 games between the AI's, minmax1 won 85% of the time. It's mean score was also about 10 points higher.

A dictionary at the top of the file maps AI names to the function that actually implements the logic for each AI. These are implemented in their own files.

## sushi_state.py

The code in this file encoded the rules of Sushi Go. It has classes for representing the game state, and for calculating the score. It also has functions for generating shuffled decks and dealing cards.

## playback_viewer.py

Each game played in the arena can have the gamestates serialized into a JSON file with the `-b` option. These JSON files can then be played back with the playback_viewer script.

[<img class="aligncenter size-large" src="{{ site.image_host }}/2019/sushi_go_gui.png" height="50%" width="50%" alt="" />]({{ site.image_host }}/2019/sushi_go_gui.png)

## ai_rand1.py

This file implements the simplest AI. The AI plays cards at complete random.

## ai_rand2.py

This is a slight improvement over ai_rand1. It still plays cards at random, but it knows to play 2 cards in a certain game state where that's allowed.

## ai_pref1.py

This is a factory for generating AI's that play at random, but have a preference for a particular card. For instance if you have a tempura card in hand play it, but otherwise play a random card.

## ai_minmax1.py

This is a very incomplete implementation of a minmax <https://en.wikipedia.org/wiki/Minimax> strategy for the game. Basically, the AI assumes the opponent will take actions that hurt AI the most. It then tries to maximize its score under this assumption.

## human_cli.py

This implements a command line interface for a human to play against the AI's in the arena.

## human_gui.py

This is a PyGame GUI for a human to play against the AI's in the arena. It basically uses the same interface as the playback_viewer.py
