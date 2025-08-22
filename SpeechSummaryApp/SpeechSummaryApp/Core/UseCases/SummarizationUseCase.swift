import Foundation
import Combine
import os.log

struct SummarizationInput {
    let text: String
    let summaryLength: SummaryLength
    let requestId: UUID
    
    init(text: String, summaryLength: SummaryLength = .medium) {
        self.text = text
        self.summaryLength = summaryLength
        self.requestId = UUID()
    }
}

struct SummarizationOutput {
    let result: SummaryResult
    let requestId: UUID
}

protocol SummarizationUseCaseProtocol {
    func execute(input: SummarizationInput) async throws -> SummarizationOutput
    func initialize() async throws
    func isAvailable() -> Bool
}

final class SummarizationUseCase: SummarizationUseCaseProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let summarizationService: SummarizationServiceProtocol
    private let logger = Logger(subsystem: "com.speechsummaryapp.summarization", category: "usecase")
    
    @Published private(set) var isInitialized: Bool = false
    @Published private(set) var lastError: SummarizationError?
    
    // MARK: - Initialization
    
    init(summarizationService: SummarizationServiceProtocol) {
        self.summarizationService = summarizationService
        logger.info("SummarizationUseCase initialized")
    }
    
    // MARK: - Public Methods
    
    func initialize() async throws {
        guard !isInitialized else {
            logger.debug("UseCase already initialized")
            return
        }
        
        logger.info("Initializing summarization use case...")
        
        do {
            try await summarizationService.initialize()
            isInitialized = true
            lastError = nil
            logger.info("SummarizationUseCase initialized successfully")
        } catch {
            logger.error("Failed to initialize summarization service: \(error.localizedDescription)")
            lastError = error as? SummarizationError ?? .modelLoadingFailed(error)
            throw error
        }
    }
    
    func execute(input: SummarizationInput) async throws -> SummarizationOutput {
        logger.info("Executing summarization for request: \(input.requestId.uuidString)")
        
        guard isInitialized else {
            logger.error("UseCase not initialized")
            throw SummarizationError.modelNotLoaded
        }
        
        // Validate input
        try validateInput(input)
        
        do {
            // Execute summarization
            let result = try await summarizationService.summarize(
                text: input.text,
                maxLength: input.summaryLength
            )
            
            // Validate output
            try validateOutput(result)
            
            logger.info("Summarization completed successfully for request: \(input.requestId.uuidString)")
            
            lastError = nil
            return SummarizationOutput(
                result: result,
                requestId: input.requestId
            )
            
        } catch let error as SummarizationError {
            logger.error("Summarization failed: \(error.localizedDescription)")
            lastError = error
            throw error
        } catch {
            logger.error("Unexpected error during summarization: \(error.localizedDescription)")
            let summarizationError = SummarizationError.processingFailed(error)
            lastError = summarizationError
            throw summarizationError
        }
    }
    
    func isAvailable() -> Bool {
        return isInitialized && summarizationService.isModelLoaded
    }
    
    // MARK: - Private Methods
    
    private func validateInput(_ input: SummarizationInput) throws {
        let trimmedText = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else {
            throw SummarizationError.invalidInput
        }
        
        guard trimmedText.count >= 50 else {
            throw SummarizationError.textTooShort
        }
        
        guard trimmedText.count <= 2000 else {
            throw SummarizationError.textTooLong
        }
        
        // Check for meaningful content (not just repeated characters)
        let uniqueWords = Set(trimmedText.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)))
        guard uniqueWords.count >= 10 else {
            throw SummarizationError.textTooShort
        }
    }
    
    private func validateOutput(_ result: SummaryResult) throws {
        guard !result.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizationError.invalidOutput
        }
        
        guard result.summary != result.originalText else {
            throw SummarizationError.invalidOutput
        }
        
        // Ensure summary is shorter than original (basic sanity check)
        guard result.summary.count < result.originalText.count else {
            logger.warning("Summary is longer than original text, but allowing it")
            return
        }
    }
}

// MARK: - Convenience Extensions

extension SummarizationUseCase {
    
    func executeSummarization(
        for transcriptionResult: TranscriptionResult,
        summaryLength: SummaryLength = .medium
    ) async throws -> SummarizationOutput {
        
        let input = SummarizationInput(
            text: transcriptionResult.text,
            summaryLength: summaryLength
        )
        
        return try await execute(input: input)
    }
}