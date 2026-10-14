import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import openfl.filters.ShaderFilter;
import Reflect;

var e2ePath = 'stages/hex/iris_void/';
var e2eLids:Array<FlxSprite> = [];
var e2eIrises:Array<FlxSprite> = [];
var e2eBodies:Array<FlxSprite> = [];
var e2eStrips:FlxSprite;
var e2eStripShader:Dynamic;
var e2eGlitchShader:Dynamic;
var e2eSkipText:FlxText;
var e2eText1:Dynamic;
var e2eText2:Dynamic;
var e2eText3:Dynamic;
var e2eText4:Dynamic;
var e2eText5:Dynamic;
var e2eOldGameFilters:Dynamic;
var e2eBaseZoom:Float = 0.9;
var e2eRealHealth:Float = 2;
var e2eLastBeat:Float = -1;
var e2eLastSongPos:Float = 0;
var e2eAdditionalGlitch:Float = 0;
var e2eEyesShown:Bool = false;
var e2eSkipped:Bool = false;
var e2eSkipQueued:Bool = false;
var e2eInitialised:Bool = false;
var e2eModCache:Dynamic = {};
var e2eBaseHealthLoss:Float = 1;
var e2eHealthLossCaptured:Bool = false;
var e2eHudSaved:Array<Dynamic> = [];
var e2eHudCaptured:Bool = false;
var e2eEyeAngle:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
var e2eEyeBaseAngle:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
var e2eEyeReach:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
var e2eEyeBecome:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
var e2eOutline:Array<Float> = [254,247,233,215,200,188,175,165,158,150,145,142,140,138,135,133,133,134,133,135,137,139,142,144,148,154,160,167,175,182,189,200,214,226,238,244,231,218,205,195,183,176,169,163,159,156,154,152,149,146,145,146,146,146,146,148,150,152,155,158,162,165,169,173,179,186,195,202,211,222,232,241];

function e2eClamp(v:Float, lo:Float, hi:Float):Float
{
    return Math.max(lo, Math.min(hi, v));
}

function e2eLerp(a:Float, b:Float, t:Float):Float
{
    return a + (b - a) * e2eClamp(t, 0, 1);
}

function e2eTween(beat:Float, start:Float, duration:Float, from:Float, to:Float):Float
{
    return e2eLerp(from, to, (beat - start) / duration);
}

function e2eGetVar(key:String, fallback:Dynamic):Dynamic
{
    var value:Dynamic = game.variables.get(key);
    return value == null ? fallback : value;
}

function e2eAssetExists(path:String):Bool
{
    return Paths.fileExists(path);
}

function e2eAtlasExists(path:String):Bool
{
    return e2eAssetExists('images/' + path + '.png') && e2eAssetExists('images/' + path + '.xml');
}

function e2eMakeAnimatedAtlas(path:String, prefix:String, z:Int):FlxSprite
{
    if (!e2eAtlasExists(path)) return null;
    var spr = new FlxSprite(0, 0);
    spr.frames = Paths.getSparrowAtlas(path);
    spr.animation.addByPrefix('idle', prefix, 24, true);
    spr.animation.play('idle');
    spr.antialiasing = true;
    spr.zIndex = z;
    game.stage.add(spr);
    return spr;
}

function e2eCreateEyes()
{
    e2eDropEyes();
    if (dad == null) return;
    if (!e2eAtlasExists(e2ePath + 'iris-detached/Iris_Eyelid')) return;
    if (!e2eAtlasExists(e2ePath + 'iris-detached/Iris_Iris')) return;

    var camZoom:Float = game.camGame.zoom;
    if (camZoom <= 0) camZoom = e2eBaseZoom;
    var tileW:Float = FlxG.width / camZoom * 0.85;
    var tileH:Float = FlxG.height / camZoom * 0.85;
    var fromX:Float = dad.x - dad.offset.x;
    var fromY:Float = dad.y - dad.offset.y;

    e2eStripShader = null;
    var hasStripTexture:Bool = e2eAssetExists('images/' + e2ePath + 'Eye2Eye_BG_1.png');
    if (hasStripTexture && e2eAssetExists('shaders/eye2eye/eye2eye_strips.frag'))
        e2eStripShader = newShader('eye2eye/eye2eye_strips');

    if (hasStripTexture)
    {
        e2eStrips = new FlxSprite(0, 0);
        e2eStrips.loadGraphic(Paths.image(e2ePath + 'Eye2Eye_BG_1'));
        e2eStrips.antialiasing = true;
        if (e2eStripShader != null)
        {
            e2eStripShader.setFloat('uTilesX', 3);
            e2eStripShader.setFloat('uTilesY', 3);
            e2eStripShader.setFloat('uTileW', FlxG.width / camZoom);
            e2eStripShader.setFloat('uTileH', FlxG.height / camZoom);
            e2eStripShader.setFloat('uScroll', 0);
            e2eStrips.shader = e2eStripShader;
        }
        e2eStrips.zIndex = 10;
        e2eStrips.setGraphicSize(Std.int(3 * tileW), Std.int(3 * tileH));
        e2eStrips.updateHitbox();
        e2eStrips.x = fromX - tileW * 1.5;
        e2eStrips.y = fromY - tileH * 1.5;
        game.stage.add(e2eStrips);
    }
    else
    {
        e2eStrips = null;
        e2eStripShader = null;
    }

    for (row in -1...2)
    {
        for (col in -1...2)
        {
            if (row == 0 && col == 0) continue;

            var lid = e2eMakeAnimatedAtlas(e2ePath + 'iris-detached/Iris_Eyelid', 'IRIS_Eyelid', 24);
            var iris = e2eMakeAnimatedAtlas(e2ePath + 'iris-detached/Iris_Iris', 'IRIS_Iris', 25);
            if (lid == null || iris == null)
            {
                if (lid != null) { game.stage.remove(lid, true); lid.destroy(); }
                if (iris != null) { game.stage.remove(iris, true); iris.destroy(); }
                e2eDropEyes();
                return;
            }
            lid.x = fromX + col * tileW;
            lid.y = fromY + row * tileH;
            iris.x = lid.x + 576;
            iris.y = lid.y + 317;

            var body = new FlxSprite(0, 0);
            body.frames = dad.frames;
            body.antialiasing = true;
            body.zIndex = 23;
            body.alpha = 0;
            body.visible = false;
            game.stage.add(body);

            e2eLids.push(lid);
            e2eIrises.push(iris);
            e2eBodies.push(body);
        }
    }
}

function e2eDropEyes()
{
    if (game != null && game.stage != null)
    {
        var all:Array<FlxSprite> = [e2eStrips].concat(e2eLids).concat(e2eIrises).concat(e2eBodies);
        for (spr in all)
        {
            if (spr == null) continue;
            game.stage.remove(spr, true);
            spr.destroy();
        }
    }
    e2eStrips = null;
    e2eStripShader = null;
    e2eLids = [];
    e2eIrises = [];
    e2eBodies = [];
}

function e2eShowEyes(on:Bool)
{
    e2eEyesShown = on;
    if (e2eStrips != null) e2eStrips.visible = on;
    for (lid in e2eLids) lid.visible = on;
    for (iris in e2eIrises) iris.visible = on;
    for (body in e2eBodies) body.visible = false;
}

function e2eOutlineAt(angle:Float):Float
{
    var a:Float = angle % 360;
    if (a < 0) a += 360;
    var at:Float = a / 5;
    var i:Int = Std.int(Math.floor(at));
    var lo:Float = e2eOutline[i % 72];
    var hi:Float = e2eOutline[(i + 1) % 72];
    return lo + (hi - lo) * (at - i);
}

