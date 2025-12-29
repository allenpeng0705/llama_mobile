import UIKit
import LlamaMobileSDK

class ViewController: UIViewController {
    
    private let llamaMobile = LlamaMobile()
    private var isInitialized = false
    
    // UI Elements
    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.backgroundColor = .secondarySystemBackground
        return textView
    }()
    
    private let promptTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter prompt..."
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Generate", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        return button
    }()
    
    private let initializeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Initialize SDK", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(textView)
        view.addSubview(promptTextField)
        view.addSubview(generateButton)
        view.addSubview(initializeButton)
        
        NSLayoutConstraint.activate([
            initializeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            initializeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            initializeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            initializeButton.heightAnchor.constraint(equalToConstant: 50),
            
            textView.topAnchor.constraint(equalTo: initializeButton.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: promptTextField.topAnchor, constant: -20),
            
            promptTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            promptTextField.trailingAnchor.constraint(equalTo: generateButton.leadingAnchor, constant: -20),
            promptTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            promptTextField.heightAnchor.constraint(equalToConstant: 50),
            
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            generateButton.widthAnchor.constraint(equalToConstant: 100),
            generateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        initializeButton.addTarget(self, action: #selector(initializeSDK), for: .touchUpInside)
        generateButton.addTarget(self, action: #selector(generateCompletion), for: .touchUpInside)
        promptTextField.delegate = self
    }
    
    @objc private func initializeSDK() {
        appendLog("Initializing Llama Mobile SDK...")
        
        // Replace with your model path
        // Note: In a real app, you would bundle the model or download it
        let modelPath = Bundle.main.path(forResource: "model", ofType: "gguf") ?? ""
        
        if modelPath.isEmpty {
            appendLog("Error: Model not found. Please add a model.gguf file to your app bundle.")
            return
        }
        
        let params = LlamaMobile.InitParams(
            modelPath: modelPath,
            chatTemplate: nil,
            nCtx: 2048,
            nBatch: 512,
            nUbatch: 512,
            nGpuLayers: 4,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttn: true,
            cacheTypeK: nil,
            cacheTypeV: nil,
            progressCallback: { progress in
                DispatchQueue.main.async {
                    self.appendLog("Initialization progress: \(String(format: "%.0f%%", progress * 100))")
                }
            }
        )
        
        let success = llamaMobile.initialize(with: params)
        
        DispatchQueue.main.async {
            if success {
                self.appendLog("✅ SDK initialized successfully!")
                self.initializeButton.isEnabled = false
                self.generateButton.isEnabled = true
            } else {
                self.appendLog("❌ Failed to initialize SDK.")
            }
        }
    }
    
    @objc private func generateCompletion() {
        guard let prompt = promptTextField.text, !prompt.isEmpty else {
            appendLog("Please enter a prompt.")
            return
        }
        
        appendLog("\nGenerating completion for: \(prompt)")
        appendLog("\n---\n")
        
        generateButton.isEnabled = false
        promptTextField.resignFirstResponder()
        
        let params = LlamaMobile.CompletionParams(
            prompt: prompt,
            nPredict: 128,
            nThreads: 4,
            seed: -1,
            temperature: 0.8,
            topK: 40,
            topP: 0.9,
            minP: 0.05,
            typicalP: 1.0,
            penaltyLastN: 64,
            penaltyRepeat: 1.1,
            penaltyFreq: 0.0,
            penaltyPresent: 0.0,
            mirostat: 0,
            mirostatTau: 5.0,
            mirostatEta: 0.1,
            ignoreEos: false,
            nProbs: 0,
            stopSequences: [],
            grammar: nil,
            tokenCallback: { token in
                DispatchQueue.main.async {
                    self.appendLog(token, withNewLine: false)
                }
                return true
            }
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let result = self.llamaMobile.completion(with: params) {
                DispatchQueue.main.async {
                    self.appendLog("\n\n---")
                    self.appendLog("✅ Completion finished!")
                    self.appendLog("Tokens predicted: \(result.tokensPredicted)")
                    self.appendLog("Tokens evaluated: \(result.tokensEvaluated)")
                    self.generateButton.isEnabled = true
                }
            } else {
                DispatchQueue.main.async {
                    self.appendLog("\n❌ Failed to generate completion.")
                    self.generateButton.isEnabled = true
                }
            }
        }
    }
    
    private func appendLog(_ text: String, withNewLine: Bool = true) {
        let formattedText = withNewLine ? (text + "\n") : text
        textView.text.append(formattedText)
        
        // Scroll to bottom
        let bottomRange = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(bottomRange)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if isInitialized {
            generateCompletion()
        }
        return true
    }
}
