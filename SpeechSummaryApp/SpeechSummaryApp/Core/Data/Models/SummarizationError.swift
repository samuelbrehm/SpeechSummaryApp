import Foundation

enum SummarizationError: LocalizedError, Equatable {
    case modelNotFound
    case modelLoadingFailed(Error)
    case modelNotLoaded
    case textTooLong
    case textTooShort
    case processingFailed(Error)
    case invalidOutput
    case insufficientMemory
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Summarization model not found in app bundle"
        case .modelLoadingFailed(let error):
            return "Failed to load summarization model: \(error.localizedDescription)"
        case .modelNotLoaded:
            return "Model not loaded. Call initialize() first"
        case .textTooLong:
            return "Input text exceeds maximum length limit"
        case .textTooShort:
            return "Input text is too short for summarization"
        case .processingFailed(let error):
            return "Summarization processing failed: \(error.localizedDescription)"
        case .invalidOutput:
            return "Invalid output from summarization model"
        case .insufficientMemory:
            return "Insufficient memory for summarization processing"
        case .invalidInput:
            return "Invalid input provided for summarization"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "Ensure the model file is included in the app bundle"
        case .modelLoadingFailed:
            return "Check device compatibility and available memory"
        case .modelNotLoaded:
            return "Initialize the model before attempting summarization"
        case .textTooLong:
            return "Split text into smaller chunks or increase token limit"
        case .textTooShort:
            return "Provide more text content for meaningful summarization"
        case .processingFailed:
            return "Try again or restart the app if problem persists"
        case .invalidOutput:
            return "Contact support if this error persists"
        case .insufficientMemory:
            return "Close other apps to free up memory"
        case .invalidInput:
            return "Please provide valid text input"
        }
    }
    
    static func == (lhs: SummarizationError, rhs: SummarizationError) -> Bool {
        switch (lhs, rhs) {
        case (.modelNotFound, .modelNotFound),
             (.modelNotLoaded, .modelNotLoaded),
             (.textTooLong, .textTooLong),
             (.textTooShort, .textTooShort),
             (.invalidOutput, .invalidOutput),
             (.insufficientMemory, .insufficientMemory),
             (.invalidInput, .invalidInput):
            return true
        case (.modelLoadingFailed(let lhsError), .modelLoadingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.processingFailed(let lhsError), .processingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}