function e2ePlaceIris(i:Int, angle:Float, reach:Float)
{
    if (reach < 0)
    {
        reach = -reach;
        angle += 180;
    }
    reach = Math.min(100, reach);
    var room:Float = Math.max(0, e2eOutlineAt(angle) - 45);
    var far:Float = room * reach / 100;
    var radians:Float = angle * Math.PI / 180;
    e2eIrises[i].x = e2eLids[i].x + 576 + Math.cos(radians) * far;
    e2eIrises[i].y = e2eLids[i].y + 317 + Math.sin(radians) * far;
}

function e2ePlaceEyes(beat:Float)
{
    if (e2eLids.length == 0 || dad == null) return;

    e2eUpdateEyeChannels(beat);
    var frame:Int = Std.int(Math.floor(Conductor.songPosition * 0.024)) % 24;
    if (frame < 0) frame += 24;

    for (i in 0...e2eLids.length)
    {
        var much:Float = e2eClamp(e2eEyeBecome[i], 0, 1);
        e2eLids[i].alpha = 1 - much;
        e2eIrises[i].alpha = 1 - much;
        e2eLids[i].visible = e2eEyesShown && much < 1;
        e2eIrises[i].visible = e2eEyesShown && much < 1;
        e2ePlaceIris(i, e2eEyeAngle[i], e2eEyeReach[i] * (1 - much));

        var body = e2eBodies[i];
        body.visible = e2eEyesShown && much > 0;
        body.alpha = much;
        if (!body.visible) continue;
        if (dad.frame != null) body.frame = dad.frame;
        body.origin.set(dad.origin.x, dad.origin.y);
        body.offset.set(dad.offset.x, dad.offset.y);
        body.scale.set(dad.scale.x, dad.scale.y);
        body.flipX = dad.flipX;
        body.flipY = dad.flipY;
        body.color = dad.color;
        body.x = e2eLids[i].x + dad.offset.x;
        body.y = e2eLids[i].y + dad.offset.y;
    }
}

function e2eUpdateEyeChannels(beat:Float)
{
    for (i in 0...8)
    {
        e2eEyeAngle[i] = 0;
        e2eEyeReach[i] = 0;
        e2eEyeBecome[i] = 0;
    }

    e2eEyeBaseAngle = [0, 0, 0, 0, 0, 0, 0, 0];
    if (beat >= 88)
    {
        e2eEyeBaseAngle[2] = 149.5;
        e2eEyeBaseAngle[4] = 172;
        e2eEyeBaseAngle[5] = -10;
        e2eEyeBaseAngle[6] = -73;
    }
    if (beat >= 88.25) e2eEyeBaseAngle[7] = 192;
    if (beat >= 88.4167)
    {
        e2eEyeBaseAngle[0] = 25.5;
        e2eEyeBaseAngle[1] = 90;
    }

    var eyeTurn:Float = 0;
    if (beat >= 96 && beat < 152)
    {
        var start:Float = 96 + Math.floor((beat - 96) / 8) * 8;
        var t:Float = e2eClamp((beat - start) / 8, 0, 1);
        eyeTurn = 360 * (1 - Math.cos(t * Math.PI * 0.5));
    }
    else if (beat >= 152 && beat < 192)
    {
        eyeTurn = 360;
    }
    else if (beat >= 192 && beat < 224)
    {
        var start2:Float = 192 + Math.floor((beat - 192) / 8) * 8;
        var t2:Float = e2eClamp((beat - start2) / 8, 0, 1);
        eyeTurn = 360 * (1 - Math.cos(t2 * Math.PI * 0.5));
    }
    else if (beat >= 224)
    {
        eyeTurn = 360;
    }

    if (beat >= 88)
    {
        for (i in 0...8) e2eEyeAngle[i] = e2eEyeBaseAngle[i] + eyeTurn;
    }

    var reach:Float = 0;
    if (beat >= 94.25 && beat < 96)
    {
        var t3:Float = e2eClamp((beat - 94.25) / 1.75, 0, 1);
        reach = 100 * (1 - Math.cos(t3 * Math.PI * 0.5));
    }
    else if (beat >= 96 && beat < 100) reach = 100;
    else if (beat >= 100 && beat < 152)
    {
        if (beat < 148)
        {
            var seg:Int = Std.int(Math.floor((beat - 100) / 8));
            var segStart:Float = 100 + seg * 8;
            var segT:Float = e2eClamp((beat - segStart) / 8, 0, 1);
            var from:Float = seg % 2 == 0 ? 100 : -100;
            var to:Float = seg % 2 == 0 ? -100 : 100;
            reach = e2eLerp(from, to, segT);
        }
        else if (beat < 151) reach = e2eLerp(100, -100, (beat - 148) / 3);
        else reach = -100 + 200 * (1 - Math.cos(e2eClamp((beat - 151), 0, 1) * Math.PI * 0.5));
    }
    else if (beat >= 152 && beat < 196) reach = 100;
    else if (beat >= 196 && beat < 224)
    {
        if (beat < 220)
        {
            var seg2:Int = Std.int(Math.floor((beat - 196) / 8));
            var segStart2:Float = 196 + seg2 * 8;
            var segT2:Float = e2eClamp((beat - segStart2) / 8, 0, 1);
            var from2:Float = seg2 % 2 == 0 ? 100 : -100;
            var to2:Float = seg2 % 2 == 0 ? -100 : 100;
            reach = e2eLerp(from2, to2, segT2);
        }
        else reach = e2eLerp(-100, 100, (beat - 220) / 4);
    }
    else if (beat >= 224 && beat < 554) reach = 100;
    else if (beat >= 570) reach = e2eLerp(0, 100, (beat - 570) / 4);

    if (beat >= 88) for (i in 0...8) e2eEyeReach[i] = reach;

    if (beat >= 192 && beat < 224)
    {
        var become:Float = e2eTween(beat, 192, 1, 0, 1) * (1 - e2eTween(beat, 223, 1, 0, 1));
        for (i in 0...8) e2eEyeBecome[i] = become;
    }
    if (beat >= 285.5 && beat < 352)
    {
        for (i in 0...8) e2eEyeBecome[i] = 1;
    }
    if (beat >= 471.25 && beat < 554)
    {
        for (i in 0...8) e2eEyeBecome[i] = 1;
    }
}

function e2eEase(t:Float, name:String):Float
{
    t = e2eClamp(t, 0, 1);
    switch (name)
    {
        case 'insine': return 1 - Math.cos(t * Math.PI * 0.5);
        case 'outsine': return Math.sin(t * Math.PI * 0.5);
        case 'inoutsine': return -(Math.cos(Math.PI * t) - 1) * 0.5;
        case 'incubic': return t * t * t;
        case 'outcubic': return 1 - Math.pow(1 - t, 3);
        case 'inoutcubic': return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) * 0.5;
        case 'instant': return t <= 0 ? 0 : 1;
        case 'arc': return Math.sin(t * Math.PI * 0.5);
        default: return t;
    }
}

