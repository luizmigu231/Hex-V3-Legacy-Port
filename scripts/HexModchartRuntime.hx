import flixel.tweens.FlxTween;
import funkin.FunkinAssets;
import funkin.Paths;
import funkin.states.PlayState;
import openfl.filters.ShaderFilter;
import funkin.Paths.PathsTestMode;

var hexRuntimeSong:String = '';
var hexRuntimeActive:Array<String> = [];
var hexRuntimeLastBeat:Float = -999999;
var hexRuntimeCueRows:Array<Dynamic> = [];
var hexRuntimeCueKey:String = '';
var hexRuntimeNextCue:Int = 0;
var hexRuntimeStateKeys:Array<String> = [];
var hexRuntimeStateCue:Array<Int> = [];
var hexRuntimeLastFocus:Int = -1;
var hexRuntimeLook:String = '';
var hexRtFocusActive:Bool = false;
var hexRtFocusTarget:Int = -1;
var hexRtFocusStart:Float = 0;
var hexRtFocusDuration:Float = 0;
var hexRtFocusFromX:Float = 0;
var hexRtFocusFromY:Float = 0;
var hexRtFocusOffsetX:Float = 0;
var hexRtFocusOffsetY:Float = 0;
var hexRtFocusEase:String = 'linear';
var hexRtZoomActive:Bool = false;
var hexRtZoomStart:Float = 0;
var hexRtZoomDuration:Float = 0;
var hexRtZoomFrom:Float = 1;
var hexRtZoomTo:Float = 1;
var hexRtZoomEase:String = 'linear';
var hexRtZoomMode:String = 'stage';
var hexRtBopIntensity:Float = 0;
var hexRtBopOffset:Float = 0;
var hexRtBopRate:Float = 1;
var hexRtBopLast:Float = 0;
var hexRtLookClock:Float = 0;
var hexRtLookChars:Array<Dynamic> = [];
var hexRtLookShaders:Array<Dynamic> = [];
var hexRtLookFrom:Array<String> = [];
var hexRtLookTo:Array<String> = [];
var hexRtLookStarts:Array<Float> = [];
var hexRtLookDurations:Array<Float> = [];
var hexRtPostShader:Dynamic = null;
var hexRtPostFilter:Dynamic = null;
var hexRtPostCamera:Dynamic = null;
var hexRtBaseState:Dynamic = null;
var hexRtBaseGameZoom:Float = 1;
var hexRtBaseGameAngle:Float = 0;
var hexRtBaseHudZoom:Float = 1;
var hexRtBaseFollowX:Float = 0;
var hexRtBaseFollowY:Float = 0;
var hexRtBaseCameraCaptured:Bool = false;

function hexRtClamp(v:Float, lo:Float, hi:Float):Float return Math.max(lo, Math.min(hi, v));
function hexRtEase(t:Float, style:String):Float
{
    t = hexRtClamp(t, 0, 1);
    switch (style == null ? 'linear' : style.toLowerCase())
    {
        case 'instant': return 1;
        case 'insine': return 1 - Math.cos(t * Math.PI * 0.5);
        case 'outsine': return Math.sin(t * Math.PI * 0.5);
        case 'inoutsine': return -(Math.cos(Math.PI * t) - 1) * 0.5;
        case 'incubic': return t * t * t;
        case 'outcubic': return 1 - Math.pow(1 - t, 3);
        case 'inoutcubic': return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) * 0.5;
        case 'inquad': return t * t;
        case 'outquad': return 1 - (1 - t) * (1 - t);
        case 'inoutquad': return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) * 0.5;
        default: return t;
    }
}

function hexRtEventEase(ease:String, direction:String):String
{
    var e:String = ease == null ? 'linear' : ease.toLowerCase();
    var d:String = direction == null ? '' : direction.toLowerCase();
    if (e == 'classic') e = 'quad';
    if (e == 'cube') e = 'cubic';
    if (e == 'sine') e = 'sine';
    if (e == 'linear' || e == 'instant') return e;
    if (d == 'in') return 'in' + e;
    if (d == 'out') return 'out' + e;
    if (d == 'inout' || d == 'in-out') return 'inout' + e;
    return 'inout' + e;
}

function hexRtCurrentBeat():Float
{
    var step:Dynamic = game == null ? null : Reflect.field(game, 'curDecStep');
    return step == null ? (Conductor.songPosition * Conductor.bpm / 60000) : (step / 4);
}

function hexRtDurationBeats(duration:Float):Float
{
    // Hex FocusCamera/ZoomCamera durations are beat durations, not seconds.
    return Math.max(0, duration);
}

function hexRtSongName():String
{
    var songData:Dynamic = PlayState.SONG;
    if (songData == null) return '';
    var name:Dynamic = Reflect.field(songData, 'song');
    return name == null ? '' : Std.string(name).toLowerCase();
}

