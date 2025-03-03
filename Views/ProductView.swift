//
//  ContentView.swift
//  SpeechTest
//
//  Created by Rajesh Triadi Noftarizal on 28/02/25.
//

import SwiftUI

struct ProductView: View {
    @ObservedObject var productVM = ProductViewModel()
    @ObservedObject var speechRecognizer = SpeechRecognizer()
    
    @State private var showWarning = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Top Selling Products")
                .font(.title)
            
            // List of top products
            List(productVM.topProducts) { product in
                HStack {
                    Text(product.name)
                    Spacer()
                    Text("\(product.sales) sales")
                }
            }
            
            Text("Least selling products")
                .font(.title)
            
            List(productVM.bottomProducts) { product in
                HStack {
                    Text(product.name)
                    Spacer()
                    Text("\(product.sales) sales")
                }
            }
            
            // Voice feedback UI
            VStack {
                if speechRecognizer.isListening {
                    ProgressView()
                        .padding(.bottom, 5)
                    Text("Listening...")
                        .foregroundStyle(.gray)
                }
                
                Text("Transcribed: \(speechRecognizer.transcribedText)")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                
                if showWarning {
                    Text("Please say a number after 'top'")
                        .foregroundStyle(.red)
                }
            }
            
            // Voice command button
            Button {
                handleVoiceCommand()
            } label: {
                Text(speechRecognizer.isListening ? "Stop Listening" : "Start Voice Command")
                    .padding()
                    .background(speechRecognizer.isListening ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
    
    private func handleVoiceCommand() {
        if speechRecognizer.isListening {
            speechRecognizer.stopRecording()
            processCommand(speechRecognizer.transcribedText)
        } else {
            showWarning = false
            speechRecognizer.transcribedText = ""
            speechRecognizer.requestAuthorization()
            speechRecognizer.startRecording()
        }
    }
    
    private func processCommand(_ command: String) {
        let lowercasedCommand = command.lowercased()
        
        // Convert words like "three" to "3"
        let convertedCommand = convertNumberWordsToDigits(lowercasedCommand)
        
        // Match patterns like "top 3" or "top 5 products"
        let pattern = "(top|bottom).*?(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        if let match = regex.firstMatch(
            in: convertedCommand,
            range: NSRange(convertedCommand.startIndex..., in: convertedCommand)
        ),
           let range = Range(match.range(at: 1), in: convertedCommand),
           let number = Int(String(convertedCommand[range])) {
            
            // Show up to the available number of products
            let count = min(number, productVM.products.count)
            productVM.fetchTopProducts(count: count)
            showWarning = false
        } else {
            showWarning = true // Show warning if no number found
        }
    }
    
    // Add this inside your ContentView or a helper class
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
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var convertedText = text
        
        // Replace individual number words (e.g., "three" → "3")
        for word in words {
            if let number = numberWords[word.lowercased()] {
                convertedText = convertedText.replacingOccurrences(
                    of: word,
                    with: "\(number)",
                    options: .caseInsensitive,
                    range: nil
                )
            }
        }
        
        return convertedText
    }
}

#Preview {
    ProductView()
}