// Track entries: [startBeat, durationBeats, target, easing, explicitFromOrNull].
// These keyframes are adapted from Eye2EyeModchart.hx. Values are compressed for Legacy's 2D field.
function e2eTrackValue(beat:Float, track:Array<Dynamic>, fallback:Float):Float
{
    var current:Float = fallback;
    var activeStart:Float = -1;
    var activeDuration:Float = 0;
    var activeFrom:Float = fallback;
    var activeTarget:Float = fallback;
    var activeEase:String = 'linear';

    for (event in track)
    {
        var start:Float = event[0];
        if (start > beat)
        {
            if (activeDuration > 0)
            {
                if (beat < activeStart + activeDuration)
                    return e2eLerp(activeFrom, activeTarget, e2eEase((beat - activeStart) / activeDuration, activeEase));
                return activeTarget;
            }
            return current;
        }

        if (activeDuration > 0)
            current = e2eLerp(activeFrom, activeTarget, e2eEase((start - activeStart) / activeDuration, activeEase));

        var duration:Float = event[1];
        var target:Float = event[2];
        var ease:String = event[3];
        var explicitFrom:Dynamic = event[4];
        var from:Float = explicitFrom == null ? current : explicitFrom;

        activeStart = start;
        activeDuration = duration;
        activeFrom = from;
        activeTarget = target;
        activeEase = ease;

        if (duration <= 0)
        {
            current = target;
            activeFrom = target;
            activeTarget = target;
            activeDuration = 0;
        }
        else
        {
            current = from;
        }
    }

    if (activeDuration > 0 && beat < activeStart + activeDuration)
        return e2eLerp(activeFrom, activeTarget, e2eEase((beat - activeStart) / activeDuration, activeEase));
    return activeDuration > 0 ? activeTarget : current;
}

var e2eFieldX1:Array<Dynamic> = [
    [0, 0, -60.5, 'linear', null], [88, 8, 0, 'linear', null],
    [111.5, 0.5, -375, 'insine', null], [113, 0.5, 300, 'insine', null],
    [114.5, 0.5, -50, 'insine', null], [116, 0.5, -371, 'insine', null],
    [117.5, 0.5, -19.5, 'insine', null], [119.5, 0.5, -315.5, 'outsine', null],
    [121, 0.5, -25, 'insine', null], [125.5, 0.5, -25, 'insine', null],
    [171, 0, -563, 'linear', null], [172, 4, 48.5, 'insine', null],
    [176, 1, 76, 'outsine', null], [177, 3, 538.5, 'insine', null],
    [180, 4, -236, 'outsine', null], [188.5, 3.5, 15.5, 'outsine', null],
    [202, 0, -400, 'linear', null], [204, 20, 2.5, 'outsine', null],
    [289, 0.5, -314.5, 'insine', null], [290.5, 0.5, 337.5, 'insine', null],
    [292, 0.5, -314.5, 'insine', null], [297, 0.5, 25, 'insine', null],
    [301.5, 0.5, 325, 'insine', null], [304, 1, -382, 'outsine', null],
    [306.5, 0.5, 453, 'insine', null], [319.5, 0.5, 248.5, 'insine', null],
    [342, 2, -0.5, 'insine', null], [415, 1, -14, 'insine', null]
];
var e2eFieldX2:Array<Dynamic> = [
    [0, 0, 1199.5, 'linear', null], [148.25, 0, -550, 'linear', null], [246.75, 0, 240, 'linear', null],
    [247.75, 0, -375, 'linear', null], [250.75, 0, -325, 'linear', null],
    [289, 0.5, 402, 'insine', null], [290.5, 0.5, -313.5, 'insine', null],
    [292, 0.5, 402, 'insine', null], [301.5, 0.5, -375, 'insine', null],
    [304, 1, 361.5, 'outsine', null], [306.5, 0.5, -379, 'insine', null],
    [337, 2, -159, 'arc', null], [342, 2, -0.5, 'insine', null],
    [352, 0, 2274.5, 'linear', null], [470, 0, -235, 'linear', null]
];
var e2eFieldX3:Array<Dynamic> = [
    [0, 0, 1467, 'linear', null], [148.25, 0, -550, 'linear', null], [246.75, 0, 240, 'linear', null],
    [467.25, 0, -550, 'linear', null], [468.5, 0, -248.5, 'linear', null]
];
var e2eFieldY1:Array<Dynamic> = [
    [111.5, 0.5, 0, 'insine', null], [114.5, 0.5, -25, 'insine', null],
    [116, 0.5, 255.5, 'insine', null], [117.5, 0.5, 9.5, 'insine', null],
    [119.5, 0.5, 300, 'outsine', null], [121, 0.5, 0, 'insine', null],
    [124, 0.5, 225, 'outsine', null], [125.5, 0.5, 25, 'insine', null],
    [202, 0, 355, 'linear', null], [247.75, 0, 276.5, 'linear', null],
    [298.5, 0.5, 553.5, 'insine', null], [300, 0.5, 651.5, 'insine', null],
    [301.5, 0.5, 250, 'insine', null], [415, 1, 344, 'insine', null],
    [478, 2, 249, 'insine', null]
];
var e2eFieldY2:Array<Dynamic> = [
    [148.25, 0, 25, 'linear', null], [150, 0, 25, 'linear', null],
    [158, 0, -1070.5, 'linear', null], [246.75, 0, 201.5, 'linear', null],
    [251, 0, 276.5, 'linear', null], [319.5, 1, 397.5, 'insine', null],
    [325, 1, 302, 'insine', null], [342, 2, 329.5, 'insine', null],
    [478, 0, -1070.5, 'linear', null]
];
var e2eFieldY3:Array<Dynamic> = [
    [148.25, 0, 25, 'linear', null], [468.25, 0, 43, 'linear', null],
    [468.5, 0, -491, 'linear', null]
];
var e2eFieldZ1:Array<Dynamic> = [
    [88, 8, -945, 'inoutsine', null], [164, 4, 134.5, 'inoutsine', null],
    [202, 0, 401, 'linear', null], [204, 20, -753, 'outsine', null],
    [246.75, 0, 206.5, 'linear', null]
];
var e2eFieldZ2:Array<Dynamic> = [
    [88, 8, -945, 'inoutsine', null], [164, 4, 134.5, 'inoutsine', null],
    [246.75, 0, 206.5, 'linear', null]
];
var e2eFieldZ3:Array<Dynamic> = [
    [88, 8, -945, 'inoutsine', null], [164, 4, 134.5, 'inoutsine', null],
    [469.75, 0, 261, 'linear', null], [466.75, 0, -944.5, 'linear', null],
    [468.5, 0, 206.5, 'linear', null]
];

function e2eGetFieldCount():Int
{
    if (game == null) return 0;
    var fields:Dynamic = Reflect.field(game, 'playFields');
    var members:Dynamic = fields == null ? null : Reflect.field(fields, 'members');
    if (members != null) return members.length;
    var manager:Dynamic = Reflect.field(game, 'modManager');
    var lanes:Dynamic = manager == null ? null : Reflect.field(manager, 'lanes');
    return lanes == null ? 0 : Std.int(lanes);
}

var e2eModSourceCache:Dynamic = {};

function e2eIsAdditiveMod(name:String):Bool
{
    return name == 'fieldX' || name == 'fieldY' || name == 'fieldZ' || name == 'shiftX' || name == 'shiftY' || name == 'shiftZ' || name == 'skewX' || name == 'skewY' || name == 'rowY' || name == 'laneY' || name == 'rowCenterX' || name == 'rowCenterY' || name == 'transformX' || name == 'transformY' || name == 'transformZ' || name == 'rotateX' || name == 'rotateY' || name == 'rotateZ';
}

