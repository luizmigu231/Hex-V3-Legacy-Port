import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import funkin.Conductor;
import funkin.states.PlayState;

var hexHudTop:Dynamic = null;
var hexHudBottom:Dynamic = null;
var hexHudLeftCircle:Dynamic = null;
var hexHudRightCircle:Dynamic = null;
var hexHudTimer:Dynamic = null;
var hexHudBarsCamera:Dynamic = null;
var hexHudBuilt:Bool = false;
var hexHudEnabled:Bool = false;
var hexHudVisible:Bool = true;
var hexHudTimerReady:Bool = false;
var hexHudTimerFade:Float = 0;
var hexHudLastWidth:Float = -1;
var hexHudLastHeight:Float = -1;
var hexHudHealthBar:Dynamic = null;
var hexHudHealthY:Dynamic = null;
var hexHudIconP1:Dynamic = null;
var hexHudIconP2:Dynamic = null;
var hexHudIconP1ScaleX:Dynamic = null;
var hexHudIconP1ScaleY:Dynamic = null;
var hexHudIconP2ScaleX:Dynamic = null;
var hexHudIconP2ScaleY:Dynamic = null;

function hexHudGet(obj:Dynamic, field:String):Dynamic
{
    if (obj == null) return null;
    try { return Reflect.field(obj, field); } catch (e:Dynamic) { return null; }
}

function hexHudMakeBar(y:Float):Dynamic
{
    var bar:FlxSprite = new FlxSprite(-4, y);
    bar.makeGraphic(1, 1, 0xFFFFFFFF);
    bar.color = 0xFF000000;
    bar.scale.set(FlxG.width + 8, 71);
    bar.updateHitbox();
    bar.scrollFactor.set();
    bar.zIndex = 700;
    if (hexHudBarsCamera != null) bar.cameras = [hexHudBarsCamera];
    else if (camHUD != null) bar.cameras = [camHUD];
    game.add(bar);
    return bar;
}

function hexHudLayout():Void
{
    if (game == null) return;
    hexHudLastWidth = FlxG.width;
    hexHudLastHeight = FlxG.height;
    if (hexHudTop != null)
    {
        hexHudTop.scale.set(FlxG.width + 8, 71);
        hexHudTop.updateHitbox();
    }
    if (hexHudBottom != null)
    {
        hexHudBottom.scale.set(FlxG.width + 8, 71);
        hexHudBottom.updateHitbox();
        hexHudBottom.y = FlxG.height - 71;
    }
    if (hexHudLeftCircle != null)
    {
        hexHudLeftCircle.x = -2;
        hexHudLeftCircle.y = FlxG.height - hexHudLeftCircle.height;
    }
    if (hexHudRightCircle != null)
    {
        hexHudRightCircle.x = FlxG.width - hexHudRightCircle.width;
        hexHudRightCircle.y = FlxG.height - hexHudRightCircle.height;
    }
    if (hexHudTimer != null)
    {
        hexHudTimer.x = (FlxG.width - hexHudTimer.width) * 0.5;
        hexHudTimer.y = hexHudTimerY();
    }
}

function hexHudTimerY():Float
{
    var strumline:Dynamic = hexHudGet(game, 'playerStrumline');
    var down:Bool = strumline != null && hexHudGet(strumline, 'isDownscroll') == true;
    return down ? FlxG.height - 57 : 10;
}

