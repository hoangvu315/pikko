//
//  HueView.swift
//  Pikko
//
//  Created by Sandra & Johannes.
//

import UIKit

/// Ring view representing the hue.
internal class HueView: UIView {
    
    // MARK: - Private attributes.
    
    /// Horizontal offset for the start of the rectangle forming the hue ring.
    private var offset_x: CGFloat = 0.0
    
    /// Vertical offset for the start of the rectangle forming the hue ring.
    private var offset_y: CGFloat = 0.0
    
    /// Radius of the circular hue view.
    private var radius: CGFloat
    
    /// Width of the small rectangles that form the hue ring.
    private var borderWidth: CGFloat
    
    /// Height of the small rectangles that form the hue ring.
    private var borderHeight: CGFloat
    
    /// The circular UI control that can be dragged around.
    private var selector: UIView?
    
    /// Diameter of the selector.
    private var selectorDiameter: CGFloat
    
    /// The scale at which the selector enlargens when the user clicks on it and holds it.
    private var scale: CGFloat
    
    /// Wrapper View holding the ring UIView.
    private var hueRingView: UIView?
    
    private var centerCircle: UIView?
    
    private var percentageLabel: UILabel?
    
    // MARK: Public attributes.
    
    /// Delegate that writes back changes of the hue value.
    internal var delegate: HueDelegate?
    
    // MARK: - Initializer.
    
    /// Initializes a new hue ring view.
    ///
    /// - TODO: borderHeight is currently hardcoded.
    /// - Parameters:
    ///   - frame: a CGRect that defines the dimensions of the view.
    ///   - borderWidth: width of the hue ring.
    ///   - selectorDiameter: diameter of the movable hue selector.
    ///   - scale: the scale at which the selector enlargens when it is clicked.
    internal init(frame: CGRect, borderWidth: CGFloat, selectorDiameter: CGFloat, scale: CGFloat) {
        self.borderWidth = borderWidth
        self.borderHeight = 5
        self.radius = (frame.width-borderWidth)/2
        self.scale = scale
        self.offset_x = (frame.width-borderWidth)/2
        self.offset_y = (frame.height-borderHeight)/2
        self.selectorDiameter = selectorDiameter
        super.init(frame: frame)
        
        createHueRing()
        createInsideCircle()
        createSelector()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helper methods.
    
    /// Creates the selector which can be dragged around by the user.
    private func createSelector() {
        selector = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: selectorDiameter,
                                        height: selectorDiameter))
        
        selector?.center = CGPoint(x: (borderWidth)/2, y: offset_y)
        selector?.layer.cornerRadius = (selectorDiameter)/2
        selector?.isUserInteractionEnabled = true
        selector?.layer.borderWidth = 1
        selector?.layer.borderColor = UIColor.white.cgColor
        
        updateColor(point: (selector?.center)!)
        setUpGestureRecognizer()
        
        self.addSubview(selector!)
    }
    
    /// Creates and adds a longpress gesture recognizer to the selector.
    private func setUpGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectorPanned(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.0
        selector?.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    /// Handles the panning of the selector and prohibits it to leave hue ring.
    @objc func selectorPanned(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let location = panGestureRecognizer.location(in: self)

        let x = location.x - center.x
        let y = location.y - center.y
        let angle = atan2(x, y) - CGFloat.pi * 0.5
        updateColorTemp(angle: abs(atan2(x, y)))
        
        let position_y = sin(-1.0 * angle) * radius + center.x
        let position_x = cos(-1.0 * angle) * radius + center.y
        
        selector?.center = CGPoint(x: position_x, y: position_y)
        updateColor(point: (selector?.center)!)
        animate(panGestureRecognizer)
    }
    
    /// Animates the selector based on the current state of the gesture. Enlargens the
    /// selector when held and shrinks it after it has been released.
    private func animate(_ panGestureRecognizer: UIPanGestureRecognizer) {
        switch panGestureRecognizer.state {
        case .began:
            Animations.animateScale(view: selector!, byScale: scale)
        case .ended:
            Animations.animateScaleReset(view: selector!)
        default:
            break
        }
    }
    
    /// Update the current color of the Selector according to a specific point.
    ///
    /// - Parameters:
    ///     - point: the CGPoint at which the color should be taken from.
    private func updateColor(point: CGPoint) {
        var hue: CGFloat = 0
        
        if let color = ColorUtilities.getPixelColorAtPoint(point: point, sourceView: hueRingView!),
            let selector = selector {
            selector.backgroundColor = color
            color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        }
    }
    
    private func updateColorTemp(angle: CGFloat) {
        let temp = 6500 - Int(angle / CGFloat.pi * 3500)
        percentageLabel?.text = "\(temp)K"
        delegate?.didUpdateHue(hue: temp)
    }
    
    // MARK: - UI setup methods.
    
    /// Creates the hue ring for the given hue.
    private func createHueRing() {
        hueRingView = UIView(frame: self.frame)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = hueRingView!.frame
        gradientLayer.cornerRadius = min(hueRingView!.frame.width / 2.0, hueRingView!.frame.height / 2.0)
        gradientLayer.colors = [UIColor.init(red: 239/255, green: 195/255, blue: 128/255, alpha: 1).cgColor,
                                UIColor.init(red: 128/255, green: 192/255, blue: 227/255, alpha: 1).cgColor]
        hueRingView!.layer.addSublayer(gradientLayer)

        addSubview(hueRingView!)
    }
    
    func createInsideCircle() {
        centerCircle = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 100))
        centerCircle?.backgroundColor = .white
        centerCircle?.translatesAutoresizingMaskIntoConstraints = false
        hueRingView?.addSubview(centerCircle!)
        
        centerCircle?.centerXAnchor.constraint(equalTo: hueRingView!.centerXAnchor).isActive = true
        centerCircle?.centerYAnchor.constraint(equalTo: hueRingView!.centerYAnchor).isActive = true
        centerCircle?.widthAnchor.constraint(equalToConstant: 256).isActive = true
        centerCircle?.heightAnchor.constraint(equalToConstant: 256).isActive = true
        
        centerCircle?.layer.cornerRadius = 128
        
        percentageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        percentageLabel?.translatesAutoresizingMaskIntoConstraints = false
        centerCircle?.addSubview(percentageLabel!)
        
        percentageLabel?.font = percentageLabel!.font.withSize(28)
        percentageLabel?.textAlignment = .center
        percentageLabel?.centerXAnchor.constraint(equalTo: centerCircle!.centerXAnchor).isActive = true
        percentageLabel?.centerYAnchor.constraint(equalTo: centerCircle!.centerYAnchor).isActive = true
        percentageLabel?.widthAnchor.constraint(equalToConstant: 120).isActive = true
        percentageLabel?.heightAnchor.constraint(equalToConstant: 47).isActive = true
        percentageLabel?.text = "3000K"
    }
    
    /// Sets the hue sele≠ctor to a certain color.
    ///
    /// - Parameter color: UIColor for the selector position.
    internal func setColor(_ color: UIColor) {
        let angle = color.hue
        
        let position_y = sin(1.0 * angle * 2 * CGFloat.pi) * radius + center.x
        let position_x = cos(1.0 * angle * 2 * CGFloat.pi) * radius + center.y
        let newCenter = CGPoint(x: position_x, y: position_y)
        
        selector?.center = newCenter
        updateColor(point: newCenter)
    }
}
