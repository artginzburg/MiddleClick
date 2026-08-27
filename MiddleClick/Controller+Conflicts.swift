import Foundation
import AppKit

extension Controller {
  private static let config = Config.shared

  func checkForConflicts() {
    accessibilityMonitor.addListener { becameTrusted in
      guard becameTrusted else { return }

      let mayConflictByFingers = Self.config.minimumFingers == 3
      guard mayConflictByFingers else { return }

      let threeFingerTap = SystemPermissions.getIsSystemThreeFingerTapEnabled()
      let threeFingerTapConflict = threeFingerTap && Self.config.tapToClick

      guard threeFingerTapConflict else { return }

      let alert = AppUtils.warningAlert(
        title: "Conflicting gesture",
        message: """
Some optional gestures on your Mac won't work properly with MiddleClick.
Turn them off in System Settings, change MiddleClick's "fingers" setting to 4, or apply the workarounds below:

Look up & data detectors: "Tap with Three Fingers"
Issue — will fire simultaneously with MiddleClick.
Workarounds — Disable 'Tap to click' in the status menu of MiddleClick.
"""
      )
      let button = alert.addButton(withTitle: "Read more...")
      button.action = #selector(self.openConflictingGesturesDocs)
      button.target = self

      let updateFingersSettingButton = alert.addButton(withTitle: "Use four fingers to middleclick")
      updateFingersSettingButton.action = #selector(self.changeTo4FingersGesture)
      updateFingersSettingButton.target = self

      alert.runModal()
    }
  }

  @objc private func changeTo4FingersGesture(sender: NSButton) {
//    This is not a good way of forcing a modal to close.
    if let buttonCell = (sender.window?.accessibilityDefaultButton() as? NSButtonCell) {
      Config.shared.minimumFingers = 4
      buttonCell.performClick(nil)
    } else {
      log.error(
        "Could not find default button in window \(String(describing: sender.window)). Please report this as a bug."
      )
    }
  }

  @objc private func openConflictingGesturesDocs() {
    if let url = URL(string: "https://github.com/artginzburg/MiddleClick/blob/c9dfda78b8a481a173381ca35a0bd1108afc1bbd/docs/three-finger-drag.md#three-finger-drag") {
      NSWorkspace.shared.open(url)
    }
  }
}
