var hexProps:Array<Dynamic> = [];
var hexBoppers:Array<Dynamic> = [];
var hexLookOverlay:FlxSprite = null;
function onLoad() {
    var hexSprite0:FlxSprite = new FlxSprite(0.0, 25.0);
    hexSprite0.loadGraphic(Paths.image('stages/hex/windows/BG_Hexware'));
    hexSprite0.scale.set(1.0, 1.0);
    hexSprite0.scrollFactor.set(1.0, 1.0);
    hexSprite0.alpha = 1.0;
    hexSprite0.angle = 0.0;
    hexSprite0.zIndex = 10;
    hexSprite0.updateHitbox();
    add(hexSprite0);
    hexProps.push(hexSprite0);
    var hexSprite1:FlxSprite = new FlxSprite(0.0, 0.0);
    hexSprite1.loadGraphic(Paths.image('stages/hex/windows/cursor'));
    hexSprite1.scale.set(1.0, 1.0);
    hexSprite1.scrollFactor.set(1.0, 1.0);
    hexSprite1.alpha = 1.0;
    hexSprite1.angle = 0.0;
    hexSprite1.zIndex = 500;
    hexSprite1.updateHitbox();
    add(hexSprite1);
    hexProps.push(hexSprite1);
    var hexSprite2:FlxSprite = new FlxSprite(135.0, 200.0);
    hexSprite2.frames = Paths.getSparrowAtlas('stages/hex/windows/windowNotepad');
    hexSprite2.animation.addByPrefix('open', 'windowNotepadOpening', 24, false);
    hexSprite2.animation.addByPrefix('close', 'windowNotepadClosing', 24, false);
    hexSprite2.animation.play('open', true);
    hexSprite2.scale.set(1.0, 1.0);
    hexSprite2.scrollFactor.set(1.0, 1.0);
    hexSprite2.alpha = 1.0;
    hexSprite2.angle = 0.0;
    hexSprite2.zIndex = 12;
    hexSprite2.updateHitbox();
    add(hexSprite2);
    hexProps.push(hexSprite2);
    var hexSprite3:FlxSprite = new FlxSprite(155.0, 715.0);
    hexSprite3.frames = Paths.getSparrowAtlas('stages/hex/windows/taskbarLayer');
    hexSprite3.animation.addByPrefix('1', '1', 1, false);
    hexSprite3.animation.addByPrefix('2', '2', 1, false);
    hexSprite3.animation.addByPrefix('3', '3', 1, false);
    hexSprite3.animation.addByPrefix('4', '4', 1, false);
    hexSprite3.animation.addByPrefix('5', '5', 1, false);
    hexSprite3.animation.play('1', true);
    hexSprite3.scale.set(1.0, 1.0);
    hexSprite3.scrollFactor.set(1.0, 1.0);
    hexSprite3.alpha = 1.0;
    hexSprite3.angle = 0.0;
    hexSprite3.zIndex = 15;
    hexSprite3.updateHitbox();
    add(hexSprite3);
    hexProps.push(hexSprite3);
}
function onCreatePost() { refreshZ(); }
function onBeatHit() {
    for (bop in hexBoppers) if (bop.beat > 0 && curBeat % bop.beat == 0) bop.sprite.animation.play(bop.anim, true);
}
