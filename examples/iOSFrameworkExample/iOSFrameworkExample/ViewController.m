//
//  ViewController.m
//  iOSFrameworkExample
//
//  Created by on 2024-12-24.
//

#import "ViewController.h"
#include <sys/stat.h>

@interface ViewController ()

@end

// Static callback functions for model operations

static void progress_callback(float progress) {
    // Since we can't get context in this callback, we'll just log progress
    NSLog(@"Model loading progress: %.2f%%", progress * 100);
}

// We'll use a static reference since we can't pass context through the API
static ViewController *tokenCallbackViewController = nil;

static bool token_callback(const char* token) {
    if (!tokenCallbackViewController) return false;
    
    if (!tokenCallbackViewController.isGenerating) {
        return false;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{                
        NSString *tokenStr = [NSString stringWithUTF8String:token];
        [tokenCallbackViewController.currentOutput appendString:tokenStr];
        [tokenCallbackViewController.outputTextView setText:[tokenCallbackViewController.outputTextView.text stringByAppendingString:tokenStr]];
    });
    
    return true;
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"DEBUG: viewDidLoad called");
    NSLog(@"DEBUG: View bounds: %@", NSStringFromCGRect(self.view.bounds));
    NSLog(@"DEBUG: View superview: %@", self.view.superview);
    NSLog(@"DEBUG: View backgroundColor: %@", self.view.backgroundColor);
    NSLog(@"DEBUG: Number of subviews: %lu", (unsigned long)self.view.subviews.count);
    
    // Set a light background color for better visibility
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Create debug log text view at the top of the screen
    self.debugLogTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.debugLogTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.debugLogTextView.backgroundColor = [UIColor lightGrayColor];
    self.debugLogTextView.textColor = [UIColor blackColor];
    self.debugLogTextView.font = [UIFont systemFontOfSize:14];
    self.debugLogTextView.textAlignment = NSTextAlignmentLeft;
    self.debugLogTextView.editable = NO;
    self.debugLogTextView.scrollEnabled = YES;
    self.debugLogTextView.layer.borderWidth = 1.0;
    self.debugLogTextView.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view insertSubview:self.debugLogTextView atIndex:0];
    
    // Layout constraints for debug log text view
    // Position debug log below output text view
    NSLayoutConstraint *topConstraint = [self.debugLogTextView.topAnchor constraintEqualToAnchor:self.outputTextView.bottomAnchor constant:8.0];
    NSLayoutConstraint *leadingConstraint = [self.debugLogTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0];
    NSLayoutConstraint *trailingConstraint = [self.debugLogTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0];
    NSLayoutConstraint *heightConstraint = [self.debugLogTextView.heightAnchor constraintEqualToConstant:100.0]; // Set height
    [NSLayoutConstraint activateConstraints:@[topConstraint, leadingConstraint, trailingConstraint, heightConstraint]];
    
    // Improve UI visibility with enhanced styling
    
    // Output text view - improve visibility
    [self.outputTextView setTextColor:[UIColor blackColor]];
    [self.outputTextView setBackgroundColor:[UIColor whiteColor]];
    [self.outputTextView setFont:[UIFont systemFontOfSize:16]];
    [self.outputTextView setTextAlignment:NSTextAlignmentLeft];
    
    // Reposition promptTextField below debugLogTextView
    NSLayoutConstraint *promptTopConstraint = [self.promptTextField.topAnchor constraintEqualToAnchor:self.debugLogTextView.bottomAnchor constant:16.0];
    promptTopConstraint.priority = UILayoutPriorityRequired;
    [promptTopConstraint setActive:YES];
    
    // Prompt text field - improve visibility and appearance
    [self.promptTextField setTextColor:[UIColor blackColor]];
    [self.promptTextField setBackgroundColor:[UIColor whiteColor]];
    [self.promptTextField setBorderStyle:UITextBorderStyleNone]; // Remove system border to use custom layer border
    [self.promptTextField setFont:[UIFont systemFontOfSize:16]];
    // Fix placeholder color
    [self.promptTextField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Enter your prompt here..." attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}]];
    [self.promptTextField.layer setCornerRadius:8.0];
    [self.promptTextField.layer setBorderWidth:1.0];
    [self.promptTextField.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.promptTextField setClipsToBounds:YES]; // Ensure content respects corner radius
    
    // Set button styles for better visibility
    NSArray *buttons = @[self.generateButton, self.completeButton, self.conversationButton, self.embeddingButton, self.initializeButton, self.multimodalButton, self.clearButton];
    
    for (UIButton *button in buttons) {
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        [button setFont:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]];
        button.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        [button.layer setCornerRadius:8.0];
        [button.layer setBorderWidth:1.0];
        [button.layer setBorderColor:[UIColor blackColor].CGColor];
        [button setContentEdgeInsets:UIEdgeInsetsMake(8, 16, 8, 16)];
    }
    
    // Set activity indicator color
    [self.activityIndicator setColor:[UIColor blackColor]];
    
    self.modelContext = NULL;
    self.currentOutput = [NSMutableString string];
    self.isGenerating = NO;
    
    // Disable buttons until model is initialized
    [self updateButtonStates];
    
    // Add keyboard handling
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"DEBUG: viewWillAppear called");
    NSLog(@"DEBUG: View bounds in viewWillAppear: %@", NSStringFromCGRect(self.view.bounds));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"DEBUG: viewDidAppear called");
    NSLog(@"DEBUG: View bounds in viewDidAppear: %@", NSStringFromCGRect(self.view.bounds));
    NSLog(@"DEBUG: View window in viewDidAppear: %@", self.view.window);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"DEBUG: viewWillDisappear called");
    
    // Clean up model context when view disappears
    if (self.modelContext != NULL) {
        llama_mobile_free(self.modelContext);
        self.modelContext = NULL;
    }
    
    // Remove keyboard observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
    // Adjust view when keyboard appears
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.outputTextView.contentInset = UIEdgeInsetsMake(0, 0, keyboardFrame.size.height, 0);
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // Reset view when keyboard disappears
    self.outputTextView.contentInset = UIEdgeInsetsZero;
}

