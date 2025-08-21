# Implementation Prompts: Core ML Text Summarization

## Overview
This document provides AI-assisted development prompts for implementing Core ML text summarization in the SpeechSummaryApp. These prompts are designed to guide Claude Code through the implementation process while maintaining architectural consistency and best practices.

## Core Service Implementation

### SummarizationService Prompt
```
Please implement a Core ML-based SummarizationService for iOS that follows these requirements:

**Context**: 
- This is part of SpeechSummaryApp using MVVM architecture
- Must integrate with existing SpeechService workflow
- Follow patterns established in docs/ADRs/003-architecture-mvvm.md
- Use Core ML for on-device text summarization

**Requirements**:
1. Create SummarizationServiceProtocol with async methods
2. Implement CoreMLSummarizationService class
3. Support model loading/unloading with memory optimization
4. Handle text preprocessing and postprocessing
5. Implement comprehensive error handling using AppError enum
6. Add performance monitoring and logging
7. Follow Swift concurrency best practices with async/await

**Architecture**:
- Service Layer: Framework abstraction
- Protocol-based design for testability
- Dependency injection via initializers
- @Published properties for reactive state
- Memory-conscious model lifecycle management

**Integration Points**:
- Works with existing SpeechService output (TranscriptionResult)
- Integrates with SummarizationUseCase (business logic layer)
- Supports SummarizationViewModel reactive updates
- Uses Core ML models bundled in app (DistilBART/T5)

**Error Handling**:
Extend existing AppError enum with:
- modelNotLoaded, textTooLong, summarizationFailed
- Provide user-friendly error descriptions and recovery suggestions

**Performance Requirements**:
- Model loading < 3 seconds
- Inference time < 5 seconds for typical text
- Memory usage monitoring
- Background processing support
```

### Use Case Implementation Prompt
```
Implement SummarizationUseCase following Clean Architecture patterns:

**Context**:
- Business logic layer between ViewModel and Service
- Part of existing MVVM + Use Case architecture
- Must handle complex summarization workflow orchestration

**Requirements**:
1. Create SummarizationUseCaseProtocol
2. Implement business logic for text summarization
3. Handle input validation and preprocessing
4. Orchestrate service calls with proper error handling
5. Format output for UI consumption
6. Support configurable summary lengths
7. Add comprehensive unit tests

**Input/Output Models**:
```swift
struct SummarizationInput {
    let text: String
    let maxLength: SummaryLength
    let language: String?
}

struct SummarizationOutput {
    let result: SummaryResult
    let processingMetrics: ProcessingMetrics?
}
```

**Business Rules**:
- Minimum text length: 50 characters
- Maximum text length: 5000 characters  
- Automatic language detection if not provided
- Quality validation of generated summaries
- Fallback strategies for model failures

**Integration**:
- Called by SummarizationViewModel
- Uses SummarizationService for ML processing
- Coordinates with existing SpeechRecognitionUseCase
- Follows reactive programming patterns with Combine
```

### ViewModel Implementation Prompt
```
Create SummarizationViewModel following existing MVVM patterns:

**Context**:
- @MainActor ViewModel for SwiftUI integration
- Reactive properties using @Published and Combine
- Integrates with existing SpeechRecognitionViewModel
- Follows patterns from docs/context/technical-stack.md

**Requirements**:
1. @MainActor final class with ObservableObject conformance
2. @Published state properties for UI binding
3. Async methods for user actions
4. Integration with SummarizationUseCase
5. Comprehensive error state management
6. Progress tracking and user feedback
7. Configuration options (summary length, etc.)

**State Management**:
```swift
enum SummarizationState {
    case idle
    case processing
    case completed(SummaryResult)
    case error(AppError)
}

@Published var state: SummarizationState = .idle
@Published var processingProgress: Double = 0.0
@Published var summaryLength: SummaryLength = .medium
@Published var errorMessage: String?
```

**User Actions**:
- summarizeText(String) -> async method
- changeSummaryLength(SummaryLength)
- retryLastSummarization()
- clearResults()

**Integration Points**:
- Receives TranscriptionResult from SpeechRecognitionViewModel
- Triggers summarization automatically or on user request
- Provides reactive updates for SwiftUI views
- Handles navigation between speech and summary states
```

## UI Implementation

