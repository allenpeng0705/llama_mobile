//
//  ContentView.swift
//  iOSSDKExample
//
//  v2 (LlamaEngine) demo: open a GGUF, chat with streaming + abort.
//  Legacy v1 LlamaMobile facade was removed on the v2 branch
//  (see docs/v1-purge-workplan.md).
//

import SwiftUI

struct DiscoveredModel: Identifiable {
    let name: String
    let path: String
    var id: String { path }
}

struct ChatBubble: Identifiable {
    enum Role { case user, assistant, system }
    let id = UUID()
    let role: Role
    var text: String
}

@MainActor
final class DemoAppModel: ObservableObject {
    @Published var models: [DiscoveredModel] = []
    @Published var selectedModelPath = ""
    @Published var isModelLoaded = false
    @Published var engineStatus = "not loaded"
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var bubbles: [ChatBubble] = []
    @Published var input = ""
    @Published var errorMessage: String?

    private var engine: LlamaEngine?
    private var activeRequestId: UInt64?
    private var stopRequested = false

    init() {
        refreshModels()
    }

    // MARK: Model discovery (Documents/models + simulator dev fixtures)

    func refreshModels() {
        var found: [DiscoveredModel] = []
        let dirs = modelDirectories()
        for dir in dirs {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for f in files where f.hasSuffix(".gguf") {
                let path = (dir as NSString).appendingPathComponent(f)
                if !found.contains(where: { $0.path == path }) {
                    found.append(DiscoveredModel(name: f, path: path))
                }
            }
        }
        models = found.sorted { $0.name < $1.name }
        if models.first(where: { $0.path == selectedModelPath }) == nil {
            selectedModelPath = models.first?.path ?? ""
        }
    }

