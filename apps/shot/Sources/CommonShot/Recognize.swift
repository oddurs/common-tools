import ShotKit
import Vision

/// The text in a shot, read on the device by Vision. No permission and no network.
enum Recognize {
    nonisolated static func text(in image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        // Code isn't prose: "correcting" an identifier into a dictionary word would break it.
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image).perform([request])
        let runs = (request.results ?? []).compactMap { observation -> TextRun? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return TextRun(text: candidate.string, x: box.minX, y: box.minY, width: box.width, height: box.height)
        }
        return TextLayout.text(from: runs)
    }
}