function hexRtCueKey(id:String):String
{
    if (id.indexOf('eye2eye') >= 0) return 'eye2eye';
    if (id.indexOf('detected') >= 0)
    {
        if (id.indexOf('new') >= 0) return 'detected_normal';
        var diff:Dynamic = game == null ? null : Reflect.field(game, 'storyDifficulty');
        if (diff == null && game != null) diff = Reflect.field(game, 'curDifficulty');
        if (diff != null && Std.int(diff) == 1) return 'detected_normal';
        return 'detected';
    }
    if (id.indexOf('headbasher') >= 0) return 'headbasher';
    if (id.indexOf('right pace') >= 0 || id.indexOf('rightpace') >= 0) return 'rightpace';
    if (id.indexOf('tangerine') >= 0)
    {
        var diff:Dynamic = game == null ? null : Reflect.field(game, 'storyDifficulty');
        if (diff == null && game != null) diff = Reflect.field(game, 'curDifficulty');
        if (diff != null && Std.int(diff) == 1) return 'tangerine_normal';
        return 'tangerine';
    }
    return '';
}

function hexRtLoadCueRows(id:String):Array<Dynamic>
{
    var key:String = hexRtCueKey(id);
    if (key == '') return [];
    var rel:String = 'data/modcharts/' + key + '.json';
    try
    {
        if (Paths.fileExists(rel))
        {
            var path:String = Paths.getPath(rel, null, PathsTestMode.NORMAL);
            var raw:String = FunkinAssets.getContent(path);
            var parsed:Dynamic = FunkinAssets.parseJson(raw);
            if (parsed != null) return cast parsed;
        }
    }
    catch (e:Dynamic) {}
    return hexRtCueRows(id);
}

function hexRtCueRows(id:String):Array<Dynamic>
{
    if (id.indexOf('detected') >= 0)
    {
        return [
            [0,0,0,100,'rate',-1,'linear'], [0,0,0,350,'drawAhead',-1,'linear'], [0,0,0,100,'drawAhead.fade',-1,'linear'],
            [0,0,0,672,'spacing',-1,'linear'], [0,0,0,112,'colspacing',-1,'linear'], [0,0,0,0,'dim',-1,'linear'],
            [16,4,0,34,'sway',-1,'inoutsine'], [24,4,34,0,'sway',-1,'inoutsine'],
            [32,8,0,100,'wrap',-1,'inoutsine'], [40,4,100,0,'wrap',-1,'outsine'],
            [48,8,0,38,'halo',-1,'inoutsine'], [56,4,38,0,'halo',-1,'outsine'],
            [64,8,0,22,'camwag',-1,'inoutsine'], [72,4,22,0,'camwag',-1,'outsine'],
            [88,8,0,65,'rowCenterX',-1,'inoutsine'], [96,4,65,0,'rowCenterX',-1,'outsine'],
            [112,8,0,48,'addDrunk',-1,'inoutsine'], [120,4,48,0,'addDrunk',-1,'outsine'],
            [128,8,0,42,'addTipsy',-1,'inoutsine'], [136,4,42,0,'addTipsy',-1,'outsine'],
            [160,8,0,100,'wrap',-1,'inoutsine'], [168,8,100,0,'wrap',-1,'outsine'],
            [192,8,0,35,'sway',-1,'inoutsine'], [200,4,35,0,'sway',-1,'outsine'],
            [224,8,0,18,'camwag',-1,'inoutsine'], [232,4,18,0,'camwag',-1,'outsine']
        ];
    }
    if (id.indexOf('headbasher') >= 0)
    {
        return [
            [0,0,0,311.5,'fieldX',0,'linear'], [0,0,0,63.5,'fieldX',1,'linear'], [0,0,0,88,'zoom',-1,'linear'],
            [0,0,0,50,'blind',0,'linear'], [0,0,0,50,'dim',0,'linear'],
            [174,2,311.5,528,'fieldX',1,'insine'], [174,2,-43.5,-551.5,'fieldX',0,'insine'],
            [192,2,528,-28,'fieldX',0,'outsine'], [192,2,-551.5,93,'fieldX',1,'outsine'],
            [237.5,0,0,100,'hideHits',1,'linear'], [237.5,0,0,798,'bobX.speed',1,'linear'],
            [237.75,0.75,0,23,'bobX',1,'insine'], [238,2,0,-145,'shiftX',1,'insine'],
            [238,2,0,91.5,'shiftX',0,'insine'], [240,4,0,0,'hideHits',1,'linear']
        ];
    }
    if (id.indexOf('right pace') >= 0 || id.indexOf('rightpace') >= 0)
    {
        return [
            [0,0,0,100,'dim',0,'linear'], [0,0,0,100,'rowCenterX',-1,'linear'],
            [8,4,100,0,'rowCenterX',-1,'outsine'], [16,4,0,75,'rowCenterX',-1,'insine'],
            [20,4,75,0,'rowCenterX',-1,'outsine'], [32,4,0,50,'rowCenterX',-1,'insine'],
            [36,4,50,0,'rowCenterX',-1,'outsine'], [48,4,0,-65,'rowCenterX',-1,'insine'],
            [52,4,-65,0,'rowCenterX',-1,'outsine'], [64,4,0,100,'rowCenterX',-1,'insine'],
            [68,4,100,0,'rowCenterX',-1,'outsine'], [80,4,0,0,'dim',0,'linear']
        ];
    }
    if (id.indexOf('tangerine') >= 0)
    {
        var rows:Array<Dynamic> = [
            [0,0,0,275,'drawAhead',-1,'linear'], [0,0,0,60,'rate',-1,'linear'], [0,0,0,0,'hideHits',-1,'linear'],
            [0.01,0.48,0,14,'skewY',-1,'outsine'], [0.5,0.25,14,-14,'skewY',-1,'outsine'],
            [0.75,0.25,-14,14,'skewY',-1,'outsine'], [1,1,14,0,'skewY',-1,'outsine'],
            [1,0.5,0,100,'fold',-1,'insine'], [1.5,0.5,100,-100,'fold',-1,'outsine'],
            [3,0.25,0,14,'skewX',-1,'outsine'], [3.25,0.25,14,-14,'skewX',-1,'outsine'],
            [3.5,0.25,-14,14,'skewX',-1,'outsine'], [3.75,0.25,14,0,'skewX',-1,'outsine'],
            [19.5,0.5,0,25,'rowCenterX',-1,'insine'], [20,0.5,25,50,'rowCenterX',-1,'insine'],
            [20.5,0.5,50,75,'rowCenterX',-1,'insine'], [21,0.5,75,100,'rowCenterX',-1,'insine'],
            [21.5,0.5,100,125,'rowCenterX',-1,'insine'], [22,0.5,125,150,'rowCenterX',-1,'insine'],
            [22.5,0.5,150,175,'rowCenterX',-1,'insine'], [23,0.5,175,200,'rowCenterX',-1,'insine'],
            [23.5,0.5,200,175,'rowCenterX',-1,'insine'], [24,0.5,175,150,'rowCenterX',-1,'insine'],
            [24.5,0.5,150,125,'rowCenterX',-1,'insine'], [25,0.5,125,100,'rowCenterX',-1,'insine'],
            [25.5,0.5,100,75,'rowCenterX',-1,'insine'], [26,0.5,75,50,'rowCenterX',-1,'insine'],
            [26.5,0.5,50,25,'rowCenterX',-1,'insine'], [27,0.5,25,0,'rowCenterX',-1,'insine'],
            [31,0.5,0,50,'fold',-1,'insine'], [31.5,0.5,50,100,'fold',-1,'insine'],
            [32,1,100,0,'fold',-1,'outsine'], [35,0.5,0,0,'fold',-1,'instant'],
            [36,4,0,18,'cam.rotZ',-1,'insine'], [40,4,18,0,'cam.rotZ',-1,'outsine'],
            [48,4,0,35,'pinch',-1,'insine'], [52,4,35,0,'pinch',-1,'outsine'],
            [64,4,0,100,'mirror',-1,'insine'], [68,4,100,0,'mirror',-1,'outsine'],
            [80,4,0,60,'drunk',-1,'insine'], [84,4,60,0,'drunk',-1,'outsine'],
            [96,4,0,40,'tipsy',-1,'insine'], [100,4,40,0,'tipsy',-1,'outsine'],
            [128,8,0,100,'fold',-1,'insine'], [136,8,100,0,'fold',-1,'outsine'],
            [160,8,0,20,'cam.rotZ',-1,'insine'], [168,8,20,0,'cam.rotZ',-1,'outsine']
        ];
        return rows;
    }
    return [];
}

