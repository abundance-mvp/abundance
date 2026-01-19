import SwiftUI

/// View displaying detection results with bounding boxes and object cards
public struct DetectionResultsView: View {
    let capturedImage: Data?
    let detectedObjects: [ServerDetectedObject]
    let catalogingObjectIds: Set<String>
    let catalogedObjectIds: Set<String>
    let onCatalogObject: (ServerDetectedObject) -> Void
    let onCatalogAll: () -> Void
    let onRetake: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var selectedObjectId: String?

    public init(
        capturedImage: Data?,
        detectedObjects: [ServerDetectedObject],
        catalogingObjectIds: Set<String>,
        catalogedObjectIds: Set<String>,
        onCatalogObject: @escaping (ServerDetectedObject) -> Void,
        onCatalogAll: @escaping () -> Void,
        onRetake: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.detectedObjects = detectedObjects
        self.catalogingObjectIds = catalogingObjectIds
        self.catalogedObjectIds = catalogedObjectIds
        self.onCatalogObject = onCatalogObject
        self.onCatalogAll = onCatalogAll
        self.onRetake = onRetake
        self.onDone = onDone
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Captured image with bounding boxes
                imageWithBoundingBoxes(geometry: geometry)
                    .frame(height: geometry.size.height * 0.55)

                // Object list
                objectList
                    .frame(maxHeight: geometry.size.height * 0.45)
            }
        }
    }

    // MARK: - Image with Bounding Boxes

    @ViewBuilder
    private func imageWithBoundingBoxes(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black

            // Background image
            if let imageData = capturedImage {
                #if os(iOS)
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                #endif
            }

            // Bounding box overlays
            GeometryReader { _ in
                ForEach(detectedObjects) { object in
                    BoundingBoxOverlay(
                        object: object,
                        isSelected: selectedObjectId == object.groupId,
                        isCataloging: catalogingObjectIds.contains(object.groupId),
                        isCataloged: catalogedObjectIds.contains(object.groupId)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Detected: \(object.label)")
                    .accessibilityHint(
                        selectedObjectId == object.groupId ? "Double tap to deselect" : "Double tap to select"
                    )
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedObjectId = selectedObjectId == object.groupId ? nil : object.groupId
                        }
                    }
                }
            }
        }
    }

    // MARK: - Object List

    private var objectList: some View {
        VStack(spacing: 0) {
            // Header
            objectListHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            // Object cards
            if detectedObjects.isEmpty {
                noObjectsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(detectedObjects) { object in
                            DetectedObjectCard(
                                object: object,
                                isSelected: selectedObjectId == object.groupId,
                                isCataloging: catalogingObjectIds.contains(object.groupId),
                                isCataloged: catalogedObjectIds.contains(object.groupId),
                                onCatalog: {
                                    onCatalogObject(object)
                                }
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(object.label), \(object.category)")
                            .accessibilityHint("Double tap to select this object")
                            .accessibilityAddTraits(.isButton)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedObjectId = object.groupId
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }

            // Bottom actions
            bottomActions
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    if reduceTransparency {
                        #if os(iOS)
                        Color(.systemBackground)
                        #else
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    } else {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
        }
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }

    private var objectListHeader: some View {
        HStack {
            Text("Detected Objects (\(detectedObjects.count))")
                .font(.system(.headline, design: .rounded))

            Spacer()

            if !detectedObjects.isEmpty && catalogedObjectIds.count < detectedObjects.count {
                Button("Catalog All") {
                    onCatalogAll()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            }
        }
    }

    private var noObjectsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No objects detected")
                .font(.system(.headline, design: .rounded))

            Text("Try taking another photo with clearer objects")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button(action: onRetake) {
                Label("Retake", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
    }

}

// MARK: - Bounding Box Overlay

struct BoundingBoxOverlay: View {
    let object: ServerDetectedObject
    let isSelected: Bool
    let isCataloging: Bool
    let isCataloged: Bool

    var body: some View {
        GeometryReader { geometry in
            // Use first bounding box for display
            if let firstBox = object.boundingBoxes.first {
                let rect = firstBox.normalizedRect
                // normalizedRect already uses SwiftUI coordinates (origin top-left)
                let frame = CGRect(
                    x: rect.minX * geometry.size.width,
                    y: rect.minY * geometry.size.height,
                    width: rect.width * geometry.size.width,
                    height: rect.height * geometry.size.height
                )

                ZStack {
                    // Bounding box
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 2)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)

                    // Label badge
                    labelBadge
                        .position(x: frame.midX, y: frame.minY - 14)
                }
            }
        }
    }

    private var borderColor: Color {
        if isCataloged {
            return .green
        } else if isCataloging {
            return .yellow
        } else if isSelected {
            return .blue
        } else {
            return .white.opacity(0.8)
        }
    }

    private var labelBadge: some View {
        HStack(spacing: 4) {
            if isCataloged {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
            } else if isCataloging {
                ProgressView()
                    .scaleEffect(0.5)
            }

            Text(object.label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(borderColor)
                .shadow(radius: 2)
        )
    }
}

// MARK: - Detected Object Card

struct DetectedObjectCard: View {
    let object: ServerDetectedObject
    let isSelected: Bool
    let isCataloging: Bool
    let isCataloged: Bool
    let onCatalog: () -> Void

    private var backgroundFillColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            #if os(iOS)
            return Color(.secondarySystemBackground)
            #else
            return Color(nsColor: .controlBackgroundColor)
            #endif
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            objectInfoView
            Spacer()
            catalogButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }

    private var thumbnailView: some View {
        AsyncImage(url: URL(string: object.croppedImageUrls.first ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            case .empty:
                ProgressView()
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private var objectInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(object.label)
                .font(.body.weight(.semibold))

            Text(object.category.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)

            attributesView
        }
    }

    @ViewBuilder
    private var attributesView: some View {
        if !object.attributes.isEmpty {
            HStack(spacing: 4) {
                ForEach(Array(object.attributes.prefix(2)), id: \.key) { _, value in
                    Text(value)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private var catalogButton: some View {
        if isCataloged {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        } else if isCataloging {
            ProgressView()
        } else {
            Button(action: onCatalog) {
                Text("Catalog")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

// MARK: - No Objects Detected View

struct NoObjectsDetectedView: View {
    let reasoning: String?
    let onRetake: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "viewfinder.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Objects Detected")
                .font(.title2.weight(.semibold))

            if let reasoning = reasoning {
                Text(reasoning)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Text("Tips for better detection:")
                    .font(.caption.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    tipRow(icon: "light.max", text: "Ensure good lighting")
                    tipRow(icon: "square.on.square", text: "Focus on movable objects")
                    tipRow(icon: "arrow.up.left.and.arrow.down.right", text: "Get closer to the item")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Retake Photo") {
                onRetake()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(text)
                .font(.system(.subheadline, design: .rounded))
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Objects") {
    DetectionResultsView(
        capturedImage: nil,
        detectedObjects: [
            ServerDetectedObject(
                groupId: "1",
                label: "Table Lamp",
                category: "lighting",
                attributes: ["color": "brass", "material": "metal"],
                confidence: "high",
                croppedImageUrls: [],
                boundingBoxes: [BoundingBoxInfo(imageIndex: 0, box2d: [100, 200, 400, 600])]
            ),
            ServerDetectedObject(
                groupId: "2",
                label: "Hardcover Book",
                category: "books",
                attributes: ["color": "blue"],
                confidence: "medium",
                croppedImageUrls: [],
                boundingBoxes: [BoundingBoxInfo(imageIndex: 0, box2d: [500, 100, 700, 300])]
            )
        ],
        catalogingObjectIds: [],
        catalogedObjectIds: [],
        onCatalogObject: { _ in },
        onCatalogAll: { },
        onRetake: { },
        onDone: { }
    )
}

#Preview("No Objects") {
    NoObjectsDetectedView(
        reasoning: "Only built-in fixtures (cabinets, countertops) found.",
        onRetake: { }
    )
}
#endif
