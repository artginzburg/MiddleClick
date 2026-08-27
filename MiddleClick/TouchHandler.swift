import MoreTouchCore
import MultitouchSupport

@MainActor class TouchHandler {
  static let shared = TouchHandler()
  private static let config = Config.shared
  private init() {
    Self.config.$tapToClick.onSet {
      self.tapToClick = $0
    }
    Self.config.$minimumFingers.onSet {
      Self.fingersQua = $0
    }
  }

  /// stored locally, since accessing the cache is more CPU-expensive than a local variable
  private var tapToClick = config.tapToClick

  private static var fingersQua = config.minimumFingers
  private static let allowMoreFingers = config.allowMoreFingers
  private static let maxDistanceDelta = config.maxDistanceDelta
  private static let maxTimeDelta = config.maxTimeDelta

  /// Minimum duration (seconds) that the qualifying finger count must be
  /// continuously held before the tap-to-click arming state is considered
  /// stable. If the count drops below the threshold before this time has
  /// elapsed, the arming state is reset so the gesture cannot emit a middle
  /// click. This prevents a brief accidental contact (e.g. a thumb edge
  /// brushing the trackpad during a 2-finger tap) from triggering a false
  /// middle click. A real 3-finger tap lasts well above 50 ms; accidental
  /// contacts from hardware deformation or palm touch are typically <2 frames
  /// (~16 ms at 120 Hz, ~33 ms at 60 Hz).
  private static let minTapQualifyingDuration: TimeInterval = 0.050

  // MARK: - Tap-to-click state machine

  /// Phases of a tap-to-click middle-click gesture.
  ///
  /// Happy-path transitions for a genuine 3-finger tap:
  /// ```
  /// idle → tracking → firstQualifyingFrame → armed → stableArmed → (fire)
  /// ```
  /// A brief accidental contact resets back to `tracking`; toggling
  /// tap-to-click off mid-gesture or finishing a gesture resets to `idle`.
  private enum TapClickState {
    /// No gesture is in progress.
    case idle
    /// Fingers are down but the qualifying count has not been detected yet,
    /// or the state was reset mid-gesture by a brief accidental contact.
    case tracking
    /// First qualifying frame seen. `qualifyingSince` marks when the
    /// qualifying count was first detected; the next qualifying frame
    /// transitions to `armed`.
    case firstQualifyingFrame(qualifyingSince: Date)
    /// Two or more qualifying frames seen. The count has not yet been
    /// continuously present for `minTapQualifyingDuration`.
    case armed(qualifyingSince: Date)
    /// Armed **and** the qualifying count has been stable for at least
    /// `minTapQualifyingDuration`. This is the only state from which a
    /// middle click may be emitted.
    case stableArmed
  }

  private var tapState: TapClickState = .idle
  private var touchStartTime: Date?
  private static var lastEmulatedMiddleClickTime: Date?
  private var middleClickPos1: SIMD2<Float> = .zero
  private var middleClickPos2: SIMD2<Float> = .zero

  private let touchCallback: MTFrameCallbackFunction = {
    _, data, nFingers, _, _ in
    guard !AppUtils.isIgnoredAppBundle() else { return }

    let state = GlobalState.shared

    // Count only fingers genuinely pressing the trackpad. Hover (StartInRange,
    // HoverInRange) and linger (LingerInRange, OutOfRange) stages are excluded so
    // a resting palm or a barely-touching finger cannot inflate the count and
    // trigger an accidental middle-click.
    let activeTouches: [MTTouch]
    if nFingers > 0, let data {
      activeTouches = UnsafeBufferPointer(start: data, count: Int(nFingers)).filter {
        $0.stage == .makeTouch || $0.stage == .touching || $0.stage == .breakTouch
      }
    } else {
      activeTouches = []
    }
    let activeCount = Int32(activeTouches.count)

    let currentThreeDown =
      allowMoreFingers ? activeCount >= fingersQua : activeCount == fingersQua

    // Track when the qualifying count first becomes stable so HIDClickHandler
    // can gate physical-click conversion on a minimum contact duration.
    if currentThreeDown && !state.threeDown {
      state.threeDownSince = Date()
    } else if !currentThreeDown {
      state.threeDownSince = nil
    }

    state.threeDown = currentThreeDown

    let handler = TouchHandler.shared

    guard handler.tapToClick else {
      // If tap-to-click is disabled while a gesture is in flight, handleTouchEnd
      // will never be called for that gesture, leaving touchStartTime set and
      // arming flags from a previous 3-finger tap intact. Clean up now so no
      // stale state bleeds into the next gesture.
      if handler.touchStartTime != nil { handler.reset() }
      return
    }

    // Fire tap-to-click as soon as all real contacts leave the trackpad surface,
    // even if hover/linger entries still appear in the callback data.
    guard activeCount != 0 else {
      handler.handleTouchEnd()
      return
    }

    let isTouchStart = handler.touchStartTime == nil
    if isTouchStart {
      handler.touchStartTime = Date()
      handler.tapState = .tracking
      handler.middleClickPos1 = .zero
    }

    // Advance the tap-to-click state machine based on the current finger count.
    // The qualifying count (currentThreeDown) must be continuously present for
    // minTapQualifyingDuration before the state reaches stableArmed, which is
    // the only state from which a middle click may be emitted.
    if currentThreeDown {
      switch handler.tapState {
      case .tracking:
        handler.tapState = .firstQualifyingFrame(qualifyingSince: Date())
      case .firstQualifyingFrame(let since):
        if -since.timeIntervalSinceNow >= minTapQualifyingDuration {
          handler.tapState = .stableArmed
        }
      case .armed(let since):
        if -since.timeIntervalSinceNow >= minTapQualifyingDuration {
          handler.tapState = .stableArmed
        }
      case .stableArmed, .idle:
        break
      }
    } else {
      switch handler.tapState {
      case .firstQualifyingFrame:
        // Qualifying count dropped before a second frame was seen — accidental.
        handler.resetMiddleClick()
      case .armed:
        // Qualifying count dropped before all fingers lifted together — reset.
        // Promoting to stableArmed here would cause false clicks when one finger
        // lifts slightly early during a scroll or drag gesture.
        handler.resetMiddleClick()
      case .tracking, .stableArmed, .idle:
        break
      }
    }

    guard currentThreeDown else { return }

    handler.processTouches(activeTouches)

    return
  }

