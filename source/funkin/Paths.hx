package funkin;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;


#if MODS_ALLOWED
import funkin.backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";
	inline public static var GIF_EXT = "gif";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var toRemove:Array<String> = [];
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				toRemove.push(key);
			}
		}
		for (i in 0...toRemove.length)
			currentTrackedAssets.remove(toRemove[i]);

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		var soundsToRemove:Array<String> = [];
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				soundsToRemove.push(key);
			}
		}
		for (i in 0...soundsToRemove.length)
			currentTrackedSounds.remove(soundsToRemove[i]);

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			//trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		var freedKeys:Array<String> = [];
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					freedKeys.push(key);
					//trace('deleted $key');
				}
			}
		}
		for (i in 0...freedKeys.length)
			currentTrackedAssets.remove(freedKeys[i]);
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	static public function gif(key:String, ?folder:String)
	{
		#if MODS_ALLOWED
		var file:String = modsGifs(key);
		if(FileSystem.exists(file)) return file;
		#end
		return getPath('gifs/$key.$GIF_EXT', BINARY, folder, true); //TO DO: find a way to cache it
	}

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function sound_string(key:String, ?modsAllowed:Bool = true):String
		return getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, null, modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, difficulty:String = null, variation:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';

		//kill me for this code
		var fileOnlyVar:String = getPath(Language.getFileTranslation(songKey + '-' + variation) + '.$SOUND_EXT', SOUND, 'songs', modsAllowed);
		var fileOnlyDiff:String = getPath(Language.getFileTranslation(songKey + '-' + difficulty) + '.$SOUND_EXT', SOUND, 'songs', modsAllowed);
		var fileBoth:String = getPath(Language.getFileTranslation(songKey + '-' + variation + '-' + difficulty) + '.$SOUND_EXT', SOUND, 'songs', modsAllowed);

		if (#if MODS_ALLOWED FileSystem.exists(fileOnlyVar) || #end Assets.exists(fileOnlyVar))
		{
			if (variation != null && variation != '') songKey += '-' + variation;
		}
		else if (#if MODS_ALLOWED FileSystem.exists(fileOnlyDiff) || #end Assets.exists(fileOnlyDiff))
		{
			if (variation != null && variation != '') songKey += '-' + difficulty;
		}
		else if (#if MODS_ALLOWED FileSystem.exists(fileBoth) || #end Assets.exists(fileBoth))
		{
			if (variation != null && variation != '') songKey += '-' + variation + '-' + difficulty;
		}

		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed);
	}

	inline static public function voices(song:String, postfix:String = null, difficulty:String = null, variation:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;

		//kill me for this code
		var fileOnlyVar:String = getPath(Language.getFileTranslation(songKey + '-' + variation) + '.$SOUND_EXT', SOUND, 'songs', modsAllowed);
		var fileOnlyDiff:String = getPath(Language.getFileTranslation(songKey + '-' + difficulty) + '.$SOUND_EXT', SOUND, 'songs', modsAllowed);
		var fileBoth:String = getPath(Language.getFileTranslation(songKey + '-' + variation + '-' + difficulty) + '.$SOUND_EXT', SOUND, 'songs', modsAllowed);

		if (#if MODS_ALLOWED FileSystem.exists(fileOnlyVar) || #end Assets.exists(fileOnlyVar))
		{
			if (variation != null && variation != '') songKey += '-' + variation;
		}
		else if (#if MODS_ALLOWED FileSystem.exists(fileOnlyDiff) || #end Assets.exists(fileOnlyDiff))
		{
			if (variation != null && variation != '') songKey += '-' + difficulty;
		}
		else if (#if MODS_ALLOWED FileSystem.exists(fileBoth) || #end Assets.exists(fileBoth))
		{
			if (variation != null && variation != '') songKey += '-' + variation + '-' + difficulty;
		}

		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	// Build the cache key. When a parentFolder is supplied we prefix it so
	// `image("foo")` and `image("foo", "songs")` no longer collide on the
	// same cache slot. When no folder is given the key stays plain so
	// existing callers (LoadingState.preloadGraphic, etc.) still match.
	inline static function trackedKey(key:String, ?parentFolder:String):String
		return parentFolder != null ? '$parentFolder:$key' : key;

	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/$key') + '.png';
		var trackKey:String = trackedKey(key, parentFolder);
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(trackKey)) {
			var cached:FlxGraphic = currentTrackedAssets.get(trackKey);
			// Some consumers (notably flixel-animate's FlxAnimateSpritemapCollection)
			// will call FlxG.bitmap.remove() on shared spritemap graphics during
			// their destroy/useCount cleanup. The cache entry would then point at
			// a destroyed FlxGraphic and crash on the next draw, so re-create it.
			if (cached != null && !cached.isDestroyed) {
				localTrackedAssets.push(trackKey);
				return cached;
			}
			currentTrackedAssets.remove(trackKey);
		}
		// Compat fallback: a previous call with no parentFolder may have
		// cached this image under the bare key. Honor that hit so mods that
		// mix folder/no-folder calls don't double-load.
		if (parentFolder != null && currentTrackedAssets.exists(key)) {
			var cached:FlxGraphic = currentTrackedAssets.get(key);
			if (cached != null && !cached.isDestroyed) {
				localTrackedAssets.push(key);
				return cached;
			}
			currentTrackedAssets.remove(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, IMAGE, parentFolder, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null)
			{
				trace('Bitmap not found: $file | key: $key');
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var trackKey:String = trackedKey(key, parentFolder);
		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, trackKey);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(trackKey, graph);
		localTrackedAssets.push(trackKey);
		return graph;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, !ignoreMods);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);

		if (imageLoaded == null) return null; // every path below resolves to null frames anyway

		// See getSparrowAtlas.
		var cached:FlxAtlasFrames = FlxAtlasFrames.findFrame(imageLoaded);
		if (cached != null) return cached;

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, parentFolder, true);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder, true);
			if(OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, parentFolder);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	static public function getMultiAnimateAtlas(keys:Array<String>, ?parentFolder:String = null, ?unique:Bool = false):FlxAtlasFrames
	{
		var textureList:Array<FlxAtlasFrames> = [];
		var parentFrames:FlxAtlasFrames;
		if(keys.length > 1)
		{
			var mainTexture:FlxAnimateFrames = Paths.loadAnimateAtlas(keys[0].trim(), parentFolder, unique);
			textureList.push(mainTexture);
			for (i in 1...keys.length)
			{
				var subTexture:FlxAnimateFrames = Paths.loadAnimateAtlas(keys[i].trim(), parentFolder, unique);
				subTexture.parent.destroyOnNoUse = false;

				if(textureList != null)
					textureList.push(subTexture);
			}
			/*var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.loadAnimateAtlas(keys[i].trim(), parentFolder, unique);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}*/
			parentFrames = FlxAnimateFrames.combineAtlas(textureList);
		}
		else
		{
			parentFrames = Paths.loadAnimateAtlas(keys[0].trim(), parentFolder, unique);
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null; // missing image -> avoid openfl spamming "null" asset-id errors

		// The from* parsers reuse an atlas already parsed for this graphic, but only once handed the
		// description -- so reading it off disk first is wasted on every call after the first.
		var cached:FlxAtlasFrames = FlxAtlasFrames.findFrame(imageLoaded);
		if (cached != null) return cached;

		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null;

		// See getSparrowAtlas.
		var cached:FlxAtlasFrames = FlxAtlasFrames.findFrame(imageLoaded);
		if (cached != null) return cached;

		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		if (imageLoaded == null) return null;

		// See getSparrowAtlas.
		var cached:FlxAtlasFrames = FlxAtlasFrames.findFrame(imageLoaded);
		if (cached != null) return cached;

		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s\/\\*?|]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			#if sys
			if(FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsGifs(key:String)
		return modFolders('gifs/' + key + '.' + GIF_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}
	#end

	public static function loadAnimateAtlas(folderOrImg:Dynamic, parentFolder:String = null, ?unique:Bool = false):FlxAnimateFrames
	{
		var animationContent:String = null;
		var spritemaps:Array<animate.FlxAnimateFrames.SpritemapInput> = [];
		var cacheKey:String = null;
		var meta:String = null;

		// Some Animate exports save JSON with a UTF-8 BOM (0xEF 0xBB 0xBF), which
		// haxe.format.JsonParser rejects with "Invalid char 65279 at position 0".
		inline function stripBom(str:String):String {
			if (str != null && str.length > 0 && str.charCodeAt(0) == 0xFEFF)
				return str.substr(1);
			return str;
		}

		// Allow callers to pass already-loaded JSON text (or a path to a file).
		inline function resolveJson(value:Dynamic):String {
			if (value == null) return null;
			if (Std.isOfType(value, String)) {
				var str:String = cast value;
				// Treat as a filesystem path if it looks like one; otherwise assume raw JSON.
				if (str.length < 4096 && (str.indexOf('{') < 0 || #if sys FileSystem.exists(str) #else false #end))
					return stripBom(File.getContent(str));
				return stripBom(str);
			}
			return stripBom(Std.string(value));
		}
		
		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var folder:String = cast folderOrImg;
			cacheKey = 'images/$folder';

			if (animationContent == null)
				animationContent = stripBom(getTextFromFile('$cacheKey/Animation.json'));

			// Optional metadata.json shipped by newer exports.
			var metadataContent:String = stripBom(getTextFromFile('$cacheKey/metadata.json'));
			meta = metadataContent;

			// Collect every `spritemap<N>.json` (and the un-indexed `spritemap.json`)
			// that exists next to the Animation.json. Different Animate exports use
			// different starting indices (Psych mods commonly ship `spritemap1.*`),
			// so we cannot bail out on the first miss.
			for (i in 0...10) {
				var st:String = (i == 0) ? '' : '$i';
				var json:String = stripBom(getTextFromFile('$cacheKey/spritemap$st.json'));
				if (json == null) continue;
				var graphic = image('$folder/spritemap$st');
				if (graphic == null) {
					trace('Paths.loadAnimateAtlas: spritemap$st.json found but image is missing for "$cacheKey".');
					continue;
				}
				spritemaps.push({source: graphic, json: json});
			}
			if (spritemaps.length == 0) {
				trace('Paths.loadAnimateAtlas: no spritemap*.json found under "$cacheKey".');
				return null;
			}
		}

		var parentFrames:FlxAnimateFrames = FlxAnimateFrames.fromAnimate(animationContent, spritemaps, meta, cacheKey, unique, {cacheOnLoad: true});
		if(parentFrames != null  && ClientPrefs.data.cacheOnGPU) parentFrames.parent.bitmap.disposeImage();
		return parentFrames;

		/*var parentFrames:FlxAnimateFrames = FlxAnimateFrames.fromAnimate(getPath('images/' + originalPath, parentFolder), null, null, null, false, {cacheOnLoad: true});
		if(parentFrames != null  && ClientPrefs.data.cacheOnGPU) parentFrames.parent.bitmap.disposeImage();
		return parentFrames;*/
		
	}

	/**
	 * Evicts a cached Animate atlas so the next `loadAnimateAtlas` re-parses it
	 * from scratch (e.g. after changing a load-time setting like `swfMode`).
	 *
	 * IMPORTANT: this destroys the cached `FlxAnimateFrames` and its graphics, so
	 * every live `FlxAnimate` still pointing at this atlas must be reloaded right
	 * after — otherwise drawing a dangling reference throws "sprite was destroyed".
	 */
	 public static function clearAnimateAtlasCache(folderOrImg:String):Void {
		if (folderOrImg == null) return;
		var key:String = 'images/$folderOrImg';
		@:privateAccess {
			var cached = animate.FlxAnimateFrames._cachedAtlases.get(key);
			if (cached != null) {
				animate.FlxAnimateFrames._cachedAtlases.remove(key);
				cached.destroy();
			}
		}
	}
}
