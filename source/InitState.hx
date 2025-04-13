package;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

import flixel.system.debug.log.LogStyle;
import openfl.display.BitmapData;

import backend.WeekData;
import backend.Highscore;

import states.StoryMenuState;
import states.FlashingState;

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
        super.create();
        
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        Language.reloadPhrases();

        Controls.instance = new Controls();
        ClientPrefs.loadDefaultKeys();
        ClientPrefs.loadPrefs();

        #if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		
        FlxG.save.bind('funkin', CoolUtil.getSavePath());
        Highscore.load();
        
        #if VIDEOS_ALLOWED
        hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
        #end

        FlxG.fixedTimestep = false;
        FlxG.game.focusLostFramerate = 30;
        FlxG.keys.preventDefaultKeys = [TAB];

        #if LUA_ALLOWED
        Mods.pushGlobalMods();
        #end
        Mods.loadTopMod();

        if(FlxG.save.data != null && FlxG.save.data.fullscreen) FlxG.fullscreen = FlxG.save.data.fullscreen;
        if (FlxG.save.data.weekCompleted != null) StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

        #if html5
        FlxG.autoPause = false;
        #end
        FlxG.mouse.visible = false;

        #if DISCORD_ALLOWED
        DiscordClient.prepare();
        #end

        // Sets the window to dark mode or white, depends.
        #if (cpp && windows)
		WindowColorMode.setWindowColorMode(ClientPrefs.data.windowDarkMode);
		WindowColorMode.redrawWindowHeader();
		#end

        setupFlixelDebug();

		FlxG.switchState(new states.TitleState());
    }

    function setupFlixelDebug():Void
    {
        #if debug
         // Make errors and warnings less annoying.
        LogStyle.WARNING.openConsole = false;
        LogStyle.WARNING.errorSound = null;

        FlxG.debugger.toggleKeys = [F2];

        FlxG.debugger.addButton(LEFT, new BitmapData(200, 200), function() {
            FlxG.debugger.visible = false;
      
            // Make errors and warnings less annoying.
            // Forcing this always since I have never been happy to have the debugger to pop up
            LogStyle.ERROR.openConsole = false;
            LogStyle.ERROR.errorSound = null;
            LogStyle.WARNING.openConsole = false;
            LogStyle.WARNING.errorSound = null;
        });

        // Adds a red button to the debugger.
        // This pauses the game AND the music! This ensures the Conductor stops.
        FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFFCC2233), function() {
            if (FlxG.vcr.paused)
            {
                FlxG.vcr.resume();
  
                for (snd in FlxG.sound.list)
                    snd.resume();
  
                FlxG.sound.music.resume();
            }
            else
            {
                FlxG.vcr.pause();
  
                for (snd in FlxG.sound.list)
                    snd.pause();
            }
            
            FlxG.sound.music.pause();
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
        #end
    }
}