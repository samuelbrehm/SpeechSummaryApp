import XCTest
@testable import SpeechSummaryApp

@MainActor
final class SummarizationViewModelTests: XCTestCase {
    
    var viewModel: SummarizationViewModel!
    var mockUseCase: MockSummarizationUseCase!
    
    override func setUpWithError() throws {
        super.setUp()
        mockUseCase = MockSummarizationUseCase()
        viewModel = SummarizationViewModel(summarizationUseCase: mockUseCase)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.summaryResult)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.selectedSummaryLength, .medium)
        XCTAssertFalse(viewModel.isModelLoaded)
        XCTAssertFalse(viewModel.canSummarize)
    }
    
    // MARK: - Initialization Tests
    
    func testSuccessfulInitialization() async {
        mockUseCase.shouldInitializeSucceed = true
        
        await viewModel.initialize()
        
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertTrue(viewModel.isModelLoaded)
        XCTAssertTrue(viewModel.canSummarize)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFailedInitialization() async {
        mockUseCase.shouldInitializeSucceed = false
        
        await viewModel.initialize()
        
        if case .error(let message) = viewModel.state {
            XCTAssertTrue(message.contains("Failed to initialize"))
        } else {
            XCTFail("State should be error")
        }
        
        XCTAssertFalse(viewModel.isModelLoaded)
        XCTAssertFalse(viewModel.canSummarize)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testMultipleInitializationCalls() async {
        mockUseCase.shouldInitializeSucceed = true
        
        await viewModel.initialize()
        XCTAssertEqual(viewModel.state, .ready)
        
        // Second call should not change state
        await viewModel.initialize()
        XCTAssertEqual(viewModel.state, .ready)
    }
    
    // MARK: - Summarization Tests
    
    func testSuccessfulSummarization() async {
        // Setup
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = true
        await viewModel.initialize()
        
        let testText = "This is a test text that should be summarized successfully."
        
        await viewModel.summarizeText(testText)
        
        if case .completed(let result) = viewModel.state {
            XCTAssertEqual(result.originalText, testText)
            XCTAssertFalse(result.summary.isEmpty)
        } else {
            XCTFail("State should be completed")
        }
        
        XCTAssertNotNil(viewModel.summaryResult)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSummarizationWithEmptyText() async {
        mockUseCase.shouldInitializeSucceed = true
        await viewModel.initialize()
        
        await viewModel.summarizeText("")
        
        if case .error(let message) = viewModel.state {
            XCTAssertTrue(message.contains("No text provided"))
        } else {
            XCTFail("State should be error")
        }
    }
    
    func testSummarizationWithWhitespaceOnlyText() async {
        mockUseCase.shouldInitializeSucceed = true
        await viewModel.initialize()
        
        await viewModel.summarizeText("   \n\t   ")
        
        if case .error(let message) = viewModel.state {
            XCTAssertTrue(message.contains("No text provided"))
        } else {
            XCTFail("State should be error")
        }
    }
    
    func testSummarizationWithoutInitialization() async {
        let testText = "Test text"
        
        await viewModel.summarizeText(testText)
        
        // Should not process because model is not ready
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.summaryResult)
    }
    
    func testSummarizationFailure() async {
        // Setup
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = false
        await viewModel.initialize()
        
        let testText = "This text should fail to summarize."
        
        await viewModel.summarizeText(testText)
        
        if case .error = viewModel.state {
            // Expected
        } else {
            XCTFail("State should be error")
        }
        
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Transcription Summarization Tests
    
    func testSummarizeTranscription() async {
        // Setup
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = true
        await viewModel.initialize()
        
        let transcription = TranscriptionResult(
            text: "This is transcribed text that needs summarization.",
            confidence: 0.95
        )
        
        await viewModel.summarizeTranscription(transcription)
        
        if case .completed(let result) = viewModel.state {
            XCTAssertEqual(result.originalText, transcription.text)
        } else {
            XCTFail("State should be completed")
        }
    }
    
    // MARK: - State Management Tests
    
    func testResetState() async {
        // Setup with completed state
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = true
        await viewModel.initialize()
        await viewModel.summarizeText("Test text")
        
        // Verify we have results
        XCTAssertNotNil(viewModel.summaryResult)
        
        // Reset
        viewModel.resetState()
        
        XCTAssertEqual(viewModel.state, .ready) // Should go back to ready since model is loaded
        XCTAssertNil(viewModel.summaryResult)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testResetStateWhenNotInitialized() {
        viewModel.resetState()
        
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.summaryResult)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Summary Length Change Tests
    
    func testChangeSummaryLength() {
        viewModel.changeSummaryLength(.long)
        
        XCTAssertEqual(viewModel.selectedSummaryLength, .long)
    }
    
    func testChangeSummaryLengthWithExistingResult() async {
        // Setup with existing result
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = true
        await viewModel.initialize()
        await viewModel.summarizeText("Test text")
        
        XCTAssertNotNil(viewModel.summaryResult)
        let originalCallCount = mockUseCase.executeCallCount
        
        // Change summary length
        viewModel.changeSummaryLength(.long)
        
        // Should trigger re-summarization
        try? await Task.sleep(nanoseconds: 100_000_000) // Give time for async operation
        
        XCTAssertEqual(viewModel.selectedSummaryLength, .long)
        XCTAssertGreaterThan(mockUseCase.executeCallCount, originalCallCount)
    }
    
    // MARK: - Export Tests
    
    func testExportSummaryWithResult() async {
        // Setup with result
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = true
        await viewModel.initialize()
        await viewModel.summarizeText("Test text for export")
        
        let exportText = viewModel.exportSummary()
        
        XCTAssertNotNil(exportText)
        XCTAssertTrue(exportText!.contains("Speech Summary Report"))
        XCTAssertTrue(exportText!.contains("Test text for export"))
        XCTAssertTrue(exportText!.contains("Mock summary"))
    }
    
    func testExportSummaryWithoutResult() {
        let exportText = viewModel.exportSummary()
        
        XCTAssertNil(exportText)
    }
    
    // MARK: - Computed Properties Tests
    
    func testProcessingProgress() async {
        XCTAssertEqual(viewModel.processingProgress, "")
        
        // Test initializing state
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.initializeDelay = 0.1
        
        let initTask = Task {
            await viewModel.initialize()
        }
        
        // Check progress during initialization
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.processingProgress, "Loading AI model...")
        
        await initTask.value
        
        // Test processing state
        mockUseCase.executeDelay = 0.1
        let processTask = Task {
            await viewModel.summarizeText("Test text")
        }
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.processingProgress, "Generating summary...")
        
        await processTask.value
    }
    
    // MARK: - Retry Tests
    
    func testRetryLastOperation() async {
        // Setup with completed operation
        mockUseCase.shouldInitializeSucceed = true
        mockUseCase.shouldExecuteSucceed = true
        await viewModel.initialize()
        await viewModel.summarizeText("Test text")
        
        let originalCallCount = mockUseCase.executeCallCount
        
        await viewModel.retryLastOperation()
        
        XCTAssertGreaterThan(mockUseCase.executeCallCount, originalCallCount)
    }
    
    func testRetryWithoutPreviousOperation() async {
        mockUseCase.shouldInitializeSucceed = true
        await viewModel.initialize()
        
        let originalCallCount = mockUseCase.executeCallCount
        
        await viewModel.retryLastOperation()
        
        XCTAssertEqual(mockUseCase.executeCallCount, originalCallCount)
    }
}

// MARK: - Mock Use Case

@MainActor
final class MockSummarizationUseCase: SummarizationUseCaseProtocol {
    
    var shouldInitializeSucceed = true
    var shouldExecuteSucceed = true
    var initializeDelay: TimeInterval = 0
    var executeDelay: TimeInterval = 0
    
    var initializeCallCount = 0
    var executeCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        
        if initializeDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(initializeDelay * 1_000_000_000))
        }
        
        if !shouldInitializeSucceed {
            throw SummarizationError.modelLoadingFailed(NSError(domain: "mock", code: 1))
        }
    }
    
    func execute(input: SummarizationInput) async throws -> SummarizationOutput {
        executeCallCount += 1
        
        if executeDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(executeDelay * 1_000_000_000))
        }
        
        if !shouldExecuteSucceed {
            throw SummarizationError.processingFailed(NSError(domain: "mock", code: 2))
        }
        
        let result = SummaryResult(
            originalText: input.text,
            summary: "Mock summary of the input text",
            processingTime: 1.0,
            confidence: 0.9,
            summaryLength: input.summaryLength
        )
        
        return SummarizationOutput(result: result, requestId: input.requestId)
    }
    
    func isAvailable() -> Bool {
        return shouldInitializeSucceed && initializeCallCount > 0
    }
}