    private func modelDirectories() -> [String] {
        var dirs: [String] = []
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let modelsDir = documents.appendingPathComponent("models").path
            try? FileManager.default.createDirectory(atPath: modelsDir, withIntermediateDirectories: true)
            dirs.append(modelsDir)
        }
        if let bundle = Bundle.main.resourceURL {
            dirs.append(bundle.appendingPathComponent("models").path)
        }
        // Simulator/dev convenience: expose the llama_mobile repo fixture dir
        // when it is reachable from this host (device builds ignore it).
        let devFixtures = "/Users/shileipeng/Documents/mygithub/llama_mobile/models"
        if FileManager.default.fileExists(atPath: devFixtures) {
            dirs.append(devFixtures)
        }
        return dirs
    }

    // MARK: Load / unload (async factory never blocks the caller)

    func loadModel() async {
        guard !selectedModelPath.isEmpty else { return }
        engine?.close()
        engine = nil
        isModelLoaded = false
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var config = LlamaModelConfig(modelPath: selectedModelPath)
        config.engine = .auto
        config.nGpuLayers = 99
        config.nCtx = 2048
        config.flags = [.mmap, .chat]
        config.loadProgress = { progress in
            Task { @MainActor in
                self.engineStatus = String(format: "loading… %.0f%%", progress * 100)
            }
            return true
        }
        do {
            engine = try await LlamaEngine.open(config)
            isModelLoaded = true
            engineStatus = "loaded"
            bubbles = [ChatBubble(role: .system, text: "Model ready. Ask anything!")]
        } catch let e as LlamaError {
            errorMessage = "Load failed: \(e)"
        } catch {
            errorMessage = "Load failed: \(error)"
        }
    }

    func unloadModel() {
        engine?.close()
        engine = nil
        isModelLoaded = false
        isStreaming = false
        engineStatus = "not loaded"
        bubbles = []
    }

    private var didAutoDemo = false

    /// One-shot on-appear demo: load the first bundled model and send a short
    /// message so Metal (nGpuLayers=50) is exercised without manual taps.
    func autoDemoOnce() {
        if didAutoDemo { return }
        didAutoDemo = true
        guard let first = models.first else { return }
        selectedModelPath = first.path
        Task {
            await loadModel()
            guard isModelLoaded, let engine else {
                engineStatus = "auto demo: load failed"
                return
            }
            // 1) Chat (Metal, already proven at 99 layers)
            do {
                var req = LlamaGenerationRequest(messages: [LlamaMessage(role: "user", content: "Say hello in one short sentence.")])
                req.maxTokens = 24
                req.sampling.temperature = 0
                let r = try await engine.generate(req)
                bubbles.append(ChatBubble(role: .assistant, text: r.text))
                engineStatus = "1/4 chat done (stop \(r.stopReason))"
            } catch {
                bubbles.append(ChatBubble(role: .assistant, text: "1/4 chat FAILED: \(error)"))
                engineStatus = "auto demo failed at chat"
                return
            }
            // 2) Embedding
            await api("2/4 embed", step: { () async throws -> String in
                let e = try await self.openBundled("Qwen3-Embedding-0.6B-Q8_0.gguf", flags: [.embedding])
                defer { e.close() }
                let rows = try e.embed(["hello llama"])
                return "dim=\(rows.first?.count ?? -1) rows=\(rows.count)"
            })
            // 3) Vision (multimodal image caption)
            await api("3/4 vision", step: { () async throws -> String in
                let v = try await self.openBundled("SmolVLM-256M-Instruct-Q8_0.gguf", flags: [.chat])
                defer { v.close() }
                try v.initMultimodal(mmprojPath: self.bundlePath("mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"))
                var req = LlamaGenerationRequest(prompt: "Describe this picture in a few words.")
                req.media = [LlamaMedia(path: self.bundlePath("image.jpg"))]
                req.maxTokens = 32
                req.sampling.temperature = 0
                let r = try await v.generate(req)
                return r.text
            })
            // 4) TTS speak (PCM)
            await api("4/4 tts", step: { () async throws -> String in
                let t = try await self.openBundled("OuteTTS-0.2-500M-Q6_K.gguf", flags: [])
                defer { t.close() }
                try t.ttsInit(vocoderModelPath: self.bundlePath("WavTokenizer-Large-75-F16.gguf"))
                let out = try t.ttsSpeak(text: "Hello from on device speech.", sampleRate: 24000, speed: 1.0)
                return "pcm=\(out.pcm.count) (\(String(format: "%.2f", Double(out.pcm.count)/24000.0))s)"
            })
            engineStatus = "auto demo complete"
            bubbles.append(ChatBubble(role: .assistant, text: "ALL APIs OK"))
        }
    }

    private func bundlePath(_ name: String) -> String {
        let dir = Bundle.main.resourceURL?.appendingPathComponent("models").path ?? ""
        return (dir as NSString).appendingPathComponent(name)
    }

    private func openBundled(_ name: String, flags: LlamaContextFlags) async throws -> LlamaEngine {
        var c = LlamaModelConfig(modelPath: bundlePath(name))
        c.engine = .auto
        c.nGpuLayers = 99
        c.nCtx = 2048
        c.flags = flags
        return try await LlamaEngine.open(c)
    }

    private func api(_ label: String, step: @escaping () async throws -> String) async {
        do {
            let msg = try await step()
            bubbles.append(ChatBubble(role: .assistant, text: "\(label): OK — \(msg)"))
        } catch {
            bubbles.append(ChatBubble(role: .assistant, text: "\(label): FAILED — \(error)"))
        }
    }

    // MARK: Chat with streaming + abort (threading contract §8)

    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let engine else { return }
        input = ""
        stopRequested = false

        bubbles.append(ChatBubble(role: .user, text: text))
        let assistantBubble = ChatBubble(role: .assistant, text: "")
        bubbles.append(assistantBubble)
        let assistantIndex = bubbles.count - 1

        var req = LlamaGenerationRequest(messages: [LlamaMessage(role: "user", content: text)])
        req.maxTokens = 256
        req.sampling.temperature = 0.8

        isStreaming = true
        engineStatus = "generating"
        defer {
            isStreaming = false
            engineStatus = "idle"
            activeRequestId = nil
        }

        do {
            for try await event in engine.generateStream(req) {
                if Task.isCancelled { break }
                switch event {
                case .started(let id):
                    activeRequestId = id
                case .token(let token):
                    bubbles[assistantIndex].text += token
                case .done(let result):
                    if result.stopReason == .aborted {
                        bubbles[assistantIndex].text += "\n[stopped]"
                    }
                case .failed(let e):
                    bubbles[assistantIndex].text += "\n[error: \(e)]"
                }
            }
        } catch {
            bubbles[assistantIndex].text += "\n[stream error]"
        }
    }

    /// Thread-safe abort: stops exactly the request that yielded `.started(id)`.
    func stop() {
        guard let engine, let id = activeRequestId else { return }
        stopRequested = true
        do {
            try engine.abort(requestId: id)
        } catch {
            engineStatus = "abort: \(error)"
        }
    }
}

struct ContentView: View {
    @StateObject private var model = DemoAppModel()

    var body: some View {
        NavigationView {
            List {
                Section("Model") {
                    Picker("GGUF", selection: $model.selectedModelPath) {
                        ForEach(model.models) { m in
                            Text(m.name).tag(m.path)
                        }
                    }
                    if model.models.isEmpty {
                        Text("Copy a .gguf into the app's Documents/models (Files app).")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Button(model.isModelLoaded ? "Unload" : "Load") {
                        if model.isModelLoaded {
                            model.unloadModel()
                        } else {
                            Task { await model.loadModel() }
                        }
                    }
                    .disabled(model.selectedModelPath.isEmpty || model.isLoading)
                    if model.isLoading { ProgressView().progressViewStyle(.linear) }
                    Text(model.engineStatus).font(.footnote).foregroundColor(.secondary)
                }

                Section("Chat") {
                    ForEach(model.bubbles) { bubble in
                        HStack {
                            if bubble.role == .user { Spacer(minLength: 40) }
                            Text(bubble.text)
                                .textSelection(.enabled)
                                .padding(8)
                                .background(bubble.role == .user ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            if bubble.role == .assistant { Spacer(minLength: 40) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onAppear { model.autoDemoOnce() }
            .navigationTitle("LlamaEngine v2")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if model.isStreaming {
                        Button("Stop") { model.stop() }
                    } else {
                        Button("Refresh") { model.refreshModels() }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Message", text: $model.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!model.isModelLoaded)
                    Button("Send") {
                        Task { await model.send() }
                    }
                    .disabled(!model.isModelLoaded || model.input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(.bar)
            }
            .alert("Error", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }
}
