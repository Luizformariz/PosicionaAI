import CoreGraphics
import Foundation

struct SpeakerObservation: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Float

    var centerX: CGFloat {
        boundingBox.midX
    }

    var centerY: CGFloat {
        boundingBox.midY
    }
}
