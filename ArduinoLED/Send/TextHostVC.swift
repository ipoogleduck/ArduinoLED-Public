//
//  TextHostVC.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 5/22/21.
//

import UIKit

var lastTextOrientation = UIDeviceOrientation.portrait

class TextHostVC: UIViewController {
    
    @IBOutlet var containerView: UIView!
    
    var textVC: TextVC!
    var lndTextVC: TextVC!
    
    var firstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        textVC = storyboard?.instantiateViewController(identifier: "textVC")
        lndTextVC = storyboard?.instantiateViewController(identifier: "LndTextVC")
        setupContainerViews(with: [textVC, lndTextVC])
        //let statusOrientation = UIApplication.shared.statusBarOrientation
        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            if interfaceOrientation == .landscapeLeft {
                lastTextOrientation = UIDeviceOrientation.landscapeLeft
            } else if interfaceOrientation == .landscapeRight {
                lastTextOrientation = UIDeviceOrientation.landscapeRight
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
            currentOrientation = lastTextOrientation
        }
        if (currentOrientation == .landscapeRight || currentOrientation == .landscapeLeft) && ((lastTextOrientation != .landscapeLeft && lastTextOrientation != .landscapeRight) || firstLoad) {
            setContainerView(to: lndTextVC)
        } else if currentOrientation == .portrait && (currentOrientation != lastTextOrientation || firstLoad) {
            setContainerView(to: textVC)
        }
        lastTextOrientation = currentOrientation
        firstLoad = false
    }
    
}