// MARK: - Model Initialization

- (IBAction)initializePressed:(id)sender {
    if (self.modelContext != NULL) {
        llama_mobile_free(self.modelContext);
        self.modelContext = NULL;
    }
    
    [self.activityIndicator startAnimating];
    [self.outputTextView setText:@"Initializing model...\n"];
    
    // Get model path from app bundle - DEBUG VERSION WITH EXTENSIVE LOGGING
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    // Log bundle information
    NSLog(@"DEBUG: Bundle path: %@", [mainBundle bundlePath]);
    NSLog(@"DEBUG: Bundle executable: %@", [mainBundle executablePath]);
    NSLog(@"DEBUG: Bundle identifier: %@", [mainBundle bundleIdentifier]);
    
    // Try to get model path with different approaches - prioritize bundle root first (where model was confirmed to exist)
    NSString *modelPath = [mainBundle pathForResource:@"SmolLM-360M-Instruct.Q6_K" ofType:@"gguf"];
    NSLog(@"DEBUG: Model path (simple): %@", modelPath);
    
    // Try with full filename in bundle root
    NSString *modelPathWithExtension = [mainBundle pathForResource:@"SmolLM-360M-Instruct.Q6_K.gguf" ofType:nil];
    NSLog(@"DEBUG: Model path (with extension in name): %@", modelPathWithExtension);
    
    
    // Try with full filename in models directory
    NSString *modelPathWithExtensionInModels = [mainBundle pathForResource:@"SmolLM-360M-Instruct.Q6_K.gguf" ofType:nil inDirectory:@"models"];
    NSLog(@"DEBUG: Model path (with extension in name in models): %@", modelPathWithExtensionInModels);
    
    // Try with lowercase path in bundle root
    NSString *modelPathLowercase = [mainBundle pathForResource:@"smollm-360m-instruct.q6_k" ofType:@"gguf"];
    NSLog(@"DEBUG: Model path (lowercase): %@", modelPathLowercase);
    
    // Try with normal case in models directory
    NSString *modelPathInModels = [mainBundle pathForResource:@"SmolLM-360M-Instruct.Q6_K" ofType:@"gguf" inDirectory:@"models"];
    NSLog(@"DEBUG: Model path (in models): %@", modelPathInModels);
    
    // Try with lowercase in models directory
    NSString *modelPathInModelsLowercase = [mainBundle pathForResource:@"smollm-360m-instruct.q6_k" ofType:@"gguf" inDirectory:@"models"];
    NSLog(@"DEBUG: Model path (lowercase in models): %@", modelPathInModelsLowercase);
    
    // List all files in the bundle root for debugging
    NSError *error = nil;
    NSArray *bundleFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[mainBundle bundlePath] error:&error];
    if (bundleFiles) {
        NSLog(@"DEBUG: Bundle root contents (%lu files):", (unsigned long)[bundleFiles count]);
        for (NSString *file in bundleFiles) {
            NSLog(@"DEBUG:   - %@", file);
        }
    } else {
        NSLog(@"DEBUG: Error listing bundle contents: %@", error);
    }
    
    // Check for models directory contents
    NSString *modelsDirPath = [[mainBundle bundlePath] stringByAppendingPathComponent:@"models"];
    NSLog(@"DEBUG: Checking models directory: %@", modelsDirPath);
    NSArray *modelsDirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:modelsDirPath error:&error];
    if (modelsDirFiles) {
        NSLog(@"DEBUG: Models directory contents (%lu files):", (unsigned long)[modelsDirFiles count]);
        for (NSString *file in modelsDirFiles) {
            NSLog(@"DEBUG:   - %@", file);
        }
    } else {
        NSLog(@"DEBUG: Error listing models directory: %@", error);
    }
    
    // Check if any model path works - prioritize bundle root first (where model was confirmed to exist)
    NSString *finalModelPath = nil;
    
    // Log file existence checks - update order to match priority
    NSLog(@"DEBUG: Checking file existence at simple path: %@ -> %d", modelPath, [[NSFileManager defaultManager] fileExistsAtPath:modelPath]);
    NSLog(@"DEBUG: Checking file existence at path with full name: %@ -> %d", modelPathWithExtension, [[NSFileManager defaultManager] fileExistsAtPath:modelPathWithExtension]);
    NSLog(@"DEBUG: Checking file existence at lowercase path: %@ -> %d", modelPathLowercase, [[NSFileManager defaultManager] fileExistsAtPath:modelPathLowercase]);
    NSLog(@"DEBUG: Checking file existence at models directory path: %@ -> %d", modelPathInModels, [[NSFileManager defaultManager] fileExistsAtPath:modelPathInModels]);
    NSLog(@"DEBUG: Checking file existence at models directory with full name: %@ -> %d", modelPathWithExtensionInModels, [[NSFileManager defaultManager] fileExistsAtPath:modelPathWithExtensionInModels]);
    NSLog(@"DEBUG: Checking file existence at lowercase models path: %@ -> %d", modelPathInModelsLowercase, [[NSFileManager defaultManager] fileExistsAtPath:modelPathInModelsLowercase]);
    
    // Update order to prioritize bundle root paths first
    if (modelPath && [[NSFileManager defaultManager] fileExistsAtPath:modelPath]) {
        finalModelPath = modelPath;
        NSLog(@"DEBUG: Model found at simple path");
    } else if (modelPathWithExtension && [[NSFileManager defaultManager] fileExistsAtPath:modelPathWithExtension]) {
        finalModelPath = modelPathWithExtension;
        NSLog(@"DEBUG: Model found at path with full name");
    } else if (modelPathLowercase && [[NSFileManager defaultManager] fileExistsAtPath:modelPathLowercase]) {
        finalModelPath = modelPathLowercase;
        NSLog(@"DEBUG: Model found at lowercase path");
    } else if (modelPathInModels && [[NSFileManager defaultManager] fileExistsAtPath:modelPathInModels]) {
        finalModelPath = modelPathInModels;
        NSLog(@"DEBUG: Model found at models directory path");
    } else if (modelPathWithExtensionInModels && [[NSFileManager defaultManager] fileExistsAtPath:modelPathWithExtensionInModels]) {
        finalModelPath = modelPathWithExtensionInModels;
        NSLog(@"DEBUG: Model found at models directory path with full name");
    } else if (modelPathInModelsLowercase && [[NSFileManager defaultManager] fileExistsAtPath:modelPathInModelsLowercase]) {
        finalModelPath = modelPathInModelsLowercase;
        NSLog(@"DEBUG: Model found at lowercase path in models directory");
    }
    
    if (!finalModelPath) {
        NSString *errorMsg = [NSString stringWithFormat:@"Error: Model file not found in app bundle. Check logs for bundle contents.\n"];
        [self.outputTextView setText:errorMsg];
        NSLog(@"ERROR: Model file not found in any expected location");
        [self.activityIndicator stopAnimating];
        return;
    }
    
    // Use the working model path
    modelPath = finalModelPath;
    NSLog(@"DEBUG: FINAL MODEL PATH BEING USED: %@", modelPath);
    // Prepend new content to show at the top
        [self prependDebugText:[NSString stringWithFormat:@"Trying to load model from: %@\n", modelPath]];
    
    // Initialize model in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
        // Enable verbose logging for debugging
        NSLog(@"DEBUG: Setting llama_mobile_verbose to true");
        llama_mobile_verbose = true;
        NSLog(@"DEBUG: llama_mobile_verbose value after setting: %d", llama_mobile_verbose);
        NSLog(@"DEBUG: About to call llama_mobile_init with path: %@", modelPath);
        NSLog(@"DEBUG: Path UTF8String: %s", [modelPath UTF8String]);
            
            // COMPREHENSIVE FILE ACCESS DIAGNOSTICS
            NSLog(@"=== BEGINNING COMPREHENSIVE FILE ACCESS DIAGNOSTICS ===");
            
            // Check if file exists and is readable
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL fileExists = [fileManager fileExistsAtPath:modelPath];
            BOOL isReadable = [fileManager isReadableFileAtPath:modelPath];
            BOOL isWritable = [fileManager isWritableFileAtPath:modelPath];
            BOOL isExecutable = [fileManager isExecutableFileAtPath:modelPath];
            
            NSLog(@"DEBUG: File exists: %d", fileExists);
            NSLog(@"DEBUG: File is readable: %d", isReadable);
            NSLog(@"DEBUG: File is writable: %d", isWritable);
            NSLog(@"DEBUG: File is executable: %d", isExecutable);
            
            if (!fileExists) {
                NSLog(@"ERROR: File does not exist at path: %@", modelPath);
                NSLog(@"DEBUG: Current working directory: %@", [fileManager currentDirectoryPath]);
            } else if (!isReadable) {
                NSLog(@"ERROR: File exists but is not readable: %@", modelPath);
            } else {
                NSLog(@"DEBUG: File exists and is readable: %@", modelPath);
                
                // Get detailed file attributes
                NSError *error = nil;
                NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:modelPath error:&error];
                if (error) {
                    NSLog(@"ERROR: Failed to get file attributes: %@", error.localizedDescription);
                } else {
                    // Log all available file attributes
                    for (NSString *key in fileAttributes) {
                        id value = [fileAttributes objectForKey:key];
                        NSLog(@"DEBUG: File attribute %@: %@", key, value);
                    }
                    
                    // Get specific attributes
                    unsigned long long fileSize = [fileAttributes fileSize];
                    NSLog(@"DEBUG: File size: %llu bytes (%.2f MB)", fileSize, (double)fileSize / (1024 * 1024));
                    
                    // Check file type
                    NSString *fileType = [fileAttributes fileType];
                    NSLog(@"DEBUG: File type: %@", fileType);
                    
                    // Check file permissions in more detail
                    NSMutableArray *permissions = [NSMutableArray array];
                    if (isReadable) [permissions addObject:@"readable"];
                    if (isWritable) [permissions addObject:@"writable"];
                    if (isExecutable) [permissions addObject:@"executable"];
                    NSLog(@"DEBUG: File permissions summary: %@", [permissions componentsJoinedByString:@", "]);
                }
            }
            
            // Test direct file opening with read access
            NSLog(@"DEBUG: Testing direct file opening with read access...");
            NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:modelPath];
            if (readHandle) {
                NSLog(@"DEBUG: SUCCESS: File opened successfully for reading");
                
                // Test reading some data from the file
                NSLog(@"DEBUG: Testing file reading...");
                NSData *testData = [readHandle readDataOfLength:1024];
                if (testData) {
                    NSLog(@"DEBUG: SUCCESS: Read %lu bytes from file", (unsigned long)[testData length]);
                    
                    // Check if we can read the GGUF header
                    if ([testData length] >= 4) {
                        char header[5];
                        [testData getBytes:header length:4];
                        header[4] = '\0';
                        NSLog(@"DEBUG: File header magic: %s", header);
                        if (strcmp(header, "GGUF") == 0) {
                            NSLog(@"DEBUG: SUCCESS: File has valid GGUF header");
                        } else {
                            NSLog(@"WARNING: File header is not GGUF: %s", header);
                        }
                    }
                } else {
                    NSLog(@"ERROR: Failed to read data from file");
                }
                
                [readHandle closeFile];
            } else {
                NSLog(@"ERROR: Failed to open file for reading");
            }
            
            // Test file reading with NSData
            NSLog(@"DEBUG: Testing file reading with NSData...");
            NSError *nsdataError = nil;
            NSData *fileData = [NSData dataWithContentsOfFile:modelPath options:NSDataReadingMappedIfSafe error:&nsdataError];
            if (fileData) {
                NSLog(@"DEBUG: SUCCESS: NSData read %lu bytes from file", (unsigned long)[fileData length]);
            } else {
                NSLog(@"ERROR: NSData failed to read file: %@", nsdataError.localizedDescription);
            }
            
            // Log the full path as a URL for additional debugging
            NSURL *fileURL = [NSURL fileURLWithPath:modelPath];
            NSLog(@"DEBUG: File URL: %@", fileURL);
            NSLog(@"DEBUG: URL file scheme: %@", [fileURL scheme]);
            NSLog(@"DEBUG: URL absolute string: %@", [fileURL absoluteString]);
            NSLog(@"DEBUG: URL path: %@", [fileURL path]);
            NSLog(@"DEBUG: URL isFileURL: %d", [fileURL isFileURL]);
            
            // Check if the file is actually accessible by attempting to stat it
            struct stat fileStat;
            if (stat([modelPath UTF8String], &fileStat) == 0) {
                NSLog(@"DEBUG: SUCCESS: stat() call succeeded");
                NSLog(@"DEBUG: stat - Size: %lld bytes", (long long)fileStat.st_size);
                NSLog(@"DEBUG: stat - Permissions: %o", fileStat.st_mode & 0777);
                NSLog(@"DEBUG: stat - Blocks: %lld", (long long)fileStat.st_blocks);
                NSLog(@"DEBUG: stat - Block size: %ld", (long)fileStat.st_blksize);
            } else {
                NSLog(@"ERROR: stat() call failed with errno: %d (%s)", errno, strerror(errno));
            }
            
            NSLog(@"=== END COMPREHENSIVE FILE ACCESS DIAGNOSTICS ===");
            
            // Add a safety delay to ensure logging is enabled
            sleep(1);
            
            // Detect if we're running on a simulator
            BOOL isSimulator = NO;
