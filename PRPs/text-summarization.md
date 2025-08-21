# PRP: Text Summarization Implementation

## Goal
Implementar funcionalidade completa de sumarização de texto usando FoundationModels framework, processando o output do reconhecimento de fala para gerar resumos estruturados on-device.

## Why
- **AI Showcase**: Demonstra FoundationModels framework state-of-the-art
- **Privacy First**: Processamento 100% on-device sem envio de dados
- **Modern Architecture**: Structured output com @Generable e streaming
- **Complete Pipeline**: Completa o fluxo speech -> text -> summary
- **Technology Demo**: Showcases Apple Intelligence integration

## What
Sistema de sumarização que:
- Processa texto transcrito do speech recognition
- Gera resumos estruturados com pontos principais
- Streaming de resultados em tempo real
- UI responsiva com progress indicators
- Fallback gracioso para dispositivos não compatíveis

### Success Criteria
- [ ] Detecta availability do FoundationModels corretamente
- [ ] Processa texto de input e gera resumo estruturado
- [ ] Streaming UI mostra progresso em tempo real
- [ ] Structured output com summary + keyPoints + category
- [ ] Error handling robusto para model unavailable
- [ ] Performance < 10s para textos até 1000 palavras
- [ ] UI liquid glass moderna e acessível
- [ ] Integration seamless com speech recognition
- [ ] Fallback para dispositivos sem Apple Intelligence

## All Needed Context

### Documentation & References
- file: docs/ADRs/002-foundation-models-choice.md
  why: Decisão arquitetural sobre uso de FoundationModels
- file: CLAUDE.md
  why: Guidelines de desenvolvimento e patterns
- file: docs/plans/action-plan-summary.md
  why: Plano detalhado para implementação
- url: https://www.createwithswift.com/exploring-the-foundation-models-framework/
  why: Referência completa de FoundationModels
- url: https://developer.apple.com/documentation/FoundationModels
  why: Documentação oficial Apple

### Known Gotchas
```swift
// CRITICAL: Sempre verificar model availability primeiro
let model = SystemLanguageModel.default
guard case .available = model.availability else { 
    // Handle unavailable case
    return 
}

// CRITICAL: Usar @Generable para structured output
// CRITICAL: @Guide constraints são importantes para qualidade
// CRITICAL: Handle streaming interruptions gracefully
// CRITICAL: Cleanup session adequadamente
```

### Code Examples
```swift
// Pattern para FoundationModels setup
import FoundationModels

let session = LanguageModelSession(
    model: .default,
    instructions: {
        "Você é especialista em sumarização de texto em português brasileiro."
    }
)

// Pattern para @Generable struct
@Generable
struct SummaryResult {
    @Guide(description: "Resumo conciso em 2-3 frases")
    let summary: String
    
    @Guide(description: "Lista de 3-5 pontos principais", .count(3...5))
    let keyPoints: [String]
    
    @Guide(description: "Categoria do conteúdo")
    let category: String
}
```

## Implementation Blueprint

### Task 1: FoundationModels Service
```swift
// SummarizationService.swift
protocol SummarizationServiceProtocol {
    var isAvailable: Bool { get }
    func summarizeText(_ text: String) async throws -> SummaryResult
    func streamSummary(_ text: String) -> AsyncStream<PartialSummaryResult>
}

final class FoundationModelsSummarizationService: SummarizationServiceProtocol {
    private let session: LanguageModelSession
    
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }
    
    init() {
        self.session = LanguageModelSession(
            model: .default,
            instructions: {
                """
                Você é um assistente especializado em sumarização de texto em português brasileiro.
                
                Analise o texto fornecido e crie uma sumarização estruturada:
                
                1. RESUMO: Um resumo conciso em 2-3 frases que capture a essência
                2. PONTOS PRINCIPAIS: Entre 3-5 pontos-chave mais importantes
                3. CATEGORIA: Classificação do tipo de conteúdo
                
                INSTRUÇÕES:
                - Mantenha o tom e contexto original
                - Use linguagem clara e objetiva  
                - Priorize informações mais relevantes
                - Seja conciso mas completo
                """
            }
        )
    }
    
    func summarizeText(_ text: String) async throws -> SummaryResult {
        guard isAvailable else {
            throw SummarizationError.modelUnavailable
        }
        
        let response = try await session.respond(
            to: "Sumarize este texto: \(text)",
            generating: SummaryResult.self,
            options: GenerationOptions(temperature: 0.3)
        )
        
        return response.content
    }
}

@Generable
struct SummaryResult: Equatable {
    @Guide(description: "Resumo conciso do texto em 2-3 frases")
    let summary: String
    
    @Guide(description: "Lista de 3-5 pontos principais", .count(3...5))
    let keyPoints: [String]
    
    @Guide(description: "Categoria do conteúdo (conversa, apresentação, notas, reunião, outro)")
    let category: String
}
```

