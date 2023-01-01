//
//  ViewController.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/2/21.
//

import UIKit
import Firebase

class ViewController: UIViewController, UIColorPickerViewControllerDelegate {

    @IBOutlet var LEDSwitch: UISwitch!
    @IBOutlet var colorView: UIButton!
    
    var ref: DatabaseReference!
    
    var lastColor: (Int, Int, Int)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        self.ref.child("LEDSwitch").getData { (error, snapshot) in
            if let error = error {
                print("Error getting data \(error)")
            } else if snapshot.exists() {
                print("Got data \(snapshot.value!)")
                let postDict = snapshot.value as? [String : AnyObject]
                DispatchQueue.main.async {
                    self.LEDSwitch.isOn = postDict?["isOn"] as? Bool ?? false
                }
            }
            else {
                print("No data available")
            }
        }
    }

    @IBAction func LEDSwitch(_ sender: Any) {
        ref.child("LEDSwitch").setValue(["isOn": LEDSwitch.isOn])
    }
    
    @IBAction func colorView(_ sender: Any) {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.supportsAlpha = false
        if let color = lastColor {
            picker.selectedColor = UIColor(red: CGFloat(color.0)/15, green: CGFloat(color.1)/15, blue: CGFloat(color.2)/15, alpha: 1)
        }
        present(picker, animated: true, completion: nil)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        
        let color = viewController.selectedColor
        
        let components = color.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let red15 = Int(r*15)
        let green15 = Int(g*15)
        let blue15 = Int(b*15)
        
        let rgb15 = (red15, green15, blue15)

        if lastColor ?? (-1, -1, -1) != rgb15 {
            colorView.backgroundColor = UIColor(red: CGFloat(red15)/15, green: CGFloat(green15)/15, blue: CGFloat(blue15)/15, alpha: 1)
            let uploadString = "$f\(createString(from: red15))\(createString(from: green15))\(createString(from: blue15))^"
            ref.child("matrixTest").setValue(["drawing": uploadString, "update": true])
            print(uploadString)
        }
        
        lastColor = rgb15
        
    }
    
    func createString(from int: Int) -> String {
        if int < 10 {
            return "0\(int)"
        }
        return String(int)
    }
    
}

