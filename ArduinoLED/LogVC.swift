//
//  LogTVC.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/10/21.
//

import UIKit
import Firebase

var amJulia = false

var otherName: String {
    if amJulia {
        return "Oliver"
    } else {
        return "Julia"
    }
}

let oliverPath = "Oliver"
let juliaPath = "Julia"

var myPath: String {
    if amJulia {
        return juliaPath
    } else {
        return oliverPath
    }
}

var otherPath: String {
    if amJulia {
        return oliverPath
    } else {
        return juliaPath
    }
}

enum MessageType: String {
    case drawing = "drawing"
    case oneTimeDrawing = "oneTimeDrawing"
    case text = "text"
    case oneTimeText = "oneTimeText"
}

struct MessageLogStruct {
    var isJulia: Bool
    var messageType: MessageType
    var dataIndex: String
    var delivered: Bool
    var opened: Bool
    var dateSent: Date
    var dateOpened: Date?
    var clean: Bool
}

class LogVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var ref: DatabaseReference!
    
    var shallowLogRef: DatabaseReference!
    
    var messageLog: [MessageLogStruct] = []
    
    var lastUpdateIndex: String! //Makes sure TV doesnt update cells until after all cells have loaded
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        shallowLogRef = ref.child("shallowLog")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sendToBottom), name: .scrollToBottomLog, object: nil)
        
        listenForUpdates()
        
        //Test Stuff
//        let testDate1String = "2021-04-03 14-37-00"
//        let testDate2String = "2021-04-19 20-53-35"
//        let testDate3String = "2021-04-25 12-37-00"
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
//        let testDate1 = formatter.date(from: testDate1String)!
//        let testDate2 = formatter.date(from: testDate2String)!
//        let testDate3 = formatter.date(from: testDate3String)!
//
//        let testMessage1 = MessageLogStruct(isJulia: true, messageType: .drawing, dataIndex: "", dateSent: testDate1, dateOpened: testDate2)
//        let testMessage2 = MessageLogStruct(isJulia: false, messageType: .text, dataIndex: "", dateSent: testDate2, dateOpened: testDate3)
//        let testMessage3 = MessageLogStruct(isJulia: false, messageType: .oneTimeDrawing, dataIndex: "", dateSent: testDate3)
//
//        messageLog = [testMessage1, testMessage2, testMessage3]
//
//        messageLog = messageLog.sorted(by: {$0.dateSent.compare($1.dateSent) == .orderedDescending })
        
    }
    
