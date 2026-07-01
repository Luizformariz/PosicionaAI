import Foundation

struct SpeakerRecommendationEngine {
    func makeResult(from observations: [SpeakerObservation]) -> AnalysisResult {
        guard !observations.isEmpty else {
            return AnalysisResult(
                title: "No speakers detected",
                summary: "The model did not find any speakers with enough confidence in this photo.",
                detectionSummary: "0 speakers detected",
                speakerDetails: [],
                recommendations: [
                    "Try a brighter photo with a wider view of the room.",
                    "Keep the speakers fully visible and avoid heavy blur or glare."
                ]
            )
        }

        var recommendations: [String] = []
        let sortedByHorizontalPosition = observations.sorted { $0.centerX < $1.centerX }
        var speakerDetails: [AnalysisSpeakerDetail] = []

        for (index, observation) in sortedByHorizontalPosition.enumerated() {
            let speakerLabel = label(for: index, totalCount: sortedByHorizontalPosition.count)
            let confidenceText = "\(Int(observation.confidence * 100))% confidence"
            var detailNotes: [String] = []

            if observation.centerX < 0.18 {
                recommendations.append("\(speakerLabel) appears very close to the left side of the room. Pulling it inward can improve stereo balance.")
                detailNotes.append("Sits very close to the left wall.")
            } else if observation.centerX > 0.82 {
                recommendations.append("\(speakerLabel) appears very close to the right side of the room. A little more breathing room may help balance and imaging.")
                detailNotes.append("Sits very close to the right wall.")
            }

            if observation.centerY < 0.18 {
                recommendations.append("\(speakerLabel) looks low in the scene. If the tweeter sits below ear level, raising it can improve clarity.")
                detailNotes.append("Looks low in the frame.")
            }

            if observation.centerX < 0.15 && observation.centerY < 0.20 {
                recommendations.append("\(speakerLabel) may be sitting in a corner. Corners often exaggerate bass and reduce accuracy.")
                detailNotes.append("May be positioned in a corner.")
            }

            if observation.centerX > 0.85 && observation.centerY < 0.20 {
                recommendations.append("\(speakerLabel) may be sitting in a corner. Moving it away from that boundary can reduce boomy low end.")
                detailNotes.append("May be positioned in a corner.")
            }

            if detailNotes.isEmpty {
                detailNotes.append("Looks reasonably placed in this first-pass photo.")
            }

            speakerDetails.append(
                AnalysisSpeakerDetail(
                    title: speakerLabel,
                    summary: detailNotes.joined(separator: " "),
                    confidenceText: confidenceText
                )
            )
        }

        if sortedByHorizontalPosition.count >= 2 {
            let positions = sortedByHorizontalPosition.map(\.centerX)
            if let first = positions.first, let last = positions.last, last - first < 0.28 {
                recommendations.append("The speakers appear very close together. More spacing usually improves stereo width and separation.")
            }

            let leftDistance = positions.first ?? 0
            let rightDistance = 1 - (positions.last ?? 1)
            if abs(leftDistance - rightDistance) > 0.18 {
                recommendations.append("Left and right placement looks uneven. A more symmetrical setup usually creates a stronger center image.")
            }
        }

        if recommendations.isEmpty {
            recommendations.append("This layout looks reasonable for a quick first-pass check.")
            recommendations.append("Keep both speakers aimed toward the listening area and avoid blocking the front with furniture.")
        }

        let confidenceAverage = observations.map(\.confidence).reduce(0, +) / Float(observations.count)
        let summary = summaryText(for: sortedByHorizontalPosition.count, averageConfidence: confidenceAverage)
        let detectionSummary = detectionSummaryText(for: sortedByHorizontalPosition.count)

        return AnalysisResult(
            title: "Placement analysis ready",
            summary: summary,
            detectionSummary: detectionSummary,
            speakerDetails: speakerDetails,
            recommendations: recommendations
        )
    }

    private func label(for index: Int, totalCount: Int) -> String {
        switch totalCount {
        case 1:
            return "Detected speaker"
        case 2:
            return index == 0 ? "Left speaker" : "Right speaker"
        default:
            if index == 0 {
                return "Left speaker"
            } else if index == totalCount - 1 {
                return "Right speaker"
            } else {
                return "Additional speaker \(index)"
            }
        }
    }

    private func summaryText(for count: Int, averageConfidence: Float) -> String {
        if count == 1 {
            return "Detected one speaker with an average confidence of about \(Int(averageConfidence * 100))%."
        }

        return "Detected \(count) speakers with an average confidence of about \(Int(averageConfidence * 100))%."
    }

    private func detectionSummaryText(for count: Int) -> String {
        if count == 1 {
            return "1 speaker detected"
        }

        return "\(count) speakers detected"
    }
}
