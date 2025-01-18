//
//  ContentView.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import SwiftUI
import Combine
import SwiftData

struct ContentView: View {
    @AppStorage("isWelcomeSheetShowing") var isWelcomeSheetShowing = true
    @Environment(\.modelContext) private var context
    @Environment(ContentViewModel.self) var viewModel
    
    @Query var schedule: [NotificationSchedule]
    @Query var userSettings: [UserSettings]
    
    @State var text: String = ""
    
    @State var scheduleTime: DateComponents = DateComponents()
    @State var repeatSchedule: RepeatSchedule = .daily
    @State var reminderToggle: Bool = false
    @State var selectedDays: [Day] = []

    @State private var keyboardHeight: CGFloat = 0 // Track keyboard height
    @State private var cancellables = Set<AnyCancellable>()
    
    private var languageAPIService: LanguageModelAPIService = LanguageModelAPIService()
    
    @FocusState var isTextEditorFocused: Bool
    @State var showDatePickerPopUp: Bool = false
    
    // Initialize observers to listen for keyboard notifications
    @State private var keyboardWillShow: AnyCancellable?
    @State private var keyboardWillHide: AnyCancellable?
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                LanguagePicker()
                    .pickerStyle(.menu)
                Spacer()
                ReminderPickerLabel(showDatePickerPopUp: $showDatePickerPopUp)
            }
            .frame(height: 50)
            
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.messageModel.messages) { message in
                            MessageView(message: message)
                            .id(message.id)
                            .allowsHitTesting(true)
                    }
                }
                .textSelection(.enabled)
                .layoutPriority(1)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaPadding(.bottom)
                .onChange(of: viewModel.messageModel.messages.count) {
                    // Scroll to the bottom whenever a new message is added
                    if let lastMessage = viewModel.messageModel.messages.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom) // Scroll to last message
                        }
                    }
                } // Scroll to bottom when new message is added.
                .onChange(of: isTextEditorFocused) {
                    DispatchQueue.main.async {
                        if let lastMessage = viewModel.messageModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom) // Scroll to last message
                            }
                        }
                    }
                }
            }
            
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .leading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 40, maxHeight: 600)
                        .fixedSize(horizontal: false, vertical: true)
                        .focused($isTextEditorFocused)
                        .padding(.leading, 5)
                        .padding(.trailing, 40)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1) // Optional border
                        )
                        .environment(\.locale, Locale(identifier: viewModel.language.localeIdentifier))
                    
                    if text.isEmpty {
                        Text(viewModel.language.enterMessage)
                            .foregroundStyle(.secondary).fontWeight(.light)
                            .padding(.leading, 10)
                            .padding(.bottom, 2)
                    }
                }
                Button {
                    submit()
                } label: {
                    VStack {
                        Image(systemName: viewModel.isFetching ? "square.fill" : "arrowshape.up.fill")
                            .resizable()  // Make the image resizable
                            .aspectRatio(contentMode: .fit)  // Maintain the aspect ratio
                            .padding(viewModel.isFetching ? 10 : 7)
                            .background(
                                Circle()
                                    .fill(text.isEmpty ? Color.gray : Color.blue) // Circle color
                                    .frame(width: 30, height: 30)
                            )
                            .foregroundStyle(.white)
                    }
                    .frame(width: 30, height: 30)
                }
                .padding(.trailing, 5)
                .padding(.bottom, 5)
                .disabled(text.isEmpty)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 15)
        .onChange(of: viewModel.language) {
            viewModel.onLanguageChange()
        } // Change language translation when language changes.
        .onChange(of: viewModel.isFetching) {
            viewModel.onChangeOfFetching()
        } // // Add a new message showing 'loading' when fetching.
        .onChange(of: viewModel.date) {
            viewModel.onDateChange()
        }
        .sheet(isPresented: $showDatePickerPopUp){
            ReminderPopUp(language: viewModel.language)
        }
        .onAppear {
            viewModel.language = userSettings.first?.selectedLanguage
        }
    }
    
    func submit() {
        Task {
            let prompt = text
            text = ""
            viewModel.messageModel.addMessage(Message(text: prompt, senderType: .user))
            isTextEditorFocused = false

            let response = await fetchHelper()
            viewModel.onChangeOfFetching()
            viewModel.messageModel.addMessage(Message(text: response, senderType: .bot))
        }
        print(viewModel.messageModel.messages.count)
    }
    
    func fetchHelper() async -> String {
        viewModel.isFetching = true
        defer { viewModel.isFetching = false }
        
        var response = ""
        print(viewModel.isFetching)
        
        do {
            // system instruction setting
            var systemInstruction: String?
            systemInstruction = "The user is trying to learn \(viewModel.language.description). Please provide them with corrections to their answer to the prompt 'what are you grateful for?'. Please respond to them in English."
            
            // response from model
            response = try await languageAPIService.languageHelper(systemInstruction: systemInstruction ?? "", messages: viewModel.messageModel.aiMessageHistory).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            response = "Error: \(error.localizedDescription)"
        }
        
        return response
    }
    
    func setupKeyboardObservers() {
        let showPublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        let hidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        showPublisher
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .sink { self.keyboardHeight = $0 }
            .store(in: &cancellables)

        hidePublisher
            .map { _ in CGFloat(0) }
            .sink { self.keyboardHeight = $0 }
            .store(in: &cancellables)
    }
}

