package states.editors;

import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;
import backend.ClientPrefs;

class ModchartEditorState extends MusicBeatState
{
    public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();

	var bottomText:FlxText;
	var bottomBG:FlxSprite;

    public static var STRUM_X = 42; // 42 БРАТУХА КЕРЕМОВСКАЯ ОБЛАСТЬ!!!!!!!!!!
	public static var STRUM_X_MIDDLESCROLL = -278;

    override function create()
    {
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Modchart Editor", null);
        #end

        var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
        var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
        for (i in 0...4)
        {
            var targetAlpha:Float = 1;
            if (player < 1)
            {
                if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
                else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
            }
    
            var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, 1);
            babyArrow.downScroll = ClientPrefs.data.downScroll;
            babyArrow.alpha = targetAlpha;
                
            playerStrums.add(babyArrow)
            opponentStrums.add(babyArrow);
        }

        strumLineNotes.add(babyArrow);
        babyArrow.playerPosition();

        bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, "Modchart Editor is unfinished.", 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
    }

    override function update(elapsed:Float)
    {
        if (controls.BACK)
        {
            MusicBeatState.switchState(new TitleState());
        }
    }
}