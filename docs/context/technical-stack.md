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
- **FoundationModels**: Sumarização on-device
- **AVFoundation**: Controle de sessão de áudio
- **CoreML**: Suporte adicional para ML (se necessário)

### Desenvolvimento
- **Swift 5.10+**: Linguagem principal
- **Xcode 16 beta**: IDE de desenvolvimento
- **SwiftLint**: Linting e code style
- **SwiftFormat**: Formatação automática

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
FoundationModels (Apple)
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
    let keyPoints: [String]
    let processedAt: Date
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

// Reactive chains
$transcribedText
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .sink { [weak self] text in
        self?.processForSummary(text)
    }
```

## Performance e Otimização

### Memory Management
- Weak references em closures
- Lazy initialization para componentes pesados
- Proper cleanup em deinit

### UI Performance
- @State para dados locais
- @StateObject para ViewModels
- @ObservedObject para objetos passados
- Evitar recomputação desnecessária

## Teste e Debug

### Testing Strategy
```
Unit Tests (80% coverage)
├── ViewModels
├── UseCases  
├── Services
└── Models

Integration Tests
├── Service + Framework
└── UseCase + Service

Manual Tests
├── Device permissions
├── Background behavior
└── Error scenarios
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
