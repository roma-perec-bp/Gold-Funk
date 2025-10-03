package flixel.system.ui;

import openfl.Assets;
#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
@:allow(flixel.system.frontEnds.SoundFrontEnd)
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	
	var _bg:Bitmap;
	
	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;
	
	/**
	 * The minimum width of the sound tray
	 */
	var _minWidth:Int = 80;

	var _defaultScale:Float = 2.0;

	/**The sound used when increasing the volume.**/
	public var volumeUpSound:String = "flixel/sounds/beep";

	/**The sound used when decreasing the volume.**/
	public var volumeDownSound:String = 'flixel/sounds/beep';

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	var volumeMaxSound:String;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		_bg = new Bitmap(getImage("images/soundtray/volumebox"));
		_bg.scaleX = 0.30;
		_bg.scaleY = 0.30;
		_bg.smoothing = ClientPrefs.data.antialiasing;
		screenCenter();
		addChild(_bg);

		_bars = new Array();

		var barTmp:Bitmap = new Bitmap(getImage('images/soundtray/bars_10'));
		barTmp.x = 9;
		barTmp.y = 5;
		barTmp.scaleX = 0.30;
		barTmp.scaleY = 0.30;
		barTmp.smoothing = ClientPrefs.data.antialiasing;
      	addChild(barTmp);
		barTmp.alpha = 0.4;

		var tmp:Bitmap;
		for (i in 1...11)
		{
			var bar:Bitmap = new Bitmap(getImage('images/soundtray/bars_$i'));
      		bar.x = 9;
      		bar.y = 5;
      		bar.scaleX = 0.30;
      		bar.scaleY = 0.30;
      		bar.smoothing = ClientPrefs.data.antialiasing;
      		addChild(bar);
      		_bars.push(bar);
		}
		//updateSize();

		y = -height;
		visible = false;

		volumeUpSound = 'Volup';
		volumeDownSound = 'Voldown';
		volumeMaxSound = 'VolMAX';
	}

	/**
	 * This function updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate sound tray thing
		if (_timer > 0)
			_timer -= (MS / 1000);
		else if (y > -height)
		{
			y -= (MS / 1000) * height * 0.5;

			if (y <= -height)
			{
				visible = false;
				active = false;

				#if FLX_SAVE
				// Save sound preferences
				if (FlxG.save.isBound)
				{
					FlxG.save.data.mute = FlxG.sound.muted;
					FlxG.save.data.volume = FlxG.sound.volume;
					FlxG.save.flush();
				}
				#end
			}
		}
	}
	
	/**
	 * Shows the volume animation for the desired settings
	 * @param   volume    The volume, 1.0 is full volume
	 * @param   sound     The sound to play, if any
	 * @param   duration  How long the tray will show
	 */
	public function showAnim(volume:Float, ?sound:openfl.media.Sound, duration = 1.0)
	{
		if (sound != null)
			FlxG.sound.load(sound).play();
		
		_timer = duration;
		y = 0;
		visible = true;
		active = true;
		final numBars = Math.round(volume * 10);
		for (i in 0..._bars.length)
			_bars[i].alpha = i < numBars ? 1.0 : 0;

		//updateSize();
	}
	
	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param   up  Whether the volume is increasing.
	 */
	@:deprecated("show is deprecated, use showAnim")
	public function show(up:Bool = false):Void
	{
		if (up)
			showIncrement();
		else
			showDecrement();
	}
	
	function showIncrement():Void
	{
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);
		var soundThing = null;

		if (FlxG.sound.muted)
			globalVolume = 0;

		if (globalVolume == 10)
			soundThing = getSound(volumeMaxSound); // Paths.returnSound('sounds/soundtray/$volumeMaxSound');
		else
			soundThing = getSound(volumeUpSound);

		final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
		showAnim(volume, silent ? null : soundThing);
	}
	
	function showDecrement():Void
	{
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);
		var soundThing = null;

		if (FlxG.sound.muted)
			globalVolume = 0;

		if (globalVolume == 10)
			soundThing = getSound(volumeMaxSound);
		else
			soundThing = getSound(volumeDownSound);

		final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
		showAnim(volume, silent ? null : soundThing);
	}
	

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _bg.width * _defaultScale) - FlxG.game.x);
	}

	function getImage(path:String):Dynamic
	{
		final imagePath = Paths.getPath('$path.png', IMAGE);
		#if MODS_ALLOWED
		return BitmapData.fromFile(imagePath);
		#end
		return Assets.getBitmapData(imagePath);
	}

	function getSound(path):openfl.media.Sound
	{
		final key:String = 'soundtray/$path';
		return Paths.returnSound('sounds/$key');
	}
	
	/*function updateSize()
	{
		if (_label.textWidth + 10 > _bg.width)
			_label.width = _label.textWidth + 10;
			
		_bg.width = _label.textWidth + 10 > _minWidth ? _label.textWidth + 10 : _minWidth;
		
		_label.width = _bg.width;
		
		var bx:Int = Std.int(_bg.width / 2 - 30);
		var by:Int = 14;
		for (i in 0..._bars.length)
		{
			_bars[i].x = bx;
			_bars[i].y = by;
			bx += 6;
			by--;
		}
		
		screenCenter();
	}*/
}
#end
