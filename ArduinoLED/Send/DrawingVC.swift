//
//  DrawingVC.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/10/21.
//

import UIKit
import Firebase

struct SavedDrawingsStruct {
    var image: CGImage
    var data: [MatrixColor]
}

enum MatrixColor: String, CaseIterable, Codable {
    case black = "000000"
    case white = "151515"
    case gray = "050505"
    case lowWhite = "010101"
    case red = "150000"
    case lowRed = "010000"
    case mintGreen = "051500"
    case green = "001500"
    case lowGreen = "000100"
    case blue = "000015"
    case lowBlue = "000001"
    case lightBlue = "001515"
    case lowLightBlue = "000101"
    case yellow = "150700"
    case lowYellow = "030100"
    case orange = "150200"
    case lowOrange = "150100"
    case pink = "150006"
    case lowPink = "040001"
    case darkPink = "150002"
    case purple = "080015"
    case lowPurple = "010001"
}

//Night mode can have its own separate enum containg values of the regular color enum


var selectedColor: MatrixColor = .white

var matrixHistory: [[MatrixColor]]!
var currentMatrixIndex = 0

///If live mode is activated in draing mode
var isLive = false

var persistentDrawingMessage = false

class DrawingVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    @IBOutlet var matrixCollectionView: UICollectionView!
    @IBOutlet var colorsCollectionView: UICollectionView!
    @IBOutlet var savedCollectionView: UICollectionView?
    
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var undoButton: UIButton!
    @IBOutlet var redoButton: UIButton!
    @IBOutlet var saveButton: UIButton?
    
    @IBOutlet var portraitSendButton: UIButton?
    @IBOutlet var landscapeSendButton: UIButton?
    
    @IBOutlet var portraitLiveButtonBackgroundView: UIView?
    @IBOutlet var liveButtonLabel: UILabel?
    @IBOutlet var portraitLiveButton: UIButton?
    
    @IBOutlet var landscapeLiveButtonBackgroundView: UIView?
    @IBOutlet var landscapeLiveButton: UIButton?
    
    
    @IBOutlet var optionButtonBackgroundView: UIView?
    @IBOutlet var optionButtonLabel: UILabel?
    @IBOutlet var optionButton: UIButton!
    
    
    let startingColors = Array(repeating: MatrixColor.black, count: 16*32)
    
    var savedDrawings: [SavedDrawingsStruct] = []
    var editingSavedCellIndexPath: IndexPath?
    
    var ref: DatabaseReference!
    
    var tap: UIGestureRecognizer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        matrixCollectionView.delegate = self
        matrixCollectionView.dataSource = self
        colorsCollectionView.delegate = self
        colorsCollectionView.dataSource = self
        if let savedCollectionView = savedCollectionView {
            savedCollectionView.delegate = self
            savedCollectionView.dataSource = self
        }
        
        matrixHistory = [startingColors]
        
        getSavedDrawings(compleation: { allDrawings in
            self.savedDrawings = allDrawings
            var indexPaths: [IndexPath] = []
            for i in 0 ..< allDrawings.count {
                indexPaths.append(IndexPath(item: i, section: 0))
            }
            self.savedCollectionView?.insertItems(at: indexPaths)
        })
        
        //Setup long press gesture recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        //lpgr.delaysTouchesBegan = true
        savedCollectionView?.addGestureRecognizer(lpgr)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(deselectLastSavedCell))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
        
        if portraitLiveButton != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(pushLiveifNeeded), name: .didFinishSwipe, object: nil)
            disableLive(withUpdate: false) //Make sure to clear any leftover live data
        }
        
        updateButtons()
        updateOptionButton()
        
        portraitSendButton?.layer.cornerRadius = 10
        landscapeSendButton?.layer.cornerRadius = (landscapeSendButton?.bounds.height)!/2
        
        portraitLiveButtonBackgroundView?.layer.cornerRadius = 10
        landscapeLiveButtonBackgroundView?.layer.cornerRadius = (landscapeLiveButtonBackgroundView?.bounds.height)!/2
        
        optionButtonBackgroundView?.layer.cornerRadius = 10
    }
    
    func getSavedDrawings(compleation: @escaping ([SavedDrawingsStruct]) -> ()) {
        DispatchQueue.main.async {
            let dataOnly = UserDefaults.getArray(key: .savedDrawings) as? [[String]] ?? []
            var allDrawings: [SavedDrawingsStruct] = []
            for matrix in dataOnly {
                let colorMatrix = matrix.map({(MatrixColor(rawValue: $0) ?? .black)})
                let cgImage = self.makeImageFromMatrixColors(colorMatrix)
                allDrawings.append(SavedDrawingsStruct(image: cgImage, data: colorMatrix))
            }
            compleation(allDrawings)
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        updateButtons()
        updateLiveButton(switchLive: false)
        matrixCollectionView.reloadData()
        colorsCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == matrixCollectionView {
            return 16*32
        } else if collectionView == colorsCollectionView {
            return MatrixColor.allCases.count
        } else {
            return savedDrawings.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == matrixCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "basicCVCell", for: indexPath) as! BasicCVCell
            cell.colorView.backgroundColor = UIColor(named: matrixHistory[currentMatrixIndex][indexPath.item].rawValue)
            //cell.colorView.layer.cornerRadius = cell.colorView.bounds.width/4
            return cell
        } else if collectionView == colorsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorSelectionCell", for: indexPath) as! ColorSelectionCell
            cell.outerColor.layer.cornerRadius = cell.outerColor.bounds.width/2
            cell.separation.layer.cornerRadius = cell.separation.bounds.width/2
            cell.innerColor.layer.cornerRadius = cell.innerColor.bounds.width/2
            let color = MatrixColor.allCases[indexPath.item].rawValue
            cell.outerColor.backgroundColor = UIColor(named: color)
            cell.innerColor.backgroundColor = UIColor(named: color)
            if selectedColor.rawValue == color {
                cell.separation.alpha = 1
            } else {
                cell.separation.alpha = 0
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SaveImageCell", for: indexPath) as! SaveImageCell
            cell.image.layer.cornerRadius = 4
            cell.image.image = UIImage(cgImage: savedDrawings[indexPath.row].image)
            cell.coverView.layer.cornerRadius = 4
            if indexPath == editingSavedCellIndexPath {
                cell.coverView.alpha = 0.7
            } else {
                cell.coverView.alpha = 0
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == matrixCollectionView {
            let noOfCellsInRow = 32.0
            //let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
            //let totalSpace = flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1)
            var widthAddition: Double = 3
            if landscapeSendButton != nil {
                widthAddition = 2
            }
            let width = Double((collectionView.bounds.width) / CGFloat(noOfCellsInRow + widthAddition))
            return CGSize(width: width, height: width)
            
//            let noOfCellsInRow = 10
//
//            let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
//
//            let totalSpace = flowLayout.sectionInset.left
//                + flowLayout.sectionInset.right
//                + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
//
//            let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
//
//            return CGSize(width: size, height: size)
            
        } else if collectionView == colorsCollectionView {
            return CGSize(width: 30, height: 30)
        } else {
            return CGSize(width: 120, height: 60)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView != matrixCollectionView {
            let spacing: CGFloat = CGFloat(9*collectionView.numberOfItems(inSection: 0))
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        }
        return UIEdgeInsets.zero
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets.zero
//    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == matrixCollectionView {
            return 1
        } else {
            return 10
        }
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .began {
            return
        }
        
        let p = gesture.location(in: self.savedCollectionView)
        
        if let indexPath = self.savedCollectionView?.indexPathForItem(at: p) {
            deselectLastSavedCell()
            editingSavedCellIndexPath = indexPath
            let cell = self.savedCollectionView?.cellForItem(at: indexPath) as! SaveImageCell
            UIView.animate(withDuration: 0.3) {
                cell.coverView.alpha = 0.7
            }
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        } else {
            print("Couldn't find index path")
        }
    }
    
    @objc func deselectLastSavedCell() {
        if let indexPath = editingSavedCellIndexPath {
            let cell = savedCollectionView?.cellForItem(at: indexPath) as! SaveImageCell
            UIView.animate(withDuration: 0.3) {
                cell.coverView.alpha = 0
            }
            editingSavedCellIndexPath = nil
        }
    }
    
    //Stops tap gesture from spilling over to other views
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == tap {
            return touch.view == gestureRecognizer.view
        } else {
            return true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    //Make CGImage from the matrix colors inputted
    func makeImageFromMatrixColors(_ matrixColors: [MatrixColor]) -> CGImage {
        
        var srgbArray: [UInt32] = []

        for color in matrixColors {
            srgbArray.append(UIColor(named: color.rawValue)!.hexa)
        }
        
        let multiplier = 10
        
        srgbArray = increaseResolution(of: srgbArray, by: multiplier)
        
        let width = 32*multiplier
        let height = 16*multiplier
        
        let cgImg = srgbArray.withUnsafeMutableBytes { (ptr) -> CGImage in
            let ctx = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 4*width,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue +
                    CGImageAlphaInfo.premultipliedFirst.rawValue
            )!
            return ctx.makeImage()!
        }
        
        return cgImg
    }
    
    //Increase reolution of 2D array
    func increaseResolution(of array: [UInt32], by multiplier: Int) -> [UInt32] {
        var newArray: [UInt32] = []
        for i in 0 ..< 16 {
            var xArray: [UInt32] = []
            for j in 0 ..< 32 {
                for _ in 0 ..< multiplier {
                    xArray.append(array[(i*32)+j])
                    //print((i*j)+j)
                }
            }
            for _ in 0 ..< multiplier {
                newArray.append(contentsOf: xArray)
            }
        }
        return newArray
    }
    
    func getXY(from item: Int) -> (Int, Int) {
        let x = item % 32
        let y = Int(item/32)
        return (x,y)
    }
    
    func intToTwoCharString(_ int: Int) -> String {
        if int < 10 {
            return "0\(int)"
        }
        return String(int)
    }
    
    func matrixSelectionDidBegin() {
        currentMatrixIndex += 1
        var newMatrixArray = Array(matrixHistory.prefix(currentMatrixIndex))
        newMatrixArray.append(newMatrixArray.last!)
        matrixHistory = newMatrixArray
        updateButtons(overideSaveButton: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == matrixCollectionView {
            var newIndexPath = indexPath
            if indexPath.section < 0 {
                newIndexPath = IndexPath(item: indexPath.item, section: 0)
                if indexPath.section == -2 {
                    matrixSelectionDidBegin()
                }
            } else {
                matrixSelectionDidBegin()
            }
            let cell = collectionView.cellForItem(at: newIndexPath) as! BasicCVCell
            cell.colorView.backgroundColor = UIColor(named: selectedColor.rawValue)
            matrixHistory[currentMatrixIndex][newIndexPath.item] = selectedColor
            collectionView.deselectItem(at: newIndexPath, animated: false)
            if indexPath.section == 0 {
                pushLiveifNeeded()
            }
        } else if collectionView == colorsCollectionView {
            selectedColor = MatrixColor.allCases[indexPath.row]
            colorsCollectionView.reloadData()
        } else {
            if indexPath == editingSavedCellIndexPath {
                savedDrawings.remove(at: indexPath.row)
                saveSavedDrawings()
                savedCollectionView?.deleteItems(at: [indexPath])
                editingSavedCellIndexPath = nil
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } else {
                currentMatrixIndex += 1
                var newMatrixArray = Array(matrixHistory.prefix(currentMatrixIndex))
                //newMatrixArray.append(savedDrawings[indexPath.row].data)
                
                //Temp
                let temp = Array(savedDrawings[indexPath.row].data.prefix(16*32))
                newMatrixArray.append(temp)
                
                matrixHistory = newMatrixArray
                updateButtons()
                matrixCollectionView.reloadData()
                pushLiveifNeeded()
            }
        }
        deselectLastSavedCell()
    }
    
    func getDataToSend(live: Bool) -> String {
        //Get most dominant color, for now just 000
        let dominantColor = MatrixColor.black
        let startColorString = "f\(dominantColor.rawValue)"
        var uploadColors: [String] = []
        //For each color, find the cords and write them in an array
        for color in MatrixColor.allCases where color != dominantColor {
            var cordinates: [String] = []
            for i in 0 ..< matrixHistory[currentMatrixIndex].count where matrixHistory[currentMatrixIndex][i] == color {
                let xy = getXY(from: i)
                cordinates.append("\(intToTwoCharString(xy.0))\(intToTwoCharString(xy.1))")
            }
            if cordinates.count > 0 {
                uploadColors.append("p\(color.rawValue)\(cordinates.joined())e")
            }
        }
        
//        for i in 0 ..< matrixHistory[currentMatrixIndex].count {
//            let color = matrixHistory[currentMatrixIndex][i]
//            if color != dominantColor {
//                let xy = getXY(from: i)
//                uploadColors.append("p\(xy.0).\(xy.1).\(color.rawValue)")
//            }
//        }
        
        var startingString = ""
        var endingString = ""
        
        if live {
            endingString = "d\(60*1000)" //Wait 1 min before clearing in live mode
        } else {
            if persistentDrawingMessage {
                endingString = "n" //Non-skip button press
            } else {
                startingString = "b"
                endingString = "d5000"
            }
        }
        
        let uploadColorString = "$" + startingString + startColorString + uploadColors.joined() + endingString + "f000000^"
        return uploadColorString
    }
    
    @IBAction func clearButton(_ sender: Any) {
        matrixHistory = [startingColors]
        currentMatrixIndex = 0
        pushLiveifNeeded()
        updateButtons()
        matrixCollectionView.reloadData()
        //In case cell is selected
        deselectLastSavedCell()
    }
    
    @IBAction func undoButton(_ sender: Any) {
        currentMatrixIndex -= 1
        pushLiveifNeeded()
        updateButtons()
        matrixCollectionView.reloadData()
        //In case cell is selected
        deselectLastSavedCell()
    }
    
    @IBAction func redoButton(_ sender: Any) {
        currentMatrixIndex += 1
        pushLiveifNeeded()
        updateButtons()
        matrixCollectionView.reloadData()
        //In case cell is selected
        deselectLastSavedCell()
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let currentMatrix = matrixHistory[currentMatrixIndex]
        let historyInsert = SavedDrawingsStruct(image: makeImageFromMatrixColors(currentMatrix), data: currentMatrix)
        savedDrawings.insert(historyInsert, at: 0)
        savedCollectionView?.insertItems(at: [IndexPath(item: 0, section: 0)])
        updateButtons()
        saveSavedDrawings()
    }
    
    func saveSavedDrawings() {
        let dataOnly = savedDrawings.map({$0.data.map({$0.rawValue})})
        UserDefaults.save(dataOnly, key: .savedDrawings)
    }
    
    func updateButtons(overideSaveButton: Bool = false) {
        let allowedOverride = overideSaveButton && selectedColor != MatrixColor.black
        let undoEnabled = currentMatrixIndex != 0
        undoButton.isEnabled = undoEnabled
        let redoEnabled = currentMatrixIndex != matrixHistory.count-1
        redoButton.isEnabled = redoEnabled
        let arrayOfData = savedDrawings.map({$0.data})
        let saveEnabled = (currentMatrixIndex > 0 && !arrayOfData.contains(matrixHistory[currentMatrixIndex])) || allowedOverride
        saveButton?.isEnabled = saveEnabled
        let clearEnabled = matrixHistory.count > 1
        clearButton.isEnabled = clearEnabled
        let sendEnabled = matrixHistory[currentMatrixIndex] != startingColors || allowedOverride
        landscapeSendButton?.isEnabled = sendEnabled
        portraitSendButton?.isEnabled = sendEnabled
        UIView.animate(withDuration: 0.3) {
            if sendEnabled && (self.landscapeSendButton?.alpha == 0.5 || self.portraitSendButton?.alpha == 0.5) {
                self.landscapeSendButton?.alpha = 1
                self.portraitSendButton?.alpha = 1
            } else if !sendEnabled && (self.landscapeSendButton?.alpha == 1 || self.portraitSendButton?.alpha == 1) {
                self.landscapeSendButton?.alpha = 0.5
                self.portraitSendButton?.alpha = 0.5
            }
        }
    }
    
    @IBAction func liveButtonTapped(_ sender: Any) {
        updateLiveButton(switchLive: true)
        pushLiveifNeeded()
        if !isLive {
            disableLive(withUpdate: true)
        }
        //In case cell is selected
        deselectLastSavedCell()
    }
    
    func updateLiveButton(switchLive: Bool) {
        if switchLive {
            if isLive {
                UIView.animate(withDuration: 0.25) {
                    self.portraitLiveButtonBackgroundView?.backgroundColor = .secondarySystemBackground
                    self.landscapeLiveButtonBackgroundView?.backgroundColor = .secondarySystemBackground
                    self.landscapeLiveButton?.tintColor = .red
                    self.landscapeLiveButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
                }
                if let liveButtonLabel = liveButtonLabel {
                    UIView.transition(with: liveButtonLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                        self.liveButtonLabel?.textColor = .label
                    })
                }
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.portraitLiveButtonBackgroundView?.backgroundColor = .red
                    self.landscapeLiveButtonBackgroundView?.backgroundColor = .red
                    self.landscapeLiveButton?.tintColor = .white
                    self.landscapeLiveButton?.setImage(UIImage(systemName: "stop.fill"), for: .normal)
                }
                if let liveButtonLabel = liveButtonLabel {
                    UIView.transition(with: liveButtonLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                        self.liveButtonLabel?.textColor = .white
                    })
                }
            }
            isLive = !isLive
        } else {
            if isLive {
                portraitLiveButtonBackgroundView?.backgroundColor = .red
                liveButtonLabel?.textColor = .white
                landscapeLiveButtonBackgroundView?.backgroundColor = .red
                landscapeLiveButton?.tintColor = .white
                landscapeLiveButton?.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            } else {
                portraitLiveButtonBackgroundView?.backgroundColor = .secondarySystemBackground
                liveButtonLabel?.textColor = .label
                landscapeLiveButtonBackgroundView?.backgroundColor = .secondarySystemBackground
                landscapeLiveButton?.tintColor = .red
                landscapeLiveButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    @objc func pushLiveifNeeded() {
        if isLive {
            let dataToUpload = getDataToSend(live: true)
            ref.child(myPath).updateChildValues(["update": false, "live": dataToUpload])
            ref.child(myPath).child("update").setValue(true)
            print("Live pushed")
        }
    }
    
    func disableLive(withUpdate: Bool) {
        if withUpdate {
            ref.child(myPath).child("update").setValue(false)
            ref.child(myPath).child("live").setValue("$f000000^")
            ref.child(myPath).child("update").setValue(true)
        } else {
            ref.child(myPath).child("live").removeValue()
        }
    }
    
    @IBAction func optionButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Select Sending Style", message: "One-Time will show the message when \(otherName) presses the button, and will disapear after a few seconds. Persistent will show the drawing on \(otherName)'s display right away and disapear on button press.", preferredStyle: .actionSheet)
        let persistentAction = UIAlertAction(title: "Persistent", style: .default, handler: {_ in
            persistentDrawingMessage = true
            self.updateOptionButton()
        })
        let oneTimeAction = UIAlertAction(title: "One-Time", style: .default, handler: {_ in
            persistentDrawingMessage = false
            self.updateOptionButton()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(oneTimeAction)
        alert.addAction(persistentAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
        //In case cell is selected
        deselectLastSavedCell()
    }
    
    func updateOptionButton() {
        if persistentDrawingMessage {
            optionButtonLabel?.text = "Persistent"
        } else {
            optionButtonLabel?.text = "One-Time"
        }
    }
    
    @IBAction func sendButton(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let dataToUpload = getDataToSend(live: false)
        let key = ref.child("fullLog").childByAutoId().key!
        ref.child("fullLog").child(key).setValue(dataToUpload)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let dateNow = formatter.string(from: Date())
        var messageType = MessageType.oneTimeDrawing.rawValue
        if persistentDrawingMessage {
            messageType = MessageType.drawing.rawValue
        }
        let metaData: [String: Any] = [
            "dateSent": dateNow,
            "isJulia": amJulia,
            "messageType": messageType
        ]
        ref.child("shallowLog").child(key).setValue(metaData)
        ref.child(otherPath).child("pendingLog").child(key).setValue(key)
        if isLive { //Turn off live mode
            updateLiveButton(switchLive: true)
            disableLive(withUpdate: true)
        }
        waitingForSuccess = true
        NotificationCenter.default.post(name: .didSendMessage, object: nil)
        ref.child(otherPath).updateChildValues(["update": false, "received": false]) //Then listen for success
        ref.child(otherPath).updateChildValues(["update": true])
    }
    
}

extension UIColor {
    var hexa: UInt32 {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        var value: UInt32 = 0
        value += UInt32(alpha * 255) << 24
        value += UInt32(red   * 255) << 16
        value += UInt32(green * 255) << 8
        value += UInt32(blue  * 255)
        return value
    }
    convenience init(hexa: UInt32) {
        self.init(red  : CGFloat((hexa & 0xFF0000)   >> 16) / 255,
                  green: CGFloat((hexa & 0xFF00)     >> 8)  / 255,
                  blue : CGFloat( hexa & 0xFF)              / 255,
                  alpha: CGFloat((hexa & 0xFF000000) >> 24) / 255)
    }
}

//For ranges
extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}

class BasicCVCell: UICollectionViewCell {
    
    @IBOutlet var colorView: UIView!
    
}

class ColorSelectionCell: UICollectionViewCell {
    
    @IBOutlet var outerColor: UIView!
    @IBOutlet var separation: UIView!
    @IBOutlet var innerColor: UIView!
    
}

class SaveImageCell: UICollectionViewCell {
    
    @IBOutlet var image: UIImageView!
    @IBOutlet var coverView: UIView!
    
}