### Task 2: Use Case Layer
```swift
// SummarizationUseCase.swift
protocol SummarizationUseCaseProtocol {
    func summarizeText(_ text: String) async throws -> SummaryResult
    func streamSummarization(_ text: String) -> AsyncStream<PartialSummaryResult>
    func validateInput(_ text: String) -> ValidationResult
}

final class SummarizationUseCase: SummarizationUseCaseProtocol {
    private let service: SummarizationServiceProtocol
    
    init(service: SummarizationServiceProtocol) {
        self.service = service
    }
    
    func validateInput(_ text: String) -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.count < 50 {
            return .tooShort(minimumLength: 50)
        }
        
        if trimmed.count > 5000 {
            return .tooLong(maximumLength: 5000)
        }
        
        return .valid
    }
    
    func summarizeText(_ text: String) async throws -> SummaryResult {
        let validation = validateInput(text)
        guard case .valid = validation else {
            throw SummarizationError.from(validation)
        }
        
        return try await service.summarizeText(text)
    }
}

enum ValidationResult {
    case valid
    case tooShort(minimumLength: Int)
    case tooLong(maximumLength: Int)
    case unsupportedContent
}
```

### Task 3: ViewModel Layer
```swift
// SummarizationViewModel.swift
@MainActor
final class SummarizationViewModel: ObservableObject {
    @Published var state: SummarizationState = .idle
    @Published var currentSummary: SummaryResult?
    @Published var partialSummary: PartialSummaryResult?
    @Published var progress: Double = 0.0
    @Published var errorMessage: String?
    @Published var isFoundationModelsAvailable: Bool = false
    
    private let useCase: SummarizationUseCaseProtocol
    private var streamingTask: Task<Void, Never>?
    
    init(useCase: SummarizationUseCaseProtocol) {
        self.useCase = useCase
        checkAvailability()
    }
    
    func summarizeText(_ text: String) {
        guard !text.isEmpty else { return }
        
        streamingTask?.cancel()
        
        streamingTask = Task {
            state = .processing
            
            do {
                let result = try await useCase.summarizeText(text)
                state = .completed(result)
                currentSummary = result
            } catch {
                errorMessage = error.localizedDescription
                state = .error(AppError.processingFailed(error))
            }
        }
    }
    
    private func checkAvailability() {
        // Check FoundationModels availability
        isFoundationModelsAvailable = SystemLanguageModel.default.availability == .available
    }
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

### Task 4: SwiftUI Views
```swift
// SummarizationView.swift
struct SummarizationView: View {
    @StateObject private var viewModel: SummarizationViewModel
    let inputText: String
    
    var body: some View {
        ZStack {
            BackgroundGradientView()
            
            ScrollView {
                VStack(spacing: 24) {
                    if !viewModel.isFoundationModelsAvailable {
                        UnavailableView()
                    } else {
                        switch viewModel.state {
                        case .idle, .validating:
                            ProcessingIndicatorView()
                        case .processing:
                            ProcessingView(progress: viewModel.progress)
                        case .completed(let summary):
                            SummaryResultView(summary: summary)
                        case .error:
                            ErrorView(message: viewModel.errorMessage ?? "Erro desconhecido")
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Resumo")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel.isFoundationModelsAvailable {
                viewModel.summarizeText(inputText)
            }
        }
    }
}

struct SummaryResultView: View {
    let summary: SummaryResult
    
    var body: some View {
        VStack(spacing: 20) {
            SummaryCard(title: "Resumo", content: summary.summary)
            KeyPointsCard(keyPoints: summary.keyPoints)
            CategoryCard(category: summary.category)
            ActionButtonsView()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
```

### Task 5: Error Handling
```swift
// SummarizationError.swift
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
            return "FoundationModels não está disponível. Verifique se Apple Intelligence está habilitado."
        case .deviceNotSupported:
            return "Este recurso requer iOS 26+ com Apple Intelligence ativado."
        case .textTooShort(let minimum):
            return "Texto muito curto para sumarização. Mínimo: \(minimum) caracteres."
        case .textTooLong(let maximum):
            return "Texto muito longo. Máximo: \(maximum) caracteres."
        case .processingFailed:
            return "Erro ao processar sumarização. Tente novamente."
        case .streamingInterrupted:
            return "Processamento foi interrompido. Tente novamente."
        }
    }
    
    static func from(_ validation: ValidationResult) -> SummarizationError {
        switch validation {
        case .tooShort(let minimum):
            return .textTooShort(minimum: minimum)
        case .tooLong(let maximum):
            return .textTooLong(maximum: maximum)
        case .unsupportedContent:
            return .processingFailed(NSError(domain: "UnsupportedContent", code: 1))
        case .valid:
            fatalError("Cannot create error from valid validation")
        }
    }
}
```

## Validation Loop

### Level 1: Compilation & Style
```bash
# Build verification
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Style verification
swiftlint --strict
swiftformat . --swiftversion 5.10
```

### Level 2: Unit Tests
```bash
# Run unit tests for summarization
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test -testPlan SummarizationTests

# Coverage verification (target: >85%)
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -enableCodeCoverage YES test
```

### Level 3: Manual Testing
```bash
# Device testing scenarios (Physical device with Apple Intelligence required):
# 1. FoundationModels availability detection
# 2. Summarize 100-word text
# 3. Summarize 500-word text  
# 4. Summarize 1000-word text
# 5. Handle text too short (< 50 chars)
# 6. Handle text too long (> 5000 chars)
# 7. Model unavailable scenario
# 8. Interruption during processing
# 9. Background/foreground behavior
# 10. Different content types (conversation, presentation, notes)
```

### Level 4: Integration Testing
```bash
# End-to-end testing
# 1. Speech -> Text -> Summarization flow
# 2. Navigation between features
# 3. State management across app
# 4. Error handling propagation
# 5. Memory usage during full flow
```
