# ADR-004: Core ML Text Summarization Implementation

## Status
**ACCEPTED** - December 2024

## Context

### Initial Approach Challenge
The original plan was to use Apple's FoundationModels framework for on-device text summarization. However, this approach proved unfeasible due to:

1. **Availability Constraints**: FoundationModels requires iOS 18.0+ and Apple Intelligence enabled
2. **Device Limitations**: Limited to newer devices with Apple Intelligence support  
3. **Simulator Incompatibility**: Cannot be tested in iOS Simulator
4. **Development Complexity**: Beta framework with limited documentation and examples

### Current Situation
We need a robust, widely compatible solution for on-device text summarization that:
- Maintains 100% privacy (no network calls)
- Works on a broader range of iOS devices
- Provides reliable performance for our demo application
- Can be developed and tested effectively

## Decision

### Chosen Approach: Core ML with Local Summarization Model
We will implement text summarization using **Core ML** with a pre-trained summarization model converted to Core ML format.

### Selected Architecture
```
┌─────────────────────┐
│  SpeechRecognition  │
│      Service        │
└──────────┬──────────┘
           │ TranscriptionResult
           ▼
┌─────────────────────┐
│  Summarization      │
│     UseCase         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  SummarizationService│
│    (Core ML)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Core ML Model     │
│  (DistilBART/T5)    │
└─────────────────────┘
```

## Rationale

### Why Core ML?
1. **Wide Compatibility**: Available since iOS 11, works on most devices
2. **Apple Native**: First-party framework with excellent optimization
3. **Performance**: Leverages Apple Neural Engine when available
4. **Privacy**: 100% on-device processing guaranteed
5. **Testability**: Works in iOS Simulator for development
6. **Stability**: Mature framework with extensive documentation

### Why Not Alternatives?

#### FoundationModels
- **Rejected**: Limited device compatibility, iOS 18.0+ requirement
- **Risk**: Beta status, insufficient documentation
- **Barrier**: Apple Intelligence requirement excludes many devices

#### Third-Party Frameworks (TensorFlow Lite, PyTorch Mobile)
- **Rejected**: Increases app size significantly  
- **Complexity**: Additional dependency management
- **Performance**: May not leverage Apple hardware optimizations
- **Privacy**: External dependencies introduce security considerations

#### Cloud-Based APIs (OpenAI, Anthropic)
- **Rejected**: Violates privacy-first principle
- **Dependency**: Requires network connectivity
- **Cost**: Usage-based pricing model
- **Latency**: Network round-trip delays

## Implementation Details

### Model Selection Strategy
We will evaluate and potentially implement multiple Core ML models:

#### Primary Option: DistilBART-CNN-12-6
- **Size**: ~40MB (acceptable for mobile)
- **Performance**: Good balance of quality and speed
- **Specialization**: News summarization (good for general text)
- **Conversion**: Available pre-converted or convertible from Hugging Face

#### Fallback Option: T5-Small
- **Size**: ~25MB (lighter weight)
- **Performance**: Faster inference, slightly lower quality
- **Flexibility**: Text-to-text transformer (versatile)
- **Conversion**: Well-documented Core ML conversion process

### Technical Architecture

#### SummarizationService Protocol
```swift
protocol SummarizationServiceProtocol {
    func initialize() async throws
    func summarize(text: String, maxLength: Int) async throws -> SummaryResult
    var isModelLoaded: Bool { get }
}

final class CoreMLSummarizationService: SummarizationServiceProtocol {
    private var model: MLModel?
    private let modelConfiguration: MLModelConfiguration
    
    // Implementation details
}
```

#### Data Models
```swift
struct SummaryResult {
    let originalText: String
    let summary: String
    let processingTime: TimeInterval
    let confidence: Float?
}

enum SummarizationError: LocalizedError {
    case modelNotLoaded
    case textTooLong
    case processingFailed(Error)
    case insufficientMemory
}
```

### Integration Points

