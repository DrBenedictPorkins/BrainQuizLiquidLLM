import SwiftUI

struct SplashView: View {
    @Environment(QuizEngine.self) private var engine
    @State private var showModelPicker = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Branding
                VStack(spacing: 16) {
                    Text("🧠")
                        .font(.system(size: 72))

                    Text("Quiz Game")
                        .font(.system(size: 38, weight: .black, design: .rounded))

                    Text("Powered by on-device AI")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Model section
                VStack(spacing: 16) {
                    // Model picker card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI MODEL")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(1)

                        Button {
                            showModelPicker = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(engine.selectedModel.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 8) {
                                        Label(engine.selectedModel.sizeDescription, systemImage: "internaldrive")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text("·")
                                            .foregroundStyle(.secondary)

                                        Text(engine.selectedModel.speedLabel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text("·")
                                            .foregroundStyle(.secondary)

                                        Text(engine.selectedModel.quantization)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(engine.modelState == .ready)
                        .accessibilityLabel("Select AI model: \(engine.selectedModel.displayName)")
                    }
                    .padding(.horizontal)

                    // Status + action
                    ModelActionSection()
                }
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet(isPresented: $showModelPicker)
        }
    }
}

// MARK: - Model Action Section

struct ModelActionSection: View {
    @Environment(QuizEngine.self) private var engine

    var body: some View {
        VStack(spacing: 12) {
            switch engine.modelState {
            case .unloaded, .failed:
                // Load button
                if case .failed(let msg) = engine.modelState {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await engine.loadModel() }
                } label: {
                    Label("Load Model", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

            case .downloading(let progress):
                VStack(spacing: 10) {
                    HStack {
                        Text("Downloading \(engine.selectedModel.displayName)...")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: progress)
                        .tint(.accentColor)
                }
                .padding(.horizontal)

            case .loading:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading model into memory...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            case .ready:
                // Loaded state — show model info + start
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(engine.loadedModel?.displayName ?? engine.selectedModel.displayName) ready")
                                .font(.subheadline.weight(.semibold))
                            Text("Running on-device · No internet needed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    Button {
                        Task { await engine.loadModel() } // transitions to .idle when already ready
                    } label: {
                        Label("Start Playing", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: engine.modelState)
    }
}

// MARK: - Model Picker Row

struct ModelPickerRow: View {
    let config: ModelConfig
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(config.sizeDescription) · \(config.speedLabel) · \(config.quantization)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("\(config.displayName), \(config.sizeDescription), \(config.speedLabel)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Model Picker Sheet

struct ModelPickerSheet: View {
    @Environment(QuizEngine.self) private var engine
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List(ModelConfig.available) { config in
                ModelPickerRow(config: config, isSelected: engine.selectedModel.id == config.id) {
                    engine.selectedModel = config
                    isPresented = false
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
