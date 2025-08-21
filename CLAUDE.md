# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# SpeechSummaryApp - AI Development Guidelines

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

### Target Code Organization (To Be Implemented)
```
SpeechSummaryApp/SpeechSummaryApp/
├── Core/
│   ├── Services/     # SpeechService, SummarizationService
│   ├── UseCases/     # SpeechRecognitionUseCase, SummarizationUseCase  
│   └── Data/         # Models, Repositories, Protocols
├── Features/
│   ├── SpeechRecognition/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── TextSummarization/
│       ├── Views/
│       ├── ViewModels/
│       └── Models/
├── Shared/
│   ├── Extensions/
│   ├── Components/   # Reusable SwiftUI components
│   └── Utils/
└── Resources/
    └── Assets.xcassets/

**NOTE**: Currently the project only contains basic SwiftUI template files.
```

### Implementation Priority
1. **Core Services Layer** - SpeechService, SummarizationService
2. **Domain Models** - TranscriptionResult, SummaryResult, AppError
3. **Use Cases** - Business logic isolation
4. **ViewModels** - @MainActor presentation logic
5. **SwiftUI Views** - Modern UI with liquid glass effects

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

## Development Commands

### Building and Testing
```bash
# Open project in Xcode (primary development method)
open SpeechSummaryApp/SpeechSummaryApp.xcodeproj

# Build from command line (if needed)
cd SpeechSummaryApp && xcodebuild -scheme SpeechSummaryApp build

# Run tests (unit tests only - no UI tests as per project requirements)
cd SpeechSummaryApp && xcodebuild -scheme SpeechSummaryApp test -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test target
cd SpeechSummaryApp && xcodebuild -scheme SpeechSummaryApp test -only-testing:SpeechSummaryAppTests

# Code quality
swiftlint --config SpeechSummaryApp/.swiftlint.yml
swiftformat SpeechSummaryApp/ --swiftversion 5.10
```

### Device Requirements
**CRITICAL**: This project requires:
- Physical iOS device (iOS 18.0+)
- Apple Intelligence enabled
- Microphone permissions
- Speech Framework and FoundationModels NOT available in iOS Simulator

### Working Directory Structure
```
SpeechSummaryApp/               # Main Xcode project folder
├── SpeechSummaryApp.xcodeproj/ # Xcode project file
└── SpeechSummaryApp/           # Source code
    ├── SpeechSummaryAppApp.swift
    ├── ContentView.swift
    ├── Info.plist
    └── Assets.xcassets/

docs/                           # Comprehensive documentation
├── ADRs/                      # Architecture Decision Records
├── context/                   # Technical context
├── plans/                     # Development plans
└── libs/                      # Framework documentation

PRPs/                          # Product Requirements Prompts
state.local.md                 # Current development state
```

## Project Context

### Current Status
This is an **early-stage demonstrative project** showcasing AI workflows in iOS development. The project structure is established, but core features are not yet implemented.

**Key Files to Reference**:
- `state.local.md` - Current development status and next steps
- `docs/ADRs/003-architecture-mvvm.md` - Detailed architecture decisions
- `docs/context/technical-stack.md` - Complete technical overview
- `docs/plans/action-plan-global.md` - Development roadmap

### Development Philosophy
- **PRPs (Product Requirements Prompts)**: This project demonstrates PRP-driven development
- **Context Engineering**: Extensive documentation for AI-assisted development
- **Privacy First**: All processing happens on-device using Apple's frameworks
- **Demo Purpose**: Focus on clarity and educational value over production complexity

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

## Code Quality Configuration

### SwiftLint Setup
- Configuration file: `SpeechSummaryApp/.swiftlint.yml`
- Disabled rules: `trailing_whitespace`, `line_length`
- Build script integration: SwiftFormat runs automatically on build

### Build Integration
- **SwiftFormat**: Configured as Xcode build script (line 264 in project.pbxproj)
- **Auto-formatting**: Runs on every build to maintain consistency
- **Swift Version**: 5.10+ with modern concurrency features

## Key Framework Dependencies

### Apple Frameworks (No External Dependencies)
- **Speech**: iOS speech recognition (requires device)
- **FoundationModels**: On-device AI summarization (iOS 18.0+, requires Apple Intelligence)
- **SwiftUI**: Modern declarative UI
- **Combine**: Reactive programming and data binding
- **AVFoundation**: Audio session management

### Development Tools
- **Xcode 16 beta**: Required for FoundationModels support
- **SwiftLint**: Code style enforcement
- **SwiftFormat**: Automatic code formatting

## Release Guidelines

- **Version Bump**: Semantic versioning
- **TestFlight**: Beta testing required
- **App Store**: Follow review guidelines
- **Privacy**: Microphone and AI usage declarations
- **Device Support**: iPhone/iPad with Apple Intelligence support

## Documentation Navigation

This project has extensive documentation for AI-assisted development:

### Essential Reading
1. **`state.local.md`** - Always check current development state first
2. **`docs/ADRs/003-architecture-mvvm.md`** - Comprehensive architecture guide with code examples
3. **`docs/context/technical-stack.md`** - Complete technical overview and patterns
4. **`docs/plans/action-plan-global.md`** - Development phases and priorities

### When Starting New Features
1. Check if there's a PRP in `PRPs/` folder for the feature
2. Review related ADRs in `docs/ADRs/`
3. Follow the MVVM pattern established in architecture documentation
4. Update `state.local.md` when completing tasks

### Development Workflow
- **Planning**: Use PRPs and action plans in `docs/plans/`
- **Architecture**: Refer to ADRs for architectural decisions
- **Implementation**: Follow patterns in `docs/context/technical-stack.md`
- **Testing**: Unit tests for ViewModels and UseCases only (no UI tests)

## Important Constraints

- **No Simulator Support**: Speech and FoundationModels require physical device
- **iOS 18.0+ Required**: FoundationModels dependency
- **Apple Intelligence Required**: Must be enabled on device
- **On-Device Only**: No network calls, complete privacy by design
- **Demo Focus**: Prioritize clarity and educational value over production complexity
