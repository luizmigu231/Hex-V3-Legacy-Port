function getName() return 'hexCompatibility';
function getModType() return NOTE_MOD;
function getOrder() return LAST;

var hexNames:Array<String> = [
	'rate', 'drawAhead', 'drawAhead.fade', 'drawBehind', 'sway', 'shiftY', 'colspacing', 'spacing', 'addx', 'waveamp',
	'slide0', 'slide1', 'slide2', 'slide3', 'lift0', 'lift1', 'lift2', 'lift3',
	'rowWave0', 'rowWave1', 'rowWave2', 'rowWave3', 'wrap', 'blind', 'dim', 'rowCenterX', 'shiftX', 'mirror',
	'rowY', 'laneY', 'fieldY', 'stamp0', 'stamp1', 'stamp2', 'stamp3', 'addDrunk', 'addDrunk 2', 'addDrunk 3', 'addDrunk 4',
	'addTipsy', 'addTipsy 2', 'addTipsy 3', 'addTipsy 4', 'tiltZ', 'fadeNear', 'fadeNear.offset', 'swell', 'flipRow', 'drag',
	'fold', 'fold.arc', 'drunk 2', 'camwagBy', 'camRock', 'halo', 'halo 2', 'center', 'camwag', 'slide', 'lift', 'rowWave', 'stamp',
	'fieldX', 'shiftX0', 'shiftX1', 'shiftX2', 'shiftX3', 'shiftY0', 'shiftY1', 'shiftY2', 'shiftY3',
	'screen.glitch', 'screen.glitch 2', 'cam.shake', 'faceX', 'faceZ', 'faceZ0', 'faceZ1', 'faceZ2', 'faceZ3', 'bobX', 'bobX.speed',
	'cam.rotZ', 'cam.rotZ 2', 'faceZ.rate', 'eyes.angle', 'eyes.reach', 'eye1.angle', 'eye2.angle', 'eye3.angle', 'eye4.angle', 'eye5.angle',
	'eye6.angle', 'eye7.angle', 'eye8.angle', 'bendX', 'joltX', 'joltY', 'joltX.period', 'stage.radius', 'cam.z', 'fieldZ',
	'freeze', 'hideHits', 'stage.rotZ', 'shrink', 'skewX', 'skewY', 'pinch', 'pinchX', 'pinchY', 'pinchZ', 'pinch0', 'pinch1',
	'pinch2', 'pinch3', 'hideNotes', 'fadeFar', 'fadeFar.fade', 'zoom', 'stage.rotY', 'stage.rotX', 'spinZ', 'spinY', 'cam.rotX', 'cam.rotY',
	'ghost', 'stage.invert', 'stage.gray', 'dim.fade', 'fade', 'cam.fov', 'shade', 'surge', 'eyes.become', 'fadeFar.offset', 'eye1.reach', 'eye1.become', 'eye2.reach', 'eye2.become', 'eye3.reach', 'eye3.become', 'eye4.reach', 'eye4.become', 'eye5.reach', 'eye5.become', 'eye6.reach', 'eye6.become', 'eye7.reach', 'eye7.become', 'eye8.reach', 'eye8.become', 'laneX0', 'laneX1',
	'laneX2', 'showPath', 'cam.x', 'cam.y', 'rowCenterY', 'tornado', 'incomeAngle', 'orient', 'shiftZ', 'easydrunk', 'easyDrunk',
	'camShake', 'camshake'
];

function onLoad(manager:Dynamic, name:String, prefix:String, parent:Dynamic)
{
	while (percents.length < modMgr.lanes) percents.push(0);
	for (subName in submods.keys()) {
		var sub = submods.get(subName);
		while (sub.percents.length < modMgr.lanes) sub.percents.push(0);
	}
}

function getSubmods()
{
	var out:Array<String> = [];
	for (name in hexNames)
	{
		if (out.indexOf(name) >= 0) continue;
		if (modMgr != null && modMgr.register.exists(name)) continue;
		out.push(name);
	}
	return out;
}

function hv(name:String, player:Int):Float
{
	if (modMgr == null) return 0;
	var mod = modMgr.get(name);
	if (mod == null) return 0;
	var value:Dynamic = mod.getValue(player);
	return value == null || Math.isNaN(value) ? 0 : value;
}

function clamp(value:Float, min:Float, max:Float):Float
{
	return Math.max(min, Math.min(max, value));
}

