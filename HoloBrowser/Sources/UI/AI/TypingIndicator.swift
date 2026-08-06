import SwiftUI

/// Animated dot indicator shown when AI is streaming a response.
public struct TypingIndicator: View {
    @State private var animateDots: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.purple.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animateDots ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animateDots
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .onAppear {
            animateDots = true
        }
    }
}
