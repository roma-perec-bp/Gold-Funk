package funkin.backend;

import funkin.data.ClientPrefs;
import openfl.events.Event;

/**
 * Modified FlxGame to support switching to mod states and to load our custom sound tray.
 */
class FunkinGame extends flixel.FlxGame
{
	public static function init():FunkinGame
	{
		var gameWidth:Int = 1280; // Width of the game in pixels.
		var gameHeight:Int = 720; // Height of the game in pixels.
		var initialState:Class<flixel.FlxState> = InitState; // The FlxState the game starts with.
		var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
		var framerate:Int = ClientPrefs.data.unlockedFramerate ? 0 : ClientPrefs.data.framerate; // How many frames per second the game should run at.

		return new FunkinGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash);
	}

	static final UNKNOWN_LIMIT:Int = 30;

	var unknownErrors:Int = 0;

	public function new(gameWidth:Int = 0,
		gameHeight:Int = 0,
		?initialState:flixel.util.typeLimit.NextState.InitialState,
		updateFramerate:Int = 60,
		drawFramerate:Int = 60,
		skipSplash:Bool = false,
		startFullscreen:Bool = false)
	{
		super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
	}

	override function create(_:Event)
	{
		//_customSoundTray = funkin.objects.FunkinSoundTray;
		
		super.create(_);
	}
	
	override function switchState():Void
	{
		// Basic reset stuff
		FlxG.cameras.reset();
		FlxG.inputs.onStateSwitch();
		#if FLX_SOUND_SYSTEM
		FlxG.sound.destroy();
		#end
		
		FlxG.signals.preStateSwitch.dispatch();
		
		#if FLX_RECORD
		FlxRandom.updateStateSeed();
		#end
		
		// Destroy the old state (if there is an old state)
		if (_state != null) _state.destroy();
		
		// we need to clear bitmap cache only after previous state is destroyed, which will reset useCount for FlxGraphic objects
		FlxG.bitmap.clearCache();
		
		// Finally assign and create the new state
		_state = _nextState.createInstance();
		
		_state._constructor = _nextState.getConstructor();
		_nextState = null;
		
		if (_gameJustStarted) FlxG.signals.preGameStart.dispatch();
		
		FlxG.signals.preStateCreate.dispatch(_state);
		
		_state.create();
		
		if (_gameJustStarted) gameStart();
		
		#if FLX_DEBUG
		debugger.console.registerObject("state", _state);
		#end
		
		FlxG.signals.postStateSwitch.dispatch();
	}
}
