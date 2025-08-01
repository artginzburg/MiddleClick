import AppKit

enum AppUtils {
  static func getFocusedApp() -> NSRunningApplication? {
    return NSWorkspace.shared.frontmostApplication
  }

  /// Caveat: Depends on getFocusedApp(), but the cursor may actually be above a window that is not currently focused,
  /// in which case a middle-click will pass through to an "Ignored" application.
  @MainActor static func isIgnoredAppBundle(_ focusedApp: NSRunningApplication? = getFocusedApp()) -> Bool {
    guard let bundleId = focusedApp?.bundleIdentifier else { return false }
    return GlobalState.shared.ignoredAppBundlesCache.contains(bundleId)
  }

  @MainActor static func warningAlert(title: String, message: String) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
//    alert.runModal()
    return alert
  }
}
