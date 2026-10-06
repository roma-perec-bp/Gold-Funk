package;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

import flixel.system.debug.log.LogStyle;
import openfl.display.BitmapData;

import funkin.menus.FullScreenScaleMode;

import funkin.menus.storymenu.StoryMenuState;
import funkin.menus.FlashingState;

#if (cpp && windows)
import hxwindowmode.WindowColorMode;
#end

class InitState extends FlxState
{
    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
    public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
    public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

    override public function create():Void
    {
        //Paths.clearStoredMemory();
        //Paths.clearUnusedMemory();

        FlxG.save.bind('funkin', CoolUtil.getSavePath());

        Language.reloadPhrases();

        //FlxSprite.defaultAntialiasing = ClientPrefs.data.antialiasing;

        Controls.instance = new Controls();
        ClientPrefs.loadDefaultKeys();
        ClientPrefs.loadPrefs();

        #if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
	
        Highscore.load();
        Progression.load();
        
        #if VIDEOS_ALLOWED
        hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
        #end

        FlxG.fixedTimestep = false;
        FlxG.signals.postGameReset.add(() -> FlxG.fixedTimestep = false);
        FlxG.game.focusLostFramerate = 30;
        FlxG.keys.preventDefaultKeys = [TAB];

        FlxG.plugins.drawOnTop = true;

        //FlxG.inputs.resetOnStateSwitch = false;

        #if LUA_ALLOWED
        Mods.pushGlobalMods();
        #end
        Mods.loadTopMod();

        //if(FlxG.save.data != null && FlxG.save.data.fullscreen) FlxG.fullscreen = FlxG.save.data.fullscreen;
        if (FlxG.save.data.weekCompleted != null) StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

        if (FlxG.save.data.playedSongs == null) FlxG.save.data.playedSongs = [];
        if (FlxG.save.data.completedSongs == null) FlxG.save.data.completedSongs = [];

        #if html5
        FlxG.autoPause = false;
        #end
        FlxG.mouse.visible = false;

        #if DISCORD_ALLOWED
        DiscordClient.prepare();
        #end

        //untyped FlxG.sound.music = new funkin.audio.FlxSoundEx();
        //FlxG.sound.music.persist = true;

        FlxG.signals.focusLost.add(onLostFocus);
        FlxG.signals.focusGained.add(onGainFocus);

        // Sets the window to dark mode or white, depends.
        #if (cpp && windows)
		    WindowColorMode.setWindowColorMode(ClientPrefs.data.windowDarkMode);
		    WindowColorMode.redrawWindowHeader();
        cpp.Windows.setDpiAware();
		    #end

        #if FEATURE_DEBUG_TRACY
		    funkin.utils.WindowUtil.initTracy();
		    #end

        #if debug
        setupFlixelDebug();
        #end

        FlxG.scaleMode = new FullScreenScaleMode();

        FlxG.signals.preStateSwitch.add(FullScreenScaleMode.instance.onMeasurePostAwait);

        super.create();

        FlxG.switchState(new funkin.menus.title.TitleState());
  }

  @:noCompletion var _lastFocusVolume:Null<Float>;

  function onLostFocus():Void
  {
    if (FlxG.sound.muted || FlxG.sound.volume == 0 || FlxG.autoPause) return;
    _lastFocusVolume = FlxG.sound.volume;
    FlxG.sound.volume *= 0.5;
  }
  
  function onGainFocus():Void
  {
    #if !mobile
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
    #end

    if (FlxG.sound.muted || FlxG.sound.volume == 0 || FlxG.autoPause) return;
    if (_lastFocusVolume != null) FlxG.sound.volume = _lastFocusVolume;
  }

  #if debug
  function setupFlixelDebug():Void
  {
      #if !debug
      // Make errors less annoying on release builds.
      LogStyle.ERROR.openConsole = false;
      LogStyle.ERROR.errorSound = null;
      #end

      // Make errors and warnings less annoying.
      LogStyle.WARNING.openConsole = false;
      LogStyle.WARNING.errorSound = null;


      FlxG.debugger.toggleKeys = [F2];

      // Adds a red button to the debugger.
      // This pauses the game AND the music! This ensures the Conductor stops.
      FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFFCC2233), function() {
      if (FlxG.vcr.paused)
      {
          FlxG.vcr.resume();
    
          for (snd in FlxG.sound.list)
          {
              snd.resume();
          }
    
          FlxG.sound.music.resume();
      }
      else
      {
          FlxG.vcr.pause();
    
          for (snd in FlxG.sound.list)
          {
              snd.pause();
          }
    
          FlxG.sound.music.pause();
      }
      });

      // Adds a blue button to the debugger.
      // This skips forward in the song.
      FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFF2222CC), function() {
      FlxG.game.debugger.vcr.onStep();

      for (snd in FlxG.sound.list)
      {
        snd.pause();
        snd.time += FlxG.elapsed * 1000;
      }

      FlxG.sound.music.pause();
      FlxG.sound.music.time += FlxG.elapsed * 1000;
      });
  }
  #end
}