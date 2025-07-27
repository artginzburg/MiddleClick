import CoreGraphics
import Foundation
import CoreFoundation

extension Controller {
  private static let state = GlobalState.shared
  private static let kCGMouseButtonCenter = Int64(CGMouseButton.center.rawValue)

  static let mouseEventHandler = CGEventController {
    _proxy, type, event, _refcon in

    let returnedEvent = Unmanaged.passUnretained(event)
    guard !AppUtils.isIgnoredAppBundle() else { return returnedEvent }

    if state.threeDown && (type == .leftMouseDown || type == .rightMouseDown) {
      state.wasThreeDown = true
      state.threeDown = false
      state.naturalMiddleClickLastTime = Date()
      event.type = .otherMouseDown

      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
    }

    if state.wasThreeDown && (type == .leftMouseUp || type == .rightMouseUp) {
      state.wasThreeDown = false
      event.type = .otherMouseUp

      event.setIntegerValueField(.mouseEventButtonNumber, value: kCGMouseButtonCenter)
    }
    return returnedEvent
  }
}
