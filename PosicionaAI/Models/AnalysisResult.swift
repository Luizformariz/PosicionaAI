import Foundation

struct AnalysisSpeakerDetail: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let confidenceText: String
}

struct AnalysisResult: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let detectionSummary: String
    let speakerDetails: [AnalysisSpeakerDetail]
    let recommendations: [String]
}
