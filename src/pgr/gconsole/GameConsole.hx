package pgr.gconsole;

import GCThemes.Theme;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.KeyboardEvent;
import nme.Lib;

/**
 * GameConsole is the main class of this lib, it should be instantiated only once
 * and then use its instance to control the console.
 * 
 * Its recomended to use GC class as API for this lib instead of GameConsole class.
 * 
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class GameConsole extends Sprite
{	
	inline static private var GC_TRC_ERR = "gc_error: ";
	/** Aligns console to bottom */
	static public var ALIGN_DOWN:String = "DOWN";
	/** Aligns console to top */
	static public var ALIGN_UP:String = "UP";
	
	private var _firstLine:Bool;
	
	private var _historyArray:Array<String>;
	private var _historyIndex:Int;
	private var _historyMaxSz:Int;
	public var _interface:GCInterface;
	
	private var _elapsedFrames:Int;
	private var _monitorRate:Int;
	
	private var _consoleScKey:Int;
	
	private var _isMonitorOn:Bool;
	private var _isConsoleOn:Bool;
	
	public static var instance:GameConsole;

	public function new(height:Float = 0.33, align:String = "DOWN", theme:Theme = null, monitorRate:Int = 10) 
	{
		super();
		
		if (height > 1) height = 1;
		if (height < 0.1) height = 0.1;
		_interface = new GCInterface(height,align,theme);
		addChild(_interface);
		
		_monitorRate = monitorRate;
		_consoleScKey = 9;
		
		_historyArray = new Array();
		_historyIndex = -1;
		_historyMaxSz = 100;	
		_firstLine = true;
		
		enable();
		hideConsole();
		hideMonitor();
		instance = this;
		
		GC.log("~~~~~~~~~~ GAME CONSOLE ~~~~~~~~~~");
	} 

	public function setConsoleFont(font:String = null, embed:Bool = true, size:Int = 14, bold:Bool = false, italic:Bool = false, underline:Bool = false )
	{
		_interface.setConsoleFont(font, embed, size, bold, italic, underline);
	}

	public function setPromptFont(font:String = null, embed:Bool = true, size:Int = 16, yOffset:Int = 22, bold:Bool = false, ?italic:Bool = false, underline:Bool = false )
	{
		_interface.setPromptFont(font, embed, size, yOffset, bold, italic, underline);
	}

	public function setMonitorFont(font:String = null, embed:Bool = true, size:Int = 14, bold:Bool = false, ?italic:Bool = false, underline:Bool = false )
	{
		_interface.setMonitorFont(font, embed, size, bold, italic, underline);
	}

	public function showConsole() 
	{
		if (!this.visible) return;
		Lib.stage.focus = _interface.txtPrompt;
		_isConsoleOn = true;
		_interface.toggleConsoleOn(true);
	}

	public function hideConsole()
	{
		if (!this.visible) return;
		_isConsoleOn = false;
		_interface.toggleConsoleOn(false);
	}

	public function showMonitor() 
	{
		_isMonitorOn = true;
		_interface.toggleMonitor(true);
		addEventListener(Event.ENTER_FRAME, updateMonitor);
		
		_elapsedFrames = _monitorRate + 1;
		updateMonitor(null);	// renders first frame.
	}

	public function hideMonitor()
	{
		_isMonitorOn = false;
		_interface.toggleMonitor(false);
		removeEventListener(Event.ENTER_FRAME, updateMonitor);
	}

	public function enable() 
	{
		visible = true;
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 10);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 10);
	}

	public function disable() 
	{
		if (_isMonitorOn) hideMonitor();
		if (_isConsoleOn) hideConsole();
		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp, false);
		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false);
		visible = false;
	}

	public function setShortcutKeyCode(key:Int)
	{
		_consoleScKey = key;
	}
	
	public function log(data:Dynamic) 
	{
		if (data == "") return;
		_firstLine ?
			_firstLine = false : 
			_interface.txtConsole.text += '\n'; //add new line if console text was not clear.
		
		_interface.txtConsole.text += data.toString();
		_interface.txtConsole.scrollV = _interface.txtConsole.maxScrollV;
	}

	public function registerVariable(object:Dynamic, name:String, alias:String, monitor:Bool=false) 
	{
		if (!Reflect.isObject(object)) {
		trace(GC_TRC_ERR + "dynamic passed with the field: " + name + " is not an object.");
			return;
		}
		#if !cpp // BUGFIX
		if (!Reflect.hasField(object, name)) {
			trace (GC_TRC_ERR + name + " field was not found in object passed.");
			return;
		}
		#end
		
		log(GCCommands.registerVariable(object, name, alias, monitor));
	}

	public function unregisterVariable(alias:String)
	{
		if (GCCommands.unregisterVariable(alias)) {
			log("variable " + alias + " unregistered.");
		} else {
			log("variable " + alias + " not found.");
		}
	}
	
	public function registerFunction(object:Dynamic, name:String, alias:String, ?monitor:Bool = false) 
	{
		#if !cpp // BUGFIX
		if (!Reflect.hasField(object, name)) {
			trace (GC_TRC_ERR + name + " field was not found in object passed.");
			return;
		}
		#end
		if (!Reflect.isFunction(Reflect.field(object, name))) {
			trace(GC_TRC_ERR + "could not find function: " + name + " in object passed.");
			return;
		}
		
		log(GCCommands.registerFunction(object, name, alias, monitor));
	}

	public function unregisterFunction(alias:String)
	{
		if (GCCommands.unregisterFunction(alias)) {
			log("function " + alias + " unregistered.");
		} else {
			log("function " + alias + " not found.");
		}
		
	}

	public function unregisterObject(object:Dynamic) 
	{
		if (!Reflect.isObject(object)) {
		trace(GC_TRC_ERR + "dynamic passed with the field: " + name + " is not an object.");
			return;
		}
		
		log(GCCommands.unregisterObject(object));
	}
	
	public function clearConsole() 
	{
		_interface.txtConsole.text = '';
		_firstLine = true;
	}

	public function clearRegistry()
	{
		GCCommands.clearRegistry();
	}
	
	// INPUT HANDLING ------------------------------------------------------
	
	private function onKeyDown(e:KeyboardEvent):Void 
	{
		#if !cpp // BUGFIX
		if (_isConsoleOn) 
			e.stopImmediatePropagation(); 
		#end
	}
	
	private function onKeyUp(e:KeyboardEvent):Void 
	{
		if (e.ctrlKey && cast(e.keyCode,Int) == _consoleScKey ) {
			_isMonitorOn ? hideMonitor() : showMonitor();
			return;
		}
		
		if (cast(e.keyCode,Int) == _consoleScKey) {
			_isConsoleOn ? hideConsole() : showConsole();
			return;
		}
		
		// Read the following input if console is showing.
		if (!_isConsoleOn)
			return;	
		
		switch (e.keyCode) {
			// ENTER
			case 13	: 	processInputLine();
			// PAGEUP
			case 33 : 	_interface.txtConsole.scrollV -= _interface.txtConsole.bottomScrollV - _interface.txtConsole.scrollV +1;
						if (_interface.txtConsole.scrollV < 0)
							_interface.txtConsole.scrollV = 0;
			// PAGEDOWN
			case 34	:	_interface.txtConsole.scrollV += _interface.txtConsole.bottomScrollV - _interface.txtConsole.scrollV +1;
						if (_interface.txtConsole.scrollV > _interface.txtConsole.maxScrollV)
							_interface.txtConsole.scrollV = _interface.txtConsole.maxScrollV;
			// UP
			case 38	:	nextHistory();
			// DOWN
			case 40	: 	prevHistory();
			default	:	_historyIndex = -1;
		}
			
		#if !cpp // BUGFIX
		e.stopImmediatePropagation(); // BUG - cpp issues.
		#end
	}
	
	private function prevHistory() 
	{
		_historyIndex--;
		if (_historyIndex < 0 ) _historyIndex = 0;
		if (_historyIndex > _historyArray.length - 1) return; 
		
		_interface.txtPrompt.text = _historyArray[_historyIndex];
		#if !cpp
		_interface.txtPrompt.setSelection(_interface.txtPrompt.length, _interface.txtPrompt.length); 
		#end
	}
	
	private function nextHistory() 
	{
		if (_historyIndex + 1 > _historyArray.length - 1) return;
		_historyIndex++;
		
		_interface.txtPrompt.text = _historyArray[_historyIndex];
		#if !cpp
		_interface.txtPrompt.setSelection(_interface.txtPrompt.length, _interface.txtPrompt.length); 
		#end
	}
	
	// INPUT PARSE ----------------------------------------------------
	
	private function processInputLine() 
	{
		if (_interface.txtPrompt.text == '') 
			return;
		var temp:String = _interface.txtPrompt.text;
		
		_historyArray.insert(0, _interface.txtPrompt.text);
		_historyIndex = -1;
		if (_historyArray.length > _historyMaxSz)
			_historyArray.splice(_historyArray.length - 1, 1);
		
		log(": " + _interface.txtPrompt.text);
		_interface.txtPrompt.text = '';
		parseInput(temp);
	}
	
	private function parseInput(input:String) 
	{
		var args:Array<String> = input.split(' ');
		var argsLC:Array<String> = input.toLowerCase().split(' ');
		
		switch (argsLC[0]) {
			case "clear"	: clearConsole();
			case "monitor"	: _isMonitorOn ? hideMonitor() : showMonitor();
			case "help"		: log(GCCommands.showHelp());
			case "commands" : log(GCCommands.showCommands());
			case "vars"		: log(GCCommands.listVars());
			case "fcns"		: log(GCCommands.listFunctions());
			case "set"		: log(GCCommands.setVar(args));
			case "call"		: log(GCCommands.callFunction(args));
		}
	}
	
	// MONITOR --------------------------------------------------------

	private function updateMonitor(e:Event):Void 
	{
		_elapsedFrames++;
		if (_elapsedFrames > _monitorRate) {
			processMonitorOutput(GCCommands.getMonitorOutput());
			_elapsedFrames = 0;
		}
	}
	
	private function processMonitorOutput(input:String) 
	{
		if (input.length == 0) return;
		var str1:String;
		var str2:String;
		
		var splitPoint:Int = Std.int(input.length / 2) - 1;
		
		while (splitPoint < input.length) {
			if (input.charAt(splitPoint) == "\n") 
				break;
			splitPoint++;
		}
		
		_interface.txtMonitorLeft.text = input.substr(0, splitPoint);
		_interface.txtMonitorRight.text = input.substr(splitPoint + 1); 
	}
	
	// GETTERS AND SETTERS ------------------------------------------------
	
	private function set_historyMaxSz(value:Int):Int 
	{
		return _historyMaxSz = value;
	}
	public var historyMaxSz(null, set_historyMaxSz):Int;
}
