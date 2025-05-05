import CoreGraphics
import Foundation
import CoreFoundation

extension Controller {
  private static let state = GlobalState.shared
  private static let kCGMouseButtonCenter = Int64(CGMouseButton.center.rawValue)

  func registerMouseCallback() {
    if !Self.mouseEventHandler.registerMouseCallback(callback: Self.mouseCallback) {
      log.info("Couldn't create event tap (check accessibility permission)")
    }
  }

  private static let mouseCallback: CGEventTapCallBack = {
    proxy, type, event, refcon in
    let returnedEvent = Unmanaged.passUnretained(event)
    guard !AppUtils.isIgnoredAppBundle() else { return returnedEvent }
    
    if state.threeDown && (type == .leftMouseDown || type == .rightMouseDown) {
      state.wasThreeDown = true
      event.type = .otherMouseDown
      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
      state.threeDown = false
      state.naturalMiddleClickLastTime = Date()
    }

    if state.wasThreeDown && (type == .leftMouseUp || type == .rightMouseUp) {
      state.wasThreeDown = false
      event.type = .otherMouseUp
      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
    }
    return returnedEvent
  }
}

class MouseEventHandler {
    private var eventTap: CFMachPort?
    private var runLoopSrc: CFRunLoopSource?

    func registerMouseCallback(callback: CGEventTapCallBack) -> Bool {
        // If we already have a valid tap, don’t install another one
        if eventTap != nil && CFMachPortIsValid(eventTap) && runLoopSrc != nil {
             log.info("Mouse callback already registered.")
             return true
        }

        // Ensure any previous state is cleaned up before creating a new one
        unregisterMouseCallback()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: .from(
                .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp
            ),
            callback: callback,
            userInfo: nil
        ) else {
            log.error("Failed to create event tap.")
            return false
        }

        guard let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            log.error("Failed to create RunLoop source for event tap.")
            CFMachPortInvalidate(tap) // Clean up the tap if source creation fails
            return false
        }

        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSrc = src

        log.info("Successfully registered mouse callback.")
        return true
    }


    func unregisterMouseCallback() {
        // Use guard to safely unwrap and validate the eventTap
        guard let tap = eventTap, CFMachPortIsValid(tap) else {
            // This block executes if eventTap is nil OR if eventTap exists but is invalid.
            // We can add specific logging if needed, but the main goal is cleanup.
            if eventTap != nil {
                // This means eventTap existed but was invalid
                log.info("Event tap was invalid, cleaning up.")
            } else {
                // This means eventTap was nil
                // log.info("No event tap found to unregister (was nil).") // Optional logging
            }

            // Ensure state is clean regardless of why the guard failed
            eventTap = nil
            runLoopSrc = nil // If the tap is gone/invalid, the source is useless
            return // Exit the function
        }

        // --- If guard passes, 'tap' is guaranteed non-nil and valid ---

        // Disable the tap first
        CGEvent.tapEnable(tap: tap, enable: false)

        // Remove the source from the run loop *if it exists*
        // (It should exist if 'tap' was valid, but check for safety)
        if let src = runLoopSrc {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
            // CFRunLoopRemoveSource handles releasing the source
            self.runLoopSrc = nil // Clear our reference
        } else {
             log.info("RunLoop source was unexpectedly nil during unregister for a valid tap.")
        }

        // Invalidate the underlying Mach port
        CFMachPortInvalidate(tap)
        // CFMachPortInvalidate handles releasing the port
        self.eventTap = nil // Clear our reference

        log.info("Successfully unregistered mouse callback.")
    }

    deinit {
        log.info("MouseEventHandler deinit: ensuring callback is unregistered.")
        unregisterMouseCallback()
    }
}

fileprivate extension CGEventMask {
    static func from(_ types: CGEventType...) -> Self {
        var mask: UInt64 = 0
        
        for type in types {
            mask |= (1 << type.rawValue)
        }

        return Self(mask)
    }
}