function e2eSetMod(name:String, value:Float, fieldID:Int)
{
    if (game == null || value != value || fieldID < 0 || fieldID > 3) return;
    var manager:Dynamic = Reflect.field(game, 'modManager');
    if (manager == null) return;
    var fields:Int = e2eGetFieldCount();
    if (fields <= 0) return;

    // Hex charts may address four visual fields; Legacy normally exposes two gameplay fields.
    // Map Hex 0/2 to Legacy field 0 and Hex 1/3 to Legacy field 1. For spatial offsets,
    // combine both source-field contributions; for non-additive mods, prefer the real field 0/1.
    var sourceKey:String = 'f' + fieldID + '_' + name;
    Reflect.setField(e2eModSourceCache, sourceKey, value);
    var targetField:Int = fields >= 4 ? fieldID : fieldID % 2;
    if (targetField >= fields) return;
    var baseValue:Dynamic = Reflect.field(e2eModSourceCache, 'f' + targetField + '_' + name);
    var extraValue:Dynamic = fields < 4 ? Reflect.field(e2eModSourceCache, 'f' + (targetField + 2) + '_' + name) : null;
    var merged:Float;
    if (fields < 4 && e2eIsAdditiveMod(name))
        merged = (baseValue == null ? 0 : baseValue) + (extraValue == null ? 0 : extraValue);
    else if (baseValue != null)
        merged = baseValue;
    else
        merged = extraValue == null ? value : extraValue;

    var setter:Dynamic = Reflect.field(manager, 'setValue');
    if (setter == null || !Reflect.isFunction(setter)) return;
    var cacheKey:String = 'f' + targetField + '_' + name;
    var previous:Dynamic = Reflect.field(e2eModCache, cacheKey);
    if (previous != null && Math.abs(previous - merged) < 0.001) return;
    try
    {
        Reflect.callMethod(manager, setter, [name, merged, targetField]);
        Reflect.setField(e2eModCache, cacheKey, merged);
    }
    catch (e:Dynamic)
    {
    }
}

function e2eSourceRate(beat:Float, fieldID:Int):Float
{
    var value:Float = 1;
    if (fieldID == 1 || fieldID == 2)
    {
        if (beat < 58.25) value = 1;
        else if (beat < 93) value = 2;
        else if (beat < 96) value = e2eLerp(2, 0.6, (beat - 93) / 3);
        else if (beat < 127) value = 0.6;
        else if (beat < 128) value = e2eLerp(0.6, 1, beat - 127);
        else value = 1;
    }

    if (fieldID == 1)
    {
        if (beat >= 131 && beat < 134) value = e2eLerp(1, 2.07, (beat - 131) / 3);
        else if (beat >= 134 && beat < 136) value = e2eLerp(2.07, 1, (beat - 134) / 2);
        else if (beat >= 136 && beat < 136.5145) value = e2eLerp(1, 1.5, (beat - 136) / 0.5145);
        else if (beat >= 136.5145 && beat < 139) value = 1.5;
        else if (beat >= 139 && beat < 142) value = e2eLerp(1.5, 1.6, (beat - 139) / 3);
        else if (beat >= 142 && beat < 154) value = 1.6;
        else if (beat >= 154 && beat < 171) value = 1.75;
        else if (beat >= 171 && beat < 201.5) value = 1;
        else if (beat >= 201.5 && beat < 201.75) value = e2eLerp(1, 1.2, (beat - 201.5) / 0.25);
        else if (beat >= 201.75 && beat < 251) value = 1.5;
        else if (beat >= 251 && beat < 287) value = 1.35;
        else if (beat >= 287 && beat < 288) value = e2eLerp(1.35, 0.863636, beat - 287);
        else if (beat >= 288 && beat < 323) value = 0.863636;
        else if (beat >= 323 && beat < 326) value = e2eLerp(0.863636, 2.07, (beat - 323) / 3);
        else if (beat >= 326 && beat < 327.75) value = 2.07;
        else if (beat >= 327.75 && beat < 328.2645) value = e2eLerp(2.07, 1.5, (beat - 327.75) / 0.5145);
        else if (beat >= 328.2645 && beat < 331) value = 1.5;
        else if (beat >= 331 && beat < 334) value = e2eLerp(1.5, 2.07, (beat - 331) / 3);
        else if (beat >= 334 && beat < 342) value = 2.07;
        else if (beat >= 342 && beat < 343) value = e2eLerp(2.07, 1.5, beat - 342);
        else if (beat >= 343 && beat < 376) value = 1.5;
        else if (beat >= 376 && beat < 380) value = e2eLerp(1.5, 0.738747, (beat - 376) / 4);
        else if (beat >= 380 && beat < 400) value = 0.738747;
        else if (beat >= 400 && beat < 402) value = e2eLerp(0.738747, 1.233747, (beat - 400) / 2);
        else if (beat >= 402 && beat < 474) value = 1.233747;
        else if (beat >= 474 && beat < 503) value = 1.25;
        else if (beat >= 503 && beat < 510.25) value = e2eLerp(1.25, 2.5, (beat - 503) / 7.25);
        else if (beat >= 510.25 && beat < 511) value = 2.5;
        else if (beat >= 511 && beat < 512) value = e2eLerp(2.5, 1.5, beat - 511);
        else if (beat >= 512 && beat < 518) value = 1.5;
        else if (beat >= 518 && beat < 520) value = e2eLerp(1.5, 2, (beat - 518) / 2);
        else if (beat >= 520 && beat < 521) value = e2eLerp(2, 1.5, beat - 520);
        else if (beat >= 521 && beat < 526) value = 1.5;
        else if (beat >= 526 && beat < 528) value = e2eLerp(1.5, 2, (beat - 526) / 2);
        else if (beat >= 528) value = 1.5;
    }
    else if (fieldID == 2)
    {
        if (beat >= 246.75 && beat < 251) value = 2.317073;
        else if (beat >= 251 && beat < 284) value = 1.35;
        else if (beat >= 284) value = 0.863636;
        if (beat >= 323 && beat < 326) value = e2eLerp(0.863636, 2.07, (beat - 323) / 3);
        else if (beat >= 326 && beat < 327.75) value = 2.07;
        else if (beat >= 327.75 && beat < 328.2645) value = e2eLerp(2.07, 1.5, (beat - 327.75) / 0.5145);
        else if (beat >= 328.2645 && beat < 331) value = 1.5;
        else if (beat >= 331 && beat < 334) value = e2eLerp(1.5, 2.07, (beat - 331) / 3);
        else if (beat >= 334 && beat < 342) value = 2.07;
        else if (beat >= 342) value = 1.5;
    }
    else if (fieldID == 3)
    {
        if (beat >= 342) value = 1.5;
        if (beat >= 468.5) value = 1.328747;
    }

    return e2eClamp(value, 0, 2.5);
}

