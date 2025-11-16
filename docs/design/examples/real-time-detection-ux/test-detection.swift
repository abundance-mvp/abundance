#!/usr/bin/env swift

import Foundation
import CoreML
import Vision
import AppKit

// Save the base64 image data (will be passed as argument)
let imagePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "test-image.jpg"

guard let image = NSImage(contentsOfFile: imagePath) else {
    print("❌ Failed to load image from: \(imagePath)")
    exit(1)
}

guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("❌ Failed to convert to CGImage")
    exit(1)
}

print("📸 Image loaded: \(cgImage.width)x\(cgImage.height)")
print("")

// Load YOLOv11n model
guard let modelURL = Bundle.main.url(forResource: "Sources/VisionCore/Resources/yolo11n", withExtension: "mlmodelc") else {
    // Try direct path
    let directPath = "Sources/VisionCore/Resources/yolo11n.mlmodelc"
    guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: URL(fileURLWithPath: directPath))) else {
        print("❌ Failed to load model from: \(directPath)")
        exit(1)
    }

    runDetection(model: model, cgImage: cgImage)
    exit(0)
}

let model = try! VNCoreMLModel(for: MLModel(contentsOf: modelURL))
runDetection(model: model, cgImage: cgImage)

func runDetection(model: VNCoreMLModel, cgImage: CGImage) {
    let request = VNCoreMLRequest(model: model) { request, error in
        if let error = error {
            print("❌ Detection error: \(error)")
            return
        }

        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            print("⚠️  No recognized objects found")
            print("Raw results type: \(type(of: request.results))")
            if let results = request.results {
                print("Results count: \(results.count)")
            }
            return
        }

        print("🎯 YOLOv11n Detection Results")
        print("═══════════════════════════════════════════")
        print("Total objects detected: \(results.count)")
        print("")

        for (index, observation) in results.enumerated() {
            print("Object #\(index + 1):")
            print("  Label: \(observation.labels.first?.identifier ?? "unknown")")
            print("  Confidence: \(String(format: "%.2f%%", (observation.labels.first?.confidence ?? 0) * 100))")
            print("  Bounding Box (normalized):")
            print("    x: \(String(format: "%.3f", observation.boundingBox.origin.x))")
            print("    y: \(String(format: "%.3f", observation.boundingBox.origin.y))")
            print("    width: \(String(format: "%.3f", observation.boundingBox.size.width))")
            print("    height: \(String(format: "%.3f", observation.boundingBox.size.height))")

            // Convert to pixel coordinates
            let pixelX = Int(observation.boundingBox.origin.x * CGFloat(cgImage.width))
            let pixelY = Int((1.0 - observation.boundingBox.origin.y - observation.boundingBox.size.height) * CGFloat(cgImage.height))
            let pixelW = Int(observation.boundingBox.size.width * CGFloat(cgImage.width))
            let pixelH = Int(observation.boundingBox.size.height * CGFloat(cgImage.height))

            print("  Bounding Box (pixels):")
            print("    x: \(pixelX), y: \(pixelY)")
            print("    width: \(pixelW), height: \(pixelH)")
            print("")

            // Show all labels (top 5)
            if observation.labels.count > 1 {
                print("  Alternative classifications:")
                for label in observation.labels.prefix(5).dropFirst() {
                    print("    - \(label.identifier): \(String(format: "%.2f%%", label.confidence * 100))")
                }
                print("")
            }
        }

        print("═══════════════════════════════════════════")
        print("")
        print("📊 Metadata Structure:")
        print("  • VNRecognizedObjectObservation")
        print("    - labels: [VNClassificationObservation]")
        print("    - boundingBox: CGRect (normalized 0-1)")
        print("    - confidence: Float (0-1)")
        print("    - uuid: UUID")
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try! handler.perform([request])
}
