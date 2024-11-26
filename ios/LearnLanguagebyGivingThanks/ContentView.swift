//
//  ContentView.swift
//  LearnLanguagebyGivingThanks
//
//  Created by Matt Lam on 11/23/24.
//

import SwiftUI

struct ContentView: View {
    @State var text: String = ""
    @State var chatbotText: String = ""
    @State var messages: [Message] = [Message(text: "Hi there! I'm here to help you learn a new language by asking you what you're grateful for each day. Don't worry if you get it wrong; I'll be here to help you out! Let's begin.\n\nWhat are you grateful for today?", senderType: .bot)/*, Message(text: "Hello world", senderType: .user)*/]
    @FocusState var isTextEditorFocused: Bool
    
    private var languageAPIService: LanguageModelAPIService = LanguageModelAPIService()
    
    var body: some View {
        VStack (alignment: .leading) {
            PickerView()
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
                .onChange(of: isTextEditorFocused) { first, second in
                    if isTextEditorFocused {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    VStack (alignment: .leading) {
                        TextEditor(text: $text)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 70, maxHeight: 600)
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
                        Text("Enter Message")
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
            .padding(.bottom, 5)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func submit() {
        Task {
            messages.append(Message(text: text, senderType: .user))
            
            languageAPIService.getAiApiResponse(text, completion: { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.chatbotText = response
                        messages.append(Message(text: response, senderType: .bot))
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.chatbotText = "Error: \(error.localizedDescription)"
                    }
                }
            })
            
            text = ""
            isTextEditorFocused = false
        }
    }
}

struct MessageView: View {
    var message: Message
    
    var body: some View {
        HStack {
            if message.senderType == .user {
                Spacer()
            }
            VStack (alignment: .leading) {
                Text(message.text)
                    .foregroundStyle(message.senderType == .bot ? .black : .white)
            }
            .padding(.all, 15)
            .background(message.senderType == .bot ? Color(.systemGray6) : Color(.systemGray)) // Bubble background color
            .cornerRadius(16)
            .padding(message.senderType == .bot ? .trailing : .leading, 60)
        }
    }
}

struct PickerView: View {
    @State private var selectedLanguage: Language = .kr
    
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
    case fr
    case sp
    case kr
    case ch
    case jp
    case ar
    
//    static var systemLanguages: [Language] {
//        return [.en, .fr, .sp, .kr, .ch, .jp, .ar]
//    }
    
    var description: String {
        switch self {
        case .us: return "english"
        case .fr: return "french"
        case .sp: return "spanish"
        case .kr: return "korean"
        case .ch: return "chinese"
        case .jp: return "japanese"
        case .ar: return "arabic"
        }
    }
}

#Preview {
    ContentView()
}
