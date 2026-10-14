var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-725.0, -980.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/bombsncombs/bg'));
    hexSprite0.scale.set(1.0, 1.0);
    hexSprite0.scrollFactor.set(1.0, 1.0);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(445.0, -85.0);
    hexSprite1.loadGraphic(Paths.image('stages/hex/bombsncombs/logo'));
    hexSprite1.scale.set(1.0, 1.0);
    hexSprite1.scrollFactor.set(1.0, 1.0);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 100000;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
