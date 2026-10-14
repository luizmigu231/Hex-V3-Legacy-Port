var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-320.0, -195.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/streetside/Tangerine_BG'));
    hexSprite0.scale.set(1.5, 1.5);
    hexSprite0.scrollFactor.set(0.9, 0.9);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(-320.0, -240.0);
    hexSprite1.frames = Paths.getSparrowAtlas('stages/hex/streetside/Tangerine_Audience');
    hexSprite1.animation.addByPrefix('idle', 'audienceLoop', 24, false);
    hexSprite1.animation.play('idle', true);
    hexSprite1.scale.set(1.5, 1.5);
    hexSprite1.scrollFactor.set(0.9, 0.9);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 1000;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
    hexBoppers.push({sprite: hexSprite1, beat: 2, anim: 'idle'});
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
