package objects;

//CODE BY PUMPSUKI!!!
class SustainSplash extends FlxSprite {

  public static var startCrochet:Float;
  public var destroyTimer:FlxTimer;

  public static var defaultNoteSplash(default, never):String = "holdSplashes/holdSplash";

  var strumMove:StrumNote;

  public function new():Void {

    super();

    var splash:String = '';
    if (PlayState.SONG != null && PlayState.SONG.holdSkin != null && PlayState.SONG.holdSkin.length > 0) 
      splash = PlayState.SONG.holdSkin;
    else
      splash = defaultNoteSplash;

    frames = Paths.getSparrowAtlas(splash);
    animation.addByPrefix('start', 'holdCoverStart0', 24, false);
    animation.addByPrefix('hold', 'holdCover0', 24, true);
		animation.addByPrefix('end', 'holdCoverEnd0', 24, false);
    animation.play('start', true, false, 0);

    destroyTimer = new FlxTimer();
  }

  override function update(elapsed:Float)
  {
    //so it won't be look weird when strum move
    if(strumMove != null)
    {
      setPosition(strumMove.x, strumMove.y);
      alpha = strumMove.alpha;
    }

    if (animation.curAnim.name == 'start' && animation.curAnim.finished) animation.play('hold');

    super.update(elapsed);
  }

  public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void {

    final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
    final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
    final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

    var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

    tailEnd.extraData['holdSplash'] = this;

    clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

    if (daNote.shader != null) {
      shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
      shader.data.r.value = daNote.shader.data.r.value;
      shader.data.g.value = daNote.shader.data.g.value;
      shader.data.b.value = daNote.shader.data.b.value;
      shader.data.mult.value = daNote.shader.data.mult.value;
    }

    setPosition(strum.x, strum.y);
    offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);

    destroyTimer.start(timeThingy, (idk:FlxTimer) -> {
      if (tailEnd.mustPress && !(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled) && ClientPrefs.data.splashAlpha != 0) {
        alpha = ClientPrefs.data.splashAlpha;
        animation.play('end', true, false, 0);
        animation.curAnim.looped = false;
        clipRect = null;
        animation.finishCallback = (idkEither:Dynamic) -> {
          die(tailEnd);
        }
        return;
      }
      die(tailEnd);
    });

  }

  public function die(?end:Note = null):Void {
    kill();
    super.kill();
    if (FlxG.state is PlayState) {
      PlayState.instance.grpHoldSplashes.remove(this);
    }
    destroy();
    super.destroy();
    if (end != null) {
      end.extraData['holdSplash'] = null;
    }
  }

  public function onAnimationFinished(animationName:String):Void
  {
    if (animationName.startsWith('start'))
    {
      animation.play('hold', true, false, 0);
    }
  }

}
