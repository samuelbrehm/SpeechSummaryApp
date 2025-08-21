# Plano de Ação - Text Summarization

## Objetivo
Implementar funcionalidade de sumarização de texto usando FoundationModels para processar o output do reconhecimento de fala e gerar resumos estruturados.

## Escopo

### In Scope
- Sumarização de texto usando FoundationModels
- Streaming de resultados em tempo real
- UI moderna com liquid glass effects
- Estruturação de resumo em pontos principais
- Error handling para FoundationModels
- Fallback para casos de indisponibilidade

### Out of Scope
- Múltiplos idiomas além de PT-BR/EN-US
- Customização de prompts por usuário
- Histórico de sumarizações
- Export/sharing de resultados
- Fine-tuning de modelos

## Arquitetura

### Componentes
```
SummarizationView
    ↓
SummarizationViewModel (@MainActor)
    ↓
SummarizationUseCase
    ↓
SummarizationService
    ↓
FoundationModels (Apple)
```

### Data Flow
```
User triggers summarization
    ↓
ViewModel calls UseCase with text
    ↓
UseCase validates and coordinates Service
    ↓
Service creates FoundationModels session
    ↓
Service streams partial results
    ↓
ViewModel updates UI incrementally
    ↓
View shows progressive summary
```

## Tasks Detalhadas

### Task 1: FoundationModels Service
**Duração**: 1.5 dias
**Prioridade**: Alta

#### Subtasks
- [ ] Implementar SummarizationServiceProtocol
- [ ] Setup SystemLanguageModel availability check
- [ ] Criar LanguageModelSession configuration
- [ ] Implementar structured output com @Generable
- [ ] Setup streaming response handling

#### Definition of Done
```swift
protocol SummarizationServiceProtocol {
    var isAvailable: Bool { get }
    func summarizeText(_ text: String) async throws -> SummaryResult
    func streamSummary(_ text: String) -> AsyncStream<PartialSummaryResult>
}

@Generable
struct SummaryResult {
    @Guide(description: "Resumo conciso em 2-3 frases")
    let summary: String
    
    @Guide(description: "Lista de 3-5 pontos principais", .count(3...5))
    let keyPoints: [String]
    
    @Guide(description: "Categoria do conteúdo")
    let category: String
    
    @Guide(description: "Nível de confiança da sumarização (0.0-1.0)")
    let confidence: Double
}
```

#### Acceptance Criteria
- Service detecta availability do FoundationModels
- Structured output funciona corretamente
- Streaming de partial results implementado
- Error handling para model unavailable

### Task 2: Use Case Implementation
**Duração**: 0.5 dia
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SummarizationUseCaseProtocol
- [ ] Implementar validation de input text
- [ ] Business rules para summarization
- [ ] Error mapping e handling

#### Definition of Done
```swift
protocol SummarizationUseCaseProtocol {
    func summarizeText(_ text: String) async throws -> SummaryResult
    func streamSummarization(_ text: String) -> AsyncStream<PartialSummaryResult>
    func validateInput(_ text: String) -> ValidationResult
}

enum ValidationResult {
    case valid
    case tooShort(minimumLength: Int)
    case tooLong(maximumLength: Int)
    case unsupportedContent
}
```

#### Acceptance Criteria
- Input validation implementada
- Business rules aplicadas
- Clean interface para ViewModel
- Appropriate error propagation

### Task 3: ViewModel Implementation  
**Duração**: 1 dia
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SummarizationViewModel
- [ ] State management para streaming
- [ ] Integration com SpeechRecognitionViewModel
- [ ] Error state handling
- [ ] Progress tracking

#### Definition of Done
```swift
@MainActor
final class SummarizationViewModel: ObservableObject {
    @Published var state: SummarizationState = .idle
    @Published var currentSummary: SummaryResult?
    @Published var partialSummary: PartialSummaryResult?
    @Published var progress: Double = 0.0
    @Published var errorMessage: String?
    @Published var isFoundationModelsAvailable: Bool = false
}

enum SummarizationState: Equatable {
    case idle
    case validating
    case processing
    case streaming(progress: Double)
    case completed(SummaryResult)
    case error(AppError)
}
```

