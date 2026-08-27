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

## Compatibility

**Three Finger Drag is compatible with MiddleClick.**

Physical click detection now uses `IOHIDManager`, which receives actual hardware button-press events from the trackpad at the kernel HID layer. TFD synthesises its drag events at the higher CGEvent/accessibility layer and is therefore completely invisible to `IOHIDManager` — TFD events pass through the system unmodified.

## Related problems

- MiddleClick conflicts with the "Tap with Three Fingers" setting of "Look up & data detectors"
  - Workaround from [#52](https://github.com/artginzburg/MiddleClick/issues/52): setting "Look up & data detectors" _to_ "Tap with Three Fingers" actually _blocks_ the unintended left click, at the cost of a brief "Look up" popup appearing sometimes.

---

## Historical context (pre-v3.3)

In v3.0–v3.2, physical click detection worked by intercepting `leftMouseDown` events in a CGEvent tap and mutating them into `otherMouseDown`. TFD works by the OS synthesising a `leftMouseDown` at exactly the same layer — making it indistinguishable from a real hardware click. MiddleClick would consume the TFD event and break dragging entirely.

### Related issues (historical)

- [#125](https://github.com/artginzburg/MiddleClick/issues/125) — TFD broke in v3.0 (root cause analysis)
- [#52](https://github.com/artginzburg/MiddleClick/issues/52) — left click fires alongside middle click (workarounds, user reports across Ventura/Sonoma/Sequoia)
- [#48](https://github.com/artginzburg/MiddleClick/issues/48) — TFD blocked entirely (commit `004510c` reference)
- [#34](https://github.com/artginzburg/MiddleClick/issues/34) — left click always fires with TFD active
- [#145](https://github.com/artginzburg/MiddleClick/issues/145) — window dragging and text selection broken in v3.1 (these are clearly TFD features)
- [#96](https://github.com/artginzburg/MiddleClick/issues/96) — RMB + LMB triggering middle click (possibly related)