function e2eSourceDrunk(beat:Float, fieldID:Int):Float
{
    if (fieldID != 1 && fieldID != 2) return 0;
    if (beat < 141.5) return 0;
    if (beat < 142.5) return e2eLerp(0, -1, (beat - 141.5) / 0.5);
    if (beat < 143) return e2eLerp(-1, 1, (beat - 142.5) / 0.5);
    if (beat < 143.5) return 1;
    if (beat < 144) return e2eLerp(1, 0, (beat - 143.5) / 0.5);
    if (fieldID == 1 && beat >= 172 && beat < 201.5) return 0.615;
    if ((fieldID == 2 && beat >= 250.75 && beat < 279) || (fieldID == 1 && beat >= 250.75 && beat < 283)) return 0.25;
    if (beat >= 343.5 && beat < 348.5)
    {
        var eventIndex:Int = Std.int(Math.floor((beat - 343.5) / 1.5));
        var phase:Float = (beat - 343.5) % 1.5;
        var high:Float = eventIndex % 2 == 0 ? 3.5 : -3.5;
        if (phase < 0.5) return e2eLerp(0, high, phase / 0.5);
        if (phase < 1) return e2eLerp(high, 0, (phase - 0.5) / 0.5);
        return 0;
    }
    if (fieldID == 1 && beat >= 351.25 && beat < 360) return 1;
    if (fieldID == 1 && beat >= 360 && beat < 361) return e2eLerp(1, 0, beat - 360);
    if (fieldID == 1 && beat >= 361 && beat < 376) return -1;
    if (fieldID == 1 && beat >= 376 && beat < 377) return e2eLerp(-1, 0, beat - 376);
    if (fieldID == 1 && beat >= 479.5 && beat < 510.5)
    {
        var half:Float = Math.floor((beat - 479.5) / 2) % 2;
        var t:Float = (beat - 479.5) % 2;
        var peak:Float = half == 0 ? 1.5 : -1.5;
        if (t < 0.5) return e2eLerp(0, peak, t / 0.5);
        return e2eLerp(peak, 0, e2eClamp((t - 0.5) / 1.5, 0, 1));
    }
    if (fieldID == 1 && beat >= 534 && beat < 536) return e2eLerp(0, 1, (beat - 534) / 2);
    return 0;
}

function e2eSourceTipsy(beat:Float, fieldID:Int):Float
{
    if (fieldID != 1) return 0;
    var bases:Array<Float> = [481, 483, 485, 487, 489, 491, 493, 495, 496.5, 499, 501, 502];
    for (i in 0...bases.length)
    {
        var start:Float = bases[i];
        var from:Float = i % 2 == 0 ? 1 : -1;
        if (beat >= start && beat < start + 0.5) return e2eLerp(from, 0, (beat - start) / 0.5);
    }
    if (beat >= 503 && beat < 504) return e2eLerp(-1, 0, beat - 503);
    return 0;
}

function e2eSourceMirror(beat:Float, fieldID:Int):Float
{
    if ((fieldID == 0 || fieldID == 1 || fieldID == 2) && ((beat >= 103.5 && beat < 105.5) || (beat >= 113 && beat < 115) || (beat >= 119.5 && beat < 121.5)))
    {
        var start:Float = beat < 106 ? 103.5 : (beat < 118 ? 113 : 119.5);
        var t:Float = beat - start;
        return t < 0.5 ? e2eLerp(0, 1, t / 0.5) : e2eLerp(1, 0, (t - 0.5) / 1.0);
    }
    if (fieldID == 1 && beat >= 134 && beat < 142) return beat < 135.5 ? e2eLerp(0, 1, (beat - 134) / 1.5) : e2eLerp(1, 0, (beat - 135.5) / 6.5);
    if (fieldID == 1 && beat >= 175 && beat < 182)
    {
        if (beat < 177) return e2eLerp(0, 1, (beat - 175));
        if (beat < 178) return e2eLerp(1.25, 0, beat - 177);
        return e2eLerp(-0.25, 0, (beat - 178) / 4);
    }
    if ((fieldID == 1 || fieldID == 2) && beat >= 324 && beat < 332) return beat < 326 ? e2eLerp(0, 1, (beat - 324) / 2) : e2eLerp(1, 0, (beat - 326) / 6);
    if ((fieldID == 1 || fieldID == 2) && beat >= 343 && beat < 348.5)
    {
        var phase:Float = (beat - 343) % 1.5;
        return phase < 0.5 ? -0.5 : e2eLerp(-0.5, -0.4, (phase - 0.5) / 1);
    }
    if (fieldID == 1 && beat >= 416 && beat < 447) return -0.2 * (1 - e2eClamp((beat - 416) / 31, 0, 1));
    if (fieldID == 1 && beat >= 496 && beat < 503)
    {
        var phase2:Float = (beat - 496) % 3.5;
        return phase2 < 0.5 ? e2eLerp(0, 1, phase2 / 0.5) : e2eLerp(1, 0, (phase2 - 0.5) / 3);
    }
    if (fieldID == 1 && beat >= 533 && beat < 544) return e2eLerp(0, 1.5, (beat - 533) / 11);
    return 0;
}

function e2eSourceHideNotes(beat:Float, fieldID:Int):Float
{
    var amount:Float = 0;
    if (fieldID == 1 && beat >= 152.5 && beat < 157) amount = (beat - 152.5) / 4.5;
    if ((fieldID == 2 || fieldID == 3) && beat >= 147 && beat < 160) amount = e2eClamp((beat - 147) / 13, 0, 1);
    if (fieldID == 1 && beat >= 280 && beat < 283.75) amount = 1;
    if (fieldID == 2 && beat >= 284 && beat < 287.75) amount = 1;
    if (fieldID == 2 && beat >= 345.5 && beat < 346.5) amount = e2eClamp(beat - 345.5, 0, 1);
    if (fieldID == 1 && beat >= 347 && beat < 348) amount = e2eClamp(beat - 347, 0, 1);
    if (fieldID == 2 && beat >= 348.5 && beat < 349.5) amount = e2eClamp(beat - 348.5, 0, 1);
    if (fieldID == 1 && beat >= 350 && beat < 351.75) amount = e2eClamp((beat - 350) / 0.75, 0, 1);
    if (fieldID == 2 && beat >= 354 && beat < 356) amount = 1;
    if ((fieldID == 1) && beat >= 472.5 && beat < 477.75) amount = e2eClamp((beat - 472.5) / 5.25, 0, 1);
    if ((fieldID == 2 || fieldID == 3) && beat >= 467 && beat < 480) amount = e2eClamp((beat - 467) / 13, 0, 1);
    return e2eClamp(amount, 0, 1);
}

function e2eSourceHideHits(beat:Float, fieldID:Int):Float
{
    if (fieldID == 1 && beat >= 151.5 && beat < 157) return 1;
    if (fieldID == 3 && beat >= 146.25 && beat < 152) return 1;
    if (fieldID == 1 && beat >= 280 && beat < 284) return 1;
    if (fieldID == 2 && beat >= 284 && beat < 287.5) return 1;
    if (fieldID == 1 && beat >= 472.5 && beat < 477.75) return 1;
    if (fieldID == 3 && beat >= 466.25 && beat < 472) return 1;
    if ((fieldID == 0 || fieldID == 2 || fieldID == 3) && beat >= 510.5) return 1;
    return 0;
}

function e2eCameraRotX(beat:Float):Float
{
    if (beat >= 228 && beat < 244) return e2eLerp(0, 8, (beat - 228) / 16);
    if (beat >= 244 && beat < 256) return e2eLerp(8, -8, (beat - 244) / 12);
    if (beat >= 256 && beat < 272) return e2eLerp(-8, 8, (beat - 256) / 16);
    if (beat >= 272 && beat < 288) return e2eLerp(8, -3, (beat - 272) / 16);
    if (beat >= 301.5 && beat < 302) return e2eLerp(0, -10, (beat - 301.5) / 0.5);
    if (beat >= 302 && beat < 302.5) return e2eLerp(-10, 0, (beat - 302) / 0.5);
    if (beat >= 302.5 && beat < 303) return e2eLerp(0, 10, (beat - 302.5) / 0.5);
    if (beat >= 303 && beat < 303.5) return e2eLerp(10, 0, (beat - 303) / 0.5);
    if (beat >= 512 && beat < 534)
    {
        var point:Float = Math.floor((beat - 512) / 2);
        var vals:Array<Float> = [8, -8, 8, 24, 8, -8, 8, 24, 8, -8, 8];
        var from:Float = point <= 0 ? 0 : vals[Std.int(Math.min(vals.length - 1, point - 1))];
        var to:Float = vals[Std.int(Math.min(vals.length - 1, point))];
        return e2eLerp(from, to, (beat - (512 + point * 2)) / 2);
    }
    return 0;
}

