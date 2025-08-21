//
//  SpeechRecognitionViewModel.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import Foundation
import Speech
import Combine

enum SpeechRecognitionState: Equatable {
    case idle
    case requestingPermission
    case ready
    case recording
    case processing
    case completed(String)
    case error(AppError)
}

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
}

@MainActor
final class SpeechRecognitionViewModel: ObservableObject {
    @Published var state: SpeechRecognitionState = .idle
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    @Published var permissionStatus: PermissionStatus = .notDetermined
    
    private let useCase: SpeechRecognitionUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(useCase: SpeechRecognitionUseCaseProtocol) {
        self.useCase = useCase
        setupBindings()
        checkInitialPermissions()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        state = .requestingPermission
        errorMessage = nil
        
        Task {
            do {
                try await useCase.startSpeechRecognition()
                state = .recording
            } catch {
                handleError(error)
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        state = .processing
        
        Task {
            await useCase.stopSpeechRecognition()
            
            if !transcribedText.isEmpty {
                state = .completed(transcribedText)
            } else {
                state = .ready
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func clearTranscription() {
        transcribedText = ""
        state = .ready
        errorMessage = nil
    }
    
    func requestPermissions() {
        state = .requestingPermission
        
        Task {
            let granted = await useCase.requestPermissions()
            
            if granted {
                permissionStatus = .authorized
                state = .ready
            } else {
                permissionStatus = .denied
                state = .error(.microphonePermissionDenied)
            }
        }
    }
    
    private func setupBindings() {
        useCase.isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        useCase.transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)
        
        useCase.authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updatePermissionStatus(from: status)
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialPermissions() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        updatePermissionStatus(from: speechStatus)
        
        if speechStatus == .authorized {
            state = .ready
        }
    }
    
    private func updatePermissionStatus(from speechStatus: SFSpeechRecognizerAuthorizationStatus) {
        switch speechStatus {
        case .authorized:
            permissionStatus = .authorized
            if state == .idle {
                state = .ready
            }
        case .denied, .restricted:
            permissionStatus = .denied
            state = .error(.microphonePermissionDenied)
        case .notDetermined:
            permissionStatus = .notDetermined
            state = .idle
        @unknown default:
            permissionStatus = .notDetermined
            state = .idle
        }
    }
    
    private func handleError(_ error: Error) {
        if let speechError = error as? SpeechError {
            switch speechError {
            case .permissionDenied:
                state = .error(.microphonePermissionDenied)
                errorMessage = speechError.errorDescription
            case .recognizerUnavailable:
                state = .error(.speechUnavailable)
                errorMessage = speechError.errorDescription
            case .audioEngineError, .recognitionFailed, .recordingInProgress:
                state = .error(.speechUnavailable)
                errorMessage = speechError.errorDescription
            }
        } else {
            state = .error(.speechUnavailable)
            errorMessage = error.localizedDescription
        }
    }
}