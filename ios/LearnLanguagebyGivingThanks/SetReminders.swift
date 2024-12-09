//
//  SetReminders.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/6/24.
//

import SwiftUI

struct ReminderPopUp: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var scheduleTime: Date
    @Binding var repeatSchedule: RepeatSchedule
    @State var language: Language
    
    @State var reminderToggle: Bool = false
    @State var selectedWeekdays: [Day] = []
    
    @State var tempDate: Date = Date()
    @State var tempRepeat: RepeatSchedule = .daily
    @State var tempReminderToggle: Bool = false
    @State var tempSelectedWeekdays: [Day] = []
    
    let notificationService = NotificationService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Reminders", isOn: $tempReminderToggle)
                }
                if tempReminderToggle {
                    Section {
                        DatePicker("", selection: $tempDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                        Picker("Repeat", selection: $tempRepeat) {
                            ForEach(RepeatSchedule.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized)
                            }
                        }
                        if tempRepeat == .weekly {
                            WeekdayPicker(selectedDays: $tempSelectedWeekdays)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .bold()
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {setDate()}) {
                        Text("Save")
                            .bold()
                    }
                }
            }
            .onAppear {
                tempDate = scheduleTime
                tempRepeat = repeatSchedule
                tempReminderToggle = reminderToggle
                tempSelectedWeekdays = selectedWeekdays
                
                notificationService.getPendingNotifications()
                notificationService.getNotificationSettings()
            }
            .navigationTitle("Set Reminder" )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @MainActor
    func setDate() {
        Task {
            scheduleTime = tempDate
            repeatSchedule = tempRepeat
            reminderToggle = tempReminderToggle
            selectedWeekdays = tempSelectedWeekdays
            
            // check for authorization
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus != .authorized {
                NotificationLogger.log("ReminderPopUp Error: Notifications are not authorized.")
                
                let center = UNUserNotificationCenter.current()
                
                do {
                    try await center.requestAuthorization(options: [.alert, .sound, .badge])
                } catch {
                    // Handle the error here.
                    NotificationLogger.log("NotificationCenter Authorization Error: \(error).")
                }
            } else {
                do {
                    try await notificationService.configureNotification(
                        title: "What Are You Grateful For Today?",
                        body: "Reminder to practice your \(language.description.capitalized).",
                        time: scheduleTime,
                        repeatSchedule: repeatSchedule,
                        selectedDays: selectedWeekdays)
                    
                    dismiss()
                    ViewLogger.log("ReminderPopUp: Success configuring notifications")
                } catch {
                    NotificationLogger.log("ReminderPopUp Error: Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ReminderPickerLabel: View {
    var scheduleTime: Date

    @Binding var showDatePickerPopUp: Bool
    
    var body: some View {
        HStack (alignment: .center) {
            Text("Set a Daily Reminder")
                .font(.caption)
                .multilineTextAlignment(.trailing)
            VStack {
                Button {
                    showDatePickerPopUp.toggle()
                } label: {
                    Text(scheduleTime.formatted(date: .omitted, time: .shortened))
                }
            }
        }
        .frame(width: 185)
    }
}

struct WeekdayPicker: View {
    @Binding var selectedDays: [Day]
    
    var body: some View {
        HStack {
            ForEach(Day.allCases, id: \.self) { day in
                Text(String(day.rawValue.first!))
                    .frame(width: 40, height: 40)
                    .background(selectedDays.contains(day) ? Color.cyan.cornerRadius(10) : Color(UIColor.systemGray6).cornerRadius(10))
                    .foregroundStyle(selectedDays.contains(day) ? Color.white : Color.black)
                    .onTapGesture {
                        if selectedDays.contains(day) {
                            selectedDays.removeAll(where: {$0 == day})
                        } else {
                            selectedDays.append(day)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum Day: String, CaseIterable {
    case Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
    
    var weekdayNumber: Int {
        var dayOfWeek: Int = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day name
        if let date = dateFormatter.date(from: rawValue) {
            let calendar = Calendar.current
            dayOfWeek = calendar.component(.weekday, from: date)
        }
        return dayOfWeek
    }
}

enum RepeatSchedule: String, CaseIterable {
    case daily
    case weekly
}

#Preview {
    ReminderPopUp(
        scheduleTime: .constant(Date()),
        repeatSchedule: .constant(RepeatSchedule.weekly),
        language: Language.kr,
        reminderToggle: true,
        selectedWeekdays: [.Sunday, .Monday]
    )
}
