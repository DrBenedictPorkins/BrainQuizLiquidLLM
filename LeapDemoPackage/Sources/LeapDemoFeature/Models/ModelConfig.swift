import Foundation

struct ModelConfig: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let modelId: String
    let quantization: String
    let sizeDescription: String
    let speedLabel: String

    static let available: [ModelConfig] = [
        ModelConfig(
            id: "lfm2-350m-extract-q4km",
            displayName: "LFM2 350M Extract",
            modelId: "LFM2-350M-Extract",
            quantization: "Q4_K_M",
            sizeDescription: "~207 MB",
            speedLabel: "Fastest"
        ),
        ModelConfig(
            id: "lfm2-1.2b-extract-q4km",
            displayName: "LFM2 1.2B Extract",
            modelId: "LFM2-1.2B-Extract",
            quantization: "Q4_K_M",
            sizeDescription: "~680 MB",
            speedLabel: "Balanced"
        ),
        ModelConfig(
            id: "lfm2-1.2b-tool-q4km",
            displayName: "LFM2 1.2B Tool",
            modelId: "LFM2-1.2B-Tool",
            quantization: "Q4_K_M",
            sizeDescription: "~680 MB",
            speedLabel: "Best for JSON"
        ),
        ModelConfig(
            id: "lfm2-2.6b-exp-q4km",
            displayName: "LFM2 2.6B Exp",
            modelId: "LFM2-2.6B-Exp",
            quantization: "Q4_K_M",
            sizeDescription: "~1.5 GB",
            speedLabel: "Sharpest"
        ),
    ]

    static let `default` = available[2]
}
