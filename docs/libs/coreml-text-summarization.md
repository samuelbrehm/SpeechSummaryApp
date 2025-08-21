# Core ML Text Summarization Implementation Guide

## Overview

This documentation provides comprehensive guidance for implementing text summarization using Core ML in iOS applications. It covers model selection, conversion, integration, and optimization strategies for on-device text summarization.

## Core ML Framework Fundamentals

### What is Core ML?

Core ML is Apple's machine learning framework that enables on-device ML inference across iOS, macOS, watchOS, and tvOS. It provides:

- **High Performance**: Optimized for Apple hardware including Neural Engine
- **Privacy**: All processing happens on-device 
- **Battery Efficiency**: Hardware-accelerated inference
- **Easy Integration**: Native Swift/Objective-C APIs

### Core ML Architecture

```
┌─────────────────────────────────────────┐
│              Your App                   │
├─────────────────────────────────────────┤
│           Core ML Framework             │
├─────────────────────────────────────────┤
│    Core ML Models (.mlmodel files)     │
├─────────────────────────────────────────┤
│         Hardware Acceleration          │
│   • CPU • GPU • Neural Engine          │
└─────────────────────────────────────────┘
```

## Text Summarization Models

### Recommended Models for Mobile

#### 1. DistilBART-CNN-12-6
- **Size**: ~40MB
- **Architecture**: Encoder-decoder transformer
- **Strengths**: Good balance of quality and speed
- **Use Case**: News articles, general text summarization
- **Conversion**: Available pre-converted from Hugging Face

#### 2. T5-Small
- **Size**: ~25MB  
- **Architecture**: Text-to-text transformer
- **Strengths**: Versatile, faster inference
- **Use Case**: General text summarization, multiple tasks
- **Conversion**: Well-documented conversion process

#### 3. PEGASUS-XSum
- **Size**: ~45MB
- **Architecture**: Encoder-decoder with gap sentences
- **Strengths**: Abstractive summarization quality
- **Use Case**: Long document summarization
- **Conversion**: May require custom conversion scripts

### Model Selection Criteria

```swift
struct ModelEvaluationCriteria {
    let maxSizeBytes: Int = 50_000_000  // 50MB limit
    let maxInferenceTimeSeconds: Double = 5.0
    let minimumQualityScore: Double = 0.7
    let supportedIOSVersion: String = "15.0+"
    let requiredHardware: HardwareRequirement = .a12OrLater
}

enum HardwareRequirement {
    case any
    case a12OrLater  // For Neural Engine optimization
    case a14OrLater  // For advanced features
}
```

## Model Conversion Process

### Prerequisites

```bash
# Install Core ML Tools
pip install coremltools
pip install transformers torch

# For specific models
pip install sentencepiece  # For T5
pip install tokenizers     # For modern transformers
```

### Basic Conversion Script

```python
import coremltools as ct
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
import torch

def convert_summarization_model_to_coreml(
    model_name: str,
    output_path: str,
    max_length: int = 512
):
    """
    Convert a Hugging Face summarization model to Core ML format
    """
    
    # Load model and tokenizer
    model = AutoModelForSeq2SeqLM.from_pretrained(model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    
    # Set model to evaluation mode
    model.eval()
    
    # Create example input
    example_text = "This is a sample text for model conversion testing."
    inputs = tokenizer(
        example_text, 
        return_tensors="pt", 
        max_length=max_length,
        truncation=True,
        padding=True
    )
    
    # Trace the model
    with torch.no_grad():
        traced_model = torch.jit.trace(
            model, 
            (inputs.input_ids, inputs.attention_mask)
        )
    
    # Convert to Core ML
    coreml_model = ct.convert(
        traced_model,
        inputs=[
            ct.TensorType(
                name="input_ids",
                shape=inputs.input_ids.shape,
                dtype=torch.int32
            ),
            ct.TensorType(
                name="attention_mask", 
                shape=inputs.attention_mask.shape,
                dtype=torch.int32
            )
        ],
        outputs=[
            ct.TensorType(name="logits", dtype=torch.float32)
        ],
        compute_units=ct.ComputeUnit.ALL  # Use Neural Engine when available
    )
    
    # Add metadata
    coreml_model.short_description = f"Text summarization model based on {model_name}"
    coreml_model.author = "Your App Name"
    coreml_model.license = "Model-specific license"
    coreml_model.version = "1.0.0"
    
    # Save the model
    coreml_model.save(output_path)
    print(f"Model converted and saved to: {output_path}")

# Example usage
convert_summarization_model_to_coreml(
    model_name="distilbart-cnn-12-6",
    output_path="./DistilBARTSummarization.mlmodel",
    max_length=512
)
```

