# Mod Engine Manual

Every single mod documented with some code snippets and samples, how to use them, and what their paramaters are.

Also includes information on everything else (other than mods), so shaders, render textures, splines, scenes, etc.

# The commands

These are how you change mods.

| Command | Shape | What it does |
|---|---|---|
| `to` | `to([beat, len, curve, value, mod, ...])` | Takes each mod to its value over `len` beats. |
| `by` | `by([beat, len, curve, delta, mod, ...])` | The same, relative to where the mod is already heading. |
| `jump` | `jump([beat, value, mod, ...])` | Puts it there at once. |
| `nudge` | `nudge([beat, delta, mod, ...])` | The same, relative. |
| `clear` | `clear([beat])` or `clear([beat, len, curve])` | Every mod back to rest, with `{only: [...]}` or `{except: [...]}`. |
| `at` | `at([beat, fn])` or `at([beat, "hook", [args]])` | Runs once. |
| `every` | `every([beat, len, fn])` | Runs each frame across the span. |
| `ramp` | `ramp([beat, len, curve, from, to, fn])` | Calls `fn(value)` each frame along the curve |
| `make` | `make([input, ..., fn, output, ...])` | Wires channels together, so one moves the others every frame. |
| `base` | `base([value, mod, ...])` | Where a mod rests before anything moves it. Called in `setup` |
| `preset` | `preset("split", beat)` | A named bundle of pairs. `definePreset(name, pairs)` makes one. |
| `layer` | `layer("name", fn)` | Every event the function writes belongs to that layer, which can be cleared as one. |
| `hook` | `hook("name", fn)` | Names a function so `at` and `every` can call it by string. |

| Option | Means |
|---|---|
| `{plr: 1}` or `{plr: [0, 2]}` | Which field or fields. |
| `{col: 2}` or `{col: [0, 2]}` | Which column or columns of a per column mod. A mod with no columns of its own, and one already spelled with a column, ignore it. |
| `{secs: true}` | To use seconds. |
| `{end: true}` | End on the second number. |
| `{from: 0}` | Where the mod starts from. |
| `{only: [...]}`, `{except: [...]}` | For `clear`. |
| `{defer: true}` | The event runs after every other event on the same beat. |
| `{persist: true}` | For `every`: the block keeps running past its length. |

## Curves

| Curve |
|---|
| `instant` |
| `linear` |
| `inQuad`, `outQuad`, `inOutQuad`, `outInQuad` |
| `inCubic`, `outCubic`, `inOutCubic`, `outInCubic` |
| `inQuart`, `outQuart`, `inOutQuart`, `outInQuart` |
| `inQuint`, `outQuint`, `inOutQuint`, `outInQuint` |
| `inSine`, `outSine`, `inOutSine`, `outInSine` |
| `inExpo`, `outExpo`, `inOutExpo`, `outInExpo` |
| `inCirc`, `outCirc`, `inOutCirc`, `outInCirc` |
| `inBack`, `outBack`, `inOutBack`, `outInBack` |
| `inElastic`, `outElastic`, `inOutElastic`, `outInElastic` |
| `inBounce`, `outBounce`, `inOutBounce`, `outInBounce` |

These curves end where they began:

| Shape |
|---|
| `arc` |
| `tri` |
| `bell` |
| `pop` |
| `tap` |
| `pulse` |
| `spike` |
| `impulse` |
| `popElastic`, `tapElastic` |
| `pulseElastic` |

If you wish to modify a given curve, you can as well:

| Builder | What it gives |
|---|---|
| `flip(c)` | The curve upside down: one minus it. |
| `blend(a, b)` | Halfway between two. |
| `repeat(c, times)` | The whole of it, that many times over the span. |
| `slice(c, from, to)` | The stretch between two points of it, stretched over the whole span. |
| `back(overshoot)` | An `outBack` that overshoots by as much as is asked. |
| `elastic(damp, count)` | An `outElastic` with its own damping and how many swings it takes. |

