# Prompts de Desenvolvimento - SpeechSummaryApp

## Prompts para Geração de Código

### 1. Implementação de Service Layer

```
Você é um especialista em desenvolvimento iOS. Implemente um Service para [FEATURE_NAME] seguindo estas especificações:

ARQUITETURA:
- Pattern: MVVM + Combine + SwiftUI
- DI: Via inicializadores
- Error Handling: Result types e async throws
- Threading: @MainActor para UI, background para processing

CONTEXTO DO PROJETO:
- App demonstrativo de workflows de IA
- Usa Speech Framework e FoundationModels
- Arquitetura clean com separation of concerns

ESPECIFICAÇÕES TÉCNICAS:
- Protocol-oriented design
- Combine publishers para reactive updates
- Async/await para operations
- Comprehensive error handling

GUIDELINES:
- Máximo 200 linhas por arquivo
- Documentação para APIs públicas
- SwiftLint compliant
- Performance-optimized

DELIVERABLES:
1. ServiceProtocol interface
2. Concrete implementation
3. Error types específicos
4. Unit test examples

Consulte CLAUDE.md para guidelines detalhados e state.local.md para contexto atual.
```

### 2. Implementação de ViewModel

```
Implemente um ViewModel para [FEATURE_NAME] seguindo a arquitetura MVVM estabelecida:

REQUIREMENTS:
- @MainActor para thread safety
- @Published properties para UI binding
- State machine pattern
- Dependency injection via initializer
- Comprehensive error handling

CONTEXT:
- Integration com [SERVICE_NAME]
- Reactive updates via Combine
- Error states com user-friendly messages
- Loading states com progress tracking

PATTERNS:
```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    @Published var state: FeatureState = .idle
    @Published var errorMessage: String?
    
    private let useCase: FeatureUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
}
```

DELIVERABLES:
1. ViewModel implementation
2. State enum definition
3. Combine subscriptions setup
4. Error handling
5. Unit test examples

Siga guidelines em CLAUDE.md e implemente seguindo patterns estabelecidos.
```

### 3. Implementação de SwiftUI View

```
Crie uma SwiftUI View moderna para [FEATURE_NAME] com design liquid glass:

DESIGN REQUIREMENTS:
- Liquid glass effects com blur
- Vibrant colors seguindo iOS trends
- Smooth animations e transitions
- Accessibility completo (VoiceOver, Dynamic Type)
- Dark/Light mode support

UI COMPONENTS:
- [SPECIFIC_COMPONENTS_LIST]
- Progress indicators
- Error state UI
- Loading states

TECHNICAL:
- Binding com ViewModel
- Navigation integrada
- Performance optimized
- SwiftUI best practices

ACCESSIBILITY:
- VoiceOver labels apropriados
- Dynamic Type scaling
- High contrast support
- Voice Control compatibility

EXAMPLE STRUCTURE:
```swift
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel
    
    var body: some View {
        // Implementation
    }
}
```

Implemente seguindo design system e guidelines em CLAUDE.md.
```

## Prompts para Debug e Otimização

### 4. Debug de Performance

```
Analise e otimize a performance desta implementação iOS:

ÁREAS DE ANÁLISE:
- Memory usage e leaks
- CPU utilization
- UI responsiveness
- Battery impact
- Network efficiency (se aplicável)

FERRAMENTAS:
- Instruments profiling
- Memory graph debugger
- SwiftUI preview performance
- Console logging analysis

OTIMIZAÇÕES ESPERADAS:
- Lazy loading onde apropriado
- Proper memory management
- Background processing
- Efficient state updates

Forneça:
1. Identificação de bottlenecks
2. Soluções específicas
3. Code improvements
4. Metrics de melhoria

Considere guidelines de performance em CLAUDE.md.
```

### 5. Error Handling Review

```
Revise e melhore o error handling desta feature:

ÁREAS DE REVIEW:
- Error types adequados
- User-friendly messages
- Recovery strategies
- Logging apropriado

PATTERNS ESPERADOS:
- LocalizedError conformance
- Result types para operations
- Error propagation adequada
- UI feedback para errors

DELIVERABLES:
1. Error types refinados
2. Error messages melhorados
3. Recovery strategies
4. Testing error scenarios

Siga patterns de error handling estabelecidos em CLAUDE.md.
```

## Prompts para Testing

### 6. Unit Test Generation

```
Gere unit tests completos para [COMPONENT_NAME]:

TESTING STRATEGY:
- AAA pattern (Arrange, Act, Assert)
- Mock dependencies
- Edge cases coverage
- Async testing com async/await

COVERAGE AREAS:
- Happy path scenarios
- Error conditions
- Edge cases
- State transitions

MOCK SETUP:
- Protocol-based mocking
- Dependency injection testing
- Combine publisher testing
- Error simulation

TARGET COVERAGE:
- ViewModels: 90%
- UseCases: 95%
- Services: 90%

EXAMPLE:
```swift
@MainActor
final class FeatureViewModelTests: XCTestCase {
    var viewModel: FeatureViewModel!
    var mockUseCase: MockFeatureUseCase!
    