function hexRtTrackActive(name:String):Void
{
    if (name != null && name != '' && hexRuntimeActive.indexOf(name) < 0)
        hexRuntimeActive.push(name);
}

function hexRtNativePercent(name:String):Bool
{
    return name == 'alpha' || name == 'drunk' || name == 'tipsy' || name == 'beat' || name == 'reverse' || name == 'confusion' || name == 'stealth' || name == 'mini' || name == 'opponentSwap' || name == 'flip' || name == 'accel' || name == 'xmod' || name == 'scale';
}

function hexRtWrite(name:String, value:Float, player:Int)
{
    if (modManager == null || value != value) return;
    if (hexRuntimeSong.indexOf('detected') >= 0)
    {
        var p:Int = player < 0 ? -1 : player % 2;
        if (name == 'alpha')
        {
            if (modManager.get('alpha') != null) { modManager.setValue('alpha', 1, p); hexRtTrackActive('alpha'); }
            hexRtWrite('blind', 100 - value, p);
            hexRtWrite('dim', 100 - value, p);
            return;
        }
        if (name == 'addDrunk' || name == 'easydrunk' || name == 'easyDrunk')
        {
            if (modManager.get('drunk') != null) { modManager.setValue('drunk', value / 100, p); hexRtTrackActive('drunk'); }
            return;
        }
        if (name == 'addTipsy')
        {
            if (modManager.get('tipsy') != null) { modManager.setValue('tipsy', value / 100, p); hexRtTrackActive('tipsy'); }
            return;
        }
        if (name == 'camwag')
        {
            hexRtWrite('tiltZ', value, p);
            return;
        }
    }
    var target:Dynamic = modManager.get(name);
    if (target == null) return;
    var out:Float = hexRtNativePercent(name) ? value / 100 : value;
    if (player < 0)
    {
        modManager.setValue(name, out, -1);
        hexRtTrackActive(name);
        return;
    }
    var p:Int = player % 2;
    if (p < 0) p = 0;
    var lanes:Dynamic = Reflect.field(modManager, 'lanes');
    if (lanes != null && p >= lanes) return;
    modManager.setValue(name, out, p);
    hexRtTrackActive(name);
}

