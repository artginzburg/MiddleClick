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

  func start() {
    log.info("Starting listeners...")

    TouchHandler.shared.registerTouchCallback()
    observeWakeNotification()
    setupSessionHandling()
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
    if !isUserSessionActive {
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
    if isUserSessionActive {
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
//
// Always enabled: the multitouch session switching bug (#127) still reproduces
// on macOS 26.5 when MiddleClick runs in more than one logged-in user's session —
// concurrent multitouch device registrations from different sessions break frame
// delivery. Stopping listeners while the session is off-console is safe on every
// macOS version, so no version gate.

fileprivate extension Controller {
  /// Session state tracking variables (using static storage for simplicity)
  private static var _userSessionActive = true

  /// Public accessor for session state (used by scheduleRestart and restartListeners)
  var isUserSessionActive: Bool { Self._userSessionActive }

  /// Initialize session handling - call this from start()
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
    log.info("User session resigned active, stopping listeners")
    Self._userSessionActive = false
    restartTimer?.invalidate()
    restartTimer = nil

    DispatchQueue.main.async {
      self.stopUnstableListeners()
    }
  }

  @objc private func receiveSessionBecomeActiveNote(_ note: Notification) {
    log.info("User session became active, restarting listeners")
    Self._userSessionActive = true

    DispatchQueue.main.async {
      self.restartListeners()
    }
  }
}
