package backend;

class Difficulty
{
	public static final defaultList:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static final defaultVariationList:Array<String> = [
		'Default',
	];
	private static final defaultDifficulty:String = 'Normal'; //The chart that has no postfix and starting difficulty on Freeplay/Story Mode
	private static final defaultVariation:String = 'Default'; //The chart that has no postfix and starting difficulty on Freeplay/Story Mode

	public static var list:Array<String> = [];
	public static var variationList:Array<String> = [];

	inline public static function getFilePath(num:Null<Int> = null, varNum:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;
		if(varNum == null) varNum = PlayState.variation;

		var fullFilePostFix:String = '';

		var difFilePostfix:String = list[num];
		var varFilePostfix:String = variationList[varNum];

		if(difFilePostfix != null && Paths.formatToSongPath(difFilePostfix) != Paths.formatToSongPath(defaultDifficulty))
			difFilePostfix = '-' + difFilePostfix;
		else
			difFilePostfix = '';

		if(varFilePostfix != null && Paths.formatToSongPath(varFilePostfix) != Paths.formatToSongPath(defaultVariation))
			varFilePostfix = '-' + varFilePostfix;
		else
			varFilePostfix = '';

		//FIRST VARIATION AND THEN DIFFICULTY
		fullFilePostFix = varFilePostfix + difFilePostfix;

		return Paths.formatToSongPath(fullFilePostFix);
	}

	inline public static function loadFromWeek(week:WeekData = null)
	{
		if(week == null) week = WeekData.getCurrentWeek();

		var diffStr:String = week.difficulties;
		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.trim().split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
				list = diffs;
		}
		else resetList();

		var varStr:String = week.variations;
		if(varStr != null && varStr.length > 0)
		{
			var vars:Array<String> = varStr.trim().split(',');
			var i:Int = vars.length - 1;
			while (i > 0)
			{
				if(vars[i] != null)
				{
					vars[i] = vars[i].trim();
					if(vars[i].length < 1) vars.remove(vars[i]);
				}
				--i;
			}

			if(vars.length > 0 && vars[0].length > 0)
				variationList = vars;
		}
		else resetVarList();
	}

	inline public static function resetList()
	{
		list = defaultList.copy();
	}

	inline public static function resetVarList()
	{
		variationList = defaultVariationList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>)
	{
		list = diffs.copy();
	}

	inline public static function copyFromVar(variations:Array<String>)
	{
		variationList = variations.copy();
	}

	inline public static function getDiffString(?num:Null<Int> = null, ?canTranslate:Bool = true):String
	{
		var diffName:String = list[num == null ? PlayState.storyDifficulty : num];
		if(diffName == null) diffName = defaultDifficulty;
		return canTranslate ? Language.getPhrase('difficulty_$diffName', diffName) : diffName;
	}

	inline public static function getVarString(?num:Null<Int> = null, ?canTranslate:Bool = true):String
	{
		var varName:String = variationList[num == null ? PlayState.variation : num];
		if(varName == null) varName = defaultVariation;
		return canTranslate ? Language.getPhrase('variation_$varName', varName) : varName;
	}

	inline public static function getDefaultDifficult():String
	{
		return defaultDifficulty;
	}

	inline public static function getDefaultVariation():String
	{
		return defaultVariation;
	}
}