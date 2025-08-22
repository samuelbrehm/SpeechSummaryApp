import Foundation
import CoreML
import NaturalLanguage
import Combine
import os.log

@MainActor
final class CoreMLSummarizationService: SummarizationServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private var model: MLModel?
    private let modelConfiguration: MLModelConfiguration
    private let textPreprocessor: TextPreprocessor
    private let logger = Logger(subsystem: "com.speechsummaryapp.summarization", category: "service")
    
    @Published private(set) var isModelLoaded: Bool = false
    @Published private(set) var modelInfo: ModelInfo = .notLoaded
    
    private let minTextLength: Int = 50
    private let maxTextLength: Int = 2000
    
    // MARK: - Initialization
    
    init(modelName: String = "DistilBARTSummarization") {
        self.modelConfiguration = MLModelConfiguration()
        self.modelConfiguration.computeUnits = .cpuAndNeuralEngine
        self.modelConfiguration.allowLowPrecisionAccumulationOnGPU = true
        
        self.textPreprocessor = TextPreprocessor()
        
        logger.info("SummarizationService initialized with model: \(modelName)")
    }
    
    // MARK: - Public Methods
    
    func initialize() async throws {
        guard !isModelLoaded else {
            logger.debug("Model already loaded, skipping initialization")
            return
        }
        
        logger.info("Starting model initialization...")
        let startTime = Date()
        
        do {
            // For demonstration purposes, we'll simulate model loading
            // In a real implementation, this would load the actual Core ML model
            try await simulateModelLoading()
            
            let loadTime = Date().timeIntervalSince(startTime)
            logger.info("Model loaded successfully in \(loadTime, privacy: .public)s")
            
            isModelLoaded = true
            modelInfo = ModelInfo(
                name: "DistilBART Summarization (Mock)",
                version: "1.0.0",
                size: 42_000_000, // ~42MB
                isLoaded: true
            )
            
        } catch {
            logger.error("Model initialization failed: \(error.localizedDescription)")
            throw SummarizationError.modelLoadingFailed(error)
        }
    }
    
    func summarize(text: String, maxLength: SummaryLength) async throws -> SummaryResult {
        guard isModelLoaded else {
            throw SummarizationError.modelNotLoaded
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizationError.invalidInput
        }
        
        guard text.count >= minTextLength else {
            throw SummarizationError.textTooShort
        }
        
        guard text.count <= maxTextLength else {
            throw SummarizationError.textTooLong
        }
        
        logger.info("Starting summarization for text of length: \(text.count)")
        let startTime = Date()
        
        do {
            // Preprocess the input text
            let preprocessedInput = try textPreprocessor.preprocess(
                text: text,
                maxTokens: 512
            )
            
            // Simulate model inference
            let summary = try await performInference(
                input: preprocessedInput,
                maxLength: maxLength
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            logger.info("Summarization completed in \(processingTime, privacy: .public)s")
            
            return SummaryResult(
                originalText: text,
                summary: summary.text,
                processingTime: processingTime,
                confidence: summary.confidence,
                summaryLength: maxLength
            )
            
        } catch {
            logger.error("Summarization failed: \(error.localizedDescription)")
            throw SummarizationError.processingFailed(error)
        }
    }
    
    func cleanup() {
        logger.info("Cleaning up summarization service")
        model = nil
        isModelLoaded = false
        modelInfo = .notLoaded
    }
    
    // MARK: - Private Methods
    
    private func simulateModelLoading() async throws {
        // Simulate model loading time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // In a real implementation, this would be:
        /*
        guard let modelURL = Bundle.main.url(
            forResource: "DistilBARTSummarization",
            withExtension: "mlmodelc"
        ) else {
            throw SummarizationError.modelNotFound
        }
        
        self.model = try MLModel(
            contentsOf: modelURL,
            configuration: modelConfiguration
        )
        */
    }
    
    private func performInference(
        input: TextPreprocessor.PreprocessedInput,
        maxLength: SummaryLength
    ) async throws -> TextPreprocessor.PostprocessedOutput {
        
        // Simulate processing time based on text length
        let processingTime = min(max(0.5, Double(input.tokenCount) / 200.0), 3.0)
        try await Task.sleep(nanoseconds: UInt64(processingTime * 1_000_000_000))
        
        // In a real implementation, this would be:
        /*
        guard let model = model else {
            throw SummarizationError.modelNotLoaded
        }
        
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": MLMultiArray(input.inputIds),
            "attention_mask": MLMultiArray(input.attentionMask)
        ])
        
        let output = try model.prediction(from: input)
        
        return try textPreprocessor.postprocess(
            output: output,
            maxLength: maxLength.tokenCount
        )
        */
        
        // Mock implementation for demonstration
        return try textPreprocessor.generateMockSummary(
            originalText: input.originalText,
            maxLength: maxLength
        )
    }
}

