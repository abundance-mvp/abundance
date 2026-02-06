#if DEBUG
import SwiftUI
import PhotosUI
import InventoryFeature
import ProfileFeature
import CameraFeature
import FirebaseAuth

/// E2E test MainTabView that connects to real Firebase but replaces the camera
/// with image injection (PHPicker or bundled test images).
///
/// Launch with `--e2e-test-mode` argument to activate.
/// Uses real Firebase Auth, Firestore, Storage, and Cloud Functions.
struct E2ETestMainTabView: View {
    @State private var selectedTab: Tab = .catalog

    enum Tab {
        case catalog
        case camera
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryView(onOpenCamera: { selectedTab = .camera })
                .tabItem {
                    Label("Catalog", systemImage: "square.grid.2x2.fill")
                }
                .accessibilityIdentifier("tab.catalog")
                .tag(Tab.catalog)

            E2EImageInjectionView(onDone: { selectedTab = .catalog })
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .accessibilityIdentifier("tab.camera")
                .tag(Tab.camera)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .accessibilityIdentifier("tab.profile")
                .tag(Tab.profile)
        }
    }
}

// MARK: - E2E Image Injection View

/// Replaces the camera with a photo picker for E2E testing.
/// Selected images flow through the real capture pipeline (upload → detect → catalog).
private struct E2EImageInjectionView: View {
    let onDone: () -> Void

    @StateObject private var viewModel = CaptureSessionViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var statusMessage = "Select an image to test the capture pipeline"
    @State private var showBundledImagePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusSection

                if case .results = viewModel.uiState {
                    resultsSection
                } else {
                    pickerSection
                }
            }
            .padding()
            .navigationTitle("E2E Capture")
            .accessibilityIdentifier("e2e.captureView")
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        VStack(spacing: 8) {
            stateIndicator
            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
        }
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.uiState {
        case .idle:
            Label("Ready", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .capturing:
            Label("Capturing...", systemImage: "camera.fill")
                .foregroundStyle(.blue)
        case .uploading(let progress):
            VStack {
                Label("Uploading...", systemImage: "arrow.up.circle")
                    .foregroundStyle(.blue)
                ProgressView(value: progress)
            }
        case .analyzing:
            HStack {
                ProgressView()
                Text("Analyzing with Gemini...")
            }
            .foregroundStyle(.orange)
        case .results:
            Label("Results Ready", systemImage: "sparkles")
                .foregroundStyle(.green)
        case .error(let error):
            Label("Error: \(error.localizedDescription)", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Picker Section

    @ViewBuilder
    private var pickerSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 1,
                matching: .images
            ) {
                Label("Pick from Photo Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isProcessing)
            .accessibilityIdentifier("e2e.photoPickerButton")
            .onChange(of: selectedItems) { _, newItems in
                guard let item = newItems.first else { return }
                Task {
                    await processSelectedPhoto(item)
                }
            }

            Button {
                showBundledImagePicker = true
            } label: {
                Label("Use Bundled Test Image", systemImage: "photo.stack")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isProcessing)
            .accessibilityIdentifier("e2e.bundledImageButton")
            .sheet(isPresented: $showBundledImagePicker) {
                BundledImagePicker { imageData in
                    Task {
                        await injectImage(imageData)
                    }
                }
            }
        }

        if case .error = viewModel.uiState {
            Button("Retry") {
                viewModel.dismissError()
                statusMessage = "Select an image to test the capture pipeline"
            }
            .buttonStyle(.bordered)
        }

        Spacer()
    }

    // MARK: - Results Section

    @ViewBuilder
    private var resultsSection: some View {
        VStack(spacing: 16) {
            Text("\(viewModel.detectedObjects.count) object(s) detected")
                .font(.headline)

            ForEach(viewModel.detectedObjects, id: \.groupId) { object in
                HStack {
                    Text(object.label)
                        .font(.body)
                    Spacer()
                    if viewModel.catalogedObjectIds.contains(object.groupId) {
                        Label("Cataloged", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if viewModel.catalogingObjectIds.contains(object.groupId) {
                        ProgressView()
                    } else {
                        Button("Catalog") {
                            Task {
                                await viewModel.catalogObject(object)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button("Catalog All") {
                    Task {
                        await viewModel.catalogAllObjects()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.detectedObjects.allSatisfy {
                    viewModel.catalogedObjectIds.contains($0.groupId) ||
                    viewModel.catalogingObjectIds.contains($0.groupId)
                })

                Button("Done") {
                    viewModel.retake()
                    statusMessage = "Select an image to test the capture pipeline"
                    onDone()
                }
                .buttonStyle(.bordered)
            }
        }

        Spacer()
    }

    // MARK: - Image Processing

    private func processSelectedPhoto(_ item: PhotosPickerItem) async {
        isProcessing = true
        statusMessage = "Loading selected photo..."

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            statusMessage = "Failed to load photo data"
            isProcessing = false
            return
        }

        await injectImage(data)
    }

    private func injectImage(_ imageData: Data) async {
        isProcessing = true
        statusMessage = "Injecting image into capture pipeline..."
        selectedItems = []

        await viewModel.handleDoubleTap(photoData: imageData)
        isProcessing = false

        switch viewModel.uiState {
        case .results:
            statusMessage = "Detection complete — \(viewModel.detectedObjects.count) object(s) found"
        case .error(let error):
            statusMessage = "Pipeline error: \(error.localizedDescription)"
        default:
            statusMessage = "Processing..."
        }
    }
}

// MARK: - Bundled Image Picker

/// Presents bundled debug images for selection.
private struct BundledImagePicker: View {
    let onSelect: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var thumbnailData: [String: Data] = [:]

    private let imageNames = (1...8).map { "object-\($0)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(imageNames, id: \.self) { name in
                        Button {
                            if let data = thumbnailData[name] ?? loadBundledImage(name: name) {
                                onSelect(data)
                                dismiss()
                            }
                        } label: {
                            bundledImageThumbnail(name: name)
                        }
                        .accessibilityLabel("Test image \(name)")
                    }
                }
                .padding()
            }
            .navigationTitle("Test Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                loadThumbnails()
            }
        }
    }

    @ViewBuilder
    private func bundledImageThumbnail(name: String) -> some View {
        #if os(iOS)
        if let data = thumbnailData[name],
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                }
                .accessibilityHidden(true)
        } else {
            placeholderThumbnail(name: name)
        }
        #else
        placeholderThumbnail(name: name)
        #endif
    }

    private func placeholderThumbnail(name: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.gray.opacity(0.2))
            .frame(height: 150)
            .overlay {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }

    private func loadThumbnails() {
        for name in imageNames {
            if let data = loadBundledImage(name: name) {
                thumbnailData[name] = data
            }
        }
    }

    private func loadBundledImage(name: String) -> Data? {
        let url = Bundle.main.url(forResource: name, withExtension: "jpeg", subdirectory: "DebugResources")
            ?? Bundle.main.url(forResource: name, withExtension: "jpeg")
        guard let url else { return nil }
        return try? Data(contentsOf: url)
    }
}
#endif