### SwiftUI Views Prompt
```
Implement SwiftUI views for summarization feature following liquid glass design:

**Context**:
- Modern iOS design with liquid glass effects
- Follows existing SpeechRecognitionView patterns
- Accessible and responsive design
- Integration with existing ContentView

**Views to Create**:

1. **SummarizationResultView**:
   - Display original transcription and generated summary
   - Side-by-side or stacked layout (responsive)
   - Copy and share functionality
   - Loading states with progress indicators
   
2. **SummaryControlsView**:
   - Summary length selection (short/medium/long)
   - Retry and clear buttons
   - Progress indicators during processing
   
3. **SummaryDisplayCard**:
   - Reusable component for text display
   - Liquid glass background with blur effects
   - Proper typography with Dynamic Type support

**Design Requirements**:
- iOS HIG compliance
- Dark/Light mode support
- Dynamic Type and accessibility
- Smooth animations using SwiftUI transitions
- Haptic feedback for user interactions

**Integration**:
- Binds to SummarizationViewModel @Published properties
- Uses existing design system colors and typography
- Integrates with ContentView navigation flow
- Supports iPad and iPhone layouts
```

### Integration View Prompt
```
Update ContentView to integrate summarization workflow:

**Context**:
- Main app view currently shows SpeechRecognitionView
- Need seamless flow from speech-to-text to summarization
- Maintain existing navigation and state management

**Integration Requirements**:
1. Update ContentView to handle both speech and summarization
2. Create smooth transitions between workflow states
3. Coordinate ViewModels for data flow
4. Add navigation controls for user choice
5. Handle error states across the entire workflow

**Workflow States**:
```swift
enum AppWorkflowState {
    case speechRecognition
    case transcriptionReview
    case summarizing
    case results
    case error(AppError)
}
```

**User Flow**:
Speech Recording → Transcription Display → Summarization Options → Processing → Results Display

**State Coordination**:
- SpeechRecognitionViewModel provides transcription
- User confirms/edits transcription
- SummarizationViewModel processes the text
- Results displayed with both transcription and summary
- Options to restart workflow or share results
```

## Testing Implementation

### Unit Testing Prompt
```
Create comprehensive unit tests for Core ML summarization:

**Test Coverage Requirements**:
- Service layer: 90%+ coverage
- Use case layer: 95%+ coverage  
- ViewModel layer: 85%+ coverage
- Error scenarios: 100% coverage

**Test Categories**:

1. **SummarizationServiceTests**:
   - Model loading/unloading
   - Text preprocessing and postprocessing
   - Error handling for various scenarios
   - Memory management
   - Performance benchmarks

2. **SummarizationUseCaseTests**:
   - Business logic validation
   - Input validation edge cases
   - Service integration mocking
   - Error propagation
   - Output formatting

3. **SummarizationViewModelTests**:
   - @MainActor property updates
   - Async action handling
   - State transitions
   - Error state management
   - Integration with Use Case

**Mock Implementation**:
Create MockSummarizationService for testing:
- Predictable responses for test scenarios
- Configurable delays for async testing
- Error injection capabilities
- Performance simulation

**Test Utilities**:
- Sample text generators of various lengths
- Expected output validation helpers
- Async testing utilities
- Memory leak detection helpers
```

### Performance Testing Prompt
```
Implement performance testing for summarization feature:

**Metrics to Track**:
1. Model loading time across different devices
2. Inference time for various text lengths
3. Memory usage during processing
4. UI responsiveness during heavy operations
5. Battery impact measurement

**Test Implementation**:
```swift
final class SummarizationPerformanceTests: XCTestCase {
    
    func testModelLoadingPerformance() {
        // Measure model initialization time
        // Target: < 3 seconds on iPhone 12+
    }
    
    func testInferencePerformance() {
        // Measure summarization time for different text sizes
        // Target: < 5 seconds for 500 words
    }
    
    func testMemoryUsage() {
        // Monitor memory consumption during processing
        // Target: < 150MB peak usage
    }
    
    func testConcurrentRequests() {
        // Test multiple summarization requests
        // Validate proper queue management
    }
}
```

**Benchmarking Framework**:
- Device capability detection
- Baseline performance establishment
- Regression detection
- Performance reporting and visualization
```

## Integration Testing

### End-to-End Testing Prompt
```
Implement integration tests for complete speech-to-summary workflow:

**Test Scenarios**:

1. **Happy Path Integration**:
   - Record speech → Transcribe → Summarize → Display results
   - Validate data flow between all components
   - Verify UI state updates throughout workflow

2. **Error Handling Integration**:
   - Model loading failures
   - Network unavailable scenarios
   - Memory pressure situations
   - Recovery and retry mechanisms

3. **Edge Cases**:
   - Very long transcriptions
   - Very short transcriptions
   - Non-English content (if supported)
   - Background/foreground transitions

**Integration Test Structure**:
```swift
final class SpeechSummaryIntegrationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    func testCompleteWorkflow() {
        // Test entire user journey
        // Mock audio input for consistent testing
        // Validate UI updates at each step
    }
    
    func testErrorRecovery() {
        // Inject failures at different points
        // Verify graceful error handling
        // Test user recovery actions
    }
    
    func testMemoryManagement() {
        // Run extended scenarios
        // Monitor memory usage
        // Validate proper cleanup
    }
}
```

**Mocking Strategy**:
- Mock SpeechService for consistent transcription
- Mock Core ML model for predictable summarization
- Simulate various device conditions
- Control timing for async operations
```

