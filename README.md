Instespeak in high level speech processor.  It functions like Siri.  You speak a command, and instespeak will do something with that command and speak feedback to you.

For example:
[You] What is the temperature?
[Instespeak] The current temperature is $some_temperature and the wind chill is $some_windchill degrees.


What was the purpose of this program?
Insteon is a company that produces home-automation devices.  Things like turning lights and outlets on and off from your phone, or on a schedule.
My goal was to use my voice to give commands like "Computer, turn off lights".  Much like how characters in Star Trek could interact with their environment.

I have two major challenges:
1.  I could not find an easy way to interface my program with Insteon.  There is an API for Insteon, but it's somewhat expensive and I'm still not confident there would be an easy way to interface with it.  However it's been a couple years now, so perhaps there have been enhancements that are worth checking out.

2.  Speech-to-text isn't perfect.  The trick is to find key words that the software (CMU Sphinx) can reliably figure out nearly 100% of the time. 
    Finding key words requires a little creativity, but even at that it's still difficult to get it working for general usage.    


How does this work?
There are 2 major components.  speech-to-text, and text-to-speech.  Speech-to-text is very complicated.  Text-to-speech is somewhat more simple, so I'll describe that
first.

For text-to-speech, I am using a program called Festival.  Festival works like this:
`echo "Hi there, how are you? | festival --tts`

The computer will then speak in a voice "Hi there, how are you?".



Ok that was simple enough.  Now let's talk about speech-to-text.
The question is, how can we take speech and convert it into text to a computer can run it?  Well the folks over at Carnegie Mellon have a solution!
It's called CMU Sphinx.  In particular, I'm using a specific port called Pocket Sphinx.

Pocket sphinx runs in a loop, and prints a lot of output, but in particular it prints one line of what it thinks you said.  It's not perfect,
but for the purposes of this program, it's what we need. 

So instespeak.pl is what will get all of this started.  But now I have a subcomponent of speech-to-text, where I am using Apache OpenNLP where
NLP stands for Natural Language Processing.

What OpenNLP does, is to take a sentence, and it breaks it up into the different parts of speech (like nouns, verbs, etc).

The goal was to develop a system that detects different parts of speech, and to do various things depending on the type of speech.

I didn't really get this concept fully baked out, as it's very complicated.  But essentially what I did was to look at the type of speech
returned by OpenNLP, and then run various modules based upon what it returns.

So to fully run this, there are essentially 2 daemons.  The first is instespeak.pl, and the second one is the java PosTagger class for tagging.
