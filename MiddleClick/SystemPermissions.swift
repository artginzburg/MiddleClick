@preconcurrency import ApplicationServices

enum SystemPermissions {
  /// #### To quickly reset the permission, run:
  ///
  /// ```
  /// tccutil reset Accessibility art.ginzburg.MiddleClick
  /// ```
  static func detectAccessibilityIsGranted(forcePrompt: Bool) -> Bool {
    return AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): forcePrompt] as CFDictionary)
  }

  static func getIsSystemTapToClickEnabled() -> Bool {
    return getTrackpadDriverSetting("Clicking")
  }
  /// Not used yet.
  static func getIsSystemThreeFingerDragEnabled() -> Bool {
    return getTrackpadDriverSetting("TrackpadThreeFingerDrag")
  }

  private static func getTrackpadDriverSetting(_ key: String) -> Bool {
    return getBooleanSystemSetting("com.apple.driver.AppleBluetoothMultitouch.trackpad", key)
  }
  private static func getBooleanSystemSetting(_ bundleId: String, _ key: String) -> Bool {
    return CFPreferencesGetAppBooleanValue(
      key as CFString,
      bundleId as CFString,
      nil
    )
  }
}
