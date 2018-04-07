//
//  ContainerViewController.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 25.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit

/// This class is responsible for drawing the content of the playground. It controlles the layout and wires up the UI components as well as its delegates.
public final class ContainerViewController: UIViewController, ColorPickerViewDelegate {
    
    /// The view that displays the coordinate system and an image of CIE xyY plot. Also highlights a given color.
    private let coordinateView: CoordinateView = CoordinateView(frame: .zero)
    
    /// The color picker UI component. The saturation slider should be positioned below the wheel.
    private let colorPicker: ColorPickerView = ColorPickerView(frame: .zero, position: .bottom)
    
    /// The switch that lets the user chose between sRGB and P3 color space.
    private let colorSpaceSwitch: UISwitch = UISwitch()
    
    /// The label that explains what the P3 color space switch does.
    private let switchDescriptionLabel: UILabel = UILabel()
    
    /// The stack view, that contains the main UI components.
    private let stackView: UIStackView = UIStackView()
    
    /// The stack view that contains the switch and its description label.
    private let switchStackView: UIStackView = UIStackView()
    
    /// The stack view that contains the switchStackView and the openCameraButton.
    private let switchButtonStackView: UIStackView = UIStackView()
    
    /// The button that opens the CameraViewController when pressed.
    private let openCameraButton = GradientButton()
    
    /// The image view of the first decoration bird.
    private let bird1ImageView = UIImageView()
    
    /// The image view of the secons decoration bird.
    private let bird2ImageView = UIImageView()
    
    /// The image view of the third decoration bird.
    private let bird3ImageView = UIImageView()
    
    /// The background gradient layer.
    private let backgroundGradient = CAGradientLayer()
    
    /// A property that keeps trakc of the current color space. When the user flipps the P3 switch, this property gets updates, which will set the '''usesP3ColorSpace''' property of the ColorPickerView. Then, the tuned color will be interpreted as P3 color or sRGB value. *(Remember: HSB does not depend on the color space)*
    private var usesP3ColorSpace: Bool = false {
        didSet {
            colorPicker.usesP3ColorSpace = usesP3ColorSpace
        }
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupGradient()
        setupBirds()
        setup()
        updateUI(with: .red)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let initialColorComponents = UIColor.red.fromsRGBToxyY()
        coordinateView.updateColor(x: initialColorComponents.x, y: initialColorComponents.y, Y: initialColorComponents.z)
        
        updateUIAccordingToViewOrientation(to: view.frame.size)
    }
    public override func viewDidLayoutSubviews() {
        
        updateUIAccordingToViewOrientation(to: view.frame.size)
        view.updateConstraints()
        view.layoutIfNeeded()
        
        backgroundGradient.frame = view.bounds
        super.viewDidLayoutSubviews()
    }
    
    /// This method configures and sets up the UI components as well as their layout.
    private func setup() {
        
        // Stack View:
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addConstraints([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
            ])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 15
        
        
        /// Color Picker View:
        colorPicker.selectedColorViewVisible = false
        colorPicker.delegate = self
        
        colorPicker.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(colorPicker)
        view.addConstraint(
            colorPicker.heightAnchor.constraint(equalTo: colorPicker.widthAnchor)
        )
        
        
        /// Coordinate View with CIE colors
        coordinateView.backgroundColor = .lightGray
        coordinateView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(coordinateView)
        
        view.addConstraints([
            coordinateView.heightAnchor.constraint(equalTo: coordinateView.widthAnchor),
            coordinateView.widthAnchor.constraint(equalTo: colorPicker.widthAnchor)
            ])
        
        
        // Stack View for switch and switch description label:
        switchStackView.axis = .horizontal
        switchStackView.distribution = .fill
        switchStackView.spacing = 10
        switchStackView.alignment = .fill
        
        /// Color Space Switch:
        colorSpaceSwitch.isOn = false
        
        colorSpaceSwitch.addTarget(self, action: #selector(self.switchValueChanged(sender:)), for: .valueChanged)
        
        /// Color Space Description Label:
        switchDescriptionLabel.text = "P3 Color Space"
        switchDescriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 755), for: .horizontal)
        
        switchStackView.addArrangedSubview(switchDescriptionLabel)
        switchStackView.addArrangedSubview(colorSpaceSwitch)
        
        // Stack View for switch, description and camera button
        switchButtonStackView.axis = .vertical
        switchButtonStackView.distribution = .fill
        switchButtonStackView.spacing = 10
        switchButtonStackView.alignment = .fill
        
        
        switchButtonStackView.addArrangedSubview(switchStackView)
        
