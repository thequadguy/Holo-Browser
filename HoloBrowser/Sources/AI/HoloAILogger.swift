import Foundation
import Combine
import SwiftUI

public enum AILogActionType: String {
    case contextExtracted = "Context Extracted"
    case blockedByScanner = "Blocked by Scanner"
    case transmittedToProvider = "Transmitted to API"
    case memorySaved = "Memory Saved"
    case actionExecuted = "Action Executed"
}

public struct AITransparencyLogEntry: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let actionType: AILogActionType
    public let details: String
    public let payloadPreview: String?
}

@MainActor
public final class HoloAILogger: ObservableObject {
    public static let shared = HoloAILogger()
    
    @Published public private(set) var logs: [AITransparencyLogEntry] = []
    
    private init() {}
    
    public func log(action: AILogActionType, details: String, payload: String? = nil) {
        let entry = AITransparencyLogEntry(
            timestamp: Date(),
            actionType: action,
            details: details,
            payloadPreview: payload
        )
        logs.insert(entry, at: 0)
        
        // Keep last 100
        if logs.count > 100 {
            logs.removeLast(logs.count - 100)
        }
    }
    
    public func clear() {
        logs.removeAll()
    }
}

public struct AITransparencyPanelView: View {
    @StateObject private var logger = HoloAILogger.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("AI Activity Transparency")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button("Clear") {
                    logger.clear()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.black.opacity(0.1))
            
            if logger.logs.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32))
                        .foregroundColor(.green.opacity(0.6))
                        .padding(.bottom, 8)
                    Text("No AI activity recorded in this session.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(logger.logs) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.actionType.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorForType(log.actionType))
                            Spacer()
                            Text(log.timestamp, style: .time)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(log.details)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        
                        if let payload = log.payloadPreview, !payload.isEmpty {
                            Text(payload)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
    
    private func colorForType(_ type: AILogActionType) -> Color {
        switch type {
        case .blockedByScanner: return .red
        case .transmittedToProvider: return .blue
        case .memorySaved: return .purple
        case .actionExecuted: return .orange
        case .contextExtracted: return .secondary
        }
    }
}
