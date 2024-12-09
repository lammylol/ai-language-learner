//
//  NotificationService.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/6/24.
//

import Foundation
import UserNotifications

class NotificationService {
    func getPendingNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getPendingNotificationRequests { requests in
            print("Pending Notifications: \(requests.count)")
            for request in requests {
                print("Identifier: \(request.identifier)")
                print("Content Title: \(request.content.title)")
                print("Content Body: \(request.content.body)")
                print("Trigger: \(String(describing: request.trigger))")
            }
        }
    }
    
    func getNotificationSettings() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                print("Notifications are authorized.")
            case .denied:
                print("Notifications are denied.")
            case .notDetermined:
                print("Notifications permission hasn't been requested yet.")
            default:
                print("Unknown authorization status.")
            }
        }
    }
    
    func configureNotification(title: String, body: String, time: Date, repeatSchedule: RepeatSchedule, selectedDays: [Day]) async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Configure the notification's payload.
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        print(selectedDays)
        print(repeatSchedule)
        print(time)
        
        let schedule = getSchedule(time: time, selectedDays: selectedDays)
        print(schedule.count)
        print(schedule)
        for dateComponents in schedule {
            // Create the trigger as a repeating event.
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents, repeats: true)
            
            let uuid = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
            
            do {
                try await notificationCenter.add(request)
                NotificationLogger.log("NotificationService: Success setting notification: \(dateComponents.weekday ?? 0) at \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
            } catch {
                NotificationLogger.log("NotificationService: Error setting notifications: \(error.localizedDescription)")
            }
        }
    }
    
    func getSchedule(time: Date, selectedDays: [Day]) -> [DateComponents] {
        var schedule: [DateComponents] = []
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        print(schedule.count)
        
        for day in selectedDays {
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            
            dateComponents.weekday = day.weekdayNumber
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            
            print(dateComponents.hour)
            
            schedule.append(dateComponents)
        }
        
//        schedule = selectedDays.map({ day in
//            var dateComponents = DateComponents()
//            dateComponents.calendar = Calendar.current
//            
//            dateComponents.weekday = day.weekdayNumber
//            dateComponents.hour = components.hour
//            dateComponents.minute = components.minute
//            
//            return dateComponents
//        })
        
        return schedule
    }
}
