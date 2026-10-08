package funkin.psychlua;

import openfl.utils.Assets;

#if (LUA_ALLOWED)
class FlxAnimateFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "makeFlxAnimateSprite", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?loadFolder:String = null, ?path:String = null) {
			tag = tag.replace('.', '');
			var lastSprite = MusicBeatState.getVariables().get(tag);
			if(lastSprite != null)
			{
				lastSprite.kill();
				PlayState.instance.remove(lastSprite);
				lastSprite.destroy();
			}

			var mySprite:ModchartAnimateSprite = new ModchartAnimateSprite(x, y);
			if(loadFolder != null)  mySprite.frames = Paths.loadAnimateAtlas(loadFolder, path);
			MusicBeatState.getVariables().set(tag, mySprite);
			mySprite.active = true;
		});

		Lua_helper.add_callback(lua, "loadAnimateAtlas", function(tag:String, folderOrImg:String, ?path:String = null) {
			var spr:FlxAnimate = MusicBeatState.getVariables().get(tag);
			if(spr != null) spr.frames = Paths.loadAnimateAtlas(folderOrImg, path);
		});
		
		Lua_helper.add_callback(lua, "addAnimationBySymbol", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false)
		{
			var obj:FlxAnimate = cast MusicBeatState.getVariables().get(tag);
			if(obj == null) return false;

			obj.anim.addBySymbol(name, symbol, framerate, loop, flipX);
	
			var obj2:ModchartAnimateSprite = cast (obj, ModchartAnimateSprite);
			if(obj2 != null) obj2.playAnim(name, true); //is ModchartAnimateSprite
			else obj.anim.play(name, true);

			return true;
		});

		Lua_helper.add_callback(lua, "addAnimationByFrameLabel", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false)
			{
				var obj:FlxAnimate = cast MusicBeatState.getVariables().get(tag);
				if(obj == null) return false;
	
				obj.anim.addByFrameLabel(name, symbol, framerate, loop, flipX);
		
				var obj2:ModchartAnimateSprite = cast (obj, ModchartAnimateSprite);
				if(obj2 != null) obj2.playAnim(name, true); //is ModchartAnimateSprite
				else obj.anim.play(name, true);
	
				return true;
			});

		Lua_helper.add_callback(lua, "addAnimationBySymbolIndices", function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false)
		{
			var obj:FlxAnimate = cast MusicBeatState.getVariables().get(tag);
			if(obj == null) return false;

			if(indices == null)
				indices = [0];
			else if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					var parsed:Null<Int> = Std.parseInt(strIndices[i]);
					if (parsed != null) myIndices.push(parsed);
				}
				indices = myIndices;
			}

			obj.anim.addBySymbolIndices(name, symbol, indices, framerate, loop, flipX);

			var obj2:ModchartAnimateSprite = cast (obj, ModchartAnimateSprite);
			if(obj2 != null) obj2.playAnim(name, true); //is ModchartAnimateSprite
			else obj.anim.play(name, true);

			return true;
		});
	}
}
#end