### Advanced Conversion with Optimization

```python
def convert_optimized_model(model_name: str, output_path: str):
    """
    Convert model with optimizations for mobile deployment
    """
    
    # Model conversion with quantization
    coreml_model = ct.convert(
        traced_model,
        inputs=input_specs,
        compute_units=ct.ComputeUnit.CPU_AND_NEURAL_ENGINE,
        
        # Optimization options
        convert_to="mlprogram",  # Use ML Program format
        minimum_deployment_target=ct.target.iOS15,
        
        # Quantization for smaller size
        pass_pipeline=ct.PassPipeline.DEFAULT_PALETTIZATION,
    )
    
    # Validate model performance
    performance_report = coreml_model.generate_performance_report()
    print("Performance Report:", performance_report)
    
    return coreml_model
```

## iOS Integration

### Service Layer Implementation

```swift
import CoreML
import NaturalLanguage

protocol SummarizationServiceProtocol {
    func initialize() async throws
    func summarize(text: String, maxLength: SummaryLength) async throws -> SummaryResult
    var isModelLoaded: Bool { get }
    var modelInfo: ModelInfo { get }
}

final class CoreMLSummarizationService: SummarizationServiceProtocol {
    
    // MARK: - Properties
    
    private var model: MLModel?
    private let modelConfiguration: MLModelConfiguration
    private let textPreprocessor: TextPreprocessor
    
    @Published private(set) var isModelLoaded: Bool = false
    
    // MARK: - Initialization
    
    init(modelName: String = "DistilBARTSummarization") {
        // Configure for optimal performance
        self.modelConfiguration = MLModelConfiguration()
        self.modelConfiguration.computeUnits = .cpuAndNeuralEngine
        self.modelConfiguration.allowLowPrecisionAccumulationOnGPU = true
        
        self.textPreprocessor = TextPreprocessor()
    }
    
    // MARK: - Public Methods
    
    func initialize() async throws {
        guard !isModelLoaded else { return }
        
        do {
            // Load model from app bundle
            guard let modelURL = Bundle.main.url(
                forResource: "DistilBARTSummarization", 
                withExtension: "mlmodelc"
            ) else {
                throw SummarizationError.modelNotFound
            }
            
            // Initialize model with configuration
            self.model = try MLModel(
                contentsOf: modelURL, 
                configuration: modelConfiguration
            )
            
            await MainActor.run {
                self.isModelLoaded = true
            }
            
            logModelInfo()
            
        } catch {
            throw SummarizationError.modelLoadingFailed(error)
        }
    }
    
    func summarize(
        text: String, 
        maxLength: SummaryLength
    ) async throws -> SummaryResult {
        
        guard isModelLoaded, let model = model else {
            throw SummarizationError.modelNotLoaded
        }
        
        let startTime = Date()
        
        do {
            // Preprocess input text
            let preprocessedInput = try textPreprocessor.preprocess(
                text: text,
                maxTokens: 512
            )
            
            // Create model input
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "input_ids": MLMultiArray(preprocessedInput.inputIds),
                "attention_mask": MLMultiArray(preprocessedInput.attentionMask)
            ])
            
            // Run inference
            let output = try model.prediction(from: input)
            
            // Post-process output
            let summary = try textPreprocessor.postprocess(
                output: output,
                maxLength: maxLength.tokenCount
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return SummaryResult(
                originalText: text,
                summary: summary.text,
                processingTime: processingTime,
                confidence: summary.confidence,
                processedAt: Date()
            )
            
        } catch {
            throw SummarizationError.processingFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func logModelInfo() {
        guard let model = model else { return }
        
        os_log(
            "Summarization model loaded successfully. Input: %{public}@, Output: %{public}@",
            log: .summarization,
            type: .info,
            model.modelDescription.inputDescriptionsByName.description,
            model.modelDescription.outputDescriptionsByName.description
        )
    }
}
```

### Text Preprocessing

