<h1 align='center'>Gold Funk'!</h1>

This is the another fork of Psych Engine 1.0.4 but this one has more than other forks (i guess)
Welp for now it doesnt but current target is making custom sofcode states and edit other states like Freeplay, MainMenu, etc.

Parts of engine was used in mods like:

[Brutal Pizdec Impotence DLC](https://gamebanana.com/mods/573827)

[That Song Again](https://gamebanana.com/mods/580609)

[I Hate This Mod](https://gamebanana.com/mods/582655)

## Installation:

Refer to [the Build Instructions](/docs/BUILDING.md)

## Customization:

If you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can refer to the `Project.xml` file.

Inside `Project.xml`, you will find several variables to customize Psych Engine to your liking.

To start you off, disabling *Video Cutscenes* should be simple, simply delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this: `<!-- YOUR_LINE_HERE -->`

Same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file.

## Credits:
* ROMA PEREC - Main Programmer of Gold Funk
* Shadow Mario - Creator of Original Psych Engine.

### Special Thanks
*later idk who to thank for now :/

***

(will be more added later)

# Features along with psych ones

Wip shit about whaa custom state whatever soon

## Changes in weeks (Warning, none of these are done but still planned to be)

### All weeks together
  * All events, recharts and other changes in stages from V-slice

### Tutorial:
  * Zoom tweens are in events instead of being hardcoded
  * Gf won't say "That's how you do it" if you messed up two times (Yea it just makes opponent vocals 0 volume yuppp)

### Week 1:
  * Dad uses icon with only one icon instead of two that identical to each other
  * Countdown in fresh changed to Fresh beatbox to return unused feature from LuddumDare
  * Bopeebo default camera zoom is 1 because uh... it fits..?

### Week 2:
  * Different way to use cheer and hey animations
  * A bit tweaked camera in Monster cutscene

### Week 4:
  * Remove henchmen kill event from Satin Panties and High cuz it's annoying there and doesn't fit so far
  * Gf uses duck animation when henchmen kill event happens

### Week 5:
  * BF sometimes plays HEY animation in Cocoa
  * Hud tweens alpha to "1" after monster starts singing

### Week 6:
  * Senpai in "Senpai" song uses DanceLeft and DanceRight animation system instead of default idle
  * BF plays HEY animation at the end of "Senpai" song

### Weekend 1:
  * Returns the unused newspaper prop
  * Blazin on hard is extended (it uses OST Version)