package objects;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var animated:Bool = false;
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

			var animToFind:String = Paths.getPath('images/' + name + '.xml', TEXT);

			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			{
				animated = true;

				var graphic = Paths.getSparrowAtlas(name, allowGPU);

				frames = graphic;

				animation.addByPrefix('idle', 'idle', 24, true, isPlayer);
				animation.addByPrefix('winning', 'winning', 24, true, isPlayer);
				animation.addByPrefix('losing', 'losing', 24, true, isPlayer);
				animation.addByPrefix('toWinning', 'toWinning', 24, false, isPlayer);
				animation.addByPrefix('toLosing', 'toLosing', 24, false, isPlayer);
				animation.addByPrefix('fromWinning', 'fromWinning', 24, false, isPlayer);
				animation.addByPrefix('fromLosing', 'fromLosing', 24, false, isPlayer);
				animation.play('idle');

				iconOffsets[0] = (width - 150) + iconOffsetsPar[0];
				iconOffsets[1] = (height - 150) + iconOffsetsPar[1];
				scale.set(scalePar, scalePar);
				flipX = flipXpar;
				updateHitbox();
				
				this.char = char;

				if(char.endsWith('-pixel'))
					antialiasing = false;
				else
					antialiasing = ClientPrefs.data.antialiasing;
			}
			else
			{
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
	}

	public function getCurrentAnimation():String
	{
		if (this.animation == null || this.animation.curAnim == null) return "";
		return this.animation.curAnim.name;
	}

	public function hasAnimation(id:String):Bool
	{
		if (animation == null) return false;
	  
		return animation.getByName(id) != null;
	}

	public function isAnimationFinished():Bool
	{
		return this.animation.finished;
	}

	public function updateHealthIcon(health:Float):Void
	{
		// We want to efficiently handle animation playback
	  
		// Here, we use the current animation name to track the current state
		// of a simple state machine. Neat!
	  
		switch (getCurrentAnimation())
		{
			case 'idle':
				if (health < 20)
					playAnimation('toLosing', 'losing');
			  	else if (health > 80)
					playAnimation('toWinning', 'winning');
			  	else
					playAnimation('idle');

			case 'winning':
				if (health < 80)
					playAnimation('fromWinning', 'idle');
			  	else
					playAnimation('winning', 'idle');

			case 'losing':
			  	if (health > 20) 
					playAnimation('fromLosing', 'idle');
			  	else
					playAnimation('losing', 'idle');

			case 'toLosing':
			  	if (isAnimationFinished())
					playAnimation('losing', 'idle');

			case 'toWinning':
			  	if (isAnimationFinished())
					playAnimation('winning', 'idle');

			case 'fromLosing' | 'fromWinning':
			  	if (isAnimationFinished())
					playAnimation('idle');

			case '':
			  	playAnimation('idle');

			default:
			  	playAnimation('idle');
		}
	}

	public function playAnimation(name:String, fallback:String = null, restart = false):Void
	{
		// Attempt to play the animation
		if (hasAnimation(name))
		{
			animation.play(name, restart, false, 0);
			return;
		}
	  
		// Play the fallback animation if the requested animation was not found
		if (fallback != null && hasAnimation(fallback))
		{
			animation.play(fallback, restart, false, 0);
			return;
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
