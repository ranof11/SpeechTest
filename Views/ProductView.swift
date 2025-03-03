//
//  ContentView.swift
//  SpeechTest
//
//  Created by Rajesh Triadi Noftarizal on 28/02/25.
//

import SwiftUI

struct ProductView: View {
    @ObservedObject var productVM = ProductViewModel()
    @ObservedObject var speechVM = SpeechViewModel()
    
    @State private var showWarning = false
    @State private var currentListType: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ABC Products")
                .font(.title)
            
            Text(currentListTitle)
                .font(.headline)
            
            ProductListView(products: productVM.displayedProducts)
            
            VoiceFeedbackView(speechVM: speechVM, showWarning: $showWarning)
            
            ActionButtons(
                resetAction: resetProducts,
                voiceCommandAction: handleVoiceCommand,
                isListening: speechVM.isListening
            )
        }
        .padding()
    }
    
    private var currentListTitle: String {
        currentListType?.capitalized.appending(" Products") ?? "All Products"
    }
    
    private func resetProducts() {
        productVM.resetProducts()
        currentListType = nil
    }
    
    private func handleVoiceCommand() {
        if speechVM.isListening {
            speechVM.stopRecording()
            processCommand(speechVM.transcribedText)
        } else {
            showWarning = false
            speechVM.transcribedText = ""
            speechVM.requestAuthorization()
            speechVM.startRecording()
        }
    }
    
    // In ProductView struct
    private func processCommand(_ command: String) {
        let (type, count, month, year) = CommandProcessor.parse(command)
        
        if let type = type, type == "all" {
            // Handle "all" with optional month/year
            productVM.fetchProducts(type: nil, count: nil, month: month, year: year)
            currentListType = "all"
            showWarning = false
        } else if let type = type, let count = count {
            // Original top/bottom case
            productVM.fetchProducts(type: type, count: count, month: month, year: year)
            currentListType = type
            showWarning = false
        } else if month != nil || year != nil {
            // Handle standalone month/year filters (NEW)
            productVM.fetchProducts(type: nil, count: nil, month: month, year: year)
            currentListType = "filtered"
            showWarning = false
        } else {
            showWarning = true
        }
    }
}

struct ProductListView: View {
    let products: [Product]
    
    var body: some View {
        List(products) { product in
            HStack {
                Text(product.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(formattedDate(product.date))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("\(product.sales) sales")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct VoiceFeedbackView: View {
    @ObservedObject var speechVM: SpeechViewModel
    @Binding var showWarning: Bool
    
    var body: some View {
        VStack {
            if speechVM.isListening {
                ProgressView()
                    .padding(.bottom, 5)
                Text("Listening...")
                    .foregroundStyle(.gray)
            }
            
            Text("Transcribed: \(speechVM.transcribedText)")
                .padding()
                .background(Color.gray.opacity(0.1))
            
            if showWarning {
                Text("Please say a number after 'top'")
                    .foregroundStyle(.red)
            }
        }
    }
}

struct ActionButtons: View {
    let resetAction: () -> Void
    let voiceCommandAction: () -> Void
    let isListening: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: resetAction) {
                Text("Show All Products")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button(action: voiceCommandAction) {
                Text(isListening ? "Stop Listening" : "Start Voice Command")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding()
                    .background(isListening ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

class CommandProcessor {
    static func parse(_ command: String) -> (String?, Int?, Int?, Int?) {
        let lowercasedCommand = command.lowercased()
        let convertedCommand = convertNumberWordsToDigits(lowercasedCommand)
        
        // 1. Check for top/bottom commands
        if let (type, count, month, year) = parseTopBottom(command: convertedCommand) {
            return (type, count, month, year)
        }
        
        // 2. Check for "all" commands
        if let (month, year) = parseAll(command: convertedCommand) {
            return ("all", nil, month, year)
        }
        
        // 3. Check for standalone month/year (NEW)
        if let (month, year) = parseMonthYear(command: convertedCommand) {
            return (nil, nil, month, year)
        }
        
        return (nil, nil, nil, nil)
    }
    
    private static func parseTopBottom(command: String) -> (String?, Int?, Int?, Int?)? {
        let pattern = "(top|bottom).*?(\\d+)(?:.*?(january|february|march|april|may|june|july|august|september|october|november|december))?(?:.*?(\\d{4}))?"
        guard let match = firstMatch(for: pattern, in: command) else { return nil }
        
        let keyword = match[1]
        guard let number = Int(match[2] ?? "") else { return nil }
        let month = monthNumber(for: match[3])
        let year = Int(match[4] ?? "")
        
        return (keyword, number, month, year)
    }
    
    private static func parseAll(command: String) -> (Int?, Int?)? {
        // Updated regex to handle "all products in <month> <year>" and "all products in <year>"
        let pattern = "all.*?(january|february|march|april|may|june|july|august|september|october|november|december)?\\s*(\\d{4})|(\\d{4})\\s*(january|february|march|april|may|june|july|august|september|october|november|december)?"
        guard let match = firstMatch(for: pattern, in: command) else { return nil }
        
        // Attempt to capture the month and year
        let month = monthNumber(for: match[1])
        let year = Int(match[2] ?? "") ?? Int(match[3] ?? "")
        
        // If we have only the year, allow filtering by year
        if month == nil && year != nil {
            return (nil, year)
        }
        
        // If we have both month and year, return them
        if month != nil && year != nil {
            return (month, year)
        }
        
        // Return nil if neither is found (not a valid "all" command)
        return nil
    }
    
    // In CommandProcessor class
    private static func parseMonthYear(command: String) -> (Int?, Int?)? {
        // Match patterns like "january 2024" or "2024 january"
        let pattern = "(january|february|march|april|may|june|july|august|september|october|november|december)\\s*(\\d{4})|(\\d{4})\\s*(january|february|march|april|may|june|july|august|september|october|november|december)"
        guard let match = firstMatch(for: pattern, in: command) else { return nil }
        
        var month: Int?
        var year: Int?
        
        // Check both possible group combinations
        if let monthStr = match[1] {
            month = monthNumber(for: monthStr)
            year = Int(match[2] ?? "")
        } else if let yearStr = match[3], let monthStr = match[4] {
            month = monthNumber(for: monthStr)
            year = Int(yearStr)
        }
        
        return (month, year)
    }
    
    private static func firstMatch(for pattern: String, in text: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        
        var groups: [String?] = []
        for i in 0..<match.numberOfRanges {
            let groupRange = match.range(at: i)
            if groupRange.location == NSNotFound {
                groups.append(nil)
            } else {
                let substring = String(text[Range(groupRange, in: text)!])
                groups.append(substring)
            }
        }
        return groups
    }
    
    private static func monthNumber(for monthString: String?) -> Int? {
        guard let monthString = monthString?.lowercased() else { return nil }
        let months = [
            "january": 1, "february": 2, "march": 3, "april": 4,
            "may": 5, "june": 6, "july": 7, "august": 8,
            "september": 9, "october": 10, "november": 11, "december": 12
        ]
        return months[monthString]
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM yyyy"
    return formatter
}()

private func formattedDate(_ date: Date) -> String {
    return dateFormatter.string(from: date)
}

private let numberWords: [String: Int] = [
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
    "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
    "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40,
    "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80,
    "ninety": 90, "hundred": 100
]

private func convertNumberWordsToDigits(_ text: String) -> String {
    var convertedText = text
    numberWords.forEach { word, digit in
        convertedText = convertedText.replacingOccurrences(of: word, with: "\(digit)", options: .caseInsensitive)
    }
    return convertedText
}

#Preview {
    ProductView()
}
