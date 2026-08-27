# Changelog

All notable changes to MiddleClick are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

---

## [4.0.0] - 2026-04-27

---

## [3.3.0] - 2026-04-27

### Fixed

- **Three Finger Drag broken / click-to-drag not working** — Physical click middle-click detection previously worked by intercepting `leftMouseDown` events in a CGEvent tap and mutating them into `otherMouseDown`. Three Finger Drag (TFD) works by the OS synthesising a `leftMouseDown` at exactly the same layer, making it indistinguishable from a real hardware click; MiddleClick would consume the TFD event and break dragging entirely. Physical click detection is now driven by `IOHIDManager`, which receives actual hardware button-press events from the trackpad at the kernel HID layer. TFD synthesises events at the higher CGEvent/accessibility layer and is therefore invisible to `IOHIDManager` — TFD events pass through the system completely unmodified. (`HIDClickHandler.swift`, `Controller.swift`)

- **False middle clicks during two-finger scrolling or gestures** — A resting thumb or palm contact could bring the active finger count to three for longer than the 50 ms arming window, and a subsequent early finger lift would promote the tap-to-click state directly to `stableArmed`, firing a middle click when all contacts lifted. The early-lift promotion (`armed → stableArmed` on count drop) has been removed; the qualifying finger count must now remain at the threshold continuously until all contacts lift together. (`TouchHandler.swift`)

- **Conflict warning incorrectly shown for Three Finger Drag** — The startup conflict alert no longer warns about Three Finger Drag, which is compatible with MiddleClick following the physical click detection rewrite. (`Controller+Conflicts.swift`)

---

## [3.2.2] - 2026-04-27

### Fixed

- **Two-finger drag (click-hold + extra finger) broken** — On Force Touch trackpads, physically depressing the trackpad can cause a momentary spike in the raw multitouch finger count due to hardware pressure deformation. If this transient reading hit 3 fingers at the exact frame a `leftMouseDown` arrived, the event tap converted it to a middle-click event, silently breaking any click-and-drag operation (window resize, text selection, Finder drag, etc.). The physical-click interception path now mirrors the tap-to-click path: it requires the qualifying finger count to be stable across at least two consecutive touch frames before the conversion is armed (`physicalClickArmed`). A single-frame transient reading cannot trigger it. (`GlobalState.swift`, `TouchHandler.swift`, `Controller+Mouse.swift`)

---

## [3.2.1] - 2026-04-27

### Fixed

- **False middle click from accidental extra finger** — In tap-to-click mode, a brief accidental contact by a third finger during a two-finger scroll could emit a middle click (closing browser tabs, etc.). The tap-to-click path now requires the gesture to be sustained across at least two consecutive touch frames before it is armed, which rules out single-frame incidental contacts while still allowing genuine quick taps. (`TouchHandler.swift`)

- **Stuck `wasThreeDown` state after listener restart** — When the system woke from sleep or a display was reconfigured, the listeners were restarted but shared gesture state was not reset. If a three-finger physical press happened to be in-flight at restart time, `wasThreeDown` could remain `true` permanently, causing subsequent single-finger `leftMouseUp` events to be silently converted to `otherMouseUp`. This left applications thinking the mouse button was still held — producing stuck UI states, broken window resizing, and erratic single-click behaviour. Gesture state is now cleared whenever listeners stop. (`GlobalState.swift`, `Controller.swift`, `TouchHandler.swift`)

### Known limitations

- **Three Finger Drag conflict** — When the system "Three Finger Drag" accessibility gesture is enabled alongside MiddleClick (3-finger setting), the two conflict: TFD stops working and middle clicks may produce an unintended left click. See [`docs/three-finger-drag.md`](./three-finger-drag.md) for workarounds and technical background.