  private func processTouches(_ touches: [MTTouch]) {
    if case .firstQualifyingFrame(let since) = tapState {
      // First qualifying frame: snapshot initial positions and transition to armed.
      // Use up to fingersQua touches so the accumulated sum has a consistent
      // scale across frames, keeping maxDistanceDelta meaningful.
      middleClickPos1 = .zero
      for touch in touches.prefix(Self.fingersQua) {
        middleClickPos1 += SIMD2(touch.normalizedVector.position)
      }
      middleClickPos2 = middleClickPos1
      tapState = .armed(qualifyingSince: since)
    } else {
      // Subsequent qualifying frames: keep the end-position snapshot current so
      // the distance check in handleTouchEnd reflects where fingers are now.
      middleClickPos2 = .zero
      for touch in touches.prefix(Self.fingersQua) {
        middleClickPos2 += SIMD2(touch.normalizedVector.position)
      }
    }
  }

  private func resetMiddleClick() {
    tapState = .tracking
    middleClickPos1 = .zero
  }

  private func handleTouchEnd() {
    guard let startTime = touchStartTime else { return }

    let elapsedTime = -startTime.timeIntervalSinceNow

    // Capture gesture state before wiping. The gesture is unconditionally over
    // at this point — resetting here (not just on isTouchStart) guarantees no
    // state survives into the next gesture even if tapToClick is toggled off
    // mid-gesture (which skips this method, leaving touchStartTime set so
    // isTouchStart never fires for the next contact).
    let shouldFire: Bool
    if case .stableArmed = tapState { shouldFire = true } else { shouldFire = false }
    let pos1 = middleClickPos1
    let pos2 = middleClickPos2
    touchStartTime = nil
    tapState = .idle
    middleClickPos1 = .zero
    middleClickPos2 = .zero

    guard shouldFire && pos1.isNonZero && elapsedTime <= Self.maxTimeDelta else { return }

    let delta = pos1.delta(to: pos2)
    if delta < Self.maxDistanceDelta && !shouldPreventEmulation(gestureStart: startTime) {
      Self.emulateMiddleClick()
    }
  }

  private static func emulateMiddleClick() {
    if let lastTime = lastEmulatedMiddleClickTime,
       -lastTime.timeIntervalSinceNow < maxTimeDelta * 0.3 {
      return
    }
    lastEmulatedMiddleClickTime = .init()

    // get the current pointer location
    let location = CGEvent(source: nil)?.location ?? .zero
    let buttonType: CGMouseButton = .center

    postMouseEvent(type: .otherMouseDown, button: buttonType, location: location)
    postMouseEvent(type: .otherMouseUp, button: buttonType, location: location)
  }

  private func shouldPreventEmulation(gestureStart: Date) -> Bool {
    let state = GlobalState.shared

    if let naturalLastTime = state.naturalMiddleClickLastTime,
       -naturalLastTime.timeIntervalSinceNow <= Self.maxTimeDelta * 0.75 {
      return true
    }

    return false
  }

  private static func postMouseEvent(
    type: CGEventType, button: CGMouseButton, location: CGPoint
  ) {
    CGEvent(
      mouseEventSource: nil, mouseType: type, mouseCursorPosition: location,
      mouseButton: button
    )?.post(tap: .cghidEventTap)
  }

  private var currentDeviceList: [MTDevice] = []
  func registerTouchCallback() {
    currentDeviceList = MTDevice.createList()
    currentDeviceList.forEach { $0.registerAndStart(touchCallback) }
  }
  func unregisterTouchCallback() {
    currentDeviceList.forEach { $0.unregisterAndStop(touchCallback) }
    currentDeviceList.removeAll()
    reset()
  }

  private func reset() {
    tapState = .idle
    touchStartTime = nil
    middleClickPos1 = .zero
    middleClickPos2 = .zero
  }

  /// Called when the CGEvent tap is recovered after being disabled by the
  /// system (timeout or user-input). Resets tap-to-click gesture state so no
  /// stale arming from before the disable can fire on the next touch.
  func resetForTapRecovery() {
    reset()
  }
}

extension SIMD2 where Scalar == Float {
  init(_ point: MTPoint) { self.init(point.x, point.y) }
}
extension SIMD2 where Scalar: FloatingPoint {
  func delta(to other: SIMD2) -> Scalar {
    return abs(x - other.x) + abs(y - other.y)
  }

  var isNonZero: Bool { x != 0 || y != 0 }
}
