import SwiftUI

struct ImagePreviewView: View {
    let image: NSImage
    @EnvironmentObject var appState: AppState
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.showImagePreview = false
                }

            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(5.0, max(0.5, lastScale * value))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )

            VStack {
                HStack {
                    Spacer()

                    Button(action: { appState.showImagePreview = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                Spacer()

                HStack(spacing: 20) {
                    Button(action: { scale = max(0.5, scale - 0.2); lastScale = scale }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 20))
                    }
                    Text("\(Int(scale * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50)
                    Button(action: { scale = min(5.0, scale + 0.2); lastScale = scale }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 20))
                    }
                    Button(action: { scale = 1.0; lastScale = 1.0; offset = .zero; lastOffset = .zero }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
