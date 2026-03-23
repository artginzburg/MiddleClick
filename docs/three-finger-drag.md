# Three Finger Drag

## What is TFD?

It is an optional built-in trackpad gesture.

#### Terms

- left/right click = primary/secondary click

#### Usage

You can use TFD just like you would hold a primary click, for example:

- Move windows
- Select text
- Drag items in Finder

#### Dragging style description

Drag an item with three fingers; dragging stops when you lift your fingers.

#### Turning on/off

The easiest way to get to it is Spotlight Search (copy-paste):

```
Three Finger Drag
```

> The full path is `System Settings > Accessibility > Pointer Control > Trackpad Options... > Dragging style`

## Incompatibility

TFD conflicts with MiddleClick, when using it with 3 fingers (default setting).

1. An intended middleclick is going to cause both an unintended left click and the middle click.
2. Three Finger Drag itself is not going to work at all.
   - With MiddleClick v2.x, it will work, but is going to cause the left+middle click problem described in point 1, making MiddleClick unusable.

## Known workarounds

- Change MiddleClick `fingers` setting to 4.
- Choose to `Ignore Finder` in the status menu of MiddleClick.
  > This obviously only works for Finder, but you can do that for other apps for which you know you need TFD more than MiddleClick.
- Opt in for [another "Dragging style"](#other-dragging-styles).

## Other "Dragging styles"

These options also make your primary tap take longer to register, as a side-effect. For me that's a deal-breaker, as I need my taps immediately.

- _Without Drag Lock_: Double-tap an item, then drag it without lifting your finger after the second tap; when you lift your finger, the item stops moving.
  - The item can still be dragged for a fraction of a second (so you can reposition your finger if it’s at the edge of the trackpad). To immediately prevent further dragging, tap the trackpad once.
- _With Drag Lock_: Double-tap an item, then drag it without lifting your finger after the second tap; dragging continues when you lift your finger, and stops when you tap the trackpad once.

## Related problems

- MiddleClick conflicts with the "Tap with Three Fingers" setting of "Look up & data detectors"
  - Workaround from [#52](https://github.com/artginzburg/MiddleClick/issues/52): setting "Look up & data detectors" _to_ "Tap with Three Fingers" actually _blocks_ the unintended left click, at the cost of a brief "Look up" popup appearing sometimes.

---

## Technical context (read before trying to fix)

### Why it broke in v3.0

In v2.7, `mouseCallback` only ran when "Tap to Click" was **disabled** (the old `needToClick` check). Most TFD users had "Tap to Click" enabled, so `mouseCallback` never interfered with TFD.

v3.0 removed this condition — `mouseCallback` now always runs. This is what introduced the regression. See [#125](https://github.com/artginzburg/MiddleClick/issues/125).

### Root cause

`mouseCallback` listens for left mouse down/up events when 3 fingers are on the trackpad. Three Finger Drag does the exact same thing — it emulates left mouse down when 3 fingers touch, and left mouse up when they lift. There is no known way to distinguish a TFD-emulated event from a real user click.

### Ideas for a fix

1. **Detect TFD and disable `mouseCallback`** — the old v2.7 logic worked because it effectively did this. If the app can detect that TFD is enabled in System Settings, it could skip `mouseCallback` and rely solely on `touchCallback`. The touch callback could then use finger pressure (>= 1) to detect a physical click instead of listening for mouse events. Error-prone but worth exploring. ([#125 comment](https://github.com/artginzburg/MiddleClick/issues/125))

2. **Check commit `004510c`** — apparently not all commits from previous contributors were merged. This commit may contain relevant logic. ([#48 comment](https://github.com/artginzburg/MiddleClick/issues/48))

3. **Study BetterTouchTool** — multiple users confirm BTT's 3-finger click does not conflict with TFD. Unclear how they achieve this. ([#48](https://github.com/artginzburg/MiddleClick/issues/48))

### Related issues

- [#125](https://github.com/artginzburg/MiddleClick/issues/125) — TFD broke in v3.0 (root cause analysis)
- [#52](https://github.com/artginzburg/MiddleClick/issues/52) — left click fires alongside middle click (workarounds, user reports across Ventura/Sonoma/Sequoia)
- [#48](https://github.com/artginzburg/MiddleClick/issues/48) — TFD blocked entirely (commit `004510c` reference)
- [#34](https://github.com/artginzburg/MiddleClick/issues/34) — left click always fires with TFD active
- [#145](https://github.com/artginzburg/MiddleClick/issues/145) — window dragging and text selection broken in v3.1 (these are clearly TFD features)
- [#96](https://github.com/artginzburg/MiddleClick/issues/96) — RMB + LMB triggering middle click (possibly related)
