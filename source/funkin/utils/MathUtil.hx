package funkin.utils;

@:nullSafety(Strict)
class MathUtil
{
	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float
  	{
    	if (deltaTime == 0) return base;
    	if (base == target) return target;
    	return lerp(target, base, Math.pow(precision, deltaTime / duration));
  	}
	public static function snap(base:Float, target:Float, threshold:Float):Float
  	{
    	return Math.abs(base - target) <= threshold ? target : base;
 	}
	/**
	 * Get the logarithm of a value with a given base.
	 * @param base The base of the logarithm.
	 * @param value The value to get the logarithm of.
	 * @return `log_base(value)`
	 */
	public static function logBase(base:Float, value:Float):Float
	{
		return Math.log(value) / Math.log(base);
	}

	 /**
   * Get the base-2 exponent of a value.
   * @param x value
   * @return `2^x`
   */
   	public static function exp2(x:Float):Float
	{
	  return Math.pow(2, x);
	}
	
	/**
	 * Remaps a value from a range to a new range
	 * 
	 * Akin to `FlxMath.remapToRange`
	 * @param x Input value
	 * @param l1 Low bound of range 1
	 * @param h1 High bound of range 1
	 * @param l2 Low bound of range 2
	 * @param h2 High bound of range 2
	 * @return Input value remapped to range 2
	 */
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);
	
	/**
	 * Clamps/Bounds a value between a range that it cannot go below or over
	 * 
	 * Akin to `FlxMath.bound`
	 * @param n Input value
	 * @param l Low boundary
	 * @param h High Boundary
	 * @return Clamped value
	 */
	inline public static function clamp(n:Float, l:Float, h:Float)
	{
		if (n > h) n = h;
		if (n < l) n = l;
		return n;
	}
	
	/**
	 * Creates or uses a provided point and rotates it around a given `x` and `y` by radians
	 * 
	 * Akin to `new FlxPoint(x,y).radians += angle`
	 * @return A rotated FlxPoint
	 */
	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		final p = point ?? FlxPoint.weak();
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}
	
	public static inline function quantizeAlpha(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}
	
	public static inline function quantize(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}
	
	/**
		FlxMath.lerp but accounts for FPS.
	**/
	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float) return FlxMath.lerp(v1, v2, FlxMath.getElapsedLerp(ratio, FlxG.elapsed));
	
	/**
	 * referenced via https://youtu.be/LSNQuFEDOyQ
	 * 
	 * A frame independent lerp. Primary purpose is for the camera
	 * 
	 * your decay should be around 1 - 25
	 */
	public static function decayLerp(a:Float, b:Float, decay:Float, elapsed:Float) return b + (a - b) * Math.exp(-decay * elapsed);

	 /**
   * Linear interpolation.
   *
   * @param base The starting value, when `alpha = 0`.
   * @param target The ending value, when `alpha = 1`.
   * @param alpha The percentage of the interpolation from `base` to `target`. Forms a "line" intersecting the two.
   *
   * @return The interpolated value.
   */
   public static function lerp(base:Float, target:Float, alpha:Float):Float
	{
	  if (alpha == 0) return base;
	  if (alpha == 1) return target;
	  return base + alpha * (target - base);
	}

	/**
   * Exponential decay interpolation.
   *
   * Framerate-independent because the rate-of-change is proportional to the difference, so you can
   * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
   *
   * Equivalent to `smoothLerpPrecision(base, target, deltaTime, halfLife, 0.5)`.
   *
   * @param base The starting or current value.
   * @param target The value this function approaches.
   * @param deltaTime The change in time along the function in seconds.
   * @param halfLife Time in seconds to reach halfway to `target`.
   *
   * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
   *
   * @return The interpolated value.
   */
   public static function smoothLerpDecay(base:Float, target:Float, deltaTime:Float, halfLife:Float):Float
	{
	  if (deltaTime == 0) return base;
	  if (base == target) return target;
	  return lerp(target, base, exp2(-deltaTime / halfLife));
	}
	
	/**
		crude version of FlxMath.wrap. supports floats though
	**/
	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		if (value < min) return max;
		else if (value > max) return min;
		else return value;
	}
	
	/**
	 * Alternative to `FlxMath.roundDecimal` but floors the value rather than rounding it
	 * @param value The number 
	 * @param precision The number of decimals
	 * @return The floored value
	 */
	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);
		
		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;
			
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}
	
	/**
		Makes a number array
		* @param	min starting number. default is 0
		* @param	max ending number
		* @return the new array
	**/
	public static inline function numberArray(?min:Int, max:Int):Array<Int>
	{
		if (min == null) min = 0;
		return [for (i in min...max) i];
	}
}