struct ReminderPickerLabel: View {
    @Query(sort: \NotificationSchedule.weekday, order: .forward)
    var schedule: [NotificationSchedule]
    
    var time: String {
        let hourValue = schedule.first?.hour ?? 0
        let minute = schedule.first?.minute ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Format for 12-hour time with AM/PM
        
        // Create a Date object for today at the specified hour
        let date = Calendar.current.date(bySettingHour: hourValue, minute: minute, second: 0, of: Date()) ?? Date()
        
        // Format the date to get the hour and AM/PM
        return formatter.string(from: date)
    }
    
    @Query var userSettings: [UserSettings]

    @State var selectedDays: [String] = []
    @Binding var showDatePickerPopUp: Bool
    
    var body: some View {
        HStack (alignment: .center) {
            Spacer()
            if !schedule.isEmpty {
                Text("\(String(describing: schedule.first!.repeatSchedule.rawValue.capitalized)) \(selectedDays.joined(separator: ", "))")
                    .font(.callout)
                    .fontWeight(.light)
                    .multilineTextAlignment(.trailing)
            }
            VStack (alignment: .trailing) {
                Button {
                    showDatePickerPopUp.toggle()
                } label: {
                    if userSettings.first?.isReminderOn ?? false {
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
        .onChange(of: schedule) {
            self.selectedDays = schedule.compactMap {
                Day.from(weekdayNumber: $0.weekday)?.string.first?.description
            }
        }
    }
}

struct MessageView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var message: Message
    
    var body: some View {
        HStack {
            if message.senderType == .user {
                Spacer()
            }
            VStack {
                Text(message.text)
                    .foregroundStyle(
                        colorScheme == .dark
                        ? message.senderType == .bot ? .white : .black
                        : message.senderType == .bot ? .black : .white
                    )
                    .padding(12)
                    .background(
                        message.senderType == .bot
                        ? Color(.systemGray6) // Background color for bot messages
                        : colorScheme == .dark ? Color.white : Color.black // Default background for other sender types
                    )
                    .cornerRadius(16)
                    .multilineTextAlignment(.leading)
            }
            .padding(message.senderType == .bot ? .trailing : .leading, 60)
            
            if message.senderType == .bot {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LanguagePicker: View {
    @Environment(ContentViewModel.self) var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Picker("Language", selection: $viewModel.language) {
                ForEach(Language.allCases, id: \.self) { language in
                    Text(language.description.capitalized)
                }
            }
            .tint(.primary)
            .fontWeight(.thin)
        }
    }
    
    func countryFlag(_ countryCode: Language) -> String {
        guard countryCode.rawValue.count == 2 else {
            return "" // Ensure we have a valid two-letter country code
        }
        
        let base: UInt32 = 127397 // Unicode scalar point for flag sequences (e.g., 🇺🇸)
        let firstScalar = UnicodeScalar(base + countryCode.rawValue.uppercased().unicodeScalars.first!.value)!
        let secondScalar = UnicodeScalar(base + countryCode.rawValue.uppercased().unicodeScalars.last!.value)!
        
        return "\(firstScalar)\(secondScalar)"
    }
}

struct promptSelector: View {
    @Query var userSettings: [UserSettings]

    @State var selectedDays: [String] = []
    @Binding var showDatePickerPopUp: Bool
    
    var body: some View {
        HStack (alignment: .center) {
            Spacer()
            if !schedule.isEmpty {
                Text("\(String(describing: schedule.first!.repeatSchedule.rawValue.capitalized)) \(selectedDays.joined(separator: ", "))")
                    .font(.callout)
                    .fontWeight(.light)
                    .multilineTextAlignment(.trailing)
            }
            VStack (alignment: .trailing) {
                Button {
                    showDatePickerPopUp.toggle()
                } label: {
                    if userSettings.first?.isReminderOn ?? false {
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
        .onChange(of: schedule) {
            self.selectedDays = schedule.compactMap {
                Day.from(weekdayNumber: $0.weekday)?.string.first?.description
            }
        }
    }
    
    private func updateStateFromLocalData() async {
        reminderToggle = userSettings.first?.isReminderOn ?? false
}

//#Preview {
//    ContentView()
//        .environment(ContentViewModel(language: .kr))
//}

#Preview {
    MessageView(message: Message(text: "Hi there! I'm here to help you learn Korean by asking you what you're thankful for today. ashdjkasdhjkasdhjkasdhjkashdjkashdkjashdjkashdjaskdhasjkdhjkasd", senderType: .bot))
}