function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Dynamic, data:Int, player:Int, obj:Dynamic)
{
	var baseY:Float = 50 + Note.swagWidth * 0.5;
	var laneCenter:Float = modMgr.getBaseX(0, player) + (modMgr.keys - 1) * Note.swagWidth * 0.5;
	var laneOffset:Float = data - (modMgr.keys - 1) * 0.5;
	var rate:Float = hv('rate', player);
	var freeze:Float = hv('freeze', player);

	if (rate != 0) pos.y = baseY + (pos.y - baseY) * clamp(rate / 100, 0, 4);
	if (freeze != 0) pos.y = baseY + (pos.y - baseY) * (1 - clamp(freeze / 100, 0, 1));

	pos.x += hv('shiftX', player) + hv('fieldX', player) + hv('addx', player);
	pos.x += hv('shiftX' + data, player) + hv('laneX' + data, player);
	pos.y += hv('shiftY', player) + hv('fieldY', player) + hv('rowY', player) + hv('laneY', player) + hv('shiftY' + data, player);
	pos.z += hv('fieldZ', player) + hv('shiftZ', player);

	var spacing:Float = hv('spacing', player);
	if (spacing != 0) pos.x += laneOffset * (spacing - Note.swagWidth);
	pos.x += laneOffset * hv('colspacing', player);
	pos.x += hv('rowCenterX', player);
	pos.y += hv('rowCenterY', player);

	var skewX:Float = hv('skewX', player);
	var skewY:Float = hv('skewY', player);
	pos.x += (pos.y - baseY) * skewX / 100;
	pos.y += (pos.x - laneCenter) * skewY / 100;

	var wave:Float = (beat * Math.PI * 2) + (data * 0.65);
	pos.x += Math.sin(wave) * (hv('sway', player) + hv('waveamp', player) + hv('addDrunk 2', player) + hv('addDrunk 3', player) + hv('addDrunk 4', player) + hv('easydrunk', player) + hv('easyDrunk', player)) * 0.35;
	pos.y += Math.cos(wave + (time * 0.001 * hv('bobX.speed', player))) * (hv('bobX', player) + hv('addTipsy 2', player) + hv('addTipsy 3', player) + hv('addTipsy 4', player)) * 0.35;
	pos.x += Math.sin(wave * 0.5) * hv('rowWave' + data, player);
	pos.y += hv('lift' + data, player);
	pos.x += hv('slide' + data, player);
	pos.y += hv('stamp' + data, player);

	var pinchX:Float = clamp((hv('pinch', player) + hv('pinchX', player) + hv('pinch' + data, player)) / 100, -1.5, 1.5);
	var shrink:Float = clamp(hv('shrink', player) / 100, -0.75, 0.95);
	var swell:Float = clamp(hv('swell', player) / 100, -0.75, 2);
	var widthScale:Float = 1 - pinchX - shrink + swell;
	pos.x = laneCenter + hv('rowCenterX', player) + (pos.x - laneCenter - hv('rowCenterX', player)) * widthScale;

	var pinchY:Float = clamp(hv('pinchY', player) / 100, -1.5, 1.5);
	pos.y = baseY + (pos.y - baseY) * (1 - pinchY);

	var mirror:Float = clamp(hv('mirror', player) / 100, -1, 1);
	if (mirror != 0) pos.x = laneCenter + (pos.x - laneCenter) * (1 - 2 * mirror);
	if (hv('flipRow', player) >= 50) pos.x = laneCenter - (pos.x - laneCenter);

	var fold:Float = clamp(hv('fold', player) / 100, -1, 1);
	if (fold != 0) pos.x = laneCenter + (pos.x - laneCenter) * (1 - Math.abs(fold) * 0.65) + Math.sin((pos.x - laneCenter) / Math.max(1, Note.swagWidth) * Math.PI) * Note.swagWidth * fold;

	var wrap:Float = clamp(hv('wrap', player) / 100, 0, 1);
	if (wrap > 0) pos.x = laneCenter + (pos.x - laneCenter) * (1 - wrap) + Math.sin((pos.x - laneCenter) / Math.max(1, Note.swagWidth) * Math.PI) * Note.swagWidth * wrap;

	var drag:Float = clamp(hv('drag', player) / 100, -2, 2);
	if (drag != 0) pos.x += Math.sin(beat * Math.PI * 0.5) * drag * (pos.y - baseY) * 0.25;

	var surge:Float = clamp(hv('surge', player) / 100, -2, 2);
	if (surge != 0) pos.y += Math.sin(wave) * surge * Math.abs(pos.y - baseY) * 0.25;

	var tornado:Float = hv('tornado', player) / 100;
	if (tornado != 0) {
		var radius:Float = pos.x - laneCenter;
		pos.x = laneCenter + radius * Math.cos(tornado * beat + data * 0.3);
		pos.y += radius * Math.sin(tornado * beat + data * 0.3);
	}

	var tilt:Float = hv('tiltZ', player) + hv('faceZ', player) + hv('faceZ' + data, player) + hv('spinZ', player) + hv('orient', player);
	if (tilt != 0) pos.x += (pos.y - baseY) * Math.sin(tilt * Math.PI / 180) * 0.25;

	var pinchZ:Float = hv('pinchZ', player);
	pos.z += pinchZ;
	return pos;
}