#### With Speech Recognition Flow
```swift
// In SpeechRecognitionUseCase
func processTranscription(_ result: TranscriptionResult) async {
    // 1. Complete speech recognition
    // 2. Trigger summarization
    let summaryResult = try await summarizationUseCase.execute(
        input: SummarizationInput(text: result.transcription)
    )
    // 3. Update UI with both transcription and summary
}
```

#### With UI Layer
```swift
// In ContentView
struct SummarizationResultView: View {
    let transcription: String
    let summary: String?
    let isProcessing: Bool
    
    var body: some View {
        // Liquid glass design with transcription + summary
    }
}
```

## Consequences

### Positive Outcomes
1. **Broad Compatibility**: Works on iOS 15+ devices (most of our target audience)
2. **Reliable Performance**: Mature Core ML framework with predictable behavior
3. **Development Velocity**: Extensive documentation and community support
4. **Testing Capability**: Full simulator support for development workflow
5. **Privacy Guarantee**: No network dependencies, 100% on-device processing
6. **Apple Integration**: Seamless integration with existing iOS frameworks

### Trade-offs and Limitations
1. **Model Quality**: May not match latest transformer models in cloud services
2. **App Size**: Will increase app bundle size by 25-50MB
3. **Processing Speed**: Slower than cloud APIs, but acceptable for demo purposes
4. **Model Updates**: Requires app updates to improve model versions
5. **Memory Usage**: Additional memory overhead for model loading

### Risk Mitigation Strategies
1. **Performance Monitoring**: Implement telemetry for processing times and memory usage
2. **Graceful Degradation**: Fallback to "no summarization" mode if model fails
3. **Model Optimization**: Use quantized models to reduce size and improve speed
4. **Progressive Enhancement**: Load model lazily only when summarization is requested

## Migration Strategy

### From Current State
Since we haven't implemented FoundationModels yet, this is not a migration but a new implementation:

1. **Phase 1**: Implement Core ML service layer
2. **Phase 2**: Create summarization use cases and view models
3. **Phase 3**: Integrate with existing speech recognition flow
4. **Phase 4**: Add UI components for summary display

### Model Integration Process
1. **Research**: Evaluate available summarization models
2. **Conversion**: Convert selected model to Core ML format
3. **Integration**: Implement Core ML service wrapper
4. **Validation**: Test model performance on target devices
5. **Optimization**: Fine-tune for mobile performance

## Monitoring and Success Criteria

### Performance Metrics
- Model loading time: < 3 seconds on target devices
- Summarization processing time: < 5 seconds for typical text
- Memory usage increase: < 100MB during processing
- App size increase: < 50MB

### Quality Metrics
- Summary coherence: User testing validation
- Summary relevance: Alignment with original text intent
- Error rates: < 5% processing failures
- User satisfaction: > 4.0/5.0 rating for summary quality

### Technical Metrics
- Model initialization success rate: > 95%
- Memory leak detection: Zero leaks in continuous operation
- Crash rates: No increase in app crash rates
- Device compatibility: Support for iPhone 12+ (Core ML optimal performance)

## Future Considerations

### Model Evolution Strategy
1. **Continuous Evaluation**: Monitor advancements in mobile-optimized models
2. **A/B Testing Framework**: Allow switching between multiple models
3. **Incremental Updates**: Strategy for updating models without breaking changes
4. **Performance Benchmarking**: Automated testing across device generations

### Framework Migration Path
1. **FoundationModels Readiness**: Monitor when FoundationModels becomes production-ready
2. **Hybrid Approach**: Potential future implementation using FoundationModels on supported devices, Core ML as fallback
3. **Model Serving**: Consider future model serving strategies as iOS AI capabilities evolve

## References
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Machine Learning in iOS](https://developer.apple.com/machine-learning/)
- [Hugging Face Core ML Models](https://huggingface.co/models?library=coreml)
- [WWDC Core ML Sessions](https://developer.apple.com/videos/play/wwdc2023/10049/)

---
**Decision made by**: Development Team  
**Date**: December 2024  
**Review date**: March 2025