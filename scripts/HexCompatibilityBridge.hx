var hexCompatAngle:Float = 0;
var hexCompatZoom:Float = 0;
var hexCompatFollowX:Float = 0;
var hexCompatFollowY:Float = 0;
var hexCompatLastState:Dynamic = null;
var hexCompatBaseState:Dynamic = null;
var hexCompatBaseCamera:Dynamic = null;
var hexCompatBaseZoom:Float = 1;
var hexCompatBaseAngle:Float = 0;
var hexCompatBaseFollowX:Float = 0;
var hexCompatBaseFollowY:Float = 0;
var hexCompatBaseCaptured:Bool = false;
var hexCompatStageScript:Dynamic = null;
var hexStageObjects:Array<Dynamic> = [];
var hexStageBaseX:Array<Float> = [];
var hexStageBaseY:Array<Float> = [];
var hexStageBaseScaleX:Array<Float> = [];
var hexStageBaseScaleY:Array<Float> = [];
var hexStageBaseAngle:Array<Float> = [];
var hexStageCacheNames:Array<String> = [];
var hexStageCacheValues:Array<Float> = [];
var hexStageKeys:Array<String> = [
	'screen.glitch', 'screen.glitch 2', 'cam.shake', 'camShake', 'cam.rotX', 'cam.rotY', 'cam.rotZ', 'cam.rotZ 2',
	'cam.x', 'cam.y', 'cam.z', 'cam.fov', 'stage.rotX', 'stage.rotY', 'stage.rotZ', 'stage.radius', 'stage.invert',
	'stage.gray', 'zoom', 'eyes.angle', 'eyes.reach', 'eye1.angle', 'eye2.angle', 'eye3.angle', 'eye4.angle',
	'eye5.angle', 'eye6.angle', 'eye7.angle', 'eye8.angle', 'eyes.become', 'eyes.reach', 'eye1.reach', 'eye1.become', 'eye2.reach', 'eye2.become', 'eye3.reach', 'eye3.become', 'eye4.reach', 'eye4.become', 'eye5.reach', 'eye5.become', 'eye6.reach', 'eye6.become', 'eye7.reach', 'eye7.become', 'eye8.reach', 'eye8.become', 'halo', 'halo 2', 'shade', 'faceX',
	'faceZ', 'faceZ0', 'faceZ1', 'faceZ2', 'faceZ3', 'faceZ.rate', 'dim', 'blind', 'showPath'
];

function hexCompatCaptureCamera():Void
{
    if (game == null || game.camGame == null) return;
    if (hexCompatBaseCaptured && hexCompatBaseState == game && hexCompatBaseCamera == game.camGame) return;
    hexCompatBaseState = game;
    hexCompatBaseCamera = game.camGame;
    hexCompatBaseZoom = game.camGame.zoom;
    hexCompatBaseAngle = game.camGame.angle;
    hexCompatBaseFollowX = game.camFollow == null ? 0 : game.camFollow.x;
    hexCompatBaseFollowY = game.camFollow == null ? 0 : game.camFollow.y;
    hexCompatBaseCaptured = true;
}

function hexCompatRestoreCamera():Void
{
    if (!hexCompatBaseCaptured || game == null || game != hexCompatBaseState || game.camGame != hexCompatBaseCamera) return;
    try { game.camGame.zoom = hexCompatBaseZoom; game.camGame.angle = hexCompatBaseAngle; } catch (e:Dynamic) {}
    try { if (game.camFollow != null) { game.camFollow.x = hexCompatBaseFollowX; game.camFollow.y = hexCompatBaseFollowY; } } catch (e:Dynamic) {}
}

function hexRead(name:String, player:Int = 0):Float
{
	if (modManager == null) return 0;
	var mod = modManager.get(name);
	if (mod == null) return 0;
	var value:Dynamic = mod.getValue(player);
	if (value == null || Math.isNaN(value)) return 0;
	return value;
}

function hexWriteStageValue(name:String, value:Float)
{
	var field:String = 'hex_' + name.replace('.', '_').replace(' ', '_').replace('-', '_');
	var index:Int = hexStageCacheNames.indexOf(field);
	if (index >= 0 && hexStageCacheValues[index] == value) return;
	if (index < 0) {
		hexStageCacheNames.push(field);
		hexStageCacheValues.push(value);
	} else hexStageCacheValues[index] = value;
	stage.script.set(field, value);
}