function hexHudApplyNativeLayout():Void
{
    if (game == null) return;
    var hud:Dynamic = hexHudGet(game, 'playHUD');
    hexHudHealthBar = hexHudGet(hud, 'healthBar');
    if (hexHudHealthBar == null) hexHudHealthBar = hexHudGet(game, 'healthBar');
    hexHudIconP1 = hexHudGet(hud, 'iconP1');
    hexHudIconP2 = hexHudGet(hud, 'iconP2');
    if (hexHudIconP1 == null) hexHudIconP1 = hexHudGet(game, 'iconP1');
    if (hexHudIconP2 == null) hexHudIconP2 = hexHudGet(game, 'iconP2');

    if (hexHudHealthBar != null)
    {
        if (hexHudHealthY == null) hexHudHealthY = hexHudGet(hexHudHealthBar, 'y');
        var strumline:Dynamic = hexHudGet(game, 'playerStrumline');
        var down:Bool = strumline != null && hexHudGet(strumline, 'isDownscroll') == true;
        try { hexHudHealthBar.y = down ? FlxG.height * 0.1 + 24 : FlxG.height * 0.9 + 4; } catch (e:Dynamic) {}
    }

    if (hexHudIconP1 != null && hexHudIconP1.scale != null)
    {
        if (hexHudIconP1ScaleX == null) hexHudIconP1ScaleX = hexHudIconP1.scale.x;
        if (hexHudIconP1ScaleY == null) hexHudIconP1ScaleY = hexHudIconP1.scale.y;
        hexHudIconP1.scale.set(0.9, 0.9);
    }
    if (hexHudIconP2 != null && hexHudIconP2.scale != null)
    {
        if (hexHudIconP2ScaleX == null) hexHudIconP2ScaleX = hexHudIconP2.scale.x;
        if (hexHudIconP2ScaleY == null) hexHudIconP2ScaleY = hexHudIconP2.scale.y;
        hexHudIconP2.scale.set(0.9, 0.9);
    }

    var popups:Dynamic = hexHudGet(game, 'comboPopUps');
    if (popups != null)
    {
        var strumline:Dynamic = hexHudGet(game, 'playerStrumline');
        var opponentLine:Dynamic = hexHudGet(game, 'opponentStrumline');
        var mobileLayout:Bool = opponentLine != null && opponentLine.strumlineScale != null && opponentLine.strumlineScale.x < 1;
        var down:Bool = strumline != null && hexHudGet(strumline, 'isDownscroll') == true;
        try { Reflect.setField(popups, 'offsets', [FlxG.width * (mobileLayout ? 0.40 : 0.34), FlxG.height * (down ? -0.18 : 0.45)]); } catch (e:Dynamic) {}
    }
}

function hexHudIsHexSong():Bool
{
    if (game == null) return false;
    var song:Dynamic = PlayState.SONG;
    if (song == null) return false;
    var raw:Dynamic = hexHudGet(song, 'song');
    if (raw == null) return false;
    var id:String = Std.string(raw).toLowerCase();
    for (part in [" ", "'", ".", "_", "-", "!", "(", ")"]) id = id.split(part).join("");
    var ids:Array<String> = [
        'bit', 'biterect', 'bitremix', 'bombsncombs', 'cooling', 'coolingnew', 'cooling2026',
        'detected', 'detectednew', 'detected2026', 'dunk', 'dunknew', 'dunk2026', 'encore',
        'encorenew', 'encore2026', 'eye2eye', 'glitcher', 'glitchernew', 'glitcher2026',
        'glitcherremix', 'headbasher', 'helloworld', 'helloworldnew', 'helloworld2026',
        'hexcript', 'java', 'javanew', 'java2026', 'jumpin', 'lan', 'lcd', 'lcdnew', 'lcd2026',
        'ram', 'ramnew', 'ram2026', 'rightpace', 'tangerine', 'thatretrosong'
    ];
    if (ids.indexOf(id) >= 0) return true;
    // 2026/New variants use the same gameplay HUD as their base song.
    var base:String = id;
    var changed:Bool = true;
    while (changed)
    {
        changed = false;
        for (suffix in ['version', 'ver', '2026', 'new', 'erect', 'remix'])
        {
            if (base.length > suffix.length && base.endsWith(suffix))
            {
                base = base.substr(0, base.length - suffix.length);
                changed = true;
                break;
            }
        }
    }
    return ['bit','cooling','detected','dunk','encore','glitcher','helloworld','java','lcd','ram'].indexOf(base) >= 0;
}