```haxe
to([16, 4, "outElastic", 100, "drunk"]);
to([24, 2, flip("outQuad"), 0, "drunk"]);
to([32, 4, repeat("arc", 3), 60, "bendX"]);
to([40, 2, elastic(1.2, 4), 45, "tiltZ"]);
```

### Custom curves

```haxe
// four steps
to([16, 4, function(t) return Math.floor(t * 4) / 4, 100, "drunk"]);

// an actual function
function snap(t:Float) { return 1 - Math.pow(1 - t, 6); }

to([32, 2, snap, 45, "tiltZ"]);
to([36, 2, snap, 0, "tiltZ"]);
```

---

# The mods

## Rate

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `rate` | yes | How fast notes travel. A percentage related to the original songs scrollspeed. | 100(%) |
| `rateFixed` | | Constant scroll mod, a BPM to dictate how fast notes travel. | 0(bpm) |
| `rateJitter` | yes | Every note gets a speed of its own, a little off the rest. | 0(%) |
| `freeze` | yes | Freezes notes at the event time (100%). | 0(%), `.at` 0 |
| `surge` | yes | Slower at the far-end, then faster at the short end. | 0(%) |
| `drag` | yes | Slows down the closer the notes get (opposite of `surge`) | 0(%) |
| `recoil` | yes | Notes boomerang from the opposite side to the current side. | 0(%) |
| `breathe` | yes | The lane's speed 'breathes' (swells). `.period` is how long one breath takes. | 0(%), `.period` 100 |
| `swell` | yes | Notes follow a wave when going down the lane. | 0(%), `.period` 100, `.size` 100 |

```haxe
to([0, 2,
    "outQuad",
    250, "rate"]); // Change rate to 250% (with easing outQuad)

to([4, 4,
	"outQuad",
	100, "rate"]); // Change rate to 100% (with easing outQuad)

to([8, 4,
    "inOutSine",
    100, "recoil"]); // Boomerang to 100% (with easing inOutSine)

to([12, 4,
    "inOutSine",
    0, "recoil"]); // Boomerang to 0% (with easing inOutSine)

jump([16, 100,
    "freeze"]); // Freeze all notes at beat 16

to([20, 1,
    "outQuad",
    0, "freeze"]); // Slowly fade out the freeze (with easing outQuad)
```

## Bending

Mods about bending the path of arrows.

| Family | Follows | Parameters |
|---|---|---|
| `bendX`, `bendY`, `bendZ` | the lane, so a note's place down it says where in the wave it is | `.shape`, `.period`, `.offset`, `.speed`, `.spread`, `.steps`, `.grow` |
| `bobX`, `bobY`, `bobZ` | the clock, so the whole lane moves as one | `.shape`, `.speed`, `.spread` |
| `swirlX`, `swirlY`, `swirlZ` | the lane, weaving the columns between each other | `.shape`, `.period`, `.offset` |
| `joltX`, `joltY`, `joltZ` | the beat, a shove that decays | `.period`, `.offset`, `.strength` |

### Bend Paramaters

| Paramater | Default |
|---|---|
| `.shape` | 1 |
| `.period` | 100 |
| `.offset` | 0 |
| `.spread` | 0 |
| `.steps` | 4 |
| `.grow` | 0 |
| `.strength` | 100 |
| `.speed` | 100 (0 on bend mods) |

`.shape` picks the wave: 0 flat, 1 sine, 2 tri, 3 saw, 4 square, 5 step (`.steps` says how many),
6 tan, 7 arc. `.grow` is an exponent, so 100 is linear, 200 parabolic and
300 cubic. `.spread` offsets each column from the last (At 0 all four columns move together. At 25 each column trails the one before it by a quarter wave. At 50, columns 0 and 2 move against columns 1 and 3), and `.speed` moves the wave along.

```haxe
jump([0, // instantly jump at beat 0
    2, "bendX.shape",  // shape to 2
    60, "bendX.period", // period to 60
	25, "bendX.spread",  // spread to 25
	100, "bendX.speed"]); // speed set to 100

to([0, 4, // start at beat 0, set len to 4
    "outQuad", // easing to outQuad
    100, "bendX"]); // bendX to 100

to([32, 8,
    "inOutSine",
    200, "drunk"]);

to([32, 8,
    "inOutSine",
    100, "tornado"]);
```

