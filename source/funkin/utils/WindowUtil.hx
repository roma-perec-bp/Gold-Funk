package funkin.utils;

import openfl.Lib;

import lime.app.Application;

// WIP
// functions used to mess with some window properties for ease
class WindowUtil
{
	public static var monitorResolutionWidth(get, never):Float;
	public static var monitorResolutionHeight(get, never):Float;
	
	static function get_monitorResolutionWidth():Float return FlxG.stage.window.display.bounds.width;
	
	static function get_monitorResolutionHeight():Float return FlxG.stage.window.display.bounds.height;
	
	public static var defaultAppTitle(get, never):String;
	
	static function get_defaultAppTitle():String return Application.current.meta['name'];

	/**
   * Shows an error dialog with an error icon.
   * @param name The title of the dialog window.
   * @param desc The error message to display.
   */
   	public static function showError(name:String, desc:String):Void
	{
	  lime.app.Application.current.window.alert(lime.ui.MessageBoxType.ERROR, desc, name);
	}
	
	public static function setTitle(?arg:String, append:Bool = false)
	{
		if (arg == null) arg = defaultAppTitle;
		
		if (append) FlxG.stage.window.title += arg;
		else FlxG.stage.window.title = arg;
	}

	 /**
   * Modifies the VSync mode of the application window.
   * @param value The desired VSync mode to use.
   */
   	public static function setVSyncMode(value:lime.ui.WindowVSyncMode):Void
	{
	  var res:Bool = FlxG.stage.application.window.setVSyncMode(value);
  
	  // SDL_GL_SetSwapInterval returns the value we assigned on success, https://wiki.libsdl.org/SDL2/SDL_GL_GetSwapInterval#return-value.
	  // In lime, we can compare this to the original value to get a boolean.
	  if (!res)
	  {
		trace('Failed to set VSync mode to ' + value);
		FlxG.stage.application.window.setVSyncMode(lime.ui.WindowVSyncMode.OFF);
	  }
	}
	
	public static function setGameDimensions(width:Int, height:Int, cameras:Array<FlxCamera>)
	{
		var newWidth:Int = width;
		var newHeight:Int = height;
		var scaledHeight:Int = height;
		
		for (camera in cameras)
		{
			camera.width = FlxG.width;
			if (newHeight <= FlxG.height)
			{
				camera.height = Std.int(FlxG.height * (FlxG.width / newHeight));
				scaledHeight = camera.height;
			}
		}
		if (!FlxG.fullscreen)
		{
			FlxG.resizeWindow(newWidth, newHeight);
			FlxG.stage.window.x = Std.int((monitorResolutionWidth - newWidth) / 2);
			FlxG.stage.window.y = Std.int((monitorResolutionHeight - newHeight) / 2);
		}
	}
	
	public static inline function centerWindowOnPoint(?point:FlxPoint)
	{
		FlxG.stage.window.x = Std.int(point.x - (FlxG.stage.window.width / 2));
		FlxG.stage.window.y = Std.int(point.y - (FlxG.stage.window.height / 2));
	}
	
	public static inline function getCenterWindowPoint():FlxPoint
	{
		return FlxPoint.weak(FlxG.stage.window.x + (FlxG.stage.window.width / 2), FlxG.stage.window.y + (FlxG.stage.window.height / 2));
	}
	
	public static function exit()
	{
		openfl.system.System.exit(0);
	}
	
	#if FEATURE_DEBUG_TRACY
	/**
	 * Initialize the tracy profiler
	 * taken from base gamehttps://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/WindowUtil.hx
	 */
	public static function initTracy():Void
	{
		// Apply a marker to indicate frame end for the Tracy profiler.
		//  Do this only if Tracy is configured to prevent lag.
		openfl.Lib.current.stage.addEventListener(openfl.events.Event.EXIT_FRAME, (e:openfl.events.Event) -> {
			cpp.vm.tracy.TracyProfiler.frameMark();
		});
		
		cpp.vm.tracy.TracyProfiler.setThreadName("main");
	}
	#end
}
