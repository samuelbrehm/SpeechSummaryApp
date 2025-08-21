# Stack Técnico

## Visão Geral da Arquitetura

### Pattern Principal
**MVVM (Model-View-ViewModel)** com Combine para reactive programming

### Estrutura em Camadas
```
Presentation Layer (SwiftUI Views)
    ↓
Business Layer (ViewModels + UseCases)  
    ↓
Service Layer (Services + Protocols)
    ↓
Data Layer (Models + Repositories)
```

## Frameworks e Tecnologias

### iOS Frameworks
- **SwiftUI**: Interface do usuário moderna e declarativa
- **Combine**: Reactive programming e data binding
- **Speech**: Reconhecimento de fala nativo
- **CoreML**: Text summarization com modelos locais
- **AVFoundation**: Controle de sessão de áudio
- **Natural Language**: Text preprocessing e análise

### Desenvolvimento
- **Swift 5.10+**: Linguagem principal
- **Xcode 15+**: IDE de desenvolvimento (Core ML support)
- **SwiftLint**: Linting e code style
- **SwiftFormat**: Formatação automática
- **Core ML Tools**: Model conversion e otimização
- **Python 3.8+**: Environment para model conversion

## Arquitetura de Features

### SpeechRecognition Feature
```
SpeechRecognitionView (SwiftUI)
    ↓
SpeechRecognitionViewModel (@MainActor)
    ↓
SpeechRecognitionUseCase (Business Logic)
    ↓
SpeechService (Framework Wrapper)
    ↓
Speech Framework (Apple)
```

### TextSummarization Feature
```
SummarizationView (SwiftUI)
    ↓
SummarizationViewModel (@MainActor)
    ↓
SummarizationUseCase (Business Logic)
    ↓
SummarizationService (Framework Wrapper)
    ↓
CoreML Model (DistilBART/T5)
    ↓
Apple Neural Engine/CPU
```

## Padrões de Design

### Dependency Injection
```swift
// Via inicializadores
class ViewModel {
    init(useCase: UseCaseProtocol) { ... }
}

// Via Environment
.environmentObject(serviceContainer)
```

### Error Handling
```swift
enum AppError: LocalizedError {
    case speechUnavailable
    case permissionDenied
    case processingFailed(Error)
    case modelNotLoaded
    case textTooLong
    case summarizationFailed(Error)
    case insufficientMemory
}

// Result types para operações que podem falhar
func performOperation() async -> Result<Output, AppError>
```

### State Management
```swift
enum FeatureState {
    case idle
    case loading
    case success(Data)
    case error(AppError)
}

@Published var state: FeatureState = .idle
```

## Estrutura de Dados

### Core Models
```swift
struct TranscriptionResult {
    let text: String
    let confidence: Float
    let timestamp: Date
    let language: String
}

struct SummaryResult {
    let originalText: String
    let summary: String
    let processingTime: TimeInterval
    let confidence: Float?
    let processedAt: Date
}

struct SummarizationInput {
    let text: String
    let maxLength: SummaryLength
    let language: String?
}

enum SummaryLength: String, CaseIterable {
    case short = "short"
    case medium = "medium" 
    case long = "long"
    
    var tokenCount: Int {
        switch self {
        case .short: return 50
        case .medium: return 100
        case .long: return 200
        }
    }
}
```

### ViewModels
```swift
@MainActor
protocol ViewModelProtocol: ObservableObject {
    var state: FeatureState { get }
    var errorMessage: String? { get }
}
```

## Threading e Concorrência

### Main Actor
```swift
@MainActor
final class ViewModel: ObservableObject {
    // UI updates sempre na main thread
}
```

### Background Processing
```swift
Task {
    // Heavy processing em background
    let result = await service.process()
    
    await MainActor.run {
        // Update UI na main thread
        self.state = .success(result)
    }
}
```

## Reactive Programming

### Combine Publishers
```swift
// Service outputs
@Published var isRecording: Bool = false
@Published var transcribedText: String = ""
@Published var summaryResult: SummaryResult?
@Published var isModelLoaded: Bool = false
@Published var isSummarizing: Bool = false

// Reactive chains
$transcribedText
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .filter { !$0.isEmpty }
    .sink { [weak self] text in
        self?.processForSummary(text)
    }

// Model loading state
$isModelLoaded
    .combineLatest($transcribedText)
    .sink { [weak self] isLoaded, text in
        if isLoaded && !text.isEmpty {
            self?.enableSummarization()
        }
    }
```

## Performance e Otimização

### Memory Management
- Weak references em closures
- Lazy initialization para componentes pesados
- Proper cleanup em deinit
- Core ML model caching e unloading strategies
- Memory monitoring durante summarization
- Background memory cleanup para models não utilizados

### UI Performance
- @State para dados locais
- @StateObject para ViewModels
- @ObservedObject para objetos passados
- Evitar recomputação desnecessária

## Teste e Debug

### Testing Strategy
```
Unit Tests (90% coverage)
├── ViewModels
├── UseCases  
├── Services (including SummarizationService)
├── Models
└── Core ML Model Wrappers

Integration Tests
├── Service + Framework
├── UseCase + Service
├── Core ML Model Integration
└── Speech-to-Summary Pipeline

Performance Tests
├── Model loading benchmarks
├── Memory usage monitoring
├── Inference time measurements
└── Device compatibility validation

Manual Tests
├── Device permissions
├── Background behavior
├── Error scenarios
└── Model performance on various devices
```

### Debug Tools
- **os_log**: Logging estruturado
- **Instruments**: Profiling de performance
- **Console**: Debug em tempo real
- **Breakpoints**: Symbolic e exception

## Build e Deploy

### Build Configuration
```
Debug: 
- SwiftLint warnings
- Debug symbols
- Local testing

Release:
- SwiftLint errors fail build
- Optimized compilation
- Strip debug symbols
```

### CI/CD (Future)
```
GitHub Actions
├── Lint check
├── Unit tests
├── Build verification
└── TestFlight upload
```

## Segurança e Privacidade

### Privacy by Design
- Processamento completamente on-device
- Sem envio de dados para servidores
- Permissões explícitas e justificadas
- Transparência sobre uso de dados

### Data Protection
- Sem persistência de áudio
- Texto transcrito apenas em memória
- Cleanup automático ao sair do app
- Conformidade com App Tracking Transparency