#### Acceptance Criteria
- State transitions corretas
- Progress tracking funcionando
- Error states bem handled
- Integration com speech recognition

### Task 4: UI Implementation
**Duração**: 2 dias
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SummarizationView
- [ ] Implementar streaming UI com animations
- [ ] Progress indicators
- [ ] Summary display com formatting
- [ ] Error state UI
- [ ] Integration com SpeechRecognitionView

#### Design Requirements
- **Streaming Effect**: Text aparece progressivamente
- **Progress Bar**: Circular progress durante processing
- **Cards Layout**: Summary e key points em cards separadas
- **Animations**: Smooth transitions entre states
- **Colors**: Vibrant palette com liquid glass
- **Typography**: Hierarchy clara para summary vs points

#### Definition of Done
```swift
struct SummarizationView: View {
    @StateObject private var viewModel: SummarizationViewModel
    let inputText: String
    
    var body: some View {
        // Implementation with streaming UI
    }
}

struct SummaryCard: View {
    let summary: SummaryResult
    // Card implementation
}

struct ProgressView: View {
    let progress: Double
    // Circular progress with animation
}
```

### Task 5: Integration & Navigation
**Duração**: 1 día
**Prioridade**: Alta

#### Subtasks
- [ ] Integrar SpeechRecognition -> Summarization flow
- [ ] Navigation entre telas
- [ ] State sharing entre ViewModels
- [ ] Deep linking preparation
- [ ] Coordinator pattern setup

#### Definition of Done
```swift
struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // Navigation implementation
        }
    }
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateToSummarization(text: String) {
        // Navigation logic
    }
}
```

### Task 6: Testing & Polish
**Duração**: 1 día
**Prioridade**: Média

#### Subtasks
- [ ] Unit tests para Service
- [ ] Unit tests para UseCase
- [ ] Unit tests para ViewModel
- [ ] Integration testing
- [ ] UI testing para key flows
- [ ] Performance testing
- [ ] Accessibility testing

#### Test Coverage Goals
- Service: 90%
- UseCase: 95%
- ViewModel: 90%
- Integration: Complete happy path

## Technical Specifications

### Models
```swift
@Generable
struct SummaryResult: Equatable {
    let summary: String
    let keyPoints: [String]
    let category: String
    let confidence: Double
    let processedAt: Date
    let originalTextLength: Int
}

@Generable  
struct PartialSummaryResult: Equatable {
    let summary: String?
    let keyPoints: [String]
    let category: String?
    let progress: Double
}

enum SummaryCategory: String, CaseIterable {
    case conversation = "Conversa"
    case presentation = "Apresentação"  
    case notes = "Notas"
    case meeting = "Reunião"
    case other = "Outro"
}
```

### FoundationModels Configuration
```swift
final class SummarizationService: SummarizationServiceProtocol {
    private let session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession(
            model: .default,
            instructions: {
                """
                Você é um assistente especializado em sumarização de texto em português brasileiro.
                
                Sua tarefa é analisar o texto fornecido e criar uma sumarização estruturada que inclui:
                
                1. RESUMO: Um resumo conciso em 2-3 frases que capture a essência do conteúdo
                2. PONTOS PRINCIPAIS: Entre 3-5 pontos-chave mais importantes
                3. CATEGORIA: Classificação do tipo de conteúdo (conversa, apresentação, notas, reunião, outro)
                4. CONFIANÇA: Seu nível de confiança na qualidade da sumarização (0.0 a 1.0)
                
                INSTRUÇÕES:
                - Mantenha o tom e contexto original
                - Use linguagem clara e objetiva
                - Priorize informações mais relevantes
                - Seja conciso mas completo
                - Para textos muito curtos (<50 palavras), indique baixa confiança
                """
            }
        )
    }
}
```

