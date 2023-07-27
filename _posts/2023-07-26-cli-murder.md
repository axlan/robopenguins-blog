---
title: CLI Murder Mystery
author: jon
layout: post
categories:
  - Software
image: 2023/cli_murder.png
---

For old time's sake, I decided to do a quick write up of the cute "educational" mystery game that tests your Bash knowledge <https://github.com/veltman/clmystery>. This is very reminiscent of the previous game writeup: [SQL Murder Mystery]({% post_url 2019-12-29-sql-murder-mystery %}).

Since you're not given a limit on the CLI tools to use, this puzzle is a very open ended. I could write scripts or use all sorts of crazy tools. I tried to limit myself to only consider the most common tools.

Since walking through this puzzle is going to be revealing the answers I'd thought I'd start with a little review. As someone who's pretty confident using the CLI, it was fun to poke around and discover the structure of the puzzle. Actually "solving" it wasn't particularly hard, but with all complicated tool use, I did end up doing some Googling. After solving the puzzle, I looked at the hints, which recommended some simpler, but more manual approaches then I took.

I don't know if this would be particularly interesting for someone who isn't at least fairly comfortable with CLI tools. You don't really "naturally" learn skills aside from looking at the hints.

Probably the most interesting part of this puzzle is understanding why it's structured the way it is. The creator wanted to construct it in such a way that it would require at least some effort to solve, but wasn't too obtuse, or hard to put together.

# Spoilers Ahead!

# !!!!!!!!!!!!!!!

# !!!!!!!!!!!!!!!

# !!!!!!!!!!!!!!!

I spent most of my time just using `ls` and `less` to get a feel for how the directories and files were structured and figure out what the concrete goals were. 

The Puzzle starts by telling you to search for "CLUE" in a crime scene file. Easy enough:

```
> grep CLUE crimescene
CLUE: Footage from an ATM security camera is blurry but shows that the perpetrator is a tall male, at least 6'.
CLUE: Found a wallet believed to belong to the killer: no ID, just loose change, and membership cards for AAA, Delta SkyMiles, the local library, and the Museum of Bash History. The cards are totally untraceable and have no name, for some reason.
CLUE: Questioned the barista at the local coffee shop. He said a woman left right before they heard the shots. The name on her latte was Annabel, she had blond spiky hair and a New Zealand accent.
```

The first clue is a filter we can apply later.

The second clue tells us that we'll need to find a name that is in all four corresponding files in the `memberships` directory.

The last clue tells us that we need to lookup someone named "Annabel" for an interview.

I decided to start with the second clue. Finding duplicates is usually a job for `sort` and `uniq` and after Googling some of their flags I got:

`cat AAA Delta_SkyMiles Terminal_City_Library Museum_of_Bash_History | sort | uniq -c -d | grep 4`

to give the list of 23 suspects who had these 4 memberships.

With that down I went to CLUE 3.

```
> grep Annabel people 
Annabel Sun     F       26      Hart Place, line 40
Oluwasegun Annabel      M       37      Mattapan Street, line 173
Annabel Church  F       38      Buckingham Place, line 179
Annabel Fuglsang        M       40      Haley Street, line 176
```

Since "Church" seemed the most "New Zelandish", I went with that. After mangling the command a few times I eventually settled on `head -n 179 streets/Buckingham_Place | tail -n 1` for checking on a suspect. This forwards 
you to an interview file.

```
> cat interviews/interview-699607 
Interviewed Ms. Church at 2:04 pm.  Witness stated that she did not see anyone she could identify as the shooter, that she ran away as soon as the shots were fired.

However, she reports seeing the car that fled the scene.  Describes it as a blue Honda, with a license plate that starts with "L337" and ends with "9"
```

Finding the license plate in the `vehicles` file just took a `grep` call with a regex. I could chain them together to apply all the information I had. However, I noticed that `grep -A 5 ' L337.*9$' vehicles | grep "Make: Honda" -A 4` gave both teal and blue Hondas so I wasn't sure if teal counted as blue. 

Applying the remaining info on gender and height and cross referencing with the 23 suspects with the right memberships left 3 suspects.

```
> cat interviews/interview-290346 
Drives a similar car to the description.

Is a SkyMiles, TCPL, Museum of Bash History, and AAA member.

Bostock is 6' 4", easily tall enough to match the camera footage.

However, upon questioning, Bostock can prove that he was out of town on the morning of the murder, multiple witnesses and credit card transactions confirm

> cat interviews/interview-904020 
Maher is not considered a suspect.  Video evidence confirms that she was away at a professional soccer game on the morning in question, even though it was a workday.

> cat interviews/interview-9620713 
Home appears to be empty, no answer at the door.

After questioning neighbors, appears that the occupant may have left for a trip recently.

Considered a suspect until proven otherwise, but would have to eliminate other suspects to confirm.
```

Turns out the teal car owner had an alabi, and I guessed one of the other suspects gender incorrectly. That only left one suspect which I confirmed with their check command:

```
> echo "Jeremy Bowers" | $(command -v md5 || command -v md5sum) | grep -qif /dev/stdin encoded && echo CORRECT\! GREAT WORK, GUMSHOE. || echo SORRY, TRY AGAIN.
CORRECT! GREAT WORK, GUMSHOE.
```

This command is pretty interesting.

1. It figures out if your system has md5 or md5sum.
2. It MD5 hashes your guess.
3. It checks if that hash matches the contents of `encoded`.
4. Based on the match it prints the success or failure message. 
