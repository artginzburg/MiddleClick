import CoreGraphics
import Foundation

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

//    problem with the current logic:
//    when middle-tapping, while Three Finger Drag is active, the first event that is sent is a left mouse down, and only then middle mouse down.
//    I want to make it so that the left mouse down is not sent when middle-tapping is certain.

    if state.allowClicks && state.threeDown && (type == .leftMouseDown || type == .rightMouseDown) {
      print("firing middle down")
      state.wasThreeDown = true
      event.type = .otherMouseDown
      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
      state.threeDown = false
      state.naturalMiddleClickLastTime = Date()
      return returnedEvent
    }

    if state.wasThreeDown && (type == .leftMouseUp || type == .rightMouseUp) {
      print("firing middle up")
      state.wasThreeDown = false
      event.type = .otherMouseUp
      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
      return returnedEvent
    }

    print("click event passed through, type:", type.rawValue)

    return returnedEvent
  }
}

class MouseEventHandler {
  private var currentEventTap: CFMachPort?

  func registerMouseCallback(callback: CGEventTapCallBack) -> Bool {
    currentEventTap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: .from(
        .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp
      ),
      callback: callback,
      userInfo: nil
    )

    if let tap = currentEventTap {
      RunLoop.current.add(tap, forMode: .common)
      CGEvent.tapEnable(tap: tap, enable: true)
    } else {
      return false
    }

    return true
  }

  func unregisterMouseCallback() {
    guard let eventTap = currentEventTap else {
      log.info("Could not find the event tap to remove")
      return
    }

    // Disable the event tap first
    CGEvent.tapEnable(tap: eventTap, enable: false)

    // Remove and release the run loop source
    RunLoop.current.remove(eventTap, forMode: .common)

    // Release the event tap
    currentEventTap = nil
  }
}

fileprivate extension CGEventMask {
  static func from(_ types: CGEventType...) -> Self {
    var mask = 0

    for type in types {
      mask |= (1 << type.rawValue)
    }

    return Self(mask)
  }
}
