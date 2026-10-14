var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(-600.0, -600.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/lan/bg'));
    hexSprite0.scale.set(1.0, 1.0);
    hexSprite0.scrollFactor.set(1.0, 1.0);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(-600.0, -600.0);
    hexSprite1.loadGraphic(Paths.image('stages/hex/lan/frg'));
    hexSprite1.scale.set(1.0, 1.0);
    hexSprite1.scrollFactor.set(1.0, 1.0);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 50;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
    var hexSprite2:FlxSprite = new FlxSprite(-725.0, -635.0);
    hexSprite2.frames = Paths.getSparrowAtlas('stages/hex/lan/Audience_LAN');
    hexSprite2.animation.addByPrefix('idle', 'audienceLoop', 24, false);
    hexSprite2.animation.play('idle', true);
    hexSprite2.scale.set(1.0, 1.0);
    hexSprite2.scrollFactor.set(1.0, 1.0);
    hexSprite2.alpha = 1.0;
    hexSprite2.angle = 0.0;
    hexSprite2.zIndex = 999;
    hexSprite2.updateHitbox();
    add(hexSprite2);
    hexProps.push(hexSprite2);
    hexBoppers.push({sprite: hexSprite2, beat: 2, anim: 'idle'});
    var hexSprite3:FlxSprite = new FlxSprite(-600.0, -600.0);
    hexSprite3.loadGraphic(Paths.image('stages/hex/lan/addlayer'));
    hexSprite3.scale.set(1.0, 1.0);
    hexSprite3.scrollFactor.set(1.0, 1.0);
    hexSprite3.alpha = 0.45;
    hexSprite3.angle = 0.0;
    hexSprite3.zIndex = 1000;
    hexSprite3.updateHitbox();
    add(hexSprite3);
    hexProps.push(hexSprite3);
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