```swift
import NaturalLanguage

final class TextPreprocessor {
    
    private let tokenizer: NLTokenizer
    private let maxTokens: Int
    
    init(maxTokens: Int = 512) {
        self.maxTokens = maxTokens
        self.tokenizer = NLTokenizer(unit: .word)
    }
    
    struct PreprocessedInput {
        let inputIds: [Int32]
        let attentionMask: [Int32]
        let tokenCount: Int
    }
    
    func preprocess(text: String, maxTokens: Int) throws -> PreprocessedInput {
        // Clean and normalize text
        let cleanedText = cleanText(text)
        
        // Tokenize using Natural Language framework
        tokenizer.string = cleanedText
        let tokens = tokenizer.tokens(for: cleanedText.startIndex..<cleanedText.endIndex)
        
        // Convert to model-specific format
        let tokenIds = try convertToTokenIds(tokens: tokens)
        let truncatedIds = truncateTokens(tokenIds, maxLength: maxTokens)
        
        // Create attention mask
        let attentionMask = Array(repeating: Int32(1), count: truncatedIds.count)
        
        return PreprocessedInput(
            inputIds: truncatedIds,
            attentionMask: attentionMask,
            tokenCount: truncatedIds.count
        )
    }
    
    struct PostprocessedOutput {
        let text: String
        let confidence: Float?
    }
    
    func postprocess(
        output: MLFeatureProvider, 
        maxLength: Int
    ) throws -> PostprocessedOutput {
        
        // Extract logits from model output
        guard let logits = output.featureValue(for: "logits")?.multiArrayValue else {
            throw SummarizationError.invalidOutput
        }
        
        // Convert logits to tokens
        let tokens = try convertLogitsToTokens(logits: logits)
        
        // Decode tokens to text
        let summaryText = try decodeTokensToText(tokens: tokens)
        
        // Calculate confidence score
        let confidence = calculateConfidence(logits: logits)
        
        return PostprocessedOutput(
            text: summaryText,
            confidence: confidence
        )
    }
    
    // MARK: - Private Methods
    
    private func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
    
    private func convertToTokenIds(tokens: [String]) throws -> [Int32] {
        // Implementation depends on specific tokenizer
        // This is a simplified version
        return tokens.compactMap { token in
            // Convert token to ID using your tokenizer's vocabulary
            Int32(token.hashValue % 30000) // Simplified example
        }
    }
    
    private func truncateTokens(_ tokens: [Int32], maxLength: Int) -> [Int32] {
        return Array(tokens.prefix(maxLength))
    }
    
    private func convertLogitsToTokens(logits: MLMultiArray) throws -> [Int32] {
        // Convert logits to token IDs using argmax or sampling
        var tokens: [Int32] = []
        
        // Simplified implementation
        let logitsPointer = logits.dataPointer.bindMemory(to: Float32.self, capacity: logits.count)
        
        // Process logits to get token IDs
        // Implementation depends on model architecture
        
        return tokens
    }
    
    private func decodeTokensToText(tokens: [Int32]) throws -> String {
        // Convert token IDs back to text
        // Implementation depends on tokenizer vocabulary
        return tokens.map { "token_\($0)" }.joined(separator: " ")
    }
    
    private func calculateConfidence(logits: MLMultiArray) -> Float? {
        // Calculate confidence score from logits
        // Could be max probability, entropy-based score, etc.
        return nil
    }
}
```

## Error Handling

```swift
enum SummarizationError: LocalizedError {
    case modelNotFound
    case modelLoadingFailed(Error)
    case modelNotLoaded
    case textTooLong
    case textTooShort
    case processingFailed(Error)
    case invalidOutput
    case insufficientMemory
    
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
        }
    }
}
```

## Performance Optimization

### Memory Management

```swift
extension CoreMLSummarizationService {
    
    func optimizeMemoryUsage() {
        // Implement memory optimization strategies
        
        // 1. Model unloading when not in use
        Task {
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            if !hasRecentActivity() {
                unloadModel()
            }
        }
        
        // 2. Input batching for multiple requests
        func processBatch(_ texts: [String]) async throws -> [SummaryResult] {
            // Implementation for batch processing
            return []
        }
        
        // 3. Memory monitoring
        func checkMemoryPressure() -> MemoryPressure {
            let info = mach_task_basic_info()
            // Check memory usage and return pressure level
            return .normal
        }
    }
    
    private func hasRecentActivity() -> Bool {
        // Track recent usage
        return false
    }
    
    private func unloadModel() {
        model = nil
        isModelLoaded = false
        os_log("Model unloaded due to inactivity", log: .summarization, type: .info)
    }
}

enum MemoryPressure {
    case normal
    case warning
    case critical
}
```

### Performance Monitoring

