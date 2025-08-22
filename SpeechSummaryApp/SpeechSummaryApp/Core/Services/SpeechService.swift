//
//  SpeechService.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import UIKit

protocol SpeechServiceProtocol {
    var authorizationStatus: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> { get }
    var isRecording: AnyPublisher<Bool, Never> { get }
    var transcribedText: AnyPublisher<String, Never> { get }
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
    func startRecording() async throws
    func stopRecording()
    func getAccumulatedText() -> String
    func clearAccumulatedText()
}

final class SpeechService: NSObject, SpeechServiceProtocol {
    @Published private var _authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published private var _isRecording: Bool = false
    @Published private var _transcribedText: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recordingTimer: Timer?
    
    private let maxRecordingDuration: TimeInterval = 60.0
    private var accumulatedTranscriptions: [String] = []
    private var currentSessionText: String = ""
    
    var authorizationStatus: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        $_authorizationStatus.eraseToAnyPublisher()
    }
    
    var isRecording: AnyPublisher<Bool, Never> {
        $_isRecording.eraseToAnyPublisher()
    }
    
    var transcribedText: AnyPublisher<String, Never> {
        $_transcribedText.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        setupNotifications()
        _authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopRecording()
    }
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self._authorizationStatus = status
                    continuation.resume(returning: status)
                }
            }
        }
    }
    
    func startRecording() async throws {
        guard !_isRecording else {
            throw SpeechError.recordingInProgress
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        
        guard _authorizationStatus == .authorized else {
            throw SpeechError.permissionDenied
        }
        
        try await setupAudioSession()
        try await startRecognition()
        
        DispatchQueue.main.async {
            self._isRecording = true
            self.currentSessionText = ""
        }
        
        startRecordingTimer()
    }
    
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self._isRecording = false
            
            if !self.currentSessionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.accumulatedTranscriptions.append(self.currentSessionText)
                self.updateCombinedText()
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        if _isRecording {
            stopRecording()
        }
    }
    
    private func setupAudioSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechError.audioEngineError(error)
        }
    }
    
    private func startRecognition() async throws {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionFailed(NSError(domain: "SpeechService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"]))
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            throw SpeechError.audioEngineError(error)
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let result = result {
                    self.currentSessionText = result.bestTranscription.formattedString
                    self.updateCombinedText()
                    
                    // Note: Não para automaticamente quando result.isFinal = true
                    // Isso permite que o usuário continue falando após pausas
                    // O stop só acontece por ação manual ou timeout
                }
                
                if error != nil {
                    self.stopRecording()
                }
            }
        }
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }
    
    func getAccumulatedText() -> String {
        return accumulatedTranscriptions.joined(separator: " ")
    }
    
    func clearAccumulatedText() {
        accumulatedTranscriptions.removeAll()
        currentSessionText = ""
        _transcribedText = ""
    }
    
    private func updateCombinedText() {
        let previousText = accumulatedTranscriptions.joined(separator: " ")
        let currentText = currentSessionText
        
        if previousText.isEmpty {
            _transcribedText = currentText
        } else {
            _transcribedText = "\(previousText) \(currentText)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}