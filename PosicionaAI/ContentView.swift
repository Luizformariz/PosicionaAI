import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: PhotoAnalysisViewModel
    @State private var presentedAnalysis: AnalysisResult?

    init(previewImage: UIImage? = nil) {
        _viewModel = StateObject(wrappedValue: PhotoAnalysisViewModel(previewImage: previewImage))
    }

    var body: some View {
        TabView {
            analyzeTab
                .tabItem {
                    Label("Analyze", systemImage: "waveform.path.ecg.rectangle")
                }

            placementBasicsTab
                .tabItem {
                    Label("Placement Basics", systemImage: "speaker.wave.2.bubble.left")
                }
        }
        .task(id: viewModel.selectedItem) {
            await viewModel.loadSelectedPhoto()
        }
        .animation(.snappy(duration: 0.25), value: viewModel.analysisResult?.title)
        .animation(.snappy(duration: 0.25), value: viewModel.isAnalyzing)
        .onChange(of: viewModel.analysisResult?.id) { _, _ in
            presentedAnalysis = viewModel.analysisResult
        }
        .sheet(item: $presentedAnalysis) { result in
            analysisSheet(for: result)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var analyzeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    analyzeHeader
                    photoPreviewCard
                    uploadCard
                    analysisCard
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
    }

    private var placementBasicsTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    basicsHeroCard

                    VStack(spacing: 14) {
                        basicsVisualCard(
                            title: "Leave space from walls",
                            subtitle: "Give each speaker breathing room.",
                            body: "Pulling speakers away from corners and back walls usually reduces boomy bass and makes the sound easier to control.",
                            systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right"
                        )

                        basicsVisualCard(
                            title: "Keep left and right balanced",
                            subtitle: "Aim for a symmetrical setup.",
                            body: "When left and right speakers sit in similar positions, the stereo image usually feels more centered and stable.",
                            systemImage: "alternatingcurrent"
                        )

                        basicsVisualCard(
                            title: "Aim for ear height",
                            subtitle: "Try to align the tweeter with the listener.",
                            body: "Speakers that fire closer to ear level usually sound clearer and more focused for casual listening.",
                            systemImage: "ear"
                        )

                        basicsVisualCard(
                            title: "Keep the front clear",
                            subtitle: "Avoid blocking the speaker path.",
                            body: "Large furniture directly in front of a speaker can soften detail and reduce clarity.",
                            systemImage: "sofa"
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Placement Basics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var analyzeHeader: some View {
        Text("PosicionaAI")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var photoPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo Preview")
                .font(.headline)

            Text("Check the image before trusting the result.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Group {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    ContentUnavailableView(
                        "No Photo Selected",
                        systemImage: "photo",
                        description: Text("Pick a room image to preview it here.")
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    private var uploadCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upload one room photo")
                .font(.title3.weight(.semibold))

            Text("Choose a clear image of the room to run the speaker analysis.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let message = viewModel.statusMessage {
                Label(message, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Analysis")
                .font(.title3.weight(.semibold))

            if let result = viewModel.analysisResult {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Last analysis ready", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)

                    Text(result.detectionSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Your full analysis opens automatically in a modal when the scan finishes. You can reopen it anytime below.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("View Analysis") {
                        presentedAnalysis = result
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Label("No analysis yet", systemImage: "sparkle.magnifyingglass")
                        .font(.headline)

                    Text("Choose a room photo and tap Analyze Photo. When the scan finishes, the result will open in a dedicated modal.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }

    private func analysisSheet(for result: AnalysisResult) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "waveform.path.ecg.rectangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(result.title)
                                    .font(.title2.weight(.semibold))

                                Text(result.detectionSummary)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(result.summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()

                    if !result.speakerDetails.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detected speakers")
                                .font(.headline)

                            ForEach(result.speakerDetails) { detail in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.accentColor.opacity(0.12))
                                            .frame(width: 46, height: 46)

                                        Image(systemName: iconName(for: detail.title))
                                            .font(.headline)
                                            .foregroundStyle(.tint)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(detail.title)
                                                .font(.subheadline.weight(.semibold))

                                            Spacer()

                                            Text(detail.confidenceText)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }

                                        Text(detail.summary)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(.tertiarySystemGroupedBackground))
                                )
                            }
                        }
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended next steps")
                            .font(.headline)

                        ForEach(Array(result.recommendations.enumerated()), id: \.offset) { index, recommendation in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.14))
                                        .frame(width: 32, height: 32)

                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tint)
                                }

                                Text(recommendation)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Analysis Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        presentedAnalysis = nil
                    }
                }
            }
        }
    }

    private var basicsHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick visual rules for better speaker placement.")
                        .font(.title2.weight(.semibold))

                    Text("Use these basics as a beginner-friendly checklist before or after running the photo analysis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Image(systemName: "speaker.2.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
            }

            HStack(spacing: 10) {
                basicsBadge(title: "Walls", systemImage: "square.split.bottomrightquarter")
                basicsBadge(title: "Balance", systemImage: "equal")
                basicsBadge(title: "Height", systemImage: "arrow.up.and.down")
            }
        }
        .cardStyle()
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                Task {
                    await viewModel.analyzePhoto()
                }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isAnalyzing {
                        ProgressView()
                    } else {
                        Image(systemName: "viewfinder")
                    }

                    Text(viewModel.isAnalyzing ? "Analyzing..." : "Analyze Photo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canAnalyze)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .background(.regularMaterial)
    }

    private func basicsVisualCard(title: String, subtitle: String, body: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func basicsBadge(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
    }

    private func iconName(for detailTitle: String) -> String {
        if detailTitle.localizedCaseInsensitiveContains("left") {
            return "arrow.left.circle.fill"
        }

        if detailTitle.localizedCaseInsensitiveContains("right") {
            return "arrow.right.circle.fill"
        }

        return "speaker.wave.2.fill"
    }
}

#Preview {
    ContentView(previewImage: PreviewImageLoader.images8Reference)
}

private enum PreviewImageLoader {
    static var images8Reference: UIImage? {
        let path = "/Users/luizformariz/Documents/New project/PosicionaAI/PosicionaAI/PreviewSupport/images-8.jpeg"
        return UIImage(contentsOfFile: path)
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}
