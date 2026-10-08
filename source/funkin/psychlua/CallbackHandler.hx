#if LUA_ALLOWED
package funkin.psychlua;

class CallbackHandler
{
	// Reusable Array<Dynamic> pool for the args buffer passed to
	// Reflect.callMethod. The dispatcher is reentrant (a Haxe callback
	// can invoke a Lua function which calls another Haxe callback), so
	// each level pops its own array off the pool and returns it after
	// the call. Exception path skips the return -- the array is just
	// GC'd, no correctness issue.
	static final argPool:Array<Array<Dynamic>> = [];
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			//trace('calling $fname');
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if(cbf == null) 
			{
				//trace('checking last script');
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if(last == null || last.lua != l)
				{
					//trace('looping thru scripts');
					for (script in PlayState.instance.luaArray)
						if (script != null && script != last && script.lua == l)
						{
							cbf = script.callbacks.get(fname);
							// Mirror linc_luajit behaviour: dispatcher updates
							// lastCalledScript so per-script API helpers route correctly.
							FunkinLua.lastCalledScript = script;
							break;
						}
				}
				else cbf = last.callbacks.get(fname);
			}
			
			if(cbf == null) return 0;

			final nparams:Int = Lua.gettop(l);
			final args:Array<Dynamic> = (argPool.length > 0 ? argPool.pop() : []);
			if (args.length != nparams) args.resize(nparams);

			for (i in 0...nparams) {
				args[i] = Convert.fromLua(l, i + 1);
			}

			final ret:Dynamic = Reflect.callMethod(null, cbf, args);

			args.resize(0);
			argPool.push(args);

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:haxe.Exception)
		{
			if(Lua_helper.sendErrorsToLua)
			{
				LuaL.error(l, 'CALLBACK ERROR! ${e.details()}');
				return 0;
			}
			throw e;
		}
		return 0;
	}
}
#end