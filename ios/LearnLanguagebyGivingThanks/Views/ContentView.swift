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
    @Environment(\.modelContext) private var context
    
    @Query var schedule: [NotificationSchedule]
    @Query var userSettings: [UserSettings]
    
    @State var language: Language = .kr
    @State var text: String = ""
    
    @State var scheduleTime: DateComponents = DateComponents()
    @State var repeatSchedule: RepeatSchedule = .daily
    @State var reminderToggle: Bool = false
    @State var selectedDays: [Day] = []

    @State private var keyboardHeight: CGFloat = 0 // Track keyboard height
    @State private var cancellables = Set<AnyCancellable>()
    
    private var languageAPIService: LanguageModelAPIService = LanguageModelAPIService()
    private var messageModel: MessageModel
    
    @State var isFetching: Bool = false
    @State var isFinished: Bool = false
    @FocusState var isTextEditorFocused: Bool
    @State var showDatePickerPopUp: Bool = false
    
    // Initialize observers to listen for keyboard notifications
    @State private var keyboardWillShow: AnyCancellable?
    @State private var keyboardWillHide: AnyCancellable?
    
    init(language: Language) {
        self.language = language
        self.messageModel = MessageModel(language: language)
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                PickerView(selectedLanguage: $language)
                    .pickerStyle(.menu)
                Spacer()
                ReminderPickerLabel(showDatePickerPopUp: $showDatePickerPopUp)
            }
            .frame(height: 50)
            
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(messageModel.messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                }
                .layoutPriority(1)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaPadding(.bottom)
                .onChange(of: messageModel.messages.count) {
                    // Scroll to the bottom whenever a new message is added
                    if let lastMessage = messageModel.messages.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom) // Scroll to last message
                        }
                    }
                } // Scroll to bottom when new message is added.
                .onChange(of: isTextEditorFocused) { old, new in
                    DispatchQueue.main.async {
                        if let lastMessage = messageModel.messages.last {
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
                        .environment(\.locale, Locale(identifier: language.localeIdentifier))
                    
                    if text.isEmpty {
                        Text(language.enterMessage)
                            .foregroundStyle(.secondary).fontWeight(.light)
                            .padding(.leading, 10)
                            .padding(.bottom, 2)
                    }
                }
                Button {
                    submit()
                } label: {
                    VStack {
                        Image(systemName: isFetching ? "square.fill" : "arrowshape.up.fill")
                            .resizable()  // Make the image resizable
                            .aspectRatio(contentMode: .fit)  // Maintain the aspect ratio
                            .padding(isFetching ? 10 : 7)
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
        .task {
            setupKeyboardObservers()
        }
        .onChange(of: language) { original, newLanguage in
            if messageModel.messages.first != nil {
                messageModel.messages[0].text = "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)"
            }
        } // Change language translation when language changes.
        .onChange(of: isFetching) { first, second in
            if isFetching {
                messageModel.messages.append(Message(text: "fetching...", senderType: .bot))
            }
        } // // Add a new message showing 'loading' when fetching.
        .sheet(isPresented: $showDatePickerPopUp){
            ReminderPopUp(language: language)
        }
    }
    
    func submit() {
        Task {
            let prompt = text
            text = ""
            messageModel.messages.append(Message(text: prompt, senderType: .user))
            isTextEditorFocused = false
            
            do {
                isFetching = true
                defer { isFetching = false }
                
                // system instruction setting
                var systemInstruction: String?
                systemInstruction = "The user is trying to learn \(language.description). Please provide them with corrections to their answer to the prompt 'what are you grateful for?'. Please respond to them in English."
                
                // response from model
                let response = try await languageAPIService.languageHelper(systemInstruction: systemInstruction ?? "", messages: messageModel.messages)
                    
                if messageModel.messages.last?.text == "fetching..." {
                    messageModel.messages.removeLast()
                }
                messageModel.messages.append(Message(text: response.trimmingCharacters(in: .whitespacesAndNewlines), senderType: .bot))
                print("AI Response: \(response)")
            } catch {
                text = ""
                messageModel.messages.append(Message(text: "Error: \(error.localizedDescription)", senderType: .bot))
                print("Error: \(error.localizedDescription)")
            }
        }
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
            VStack (alignment: .leading) {
                Text(message.text)
                    .foregroundStyle(
                        colorScheme == .dark
                        ? .white
                        : message.senderType == .bot ? .black : .white
                    )
                    .background(Color.clear)
                    .textSelection(.enabled)
                    .padding(.all, 15)
                    .background(message.senderType == .bot
                                ? Color(.systemGray6)
                                : Color.secondary) // Bubble background color
                    .cornerRadius(16)
            }
            .padding(message.senderType == .bot ? .trailing : .leading, 60)
            
            if message.senderType == .bot {
                Spacer()
            }
        }
    }
}

struct PickerView: View {
    @Binding var selectedLanguage: Language
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Picker("Language", selection: $selectedLanguage) {
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

enum Language: String, CaseIterable {
    case us
    case sp
    case kr
    case ch
    
    var localeIdentifier: String {
        switch self {
        case .us: return "en_US"
        case .sp: return "es_ES"
        case .kr: return "ko_KR"
        case .ch: return "zh_CN"
        }
    }
    
    var description: String {
        switch self {
        case .us: return "english"
        case .sp: return "spanish"
        case .kr: return "korean"
        case .ch: return "chinese"
        }
    }
    
    var welcomeMessage: String {
        switch self {
        case .us: return ""
        case .sp: return "¿Qué te gusta hoy?"
        case .kr: return "오늘 무엇을 감사하세요?"
        case .ch: return "今天感谢什么?"
        }
    }
    
    var enterMessage: String {
        switch self {
        case .us: return "Enter Message"
        case .sp: return "Enter Message. Escribe un mensaje!"
        case .kr: return "Enter Message. 메시지 입력!"
        case .ch: return "Enter Message. 输入消息!"
        }
    }
}

#Preview {
    ContentView(language: .kr)
}
