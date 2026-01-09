import AppKit
import Vision

// MARK: - OCR Engine
class OCREngine {
    static let shared = OCREngine()

    func extractText(from image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            completion(text.isEmpty ? nil : text)
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
