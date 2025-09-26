package states.stages;

import states.stages.objects.*;

class MallEvil extends BaseStage
{
	override function create()
	{
		var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
		add(evilTree);

		var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
		add(evilSnow);
		setDefaultGF('gf-christmas');
		
		//Winter Horrorland cutscene
		if (isStoryMode && !seenCutscene)
		{
			switch(songName)
			{
				case 'winter-horrorland':
					setStartCallback(winterHorrorlandCutscene);
			}
		}
	}

	function winterHorrorlandCutscene()
	{
		camHUD.alpha = 0;
		camNotes.alpha = 0;

		inCutscene = true;

		FlxG.sound.play(Paths.sound('Lights_Turn_On'));
		game.currentCameraZoom = 1.5;
		game.tweenCameraToPosition(400, -2050, 0);

		// blackout at the start
		var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackScreen.scrollFactor.set();
		add(blackScreen);

		FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween) {
				remove(blackScreen);
			}
		});

		// zoom out
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			game.tweenCameraZoom(1, 2.5, false, FlxEase.quadInOut);
			new FlxTimer().start(2.5, function(tmr:FlxTimer)
			{
				FlxTween.tween(camHUD, {alpha: 1}, 2);
				FlxTween.tween(camNotes, {alpha: 1}, 2);
				camHUD.visible = true;
				startCountdown();
			});
		});
	}
}