// MARK: - Text Preprocessor

final class TextPreprocessor {
    
    private let tokenizer: NLTokenizer
    private let logger = Logger(subsystem: "com.speechsummaryapp.summarization", category: "preprocessor")
    
    struct PreprocessedInput {
        let inputIds: [Int32]
        let attentionMask: [Int32]
        let tokenCount: Int
        let originalText: String
    }
    
    struct PostprocessedOutput {
        let text: String
        let confidence: Float?
    }
    
    init() {
        self.tokenizer = NLTokenizer(unit: .word)
    }
    
    func preprocess(text: String, maxTokens: Int) throws -> PreprocessedInput {
        let cleanedText = cleanText(text)
        
        tokenizer.string = cleanedText
        let tokenRanges = tokenizer.tokens(for: cleanedText.startIndex..<cleanedText.endIndex)
        let tokens = tokenRanges.map { String(cleanedText[$0]) }
        
        let tokenIds = convertToTokenIds(tokens: tokens)
        let truncatedIds = Array(tokenIds.prefix(maxTokens))
        let attentionMask = Array(repeating: Int32(1), count: truncatedIds.count)
        
        logger.debug("Preprocessed text into \(truncatedIds.count) tokens")
        
        return PreprocessedInput(
            inputIds: truncatedIds,
            attentionMask: attentionMask,
            tokenCount: truncatedIds.count,
            originalText: cleanedText
        )
    }
    
    func generateMockSummary(
        originalText: String,
        maxLength: SummaryLength
    ) throws -> PostprocessedOutput {
        
        guard !originalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return PostprocessedOutput(text: "Texto insuficiente para sumarização.", confidence: 0.3)
        }
        
        // Generate abstractive summary with topics
        let summary = try generateAbstractiveSummary(
            originalText: originalText,
            targetLength: maxLength
        )
        
