package funkin.menus.options;

import funkin.game.objects.Character;
import funkin.utils.WindowUtil;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Detail Mode', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('VSync:',
			"If enabled, game will attempt to match framerate with your monitor.",
			'vsync',
			STRING,
			['OFF', 'ON', 'ADAPTIVE']);
		addOption(option);
		option.onChange = onChangeVsync;

		var option:Option = new Option('Full Optimization',
			"If checked, disables absolutely EVERYTHING from camera and leaves only interface, which is making much more optimization",
			'optimize',
			BOOL);
		addOption(option);

		var option:Option = new Option('Shaders', //Name
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker PCs.", //Description
			'shaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('GPU Caching', //Name
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.", //Description
			'cacheOnGPU',
			BOOL);
		addOption(option);

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?\nThis setting is mutually exclusive with Unlocked Framerate.",
			'framerate',
			INT);
		addOption(option);

		var option:Option = new Option('Unlocked Framerate', //Name
			"If checked, the framerate is unlocked.\nThis setting is mutually exclusive with FPS.", //Description
			'unlockedFramerate',
			BOOL);
		option.onChange = toggleOffCap; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 60;
		option.maxValue = 240;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		super();
		insert(1, boyfriend);
	}

	function toggleOffCap()
	{
		if (ClientPrefs.data.unlockedFramerate)
		{
			FlxG.updateFramerate = 0;
			FlxG.drawFramerate = 0;
		}
		else
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeVsync()
	{
		switch(ClientPrefs.data.vsync)
		{
			case 'OFF':
				WindowUtil.setVSyncMode(lime.ui.WindowVSyncMode.OFF);
			case 'ON':
				WindowUtil.setVSyncMode(lime.ui.WindowVSyncMode.ON);
			case 'ADAPTIVE':
				WindowUtil.setVSyncMode(lime.ui.WindowVSyncMode.ADAPTIVE);
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.unlockedFramerate)
		{
			FlxG.updateFramerate = 0;
			FlxG.drawFramerate = 0;
		}
		else
		{
			if(ClientPrefs.data.framerate > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = ClientPrefs.data.framerate;
				FlxG.drawFramerate = ClientPrefs.data.framerate;
			}
			else
			{
				FlxG.drawFramerate = ClientPrefs.data.framerate;
				FlxG.updateFramerate = ClientPrefs.data.framerate;
			}
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}
