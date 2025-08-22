import XCTest
@testable import SpeechSummaryApp

@MainActor
final class SummarizationServiceTests: XCTestCase {
    
    var service: CoreMLSummarizationService!
    
    override func setUpWithError() throws {
        super.setUp()
        service = CoreMLSummarizationService()
    }
    
    override func tearDownWithError() throws {
        service.cleanup()
        service = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() throws {
        XCTAssertFalse(service.isModelLoaded)
        XCTAssertEqual(service.modelInfo.name, "Unknown")
        XCTAssertFalse(service.modelInfo.isLoaded)
    }
    
    func testModelInitialization() async throws {
        XCTAssertFalse(service.isModelLoaded)
        
        try await service.initialize()
        
        XCTAssertTrue(service.isModelLoaded)
        XCTAssertNotEqual(service.modelInfo.name, "Unknown")
        XCTAssertTrue(service.modelInfo.isLoaded)
    }
    
    func testMultipleInitializationCalls() async throws {
        try await service.initialize()
        XCTAssertTrue(service.isModelLoaded)
        
        // Second call should not throw and should maintain loaded state
        try await service.initialize()
        XCTAssertTrue(service.isModelLoaded)
    }
    
    // MARK: - Summarization Tests
    
    func testSummarizationWithValidInput() async throws {
        try await service.initialize()
        
        let sampleText = """
        This is a comprehensive sample text that contains multiple sentences and provides 
        sufficient context for the summarization model to generate meaningful output. 
        The text discusses various topics and includes enough content to be properly 
        summarized while maintaining the key information and context.
        """
        
        let result = try await service.summarize(
            text: sampleText,
            maxLength: .medium
        )
        
        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertEqual(result.originalText, sampleText)
        XCTAssertGreaterThan(result.processingTime, 0)
        XCTAssertEqual(result.summaryLength, .medium)
        XCTAssertNotNil(result.confidence)
        XCTAssertLessThan(result.summary.count, sampleText.count)
    }
    
    func testSummarizationWithDifferentLengths() async throws {
        try await service.initialize()
        
        let sampleText = String(repeating: "This is a test sentence. ", count: 20)
        
        let shortResult = try await service.summarize(text: sampleText, maxLength: .short)
        let mediumResult = try await service.summarize(text: sampleText, maxLength: .medium)
        let longResult = try await service.summarize(text: sampleText, maxLength: .long)
        
        XCTAssertEqual(shortResult.summaryLength, .short)
        XCTAssertEqual(mediumResult.summaryLength, .medium)
        XCTAssertEqual(longResult.summaryLength, .long)
        
        // All should produce valid summaries
        XCTAssertFalse(shortResult.summary.isEmpty)
        XCTAssertFalse(mediumResult.summary.isEmpty)
        XCTAssertFalse(longResult.summary.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testSummarizationWithoutInitialization() async throws {
        do {
            _ = try await service.summarize(text: "Test text", maxLength: .medium)
            XCTFail("Should throw error when model not loaded")
        } catch SummarizationError.modelNotLoaded {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSummarizationWithEmptyInput() async throws {
        try await service.initialize()
        
        do {
            _ = try await service.summarize(text: "", maxLength: .medium)
            XCTFail("Should throw error for empty input")
        } catch SummarizationError.invalidInput {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSummarizationWithWhitespaceOnlyInput() async throws {
        try await service.initialize()
        
        do {
            _ = try await service.summarize(text: "   \n\t   ", maxLength: .medium)
            XCTFail("Should throw error for whitespace-only input")
        } catch SummarizationError.invalidInput {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSummarizationWithTooShortText() async throws {
        try await service.initialize()
        
        do {
            _ = try await service.summarize(text: "Short", maxLength: .medium)
            XCTFail("Should throw error for too short text")
        } catch SummarizationError.textTooShort {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSummarizationWithTooLongText() async throws {
        try await service.initialize()
        
        let longText = String(repeating: "A", count: 3000)
        
        do {
            _ = try await service.summarize(text: longText, maxLength: .medium)
            XCTFail("Should throw error for too long text")
        } catch SummarizationError.textTooLong {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testModelLoadingPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Model loading")
            
            Task {
                try await service.initialize()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testSummarizationPerformance() throws {
        let setupExpectation = XCTestExpectation(description: "Setup")
        Task {
            try await service.initialize()
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 5.0)
        
        let sampleText = String(repeating: "This is a test sentence with meaningful content. ", count: 10)
        
        measure {
            let expectation = XCTestExpectation(description: "Summarization")
            
            Task {
                _ = try await service.summarize(text: sampleText, maxLength: .medium)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() async throws {
        try await service.initialize()
        XCTAssertTrue(service.isModelLoaded)
        
        service.cleanup()
        
        XCTAssertFalse(service.isModelLoaded)
        XCTAssertFalse(service.modelInfo.isLoaded)
    }
}