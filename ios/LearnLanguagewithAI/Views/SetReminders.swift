//
//  SetReminders.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 12/6/24.
//

import SwiftUI
import SwiftData

struct ReminderPopUp: View {
    @Query var userSettings: [UserSettings]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State var scheduleTime: DateComponents = DateComponents()
    @State var repeatSchedule: RepeatSchedule = .daily
    @State var language: Language
    
    @State var reminderToggle: Bool = false
    @State var selectedDays: [Day] = []
    
    @State var tempDate: Date = Date()
    @State var tempRepeat: RepeatSchedule = .daily
    
    let notificationService = NotificationService()
    
    var notificationSchedules: [NotificationSchedule] {
        userSettings.first?.notificationSchedules ?? []
    }

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
                    Button("Cancel") { dismiss() }
                        .bold()
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { setDate() }) {
                        Text("Save").bold()
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
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @MainActor
    func setDate() {
        Task {
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
            
            updateReminderToggle(reminderToggle: reminderToggle)
            
            guard reminderToggle else {
                notificationService.deleteAllNotifications(context: context)
                dismiss()
                return
            }
            
            updateTempStateFromValues()

            do {
                try await notificationService.configureNotification(
                    title: userSettings.first?.selectedPrompt.rawValue ?? "What Are You Grateful For?",
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
        
        if !notificationSchedules.isEmpty {
            var dateComponents = DateComponents()
            dateComponents.hour = notificationSchedules.first?.hour
            dateComponents.minute = notificationSchedules.first?.minute
            
            if let fullDate = Calendar.current.date(from: dateComponents) {
                self.tempDate = fullDate
            }
            
            self.tempRepeat = notificationSchedules.first?.repeatSchedule ?? .daily
            
            selectedDays = notificationSchedules.compactMap { schedule in
                Day.from(weekdayNumber: schedule.weekday)
            }
            
            ViewLogger.log("ReminderPopUp: updated state variables")
        }
    }
    
    func updateTempStateFromValues() {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: tempDate)
        
        scheduleTime.hour = time.hour
        scheduleTime.minute = time.minute
        repeatSchedule = tempRepeat
        
        if repeatSchedule == .daily {
            selectedDays = []
        }
        
        if let existingSettings = userSettings.first {
            existingSettings.notificationSchedules = [
                NotificationSchedule(
                    weekday: scheduleTime.weekday ?? 1, // Ensure you set a weekday
                    hour: scheduleTime.hour ?? 0,
                    minute: scheduleTime.minute ?? 0,
                    repeatSchedule: repeatSchedule
                )
            ]
            try? context.save()
        }
    }
    
    func updateReminderToggle(reminderToggle: Bool) {
        userSettings.first?.isReminderOn = reminderToggle
    }
}

struct WeekdayPicker: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedDays: [Day]
    
    var body: some View {
        HStack {
            ForEach(Day.allCases, id: \.self) { day in
                Text(String(day.rawValue.first!))
                    .frame(width: 40, height: 40)
                    .background(selectedDays.contains(day) ? Color.cyan.cornerRadius(10) : Color(UIColor.systemGray6).cornerRadius(10))
                    .foregroundStyle(selectedDays.contains(day) ? (colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white ) : (colorScheme == .dark ? Color.white : Color.black))
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

//#Preview {
//    ReminderPopUp(
//        scheduleTime: .constant(Date()),
//        repeatSchedule: .constant(RepeatSchedule.weekly),
//        language: Language.kr,
//        reminderToggle: true,
//        selectedWeekdays: [.Sunday, .Monday]
//    )
//}
