//
//  TextVC.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/17/21.
//

import UIKit
import Firebase

var persistentMessage = false
var speed = 0.6
var isFixedText = true
var selectedTextColor = MatrixColor.white
var currentText: String?

class TextVC: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var colorsCollectionView: UICollectionView!
    
    @IBOutlet var textModeControl: UISegmentedControl!
    
    @IBOutlet var speedSlider: UISlider!
    @IBOutlet var speedLabel: UILabel!
    
    @IBOutlet var previewButtonBackgroundView: UIView!
    @IBOutlet var previewButton: UIButton!
    
    @IBOutlet var optionButtonBackgroundView: UIView!
    @IBOutlet var optionButtonLabel: UILabel!
    @IBOutlet var optionButton: UIButton!
    
    var ref: DatabaseReference!
    
    let fixedSpeedRange = 100 ... 4000
    let scrollSpeedRange = 0 ... 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        colorsCollectionView.delegate = self
        colorsCollectionView.dataSource = self
        
        textField.delegate = self
        
        //Kill keyboard when you tap on view
        let tap = UITapGestureRecognizer(target: self, action: #selector(killKeyboard))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
        
        previewButtonBackgroundView.layer.cornerRadius = 10
        optionButtonBackgroundView.layer.cornerRadius = 10
        sendButton.layer.cornerRadius = 10
        
        updateOptionButton()
        updateSendButton(animated: false)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        speedSlider.value = Float(speed)
        if isFixedText {
            textModeControl.selectedSegmentIndex = 0
        } else {
            textModeControl.selectedSegmentIndex = 1
        }
        colorsCollectionView.reloadData()
        updateSpeedLabel()
        updateOptionButton()
        textField.text = currentText
        updateSendButton(animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        MatrixColor.allCases.count-1 //Exclude black
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorSelectionCell", for: indexPath) as! ColorSelectionCell
        cell.outerColor.layer.cornerRadius = cell.outerColor.bounds.width/2
        cell.separation.layer.cornerRadius = cell.separation.bounds.width/2
        cell.innerColor.layer.cornerRadius = cell.innerColor.bounds.width/2
        let color = MatrixColor.allCases[indexPath.item+1].rawValue //Exclude black
        cell.outerColor.backgroundColor = UIColor(named: color)
        cell.innerColor.backgroundColor = UIColor(named: color)
        if selectedTextColor.rawValue == color {
            cell.separation.alpha = 1
        } else {
            cell.separation.alpha = 0
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 30, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let spacing: CGFloat = CGFloat(9*collectionView.numberOfItems(inSection: 0))
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTextColor = MatrixColor.allCases[indexPath.row+1] //Exclude black
        colorsCollectionView.reloadData()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let lettersNumbers = CharacterSet.alphanumerics
        let symbols = CharacterSet.punctuationCharacters
        let otherCharacters = CharacterSet(charactersIn: "$^+=~<> ")
        let characterSet = CharacterSet(charactersIn: string)
        return lettersNumbers.isSuperset(of: characterSet) || symbols.isSuperset(of: characterSet) || otherCharacters.isSuperset(of: characterSet) && !characterSet.contains("^")
    }
    
    @objc func killKeyboard() {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateSendButton(animated: false)
        return textField.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view == gestureRecognizer.view
    }
    
    func updateSendButton(animated: Bool) {
        if textField.text != nil && textField.text != "" {
            sendButton.isEnabled = true
            if animated {
                UIView.animate(withDuration: 0.25) {
                    self.sendButton.alpha = 1
                    self.previewButtonBackgroundView.alpha = 1
                }
            } else {
                self.sendButton.alpha = 1
                self.previewButtonBackgroundView.alpha = 1
            }
        } else {
            sendButton.isEnabled = false
            if animated {
                UIView.animate(withDuration: 0.25) {
                    self.sendButton.alpha = 0.5
                    self.previewButtonBackgroundView.alpha = 0.5
                }
            } else {
                self.sendButton.alpha = 0.5
                self.previewButtonBackgroundView.alpha = 0.5
            }
        }
    }
    
    func parseString(with text: String) -> [String] { //Bruh moment this took like an hour to write
        let text = text.trimmingCharacters(in: .whitespaces) + " "
        var devidedStrings: [String] = []
        var indexInString = 0
        while indexInString < text.count-1 { //This is -1 bc of whitespace addition
            if indexInString < text.count, text[indexInString] == " " {
                indexInString += 1
            }
            var line1 = ""
            for _ in 0 ..< 5 {
                if indexInString < text.count {
                    line1.append(text[indexInString])
                    indexInString += 1
                }
            }
            devidedStrings.append(line1)
            if indexInString < text.count, text[indexInString] == " " {
                indexInString += 1
            }
            if indexInString != text.count-1 {
                var breakpoint = indexInString
                for i in 0 ..< 6 {
                    if indexInString+5-i < text.count, text[indexInString+5-i] == " " {
                        breakpoint = indexInString+5-i
                        break
                    }
                }
                let currentIndex = indexInString
                var line2 = ""
                for i in currentIndex ..< breakpoint {
                    line2.append(text[i])
                    indexInString += 1
                }
                devidedStrings.append(line2)
            }
        }
        return devidedStrings
    }
    
    func getDataToUpload(from text: String, live: Bool) -> String {
        let delayTime = delayTime()
        let textColor = selectedTextColor
        var stringToUpload = ""
        if isFixedText {
            let parsedStrings = parseString(with: text)
            for i in 0 ..< parsedStrings.count {
                if i.isMultiple(of: 2) {
                    stringToUpload.append("f000000t1c0100\(textColor.rawValue)\(parsedStrings[i])|")
                } else {
                    stringToUpload.append("t1c0108\(textColor.rawValue)\(parsedStrings[i])|")
                    if i != parsedStrings.count-1 { //If not on last value append wait delay
                        stringToUpload.append("d\(delayTime)")
                    }
                }
            }
        } else {
            stringToUpload = "f000000t2c0001x\(textColor.rawValue)\(text)|s"
        }
        var startingString = ""
        var endingString = ""
        
        if live {
            endingString = "d\(delayTime)"
        } else {
            if persistentMessage {
                endingString = "d\(delayTime)r"
            } else {
                startingString = "b"
                endingString = "d\(delayTime)"
            }
        }
        
        let dataToUpload = "$\(startingString)\(stringToUpload)\(endingString)f000000^"
        return dataToUpload
    }
    
    func delayTime() -> Int {
        var range = scrollSpeedRange
        if isFixedText {
            range = fixedSpeedRange
        }
        let max = Double(range.max()!-range.min()!) //Get the difference between max and min value
        let currentSpeed = 1-speed //Reverse min and max so that highest value is lowest delay
        let multipliedValue = Int(currentSpeed*max) //Multiply by difference & convert to Int
        return multipliedValue+range.min()! //Add back in min range
    }
    
    @IBAction func textChanged(_ sender: Any) {
        currentText = textField.text //This is just for updating TF when switching between orientations
    }
    
    @IBAction func textModeChanged(_ sender: Any) {
        if textModeControl.selectedSegmentIndex == 0 {
            isFixedText = true
        } else {
            isFixedText = false
        }
    }
    
    @IBAction func speedChangeBegan(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @IBAction func speedValueChanged(_ sender: Any) {
        speed = Double(speedSlider.value)
        updateSpeedLabel()
    }
    
    func updateSpeedLabel() {
        if speed < 0.1 {
            speedLabel.text = "Hella Slow Speed"
        } else if speed < 0.45 {
            speedLabel.text = "Slow Speed"
        } else if speed < 0.7 {
            speedLabel.text = "Medium Speed"
        } else if speed < 0.9 {
            speedLabel.text = "Fast Speed"
        } else {
            speedLabel.text = "Zoomie Speed"
        }
    }
    
    @IBAction func previewButton(_ sender: Any) {
        if let text = textField.text, text != "" {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            let dataToUpload = getDataToUpload(from: text, live: true)
            ref.child(myPath).updateChildValues(["update": false, "live": dataToUpload])
            ref.child(myPath).child("update").setValue(true)
        }
    }
    
    @IBAction func optionButton(_ sender: Any) {
        let alert = UIAlertController(title: "Select Sending Style", message: "One-Time will show the message when \(otherName) presses the button, and will disapear after displaying the text. Persistent will show the text on repeat right away and disapear on button press.", preferredStyle: .actionSheet)
        let persistentAction = UIAlertAction(title: "Persistent", style: .default, handler: {_ in
            persistentMessage = true
            self.updateOptionButton()
        })
        let oneTimeAction = UIAlertAction(title: "One-Time", style: .default, handler: {_ in
            persistentMessage = false
            self.updateOptionButton()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(oneTimeAction)
        alert.addAction(persistentAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func updateOptionButton() {
        if persistentMessage {
            optionButtonLabel?.text = "Persistent"
        } else {
            optionButtonLabel?.text = "One-Time"
        }
    }
    
    
    @IBAction func sendButton(_ sender: Any) {
        if let text = textField.text, text != "" {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            let dataToUpload = getDataToUpload(from: text, live: false)
            
            let key = ref.child("fullLog").childByAutoId().key!
            ref.child("fullLog").child(key).setValue(dataToUpload)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let dateNow = formatter.string(from: Date())
            var messageType = MessageType.oneTimeText.rawValue
            if persistentMessage {
                messageType = MessageType.text.rawValue
            }
            let metaData: [String: Any] = [
                "dateSent": dateNow,
                "isJulia": amJulia,
                "messageType": messageType
            ]
            ref.child("shallowLog").child(key).setValue(metaData)
            ref.child(otherPath).child("pendingLog").child(key).setValue(key)
            NotificationCenter.default.post(name: .didSendMessage, object: nil)
            waitingForSuccess = true
            ref.child(otherPath).updateChildValues(["update": false, "received": false])
            ref.child(otherPath).updateChildValues(["update": true])
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                self.ref.child("matrixTest").updateChildValues(["update": true])
//            }
            
            
            textField.text = nil
            updateSendButton(animated: true)
        }
    }
    
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
