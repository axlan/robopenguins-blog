---
title: How do computers work?
date: 2017-05-10T05:11:35+00:00
author: jon
layout: post
categories:
  - Personal
image: http://gria.org/wp-content/uploads/2017/09/silicon-chip.jpg
---
Awhile back my great aunt asked me for some resources on learning about computers. I&#8217;d thought I&#8217;d upload the conversation to save it for posterity.

<!--more-->

While I first understood the question to be about programming, after a few emails back and forth she clarified her interest:

> I realize that what I am looking for is to understand <u>how computers work</u> – the underlying mechanics/engineering – whatever &#8212; not to learn how to program or code.  I mean how all this information gets embedded – or whatever the term is – in a minuscule chip  &#8212; how it was possible to move from the room-filling contraptions that were the first computers into the hand-held devices that now can tie together the entire world – and beyond. How machines are able to respond to digitized instructions. What am I missing here?

I decided to spend an evening trying to figure out how to answer that question. It&#8217;s a pretty huge nugget to break down, but this was my take on it:

>  That&#8217;s an interesting angle to be approaching things. Computers have progressed to the point where very few people, even programmers could really describe how they work. A huge portion of engineering is about building mental abstractions to allow one to work with things without needing to know all (any of) the details. At the most fundamental level I&#8217;d break how a computer works into math and physics.
> 
> <div>
>   The physics is mostly about the design of semiconductors especially the transistor <a href="https://en.wikipedia.org/wiki/Transistor" target="_blank" rel="noopener noreferrer" data-saferedirecturl="https://www.google.com/url?hl=en&q=https://en.wikipedia.org/wiki/Transistor&source=gmail&ust=1494472960264000&usg=AFQjCNHGbmlxFwFgDbWykWR4ISytcZE4iw">https://en.wikipedi<wbr />a.org/wiki/Transistor</a> . While there are many other technologies that also come into play, the computation in a computer basically just comes down to these digital switches. Getting into the physics of the transistor is an area I learned in school, but hardly remember at this point. The main thing that I would try to understand, is how you go from the idea of a transistor to it&#8217;s mathematical representation of a logic gate <a href="https://en.wikipedia.org/wiki/Logic_gate" target="_blank" rel="noopener noreferrer" data-saferedirecturl="https://www.google.com/url?hl=en&q=https://en.wikipedia.org/wiki/Logic_gate&source=gmail&ust=1494472960264000&usg=AFQjCNF1q3LrqZ3myVTNEqX8QTDuXHbwKg">https://en.wikipedia.org/<wbr />wiki/Logic_gate</a> . The evolution of room sized machines, to modern phones, has fundamentally been an evolution of these gates to be smaller, cheaper and more efficient. This evolution is commonly described as Moore&#8217;s Law <a href="https://en.wikipedia.org/wiki/Moore%27s_law">https://en.wikipedia.org/wiki/Moore&#8217;s law</a> . The picture:
> </div>
> 
> <div>
>   <a href="https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Moore%27s_Law_over_120_Years.png/1024px-Moore%27s_Law_over_120_Years.png" target="_blank" rel="https://en.wikipedia.org/wiki/Moore%27s_law#/media/File:Moore%27s_Law_over_120_Years.png noopener noreferrer"><img class="alignnone" src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Moore%27s_Law_over_120_Years.png/1024px-Moore%27s_Law_over_120_Years.png" alt="" width="1024" height="719" /></a>
> </div>
> 
> <div>
>    shows how we&#8217;ve gone between different underlying technologies over the years to get to modern computers. In that picture, integrated circuits are the chips which are made of billions of individual transistors printed onto a silicon wafer. Advances in how this is done is what has contributed to most of the miniaturization and increased power of computers. The basics of the most ubiquitous technique are shown here
> </div>



> <div>
>   To leave the physics of what&#8217;s being built, the next level of abstraction are the logic gates as mentioned before. These gates are reasoned with using boolean algebra <a href="https://en.wikipedia.org/wiki/Boolean_algebra" target="_blank" rel="noopener noreferrer" data-saferedirecturl="https://www.google.com/url?hl=en&q=https://en.wikipedia.org/wiki/Boolean_algebra&source=gmail&ust=1494472960265000&usg=AFQjCNGEsXl7AZIASLpKcO1UzB3DGz-muA">https://en.wikipedia.org/wiki/Boolean_algebra</a> . The basic idea is that since we have these electrical switches, everything the computer &#8220;computes&#8221; is operating on this idea of on and off or 0 and 1. To extend this to numbers you can represent values and computation in binary <a href="http://www.math.grin.edu/~rebelsky/Courses/152/97F/Readings/student-binary" target="_blank" rel="noopener noreferrer" data-saferedirecturl="https://www.google.com/url?hl=en&q=http://www.math.grin.edu/~rebelsky/Courses/152/97F/Readings/student-binary&source=gmail&ust=1494472960265000&usg=AFQjCNHrTLkj92yo5Vx_teKKXaYzkGt7eg">http://www.math.grin.edu/~rebelsky/Courses/152/97F/Readings/student-binary</a> . This might be a bit complex, but it shows how you work through the logic and build more complicated computations from simpler pieces
> </div>



> <div>
>   Computers have a clock that triggers the circuits to feed data through step by step. They also have memory that can store the results for future calculations. You could dive into the physics of the oscillators that make up the clocks, or the various memory technologies, but at their core it&#8217;s the process of translating an electrical phenomenon into 1&#8217;s and 0&#8217;s. The logic in a computer is arranged so that it can take in a series of instructions <a href="https://en.wikipedia.org/wiki/Instruction_set" target="_blank" rel="noopener noreferrer" data-saferedirecturl="https://www.google.com/url?hl=en&q=https://en.wikipedia.org/wiki/Instruction_set&source=gmail&ust=1494472960265000&usg=AFQjCNEFUTonRKcGqOpvDjPerfTiwipEnQ">https://en.wikipedia.org/wiki/Instruction_set</a> and store the results. These instructions are incredibly basic arithmetic, logic, and controlling the selection of the next instruction. When you run a program on a computer it&#8217;s just an extremely complicated set of millions of these instructions.
> </div>
> 
> <div>
>
> </div>
> 
> <div>
>   Humans almost never interact with these instructions directly. We write &#8220;code&#8221; which is an &#8220;easy&#8221; way to represent what we want a computer to do which gets mapped to these basic instructions. Different programming languages are different attempts to make this mapping as efficient as possible. From there it&#8217;s mostly layer after layer of abstraction to make telling the computer what you want as easy as possible.
> </div>
> 
> <div>
>
> </div>
> 
> <div>
>   The input (mouse, keyboard) and output (screen, speakers) are electrically connected and have their interfaces mapped to 1&#8217;s and 0&#8217;s. These affect and are effected by the execution of instructions in the computer and translate the data from the digital world inside the chip, to something a human can interact with.
> </div>
> 
> <div>
>
> </div>
> 
> <div>
>   I found this video series decent in covering this information:
> </div>







> <div>
>   This is all tremendously complicated to understand in the abstract, and any of these ideas can be a whole university course. I most confidently understand the pieces of the computer I interact with on a regular basis, and most of the time I don&#8217;t need to think about anything lower level then the instructions that my code might be mapped to.
> </div>
> 
> <div>
>
> </div>
> 
> <div>
>   I find the fact that the human race has managed to create things of such complexity that work with such consistency amazing. They have been able to develop so rapidly because they support cooperation among engineers that allow millions of people to build on each others work. The fact that this all boils down to pretty basic logic allows people to use each others work unambiguously.
> </div>

<div>
</div>

<div>
</div>