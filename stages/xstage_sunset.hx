var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-600.0, -200.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/xstage_sunset/weekx_back'));
    hexSprite0.scale.set(1.0, 1.0);
    hexSprite0.scrollFactor.set(0.9, 0.9);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(-650.0, 600.0);
    hexSprite1.loadGraphic(Paths.image('stages/hex/xstage_sunset/weekx_front'));
    hexSprite1.scale.set(1.1, 1.1);
    hexSprite1.scrollFactor.set(0.9, 0.9);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 20;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
