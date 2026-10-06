package;

@:dox(hide)
class ApplicationMain
{
  #if !macro
  public static function main():Void
  {
    // Registers libraries prim symbols.
    bootstrap.LimeBootstrap.registerPrims();

    #if (windows && cpp)
    // Disable the Windows "ghosting" effect that dims unresponsive windows.
    funkin.external.windows.WinAPI.disableWindowsGhosting();

    // Disable Windows error reporting (avoids sending bug reports to Microsoft).
    funkin.external.windows.WinAPI.disableErrorReporting();
    #end

    // Registers the application entry point.
    bootstrap.LimeBootstrap.registerEntryPoint(create);
  }

  public static function create(config:Dynamic):Void
  {
    #if (linux && cpp)
     // Requests Gamemode optimization for Linux systems.
    hxgamemode.GamemodeClient.request_start();
    #end

    #if hxvlc
    // Initialize hxvlc's Handle here so the videos are loading faster.
    hxvlc.util.Handle.init();
    #end

    // Creates the primary OpenFL application instance.
    final app:openfl.display.Application = bootstrap.OpenFLBootstrap.createApplication();

    // Set the current working directory for Android and iOS devices
    #if android
    // On Android use External Files Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
    #elseif ios
    // On iOS use Documents Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory));
    #end
    
     // Get OpenFL to stop complaining so much, you can remove this line if you want to read debug messages.
    lime.utils.Log.level = INFO;

    // Creates primary OpenFL application window.
    bootstrap.OpenFLBootstrap.createWindow(app, config, false); //TO-DO: save fullscreen param

     // Manually crash the game when using a software renderer in order to give a nicer error message.
     checkRenderer(app.window.context);

     // Manually crash the game when using a software renderer in order to give a nicer error message.
     checkRenderer(app.window.context);

     // Initialize the FunkinGame instance.
    funkin.backend.FunkinGame.init();

    // Loads the application preloader.
    bootstrap.OpenFLBootstrap.loadPreloader(app, config);

    // Executes the main application loop.
    bootstrap.LimeBootstrap.exec(app);

    #if (linux && cpp)
    // Stops Gamemode optimization upon exit.
    hxgamemode.GamemodeClient.request_end();
    #end
  }

  @:noCompletion
  private static function checkRenderer(context:lime.graphics.RenderContext):Void
  {
    if (context.type != WEBGL && context.type != OPENGL && context.type != OPENGLES)
    {
      var tech:String = #if web 'WebGL' #elseif desktop 'OpenGL' #else 'OpenGL ES' #end;

      var requiredVersion:String = #if web '$tech 1.0 or newer' #elseif desktop '$tech 3.0 or newer' #else '$tech 2.0 or newer' #end;

      var desc:String = 'Failed to initialize the $tech rendering context!\n\n';

      #if web
      desc += 'Make sure your graphics card supports $requiredVersion, your graphics drivers are up to date, and hardware acceleration is enabled on your browser.';
      #elseif desktop
      desc += 'Make sure your graphics card supports $requiredVersion, and your graphics drivers are up to date.';
      #else
      desc += 'Make sure your device supports $requiredVersion.';
      #end

      funkin.utils.WindowUtil.showError('Failed to initialize $tech', desc);

      lime.system.System.exit(1);
    }
  }
  #end
}
