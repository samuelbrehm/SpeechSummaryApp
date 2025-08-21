# Prompts para Geração de PRPs

## Template Principal para PRP

```
Você é um especialista em desenvolvimento iOS e engenharia de contexto. Crie um PRP (Product Requirements Prompt) completo para implementar [FEATURE_NAME] no projeto SpeechSummaryApp.

CONTEXTO DO PROJETO:
- App demonstrativo iOS de workflows de IA
- Arquitetura: MVVM + Combine + SwiftUI  
- Stack: Speech Framework + FoundationModels
- Target: iOS 26+, dispositivos com Apple Intelligence
- Objetivo: Demonstrar PRPs e Context Engineering

ESTRUTURA DO PRP:

## Goal
[Descrição clara do que implementar]

## Why  
[Valor de negócio e impacto para demonstração]

## What
[Funcionalidade específica com success criteria]

## All Needed Context

### Documentation & References
- file: [arquivos relevantes do projeto]
- url: [documentação Apple ou external]
- section: [seções específicas]

### Known Gotchas
[Armadilhas técnicas específicas da feature]

### Code Examples
[Patterns e snippets específicos para a implementação]

## Implementation Blueprint

### Task 1: [Nome da Task]
```swift
// Código de estrutura/interface
```

### Task 2-N: [Outras tasks]
[Pseudocódigo e estrutura detalhada]

## Validation Loop

### Level 1: Compilation & Style
```bash
# Comandos de build e lint
```

### Level 2: Unit Tests
```bash  
# Comandos de teste
```

### Level 3: Manual Testing
```bash
# Cenários de teste manual
```

GUIDELINES:
- Use arquitetura MVVM estabelecida
- Siga guidelines em CLAUDE.md
- Considere state atual em state.local.md
- Implemente patterns de dependency injection
- Focus em testability e maintainability

ENTREGUE um PRP completo e executável que uma IA possa seguir para implementar a feature com sucesso na primeira tentativa.
```

## Prompt para PRP de Speech Recognition

```
Crie um PRP completo para implementar Speech Recognition no SpeechSummaryApp.

ESPECIFICAÇÕES TÉCNICAS:
- Use Speech Framework nativo do iOS
- Implementar reconhecimento em tempo real
- Suporte para PT-BR e EN-US
- Máximo 60 segundos de gravação
- UI com liquid glass effects
- Feedback visual durante gravação

ARQUITETURA REQUERIDA:
```
SpeechRecognitionView (SwiftUI)
    ↓
SpeechRecognitionViewModel (@MainActor)
    ↓
SpeechRecognitionUseCase
    ↓
SpeechService (Speech Framework wrapper)
```

CONTEXTO ESPECÍFICO:
- ADR 001 define uso de Speech Framework
- Permissions: NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription
- Error handling robusto para permissions e availability
- Performance: < 2s response time para transcription

INTEGRATION POINTS:
- Output: transcribedText para SummarizationFeature
- Navigation: Transition suave para summarization
- State: Compartilhamento via coordinator

Implemente seguindo patterns estabelecidos e guidelines do projeto.
```

## Prompt para PRP de Text Summarization

```
Crie um PRP completo para implementar Text Summarization usando FoundationModels.

ESPECIFICAÇÕES TÉCNICAS:
- Use FoundationModels framework (iOS 26+)
- Structured output com @Generable
- Streaming responses com AsyncStream
- On-device processing exclusivamente
- UI responsiva com progress indicators

ARQUITETURA REQUERIDA:
```
SummarizationView (SwiftUI)
    ↓
SummarizationViewModel (@MainActor)
    ↓
SummarizationUseCase
    ↓
SummarizationService (FoundationModels wrapper)
```

CONTEXTO ESPECÍFICO:
- ADR 002 define uso de FoundationModels
- Input: texto do SpeechRecognitionFeature
- Output: estruturado com summary + keyPoints + category
- Availability check: SystemLanguageModel.availability
- Error handling para device compatibility

STRUCTURED OUTPUT:
```swift
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

PERFORMANCE REQUIREMENTS:
- < 10s processing time
- Streaming updates a cada 1-2s
- Memory efficient (< 200MB adicional)

Implemente seguindo patterns do projeto e guidelines de FoundationModels.
```

## Prompt para PRP de Integration

```
Crie um PRP para integrar Speech Recognition + Text Summarization em um fluxo completo.

INTEGRATION REQUIREMENTS:
- Navigation seamless entre features
- State sharing entre ViewModels
- Error handling consistente
- Performance otimizada end-to-end

FLUXO ESPERADO:
1. User grava áudio -> Speech Recognition
2. Texto transcrito -> Automatic trigger para Summarization
3. Summary gerado -> Display com opções de share/restart

ARQUITETURA DE INTEGRAÇÃO:
```
AppCoordinator (Navigation)
    ↓
ContentView (Main container)
    ├── SpeechRecognitionView
    └── SummarizationView
```

SHARING MECHANISMS:
- @EnvironmentObject para coordinator
- Published text state entre ViewModels
- Event-driven transitions
- Shared error handling

TECHNICAL CONSIDERATIONS:
- Memory cleanup entre features
- Background behavior durante processing
- Permission coordination
- Device capability checks

