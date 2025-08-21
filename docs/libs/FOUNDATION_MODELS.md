# FoundationModels Framework - Documentação de Referência

## Overview
O FoundationModels framework 26+) expõe os modelos de linguagem on-device que alimentam a Apple Intelligence, fornecendo capacidades avançadas de compreensão e geração de linguagem.

## Core Components

### SystemLanguageModel
Ponto de acesso principal aos LLMs built-in da Apple.

```swift
import FoundationModels

// Modelo base para tarefas gerais
let generalModel = SystemLanguageModel.default

// Modelo especializado para content tagging
let taggingModel = SystemLanguageModel(useCase: .contentTagging)

// Verificar disponibilidade
switch generalModel.availability {
case .available:
    // Modelo pronto para uso
    break
case .unavailable(let reason):
    // Handle: device not eligible, Apple Intelligence off, etc.
    break
}
```

### LanguageModelSession
Context único para interagir com o modelo, mantendo histórico da conversa.

```swift
// Session básica
let session = LanguageModelSession()

// Session customizada
let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: .default,
    tools: [myTool1, myTool2],
    instructions: {
        "Você é um assistente especializado em sumarização de texto."
    }
)
```

## Structured Output com @Generable

### Definindo Structs
```swift
@Generable
struct SummaryResult: Equatable {
    let summary: String
    let keyPoints: [String]
    let category: String
}

// Com constraints usando @Guide
@Generable
struct DetailedSummary {
    @Guide(description: "Resumo conciso em 2-3 frases")
    let summary: String
    
    @Guide(description: "Lista de pontos principais", .count(3...5))
    let keyPoints: [String]
    
    @Guide(.anyOf(["conversa", "apresentação", "notas", "reunião", "outro"]))
    let category: String
}
```

### Response Methods
```swift
// Response simples
let result = try await session.respond(to: "Summarize this text...")
print(result.content) // String response

// Structured response
let summaryResult = try await session.respond(
    to: "Analyze this text: \(inputText)",
    generating: SummaryResult.self,
    options: GenerationOptions(temperature: 0.3)
)
let summary: SummaryResult = summaryResult.content
```

## Streaming Responses

### Basic Streaming
```swift
let stream = try await session.streamResponse(
    generating: SummaryResult.self,
    options: GenerationOptions(),
    includeSchemaInPrompt: false
) {
    "Please generate a summary of this text: \(inputText)"
}

for try await partial in stream {
    // `partial` é SummaryResult.PartiallyGenerated
    // Fields são gradually populated
    updateUI(with: partial)
}
```

### Partially Generated Types
```swift
// Para SummaryResult, o compilador gera automaticamente:
// SummaryResult.PartiallyGenerated onde todos fields são Optional

if let summary = partial.summary {
    // Summary field está disponível
    displaySummary(summary)
}

if let points = partial.keyPoints, !points.isEmpty {
    // Key points estão sendo populated
    displayKeyPoints(points)
}
```

## Generation Options

### Sampling e Temperature
```swift
let options = GenerationOptions(
    sampling: .greedy,              // Deterministic output
    temperature: 0.8,               // Creativity level (0.0-2.0)
    maximumResponseTokens: 200      // Limit response length
)

// Random sampling with top-p
let creativityOptions = GenerationOptions(
    sampling: .random(probabilityThreshold: 0.9, seed: 42),
    temperature: 1.2
)
```

## Tools Integration

### Definindo Tools
```swift
final class WeatherTool: Tool {
    let name = "getWeather"
    let description = "Gets current weather for a location"
    
    @Generable
    struct Arguments {
        @Guide(description: "City name to get weather for")
        let city: String
        
        @Guide(.anyOf(["celsius", "fahrenheit"]))
        let unit: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Implement weather lookup
        let weather = getWeatherData(for: arguments.city, unit: arguments.unit)
        return ToolOutput(weather)
    }
}

// Use with session
let tools: [any Tool] = [WeatherTool()]
let session = LanguageModelSession(tools: tools)
```

## Error Handling

### Common Errors
```swift
enum FoundationModelsError: LocalizedError {
    case modelUnavailable
    case deviceNotSupported
    case processingFailed(Error)
    case streamingInterrupted
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence não está disponível"
        case .deviceNotSupported:
            return "Requer iOS 26+ com Apple Intelligence"
        case .processingFailed(let error):
            return "Erro de processamento: \(error.localizedDescription)"
        case .streamingInterrupted:
            return "Stream foi interrompido"
        }
    }
}
```

### Error Recovery
```swift
do {
    let result = try await session.respond(to: prompt, generating: MyStruct.self)
    return result.content
} catch {
    if case .unavailable(let reason) = SystemLanguageModel.default.availability {
        // Handle model unavailable
        throw FoundationModelsError.modelUnavailable
    } else {
        // Handle other errors
        throw FoundationModelsError.processingFailed(error)
    }
}
```

## Best Practices

### Session Management
```swift
// Prewarm para melhor performance
await session.prewarm(promptPrefix: "You are a helpful assistant")

// Check if session is responding
guard !session.isResponding else {
    // Don't start new request while processing
    return
}

// Monitor session state
if session.isResponding {
    // Show loading indicator
}
```

### Memory Management
```swift
// Cleanup session quando não precisar mais
// Sessions mantêm transcript history
let newSession = LanguageModelSession() // Fresh context

// Ou restore de transcript anterior
let restoredSession = LanguageModelSession(transcript: savedTranscript)
```

### Performance Optimization
```swift
// Use temperature baixa para output consistente
let options = GenerationOptions(temperature: 0.1)

// Limit token count para response rápida
let fastOptions = GenerationOptions(maximumResponseTokens: 100)

// Use includeSchemaInPrompt: false se você incluir schema manualmente
let result = try await session.respond(
    to: manualPromptWithSchema,
    generating: MyStruct.self,
    includeSchemaInPrompt: false
)
```

## Limitations e Considerações

### Device Requirements
- **iOS 26+**: Framework availability
- **Apple Intelligence**: Must be enabled
- **Neural Engine**: Melhor performance
- **Physical Device**: Não funciona no Simulator

### Model Capabilities
- **Languages**: Primarily English, some Portuguese support
- **Context Window**: Limited compared to cloud models
- **Specialization**: General purpose, com adapters específicos
- **Output Quality**: Dependente do prompt quality

### Privacy e Security
- **On-device only**: Dados nunca saem do dispositivo
- **No internet required**: Funciona offline
- **No logging**: Apple não tem acesso aos prompts
- **Guardrails**: Built-in content safety

## Troubleshooting

### Common Issues
```swift
// Check model availability
let model = SystemLanguageModel.default
print("Model availability: \(model.availability)")

// Verify Apple Intelligence is enabled
// Settings > Apple Intelligence & Siri

// Check device compatibility
// Requires A17 Pro or M1+ chips

// Monitor memory usage during processing
// Large prompts can cause memory pressure
```

### Debug Tips
```swift
// Add verbose logging
let session = LanguageModelSession(
    instructions: {
        """
        Debug mode: Explain your reasoning step by step.
        Original request: \(userPrompt)
        """
    }
)

// Test with simple prompts first
let testResult = try await session.respond(to: "Say hello")
print("Test response: \(testResult.content)")

// Monitor transcript
print("Session transcript: \(session.transcript)")
```