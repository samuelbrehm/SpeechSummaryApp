import SwiftUI

struct SummarizationView: View {
    @StateObject private var viewModel = SummarizationViewModel()
    let transcriptionResult: TranscriptionResult?
    
    init(transcriptionResult: TranscriptionResult? = nil) {
        self.transcriptionResult = transcriptionResult
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if viewModel.isModelLoaded {
                        contentSection
                    } else {
                        initializationSection
                    }
                    
                    // Add some bottom padding to ensure content isn't cut off
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(minHeight: geometry.size.height - 100)
            }
        }
        .background(BackgroundGradientView())
        .navigationTitle("Text Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.initialize()
            
            if let transcription = transcriptionResult {
                await viewModel.summarizeTranscription(transcription)
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.blue.gradient)
            
            Text("AI Text Summarization")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Generate intelligent summaries of your transcribed speech")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var contentSection: some View {
        VStack(spacing: 20) {
            summaryControlsSection
            
            if viewModel.state.isProcessing {
                processingView
            } else if let result = viewModel.summaryResult {
                summaryResultView(result: result)
            } else if let transcription = transcriptionResult {
                originalTextView(text: transcription.text)
                summarizeButton
            } else {
                emptyStateView
            }
            
            if let error = viewModel.errorMessage {
                errorView(message: error)
            }
        }
    }
    
    private var initializationSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading AI Model...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .liquidGlassCard()
    }
    
    private var summaryControlsSection: some View {
        VStack(spacing: 16) {
            Text("Summary Length")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("Summary Length", selection: $viewModel.selectedSummaryLength) {
                ForEach(SummaryLength.allCases, id: \.self) { length in
                    Text(length.displayName)
                        .tag(length)
                }
            }
            .pickerStyle(.segmented)
        }
        .liquidGlassCard()
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(viewModel.processingProgress)
                .font(.headline)
                .foregroundStyle(.blue)
            
            Text("This may take a few seconds...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .liquidGlassCard()
    }
    
    private func originalTextView(text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Original Text", systemImage: "doc.text")
                .font(.headline)
                .foregroundStyle(.blue)
            
            ScrollView {
                Text(text)
                    .font(.body)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .frame(maxHeight: 200)
        }
        .liquidGlassCard()
    }
    
    private func summaryResultView(result: SummaryResult) -> some View {
        VStack(spacing: 20) {
            // Original Text Section
            originalTextCard(result: result)
            
            // Summary Section
            summaryCard(result: result)
            
            // Metadata Section
            metadataCard(result: result)
            
            // Action Buttons
            actionButtonsSection(result: result)
        }
    }
    
    private func originalTextCard(result: SummaryResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Original Text", systemImage: "doc.text")
                .font(.headline)
                .foregroundStyle(.gray)
            
            ScrollView {
                Text(result.originalText)
                    .font(.body)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .frame(maxHeight: 150)
        }
        .liquidGlassCard()
    }
    
    private func summaryCard(result: SummaryResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.blue.gradient)
                
                Spacer()
                
                Text(result.summaryLength.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            Text(result.summary)
                .font(.body)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
        .liquidGlassCard()
    }
    
    private func metadataCard(result: SummaryResult) -> some View {
        HStack(spacing: 20) {
            metadataItem(
                icon: "clock",
                label: "Processing Time",
                value: String(format: "%.2fs", result.processingTime)
            )
            
            Divider()
                .frame(height: 30)
            
            if let confidence = result.confidence {
                metadataItem(
                    icon: "checkmark.seal",
                    label: "Confidence",
                    value: String(format: "%.0f%%", confidence * 100)
                )
            }
            
            Divider()
                .frame(height: 30)
            
            metadataItem(
                icon: "calendar",
                label: "Generated",
                value: DateFormatter.localizedString(
                    from: result.processedAt,
                    dateStyle: .none,
                    timeStyle: .short
                )
            )
        }
        .liquidGlassCard()
    }
    
    private func metadataItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func actionButtonsSection(result: SummaryResult) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.retryLastOperation()
                }
            }) {
                Label("Regenerate", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.state.isProcessing)
            
            Button(action: {
                if let exportText = viewModel.exportSummary() {
                    UIPasteboard.general.string = exportText
                }
            }) {
                Label("Copy All", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var summarizeButton: some View {
        Button(action: {
            if let transcription = transcriptionResult {
                Task {
                    await viewModel.summarizeTranscription(transcription)
                }
            }
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Summary")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canSummarize)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Text to Summarize")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please record some speech first to generate a summary")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .liquidGlassCard()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)
            
            Text("Error")
                .font(.headline)
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button("Dismiss") {
                    viewModel.resetState()
                }
                .buttonStyle(.bordered)
                
                Button("Try Again") {
                    Task {
                        await viewModel.retryLastOperation()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .liquidGlassCard()
    }
}

// MARK: - Liquid Glass Card Modifier

extension View {
    func liquidGlassCard() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Preview

#Preview("Empty State") {
    NavigationView {
        SummarizationView()
    }
}

#Preview("With Transcription") {
    NavigationView {
        SummarizationView(
            transcriptionResult: TranscriptionResult(
                text: "This is a sample transcription that needs to be summarized. It contains multiple sentences with meaningful content that can be processed by the AI summarization model.",
                confidence: 0.95
            )
        )
    }
}

#Preview("With Result") {
    NavigationView {
        SummarizationView()
    }
    .environmentObject(SummarizationViewModel.previewWithResult)
}