package funkin.game.notes;

import funkin.graphics.FunkinSprite;

//Code by PumpSuki and DuskieWhy
class SustainSplash extends FlxSprite {

	public var data(get, set):Int;
	public var noteData:Int = 0;
	
	public var player:Int = 0;
	
	private var _note:Note;
	private var _strum:StrumNote;

  public static var defaultNoteSplash(default, never):String = "holdSplashes/holdSplash";

  // internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;

  public function new():Void {
    super();

    loadSplash();
  }

  public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashHoldSkin != ClientPrefs.defaultData.splashHoldSkin)
			skin = '-' + ClientPrefs.data.splashHoldSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

  public function loadSplash()
  {
    var splash:String = null;
    var texture:String = null;

    if(splash == null)
		{
			splash = defaultNoteSplash + getSplashSkinPostfix();
		}

		if (frames == null)
		{
			texture = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(texture);
			if (frames == null)
			{
				texture = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(texture);
			}
		}
		
		animation.addByPrefix('start', 'holdCoverStart0', 24, false);
    switch(ClientPrefs.data.splashHoldSkin)
    {
      case 'Impostor':
        animation.addByPrefix('hold', 'holdCover0', 48, true);
      default: 
        animation.addByPrefix('hold', 'holdCover0', 24, true);
    }
		animation.addByPrefix('end', 'holdCoverEnd0', 24, false);

    animation.onFinish.add(this.onAnimationFinished);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    _position();
    
    //so it won't be look weird when strum move
    if(_strum != null)
    {
      alpha = _strum.alpha;
    }
  }

  public function playAnim(anim:String, force:Bool = false, isReversed:Bool = false, frame:Int = 0)
	{
    animation.play(anim, force, isReversed, frame);
		
		centerOffsets();
		centerOrigin();

    updateHitbox();

    if(anim == 'end' && ClientPrefs.data.splashHoldSkin == 'Default')
      offsetOverride = [0, -21];
    else
      offsetOverride = [0, 0];

    _position();
	}

  public function setupSplash(strum:StrumNote, ?note:Note, ?time:Float = 0.5, ?isPlayer:Bool = false):Void 
  {
    this._note = note;
		this._strum = strum;
		
		data = note.noteData;
		
		visible = true;
		angle = 0;
		alpha = strum.alpha;

    if (note.rgbShader.enabled) {
      shader = new NoteSplash.PixelSplashShaderRef().shader;
      shader.data.r.value = note.shader.data.r.value;
      shader.data.g.value = note.shader.data.g.value;
      shader.data.b.value = note.shader.data.b.value;
      shader.data.mult.value = note.shader.data.mult.value;
    }

    antialiasing = ClientPrefs.data.antialiasing;

    switch(ClientPrefs.data.splashHoldSkin)
    {
      case 'Impostor':
        scale.set(0.7, 0.7);
    }

    updateHitbox();
		
		playAnim('start', true);

    _position();
		
		FlxTimer.wait(time, () -> {
			if (isPlayer && ClientPrefs.data.splashAlpha != 0 && !PlayState.SONG.disableHoldSparkle) playAnim('end', true);
			else kill();
		});

    //offset.set(PlayState.isPixelStage ? 112.5 : (ClientPrefs.data.noteSkin == 'Default') ? 111 : 106.25, 100);
  }
  var offsetsChange = [13, -50];
  var offsetOverride = [0, 0];
  function _position()
	{
		if (_strum != null)
		{
      switch(ClientPrefs.data.splashHoldSkin)
      {
        case 'Impostor':
          offsetsChange = [33, 46];
        case 'NightmareVision':
          offsetsChange = [-10, 15];
        case 'Vanilla':
          offsetsChange = [13, -50];
        default:
          offsetsChange = [0, -20];
      }
			
			setPosition(_strum.x + (_strum.width - width) * .5, _strum.y + (_strum.height - height) * .5);
			offset.set(offsetsChange[0] + offsetOverride[0], offsetsChange[1] + offsetOverride[1]);
		}
	}

  inline function get_data():Int return noteData;
	
	inline function set_data(v:Int):Int return noteData = v;

  public function onAnimationFinished(animationName:String):Void
  {
    if (animationName.startsWith('start'))
    {
      playAnim('hold', true);
    }
    if (animationName.startsWith('end'))
    {
      // *lightning* *zap* *crackle*
      this.visible = false;
      this.kill();
    }
  }
}