var hexVisualObjects:Array<Dynamic> = [];
var hexLastAngle:Array<Float> = [];
var hexLastScale:Array<Float> = [];
var hexLastOpacity:Array<Float> = [];
var hexBaseOpacity:Array<Float> = [];
var hexOpacityCaptured:Array<Bool> = [];

function objectIndex(obj:Dynamic):Int
{
	var index:Int = hexVisualObjects.indexOf(obj);
	if (index >= 0) return index;
	hexVisualObjects.push(obj);
	hexLastAngle.push(0);
	hexLastScale.push(1);
	hexLastOpacity.push(1);
	hexBaseOpacity.push(1);
	hexOpacityCaptured.push(false);
	return hexVisualObjects.length - 1;
}

function applyVisuals(obj:Dynamic, pos:Dynamic, player:Int)
{
	if (obj == null || pos == null) return;
	var index:Int = objectIndex(obj);
	var data:Int = obj.noteData == null ? 0 : obj.noteData;

	var angle:Float = hv('faceZ', player) + hv('faceZ' + data, player) + hv('tiltZ', player) + hv('spinZ', player) + hv('orient', player);
	angle += hv('faceX', player) * 0.25;
	obj.angle += angle - hexLastAngle[index];
	hexLastAngle[index] = angle;

	var zScale:Float = 1;
	if (pos.z != 0) zScale = clamp(1000 / (1000 + pos.z), 0.25, 3);
	var desiredScale:Float = zScale * (1 + hv('swell', player) / 100 - hv('shrink', player) / 100);
	desiredScale = clamp(desiredScale, 0.1, 3);
	if (obj.scale != null) {
		var baseScale:Dynamic = null;
		try { baseScale = Reflect.field(obj, 'baseScale'); } catch (e:Dynamic) {}
		if (baseScale != null && Reflect.field(baseScale, 'x') != null && Reflect.field(baseScale, 'y') != null) {
			obj.scale.x = Reflect.field(baseScale, 'x') * desiredScale;
			obj.scale.y = Reflect.field(baseScale, 'y') * desiredScale;
		} else if (hexLastScale[index] != 0) {
			obj.scale.x = obj.scale.x / hexLastScale[index] * desiredScale;
			obj.scale.y = obj.scale.y / hexLastScale[index] * desiredScale;
		}
		hexLastScale[index] = desiredScale;
	}

	var hidden:Float = Math.max(hv('dim', player), Math.max(hv('blind', player), Math.max(hv('ghost', player), Math.max(hv('hideNotes', player), hv('hideHits', player)))));
	var opacity:Float = 1 - clamp(hidden / 100, 0, 1);
	var nearFade:Float = hv('fadeNear', player);
	var farFade:Float = hv('fadeFar', player);
	var distance:Float = Math.abs(pos.y - (50 + Note.swagWidth * 0.5));
	var nearOffset:Float = hv('fadeNear.offset', player);
	var farOffset:Float = hv('fadeFar.offset', player);
	if (nearFade > 0) opacity *= clamp((distance - nearOffset) / Math.max(1, nearFade), 0, 1);
	if (farFade > 0) opacity *= clamp((Math.max(1, farFade + farOffset) - distance) / Math.max(1, farFade), 0, 1);
	opacity = clamp(opacity, 0, 1);
	if (obj.alpha != null && (opacity != 1 || hexOpacityCaptured[index])) {
		if (!hexOpacityCaptured[index]) {
			hexBaseOpacity[index] = obj.alpha;
			hexOpacityCaptured[index] = true;
		}
		obj.alpha = clamp(hexBaseOpacity[index] * opacity, 0, 1);
		if (opacity == 1) hexOpacityCaptured[index] = false;
	}
	hexLastOpacity[index] = opacity;
}

function updateNote(beat:Float, note:Dynamic, pos:Dynamic, player:Int) applyVisuals(note, pos, player);
function updateReceptor(beat:Float, receptor:Dynamic, pos:Dynamic, player:Int) applyVisuals(receptor, pos, player);
function updateNoteSplash(beat:Float, splash:Dynamic, pos:Dynamic, player:Int) applyVisuals(splash, pos, player);
function updateSustainSplash(beat:Float, splash:Dynamic, pos:Dynamic, player:Int) applyVisuals(splash, pos, player);

function destroy()
{
	hexVisualObjects.resize(0);
	hexLastAngle.resize(0);
	hexLastScale.resize(0);
	hexLastOpacity.resize(0);
	hexBaseOpacity.resize(0);
	hexOpacityCaptured.resize(0);
}
