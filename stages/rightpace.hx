var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-606.3, -514.1);
    hexSprite0.loadGraphic(Paths.image('stages/hex/rightpace/white-man'));
    hexSprite0.scale.set(1.0204, 1.0204);
    hexSprite0.scrollFactor.set(1.0, 1.0);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 9;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(-606.3, -514.1);
    hexSprite1.loadGraphic(Paths.image('stages/hex/rightpace/RightPaceBG2'));
    hexSprite1.scale.set(1.0204, 1.0204);
    hexSprite1.scrollFactor.set(1.0, 1.0);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 10;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
    var hexSprite2:FlxSprite = new FlxSprite(-606.3, -514.1);
    hexSprite2.loadGraphic(Paths.image('stages/hex/rightpace/RightPaceBG9'));
    hexSprite2.scale.set(1.0204, 1.0204);
    hexSprite2.scrollFactor.set(1.0, 1.0);
    hexSprite2.alpha = 1.0;
    hexSprite2.angle = 0.0;
    hexSprite2.zIndex = 10;
    hexSprite2.updateHitbox();
    add(hexSprite2);
    hexProps.push(hexSprite2);
    var hexSprite3:FlxSprite = new FlxSprite(-278.3, -177.0);
    hexSprite3.frames = Paths.getSparrowAtlas('stages/hex/rightpace/RightPaceRichard');
    hexSprite3.animation.addByPrefix('idle', 'richardLoop', 24, false);
    hexSprite3.animation.play('idle', true);
    hexSprite3.scale.set(1.0204, 1.0204);
    hexSprite3.scrollFactor.set(1.0, 1.0);
    hexSprite3.alpha = 1.0;
    hexSprite3.angle = 0.0;
    hexSprite3.zIndex = 10;
    hexSprite3.updateHitbox();
    add(hexSprite3);
    hexProps.push(hexSprite3);
    hexBoppers.push({sprite: hexSprite3, beat: 4, anim: 'idle'});
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
