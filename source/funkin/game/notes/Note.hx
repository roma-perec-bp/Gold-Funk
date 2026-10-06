package funkin.game.notes;

import funkin.backend.animation.PsychAnimationController;

import funkin.graphics.shaders.RGBPalette;
import funkin.graphics.shaders.RGBPalette.RGBShaderReference;

import funkin.graphics.shaders.ColorSwap;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String,
	value3:String,
	value4:String,
	value5:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'GF Sing (Colored)',
		'Autoplay Note'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var dadNote:Bool = false; //i had to make this because opponent skins did not worked properly, there is might be easier way but for now...
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var canChangeRGB:Bool = true;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;
	public var released:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;
	public var badassed:Bool = false;

	public var customSingTime:Float = 0;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var sustainType:String = ''; //[stutter, freeze, nothing]
	public var ghostType:String = '';
	public var heyAnim:String = '';
	public var invisibleNote:Bool = false;
	public var autoplay:Bool = false;

	public var isInvisible:Bool = false; //used for skip time feature

	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	//public var eventVal1:String = '';
	//public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];

	var _colorSwap:Null<ColorSwap> = null;
 	var colorSwap(get, never):ColorSwap;

	function get_colorSwap():ColorSwap
	{
		if (_colorSwap == null) _colorSwap = new ColorSwap();
	
		return _colorSwap;
	}

	// Per-song dedupe set for hitsound precaching. set_noteType used to
	// call Paths.sound(hitsound) for every note that referenced a custom
	// hitsound -- with hundreds of notes per chart that's hundreds of
	// string formats + Map.exists checks + localTrackedAssets pushes
	// for the same handful of unique sounds. PlayState resets this on
	// create() so memory doesn't accumulate across songs.
	public static var precachedHitsounds:Map<String, Bool> = new Map();

	public var inEditor:Bool = false;
	public var inTestEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var colored:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var quantStepManiaColors:Array<Array<FlxColor>> = [
		[0xFFE51919, 0xFFFFFF, 0xFF5B0A30], // 4th
		[0xFF193BE5, 0xFFFFFF, 0xFF0A3B5B], // 8th
		[0xFFA119E5, 0xFFFFFF, 0xFF1D0A5B], // 12th
		[0xFF26D93E, 0xFFFFFF, 0xFF24560F], // 16th
		[0xFF0000B2, 0xFFFFFF, 0xFF002247], // 20th
		[0xFFA119E5, 0xFFFFFF, 0xFF1D0A5B], // 24th
		[0xFFE5C319, 0xFFFFFF, 0xFF5B2A0A], // 32nd
		[0xFFA119E5, 0xFFFFFF, 0xFF1D0A5B], // 48th
		[0xFF13ECA4, 0xFFFFFF, 0xFF085D18], // 64th
		[0xFF3A3A6C, 0xFFFFFF, 0xFF17202B], // 96th
		[0xFF3A3A6C, 0xFFFFFF, 0xFF17202B] // 192nd
	];

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var noteHoldSplash:SustainSplash;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var lightStrum:Bool = true;
	public var catchNote:Bool = true;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;

	// quant stuff
	public static final quants:Array<Int> = [
		4, // quarter note
		8, // eight
		12, // etc
		16, 20, 24, 32, 48, 64, 96, 192];

	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		// @:bypassAccessor avoids re-entering this getter recursively
		return hitsoundForce ? @:bypassAccessor this.hitsoundVolume : 0.0;
	}
	public var hitsound:String = "hitsounds/"+ClientPrefs.data.hitsoundType;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
		return value;
	}
	

	public static function getQuant(beat:Float)
	{
		var row = Conductor.beatToNoteRow(beat);
		for (data in quants)
		{
			if (row % (Conductor.ROWS_PER_MEASURE / data) == 0)
			{
				return data;
			}
		}
		return quants[quants.length - 1]; // invalid
	}

	public function defaultRGB()
	{
		if(inEditor || inTestEditor)
		{
			var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
			if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData];
		
			// `arr` is the per-direction RGB triple ([r,g,b], length 3); guarding
			// `noteData < arr.length` rejected noteData == 3 (right arrow) and
			// caused the right arrow to render with the fallback palette. Bound
			// against the outer arrowRGB length and require the triple to be full.
			if (arr != null && noteData > -1 && arr.length >= 3)
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
			else
			{
				rgbShader.r = 0xFFFF0000;
				rgbShader.g = 0xFF00FF00;
				rgbShader.b = 0xFF0000FF;
			}
		}
		else
		{
			if(mustPress || PlayState.instance.opponentMode)
			{
				var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
				if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData];
			
				if (arr != null && noteData > -1 && arr.length >= 3)
				{
					rgbShader.r = arr[0];
					rgbShader.g = arr[1];
					rgbShader.b = arr[2];
				}
				else
				{
					rgbShader.r = 0xFFFF0000;
					rgbShader.g = 0xFF00FF00;
					rgbShader.b = 0xFF0000FF;
				}

				if(ClientPrefs.data.quants != 'Off')
				{
					var beatRow:Int = 0;
					beatRow = getQuant(Conductor.getBeat(strumTime));
					// STOLEN ETTERNA CODE (IN 2002)

					var colorQuant:Int = 0;

					if(!isSustainNote) //TO DO MAKE COLOR OPTION FOR IT
					{
						if(ClientPrefs.data.quants != 'StepMania Mode')
						{
							//help me
							if (beatRow == 4)
								colorQuant = 0;
							else if (beatRow == 8)
								colorQuant = 1;
							else if (beatRow == 12)
								colorQuant = 2;
							else if (beatRow == 16)
								colorQuant = 3;
							else if (beatRow == 20)
								colorQuant = 2;
							else if (beatRow == 24)
								colorQuant = 1;
							else if (beatRow == 32)
								colorQuant = 0;
							else if (beatRow == 48)
								colorQuant = 1;
							else if (beatRow == 64)
								colorQuant = 2;
							else if (beatRow == 96)
								colorQuant = 3;
							else if (beatRow == 192)
								colorQuant = 2;
						}
						else
						{
							colorQuant = quants.indexOf(beatRow);
						}

						var arrQuant:Array<FlxColor> = ClientPrefs.data.arrowRGB[colorQuant];
						if(PlayState.isPixelStage) arrQuant = ClientPrefs.data.arrowRGBPixel[colorQuant];

						if(ClientPrefs.data.quants == 'StepMania Mode') arrQuant  = quantStepManiaColors[colorQuant];

						rgbShader.r = arrQuant[0];
						rgbShader.g = arrQuant[1];
						rgbShader.b = arrQuant[2];

						noteSplashData.r = arrQuant[0];
						noteSplashData.g = arrQuant[1];
					}
					else
					{
						rgbShader.r = prevNote.rgbShader.r;
						rgbShader.g = prevNote.rgbShader.g;
						rgbShader.b = prevNote.rgbShader.b;
					}
				}

				//TO DO: FIX IT SO BF COULD HAVE COLORED GF NOTES TOO
				/*if(colored && gfNote)
				{
					var arrGf:Array<String>;
					arrGf = PlayState.instance.gf.opponentNoteColor[noteData];

					if (arrGf != null && noteData > -1 && noteData <= arrGf.length)
					{
						rgbShader.r = CoolUtil.colorFromString(arrGf[0]);
						rgbShader.g = CoolUtil.colorFromString(arrGf[1]);
						rgbShader.b = CoolUtil.colorFromString(arrGf[2]);
					}
					else
					{
						rgbShader.r = 0xFFFF0000;
						rgbShader.g = 0xFF00FF00;
						rgbShader.b = 0xFF0000FF;
					}
				}*/
			}
			else
			{
				var arrOpp:Array<String>;
					
				arrOpp = PlayState.instance.dad.opponentNoteColor[noteData];
				var extra_arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];

				if (arrOpp != null && noteData > -1 && noteData <= arrOpp.length)
				{
					rgbShader.r = CoolUtil.colorFromString(arrOpp[0]);
					rgbShader.g = CoolUtil.colorFromString(arrOpp[1]);
					rgbShader.b = CoolUtil.colorFromString(arrOpp[2]);

					noteSplashData.r = CoolUtil.colorFromString(arrOpp[0]);
					noteSplashData.g =  CoolUtil.colorFromString(arrOpp[1]);
				}
				else
				{
					rgbShader.r = 0xFFFF0000;
					rgbShader.g = 0xFF00FF00;
					rgbShader.b = 0xFF0000FF;

					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g =  0xFF00FF00;
				}

				if(colored && gfNote)
				{
					var arrGf:Array<String>;
					arrGf = PlayState.instance.gf.opponentNoteColor[noteData];

					if (arrGf != null && noteData > -1 && noteData <= arrGf.length)
					{
						rgbShader.r = CoolUtil.colorFromString(arrGf[0]);
						rgbShader.g = CoolUtil.colorFromString(arrGf[1]);
						rgbShader.b = CoolUtil.colorFromString(arrGf[2]);

						noteSplashData.r = CoolUtil.colorFromString(arrOpp[0]);
						noteSplashData.g =  CoolUtil.colorFromString(arrOpp[1]);
					}
					else
					{
						rgbShader.r = 0xFFFF0000;
						rgbShader.g = 0xFF00FF00;
						rgbShader.b = 0xFF0000FF;

						noteSplashData.r = 0xFFFF0000;
						noteSplashData.g =  0xFF00FF00;
					}
				}
			}
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					canChangeRGB = false;

					// note colors
					rgbShader.r = 0xFF000000;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF000000;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'GF Sing':
					gfNote = true;
				case 'GF Sing (Colored)':
					gfNote = true;
					colored = true;
				case 'Autoplay Note':
					autoplay = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != "hitsounds/"+ClientPrefs.data.hitsoundType && hitsoundVolume > 0 && !precachedHitsounds.exists(hitsound)) {
				precachedHitsounds.set(hitsound, true);
				Paths.sound(hitsound); //precache new sound for being idiot-proof
			}
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null, ?dadNote:Bool = true)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.dadNote = dadNote;
		this.moves = false;
		this.moves = false;

		if (!inEditor) x += ((ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll') ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
			{
				rgbShader.enabled = false;

				if (_colorSwap != null) shader = _colorSwap.shader;
			}
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 1;
			multAlpha = 1;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			scale.y = 0.62;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();
			centerOffsets();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y = Conductor.stepCrochet / 100 * 1.058;

				if(createdFrom != null &&  createdFrom.songSpeedOpponent != null) 
					if (!prevNote.mustPress)
						prevNote.scale.y *= createdFrom.songSpeedOpponent;

				if(createdFrom != null && createdFrom.songSpeed != null) 
					if (prevNote.mustPress)
						prevNote.scale.y *= createdFrom.songSpeed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 4.58;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public function dadRGBdisable()
	{
		if(PlayState.SONG != null && PlayState.SONG.disableDadRGB && !mustPress)
		{
			rgbShader.enabled = false;

			if (_colorSwap != null) shader = _colorSwap.shader;
		}
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData] : ClientPrefs.data.arrowRGBPixel[noteData];
			
			if (arr != null && arr.length >= 3)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			if(PlayState.SONG != null)
			{
				skin = PlayState.SONG.arrowSkin;

				if (!dadNote && PlayState.SONG.opponentArrowSkin != null && PlayState.SONG.opponentArrowSkin.length > 1 && !PlayState.instance.opponentMode) 
					skin = PlayState.SONG.opponentArrowSkin;
			}
			else 
				skin == null;

			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}
		else rgbShader.enabled = false;

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				if (graphic == null) {
					FlxG.log.error('Note: missing pixel sustain skin "images/pixelUI/${skinPixel}ENDS${skinPostfix}.png"');
					return;
				}
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				if (graphic == null) {
					FlxG.log.error('Note: missing pixel skin "images/pixelUI/${skinPixel}${skinPostfix}.png"');
					return;
				}
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	public function desaturate():Void
	{
		if(_colorSwap != null)
		{
			_colorSwap.hue = 0;
			_colorSwap.brightness = 0;
			_colorSwap.saturation = -1;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		if (this.extraData['holdSplash'] != null)
			this.extraData['holdSplash'].playEnd(this);

		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(isSustainNote)
			angle = strumDirection - 90;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			{
			@:privateAccess
			x = strumX + offsetX + myStrum._dirCos * distance;
		}

		if(copyY)
		{
			@:privateAccess
			y = strumY + offsetY + correctionOffset + myStrum._dirSin * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote || !catchNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		// @:bypassAccessor avoids recursing into this setter through the
		// (default, set) property declared on FlxSprite. Without it, hxcpp
		// re-enters set_clipRect for every assignment to clipRect.
		@:bypassAccessor clipRect = rect;

		if (frames != null && animation.frameIndex >= 0 && animation.frameIndex < frames.frames.length)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
