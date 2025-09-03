package states;

import states.editors.StageEditorState;
import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import haxe.ds.ObjectMap;

import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if !flash
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import shaders.Shaders; //idk why but that worked
import shaders.*;
import flixel.addons.display.FlxRuntimeShader;
#end

import shaders.ErrorHandledShader;

import objects.VideoSprite;
import objects.Note.EventNote;
import objects.*;
import states.stages.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	var cameraFollowPoint:FlxObject = new FlxObject();
	var followCharacter:Bool = false;
    var noteCamOffset:Float = 30;

	var curFocusedChar:String;
	
	var cameraFollowTween:FlxTween;
	var cameraZoomTween:FlxTween;
	var cameraHudZoomTween:FlxTween;
	var cameraNotesZoomTween:FlxTween;

	public var currentCameraZoom:Float = 1.0;
	var cameraBopMultiplier:Float = 1.0;

	var defaultHUDCameraZoom:Float = 1.0;
	var camHudBopMult:Float = 1.0;

	var defaultNotesCameraZoom:Float = 0.95;
	var camNotesBopMult:Float = 1.0;

	public var camZoomingDecay:Float = 1;
	public var camZoomingDecayHud:Float = 1;

	var cameraBopIntensity:Float = 1.015;
	var hudCameraZoomIntensity:Float = 0.015 * 2.0;
	var cameraZoomRate:Int = 4;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpHoldSplashes:FlxTypedGroup<SustainSplash> = new FlxTypedGroup<SustainSplash>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	private var curSong:String = "";

	var offsetX:Float = 650; // How far to the right of the player you want the combo to appear
	var offsetY:Float = 300; // How far above the player you want the combo to appear
	var playerX:Float;
	var playerY:Float;

	private var opponentHealthDrain:Bool = false;
	private var opponentHealthDrainAmount:Float = 0.023;
	private var singingShakeArray:Array<Bool> = [false, false];

	public var shakeBeat = false;
	public var shakeDec:Int = 1;

	public var goHealthDamageBeat:Bool = false;
	public var beatHealthDrain:Float = 0.023; //mb can be good???
	public var beatHealthStep:Int = 4;

	public var gfSpeed:Int = 1;

	public var health(default, set):Float = 1;
	private var lerpHealth:Float = 1;

	public var combo:Int = 0;
	public var comboGot:Int = 10;
	public var comboIsInCamGame:Bool = false;

	public var shaderUpdates:Array<Float->Void> = [];

	//omg
	public var camGameShaders:Array<Dynamic> = [];
	public var camHUDShaders:Array<Dynamic> = [];
	public var camNotesShaders:Array<Dynamic> = [];
	public var camHudOverlayShaders:Array<Dynamic> = [];
	public var camOtherShaders:Array<Dynamic> = [];

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	public static var isFirstSongInCampaign:Bool = true;
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var frozenCharacters:ObjectMap<Character, Bool> = new ObjectMap();

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camOverlayHUD:FlxCamera; //does same as camHUD but above notes ye
	public var camGame:FlxCamera;
	public var camNotes:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var subtitlesTxt:FlxText;
	var timeTxt:FlxText;

	var trailBf:FlxTrail;
	var trailDad:FlxTrail;
	var trailGf:FlxTrail;

	var scoreTxtTween:FlxTween;
	var subtitlesTxtTween:FlxTween;
	var prevTxt:String;
	var subTimer:FlxTimer;

	var solidColBeh:FlxSprite;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	var stageZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;
	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearStoredMemory();
		if(nextReloadAll)
		{
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camNotes = new FlxCamera();
		camOverlayHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOverlayHUD.bgColor.alpha = 0;
		camNotes.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camNotes, false);
		FlxG.cameras.add(camOverlayHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		noteCamOffset = SONG.followCamOffset;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;
		stageZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		cameraSpeed += SONG.cameraSpeedMult;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': new StageWeek1(); 			//Week 1

			#if BASE_GAME_FILES
			case 'spooky': new Spooky();				//Week 2
			case 'philly': new Philly();				//Week 3
			case 'limo': new Limo();					//Week 4
			case 'mall': new Mall();					//Week 5 - Cocoa, Eggnog
			case 'mallEvil': new MallEvil();			//Week 5 - Winter Horrorland
			case 'school': new School();				//Week 6 - Senpai, Roses
			case 'schoolEvil': new SchoolEvil();		//Week 6 - Thorns
			case 'tank': new Tank();					//Week 7 - Ugh, Guns, Stress
			case 'phillyStreets': new PhillyStreets(); 	//Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin': new PhillyBlazin();	//Weekend 1 - Blazin
			#end
		}
		if(isPixelStage) introSoundsSuffix = '-pixel';

		if(SONG.countdownSuffix != null) introSoundsSuffix += SONG.countdownSuffix;

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		
		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		resetCamera();
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('stages/' + curStage + '.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('stages/' + curStage + '.hx'); #end

		// CHARACTER SCRIPTS
		if(gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);
		#end

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		uiPostGroup = new FlxSpriteGroup();
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);
		add(uiPostGroup);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled' && !PlayState.SONG.disableTimeBar);
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 21.5, 400, "", 20);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 6), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		noteGroup.add(strumLineNotes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		generateSong();

		noteGroup.add(grpHoldSplashes);
		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return isPixelStage ? health : lerpHealth, 0, 2);
		healthBar.scale.set(0.85, 0.85);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		if(PlayState.SONG.swapPlayers)
			healthBar.leftToRight = true;
		else
			healthBar.leftToRight = false;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 35, FlxG.width, "", 16);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiPostGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camNotes];
		comboGroup.cameras = [camHUD];
		uiPostGroup.cameras = [camOverlayHUD];

		if(PlayState.SONG.comboInGameCam) comboOnCamGame(true, PlayState.SONG.comboX, PlayState.SONG.comboY);

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		setupCameraToSong();
		resetCamera();

		if(eventNotes.length > 0)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if(!ClientPrefs.data.missSounds) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnScripts('onCreatePost');

		if (PlayState.SONG.fadeOutStart)
		{
			if(PlayState.SONG.fadeCount)
			{
				if (!PlayState.SONG.inFrontFade)
					FlxG.camera.fade(FlxColor.BLACK, 0.0001, false, null, true);
				else
					camOther.fade(FlxColor.BLACK, 0.0001, false, null, true);
			}
			else
			{
				if (!PlayState.SONG.inFrontFade)
					FlxG.camera.fade(FlxColor.BLACK, PlayState.SONG.fadeDuration, true, null, true);
				else
					camOther.fade(FlxColor.BLACK, PlayState.SONG.fadeDuration, true, null, true);
			}
		}
		
		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0001; //cant make it invisible or it won't allow precaching

		SustainSplash.startCrochet = Conductor.stepCrochet;
		var splashHold:SustainSplash = new SustainSplash();
		grpHoldSplashes.add(splashHold);
		splashHold.alpha = 0.0001;

		super.create();
		Paths.clearUnusedMemory();

		cacheCountdown();
		cachePopUpScore();

		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if(videoCutscene != null && videoCutscene.videoSprite != null) videoCutscene.videoSprite.bitmap.rate = value;
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		if(PlayState.SONG.originalHealthColors)
			healthBar.setColors(0xFFFF0000, 0xFF66FF33);
		else
			healthBar.setColors(
				FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), 
				FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2])
			);
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(Iris.instances.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String):Dynamic
		return variables.get(tag);

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if(forMidSong) videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
			else add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		skipCountdown = SONG.skipCountdown;

		//when first song in week or freeplay one ALWAYS go true if data one is null
		if (isFirstSongInCampaign)
			skipArrowStartTween = true;
		else
			skipArrowStartTween = false;

		skipArrowStartTween = SONG.skipArrowTween;

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0);
			generateStaticArrows(1);

			if (SONG.swapNotes)
			{
				if(!ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset != 'Forced MiddleScroll')
				{
					for (i in 0...playerStrums.length) {
						var ogDadStrums = opponentStrums.members[i].x;
						var ogBfStrums = playerStrums.members[i].x;

						playerStrums.members[i].x = ogDadStrums;
						opponentStrums.members[i].x = ogBfStrums;
					}
				}
			}
			
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y + ((!isStoryMode && !skipArrowStartTween) ? 0 : 25));

				//same thing but can be updated any time for modcharts so it wont override default one if needs
				setOnScripts('curPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('curPlayerStrumY' + i, playerStrums.members[i].y + ((!isStoryMode && !skipArrowStartTween) ? 0 : 25));
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y + ((!isStoryMode && !skipArrowStartTween) ? 0 : 25));

				//same thing but can be updated any time for modcharts so it wont override default one if needs
				setOnScripts('curOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('curOpponentStrumY' + i, opponentStrums.members[i].y + ((!isStoryMode && !skipArrowStartTween) ? 0 : 25));
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						if (!SONG.quietCountdown) FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						if (!SONG.quietCountdown)
						{
							countdownReady = createCountdownSprite(introAlts[0], antialias);
							FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						}
						tick = TWO;
					case 2:
						if (!SONG.quietCountdown)
						{
							countdownSet = createCountdownSprite(introAlts[1], antialias);
							FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						}
						tick = ONE;
					case 3:
						if (!SONG.quietCountdown)
						{
							countdownGo = createCountdownSprite(introAlts[2], antialias);
							FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						}
						tick = GO;
					case 4:
						tick = START;

						if (PlayState.SONG.fadeOutStart)
						{
							if(PlayState.SONG.fadeCount)
							{
								if (!PlayState.SONG.inFrontFade)
									FlxG.camera.fade(FlxColor.BLACK, PlayState.SONG.fadeDuration, true, null, true);
								else
									camHUD.fade(FlxColor.BLACK, PlayState.SONG.fadeDuration, true, null, true);
							}
						}
				}

				if(!skipArrowStartTween)
				{
					notes.forEachAlive(function(note:Note) {
						if((ClientPrefs.data.opponentStrums && !PlayState.SONG.opponentDisabled) || note.mustPress)
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if((ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll') && !note.mustPress)
								note.alpha *= 0.35;
						}
					});
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite();

		if(Assets.exists(Paths.getSharedPath(Language.getFileTranslation('images/$image') + '.xml')))
		{
			spr.frames = Paths.getSparrowAtlas(image);
			spr.animation.addByPrefix(image, image, 24, false);
			spr.animation.play(image);
		}
		else
		{
			spr.loadGraphic(Paths.image(image));
		}

		spr.cameras = [camOther];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);

		if (PlayState.isPixelStage)
		{
			new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				remove(spr);
				spr.destroy();
			});
		}
		else if(stageUI == "normal" && image == "go")
		{
			new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				FlxTween.tween(spr.scale, {x: 0, y: 0}, Conductor.stepCrochet * 2 / 1000, {
					ease: FlxEase.expoIn,
					onComplete: function(twn:FlxTween)
					{
						remove(spr);
						spr.destroy();
					}
				});
			});
		}
		else
		{
			FlxTween.tween(spr, {y: spr.y + 50, alpha: 0}, Conductor.crochet / 1000, {
				ease: FlxEase.cubeIn,
				onComplete: function(twn:FlxTween)
				{
					remove(spr);
					spr.destroy();
				}
			});
		}
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function updateScoreText()
	{
		var str:String = '?';
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str = '(${percent}%) - ' + Language.getPhrase(ratingFC);
		}

		var tempScore:String;
		if(!instakillOnMiss) tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Accuracy: {3}', [FlxStringUtil.formatMoney(songScore, false, true), songMisses, str]);
		else tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Accuracy: {2}', [FlxStringUtil.formatMoney(songScore, false, true), str]);
		scoreTxt.text = tempScore;
	}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function doSubtitlesBop():Void {
		if(subtitlesTxtTween != null)
			subtitlesTxtTween.cancel();

		subtitlesTxt.scale.x = 1.075;
		subtitlesTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(subtitlesTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				subtitlesTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition < vocals.length)
		{
			vocals.time = time - Conductor.offset;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
			vocals.play();
		}
		else vocals.pause();

		if (Conductor.songPosition < opponentVocals.length)
		{
			opponentVocals.time = time - Conductor.offset;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
			opponentVocals.play();
		}
		else opponentVocals.pause();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		if (PlayState.SONG.timeBarFake != null && PlayState.SONG.timeBarFake != 0)
			songLength = PlayState.SONG.timeBarFake * 1000;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns: Int = 4;

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if(oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		try
		{
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if(eventsChart != null)
				for (event in eventsChart.events) //Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch(e:Dynamic) {}

		var oldNote:Note = null;
		var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
		var ghostNotesCaught:Int = 0;
		var daBpm:Float = Conductor.bpm;
	
		for (section in sectionsData)
		{
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes: Array<Dynamic> = section.sectionNotes[i];
				var spawnTime: Float = songNotes[0];
				var noteColumn: Int = Std.int(songNotes[1] % totalColumns);
				var holdLength: Float = songNotes[2];
				var noteType: String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				var sustainType: String = songNotes[4];
				if (Math.isNaN(holdLength))
					holdLength = 0.0;

				var altAnimSuffix: String = songNotes[5];
				var customSongDur: Float = songNotes[6];
				var altHey: String = songNotes[7];

				//same thing as in chart editor
				if(songNotes[8] == '0' || songNotes[8] == null) songNotes[8] = true;
				var lightStrumCheck: Bool = songNotes[8];

				var noAnimationCheck: Bool = songNotes[9];

				var ghostType: String = songNotes[10];

				if(songNotes[11] == '0' || songNotes[11] == null) songNotes[11] = true;
				var catchNote: Bool = songNotes[11];

				var noMissAnimationCheck: Bool = songNotes[12];
				var invisibleNote: Bool = songNotes[13];

				var gottaHitNote:Bool = (songNotes[1] < totalColumns);

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in unspawnNotes) {
						var matches: Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
						if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON) {
							if (evilNote.tail.length > 0)
								for (tail in evilNote.tail)
								{
									tail.destroy();
									unspawnNotes.remove(tail);
								}
							evilNote.destroy();
							unspawnNotes.remove(evilNote);
							ghostNotesCaught++;
							//continue;
						}
					}
				}

				var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
				var isAlt: Bool = section.altAnim && !gottaHitNote;
				swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);

				if(altAnimSuffix == '0' || altAnimSuffix == null || altAnimSuffix == '') //WHAT THE FUCK HOW IT'S FUCKING ZERO, IT TOOK ME HOURS TO FIGURE OUT WHY ANIMATIONS DIDN'T PLAYED
					swagNote.animSuffix = isAlt ? "-alt" : "";
				else
					swagNote.animSuffix = isAlt ? "-alt" : altAnimSuffix;

				swagNote.customSingTime = customSongDur;
				swagNote.heyAnim = altHey;
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = holdLength;
				swagNote.noteType = noteType;
				swagNote.sustainType = sustainType;

				swagNote.lightStrum = lightStrumCheck;
				swagNote.noAnimation = noAnimationCheck;

				swagNote.ghostType = ghostType;

				swagNote.noMissAnimation = noMissAnimationCheck;
				swagNote.catchNote = catchNote;

				swagNote.visible = !invisibleNote;
				
				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
				final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
				if(roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, true);
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.customSingTime = swagNote.customSingTime;
						sustainNote.heyAnim = swagNote.heyAnim;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.sustainType = swagNote.sustainType;
						sustainNote.lightStrum = swagNote.lightStrum;
						sustainNote.noAnimation = swagNote.noAnimation;
						sustainNote.ghostType = swagNote.ghostType;
						sustainNote.noMissAnimation = swagNote.noMissAnimation;
						sustainNote.catchNote = swagNote.catchNote;
						sustainNote.visible = swagNote.visible;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll')
						{
							sustainNote.x += 310;
							if(noteColumn > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll')
				{
					swagNote.x += 310;
					if(noteColumn > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);

				oldNote = swagNote;
			}
		}
		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');

		if(PlayState.SONG.swapMustPlay)
		{
			for (note in unspawnNotes) 
				note.mustPress = !note.mustPress;
		}

		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		switch(event.event)
		{
			case "Solid Graphic Behind Characters":
				solidColBeh = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				solidColBeh.scale.set(5,5);
				solidColBeh.alpha = 0.001;
				addBehindGF(solidColBeh);

			case 'Subtitles': //creates at event so 
				subtitlesTxt = new FlxText(0, FlxG.height * 0.75, FlxG.width - 800, "", 24);
				subtitlesTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				subtitlesTxt.scrollFactor.set();
				subtitlesTxt.borderSize = 1.25;
				subtitlesTxt.screenCenter(X);
				subtitlesTxt.alpha = 0;
				uiPostGroup.add(subtitlesTxt); //might add another camHUD overlay or backlay or whatever :p
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound

			case 'Play Video':
				startVideo(event.value1, true, true, false, false); //Precache video
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
		if(returnedValue != null && returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2],
			value3: event[1][i][3],
			value4: event[1][i][4],
			value5: event[1][i][5]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, 
			subEvent.value1 != null ? subEvent.value1 : '', 
			subEvent.value2 != null ? subEvent.value2 : '', 
			subEvent.value3 != null ? subEvent.value3 : '', 
			subEvent.value4 != null ? subEvent.value4 : '', 
			subEvent.value5 != null ? subEvent.value5 : '',
			subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		switch(PlayState.SONG.strumOffset)
		{
			case 'Player Focus':
				STRUM_X = 0;
			case 'Opponent Focus':
				STRUM_X = 84;
		}

		var strumLineX:Float = (ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll') ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums || PlayState.SONG.opponentDisabled) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll') targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.y -= 25;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 25, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Forced MiddleScroll')
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
			#if VIDEOS_ALLOWED
 			if(videoCutscene != null) videoCutscene.pause();
 			#end
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);
			#if VIDEOS_ALLOWED
 			if(videoCutscene != null) videoCutscene.resume();
 			#end

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	#if DISCORD_ALLOWED
	override public function onFocus():Void
	{
		super.onFocus();
		if (!paused && health > 0)
		{
			resetRPC(Conductor.songPosition > 0.0);
		}
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!paused && health > 0 && autoUpdateRPC)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
	}
	#end

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var checkVocals = [vocals, opponentVocals];
		for (voc in checkVocals)
		{
			if (FlxG.sound.music.time < vocals.length)
			{
				voc.time = FlxG.sound.music.time;
				#if FLX_PITCH voc.pitch = playbackRate; #end
				voc.play();
			}
			else voc.pause();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;
	var holdBonus:Float = 250;

	var char:Character;
	var charBF:Character;

	override public function update(elapsed:Float)
	{
		if(!inCutscene && !paused && !freezeCamera) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
			var idleAnim:Bool = ((PlayState.SONG.swapPlayers ? dad : boyfriend).getAnimationName().startsWith('idle') || (PlayState.SONG.swapPlayers ? dad : boyfriend).getAnimationName().startsWith('danceLeft') || (PlayState.SONG.swapPlayers ? dad : boyfriend).getAnimationName().startsWith('danceRight'));
			if(!startingSong && !endingSong && idleAnim) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		if(!isPixelStage) lerpHealth = FlxMath.lerp(lerpHealth, health, .2 / (ClientPrefs.data.framerate / 60)); //плавный хелбар

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1'))
				openChartEditor();
			else if (controls.justPressed('debug_2'))
				openCharacterEditor();
			else if (controls.justPressed('debug_3'))
				openStageEditor();
		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset)
			{
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= Conductor.offset)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (cameraZoomRate > 0.0)
		{
			cameraBopMultiplier = FlxMath.lerp(1.0, cameraBopMultiplier, 0.95 * camZoomingDecay * playbackRate / (ClientPrefs.data.framerate / 60)); // Lerp bop multiplier back to 1.0x
			var zoomPlusBop:Float = currentCameraZoom * cameraBopMultiplier; // Apply camera bop multiplier.
			FlxG.camera.zoom = zoomPlusBop; // Actually apply the zoom to the camera.
		
			camHudBopMult = FlxMath.lerp(1, camHudBopMult, 0.95 * camZoomingDecayHud * playbackRate / (ClientPrefs.data.framerate / 60)); // Lerp bop multiplier back to 1.0x
			var zoomHudPlusBop:Float = defaultHUDCameraZoom * camHudBopMult; // Apply camera bop multiplier.
			camHUD.zoom = zoomHudPlusBop;  // Actually apply the zoom to the camera.
			camOverlayHUD.zoom = zoomHudPlusBop;  // ditto

			camNotesBopMult = FlxMath.lerp(1, camNotesBopMult, 0.95 * camZoomingDecayHud * playbackRate / (ClientPrefs.data.framerate / 60)); // Lerp bop multiplier back to 1.0x
			var zoomNotesPlusBop:Float = defaultNotesCameraZoom * camNotesBopMult; // Apply camera bop multiplier.
			camNotes.zoom = zoomNotesPlusBop;  // Actually apply the zoom to the camera.
		}

		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].gfSection)
				charBF = gf;
			else
				charBF = boyfriend;

			if(curFocusedChar == 'bf' && charBF.getAnimationName() == "idle" || charBF.getAnimationName() == "danceLeft" || charBF.getAnimationName() == "danceRight")
			{
				FlxG.camera.targetOffset.x = 0;
				FlxG.camera.targetOffset.y = 0;
			}

			if (SONG.notes[curSection].gfSection)
				char = gf;
			else
				char = dad;

			if(curFocusedChar == 'dad' && (char.getAnimationName() == "idle" || char.getAnimationName() == "danceLeft" || char.getAnimationName() == "danceRight"))
			{
				FlxG.camera.targetOffset.x = 0;
                FlxG.camera.targetOffset.y = 0;
			}
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();
				else
					playerDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var i:Int = 0;
						while(i < notes.length)
						{
							var daNote:Note = notes.members[i];
							if(daNote == null) continue;

							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && daNote.visible && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.catchNote)
								opponentNoteHit(daNote);

							if(daNote.mustPress && !daNote.visible && !daNote.ignoreNote && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
								invisibleNoteHitPlayer(daNote);
							
							if (daNote.wasGoodHit && !daNote.mustPress && !daNote.catchNote && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteMiss(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit) && daNote.visible)
									noteMiss(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
							if(daNote.exists) i++;
						}
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		for (holdNote in notes.members)
		{
			if (holdNote == null || !holdNote.alive || !holdNote.mustPress) continue;

			if (holdNote.noteWasHit && !holdNote.missed && holdNote.isSustainNote)
			{
				if(!isPixelStage && ClientPrefs.data.sustainGain) health += 0.05 * healthGain * elapsed;

				if(!cpuControlled && !practiceMode)
				{
					songScore += Std.int(holdBonus * elapsed);
					updateScoreText();
				}
			}
		}

		for (char in frozenCharacters.keys())
			if (frozenCharacters.get(char)) char.animPaused = true;
			else char.animPaused = false;

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);

		for (i in shaderUpdates) i(elapsed);
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(0.85, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(0.85, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if(PlayState.SONG.swapPlayers)
		{
			iconP2.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : (healthBar.percent > 80 && iconP2.hasThirdIcon) ? 2 : 0;
			iconP1.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : (healthBar.percent < 20 && iconP1.hasThirdIcon) ? 2 : 0;
		}
		else
		{
			iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : (healthBar.percent > 80 && iconP1.hasThirdIcon) ? 2 : 0;
			iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : (healthBar.percent < 20 && iconP2.hasThirdIcon) ? 2 : 0;
		}
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		chartingMode = true;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	function openStageEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new StageEditorState(curStage, null, true));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && gameOverTimer == null)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				canResync = false;
				canPause = false;
				#if VIDEOS_ALLOWED
				if(videoCutscene != null)
				{
					videoCutscene.destroy();
					videoCutscene = null;
				}
				#end

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				FlxG.camera.filters = [];

				if(GameOverSubstate.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						FlxG.sound.music.stop();
						openSubState(new GameOverSubstate(boyfriend));
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverSubstate(boyfriend));
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			var value3:String = '';
			if(eventNotes[0].value3 != null)
				value3 = eventNotes[0].value3;

			var value4:String = '';
			if(eventNotes[0].value4 != null)
				value4 = eventNotes[0].value4;

			var value5:String = '';
			if(eventNotes[0].value5 != null)
				value5 = eventNotes[0].value5;

			triggerEvent(eventNotes[0].event, value1, value2, value3, value4, value5, leStrumTime);
			eventNotes.shift();
		}
	}

	//most of the new events are from that one fnf trollge mod and ddto bad ending
	public function triggerEvent(eventName:String, value1:String, value2:String, value3:String, value4:String, value5:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		var flValue3:Null<Float> = Std.parseFloat(value3);
		var flValue4:Null<Float> = Std.parseFloat(value4);
		var flValue5:Null<Float> = Std.parseFloat(value5);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		if(Math.isNaN(flValue3)) flValue3 = null;
		if(Math.isNaN(flValue4)) flValue4 = null;
		if(Math.isNaN(flValue5)) flValue5 = null;

		switch(eventName) {
			case 'CountDown':
				final introAlts:Array<String> = switch(stageUI)
				{
					case "pixel":  ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default:       ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				};
				final antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
	
				switch(value1.toLowerCase().trim()) {
					case 'pre-ready': 
						if(value2 == 'true' || value2 == 'True') FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 'ready': 
						countdownReady = createCountdownSprite(introAlts[0], antialias); 
						if(value2 == 'true' || value2 == 'True') FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 'set':
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						if(value2 == 'true' || value2 == 'True') FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 'go':
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						if(value2 == 'true' || value2 == 'True') FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

				var forceLol:Bool;
				if(value2 == 'true')
					gf.idleForce = true;
				else
					gf.idleForce = false;

			case 'Set DAD Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 2;
				dad.danceEveryNumBeats = Math.round(flValue1);

				var forceLol:Bool;
				if(value2 == 'true')
					dad.idleForce = true;
				else
					dad.idleForce = false;

			case 'Set BF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 2;
				boyfriend.danceEveryNumBeats = Math.round(flValue1);

				var forceLol:Bool;
				if(value2 == 'true')
					boyfriend.idleForce = true;
				else
					boyfriend.idleForce = false;

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.7) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					cameraBopMultiplier += flValue1;
					camHudBopMult += flValue2;
					camNotesBopMult += flValue2;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					if(value3 == 'true') char.uninterruptableAnim = true;
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Change Icon':
				var iconToSwitch:HealthIcon = 
				switch(value1.toLowerCase().trim())
				{
					case 'dad' | 'opponent' | 'p2':
						iconP2;
					default:
						iconP1;
				}

				iconToSwitch.changeIcon(value2);

			case 'Change Combo Camera':
				var args:Array<String> = value2.split(",");
				var bools:Bool = false;

				var xTarg:Float = Std.parseFloat(args[0]);
				var yTarg:Float = Std.parseFloat(args[1]);

				switch(value1)
				{
					case 'camHUD' | 'hud' | 'camhud':
						bools = false;
					default:
						bools = true;
				}

				comboOnCamGame(bools, xTarg, yTarg);

			case "Focus Camera":
				var coordsStr:Array<String> = value4.split(",");
					
				var char:String = value1 ?? "dad";
		
				var duration:Float = flValue2;
				if (flValue2 == null)
					duration = 4.0;
		
				var ease:String = value3 ?? "CLASSIC";
		
				var targetX:Float = Std.parseFloat(coordsStr[0]);
				var targetY:Float = Std.parseFloat(coordsStr[1]);
		
				if (Math.isNaN(targetX))
					targetX = 0;
				if (Math.isNaN(targetY))
					targetY = 0;
		
				switch (char.toLowerCase())
				{
					case "origin":
						trace("Chose origin");
					case "bf":
						targetX += boyfriend.getMidpoint().x - boyfriend.cameraPosition[0] + boyfriendCameraOffset[0] - 100;
						targetY += boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] + boyfriendCameraOffset[1] - 100;
						curFocusedChar = 'bf';
					case "gf":
						targetX += gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0];
						targetY += gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1];

						if(!SONG.notes[curSection].mustHitSection)
							curFocusedChar = 'dad';
						else
							curFocusedChar = 'bf';
					default:
						targetX += dad.getMidpoint().x + dad.cameraPosition[0] + opponentCameraOffset[0] + 150;
						targetY += dad.getMidpoint().y + dad.cameraPosition[1] + opponentCameraOffset[1] - 100;
						curFocusedChar = 'dad';
						
				}
		
				switch (ease)
				{
					case 'CLASSIC': // Old-school. No ease. Just set follow point.
						resetCamera(false, false, false);
						cancelCameraFollowTween();
						cameraFollowPoint.setPosition(targetX, targetY);
					case 'INSTANT': // Instant ease. Duration is automatically 0.
						tweenCameraToPosition(targetX, targetY, 0);
					default:
						var durSeconds:Float = Conductor.stepCrochet * duration / 1000;
						tweenCameraToPosition(targetX, targetY, durSeconds, LuaUtils.getTweenEaseByString(ease));
				}

			case 'Change Object Layer':
				var leObj:FlxBasic = LuaUtils.getObjectDirectly(value1);
				if(leObj != null)
				{
					var groupOrArray:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : LuaUtils.getTargetInstance();
					groupOrArray.remove(leObj, true);
					groupOrArray.insert(Std.parseInt(value2), leObj);
					return;
				}
				addTextToDebug('Change Object Layer event: Object $value3 doesn\'t exist!', FlxColor.RED);

			case 'Update Strum Position Variable':
				for (i in 0...playerStrums.length) {
					setOnScripts('curPlayerStrumX' + i, playerStrums.members[i].x);
					setOnScripts('curPlayerStrumY' + i, playerStrums.members[i].y);
				}
				for (i in 0...opponentStrums.length) {
					setOnScripts('curOpponentStrumX' + i, opponentStrums.members[i].x);
					setOnScripts('curOpponentStrumY' + i, opponentStrums.members[i].y);
					//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
				}

			case "Set Camera Bop":
				var rate:Int = Std.parseInt(value1);
				var intensity:Float = flValue2;

				if (flValue3 == null) flValue3 = 1;

				cameraBopIntensity = 0.015 * intensity + 1.0;
				hudCameraZoomIntensity = 0.015 * intensity * 2.0;

				camZoomingDecay = flValue3;
				camZoomingDecayHud = flValue3;

				cameraZoomRate = rate;

			case "Zoom Camera":	
				var zoom:Float = flValue2 ?? 1.0;
				var duration:Float = flValue3 ?? 4.0;
					
				var mode:String = value4 ?? "direct";
				var isDirectMode:Bool = mode == "direct";
		
				if (value1 == "")
					value1 = "linear";
		
				switch(value1)
				{
					case "INSTANT":
						tweenCameraZoom(zoom, 0, isDirectMode);
					default:
						var durSeconds:Float = Conductor.stepCrochet * duration / 1000;
						tweenCameraZoom(zoom, durSeconds, isDirectMode, LuaUtils.getTweenEaseByString(value1));
				}

			case "Zoom Hud Camera":
				var durSeconds:Float = Conductor.stepCrochet * flValue2 / 1000;

				if (cameraHudZoomTween != null)
					cameraHudZoomTween.cancel();

				if (value3 == 'INSTANT')
					// Instant zoom. No tween needed.
				    defaultHUDCameraZoom = flValue1;
				else
					// Zoom tween! Caching it so we can cancel/pause it later if needed.
					cameraHudZoomTween = FlxTween.num(
						defaultHUDCameraZoom,
						flValue1,
						durSeconds / playbackRate,
						{ease: LuaUtils.getTweenEaseByString(value3)},
						function(num:Float) {defaultHUDCameraZoom = num;}
					);

			case "Zoom Notes Camera":
				var durSeconds:Float = Conductor.stepCrochet * flValue2 / 1000;
				
				if (cameraNotesZoomTween != null)
					cameraNotesZoomTween.cancel();

				if (value3 == 'INSTANT')
					// Instant zoom. No tween needed.
				    defaultNotesCameraZoom = flValue1;
				else
					// Zoom tween! Caching it so we can cancel/pause it later if needed.
					cameraNotesZoomTween = FlxTween.num(
						defaultNotesCameraZoom,
						flValue1,
						durSeconds / playbackRate,
						{ease: LuaUtils.getTweenEaseByString(value3)},
						function(num:Float) {defaultNotesCameraZoom = num;}
					);

			case "Camera Angle":
				var angleChange:Float = flValue2 ?? 0;
				var duration:Float = flValue3 ?? 4.0;
		
				if (value1 == "")
					value1 = "linear";

				var durSeconds:Float = Conductor.stepCrochet * duration / 1000;

				switch(value4)
				{
					case 'camgame' | 'camGame':
						FlxTween.cancelTweensOf(camGame.angle);
						FlxTween.tween(camGame, {angle: angleChange}, durSeconds / playbackRate, {ease: LuaUtils.getTweenEaseByString(value1)});
					case 'camhud' | 'camHUD' | 'hud':
						FlxTween.cancelTweensOf(camHUD.angle);
						FlxTween.tween(camHUD, {angle: angleChange}, durSeconds / playbackRate, {ease: LuaUtils.getTweenEaseByString(value1)});
					case 'camnotes' | 'camNotes' | 'notes':
						FlxTween.cancelTweensOf(camNotes.angle);
						FlxTween.tween(camNotes, {angle: angleChange}, durSeconds / playbackRate, {ease: LuaUtils.getTweenEaseByString(value1)});
					case 'camoverlayhud' | 'camOverlayHUD' | 'overlay':
						FlxTween.cancelTweensOf(camOverlayHUD.angle);
						FlxTween.tween(camOverlayHUD, {angle: angleChange}, durSeconds / playbackRate, {ease: LuaUtils.getTweenEaseByString(value1)});
					case 'camOther' | 'camother' | 'other':
						FlxTween.cancelTweensOf(camOther.angle);
						FlxTween.tween(camOther, {angle: angleChange}, durSeconds / playbackRate, {ease: LuaUtils.getTweenEaseByString(value1)});
				}

			case 'Change Note Camera Move Offset':
				noteCamOffset = flValue1;

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Shake Beat':
				if(!ClientPrefs.data.flashing) return;

				shakeBeat = !shakeBeat;
				shakeDec = Std.parseInt(value2);

			case 'Subtitles':
				var duration:Float = flValue2 ?? 4.0;
				var durSeconds:Float = Conductor.stepCrochet * duration / 1000;
				var textCache:FlxText = subtitlesTxt;
				
				var metadata:Array<String> = value5.split(',');
				var sizes:Array<String> = value4.split(',');

				var size:Int = Std.parseInt(sizes[0]);
				var outlineSize:Float = Std.parseFloat(sizes[1]);

				var intro:String = metadata[0];
				var fade:String = metadata[1];
				var font:String = metadata[2];

				if (subtitlesTxt != null) {
					if (value1.length > 0) {
						subtitlesTxt.text = value1;
						subtitlesTxt.alpha = 1;
						if(font != null)
							subtitlesTxt.font = Paths.font(font);
						else
							subtitlesTxt.font = Paths.font('vcr.ttf');

						if(fade == 'true' || fade == 'fadeOut' || fade == 'fade out' || fade == 'fade') //WE FADING WITH THIS ONE
						{
							//FlxTween.cancelTweensOf(subtitlesTxt);
							FlxTween.tween(subtitlesTxt, {alpha: 0}, 1, {
								startDelay: durSeconds / playbackRate
							});
						}
						else
						{
							if(subTimer != null) subTimer.cancel();
							subTimer = new FlxTimer().start(durSeconds / playbackRate, function(tmr:FlxTimer) {
								subtitlesTxt.alpha = 0;
							});
						}
					} else {
						subtitlesTxt.text = null;
						subtitlesTxt.alpha = 0;
					}
				}
	
				if (value3 == null || value3 == '')
					subtitlesTxt.color = 0xFFFFFFFF;
				else
				{
					switch(value3)
					{
						case 'dad':
							subtitlesTxt.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
						case 'gf':
							subtitlesTxt.color = FlxColor.fromRGB(gf.healthColorArray[0], gf.healthColorArray[1], gf.healthColorArray[2]);
						case 'bf':
							subtitlesTxt.color = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
						default:
							subtitlesTxt.color = Std.parseInt(value3);
					}
				}

				if (sizes[0] == null || sizes[0] == '')
					size = 24;

				if (sizes[1] == null || sizes[1] == '')
					outlineSize = 1.25;

				subtitlesTxt.size = size;
				subtitlesTxt.borderSize = outlineSize;
			
				switch(intro)
				{
					case 'bop':
						doSubtitlesBop();
					case 'fade in':
						subtitlesTxt.alpha = 0;
						FlxTween.tween(subtitlesTxt, {alpha: 1}, 0.3 / playbackRate, {ease: FlxEase.circOut});
					case 'fly away':
						subtitlesTxt.alpha = 0;
						FlxTween.cancelTweensOf(subtitlesTxt);

						var subtitlesCache:FlxText = new FlxText(0, FlxG.height * 0.75, FlxG.width - 800, prevTxt, textCache.size);
						subtitlesCache.setFormat(Paths.font("vcr.ttf"), 24, textCache.color, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						subtitlesCache.scrollFactor.set();
						subtitlesCache.borderSize = 1.25;
						subtitlesCache.screenCenter(X);
						subtitlesCache.alpha = 1;
						uiPostGroup.add(subtitlesCache);

						FlxTween.tween(subtitlesCache, {alpha: 0, y: subtitlesCache.y - 100}, 1, {
							ease: FlxEase.expoOut,
							onComplete:
							function (twn:FlxTween)
							{
								subtitlesCache.destroy();
							}
						});

						prevTxt = subtitlesTxt.text;

						subtitlesTxt.y = FlxG.height;
						FlxTween.tween(subtitlesTxt, {alpha: 1, y: FlxG.height * 0.75}, 1, {
							ease: FlxEase.expoOut,
						});
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2, value3];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD, camNotes];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, Conductor.stepCrochet * duration / 1000);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 4;

					var ease = LuaUtils.getTweenEaseByString(value3);

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, Conductor.stepCrochet * flValue2 / 1000 / playbackRate, {ease: ease, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Flash Camera':
				var color:FlxColor = 0xFFFFFFFF;
	
				if (value1 == null || value1 == '')
					color = 0xFFFFFFFF;

				color = Std.parseInt(value1);

				if (flValue2 == null) flValue2 = 4;

				if(!ClientPrefs.data.flashing && value1 != '0xFF000000') return;
	
				switch(value3.toLowerCase().trim()) {
					case 'camhud' | 'HUD' | 'hud':
						camHUD.flash(color, Conductor.stepCrochet * flValue2 / 1000, null, true);
					case 'camnotes' | 'NOTES' | 'notes':
						camHUD.flash(color, Conductor.stepCrochet * flValue2 / 1000, null, true);
					case 'camoverlayhud' | 'OVERLAY' | 'overlay':
						camOverlayHUD.flash(color, Conductor.stepCrochet * flValue2 / 1000, null, true);
					case 'camother' | 'camOther' | 'other':
						camOther.flash(color, Conductor.stepCrochet * flValue2 / 1000, null, true);
					default:
						FlxG.camera.flash(color, Conductor.stepCrochet * flValue2 / 1000, null, true);
				}

			case 'Fade Camera':
				if(!ClientPrefs.data.flashing) return;

				var color:FlxColor = 0xFFFFFFFF;
	
				if (value1 == null || value1 == '')
					color = 0xFFFFFFFF;

				color = Std.parseInt(value1);

				if (flValue2 == null) flValue2 = 4;

				var fade:Bool;
				if(value4 == 'true')
					fade = true;
				else
					fade = false;
	
				switch(value3.toLowerCase().trim()) {
					case 'camhud' | 'hud':
						camHUD.fade(color, Conductor.stepCrochet * flValue2 / 1000, fade, null, true);
					case 'camnotes' | 'notes':
						camNotes.fade(color, Conductor.stepCrochet * flValue2 / 1000, fade, null, true);
					case 'camoverlayhud' | 'OVERLAY' | 'overlay':
						camOverlayHUD.fade(color, Conductor.stepCrochet * flValue2 / 1000, fade, null, true);
					case 'camother' | 'other':
						camOther.fade(color, Conductor.stepCrochet * flValue2 / 1000, fade, null, true);
					default:
						FlxG.camera.fade(color, Conductor.stepCrochet * flValue2 / 1000, fade, null, true);
				}

			case "Solid Graphic Behind Characters": //BLAMMED LI-
				var color:FlxColor = 0xFF000000;
	
				if (value3 == null || value3 == '')
					color = 0xFF000000;

				color = Std.parseInt(value3);

				if (flValue1 == null)
					flValue1 = 0;

				if (flValue2 == null)
					flValue2 = 4;

				FlxTween.tween(solidColBeh, {alpha: flValue1}, Conductor.stepCrochet * flValue2 / 1000);
				solidColBeh.color = color;

			case 'Set Health':
				if(value2 != null)
				{
					var ease = LuaUtils.getTweenEaseByString(value2);
					FlxTween.tween(this, {health: flValue1}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});
				}
				else
					health = flValue1;

			case 'Add Health':
				var newhealth:Float = (health + flValue1);

				if(value2 != null)
				{
					var ease = LuaUtils.getTweenEaseByString(value2);
					FlxTween.tween(this, {health: newhealth}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});
				}
				else
					health += newhealth;

			case 'Singing Shakes':
				if (!ClientPrefs.data.flashing) return;
				
				var charType:Int = 0;
				switch(value2.toLowerCase().trim())
				{
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType))
							charType = 0;
				}
				switch (value1.toLowerCase().trim())
				{
					case 'on' | 'true':
						singingShakeArray[charType] = true;
					case 'off' | 'false':
						singingShakeArray[charType] = false;
				}

			case 'Opponent Drain':
				switch (value1.toLowerCase().trim())
				{
					case 'on' | 'true':
						opponentHealthDrain = true;
					case 'off' | 'false':
						opponentHealthDrain = false;
				}

				var drain:Float = flValue2;
				if (Math.isNaN(drain) || value2 == null)
					drain = 0.023; //в ивенте написано 0.023 и значить вот эту поставлю
				
				opponentHealthDrainAmount = drain;

			case 'Beat Drain':
				if(flValue3 == null || flValue3 < 1) flValue3 = 8;
				switch (value1.toLowerCase().trim())
				{
					case 'on' | 'true':
						goHealthDamageBeat = true;
					case 'off' | 'false':
						goHealthDamageBeat = false;
				}

				var drain:Float = flValue2;
				if (Math.isNaN(drain) || value2 == null)
					drain = 0.023;

				beatHealthStep = Math.round(flValue3);
				
				beatHealthDrain = drain;

			case 'Set Char Position':
				var charType:Int = 0;

				var split:Array<String> = value2.split(',');
				var xMove:Float = Std.parseFloat(split[0]);
				var yMove:Float = Std.parseFloat(split[1]);

				switch (value1)
				{
					case 'dad' | 'Dad' | 'DAD':
						charType = 1;
					case 'gf' | 'GF' | 'girlfriend' | 'Girlfriend':
						charType = 2;
					default:
						charType = 0;
				}

				switch (charType)
				{
					case 1:
						if(Math.isNaN(xMove)) dadGroup.x = DAD_X;
						else dadGroup.x = xMove;

						if(Math.isNaN(yMove)) dadGroup.y = DAD_Y;
						else dadGroup.y = yMove;

					case 2:
						if(Math.isNaN(xMove)) gfGroup.x = GF_X;
						else gfGroup.x = xMove;
	
						if(Math.isNaN(yMove)) gfGroup.y = GF_Y;
						else gfGroup.y = yMove;

					default:
						if(Math.isNaN(xMove)) boyfriendGroup.x = BF_X;
						else boyfriendGroup.x = xMove;

						if(Math.isNaN(yMove)) boyfriendGroup.y = BF_Y;
						else boyfriendGroup.y = yMove;
				}

			case 'Set Char Position Tween':
				var charType:Int = 0;

				var split:Array<String> = value2.split(',');
				var xMove:Float = Std.parseFloat(split[0]);
				var yMove:Float = Std.parseFloat(split[1]);

				var ease = LuaUtils.getTweenEaseByString(value4);

				if (flValue3 == null)
					flValue3 = 4;

				switch (value1)
				{
					case 'dad' | 'Dad' | 'DAD':
						charType = 1;
					case 'gf' | 'GF' | 'girlfriend' | 'Girlfriend':
						charType = 2;
					default:
						charType = 0;
				}

				switch (charType)
				{
					case 1:
						if(Math.isNaN(xMove)) xMove = DAD_X;
						if(Math.isNaN(yMove)) yMove = DAD_Y;

						FlxTween.cancelTweensOf(dadGroup);
						FlxTween.tween(dadGroup, {x: xMove, y: yMove}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});

					case 2:
						if(Math.isNaN(xMove)) xMove = GF_X;
						if(Math.isNaN(yMove)) yMove = GF_Y;

						FlxTween.cancelTweensOf(gfGroup);
						FlxTween.tween(gfGroup, {x: xMove, y: yMove}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});

					default:
						if(Math.isNaN(xMove)) xMove = BF_X;
						if(Math.isNaN(yMove)) yMove = BF_Y;

						FlxTween.cancelTweensOf(boyfriendGroup);
						FlxTween.tween(boyfriendGroup, {x: xMove, y: yMove}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});
				}

			case 'Set Char Color':
				var char:Character = boyfriend;
				var val2:Int = Std.parseInt(value2);

				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					default:
						char = boyfriend;
				}

				if (Math.isNaN(val2))
					val2 = 0xFFFFFFFF;
				
				char.color = val2;

			case 'Set Char Color Tween':
				var char:Character = boyfriend;

				if (flValue3 == null)
					flValue3 = 4;

				var ease = LuaUtils.getTweenEaseByString(value4);
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					default:
						char = boyfriend;
				}

				var curColor:FlxColor = char.color;
				curColor.alphaFloat = char.alpha;
				
				FlxTween.color(char, Conductor.stepCrochet * flValue3 / 1000, curColor, CoolUtil.colorFromString(value2), {ease: ease});

			case 'Set Char Color Transform':
				var char:Character = boyfriend;

				var split:Array<String> = value2.split(',');
				var splitAlpha:Array<String> = value3.split(',');
				var redOff:Int = 0;
				var greenOff:Int = 0;
				var blueOff:Int = 0;
				var alphaOff:Int = 0;
				var redMult:Int = 0;
				var greenMult:Int = 0;
				var blueMult:Int = 0;
				var alphaMult:Int = 0;
				if(split[0] != null) redOff = Std.parseInt(split[0].trim());
				if(split[1] != null) greenOff = Std.parseInt(split[1].trim());
				if(split[2] != null) blueOff = Std.parseInt(split[2].trim());
				if(split[3] != null) alphaOff = Std.parseInt(split[3].trim());
				if(splitAlpha[0] != null) redMult = Std.parseInt(splitAlpha[0].trim());
				if(splitAlpha[1] != null) greenMult = Std.parseInt(splitAlpha[1].trim());
				if(splitAlpha[2] != null) blueMult = Std.parseInt(splitAlpha[2].trim());
				if(splitAlpha[3] != null) alphaMult = Std.parseInt(splitAlpha[3].trim());

				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					default:
						char = boyfriend;
				}
				char.colorTransform.redOffset = redOff;
				char.colorTransform.greenOffset = greenOff;
				char.colorTransform.blueOffset = blueOff;
				char.colorTransform.alphaOffset = alphaOff;

				char.colorTransform.redMultiplier = redMult;
				char.colorTransform.greenMultiplier = greenMult;
				char.colorTransform.blueMultiplier = blueMult;
				char.colorTransform.alphaMultiplier = alphaMult;

			case 'Set Char Color Transform Tween':
				var char:Character = boyfriend;

				var split:Array<String> = value2.split(',');
				var splitAlpha:Array<String> = value3.split(',');
				var redOff:Int = 0;
				var greenOff:Int = 0;
				var blueOff:Int = 0;
				var alphaOff:Int = 0;
				var redMult:Int = 0;
				var greenMult:Int = 0;
				var blueMult:Int = 0;
				var alphaMult:Int = 0;
				if(split[0] != null) redOff = Std.parseInt(split[0].trim());
				if(split[1] != null) greenOff = Std.parseInt(split[1].trim());
				if(split[2] != null) blueOff = Std.parseInt(split[2].trim());
				if(split[3] != null) alphaOff = Std.parseInt(split[3].trim());
				if(splitAlpha[0] != null) redMult = Std.parseInt(splitAlpha[0].trim());
				if(splitAlpha[1] != null) greenMult = Std.parseInt(splitAlpha[1].trim());
				if(splitAlpha[2] != null) blueMult = Std.parseInt(splitAlpha[2].trim());
				if(splitAlpha[3] != null) alphaMult = Std.parseInt(splitAlpha[3].trim());

				if (flValue4 == null || flValue4 == 0)
					flValue4 = 4;

				var ease = LuaUtils.getTweenEaseByString(value5);

				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					default:
						char = boyfriend;
				}
				
				FlxTween.tween(char.colorTransform, {redOffset: redOff, greenOffset: greenOff, blueOffset: blueOff, alphaOffset: alphaOff, redMultiplier: redMult, greenMultiplier: greenMult, blueMultiplier: blueMult, alphaMultiplier: alphaMult}, Conductor.stepCrochet * flValue4 / 1000, {ease: ease});

			case 'Add trail':
				var charType:Int = 0;
				var val3:Int = Std.parseInt(value3);

				var split:Array<String> = value1.split(',');
				var length:Int = 0;
				var delay:Int = 0;
				var alpha:Float = 0;
				var diff:Float = 0;

				if(split[0] != null) length = Std.parseInt(split[0].trim());
				if(split[1] != null) delay = Std.parseInt(split[1].trim());
				if(split[2] != null) alpha = Std.parseFloat(split[2].trim());
				if(split[3] != null) diff = Std.parseFloat(split[3].trim());
				if(Math.isNaN(length)) length = 4;
				if(Math.isNaN(delay)) delay = 24;
				if(Math.isNaN(alpha)) alpha = 0.3;
				if(Math.isNaN(diff)) diff = 0.069;

				switch (value2)
				{
					case 'dad' | 'Dad' | 'DAD':
						charType = 1;
					case 'gf' | 'GF' | 'girlfriend' | 'Girlfriend':
						charType = 2;
					default:
						charType = 0;
				}

				var blendValue = LuaUtils.blendModeFromString(value4);

				switch (charType)
				{
					case 1:
						trailDad = new FlxTrail(dad, null, length, delay, alpha, diff);
						trailDad.blend = blendValue;
						if (!Math.isNaN(val3)) trailDad.color = val3;
						addBehindDad(trailDad);
					case 2:
						trailGf = new FlxTrail(gf, null, length, delay, alpha, diff);
						trailGf.blend = blendValue;
						if (!Math.isNaN(val3)) trailGf.color = val3;
						addBehindGF(trailGf);
					default:
						trailBf = new FlxTrail(boyfriend, null, length, delay, alpha, diff);
						trailBf.blend = blendValue;
						if (!Math.isNaN(val3)) trailBf.color = val3;
						addBehindBF(trailBf);
				}

			case 'Remove trail':
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						remove(trailGf);
						trailGf.destroy();
					case 'dad' | 'opponent':
						remove(trailDad);
						trailDad.destroy();
					default:
						remove(trailBf);
						trailBf.destroy();
				}
			case 'Update Vocals':
				vocals.volume = flValue1;
				opponentVocals.volume = flValue2;

			case 'Character Visibility':
				var char:Character = boyfriend;
				var val2:Int = Std.parseInt(value2);

				if (flValue3 == null)
					flValue3 = 4;

				var ease = LuaUtils.getTweenEaseByString(value4);
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					default:
						char = boyfriend;
				}

				if (Math.isNaN(val2))
					val2 = 0xFFFFFFFF;

				FlxTween.cancelTweensOf(char);
				FlxTween.tween(char, {alpha: flValue2}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});

			case 'Strumline Visibility':
				var strum:FlxTypedGroup<StrumNote>;

				var ease = LuaUtils.getTweenEaseByString(value4);
						
				if (Math.isNaN(flValue2))
					flValue2 = 1;
				else if (flValue2 == 0)
					flValue2 = 0.0001;
						
				if (Math.isNaN(flValue3) || flValue3 <= 0)
					flValue3 = 4;
						
				switch (value1)
					{
						case 'dad' | 'opponent':
						{
							strum = opponentStrums;
						
							if (ClientPrefs.data.middleScroll || PlayState.SONG.strumOffset == 'Enable MiddleScroll')
								flValue2 *= 0.35;
						}
						default:
							strum = playerStrums;
					}

				for (i in 0...strum.members.length)
				{
					FlxTween.cancelTweensOf(strum.members[i]);
					FlxTween.tween(strum.members[i], {alpha: flValue2}, Conductor.stepCrochet * flValue3 / 1000, {ease: ease});
				}

			case 'UI visibilty':
				var ease = LuaUtils.getTweenEaseByString(value3);
				FlxTween.tween(camHUD, {alpha: value1}, Conductor.stepCrochet * flValue2 / 1000, {ease: ease, onComplete: function(twn:FlxTween){}});

			case 'Notes visibilty':
				var ease = LuaUtils.getTweenEaseByString(value3);
				FlxTween.tween(camNotes, {alpha: value1}, Conductor.stepCrochet * flValue2 / 1000, {ease: ease, onComplete: function(twn:FlxTween){}});

			case 'Overlay visibilty':
				var ease = LuaUtils.getTweenEaseByString(value3);
				FlxTween.tween(camOverlayHUD, {alpha: value1}, Conductor.stepCrochet * flValue2 / 1000, {ease: ease, onComplete: function(twn:FlxTween){}});

			case 'Force Dance':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
					if (Math.isNaN(val2))
						val2 = 0;
				
					switch (val2)
					{
						case 1: char = boyfriend;
						case 2: char = gf;
					}
				}
				if(!char.stunned)
				{
					char.specialAnim = false;
					char.dance(true);		
				}
			
			#if VIDEOS_ALLOWED
			case 'Play Video':
				startVideo(value1, true, false);	
			#end
	
			case 'Set Property':
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;

					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], trueValue);
					} else {
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, value3, value4, value5, flValue1, flValue2, flValue3, flValue4, flValue5, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, value3, value4, value5, strumTime]);
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		moveCamera();

		if (gf != null && SONG.notes[sec].gfSection)
		{
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		if (isDad)
			callOnScripts('onMoveCamera', ['dad']);
		else
			callOnScripts('onMoveCamera', ['boyfriend']);
	}

	public function moveCamera()
	{
		var targetX:Float = SONG.notes[curSection].followX;
		var targetY:Float = SONG.notes[curSection].followY;

		if (SONG.notes[curSection].followCam)
		{
			switch (SONG.notes[curSection].charFollow.toLowerCase())
			{
				case "bf":
					targetX += boyfriend.getMidpoint().x - boyfriend.cameraPosition[0] + boyfriendCameraOffset[0] - 100;
					targetY += boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] + boyfriendCameraOffset[1] - 100;
					curFocusedChar = 'bf';
				case "gf":
					targetX += gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0];
					targetY += gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1];

					if(!SONG.notes[curSection].mustHitSection)
						curFocusedChar = 'dad';
					else
						curFocusedChar = 'bf';
				default:
					targetX += dad.getMidpoint().x + dad.cameraPosition[0] + opponentCameraOffset[0] + 150;
					targetY += dad.getMidpoint().y + dad.cameraPosition[1] + opponentCameraOffset[1] - 100;
					curFocusedChar = 'dad';
			}
	
			var ease:String = SONG.notes[curSection].tweenFollow;
			
			switch (ease)
			{
				case 'CLASSIC': // Old-school. No ease. Just set follow point.
					resetCamera(false, false, false);
					cancelCameraFollowTween();
					cameraFollowPoint.setPosition(targetX, targetY);
				case 'INSTANT': // Instant ease. Duration is automatically 0.
					tweenCameraToPosition(targetX, targetY, 0);
				default:
					var durSeconds:Float = Conductor.stepCrochet * SONG.notes[curSection].followTime / 1000;
					tweenCameraToPosition(targetX, targetY, durSeconds, LuaUtils.getTweenEaseByString(ease));
			}
		}

		if (SONG.notes[curSection].zoomCam)
		{
			var ease:String = SONG.notes[curSection].tweenZoom;

			switch(ease)
			{
				case "INSTANT":
					tweenCameraZoom(SONG.notes[curSection].zoom, 0, SONG.notes[curSection].stgZoom);
				default:
					var durSeconds:Float = Conductor.stepCrochet * SONG.notes[curSection].zoomTime / 1000;
					tweenCameraZoom(SONG.notes[curSection].zoom, durSeconds, SONG.notes[curSection].stgZoom, LuaUtils.getTweenEaseByString(ease));
			}
		}
	}	

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			});
			for (daNote in unspawnNotes)
			{
				if(daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie' #if BASE_GAME_FILES, 'debugger' #end]);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				isFirstSongInCampaign = false;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					//prevCamFollow = camFollow;

					Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState(), false, false);
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showMiss:Bool = true;
	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;
	// Stores HUD Objects after notes in a Group
	public var uiPostGroup:FlxSpriteGroup;

	private function cachePopUpScore()
	{
		var uiFolder:String = "ratingPopUps/";
		if (stageUI != "normal")
			uiFolder = uiPrefix + "UI/ratingPopUps/";

		for (rating in ratingsData)
			Paths.image(uiFolder + rating.image + uiPostfix);

		if(showComboNum) for (i in 0...10) Paths.image(uiFolder + 'num' + i + uiPostfix);

		if(showCombo) Paths.image(uiFolder + 'combo' + uiPostfix);
		//Paths.image(uiFolder + 'miss' + uiPostfix);
	}

	var c_PBOT1_MISS = 160;
	var c_PBOT1_PERFECT = 5;
	var c_PBOT1_SCORING_OFFSET = 54.99;
	var c_PBOT1_SCORING_SLOPE = .08;
	var c_PBOT1_MAX_SCORE = 500;
	var c_PBOT1_MIN_SCORE = 5;
	private function popUpScore(note:Note = null):Void
	{
		var texture:String = 'miss';
		var lastCombo:Int = combo;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) {
			for (spr in comboGroup) {
				spr.destroy();
				comboGroup.remove(spr);
			}
		}

		if(note != null) 
		{
			var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
			vocals.volume = 1;

			//tryna do MS based judgment due to popular demand
			var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);
			var score:Int = c_PBOT1_MIN_SCORE;

			totalNotesHit += daRating.ratingMod;
			note.ratingMod = daRating.ratingMod;
			if(!note.ratingDisabled) daRating.hits++;
			note.rating = daRating.name;
			note.hitHealth = daRating.bonusHealth;

			if (noteDiff < c_PBOT1_PERFECT) score = c_PBOT1_MAX_SCORE;
			else if (noteDiff < c_PBOT1_MISS) {
				var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-c_PBOT1_SCORING_SLOPE * (noteDiff - c_PBOT1_SCORING_OFFSET))));
				score = Std.int(c_PBOT1_MAX_SCORE * factor + c_PBOT1_MIN_SCORE);
			}

			/*if (onlySick && (noteDiff > ClientPrefs.data.sickWindow || noteDiff < -ClientPrefs.data.sickWindow))
				doDeathCheck(true);*/

			if(daRating.noteSplash && !note.noteSplashData.disabled && !PlayState.SONG.disableSplash) spawnNoteSplashOnNote(note);

			if(daRating.grayNote)
			{
				grayNoteEarly(note);
				killCombo();
				if (lastCombo > comboGot) comboGot = lastCombo;

				gfComboBreak(lastCombo);
			}
			else
			{
				combo++;
				if(combo > 9999) combo = 9999;
			}

			if(!cpuControlled) {
				songScore += score;
				if(!note.ratingDisabled)
				{
					songHits++;
					totalPlayed++;
					RecalculateRating(false);
				}
			}

			texture = daRating.image;

			/*if(ClientPrefs.data.showMsTiming)
			{
				switch (note.rating)
				{
					case 'shit': currentTimingShown.color = FlxColor.RED;
					case 'bad': currentTimingShown.color = FlxColor.YELLOW;
					case 'good': currentTimingShown.color = FlxColor.CYAN;
					case 'sick': currentTimingShown.color = FlxColor.LIME;
				}
				FlxTween.cancelTweensOf(currentTimingShown);
				FlxTween.cancelTweensOf(currentTimingShown.alpha);
		
				currentTimingShown.alignment = CENTER;
				currentTimingShown.text =  Math.round(Conductor.songPosition - note.strumTime) + "ms";
				currentTimingShown.antialiasing = ClientPrefs.data.antialiasing;
				currentTimingShown.alpha = 1;
			
				FlxTween.tween(currentTimingShown, {alpha: 0.00001},  Conductor.crochet * 0.002 / playbackRate);
			}*/
		}

		if(!ClientPrefs.data.hideHud && showRating)
		{
			var placement:Float = FlxG.width * 0.35;
			var rating:FlxSprite = new FlxSprite();

			var uiFolder:String = "ratingPopUps/";
			var antialias:Bool = ClientPrefs.data.antialiasing;
			
			if (stageUI != "normal")
			{
				uiFolder = uiPrefix + "UI/ratingPopUps/";
				antialias = !isPixelStage;
			}

			rating.loadGraphic(Paths.image(uiFolder + texture + uiPostfix));
			rating.screenCenter();
			rating.x = placement - 40;
			rating.y -= 60;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			if(comboIsInCamGame)
			{
				rating.x += playerX - offsetX;
				rating.y += playerY - offsetY;
			}
			else
			{
				rating.x += ClientPrefs.data.comboOffset[0];
				rating.y -= ClientPrefs.data.comboOffset[1];
			}
		
			rating.antialiasing = antialias;
			comboGroup.add(rating);

			if (!PlayState.isPixelStage)
				rating.setGraphicSize(Std.int(rating.width * 0.6));
			else
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.75));
			
			rating.updateHitbox();

			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});
		}

		if(note != null) 
		{
			if(!ClientPrefs.data.hideHud)
				if (combo >= 10)
					displayCombo(comboGot);
		}
	}

	function displayCombo(?comboGet:Int):Void
	{
		var placement:Float = FlxG.width * 0.35;

		var uiFolder:String = "ratingPopUps/";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/ratingPopUps/";
			antialias = !isPixelStage;
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement + 80;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
	
		if(comboIsInCamGame)
		{
			comboSpr.x += playerX - offsetX;
			comboSpr.y += playerY - offsetY;
		}
		else
		{
			comboSpr.x += ClientPrefs.data.comboOffset[4];
			comboSpr.y -= ClientPrefs.data.comboOffset[5];
		}
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
	
		if (!PlayState.isPixelStage)
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.5));
		else
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.75));
	
		comboSpr.updateHitbox();
	
		if (combo >= comboGet)
			if (showCombo)
				comboGroup.add(comboSpr);

		var daLoop:Int = 0;
		var xThing:Float = 0;

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			
			if(!comboIsInCamGame)
			{
				numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
				numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			}
			else
			{
				numScore.x = placement + (43 * daLoop) - 90 + playerX - offsetX;
				numScore.y += 80 + playerY - offsetY;
			}

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.4));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom * 0.95));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.antialiasing = antialias;

			if(showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || (PlayState.SONG.swapPlayers ? dad : boyfriend).stunned) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit && n.visible;
			return canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else
		{
			if (ClientPrefs.data.ghostTapping)
				callOnScripts('onGhostTap', [key]);
			else
				noteMissPress(key);
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !inCutscene && !(PlayState.SONG.swapPlayers ? dad : boyfriend).stunned && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit && n.visible);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();

			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		final end:Note = daNote.isSustainNote ? daNote.parent.tail[daNote.parent.tail.length - 1] : daNote.tail[daNote.tail.length - 1];
		if (end != null && end.extraData['holdSplash'] != null) {
			end.extraData['holdSplash'].visible = false;
		}

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);

		var charMiss:Character = daNote.gfNote ? gf : boyfriend;
		if(PlayState.SONG.swapPlayers) char = dad;
		if (charMiss != null) frozenCharacters.set(charMiss, false);
	}

	function opponentNoteMiss(daNote:Note):Void {
		daNote.hitByOpponent = true;

		// play character anims
		var char:Character = dad;
		if(PlayState.SONG.swapPlayers) char = boyfriend;
		if((daNote != null && daNote.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (daNote == null || !daNote.noMissAnimation) && char.hasMissAnimations)
		{
			var postfix:String = '';
			if(daNote != null) postfix = daNote.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, daNote.noteData)))] + 'miss' + postfix;
			if (!daNote.isSustainNote) char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		var result:Dynamic = callOnLuas('opponentNoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteMiss', [daNote]);
	}

	function invisibleNoteHitPlayer(note:Note):Void
	{
		// play character anims
		var char:Character = boyfriend;
		if(PlayState.SONG.swapPlayers) char = dad;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noAnimation))
		{
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + suffix;

			if(!note.isSustainNote) char.playAnim(animToPlay, true); //sustain shit later im lazy zzzzzzzzzzzzz
			char.holdTimer = 0;
		}

		var result:Dynamic = callOnLuas('playerInvisibleNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('playerInvisibleNoteHit', [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction, null);
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);

		frozenCharacters.set(PlayState.SONG.swapPlayers ? dad : boyfriend, false);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = pressMissDamage;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				note.multAlpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.multAlpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -[REDACTED]
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				parentNote.alpha = 0.35;
				parentNote.multAlpha = 0.35;
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.alpha = parentNote.alpha;
					child.multAlpha = parentNote.multAlpha;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		if(note != null)
		{
			if(showMiss && !note.isSustainNote) popUpScore(null);
			killCombo();
			if(!endingSong) songMisses++;

			totalPlayed++;
		}

		if (lastCombo > comboGot)
			comboGot = lastCombo;

		health -= subtract * healthLoss;
		if(!practiceMode) songScore -= 10;

		if(!practiceMode) RecalculateRating(true);

		if(ClientPrefs.data.missSounds) FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		var noteTypeName:String = '';

		if(note != null)
			noteTypeName = note.noteType;

		// play character anims
		var char:Character = boyfriend;
		if(PlayState.SONG.swapPlayers) char = dad;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			switch(noteTypeName) { //wip for future notes idk
				default:
					var postfix:String = '';
					if(note != null) postfix = note.animSuffix;

					var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + postfix;
					char.playAnim(animToPlay, true);
			}

			if(char != gf && note != null)
				gfComboBreak(lastCombo);
		}

		vocals.volume = 0;
	}

	/*function findCountAnimations(prefix:String):Array<Int>
	{
		var animNames:Array<String> = gf.animation.getNameList();
	  
		var result:Array<Int> = [];
	  
		for (anim in animNames)
		{
			if (anim.startsWith(prefix))
			{
				var comboNum:Null<Int> = Std.parseInt(anim.substring(prefix.length));
				if (comboNum != null)
					result.push(comboNum);
			}
		}
	  
		  // Sort numerically.
		  result.sort((a, b) -> a - b);
		  return result;
	}*/

	function gfComboBreak(comboBreak:Int)
	{
		if(comboBreak > 70 && gf != null && gf.hasAnimation('sad'))
		{
			gf.playAnim('sad', true);
			gf.specialAnim = true;
		}
	}

	function killCombo():Void
	{
		if (combo != 0)
		{
			combo = 0;
			displayCombo();
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		var charPlay:Character = note.gfNote ? gf : dad;
		if(PlayState.SONG.swapPlayers) charPlay = boyfriend;
		if (charPlay != null) preNoteHitCheck(note, charPlay);

		var heyAnimation:String = 'hey';

		if(note.heyAnim != '0' && note.heyAnim != '' && note.heyAnim != null)
			heyAnimation = note.heyAnim;

		if(note.noteType == 'Hey!' && charPlay.hasAnimation(heyAnimation))
		{
			charPlay.playAnim(heyAnimation, true);
			charPlay.specialAnim = true;
			charPlay.heyTimer = 0.6;
		}
		else if(!note.noAnimation)
		{
			var char:Character = dad;
			if(PlayState.SONG.swapPlayers) char = boyfriend;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;
			if(note.gfNote) char = gf;

			if(char != null)
			{
				if(note.customSingTime == 0)
					char.singDuration = char.jsonDuration;
				else
					char.singDuration = note.customSingTime;

				var holdAnim:String = animToPlay + '-hold';
				if(note.sustainLength != 0 && char.hasAnimation(holdAnim)) 
					animToPlay = holdAnim;

				if(!note.isSustainNote) char.playAnim(animToPlay, true);

				if(note.isSustainNote && note.sustainType == 'stutter') //mm optimized way to do this?
					char.playAnim(animToPlay, true);

				if(!note.isSustainNote && note.ghostType != '' && note.ghostType != null && note.ghostType != '0')
					doGhostAnim('dad', animToPlay, note.ghostType, note.noteData);

				char.holdTimer = 0;
			}
		}

		if(opponentVocals.length <= 0) 
			vocals.volume = 1;
		else
			opponentVocals.volume = 1;

		if(note.lightStrum) strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate, note);
		note.hitByOpponent = true;

		if(note.visible && note.lightStrum) 
			if((ClientPrefs.data.opponentStrums && !PlayState.SONG.opponentDisabled) && !PlayState.SONG.disableHoldCover)
				spawnHoldSplashOnNote(note);

		if (opponentHealthDrain && health >= opponentHealthDrainAmount && !note.gfNote && note.noteType != 'GF Sing')
			health -= opponentHealthDrainAmount;

		if (singingShakeArray[1])
		{
			camGame.shake(0.005, 0.2);
			camHUD.shake(0.005, 0.2);
			camOverlayHUD.shake(0.005, 0.2);
			camNotes.shake(0.005, 0.2);
		}

		if(!note.noAnimation)
		{
			if(SONG.notes[curSection] != null && (PlayState.SONG.swapPlayers ? curFocusedChar == 'bf' : curFocusedChar == 'dad'))
			{
				FlxG.camera.targetOffset.set(0,0);
				switch(note.noteData)
				{
					case 0:
						FlxG.camera.targetOffset.x = -noteCamOffset;
					case 1:
						FlxG.camera.targetOffset.y = noteCamOffset;
					case 2:
						FlxG.camera.targetOffset.y = -noteCamOffset;
					case 3:
						FlxG.camera.targetOffset.x = noteCamOffset;
				}
			}
		}
		
		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		var charSus:Character = note.gfNote ? gf : dad;
		if(PlayState.SONG.swapPlayers) charSus = boyfriend;
		if (charSus != null) noteHitCheck(note, charSus);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		var charPlay:Character = note.gfNote ? gf : boyfriend;
		if(PlayState.SONG.swapPlayers) charPlay = dad;
		if (charPlay != null) preNoteHitCheck(note, charPlay);

		note.wasGoodHit = true;
		note.noteWasHit = true; //пиздец что эту переменную не использовали

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(!note.hitCausesMiss) //Common notes
		{
			if(!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;

				var char:Character = boyfriend;
				if(PlayState.SONG.swapPlayers) char = dad;
				var animCheck:String = 'hey';
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}

				if(note.heyAnim != '0' && note.heyAnim != '' && note.heyAnim != null)
					animCheck = note.heyAnim;

				if(char != null)
				{
					if(note.customSingTime == 0)
						char.singDuration = char.jsonDuration;
					else
						char.singDuration = note.customSingTime;

					var holdAnim:String = animToPlay + '-hold';
					if(note.sustainLength != 0 && char.hasAnimation(holdAnim)) 
						animToPlay = holdAnim;
					
					if(!note.isSustainNote) char.playAnim(animToPlay, true);
					
					if(note.isSustainNote && note.sustainType == 'stutter') //mm optimized way to do this?
						char.playAnim(animToPlay, true);

					if(!note.isSustainNote && note.ghostType != '' && note.ghostType != null && note.ghostType != '0')
						doGhostAnim((char == gf ? 'gf': 'bf'), animToPlay, note.ghostType, note.noteData);
				
					char.holdTimer = 0;

					if(note.noteType == 'Hey!')
					{
						if(char.hasAnimation(animCheck))
						{
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if(note.lightStrum)
			{
				if(!cpuControlled)
				{
					var spr = playerStrums.members[note.noteData];
					if(spr != null) spr.playAnim('confirm', true, [note.rgbShader.r, note.rgbShader.g, note.rgbShader.b]);
				}
				else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate, note);
			}

			vocals.volume = 1;

			if(note.lightStrum && !PlayState.SONG.disableHoldCover) spawnHoldSplashOnNote(note);
			if (!note.isSustainNote)
			{
				var whichAnim:String = '';
				popUpScore(note);

				switch(combo)
				{
					case 50:
						whichAnim = 'cheer';
					case 200:
						whichAnim = 'fawn';
				}

				if(whichAnim != '')
				{
					if(gf != null && gf.hasAnimation(whichAnim))
					{
						gf.playAnim(whichAnim, true);
						gf.specialAnim = true;
					}
				}

				health += note.hitHealth * healthGain;
			}

			if(isPixelStage && ClientPrefs.data.sustainGain) if (note.isSustainNote) health += note.hitHealth * healthGain; //so it wont be smooth in week 6

		}
		else //Notes that count as a miss if you hit them (Hurt notes for example)
		{
			if(!note.noMissAnimation)
			{
				var charPlay:Character = note.gfNote ? gf : boyfriend;
				if(PlayState.SONG.swapPlayers) charPlay = dad;
				switch(note.noteType)
				{
					case 'Hurt Note':
						if(charPlay.hasAnimation('hurt'))
						{
							charPlay.playAnim('hurt', true);
							charPlay.specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if(!note.noteSplashData.disabled && !note.isSustainNote && !PlayState.SONG.disableSplash) spawnNoteSplashOnNote(note);
		}

		if(!note.noAnimation)
		{
			if(SONG.notes[curSection] != null && (PlayState.SONG.swapPlayers ? curFocusedChar == 'dad' : curFocusedChar == 'bf'))
			{
				FlxG.camera.targetOffset.set(0,0);
				switch(note.noteData)
				{
					case 0:
						FlxG.camera.targetOffset.x = -noteCamOffset;
					case 1:
						FlxG.camera.targetOffset.y = noteCamOffset;
					case 2:
						FlxG.camera.targetOffset.y = -noteCamOffset;
					case 3:
						FlxG.camera.targetOffset.x = noteCamOffset;
				}
			}
		}

		if (singingShakeArray[0])
		{
			camGame.shake(0.005, 0.2);
			camHUD.shake(0.005, 0.2);
			camOverlayHUD.shake(0.005, 0.2);
			camNotes.shake(0.005, 0.2);
		}

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);

		var charSus:Character = note.gfNote ? gf : boyfriend;
		if(PlayState.SONG.swapPlayers) charSus = dad;
		if (charSus != null) noteHitCheck(note, charSus);

		if(!note.isSustainNote && !note.badassed) invalidateNote(note);
	}

	public function comboOnCamGame(enable:Bool, targetX:Float = 650, targetY:Float = 300)
	{
		comboIsInCamGame = enable;

		if(enable)
		{
			comboGroup.cameras = [camGame];
			offsetX = targetX; // How far to the right of the player you want the combo to appear
			offsetY = targetY; // How far above the player you want the combo to appear
			playerX = boyfriend.x;
			playerY = boyfriend.y;
		}
		else
		{
			comboGroup.cameras = [camHUD];
			playerX = 0;
			playerY = 0;
		}
	}

	public function grayNoteEarly(note:Note):Void 
	{
		if(!PlayState.SONG.disableNoteRGB)
		{
			note.rgbShader.r = 0xFFA0A0A0;
			note.rgbShader.g = 0xFFFFFFFF;
			note.rgbShader.b = 0xFF000000;
		}
		else //all colorSwap just for this man...
		{
			note.desaturate();
		}

		note.alpha = 0.4;
		note.multAlpha = 0.4;
		note.ignoreNote = true;
		note.blockHit = true;
		note.badassed = true;
		note.active = false;
	}

	//so originally this was port of @vechett codename engine script, port by goat @rodney528
	function preNoteHitCheck(note:Note, char:Character):Void {
		var charAnim:String = StringTools.startsWith(char.getAnimationName(), 'sing') ? char.getAnimationName() : singAnimations[note.noteData] + note.animSuffix;
		charAnim = StringTools.replace(StringTools.replace(charAnim, '-loop', ''), '-hold', '');
		var hasHoldAnim:Bool = char.hasAnimation(charAnim + '-hold');
		var hasLoopAnim:Bool = char.hasAnimation(charAnim + '-loop');
		var hasHoldLoopAnim:Bool = char.hasAnimation(charAnim + '-hold-loop');

		note.extraData.set('continueAnimation', false);
		/*if (note.isSustainNote && note.sustainType == 'freeze')
			if (hasHoldAnim) {
				note.animSuffix += '-hold';
				note.extraData.set('continueAnimation', note.noAnimation = true);
			} else if (hasLoopAnim) {
				note.animSuffix += '-loop';
				note.extraData.set('continueAnimation', note.noAnimation = true);
			}*/
	}

	function noteHitCheck(note:Note, char:Character):Void {
		var prev:Bool = note.noAnimation;
		if (note.extraData.get('continueAnimation')) {
			note.noAnimation = false;
			char.holdTimer = 0;
		}
		if (!prev) {
			if (note.isSustainNote && note.sustainType == 'freeze')
				frozenCharacters.set(char, true);
			if (StringTools.endsWith(note.animation.name, 'end'))
				frozenCharacters.set(char, false);
		}
		/*if (StringTools.endsWith(char.getAnimationName(), '-hold') || StringTools.endsWith(char.getAnimationName(), '-loop'))*/
		frozenCharacters.set(char, false);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnHoldSplashOnNote(note:Note) {
		if (!note.isSustainNote && note.tail.length != 0 && note.tail[note.tail.length - 1].extraData['holdSplash'] == null) {
			spawnHoldSplash(note);
		} else if (note.isSustainNote) {
			final end:Note = StringTools.endsWith(note.animation.curAnim.name, 'end') ? note : note.parent.tail[note.parent.tail.length - 1];
			if (end != null) {
				var leSplash:SustainSplash = end.extraData['holdSplash'];
				if (leSplash == null && !end.parent.wasGoodHit) {
					spawnHoldSplash(end);
				} else if (leSplash != null) {
					leSplash.visible = true;
				}
			}
		}
	}

	public function spawnHoldSplash(note:Note) {
		var end:Note = note.isSustainNote ? note.parent.tail[note.parent.tail.length - 1] : note.tail[note.tail.length - 1];
		var splash:SustainSplash = grpHoldSplashes.recycle(SustainSplash);
		splash.setupSusSplash(strumLineNotes.members[note.noteData + (note.mustPress ? 4 : 0)], note, playbackRate);
		grpHoldSplashes.add(end.extraData['holdSplash'] = splash);
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
		}
	}

	public function spawnNoteSplash(x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		splash.spawnSplashNote(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		stagesFunc(function(stage:BaseStage) stage.destroy());

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.filters = [];

		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		NoteSplash.configs.clear();
		instance = null;
		super.destroy();
	}

	public function addShaderToCamera(cam:String,effect:ShaderEffect){//GOT FROM ANDROMEDA ENGIN
		if(!ClientPrefs.data.shaders) return;

		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
				camHUDShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camHUDShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camHUD.filters = newCamEffects;

			case 'camnotes' | 'notes':
				camNotesShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camNotesShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camNotes.filters = newCamEffects ;
				
			case 'camhudoverlay' | 'overlay':
				camHudOverlayShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camHudOverlayShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camOverlayHUD.filters = newCamEffects;

			case 'camother' | 'other':
				camOtherShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camOtherShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camOther.filters = newCamEffects;

			default:
				camGameShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camGameShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camGame.filters = newCamEffects;
		}
	}

	public function addRuntimeShaderToCamera(cam:String,effect:String){//GOT FROM ANY HSCRIPT LMAOOOOOO
		if(!ClientPrefs.data.shaders) return;

		initLuaShader(effect);
		var newShader:FlxRuntimeShader = createRuntimeShader(effect);

		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
				camHUDShaders.push(newShader);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camHUDShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camHUD.filters = newCamEffects;

			case 'camnotes' | 'notes':
				camNotesShaders.push(newShader);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camNotesShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camNotes.filters = newCamEffects;
				
			case 'camhudoverlay' | 'overlay':
				camHudOverlayShaders.push(newShader);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camHudOverlayShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camOverlayHUD.filters = newCamEffects;

			case 'camother' | 'other':
				camOtherShaders.push(newShader);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camOtherShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camOther.filters = newCamEffects;

			default:
				camGameShaders.push(newShader);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camGameShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camGame.filters = newCamEffects;
		}
	}

	public function removeShaderFromCamera(cam:String,effect:ShaderEffect){
		if(!ClientPrefs.data.shaders) return;

		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': 
                camHUDShaders.remove(effect);
                var newCamEffects:Array<BitmapFilter>=[];
                for(i in camHUDShaders) newCamEffects.push(new ShaderFilter(i.shader));
                camHUD.filters = newCamEffects;

			case 'camnotes' | 'notes': 
                camNotesShaders.remove(effect);
                var newCamEffects:Array<BitmapFilter>=[];
                for(i in camNotesShaders) newCamEffects.push(new ShaderFilter(i.shader));
                camNotes.filters = newCamEffects;

			case 'camhudoverlay' | 'overlay': 
                camHudOverlayShaders.remove(effect);
                var newCamEffects:Array<BitmapFilter>=[];
                for(i in camHudOverlayShaders) newCamEffects.push(new ShaderFilter(i.shader));
                camOverlayHUD.filters = newCamEffects;

			case 'camother' | 'other': 
				camOtherShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camOtherShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camOther.filters = newCamEffects;

			default: 
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders) newCamEffects.push(new ShaderFilter(i.shader));
				camGame.filters = newCamEffects;
		}
	}

	public function clearShaderFromCamera(cam:String){
		if(!ClientPrefs.data.shaders) return;

		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camHUD.filters = newCamEffects;
			case 'camnotes' | 'notes': 
				camNotesShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camNotes.filters = newCamEffects;
			case 'camhudoverlay' | 'overlay': 
				camHudOverlayShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camOverlayHUD.filters = newCamEffects;
			case 'camother' | 'other': 
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camOther.filters = newCamEffects;
			default: 
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.filters = newCamEffects;
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if (goHealthDamageBeat && curStep % Math.round(beatHealthStep) == 0) // :3 fuck my ass
			if (health >= beatHealthDrain)
				health -= beatHealthDrain;

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.scale.set(1.05);
		iconP2.scale.set(1.05);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		if (FlxG.camera.zoom < 1.7 && cameraZoomRate > 0 && curBeat % cameraZoomRate == 0 && ClientPrefs.data.camZooms)
		{
			// Set zoom multiplier for camera bop.
			cameraBopMultiplier = cameraBopIntensity;
			// HUD camera zoom still uses old system. To change. (+3%)
			camHudBopMult += hudCameraZoomIntensity;
			camNotesBopMult += hudCameraZoomIntensity;

			if(shakeBeat)
			{
				camGame.shake(0.003 * shakeDec, 1 / (Conductor.bpm / 60));
				camHUD.shake(0.003 * shakeDec, 1 / (Conductor.bpm / 60));
				camOverlayHUD.shake(0.003 * shakeDec, 1 / (Conductor.bpm / 60));
				camNotes.shake(0.003 * shakeDec, 1 / (Conductor.bpm / 60));
			}
		}

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance(gf.idleForce);
		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance(boyfriend.idleForce);
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance(dad.idleForce);
	}

	public function playerDance():Void
	{
		if(PlayState.SONG.swapPlayers)
		{
			var anim:String = dad.getAnimationName();
			if(dad.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * dad.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
				dad.dance();
		}
		else
		{
			var anim:String = boyfriend.getAnimationName();
			if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
				boyfriend.dance();
		}
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	function setupCameraToSong()
	{
		if (SONG.charFocusStart == null)
		{
			if(!SONG.notes[curSection].mustHitSection)
			{
				cameraFollowPoint.setPosition(dad.getMidpoint().x + dad.cameraPosition[0] + opponentCameraOffset[0] + 150, dad.getMidpoint().y + dad.cameraPosition[1] + opponentCameraOffset[1] - 100);
				curFocusedChar = 'dad';
			}
			else
			{
				cameraFollowPoint.setPosition(boyfriend.getMidpoint().x + boyfriend.cameraPosition[0] + boyfriendCameraOffset[0] - 100, boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] + boyfriendCameraOffset[1] - 100);
				curFocusedChar = 'bf';
			}
		}
		else
		{
			switch(SONG.charFocusStart)
			{
				case 'dad':
					cameraFollowPoint.setPosition(dad.getMidpoint().x + dad.cameraPosition[0] + opponentCameraOffset[0] + 150 + SONG.cameraOffsetX, dad.getMidpoint().y + dad.cameraPosition[1] + opponentCameraOffset[1] - 100 + SONG.cameraOffsetY);
					curFocusedChar = 'dad';

				case 'gf':
					cameraFollowPoint.setPosition(gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0] + SONG.cameraOffsetX,  gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1] + SONG.cameraOffsetY);

					if(!SONG.notes[curSection].mustHitSection)
						curFocusedChar = 'dad';
					else
						curFocusedChar = 'bf';

				default:
					cameraFollowPoint.setPosition(boyfriend.getMidpoint().x + boyfriend.cameraPosition[0] + boyfriendCameraOffset[0] - 100 + SONG.cameraOffsetX, boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] + boyfriendCameraOffset[1] - 100 + SONG.cameraOffsetY);
					curFocusedChar = 'bf';
			}
		}
	}

	function resetCameraZoom():Void
	{
		// Apply camera zoom level from stage data.
		currentCameraZoom = stageZoom;
		FlxG.camera.zoom = currentCameraZoom;
		
		// Reset bop multiplier.
		cameraBopMultiplier = 1.0;
	}
		
	public function resetCamera(?resetZoom:Bool = true, ?cancelTweens:Bool = true, ?snap:Bool = true):Void
	{
		resetZoom = resetZoom ?? true;
		cancelTweens = cancelTweens ?? true;
		
		// Cancel camera tweens if any are active.
		if (cancelTweens)
			cancelAllCameraTweens();
		
		FlxG.camera.follow(cameraFollowPoint, FlxCameraFollowStyle.LOCKON, 0.04);
		FlxG.camera.targetOffset.set();
		
		if (resetZoom)
			resetCameraZoom();
		
		// Snap the camera to the follow point immediately.
		if (snap) FlxG.camera.focusOn(cameraFollowPoint.getPosition());
	}
		
	function tweenCameraToPosition(?x:Float, ?y:Float, ?duration:Float, ?ease:Null<Float->Float>):Void
	{
		cameraFollowPoint.setPosition(x, y);
		tweenCameraToFollowPoint(duration, ease);
	}
		
	/**
	* Disables camera following and tweens the camera to the follow point manually.
	*/
	function tweenCameraToFollowPoint(?duration:Float, ?ease:Null<Float->Float>):Void
	{
		// Cancel the current tween if it's active.
		cancelCameraFollowTween();
		
		if (duration == 0)
		{
			// Instant movement. Just reset the camera to force it to the follow point.
			resetCamera(false, false);
		}
		else
		{
			// Disable camera following for the duration of the tween.
			FlxG.camera.target = null;
		
			// Follow tween! Caching it so we can cancel/pause it later if needed.
			var followPos:FlxBasePoint = FlxBasePoint.get(cameraFollowPoint.x - FlxG.camera.width * .5, cameraFollowPoint.y - FlxG.camera.height * .5);
			cameraFollowTween = FlxTween.tween(FlxG.camera.scroll, {x: followPos.x, y: followPos.y}, duration / playbackRate,
			{
				ease: ease,
				onComplete: function(_) {
					resetCamera(false, false); // Re-enable camera following when the tween is complete.
				}
			});
		}
	}
		
	function cancelCameraFollowTween()
	{
		if (cameraFollowTween != null)
			cameraFollowTween.cancel();
	}
		
	/**
	* Tweens the camera zoom to the desired amount.
	*/
	public function tweenCameraZoom(?zoom:Float, ?duration:Float, ?direct:Bool, ?ease:EaseFunction):Void
	{
		// Cancel the current tween if it's active.
		cancelCameraZoomTween();
		
		// Direct mode: Set zoom directly.
		// Stage mode: Set zoom as a multiplier of the current stage's default zoom.
		var targetZoom = zoom * (direct ? 1.0 : stageZoom);
		
		if (duration == 0)
			// Instant zoom. No tween needed.
			currentCameraZoom = targetZoom;
		else
			// Zoom tween! Caching it so we can cancel/pause it later if needed.
			cameraZoomTween = FlxTween.num(
				currentCameraZoom,
				targetZoom,
				duration / playbackRate,
				{ease: ease},
				function(num:Float) {currentCameraZoom = num;}
			);
	}
		
	function cancelCameraZoomTween()
	{
		if (cameraZoomTween != null)
			cameraZoomTween.cancel();
	}
		
	function cancelAllCameraTweens()
	{
		cancelCameraFollowTween();
		cancelCameraZoomTween();
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for(script in hscriptArray)
		{
			@:privateAccess
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var callValue = script.call(funcToCall, args);
			if(callValue != null)
			{
				var myValue:Dynamic = callValue.returnValue;

				if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	//TO DOL FIX SHIT FOR ATLAS SPRITES
	function doGhostAnim(char:String, animToPlay:String, mode:String, ?noteNum:Int)
	{
		//if(onlyChart) return;

		var ghost:FlxSprite = new FlxSprite();
		var player:Character = dad;
	
		switch(char.toLowerCase().trim())
		{
			case 'bf' | 'boyfriend':
				player = boyfriend;
			case 'dad':
				player = dad;
			case 'gf':
				player = gf;
		}
	
		if (player.animation != null)
		{
			ghost.frames = player.frames;
	
			// Check for null before copying from player.animation
			if (player.animation != null)
				ghost.animation.copyFrom(player.animation);
	
			ghost.x = player.x;
			ghost.y = player.y;
			ghost.animation.play(animToPlay, true, false);
			
			ghost.scale.copyFrom(player.scale);
			ghost.updateHitbox();
	
			// Check for null before accessing animOffsets
			if (player.animOffsets != null && player.animOffsets.exists(animToPlay))
				ghost.offset.set(player.animOffsets.get(animToPlay)[0], player.animOffsets.get(animToPlay)[1]);
	
			ghost.flipX = player.flipX;
			ghost.flipY = player.flipY;

			if(player.blend == '')
				ghost.blend = HARDLIGHT;
			else
				ghost.blend = player.blend;

			ghost.scrollFactor.set(player.scrollFactor.x, player.scrollFactor.y);

			ghost.alpha = player.alpha - 0.3;
			ghost.shader = player.shader;
			ghost.angle = player.angle;
			ghost.antialiasing = ClientPrefs.data.antialiasing ? !player.noAntialiasing : false;
			ghost.visible = true;

			ghost.color = FlxColor.fromRGB(player.healthColorArray[0] + 50, player.healthColorArray[1] + 50, player.healthColorArray[2] + 50);

			ghost.velocity.x = 0;
			ghost.velocity.y = 0;

			switch (mode)
			{
				case 'Arrow Movement Ghost':
					switch(noteNum)
					{
						case 0:
							ghost.velocity.x = -140;
						case 1:
							ghost.velocity.y = 140;
						case 2:
							ghost.velocity.y = -140;
						case 3:
							ghost.velocity.x = 140;
					}
				case 'Ascend Ghost':
					ghost.velocity.y = FlxG.random.int(-240, -275);
					ghost.velocity.x = FlxG.random.int(-100, 100);

				case 'Fall Ghost':
					ghost.velocity.y = FlxG.random.int(240, 275);
					ghost.velocity.x = FlxG.random.int(-100, 100);

				case 'Left Velocity Ghost':
					ghost.velocity.x = -140;

				case 'Right Velocity Ghost':
					ghost.velocity.x = 140;

				case 'Left and Right Velocity Ghost':
					switch(noteNum)
					{
						case 0 | 1:
							ghost.velocity.x = -140;
						case 2 | 3:
							ghost.velocity.x = 140;
					}
				case 'Random Left and Right Velocity Ghost':
					ghost.velocity.x = FlxG.random.int(-140, 140);
			}

			switch(char.toLowerCase().trim())
			{
				case 'bf' | 'boyfriend':
					insert(members.indexOf(boyfriendGroup), ghost);
				case 'dad':
					insert(members.indexOf(dadGroup), ghost);
				case 'gf':
					insert(members.indexOf(gfGroup), ghost);
			}
	
			FlxTween.tween(ghost, {alpha: 0}, Conductor.crochet * 0.002, {
				ease: FlxEase.linear,
					onComplete: function(twn:FlxTween)
					{
						ghost.destroy();
					}
			});
		}
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float, note:Note) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true, [note.rgbShader.r, note.rgbShader.g, note.rgbShader.b]);
			spr.resetAnim = time;
		}
	}

	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			if(totalPlayed != 0) //Prevent divide by 0
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed)); // Rating Percent

			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			if(!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					#if BASE_GAME_FILES
					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
					#end
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		#if (!flash && sys)
		if(!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);

		if(!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
}
