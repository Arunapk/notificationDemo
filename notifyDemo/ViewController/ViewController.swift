//
//  ViewController.swift
//  notifyDemo
//
//  Created by Arunpandikumar MAC Book Pro on 04/11/24.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func btnActs(_ sender: UIButton) {
        self.scheduleLocalNotification()
    }
    
    func scheduleLocalNotification() {
        // Request permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
                return
            }
            
            if granted {
                // Create the notification content
                let content = UNMutableNotificationContent()
                content.title = "Hello!"
                content.body = "This is your local notification."
                content.sound = .default

                // Set the trigger time (e.g., 5 seconds from now)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

                // Create the request
                let request = UNNotificationRequest(identifier: "localNotification", content: content, trigger: trigger)

                // Schedule the notification
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error adding notification: \(error)")
                    } else {
                        print("Notification scheduled successfully!")
                    }
                }
            } else {
                print("Notification permission not granted.")
            }
        }
    }
    

}