## Documentation Prompts

### Code Documentation Prompt
```
Add comprehensive documentation to all Core ML implementation:

**Documentation Standards**:
- Swift DocC format for all public APIs
- Inline comments for complex business logic
- README updates for new features
- Architecture decision records for major changes

**Required Documentation**:

1. **API Documentation**:
```swift
/// Core ML-based text summarization service
/// 
/// Provides on-device text summarization using DistilBART model.
/// Optimized for iOS devices with Neural Engine support.
///
/// ## Usage
/// ```swift
/// let service = CoreMLSummarizationService()
/// try await service.initialize()
/// let result = try await service.summarize(text: "...", maxLength: .medium)
/// ```
///
/// ## Performance
/// - Model loading: < 3 seconds
/// - Inference: < 5 seconds (500 words)
/// - Memory usage: < 150MB peak
public final class CoreMLSummarizationService: SummarizationServiceProtocol
```

2. **Implementation Notes**:
- Complex algorithm explanations
- Performance optimization rationale
- Error handling strategy documentation
- Integration points and dependencies

3. **User Guide**:
- Feature overview for end users
- Troubleshooting common issues
- Privacy and data handling explanation
- Accessibility features documentation
```

### Architecture Documentation Prompt
```
Update architectural documentation for Core ML integration:

**Documents to Update**:

1. **Technical Stack (docs/context/technical-stack.md)**:
   - Add Core ML framework details
   - Update service layer architecture
   - Document new data models and protocols
   - Add performance considerations

2. **Architecture ADR (docs/ADRs/003-architecture-mvvm.md)**:
   - Document Core ML service integration
   - Update MVVM pattern implementation
   - Add testing strategies for ML components
   - Document dependency injection changes

3. **Implementation Guide**:
   - Step-by-step Core ML integration
   - Model selection and conversion process
   - Performance optimization techniques
   - Troubleshooting common issues

**Documentation Standards**:
- Mermaid diagrams for architecture visualization
- Code examples for key patterns
- Decision rationale documentation
- Future considerations and extensibility
```

## Deployment and Release

### Release Preparation Prompt
```
Prepare Core ML summarization feature for production release:

**Pre-Release Checklist**:

1. **Code Quality**:
   - SwiftLint compliance (100%)
   - SwiftFormat consistency
   - Code review completion
   - Security audit for ML models

2. **Testing Validation**:
   - Unit test coverage > 90%
   - Integration tests passing
   - Performance benchmarks met
   - Device compatibility validated

3. **Documentation**:
   - API documentation complete
   - User guide updated
   - Privacy policy updated
   - App Store description ready

4. **App Store Compliance**:
   - Privacy labels configuration
   - App size optimization
   - TestFlight beta testing
   - Review guidelines compliance

**Release Configuration**:
```swift
// Production optimizations
#if RELEASE
let modelConfig = MLModelConfiguration()
modelConfig.computeUnits = .cpuAndNeuralEngine
modelConfig.allowLowPrecisionAccumulationOnGPU = true
#endif
```

**Monitoring Setup**:
- Crash reporting integration
- Performance metrics collection  
- Feature usage analytics
- Error rate monitoring
```

## Maintenance and Updates

### Model Update Strategy Prompt
```
Implement strategy for Core ML model updates:

**Update Mechanism Design**:

1. **Versioning System**:
```swift
struct ModelVersion {
    let major: Int
    let minor: Int
    let patch: Int
    let modelHash: String
    
    var isCompatible: Bool {
        // Compatibility checking logic
    }
}
```

2. **Update Process**:
   - Model validation before deployment
   - Fallback to previous version on failure
   - Progressive rollout capability
   - User notification for significant improvements

3. **A/B Testing Framework**:
   - Multiple model support
   - Performance comparison
   - User experience metrics
   - Gradual model migration

**Implementation Requirements**:
- Backward compatibility maintenance
- Seamless user experience during updates  
- Performance regression detection
- Rollback capability for failed updates

**Monitoring and Analytics**:
- Model performance metrics
- User satisfaction tracking
- Error rate monitoring
- Feature adoption analytics
```

These implementation prompts provide comprehensive guidance for developing the Core ML text summarization feature while maintaining architectural consistency and development best practices. Use them to guide AI-assisted development sessions and ensure complete feature implementation.