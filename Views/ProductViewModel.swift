//
//  ProductViewModel.swift
//  SpeechTest
//
//  Created by Rajesh Triadi Noftarizal on 28/02/25.
//

import SwiftUI
import Speech

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = [
        Product(name: "Product A", sales: 100),
        Product(name: "Product B", sales: 150),
        Product(name: "Product C", sales: 80),
        Product(name: "Product D", sales: 200),
        Product(name: "Product E", sales: 120)
    ]
    
    @Published var displayedProducts: [Product] = []
    
    init() {
        displayedProducts = products
    }
    
    func fetchProducts(type: String, count: Int) {
        let sortedProducts = products.sorted { type == "top" ? $0.sales > $1.sales : $0.sales < $1.sales }
        displayedProducts = Array(sortedProducts.prefix(count))
    }
    
    func resetProducts() {
        displayedProducts = products
    }
}

class SpeechRecognizer: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    
    @Published var transcribedText: String = ""
    @Published var isListening = false
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Request speech recognition authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied, .restricted, .notDetermined:
                print("Speech recognition not authorized")
            @unknown default:
                print("Unknown speech recognition status")
            }
        }
    }
    
    // Start recording and transcribing
    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            print("Audio engine start error: \(error.localizedDescription)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isListening = false
                }
            }
        }
    }
    
    // Stop recording explicitly
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
}
