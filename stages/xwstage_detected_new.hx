var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-24.0, -24.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/xwstage_detected_new/hexBack'));
    hexSprite0.scale.set(1.5, 1.5);
    hexSprite0.scrollFactor.set(0.9, 0.9);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(-24.0, -24.0);
    hexSprite1.loadGraphic(Paths.image('stages/hex/xwstage_detected_new/hexFront'));
    hexSprite1.scale.set(1.5, 1.5);
    hexSprite1.scrollFactor.set(0.9, 0.9);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 20;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
    var hexSprite2:FlxSprite = new FlxSprite(-24.0, -24.0);
    hexSprite2.loadGraphic(Paths.image('stages/hex/xwstage_detected_new/topOverlay'));
    hexSprite2.scale.set(1.5, 1.5);
    hexSprite2.scrollFactor.set(0.9, 0.9);
    hexSprite2.alpha = 1.0;
    hexSprite2.angle = 0.0;
    hexSprite2.zIndex = 30;
    hexSprite2.updateHitbox();
    add(hexSprite2);
    hexProps.push(hexSprite2);
    var hexSprite3:FlxSprite = new FlxSprite(42.0, -150.0);
    hexSprite3.frames = Paths.getSparrowAtlas('stages/hex/xwstage_detected_new/crowd');
    hexSprite3.animation.addByPrefix('idle', 'Symbol', 24, false);
    hexSprite3.animation.play('idle', true);
    hexSprite3.scale.set(1.5, 1.5);
    hexSprite3.scrollFactor.set(0.9, 0.9);
    hexSprite3.alpha = 1.0;
    hexSprite3.angle = 0.0;
    hexSprite3.zIndex = 25;
    hexSprite3.updateHitbox();
    add(hexSprite3);
    hexProps.push(hexSprite3);
    hexBoppers.push({sprite: hexSprite3, beat: 4, anim: 'idle'});
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
