import Foundation

@MainActor
final class GlobalState {
  static let shared = GlobalState()
  private init() {
    Config.shared.$ignoredAppBundles.onSet {
      self.ignoredAppBundlesCache = $0
    }
  }

  var threeDown = false
  var naturalMiddleClickLastTime: Date?
  /// Timestamp of the first callback frame in which the qualifying finger count was detected.
  /// Used by HIDClickHandler to require a minimum stable contact duration before allowing
  /// a physical click to be converted, filtering out pressure-deformation transients.
  var threeDownSince: Date?

  func reset() {
    threeDown = false
    naturalMiddleClickLastTime = nil
    threeDownSince = nil
  }

  /// stored locally, since accessing the cache is more CPU-expensive than a local variable
  var ignoredAppBundlesCache = Config.shared.ignoredAppBundles
}
