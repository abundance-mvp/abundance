import SwiftUI
import Core

/// View displaying detection results with bounding boxes and object cards
public struct DetectionResultsView: View {
    let capturedImage: Data?
    let detectedObjects: [ServerDetectedObject]
    let catalogingObjectIds: Set<String>
    let catalogedObjectIds: Set<String>
    let onCatalogSelected: (Set<String>) -> Void
    let onRetake: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedObjectId: String?
    @State private var selectedObjectIds: Set<String> = []
    @State private var decodedImage: Image?
    @State private var decodedImageSize: CGSize?

    private var uncatalogedObjects: [ServerDetectedObject] {
        detectedObjects.filter { !catalogedObjectIds.contains($0.groupId) && !catalogingObjectIds.contains($0.groupId) }
    }

    private var selectedCount: Int {
        uncatalogedObjects.filter { selectedObjectIds.contains($0.groupId) }.count
    }

    private func toggleObjectSelection(_ objectId: String) {
        if selectedObjectIds.contains(objectId) {
            selectedObjectIds.remove(objectId)
        } else {
            selectedObjectIds.insert(objectId)
        }
    }

    public init(
        capturedImage: Data?,
        detectedObjects: [ServerDetectedObject],
        catalogingObjectIds: Set<String>,
        catalogedObjectIds: Set<String>,
        onCatalogSelected: @escaping (Set<String>) -> Void,
        onRetake: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.detectedObjects = detectedObjects
        self.catalogingObjectIds = catalogingObjectIds
        self.catalogedObjectIds = catalogedObjectIds
        self.onCatalogSelected = onCatalogSelected
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
        .onAppear {
            if selectedObjectIds.isEmpty {
                selectedObjectIds = Set(detectedObjects.map(\.groupId))
            }
        }
        .task {
            // Decode image once to avoid repeated decoding in body
            if let imageData = capturedImage,
               let decoded = ImageDecoding.decodeWithSize(imageData) {
                decodedImage = decoded.image
                decodedImageSize = decoded.size
            }
        }
    }

    // MARK: - Image with Bounding Boxes