### Classical (ITG) bend mods

| Mod | Per Column | What it does |
|---|---|---|
|`drunk` | Yes | Makes the arrows look drunk (horizontally) |
|`tipsy` | Yes | Makes the arrows look drunk (vertically) |
|`tornado` | Yes | Arrows come in from the right side (left side on negatives) in a tornado fashion |
|`bumpy` | Yes | Bumps the arrows on each beat, can be in a direction: `bumpyX/Y/Z` |
|`beat` | Yes | Moves the arrows in a funky way on the beat |


## Placement

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `shiftX`, `shiftY`, `shiftZ` | yes | Moves the lane, receptors and notes together. 100 is a lane across. | 0(%) |
| `rowX`, `rowY`, `rowZ` | yes | Move the receptors. | 0(%) |
| `laneX`, `laneY`, `laneZ` | yes | Move each lane only. | 0(%) |
| `incomeAngle` | yes | Rotates the incoming path of a column. | 0(deg) |
| `incomeLeanX`, `incomeLeanY`, `incomeLeanZ` | yes | Leans a specific lane about its own receptor | 0(%) |
| `leanX`, `leanY`, `leanZ` | yes | Leans a column about the middle of the field (receptors included) | 0(deg) |

## Rotation

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `spinX`, `spinY`, `spinZ` | yes | Each note turns as it comes down.  | 0(deg), `.rate` 100, `.offset` 0 |
| `faceX`, `faceY`, `faceZ` | yes | Each note is rotated by this amount. | 0(deg), `.rate` 0, `.offset` 0 |
| `orient` | yes | Each note is rotated to face the direction it is heading. | 0(%) |
| `tiltX`, `tiltY`, `tiltZ` | | Rotate the whole field (in perspective, unlike the `lean` family). | 0(deg) |

## Fields

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `zoom` | | How big the field stands. `zoomX`, `zoomY` and `zoomZ` multiply the whole rather than replacing it. | 100(%) |
| `skewX`, `skewY` | yes | Shears the notes in a direction. | 0(%) |
| `fieldX`, `fieldY`, `fieldZ` | | Moves the whole field. | 0(%) |
| `rowCenterY`, `rowCenterX` | | 100 = center of each axis| 0(%) |
| `borrow` | | Borrow another fields mods | -1(off), number corresponds to the field to copy |
| `reset` | | Resets mods on the field | 0 |

```haxe
jump([16,
    0, "borrow"], {plr: 1}); // field 1 borrows the mods field 0 currently has

jump([48,
    100, "reset"], {plr: 1}); // every mod on field 1 back to its rest at once
```

A borrowing field keeps its own position. Ignoring `fieldX/Y/Z`, `tiltX/Y/Z`, `vanishX/Y`, and `rowCenterX/Y`

## Size

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `shrink` | | The field draws in toward its own center, spacing and all. | 0(%) |
| `pinch`, `pinchX`, `pinchY`, `pinchZ` | yes | The notes alone get smaller, the field's spacing unchanged. | 0(%) |
| `throb` | | Notes pulse in size along the lane. `.near` and `.far` are how strong the pulse is at each end. | 0(%), `.period` 100, `.offset` 0, `.near` 100, `.far` 100 |
| `taper` | | Notes shed size the further down the lane they are, `.curve` being the exponent on that distance. | 0(%), `.curve` 0 |