function hexCaptureStageProps():Void
{
	if (stage == null || stage.script == null) return;
	if (hexCompatStageScript != stage.script)
	{
		hexCompatStageScript = stage.script;
		hexStageObjects.resize(0);
		hexStageBaseX.resize(0);
		hexStageBaseY.resize(0);
		hexStageBaseScaleX.resize(0);
		hexStageBaseScaleY.resize(0);
		hexStageBaseAngle.resize(0);
		hexStageCacheNames.resize(0);
		hexStageCacheValues.resize(0);
	}
	var props:Dynamic = null;
	try { props = stage.script.get('hexProps'); } catch (e:Dynamic) {}
	if (props == null) return;
	var count:Int = 0;
	try { count = props.length; } catch (e:Dynamic) { return; }
	for (i in 0...count)
	{
		var obj:Dynamic = null;
		try { obj = props[i]; } catch (e:Dynamic) {}
		if (obj == null || hexStageObjects.indexOf(obj) >= 0) continue;
		hexStageObjects.push(obj);
		hexStageBaseX.push(obj.x);
		hexStageBaseY.push(obj.y);
		hexStageBaseScaleX.push(obj.scale == null ? 1 : obj.scale.x);
		hexStageBaseScaleY.push(obj.scale == null ? 1 : obj.scale.y);
		hexStageBaseAngle.push(obj.angle);
	}
}

function hexRestoreStageProps():Void
{
	for (i in 0...hexStageObjects.length)
	{
		var obj:Dynamic = hexStageObjects[i];
		if (obj == null) continue;
		try
		{
			obj.x = hexStageBaseX[i];
			obj.y = hexStageBaseY[i];
			obj.angle = hexStageBaseAngle[i];
			if (obj.scale != null)
			{
				obj.scale.x = hexStageBaseScaleX[i];
				obj.scale.y = hexStageBaseScaleY[i];
			}
		}
		catch (e:Dynamic) {}
	}
}

function hexApplyStageProps():Void
{
	if (hexStageObjects.length == 0) return;
	var rotX:Float = hexRead('stage.rotX') * Math.PI / 180;
	var rotY:Float = hexRead('stage.rotY') * Math.PI / 180;
	var rotZ:Float = hexRead('stage.rotZ') * Math.PI / 180;
	var sxFactor:Float = Math.max(0.2, Math.min(1.25, Math.abs(Math.cos(rotY))));
	var syFactor:Float = Math.max(0.2, Math.min(1.25, Math.abs(Math.cos(rotX))));
	var cx:Float = FlxG.width * 0.5;
	var cy:Float = FlxG.height * 0.5;
	var cz:Float = Math.cos(rotZ);
	var sz:Float = Math.sin(rotZ);
	var skewX:Float = Math.sin(rotY) * 0.18;
	var skewY:Float = Math.sin(rotX) * 0.18;
	for (i in 0...hexStageObjects.length)
	{
		var obj:Dynamic = hexStageObjects[i];
		if (obj == null) continue;
		var bx:Float = hexStageBaseX[i];
		var by:Float = hexStageBaseY[i];
		var dx:Float = bx - cx;
		var dy:Float = by - cy;
		try
		{
			obj.x = cx + dx * cz - dy * sz + dy * skewX;
			obj.y = cy + dx * sz + dy * cz - dx * skewY;
			obj.angle = hexStageBaseAngle[i] + rotZ * 180 / Math.PI;
			if (obj.scale != null)
			{
				obj.scale.x = hexStageBaseScaleX[i] * sxFactor;
				obj.scale.y = hexStageBaseScaleY[i] * syFactor;
			}
		}
		catch (e:Dynamic) {}
	}
}

function hexExposeStageValues()
{
	if (stage == null || stage.script == null || modManager == null) return;
	if (hexCompatStageScript != stage.script) {
		hexCompatStageScript = stage.script;
		hexStageCacheNames.resize(0);
		hexStageCacheValues.resize(0);
	}
	for (name in hexStageKeys) {
		var mod = modManager.get(name);
		if (mod == null) continue;
		var value:Dynamic = mod.getValue(0);
		if (value == null || Math.isNaN(value)) value = 0;
		hexWriteStageValue(name, value);
	}
}

