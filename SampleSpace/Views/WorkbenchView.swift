import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The Workbench: a Quarto document of your own, on your own data, with no checks or scoring.
/// Add your CSV or SPSS files, write the report, knit it with Run and render it with Quarto.
/// It's the Dissertation Dry Run without the Crew Log: the place to try your real analysis.
struct WorkbenchView: View {
    @Environment(GameModel.self) private var model
    @Environment(\.codeFontSize) private var codeFontSize
    @State private var files: [URL] = []
    @State private var confirmTemplate = false
    @State private var fileToRemove: URL?
    @State private var problem: String?

    var body: some View {
        let session = model.workbenchSession()
        ZStack {
            StarfieldView(animated: false)
            HSplitView {
                dataPanel
                    .frame(minWidth: 240, idealWidth: 280, maxWidth: 360)
                    .background(.ultraThinMaterial)
                VSplitView {
                    VStack(spacing: 0) {
                        actionBar(session)
                        Divider()
                        CodeEditor(text: Bindable(session).code, language: .quarto, fontSize: codeFontSize)
                    }
                    .frame(minHeight: 240, idealHeight: 420)
                    OutputPanel(session: session)
                        .frame(minHeight: 160, idealHeight: 300)
                }
                .frame(minWidth: 520)
            }
        }
        .navigationTitle("Workbench")
        .navigationSubtitle("Your own report, on your own data")
        .onAppear(perform: refresh)
        .onDisappear { session.cancel() }
        .confirmationDialog("Start again from the template?", isPresented: $confirmTemplate) {
            Button("Use Template", role: .destructive) { session.reset() }
        } message: {
            Text("Your document will be replaced by the starting template. You can undo with ⌘Z.")
        }
        .confirmationDialog("Move \(fileToRemove?.lastPathComponent ?? "this file") to the Trash?",
                            isPresented: Binding(get: { fileToRemove != nil }, set: { if !$0 { fileToRemove = nil } })) {
            Button("Move to Trash", role: .destructive) {
                if let url = fileToRemove { remove(url) }
            }
        } message: {
            Text("This removes the Workbench's copy only; your original file stays where it was.")
        }
    }

    private var dataPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your data").font(.headline)
            Text("Files here are in R's working directory, so `read_csv(\"file.csv\")` or `haven::read_sav(\"file.sav\")` finds them. They stay on this Mac.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if files.isEmpty {
                Text("No files yet.").font(.callout).foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(files, id: \.self) { url in
                            HStack {
                                Image(systemName: icon(for: url)).foregroundStyle(Theme.accent)
                                Text(url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                                    .textSelection(.enabled)
                                Spacer()
                                Button { fileToRemove = url } label: { Image(systemName: "minus.circle") }
                                    .buttonStyle(.borderless)
                                    .help("Remove \(url.lastPathComponent) from the Workbench")
                                    .accessibilityLabel("Remove \(url.lastPathComponent)")
                            }
                            .font(.callout)
                        }
                    }
                }
            }
            HStack {
                Button { addFiles() } label: { Label("Add Data Files…", systemImage: "plus") }
                Button { NSWorkspace.shared.open(GameModel.workbenchFolder) } label: { Image(systemName: "folder") }
                    .help("Show the Workbench folder in Finder")
                    .accessibilityLabel("Show the Workbench folder in Finder")
            }
            if let problem {
                Text(problem).font(.caption).foregroundStyle(Theme.fail)
            }
            Divider()
            Text("Tips").font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                tip("**Run** knits the document here, fast, for checking your numbers.")
                tip("**Render** runs Quarto for the finished report (HTML, or Word with `format: docx`).")
                tip("Never type a result: inline `` `r ` `` code keeps every number tied to the data.")
                tip("The Dissertation Dock's Dry Run walks through a whole report first.")
            }
            Spacer()
        }
        .padding(16)
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("•").foregroundStyle(Theme.accent)
            Text(AttributedString.inlineMarkdown(text)).font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func actionBar(_ session: LevelSession) -> some View {
        HStack(spacing: 8) {
            if session.isBusy {
                Button { session.cancel() } label: { Label("Stop", systemImage: "stop.fill") }
                    .keyboardShortcut(".", modifiers: .command)
                    .help("Stop R (⌘.)")
            } else {
                Button { session.run() } label: { Label("Run", systemImage: "play.fill") }
                    .keyboardShortcut(.return, modifiers: .command)
                    .help("Knit the document and show the report (⌘↩)")
            }
            Divider().frame(height: 18)
            RenderControls(session: session, folderName: "workbench", dataDirectory: GameModel.workbenchFolder)
            Spacer()
            Button { confirmTemplate = true } label: { Label("Template", systemImage: "doc.badge.arrow.up") }
                .disabled(session.isStarterCode)
                .help("Start again from the results-chapter template")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.3))
    }

    private func icon(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "sav", "por", "zsav": "tablecells.badge.ellipsis"
        case "csv", "tsv", "txt": "tablecells"
        case "xlsx", "xls": "tablecells.fill"
        default: "doc"
        }
    }

    private func refresh() {
        files = GameModel.workbenchDataFiles()
    }

    private func addFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Choose data files to copy into the Workbench (CSV, SPSS .sav, Excel…)"
        panel.prompt = "Add"
        guard panel.runModal() == .OK else { return }
        problem = nil
        for url in panel.urls {
            let target = GameModel.workbenchFolder.appending(path: url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: target.path) {
                    try FileManager.default.removeItem(at: target)
                }
                try FileManager.default.copyItem(at: url, to: target)
            } catch {
                problem = "Couldn't add \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
        refresh()
    }

    private func remove(_ url: URL) {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch {
            problem = "Couldn't remove \(url.lastPathComponent): \(error.localizedDescription)"
        }
        fileToRemove = nil
        refresh()
    }
}
