package debug;

import flixel.util.FlxStringUtil;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import debug.StatsGraph;
import debug.MemoryUtil;
import flixel.FlxG;
import openfl.system.System;

/**
 * A debug overlay showing useful info.
 */
 #if cpp
@:access(lime._internal.backend.native.NativeCFFI)
#end
class FPSCounter extends Sprite
{
  static final UPDATE_DELAY:Int = 100;
  static final INNER_RECT_DIFF:Int = 3;
  static final OUTER_RECT_DIMENSIONS:Array<Int> = [234, 201];
  static final OTHERS_OFFSET:Int = 8;

  /**
   * Indicates whether the debug display is in advanced mode.
   */
  public var isAdvanced(default, set):Bool = false;

  /**
   * The opacity of the debug display's background.
   */
  public var backgroundOpacity(default, set):Float = 0.5;

  var currentFPS:Int;
  var deltaTimeout:Float;
  var times:Array<Float>;
  var color:Int;

  var gcMem:Float;
  var gcMemPeak:Float;

  var taskMem:Float;
  var taskMemPeak:Float;

  var background:Shape;

  var fpsGraph:StatsGraph;
  var gcMemGraph:StatsGraph;
  var taskMemGraph:StatsGraph;

  var infoDisplay:TextField;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000):Void
  {
    super();

    this.x = x;
    this.y = y;
    this.currentFPS = 0;
    this.deltaTimeout = 0.0;

    this.gcMem = 0.0;
    this.gcMemPeak = 0.0;
    this.taskMem = 0.0;
    this.taskMemPeak = 0.0;

    this.times = [];
    this.color = color;
    this.backgroundOpacity = 0.5;
    this.isAdvanced = false;
  }

  function buildDebugDisplay(advanced:Bool):Void
  {
    removeChildren(0, numChildren);

    final BG_WIDTH_MULTIPLIER:Float = 0.8;

    final BG_HEIGHT_MULTIPLIER:Float = advanced ? 1 : (MemoryUtil.supportsTaskMem()) ? 0.27 : 0.17;

    background = new Shape();
    background.graphics.beginFill(0xFFFFFFFF, 1);
    background.graphics.drawRect(0, 0, (OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER) + (INNER_RECT_DIFF * 2),
      (OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER) + (INNER_RECT_DIFF * 2));
    background.graphics.endFill();
    background.graphics.beginFill(0xFF000000, 1);
    background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER,
      OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER);
    background.graphics.endFill();
    background.alpha = backgroundOpacity;
    addChild(background);

    if (advanced)
    {
      createAdvancedElements();
      updateAdvancedDisplay();
    }
    else
    {
      createSimpleElements();
      updateSimpleDisplay();
    }
  }

  function createAdvancedElements():Void
  {
    final graphsWidth:Int = OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2) - (OTHERS_OFFSET * 3);
    final graphsHeight:Int = 25;

    fpsGraph = new StatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + 49, graphsWidth, graphsHeight, color);
    fpsGraph.textDisplay.y = -49;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    gcMemGraph = new StatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), graphsWidth, graphsHeight, color);
    gcMemGraph.minValue = 0;
    addChild(gcMemGraph);

    if (MemoryUtil.supportsTaskMem())
    {
      taskMemGraph = new StatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), graphsWidth, graphsHeight,
        color);
      taskMemGraph.minValue = 0;
      addChild(taskMemGraph);
    }
  }

  function createSimpleElements():Void
  {
    infoDisplay = new TextField();
    infoDisplay.x = OTHERS_OFFSET;
    infoDisplay.y = OTHERS_OFFSET;
    infoDisplay.width = 500;
    infoDisplay.selectable = false;
    infoDisplay.mouseEnabled = false;
    infoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 10, color, JUSTIFY);
    infoDisplay.antiAliasType = NORMAL;
    infoDisplay.sharpness = 100;
    infoDisplay.multiline = true;
    addChild(infoDisplay);
  }

  override function __enterFrame(deltaTime:Int):Void
  {
    final currentTime:Float = haxe.Timer.stamp() * 1000;

    times.push(currentTime);

    while (times[0] < currentTime - 1000)
    {
      times.shift();
    }

    if (deltaTimeout < UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length;

    gcMem = MemoryUtil.getGCMemory();

    if (gcMem > gcMemPeak) gcMemPeak = gcMem;

    if (MemoryUtil.supportsTaskMem())
    {
      taskMem = MemoryUtil.getTaskMemory();

      if (taskMem > taskMemPeak) taskMemPeak = taskMem;
    }

    if (isAdvanced)
    {
      updateAdvancedDisplay();
    }
    else
    {
      updateSimpleDisplay();
    }

    deltaTimeout = 0.0;
  }

  function updateAdvancedDisplay():Void
  {
    updateFPSGraph();

    updateGcMemGraph();
    updateTaskMemGraph();

    final info:Array<String> = [];
    info.push('FPS: $currentFPS');
    info.push('AVG FPS: ${Math.floor(fpsGraph.average())}');
    info.push('1% LOW FPS: ${Math.floor(fpsGraph.lowest())}');
    fpsGraph.textDisplay.text = info.join('\n');

	fpsGraph.textDisplay.textColor = 0xFFFFFFFF;

	if (currentFPS < FlxG.drawFramerate * 0.5)
		fpsGraph.textDisplay.textColor = 0xFFFF0000;

    gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}';

    if (taskMemGraph != null)
    {
      taskMemGraph.textDisplay.text = 'TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}';
    }
  }

  function updateSimpleDisplay():Void
  {
    if (infoDisplay != null)
    {
      final info:Array<String> = [];

      info.push('FPS: $currentFPS');

      info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}');

      if (MemoryUtil.supportsTaskMem())
        info.push('TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}');

      infoDisplay.text = info.join('\n');

	  infoDisplay.textColor = 0xFFFFFFFF;

	if (currentFPS < FlxG.drawFramerate * 0.5)
		infoDisplay.textColor = 0xFFFF0000;
    }
  }

  function updateFPSGraph(?currentFPS:Int = 0):Void
  {
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.update(times.length);
  }

  function updateGcMemGraph(?currentFPS:Int = 0):Void
  {
    gcMemGraph.maxValue = gcMemPeak;
    gcMemGraph.update(gcMem);
  }

  function updateTaskMemGraph(?currentFPS:Int = 0):Void
  {
    if (taskMemGraph != null)
    {
      taskMemGraph.maxValue = taskMemPeak;
      taskMemGraph.update(taskMem);
    }
  }

  function set_isAdvanced(value:Bool):Bool
  {
    buildDebugDisplay(value);

    return isAdvanced = value;
  }

  function set_backgroundOpacity(value:Float):Float
  {
    if (background != null) background.alpha = value;

    return backgroundOpacity = value;
  }
}

enum abstract DebugDisplayMode(Int) from Int to Int
{
  /**
   * Debug display is disabled.
   */
  var OFF = 0;

  /**
   * Simple debug display.
   * FPS and Memory counters only.
   */
  var SIMPLE = 1;

  /**
   * Advanced debug display.
   * Full FPS and Memory info.
   */
  var ADVANCED = 2;
}