function e2eCameraRotY(beat:Float):Float
{
    if (beat >= 352 && beat < 384) return (Math.floor((beat - 352) / 8) % 2 == 0) ? e2eLerp(-6.5, 6.5, ((beat - 352) % 8) / 8) : e2eLerp(6.5, -6.5, ((beat - 352) % 8) / 8);
    if (beat >= 384 && beat < 400) return Math.sin((beat - 384) * Math.PI / 2) * 16;
    if (beat >= 400 && beat < 414) return Math.sin((beat - 400) * Math.PI / 4) * 16;
    if (beat >= 416 && beat < 447) return Math.sin((beat - 416) * Math.PI) * 12;
    if (beat >= 451 && beat < 470) return Math.sin((beat - 451) * Math.PI / 2) * 8;
    if (beat >= 288 && beat < 320) return Math.sin((beat - 288) * Math.PI / 2) * 10;
    return 0;
}

function e2eApplyModchart(beat:Float)
{
    var fieldCount:Int = e2eGetFieldCount();
    if (fieldCount <= 0) return;

    for (fieldID in 0...fieldCount)
    {
        var x:Float = 0;
        var y:Float = 0;
        var z:Float = 0;
        if (fieldID == 1)
        {
            x = e2eTrackValue(beat, e2eFieldX1, 0) * 0.55;
            y = e2eTrackValue(beat, e2eFieldY1, 0) * 0.45;
            z = e2eTrackValue(beat, e2eFieldZ1, 0) * 0.16;
        }
        else if (fieldID == 2)
        {
            x = e2eTrackValue(beat, e2eFieldX2, 0) * 0.35;
            y = e2eTrackValue(beat, e2eFieldY2, 0) * 0.35;
            z = e2eTrackValue(beat, e2eFieldZ2, 0) * 0.16;
        }
        else if (fieldID == 3)
        {
            x = e2eTrackValue(beat, e2eFieldX3, 0) * 0.35;
            y = e2eTrackValue(beat, e2eFieldY3, 0) * 0.35;
            z = e2eTrackValue(beat, e2eFieldZ3, 0) * 0.16;
        }
        x = e2eClamp(x, -FlxG.width * 0.65, FlxG.width * 0.65);
        y = e2eClamp(y, -FlxG.height * 0.65, FlxG.height * 0.65);
        z = e2eClamp(z, -220, 220);

        var hide:Float = beat < 32 ? 1 : e2eSourceHideNotes(beat, fieldID);
        var hideHits:Float = e2eSourceHideHits(beat, fieldID);
        var mirror:Float = e2eSourceMirror(beat, fieldID);
        var drunk:Float = e2eSourceDrunk(beat, fieldID);
        var tipsy:Float = e2eSourceTipsy(beat, fieldID);
        var rate:Float = e2eSourceRate(beat, fieldID);
        var rotX:Float = e2eCameraRotX(beat) * 0.5;
        var rotY:Float = e2eCameraRotY(beat) * 0.5;

        e2eSetMod('transformX', x, fieldID);
        e2eSetMod('transformY', y, fieldID);
        e2eSetMod('transformZ', z, fieldID);
        e2eSetMod('rotateX', rotX, fieldID);
        e2eSetMod('rotateY', rotY, fieldID);
        e2eSetMod('flip', e2eClamp(mirror, -1.5, 1.5), fieldID);
        e2eSetMod('drunk', e2eClamp(drunk, -3.5, 3.5), fieldID);
        e2eSetMod('tipsy', e2eClamp(tipsy, -1.2, 1.2), fieldID);
        e2eSetMod('xmod', rate, fieldID);
        e2eSetMod('stealth', hide, fieldID);
        e2eSetMod('noteAlpha', hide, fieldID);
        e2eSetMod('noteSplashAlpha', hideHits, fieldID);
        e2eSetMod('sustainSplashAlpha', hideHits, fieldID);
        e2eSetMod('alpha', beat < 32 ? 1 : 0, fieldID);

        // The original has separate per-key shifts around beats 57.5–60.
        for (key in 0...4)
        {
            var laneX:Float = 0;
            if (fieldID == 1)
            {
                var start:Float = 57.5 + key * 0.25;
                var target:Float = [-475, -425, -100, -50][key];
                if (beat >= start && beat < 88) laneX = target;
                else if (beat >= 88 && beat < 96) laneX = e2eLerp(target, 0, (beat - 88) / 8);
            }
            e2eSetMod('transform' + key + 'X', laneX * 0.55, fieldID);
            e2eSetMod('transform' + key + 'Y', 0, fieldID);
        }
    }
}

function e2eGlitchAt(beat:Float):Float
{
    if (beat < 28) return 0;
    if (beat < 32) return 0.5;
    if (beat < 38) return e2eTween(beat, 32, 6, 0.6, 0);
    if (beat >= 58.5 && beat < 60) return e2eTween(beat, 58.5, 1.5, 0.3, 0);
    if (beat >= 88 && beat < 128) return 0.5 * (1 - (beat - 88) % 1.5 / 1.5);
    if (beat >= 128 && beat < 156) return 0.2 * (1 - (beat - 128) % 3 / 3);
    if (beat >= 156 && beat < 172) return e2eTween(beat, 156, 16, 0.2, 0.05);
    if (beat >= 191 && beat < 224) return 0.2;
    if (beat >= 224 && beat < 228) return e2eTween(beat, 224, 4, 0.5, 0);
    if (beat >= 251 && beat < 252) return e2eTween(beat, 251, 1, 0.3, 0);
    if (beat >= 288 && beat < 320) return 0.25 * (1 - (beat - 288) % 1.5 / 1.5);
    if (beat >= 320 && beat < 352) return 0.2 * (1 - (beat - 320) % 3 / 3);
    if (beat >= 352 && beat < 415) return 0.05;
    if (beat >= 415 && beat < 416) return 0.4;
    if (beat >= 416 && beat < 472) return 0.1 * (1 - (beat - 416) % 3 / 3);
    if (beat >= 472 && beat < 478) return e2eTween(beat, 472, 6, 0.4, 0);
    if (beat >= 480 && beat < 512) return 0.1 * (1 - (beat - 480) % 1.5 / 1.5);
    if (beat >= 512 && beat < 544) return 0.15 * (1 - (beat - 512) % 2 / 2);
    if (beat >= 544 && beat < 576) return e2eTween(beat, 544, 32, 0.15, 0.8);
    return 0;
}

