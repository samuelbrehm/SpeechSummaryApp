# Plano de Ação - Speech Recognition

## Objetivo
Implementar funcionalidade completa de reconhecimento de fala com transcrição em tempo real usando Speech Framework.

## Escopo

### In Scope
- Reconhecimento de fala em tempo real
- Transcrição para texto
- UI de gravação com feedback visual
- Tratamento de permissões
- Error handling robusto
- Suporte para PT-BR e EN-US

### Out of Scope
- Múltiplos idiomas além de PT-BR/EN-US
- Persistência de gravações
- Compartilhamento de áudio
- Edição de transcrições
- Backup cloud

## Arquitetura

### Componentes
```
SpeechRecognitionView
    ↓
SpeechRecognitionViewModel (@MainActor)
    ↓  
SpeechRecognitionUseCase
    ↓
SpeechService
    ↓
Speech Framework (Apple)
```

### Data Flow
```
User taps record
    ↓
ViewModel calls UseCase
    ↓
UseCase coordinates Service
    ↓
Service starts Speech Framework
    ↓
Framework streams partial results
    ↓
Service publishes updates
    ↓
ViewModel updates UI state
    ↓
View reflects new state
```

## Tasks Detalhadas

### Task 1: Core Service Implementation
**Duração**: 1 dia
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SpeechServiceProtocol
- [ ] Implementar SpeechService
- [ ] Setup SFSpeechRecognizer
- [ ] Configurar AVAudioEngine
- [ ] Implementar permission handling

#### Definition of Done
```swift
protocol SpeechServiceProtocol {
    var authorizationStatus: Published<SFSpeechRecognizerAuthorizationStatus>.Publisher { get }
    var isRecording: Published<Bool>.Publisher { get }
    var transcribedText: Published<String>.Publisher { get }
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
    func startRecording() async throws
    func stopRecording()
}
```

#### Acceptance Criteria
- Service compila sem erros
- Permission request funciona
- Basic recording start/stop implementado
- Publishers configurados corretamente

### Task 2: Use Case Layer
**Duração**: 0.5 dia  
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SpeechRecognitionUseCaseProtocol
- [ ] Implementar business logic
- [ ] Error mapping
- [ ] Validation rules

#### Definition of Done
```swift
protocol SpeechRecognitionUseCaseProtocol {
    func requestPermissions() async -> Bool
    func startSpeechRecognition() async throws
    func stopSpeechRecognition() async
    func getCurrentTranscription() -> String
}
```

#### Acceptance Criteria
- Use case coordena service corretamente
- Business rules implementadas
- Error handling apropriado
- Interface clara para ViewModel

### Task 3: ViewModel Implementation
**Duração**: 1 dia
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SpeechRecognitionViewModel
- [ ] State management implementation
- [ ] Combine subscriptions
- [ ] Error handling for UI

#### Definition of Done
```swift
@MainActor
final class SpeechRecognitionViewModel: ObservableObject {
    @Published var state: SpeechRecognitionState = .idle
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    @Published var permissionStatus: PermissionStatus = .notDetermined
}
```

#### Acceptance Criteria
- State updates corretamente
- UI bindings funcionais
- Error messages user-friendly
- Performance adequada (@MainActor)

### Task 4: UI Implementation
**Duração**: 1.5 dias
**Prioridade**: Alta

#### Subtasks
- [ ] Criar SpeechRecognitionView
- [ ] Implementar record button com animação
- [ ] Feedback visual para recording state
- [ ] Text display com scroll
- [ ] Error state UI
- [ ] Permission request UI

#### Design Requirements
- **Record Button**: Circular, red quando recording
- **Visual Feedback**: Pulse animation durante recording
- **Text Display**: ScrollView com auto-scroll
- **Colors**: Vibrant seguindo iOS design trends
- **Accessibility**: VoiceOver e Dynamic Type

#### Definition of Done
```swift
struct SpeechRecognitionView: View {
    @StateObject private var viewModel: SpeechRecognitionViewModel
    
    var body: some View {
        // Implementation with liquid glass effects
    }
}
```