        return PostprocessedOutput(
            text: summary.text,
            confidence: summary.confidence
        )
    }
    
    // MARK: - Abstractive Summarization
    
    private func generateAbstractiveSummary(
        originalText: String,
        targetLength: SummaryLength
    ) throws -> (text: String, confidence: Float) {
        
        // Handle very short texts
        if originalText.count < 30 {
            return generateShortTextSummary(originalText: originalText)
        }
        
        // Extract key concepts and topics
        let topics = extractMainTopics(from: originalText)
        let keyEntities = extractKeyEntities(from: originalText)
        let actionVerbs = extractActionVerbs(from: originalText)
        
        // Ensure minimum 2 topics - create fallback topics if needed
        var selectedTopics = Array(topics.prefix(targetLength == .short ? 2 : targetLength == .medium ? 3 : 4))
        
        if selectedTopics.count < 2 {
            selectedTopics = createFallbackTopics(from: originalText, existing: selectedTopics)
        }
        
        // Create abstractive summary based on topics and entities
        let summaryText = createAbstractiveText(
            topics: selectedTopics,
            entities: keyEntities,
            actions: actionVerbs,
            originalLength: originalText.count,
            targetLength: targetLength
        )
        
        // Calculate confidence based on topic coverage and content quality
        let confidence = calculateAbstractiveConfidence(
            topics: selectedTopics,
            entities: keyEntities,
            originalLength: originalText.count,
            summaryLength: summaryText.count
        )
        
        return (text: summaryText, confidence: confidence)
    }
    
    private func generateShortTextSummary(originalText: String) -> (text: String, confidence: Float) {
        let words = originalText.components(separatedBy: .punctuationCharacters.union(.whitespacesAndNewlines))
            .filter { !$0.isEmpty && $0.count > 2 && !isStopWord($0.lowercased()) }
        
        if words.count >= 2 {
            let topic1 = "Tópico sobre \(words[0].lowercased())"
            let topic2 = words.count > 1 ? "Discussão de \(words[1].lowercased())" : "Conceito relacionado"
            
            let summary = "O conteúdo aborda 2 temas principais. Primeiro, há \(topic1) que apresenta pontos relevantes. Além disso, apresenta \(topic2) que discute aspectos importantes."
            
            return (text: summary, confidence: 0.7)
        } else {
            return (text: "O conteúdo aborda 2 temas principais. Primeiro, há tópico sobre comunicação que apresenta pontos relevantes. Além disso, apresenta discussão sobre informação que discute aspectos importantes.", confidence: 0.5)
        }
    }
    
    private func createFallbackTopics(from text: String, existing: [String]) -> [String] {
        var topics = existing
        let words = text.components(separatedBy: .punctuationCharacters.union(.whitespacesAndNewlines))
            .filter { !$0.isEmpty && $0.count > 3 && !isStopWord($0.lowercased()) }
        
        // Create generic topics based on available words
        let fallbackPatterns = [
            "Tópico sobre comunicação",
            "Discussão de informação", 
            "Conceito sobre processo",
            "Tópico relacionado a desenvolvimento"
        ]
        
        // Use words from text if available, otherwise use generic patterns
        for i in topics.count..<2 {
            if i < words.count {
                topics.append("Tópico sobre \(words[i].lowercased())")
            } else if i < fallbackPatterns.count {
                topics.append(fallbackPatterns[i])
            }
        }
        
        // Ensure we always have at least 2 topics
        while topics.count < 2 {
            topics.append("Tópico sobre \(topics.count == 0 ? "comunicação" : "informação")")
        }
        
        return topics
    }
    
    private func extractMainTopics(from text: String) -> [String] {
        let keywords = extractKeywords(from: text)
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        // Group keywords by semantic similarity and frequency
        var topicClusters: [String: [String]] = [:]
        
        for keyword in keywords {
            let cluster = findTopicCluster(for: keyword, in: sentences)
            if let existingCluster = topicClusters[cluster] {
                topicClusters[cluster] = existingCluster + [keyword]
            } else {
                topicClusters[cluster] = [keyword]
            }
        }
        
        // Generate topic descriptions
        return topicClusters.sorted { $0.value.count > $1.value.count }
            .prefix(6)
            .map { cluster, keywords in
                generateTopicDescription(cluster: cluster, keywords: keywords)
            }
    }
    
    private func findTopicCluster(for keyword: String, in sentences: [String]) -> String {
        // Find the sentence that contains this keyword and extract context
        for sentence in sentences {
            if sentence.lowercased().contains(keyword.lowercased()) {
                let words = sentence.components(separatedBy: .punctuationCharacters.union(.whitespacesAndNewlines))
                    .filter { !$0.isEmpty && $0.count > 2 }
                
                // Return the most significant word near the keyword as cluster identifier
                if let keywordIndex = words.firstIndex(where: { $0.lowercased().contains(keyword.lowercased()) }) {
                    let contextStart = max(0, keywordIndex - 2)
                    let contextEnd = min(words.count, keywordIndex + 3)
                    let context = words[contextStart..<contextEnd].joined(separator: "_")
                    return context.lowercased()
                }
            }
        }
        return keyword.lowercased()
    }
    
    private func generateTopicDescription(cluster: String, keywords: [String]) -> String {
        // Create a topic description that doesn't copy exact text
        let primaryKeyword = keywords.first ?? "assunto"
        let secondaryKeywords = Array(keywords.dropFirst().prefix(2))
        
        if secondaryKeywords.isEmpty {
            return "Tópico sobre \(primaryKeyword)"
        } else {
            return "Discussão de \(primaryKeyword) relacionado a \(secondaryKeywords.joined(separator: " e "))"
        }
    }
    
    private func extractKeyEntities(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType,
                            options: options) { tag, tokenRange in
            
            if let tag = tag, tag == .personalName || tag == .placeName || tag == .organizationName {
                let entity = String(text[tokenRange])
                if entity.count > 2 && !entities.contains(entity) {
                    entities.append(entity)
                }
            }
            return true
        }
        
        return Array(entities.prefix(5))
    }
    
    private func extractActionVerbs(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var verbs: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, tokenRange in
            
            if let tag = tag, tag == .verb {
                let verb = String(text[tokenRange]).lowercased()
                if verb.count > 3 && !isStopWord(verb) && !verbs.contains(verb) {
                    verbs.append(verb)
                }
            }
            return true
        }
        
        return Array(verbs.prefix(8))
    }
    
    private func createAbstractiveText(
        topics: [String],
        entities: [String],
        actions: [String],
        originalLength: Int,
        targetLength: SummaryLength
    ) -> String {
        
        var summaryParts: [String] = []
        
        // Generate introduction
        let intro = generateIntroduction(topics: topics, entities: entities)
        summaryParts.append(intro)
        
        // Generate topic-based content
        for (index, topic) in topics.enumerated() {
            let topicSentence = generateTopicSentence(
                topic: topic,
                entities: entities,
                actions: actions,
                index: index
            )
            summaryParts.append(topicSentence)
        }
        
        // Generate conclusion if needed
        if targetLength != .short && topics.count > 2 {
            let conclusion = generateConclusion(topics: topics, actions: actions)
            summaryParts.append(conclusion)
        }
        
        return summaryParts.joined(separator: ". ") + "."
    }
    
    private func generateIntroduction(topics: [String], entities: [String]) -> String {
        let entityContext = entities.isEmpty ? "" : " envolvendo \(entities.prefix(2).joined(separator: " e "))"
        return "O conteúdo aborda \(topics.count) temas principais\(entityContext)"
    }
    
    private func generateTopicSentence(topic: String, entities: [String], actions: [String], index: Int) -> String {
        let transitions = ["Primeiro,", "Além disso,", "Também,", "Adicionalmente,", "Por fim,"]
        let transition = index < transitions.count ? transitions[index] + " " : ""
        
        let action = actions.randomElement() ?? "discute"
        let entity = entities.randomElement()
        
        if let entity = entity {
            return "\(transition)há \(topic) que \(action) aspectos relacionados a \(entity)"
        } else {
            return "\(transition)apresenta \(topic) que \(action) pontos relevantes"
        }
    }
    
    private func generateConclusion(topics: [String], actions: [String]) -> String {
        let action = actions.randomElement() ?? "aborda"
        return "Em resumo, o texto \(action) \(topics.count) áreas temáticas distintas"
    }
    
    private func calculateAbstractiveConfidence(
        topics: [String],
        entities: [String],
        originalLength: Int,
        summaryLength: Int
    ) -> Float {
        
        let topicScore = min(1.0, Double(topics.count) / 3.0)
        let entityScore = min(1.0, Double(entities.count) / 2.0)
        let lengthScore = originalLength > 100 ? 0.9 : 0.7
        
        let finalScore = (topicScore * 0.5 + entityScore * 0.3 + lengthScore * 0.2)
        return Float(max(0.6, min(0.95, finalScore)))
    }
    
    // MARK: - Shared Helper Methods
    
    private func extractKeywords(from text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: Set<String> = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, tokenRange in
            
            if let tag = tag, tag == .noun || tag == .verb || tag == .adjective {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 3 && !isStopWord(word) {
                    keywords.insert(word)
                }
            }
            return true
        }
        
        return keywords
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "para", "com", "por", "em", "de", "da", "do", "das", "dos", "uma", "um", "o", "a", "os", "as",
            "que", "não", "mais", "muito", "ser", "ter", "fazer", "estar", "ir", "ver", "dar", "saber",
            "falar", "dizer", "quando", "onde", "como", "porque", "então", "mas", "também", "ainda",
            "the", "be", "to", "of", "and", "a", "in", "that", "have", "i", "it", "for", "not", "on",
            "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we"
        ]
        return stopWords.contains(word)
    }
    
    // MARK: - Private Methods
    
    private func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
    
    private func convertToTokenIds(tokens: [String]) -> [Int32] {
        // Simplified tokenization for demonstration
        return tokens.enumerated().map { index, token in
            Int32((token.hash + index) % 30000)
        }
    }
}
