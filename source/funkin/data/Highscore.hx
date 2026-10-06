package funkin.data;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();

	public static var songMisses:Map<String, Int> = new Map<String, Int>();
	public static var songRank:Map<String, Int> = new Map<String, Int>();

	public static function resetSong(song:String, diff:Int = 0, variation:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff, variation);
		setScore(daSong, 0);
		setRating(daSong, 0);
		setMisses(daSong, 0);
		setRank(daSong, 6);
	}

	public static function resetWeek(week:String, diff:Int = 0, variation:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff, variation);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?variation:Int = 0, ?rating:Float = -1, ?misses:Int = 0, ?rank:Int = 6):Void
	{
		if(song == null) return;
		var daSong:String = formatSong(song, diff, variation);

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
			{
				setScore(daSong, score);
				if(rating >= 0) setRating(daSong, rating);
			}
			if(rank < songRank.get(daSong)) setRank(daSong, rank);
		}
		else
		{
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
			setRank(daSong, rank);
		}

		if (songMisses.exists(daSong))
		{
			if(songMisses.get(daSong) > misses) setMisses(daSong, misses); //we dont care about score max shit
			trace(misses);
		}
		else
			setMisses(daSong, misses);
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0, ?variation:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff, variation);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	static function setMisses(song:String, misses:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songMisses.set(song, misses);
		FlxG.save.data.songMisses = songMisses;
		FlxG.save.flush();
	}

	static function setRank(song:String, rank:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRank.set(song, rank);
		FlxG.save.data.songRank = songRank;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int, variation:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff, variation);
	}

	public static function getScore(song:String, diff:Int, variation:Int):Int
	{
		var daSong:String = formatSong(song, diff, variation);
		// Don't flush a 0 to disk just for a UI lookup -- the old code called
		// setScore(..., 0) which triggers FlxG.save.flush() (sync disk I/O).
		// Just return 0 for unseen songs; the entry is created on actual save.
		return songScores.exists(daSong) ? songScores.get(daSong) : 0;
	}

	public static function getRating(song:String, diff:Int, variation:Int):Float
	{
		var daSong:String = formatSong(song, diff, variation);
		return songRating.exists(daSong) ? songRating.get(daSong) : 0;
	}

	public static function getMisses(song:String, diff:Int, variation:Int):Int
	{
		var daSong:String = formatSong(song, diff, variation);
		return songMisses.exists(daSong) ? songMisses.get(daSong) : 0;
	}

	public static function getRank(song:String, diff:Int, variation:Int):Int
	{
		var daSong:String = formatSong(song, diff, variation);
		return songRank.exists(daSong) ? songRank.get(daSong) : 6;
	}

	public static function getWeekScore(week:String, diff:Int, variation:Int):Int
	{
		var daWeek:String = formatSong(week, diff, variation);
		return weekScores.exists(daWeek) ? weekScores.get(daWeek) : 0;
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
			weekScores = FlxG.save.data.weekScores;

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;

		if (FlxG.save.data.songRating != null)
			songRating = FlxG.save.data.songRating;

		if (FlxG.save.data.songMisses != null)
			songMisses = FlxG.save.data.songMisses;

		if (FlxG.save.data.songRank != null)
			songRank = FlxG.save.data.songRank;
	}
}