import ConfigCore

final class Config: ConfigCore {
  required init() {
    Self.options.cacheAll = true
  }

  @UserDefault("fingers")
  var minimumFingers = 3

  @UserDefault var allowMoreFingers = false

  @UserDefault var maxDistanceDelta: Float = 0.05

  /// In milliseconds
  @UserDefault(transformGet: { $0 / 1000 })
  var maxTimeDelta = 300.0

  @UserDefault var tapToClick = SystemPermissions.getIsSystemTapToClickEnabled

  @UserDefault var ignoredAppBundles = Set<String>()
}
