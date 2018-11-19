//
//  CompassViewController.swift
//  WunderLINQ
//
//  Created by Keith Conger on 8/13/17.
//  Copyright © 2017 Black Box Embedded, LLC. All rights reserved.
//

import UIKit
import CoreLocation

class CompassViewController: UIViewController {
    @IBOutlet weak var compassLabel: UILabel!

    // MARK: - Handling User Interaction
    
    override var keyCommands: [UIKeyCommand]? {
        
        let commands = [
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags:[], action: #selector(leftScreen), discoverabilityTitle: "Go left"),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags:[], action: #selector(rightScreen), discoverabilityTitle: "Go right"),
            UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags:[], action: #selector(nextUnit), discoverabilityTitle: "Next Unit"),
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags:[], action: #selector(previousUnit), discoverabilityTitle: "Previous Unit")
        ]
        return commands
    }
    
    @objc func leftScreen() {
        performSegue(withIdentifier: "backToMotorcycle", sender: [])
    }
    @objc func rightScreen() {
        performSegue(withIdentifier: "compassToMusic", sender: [])
    }
    @objc func nextUnit() {
        switch (UserDefaults.standard.integer(forKey: "bearing_unit_preference")){
        case 0:
            UserDefaults.standard.set(1, forKey: "bearing_unit_preference")
        case 1:
            UserDefaults.standard.set(2, forKey: "bearing_unit_preference")
        case 2:
            UserDefaults.standard.set(0, forKey: "bearing_unit_preference")
        default:
            print("Invalid bearing unit")
        }
    }
    @objc func previousUnit() {
        switch (UserDefaults.standard.integer(forKey: "bearing_unit_preference")){
        case 0:
            UserDefaults.standard.set(2, forKey: "bearing_unit_preference")
        case 1:
            UserDefaults.standard.set(0, forKey: "bearing_unit_preference")
        case 2:
            UserDefaults.standard.set(1, forKey: "bearing_unit_preference")
        default:
            print("Invalid bearing unit")
        }
    }
    
    func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizerDirection.right {
            performSegue(withIdentifier: "backToMotorcycle", sender: [])
        }
        else if gesture.direction == UISwipeGestureRecognizerDirection.left {
            performSegue(withIdentifier: "compassToMusic", sender: [])
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
    }
    
    let locationDelegate = LocationDelegate()
    var latestLocation: CLLocation? = nil
    var yourLocationBearing: CGFloat { return latestLocation?.bearingToLocationRadian(self.yourLocation) ?? 0 }
    var yourLocation: CLLocation {
        get { return UserDefaults.standard.currentLocation }
        set { UserDefaults.standard.currentLocation = newValue }
    }
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    private func orientationAdjustment() -> CGFloat {
        let isFaceDown: Bool = {
            switch UIDevice.current.orientation {
            case .faceDown: return true
            default: return false
            }
        }()
        
        let adjAngle: CGFloat = {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return 90
            case .landscapeRight:
                return -90
            case .portrait, .unknown: return 0
            case .portraitUpsideDown: return isFaceDown ? 180 : -180
            }
        }()
        return adjAngle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let backBtn = UIButton()
        backBtn.setImage(UIImage(named: "Left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backBtn.addTarget(self, action: #selector(leftScreen), for: .touchUpInside)
        let backButton = UIBarButtonItem(customView: backBtn)
        let backButtonWidth = backButton.customView?.widthAnchor.constraint(equalToConstant: 30)
        backButtonWidth?.isActive = true
        let backButtonHeight = backButton.customView?.heightAnchor.constraint(equalToConstant: 30)
        backButtonHeight?.isActive = true
        
        let forwardBtn = UIButton()
        forwardBtn.setImage(UIImage(named: "Right")?.withRenderingMode(.alwaysTemplate), for: .normal)
        forwardBtn.addTarget(self, action: #selector(rightScreen), for: .touchUpInside)
        let forwardButton = UIBarButtonItem(customView: forwardBtn)
        let forwardButtonWidth = forwardButton.customView?.widthAnchor.constraint(equalToConstant: 30)
        forwardButtonWidth?.isActive = true
        let forwardButtonHeight = forwardButton.customView?.heightAnchor.constraint(equalToConstant: 30)
        forwardButtonHeight?.isActive = true
        
        self.navigationItem.title = NSLocalizedString("compass_title", comment: "")
        self.navigationItem.leftBarButtonItems = [backButton]
        self.navigationItem.rightBarButtonItems = [forwardButton]
        
        if UserDefaults.standard.bool(forKey: "display_brightness_preference") {
            UIScreen.main.brightness = CGFloat(1.0)
        } else {
            UIScreen.main.brightness = CGFloat(UserDefaults.standard.float(forKey: "systemBrightness"))
        }
        
        locationManager.delegate = locationDelegate
        
        locationDelegate.locationCallback = { location in
            self.latestLocation = location
        }
        
        locationDelegate.headingCallback = { newHeading in
            
            func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
                let heading: CGFloat = {
                    let originalHeading = self.yourLocationBearing - newAngle.degreesToRadians
                    switch UIDevice.current.orientation {
                    case .faceDown: return -originalHeading
                    default: return originalHeading
                    }
                }()
                
                return CGFloat(self.orientationAdjustment().degreesToRadians + heading)
            }
            let angle = computeNewAngle(with: CGFloat(newHeading.trueHeading))
            
            var fixedHeading = abs(angle.radiansToDegrees)
            if fixedHeading > 360 {
                fixedHeading = fixedHeading - 360
            } else if fixedHeading < 0 {
                fixedHeading = fixedHeading + 360
            }
            
            let degrees = abs(Int(fixedHeading))
            //print("degrees: \(degrees) fixedHeading: \(fixedHeading)) newHeading: \(newHeading) angle(degrees): \(angle.radiansToDegrees) ")
                        
            var cardinal = "-";
            var bearing = "-";
            if UserDefaults.standard.integer(forKey: "bearing_unit_preference") != 0 {
                if degrees > 331 || degrees <= 28 {
                    cardinal = NSLocalizedString("north", comment: "")
                } else if degrees > 28 && degrees <= 73 {
                    cardinal = NSLocalizedString("north_east", comment: "")
                } else if degrees > 73 && degrees <= 118 {
                    cardinal = NSLocalizedString("east", comment: "")
                } else if degrees > 118 && degrees <= 163 {
                    cardinal = NSLocalizedString("south_east", comment: "")
                } else if degrees > 163 && degrees <= 208 {
                    cardinal = NSLocalizedString("south", comment: "")
                } else if degrees > 208 && degrees <= 253 {
                    cardinal = NSLocalizedString("south_west", comment: "")
                } else if degrees > 253 && degrees <= 298 {
                    cardinal = NSLocalizedString("west", comment: "")
                } else if degrees > 298 && degrees <= 331 {
                    cardinal = NSLocalizedString("north_west", comment: "")
                } else {
                    cardinal = "-"
                }
            }
            
            if UserDefaults.standard.integer(forKey: "bearing_unit_preference") == 1 {
                bearing = cardinal;
            } else if UserDefaults.standard.integer(forKey: "bearing_unit_preference") == 2 {
                bearing = "\(degrees)\n\(cardinal)";
            } else {
                bearing = "\(degrees)";
            }
            self.compassLabel.text = bearing
        }
    }
}
