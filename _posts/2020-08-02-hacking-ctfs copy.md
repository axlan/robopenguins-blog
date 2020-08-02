---
title: Dishonored 2 Jindosh Riddle
author: jon
layout: post
categories:
  - Software
  - Personal
image: 2020/dishonored-2-cover.jpg
---

I wrote a quick script to solve a logic grid puzzle in Dishonored 2. It probably would be a decent tool for solving arbitrary logic grid puzzles.

Dishonored 2 is a FPS that focusses on providing multiple potential solutions to reaching the games objectives. Typically, this is just stealth versus combat. At the end of each level the game tracks how much you are detected and how many enemies you kill:

[<img class="center" style="width:50%;" src="{{ site.image_host }}/2020/dishonorednonlethal9.webp" alt="dishonorednonlethal">]({{ site.image_host }}/2020/dishonorednonlethal9.webp)

To make taking the stealth approach more fun, the game structures the levels so there's some sort of mystery or puzzle you can solve to avoid most of the confrontations. This might be finding a ventilation shaft to stay out of sight, or setting off a chain of events that distracts the guards.

One area revolves around opening a door locked by a logic puzzle. If you actually want to play through the level, you don't need to solve the puzzle at all, since a character in the game will just give you the answer. In addition the puzzle is relatively easy to solve with brute force.

Here's a video of the puzzle along with the brute force solution:
<iframe width="1583" height="620" src="https://www.youtube.com/embed/d4c5bfSDvYk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

In addition it turns out the puzzle isn't really random. Apparently, the game does some simple word substitution, so you can look up the answer and [simply substitute in the words used in your run of the game](https://gamecrate.com/dishonored-2-how-solve-jindosh-riddle-and-lock-and-skip-most-dust-district/14960#comment-3033661119).

Despite all this, I thought it would be fun to write a program to solve the puzzle. I vaguely remember some elective CS course I'd taken that used this sort of problem as an introduction to [boolean satisfiability](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem) or a related analysis toolset. I wanted to see if my very quick and dirty approach would work.

Here's my version of the riddle:

> At the dinner party were Lady Winslow, Doctor Marcolla, Countess Contee, Madam Natsiou, and Baroness Finch. The women sat in a row They all > wore different colors and Countess Contee wore a jaunty white hat. Lady Winslow was at the far left, next to the guest wearing a red jacket. The lady in green sat left of someone in blue. I remember that green outfit because the woman spilled her wine all over it. The traveler from Dabokva was dressed entirely in purple. When one of the dinner guests bragged about her Bird Pendant, the woman next to her said they were finer in Dabokva, where she lived. 

> So Doctor Marcolla showed off a prized Diamond, crt which the lady from Dunwall scoffed, saying it was no match for her War Medal. Someone else carried a valuable Ring and when she saw it, the visitor from Fraeport next to her almost spilled her neighbor's absinthe. Baroness Finch raised her rum in toast. The lady from Karnaca, full of whiskey, jumped up onto the table, falling onto the guest in the center seat, spilling the poor woman's beer. Then Madam Natsiou captivated them all with a story about her wild youth in Baleton. 

> In the morning, there were four heirlooms under the table: the Bird Pendant, Snuff Tin, the War Medal, and the Ring. But who owned each? 

My approach was to have a map of every "trait" (the names, positions, drinks, etc. for each lady) and for each trait have a set of every possible other trait that it was possible to coexist with. I ended up organizing the sets into maps by category. From there I created functions to handle setting that a relationship between two traits was definite (ie. the lady in red was in the center), or impossible. I ended up having to also create a couple functions that would scan the current state and clean things up when I found a connection by process of elimination. This is probably not a particularly clean or efficient implementation, I didn't plan it out and figured it out as I was writing it.

Solving the puzzle was then just a matter of translating the written puzzle into these function calls.

The positioning hints gave me a couple issues with this approach. First, when a clue said someone was "to the left" of someone else it could mean they were immediately to the left, or could be separated by more then one seat. I initially tried the less restrictive interpretation, but ended up needing to assume they were next to each other. The other issue is that the functions I wrote can't easily encode the nuance of positioning. I solved this by encoding the constraints from the initial hints, running the program and adding additional constraints based on the remaining possibilities.

Ended up working pretty well:

