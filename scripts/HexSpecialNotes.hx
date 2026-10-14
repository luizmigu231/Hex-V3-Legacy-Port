import flixel.FlxG;
import flixel.FlxSprite;
import funkin.Paths;

var hexMineOwner:Dynamic = null;
var hexMineActive:Array<Dynamic> = [];
var hexMinePool:Array<Dynamic> = [];
var hexMinePending:Array<Dynamic> = [];
var hexMineComboFinalize:Array<Dynamic> = [];
var hexMineSlasherBotKeys:Array<String> = [];

function hexSpecialSing(note:Dynamic, miss:Bool = false):Void
{
    if (game == null || note == null || gf == null) return;
    var direction:Int = 0;
    try { direction = Std.int(Math.abs(note.noteData)) % 4; } catch (e:Dynamic) { return; }
    var anims:Dynamic = null;
    try { anims = note.skin.singAnimations; } catch (e:Dynamic) {}
    var names:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
    var anim:String = names[direction];
    try { if (anims != null && anims.length > direction && anims[direction] != null) anim = Std.string(anims[direction]); } catch (e:Dynamic) {}
    if (miss) anim += 'miss';
    else try { if (note.animSuffix != null) anim += Std.string(note.animSuffix); } catch (e:Dynamic) {}
    try { gf.playAnim(anim, true); gf.holdTimer = 0; } catch (e:Dynamic) {}
}

function hexMineHeld(lane:Int):Bool
{
    if (game == null || lane < 0 || lane > 3 || game.cpuControlled) return false;
    var c:Dynamic = null;
    try { c = game.controls; } catch (e:Dynamic) {}
    if (c == null) return false;
    try
    {
        switch (lane)
        {
            case 0: return c.NOTE_LEFT;
            case 1: return c.NOTE_DOWN;
            case 2: return c.NOTE_UP;
            case 3: return c.NOTE_RIGHT;
        }
    }
    catch (e:Dynamic) {}
    return false;
}

function hexMineSpawnExplosion(x:Float, y:Float, width:Float, height:Float, kind:String):Void
{
    if (game == null) return;
    var boom:Dynamic = hexMinePool.length > 0 ? hexMinePool.pop() : null;
    if (boom == null)
    {
        try
        {
            boom = new FlxSprite();
            boom.frames = Paths.getSparrowAtlas('ui/hex/hex_mine_explosion');
            boom.animation.addByPrefix('explode', 'mineBoom', 24, false);
        }
        catch (e:Dynamic)
        {
            trace('[HexSpecialNotes] Could not load mine explosion atlas: ' + e);
            return;
        }
    }
    try
    {
        boom.revive();
        boom.visible = true;
        boom.alpha = 1;
        boom.x = x + (width - boom.width) * 0.5;
        boom.y = y + (height - boom.height) * 0.5;
        boom.cameras = [game.camHUD];
        boom.animation.play('explode', true);
        game.add(boom);
        hexMineActive.push(boom);
    }
    catch (e:Dynamic) { trace('[HexSpecialNotes] Could not display mine explosion: ' + e); }
    if (kind == 'mine_reg')
    {
        try { FlxG.sound.play(Paths.sound('ui/hex/sounds/mine_reg_hit')); } catch (e:Dynamic) {}
    }
}

function hexMineSlasherDeath():Bool
{
    if (game == null || game.scripts == null) return false;
    try
    {
        for (script in game.scripts.members)
        {
            if (script == null || !script.exists('evilDeathScreen')) continue;
            script.call('evilDeathScreen', []);
            return true;
        }
    }
    catch (e:Dynamic) {}
    return false;
}

function hexMineApplyPenalty(kind:String, alreadyCounted:Bool):Void
{
    if (game == null) return;
    try
    {
        if (!game.practiceMode) game.songScore -= (alreadyCounted ? 990 : 1000);
        if (!alreadyCounted)
        {
            game.songMisses++;
            game.totalPlayed++;
            game.missCombo++;
        }
        game.combo = 0;
        game.health -= 0.1;
    }
    catch (e:Dynamic) { trace('[HexSpecialNotes] Mine penalty partially failed: ' + e); }
    if (kind == 'mine_slasher' && !hexMineSlasherDeath())
    {
        try { game.health = 0; } catch (e:Dynamic) {}
    }
}