```swift
final class PerformanceMonitor {
    
    struct Metrics {
        let modelLoadTime: TimeInterval
        let inferenceTime: TimeInterval
        let memoryUsage: Int64
        let deviceModel: String
        let iosVersion: String
    }
    
    static func measurePerformance<T>(
        operation: () async throws -> T
    ) async throws -> (result: T, metrics: Metrics) {
        
        let startTime = Date()
        let initialMemory = getCurrentMemoryUsage()
        
        let result = try await operation()
        
        let endTime = Date()
        let finalMemory = getCurrentMemoryUsage()
        
        let metrics = Metrics(
            modelLoadTime: 0, // Set appropriately
            inferenceTime: endTime.timeIntervalSince(startTime),
            memoryUsage: finalMemory - initialMemory,
            deviceModel: UIDevice.current.model,
            iosVersion: UIDevice.current.systemVersion
        )
        
        logMetrics(metrics)
        
        return (result, metrics)
    }
    
    private static func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private static func logMetrics(_ metrics: Metrics) {
        os_log(
            "Performance - Inference: %{public}.3fs, Memory: %{public}lld bytes, Device: %{public}@",
            log: .performance,
            type: .info,
            metrics.inferenceTime,
            metrics.memoryUsage,
            metrics.deviceModel
        )
    }
}
```

## Testing Strategies

### Unit Testing

```swift
import XCTest
@testable import SpeechSummaryApp

final class SummarizationServiceTests: XCTestCase {
    
    var service: CoreMLSummarizationService!
    
    override func setUpWithError() throws {
        service = CoreMLSummarizationService()
    }
    
    override func tearDownWithError() throws {
        service = nil
    }
    
    func testModelInitialization() async throws {
        XCTAssertFalse(service.isModelLoaded)
        
        try await service.initialize()
        
        XCTAssertTrue(service.isModelLoaded)
    }
    
    func testSummarizationWithValidInput() async throws {
        try await service.initialize()
        
        let sampleText = """
        This is a sample text that is long enough to be summarized effectively.
        It contains multiple sentences and provides sufficient context for 
        the summarization model to generate meaningful output.
        """
        
        let result = try await service.summarize(
            text: sampleText, 
            maxLength: .medium
        )
        
        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertEqual(result.originalText, sampleText)
        XCTAssertGreaterThan(result.processingTime, 0)
    }
    
    func testErrorHandlingForInvalidInput() async throws {
        try await service.initialize()
        
        do {
            _ = try await service.summarize(text: "", maxLength: .short)
            XCTFail("Should throw error for empty input")
        } catch SummarizationError.textTooShort {
            // Expected error
        }
    }
}
```

### Performance Testing

```swift
final class SummarizationPerformanceTests: XCTestCase {
    
    func testModelLoadingPerformance() throws {
        measure {
            let service = CoreMLSummarizationService()
            let expectation = XCTestExpectation(description: "Model loading")
            
            Task {
                try await service.initialize()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testInferencePerformance() throws {
        let service = CoreMLSummarizationService()
        
        // Setup
        let setupExpectation = XCTestExpectation(description: "Setup")
        Task {
            try await service.initialize()
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 5.0)
        
        // Performance test
        measure {
            let expectation = XCTestExpectation(description: "Inference")
            
            Task {
                _ = try await service.summarize(
                    text: generateSampleText(),
                    maxLength: .medium
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    private func generateSampleText() -> String {
        return String(repeating: "This is a sample sentence. ", count: 50)
    }
}
```

## Best Practices

### Model Management
1. **Lazy Loading**: Load models only when needed
2. **Memory Monitoring**: Implement memory pressure handling
3. **Model Validation**: Verify model integrity after loading
4. **Fallback Strategies**: Provide graceful degradation options

### Performance Optimization
1. **Batch Processing**: Process multiple texts efficiently
2. **Background Processing**: Use background queues for heavy operations
3. **Caching**: Cache results for repeated inputs
4. **Hardware Utilization**: Leverage Neural Engine when available

### User Experience
1. **Progress Feedback**: Show processing progress to users
2. **Error Recovery**: Provide clear error messages and recovery options
3. **Offline Support**: Ensure functionality without network connectivity
4. **Accessibility**: Support all iOS accessibility features

## Troubleshooting

### Common Issues

1. **Model Loading Failures**
   - Verify model file is in app bundle
   - Check device compatibility
   - Monitor memory availability

2. **Performance Issues**
   - Profile with Instruments
   - Check Neural Engine utilization
   - Monitor memory usage patterns

3. **Quality Issues**
   - Validate input preprocessing
   - Check model conversion accuracy
   - Consider alternative models

### Debug Configuration

```swift
#if DEBUG
extension OSLog {
    static let summarization = OSLog(subsystem: "com.app.summarization", category: "summarization")
    static let performance = OSLog(subsystem: "com.app.summarization", category: "performance")
    static let memory = OSLog(subsystem: "com.app.summarization", category: "memory")
}
#endif
```

This comprehensive guide provides the foundation for implementing Core ML-based text summarization in iOS applications while maintaining high performance and user experience standards.