import Combine
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class PhotoAnalysisViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var analysisResult: AnalysisResult?
    @Published var statusMessage: String?
    @Published var isAnalyzing = false

    var canAnalyze: Bool {
        selectedImage != nil && !isAnalyzing
    }

    private let detector = SpeakerDetectionService()
    private let recommendationEngine = SpeakerRecommendationEngine()

    init(previewImage: UIImage? = nil) {
        selectedImage = previewImage
        if previewImage != nil {
            statusMessage = "Preview image loaded."
        }
    }

    func loadSelectedPhoto() async {
        guard let selectedItem else {
            return
        }

        do {
            statusMessage = "Loading photo..."
            analysisResult = nil

            guard let data = try await selectedItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                statusMessage = "We could not open that photo."
                selectedImage = nil
                return
            }

            selectedImage = image
            statusMessage = "Photo ready for analysis."
        } catch {
            statusMessage = "Failed to load the selected photo."
            selectedImage = nil
        }
    }

    func analyzePhoto() async {
        guard let selectedImage else {
            statusMessage = "Choose a photo before starting analysis."
            return
        }

        isAnalyzing = true
        statusMessage = "Running speaker detection..."
        defer { isAnalyzing = false }

        do {
            let observations = try await detector.detectSpeakers(in: selectedImage)
            analysisResult = recommendationEngine.makeResult(from: observations)
            statusMessage = "Analysis complete."
        } catch let error as LocalizedError {
            analysisResult = AnalysisResult(
                title: "Analysis failed",
                summary: error.errorDescription ?? "The app could not analyze this photo.",
                detectionSummary: "Analysis unavailable",
                speakerDetails: [],
                recommendations: [
                    "Make sure best.mlpackage is included in the PosicionaAI target.",
                    "If the issue persists, we can review the model integration together."
                ]
            )
            statusMessage = "Detection could not be completed."
        } catch {
            analysisResult = AnalysisResult(
                title: "Analysis failed",
                summary: "An unexpected error happened during analysis.",
                detectionSummary: "Analysis unavailable",
                speakerDetails: [],
                recommendations: [
                    "Try a different image and run the scan again.",
                    "If the issue persists, we can inspect the model pipeline next."
                ]
            )
            statusMessage = "Unexpected analysis error."
        }
    }
}
