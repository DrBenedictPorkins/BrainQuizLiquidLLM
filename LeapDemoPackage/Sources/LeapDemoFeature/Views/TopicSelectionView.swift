import SwiftUI

struct TopicSelectionView: View {
    @Environment(QuizEngine.self) private var engine
    @State private var selectedTopic: Topic? = nil
    @State private var selectedSubcategory: Topic.Subcategory? = nil
    @State private var showCustomInput = false
    @State private var customTopic = ""

    private var topicSelection: TopicSelection? {
        if showCustomInput {
            let trimmed = customTopic.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : .custom(trimmed)
        }
        guard let topic = selectedTopic else { return nil }
        return .preset(topic: topic, subcategory: selectedSubcategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quiz Game")
                            .font(.largeTitle.bold())
                        Text("Pick a topic to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Generation error banner
                    if let err = engine.generationError {
                        Text(err)
                            .font(.caption.monospaced())
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red, in: RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                    }

                    // Model loading state
                    ModelLoadingBanner()

                    // Topic grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Topic.presets) { topic in
                            TopicCard(
                                topic: topic,
                                isSelected: selectedTopic?.id == topic.id && !showCustomInput
                            )
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.2)) {
                                    showCustomInput = false
                                    if selectedTopic?.id == topic.id {
                                        selectedTopic = nil
                                        selectedSubcategory = nil
                                    } else {
                                        selectedTopic = topic
                                        selectedSubcategory = nil
                                    }
                                }
                            }
                        }

                        // Random topic card
                        RandomTopicCard()
                            .onTapGesture {
                                engine.selectTopic(.random)
                            }

                        // Custom topic card
                        CustomTopicCard(isSelected: showCustomInput)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.2)) {
                                    showCustomInput = true
                                    selectedTopic = nil
                                    selectedSubcategory = nil
                                }
                            }
                    }
                    .padding(.horizontal)

                    // Subcategory selection (shown when topic selected)
                    if let topic = selectedTopic, !showCustomInput {
                        SubcategoryRow(
                            topic: topic,
                            selected: $selectedSubcategory
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Custom input field
                    if showCustomInput {
                        CustomTopicField(text: $customTopic)
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Start button
                    if let selection = topicSelection {
                        Button {
                            engine.selectTopic(selection)
                        } label: {
                            Label("Start Quiz", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                        .disabled(engine.modelState != .ready)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 40)
            }
            .animation(.spring(duration: 0.3), value: showCustomInput)
            .animation(.spring(duration: 0.3), value: selectedTopic?.id)
            .animation(.spring(duration: 0.3), value: topicSelection != nil)
        }
    }
}

struct TopicCard: View {
    let topic: Topic
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(topic.emoji)
                .font(.system(size: 32))
            Text(topic.displayName)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .accessibilityLabel("\(topic.displayName), \(topic.emoji)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct RandomTopicCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "shuffle.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.purple)
            Text("Random")
                .font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.08))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Random topic")
        .accessibilityAddTraits(.isButton)
    }
}

struct CustomTopicCard: View {
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            Text("Custom")
                .font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .accessibilityLabel("Custom topic")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct SubcategoryRow: View {
    let topic: Topic
    @Binding var selected: Topic.Subcategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topic.subcategories) { sub in
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                selected = selected?.id == sub.id ? nil : sub
                            }
                        } label: {
                            Text(sub.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selected?.id == sub.id ? Color.accentColor : Color(.secondarySystemBackground))
                                )
                                .foregroundStyle(selected?.id == sub.id ? .white : .primary)
                        }
                        .accessibilityLabel(sub.displayName)
                        .accessibilityAddTraits(selected?.id == sub.id ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
        }
    }
}

struct CustomTopicField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your topic")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("e.g. Ancient Egyptian Pharaohs", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .submitLabel(.done)
                .accessibilityLabel("Custom topic input")
        }
    }
}

struct ModelLoadingBanner: View {
    @Environment(QuizEngine.self) private var engine

    var body: some View {
        switch engine.modelState {
        case .downloading(let progress):
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Downloading AI model...")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: progress)
                    .tint(.blue)
            }
            .padding()
            .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Loading AI model...")
                    .font(.subheadline.weight(.medium))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        case .failed(let msg):
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Failed to load: \(msg)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        case .ready, .unloaded:
            EmptyView()
        }
    }
}
