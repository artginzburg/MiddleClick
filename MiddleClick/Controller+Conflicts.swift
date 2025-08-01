import Foundation
import AppKit

extension Controller {
  private static let config = Config.shared

  func checkForConflicts() {
    accessibilityMonitor.addListener { becameTrusted in
      guard becameTrusted else { return }

      let mayConflictByFingers = Self.config.minimumFingers == 3
      guard mayConflictByFingers else { return }

      let threeFingerDragConflict = SystemPermissions.getIsSystemThreeFingerDragEnabled()
      let threeFingerTap = SystemPermissions.getIsSystemThreeFingerTapEnabled()
      let threeFingerTapConflict = threeFingerTap && Self.config.tapToClick

      guard threeFingerDragConflict || threeFingerTapConflict else { return }

      let both = threeFingerDragConflict && threeFingerTapConflict

      let alert = AppUtils.warningAlert(
        title: "Conflicting gesture\(both ? "s" : "")",
        message: """
Some optional gestures on your Mac won't work properly with MiddleClick.
Turn them off in System Settings, change MiddleClick's "fingers" setting to 4, or apply the workarounds below:
\(threeFingerDragConflict ? """

Dragging style: "Three Finger Drag"
Issue — won't function, also adds an unintended left click to any middle click.
Workarounds — Opt in for another Dragging style, or Choose to 'Ignore Finder' in the status menu of MiddleClick.
""" : "")
\(threeFingerTapConflict ? """

Look up & data detectors: "Tap with Three Fingers"
Issue — will fire simultaneously with MiddleClick.
Workarounds — Disable 'Tap to click' in the status menu of MiddleClick.
""" : "")
"""
      )
      let button = alert.addButton(withTitle: "Read more...")
      button.action = #selector(self.openConflictingGesturesDocs)
      button.target = self

      alert.runModal()
    }
  }

  @objc private func openConflictingGesturesDocs() {
    if let url = URL(string: "https://github.com/artginzburg/MiddleClick/blob/c9dfda78b8a481a173381ca35a0bd1108afc1bbd/docs/three-finger-drag.md#three-finger-drag") {
      NSWorkspace.shared.open(url)
    }
  }
}
