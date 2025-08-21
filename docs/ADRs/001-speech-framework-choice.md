# ADR 001: Uso do Speech Framework Nativo

## Status
Aceito

## Data
2025-08-20

## Contexto
Precisamos implementar reconhecimento de fala para converter áudio em texto no app demonstrativo de workflows de IA.

## Opções Consideradas

### 1. Speech Framework (Apple)
- Framework nativo do iOS
- Processamento on-device quando disponível
- Integração profunda com sistema
- Suporte offline para idiomas suportados

### 2. Google Speech-to-Text API
- Alta precisão em múltiplos idiomas
- Processamento na nuvem
- Recursos avançados (punctuation, timestamps)
- Custo por uso

### 3. Azure Cognitive Services Speech
- API robusta da Microsoft
- Boa precisão e performance
- Processamento cloud
- Modelo de pricing baseado em uso

### 4. OpenAI Whisper
- State-of-the-art em precisão
- Suporte a múltiplos idiomas
- Processamento local ou API
- Open source

## Decisão
**Speech Framework nativo do iOS**

## Justificativa

### Alinhamento com Objetivos
- **Privacy First**: Processamento local alinhado com uso de FoundationModels
- **Demonstração**: Mostra integração com ecosistema Apple
- **Simplicidade**: Framework nativo reduz complexidade

### Vantagens Técnicas
- **Performance**: Otimizado para hardware Apple
- **Latência**: Processamento local = menor latência
- **Offline**: Funciona sem conexão de internet
- **Integração**: APIs nativas bem documentadas

### Vantagens de Negócio
- **Custo**: Zero custo operacional
- **Compliance**: Conformidade automática com regulações de privacidade
- **UX**: Experiência consistente com outros apps iOS

## Consequências

### Positivas
- Melhor performance em dispositivos Apple
- Privacidade garantida por design
- Zero custo operacional
- Funcionalidade offline
- Integração nativa com iOS
- Menos dependências externas

### Negativas
- Limitado aos idiomas suportados pela Apple
- Precisão pode ser inferior a soluções cloud
- Menor controle sobre modelo de ML
- Funcionalidade limitada a dispositivos Apple
- Dependente de recursos do dispositivo

### Mitigações
- **Idiomas**: Focar em PT-BR e EN-US inicialmente
- **Precisão**: Implementar feedback visual para confirmação
- **Fallback**: Preparar arquitetura para futuras alternativas
- **Performance**: Testes em dispositivos variados

## Implementação

### Componentes Necessários
```swift
// Service layer
protocol SpeechServiceProtocol {
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
    func startRecording() async throws
    func stopRecording()
}

// Use case layer  
protocol SpeechRecognitionUseCaseProtocol {
    func startSpeechRecognition() async throws -> AsyncStream<String>
    func stopSpeechRecognition() async
}
```

### Configurações Necessárias
- Permissões: NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription
- Capabilities: Nenhuma adicional necessária
- Localização: Configurar para PT-BR primary, EN-US secondary

## Revisão
Esta decisão deve ser revisada se:
- Precisão do Speech Framework for insuficiente
- Necessidade de suporte a mais idiomas
- Requisitos de processamento cloud emergirem
- Feedback negativo sobre performance
