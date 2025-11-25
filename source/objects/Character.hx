package objects;

import backend.animation.PsychAnimationController;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;

import backend.Song;
import states.stages.objects.TankmenBG;

typedef CharacterFile = {
	var animations:Array<AnimArray>;

	var image:String;
	var scale:Float;
	var sing_duration:Float;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var danceEvery:Int;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var vocals_file:String;

	var healthicon:String;
	var healthbar_colors:Array<Int>;
	var iconOffsets:Array<Float>;
	var iconScale:Float;
	var iconFlipX:Bool;
	var iconBlend:String;
	var iconFps24:Int;

	var updateCamera:Bool;

	var opponentArrows:Array<Array<String>>;

	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var flipX:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxAnimate
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var opponentNoteColor:Array<Array<String>> = [
		["0xFFC24B99", "0xFFFFFFFF", "0xFF3C1F56"],
		["0xFF00FFFF", "0xFFFFFFFF", "0xFF1542B7"],
		["0xFF12FA05", "0xFFFFFFFF", "0xFF0A4447"],
		["0xFFF9393F", "0xFFFFFFFF", "0xFF651038"]];

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var uninterruptableAnim:Bool = false; //because psych didnt have this already?????

	public var idleForce:Bool = false;

	public var dropNoteCounts(default, null):Array<Int>;

	public var loopedIdle:Bool = false;

	public var followCharacter:Bool = false;

	public var healthIcon:String = 'face';
	public var iconOffsets:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var iconScale:Float = 1;
	public var iconFlipX:Bool = false;
	public var iconBlend:String = '';
	public var iconFps24:Int = 24;

	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	public var defaultStringColor:Array<Array<String>> = [
		['0xFFC24B99', '0xFFFFFFFF', '0xFF3C1F56'],
		['0xFF00FFFF', '0xFFFFFFFF', '0xFF1542B7'],
		['0xFF12FA05', '0xFFFFFFFF', '0xFF0A4447'],
		['0xFFF9393F', '0xFFFFFFFF', '0xFF651038']];
	public var defaultPixelStringColor:Array<Array<String>> = [
		['0xFFE276FF', '0xFFFFF9FF', '0xFF60008D'],
		['0xFF3DCAFF', '0xFFF4FFFF', '0xFF003060'],
		['0xFF71E300', '0xFFF6FFE6', '0xFF003100'],
		['0xFFFF884E', '0xFFFFFAF5', '0xFF6C0000']];

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var jsonDuration:Float = 4;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var originalIconFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		anim = new animate.FlxAnimateController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);
		
		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}

		this.dropNoteCounts = findCountAnimations('drop'); // example: drop50
	}

	public function playInitAnimation()
	{
		if(danceIdle)
		{
			danced = !danced;

			if (danced)
				playAnim('danceRight' + idleSuffix);
			else
				playAnim('danceLeft' + idleSuffix);
		}
		else if(hasAnimation('idle' + idleSuffix))
		{
			playAnim('idle' + idleSuffix);
		}
	}

	function findCountAnimations(prefix:String):Array<Int>
	{
		var animNames:Array<String> = this.anim.getNameList();
	  
		var result:Array<Int> = [];
	  
		for (anim in animNames)
		{
			if (anim.startsWith(prefix))
			{
			  	var comboNum:Null<Int> = Std.parseInt(anim.substring(prefix.length));
			  	if (comboNum != null)
					result.push(comboNum);
			}
		}
	  
		// Sort numerically.
		result.sort((a, b) -> a - b);
		return result;
	}

	public function changeCharacter(character:String)
	{
		animationsArray = [];

		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'characters/$character.json';

		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
		if(skipDance) finishAnimation();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;

		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;

		scale.set(1, 1);
		updateHitbox();

		if(!isAnimateAtlas)
		{
			frames = Paths.getMultiAtlas(json.image.split(','));
		}
		else
		{
			frames = Paths.loadAnimateAtlas(json.image);
			//frames = FlxAnimateFrames.fromAnimate(Paths.getPath('images/' + json.image));
		}

		imageFile = json.image;
		jsonScale = json.scale;
		if(json.scale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		singDuration = json.sing_duration;
		jsonDuration = json.sing_duration; //for custom note duration
		flipX = (json.flip_x != isPlayer);
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = (json.flip_x == true);
		danceEveryNumBeats = json.danceEvery;
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		//icon
		healthIcon = json.healthicon;
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		iconScale = json.iconScale != null ? json.iconScale : 1;
		iconFlipX = (json.iconFlipX == true);
		iconOffsets = json.iconOffsets != null ? json.iconOffsets : [0, 0];
		originalIconFlipX = (json.iconFlipX != isPlayer);
		iconBlend = json.iconBlend;
		iconFps24 = json.iconFps24 != null ? json.iconFps24 : 24;

		followCharacter = json.updateCamera;
		
		//notes
		opponentNoteColor = (json.opponentArrows != null ? json.opponentArrows : (PlayState.isPixelStage ? defaultPixelStringColor : defaultStringColor));

		// animations
		animationsArray = json.animations;
		if(animationsArray != null && animationsArray.length > 0) {
			for (animation in animationsArray) {
				var animAnim:String = '' + animation.anim;
				var animName:String = '' + animation.name;
				var animFps:Int = animation.fps;
				var animFlipX:Bool = animation.flipX;
				var animLoop:Bool = !!animation.loop; //Bruh
				var animIndices:Array<Int> = animation.indices;

				if(!isAnimateAtlas)
				{
					if(animIndices != null && animIndices.length > 0)
						anim.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, animFlipX);
					else
						anim.addByPrefix(animAnim, animName, animFps, animLoop, animFlipX);
				}
				else
				{
					if(animIndices != null && animIndices.length > 0)
						anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop, animFlipX);
					else
						anim.addBySymbol(animAnim, animName, animFps, animLoop, animFlipX);
				}

				if(animation.offsets != null && animation.offsets.length > 1) addOffset(animation.anim, animation.offsets[0], animation.offsets[1]);
				else addOffset(animation.anim, 0, 0);

				if (animAnim == 'idle' && animLoop == true) loopedIdle = true;
			}
		}
		//trace('Loaded file to character ' + curCharacter);
	}

	override function update(elapsed:Float)
	{
		if(debugMode || anim.curAnim == null)
		{
			super.update(elapsed);
			return;
		}

		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
					if(!loopedIdle) finishAnimation();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
			if(!loopedIdle) finishAnimation();
		}
		else if(uninterruptableAnim && isAnimationFinished())
		{
			uninterruptableAnim = false;
			dance();
			if(!loopedIdle) finishAnimation();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			if(!loopedIdle) finishAnimation();
		}
		else if (getAnimationName().endsWith('-end') && isAnimationFinished())
		{
			dance();
			//finishAnimation();
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(getAnimationName(), false, false, anim.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing') && !getAnimationName().endsWith('-end')) 
			holdTimer += elapsed;
		else 
		{
			if(PlayState.SONG != null)
			{
				if(PlayState.SONG.swapPlayers && isPlayer)
					holdTimer = 0;
	
				if(!PlayState.SONG.swapPlayers && !isPlayer)
					holdTimer = 0;
			}
		}

		if (holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			if(PlayState.SONG != null)
			{
				if(PlayState.SONG.swapPlayers && isPlayer)
				{
					holdTimer = 0;

					var endAnimation:String = anim.curAnim.name + '-end';
					if (hasAnimation(endAnimation))
					{
						playAnim(endAnimation);
					}
					else
					{
						dance();
						if(!loopedIdle) finishAnimation();
					}
				}

				if(!PlayState.SONG.swapPlayers && !isPlayer)
				{
					holdTimer = 0;

					var endAnimation:String = anim.curAnim.name + '-end';
					if (hasAnimation(endAnimation))
					{
						playAnim(endAnimation);
					}
					else
					{
						dance();
						if(!loopedIdle) finishAnimation();
					}
				}
			}
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return (anim.curAnim == null);
	}

	var _lastPlayedAnimation:String;
	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return anim.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		anim.curAnim.finish();
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return anim.curAnim.paused;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		anim.curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?force:Bool = false)
	{
		if (!debugMode && !skipDance && !specialAnim && !uninterruptableAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(hasAnimation('idle' + idleSuffix))
			{
				playAnim('idle' + idleSuffix, force);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (uninterruptableAnim) //get fucked no anim 4 u
			return;

		specialAnim = false;
		anim.play(AnimName, Force, Reversed, Frame);

		_lastPlayedAnimation = AnimName;

		if (hasAnimation(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		//else offset.set(0, 0);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;

			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, animString:String)
	{
		anim.addByPrefix(name, animString, 24, false);
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	public override function draw()
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		super.draw();
		if(missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
		}
	}

	public override function destroy()
	{
		super.destroy();
	}
}