    override func setUp() async throws {
        mockUseCase = MockFeatureUseCase()
        viewModel = FeatureViewModel(useCase: mockUseCase)
    }
}
```

Siga testing guidelines em CLAUDE.md.
```

## Prompts para Documentation

### 7. API Documentation

```
Crie documentação completa para esta API:

FORMATO:
- Swift DocC format
- Usage examples
- Parameter descriptions
- Return value documentation
- Error conditions

ÁREAS:
- Public interfaces
- Protocol methods
- Published properties
- Error types

EXEMPLO:
```swift
/// Service responsible for [FUNCTIONALITY]
///
/// This service provides [DESCRIPTION] using [TECHNOLOGY].
///
/// ## Usage
/// ```swift
/// let service = ServiceImplementation()
/// let result = try await service.performOperation(input)
/// ```
///
/// - Note: Requires [PERMISSIONS/REQUIREMENTS]
protocol ServiceProtocol {
    /// Performs [OPERATION] with given input
    /// - Parameter input: The input data for processing
    /// - Returns: Processed result
    /// - Throws: ServiceError if operation fails
    func performOperation(_ input: Input) async throws -> Output
}
```
```

### 8. ADR Creation

```
Crie um ADR (Architecture Decision Record) para a decisão de [DECISION_TOPIC]:

TEMPLATE:
```markdown
# ADR [NUMBER]: [TITLE]

## Status
[Proposed/Accepted/Deprecated/Superseded]

## Date
[YYYY-MM-DD]

## Context
[Situação que motivou a decisão]

## Opções Consideradas
[Lista de alternativas avaliadas]

## Decisão
[Decisão tomada]

## Justificativa
[Razões para a decisão]

## Consequências
### Positivas
### Negativas
### Mitigações

## Implementação
[Detalhes técnicos de implementação]

## Revisão
[Condições para revisar esta decisão]
```

CONTEXTO DO PROJETO:
- App demonstrativo iOS
- Arquitetura MVVM + Combine
- Uso de Speech Framework e FoundationModels
- Focus em privacy e on-device processing

Documente seguindo formato estabelecido em docs/ADRs/.
```

## Prompts para Code Review

### 9. Code Review Comprehensivo

```
Execute code review completo desta implementação iOS:

ÁREAS DE REVIEW:
1. **Architecture Compliance**
   - MVVM pattern seguido corretamente
   - Separation of concerns adequada
   - Dependency injection apropriada

2. **Code Quality**
   - Swift conventions
   - Naming consistency
   - Function/class size
   - Complexity management

3. **Performance**
   - Memory management
   - UI responsiveness
   - Async operations
   - Resource cleanup

4. **Testing**
   - Test coverage adequada
   - Test quality e maintainability
   - Mock usage apropriado

5. **Documentation**
   - API documentation
   - Code comments adequados
   - README updates

DELIVERABLES:
1. Issues identificados com severidade
2. Sugestões de melhoria
3. Code snippets corrigidos
4. Action items priorizados

Siga guidelines de code review em CLAUDE.md.
```

## Prompts para Integration

### 10. Feature Integration

```
Integre as features [FEATURE_1] e [FEATURE_2] seguindo a arquitetura estabelecida:

INTEGRATION POINTS:
- Data flow entre features
- Navigation patterns
- State sharing
- Error propagation

PATTERNS:
- Coordinator pattern para navigation
- Shared ViewModels quando apropriado
- Event-driven communication
- Dependency injection coordination

CONSIDERATIONS:
- Performance impact
- Memory management
- User experience flow
- Error handling consistency

DELIVERABLES:
1. Integration layer implementation
2. Navigation flow updates
3. State management adjustments
4. Integration tests

Siga patterns de integration estabelecidos no projeto.
```

## Como Usar Estes Prompts

### Setup Inicial
1. Abra Claude.ai ou use Claude CLI
2. Carregue contexto do projeto (CLAUDE.md, state.local.md, ADRs relevantes)
3. Escolha prompt apropriado para task
4. Customize [PLACEHOLDERS] com informações específicas

### Exemplo de Uso
```
Para implementar SpeechService, use prompt #1:
- Substitua [FEATURE_NAME] por "Speech Recognition" 
- Adicione contexto específico do Speech Framework
- Inclua requirements de permissions
```

### Best Practices
- Sempre forneça contexto completo do projeto
- Use prompts iterativamente (implemente -> review -> refine)
- Adapte prompts conforme learnings
- Mantenha state.local.md atualizado após cada implementação
