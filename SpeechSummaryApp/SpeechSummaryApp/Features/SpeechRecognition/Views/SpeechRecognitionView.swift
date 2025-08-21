//
//  SpeechRecognitionView.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import SwiftUI

struct SpeechRecognitionView: View {
    @StateObject private var viewModel: SpeechRecognitionViewModel
    
    init(viewModel: SpeechRecognitionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            BackgroundGradientView()
            
            VStack(spacing: 40) {
                headerView
                
                TranscriptionDisplayView(
                    text: viewModel.transcribedText,
                    isRecording: viewModel.isRecording
                )
                
                Spacer()
                
                controlsView
                
                Spacer()
            }
            .padding()
        }
        .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { 
                viewModel.errorMessage = nil 
            }
            
            if viewModel.permissionStatus == .denied {
                Button("Configurações") {
                    openSettings()
                }
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: .constant(viewModel.state == .idle && viewModel.permissionStatus == .notDetermined)) {
            PermissionRequestView {
                viewModel.requestPermissions()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Reconhecimento de Fala")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Toque no botão para começar a transcrever")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 30) {
            RecordButtonView(
                isRecording: viewModel.isRecording,
                action: viewModel.toggleRecording
            )
            
            HStack(spacing: 20) {
                if !viewModel.transcribedText.isEmpty {
                    Button("Limpar") {
                        viewModel.clearTranscription()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                NavigationButtonView(text: viewModel.transcribedText) {
                    // TODO: Navigate to summarization
                }
            }
            
            stateIndicator
        }
    }
    
    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.state {
        case .idle:
            Text("Pronto para começar")
                .foregroundColor(.secondary)
        case .requestingPermission:
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Solicitando permissões...")
            }
            .foregroundColor(.secondary)
        case .ready:
            Text("Toque para gravar")
                .foregroundColor(.blue)
        case .recording:
            HStack {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.5)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isRecording)
                Text("Gravando...")
            }
            .foregroundColor(.red)
        case .processing:
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Processando...")
            }
            .foregroundColor(.orange)
        case .completed(let text):
            Text("Transcrição concluída (\(text.count) caracteres)")
                .foregroundColor(.green)
        case .error:
            Text("Erro na transcrição")
                .foregroundColor(.red)
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct PermissionRequestView: View {
    let onRequestPermissions: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Permissões Necessárias")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Este app precisa de acesso ao microfone e ao reconhecimento de fala para funcionar.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                PermissionItem(
                    icon: "mic.fill",
                    title: "Microfone",
                    description: "Para capturar sua voz"
                )
                
                PermissionItem(
                    icon: "waveform",
                    title: "Reconhecimento de Fala",
                    description: "Para converter fala em texto"
                )
            }
            
            Button("Continuar") {
                onRequestPermissions()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            .padding(.top)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}

struct PermissionItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}