## Column arrangement

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `flipRow` | yes | Flips the scroll direction and receptors. | 0(%) |
| `mirror` | | The columns swap left for right. | 0(%) |
| `fold` | | Turns each column about the one beside it, the first two together and the last two together, so a hundred leaves the row as 2 1 4 3. (itg's invert) | 0(%), `.arc` 100 |

```haxe
jump([0,
    100, "flipRow1",
    100, "flipRow2"]); // reverse the 2nd and 3rd column (cross)

preset("split", 16); // the same pairs under a name

to([32, 2,
    "outQuad",
    100, "fold"]); // fold the columns round each other
```

## Alpha

Most mods have a `.fade` which corresponds to the "fade to white, then fade out" aspect. Set to `0` causes no white, while anything else specifies how long the white stays for (% of the fade out)

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `blind` | yes | Notes fade out. | 0(%), `.fade` 0 |
| `dim` | yes | The receptors fade out.| 0(%), `.fade` 0 |
| `ghost` | yes | Notes go white, and `.red`, `.green`, `.blue` say what color the whitened note is then taken to. | 0(%) |
| `receptorGhost` | yes | The same for the receptors, which `ghost` leaves alone. | 0(%)|
| `shade` | yes | Takes light away, with `.red`, `.green` and `.blue`. | 0(%)|
| `flicker` | yes | The blink, hard on and off. The value is the rate. `.red`, `.green`, `.blue` flash them to that color instead of hiding them. | 0(rate) |
| `fadeNear` | yes | Sudden | 0(%), `.offset` 0, `.fade` 0 |
| `fadeFar` | yes | Hidden | 0(%), `.offset` 0, `.fade` 0 |
| `fade` | | A wash over the whole **camera** (as in the actual game camera), with `.red`, `.green`, `.blue`. These are 0 to 255, not a percent. | 0 |
| `noteLight` | | How much a scenes lighting effects the notes.  | 100(%) |
| `hideBar`, `hideJudge` | | The health bar and the judgement. | 0(%) |
| `hideNotes` | yes | Hides notes between the start beat and end beat. | 0 |
| `hideHits` | | Hides the note hit animation on the receptor. | 0 |

```haxe
to([0, 4,
    "outQuad",
    100, "ghost",
    100, "ghost.red"]); // whiten the notes, then take the white to red

to([8, 2,
    "outQuad",
    100, "blind"]); // and then fade them out
jump([8,
    100, "blind.fade"]); // white first instead of plain fading
```

## The draw window

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `drawAhead` | yes | How far up the lane notes exist at all. | 1000, `.fade` 20 |
| `drawBehind` | yes | The same window past the receptors. | 100000, `.fade` 20 |
| `fadeTop` | | Gradually hides the note art (receptors, and notes), and reveals them (past 100). Then loops. A hold has no art of its own to run down, so the whole trail fades with its note rather than along its own length. | 0(%) |

When notes appear (based on the `drawAhead/drawBehind` `.fade`), they will either fade in (as fully white) then flush to no white at all (full transition), or fade to fully white - then fade out (full transition).

## Hold notes

| Mod | Per column | What it does | Default |
|---|---|---|---|
| `holdWidth` | yes | How wide the trail is. | 100(%) |
| `holdLength` | yes | How visually long a hold is. | 0(%) |
| `holdStraight` | yes | How much the hold adhears to the path. | 0(%) |
| `holdTwist` | yes | The trail turns about its own middle as it runs, the value being the degrees it turns over one screen of lane. | 0(deg) |
| `holdHue` | yes | The trail's color runs through the wheel, `.period` saying how fast. | 0(%), `.period` 100 |
| `holdGhost` | yes | The trail fades. | 0(%), `.fade` 0 |
| `holdHide` | yes | The trails are not drawn. | 0(%) |

## The path

`showPath` draws the arrow path of that column.

| Paramater | What it is | Default |
|---|---|---|
| `.width` | How wide the path is | 100 |

## Splines and corners

A spline is a set of points down the lane, and the path has to go through them.

This runs as it stands, from beat 0. A spline given points always grows out of a straight lane, so each shape is put away before the next one comes in.

```haxe
override function build():Void
{
    // the lane swinging out and back as it comes in
    spline([0, 4,
        "outQuad",
        [{at: 0}, {at: 50, x: 40}, {at: 100, x: -40, y: 20}]]);

    // back to 0
    spline([8, 4,
        "inSine",
        0, "spline"]);

    // the lanes fanning out from the receptors
    spline([16, 4,
        "outQuad",
        [[{x: 0}, {x: -60}], [{x: 0}, {x: -20}], [{x: 0}, {x: 20}], [{x: 0}, {x: 60}]]]);

    // eased back to part of that fan
    spline([24, 2,
        "inOutSine",
        50, "spline"]);

    spline([28, 4,
        "inSine",
        0, "spline"]);

    // the last two columns left straight
    spline([36, 4,
        "outQuad",
        60, [[{x: 25}, {x: -25}], [{x: 40}], [], []]]);

    spline([44, 4,
        "inSine",
        0, "spline"]);
}
```

| In a point | What it is | Default |
|---|---|---|
| `at` | How far down the lane the point sits. |  |
| `x`, `y`, `z` | Where the lane stands once a note has got there, in hundredths of a note. | 0 |
| `rotZ` | And how far it is turned there. | 0(deg) |

| Channel | What it is | Default |
|---|---|---|
| `spline` | Per column. What every point is multiplied by, so 0 is a straight lane and a hundred is the shape. | |
| `spline.xType`, `.yType`, `.zType`, `.rotZType` | 0 straight between points, 100 eased into both, 200 the curve through them. | 200 |
| `spline.tension` | How hard the curve leans through a point. A hundred is the plain curve, lower runs nearer straight. | 100(%) |
| `cornerX0..3`, `cornerY0..3`, `cornerZ0..3` | The field's own rectangle pulled about by its four corners, and `corner2X0` for one column of it. | 0(%) |

## Per column

How to change per column mods. A number on the end of a mod picks the column, 0 left, 1 down, 2 up and 3 right. This runs as it stands, from beat 0.

```haxe
override function build():Void
{
    // every column drunk
    to([0, 2,
        "outQuad",
        100, "drunk"]);

    // the left column pushed further on its own
    to([4, 2,
        "outQuad",
        200, "drunk0"]);

    // the middle two settle, the outer two keep going
    to([8, 2,
        "outQuad",
        0, "drunk"], {col: [1, 2]});

    // and the middle two bend opposite ways instead
    jump([8,
        3, "bendX.shape"]);
    to([8, 2,
        "outQuad",
        60, "bendX1",
        -60, "bendX2"]);

    // holds on the up column of the second field fade out
    to([12, 4,
        "outQuad",
        100, "holdHide2"], {plr: 1});

    // the outer two settle, named once
    to([16, 2,
        "outQuad",
        0, "drunk"], {col: [0, 3]});

    // one column, the same as "bendX1"
    to([16, 2,
        "outQuad",
        0, "bendX"], {col: 1});

    // the up column back to straight, and its holds back on the second field
    jump([20,
        0, "bendX2"]);
    to([20, 2,
        "outQuad",
        0, "holdHide2"], {plr: 1});
}
```

---

# Shaders

A chart declares a shader by name and a key.

```haxe
// tries to read wobble.frag, and wobble.vert (if either exists)
shader("wobble", "ui/shaders/wobble");
// tries to read crt.frag, and passthrough.vert
shader("crt", "ui/shaders/crt", "ui/shaders/passthrough");
```

Each half is a whole GLSL stage with its own `main`. The engine's own code is whereas a `#pragma header` would be (or at the top if you do not define it)

| In a vertex stage | Gives |
|---|---|
| `vec3 nfWorld()` | where this vertex stands in the world |
| `vec3 nfNormal()` | the way the surface faces |
| `vec2 nfUV()` | the texture coordinate |
| `vec4 nfTint()` | the color the engine worked out for it |
| `void nfPass(vec3 world)` | hands the world place on to the fragment stage |
| `vec4 nfProject(vec3 world)` | that place through the camera, for `gl_Position` |
| `vec4 nfVertex()` | the whole stock stage in one call |

| In a fragment stage | Gives |
|---|---|
| `vec2 nfUV()` | the texture coordinate |
| `vec4 nfSample()`, `vec4 nfSampleAt(vec2 uv)` | the texel |
| `float nfAlpha(vec4 texel)` | the alpha the engine worked out |
| `vec3 nfLook()`, `vec3 nfLit()` | the way the pixel is looked at, and its lighting |
| `vec4 nfShade(vec4 texel)` | that texel lit and tinted |
| `vec4 nfColor()` | the whole stock stage in one call |
| `vec2 nfPixel()` | one screen pixel in texture coordinates, for a filter |

| Global variables | What it is |
|---|---|
| `float nfTime` | the song's own time, in seconds |
| `float nfBeat` | and where that is on the beat |
| `vec2 nfSize` | how big the picture being drawn into is, in pixels |

| Flixel variables | What it is |
|---|---|
| `vec2 openfl_TextureCoordv` | the texture coordinate, the same as `nfUV()` |
| `sampler2D bitmap` | the picture being filtered |
| `flixel_texture2D(bitmap, uv)` | reading it, the same as `texture2D` |
| `vec2 openfl_TextureSize` | how big it is, in pixels |

A vertex shader (put onto the notes) moves each corner of the note in a sine wave:

```glsl
// vertex shader

#pragma header

uniform float uAmp;

void main(void) {
    vec3 world = nfWorld();

    // move the world position in a sine wave
    world.x += sin(world.y * 0.02 + nfTime * 3.0) * uAmp;

    // hand to the fragment shader
    nfPass(world);

    // set position
    gl_Position = nfProject(world);
}
```

A fragment shader that makes that changes the color to a rainbow effect:

```glsl
// fragment shader

#pragma header

uniform float uMuch;
uniform float uSpeed;
uniform float uSpread;

void main(void) {
    // the color the engine has it as
    vec4 came = nfShade(nfSample());

    float turn = nfUV().y * uSpread * 0.01 + nfTime * uSpeed * 0.01;
    vec3 wheel = 0.5 + 0.5 * cos((turn + vec3(0.0, 0.33333, 0.66667)) * 6.28318);

    // multiply it against what the engine had
    gl_FragColor = vec4(mix(came.rgb, came.rgb * wheel * 2.0, uMuch * 0.01), came.a);
}
```

## Easing shader values (uniforms)

```haxe
shader("rainbow", "ui/shaders/rainbow");
// set the fields (every single field) material to the rainbow shader
material("rainbow", "fields");

to([16, 2, "outQuad", 100, "rainbow.uMuch"]);
to([32, 4, "outQuad", 200, "rainbow.uSpeed"]);
```

## Materials

`material(shader, target)` draws something with the shader in place of the stock one. The nearest
target wins: a prop's own over the scene's, one field's over every field's, either over the one
for all.

```haxe
material("wobble", "field:1");
// all, fields, field:2, scene, prop:ball, stage, tex:echo
```

`filter(shader, target)` runs the shader over a finished picture instead. Several on one target
run in the order they were put on.

```haxe
filter("crt", "final");
// final, stage, scene, fields, field:2, tex:echo
```

```haxe
to([16, 4,
    "outQuad",
    60, "crt.uBend"]); // a uniform of the shader's own

jump([32,
    0, "crt.on"]); // the whole shader off
```

---

# Scenes

A scene is a class of its own that stands behind the rows: props, lighting, and a camera.

```haxe
// in the chart
scene("modchart_scene");
```

```haxe
import kade.hex.chart.Scene;

class ModchartScene extends Scene {
    public function new() {
        super("modchart_scene", 100); // id, priority (scene extends Module)
    }

    // this is ran once (when the scene is created)
    override public function declare() {
        stage3d();
        depth(20000);

        quad("wall", "ui/backgrounds/wall", 1600, 900);
        place("wall", 0, 0, 900);

        channel("wall.glow", 0);
    }

    override public function open() {} // the song starts
    override public function frame(beat:Float) {} // every frame
    override public function close() {} // the song ends
}
```

## What a scene can hold

| Call | What it makes |
|---|---|
| `sprite(name, path)` | a flat picture on the screen (no 3D) |
| `quad(name, path, wide, tall)` | a flat picture standing in the world (a billboard) |
| `box(name, path, wide, tall, deep, cuts)` | a textured cube |
| `plane(name, path, wide, deep, cols, rows, tiles)` | a floor, cut into a grid so it can be bent |
| `model(name, path, grow)` | an `.obj` model |
| `sky(name, path, size)` | a skybox |
| `ball(name, path, size, rings, segments)` | a ball about the eye with its picture laid round it |

Anything mentioned here also gets these properties: `.x`, `.y`, `.z`, `.rotX`, `.rotY`,
`.rotZ`, `.scaleX`, `.scaleY`, `.scaleZ`, `.skewX`, `.skewY`, `.skewZ` and `.alpha`.

| Call | What it does |
|---|---|
| `place(name, x, y, z)` | where it is placed |
| `size(name, much)` | how big it is |
| `order(name, z)` | what is drawn over what |
| `tint(name, r, g, b)` | a color over its picture |
| `cull(name, on)` | whether the far side of a surface is discarded |
| `wrap(name, on)` | whether its picture repeats past its edges |
| `follow(name, on)` | whether it rides the game camera |
| `followField(on)` | whether the scene's camera follows the field (default is on) |
| `lightField(on)` | whether the rows are lit by this scene's sun and lamps |
| `depth(much)` | how deep the world goes |
| `layer(name, [of])`, `onLayer(name, layer)` | groups props so one move carries all of them |
| `rideWith(name, other)` | ties one prop to another |
| `roundAt(name, across, down)` | how much of its picture a ball carries to the radian |

A scene can carry the stage picture itself: `stagePath()` is the path to hand a prop,
`stageWide()` and `stageTall()` say how big it is, and `stageDrawn(false)` disables the stage entirely.

| Drawn things | What is it |
|---|---|
| Notefield | The receptors and notes |
| Stage | The base game `stage` drawn by flixel |
| Scene | The scene that is drawn by mod-engine |
| Render Texture | A texture that takes an output drawn by mod-engine |

## Channels of its own

You can declare channels and then change them with events in your modchart. So custom things.

```haxe
// Define a channel
channel("wall.glow", 0);

// Grab the channel, and then read its value
var id = idOf("wall.glow");
var v:Float = readId(id);

// do something with the value...

// Watch multiple ids at once
watch([idA, idB, idC]);
var vals:Array<Float> = readWatched();
```

```haxe
// In a modchart (as any other event works):
to([2, 4,
    "outQuad",
    2, "wall.glow"]);
```

---

# 3D models

`model(name, path, grow)` loads an `.obj` file. Only `.obj` is read. `grow` scales it.

Supports transparency and simple material colors in the `.obj` format and `.mtl`.

```haxe
model("head", "ui/models/head", 40);
place("head", 0, -120, 600);
tint("head", 1, 0.9, 0.9);
cull("head", true);
```

```haxe
to([16, 8,
    "inOutSine",
    720, "head.rotY"]); // two turns about its own middle

to([16, 8,
    "outQuad",
    150, "head.scaleX",
    150, "head.scaleY",
    150, "head.scaleZ"]); // half again as big
```

---

# Skyboxes

`sky(name, path, size)` stands a box around the world, `size` being how far out its walls are
(20000 by default). It is drawn behind everything.

```haxe
sky("space", "ui/backgrounds/space");
```

`ball(name, path, size, rings, segments)` is the other way to fill the view: a ball with the
picture laid round it from the front and repeating. `roundAt(name, across, down)` says how much
of the picture it carries to the radian, so the picture keeps its own size straight ahead when
`across` is the radius over the picture's width.

```haxe
ball("stage", stagePath(), 1400);
follow("stage", false);
roundAt("stage", 1400 / stageWide(), 1400 / stageTall());
```

---

# Lighting

| Call | What it does |
|---|---|
| `sun(x, y, z, floor)` | one light from the sky (one direction) |
| `lamp(i, x, y, z, range, r, g, b, strength)` | a point of light that shines omni-directional. Currently limited to 4 lights. |
| `unlamp(i)` | takes that one away. |
| `lampOn(i, other)` | ties a lamp to a prop, so it rides with it. |
| `lightField(on)` | whether the rows take this lighting at all. |

```haxe
sun(-0.4, -1, -0.3, 0.25);
lamp(0, 0, -100, 400, 900, 1, 0.4, 0.4, 1.4);
lampOn(0, "head");
lightField(true);
```

Then the rows can be walked in and out of it.

```haxe
to([16, 4,
    "outQuad",
    0, "noteLight"]); // the rows stop taking the scene's light
```

---

# Render textures

`texture(name, options)` creates a render texture of the current options. What
it takes is any of `all`, `stage`, `scene`, `fields`, `field:2`, and or a another texture's name.

```haxe
texture("echo", {takes: ["fields"], size: 1, quad: true, locked: true, moved: true});
```

| Option | Means |
|---|---|
| `takes` | what the picture holds, in order |
| `size` | in screen pixels, one being the screen |
| `sharp` | true draws its picture at twice the size and brings it back down, which reads smoother on a quad standing larger than life. It costs four times the pixels on every pass the picture takes, so it is asked for rather than given: without it the picture is drawn at whatever size the frame itself is drawn at. |
| `quad` | false keeps the picture without drawing it, for a prop to wear or another texture to take |
| `locked` | holds the quad on the game's screen whatever the chart's camera does. Let go of it and the quad stands in the world, and the camera moves past it. |
| `moved` | true if it shouldn't draw the source, and false if it should (IE the render texture is either a copy of the source, *or* it becomes the source - visually at least.) |
| `part` | `[x, y, wide, tall]` in screen pixels: it takes only that rectangle instead of the whole screen.  |

```haxe
texture("corner", {takes: ["fields"], part: [0, 0, 640, 360], moved: true});
```

Every texture also has a `<name>.freeze`: which controls the framerate of the texture.

0 = no effect, 100 = fully frozen.

```haxe
jump([16, 50, "corner.freeze"]); // the picture runs at half the frame rate
to([16, 4, "outCubic", 400, "corner.x"]); // and slides away while it does
jump([20, 100, "corner.freeze"]); // stood still
jump([24, 0, "corner.freeze"]); // and live again
```

```haxe
to([8, 4,
    "outCubic",
    35, "echo.rotY",
    30, "echo.skewX"]); // turn and lean the quad

to([8, 4,
    "outCubic",
    -300, "echo.x"]); // and stand it to the left
```

## The cameras

There are three, and a chart asks for the ones it wants.

| Camera | Asked for by | Parts | What it moves |
|---|---|---|---|
| `gameCam` | `camera2d()` | `x`, `y`, `zoom`, `rotZ`, `shake` | Flixel camera, same as haxe basically. |
| `cam` | `stage3d()` | `x`, `y`, `z`, `rotX`, `rotY`, `rotZ`, `fov`, `shake` | The 3D camera in the scene |
| `worldCam` | the first `texture()` created | the same eight | The world camera (meta camera for render textures) |

Yes you can use gameCam inside of stage3d to control the original games camera.

```haxe

camera2d(); // gameCam.*

stage3d(0, 1, 1, 2.55); // cam.*

texture("echo", {takes: ["fields"], size: 1, quad: true, locked: true, moved: true}); // worldCam.*

to([16, 4,
    "outCubic",
    30, "gameCam.rotZ"]); // the whole picture leans, stage and all

to([16, 4,
    "outCubic",
    30, "cam.rotY"]); // the stage turns inside the picture

to([16, 4,
    "outCubic",
    30, "worldCam.rotY"]); // the picture itself turns, its content still
```

## World scenes

`worldScene(id)` just like worldCam, a meta scene outside (not effected by render textures)

```haxe
scene("scene"); // inside the textures
worldScene("frame_scene"); // around them
```

## A texture as a picture

`texturePath(name)` gives `@tex:name`, which a prop can use like any other picture, so a texture
can be laid round a ball or over a wall.

```haxe
texture("feed", {takes: ["fields"], size: 0.5, quad: false}); // render texture
quad("tv", texturePath("feed"), 640, 360); // placed on a quad
place("tv", -400, -100, 500);
```

## Shaders on render texture

A texture is a target like any other: `material("wobble", "tex:echo")` draws what goes into it
with that shader, and `filter("crt", "tex:echo")` runs one over the finished picture.

```haxe
shader("crt", "ui/shaders/crt");
filter("crt", "tex:echo");
to([24, 2,
    "outQuad",
    100, "crt.uBend"]);
```
