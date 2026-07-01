import CoreML
import UIKit

enum SpeakerDetectionError: LocalizedError {
    case missingModel
    case invalidImage
    case predictionFailure

    var errorDescription: String? {
        switch self {
        case .missingModel:
            return "Add best.mlpackage to the app target to enable real speaker detection."
        case .invalidImage:
            return "The selected image could not be read."
        case .predictionFailure:
            return "The model failed while processing the image."
        }
    }
}

actor SpeakerDetectionService {
    private let modelName = "best"
    private let preferredOutputFeatureName = "var_1222"
    private let modelInputSize: CGFloat = 640
    private let confidenceThreshold: Float = 0.35
    private let iouThreshold: CGFloat = 0.45
    private var cachedModel: MLModel?

    func detectSpeakers(in image: UIImage) async throws -> [SpeakerObservation] {
        let model = try loadModel()
        let pixelBuffer = try makePixelBuffer(from: image)
        let input = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: pixelBuffer)])
        let prediction = try await model.prediction(from: input)

        guard let output = multiArrayOutput(from: prediction) else {
            throw SpeakerDetectionError.predictionFailure
        }

        let rawDetections = parseDetections(from: output)
        return nonMaximumSuppression(on: rawDetections)
    }

    private func loadModel() throws -> MLModel {
        if let cachedModel {
            return cachedModel
        }

        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw SpeakerDetectionError.missingModel
        }

        let model = try MLModel(contentsOf: modelURL)
        cachedModel = model
        return model
    }

    private func multiArrayOutput(from prediction: MLFeatureProvider) -> MLMultiArray? {
        if let preferred = prediction.featureValue(for: preferredOutputFeatureName)?.multiArrayValue {
            return preferred
        }

        let outputNames = prediction.featureNames.sorted()
        for name in outputNames {
            if let value = prediction.featureValue(for: name)?.multiArrayValue {
                return value
            }
        }

        return nil
    }

    private func makePixelBuffer(from image: UIImage) throws -> CVPixelBuffer {
        let size = CGSize(width: modelInputSize, height: modelInputSize)
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else {
            throw SpeakerDetectionError.invalidImage
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            throw SpeakerDetectionError.invalidImage
        }

        context.clear(CGRect(origin: .zero, size: size))
        context.interpolationQuality = .high

        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()

        return pixelBuffer
    }

    private func parseDetections(from output: MLMultiArray) -> [SpeakerObservation] {
        let pointer = output.dataPointer.bindMemory(to: Float32.self, capacity: output.count)
        let candidateCount = 8400

        var detections: [SpeakerObservation] = []
        detections.reserveCapacity(32)

        for index in 0..<candidateCount {
            let centerX = CGFloat(pointer[index])
            let centerY = CGFloat(pointer[candidateCount + index])
            let width = CGFloat(pointer[(candidateCount * 2) + index])
            let height = CGFloat(pointer[(candidateCount * 3) + index])
            let rawScore = Float(pointer[(candidateCount * 4) + index])
            let score = normalizedConfidence(from: rawScore)

            guard score >= confidenceThreshold, width > 0, height > 0 else {
                continue
            }

            let xMin = max(0, centerX - (width / 2))
            let yMin = max(0, centerY - (height / 2))
            let xMax = min(modelInputSize, centerX + (width / 2))
            let yMax = min(modelInputSize, centerY + (height / 2))

            guard xMax > xMin, yMax > yMin else {
                continue
            }

            let normalizedX = xMin / modelInputSize
            let normalizedWidth = (xMax - xMin) / modelInputSize

            // UIKit/Core Graphics use top-left origin. The rest of the app expects Vision-style bottom-left origin.
            let normalizedY = 1 - (yMax / modelInputSize)
            let normalizedHeight = (yMax - yMin) / modelInputSize

            let boundingBox = CGRect(
                x: normalizedX,
                y: normalizedY,
                width: normalizedWidth,
                height: normalizedHeight
            )

            detections.append(
                SpeakerObservation(
                    boundingBox: boundingBox,
                    confidence: score
                )
            )
        }

        return detections
    }

    private func normalizedConfidence(from rawScore: Float) -> Float {
        if (0...1).contains(rawScore) {
            return rawScore
        }

        return 1 / (1 + exp(-rawScore))
    }

    private func nonMaximumSuppression(on detections: [SpeakerObservation]) -> [SpeakerObservation] {
        let sorted = detections.sorted { $0.confidence > $1.confidence }
        var kept: [SpeakerObservation] = []

        for detection in sorted {
            let shouldKeep = kept.allSatisfy { intersectionOverUnion($0.boundingBox, detection.boundingBox) < iouThreshold }
            if shouldKeep {
                kept.append(detection)
            }
        }

        return kept
    }

    private func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else {
            return 0
        }

        let intersectionArea = intersection.width * intersection.height
        let unionArea = (lhs.width * lhs.height) + (rhs.width * rhs.height) - intersectionArea
        guard unionArea > 0 else {
            return 0
        }

        return intersectionArea / unionArea
    }
}
