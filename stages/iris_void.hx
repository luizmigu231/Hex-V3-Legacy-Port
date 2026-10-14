import flixel.FlxSprite;
import flixel.FlxG;

var e2eStagePath = 'stages/hex/iris_void/';
var e2eStageSphere:FlxSprite;
var e2eStageSphereName:String = '';
var e2eStageSphereShader:Dynamic;
var e2eStageRadius:Float = 1400;
var e2eStageOldBgColor:Int = 0xFF000000;
var e2eStageText1:FlxSprite;
var e2eStageText2:FlxSprite;
var e2eStageText3:FlxSprite;
var e2eStageText4:FlxSprite;
var e2eStageText5:FlxSprite;

function e2eAssetExists(path:String):Bool
{
    return Paths.fileExists(path);
}

function e2eMakeText(name:String, scale:Float):FlxSprite
{
    var imagePath = 'images/' + e2eStagePath + name + '.png';
    if (!e2eAssetExists(imagePath)) return null;
    var spr = new FlxSprite(-10000, -10000);
    spr.loadGraphic(Paths.image(e2eStagePath + name));
    spr.setGraphicSize(Std.int(spr.width * scale));
    spr.updateHitbox();
    spr.scrollFactor.set(0, 0);
    spr.zIndex = 10;
    spr.alpha = 0;
    spr.visible = false;
    add(spr);
    return spr;
}

function onLoad()
{
    if (FlxG.camera != null)
    {
        e2eStageOldBgColor = FlxG.camera.bgColor;
        FlxG.camera.bgColor = 0xFF000000;
    }

    e2eStageSphere = null;
    e2eStageSphereShader = null;
    e2eStageSphereName = '';
    var sphereCandidates:Array<String> = ['Eye2Eye_BG_0', 'Eye2Eye_BG_2'];
    for (candidate in sphereCandidates)
    {
        if (e2eAssetExists('images/' + e2eStagePath + candidate + '.png'))
        {
            e2eStageSphereName = candidate;
            break;
        }
    }
    if (e2eStageSphereName != '')
    {
        e2eStageSphere = new FlxSprite(FlxG.width * 0.5 - 1400, FlxG.height * 0.5 - 1400);
        e2eStageSphere.loadGraphic(Paths.image(e2eStagePath + e2eStageSphereName));
        e2eStageSphere.setGraphicSize(2800, 2800);
        e2eStageSphere.updateHitbox();
        e2eStageSphere.scrollFactor.set(0, 0);
        e2eStageSphere.zIndex = 15;
        if (e2eAssetExists('shaders/eye2eye/eye2eye_sphere.frag'))
            e2eStageSphereShader = newShader('eye2eye/eye2eye_sphere');
        if (e2eStageSphereShader != null)
        {
            e2eStageSphere.shader = e2eStageSphereShader;
            e2eStageSphereShader.setFloat('uGray', 0);
            e2eStageSphereShader.setFloat('uInvert', 0);
        }
        add(e2eStageSphere);
    }

    e2eStageText1 = e2eMakeText('text1', 0.75);
    e2eStageText2 = e2eMakeText('text2', 0.75);
    e2eStageText3 = e2eMakeText('text3', 0.5);
    e2eStageText4 = e2eMakeText('text4', 0.5);
    e2eStageText5 = e2eMakeText('text5', 0.5);

    if (e2eStageText1 != null) { e2eStageText1.x = -75; e2eStageText1.y = -75; }
    if (e2eStageText2 != null) { e2eStageText2.x = -75; e2eStageText2.y = -75; }

    if (e2eStageText3 != null) { e2eStageText3.x = FlxG.width * 0.5 - e2eStageText3.width * 0.5; e2eStageText3.y = 75; }
    if (e2eStageText4 != null) { e2eStageText4.x = FlxG.width * 0.5 - e2eStageText4.width * 0.5; e2eStageText4.y = 75; }
    if (e2eStageText5 != null) { e2eStageText5.x = FlxG.width * 0.5 - e2eStageText5.width * 0.5; e2eStageText5.y = 75; }

    game.variables.set('eye2eye.sphere', e2eStageSphere);
    game.variables.set('eye2eye.sphereShader', e2eStageSphereShader);
    game.variables.set('eye2eye.text1', e2eStageText1);
    game.variables.set('eye2eye.text2', e2eStageText2);
    game.variables.set('eye2eye.text3', e2eStageText3);
    game.variables.set('eye2eye.text4', e2eStageText4);
    game.variables.set('eye2eye.text5', e2eStageText5);
    game.variables.set('eye2eye.radius', 1400);
    game.variables.set('eye2eye.gray', 0);
    game.variables.set('eye2eye.invert', 0);
}

function onUpdate(elapsed:Float)
{
    if (e2eStageSphere == null) return;

    var targetRadius:Float = game.variables.get('eye2eye.radius');
    if (targetRadius <= 0) targetRadius = 1400;
    if (e2eStageSphere == null) return;
    e2eStageRadius += (targetRadius - e2eStageRadius) * Math.min(1, elapsed * 7);

    var diameter = Std.int(e2eStageRadius * 2);
    e2eStageSphere.setGraphicSize(diameter, diameter);
    e2eStageSphere.updateHitbox();
    e2eStageSphere.x = FlxG.width * 0.5 - e2eStageRadius;
    e2eStageSphere.y = FlxG.height * 0.5 - e2eStageRadius;

    if (e2eStageSphereShader != null)
    {
        var gray:Float = game.variables.get('eye2eye.gray');
        var invert:Float = game.variables.get('eye2eye.invert');
        e2eStageSphereShader.setFloat('uGray', gray);
        e2eStageSphereShader.setFloat('uInvert', invert);
    }
}

function onDestroy()
{
    if (FlxG.camera != null) FlxG.camera.bgColor = e2eStageOldBgColor;
}
