import Foundation

struct SummaryResult {
    let id: UUID
    let originalText: String
    let summary: String
    let processingTime: TimeInterval
    let confidence: Float?
    let processedAt: Date
    let summaryLength: SummaryLength
    
    init(
        originalText: String,
        summary: String,
        processingTime: TimeInterval,
        confidence: Float? = nil,
        summaryLength: SummaryLength = .medium
    ) {
        self.id = UUID()
        self.originalText = originalText
        self.summary = summary
        self.processingTime = processingTime
        self.confidence = confidence
        self.processedAt = Date()
        self.summaryLength = summaryLength
    }
}

enum SummaryLength: CaseIterable {
    case short
    case medium
    case long
    
    var tokenCount: Int {
        switch self {
        case .short: return 50
        case .medium: return 100
        case .long: return 150
        }
    }
    
    var displayName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }
    
    var compressionRatio: Double {
        switch self {
        case .short: return 0.25  // More aggressive compression
        case .medium: return 0.40 // Balanced compression
        case .long: return 0.60   // Less compression, more detail
        }
    }
}

extension SummaryResult: Identifiable {}