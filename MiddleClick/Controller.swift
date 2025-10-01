import AppKit

// swiftlint:disable:next redundant_sendable
@MainActor final class Controller: PointerableObject, Sendable {
  private lazy var multitouchManager = IOMultitouchManager {
    self.scheduleRestart(2, reason: "Multitouch device added")
  }

  private var restartTimer: Timer?

  private static let fastRestart = false
  private static let wakeRestartTimeout: TimeInterval = fastRestart ? 2 : 10

  private static let immediateRestart = false

  /// Feature flag to enable/disable session handling for Fast User Switching.
  private static let enableSessionHandling = decideOnEnableSessionHandling()

  func start() {
    log.info("Starting listeners...")

    TouchHandler.shared.registerTouchCallback()
    observeWakeNotification()
    if Self.enableSessionHandling {
      log.info("Session handling enabled - will monitor Fast User Switching")
      setupSessionHandling()
    } else {
      log.info("Session handling disabled - macOS 15 handles session switching correctly")
    }
    multitouchManager.setupMultitouchListener()
    setupDisplayReconfigurationCallback()

    accessibilityMonitor.addListener { becameTrusted in
      if becameTrusted {
        _ = Self.mouseEventHandler.start()
      } else {
        trayMenu.isStatusItemVisible = true
        Self.mouseEventHandler.stop()
      }
    }

    checkForConflicts()
  }

  /// Schedule listeners to be restarted. If a restart is pending, discard its delay and use the most recently requested delay.
  func scheduleRestart(_ delay: TimeInterval, reason: String) {
    if Self.enableSessionHandling && !isUserSessionActive {
      restartLog.info("\(reason), but user session is inactive - skipping restart")
      return
    }
    restartLog.info("\(reason), restarting in \(delay)")
    restartTimer?.invalidate()
    restartTimer = Timer.scheduledTimer(
      withTimeInterval: Self.immediateRestart ? 0 : delay, repeats: false
    ) { _ in
      DispatchQueue.main.async {
        self.restartListeners()
      }
    }
  }

  func restartListeners() {
    log.info("Restarting now...")
    stopUnstableListeners()
    if !Self.enableSessionHandling || isUserSessionActive {
      startUnstableListeners()
      log.info("Restart success.")
    } else {
//      This logic should never be reached — just a safeguard.
      log.info("Restart completed - listeners remain stopped due to inactive session")
    }
  }

  private func startUnstableListeners() {
    TouchHandler.shared.registerTouchCallback()
    _ = Self.mouseEventHandler.start()
  }

  private func stopUnstableListeners() {
    TouchHandler.shared.unregisterTouchCallback()
    Self.mouseEventHandler.stop()
  }
}

fileprivate extension Controller {
  /// Callback for system wake up.
  /// Can be tested by entering `pmset sleepnow` in the Terminal
  @objc func receiveWakeNote(_ note: Notification) {
    scheduleRestart(Self.wakeRestartTimeout, reason: "System woke up")
  }

  func observeWakeNotification() {
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(receiveWakeNote),
      name: NSWorkspace.didWakeNotification,
      object: nil
    )
  }
}

fileprivate extension Controller {
  /// TODO:? is this restart necessary? I don't see any changes when it's removed, but keep in mind I've only spent 5 minutes testing different app and system states
  static let displayReconfigurationCallback:
  CGDisplayReconfigurationCallBack = { _, flags, userData in
    if flags.containsAny(of: .setModeFlag, .addFlag, .removeFlag, .disabledFlag) {
      Controller.from(pointer: userData).scheduleRestart(2, reason: "Display reconfigured")
    }
  }

  func setupDisplayReconfigurationCallback() {
    CGDisplayRegisterReconfigurationCallback(
      Self.displayReconfigurationCallback,
      rawPointer
    )
  }
}

fileprivate extension CGDisplayChangeSummaryFlags {
  func containsAny(of flags: CGDisplayChangeSummaryFlags...) -> Bool {
    flags.contains(where: contains)
  }
}

// MARK: - Session Handling for Fast User Switching

fileprivate extension Controller {
  /// Session state tracking variables (using static storage for simplicity)
  private static var _userSessionActive = true
  private static var _lastSessionChangeTime: Date = .distantPast

  /// Public accessor for session state (used by scheduleRestart and restartListeners)
  var isUserSessionActive: Bool { Self._userSessionActive }

  /// Enable for macOS versions that have the multitouch session switching bug.
  /// Disable for macOS 15.0+ (Sequoia) where Apple fixed the issue.
  ///
  /// This is actually not confirmed, but I can't reproduce issue #127 on macOS 15.7.
  private static func decideOnEnableSessionHandling() -> Bool {
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    if osVersion.majorVersion < 15 {
      return true
    }
    return false
  }

  /// Initialize session handling - call this from start() when feature is enabled
  func setupSessionHandling() {
    Self._userSessionActive = true
    observeSessionNotifications()
  }

  private func observeSessionNotifications() {
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(receiveSessionResignActiveNote),
      name: NSWorkspace.sessionDidResignActiveNotification,
      object: nil
    )
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(receiveSessionBecomeActiveNote),
      name: NSWorkspace.sessionDidBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func receiveSessionResignActiveNote(_ note: Notification) {
    let now = Date()
    guard now.timeIntervalSince(Self._lastSessionChangeTime) > 0.5 else {
      log.info("Ignoring session resign - too soon after last change")
      return
    }
    Self._lastSessionChangeTime = now

    log.info("User session resigned active, stopping listeners")
    Self._userSessionActive = false
    restartTimer?.invalidate()
    restartTimer = nil

    DispatchQueue.main.async {
      self.stopUnstableListeners()
    }
  }

  @objc private func receiveSessionBecomeActiveNote(_ note: Notification) {
    let now = Date()
    guard now.timeIntervalSince(Self._lastSessionChangeTime) > 0.5 else {
      log.info("Ignoring session become active - too soon after last change")
      return
    }
    Self._lastSessionChangeTime = now

    log.info("User session became active, starting listeners")
    Self._userSessionActive = true

    DispatchQueue.main.async {
      self.startUnstableListeners()
    }
  }
}