#if TARGET_IPHONE_SIMULATOR
            isSimulator = YES;
#endif
            
            // Use appropriate GPU layers: 0 for simulator, 20 for real device as requested by user
            int32_t gpuLayers = isSimulator ? 0 : 20;
            
            NSLog(@"DEBUG: Running on %@", isSimulator ? @"SIMULATOR" : @"REAL DEVICE");
            // Set up detailed parameters following user's example exactly
            llama_mobile_init_params_t params = {0}; // Initialize all fields to zero first
            params.model_path = [modelPath UTF8String];
            params.n_ctx = 2048;
            params.n_gpu_layers = gpuLayers;
            params.n_threads = 4;
            params.progress_callback = progress_callback;
            params.embedding = false;
            params.use_mmap = true;
            params.n_batch = 512;
            
            // Log all parameters as per user's example
            NSLog(@"DEBUG: Calling llama_mobile_init with parameters from user's example:");
            NSLog(@"DEBUG:   model_path: %s", params.model_path);
            NSLog(@"DEBUG:   n_ctx: %d", params.n_ctx);
            NSLog(@"DEBUG:   n_gpu_layers: %d", params.n_gpu_layers);
            NSLog(@"DEBUG:   n_threads: %d", params.n_threads);
            NSLog(@"DEBUG:   progress_callback: %p", params.progress_callback);
            NSLog(@"DEBUG:   embedding: %d", params.embedding);
            NSLog(@"DEBUG:   use_mmap: %d", params.use_mmap);
            NSLog(@"DEBUG:   n_batch: %d", params.n_batch);
            
            // Call llama_mobile_init directly with user's exact parameters
            self.modelContext = llama_mobile_init(&params);
            NSLog(@"DEBUG: llama_mobile_init returned: %p", self.modelContext);
            
            // Fallback to try without memory mapping if first attempt fails
            if (self.modelContext == NULL) {
                NSLog(@"DEBUG: First initialization attempt failed with use_mmap=true. Trying again without memory mapping...");
                llama_mobile_init_params_t fallbackParams = params;
                fallbackParams.use_mmap = false;
                NSLog(@"DEBUG: Calling llama_mobile_init with use_mmap=false");
                NSLog(@"DEBUG:   model_path: %s", fallbackParams.model_path);
                NSLog(@"DEBUG:   n_ctx: %d", fallbackParams.n_ctx);
                NSLog(@"DEBUG:   n_gpu_layers: %d", fallbackParams.n_gpu_layers);
                NSLog(@"DEBUG:   use_mmap: %d", fallbackParams.use_mmap);
                
                self.modelContext = llama_mobile_init(&fallbackParams);
                NSLog(@"DEBUG: llama_mobile_init (fallback) returned: %p", self.modelContext);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{            
                [self.activityIndicator stopAnimating];
                
                if (self.modelContext != NULL) {
                    // Prepend success message to show at the top
                    [self prependDebugText:@"Model initialized successfully with user's parameters!\n"];
                    [self updateButtonStates];
                } else {
                    // Prepend error message to show at the top
                    [self prependDebugText:@"Error: Initialization failed with both use_mmap=true and use_mmap=false.\n"];
                    NSLog(@"ERROR: llama_mobile_init returned NULL in both attempts");
                    
                    // Validate model file as a final troubleshooting step
                    [self validateModelFile:modelPath];
                }
            });
        });
}



