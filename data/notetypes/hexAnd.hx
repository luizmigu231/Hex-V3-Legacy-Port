function hit(note:Dynamic, fieldID:Int = 0):Void
{
    if (note == null || fieldID != 0 || game == null) return;
    game.scripts.call('hexSpecialSing', [note, false]);
}

function noteMiss(note:Dynamic, fieldID:Int = 0):Void
{
    if (note == null || fieldID != 0 || game == null) return;
    game.scripts.call('hexSpecialSing', [note, true]);
}
