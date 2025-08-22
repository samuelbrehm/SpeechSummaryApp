import XCTest
@testable import SpeechSummaryApp

@MainActor
final class SummarizationUseCaseTests: XCTestCase {
    
    var useCase: SummarizationUseCase!
    var mockService: MockSummarizationService!
    
    override func setUpWithError() throws {
        super.setUp()
        mockService = MockSummarizationService()
        useCase = SummarizationUseCase(summarizationService: mockService)
    }
    
    override func tearDownWithError() throws {
        useCase = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() throws {
        XCTAssertFalse(useCase.isInitialized)
        XCTAssertFalse(useCase.isAvailable())
        XCTAssertNil(useCase.lastError)
    }
    
    func testSuccessfulInitialization() async throws {
        mockService.shouldInitializeSucceed = true
        
        try await useCase.initialize()
        
        XCTAssertTrue(useCase.isInitialized)
        XCTAssertTrue(useCase.isAvailable())
        XCTAssertNil(useCase.lastError)
    }
    
    func testFailedInitialization() async throws {
        mockService.shouldInitializeSucceed = false
        mockService.initializationError = SummarizationError.modelNotFound
        
        do {
            try await useCase.initialize()
            XCTFail("Should throw initialization error")
        } catch SummarizationError.modelNotFound {
            XCTAssertFalse(useCase.isInitialized)
            XCTAssertFalse(useCase.isAvailable())
            XCTAssertNotNil(useCase.lastError)
        }
    }
    
    func testMultipleInitializationCalls() async throws {
        mockService.shouldInitializeSucceed = true
        
        try await useCase.initialize()
        let initCallsAfterFirst = mockService.initializeCallCount
        
        try await useCase.initialize()
        
        XCTAssertEqual(mockService.initializeCallCount, initCallsAfterFirst)
        XCTAssertTrue(useCase.isInitialized)
    }
    
    // MARK: - Execution Tests
    
    func testSuccessfulExecution() async throws {
        // Setup
        mockService.shouldInitializeSucceed = true
        mockService.shouldSummarizeSucceed = true
        try await useCase.initialize()
        
        let input = SummarizationInput(
            text: "This is a long enough text that should be successfully summarized by the service.",
            summaryLength: .medium
        )
        
        let output = try await useCase.execute(input: input)
        
        XCTAssertEqual(output.requestId, input.requestId)
        XCTAssertEqual(output.result.originalText, input.text)
        XCTAssertEqual(output.result.summaryLength, input.summaryLength)
        XCTAssertFalse(output.result.summary.isEmpty)
        XCTAssertNil(useCase.lastError)
    }
    
    func testExecutionWithoutInitialization() async throws {
        let input = SummarizationInput(text: "Test text")
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should throw error when not initialized")
        } catch SummarizationError.modelNotLoaded {
            // Expected error
        }
    }
    
    func testExecutionWithTranscriptionResult() async throws {
        // Setup
        mockService.shouldInitializeSucceed = true
        mockService.shouldSummarizeSucceed = true
        try await useCase.initialize()
        
        let transcription = TranscriptionResult(
            text: "This is a transcribed text that needs to be summarized for better understanding.",
            confidence: 0.95
        )
        
        let output = try await useCase.executeSummarization(
            for: transcription,
            summaryLength: .short
        )
        
        XCTAssertEqual(output.result.originalText, transcription.text)
        XCTAssertEqual(output.result.summaryLength, .short)
    }
    
    // MARK: - Input Validation Tests
    
    func testValidationWithEmptyText() async throws {
        mockService.shouldInitializeSucceed = true
        try await useCase.initialize()
        
        let input = SummarizationInput(text: "")
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should throw validation error")
        } catch SummarizationError.invalidInput {
            XCTAssertEqual(useCase.lastError, .invalidInput)
        }
    }
    
    func testValidationWithWhitespaceOnlyText() async throws {
        mockService.shouldInitializeSucceed = true
        try await useCase.initialize()
        
        let input = SummarizationInput(text: "   \n\t   ")
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should throw validation error")
        } catch SummarizationError.invalidInput {
            // Expected error
        }
    }
    
    func testValidationWithTooShortText() async throws {
        mockService.shouldInitializeSucceed = true
        try await useCase.initialize()
        
        let input = SummarizationInput(text: "Short")
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should throw validation error")
        } catch SummarizationError.textTooShort {
            // Expected error
        }
    }
    
    func testValidationWithTooLongText() async throws {
        mockService.shouldInitializeSucceed = true
        try await useCase.initialize()
        
        let input = SummarizationInput(text: String(repeating: "A", count: 3000))
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should throw validation error")
        } catch SummarizationError.textTooLong {
            // Expected error
        }
    }
    
    func testValidationWithInsufficientVariety() async throws {
        mockService.shouldInitializeSucceed = true
        try await useCase.initialize()
        
        let input = SummarizationInput(text: String(repeating: "same word ", count: 20))
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should throw validation error")
        } catch SummarizationError.textTooShort {
            // Expected error for insufficient variety
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testServiceErrorPropagation() async throws {
        mockService.shouldInitializeSucceed = true
        mockService.shouldSummarizeSucceed = false
        mockService.summarizationError = SummarizationError.processingFailed(NSError(domain: "test", code: 1))
        try await useCase.initialize()
        
        let input = SummarizationInput(text: "Valid text for summarization that meets all requirements.")
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should propagate service error")
        } catch SummarizationError.processingFailed {
            XCTAssertNotNil(useCase.lastError)
        }
    }
    
    func testUnexpectedErrorHandling() async throws {
        mockService.shouldInitializeSucceed = true
        mockService.shouldSummarizeSucceed = false
        mockService.summarizationError = NSError(domain: "unexpected", code: 999)
        try await useCase.initialize()
        
        let input = SummarizationInput(text: "Valid text for summarization that meets all requirements.")
        
        do {
            _ = try await useCase.execute(input: input)
            XCTFail("Should wrap unexpected error")
        } catch SummarizationError.processingFailed {
            XCTAssertNotNil(useCase.lastError)
        }
    }
}

// MARK: - Mock Service

@MainActor
final class MockSummarizationService: SummarizationServiceProtocol {
    
    var isModelLoaded: Bool = false
    var modelInfo: ModelInfo = .notLoaded
    
    var shouldInitializeSucceed = true
    var shouldSummarizeSucceed = true
    var initializationError: Error?
    var summarizationError: Error?
    
    var initializeCallCount = 0
    var summarizeCallCount = 0
    
    func initialize() async throws {
        initializeCallCount += 1
        
        if shouldInitializeSucceed {
            isModelLoaded = true
            modelInfo = ModelInfo(name: "Mock Model", version: "1.0", size: 1000, isLoaded: true)
        } else {
            throw initializationError ?? SummarizationError.modelLoadingFailed(NSError(domain: "mock", code: 1))
        }
    }
    
    func summarize(text: String, maxLength: SummaryLength) async throws -> SummaryResult {
        summarizeCallCount += 1
        
        if shouldSummarizeSucceed {
            return SummaryResult(
                originalText: text,
                summary: "Mock summary of the provided text",
                processingTime: 1.0,
                confidence: 0.9,
                summaryLength: maxLength
            )
        } else {
            throw summarizationError ?? SummarizationError.processingFailed(NSError(domain: "mock", code: 2))
        }
    }
    
    func cleanup() {
        isModelLoaded = false
        modelInfo = .notLoaded
    }
}