    /// Calculate the displayed image rect within a container when using .aspectRatio(.fit)
    private func imageDisplayRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        let displaySize: CGSize
        if imageAspect > containerAspect {
            // Image is wider than container — fits to width, letterbox top/bottom
            displaySize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspect
            )
        } else {
            // Image is taller than container — fits to height, letterbox left/right
            displaySize = CGSize(
                width: containerSize.height * imageAspect,
                height: containerSize.height
            )
        }

        return CGRect(
            x: (containerSize.width - displaySize.width) / 2,
            y: (containerSize.height - displaySize.height) / 2,
            width: displaySize.width,
            height: displaySize.height
        )
    }

    @ViewBuilder
    private func imageWithBoundingBoxes(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black

            // Background image
            if capturedImage != nil {
                if let image = decodedImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay {
                            // Bounding box overlays as overlay on image ensures
                            // coordinate alignment without offset calculations
                            GeometryReader { imageGeometry in
                                ForEach(detectedObjects) { object in
                                    BoundingBoxOverlay(
                                        object: object,
                                        imageRect: CGRect(origin: .zero, size: imageGeometry.size),
                                        isSelected: selectedObjectId == object.groupId,
                                        isChecked: selectedObjectIds.contains(object.groupId),
                                        isCataloging: catalogingObjectIds.contains(object.groupId),
                                        isCataloged: catalogedObjectIds.contains(object.groupId)
                                    )
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("Detected: \(object.label)")
                                    .accessibilityHint(
                                        selectedObjectIds.contains(object.groupId) ? "Double tap to deselect" : "Double tap to select"
                                    )
                                    .accessibilityAddTraits(.isButton)
                                    .onTapGesture {
                                        withAnimation(reduceMotion ? nil : .brandPress) {
                                            selectedObjectId = selectedObjectId == object.groupId ? nil : object.groupId
                                            toggleObjectSelection(object.groupId)
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // Retake overlay button (positioned via overlay to avoid affecting image centering)
            Button(action: onRetake) {
                HStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(.caption2.weight(.semibold))
                    Text("Retake")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    if #available(iOS 26.0, macOS 26.0, *) {
                        Color.clear.glassEffect(.regular.interactive(), in: Capsule())
                    } else {
                        Capsule().fill(.black.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .accessibilityIdentifier("detection.retakeOverlayButton")
            .accessibilityLabel("Retake photo")
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
                                isChecked: selectedObjectIds.contains(object.groupId),
                                isCataloging: catalogingObjectIds.contains(object.groupId),
                                isCataloged: catalogedObjectIds.contains(object.groupId),
                                onToggleCheck: {
                                    toggleObjectSelection(object.groupId)
                                }
                            )
                            .accessibilityIdentifier("detection.object.\(object.groupId)")
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(object.label), \(object.category)")
                            .accessibilityHint("Double tap to select this object")
                            .accessibilityAddTraits(.isButton)
                            .onTapGesture {
                                withAnimation(reduceMotion ? nil : .brandPress) {
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
                .adaptiveGlass(in: Rectangle())
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

            if !detectedObjects.isEmpty {
                let allSelected = uncatalogedObjects.allSatisfy { selectedObjectIds.contains($0.groupId) }
                Button(allSelected ? "Deselect All" : "Select All") {
                    if allSelected {
                        for obj in uncatalogedObjects {
                            selectedObjectIds.remove(obj.groupId)
                        }
                    } else {
                        for obj in uncatalogedObjects {
                            selectedObjectIds.insert(obj.groupId)
                        }
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentPrimary)
                .accessibilityIdentifier("detection.selectAllButton")
            }
        }
    }

    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48

    private var noObjectsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "viewfinder")
                .font(.system(size: emptyIconSize))
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

    @ViewBuilder
    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button(action: onRetake) {
                Label("Retake", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("detection.retakeButton")

            Spacer()

            if #available(iOS 26.0, macOS 26.0, *) {
                Button {
                    onCatalogSelected(selectedObjectIds)
                } label: {
                    Label("Catalog", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .glassEffect(.regular.interactive())
                .disabled(selectedCount == 0)
                .opacity(selectedCount == 0 ? 0.5 : 1.0)
                .accessibilityIdentifier("detection.catalogSelectedButton")
                .accessibilityLabel("Catalog \(selectedCount) items")
                .accessibilityHint(selectedCount == 0 ? "No items selected" : "Double tap to catalog selected items")
            } else {
                Button {
                    onCatalogSelected(selectedObjectIds)
                } label: {
                    Label("Catalog", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
                .opacity(selectedCount == 0 ? 0.5 : 1.0)
                .accessibilityIdentifier("detection.catalogSelectedButton")
                .accessibilityLabel("Catalog \(selectedCount) items")
            }

            Button(action: onDone) {
                Text("Done")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("detection.doneButton")
            .accessibilityHint("Saves results and returns to catalog view")
        }
    }

}

// MARK: - Bounding Box Overlay

struct BoundingBoxOverlay: View {
    let object: ServerDetectedObject
    /// The rect within the container where the image is actually displayed (accounting for aspect-fit)
    let imageRect: CGRect
    let isSelected: Bool
    let isChecked: Bool
    let isCataloging: Bool
    let isCataloged: Bool

    var body: some View {
        // Use first bounding box for display
        if let firstBox = object.boundingBoxes.first {
            let rect = firstBox.normalizedRect
            // Map normalized coordinates to the actual displayed image rect
            let frame = CGRect(
                x: imageRect.minX + rect.minX * imageRect.width,
                y: imageRect.minY + rect.minY * imageRect.height,
                width: rect.width * imageRect.width,
                height: rect.height * imageRect.height
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

    private var borderColor: Color {
        if isCataloged {
            return .successColor
        } else if isCataloging {
            return .cream
        } else if isSelected {
            return .accentPrimary
        } else if !isChecked {
            return .white.opacity(0.6)
        } else {
            return .white.opacity(0.8)
        }
    }

    private var labelBadge: some View {
        HStack(spacing: 4) {
            if isCataloged {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
            } else if isCataloging {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
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
    let isChecked: Bool
    let isCataloging: Bool
    let isCataloged: Bool
    let onToggleCheck: () -> Void

    private var backgroundFillColor: Color {
        if isSelected {
            return Color.accentPrimary.opacity(0.1)
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
                .stroke(isSelected ? Color.accentPrimary : Color.clear, lineWidth: 1)
        )
    }

    private var thumbnailView: some View {
        Group {
            if let urlString = object.croppedImageUrls.first,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        thumbnailPlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.accentPrimary : .clear, lineWidth: 2))
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            #if os(iOS)
            Color(.secondarySystemFill)
            #else
            Color(nsColor: .controlBackgroundColor)
            #endif
            Image(systemName: "photo.badge.exclamationmark").font(.title3).foregroundStyle(.secondary)
        }
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
                .foregroundStyle(Color.successColor)
                .accessibilityLabel("Cataloged")
        } else if isCataloging {
            ProgressView()
                .accessibilityLabel("Cataloging in progress")
        } else {
            Button(action: onToggleCheck) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? Color.accentPrimary : .secondary)
            }
            .accessibilityLabel(isChecked ? "Selected for cataloging" : "Not selected")
            .accessibilityHint("Double tap to \(isChecked ? "deselect" : "select") this item")
            .accessibilityIdentifier("detection.toggleCheck.\(object.groupId)")
        }
    }
}

// MARK: - No Objects Detected View

struct NoObjectsDetectedView: View {
    let reasoning: String?
    let onRetake: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var noObjectsIconSize: CGFloat = 64

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "viewfinder.circle")
                .font(.system(size: noObjectsIconSize))
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
                .foregroundStyle(Color.accentPrimary)
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
            ServerDetectedObject(groupId: "1", label: "Table Lamp", category: "lighting",
                attributes: ["color": "brass"], confidence: "high", croppedImageUrls: [],
                boundingBoxes: [BoundingBoxInfo(imageIndex: 0, box2d: [100, 200, 400, 600])]),
            ServerDetectedObject(groupId: "2", label: "Book", category: "books",
                attributes: [:], confidence: "medium", croppedImageUrls: [],
                boundingBoxes: [BoundingBoxInfo(imageIndex: 0, box2d: [500, 100, 700, 300])])
        ],
        catalogingObjectIds: [], catalogedObjectIds: [],
        onCatalogSelected: { ids in print("Catalog: \(ids)") },
        onRetake: { }, onDone: { })
}

#Preview("No Objects") {
    NoObjectsDetectedView(reasoning: "Only fixtures found.", onRetake: { })
}
#endif
