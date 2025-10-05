package substates;

import backend.WeekData;

import objects.Character;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;

import states.StoryMenuState;
import states.FreeplayState;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend_death:Character;
	var camFollow:FlxObject;

	var stagePostfix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	//extra vars
	public static var removeCameraShaders:Bool = true;
	public static var removeBfShaders:Bool = true;
	public static var bg_alpha:Float = 1;

	public static var deathDelay:Float = 0;

	public static var instance:GameOverSubstate;
	public function new(?playStateBoyfriend:Character = null)
	{
		/*if(playStateBoyfriend != null && playStateBoyfriend.curCharacter == characterName) //Avoids spawning a second boyfriend cuz animate atlas is laggy
		{
			this.boyfriend_death = playStateBoyfriend;
		}*/
		super();
	}

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		removeBfShaders = true;
		removeCameraShaders = true;
		bg_alpha = 1;
		deathDelay = 0;

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
		}
	}

	var charX:Float = 0;
	var charY:Float = 0;

	var overlay:FlxSprite;
	var overlayConfirmOffsets:FlxPoint = FlxPoint.get();
	override function create()
	{
		instance = this;

		FlxTween.tween(PlayState.instance.camHUD, {alpha: 0}, 1);

		if (GameOverSubstate.bg_alpha != 1)
		{
			// Add a black background to the screen.
			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			bg.alpha = GameOverSubstate.bg_alpha;
			bg.scrollFactor.set();
			bg.screenCenter();
			add(bg);
		}

		if(boyfriend_death == null)
		{
			boyfriend_death = new Character(PlayState.instance.boyfriend.getScreenPosition().x, PlayState.instance.boyfriend.getScreenPosition().y, characterName, true);
			boyfriend_death.x += boyfriend_death.positionArray[0] - PlayState.instance.boyfriend.positionArray[0];
			boyfriend_death.y += boyfriend_death.positionArray[1] - PlayState.instance.boyfriend.positionArray[1];
		}
		boyfriend_death.skipDance = true;
		if (removeBfShaders) boyfriend_death.shader = null;
		add(boyfriend_death);

		FlxG.sound.play(Paths.sound(deathSoundName));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend_death.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(boyfriend_death.getGraphicMidpoint().x + boyfriend_death.cameraPosition[0], boyfriend_death.getGraphicMidpoint().y + boyfriend_death.cameraPosition[1]);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		add(camFollow);
		
		PlayState.instance.setOnScripts('inGameOver', true);
		PlayState.instance.callOnScripts('onGameOverStart', []);
		FlxG.sound.music.loadEmbedded(Paths.music(loopSoundName), true);

		if(characterName == 'pico-dead')
		{
			overlay = new FlxSprite(boyfriend_death.x + 205, boyfriend_death.y - 80);
			overlay.frames = Paths.getSparrowAtlas('Pico_Death_Retry');
			overlay.animation.addByPrefix('deathLoop', 'Retry Text Loop', 24, true);
			overlay.animation.addByPrefix('deathConfirm', 'Retry Text Confirm', 24, false);
			overlay.antialiasing = ClientPrefs.data.antialiasing;
			overlayConfirmOffsets.set(250, 200);
			overlay.visible = false;
			add(overlay);

			boyfriend_death.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				switch(name)
				{
					case 'firstDeath':
						if(frameNumber >= 36 - 1)
						{
							overlay.visible = true;
							overlay.animation.play('deathLoop');
							boyfriend_death.animation.callback = null;
						}
					default:
						boyfriend_death.animation.callback = null;
				}
			}

			if(PlayState.instance.gf != null && PlayState.instance.gf.curCharacter == 'nene')
			{
				var neneKnife:FlxSprite = new FlxSprite(boyfriend_death.x - 450, boyfriend_death.y - 250);
				neneKnife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
				neneKnife.animation.addByPrefix('anim', 'knife toss', 24, false);
				neneKnife.antialiasing = ClientPrefs.data.antialiasing;
				neneKnife.animation.finishCallback = function(_)
				{
					/*neneKnife.kill();
					remove(neneKnife);
					neneKnife.destroy();*/

					neneKnife.visible = false;
				}
				insert(0, neneKnife);
				neneKnife.animation.play('anim', true);
			}
		}

		FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.stageZoom}, 1, {ease: FlxEase.expoOut}); //if camera zoom on playstate was messed up, then reset to stage zoom

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		var justPlayedLoop:Bool = false;
		if (!boyfriend_death.isAnimationNull() && boyfriend_death.getAnimationName() == 'firstDeath' && boyfriend_death.isAnimationFinished())
		{
			boyfriend_death.playAnim('deathLoop');
			if(overlay != null && overlay.animation.exists('deathLoop'))
			{
				overlay.visible = true;
				overlay.animation.play('deathLoop');
			}
			justPlayedLoop = true;
		}

		if(!isEnding)
		{
			if (controls.ACCEPT)
			{
				endBullshit();
			}
			else if (controls.BACK)
			{
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.camera.visible = false;
				FlxG.sound.music.stop();
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.chartingMode = false;
	
				Mods.loadTopMod();
				if (PlayState.isStoryMode)
					MusicBeatState.switchState(new StoryMenuState());
				else
					MusicBeatState.switchState(new FreeplayState());
	
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
			}
			else if (justPlayedLoop)
			{
				switch(PlayState.SONG.stage)
				{
					case 'tank':
						coolStartDeath(0.2);
						
						var exclude:Array<Int> = [];
						//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];
	
						FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
							if(!isEnding)
							{
								FlxG.sound.music.fadeIn(0.2, 1, 4);
							}
						});

					default:
						coolStartDeath();
				}
			}
			
			if (FlxG.sound.music.playing)
			{
				Conductor.songPosition = FlxG.sound.music.time;
			}
		}
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;
	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.music.play(true);
		FlxG.sound.music.volume = volume;
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if(boyfriend_death.hasAnimation('deathConfirm'))
				boyfriend_death.playAnim('deathConfirm', true);
			else if(boyfriend_death.hasAnimation('deathLoop'))
				boyfriend_death.playAnim('deathLoop', true);

			if(overlay != null && overlay.animation.exists('deathConfirm'))
			{
				overlay.visible = true;
				overlay.animation.play('deathConfirm');
				overlay.offset.set(overlayConfirmOffsets.x, overlayConfirmOffsets.y);
			}
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function() //TO DO: INSTA RESTART IN GAME OVER AND PRB REWRITING THIS SHIT OMG
				{
					if(PlayState.SONG.swapPlayers)
						PlayState.instance.dad.stunned = false;
					else
						PlayState.instance.boyfriend.stunned = false;

					PlayState.instance.health = 1;
					//PlayState.instance.add(PlayState.instance.boyfriend);

					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						PlayState.instance.camOther.fade(FlxColor.BLACK, 1, true, null, true); //cuz hud
						FlxTween.tween(PlayState.instance.camHUD, {alpha: 1}, 1);
						FlxG.camera.fade(FlxColor.BLACK, 1, true, null, true);
						PlayState.instance.revivePlayer();
						PlayState.instance.boyfriend.playInitAnimation();
						PlayState.instance.dad.playInitAnimation();
						if(PlayState.instance.gf != null) PlayState.instance.gf.playInitAnimation();

						close();
					});

					//MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
