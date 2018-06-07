//
//  CameraLiveViewController.swift
//  Colors Playground, WWDC18 scholarship submission
//
//  Created by Andreas Neusüß on 24.03.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

/// This ViewController is responsible for displaying a live feed of the devices camera and applying a CIFilter on it, that highlights every color that is exclusive in the P3 color space (not contained in sRGB).
public final class CameraLiveViewController: UIViewController {
    
    /// The image view that displays the filtered image.
    private let liveFeedImageView: UIImageView = UIImageView()
    
    /// The blur container view of the center label that tells the user what color space they use.
    private var blurLabelContainer: UIVisualEffectView!
    /// The blur container view of the done button.
    private var blurButtonContainer: UIVisualEffectView!
    /// The blur container view of the description label on the bottom that tells the user what they see in this ViewController.
    private var blurDescriptionContainer: UIVisualEffectView!
    
    /// The label that informs the user about the devices color space.
    let colorSpaceLabel: UILabel = UILabel()
    /// The done button to dismiss the ViewController.
    let doneButton = UIButton(type: UIButtonType.system)
    
    /// The AVCaptureSession that managaes the video input and output.
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        return session
    }()
    
    /// The CIContext to define the CI settings.
    private lazy var ciContext: CIContext = {
        // Use the color space that the device will 100% support
        let colorSpace = CGColorSpace(name: CGColorSpace.extendedSRGB)!
        let floatPixelFormat = NSNumber(value: kCIFormatRGBAh)
        let options: [String: Any] = [kCIContextWorkingColorSpace: colorSpace, kCIContextWorkingFormat: floatPixelFormat]
        return CIContext(options: options)
    }()
    
    /// The used CIFilter. Will perform an operation every time a new frame comes in.
    private lazy var filter: CIFilter = CIFilter(name: P3ColorFilter.name)!
    
    /// The queue on which the session operates.
    private let sessionQueue = DispatchQueue(label: "de.Andreas Neusüß.session_queue", qos: DispatchQoS.userInteractive, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    /// The queue on which the images of the camera are delivered to.
    private let bufferQueue = DispatchQueue(label: "de.Andreas Neusüß.buffer_queue", qos: DispatchQoS.default, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    /// The queue on which the render process takes place.
    private let renderQueue = DispatchQueue(label: "de.Andreas Neusüß.render_queue", qos: DispatchQoS.userInteractive, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the filter so it can be instantiated by using its name
        P3ColorFilter.register()
        
        configureUI()
        
        requestPermissionIfNeeded()
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    override public func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            self.session.stopRunning()
        }
        super.viewWillDisappear(animated)
    }
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Sets up and configures the UI, exspecially the image view. Will call several helper methods for other UI components.
    private func configureUI() {
        view.backgroundColor = .white
        liveFeedImageView.backgroundColor = .white
        
        liveFeedImageView.contentMode = .scaleAspectFill
        view.addSubview(liveFeedImageView)
        liveFeedImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addConstraints([
            liveFeedImageView.topAnchor.constraint(equalTo: view.topAnchor),
            liveFeedImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            liveFeedImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            liveFeedImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        
        
        setupBlurLabelView()
        setupBlurDoneButton()
        setupBlurDescription()
    }
    /// Sets up and configures the UI for the color space label and its container blur view.
    private func setupBlurLabelView() {
        colorSpaceLabel.numberOfLines = 2
        //        colorSpaceLabel.textColor = view.tintColor
        colorSpaceLabel.textAlignment = .center
        colorSpaceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffectLabel = UIBlurEffect(style: .prominent)
        blurLabelContainer = UIVisualEffectView(effect: blurEffectLabel)
        blurLabelContainer.layer.cornerRadius = 10
        blurLabelContainer.clipsToBounds = true
        blurLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(blurLabelContainer)
        view.addConstraints([
            blurLabelContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            blurLabelContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        
        let vibrancyLabelEffect = UIVibrancyEffect(blurEffect: blurEffectLabel)
        let vibrayncyLabelEffectView = UIVisualEffectView(effect: vibrancyLabelEffect)
        vibrayncyLabelEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        vibrayncyLabelEffectView.contentView.addSubview(colorSpaceLabel)
        vibrayncyLabelEffectView.addConstraints([
            colorSpaceLabel.leadingAnchor.constraint(equalTo: vibrayncyLabelEffectView.contentView.leadingAnchor, constant: 8),
            colorSpaceLabel.trailingAnchor.constraint(equalTo: vibrayncyLabelEffectView.trailingAnchor, constant: -8),
            colorSpaceLabel.topAnchor.constraint(equalTo: vibrayncyLabelEffectView.contentView.topAnchor, constant: 8),
            colorSpaceLabel.bottomAnchor.constraint(equalTo: vibrayncyLabelEffectView.contentView.bottomAnchor, constant: -8)
            ])
        
        blurLabelContainer.contentView.addSubview(vibrayncyLabelEffectView)
        
        blurLabelContainer.contentView.addConstraints([
            vibrayncyLabelEffectView.leadingAnchor.constraint(equalTo: blurLabelContainer.contentView.leadingAnchor),
            vibrayncyLabelEffectView.trailingAnchor.constraint(equalTo: blurLabelContainer.contentView.trailingAnchor),
            vibrayncyLabelEffectView.topAnchor.constraint(equalTo: blurLabelContainer.contentView.topAnchor),
            vibrayncyLabelEffectView.bottomAnchor.constraint(equalTo: blurLabelContainer.contentView.bottomAnchor)
            ])
        
    }
    
    /// Sets up and configures the UI for the description label and its container blur view.
    private func setupBlurDescription() {
        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        //        colorSpaceLabel.textColor = view.tintColor
        descriptionLabel.text = "Only colors within P3 color space are visible,\n the the other colors are made gray."
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffectDescription = UIBlurEffect(style: .prominent)
        blurDescriptionContainer = UIVisualEffectView(effect: blurEffectDescription)
        blurDescriptionContainer.layer.cornerRadius = 10
        blurDescriptionContainer.clipsToBounds = true
        blurDescriptionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(blurDescriptionContainer)
        view.addConstraints([
            blurDescriptionContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            blurDescriptionContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        
        let vibrancyDescriptionEffect = UIVibrancyEffect(blurEffect: blurEffectDescription)
        let vibrayncyDescriptionEffectView = UIVisualEffectView(effect: vibrancyDescriptionEffect)
        vibrayncyDescriptionEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        vibrayncyDescriptionEffectView.contentView.addSubview(descriptionLabel)
        vibrayncyDescriptionEffectView.addConstraints([
            descriptionLabel.leadingAnchor.constraint(equalTo: vibrayncyDescriptionEffectView.contentView.leadingAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: vibrayncyDescriptionEffectView.trailingAnchor, constant: -8),
            descriptionLabel.topAnchor.constraint(equalTo: vibrayncyDescriptionEffectView.contentView.topAnchor, constant: 8),
            descriptionLabel.bottomAnchor.constraint(equalTo: vibrayncyDescriptionEffectView.contentView.bottomAnchor, constant: -8)
            ])
        
        blurDescriptionContainer.contentView.addSubview(vibrayncyDescriptionEffectView)
        
        blurDescriptionContainer.contentView.addConstraints([
            vibrayncyDescriptionEffectView.leadingAnchor.constraint(equalTo: blurDescriptionContainer.contentView.leadingAnchor),
            vibrayncyDescriptionEffectView.trailingAnchor.constraint(equalTo: blurDescriptionContainer.contentView.trailingAnchor),
            vibrayncyDescriptionEffectView.topAnchor.constraint(equalTo: blurDescriptionContainer.contentView.topAnchor),
            vibrayncyDescriptionEffectView.bottomAnchor.constraint(equalTo: blurDescriptionContainer.contentView.bottomAnchor)
            ])
    }
    /// Sets up and configures the UI for the done button and its container blur view.
    private func setupBlurDoneButton() {
        
        let blurEffectButton = UIBlurEffect(style: .prominent)
        blurButtonContainer = UIVisualEffectView(effect: blurEffectButton)
        blurButtonContainer.layer.cornerRadius = 10
        blurButtonContainer.clipsToBounds = true
        blurButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(blurButtonContainer)
        view.addConstraints([
            blurButtonContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            blurButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15)
            ])
        
        //        doneButton.tintColor = view.tintColor
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(self.doneButtonPressed(sender:)), for: .touchUpInside)
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        blurButtonContainer.contentView.addSubview(doneButton)
        blurButtonContainer.addConstraints([
            doneButton.leadingAnchor.constraint(equalTo: blurButtonContainer.contentView.leadingAnchor, constant: 8),
            doneButton.trailingAnchor.constraint(equalTo: blurButtonContainer.trailingAnchor, constant: -8),
            doneButton.topAnchor.constraint(equalTo: blurButtonContainer.contentView.topAnchor, constant: 5),
            doneButton.bottomAnchor.constraint(equalTo: blurButtonContainer.contentView.bottomAnchor, constant: -5)
            ])
        
    }
    @objc private func doneButtonPressed(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    /// Configures the AVCaptureSession by adding inputs and outputs. Will also set the text of color space label.
    private func configureSession() {
        guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
            else {
                print("No suitable camera found :(")
                presentAlert(title: "Error setting up the camera.", text: "An error occured during setup. Please try it again or use a different device.")
                return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Input not created!")
            presentAlert(title: "Error setting up the camera.", text: "An error occured during setup. Please try it again or use a different device.")
            return
        }
        
        session.beginConfiguration()
        guard session.canAddInput(input) else {
            print("Input not Added!")
            presentAlert(title: "Error setting up the camera.", text: "An error occured during setup. Please try it again or use a different device.")
            return
        }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        // Drop frames if the computing lacks behind
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: bufferQueue)
        
        guard session.canAddOutput(output) else {
            print("Output not Added!")
            presentAlert(title: "Error setting up the camera.", text: "An error occured during setup. Please try it again or use a different device.")
            return
        }
        session.addOutput(output)
        output.connections.first?.videoOrientation = outputOrientation(for: UIScreen.main.orientation)
        
        // For displaying in imageview
        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddOutput(photoOutput) else {
            print("Output Photo not Added!")
            presentAlert(title: "Error setting up the camera.", text: "An error occured during setup. Please try it again or use a different device.")
            return
        }
        session.addOutput(photoOutput)
        session.commitConfiguration()
        
        let colorSpace = device.activeColorSpace
        DispatchQueue.main.async {
            switch colorSpace {
            case .sRGB:
                self.colorSpaceLabel.text = "You are using \nsRGB colorspace"
            case .P3_D65:
                self.colorSpaceLabel.text = "You are using \nP3 colorspace"
            }
        }
        
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator:
        UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.session.outputs.first!.connections.first!.videoOrientation = self.outputOrientation(for: UIScreen.main.orientation)
            
        }, completion: {_ in
            
        })
    }
    
    
    /// This method converts a UIDeviceOrientation to its according AVCaptureVideoOrientation.
    ///
    /// - Parameter orientation: The orientation of the device.
    /// - Returns: The orientation of the output.
    private func outputOrientation(for orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    /// This function requests the permission to use the users camera. If the user has granted access, the method returns immediately. If not, a dialogue will ask the user. Then, the sessionQueue is suspended until the user has made a decision. If so, the queue is resumed (if granted) or a warning is displayed.
    private func requestPermissionIfNeeded() {
        let currentPermission = AVCaptureDevice.authorizationStatus(for: .video)
        switch currentPermission {
        case .authorized:
            // great :)
            break
        case .notDetermined:
            // ask politely
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
                if granted {
                    self.sessionQueue.resume()
                }
                else {
                    self.presentAlert(title: "Permission not granted.", text: "You did not authorize the app to use your camera. Please restart or re-install the playground.")
                }
            })
        case .restricted:
            self.presentAlert(title: "Permission not granted.", text: "You did not authorize the app to use your camera. Please go to settings and allow it. Please restart or re-install the playground.")
        case .denied:
            self.presentAlert(title: "Permission not granted.", text: "You did not authorize the app to use your camera. Please go to settings and allow it. Please restart or re-install the playground.")
        }
    }
    
    /// Presents an alert with given title and text.
    //
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - text: The message of the alert.
    private func presentAlert(title: String, text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Dismiss", style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(doneAction)
        present(alert, animated: true, completion: nil)
    }
}

extension CameraLiveViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("sample buffer not created")
            return
        }
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        filter.setValue(ciimage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            print("Filter did not produce output image")
            return
        }
        renderQueue.async {
            let colorSpace = CGColorSpace(name: CGColorSpace.displayP3)
            guard let cgOutPutImage = self.ciContext.createCGImage(outputImage, from: outputImage.extent, format: kCIFormatRGBAh, colorSpace: colorSpace) else {
                print("CIContext could not produce image for render queue")
                return
            }
            
            DispatchQueue.main.async {
                self.liveFeedImageView.image = UIImage(cgImage: cgOutPutImage)
            }
        }
        
        
    }
}


extension UIScreen {
    var orientation: UIDeviceOrientation {
        let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
        switch (point.x, point.y) {
        case (0, 0):
            return .portrait
        case let (x, y) where x != 0 && y != 0:
            return .portraitUpsideDown
        case let (0, y) where y != 0:
            return .landscapeLeft
        case let (x, 0) where x != 0:
            return .landscapeRight
        default:
            return .unknown
        }
    }
}