function hexRtResetCueState()
{
    hexRuntimeNextCue = 0;
    hexRuntimeStateKeys = [];
    hexRuntimeStateCue = [];
}

function hexRtQueueCueState(cueIndex:Int)
{
    var cue:Dynamic = hexRuntimeCueRows[cueIndex];
    if (cue == null || cue.length < 7) return;
    var name:String = Std.string(cue[4]);
    var player:Int = Std.int(cue[5]);
    var targets:Array<Int> = player < 0 ? [0,1] : [player % 2];
    for (p in targets)
    {
        var key:String = name + ':' + p;
        var at:Int = hexRuntimeStateKeys.indexOf(key);
        if (at < 0)
        {
            hexRuntimeStateKeys.push(key);
            hexRuntimeStateCue.push(cueIndex);
        }
        else hexRuntimeStateCue[at] = cueIndex;
    }
}

function hexRtRunCues(beat:Float)
{
    if (beat < hexRuntimeLastBeat)
    {
        for (name in hexRuntimeActive) if (modManager != null && modManager.get(name) != null) modManager.setValue(name, 0, -1);
        hexRuntimeActive = [];
        hexRtResetCueState();
    }
    while (hexRuntimeNextCue < hexRuntimeCueRows.length)
    {
        var cue:Dynamic = hexRuntimeCueRows[hexRuntimeNextCue];
        if (cue == null || cue.length < 7) { hexRuntimeNextCue++; continue; }
        if (cue[0] > beat) break;
        hexRtQueueCueState(hexRuntimeNextCue);
        hexRuntimeNextCue++;
    }
    for (i in 0...hexRuntimeStateKeys.length)
    {
        var cue:Dynamic = hexRuntimeCueRows[hexRuntimeStateCue[i]];
        var start:Float = cue[0];
        var duration:Float = cue[1];
        var from:Float = cue[2] == null ? 0 : cue[2];
        var to:Float = cue[3];
        var name:String = Std.string(cue[4]);
        var player:Int = Std.int(cue[5]);
        var ease:String = Std.string(cue[6]);
        var t:Float = duration <= 0 ? 1 : hexRtClamp((beat - start) / duration, 0, 1);
        var value:Float = from + (to - from) * hexRtEase(t, ease);
        var parts:Array<String> = hexRuntimeStateKeys[i].split(':');
        if (parts.length > 1) hexRtWrite(parts[0], value, Std.parseInt(parts[1]));
    }
}

function hexRtSyncStage()
{
    if (game == null || game.variables == null || modManager == null) return;
    if (hexRuntimeSong.indexOf('eye2eye') < 0) return;
    var radius:Float = 1400;
    var r = modManager.get('stage.radius');
    if (r != null && r.getValue(0) > 0) radius = r.getValue(0);
    game.variables.set('eye2eye.radius', radius);
    var gray:Float = 0;
    var inv:Float = 0;
    var gm = modManager.get('stage.gray');
    var im = modManager.get('stage.invert');
    if (gm != null) gray = hexRtClamp(gm.getValue(0) / 100, 0, 1);
    if (im != null) inv = hexRtClamp(im.getValue(0) / 100, 0, 1);
    game.variables.set('eye2eye.gray', gray);
    game.variables.set('eye2eye.invert', inv);
}

function hexRtReset()
{
    if (modManager != null)
    {
        for (name in hexRuntimeActive)
        {
            if (modManager.get(name) == null) continue;
            modManager.setValue(name, 0, -1);
        }
    }
    hexRuntimeActive = [];
}

function hexRtFocusedCharacter():Dynamic
{
    if (game == null) return null;
    if (hexRtFocusTarget == 0) return Reflect.field(game, 'boyfriend');
    if (hexRtFocusTarget == 1) return Reflect.field(game, 'dad');
    if (hexRtFocusTarget == 2) return Reflect.field(game, 'gf');
    return null;
}

function hexRtUpdateFocus(beat:Float)
{
    if (!hexRtFocusActive || game == null || game.camFollow == null) return;
    var target:Dynamic = hexRtFocusedCharacter();
    if (target == null) return;
    var tx:Float = hexRtFocusOffsetX;
    var ty:Float = hexRtFocusOffsetY;
    try
    {
        var mid:Dynamic = target.getMidpoint();
        tx += mid.x;
        ty += mid.y;
    }
    catch (e:Dynamic) return;
    var t:Float = hexRtFocusDuration <= 0 ? 1 : hexRtClamp((beat - hexRtFocusStart) / hexRtFocusDuration, 0, 1);
    var eased:Float = hexRtEase(t, hexRtFocusEase);
    game.camFollow.x = hexRtFocusFromX + (tx - hexRtFocusFromX) * eased;
    game.camFollow.y = hexRtFocusFromY + (ty - hexRtFocusFromY) * eased;
}

