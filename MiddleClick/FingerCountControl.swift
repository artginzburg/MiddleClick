import AppKit

class FingerCountControl: NSView {
  private let decrementButton = NSButton()
  private let incrementButton = NSButton()
  private let label = NSTextField()
  private let config = Config.shared

  private let minFingers = 2
  private let maxFingers = 5

  var onValueChanged: ((Int) -> Void)?

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
    updateLabel()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    let buttonSize: CGFloat = 30
    let buttonSpacing: CGFloat = 4
    let viewHeight: CGFloat = 22
    let viewWidth: CGFloat = 160
    let leftPadding: CGFloat = 14
    let rightPadding: CGFloat = -8

    // Set view frame
    self.frame = NSRect(x: 0, y: 0, width: viewWidth, height: viewHeight)

    setupLabel()
    setupButton(decrementButton, title: "−", action: #selector(decrementFingers))
    setupButton(incrementButton, title: "+", action: #selector(incrementFingers))

    // Create button stack
    let buttonStack = NSStackView(views: [decrementButton, incrementButton])
    buttonStack.orientation = .horizontal
    buttonStack.spacing = buttonSpacing
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(buttonStack)

    // Set fixed button sizes
    NSLayoutConstraint.activate([
      decrementButton.widthAnchor.constraint(equalToConstant: buttonSize),
      decrementButton.heightAnchor.constraint(equalToConstant: buttonSize),
      incrementButton.widthAnchor.constraint(equalToConstant: buttonSize),
      incrementButton.heightAnchor.constraint(equalToConstant: buttonSize),

      // Label positioning
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftPadding),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),

      // Button stack positioning
      buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightPadding),
      buttonStack.centerYAnchor.constraint(equalTo: centerYAnchor),

      // Label doesn't overlap buttons
      label.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: -8),
    ])
  }

  private func setupButton(_ button: NSButton, title: String, action: Selector) {
    button.title = title
    button.bezelStyle = .roundRect
    button.target = self
    button.action = action
    button.font = .systemFont(ofSize: 14)
    button.setButtonType(.momentaryPushIn)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.focusRingType = .none
  }

  private func setupLabel() {
    label.isEditable = false
    label.isBordered = false
    label.drawsBackground = false
    label.alignment = .left
    label.font = .menuFont(ofSize: 0)
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
  }

  private func updateLabel() {
    let fingers = config.minimumFingers
    label.stringValue = "Fingers: \(fingers)"
    decrementButton.isEnabled = fingers > minFingers
    incrementButton.isEnabled = fingers < maxFingers
  }

  @objc private func decrementFingers() {
    if config.minimumFingers <= minFingers { return }

    config.minimumFingers -= 1
    updateLabel()
    onValueChanged?(config.minimumFingers)
  }

  @objc private func incrementFingers() {
    if config.minimumFingers >= maxFingers { return }

    config.minimumFingers += 1
    updateLabel()
    onValueChanged?(config.minimumFingers)
  }

  func refresh() {
    updateLabel()
  }
}
