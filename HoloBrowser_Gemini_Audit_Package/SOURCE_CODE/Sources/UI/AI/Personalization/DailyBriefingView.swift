import SwiftUI

/// Opt-in morning daily briefing summary card.
public struct DailyBriefingView: View {
    let briefing: DailyBriefing
    let onDismiss: () -> Void
    
    public init(briefing: DailyBriefing, onDismiss: @escaping () -> Void) {
        self.briefing = briefing
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("Holo AI Daily Briefing")
                        .font(.headline)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(briefing.greeting)
                .font(.system(size: 12, weight: .semibold))
            
            HStack(spacing: 12) {
                VStack {
                    Text("\(briefing.openResearchCount)")
                        .font(.title3)
                        .bold()
                    Text("Active Research")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                
                VStack {
                    Text("\(briefing.unreadReadingCount)")
                        .font(.title3)
                        .bold()
                    Text("Unread Articles")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
            }
            
            HStack {
                Text("Frequent Topics:")
                    .font(.caption)
                    .bold()
                ForEach(briefing.topTopics, id: \.self) { topic in
                    Text(topic)
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(
            VisualEffectViewWrapper(material: .hudWindow, blendingMode: .withinWindow)
                .cornerRadius(10)
        )
        .shadow(radius: 4)
        .frame(maxWidth: 480)
    }
}