//    func getLogFromDatabase() {
//        shallowLogRef.getData(completion: { (error, snapshot) in
//            if let error = error {
//                print("Error getting data \(error)")
//            } else if snapshot.exists() {
//                var messages: [MessageLogStruct] = []
//                for child in snapshot.children {
//                    let message = self.structureData(from: child as! DataSnapshot)
//                    messages.append(message)
//                }
//                //self.sortMessageLog()
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                    //self.listenForUpdates()
//                }
//            }
//        })
//    }
    
    func structureData(from snapshot: DataSnapshot) -> MessageLogStruct {
        let data = snapshot.value as! [String : Any]
        let delivered = data["delivered"] as? Bool ?? false
        let opened = data["opened"] as? Bool ?? false
        let dateSentString = data["dateSent"] as! String
        let dateOpenedString = data["dateOpened"] as? String
        let isJulia = data["isJulia"] as! Bool
        let messageTypeString = data["messageType"] as! String
        let dataIndex = snapshot.key
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let dateSent = formatter.date(from: dateSentString)!
        var dateOpened: Date?
        if let dateOpenedString = dateOpenedString {
            dateOpened = formatter.date(from: dateOpenedString)
        }
        let messageType = MessageType(rawValue: messageTypeString)!
        
        
        let message = MessageLogStruct(isJulia: isJulia, messageType: messageType, dataIndex: dataIndex, delivered: delivered, opened: opened, dateSent: dateSent, dateOpened: dateOpened, clean: false)
        return message
    }
    
    func sortMessageLog() {
        messageLog = messageLog.sorted(by: {$0.dateSent.compare($1.dateSent) == .orderedDescending })
    }
    
    func listenForUpdates() {
        shallowLogRef.observe(.childAdded, with: { (snapshot) -> Void in
            let data = self.structureData(from: snapshot)
            self.messageLog.insert(data, at: 0)
            self.lastUpdateIndex = data.dataIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.lastUpdateIndex == data.dataIndex {
                    var insertPaths: [IndexPath] = []
                    for i in 0 ..< self.messageLog.count-self.tableView.numberOfRows(inSection: 0) {
                        insertPaths.append(IndexPath(row: i, section: 0))
                    }
                    //print("Insert rows: \(insertPaths) with last ID: \(self.lastUpdateIndex)")
                    self.tableView.insertRows(at: insertPaths, with: .automatic)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        print("Reloading TV")
                        self.sortMessageLog()
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        })
        
        shallowLogRef.observe(.childChanged, with: { (snapshot) -> Void in
            let data = self.structureData(from: snapshot)
            let index = self.messageLog.firstIndex(where: {$0.dataIndex == data.dataIndex})
            if let index = index {
                self.messageLog[index] = data
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageLog.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let message = messageLog[indexPath.row]
        let incomingMessage = amJulia != message.isJulia
        if incomingMessage {
            let firstOutgoingCell = messageLog.firstIndex(where: {$0.isJulia == amJulia}) ?? 0
            let isReplayCell = indexPath.row < firstOutgoingCell && message.opened
            var ID = "IncomingMessageCell"
            if isReplayCell {
                ID = "IncomingReplayMessageCell"
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: ID, for: indexPath) as! IncomingMessageCell
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            cell.view.layer.cornerRadius = 5
            cell.mainLabel.text = getStringFromMessageType(message.messageType)
            cell.dateLabel.text = formatDateToString(from: message.dateSent)
            cell.imageIcon.image = UIImage(named: message.messageType.rawValue)
            cell.imageIcon.tintColor = UIColor(named: "MainColor")
            if let replayButton = cell.replayButton, isReplayCell {
                replayButton.tag = indexPath.row
                replayButton.addTarget(self, action: #selector(replayButtonTapped), for: .touchUpInside)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OutgoingMessageCell", for: indexPath) as! OutgoingMessageCell
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            cell.view.layer.cornerRadius = 5
            cell.mainLabel.text = getStringFromMessageType(message.messageType)
            cell.dateLabel.text = formatDateToString(from: message.dateSent)
            cell.imageIcon.image = UIImage(named: message.messageType.rawValue)
            cell.imageIcon.tintColor = UIColor(named: "MainColor")
            //Find first cell where delivered and am user
            let lastDeliveredIndex = messageLog.firstIndex(where: {$0.isJulia == amJulia && ($0.delivered || $0.opened)})
            let isLastOpenCell = messageLog.firstIndex(where: {$0.isJulia == amJulia && $0.opened})
            let isValidCell = lastDeliveredIndex == indexPath.row || isLastOpenCell == indexPath.row
            if let dateOpened = message.dateOpened, isValidCell {
                cell.openedLabel.text = "Opened \(formatDateToString(from: dateOpened))"
            } else if message.opened && isValidCell {
                cell.openedLabel.text = "Opened"
            } else if message.delivered && isValidCell {
                cell.openedLabel.text = "Delivered"
            } else {
                cell.openedLabel.text = nil
            }
            return cell
        }
    }
    
    @objc func replayButtonTapped(_ button: UIButton) {
        //Get message
        let message = messageLog[button.tag]
        let ID = message.dataIndex
        if message.clean {
            replayMessage(for: ID)
        } else {
            //Get data from firebase
            ref.child("fullLog").child(ID).getData(completion: { (error,snapshot) in
                if let error = error {
                    print("Error getting data \(error)")
                } else if snapshot.exists() {
                    let data = snapshot.value as! String
                    //Remove button references
                    let cleanData = data.replacingOccurrences(of: "b", with: "").replacingOccurrences(of: "n", with: "d5000")
                    self.ref.child("fullLog").child(ID).setValue(cleanData, withCompletionBlock: { (error,_) in
                        if let error = error {
                            print("Error setting clean data \(error)")
                        } else {
                            self.messageLog[button.tag].clean = true
                            print("Success uploading clean data")
                        }
                    })
                    self.replayMessage(for: ID)
                }
            })
        }
    }
    
    func replayMessage(for ID: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        ref.child(myPath).child("pendingLog").child(ID).setValue(ID)
        ref.child(myPath).updateChildValues(["update": false])
        ref.child(myPath).updateChildValues(["update": true])
    }
    
    func getStringFromMessageType(_ messageType: MessageType) -> String {
        switch messageType {
        case .drawing:
            return "Sent a Persistent Drawing"
        case .oneTimeDrawing:
            return "Sent a One-Time Drawing"
        case .text:
            return "Sent a Persistent Text"
        case .oneTimeText:
            return "Sent a One-Time Text"
        }
    }
    
    func formatDateToString(from date: Date) -> String {
        let formatter = DateFormatter()
        let currentDate = Date()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a" //Formats for 8:27 am
            return "Yesterday \(formatter.string(from: date))"
        } else if let diff = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour, diff < 24 {
            formatter.dateFormat = "h:mm a" //Formats for 8:27 am
            return "Today \(formatter.string(from: date))"
        } else if let diff = Calendar.current.dateComponents([.day], from: date, to: currentDate).day, diff < 7 {
            formatter.dateFormat = "EEEE h:mm a" //Formats for Thursday
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "M/d/yy" //Formats for month day year
            return formatter.string(from: date)
        }
    }
    
    @objc func sendToBottom() {
        tableView.setContentOffset(.zero, animated: true)
    }
    
}

class IncomingMessageCell: UITableViewCell {
    
    @IBOutlet var view: UIView!
    @IBOutlet var mainLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageIcon: UIImageView!
    @IBOutlet var replayButton: UIButton?
    
}

class OutgoingMessageCell: UITableViewCell {
    
    @IBOutlet var view: UIView!
    @IBOutlet var mainLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageIcon: UIImageView!
    @IBOutlet var openedLabel: UILabel!
    
}
