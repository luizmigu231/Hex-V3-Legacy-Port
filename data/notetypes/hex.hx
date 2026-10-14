function setupNote(note:Dynamic):Void
{
    if (note == null) return;
    // Note setup runs before Legacy assigns note.playField; lane is the queued field ID here.
    if (note.lane != 1) note.gfNote = true;
}

function hit(note:Dynamic, fieldID:Int = 0):Void
{
    if (note == null || fieldID != 0) return;
    try { if (boyfriend != null) boyfriend.holdTimer = 2000; } catch (e:Dynamic) {}
}

function goodNoteHit(note:Dynamic, fieldID:Int = 0):Dynamic return Function_Stop;
function opponentNoteHit(note:Dynamic, fieldID:Int = 0):Dynamic return Function_Stop;