### Error Handling
```swift
enum SummarizationError: LocalizedError {
    case modelUnavailable
    case deviceNotSupported
    case textTooShort(minimum: Int)
    case textTooLong(maximum: Int)
    case processingFailed(Error)
    case streamingInterrupted
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "FoundationModels não disponível. Verifique se Apple Intelligence está habilitado."
        case .deviceNotSupported:
            return "Este recurso requer iOS 26+ com Apple Intelligence."
        case .textTooShort(let minimum):
            return "Texto muito curto para sumarização. Mínimo: \(minimum) caracteres."
        case .textTooLong(let maximum):
            return "Texto muito longo. Máximo: \(maximum) caracteres."
        case .processingFailed:
            return "Erro ao processar sumarização. Tente novamente."
        case .streamingInterrupted:
            return "Processamento interrompido. Tente novamente."
        }
    }
}
```

## Performance Requirements

### Response Times
- **Availability Check**: < 100ms
- **Processing Start**: < 500ms para feedback inicial
- **Streaming**: Partial results a cada 1-2s
- **Completion**: Total < 10s para textos de até 1000 palavras

### Memory Usage
- **Model Loading**: < 200MB adicional
- **Processing**: < 100MB durante operação
- **Cleanup**: Automatic após completion

### Quality Metrics
- **Relevance**: Summary deve capturar pontos principais
- **Conciseness**: Summary 10-15% do tamanho original
- **Accuracy**: Key points devem ser factualmente corretos
- **Language**: Output em português bem formado

## User Experience

### Happy Path Flow
1. User completa speech recognition
2. "Summarize" button aparece
3. User taps -> transition suave para summary screen
4. Progress indicator mostra processamento
5. Summary aparece progressivamente
6. Final result com summary + key points
7. Option para voltar ou começar novo

### Error Scenarios
- **Model Unavailable**: Clear message + fallback option
- **Text Too Short**: Guidance sobre minimum length
- **Processing Failed**: Retry option
- **Network Issues**: Offline-first approach

### Accessibility
- **VoiceOver**: Todos elementos com labels apropriados
- **Dynamic Type**: Text scaling correto
- **High Contrast**: Readable em accessibility modes
- **Voice Control**: Navegação por comandos de voz

## Integration Points

### Input Sources
- Direct from SpeechRecognitionViewModel
- Manual text input (future enhancement)
- Clipboard import (future)

### Output Destinations
- Display in app UI
- Share via standard iOS sharing
- Copy to clipboard
- Export to other apps (future)

## Acceptance Criteria (Feature Level)

### Functional
- [ ] FoundationModels availability é detectada corretamente
- [ ] Text input é validado apropriadamente
- [ ] Summarization produz resultados relevantes
- [ ] Streaming UI funciona smoothly
- [ ] Error handling é robusto
- [ ] Integration com speech recognition é seamless

### Non-Functional
- [ ] Response time < 10s para textos normais
- [ ] UI permanece responsiva durante processing
- [ ] Memory usage dentro dos limites
- [ ] Accessibility completo
- [ ] Support para Dark/Light mode

### Technical
- [ ] Code coverage > 85%
- [ ] SwiftLint passa sem warnings
- [ ] No memory leaks
- [ ] Performance profiling approved

## Risk Assessment

### Riscos Altos
- **FoundationModels Quality**: Qualidade do modelo pode não atender expectativas
- **Device Compatibility**: Limited availability em devices mais antigos
- **Processing Time**: Pode ser muito lento para UX aceitável

### Mitigações
- **Quality**: Extensive testing com diferentes tipos de texto
- **Compatibility**: Clear messaging sobre requirements
- **Performance**: Optimization + fallback para textos muito longos
- **Feedback**: Progress indicators + partial results para perceived performance

## Dependencies

### Internal
- SpeechRecognitionViewModel (para input text)
- Core architecture (MVVM, error handling)
- Navigation system

### External
- FoundationModels framework
- SwiftUI para streaming UI
- Combine para reactive updates

## Definition of Done (Feature Completa)

- [ ] Todas as tasks completadas e testadas
- [ ] Integration com speech recognition funcional
- [ ] UI polida e acessível
- [ ] Performance requirements atendidos
- [ ] Error handling robusto
- [ ] Documentation atualizada
- [ ] Demo-ready para apresentação
- [ ] Code review aprovado