function hexMineComboEntry(note:Dynamic):Dynamic
{
    if (note == null) return null;
    for (entry in hexMineComboFinalize)
    {
        if (entry != null && entry.note == note && entry.strumTime == note.strumTime && entry.noteData == note.noteData && entry.noteType == note.noteType && entry.fieldID == note.lane) return entry;
    }
    return null;
}

function hexMineMarkTriggered(note:Dynamic):Void
{
    var entry:Dynamic = hexMineComboEntry(note);
    if (entry != null) entry.triggered = true;
}

function hexMineFinalizeHit(note:Dynamic):Void
{
    var entry:Dynamic = hexMineComboEntry(note);
    if (entry != null) entry.ready = true;
}

function hexMineDetonate(note:Dynamic, kind:String, alreadyCounted:Bool = false):Void
{
    if (game == null || note == null) return;
    hexMineMarkTriggered(note);
    var x:Float = 0; var y:Float = 0; var w:Float = 0; var h:Float = 0;
    try { x = note.x; y = note.y; w = note.width; h = note.height; } catch (e:Dynamic) {}
    hexMineSpawnExplosion(x, y, w, h, kind);
    hexMineApplyPenalty(kind, alreadyCounted);
    try { note.visible = false; note.alpha = 0; note.kill(); } catch (e:Dynamic) {}
}

function hexMineDetonatePending(entry:Dynamic):Void
{
    if (entry == null) return;
    if (entry.comboEntry != null) entry.comboEntry.triggered = true;
    hexMineSpawnExplosion(entry.x, entry.y, entry.width, entry.height, entry.kind);
    hexMineApplyPenalty(entry.kind, false);
    entry.triggered = true;
}

function hexMineQueueOrDetonate(note:Dynamic, kind:String):Void
{
    if (game == null || note == null) return;
    var comboEntry:Dynamic = hexMineComboEntry(note);
    if (comboEntry == null)
    {
        comboEntry = {note: note, before: game.combo, triggered: false, ready: false, strumTime: note.strumTime, noteData: note.noteData, noteType: note.noteType, fieldID: note.lane};
        hexMineComboFinalize.push(comboEntry);
    }
    var now:Float = Conductor.songPosition;
    if (now >= note.strumTime)
    {
        hexMineDetonate(note, kind, false);
        return;
    }
    var entry:Dynamic = {
        lane: Std.int(Math.abs(note.noteData)) % 4,
        strumTime: note.strumTime,
        x: note.x,
        y: note.y,
        width: note.width,
        height: note.height,
        note: note,
        comboEntry: comboEntry,
        kind: kind,
        triggered: false
    };
    hexMinePending.push(entry);
    try { note.visible = false; note.alpha = 0; } catch (e:Dynamic) {}
}