function hexRtUpdateZoom(beat:Float)
{
    if (game == null) return;
    var camera:Dynamic = hexRtZoomMode == 'hud' ? game.camHUD : game.camGame;
    if (camera == null) return;
    if (hexRtZoomActive)
    {
        var t:Float = hexRtZoomDuration <= 0 ? 1 : hexRtClamp((beat - hexRtZoomStart) / hexRtZoomDuration, 0, 1);
        camera.zoom = hexRtZoomFrom + (hexRtZoomTo - hexRtZoomFrom) * hexRtEase(t, hexRtZoomEase);
    }
    if (game.camGame != null)
    {
        game.camGame.zoom -= hexRtBopLast;
        var phase:Float = (beat + hexRtBopOffset) * Math.PI * 0.5 * Math.max(0, hexRtBopRate);
        var bop:Float = Math.sin(phase) * hexRtBopIntensity * 0.012;
        game.camGame.zoom += bop;
        hexRtBopLast = bop;
    }
}

function hexRtCharId(who:Dynamic, slot:Int):String
{
    var id:Dynamic = null;
    try { id = Reflect.field(who, 'curCharacter'); } catch (e:Dynamic) {}
    if (id == null) { try { id = Reflect.field(who, 'characterId'); } catch (e:Dynamic) {} }
    if (id == null) { try { id = Reflect.field(who, 'character'); } catch (e:Dynamic) {} }
    if (id == null && game != null)
    {
        var song:Dynamic = PlayState.SONG;
        var field:String = slot == 0 ? 'player1' : (slot == 1 ? 'player2' : 'gfVersion');
        if (song != null) { try { id = Reflect.field(song, field); } catch (e:Dynamic) {} }
    }
    return id == null ? '' : Std.string(id).toLowerCase();
}

function hexRtLookAsset(id:String, look:String):String
{
    return Paths.getPath('images/looks/hex/' + id + '-' + look + '.png', null, PathsTestMode.NORMAL);
}

function hexRtHasLook(id:String, look:String):Bool
{
    if (look == null || look == '' || look == 'none') return true;
    if (id == null || id == '') return false;
    try { return FunkinAssets.exists(hexRtLookAsset(id, look)); } catch (e:Dynamic) { return false; }
}

function hexRtFirstLook(id:String):String
{
    for (look in ['dark', 'lcdred', 'lcdreddark', 'night', 'sunset', 'weekend', 'weekend-dark'])
        if (hexRtHasLook(id, look)) return look;
    return '';
}

function hexRtBindLook(shader:Dynamic, id:String, look:String, sampler:String, flag:String):Void
{
    var on:Bool = look != null && look != '' && look != 'none';
    shader.setFloat(flag, on ? 1 : 0);
    var fallback:String = on ? look : hexRtFirstLook(id);
    if (fallback == '') return;
    var path:String = hexRtLookAsset(id, fallback);
    var bitmap:Dynamic = null;
    try { bitmap = FunkinAssets.getBitmapData(path, false); } catch (e:Dynamic) {}
    if (bitmap != null) try { shader.setBitmapData(sampler, bitmap); } catch (e:Dynamic) {}
    else shader.setFloat(flag, 0);
}

function hexRtRemoveLook(index:Int):Void
{
    if (index < 0 || index >= hexRtLookChars.length) return;
    var who:Dynamic = hexRtLookChars[index];
    var shader:Dynamic = hexRtLookShaders[index];
    if (who != null && shader != null)
    {
        try { if (Reflect.field(who, 'shader') == shader) who.shader = null; } catch (e:Dynamic) {}
    }
    hexRtLookChars.splice(index, 1);
    hexRtLookShaders.splice(index, 1);
    hexRtLookFrom.splice(index, 1);
    hexRtLookTo.splice(index, 1);
    hexRtLookStarts.splice(index, 1);
    hexRtLookDurations.splice(index, 1);
}

function hexRtResetLooks():Void
{
    var i:Int = hexRtLookChars.length;
    while (i-- > 0) hexRtRemoveLook(i);
    hexRtLookClock = 0;
}