DELIVERABLES:
1. AppCoordinator implementation
2. Navigation flow setup
3. State management integration
4. Error handling coordination
5. End-to-end testing scenarios

Implemente seguindo patterns MVVM e guidelines estabelecidos.
```

## Prompt para Refinamento de PRP

```
Refine este PRP existente para melhorar sua completude e executabilidade:

[INSERIR PRP EXISTENTE]

CRITÉRIOS DE REFINAMENTO:
1. **Completude**: Todas as informações necessárias presentes?
2. **Executabilidade**: Uma IA consegue implementar seguindo apenas o PRP?
3. **Context Engineering**: Context adequado fornecido?
4. **Validation**: Loops de validação abrangentes?
5. **Implementation**: Blueprint detalhado suficiente?

MELHORIAS ESPECÍFICAS:
- Adicionar code examples missing
- Expandir known gotchas
- Detalhar validation scenarios
- Clarificar integration points
- Melhorar documentation references

CHECKLIST:
- [ ] Goal claro e específico
- [ ] Why justifica implementação
- [ ] What com success criteria mensuráveis
- [ ] Context completo com files/urls/examples
- [ ] Known gotchas comprehensive
- [ ] Implementation blueprint executável
- [ ] Validation loop completo
- [ ] Integration points definidos

ENTREGUE versão refinada do PRP que maximize chances de implementação bem-sucedida na primeira tentativa.
```

## Prompt para Análise de Quality de PRP

```
Analise a qualidade deste PRP usando os critérios de um PRP excelente:

[INSERIR PRP PARA ANÁLISE]

CRITÉRIOS DE AVALIAÇÃO:

### 1. Clarity & Specificity (1-10)
- Goal é específico e mensurável?
- Requirements são claros e não ambíguos?
- Success criteria são objetivos?

### 2. Context Engineering (1-10)  
- Context necessário está presente?
- Documentation references são adequados?
- Code examples são relevantes e corretos?
- Known gotchas são abrangentes?

### 3. Executability (1-10)
- Implementation blueprint é detalhado?
- Tasks são quebradas apropriadamente?
- Dependencies são claras?
- Uma IA consegue executar without clarification?

### 4. Validation (1-10)
- Validation loops são completos?
- Test scenarios cobrem edge cases?
- Manual testing é bem definido?
- Quality gates são mensuráveis?

### 5. Integration (1-10)
- Integration points são claros?
- Handoffs para outras features definidos?
- State management é apropriado?
- Error handling é consistente?

DELIVERABLES:
1. Score para cada critério com justificativa
2. Strengths identificados
3. Gaps e weaknesses
4. Action items para melhorias
5. Overall recommendation (Ready/Needs Work/Major Revision)

SCORE TOTAL: [X]/50

Forneça analysis detalhado e acionável para maximizar quality do PRP.
```

## Prompt para PRP de Testing

```
Crie um PRP específico para implementar testing completo para [FEATURE_NAME]:

TESTING STRATEGY:
- Unit Tests: ViewModels, UseCases, Services
- Integration Tests: Feature interactions
- Manual Testing: Device scenarios
- Performance Testing: Memory, CPU, responsiveness

COVERAGE TARGETS:
- ViewModels: 90%
- UseCases: 95% 
- Services: 90%
- Integration: Happy path + major error scenarios

TESTING ARCHITECTURE:
```
FeatureTests/
├── ViewModelTests/
├── UseCaseTests/
├── ServiceTests/
├── IntegrationTests/
└── MockSupport/
```

SPECIFIC REQUIREMENTS:
- Mock all external dependencies
- Test async/await code correctly
- Combine publisher testing
- Error scenario coverage
- Performance benchmarks

VALIDATION CRITERIA:
- All tests pass consistently
- Coverage meets targets
- No flaky tests
- Fast execution (< 30s total)
- Clear test names and documentation

Crie PRP executável para comprehensive testing implementation.
```

## Como Usar Estes Prompts

### Processo Sugerido

1. **Seleção**: Escolha prompt baseado na feature/task
2. **Customização**: Substitua [PLACEHOLDERS] com especificações
3. **Context Loading**: Carregue arquivos relevantes (CLAUDE.md, ADRs, state.local.md)
4. **Execução**: Execute prompt com context completo
5. **Refinamento**: Use prompt de refinamento se necessário
6. **Validação**: Use prompt de análise para quality check

### Exemplo de Workflow

```bash
# 1. Gerar PRP inicial
Use prompt "PRP de Speech Recognition" 
-> Gera primeiro draft

# 2. Refinar PRP  
Use prompt "Refinamento de PRP"
-> Melhora completude e executabilidade

# 3. Validar qualidade
Use prompt "Análise de Quality"
-> Identifica gaps e melhorias

# 4. Implementar
Use PRP final com Claude Code
-> Executa implementação
```

### Best Practices

- **Context First**: Sempre carregue contexto completo do projeto
- **Iterative**: Use múltiplos rounds de refinement
- **Validation**: Sempre valide quality antes de executar
- **Documentation**: Mantenha PRPs atualizados conforme implementação
- **Learning**: Capture learnings para melhorar próximos PRPs