        /// Open Camera Button
        openCameraButton.setTitle("Open Camera", for: .normal)
        openCameraButton.setTitleColor(.white, for: .normal)
        openCameraButton.addTarget(self, action: #selector(self.openCameraButtonPressed(sender:)), for: .touchUpInside)
        openCameraButton.gradientStartColor = UIColor.red
        openCameraButton.gradientEndColor = UIColor.red.withAlphaComponent(0.5)
        //        openCameraButton.borderWidth = 1
        openCameraButton.cornerRadius = 5
        openCameraButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        openCameraButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 755), for: .horizontal)
        
        switchButtonStackView.addArrangedSubview(openCameraButton)
        
        
        stackView.addArrangedSubview(switchButtonStackView)
        view.addConstraint(openCameraButton.heightAnchor.constraint(equalToConstant: 50))
        
        
        /// Fill view at the bottom of the stack view. Allowed more flexible layout as it fills the bottom space of the stack view to the bottom of the stack views superview.
        let fillView = UIView(frame: .zero)
        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.setContentHuggingPriority(UILayoutPriority(rawValue: 245), for: .vertical)
        fillView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 240), for: .vertical)
        fillView.backgroundColor = .clear
        
        stackView.addArrangedSubview(fillView)
        
        let heightConstraint = fillView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority(rawValue: 250)
        let widthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = UILayoutPriority(rawValue: 250)
        
        stackView.addConstraints([heightConstraint, widthConstraint])
    }
    
    /// This method sets up the image views for decoration birds.
    private func setupBirds() {
        bird1ImageView.image = UIImage(named: "Bird 1", in: Bundle(for: type(of: self)), compatibleWith: nil)
        bird2ImageView.image = UIImage(named: "Bird 2", in: Bundle(for: type(of: self)), compatibleWith: nil)
        bird3ImageView.image = UIImage(named: "Bird 3", in: Bundle(for: type(of: self)), compatibleWith: nil)
        
        bird1ImageView.translatesAutoresizingMaskIntoConstraints = false
        bird2ImageView.translatesAutoresizingMaskIntoConstraints = false
        bird3ImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(bird1ImageView)
        view.addSubview(bird2ImageView)
        view.addSubview(bird3ImageView)
        
        view.addConstraints([
            bird1ImageView.heightAnchor.constraint(equalToConstant: 40),
            bird1ImageView.widthAnchor.constraint(equalToConstant: 45),
            bird1ImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 75),
            bird1ImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12)
            ])
        view.addConstraints([
            bird2ImageView.heightAnchor.constraint(equalToConstant: 27),
            bird2ImageView.widthAnchor.constraint(equalToConstant: 44),
            bird2ImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            bird2ImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55)
            ])
        view.addConstraints([
            bird3ImageView.heightAnchor.constraint(equalToConstant: 25),
            bird3ImageView.widthAnchor.constraint(equalToConstant: 36),
            bird3ImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            bird3ImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
            ])
    }
    
    /// This function sets up the background gradient.
    private func setupGradient() {
        backgroundGradient.colors = [UIColor.color(from: 0xF9E9D2).cgColor, UIColor.white.cgColor]
        
        view.layer.addSublayer(backgroundGradient)
    }
    
    @objc private func switchValueChanged(sender: UISwitch) {
        usesP3ColorSpace = sender.isOn
    }
    @objc private func openCameraButtonPressed(sender: UIButton) {
        //        let cameraViewController = CameraLiveViewController()
        //        cameraViewController.view.tintColor = colorPicker.composedColor
        //        present(cameraViewController, animated: true, completion: nil)
    }
    
    
    public func colorDidChange(color: UIColor, causedByUserInteraction: Bool, from picker: ColorPickerView) {
        
        let componentsForxyY: (x: CGFloat, y: CGFloat, z: CGFloat)
        if usesP3ColorSpace {
            componentsForxyY = color.fromP3ToxyY()
        }
        else {
            componentsForxyY = color.fromsRGBToxyY()
        }
        coordinateView.updateColor(x: componentsForxyY.x, y: componentsForxyY.y, Y: componentsForxyY.z)
        
        //        if color.isEqual(to: .white) {
        //            print("White!")
        //        }
        //        let fullSaturatedColorComponents = color.hsbComponents()
        //        let fullSaturatedColor = UIColor(hue: fullSaturatedColorComponents.hue, saturation: 1, brightness: 1, alpha: 1)
        updateUI(with: color, shouldUpdateSwitchTintColor: causedByUserInteraction)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.updateUIAccordingToViewOrientation(to: size)
            self.backgroundGradient.frame = self.view.bounds
        }, completion: {_ in
            
            self.colorDidChange(color: self.colorPicker.composedColor, causedByUserInteraction: false, from: self.colorPicker)
            
        })
    }
    
    
    /// This method updates the UI according to a new size.
    ///
    /// - Parameter newSize: The new size to adapt the UI to.
    private func updateUIAccordingToViewOrientation(to newSize: CGSize) {
        if newSize.height > newSize.width {
            stackView.axis = .vertical
            switchStackView.axis = .horizontal
            switchButtonStackView.axis = .vertical
            
            bird1ImageView.alpha = 1
            bird2ImageView.alpha = 1
            bird3ImageView.alpha = 1
            
            backgroundGradient.endPoint = CGPoint(x: 0.5, y:0.3)
        }
        else {
            stackView.axis = .horizontal
            switchStackView.axis = .vertical
            switchButtonStackView.axis = .vertical
            
            bird1ImageView.alpha = 0
            bird2ImageView.alpha = 0
            backgroundGradient.endPoint = CGPoint(x: 0.5, y:0.05)
        }
    }
    
    
    /// This method updates the UI to a given color. The color is applied eg. to the camera button or the switch.
    ///
    /// - Parameters:
    ///   - color: The new color to which the UI should be updated to.
    ///   - shouldUpdateSwitchTintColor: A flag that defines if the tint color of the switch should be adjusted as well. Should be false if the user just fipped the switch and this method is called as a result of this interaction to avoid render glitches (that can happen when the tint color is changed while the switch is still animating its position).
    private func updateUI(with color: UIColor, shouldUpdateSwitchTintColor: Bool = true) {
        
        //        openCameraButton.setTitleColor(color, for: .normal)
        openCameraButton.gradientStartColor = color
        openCameraButton.gradientEndColor = color.withAlphaComponent(0.5)
        //        openCameraButton.borderColor = color
        if shouldUpdateSwitchTintColor {
            colorSpaceSwitch.tintColor = color
        }
        switchDescriptionLabel.textColor = color
    }
}