function hexRtSetLook(look:String, fade:Float):Void
{
    var chars:Array<Dynamic> = [Reflect.field(game, 'boyfriend'), Reflect.field(game, 'dad'), Reflect.field(game, 'gf')];
    var i:Int = 0;
    while (i < chars.length)
    {
        var who:Dynamic = chars[i];
        if (who == null) { i++; continue; }
        var id:String = hexRtCharId(who, i);
        var target:String = (look == null || look == 'none') ? '' : look.toLowerCase();
        if (target != '' && !hexRtHasLook(id, target)) { i++; continue; }
        var at:Int = hexRtLookChars.indexOf(who);
        if (at < 0)
        {
            if (target == '') { i++; continue; }
            var shader:Dynamic = null;
            try { shader = newShader('hex/characterLook'); } catch (e:Dynamic) {}
            if (shader == null) { i++; continue; }
            hexRtLookChars.push(who);
            hexRtLookShaders.push(shader);
            hexRtLookFrom.push('');
            hexRtLookTo.push('');
            hexRtLookStarts.push(hexRtLookClock);
            hexRtLookDurations.push(0);
            at = hexRtLookChars.length - 1;
            who.shader = shader;
        }
        hexRtLookFrom[at] = hexRtLookTo[at];
        hexRtLookTo[at] = target;
        hexRtLookStarts[at] = hexRtLookClock;
        hexRtLookDurations[at] = Math.max(0, fade);
        var activeShader:Dynamic = hexRtLookShaders[at];
        hexRtBindLook(activeShader, id, hexRtLookFrom[at], 'lutFrom', 'uFromOn');
        hexRtBindLook(activeShader, id, hexRtLookTo[at], 'lutTo', 'uToOn');
        activeShader.setFloat('uBlend', fade <= 0 ? 1 : 0);
        i++;
    }
    hexRtUpdateLooks(0);
}

function hexRtUpdateLooks(elapsed:Float):Void
{
    var i:Int = hexRtLookChars.length;
    while (i-- > 0)
    {
        var who:Dynamic = hexRtLookChars[i];
        var shader:Dynamic = hexRtLookShaders[i];
        if (who == null || shader == null) { hexRtRemoveLook(i); continue; }
        var duration:Float = hexRtLookDurations[i];
        var t:Float = duration <= 0 ? 1 : hexRtClamp((hexRtLookClock - hexRtLookStarts[i]) / duration, 0, 1);
        shader.setFloat('uBlend', hexRtEase(t, 'inoutsine'));
        if (t >= 1 && hexRtLookTo[i] == '') hexRtRemoveLook(i);
    }
}

function hexRtChannelValue(name:String):Float
{
    if (modManager == null) return 0;
    var mod:Dynamic = modManager.get(name);
    if (mod == null) return 0;
    var value:Dynamic = mod.getValue(0);
    return value == null || Math.isNaN(value) ? 0 : value;
}

function hexRtRemovePostFilter():Void
{
    if (game != null && game.camGame != null && hexRtPostFilter != null)
    {
        var out:Array<Dynamic> = [];
        try
        {
            var current:Dynamic = game.camGame.filters;
            if (current != null) for (filter in current) if (filter != null && filter != hexRtPostFilter) out.push(filter);
            game.camGame.filters = out;
        }
        catch (e:Dynamic) {}
    }
    hexRtPostShader = null;
    hexRtPostFilter = null;
    hexRtPostCamera = null;
}

function hexRtUpdatePostFX(beat:Float):Void
{
    if (game == null || game.camGame == null || modManager == null) return;
    var glitch:Float = Math.max(Math.abs(hexRtChannelValue('screen.glitch')), Math.abs(hexRtChannelValue('screen.glitch 2')));
    var gray:Float = Math.abs(hexRtChannelValue('stage.gray'));
    var invert:Float = Math.abs(hexRtChannelValue('stage.invert'));
    var active:Bool = glitch > 0.01 || gray > 0.01 || invert > 0.01;
    if (!active)
    {
        if (hexRtPostFilter != null) hexRtRemovePostFilter();
        return;
    }
    if (hexRtPostShader == null || hexRtPostCamera != game.camGame)
    {
        if (hexRtPostFilter != null) hexRtRemovePostFilter();
        try
        {
            hexRtPostShader = newShader('hex/hex_stage_fx');
            if (hexRtPostShader == null) return;
            hexRtPostFilter = new ShaderFilter(hexRtPostShader);
            hexRtPostCamera = game.camGame;
        }
        catch (e:Dynamic)
        {
            hexRtPostShader = null;
            hexRtPostFilter = null;
            return;
        }
    }
    hexRtPostShader.setFloat('uBeat', beat);
    hexRtPostShader.setFloat('uGlitch', hexRtClamp(glitch / 100, 0, 1));
    hexRtPostShader.setFloat('uGray', hexRtClamp(gray / 100, 0, 1));
    hexRtPostShader.setFloat('uInvert', hexRtClamp(invert / 100, 0, 1));
    var found:Bool = false;
    try
    {
        var current:Dynamic = game.camGame.filters;
        if (current != null) for (filter in current) if (filter == hexRtPostFilter) found = true;
        if (!found)
        {
            var out:Array<Dynamic> = [];
            if (current != null) for (filter in current) if (filter != null) out.push(filter);
            out.push(hexRtPostFilter);
            game.camGame.filters = out;
        }
    }
    catch (e:Dynamic) {}
}