### Task 5: Integration & Testing
**Duração**: 1 dia
**Prioridade**: Média

#### Subtasks
- [ ] Unit tests para Service
- [ ] Unit tests para UseCase  
- [ ] Unit tests para ViewModel
- [ ] Integration testing
- [ ] Manual testing em device

#### Test Coverage Goals
- Service: 90%
- UseCase: 95%
- ViewModel: 90%
- Integration: Happy path + main error cases

## Technical Specifications

### Models
```swift
enum SpeechRecognitionState: Equatable {
    case idle
    case requestingPermission
    case ready
    case recording
    case processing
    case completed(String)
    case error(AppError)
}

enum PermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}

struct TranscriptionResult {
    let text: String
    let confidence: Float
    let isFinal: Bool
    let timestamp: Date
}
```

### Error Handling
```swift
enum SpeechError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case audioEngineError(Error)
    case recognitionFailed(Error)
    case recordingInProgress
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Acesso ao microfone e reconhecimento de fala necessário"
        case .recognizerUnavailable:
            return "Reconhecimento de fala não disponível"
        // ... outros casos
        }
    }
}
```

### Configuration
```swift
// Locale configuration
private let supportedLocales = [
    Locale(identifier: "pt-BR"),
    Locale(identifier: "en-US")
]

// Recognition settings
private let maxRecordingDuration: TimeInterval = 60.0
private let audioFormat = AVAudioFormat(
    standardFormatWithSampleRate: 44100,
    channels: 1
)
```

## Performance Requirements

### Response Times
- **Permission Request**: < 1s para mostrar dialog
- **Recording Start**: < 500ms para feedback visual
- **Transcription**: Partial results < 1s, final < 2s
- **UI Updates**: 60fps durante animações

### Memory Usage
- **Baseline**: < 50MB quando idle
- **Recording**: < 100MB durante operação
- **Cleanup**: Return to baseline após stop

### Battery Impact
- **Minimal**: Uso eficiente de Neural Engine
- **Optimization**: Stop recognition quando app backgrounded

## Acceptance Criteria (Feature Level)

### Functional
- [ ] User pode iniciar gravação com um tap
- [ ] Text aparece em tempo real durante gravação
- [ ] User pode parar gravação a qualquer momento
- [ ] Permissions são solicitadas apropriadamente
- [ ] Errors são tratados graciosamente
- [ ] App funciona offline

### Non-Functional
- [ ] Response time < 2s para transcription
- [ ] UI responsiva durante operação
- [ ] Memory usage dentro dos limites
- [ ] Accessibility completo
- [ ] Suporte Dark/Light mode

### Technical
- [ ] Code coverage > 85%
- [ ] SwiftLint passa sem warnings
- [ ] No memory leaks detectados
- [ ] Performance profiling aprovado

## Risk Assessment

### Riscos Altos
- **Device Compatibility**: Nem todos devices suportam Speech Framework adequadamente
- **Noise Handling**: Ambiente ruidoso pode degradar qualidade

### Mitigações
- **Testing**: Testar em múltiplos devices
- **Feedback**: Indicar qualidade da transcrição para user
- **Fallback**: Permitir retry em caso de erro

## Dependencies

### Internal
- Core architecture (MVVM setup)
- Base UI components
- Error handling framework

### External  
- Speech Framework
- AVFoundation
- Combine
- SwiftUI

## Handoff para Próxima Feature

### Deliverables
- SpeechRecognitionView pronta para integração
- TranscriptionResult model para consumo
- Documentação de APIs públicas
- Test suite completa

### Integration Points
- ViewModel expõe transcribedText para próxima feature
- State management compatível com summarization
- Error handling consistente across features

## Definition of Done (Feature Completa)

- [ ] Todas as tasks completadas e testadas
- [ ] Code review aprovado
- [ ] Documentation atualizada
- [ ] Performance requirements atendidos
- [ ] Accessibility validado
- [ ] Integration testing passed
- [ ] Demo-ready para apresentação
