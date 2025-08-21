# SpeechSummaryApp - Guidelines para IA

## Princípios Fundamentais

- **KISS**: Mantenha simples, uma feature por vez
- **YAGNI**: Não implemente até precisar  
- **Privacy First**: Processamento on-device sempre que possível
- **iOS HIG**: Seguir rigorosamente Human Interface Guidelines

## Arquitetura

- **Pattern**: MVVM com Combine
- **UI**: SwiftUI puro com liquid glass effects
- **Threading**: async/await para operações assíncronas
- **DI**: Via inicializadores e environment objects
- **State**: @StateObject para ViewModels, @Published para dados reativos

## Estrutura de Código

### Organização
```
Core/
├── Services/     # SpeechService, SummarizationService
├── UseCases/     # SpeechRecognitionUseCase, SummarizationUseCase  
└── Data/         # Models, Repositories

Features/
├── SpeechRecognition/
│   ├── Views/
│   ├── ViewModels/
│   └── Models/
└── TextSummarization/
    ├── Views/
    ├── ViewModels/
    └── Models/
```

### Regras de Código
- **Máximo 200 linhas por arquivo**
- **Máximo 20 linhas por função**
- **Nomenclatura**: Swift API Design Guidelines
- **Documentation**: Sempre documentar APIs públicas
- **Error Handling**: Usar Result type ou async throws

## Testing Strategy

- **Unit Tests**: ViewModels e UseCases (80% coverage mínimo)
- **Integration Tests**: Services com mocks
- **UI Tests**: Apenas fluxos críticos principais
- **No UI Tests**: Conforme solicitado

## Dependências Aprovadas

### Frameworks Apple
- **SwiftUI**: Interface do usuário
- **Combine**: Reactive programming
- **Speech**: Reconhecimento de fala
- **FoundationModels**: Sumarização on-device
- **AVFoundation**: Controle de áudio

### Bibliotecas Externas
- **SwiftLint**: Linting de código
- **SwiftFormat**: Formatação automática

## Design System

### Cores
- **Primary**: Sistema blue do iOS
- **Secondary**: Sistema green para feedback positivo
- **Warning**: Sistema orange para estados intermediários
- **Error**: Sistema red para erros
- **Background**: Liquid glass effects com blur

### Componentes
- **Buttons**: SF Symbols com haptic feedback
- **Cards**: Rounded rectangles com shadow
- **Progress**: Circular progress para operations
- **Animations**: Spring animations para transições

## Comandos de Desenvolvimento

```bash
# Build do projeto
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Executar testes
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

# Linting
swiftlint --strict

# Formatação
swiftformat . --swiftversion 5.10
```

## Estrutura de Errors

```swift
enum AppError: LocalizedError {
    case speechUnavailable
    case microphonePermissionDenied
    case foundationModelsUnavailable
    case networkError(Error)
    
    var errorDescription: String? {
        // Implementar descrições user-friendly
    }
}
```

## Patterns Obrigatórios

### ViewModels
```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    @Published var state: FeatureState = .idle
    @Published var errorMessage: String?
    
    private let useCase: FeatureUseCaseProtocol
    
    init(useCase: FeatureUseCaseProtocol) {
        self.useCase = useCase
    }
}
```

### Services
```swift
protocol ServiceProtocol {
    func performAction() async throws -> Result
}

final class ServiceImplementation: ServiceProtocol {
    // Implementação concreta
}
```

### Use Cases
```swift
protocol UseCaseProtocol {
    func execute(input: Input) async throws -> Output
}
```

## Performance Guidelines

- **Lazy Loading**: Para componentes pesados
- **Image Optimization**: Usar SF Symbols quando possível
- **Memory Management**: Weak references em closures
- **Background Processing**: Para operações I/O

## Debugging

- **os_log**: Para logging estruturado
- **Print Statements**: Apenas durante desenvolvimento
- **Breakpoints**: Usar symbolic breakpoints para errors
- **Instruments**: Para análise de performance

## Accessibility

- **VoiceOver**: Todos os elementos interativos
- **Dynamic Type**: Suporte completo
- **High Contrast**: Testar em modo acessibilidade
- **Haptic Feedback**: Para feedback tátil

## Release Guidelines

- **Version Bump**: Semantic versioning
- **TestFlight**: Testes beta obrigatórios
- **App Store**: Seguir review guidelines
- **Privacy**: Declarar uso de microfone e IA