function hexRtCaptureBaseCamera():Void
{
    if (game == null || game.camGame == null) return;
    if (hexRtBaseState == game && hexRtBaseCameraCaptured) return;
    hexRtBaseState = game;
    hexRtBaseGameZoom = game.camGame.zoom;
    hexRtBaseGameAngle = game.camGame.angle;
    hexRtBaseHudZoom = game.camHUD == null ? 1 : game.camHUD.zoom;
    hexRtBaseFollowX = game.camFollow == null ? 0 : game.camFollow.x;
    hexRtBaseFollowY = game.camFollow == null ? 0 : game.camFollow.y;
    hexRtBaseCameraCaptured = true;
}

function hexRtRestoreBaseCamera():Void
{
    if (game == null || !hexRtBaseCameraCaptured || hexRtBaseState != game) return;
    try { if (game.camGame != null) { game.camGame.zoom = hexRtBaseGameZoom; game.camGame.angle = hexRtBaseGameAngle; } } catch (e:Dynamic) {}
    try { if (game.camHUD != null) game.camHUD.zoom = hexRtBaseHudZoom; } catch (e:Dynamic) {}
    try { if (game.camFollow != null) { game.camFollow.x = hexRtBaseFollowX; game.camFollow.y = hexRtBaseFollowY; } } catch (e:Dynamic) {}
}

function hexRtRestartSession(restoreCamera:Bool):Void
{
    if (restoreCamera) hexRtRestoreBaseCamera();
    hexRtResetLooks();
    hexRtRemovePostFilter();
    hexRtReset();
    hexRuntimeSong = '';
    hexRuntimeLastBeat = -999999;
    hexRuntimeCueRows = [];
    hexRuntimeCueKey = '';
    hexRtResetCueState();
    hexRtFocusActive = false;
    hexRtZoomActive = false;
    hexRtFocusTarget = -1;
    hexRtBopIntensity = 0;
    hexRtBopOffset = 0;
    hexRtBopRate = 1;
    hexRtBopLast = 0;
    hexRuntimeLook = '';
}

function onCreatePost():Void
{
    hexRtCaptureBaseCamera();
}

function onSongLoaded(event:Dynamic = null):Void
{
    hexRtRestartSession(hexRtBaseState == game);
    hexRtCaptureBaseCamera();
}

function onSongRetry(event:Dynamic = null):Void
{
    hexRtRestartSession(true);
}

function onUpdatePost(elapsed:Float)
{
    if (game == null || modManager == null) return;
    var id:String = hexRtSongName();
    if (id == '') return;
    if (id != hexRuntimeSong)
    {
        hexRtReset();
        hexRtResetLooks();
        hexRtRemovePostFilter();
        hexRuntimeSong = id;
        hexRuntimeLastBeat = -999999;
        hexRuntimeCueKey = hexRtCueKey(id);
        hexRuntimeCueRows = hexRtLoadCueRows(id);
        hexRtResetCueState();
        hexRtFocusActive = false;
        hexRtZoomActive = false;
        hexRtFocusTarget = -1;
        hexRtBopIntensity = 0;
        hexRtBopOffset = 0;
        hexRtBopRate = 1;
        hexRtBopLast = 0;
    }
    var beat:Float = hexRtCurrentBeat();
    if (hexRuntimeSong.indexOf('eye2eye') < 0) hexRtRunCues(beat);
    hexRtLookClock += Math.max(0, elapsed);
    hexRtUpdateLooks(elapsed);
    hexRtUpdatePostFX(beat);
    hexRtUpdateFocus(beat);
    hexRtUpdateZoom(beat);
    hexRtSyncStage();
    hexRuntimeLastBeat = beat;
}