function hexHudBuild():Void
{
    if (hexHudBuilt || game == null || !hexHudEnabled) return;
    hexHudBuilt = true;
    try
    {
        hexHudBarsCamera = new FlxCamera();
        hexHudBarsCamera.bgColor = 0x00000000;
        var camIndex:Int = FlxG.cameras.list.indexOf(camHUD);
        if (camIndex < 0) camIndex = FlxG.cameras.list.length;
        FlxG.cameras.insert(hexHudBarsCamera, camIndex, false);
    }
    catch (e:Dynamic)
    {
        hexHudBarsCamera = null;
    }

    hexHudTop = hexHudMakeBar(-4);
    hexHudBottom = hexHudMakeBar(FlxG.height - 71);

    hexHudLeftCircle = new FlxSprite();
    try { hexHudLeftCircle.loadGraphic(Paths.image('ui/hex/circle')); } catch (e:Dynamic) {}
    hexHudLeftCircle.scrollFactor.set();
    hexHudLeftCircle.x = -2;
    hexHudLeftCircle.y = FlxG.height - hexHudLeftCircle.height;
    hexHudLeftCircle.zIndex = 701;
    if (hexHudBarsCamera != null) hexHudLeftCircle.cameras = [hexHudBarsCamera];
    else if (camHUD != null) hexHudLeftCircle.cameras = [camHUD];
    game.add(hexHudLeftCircle);

    hexHudRightCircle = new FlxSprite();
    try { hexHudRightCircle.loadGraphic(Paths.image('ui/hex/circle')); } catch (e:Dynamic) {}
    hexHudRightCircle.scrollFactor.set();
    hexHudRightCircle.scale.set(1.5, 1.5);
    hexHudRightCircle.flipX = true;
    hexHudRightCircle.origin.set(0, 0);
    hexHudRightCircle.updateHitbox();
    hexHudRightCircle.x = FlxG.width - hexHudRightCircle.width;
    hexHudRightCircle.y = FlxG.height - hexHudRightCircle.height;
    hexHudRightCircle.zIndex = 701;
    if (hexHudBarsCamera != null) hexHudRightCircle.cameras = [hexHudBarsCamera];
    else if (camHUD != null) hexHudRightCircle.cameras = [camHUD];
    game.add(hexHudRightCircle);

    hexHudTimer = new FlxText(0, 10, FlxG.width, '', 20);
    try { hexHudTimer.setFormat(Paths.font('ui/fonts/Arista'), 42, 0xFFFFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0xFF000000); }
    catch (e:Dynamic) { hexHudTimer.setFormat(null, 32, 0xFFFFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0xFF000000); }
    hexHudTimer.scrollFactor.set();
    hexHudTimer.zIndex = 801;
    if (camHUD != null) hexHudTimer.cameras = [camHUD];
    hexHudTimer.alpha = 0;
    game.add(hexHudTimer);
    hexHudTimerFade = 0;
    hexHudTimerReady = false;
    hexHudApplyNativeLayout();
    hexHudLayout();
    try {
        var refreshFn:Dynamic = Reflect.field(game, 'refresh');
        if (refreshFn != null && Reflect.isFunction(refreshFn)) Reflect.callMethod(game, refreshFn, []);
    } catch (e:Dynamic) {}
}

function hexHudSetVisible(value:Bool):Void
{
    hexHudVisible = value;
    for (obj in [hexHudTop, hexHudBottom, hexHudLeftCircle, hexHudRightCircle])
        if (obj != null) obj.visible = value;
}

