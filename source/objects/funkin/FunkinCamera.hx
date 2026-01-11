package objects.funkin;

import animate.internal.RenderTexture;
import flash.geom.ColorTransform;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import objects.funkin.framebuffer.FixedBitmapData;
import shaders.RuntimeCustomBlendShader;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.OpenGLRenderer;
import openfl.display3D.textures.TextureBase;

/**
 * A FlxCamera with additional powerful features:
 * - Added the ability to grab the camera screen as a `BitmapData` and use it as a texture.
 * - Added support for the following blend modes for a sprite through shaders:
 *   - DARKEN
 *   - HARDLIGHT
 *   - LIGHTEN
 *   - OVERLAY
 *   - DIFFERENCE
 *   - INVERT
 */
@:nullSafety
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
class FunkinCamera extends FlxCamera
{
  /**
   * A list of blend modes that require the OpenGL extension `KHR_blend_equation_advanced`.
   *
   * NOTE:
   *  - `LIGHTEN` is supported natively on desktop, but not other platforms.
   *  - While `DARKEN` is supported natively on desktop, it causes issues with transparency.
   */
  static final KHR_BLEND_MODES:Array<BlendMode> = [
    DARKEN,
    HARDLIGHT,
    #if !desktop LIGHTEN, #end
    OVERLAY,
    DIFFERENCE,
    COLORDODGE,
    COLORBURN,
    SOFTLIGHT,
    EXCLUSION,
    HUE,
    SATURATION,
    COLOR,
    LUMINOSITY
  ];

  /**
   * A list of blend modes that require the shader no matter what.
   * This is due to these blend modes not being supported on any platform.
   */
  static final SHADER_REQUIRED_BLEND_MODES:Array<BlendMode> = [INVERT];

  /**
   * The ID of this camera, used for debugging.
   */
  public var id:String;

  /**
   * Whether or not the device supports the OpenGL extension `KHR_blend_equation_advanced`.
   * If `false`, a shader implementation will be used to render certain blend modes.
   */
  public var hasKhronosExtension(get, never):Bool;

  inline function get_hasKhronosExtension():Bool
  {
    @:privateAccess
    return _renderer._complexBlendsSupported;
  }

  var _blendShader:RuntimeCustomBlendShader;
  var _backgroundFrame:FlxFrame;

  var _blendRenderTexture:RenderTexture;
  var _backgroundRenderTexture:RenderTexture;

  var _backgroundBitmap:Null<BitmapData>;

  var _renderer:OpenGLRenderer;

  @:nullSafety(Off)
  public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    super(x, y, width, height, zoom);

    this.id = id;

    _backgroundFrame = new FlxFrame(new FlxGraphic('', null));
    _backgroundFrame.frame = new FlxRect();

    _blendShader = new RuntimeCustomBlendShader();

    @:privateAccess
    _renderer = new OpenGLRenderer(Lib.current.stage.context3D);

    _backgroundRenderTexture = new RenderTexture(width, height);
    _blendRenderTexture = new RenderTexture(width, height);
  }

  /**
   * Grabs the camera screen and returns it as a `BitmapData`. The returned bitmap
   * will not be referred by the camera so, changing it will not affect the scene.
   * The returned bitmap **will be reused in the next frame**, so the content is available
   * only in the current frame.
   *
   * @param clearScreen if this is `true`, the screen will be cleared before rendering
   * @return the grabbed bitmap data
   */
  public function grabScreen(clearScreen:Bool = false):Null<BitmapData>
  {
    if (_backgroundBitmap == null)
    {
      var texture:Null<TextureBase> = _createTexture(width, height);
      if (texture == null) return null;

      _backgroundBitmap = FixedBitmapData.fromTexture(texture);
    }

    if (_backgroundBitmap != null)
    {
      var matrix:FlxMatrix = new FlxMatrix();
      matrix.setTo(1, 0, 0, 1, flashSprite.x, flashSprite.y);

      this.render();

      _backgroundBitmap.draw(flashSprite, matrix, true);

      if (clearScreen)
      {
        // clear graphics data
        super.clearDrawStack();
        canvas.graphics.clear();
      }

      _backgroundFrame.frame.set(0, 0, width, height);
    }

    return _backgroundBitmap;
  }

  override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
      ?shader:FlxShader):Void
  {
    var shouldUseShader:Bool = (!hasKhronosExtension && KHR_BLEND_MODES.contains(blend)) || SHADER_REQUIRED_BLEND_MODES.contains(blend);

    // Fallback to the shader implementation if the device doesn't support `KHR_blend_equation_advanced`, or if
    // the specified blend mode requires the shader.
    if (shouldUseShader)
    {
      var background:Null<BitmapData> = grabScreen(true);
      var frameMatrix:FlxMatrix = new FlxMatrix();
      frameMatrix.copyFrom(matrix);

      _blendRenderTexture.init(this.width, this.height);
      _blendRenderTexture.drawToCamera((camera, matrix) -> {
        var pivotX:Float = width / 2;
        var pivotY:Float = height / 2;

        frameMatrix.translate(-pivotX, -pivotY);
        frameMatrix.scale(this.scaleX, this.scaleY);
        frameMatrix.translate(pivotX, pivotY);

        camera.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
      });
      _blendRenderTexture.render();

      if (background == null || _blendRenderTexture.graphic.bitmap == null)
      {
        FlxG.log.error('Failed to get bitmap for blending!');
        super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
        return;
      }

      _blendShader.sourceSwag = _blendRenderTexture.graphic.bitmap;
      _blendShader.backgroundSwag = background;

      _blendShader.blendSwag = blend;
      _blendShader.updateViewInfo(width, height, this);

      _backgroundFrame.parent.bitmap = _blendRenderTexture.graphic.bitmap;

      _backgroundRenderTexture.init(this.width, this.height);
      _backgroundRenderTexture.drawToCamera((camera, matrix) -> {
        camera.zoom = this.zoom;
        camera.drawPixels(_backgroundFrame, null, matrix, canvas.transform.colorTransform, null, false, _blendShader);
      });

      _backgroundRenderTexture.render();

      // Resize the frame so it always fills the screen
      var cameraMatrix:FlxMatrix = new FlxMatrix();
      cameraMatrix.identity();
      cameraMatrix.scale(1 / this.scaleX, 1 / this.scaleY);
      cameraMatrix.translate((width - width / this.scaleX) * 0.5, (height - height / this.scaleY) * 0.5);

      super.drawPixels(_backgroundRenderTexture.graphic.imageFrame.frame, null, cameraMatrix, null, null, false, null);
    }
    else
    {
      super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
    }
  }

  override function destroy():Void
  {
    super.destroy();

    _blendRenderTexture.destroy();
    _backgroundRenderTexture.destroy();

    if (_backgroundBitmap != null)
    {
      _backgroundBitmap.dispose();
      _backgroundBitmap = null;
    }
  }

  function _createTexture(width:Int, height:Int):Null<TextureBase>
  {
    // zero-sized textures will be problematic
    width = width < 1 ? 1 : width;
    height = height < 1 ? 1 : height;

    return Lib.current.stage.context3D.createTexture(width, height, BGRA, true);
  }
}
