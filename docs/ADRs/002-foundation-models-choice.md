# ADR 002: Uso do FoundationModels para Sumarização

## Status
Aceito

## Data
2025-08-20

## Contexto
Necessitamos de um sistema de sumarização de texto para processar o output do reconhecimento de fala e gerar resumos com pontos principais.

## Opções Consideradas

### 1. FoundationModels (Apple)
- Framework nativo iOS 26+
- Processamento completamente on-device
- Modelos otimizados para Apple Silicon
- Integração com Apple Intelligence

### 2. OpenAI GPT API
- Alta qualidade de sumarização
- Processamento na nuvem
- Flexibilidade de prompts
- Custo por token

### 3. Claude API (Anthropic)
- Excelente capacidade de sumarização
- Processamento cloud
- Boa performance em texto português
- Modelo de pricing baseado em uso

### 4. Modelos locais (CoreML)
- Processamento local
- Controle total sobre modelo
- Performance dependente do dispositivo
- Requer conversão e otimização

## Decisão
**FoundationModels framework do Apple**

## Justificativa

### Alinhamento Estratégico
- **Demonstração**: Showcases tecnologia cutting-edge da Apple
- **Consistência**: Mantém stack 100% Apple/on-device
- **Modernidade**: Usa as APIs mais recentes disponíveis
- **Privacy**: Alinhado com estratégia privacy-first

### Vantagens Técnicas
- **Performance**: Otimizado para Apple Silicon (Neural Engine)
- **Latência**: Processamento local elimina network latency
- **Reliability**: Não depende de conectividade
- **Integration**: APIs nativas Swift bem integradas

### Vantagens de Negócio
- **Custo**: Zero custo operacional
- **Privacy**: Dados nunca saem do dispositivo
- **Offline**: Funciona em qualquer lugar
- **Compliance**: Conformidade automática com GDPR/LGPD

## Consequências

### Positivas
- Privacidade total do usuário
- Performance otimizada para iOS
- Zero custo operacional
- Funcionalidade offline completa
- Integração nativa com SwiftUI/Combine
- Demonstra tecnologia state-of-the-art

### Negativas
- Requer iOS 26+ e Apple Intelligence habilitado
- Limitado a dispositivos com Neural Engine
- Menor controle sobre prompts/behavior
- Qualidade dependente dos modelos Apple
- Funcionalidade limitada comparada a APIs cloud
- Base de dispositivos compatíveis menor

### Mitigações
- **Compatibilidade**: Detectar availability e mostrar fallback
- **Quality**: Testes extensivos com diferentes tipos de texto
- **Fallback**: Preparar arquitetura para alternativas futuras
- **UX**: Comunicar claramente requisitos do sistema

## Implementação

### Detecção de Disponibilidade
```swift
let model = SystemLanguageModel.default
switch model.availability {
case .available:
    // Prosseguir com sumarização
case .unavailable(let reason):
    // Mostrar fallback ou erro amigável
}
```

### Service Architecture
```swift
protocol SummarizationServiceProtocol {
    func summarizeText(_ text: String) async throws -> SummaryResult
    func streamSummary(_ text: String) -> AsyncStream<PartialSummary>
}

final class FoundationModelsSummarizationService: SummarizationServiceProtocol {
    private let session: LanguageModelSession
    
    init() {
        self.session = LanguageModelSession(
            model: .default,
            instructions: {
                """
                Você é um assistente especializado em sumarização.
                Analise o texto fornecido e extraia:
                1. Um resumo conciso (2-3 frases)
                2. 3-5 pontos principais
                3. Mantenha o tom e contexto original
                """
            }
        )
    }
}
```

### Modelo de Dados
```swift
@Generable
struct SummaryResult {
    @Guide(description: "Resumo conciso do texto em 2-3 frases")
    let summary: String
    
    @Guide(description: "Lista de 3-5 pontos principais", .count(3...5))
    let keyPoints: [String]
    
    @Guide(description: "Categoria do conteúdo (conversa, apresentação, notas, etc)")
    let category: String
}
```

## Configuração Necessária

### Info.plist
```xml
<key>NSAppleAINaturalLanguageDescription</key>
<string>Este app usa Apple Intelligence para sumarizar texto transcrito</string>
```

### Capabilities
- Apple Intelligence (automático em iOS 26+)
- Nenhuma capability adicional necessária

### Error Handling
```swift
enum SummarizationError: LocalizedError {
    case modelUnavailable
    case deviceNotSupported
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence não está disponível neste dispositivo"
        case .deviceNotSupported:
            return "Este recurso requer iOS 26+ com Apple Intelligence"
        case .processingFailed(let error):
            return "Erro ao processar texto: \(error.localizedDescription)"
        }
    }
}
```

## Revisão
Esta decisão deve ser revisada se:
- FoundationModels não atender qualidade esperada
- Base de dispositivos compatíveis for muito limitada
- Apple modificar significativamente as APIs
- Requisitos de funcionalidade cloud emergirem
- Feedback negativo sobre performance ou accuracy
