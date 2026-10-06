package funkin.debug.editors.content;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;

import haxe.Exception;
import sys.io.File;
import lime.ui.*;

import openfl.Lib;

import flixel.FlxBasic;

//Currently only supports OPEN and SAVE, might change that in the future, who knows
class FileDialogHandler extends FlxBasic
{
	var _fileRef:FileReferenceCustom;
	public function new()
	{
		_fileRef = new FileReferenceCustom();
		_fileRef.addEventListener(Event.CANCEL, onCancelFn);
		_fileRef.addEventListener(IOErrorEvent.IO_ERROR, onErrorFn);

		super();
	}

	// callbacks
	public var onComplete:Void->Void;
	public var onCancel:Void->Void;
	public var onError:Void->Void;

	var _currentEvent:openfl.events.Event->Void;

	public function save(?fileName:String = '', ?dataToSave:String = '', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		_startUp(onComplete, onCancel, onError);

		removeEvents();
		_currentEvent = onSaveComplete;
		_fileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		_fileRef.save(dataToSave, fileName);
	}

	public function open(?defaultName:String = null, ?title:String = null, ?filter:Array<FileFilter> = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		_startUp(onComplete, onCancel, onError);
		if(filter == null) filter = [new FileFilter('JSON', 'json')];
		#if mac
		filter = [];
		#end

		removeEvents();
		_currentEvent = onLoadComplete;
		_fileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);

		//_fileRef.browseEx(true, defaultName, title, filter);

		_fileRef.nullSet();

		var filterLol = null;

		if (filter != null)
		{
			var filters = [];

			for (type in filter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", ""), ";", ","));
			}

			filterLol = filters.join(";");
		}

		FileDialog.openFile(Lib.current.stage.window, function(filepaths:Array<String>, filterLol):Void
		{
			if (filepaths.length > 0)
			{
				@:privateAccess
				this.path = filepaths[0];
				this.data = File.getContent(this.path);
				this.completed = true;
				//trace('Loaded file from: $path');

				removeEvents();
				this.completed = true;
				if(onComplete != null) onComplete();
			}
			else
			{
				removeEvents();
				this.completed = true;
				if(onCancel != null) onError();
			}
		}, @:privateAccess openfl.filesystem.File.__getFilterTypes(filter ?? []),
		defaultName, true);
		
		return true;
	}

	public function openDirectory(?title:String = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		_startUp(onComplete, onCancel, onError);

		removeEvents();
		_currentEvent = onLoadDirectoryComplete;
		_fileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		_fileRef.browseEx(false, null, title);
	}

	public var data:String;
	public var path:String;
	public var completed:Bool = true;
	function onSaveComplete(_)
	{
		@:privateAccess
		this.path = _fileRef._trackSavedPath;
		this.completed = true;
		trace('Saved file to: $path');

		removeEvents();
		this.completed = true;
		if(onComplete != null) onComplete();
	}

	public function onLoadComplete(_)
	{
		@:privateAccess
		this.path = _fileRef.__path;
		this.data = File.getContent(this.path);
		this.completed = true;
		trace('Loaded file from: $path');

		removeEvents();
		this.completed = true;
		if(onComplete != null)
			onComplete();
	}

	function onLoadDirectoryComplete(_)
	{
		@:privateAccess
		this.path = _fileRef.__path;
		this.completed = true;
		trace('Loaded directory: $path');

		removeEvents();
		this.completed = true;
		if(onComplete != null)
			onComplete();
	}

	public function onCancelFn(_)
	{
		removeEvents();
		this.completed = true;
		if(onCancel != null) onError();
	}

	function onErrorFn(_)
	{
		removeEvents();
		this.completed = true;
		if(onError != null) onError();
	}

	function _startUp(onComplete:Void->Void, onCancel:Void->Void, onError:Void->Void)
	{
		this.onComplete = onComplete;
		this.onCancel = onCancel;
		this.onError = onError;
		this.completed = false;

		this.data = null;
		this.path = null;
	}

	function removeEvents()
	{
		if(_currentEvent == null) return;
		
		_fileRef.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		_currentEvent = null;
	}

	override function destroy()
	{
		removeEvents();
		_fileRef = null;
		_currentEvent = null;
		onComplete = null;
		onCancel = null;
		onError = null;
		data = null;
		path = null;
		completed = true;
		super.destroy();
	}
}

//Only way I could find to keep the path after saving a file
class FileReferenceCustom extends FileReference
{
	@:allow(backend.FileDialogHandler)
	var _trackSavedPath:String;
	override function saveFileDialog_onSelect(path:String):Void
	{
		_trackSavedPath = path;
		super.saveFileDialog_onSelect(path);
	}

	public function nullSet()
	{
		__data = null;
		__path = null;
	}
	
	public function browseEx(browseType:Bool = true, ?defaultName:String, ?title:String = null, ?typeFilter:Array<FileFilter> = null):Bool
	{
		__data = null;
		__path = null;

		/*FileDialog.openFile(Lib.current.stage.window, function(filepaths:Array<String>, filter):Void
		{
			if (filepaths.length > 0)
			{
				FileDialogHandler.onLoadComplete();
			}
			else
			{
				FileDialogHandler.onCancelFn();
			}
		}, @:privateAccess openfl.filesystem.File.__getFilterTypes(typeFilter ?? []),
		defaultName, true);*/
		
		return true;
	}
}