- (void)validateModelFile:(NSString *)modelPath {
    NSLog(@"DEBUG: Validating model file: %@", modelPath);
    
    // Check file size again
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:modelPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: Failed to get file attributes: %@", error.localizedDescription);
        NSString *errorMsg = [NSString stringWithFormat:@"Error getting file attributes: %@\n", error.localizedDescription];
        [self prependDebugText:errorMsg];
        return;
    }
    
    unsigned long long fileSize = [fileAttributes fileSize];
    NSLog(@"DEBUG: Final file size: %llu bytes (%.2f MB)", fileSize, (double)fileSize / (1024 * 1024));
    NSString *sizeMsg = [NSString stringWithFormat:@"Model file size: %.2f MB\n", (double)fileSize / (1024 * 1024)];
    [self prependDebugText:sizeMsg];
    
    // Check file permissions in detail
    NSMutableArray *permissions = [NSMutableArray array];
    if ([fileManager isReadableFileAtPath:modelPath]) {
        [permissions addObject:@"readable"];
    } else {
        [permissions addObject:@"NOT readable"];
        NSLog(@"ERROR: File is not readable");
        NSString *readErrorMsg = @"Error: Model file is not readable.\n";
        [self prependDebugText:readErrorMsg];
    }
    if ([fileManager isWritableFileAtPath:modelPath]) {
        [permissions addObject:@"writable"];
    } else {
        [permissions addObject:@"NOT writable"];
    }
    if ([fileManager isExecutableFileAtPath:modelPath]) {
        [permissions addObject:@"executable"];
    } else {
        [permissions addObject:@"NOT executable"];
    }
    NSLog(@"DEBUG: File permissions: %@", [permissions componentsJoinedByString:@", "]);
    NSString *permissionsMsg = [NSString stringWithFormat:@"File permissions: %@\n", [permissions componentsJoinedByString:@", "]];
    [self prependDebugText:permissionsMsg];
    
    // Check if file extension is correct
    NSString *fileExtension = [modelPath pathExtension];
    if (![fileExtension isEqualToString:@"gguf"] && ![fileExtension isEqualToString:@""]) {
        NSLog(@"WARNING: File extension is not gguf: %@", fileExtension);
        NSString *extensionMsg = [NSString stringWithFormat:@"Warning: File extension is %@, expected gguf\n", fileExtension];
        [self prependDebugText:extensionMsg];
    }
    
    // Check first few bytes to verify it's a GGUF file
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:modelPath];
    if (fileHandle) {
        NSData *headerData = [fileHandle readDataOfLength:16]; // Read more bytes for better verification
        [fileHandle closeFile];
        
        // Additional safety check to ensure headerData is NSData
        if ([headerData isKindOfClass:[NSData class]]) {
            NSLog(@"DEBUG: Header data length: %lu bytes", (unsigned long)[headerData length]);
            
            if ([headerData length] >= 4) {
                char header[5];
                [headerData getBytes:header length:4];
                header[4] = '\0';
                NSLog(@"DEBUG: File header magic: %s", header);
                
                if (strcmp(header, "GGUF") != 0) {
                    NSLog(@"ERROR: File is not a valid GGUF file - wrong magic header");
                    NSString *headerErrorMsg = @"Error: Model file is not a valid GGUF file (wrong magic header).\n";
                    [self prependDebugText:headerErrorMsg];
                    
                    // Log the hex dump of the header for debugging
                    NSMutableString *hexDump = [NSMutableString stringWithString:@"Header hex dump: "];
                    const unsigned char *bytes = [headerData bytes];
                    for (NSUInteger i = 0; i < MIN(16, [headerData length]); i++) {
                        [hexDump appendFormat:@"%02X ", bytes[i]];
                    }
                    NSLog(@"DEBUG: %@", hexDump);
                    [self prependDebugText:[hexDump stringByAppendingString:@"\n"]];
                } else {
                    NSLog(@"DEBUG: File appears to be a valid GGUF file");
                    NSString *validGGUFMsg = @"File appears to be a valid GGUF file, but still failed to initialize.\n";
                    [self prependDebugText:validGGUFMsg];
                    
                    // Log GGUF version information if available
                    // Additional safety check to ensure headerData is still NSData
                    if ([headerData isKindOfClass:[NSData class]] && [headerData length] >= 8) {
                        uint32_t ggufVersion;
                        [headerData getBytes:&ggufVersion range:NSMakeRange(4, 4)];
                        // Convert from little-endian to host byte order
                        ggufVersion = CFSwapInt32LittleToHost(ggufVersion);
                        NSLog(@"DEBUG: GGUF version: %u", ggufVersion);
                        NSString *versionMsg = [NSString stringWithFormat:@"GGUF version: %u\n", ggufVersion];
                        [self prependDebugText:versionMsg];
                    } else {
                        NSLog(@"DEBUG: headerData is not NSData or too short for GGUF version check: %@", [headerData class]);
                    }
                }
            }
        } else {
            NSLog(@"ERROR: Could not open file handle for reading");
            NSString *openErrorMsg = @"Error: Could not open file for reading.\n";
            [self prependDebugText:openErrorMsg];
        }
        
        // Additional checks for file accessibility
        NSURL *fileURL = [NSURL fileURLWithPath:modelPath];
        NSLog(@"DEBUG: Final validation file URL: %@", fileURL);
        NSLog(@"DEBUG: File URL isFileURL: %d", [fileURL isFileURL]);
        
        // Check if we can actually read from the file
        NSData *testData = [NSData dataWithContentsOfFile:modelPath options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
            NSLog(@"ERROR: Failed to read test data from file: %@", error.localizedDescription);
            NSString *readErrorMsg = [NSString stringWithFormat:@"Error reading test data: %@\n", error.localizedDescription];
            [self prependDebugText:readErrorMsg];
        } else if (testData) {
            NSLog(@"DEBUG: Successfully read %lu bytes for test", (unsigned long)[testData length]);
            NSString *readSuccessMsg = [NSString stringWithFormat:@"Successfully read %lu bytes from file.\n", (unsigned long)[testData length]];
            [self prependDebugText:readSuccessMsg];
        }
    }
}
    // MARK: - Text Completion
    
    - (IBAction)completePressed:(id)sender {
        NSLog(@"DEBUG: completePressed button clicked");
        [self generateTextWithMode:@"completion"];
    }
    
    - (IBAction)generatePressed:(id)sender {
        NSLog(@"DEBUG: generatePressed button clicked");
        [self generateTextWithMode:@"simple"];
    }
    
    - (void)generateTextWithMode:(NSString *)mode {
        NSLog(@"DEBUG: generateTextWithMode called with mode: %@", mode);
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot generate text");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            return;
        }
        
        if (self.isGenerating) {
            NSLog(@"DEBUG: Generation already in progress - ignoring request");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generation already in progress.\n"]];
            return;
        }
        
        NSString *prompt = self.promptTextField.text;
        NSLog(@"DEBUG: Using prompt: %@", prompt);
        if ([prompt length] == 0) {
            NSLog(@"DEBUG: Empty prompt - cannot generate text");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            return;
        }
        
        self.isGenerating = YES;
        [self.generateButton setEnabled:NO];
        [self.activityIndicator startAnimating];
        
        NSLog(@"DEBUG: Starting text generation with mode: %@", mode);
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Generating for prompt: %@\n", prompt]];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\nGenerated text:\n"]];
        
        // Clear current output
        [self.currentOutput setString:@""];
        
        // Generate text in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            if ([mode isEqualToString:@"completion"]) {
                // Set the static reference for the callback
                tokenCallbackViewController = self;
                
                // Advanced completion with streaming
                llama_mobile_completion_params_t completion_params = {
                    .prompt = [prompt UTF8String],
                    .max_tokens = 200,
                    .temperature = 0.7,
                    .top_k = 50,
                    .top_p = 0.9,
                    .token_callback = token_callback
                };
                
                NSLog(@"DEBUG: Calling llama_mobile_completion with streaming");
                llama_mobile_completion_result_t result;
                int status = llama_mobile_completion(self.modelContext, &completion_params, &result);
                
                dispatch_async(dispatch_get_main_queue(), ^{                
                    NSLog(@"DEBUG: Completion generation finished with status: %d", status);
                    if (status == 0) {
                        NSLog(@"DEBUG: Completion successful - tokens generated: %d", result.tokens_generated);
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nGeneration completed. Tokens generated: %d\n", result.tokens_generated]];
                        llama_mobile_free_completion_result((llama_mobile_completion_result_t *)&result);
                    } else {
                        NSLog(@"DEBUG: Completion failed with status: %d", status);
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Generation failed.\n"]];
                    }
                    
                    self.isGenerating = NO;
                    [self.generateButton setEnabled:YES];
                    [self.activityIndicator stopAnimating];
                    
                    // Clear the static reference to prevent memory leaks
                    tokenCallbackViewController = nil;
                });
            } else {
                // Simple completion
                NSLog(@"DEBUG: Calling llama_mobile_completion_simple (no streaming)");
                llama_mobile_completion_result_t result;
                int status = llama_mobile_completion_simple(
                                                            self.modelContext,
                                                            [prompt UTF8String],
                                                            100,          // Max tokens
                                                            0.8,          // Temperature
                                                            NULL,         // Token callback
                                                            &result
                                                            );
                
                dispatch_async(dispatch_get_main_queue(), ^{                
                    NSLog(@"DEBUG: Simple generation finished with status: %d", status);
                    if (status == 0) {
                        NSLog(@"DEBUG: Simple generation successful - tokens generated: %d", result.tokens_generated);
                        NSString *generatedText = [NSString stringWithUTF8String:result.text];
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:generatedText]];
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nTokens generated: %d\n", result.tokens_generated]];
                        
                        // Free the result when done
                        llama_mobile_free_completion_result((llama_mobile_completion_result_t *)&result);
                        llama_mobile_free_string(result.text);
                    } else {
                        NSLog(@"DEBUG: Simple generation failed with status: %d", status);
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Generation failed.\n"]];
                    }
                    
                    self.isGenerating = NO;
                    [self.generateButton setEnabled:YES];
                    [self.activityIndicator stopAnimating];
                });
            }
        });
    }
    
    // MARK: - Conversation
    
    - (IBAction)conversationPressed:(id)sender {
        NSLog(@"DEBUG: conversationPressed button clicked");
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot start conversation");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            return;
        }
        
        NSString *prompt = self.promptTextField.text;
        NSLog(@"DEBUG: Conversation prompt: %@", prompt);
        if ([prompt length] == 0) {
            NSLog(@"DEBUG: Empty conversation prompt - returning");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            return;
        }
        
        NSLog(@"DEBUG: Starting conversation generation");
        [self.activityIndicator startAnimating];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Conversation: %@\n", prompt]];
        
        // Generate conversation response in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            llama_mobile_conversation_result_t conv_result;
            NSLog(@"DEBUG: Calling llama_mobile_generate_response_simple for conversation");
            int status = llama_mobile_generate_response_simple(
                                                               self.modelContext,
                                                               [prompt UTF8String],
                                                               100,          // Max tokens
                                                               &conv_result
                                                               );
            
            dispatch_async(dispatch_get_main_queue(), ^{            
                [self.activityIndicator stopAnimating];
                NSLog(@"DEBUG: Conversation generation finished with status: %d", status);
                
                if (status == 0) {
                    NSLog(@"DEBUG: Conversation successful - time to first token: %lld ms, total time: %lld ms", conv_result.time_to_first_token, conv_result.total_time);
                    NSString *response = [NSString stringWithUTF8String:conv_result.text];
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:response]];
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nTime to first token: %lld ms\nTotal time: %lld ms\n", conv_result.time_to_first_token, conv_result.total_time]];
                    
                    // Free resources
                    llama_mobile_free_string(conv_result.text);
                } else {
                    NSLog(@"DEBUG: Conversation failed with status: %d", status);
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Conversation failed.\n"]];
                }
            });
        });
    }
    
    // MARK: - Embeddings
    
    - (IBAction)embeddingPressed:(id)sender {
        NSLog(@"DEBUG: embeddingPressed button clicked");
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot generate embeddings");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            return;
        }
        
        NSString *prompt = self.promptTextField.text;
        NSLog(@"DEBUG: Embedding prompt: %@", prompt);
        if ([prompt length] == 0) {
            NSLog(@"DEBUG: Empty embedding prompt - returning");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            return;
        }
        
        NSLog(@"DEBUG: Starting embedding generation");
        [self.activityIndicator startAnimating];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Generating embeddings for: %@\n", prompt]];
        
        // Generate embeddings in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            NSLog(@"DEBUG: Calling llama_mobile_embedding");
            llama_mobile_float_array_t embedding = llama_mobile_embedding(
                                                                          self.modelContext,
                                                                          [prompt UTF8String]
                                                                          );
            
            dispatch_async(dispatch_get_main_queue(), ^{            
                [self.activityIndicator stopAnimating];
                NSLog(@"DEBUG: Embedding generation finished - dimension: %d", embedding.count);
                
                if (embedding.count > 0) {
                    NSLog(@"DEBUG: Embedding generation successful");
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Embedding dimension: %d\n", embedding.count]];
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"First few values:\n"]];
                    
                    // Show first 10 values
                    NSMutableString *embeddingText = [NSMutableString string];
                    for (int i = 0; i < MIN(10, embedding.count); i++) {
                        [embeddingText appendFormat:@"%.6f ", embedding.values[i]];
                    }
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:embeddingText]];
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n...\n"]];
                    
                    // Free embedding when done
                    llama_mobile_free_float_array(embedding);
                } else {
                    NSLog(@"DEBUG: Embedding generation failed - count is zero");
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Failed to generate embeddings.\n"]];
                }
            });
        });
    }
    
    // MARK: - UI Helpers
    
    - (IBAction)clearPressed:(id)sender {
        [self.promptTextField setText:@""];
        [self.outputTextView setText:@""];
        [self.currentOutput setString:@""];
    }
    
    - (void)updateButtonStates {
        BOOL isModelInitialized = (self.modelContext != NULL);
        [self.generateButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.completeButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.conversationButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.embeddingButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.multimodalButton setEnabled:isModelInitialized && !self.isGenerating];
    }
    
    - (void)prependDebugText:(NSString *)text {
        // Make sure we're on the main thread
        if (![NSThread isMainThread]) {
            dispatch_sync(dispatch_get_main_queue(), ^{ [self prependDebugText:text]; });
            return;
        }
        
        // Use the dedicated debug log text view
        if (!self.debugLogTextView) {
            // Fallback to outputTextView if debugLogTextView is not initialized
            NSString *newContent = [text stringByAppendingString:self.outputTextView.text];
            [self.outputTextView setText:newContent];
            [self.outputTextView setContentOffset:CGPointZero animated:YES];
            return;
        }
        
        // Prepend the text to the debug log
        NSString *newContent = [text stringByAppendingString:self.debugLogTextView.text];
        [self.debugLogTextView setText:newContent];
        
        // Scroll to the top to show the new debug information
        [self.debugLogTextView setContentOffset:CGPointZero animated:YES];
    }
    
    // MARK: - Multimodal Support
    
    - (IBAction)multimodalPressed:(id)sender {
        if (self.modelContext == NULL) {
            [self prependDebugText:@"Error: Model not initialized.\n"];
            return;
        }
        
        NSString *prompt = self.promptTextField.text;
        if ([prompt length] == 0) {
            [self prependDebugText:@"Please enter a prompt.\n"];
            return;
        }
        
        // Initialize multimodal if not already done
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *mmprojPath = [[bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        mmprojPath = [mmprojPath stringByAppendingPathComponent:@"lib/models/mmproj-model.f16.gguf"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:mmprojPath]) {
            int status = llama_mobile_init_multimodal_simple(self.modelContext, [mmprojPath UTF8String]);
            if (status != 0) {
                [self prependDebugText:@"Error: Failed to initialize multimodal support.\n"];
                return;
            }
            [self prependDebugText:@"Multimodal support initialized.\n"];
        } else {
            [self prependDebugText:@"Warning: Multimodal projection file not found. Using text only.\n"];
            // Proceed with text-only completion
            [self generateTextWithMode:@"completion"];
            return;
        }
        
        // Show image picker to select an image for multimodal completion
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    
    - (void)processImageWithPrompt:(NSString *)prompt imagePath:(NSString *)imagePath {
        if (self.isGenerating) {
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generation already in progress.\n"]];
            return;
        }
        
        self.isGenerating = YES;
        [self.generateButton setEnabled:NO];
        [self.activityIndicator startAnimating];
        
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Generating for prompt: %@\n", prompt]];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Using image: %@\n\n", imagePath]];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generated text:\n"]];
        
        // Clear current output
        [self.currentOutput setString:@""];
        
        // Convert image path to C string
        const char *imagePathC = [imagePath UTF8String];
        
        // Generate multimodal completion in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            // Create media paths array inside the block
            const char *mediaPaths[] = { imagePathC };
            int mediaCount = 1;
            
            // Create a local copy that can be safely passed to the function
            const char* localMediaPaths[1];
            localMediaPaths[0] = mediaPaths[0];
            
            // Set the static reference for the callback
            tokenCallbackViewController = self;
            
            // Advanced completion with streaming and media
            llama_mobile_completion_params_t completion_params = {
                .prompt = [prompt UTF8String],
                .max_tokens = 200,
                .temperature = 0.7,
                .top_k = 50,
                .top_p = 0.9,
                .token_callback = token_callback
            };
            
            llama_mobile_completion_result_t result;
            int status = llama_mobile_multimodal_completion(self.modelContext, &completion_params, localMediaPaths, mediaCount, &result);
            
            dispatch_async(dispatch_get_main_queue(), ^{                
                if (status == 0) {
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nGeneration completed. Tokens generated: %d\n", result.tokens_generated]];
                    llama_mobile_free_completion_result((llama_mobile_completion_result_t *)&result);
                } else {
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Multimodal generation failed.\n"]];
                }
                
                self.isGenerating = NO;
                [self.generateButton setEnabled:YES];
                [self.activityIndicator stopAnimating];
                
                // Clear the static reference to prevent memory leaks
                tokenCallbackViewController = nil;
            });
        });
    }
    
    // MARK: - UIImagePickerController Delegate
    
    - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
        // Get the selected image
        UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
        if (selectedImage) {
            // Save image to temporary directory
            NSString *tempDirectory = NSTemporaryDirectory();
            NSString *tempImagePath = [tempDirectory stringByAppendingPathComponent:@"temp_image.jpg"];
            NSData *imageData = UIImageJPEGRepresentation(selectedImage, 0.9);
            
            if ([imageData writeToFile:tempImagePath atomically:YES]) {
                // Dismiss the picker
                [picker dismissViewControllerAnimated:YES completion:^{                
                    // Process the image with the current prompt
                    NSString *prompt = self.promptTextField.text;
                    [self processImageWithPrompt:prompt imagePath:tempImagePath];
                }];
            } else {
                [picker dismissViewControllerAnimated:YES completion:^{                
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Failed to save image.\n"]];
                }];
            }
        } else {
            [picker dismissViewControllerAnimated:YES completion:nil];
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Could not get selected image.\n"]];
        }
    }
    
    - (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
    // MARK: - UITextField Delegate
    
    - (BOOL)textFieldShouldReturn:(UITextField *)textField {
        [textField resignFirstResponder];
        return YES;
    }

@end
