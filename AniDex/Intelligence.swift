import Foundation
import UIKit
import Vision

// MARK: - Models

public struct LabelConfidence: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let confidence: Float
}

public struct PhotoAnalysis: Sendable {
    public let labels: [LabelConfidence]
    public var bestLabel: LabelConfidence? { labels.first }
}

public enum IntelligenceError: Error {
    case invalidImage
    case analysisFailed
}

// MARK: - Vision-based classifier

public actor Intelligence {
    public nonisolated static let shared = Intelligence()
    private init() {}

    // Classify an image and return top labels (on-device)
    public func analyze(image: UIImage, topK: Int = 5) async throws -> PhotoAnalysis {
        guard let cgImage = image.cgImage else { throw IntelligenceError.invalidImage }

        let request = VNClassifyImageRequest()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation, options: [:])
                    try handler.perform([request])
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        guard let results = request.results as? [VNClassificationObservation], !results.isEmpty else {
            throw IntelligenceError.analysisFailed
        }

        let labels = results.prefix(topK).map { obs in
            LabelConfidence(label: obs.identifier, confidence: obs.confidence)
        }
        return PhotoAnalysis(labels: Array(labels))
    }

    // Convenience: return only the best label
    public func bestLabel(for image: UIImage) async throws -> LabelConfidence? {
        let analysis = try await analyze(image: image, topK: 1)
        return analysis.bestLabel
    }
}

// MARK: - Helpers

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
