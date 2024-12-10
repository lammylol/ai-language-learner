//
//  SetReminders.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/6/24.
//

import SwiftUI
import SwiftData

struct ReminderPopUp: View {
//    @Query(sort: \NotificationSchedule.weekday, order: .forward)
    @Query var schedule: [NotificationSchedule]
    @Query var userSettings: [UserSettings]
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
//    
    @State var scheduleTime: DateComponents = DateComponents()
    @State var repeatSchedule: RepeatSchedule = .daily
    @State var language: Language
    
    @State var reminderToggle: Bool = false
    @State var selectedDays: [Day] = []
    
    @State var tempDate: Date = Date()
    @State var tempRepeat: RepeatSchedule = .daily
    
    let notificationService = NotificationService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Reminders", isOn: $reminderToggle)
                }
                if reminderToggle {
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
                            WeekdayPicker(selectedDays: $selectedDays)
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
                Task {
                    await updateStateFromLocalData()
                    notificationService.getPendingNotifications()
                    notificationService.getNotificationSettings()
                }
            }
            .navigationTitle("Set Reminder" )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @MainActor
    func setDate() {
        Task {
            // Check notification authorization, request if not authorized
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            guard settings.authorizationStatus == .authorized else {
                do {
                    try await center.requestAuthorization(options: [.alert, .sound, .badge])
                } catch {
                    NotificationLogger.log("NotificationCenter Authorization Error: \(error).")
                    return
                }
                return
            }
            
            // update reminder toggle
            updateReminderToggle()
            
            // If reminders are disabled, delete all notifications and exit
            guard reminderToggle else {
                notificationService.deleteAllNotifications(context: context)
                dismiss()
                return
            }
            
            updateTempStateFromValues()
            
            // Configure the notification
            do {
                try await notificationService.configureNotification(
                    title: "What Are You Grateful For Today?",
                    body: "Reminder to practice your \(language.description.capitalized).",
                    time: scheduleTime,
                    repeatSchedule: repeatSchedule,
                    selectedDays: selectedDays,
                    context: context
                )
                ViewLogger.log("ReminderPopUp: Success configuring notifications")
                dismiss()
            } catch {
                NotificationLogger.log("ReminderPopUp Error: Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func updateStateFromLocalData() async {
        reminderToggle = userSettings.first?.isReminderOn ?? false
        
        if !schedule.isEmpty {
            var dateComponents = DateComponents()
            dateComponents.hour = schedule.first?.hour
            dateComponents.minute = schedule.first?.minute
            
            // Assuming `self.tempDate` is declared as a `Date?`
            if let fullDate = Calendar.current.date(from: dateComponents) {
                self.tempDate = fullDate
            }
            
            self.tempRepeat = schedule.first?.repeatSchedule ?? .daily
            
            self.selectedDays = schedule.compactMap {
                Day.from(weekdayNumber: $0.weekday)
            }
            
            ViewLogger.log("ContentView: updated state variables")
        }
    }
    
    func updateTempStateFromValues() {
        
        // update schedule time
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let time = calendar.dateComponents([.hour,.minute], from: tempDate)
        
        scheduleTime.hour = time.hour
        scheduleTime.minute = time.minute
        
        repeatSchedule = tempRepeat
        if repeatSchedule == .daily {
            selectedDays = []
        }
    }
    
    func updateReminderToggle() {
        if let existingSettings = userSettings.first {
            existingSettings.isReminderOn = reminderToggle
            print("updated reminderToggle: \(reminderToggle)")
        } else {
            let newSettings = UserSettings(isReminderOn: true)
            context.insert(newSettings)
            print("added reminderToggle: \(reminderToggle)")
        }
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

enum Day: String, CaseIterable, Codable {
    case Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
    
    var weekdayNumber: Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day name
        if let date = dateFormatter.date(from: rawValue) {
            let calendar = Calendar.current
            return calendar.component(.weekday, from: date)
        }
        return 0
    }

    static func from(weekdayNumber: Int) -> Day? {
        switch weekdayNumber {
        case 1: return .Sunday
        case 2: return .Monday
        case 3: return .Tuesday
        case 4: return .Wednesday
        case 5: return .Thursday
        case 6: return .Friday
        case 7: return .Saturday
        default: return nil
        }
    }
    
    var string: String {
        rawValue
    }
}

enum RepeatSchedule: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    
    init(from rawValue: String) {
        self = RepeatSchedule(rawValue: rawValue) ?? .daily
    }
}

//#Preview {
//    ReminderPopUp(
//        scheduleTime: .constant(Date()),
//        repeatSchedule: .constant(RepeatSchedule.weekly),
//        language: Language.kr,
//        reminderToggle: true,
//        selectedWeekdays: [.Sunday, .Monday]
//    )
//}
