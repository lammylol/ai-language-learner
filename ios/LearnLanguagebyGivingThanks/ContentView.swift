//
//  ContentView.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import SwiftUI
import Combine

struct ContentView: View {
//    @Environment(MessageModel.self) var messageModel
//    
    @State var language: Language = .kr
    @State var text: String = ""
    @State var chatbotText: String = ""
    @State var messages: [Message]
//    @State var messages: [Message] = [Message(text: "Hi there! I'm here to help you learn a new language by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today?", senderType: .bot), Message(text: "Hello world", senderType: .user), Message(text: "Hello world", senderType: .bot)]
    @State private var keyboardHeight: CGFloat = 0 // Track keyboard height
    
    private var languageAPIService: LanguageModelAPIService = LanguageModelAPIService()
    
    @State var isFetching: Bool = false
    @State var isFinished: Bool = false
    @FocusState var isTextEditorFocused: Bool
    
    // Initialize observers to listen for keyboard notifications
    @State private var keyboardWillShow: AnyCancellable?
    @State private var keyboardWillHide: AnyCancellable?
    
    init(language: Language) {
        self.language = language
        messages = [Message(text: "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)", senderType: .bot)]
//        
//        // Listen for keyboard show and hide events
//        self.keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
//            .sink { notification in
//                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
//                    self.keyboardHeight = keyboardFrame.height
//                }
//            }
//        
//        self.keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
//            .sink { _ in
//                self.keyboardHeight = 0
//            }
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            PickerView(selectedLanguage: $language)
                .pickerStyle(.menu)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        ForEach(messages) { message in
                            MessageView(message: message)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: messages.count) { first, second in
                    // Scroll to the bottom whenever a new message is added
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .ignoresSafeArea(.keyboard)
                .onChange(of: isFetching) { first, second in
                    if isFetching {
                        messages.append(Message(text: "...", senderType: .bot))
//                        messageModel.addMessage(Message(text: "...", senderType: .bot))
                    }
                }
            }
            
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    VStack (alignment: .leading) {
                        TextEditor(text: $text)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 600)
                            .fixedSize(horizontal: false, vertical: true)
                            .focused($isTextEditorFocused)
                    }
                    .padding()
                    .offset(x: -4, y: -7)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1) // Optional border
                    )
                    
                    if text.isEmpty {
                        Text(language.enterMessage)
                            .foregroundStyle(.secondary).fontWeight(.light)
                            .padding()
                    }
                }
                
                Button { submit()
                } label: {
                    Image(systemName: "arrowshape.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(text.isEmpty ? Color.gray : Color.blue)
                        .padding(.all, 7)
                }
            }
            .padding(.bottom, 10)
        }
        .onChange(of: language) { original, newLanguage in
            if let firstMessage = messages.first {
                messages[0].text = "Hi there! I'm here to help you learn \(language.description.capitalized) by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today? \(language.welcomeMessage)"
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func submit() {
        Task {
            let prompt = text
            text = ""
            messages.append(Message(text: prompt, senderType: .user))
//            messageModel.addMessage(Message(text: prompt, senderType: .user))
            isTextEditorFocused = false
            
            do {
                isFetching = true
                defer { isFinished = true }
                
                var systemInstruction: String?
//                if messages.count == 2 {
                    systemInstruction = "The user is trying to learn \(language.description). Please provide them with corrections to their answer to the prompt 'what are you grateful for?'. Please respond to them in English."
//                }
                let response = try await languageAPIService.languageHelper(systemInstruction: systemInstruction ?? "", prompt: prompt)
                    
                if messages.last?.text == "..." {
                    messages.removeLast()
                }
                messages.append(Message(text: response.trimmingCharacters(in: .whitespacesAndNewlines), senderType: .bot))
//                messageModel.addMessage(Message(text: response.trimmingCharacters(in: .whitespacesAndNewlines), senderType: .bot))
                print("AI Response: \(response)")
            } catch {
                text = ""
                messages.append(Message(text: "Error: \(error.localizedDescription)", senderType: .bot))
//                messageModel.addMessage(Message(text: "Error: \(error.localizedDescription)", senderType: .bot))
                print("Error: \(error.localizedDescription)")
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
                                : Color(.systemGray)) // Bubble background color
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
//    case fr
    case sp
    case kr
    case ch
//    case jp
//    case ar
    
//    static var systemLanguages: [Language] {
//        return [.en, .fr, .sp, .kr, .ch, .jp, .ar]
//    }
    
    var description: String {
        switch self {
        case .us: return "english"
//        case .fr: return "french"
        case .sp: return "spanish"
        case .kr: return "korean"
        case .ch: return "chinese"
//        case .jp: return "japanese"
//        case .ar: return "arabic"
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
