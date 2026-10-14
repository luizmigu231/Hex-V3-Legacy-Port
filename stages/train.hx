var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-250.0, 150.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/train/BIT_BG'));
    hexSprite0.scale.set(0.75, 0.75);
    hexSprite0.scrollFactor.set(1.0, 1.0);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(-225.0, 425.0);
    hexSprite1.frames = Paths.getSparrowAtlas('stages/hex/train/BIT_GUY1');
    hexSprite1.animation.addByPrefix('idle', 'guy1_idle', 24, false);
    hexSprite1.animation.play('idle', true);
    hexSprite1.scale.set(1.0, 1.0);
    hexSprite1.scrollFactor.set(1.0, 1.0);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 20;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
    hexBoppers.push({sprite: hexSprite1, beat: 8, anim: 'idle'});
    var hexSprite2:FlxSprite = new FlxSprite(955.0, 425.0);
    hexSprite2.frames = Paths.getSparrowAtlas('stages/hex/train/BIT_GUY2');
    hexSprite2.animation.addByPrefix('idle', 'guy2_idle', 24, false);
    hexSprite2.animation.play('idle', true);
    hexSprite2.scale.set(1.0, 1.0);
    hexSprite2.scrollFactor.set(1.0, 1.0);
    hexSprite2.alpha = 1.0;
    hexSprite2.angle = 0.0;
    hexSprite2.zIndex = 20;
    hexSprite2.updateHitbox();
    add(hexSprite2);
    hexProps.push(hexSprite2);
    hexBoppers.push({sprite: hexSprite2, beat: 8, anim: 'idle'});
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
