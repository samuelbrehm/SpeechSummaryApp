import Foundation
import Combine
import SwiftUI
import os.log

enum SummarizationState: Equatable {
    case idle
    case initializing
    case ready
    case processing
    case completed(SummaryResult)
    case error(String)
    
    var isProcessing: Bool {
        switch self {
        case .initializing, .processing:
            return true
        default:
            return false
        }
    }
    
    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
    
    static func == (lhs: SummarizationState, rhs: SummarizationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.initializing, .initializing), (.ready, .ready), (.processing, .processing):
            return true
        case (.completed(let lhsResult), .completed(let rhsResult)):
            return lhsResult.id == rhsResult.id
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

@MainActor
final class SummarizationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: SummarizationState = .idle
    @Published private(set) var summaryResult: SummaryResult?
    @Published private(set) var errorMessage: String?
    @Published var selectedSummaryLength: SummaryLength = .medium
    @Published private(set) var isModelLoaded: Bool = false
    @Published private(set) var modelInfo: ModelInfo = .notLoaded
    
    // MARK: - Private Properties
    
    private let summarizationUseCase: SummarizationUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.speechsummaryapp.summarization", category: "viewmodel")
    
    private var currentProcessingTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var canSummarize: Bool {
        return state.isReady && !state.isProcessing
    }
    
    var processingProgress: String {
        switch state {
        case .initializing:
            return "Loading AI model..."
        case .processing:
            return "Generating summary..."
        case .completed:
            return "Summary complete"
        case .error:
            return "Error occurred"
        default:
            return ""
        }
    }
    
    // MARK: - Initialization
    
    init(summarizationUseCase: SummarizationUseCaseProtocol? = nil) {
        if let useCase = summarizationUseCase {
            self.summarizationUseCase = useCase
        } else {
            self.summarizationUseCase = SummarizationUseCase(
                summarizationService: CoreMLSummarizationService()
            )
        }
        
        setupObservers()
        logger.info("SummarizationViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    func initialize() async {
        guard state == .idle else {
            logger.debug("ViewModel already initialized or in progress")
            return
        }
        
        logger.info("Initializing summarization model...")
        state = .initializing
        errorMessage = nil
        
        do {
            try await summarizationUseCase.initialize()
            state = .ready
            isModelLoaded = true
            logger.info("Model initialized successfully")
        } catch {
            let errorMsg = "Failed to initialize AI model: \(error.localizedDescription)"
            logger.error("\(errorMsg)")
            state = .error(errorMsg)
            errorMessage = errorMsg
            isModelLoaded = false
        }
    }
    
    func summarizeText(_ text: String) async {
        guard canSummarize else {
            logger.warning("Cannot summarize: model not ready or already processing")
            return
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            handleError("No text provided for summarization")
            return
        }
        
        logger.info("Starting text summarization...")
        state = .processing
        errorMessage = nil
        
        // Cancel any existing processing task
        currentProcessingTask?.cancel()
        
        currentProcessingTask = Task {
            do {
                let input = SummarizationInput(
                    text: text,
                    summaryLength: selectedSummaryLength
                )
                
                let output = try await summarizationUseCase.execute(input: input)
                
                // Check if task was cancelled
                guard !Task.isCancelled else {
                    logger.debug("Summarization task was cancelled")
                    return
                }
                
                summaryResult = output.result
                state = .completed(output.result)
                logger.info("Summarization completed successfully")
                
            } catch {
                guard !Task.isCancelled else {
                    logger.debug("Summarization task was cancelled due to error")
                    return
                }
                
                let errorMsg = error.localizedDescription
                logger.error("Summarization failed: \(errorMsg)")
                handleError(errorMsg)
            }
        }
    }
    
    func summarizeTranscription(_ transcriptionResult: TranscriptionResult) async {
        await summarizeText(transcriptionResult.text)
    }
    
    func resetState() {
        logger.info("Resetting summarization state")
        currentProcessingTask?.cancel()
        currentProcessingTask = nil
        
        state = isModelLoaded ? .ready : .idle
        summaryResult = nil
        errorMessage = nil
    }
    
    func clearSummary() {
        logger.info("Clearing summary results")
        summaryResult = nil
        state = isModelLoaded ? .ready : .idle
        errorMessage = nil
    }
    
    func retryLastOperation() async {
        guard let lastResult = summaryResult else {
            logger.warning("No previous operation to retry")
            return
        }
        
        await summarizeText(lastResult.originalText)
    }
    
    func changeSummaryLength(_ newLength: SummaryLength) {
        selectedSummaryLength = newLength
        logger.debug("Summary length changed to: \(newLength.displayName)")
        
        // If we have a current result, regenerate with new length
        if let currentResult = summaryResult {
            Task {
                await summarizeText(currentResult.originalText)
            }
        }
    }
    
    func exportSummary() -> String? {
        guard let result = summaryResult else { return nil }
        
        let timestamp = DateFormatter.localizedString(
            from: result.processedAt,
            dateStyle: .medium,
            timeStyle: .short
        )
        
        return """
        Speech Summary Report
        Generated: \(timestamp)
        
        Original Text:
        \(result.originalText)
        
        Summary (\(result.summaryLength.displayName)):
        \(result.summary)
        
        Processing Time: \(String(format: "%.2f", result.processingTime))s
        """
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe use case state if it's an ObservableObject
        if let observableUseCase = summarizationUseCase as? SummarizationUseCase {
            observableUseCase.$isInitialized
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isInitialized in
                    self?.isModelLoaded = isInitialized
                }
                .store(in: &cancellables)
        }
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        state = .error(message)
        summaryResult = nil
    }
}

// MARK: - Extensions

extension SummarizationViewModel {
    
    static let preview: SummarizationViewModel = {
        let viewModel = SummarizationViewModel()
        viewModel.state = .ready
        viewModel.isModelLoaded = true
        return viewModel
    }()
    
    static let previewWithResult: SummarizationViewModel = {
        let viewModel = SummarizationViewModel()
        let sampleResult = SummaryResult(
            originalText: "This is a long piece of text that has been transcribed from speech and needs to be summarized for better understanding and readability.",
            summary: "This text was transcribed and summarized for better readability.",
            processingTime: 2.5,
            confidence: 0.92
        )
        viewModel.summaryResult = sampleResult
        viewModel.state = .completed(sampleResult)
        viewModel.isModelLoaded = true
        return viewModel
    }()
}