//
//  TranscriptionResult.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import Foundation

struct TranscriptionResult {
    let text: String
    let confidence: Float
    let isFinal: Bool
    let timestamp: Date
    
    init(text: String, confidence: Float = 0.0, isFinal: Bool = false, timestamp: Date = Date()) {
        self.text = text
        self.confidence = confidence
        self.isFinal = isFinal
        self.timestamp = timestamp
    }
}