function onEvent(eventName:Dynamic, value1:Dynamic = null, value2:Dynamic = null)
{
    if (game == null || eventName == null) return;
    var name:String = Std.string(eventName);
    var a:String = value1 == null ? '' : Std.string(value1);
    var b:String = value2 == null ? '' : Std.string(value2);
    var args:Array<String> = b.split('|');
    var beat:Float = hexRtCurrentBeat();
    if (name == 'HEX FocusCamera')
    {
        var focus:Int = Std.parseInt(a);
        if (focus < 0 || focus > 2) return;
        var duration:Float = args.length > 0 ? Std.parseFloat(args[0]) : 0;
        if (Math.isNaN(duration)) duration = 0;
        var ease:String = args.length > 1 ? hexRtEventEase(args[1], args.length > 2 ? args[2] : '') : 'linear';
        var offX:Float = args.length > 3 ? Std.parseFloat(args[3]) : 0;
        var offY:Float = args.length > 4 ? Std.parseFloat(args[4]) : 0;
        if (Math.isNaN(offX)) offX = 0;
        if (Math.isNaN(offY)) offY = 0;
        hexRtFocusTarget = focus;
        hexRtFocusStart = beat;
        hexRtFocusDuration = hexRtDurationBeats(duration);
        hexRtFocusOffsetX = offX;
        hexRtFocusOffsetY = offY;
        hexRtFocusEase = ease;
        hexRtFocusFromX = game.camFollow == null ? 0 : game.camFollow.x;
        hexRtFocusFromY = game.camFollow == null ? 0 : game.camFollow.y;
        hexRtFocusActive = true;
        hexRtUpdateFocus(beat);
        return;
    }
    if (name == 'HEX ZoomCamera')
    {
        var zoom:Float = Std.parseFloat(a);
        if (Math.isNaN(zoom)) return;
        var duration:Float = args.length > 0 ? Std.parseFloat(args[0]) : 0;
        if (Math.isNaN(duration)) duration = 0;
        var ease:String = args.length > 1 ? hexRtEventEase(args[1], args.length > 2 ? args[2] : '') : 'linear';
        var mode:String = args.length > 3 ? args[3].toLowerCase() : 'stage';
        hexRtZoomMode = mode == 'hud' ? 'hud' : 'stage';
        var camera:Dynamic = hexRtZoomMode == 'hud' ? game.camHUD : game.camGame;
        if (camera == null) return;
        hexRtZoomFrom = camera.zoom;
        hexRtZoomTo = zoom;
        hexRtZoomStart = beat;
        hexRtZoomDuration = hexRtDurationBeats(duration);
        hexRtZoomEase = ease;
        hexRtZoomActive = true;
        hexRtUpdateZoom(beat);
        return;
    }
    if (name == 'HEX SetCameraBop')
    {
        var intensity:Float = Std.parseFloat(a);
        var offset:Float = args.length > 0 ? Std.parseFloat(args[0]) : 0;
        var rate:Float = args.length > 1 ? Std.parseFloat(args[1]) : 1;
        if (Math.isNaN(intensity)) intensity = 0;
        if (Math.isNaN(offset)) offset = 0;
        if (Math.isNaN(rate)) rate = 1;
        hexRtBopIntensity = intensity;
        hexRtBopOffset = offset;
        hexRtBopRate = rate;
        return;
    }
    if (name == 'HEX SwitchCharacter')
    {
        var target:Int = Std.parseInt(a);
        if (target < 0 || target > 2 || args.length < 1 || args[0] == '') return;
        var charId:String = args[0];
        var offsetX:Float = args.length > 1 ? Std.parseFloat(args[1]) : 0;
        var offsetY:Float = args.length > 2 ? Std.parseFloat(args[2]) : 0;
        var stageMark:Bool = args.length > 3 ? (args[3] == 'true' || args[3] == '1') : false;
        var fade:Float = args.length > 4 ? Std.parseFloat(args[4]) : 0;
        if (Math.isNaN(offsetX)) offsetX = 0;
        if (Math.isNaN(offsetY)) offsetY = 0;
        if (Math.isNaN(fade)) fade = 0;
        try
        {
            var fn:Dynamic = Reflect.field(game, 'changeCharacter');
            if (fn != null && Reflect.isFunction(fn)) Reflect.callMethod(game, fn, [charId, target]);
            var ch:Dynamic = target == 0 ? Reflect.field(game, 'boyfriend') : (target == 1 ? Reflect.field(game, 'dad') : Reflect.field(game, 'gf'));
            if (ch != null)
            {
                if (!stageMark) { ch.x += offsetX; ch.y += offsetY; }
                if (fade > 0)
                {
                    ch.alpha = 0;
                    try { FlxTween.tween(ch, {alpha: 1}, fade); } catch (e:Dynamic) { ch.alpha = 1; }
                }
            }
        }
        catch (e:Dynamic) {}
        return;
    }
    if (name == 'HEX CharacterLook')
    {
        var fade:Float = Std.parseFloat(b);
        if (Math.isNaN(fade) || fade < 0) fade = 0;
        hexRtSetLook(a, fade);
        hexRuntimeLook = a;
        return;
    }
    if (name == 'HEX PlayAnimation')
    {
        var target:String = a.toLowerCase();
        var char:Dynamic = null;
        if (target == 'bf' || target == 'boyfriend' || target == 'player') char = Reflect.field(game, 'boyfriend');
        else if (target == 'dad' || target == 'opponent' || target == 'hex') char = Reflect.field(game, 'dad');
        else if (target == 'gf' || target == 'girlfriend') char = Reflect.field(game, 'gf');
        else
        {
            var bf:Dynamic = Reflect.field(game, 'boyfriend');
            var dad:Dynamic = Reflect.field(game, 'dad');
            var gf:Dynamic = Reflect.field(game, 'gf');
            if (hexRtCharId(bf, 0) == target) char = bf;
            else if (hexRtCharId(dad, 1) == target) char = dad;
            else if (hexRtCharId(gf, 2) == target) char = gf;
        }
        if (char != null && args.length > 0 && args[0] != '')
        {
            var play:Dynamic = Reflect.field(char, 'playAnim');
            var force:Bool = args.length > 1 && (args[1] == 'true' || args[1] == '1');
            if (play != null && Reflect.isFunction(play))
            {
                try { Reflect.callMethod(char, play, [args[0], force]); }
                catch (e:Dynamic) { try { Reflect.callMethod(char, play, [args[0]]); } catch (inner:Dynamic) {} }
            }
        }
        return;
    }
}

function onDestroy()
{
    hexRtRestartSession(true);
    hexRtBaseState = null;
    hexRtBaseCameraCaptured = false;
}