function e2eRadiusAt(beat:Float):Float
{
    if (beat >= 89 && beat < 91.25) return e2eTween(beat, 89, 2.25, 1400, 1040);
    if (beat >= 91.25 && beat < 191) return 1040;
    if (beat >= 191 && beat < 192.75) return e2eTween(beat, 191, 1.75, 1040, 2862);
    if (beat >= 192.75 && beat < 224) return 2862;
    if (beat >= 224 && beat < 225.75) return e2eTween(beat, 224, 1.75, 2862, 1400);
    if (beat >= 288 && beat < 304) return e2eTween(beat, 288, 16, 1400, 2000);
    if (beat >= 304 && beat < 480) return 2000;
    if (beat >= 480 && beat < 506) return e2eTween(beat, 480, 26, 2000, 524);
    if (beat >= 506) return e2eTween(beat, 506, 6, 524, 3581.5);
    return 1400;
}

function e2eCameraAngle(beat:Float):Float
{
    if (beat >= 127 && beat < 128) return e2eTween(beat, 127, 1, 0, -33.5);
    if (beat >= 128 && beat < 136) return e2eTween(beat, 128, 8, -33.5, 150);
    if (beat >= 136 && beat < 142) return e2eTween(beat, 136, 6, 150, 340);
    if (beat >= 142 && beat < 147) return e2eTween(beat, 142, 5, 340, 720);
    if (beat >= 147 && beat < 192) return 720;
    if (beat >= 192 && beat < 208) return e2eTween(beat, 192, 16, 0, 33.5);
    if (beat >= 208 && beat < 224) return e2eTween(beat, 208, 16, 33.5, -8);
    if (beat >= 228 && beat < 244) return e2eTween(beat, 228, 16, 8, -8);
    if (beat >= 288 && beat < 320) return 720 + Math.sin((beat - 288) * Math.PI) * 4;
    if (beat >= 320 && beat < 340) return e2eTween(beat, 320, 20, 0, 360);
    if (beat >= 340 && beat < 352) return e2eTween(beat, 340, 12, 360, 387.5);
    if (beat >= 384 && beat < 400) return 360 + Math.sin((beat - 384) * Math.PI) * 2.5;
    if (beat >= 416 && beat < 445) return Math.sin((beat - 416) * Math.PI) * 10;
    if (beat >= 544 && beat < 574) return e2eTween(beat, 544, 30, 0, 389);
    if (beat >= 574 && beat < 576) return e2eTween(beat, 574, 2, 389, 360);
    if (beat >= 576) return e2eTween(beat, 576, 20, 360, 315);
    return 0;
}

function e2eUpdateStageChannels(beat:Float)
{
    var gray:Float = 0;
    var invert:Float = 0;
    if (beat >= 415 && beat < 472.5)
    {
        gray = 1;
        invert = 0.25;
    }
    else if (beat >= 472.5 && beat < 477.75)
    {
        gray = e2eTween(beat, 472.5, 5.25, 1, 0);
        invert = e2eTween(beat, 472.5, 5.25, 0.25, 0);
    }
    if ((beat >= 516 && beat < 519.5) || (beat >= 524 && beat < 527.5))
    {
        var start:Float = beat < 520 ? 516 : 524;
        var end:Float = start + 3.5;
        invert = beat < start + 1.5 ? e2eTween(beat, start, 1.5, 0, 1) : e2eTween(beat, start + 1.5, 2, 1, 0);
        gray = e2eTween(beat, start, end - start, 0, 0.6);
    }
    game.variables.set('eye2eye.radius', e2eRadiusAt(beat));
    game.variables.set('eye2eye.gray', gray);
    game.variables.set('eye2eye.invert', invert);
}

function e2eSetHudAlpha(value:Float)
{
    if (game.playHUD == null) return;
    var names:Array<String> = ['healthBar', 'healthBarBG', 'healthBarOverlay', 'iconP1', 'iconP2'];
    for (name in names)
    {
        var obj:Dynamic = Reflect.field(game.playHUD, name);
        if (obj != null && Reflect.hasField(obj, 'alpha'))
        {
            if (!e2eHudCaptured) e2eHudSaved.push([obj, Reflect.field(obj, 'alpha')]);
            Reflect.setField(obj, 'alpha', value);
        }
    }
    if (value == 0) e2eHudCaptured = true;
}

function e2eRestoreHud()
{
    for (data in e2eHudSaved)
    {
        if (data[0] != null) Reflect.setField(data[0], 'alpha', data[1]);
    }
    e2eHudSaved = [];
    e2eHudCaptured = false;
}

function e2eSkipWasPressed():Bool
{
    if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.BACKSPACE) return true;
    var input:Dynamic = null;
    try { input = Reflect.field(game, 'input'); } catch (e:Dynamic) {}
    if (input != null)
    {
        var check:Dynamic = null;
        try { check = Reflect.field(input, 'inputJustPressed'); } catch (e:Dynamic) {}
        if (check != null && Reflect.isFunction(check))
        {
            try { if (Reflect.callMethod(input, check, [3]) == true) return true; }
            catch (e:Dynamic) {}
        }
    }
    return false;
}

function e2ePerformQueuedSkip():Bool
{
    if (FlxG.sound.music == null || !FlxG.sound.music.playing || Conductor.songPosition < 0) return false;
    e2eSkipQueued = false;
    setSongTime(9000);
    clearNotesBefore(9000);
    return true;
}

function e2eSkipIntro()
{
    if (e2eSkipped) return;
    e2eSkipped = true;
    if (e2eSkipText != null) e2eSkipText.visible = false;
    if (!e2ePerformQueuedSkip()) e2eSkipQueued = true;
}

function onCreatePost()
{
    if (e2eInitialised) return;
    e2eBaseZoom = game.defaultCamZoom;
    if (e2eBaseZoom <= 0) e2eBaseZoom = 0.9;
    e2eRealHealth = 2;
    game.health = e2eRealHealth;
    if (!e2eHealthLossCaptured)
    {
        e2eBaseHealthLoss = game.healthLoss;
        e2eHealthLossCaptured = true;
    }
    game.healthLoss = 0;
    e2eLastBeat = -1;
    e2eLastSongPos = 0;
    e2eSkipped = false;
    e2eSkipQueued = false;
    e2eAdditionalGlitch = 0;

    e2eText1 = e2eGetVar('eye2eye.text1', null);
    e2eText2 = e2eGetVar('eye2eye.text2', null);
    e2eText3 = e2eGetVar('eye2eye.text3', null);
    e2eText4 = e2eGetVar('eye2eye.text4', null);
    e2eText5 = e2eGetVar('eye2eye.text5', null);

    if (dad != null) dad.visible = false;
    e2eSetHudAlpha(0);

    e2eSkipText = new FlxText(0, FlxG.height - 30, FlxG.width, FlxG.onMobile ? 'Press RIGHT to skip intro' : 'Press BACKSPACE to skip intro');
    e2eSkipText.setFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0xFF000000);
    e2eSkipText.scrollFactor.set(0, 0);
    e2eSkipText.zIndex = 1000;
    e2eSkipText.cameras = [game.camGame];
    game.add(e2eSkipText);

    e2eOldGameFilters = game.camGame.filters == null ? [] : game.camGame.filters.copy();
    e2eGlitchShader = null;
    if (e2eAssetExists('shaders/eye2eye/eye2eye_glitch.frag'))
        e2eGlitchShader = newShader('eye2eye/eye2eye_glitch');
    if (e2eGlitchShader != null)
    {
        e2eGlitchShader.setFloat('uBeat', 0);
        e2eGlitchShader.setFloat('uGlitch', 0);
        e2eGlitchShader.setFloat('uTaps', 8);
        var filters = e2eOldGameFilters.copy();
        filters.push(new ShaderFilter(e2eGlitchShader));
        game.camGame.filters = filters;
    }

    e2eModCache = {};
    e2eModSourceCache = {};
    e2eCreateEyes();
    e2eShowEyes(false);
    e2eInitialised = true;
}

