import SwiftUI
import Core
import Persistence

/// Manual edit form with all editable fields
public struct EditItemSheet: View {
    @Bindable var viewModel: EditItemViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: EditableField?

    public init(viewModel: EditItemViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    EditableTextField(
                        title: "Name",
                        text: Binding(
                            get: { viewModel.editableItem.name ?? "" },
                            set: { viewModel.updateField(\.name, value: $0.isEmpty ? nil : $0, fieldName: "name") }
                        ),
                        error: viewModel.validationErrors["name"]
                    )
                    .accessibilityIdentifier("edit.nameField")
                    .focused($focusedField, equals: .name)

                    EditableTextField(
                        title: "Brand",
                        text: Binding(
                            get: { viewModel.editableItem.brand ?? "" },
                            set: { viewModel.updateField(\.brand, value: $0.isEmpty ? nil : $0, fieldName: "brand") }
                        )
                    )
                    .accessibilityIdentifier("edit.brandField")
                    .focused($focusedField, equals: .brand)

                    EditableTextField(
                        title: "Model",
                        text: Binding(
                            get: { viewModel.editableItem.model ?? "" },
                            set: { viewModel.updateField(\.model, value: $0.isEmpty ? nil : $0, fieldName: "model") }
                        )
                    )
                    .accessibilityIdentifier("edit.modelField")
                    .focused($focusedField, equals: .model)
                } header: {
                    Text("Basic Information")
                }

                // Categorization Section
                Section {
                    EditableTextField(
                        title: "Category",
                        text: Binding(
                            get: { viewModel.editableItem.category ?? "" },
                            set: { newValue in
                                viewModel.updateField(
                                    \.category,
                                    value: newValue.isEmpty ? nil : newValue,
                                    fieldName: "category"
                                )
                            }
                        )
                    )
                    .accessibilityIdentifier("edit.categoryField")

                    EditableTextField(
                        title: "Sub-Category",
                        text: Binding(
                            get: { viewModel.editableItem.subCategory ?? "" },
                            set: { newValue in
                                viewModel.updateField(
                                    \.subCategory,
                                    value: newValue.isEmpty ? nil : newValue,
                                    fieldName: "subCategory"
                                )
                            }
                        )
                    )
                    .accessibilityIdentifier("edit.subCategoryField")
                } header: {
                    Text("Categorization")
                }

                // Physical Properties Section
                Section {
                    EditableTextField(
                        title: "Color",
                        text: Binding(
                            get: { viewModel.editableItem.color ?? "" },
                            set: { newValue in
                                viewModel.updateField(
                                    \.color,
                                    value: newValue.isEmpty ? nil : newValue,
                                    fieldName: "color"
                                )
                            }
                        )
                    )
                    .accessibilityIdentifier("edit.colorField")

                    EditableTextField(
                        title: "Material",
                        text: Binding(
                            get: { viewModel.editableItem.material ?? "" },
                            set: { newValue in
                                viewModel.updateField(
                                    \.material,
                                    value: newValue.isEmpty ? nil : newValue,
                                    fieldName: "material"
                                )
                            }
                        )
                    )
                    .accessibilityIdentifier("edit.materialField")

                    EditableTextField(
                        title: "Dimensions",
                        text: Binding(
                            get: { viewModel.editableItem.dimensions ?? "" },
                            set: { newValue in
                                viewModel.updateField(
                                    \.dimensions,
                                    value: newValue.isEmpty ? nil : newValue,
                                    fieldName: "dimensions"
                                )
                            }
                        ),
                        placeholder: "e.g., 10\" x 5\" x 3\""
                    )
                    .accessibilityIdentifier("edit.dimensionsField")

                    // Condition Picker
                    Picker("Condition", selection: Binding(
                        get: { viewModel.editableItem.condition ?? .good },
                        set: { viewModel.updateField(\.condition, value: $0, fieldName: "condition") }
                    )) {
                        Text("New").tag(ItemCondition.new)
                        Text("Like New").tag(ItemCondition.likeNew)
                        Text("Good").tag(ItemCondition.good)
                        Text("Fair").tag(ItemCondition.fair)
                        Text("Poor").tag(ItemCondition.poor)
                    }
                    .accessibilityIdentifier("edit.conditionPicker")
                } header: {
                    Text("Physical Properties")
                }

