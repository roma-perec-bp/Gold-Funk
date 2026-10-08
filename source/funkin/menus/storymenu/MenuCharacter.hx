package funkin.menus.storymenu;

import openfl.utils.Assets;
import haxe.Json;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
	var antialiasing:Null<Bool>;
}

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	private static var DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf') {
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();
		
		color = FlxColor.WHITE;
		alpha = 1;

		hasConfirmAnimation = false;
		switch(character) {
			case '':
				visible = false;
				dontPlayAnim = true;
			default:
				var characterPath:String = 'images/menucharacters/' + character + '.json';

				var path:String = Paths.getPath(characterPath, TEXT);
				var missing:Bool = false;
				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path))
				#end
				{
					missing = true;
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				var charFile:MenuCharacterFile = null;
				if (!missing) {
					try {
						#if MODS_ALLOWED
						charFile = Json.parse(File.getContent(path));
						#else
						charFile = Json.parse(Assets.getText(path));
						#end
					} catch (e:Dynamic) {
						trace('Error loading menu character file of "$character": $e');
					}
				}

				if (charFile == null) {
					// Fallback used to point at characters/bf.json (a Character JSON,
					// not a MenuCharacterFile) which guaranteed an NPE on charFile.image,
					// charFile.position, etc. Use a synthetic default instead.
					charFile = dummyFile();
				}
				frames = Paths.getSparrowAtlas('menucharacters/' + charFile.image);
				if (frames == null) {
					visible = false;
					dontPlayAnim = true;
				} else {
					animation.addByPrefix('idle', charFile.idle_anim, 24);

					var confirmAnim:String = charFile.confirm_anim;
					if (confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim) {
						animation.addByPrefix('confirm', confirmAnim, 24, false);
						if (animation.getByName('confirm') != null) // check for invalid animation
							hasConfirmAnimation = true;
					}
					flipX = (charFile.flipX == true);

					if (charFile.scale != 1) {
						scale.set(charFile.scale, charFile.scale);
						updateHitbox();
					}
					if (charFile.position != null && charFile.position.length >= 2)
						offset.set(charFile.position[0], charFile.position[1]);
					animation.play('idle');

					antialiasing = (charFile.antialiasing != false && ClientPrefs.data.antialiasing);
				}
		}
	}

	private static function dummyFile():MenuCharacterFile {
		return {
			image: 'bf',
			scale: 1.0,
			position: [0, 0],
			idle_anim: 'BF idle dance',
			confirm_anim: 'BF HEY!!',
			flipX: false,
			antialiasing: true
		};
	}
}
