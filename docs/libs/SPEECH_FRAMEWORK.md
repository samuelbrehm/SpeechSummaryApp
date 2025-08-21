# Speech Framework - Documentação de Referência

## Overview
O Speech Framework fornece APIs para reconhecimento de fala on-device e via cloud, permitindo transcrição de áudio em texto em tempo real.

## Core Classes

### SFSpeechRecognizer
Classe principal para reconhecimento de fala.

```swift
let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))

// Verificar disponibilidade
guard let recognizer = recognizer, recognizer.isAvailable else {
    // Handle unavailable
    return
}

// Verificar autorização
let authStatus = await SFSpeechRecognizer.requestAuthorization()
guard authStatus == .authorized else {
    // Handle denied permission
    return
}
```

### SFSpeechAudioBufferRecognitionRequest
Request para reconhecimento em tempo real usando audio buffers.

```swift
let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
recognitionRequest.shouldReportPartialResults = true
recognitionRequest.requiresOnDeviceRecognition = true // Para processamento local
```

### AVAudioEngine
Usado para capturar áudio do microfone.

```swift
let audioEngine = AVAudioEngine()
let inputNode = audioEngine.inputNode
let recordingFormat = inputNode.outputFormat(forBus: 0)

inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
    recognitionRequest.append(buffer)
}

try audioEngine.start()
```

## Patterns de Implementação

### Permission Handling
```swift
func requestSpeechPermission() async -> Bool {
    let status = await SFSpeechRecognizer.requestAuthorization()
    return status == .authorized
}

func requestMicrophonePermission() async -> Bool {
    let status = await AVAudioSession.sharedInstance().requestRecordPermission()
    return status
}
```

### Real-time Recognition
```swift
func startRecording() throws {
    // Configure audio session
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    
    // Setup recognition request
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    recognitionRequest?.shouldReportPartialResults = true
    
    // Start recognition task
    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
        if let result = result {
            let transcribedText = result.bestTranscription.formattedString
            // Update UI with transcribed text
        }
        
        if error != nil || result?.isFinal == true {
            // Stop recording and cleanup
        }
    }
    
    // Setup audio engine
    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
        self.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    try audioEngine.start()
}
```

### Cleanup
```swift
func stopRecording() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    
    recognitionRequest = nil
    recognitionTask = nil
}
```

## Error Handling

### Common Errors
```swift
enum SpeechRecognitionError: Error {
    case recognizerUnavailable
    case audioEngineError
    case recognitionFailed
    case permissionDenied
    case networkUnavailable // Para cloud recognition
}
```

### Error Recovery
```swift
func handleSpeechError(_ error: Error) {
    if let sfError = error as? SFError {
        switch sfError.code {
        case .speechRecognitionRequestIsCancelled:
            // User cancelled, don't show error
            break
        case .speechRecognitionRequestTimedOut:
            // Restart recognition
            restartRecognition()
        default:
            // Show generic error
            showError("Speech recognition failed")
        }
    }
}
```

## Best Practices

### Performance
- Use `requiresOnDeviceRecognition = true` quando possível
- Limite duração da gravação (60s maximum)
- Stop recognition quando app vai para background
- Cleanup resources adequadamente

### User Experience
- Sempre solicitar permissões antes de usar
- Fornecer feedback visual durante gravação
- Mostrar partial results para melhor UX
- Handle interruptions (calls, notifications)

### Privacy
- Declare uso no Info.plist:
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`
- Preferir processamento on-device
- Não persistir dados de áudio

## Limitations

### Device Requirements
- Requires physical device (não funciona no Simulator)
- Melhor performance em devices com Neural Engine
- Some features require internet connection

### Language Support
- Nem todos idiomas suportam on-device recognition
- Quality varia por idioma
- Verificar `supportedLocales` antes de usar

### Usage Limits
- Limited recognition time per request
- Rate limiting para cloud requests
- Battery impact durante uso prolongado

## Troubleshooting

### Common Issues
1. **Recognition not starting**: Verificar permissions e device availability
2. **Poor accuracy**: Verificar quality do áudio e noise
3. **Timeout errors**: Implementar retry logic
4. **Memory leaks**: Ensure proper cleanup of audio engine

### Debug Tips
```swift
// Enable speech framework logging
speechRecognizer?.defaultTaskHint = .dictation
speechRecognizer?.supportsOnDeviceRecognition // Check support

// Monitor audio levels
inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
    let level = buffer.floatChannelData?[0][0] ?? 0
    print("Audio level: \(level)")
    recognitionRequest?.append(buffer)
}
```
