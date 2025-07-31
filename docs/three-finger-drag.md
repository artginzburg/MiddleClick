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

- MiddleClick conflicts with the "Tap with Three Fingers" setting of "Look up & data selectors"

Opened issues:

- https://github.com/artginzburg/MiddleClick/issues/145
- https://github.com/artginzburg/MiddleClick/issues/125
- https://github.com/artginzburg/MiddleClick/issues/96
- https://github.com/artginzburg/MiddleClick/issues/48
- https://github.com/artginzburg/MiddleClick/issues/52
- https://github.com/artginzburg/MiddleClick/issues/34
