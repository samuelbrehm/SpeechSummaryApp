//
//  SpeechError.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import Foundation

enum SpeechError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case audioEngineError(Error)
    case recognitionFailed(Error)
    case recordingInProgress
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Acesso ao microfone e reconhecimento de fala é necessário"
        case .recognizerUnavailable:
            return "Reconhecimento de fala não está disponível neste dispositivo"
        case .audioEngineError(let error):
            return "Erro no sistema de áudio: \(error.localizedDescription)"
        case .recognitionFailed(let error):
            return "Falha no reconhecimento: \(error.localizedDescription)"
        case .recordingInProgress:
            return "Gravação já está em andamento"
        }
    }
}

enum AppError: LocalizedError, Equatable {
    case speechUnavailable
    case microphonePermissionDenied
    case foundationModelsUnavailable
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .speechUnavailable:
            return "Reconhecimento de fala não está disponível"
        case .microphonePermissionDenied:
            return "Permissão de microfone negada"
        case .foundationModelsUnavailable:
            return "Foundation Models não estão disponíveis"
        case .networkError(let message):
            return "Erro de rede: \(message)"
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.speechUnavailable, .speechUnavailable),
             (.microphonePermissionDenied, .microphonePermissionDenied),
             (.foundationModelsUnavailable, .foundationModelsUnavailable):
            return true
        case (.networkError(let lhsMessage), .networkError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}