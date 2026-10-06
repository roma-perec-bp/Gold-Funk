package backend;

//CODE FROM WEDNESDAY INFIDELITY

class Progression
{
	public static var weekProgress:Map<String, {song:Array<String>, weekMisees:Int, weekSocre:Int}> = [];

	public static function load()
		if (FlxG.save.data.weekProgress != null) weekProgress = FlxG.save.data.weekProgress;

	public static function save()
	{
		FlxG.save.data.weekProgress = weekProgress;

		FlxG.save.flush();
	}

	public static function reset()
	{
		weekProgress = [];
		save();
	}
}
