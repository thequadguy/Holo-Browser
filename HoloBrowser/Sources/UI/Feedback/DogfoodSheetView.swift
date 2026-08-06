import SwiftUI

/// Fast-access founder and QA dogfooding feedback sheet.
public struct DogfoodSheetView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @ObservedObject private var dogfoodManager = DogfoodReportManager.shared
    
    @State private var category: DogfoodCategory = .bug
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var showConfirmation: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Founder Dogfooding Feedback")
                        .font(.headline)
                    Text("Local feedback collector for founder & internal QA dogfooding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Category Picker
            Picker("Category", selection: $category) {
                ForEach(DogfoodCategory.allCases) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            
            // Title Field
            TextField("Issue Title / Summary", text: $title)
                .textFieldStyle(.roundedBorder)
            
            // Details Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Details & Reproduction Steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $details)
                    .font(.system(size: 12))
                    .frame(minHeight: 90, maxHeight: 140)
                    .border(Color.secondary.opacity(0.2), width: 1)
                    .cornerRadius(4)
            }
            
            // Auto-Captured Metadata Preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Auto-Captured Local System Context:")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text("Version: \(BuildConfiguration.appVersion)")
                    Text("Profile: \(viewModel.profileManager.activeProfile.name)")
                    Text("Tabs: \(viewModel.tabManager.tabs.count)")
                    Text("RAM: \(formattedMemory()) MB")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Submit Local Report") {
                    dogfoodManager.submitReport(
                        category: category,
                        title: title,
                        details: details,
                        activeProfileName: viewModel.profileManager.activeProfile.name,
                        openTabCount: viewModel.tabManager.tabs.count
                    )
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500)
        .alert("Report Saved Locally", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("Dogfooding feedback saved to Application Support/HoloBrowser/dogfood_reports.json.")
        }
    }
    
    private func formattedMemory() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return String(format: "%.1f", Double(info.resident_size)/(1024.0*1024.0))
        }
        return "N/A"
    }
}
