package;

#if !macro
//Discord API
#if DISCORD_ALLOWED
import funkin.api.Discord;
#end

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import funkin.menus.achievements.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

import funkin.Paths;
import funkin.data.Song;
import funkin.data.*;
import funkin.utils.*;
import funkin.menus.MusicBeatState;
import funkin.menus.MusicBeatSubstate;
import funkin.menus.transitions.CustomFadeTransition;

import funkin.backend.Conductor;
import funkin.game.stages.BaseStage;
import funkin.backend.Mods;
import funkin.backend.Language;

import funkin.backend.ui.*; //Psych-UI

import funkin.objects.Alphabet;
import funkin.game.objects.BGSprite;

import funkin.game.PlayState;
import funkin.menus.LoadingState;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;

//Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;
#end
