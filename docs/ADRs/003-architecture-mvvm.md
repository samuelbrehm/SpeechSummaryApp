# ADR 003: Arquitetura MVVM com Combine

## Status
Aceito

## Data
2025-08-20

## Contexto
Definir arquitetura de software para o app demonstrativo, considerando maintainability, testability e alinhamento com melhores práticas iOS modernas.

## Opções Consideradas

### 1. MVVM + Combine
- Model-View-ViewModel com reactive programming
- SwiftUI nativo com @ObservableObject
- Combine para data flow
- Separation of concerns clara

### 2. MVI (Model-View-Intent)
- Unidirectional data flow
- State machines explícitos
- Redux-like pattern
- Complexity maior para app simples

### 3. VIPER
- View-Interactor-Presenter-Entity-Router
- Máxima separação de responsabilidades
- Overhead significativo para projeto demo
- Curva de aprendizado maior

### 4. Clean Architecture + SwiftUI
- Layers bem definidas
- Dependency Rule
- Testability máxima
- Complexity para projeto demonstrativo

## Decisão
**MVVM + Combine com Services + UseCases**

## Justificativa

### Alinhamento com Objetivos
- **Demonstração**: Mostra padrões iOS modernos
- **Simplicidade**: Equilibra structure vs complexity
- **SwiftUI**: Integração natural com framework
- **Learning**: Padrão acessível para diferentes níveis

### Vantagens Técnicas
- **Reactive**: Combine oferece reactive programming nativo
- **Testability**: ViewModels testáveis independentemente
- **SwiftUI Integration**: @ObservableObject nativo
- **Async/Await**: Compatível com concurrency moderna

### Manutenibilidade
- **Separation**: UI, business logic e data separados
- **Single Responsibility**: Cada camada com responsabilidade clara
- **Dependency Injection**: Testability e flexibility
- **Scalability**: Estrutura que cresce bem

## Consequências

### Estrutura de Camadas
```
┌─ Views (SwiftUI)              <- UI Layer
├─ ViewModels (@MainActor)      <- Presentation Layer  
├─ UseCases                     <- Business Layer
├─ Services                     <- Service Layer
└─ Models/Data                  <- Data Layer
```

### Responsabilidades

#### Views (SwiftUI)
- Renderização de UI
- User interaction handling
- Navigation
- Binding com ViewModels

#### ViewModels
- State management
- UI logic
- Coordinate com UseCases
- Error handling para UI

#### UseCases
- Business logic específica
- Orchestration de Services
- Domain rules
- Independent de UI

#### Services
- External APIs/Frameworks wrapper
- Data persistence
- Network communication
- System integration

#### Models/Data
- Data structures
- Domain entities
- Value objects
- Protocols/Interfaces

### Implementation Patterns

#### ViewModel Pattern
```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    // Published state
    @Published var state: FeatureState = .idle
    @Published var errorMessage: String?
    
    // Dependencies
    private let useCase: FeatureUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(useCase: FeatureUseCaseProtocol) {
        self.useCase = useCase
        setupBindings()
    }
    
    // Actions
    func performAction() {
        Task {
            state = .loading
            do {
                let result = try await useCase.execute()
                state = .success(result)
            } catch {
                state = .error(error)
            }
        }
    }
}
```

#### UseCase Pattern
```swift
protocol FeatureUseCaseProtocol {
    func execute(input: Input) async throws -> Output
}

final class FeatureUseCase: FeatureUseCaseProtocol {
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol) {
        self.service = service
    }
    
    func execute(input: Input) async throws -> Output {
        // Business logic here
        return try await service.performOperation(input)
    }
}
```

#### Service Pattern
```swift
protocol ServiceProtocol {
    func performOperation(_ input: Input) async throws -> Output
}

final class ServiceImplementation: ServiceProtocol {
    func performOperation(_ input: Input) async throws -> Output {
        // Framework/API integration
    }
}
```

### Dependency Injection

#### Constructor Injection
```swift
// Primary DI method
class ViewModel {
    init(useCase: UseCaseProtocol) { ... }
}

// In SwiftUI
.environmentObject(ViewModel(useCase: useCase))
```

#### Environment Objects
```swift
// For shared services
.environmentObject(serviceContainer)

// In views
@EnvironmentObject var container: ServiceContainer
```

### State Management

#### Feature States
```swift
enum FeatureState: Equatable {
    case idle
    case loading
    case success(Data)
    case error(AppError)
}
```

#### Combine Integration
```swift
@Published var transcribedText: String = ""

// Reactive chains
$transcribedText
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .removeDuplicates()
    .sink { [weak self] text in
        self?.processSummary(text)
    }
    .store(in: &cancellables)
```

### Testing Strategy

#### ViewModel Tests
```swift
class ViewModelTests: XCTestCase {
    var viewModel: ViewModel!
    var mockUseCase: MockUseCase!
    
    override func setUp() {
        mockUseCase = MockUseCase()
        viewModel = ViewModel(useCase: mockUseCase)
    }
    
    func testSuccessFlow() async {
        // Test business logic without UI
    }
}
```

#### UseCase Tests
```swift
class UseCaseTests: XCTestCase {
    var useCase: UseCase!
    var mockService: MockService!
    
    func testBusinessLogic() async throws {
        // Test pure business logic
    }
}
```

### Error Handling

#### Centralized Errors
```swift
enum AppError: LocalizedError {
    case speechUnavailable
    case permissionDenied
    case processingFailed(Error)
    
    var errorDescription: String? {
        // User-friendly messages
    }
}
```

#### Error Propagation
```swift
// Service -> UseCase -> ViewModel -> View
do {
    let result = try await useCase.execute()
    state = .success(result)
} catch let error as AppError {
    errorMessage = error.localizedDescription
    state = .error(error)
} catch {
    state = .error(.processingFailed(error))
}
```

## Implementation Guidelines

### Naming Conventions
- **ViewModels**: `FeatureViewModel`
- **UseCases**: `FeatureUseCase` 
- **Services**: `FeatureService`
- **Protocols**: `FeatureServiceProtocol`

### File Organization
```
Features/
├── FeatureName/
│   ├── Views/
│   │   ├── FeatureView.swift
│   │   └── Components/
│   ├── ViewModels/
│   │   └── FeatureViewModel.swift
│   └── Models/
│       └── FeatureModels.swift
```

### Threading Rules
- **@MainActor**: ViewModels sempre
- **Background**: Services e UseCases quando apropriado
- **UI Updates**: Sempre via MainActor.run quando necessário

## Revisão
Esta decisão deve ser revisada se:
- Complexity do projeto crescer significativamente
- Performance issues relacionadas a arquitetura
- Team feedback negativo sobre maintainability
- Emergir necessidade de features que não se adaptam bem ao padrão
