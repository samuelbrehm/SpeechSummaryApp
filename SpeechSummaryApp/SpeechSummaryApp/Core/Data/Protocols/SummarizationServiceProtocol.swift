import Foundation

@MainActor
protocol SummarizationServiceProtocol {
    var isModelLoaded: Bool { get }
    var modelInfo: ModelInfo { get }
    
    func initialize() async throws
    func summarize(text: String, maxLength: SummaryLength) async throws -> SummaryResult
    func cleanup()
}

struct ModelInfo {
    let name: String
    let version: String
    let size: Int64
    let isLoaded: Bool
    
    static let notLoaded = ModelInfo(
        name: "Unknown",
        version: "Unknown",
        size: 0,
        isLoaded: false
    )
}