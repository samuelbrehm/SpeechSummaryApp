# PRP: Speech Recognition Implementation

## Goal
Implementar funcionalidade completa de reconhecimento de fala com transcrição em tempo real usando Speech Framework nativo do iOS, seguindo arquitetura MVVM estabelecida no projeto.

## Why
- **Core Feature**: Funcionalidade essencial para o app demonstrativo
- **Technology Showcase**: Demonstra uso avançado de Speech Framework
- **Context Engineering**: Exemplo prático de PRP implementation
- **Privacy Focus**: Processamento on-device alinhado com estratégia do projeto
- **Foundation**: Base para feature de sumarização subsequente

## What
Sistema completo de reconhecimento de fala que permite:
- Captura e transcrição de áudio em tempo real
- Interface moderna com liquid glass effects
- Tratamento robusto de permissões e erros
- Feedback visual durante gravação
- Transição suave para feature de sumarização

### Success Criteria
- [ ] User consegue iniciar/parar gravação com um tap
- [ ] Texto transcrito aparece em tempo real durante gravação
- [ ] Permissões de microfone e speech recognition solicitadas apropriadamente
- [ ] Error handling gracioso para todos os cenários
- [ ] UI responsiva com feedback visual claro
- [ ] Funciona offline para idiomas suportados (PT-BR, EN-US)
- [ ] Transição smooth para feature de sumarização
- [ ] Accessibility completo (VoiceOver, Dynamic Type)
- [ ] Performance: < 2s response time para transcription start

## All Needed Context

### Documentation & References
- file: docs/ADRs/001-speech-framework-choice.md
  why: Decisão arquitetural sobre uso de Speech Framework
- file: CLAUDE.md
  why: Guidelines de desenvolvimento e patterns do projeto
- file: docs/plans/action-plan-speech.md
  why: Plano detalhado de implementação
- url: https://www.createwithswift.com/implementing-advanced-speech-to-text-in-your-swiftui-app/
  why: Referência de implementação para Speech Framework
- url: https://developer.apple.com/documentation/speech
  why: Documentação oficial do Speech Framework

### Known Gotchas
```swift
// CRITICAL: Sempre verificar autorização antes de iniciar
let status = await SFSpeechRecognizer.requestAuthorization()
guard status == .authorized else { return }

// CRITICAL: Parar reconhecimento quando app vai para background
// CRITICAL: Limitar duração máxima (60s) para evitar timeout
// CRITICAL: Cleanup adequado de audioEngine e recognitionTask
```

### Code Examples
```swift
// Pattern para setup de SFSpeechRecognizer
private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
private let audioEngine = AVAudioEngine()
private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
private var recognitionTask: SFSpeechRecognitionTask?

// Pattern para Combine integration
@Published var transcribedText: String = ""
@Published var isRecording: Bool = false
@Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
```

## Implementation Blueprint

### Task 1: Core Service Layer
```swift
// SpeechService.swift
protocol SpeechServiceProtocol {
    var authorizationStatus: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> { get }
    var isRecording: AnyPublisher<Bool, Never> { get }
    var transcribedText: AnyPublisher<String, Never> { get }
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
    func startRecording() async throws
    func stopRecording()
}

final class SpeechService: NSObject, SpeechServiceProtocol {
    @Published private var _authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published private var _isRecording: Bool = false
    @Published private var _transcribedText: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var authorizationStatus: AnyPublisher<SFSpeechRecognizerAuthorizationStatus, Never> {
        $_authorizationStatus.eraseToAnyPublisher()
    }
    
    var isRecording: AnyPublisher<Bool, Never> {
        $_isRecording.eraseToAnyPublisher()
    }
    
    var transcribedText: AnyPublisher<String, Never> {
        $_transcribedText.eraseToAnyPublisher()
    }
}
```

### Task 2: Use Case Layer
```swift
// SpeechRecognitionUseCase.swift
protocol SpeechRecognitionUseCaseProtocol {
    func requestPermissions() async -> Bool
    func startSpeechRecognition() async throws
    func stopSpeechRecognition() async
    func getCurrentTranscription() -> String
}

final class SpeechRecognitionUseCase: SpeechRecognitionUseCaseProtocol {
    private let speechService: SpeechServiceProtocol
    
    init(speechService: SpeechServiceProtocol) {
        self.speechService = speechService
    }
    
    func requestPermissions() async -> Bool {
        let status = await speechService.requestAuthorization()
        return status == .authorized
    }
}
```

### Task 3: ViewModel Layer
```swift
// SpeechRecognitionViewModel.swift
@MainActor
final class SpeechRecognitionViewModel: ObservableObject {
    @Published var state: SpeechRecognitionState = .idle
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    @Published var permissionStatus: PermissionStatus = .notDetermined
    
    private let useCase: SpeechRecognitionUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(useCase: SpeechRecognitionUseCaseProtocol) {
        self.useCase = useCase
        setupBindings()
    }
    
    func startRecording() {
        Task {
            do {
                try await useCase.startSpeechRecognition()
            } catch {
                errorMessage = error.localizedDescription
                state = .error(AppError.speechUnavailable)
            }
        }
    }
}

enum SpeechRecognitionState: Equatable {
    case idle
    case requestingPermission
    case ready
    case recording
    case processing
    case completed(String)
    case error(AppError)
}
```

### Task 4: SwiftUI Views
```swift
// SpeechRecognitionView.swift
struct SpeechRecognitionView: View {
    @StateObject private var viewModel: SpeechRecognitionViewModel
    
    var body: some View {
        ZStack {
            // Liquid glass background
            BackgroundGradientView()
            
            VStack(spacing: 30) {
                TranscriptionDisplayView(text: viewModel.transcribedText)
                RecordButtonView(
                    isRecording: viewModel.isRecording,
                    action: { viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording() }
                )
                NavigationButtonView(text: viewModel.transcribedText)
            }
            .padding()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct RecordButtonView: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
        .accessibilityHint("Tap to toggle speech recognition")
    }
}
```

### Task 5: Error Handling & Models
```swift
// SpeechError.swift
enum SpeechError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case audioEngineError(Error)
    case recognitionFailed(Error)
    case recordingInProgress
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Acesso ao microfone e reconhecimento de fala é necessário"
        case .recognizerUnavailable:
            return "Reconhecimento de fala não está disponível neste dispositivo"
        case .audioEngineError(let error):
            return "Erro no sistema de áudio: \(error.localizedDescription)"
        case .recognitionFailed(let error):
            return "Falha no reconhecimento: \(error.localizedDescription)"
        case .recordingInProgress:
            return "Gravação já está em andamento"
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
# Run unit tests
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

# Coverage verification (target: >80%)
xcodebuild -scheme SpeechSummaryApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -enableCodeCoverage YES test
```

### Level 3: Manual Testing
```bash
# Device testing scenarios (Physical device required):
# 1. Permission flow - primeira execução
# 2. Record 10s de fala em português
# 3. Record 10s de fala em inglês  
# 4. Interrupção de chamada durante gravação
# 5. App para background durante gravação
# 6. Ambiente ruidoso
# 7. Timeout de 60s
# 8. Deny permissions e recovery
```

### Level 4: Integration Testing
```bash
# Integration with next feature
# 1. Verify transcribedText is available for summarization
# 2. Test navigation flow to summary screen
# 3. Verify state management across features
```
