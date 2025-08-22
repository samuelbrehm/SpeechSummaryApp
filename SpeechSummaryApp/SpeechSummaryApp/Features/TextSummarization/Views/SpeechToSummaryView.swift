import SwiftUI

struct SpeechToSummaryView: View {
    @StateObject private var speechViewModel = SpeechRecognitionViewModel(
        useCase: SpeechRecognitionUseCase(speechService: SpeechService())
    )
    @StateObject private var summaryViewModel = SummarizationViewModel()
    @State private var showingSummaryView = false
    @State private var currentTranscription: TranscriptionResult?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        speechRecognitionSection
                        
                        if let transcription = currentTranscription {
                            transcriptionResultSection(transcription: transcription)
                            
                            if summaryViewModel.isModelLoaded {
                                summarizationSection
                            }
                        }
                        
                        // Add minimum height to ensure scroll works properly
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .background(BackgroundGradientView())
            .navigationTitle("Speech Summary")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSummaryView) {
                if let transcription = currentTranscription {
                    NavigationView {
                        SummarizationView(transcriptionResult: transcription)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Cancel") {
                                        showingSummaryView = false
                                    }
                                }
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingSummaryView = false
                                    }
                                }
                            }
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .task {
            await summaryViewModel.initialize()
        }
        .onChange(of: speechViewModel.transcribedText) { _, newText in
            if !newText.isEmpty {
                currentTranscription = TranscriptionResult(
                    text: newText,
                    confidence: 0.9, // Default confidence
                    isFinal: true
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mic.circle")
                    .font(.system(size: 30))
                    .foregroundStyle(.blue.gradient)
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundStyle(.green.gradient)
            }
            
            Text("Speech to Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Record speech and get an AI-generated summary")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var speechRecognitionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "mic")
                    .foregroundStyle(.blue)
                
                Text("Step 1: Record Speech")
                    .font(.headline)
                
                Spacer()
                
                if speechViewModel.isRecording {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            SpeechRecognitionView(viewModel: speechViewModel) {
                if currentTranscription != nil {
                    showingSummaryView = true
                }
            }
        }
        .liquidGlassCard()
    }
    
    private func transcriptionResultSection(transcription: TranscriptionResult) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundStyle(.green)
                
                Text("Step 2: Speech Transcribed")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            
            ScrollView {
                Text(transcription.text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(6)
            }
            .frame(maxHeight: 120)
            
            HStack {
                Label(
                    "Confidence: \(Int(transcription.confidence * 100))%",
                    systemImage: "checkmark.seal"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(
                    "Generated: \(DateFormatter.localizedString(from: transcription.timestamp, dateStyle: .none, timeStyle: .short))",
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .liquidGlassCard()
    }
    
    private var summarizationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                
                Text("Step 3: Generate Summary")
                    .font(.headline)
                
                Spacer()
                
                if summaryViewModel.summaryResult != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            if let summaryResult = summaryViewModel.summaryResult {
                // Show summary preview
                summaryPreviewSection(result: summaryResult)
            } else if summaryViewModel.state.isProcessing {
                processingIndicator
            } else {
                summaryControls
            }
        }
        .liquidGlassCard()
    }
    
    private func summaryPreviewSection(result: SummaryResult) -> some View {
        VStack(spacing: 12) {
            Text("Summary Preview")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(result.summary)
                .font(.body)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button("View Full Summary") {
                    showingSummaryView = true
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Regenerate") {
                    if let transcription = currentTranscription {
                        Task {
                            await summaryViewModel.summarizeTranscription(transcription)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(summaryViewModel.state.isProcessing)
            }
        }
    }
    
    private var processingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(summaryViewModel.processingProgress)
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
    
    private var summaryControls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Summary Length:")
                    .font(.subheadline)
                
                Spacer()
                
                Picker("Length", selection: $summaryViewModel.selectedSummaryLength) {
                    ForEach(SummaryLength.allCases, id: \.self) { length in
                        Text(length.displayName).tag(length)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Button(action: {
                if let transcription = currentTranscription {
                    Task {
                        await summaryViewModel.summarizeTranscription(transcription)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate AI Summary")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!summaryViewModel.canSummarize || currentTranscription == nil)
        }
    }
}

// MARK: - Preview

#Preview {
    SpeechToSummaryView()
}