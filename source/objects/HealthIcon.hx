package objects;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var hasThirdIcon:Bool = false;
	private var iconOffsets:Array<Float> = [0, 0];

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true, ?offsetsThing:Array<Float>, ?scale:Float = 1, ?flipX:Bool = false)
	{
		super();

		if (offsetsThing == null) offsetsThing = [0, 0];

		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU, offsetsThing, scale, flipX);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true, ?iconOffsetsPar:Array<Float>, ?scalePar:Float = 1, ?flipXpar:Bool = false) {
		if(this.char != char) {
			if (iconOffsetsPar == null) iconOffsetsPar = [0, 0];

			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			
			var graphic = Paths.image(name, allowGPU);
			var iSize:Float = Math.round(graphic.width / graphic.height);
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / iSize + iconOffsetsPar[0];
			iconOffsets[1] = (height - 150) / iSize + iconOffsetsPar[1];
			scale.set(scalePar, scalePar);
			flipX = flipXpar;
			updateHitbox();

			animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);

			if (animation.curAnim.numFrames == 3)
				hasThirdIcon = true;

			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
