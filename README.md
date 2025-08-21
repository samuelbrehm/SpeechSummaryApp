# SpeechSummaryApp

Um aplicativo iOS demonstrativo que utiliza workflows de IA para desenvolvimento mobile, implementando reconhecimento de fala e sumarização de texto usando FoundationModels.

## Características

- Reconhecimento de fala em tempo real usando Speech Framework
- Sumarização inteligente de texto usando FoundationModels
- Arquitetura MVVM com Combine e SwiftUI
- Interface moderna com liquid glass effects
- Processamento totalmente on-device para privacidade

## Requisitos

- Xcode 16 beta ou superior
- iOS 18.0+ (para FoundationModels)
- Dispositivo físico com Apple Intelligence habilitado
- macOS Sequoia para desenvolvimento

## Configuração do Projeto

### 1. Clone o repositório
```bash
git clone [URL_DO_REPOSITORIO]
cd SpeechSummaryApp
```

### 2. Abra no Xcode
```bash
open SpeechSummaryApp.xcodeproj
```

### 3. Configure o Team e Bundle ID
- Selecione seu Team de desenvolvimento
- Altere o Bundle Identifier para um único
- Habilite capabilities necessárias

### 4. Configuração do dispositivo
- Use um dispositivo físico (Simulador não suporta Speech/FoundationModels)
- Certifique-se de que Apple Intelligence está habilitado
- Verifique permissões de microfone

## Arquitetura

O projeto segue arquitetura MVVM com separação clara de responsabilidades:

```
Core/
├── Services/          # Serviços de infraestrutura
├── UseCases/         # Casos de uso da aplicação  
└── Data/             # Modelos e repositórios

Features/
├── SpeechRecognition/ # Funcionalidade de reconhecimento
└── TextSummarization/ # Funcionalidade de sumarização
```

## Funcionalidades

### Reconhecimento de Fala
- Captura áudio em tempo real
- Transcrição usando Speech Framework
- Feedback visual durante gravação
- Suporte offline para idiomas principais

### Sumarização de Texto
- Processamento usando FoundationModels
- Geração de resumos estruturados
- Interface responsiva com streaming
- Totalmente on-device

## Desenvolvimento com IA

Este projeto demonstra o uso de PRPs (Product Requirements Prompts) e Context Engineering:

- **ADRs**: Decisões arquiteturais documentadas
- **Context Engineering**: Documentação estruturada para IA
- **PRPs**: Requisitos executáveis para implementação
- **State Management**: Controle de estado do desenvolvimento

## Comandos de Desenvolvimento

```bash
# Build
xcodebuild -scheme SpeechSummaryApp build

# Testes
xcodebuild -scheme SpeechSummaryApp test

# Linting (SwiftLint)
swiftlint

# Formatação (SwiftFormat)  
swiftformat .
```

## Estrutura de Documentação

- `docs/ADRs/` - Architecture Decision Records
- `docs/plans/` - Planos de ação e tasks
- `docs/prompts/` - Templates de prompts para IA
- `PRPs/` - Product Requirements Prompts
- `state.local.md` - Estado atual do desenvolvimento

## Contribuição

1. Leia a documentação em `docs/`
2. Verifique `state.local.md` para contexto atual
3. Use PRPs para novas funcionalidades
4. Siga guidelines em `CLAUDE.md`
