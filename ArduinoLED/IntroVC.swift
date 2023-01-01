//
//  IntroVC.swift
//  ArduinoLED
//
//  Created by Oliver Elliott on 4/29/21.
//

import UIKit

class IntroVC: UIViewController {
    
    @IBOutlet var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let firstInstall = !UserDefaults.getBool(key: .firstInstall)
        if firstInstall {
            let array = StringInterpretationStruct.getPreSavedDrawings()
            var savedDrawings: [[String]] = []
            for drawing in array {
                savedDrawings.append(drawing.map{$0.rawValue})
            }
            UserDefaults.save(savedDrawings, key: .savedDrawings)
            UserDefaults.save(!false, key: .firstInstall)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let dateString = "2020-05-10"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let anniversaryDate = formatter.date(from: dateString)!
//        let testDateString = "2021-07-11"
//        let testDate = formatter.date(from: testDateString)!
        let currentDate = Date()
        let timeSinceAnniversary = Calendar.current.dateComponents([.day, .month, .year], from: anniversaryDate, to: currentDate)
        let diffInYears = timeSinceAnniversary.year!
        let diffInMonths = timeSinceAnniversary.month!
        let diffInDays = timeSinceAnniversary.day!
        let yearsString = addPluralIfNeeded(with: diffInYears, to: "\(diffInYears) year")
        let monthsString = addPluralIfNeeded(with: diffInMonths, to: "\(diffInMonths) month")
        let daysString = addPluralIfNeeded(with: diffInDays, to: "\(diffInDays) day")
        animateDateLabel(delay: 0, duration: 0.5, text: yearsString, completion: {
            if diffInMonths > 0 {
                self.animateDateLabel(delay: 0.5, duration: 0.5, text: monthsString, completion: {
                    if diffInDays > 0 {
                        self.showDays(with: daysString)
                    } else {
                        self.moveOn()
                    }
                })
            } else {
                if diffInDays > 0 {
                    self.showDays(with: daysString)
                } else {
                    self.moveOn()
                }
            }
        })
    }
    
    func showDays(with days: String) {
        self.animateDateLabel(delay: 0.5, duration: 0.5, text: days, completion: {
            self.moveOn()
        })
    }
    
    func moveOn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.performSegue(withIdentifier: "IntroSegue", sender: self)
        }
    }
    
    func addPluralIfNeeded(with int: Int, to string: String) -> String {
        if int != 1 {
            return "\(string)s"
        }
        return string
    }
    
    func animateDateLabel(delay: Double, duration: Double, text : String, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIView.transition(with: self.dateLabel, duration: duration/2, options: .transitionCrossDissolve, animations: {
                self.dateLabel.text = nil
            }, completion: {_ in
                UIView.transition(with: self.dateLabel, duration: duration/2, options: .transitionCrossDissolve, animations: {
                    self.dateLabel.text = text
                }, completion: {_ in
                    completion()
                })
            })
        }
    }
    
}