                // Value Section
                Section {
                    EditableNumberField(
                        title: "Quantity",
                        value: Binding(
                            get: { viewModel.editableItem.quantity ?? 1 },
                            set: { viewModel.updateField(\.quantity, value: $0, fieldName: "quantity") }
                        ),
                        error: viewModel.validationErrors["quantity"]
                    )
                    .accessibilityIdentifier("edit.quantityStepper")

                    EditableCurrencyField(
                        title: "Estimated Value",
                        value: Binding(
                            get: { viewModel.editableItem.estimatedValue ?? 0 },
                            set: { viewModel.updateField(\.estimatedValue, value: $0, fieldName: "estimatedValue") }
                        ),
                        error: viewModel.validationErrors["estimatedValue"]
                    )
                    .accessibilityIdentifier("edit.valueField")
                } header: {
                    Text("Value")
                } footer: {
                    Text("Your edits help improve our AI for future items.")
                        .font(.footnote)
                }

                // Photos Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Existing photos
                            ForEach(Array(viewModel.editableItem.allImageUrls.enumerated()), id: \.offset) { index, urlString in
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: URL(string: urlString)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        default:
                                            Rectangle()
                                                .fill(.gray.opacity(0.2))
                                                .overlay {
                                                    ProgressView()
                                                }
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    if index == 0 {
                                        Text("Primary")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(.ultraThinMaterial, in: Capsule())
                                            .padding(4)
                                    } else {
                                        Button {
                                            viewModel.deletePhoto(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.callout)
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .red)
                                        }
                                        .padding(4)
                                        .accessibilityLabel("Remove photo \(index + 1)")
                                    }
                                }
                            }

                            // Add Photo button
                            Button {
                                viewModel.beginAddPhoto()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Add")
                                        .font(.caption2)
                                }
                                .frame(width: 80, height: 80)
                                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(viewModel.isUploadingPhoto)
                            .accessibilityIdentifier("edit.addPhotoButton")
                        }
                        .padding(.vertical, 4)
                    }

                    if viewModel.isUploadingPhoto {
                        HStack {
                            ProgressView()
                            Text("Uploading photo...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let photoError = viewModel.photoError {
                        Text(photoError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Photos")
                }

                // AI Metadata (Read-Only)
                Section {
                    if let confidence = viewModel.editableItem.confidence {
                        LabeledContent("AI Confidence") {
                            Text(confidence.rawValue.capitalized)
                                .foregroundStyle(confidenceColor(confidence))
                        }
                    }

                    if let notes = viewModel.editableItem.processingNotes, !notes.isEmpty {
                        LabeledContent("Processing Notes") {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("AI Metadata")
                } footer: {
                    Text("This information cannot be edited.")
                }
            }
            .navigationTitle("Edit Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelFlow()
                        dismiss()
                    }
                    .accessibilityIdentifier("edit.cancelButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            try? await viewModel.saveManualEdits()
                            if viewModel.state == .idle {
                                dismiss()
                            }
                        }
                    }
                    .accessibilityIdentifier("edit.saveButton")
                    .buttonStyle(.borderedProminent)
                    .tint(Color.successColor)
                    .disabled(!viewModel.validationErrors.isEmpty || viewModel.state == .saving)
                }
            }
            .overlay {
                if viewModel.state == .saving {
                    SavingOverlay()
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(viewModel.state == .saving)
    }

    private func confidenceColor(_ confidence: ItemConfidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

// MARK: - Field Types

private enum EditableField {
    case name, brand, model, category, subCategory, color, material, dimensions
}

// MARK: - Custom Input Components

private struct EditableTextField: View {
    let title: String
    @Binding var text: String
    var error: String?
    var placeholder: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text, prompt: placeholder.map { Text($0) })

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct EditableNumberField: View {
    let title: String
    @Binding var value: Int
    var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Stepper(title, value: $value, in: 1...1000)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct EditableCurrencyField: View {
    let title: String
    @Binding var value: Double
    var error: String?

    private var currencyBinding: Binding<String> {
        Binding(
            get: {
                if value == 0 { return "" }
                return String(format: "%.2f", value)
            },
            set: { newValue in
                value = Double(newValue.filter { $0.isNumber || $0 == "." }) ?? 0
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                HStack(spacing: 2) {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: currencyBinding)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Saving Overlay

private struct SavingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving...")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
            }
            .padding(24)
            .background(Color.cream, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
