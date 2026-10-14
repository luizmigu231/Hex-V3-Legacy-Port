function setupNote(note:Dynamic):Void
{
    if (note == null) return;
    note.canMiss = true;
    note.ratingDisabled = true;
    note.noAnimation = true;
    note.noMissAnimation = true;
    note.noteSplashDisabled = true;
    note.hitsoundDisabled = true;
    note.hitHealth = 0;
    note.missHealth = 0;
    note.hitbox = 75;
    try { if (note.lane == 1 || (game != null && game.cpuControlled)) note.ignoreNote = true; } catch (e:Dynamic) {}
    note.texture = 'notes/hex_mine_slasher';
}

function loadNoteAnims(note:Dynamic):Void
{
    if (note == null) return;
    var prefixes:Array<String> = ['noteLeft', 'noteDown', 'noteUp', 'noteRight'];
    var prefix:String = prefixes[Std.int(Math.abs(note.noteData)) % 4];
    note.animation.addByPrefix('scroll', prefix, 24, true);
    note.animation.addByPrefix('hold', prefix, 24, true);
    note.animation.addByPrefix('holdend', prefix, 24, true);
    note.setGraphicSize(Std.int(note.width * 0.65));
    note.updateHitbox();
    note.baseScale.copyFrom(note.scale);
}

function hit(note:Dynamic, fieldID:Int = 0):Void
{
    if (note == null || game == null || game.cpuControlled || fieldID == 1) return;
    game.scripts.call('hexMineQueueOrDetonate', [note, 'mine_slasher']);
}

function goodNoteHit(note:Dynamic, fieldID:Int = 0):Dynamic
{
    if (note != null && game != null && fieldID != 1) game.scripts.call('hexMineFinalizeHit', [note]);
    return Function_Stop;
}
function opponentNoteHit(note:Dynamic, fieldID:Int = 0):Dynamic return Function_Stop;
function extraNoteHit(note:Dynamic, fieldID:Int = 0):Dynamic return Function_Stop;

function noteMiss(note:Dynamic, fieldID:Int = 0):Dynamic
{
    if (note != null) { note.visible = false; note.alpha = 0; }
    return Function_Stop;
}
