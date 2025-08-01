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
  static func getIsSystemThreeFingerDragEnabled() -> Bool {
    return getTrackpadDriverSetting("TrackpadThreeFingerDrag")
  }
  static func getIsSystemThreeFingerTapEnabled() -> Bool {
//    This one actually returns either 0 or 2, but that converts to a boolean just fine.
    return getTrackpadDriverSetting("TrackpadThreeFingerTapGesture")
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