```python
from collections import defaultdict
from typing import Set, Dict

# Set of traits for the clues
traits = {
    'names': set(['Winslow', 'Marcolla', 'Natsiou', 'Finch', 'Contee']),
    'positions': set(['Far Left', 'Left', 'Center', 'Right', 'Far Right']),
    'drinks': set(['Beer', 'Wine', 'Whiskey', 'Rum', 'Absinthe']),
    'cities': set(['Baleton', 'Dunwall', 'Karnaca', 'Dabokva', 'Fraeport']),
    'heirlooms': set(['War Medal', 'Bird Pendant', 'Ring', 'Diamond', 'Snuff Box']),
    'colors': set(['White', 'Green', 'Purple', 'Blue', 'Red'])
}

# Create a mapping of all possible traits
mappings: Dict[str, Dict[str, Set[str]]] = defaultdict(dict)
for cat, traits1 in traits.items():
    for trait1 in traits1:
        for trait2, items2 in traits.items():
            if trait2 == cat:
                continue
            mappings[trait1][trait2] = set(items2)

# Get the category of an trait
def get_cat(trait):
    for k, v in traits.items():
        if trait in v:
            return k

# Link two traits
def set_map(cat1, trait1, cat2, trait2):
    mappings[trait1][cat2].intersection_update(set([trait2]))
    for v in traits[cat1]:
        if v != trait1:
            remove_map(cat1, v, cat2, trait2)
    mappings[trait2][cat1].intersection_update(set([trait1]))
    for v in traits[cat2]:
        if v != trait2:
            remove_map(cat2, v, cat1, trait1)
    propagate_maps()

# Remove possible mapping between two traits
def remove_map(cat1, trait1, cat2, trait2):
    if trait2 in mappings[trait1][cat2]:
        mappings[trait1][cat2].remove(trait2)
    if trait1 in mappings[trait2][cat1]:
        mappings[trait2][cat1].remove(trait1)

# Check if results violate any constraints 
def check_valid():
    # all the items need to be present for each combination of categories
    for cat1, traits1 in traits.items():
        for cat2, traits2 in traits.items():
            if cat2 == cat1:
                continue
            tmp = set()
            for trait1 in traits1:
                tmp.update(mappings[trait1][cat2])
            if tmp != traits2:
                return False
    # There always needs to be at least one mapping for category for each item
    return all([ len(l) != 0 for l in mappings.values() ])

# If there's only one possibility for a map, link it
def set_map_cleared():
    for trait, maps in mappings.items():
        cat1 = get_cat(trait)
        for cat2, items2 in maps.items():
            if len(items2) == 1:
                set_map(cat1, trait, cat2, list(items2)[0])

# Once a match is found, the mappings are linked
def propagate_maps():
    for trait, maps in mappings.items():
        cat3 = get_cat(trait)
        for cat1, matches in maps.items():
            if len(matches) == 1:
                match = list(matches)[0]
                for cat2 in traits.keys():
                    if cat1 == cat2 or cat2 == cat3:
                        continue
                    mappings[trait][cat2].intersection_update(mappings[match][cat2])
                    mappings[match][cat2].intersection_update(mappings[trait][cat2])

# Print all the mappings
def print_results():
    for cat1, traits1 in traits.items():
        print(cat1)
        for trait1 in traits1:
            print(f'\t{trait1}')
            for cat2 in traits.keys():
                if cat2 != cat1:
                    print(f'\t\t{mappings[trait1][cat2]}')

# Enter the clues
set_map('names', 'Contee', 'colors', 'White')
set_map('names', 'Winslow', 'positions', 'Far Left')
set_map('positions', 'Left', 'colors', 'Red')
# Partial constraints for Lady in green left of lady in blue
remove_map('positions', 'Far Left', 'colors', 'Blue')
remove_map('positions', 'Far Right', 'colors', 'Green')

# Assuming immediate left
remove_map('positions', 'Far Left', 'colors', 'Green')
remove_map('positions', 'Center', 'colors', 'Blue')

set_map('drinks', 'Wine', 'colors', 'Green')
set_map('cities', 'Dabokva', 'colors', 'Purple')
# Partial constraints for bird pendant next to Dabokva
remove_map('cities', 'Dabokva', 'heirlooms', 'Bird Pendant')
set_map('names', 'Marcolla', 'heirlooms', 'Diamond')
set_map('cities', 'Dunwall', 'heirlooms', 'War Medal')
# Partial constraints for Fraeport next to ring next to absinthe
remove_map('cities', 'Fraeport', 'heirlooms', 'Ring')
remove_map('cities', 'Fraeport', 'drinks', 'Absinthe')
set_map('names', 'Finch', 'drinks', 'Rum')
set_map('cities', 'Karnaca', 'drinks', 'Whiskey')
remove_map('cities', 'Karnaca', 'positions', 'Center')
set_map('drinks', 'Beer', 'positions', 'Center')
set_map('names', 'Natsiou', 'cities', 'Baleton')

# After looking at results to apply bird pendant next to Dabokva
set_map('positions', 'Left', 'heirlooms', 'Bird Pendant')
# After looking at results to apply Fraeport next to ring next to absinthe
set_map('positions', 'Far Left', 'heirlooms', 'Ring')

set_map_cleared()
print_results()
print(f'valid: {check_valid()}')
```
