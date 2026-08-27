import CoreGraphics
import Foundation
import IOKit.hid

/// Detects physical trackpad button presses via IOHIDManager and synthesizes
/// otherMouseDown/Up events when the qualifying finger count is on the trackpad.
///
/// Using IOHIDManager instead of a CGEvent tap means TFD-generated leftMouseDown
/// events (which live at the CGEvent layer) are never intercepted or mutated.
/// Only real hardware button-press events — invisible to Three Finger Drag — reach
/// this handler, eliminating the TFD conflict entirely.
@MainActor
final class HIDClickHandler {
  static let shared = HIDClickHandler()
  private init() {}

  /// Minimum duration (seconds) that the qualifying finger count must be continuously
  /// present before a physical button press is converted to a middle click.
  /// Filters out pressure-deformation transients during 2-finger clicks, which rarely
  /// last longer than a few milliseconds. Matches the tap-to-click arming window.
  private static let minPressDuration: TimeInterval = 0.060

  private var manager: IOHIDManager?
  /// True when we synthesized an otherMouseDown for the current button press;
  /// gates the matching otherMouseUp so orphaned releases are ignored.
  private var wasConverted = false

  func start() {
    guard manager == nil else {
      log.info("HIDClickHandler already running.")
      return
    }

    let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

    // Match pointer/mouse HID devices: built-in trackpad, Magic Trackpad, Magic Mouse.
    IOHIDManagerSetDeviceMatchingMultiple(mgr, [
      [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
       kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse],
      [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
       kIOHIDDeviceUsageKey: kHIDUsage_GD_Pointer],
    ] as CFArray)

    // The manager is scheduled on the main run loop so callbacks fire on the
    // main thread — @MainActor singletons are safe to access via assumeIsolated.
    IOHIDManagerRegisterInputValueCallback(mgr, { _, _, _, value in
      let elem = IOHIDValueGetElement(value)
      guard IOHIDElementGetUsagePage(elem) == UInt32(kHIDPage_Button),
            IOHIDElementGetUsage(elem) == 1 else { return }
      let pressed = IOHIDValueGetIntegerValue(value) != 0
      HIDClickHandler.shared.handleButtonChange(pressed: pressed)
    }, nil)

    IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

    let result = IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
    guard result == kIOReturnSuccess else {
      log.error("HIDClickHandler: IOHIDManagerOpen failed: \(result)")
      return
    }

    manager = mgr
    log.info("HIDClickHandler started.")
  }

  func stop() {
    if wasConverted {
      // Prevent a stuck middle button if stop() is called mid-click.
      postMouseEvent(type: .otherMouseUp)
      wasConverted = false
    }
    guard let mgr = manager else { return }
    IOHIDManagerUnscheduleFromRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
    manager = nil
    log.info("HIDClickHandler stopped.")
  }

  private func handleButtonChange(pressed: Bool) {
    if pressed {
      let state = GlobalState.shared
      guard state.threeDown,
            let since = state.threeDownSince,
            -since.timeIntervalSinceNow >= Self.minPressDuration,
            !wasConverted,
            !AppUtils.isIgnoredAppBundle() else { return }
      wasConverted = true
      state.naturalMiddleClickLastTime = Date()
      postMouseEvent(type: .otherMouseDown)
    } else if wasConverted {
      wasConverted = false
      postMouseEvent(type: .otherMouseUp)
    }
  }

  private func postMouseEvent(type: CGEventType) {
    let location = CGEvent(source: nil)?.location ?? .zero
    CGEvent(
      mouseEventSource: nil,
      mouseType: type,
      mouseCursorPosition: location,
      mouseButton: .center
    )?.post(tap: .cghidEventTap)
  }
}
