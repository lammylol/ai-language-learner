//
//  NotificationService.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/6/24.
//

import Foundation
import UserNotifications
import SwiftData
import SwiftUI

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
    
    func configureNotification(title: String, body: String, time: DateComponents, repeatSchedule: RepeatSchedule, selectedDays: [Day], context: ModelContext) async throws {
        
        // Configure the notification's payload.
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        // remove existing notification schedule to replace it.
        deleteAllNotifications(context: context)
        
        switch repeatSchedule {
        case .daily:
            await configureDailySchedule(content: content, time: time, repeatSchedule: repeatSchedule, context: context)
        case .weekly:
            guard !selectedDays.isEmpty else {
                NotificationLogger.log("NotificationService: No days selected for repeat schedule.")
                return
            }
            await configureWeeklySchedule(content: content, time: time, selectedDays: selectedDays, context: context, repeatSchedule: repeatSchedule)
        }
    }
    
    func configureDailySchedule(content: UNMutableNotificationContent, time: DateComponents, repeatSchedule: RepeatSchedule, context: ModelContext) async {
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time, repeats: true)
        
        let uuid = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
        
        await setNotifications(request: request, dateComponents: time, repeatSchedule: repeatSchedule, context: context)
    }
    
    func configureWeeklySchedule(content: UNMutableNotificationContent, time: DateComponents, selectedDays: [Day], context: ModelContext, repeatSchedule: RepeatSchedule) async {
        let schedule = getSchedule(time: time, selectedDays: selectedDays)
        
        for dateComponents in schedule {
            // Create the trigger as a repeating event.
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents, repeats: true)
            
            let uuid = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
            
            await setNotifications(request: request, dateComponents: dateComponents, repeatSchedule: repeatSchedule, context: context)
        }
    }
    
    // Set notificiations locally and in the system.
    func setNotifications(request: UNNotificationRequest, dateComponents: DateComponents, repeatSchedule: RepeatSchedule, context: ModelContext) async {
        let notificationCenter = UNUserNotificationCenter.current()
        
        do {
            try await notificationCenter.add(request)
            saveNotificationLocally(time: dateComponents, day: dateComponents.weekday ?? 0, repeatSchedule: repeatSchedule, context: context)
            try context.save()
            NotificationLogger.log("NotificationService: Success setting notification: \(dateComponents.weekday ?? 0) at \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0) \(repeatSchedule.rawValue)")
        } catch {
            NotificationLogger.log("NotificationService: Error setting notifications: \(error.localizedDescription)")
        }
    }
    
    func getSchedule(time: DateComponents, selectedDays: [Day]) -> [DateComponents] {
        var schedule: [DateComponents] = []

        for day in selectedDays {
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            
            dateComponents.weekday = day.weekdayNumber
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute

            schedule.append(dateComponents)
        }
        
        return schedule
    }
    
    // Function to save to local data via SwiftData. Stores the notification schedule.
    func saveNotificationLocally(time: DateComponents, day: Int, repeatSchedule: RepeatSchedule, context: ModelContext) {
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        let notification = NotificationSchedule(weekday: day, hour: hour, minute: minute, repeatSchedule: repeatSchedule)
    
        do {
            // Fetch the existing UserSettings object
            let settingsFetch = try context.fetch(FetchDescriptor<UserSettings>())

            if let userSettings = settingsFetch.first {
                userSettings.notificationSchedules = (userSettings.notificationSchedules ?? []) + [notification]
            } else {
                let newUserSettings = UserSettings(isReminderOn: true, language: .kr, notificationSchedules: [notification])
                context.insert(newUserSettings)
            }
            
            try context.save()
            ViewLogger.log("NotificationService: Successfully saved notification locally: \(notification.weekday), \(notification.hour):\(notification.minute)")
            
        } catch {
            ViewLogger.log("NotificationService: Error saving notification locally: \(error)")
        }
    }
    
    func deleteAllNotifications(context: ModelContext) {
        do {
            // Fetch the UserSettings object
            let settingsFetch = try context.fetch(FetchDescriptor<UserSettings>())
            
            if let userSettings = settingsFetch.first {
                // Clear notification schedules in UserSettings
                userSettings.notificationSchedules?.removeAll()
                
                // Save changes to SwiftData
                try context.save()
            }
            
            // Remove all notifications from UserNotificationCenter
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.removeAllPendingNotificationRequests()
            notificationCenter.removeAllDeliveredNotifications()
            
            ViewLogger.log("NotificationService: Successfully deleted all notifications from UserSettings and system notifications.")
        } catch {
            ViewLogger.log("NotificationService: Error deleting notifications. \(error)")
        }
    }
}