function postModifierRegister()
{
	hexCompatCaptureCamera();
	hexCompatAngle = 0;
	hexCompatZoom = 0;
	hexCompatFollowX = 0;
	hexCompatFollowY = 0;
	hexCompatLastState = null;
	hexCompatStageScript = null;
	hexStageCacheNames.resize(0);
	hexStageCacheValues.resize(0);
}

function onUpdatePost(elapsed:Float)
{
	if (modManager == null || modManager.get('hexCompatibility') == null) return;
	if (game == null || game.camGame == null || camFollow == null) return;
	hexCompatCaptureCamera();
	if (hexCompatLastState != PlayState.instance) {
		hexCompatAngle = 0;
		hexCompatZoom = 0;
		hexCompatFollowX = 0;
		hexCompatFollowY = 0;
		hexCompatLastState = PlayState.instance;
	}

	var camAngle:Float = hexRead('cam.rotZ') + hexRead('cam.rotZ 2');
	var camZoom:Float = hexRead('zoom') / 100 + hexRead('cam.z') / 5000 + hexRead('cam.fov') / 400;
	var shake:Float = Math.abs(hexRead('cam.shake')) + Math.abs(hexRead('camShake')) + Math.abs(hexRead('screen.glitch')) * 12 + Math.abs(hexRead('screen.glitch 2')) * 8;
	var shakePhase:Float = Conductor.songPosition * 0.075;
	var camX:Float = hexRead('cam.x') + hexRead('cam.rotY') * 0.5 + Math.sin(shakePhase) * shake * 0.12;
	var camY:Float = hexRead('cam.y') + hexRead('cam.rotX') * 0.5 + Math.cos(shakePhase * 1.37) * shake * 0.12;

	game.camGame.angle += camAngle - hexCompatAngle;
	game.camGame.zoom = Math.max(0.05, game.camGame.zoom + camZoom - hexCompatZoom);
	camFollow.x += camX - hexCompatFollowX;
	camFollow.y += camY - hexCompatFollowY;

	hexCompatAngle = camAngle;
	hexCompatZoom = camZoom;
	hexCompatFollowX = camX;
	hexCompatFollowY = camY;
	hexCaptureStageProps();
	hexApplyStageProps();
	hexExposeStageValues();
}

function onCreatePost():Void
{
	hexCompatCaptureCamera();
}

function onSongLoaded(event:Dynamic = null)
{
	hexCompatRestoreCamera();
	hexRestoreStageProps();
	hexCompatAngle = 0;
	hexCompatZoom = 0;
	hexCompatFollowX = 0;
	hexCompatFollowY = 0;
	hexCompatLastState = PlayState.instance;
	hexCompatStageScript = null;
	hexStageCacheNames.resize(0);
	hexStageCacheValues.resize(0);
	hexStageObjects.resize(0);
	hexStageBaseX.resize(0);
	hexStageBaseY.resize(0);
	hexStageBaseScaleX.resize(0);
	hexStageBaseScaleY.resize(0);
	hexStageBaseAngle.resize(0);
}

function onSongRetry(event:Dynamic = null)
{
	hexCompatRestoreCamera();
	hexRestoreStageProps();
	hexCompatAngle = 0;
	hexCompatZoom = 0;
	hexCompatFollowX = 0;
	hexCompatFollowY = 0;
	hexCompatLastState = PlayState.instance;
	hexCompatStageScript = null;
	hexStageCacheNames.resize(0);
	hexStageCacheValues.resize(0);
	hexStageObjects.resize(0);
	hexStageBaseX.resize(0);
	hexStageBaseY.resize(0);
	hexStageBaseScaleX.resize(0);
	hexStageBaseScaleY.resize(0);
	hexStageBaseAngle.resize(0);
}

function onDestroy()
{
    hexCompatRestoreCamera();
    hexRestoreStageProps();
    hexCompatBaseState = null;
    hexCompatBaseCamera = null;
    hexCompatBaseCaptured = false;
}