function hexHudShowHealth(value:Bool):Void
{
    if (hexHudTimer != null) hexHudTimer.visible = value;
    var hud:Dynamic = hexHudGet(game, 'playHUD');
    for (field in ['healthBar', 'healthBarBG', 'iconP1', 'iconP2', 'scoreText'])
    {
        var obj:Dynamic = hexHudGet(hud, field);
        if (obj == null) obj = hexHudGet(game, field);
        if (obj != null) try { obj.visible = value; } catch (e:Dynamic) {}
    }
}

function onCreatePost():Void
{
    hexHudEnabled = hexHudIsHexSong();
    if (!hexHudEnabled) return;
    hexHudBuild();
}

function onUpdatePost(elapsed:Float):Void
{
    if (game == null) return;
    if (!hexHudEnabled) { hexHudEnabled = hexHudIsHexSong(); if (!hexHudEnabled) return; }
    if (!hexHudBuilt) hexHudBuild();
    if (!hexHudBuilt) return;

    if (FlxG.width != hexHudLastWidth || FlxG.height != hexHudLastHeight)
        hexHudLayout();

    if (hexHudTimer != null && FlxG.sound.music != null)
    {
        var remain:Float = (FlxG.sound.music.length - Conductor.songPosition) / 1000;
        if (remain < 0) remain = 0;
        var mins:Int = Std.int(remain / 60);
        var secs:Int = Std.int(remain) % 60;
        hexHudTimer.text = Std.string(mins) + ':' + (secs < 10 ? '0' : '') + Std.string(secs);
        hexHudTimer.x = (FlxG.width - hexHudTimer.width) * 0.5;
        hexHudTimer.y = hexHudTimerY();
        if (!hexHudTimerReady)
        {
            hexHudTimerFade += elapsed;
            hexHudTimer.alpha = Math.min(1, hexHudTimerFade * 2);
            if (hexHudTimer.alpha >= 1) hexHudTimerReady = true;
        }
    }
}

function onSongRetry(event:Dynamic = null):Void
{
    if (!hexHudEnabled) return;
    hexHudTimerReady = false;
    hexHudTimerFade = 0;
    if (hexHudTimer != null) hexHudTimer.alpha = 0;
    hexHudSetVisible(true);
    hexHudApplyNativeLayout();
}

function onDestroy():Void
{
    if (hexHudEnabled)
    {
        if (hexHudHealthBar != null && hexHudHealthY != null)
            try { hexHudHealthBar.y = hexHudHealthY; } catch (e:Dynamic) {}
        if (hexHudIconP1 != null && hexHudIconP1.scale != null && hexHudIconP1ScaleX != null && hexHudIconP1ScaleY != null)
            try { hexHudIconP1.scale.set(hexHudIconP1ScaleX, hexHudIconP1ScaleY); } catch (e:Dynamic) {}
        if (hexHudIconP2 != null && hexHudIconP2.scale != null && hexHudIconP2ScaleX != null && hexHudIconP2ScaleY != null)
            try { hexHudIconP2.scale.set(hexHudIconP2ScaleX, hexHudIconP2ScaleY); } catch (e:Dynamic) {}
    }

    if (game != null)
    {
        for (obj in [hexHudTop, hexHudBottom, hexHudLeftCircle, hexHudRightCircle, hexHudTimer])
        {
            if (obj == null) continue;
            try { game.remove(obj); } catch (e:Dynamic) {}
            try { obj.destroy(); } catch (inner:Dynamic) {}
        }
    }
    if (hexHudBarsCamera != null)
    {
        try { if (FlxG.cameras.list.indexOf(hexHudBarsCamera) >= 0) FlxG.cameras.remove(hexHudBarsCamera); } catch (e:Dynamic) {}
        try { hexHudBarsCamera.destroy(); } catch (e:Dynamic) {}
    }
    hexHudTop = null;
    hexHudBottom = null;
    hexHudLeftCircle = null;
    hexHudRightCircle = null;
    hexHudTimer = null;
    hexHudBarsCamera = null;
    hexHudBuilt = false;
    hexHudEnabled = false;
}
