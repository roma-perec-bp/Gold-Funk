package psychlua;

import flxgif.FlxGifSprite;

class ModchartGifSprite extends FlxGifSprite
{
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.data.antialiasing;
	}
}
