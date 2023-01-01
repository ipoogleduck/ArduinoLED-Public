//
//  TabBarController.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/28/21.
//

import UIKit
import Firebase
import Indicate
import JGProgressHUD

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var ref: DatabaseReference!
    var successRef: DatabaseReference!
    
    var isOnLog = false
    
    var currentVC: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor(named: "MainColor")
        self.delegate = self
        
        ref = Database.database().reference()
        successRef = ref.child(otherPath).child("received")
        
        setupSuccessListner()
        setupViewControllers()
        NotificationCenter.default.addObserver(self, selector: #selector(didSendMessage), name: .didSendMessage, object: nil)
        
        if amJulia {
            print("RUNNING APP AS JULIA")
        } else {
            print("RUNNING APP AS OLIVER")
        }
    }
    
    func setupViewControllers() {
        //Access these later when showing sent or delivered message
        let drawingHostVC = storyboard!.instantiateViewController(identifier: "DrawingHostVC")
        let textHostVC = storyboard!.instantiateViewController(identifier: "TextHostVC")
        let logVC = storyboard!.instantiateViewController(identifier: "LogVC")
        viewControllers = [drawingHostVC, textHostVC, logVC]
        currentVC = viewControllers![0]
    }
    
    func setupSuccessListner() {
        successRef.observe(.value, with: { (snapshot) -> Void in
            let recieved = snapshot.value as? Bool ?? false
            if recieved && waitingForSuccess {
                //Show Success!
                let hud = JGProgressHUD()
                //hud.vibrancyEnabled = true
                hud.textLabel.text = "Delivered"
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.show(in: self.currentVC.view)
                hud.dismiss(afterDelay: 1.0)
                waitingForSuccess = false
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        })
    }
    
    @objc func didSendMessage() {
        let possibleEmojis = ["🦧", "🐈", "🍆", "💘", "💕", "💗", "💩", "😏", "🎾", "🐰"]
        let emoji = possibleEmojis.randomElement()!
        // STEP 1: Define the content
        let content = Indicate.Content(title: .init(value: "Message Sent", alignment: .natural),
                                       attachment: .emoji(.init(value: emoji, alignment: .natural)))

        // STEP 2: Configure the presentation
        let config = Indicate.Configuration()
            .with(tap: { controller in
                controller.dismiss()
            })
                
        // STEP 3: Present the indicator
        let controller = Indicate.PresentationController(content: content, configuration: config)
        controller.present(in: currentVC.view)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        currentVC = viewController
        //When map tab is tapped twice in a row, recenter map to original location
        let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController)!
        if selectedIndex == 2 {
            if isOnLog {
                //sends notification to recenter map
                print("Scrolling to bottom")
                NotificationCenter.default.post(name: .scrollToBottomLog, object: nil)
            } else {
                isOnLog = true
            }
        } else {
            isOnLog = false
        }
    }
    
}