function hexMineSweep():Void
{
    if (game != null)
    {
        try
        {
            var now:Float = Conductor.songPosition;
            for (note in game.notes.members)
            {
                if (note == null || !note.alive || !note.visible) continue;
                var kind:String = note.noteType == null ? '' : Std.string(note.noteType);
                if (kind != 'mine_reg' && kind != 'mine_slasher') continue;
                var late:Float = now - note.strumTime;
                if (game.cpuControlled)
                {
                    if (kind == 'mine_slasher' && late >= 0 && late <= 75)
                    {
                        var botKey:String = Std.string(note.strumTime) + ':' + Std.string(note.noteData) + ':' + Std.string(note.lane);
                        if (hexMineSlasherBotKeys.indexOf(botKey) < 0)
                        {
                            hexMineSlasherBotKeys.push(botKey);
                            var botAnims:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
                            try { if (dad != null) { dad.playAnim(botAnims[Std.int(Math.abs(note.noteData)) % 4], true); dad.holdTimer = 0; } } catch (e:Dynamic) {}
                        }
                    }
                    continue;
                }
                if (late < 0 || late > 75) continue;
                if (hexMineHeld(Std.int(Math.abs(note.noteData)) % 4)) hexMineDetonate(note, kind, false);
            }
        }
        catch (e:Dynamic) {}
    }
    var i:Int = hexMineActive.length;
    while (i-- > 0)
    {
        var boom:Dynamic = hexMineActive[i];
        var finished:Bool = false;
        try { finished = boom.animation == null || boom.animation.curAnim == null || boom.animation.curAnim.finished; } catch (e:Dynamic) { finished = true; }
        if (!finished) continue;
        try { game.remove(boom); boom.kill(); } catch (e:Dynamic) {}
        hexMineActive.splice(i, 1);
        hexMinePool.push(boom);
    }
    var now:Float = Conductor.songPosition;
    i = hexMinePending.length;
    while (i-- > 0)
    {
        var entry:Dynamic = hexMinePending[i];
        if (entry == null || entry.triggered || now - entry.strumTime > 75)
        {
            hexMinePending.splice(i, 1);
            continue;
        }
        var late:Float = now - entry.strumTime;
        if (late >= 0 && late <= 75 && hexMineHeld(entry.lane))
        {
            hexMineDetonatePending(entry);
            hexMinePending.splice(i, 1);
        }
    }
    if (game != null && gf != null)
    {
        try
        {
            for (note in game.notes.members)
            {
                if (note == null || !note.alive || !note.isSustainNote || !note.wasGoodHit || note.tooLate) continue;
                if (note.noteType != 'hex' && note.noteType != 'hexAnd') continue;
                if (gf.animation != null && gf.animation.curAnim != null && StringTools.startsWith(gf.animation.curAnim.name, 'sing')) gf.holdTimer = 0;
            }
        }
        catch (e:Dynamic) {}
    }
    if (game != null && hexMineComboFinalize.length > 0)
    {
        var restoreCombo:Int = game.combo;
        var foundBefore:Bool = false;
        var wasTriggered:Bool = false;
        var keep:Array<Dynamic> = [];
        for (entry in hexMineComboFinalize)
        {
            if (entry == null) continue;
            if (entry.ready != true)
            {
                keep.push(entry);
                continue;
            }
            if (entry.triggered == true) wasTriggered = true;
            var before:Dynamic = entry.before;
            if (before != null && (!foundBefore || Std.int(before) < restoreCombo))
            {
                restoreCombo = Std.int(before);
                foundBefore = true;
            }
        }
        hexMineComboFinalize = keep;
        if (wasTriggered) game.combo = 0;
        else if (foundBefore) game.combo = restoreCombo;
    }
}

function onCreatePost():Void
{
    if (hexMineOwner != game)
    {
        hexMineOwner = game;
        hexMineActive = [];
        hexMinePool = [];
        hexMinePending = [];
        hexMineComboFinalize = [];
        hexMineSlasherBotKeys = [];
    }
}

function onUpdatePost(elapsed:Float):Void hexMineSweep();

function onSongRetry(event:Dynamic = null):Void
{
    hexMinePending.resize(0);
    hexMineComboFinalize.resize(0);
    hexMineSlasherBotKeys.resize(0);
    for (boom in hexMineActive)
    {
        try { game.remove(boom); boom.kill(); hexMinePool.push(boom); } catch (e:Dynamic) {}
    }
    hexMineActive.resize(0);
}

function onDestroy():Void
{
    if (game != null)
    {
        for (boom in hexMineActive) try { game.remove(boom); boom.destroy(); } catch (e:Dynamic) {}
        for (boom in hexMinePool) try { boom.destroy(); } catch (e:Dynamic) {}
    }
    hexMineActive.resize(0);
    hexMinePool.resize(0);
    hexMinePending.resize(0);
    hexMineComboFinalize.resize(0);
    hexMineSlasherBotKeys.resize(0);
    hexMineOwner = null;
}
