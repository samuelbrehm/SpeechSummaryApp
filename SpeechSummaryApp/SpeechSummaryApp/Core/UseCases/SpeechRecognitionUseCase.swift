//
//  SpeechRecognitionUseCase.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import Foundation
import Speech
import AVFoundation
import Combine

protocol SpeechRecognitionUseCaseProtocol {
    func requestPermissions() async -> Bool
    func startSpeechRecognition() async throws
    func stopSpeechRecognition() async
    func getCurrentTranscription() -> String
    func getAccumulatedText() -> String
    func clearAccumulatedText()
    
    var isRecording: AnyPublisher<Bool, Never> { get }
    var transcribedText: AnyPublisher<String, Never> { get }
    var authorizationStatus: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> { get }
}

final class SpeechRecognitionUseCase: SpeechRecognitionUseCaseProtocol {
    private let speechService: SpeechServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var isRecording: AnyPublisher<Bool, Never> {
        speechService.isRecording
    }
    
    var transcribedText: AnyPublisher<String, Never> {
        speechService.transcribedText
    }
    
    var authorizationStatus: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        speechService.authorizationStatus
    }
    
    init(speechService: SpeechServiceProtocol) {
        self.speechService = speechService
    }
    
    func requestPermissions() async -> Bool {
        let speechStatus = await speechService.requestAuthorization()
        
        guard speechStatus == .authorized else {
            return false
        }
        
        let microphoneStatus = await requestMicrophonePermission()
        return microphoneStatus
    }
    
    func startSpeechRecognition() async throws {
        let permissionsGranted = await requestPermissions()
        
        guard permissionsGranted else {
            throw SpeechError.permissionDenied
        }
        
        try await speechService.startRecording()
    }
    
    func stopSpeechRecognition() async {
        speechService.stopRecording()
    }
    
    func getCurrentTranscription() -> String {
        return speechService.getAccumulatedText()
    }
    
    func getAccumulatedText() -> String {
        return speechService.getAccumulatedText()
    }
    
    func clearAccumulatedText() {
        speechService.clearAccumulatedText()
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}