function onSongStart()
{
    game.camGame.zoom = e2eBaseZoom;
}

function onUpdate(elapsed:Float)
{
    if (!e2eInitialised || game == null) return;

    var beat:Float = Conductor.songPosition * Conductor.bpm / 60000;
    if (Conductor.songPosition < 250 && e2eLastSongPos > 1000)
    {
        e2eRealHealth = 2;
        game.health = 2;
        e2eLastBeat = -1;
        e2eSkipped = false;
        e2eSkipQueued = false;
        e2eAdditionalGlitch = 0;
        e2eModCache = {};
    e2eModSourceCache = {};
        game.camGame.angle = 0;
        game.camGame.zoom = e2eBaseZoom;
        if (game.camHUD != null) { game.camHUD.angle = 0; game.camHUD.zoom = 1; }
        if (e2eGlitchShader != null) { e2eGlitchShader.setFloat('uBeat', 0); e2eGlitchShader.setFloat('uGlitch', 0); }
        if (e2eStripShader != null) e2eStripShader.setFloat('uScroll', 0);
        if (dad != null) dad.visible = false;
        e2eShowEyes(false);
    }
    e2eLastSongPos = Conductor.songPosition;

    var skipPressed:Bool = e2eSkipWasPressed();
    if (!e2eSkipped && beat < 32 && skipPressed) e2eSkipIntro();
    if (e2eSkipQueued) e2ePerformQueuedSkip();

    var pastIntro:Bool = beat >= 32;
    if (pastIntro && e2eLastBeat >= 0 && e2eLastBeat < 32) FlxG.camera.flash(0xFFFF0000, 0.75);
    e2eLastBeat = beat;

    if (dad != null) dad.visible = pastIntro;
    e2eShowEyes(pastIntro);

    if (beat >= 0 && beat < 14)
    {
        if (e2eText1 != null) { e2eText1.visible = true; e2eText1.alpha = e2eClamp(beat / 14, 0, 1); }
    }
    else if (beat >= 14 && beat < 18)
    {
        if (e2eText1 != null) { e2eText1.visible = true; e2eText1.alpha = e2eClamp(1 - (beat - 14) / 3, 0, 1); }
    }
    else if (e2eText1 != null) e2eText1.visible = false;

    if (beat >= 18 && beat < 28)
    {
        if (e2eText2 != null) { e2eText2.visible = true; e2eText2.alpha = e2eClamp((beat - 18) / 10, 0, 1); }
    }
    else if (e2eText2 != null) e2eText2.visible = false;

    if (e2eText3 != null) e2eText3.visible = beat >= 28 && beat < 29;
    if (e2eText4 != null) e2eText4.visible = beat >= 29 && beat < 30;
    if (e2eText5 != null) e2eText5.visible = beat >= 30 && beat < 32;
    if (e2eSkipText != null) e2eSkipText.visible = !e2eSkipped && beat < 28;

    e2eUpdateStageChannels(beat);
    e2eApplyModchart(beat);

    var baseGlitch:Float = e2eGlitchAt(beat);
    var healthGlitch:Float = (1 - game.health / 2) * 0.1;
    var glitchAmount:Float = e2eClamp(baseGlitch + healthGlitch + e2eAdditionalGlitch, 0, 1);
    if (e2eGlitchShader != null)
    {
        e2eGlitchShader.setFloat('uBeat', beat);
        e2eGlitchShader.setFloat('uGlitch', glitchAmount);
        e2eGlitchShader.setFloat('uTaps', FlxG.onMobile ? 8 : 20);
    }
    if (e2eAdditionalGlitch > 0) e2eAdditionalGlitch = Math.max(0, e2eAdditionalGlitch - elapsed * 10);

    var camAngle:Float = e2eCameraAngle(beat);
    game.camGame.angle = camAngle;
    game.camGame.zoom = e2eBaseZoom * (1 + 0.04 * Math.sin(beat * Math.PI / 2));
    if (beat >= 88 && beat < 96) game.camGame.zoom = e2eBaseZoom * (1 + 0.1 * Math.sin((beat - 88) / 8 * Math.PI * 2));
    if (beat >= 224 && beat < 252) game.camGame.zoom = e2eBaseZoom * (1 + 0.07 * Math.sin((beat - 224) * Math.PI / 2));
    if (beat >= 288 && beat < 352) game.camGame.zoom = e2eBaseZoom * (1 + 0.05 * Math.sin((beat - 288) * Math.PI / 2));
    if (beat >= 544) game.camGame.zoom = e2eBaseZoom * e2eLerp(1, 1.2, (beat - 544) / 32);

    if (game.camHUD != null)
    {
        game.camHUD.angle = beat >= 288 && beat < 320 ? Math.sin((beat - 288) * Math.PI) * 1.2 : 0;
        game.camHUD.zoom = 1;
    }
}

function onUpdatePost(elapsed:Float)
{
    if (!e2eInitialised) return;
    var beat:Float = Conductor.songPosition * Conductor.bpm / 60000;
    e2ePlaceEyes(beat);
    game.health = e2eRealHealth;
    if (e2eStripShader != null)
    {
        var slid:Float = 38 * Conductor.songPosition / 1000;
        slid -= Math.floor(slid / 1440) * 1440;
        e2eStripShader.setFloat('uScroll', slid);
        var zoom:Float = game.camGame.zoom;
        if (zoom <= 0) zoom = e2eBaseZoom;
        e2eStripShader.setFloat('uTileW', FlxG.width / zoom);
        e2eStripShader.setFloat('uTileH', FlxG.height / zoom);
    }
    if (game.playHUD != null)
    {
        e2eSetHudAlpha(0);
    }
}

function noteMiss(note, fieldID:Int = -1)
{
    var noteType:Dynamic = Reflect.field(note, 'noteType');
    var noteKind:Dynamic = Reflect.field(note, 'kind');
    var mine:Bool = (noteType != null && Std.string(noteType).toLowerCase() == 'mine') || (noteKind != null && Std.string(noteKind).toLowerCase() == 'mine');
    if (mine) return Function_Stop;
    e2eRealHealth = Math.max(0, e2eRealHealth - 0.035);
    game.health = e2eRealHealth;
}

function onDestroy()
{
    // Legacy calls script onDestroy before destroying the PlayState's children.
    // Restore global camera/HUD settings, but never manually remove or destroy state-owned sprites.
    if (game != null)
    {
        if (e2eHealthLossCaptured) game.healthLoss = e2eBaseHealthLoss;
        e2eRestoreHud();
        if (game.camGame != null)
        {
            game.camGame.angle = 0;
            game.camGame.zoom = e2eBaseZoom;
            if (e2eOldGameFilters != null) game.camGame.filters = e2eOldGameFilters;
        }
        if (game.camHUD != null)
        {
            game.camHUD.angle = 0;
            game.camHUD.zoom = 1;
        }
    }
    e2eInitialised = false;
    e2eLids = [];
    e2eIrises = [];
    e2eBodies = [];
    e2eStrips = null;
    e2eSkipText = null;
    e2eHudSaved = [];
    e2eModCache = {};
    e2eModSourceCache = {};
    e2eOldGameFilters = null;
    e2eStripShader = null;
    e2eGlitchShader = null;
}
