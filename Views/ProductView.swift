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

    private func processCommand(_ command: String) {
        let (type, count, month, year) = CommandProcessor.parse(command)

        if let type = type, let count = count {
            productVM.fetchProducts(type: type, count: count, month: month, year: year)
            currentListType = type
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

        let pattern = "(top|bottom).*?(\\d+)(?:.*?(january|february|march|april|may|june|july|august|september|october|november|december))?(?:.*?(\\d{4}))?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return (nil, nil, nil, nil) }

        if let match = regex.firstMatch(
            in: convertedCommand,
            range: NSRange(convertedCommand.startIndex..., in: convertedCommand)
        ),
           let keywordRange = Range(match.range(at: 1), in: convertedCommand),
           let numberRange = Range(match.range(at: 2), in: convertedCommand),
           let number = Int(String(convertedCommand[numberRange])) {

            let keyword = String(convertedCommand[keywordRange]) // "top" or "bottom"
            var month: Int? = nil
            var year: Int? = nil

            if let monthRange = Range(match.range(at: 3), in: convertedCommand) {
                let monthString = String(convertedCommand[monthRange]).lowercased()
                let months = [
                    "january": 1, "february": 2, "march": 3, "april": 4,
                    "may": 5, "june": 6, "july": 7, "august": 8,
                    "september": 9, "october": 10, "november": 11, "december": 12
                ]
                month = months[monthString]
            }

            if let yearRange = Range(match.range(at: 4), in: convertedCommand) {
                year = Int(String(convertedCommand[yearRange]))
            }

            return (keyword, number, month, year)
        }

        return (nil, nil, nil, nil)
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
