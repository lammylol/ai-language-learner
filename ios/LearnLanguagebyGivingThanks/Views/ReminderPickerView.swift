//
//  ReminderPickerView.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 3/25/25.
//

import SwiftUI
import SwiftData

struct ReminderPickerLabel: View {
    @Query var userSettings: [UserSettings]
    @Binding var showDatePickerPopUp: Bool
    
    // Get notificationSchedules.
    var notificationSchedules: [NotificationSchedule]? {
        userSettings.first?.notificationSchedules
    }
    
    // Get notificationSchedule first.
    var selectedDayInitials: [String] {
        userSettings.first?.notificationSchedules?.compactMap { schedule in
            Day.from(weekdayNumber: schedule.weekday)?.rawValue.prefix(1).uppercased()
        } ?? []
    }
    
    // Only pick up time from notificationSchedule.
    var time: String {
        guard let schedule = notificationSchedules?.first else { return "12:00 AM" }
        
        let hourValue = schedule.hour
        let minute = schedule.minute
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Format for 12-hour time with AM/PM
        
        // Create a Date object for today at the specified hour
        let date = Calendar.current.date(bySettingHour: hourValue, minute: minute, second: 0, of: Date()) ?? Date()
        
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            if let schedule = notificationSchedules?.first {
                Text("\(schedule.repeatSchedule.rawValue.capitalized) \(selectedDayInitials.joined(separator: ", "))")
                    .font(.callout)
                    .fontWeight(.light)
                    .multilineTextAlignment(.trailing)
            }
            VStack(alignment: .trailing) {
                Button {
                    showDatePickerPopUp.toggle()
                } label: {
                    if userSettings.first?.isReminderOn == true {
                        VStack {
                            Text("\(time)")
                        }
                    } else {
                        Text("Set a Daily Reminder")
                            .font(.callout)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
//
//
//#Preview {
//    ReminderPickerView()
//}
