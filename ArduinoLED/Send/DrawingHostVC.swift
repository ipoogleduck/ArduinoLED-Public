//
//  SendHostVC.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/10/21.
//

import UIKit

var waitingForSuccess = false //If waiting to hear back from listner if message was recieved

class DrawingHostVC: UIViewController {
    
    @IBOutlet var containerView: UIView!
    
    var lastOrientation = UIDeviceOrientation.portrait
    
    var drawingVC: DrawingVC!
    var lndDrawingVC: DrawingVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        drawingVC = storyboard?.instantiateViewController(identifier: "DrawingVC")
        lndDrawingVC = storyboard?.instantiateViewController(identifier: "LndDrawingVC")
        setupContainerViews(with: [drawingVC, lndDrawingVC])
        //let statusOrientation = UIApplication.shared.statusBarOrientation
        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            if interfaceOrientation == .landscapeLeft {
                lastOrientation = UIDeviceOrientation.landscapeLeft
            } else if interfaceOrientation == .landscapeRight {
                lastOrientation = UIDeviceOrientation.landscapeRight
            }
        }
        rotated()
    }
    
    func setupContainerViews(with viewControllers: [UIViewController]) {
        for viewController in viewControllers {
            addChild(viewController)
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func setContainerView(to viewController: UIViewController) {
        for view in containerView.subviews {
            view.removeFromSuperview()
        }
        containerView.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])
        viewController.didMove(toParent: self)
    }
    
    @objc func rotated() { //Change UI when rotated
        var currentOrientation = UIDevice.current.orientation
        if currentOrientation != .landscapeLeft && currentOrientation != .landscapeRight && currentOrientation != .portrait {
            currentOrientation = lastOrientation
        }
        if (currentOrientation == .landscapeRight || currentOrientation == .landscapeLeft) {
            setContainerView(to: lndDrawingVC)
        } else if currentOrientation == .portrait {
            setContainerView(to: drawingVC)
        }
        lastOrientation = currentOrientation

    }
    
}
