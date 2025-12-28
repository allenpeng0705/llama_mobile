//
//  ViewController.m
//  iOSFrameworkExample
//
//  Created by on 2024-12-24.
//

#import "ViewController.h"
#include <sys/stat.h>
#import <AVFoundation/AVFoundation.h>


// C++ standard library includes for TTS functionality
#include <string>
#include <vector>

// Import FFI header directly with C linkage
extern "C" {
    #import <llama_mobile/llama_mobile_ffi.h>
}


@interface ViewController ()

@property (nonatomic, strong) UIStackView *mainStackView;

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
    
    // Create debug log text view first
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
    
    // Initialize output text view programmatically since there's no storyboard
    if (!self.outputTextView) {
        self.outputTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        self.outputTextView.translatesAutoresizingMaskIntoConstraints = NO;
        self.outputTextView.backgroundColor = [UIColor whiteColor];
        self.outputTextView.textColor = [UIColor blackColor];
        self.outputTextView.font = [UIFont systemFontOfSize:16];
        self.outputTextView.textAlignment = NSTextAlignmentLeft;
        self.outputTextView.editable = NO;
        self.outputTextView.scrollEnabled = YES;
        self.outputTextView.layer.borderWidth = 1.0;
        self.outputTextView.layer.borderColor = [UIColor blackColor].CGColor;
    }
    
    // Initialize prompt text view programmatically since there's no storyboard
    if (!self.promptTextField) {
        self.promptTextField = [[UITextView alloc] initWithFrame:CGRectZero];
        self.promptTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.promptTextField.backgroundColor = [UIColor whiteColor];
        self.promptTextField.textColor = [UIColor lightGrayColor];
        self.promptTextField.font = [UIFont systemFontOfSize:16];
        self.promptTextField.textAlignment = NSTextAlignmentLeft;
        self.promptTextField.userInteractionEnabled = YES;
        self.promptTextField.delegate = self;
        self.promptTextField.editable = YES;
        self.promptTextField.scrollEnabled = YES;
        self.promptTextField.textContainerInset = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);
        [self.promptTextField setText:@"Enter your prompt here..."];
        self.promptTextField.layer.borderWidth = 1.0;
        self.promptTextField.layer.borderColor = [UIColor blackColor].CGColor;
        self.promptTextField.clipsToBounds = YES;
    }
    
    // Initialize activity indicator programmatically since there's no storyboard
    if (!self.activityIndicator) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        self.activityIndicator.hidesWhenStopped = YES;
    }
    
    // Improve UI visibility with enhanced styling
    
    // Output text view - improve visibility
    [self.outputTextView setTextColor:[UIColor blackColor]];
    [self.outputTextView setBackgroundColor:[UIColor whiteColor]];
    [self.outputTextView setFont:[UIFont systemFontOfSize:16]];
    [self.outputTextView setTextAlignment:NSTextAlignmentLeft];
    [self.outputTextView setText:@""];
    
    
    // Prompt input - improve visibility and appearance
    [self.promptTextField setTextColor:[UIColor blackColor]];
    [self.promptTextField setBackgroundColor:[UIColor whiteColor]];
    [self.promptTextField setFont:[UIFont systemFontOfSize:16]];
    [self.promptTextField setTextAlignment:NSTextAlignmentLeft];
    [self.promptTextField setUserInteractionEnabled:YES];
    [self.promptTextField setDelegate:self];
    
    // UITextView-specific properties
    [self.promptTextField setEditable:YES];
    [self.promptTextField setScrollEnabled:YES];
    [self.promptTextField setTextContainerInset:UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)];
    // Set placeholder text for text view
    [self.promptTextField setText:@"Enter your prompt here..."];
    [self.promptTextField setTextColor:[UIColor lightGrayColor]];
    
    // Increase height of prompt input field
    [self.promptTextField.heightAnchor constraintEqualToConstant:120.0].active = YES;
    
    // Set layer properties for better appearance
    [self.promptTextField.layer setCornerRadius:8.0];
    [self.promptTextField.layer setBorderWidth:1.0];
    [self.promptTextField.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.promptTextField setClipsToBounds:YES]; // Ensure content respects corner radius
    
    // Initialize buttons programmatically since there's no storyboard
    if (!self.generateButton) {
        self.generateButton = [[UIButton alloc] init];
        self.generateButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.generateButton setTitle:@"Generate" forState:UIControlStateNormal];
        [self.generateButton addTarget:self action:@selector(generatePressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!self.completeButton) {
        self.completeButton = [[UIButton alloc] init];
        self.completeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.completeButton setTitle:@"Complete" forState:UIControlStateNormal];
        [self.completeButton addTarget:self action:@selector(completePressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!self.conversationButton) {
        self.conversationButton = [[UIButton alloc] init];
        self.conversationButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.conversationButton setTitle:@"Conversation" forState:UIControlStateNormal];
        [self.conversationButton addTarget:self action:@selector(conversationPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!self.embeddingButton) {
        self.embeddingButton = [[UIButton alloc] init];
        self.embeddingButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.embeddingButton setTitle:@"Embedding" forState:UIControlStateNormal];
        [self.embeddingButton addTarget:self action:@selector(embeddingPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!self.initializeButton) {
        self.initializeButton = [[UIButton alloc] init];
        self.initializeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.initializeButton setTitle:@"Initialize" forState:UIControlStateNormal];
        [self.initializeButton addTarget:self action:@selector(initializePressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!self.multimodalButton) {
        self.multimodalButton = [[UIButton alloc] init];
        self.multimodalButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.multimodalButton setTitle:@"Multimodal" forState:UIControlStateNormal];
        [self.multimodalButton addTarget:self action:@selector(multimodalPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!self.clearButton) {
        self.clearButton = [[UIButton alloc] init];
        self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.clearButton setTitle:@"Clear" forState:UIControlStateNormal];
        [self.clearButton addTarget:self action:@selector(clearPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
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
    self.isPlayingAudio = NO;
    
    // Initialize audio engine and player node for TTS playback
    self.audioEngine = [[AVAudioEngine alloc] init];
    self.audioPlayerNode = [[AVAudioPlayerNode alloc] init];
    [self.audioEngine attachNode:self.audioPlayerNode];
    
    // Initialize model selection data structures
    self.modelPaths = [NSMutableDictionary dictionary];
    
    // Scan app bundle for all GGUF model files FIRST - this is critical for model picker
    [self scanForModelFiles];
    
    // Add model picker view after models are scanned
    [self setupModelPickerView];
    
    // Disable buttons until model is initialized
    [self updateButtonStates];
    
    // Add keyboard handling
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Add debug log view to main stack view in setupModelPickerView
    // So we don't need to add it here
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
        llama_mobile_free_context_c(self.modelContext);
        self.modelContext = NULL;
    }
    
    // Remove keyboard observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
    // Adjust scroll view content inset when keyboard appears
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Get keyboard height
    CGFloat keyboardHeight = [self.view convertRect:keyboardFrame fromView:nil].size.height;
    
    // Adjust scroll view content inset
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = keyboardHeight + 16.0;
    self.scrollView.contentInset = contentInset;
    
    // Also adjust scroll indicator inset
    UIEdgeInsets scrollIndicatorInset = self.scrollView.scrollIndicatorInsets;
    scrollIndicatorInset.bottom = keyboardHeight + 16.0;
    self.scrollView.scrollIndicatorInsets = scrollIndicatorInset;
    
    // Animate the change to match keyboard animation
    double animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{ 
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // Reset scroll view content inset when keyboard disappears
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = 16.0;
    self.scrollView.contentInset = contentInset;
    
    // Also reset scroll indicator inset
    UIEdgeInsets scrollIndicatorInset = self.scrollView.scrollIndicatorInsets;
    scrollIndicatorInset.bottom = 16.0;
    self.scrollView.scrollIndicatorInsets = scrollIndicatorInset;
    
    // Animate the change to match keyboard animation
    NSDictionary *info = [notification userInfo];
    double animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{ 
        [self.view layoutIfNeeded];
    }];
}

// MARK: - Model Selection

- (void)scanForModelFiles {
    NSLog(@"DEBUG: Scanning for model files in app bundle");
    
    // Get the main bundle
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *bundlePath = [mainBundle bundlePath];
    
    // Scan the bundle root directory for GGUF files
    [self scanDirectory:bundlePath forFilesWithExtension:@"gguf"];
    
    // Also check if there's a models directory
    NSString *modelsDirPath = [bundlePath stringByAppendingPathComponent:@"models"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:modelsDirPath isDirectory:NULL]) {
        [self scanDirectory:modelsDirPath forFilesWithExtension:@"gguf"];
    }
    
    // Extract the available model names from the dictionary keys, sorted alphabetically
    self.availableModels = [[self.modelPaths allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSLog(@"DEBUG: Found %lu model files:", (unsigned long)[self.availableModels count]);
    for (NSString *modelName in self.availableModels) {
        NSLog(@"DEBUG:   - %@: %@", modelName, [self.modelPaths objectForKey:modelName]);
    }
    

}

- (void)scanDirectory:(NSString *)directoryPath forFilesWithExtension:(NSString *)extension {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: Failed to scan directory %@: %@", directoryPath, error);
        return;
    }
    
    for (NSString *file in files) {
        NSString *filePath = [directoryPath stringByAppendingPathComponent:file];
        
        // Check if it's a file (not a directory)
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory) {
            // Check if it has the right extension (case-insensitive)
            if ([[file pathExtension] caseInsensitiveCompare:extension] == NSOrderedSame) {
                // Use the filename without extension as the display name
                NSString *modelName = [file stringByDeletingPathExtension];
                [self.modelPaths setObject:filePath forKey:modelName];
            }
        }
    }
}

- (void)setupModelPickerView {
    // Create model label
    if (!self.modelLabel) {
        self.modelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.modelLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.modelLabel.text = @"Select Model:";
        self.modelLabel.textColor = [UIColor blackColor];
        self.modelLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [self.view addSubview:self.modelLabel];
    }
    
    // Create model dropdown text field
    if (!self.modelDropdownTextField) {
        self.modelDropdownTextField = [[UITextField alloc] init];
        self.modelDropdownTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.modelDropdownTextField.backgroundColor = [UIColor whiteColor];
        [self.modelDropdownTextField.layer setBorderWidth:1.0];
        [self.modelDropdownTextField.layer setBorderColor:[UIColor blackColor].CGColor];
        [self.modelDropdownTextField.layer setCornerRadius:8.0];
        self.modelDropdownTextField.textColor = [UIColor blackColor];
        self.modelDropdownTextField.font = [UIFont systemFontOfSize:16];
        self.modelDropdownTextField.textAlignment = NSTextAlignmentCenter;
        self.modelDropdownTextField.userInteractionEnabled = YES;
        self.modelDropdownTextField.delegate = self;
        
        // Add a down arrow button to indicate dropdown
        UIButton *dropdownButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [dropdownButton setImage:[UIImage systemImageNamed:@"chevron.down"] forState:UIControlStateNormal];
        [dropdownButton setTintColor:[UIColor blackColor]];
        self.modelDropdownTextField.rightView = dropdownButton;
        self.modelDropdownTextField.rightViewMode = UITextFieldViewModeAlways;
        
        // Create picker view
        self.modelPickerView = [[UIPickerView alloc] init];
        self.modelPickerView.backgroundColor = [UIColor whiteColor];
        self.modelPickerView.dataSource = self;
        self.modelPickerView.delegate = self;
        
        // Set picker as input view
        self.modelDropdownTextField.inputView = self.modelPickerView;
        
        // Create a toolbar with done button
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [toolbar setItems:@[flexSpace, doneButton] animated:NO];
        
        // Set toolbar as input accessory view
        self.modelDropdownTextField.inputAccessoryView = toolbar;
        
        [self.view addSubview:self.modelDropdownTextField];
    }
    
    // Reload picker data to ensure models are displayed
    [self.modelPickerView reloadAllComponents];
    
    // If there's only one model, select it by default
    if ([self.availableModels count] > 0) {
        [self.modelPickerView selectRow:0 inComponent:0 animated:NO];
        [self dropdownDidSelectModelAtIndex:0];
    }
    
    // Remove all existing constraints for all key views to start fresh
    NSArray *viewsToCleanup = @[
        self.modelLabel, self.modelPickerView, self.outputTextView, 
        self.debugLogTextView, self.promptTextField, self.generateButton, 
        self.completeButton, self.conversationButton, self.embeddingButton,
        self.initializeButton, self.multimodalButton, self.clearButton
    ];
    
    for (UIView *view in viewsToCleanup) {
        if (view) {
            [view removeConstraints:view.constraints];
            NSMutableArray *constraintsToRemove = [NSMutableArray array];
            for (NSLayoutConstraint *constraint in view.superview.constraints) {
                if (constraint.firstItem == view || constraint.secondItem == view) {
                    [constraintsToRemove addObject:constraint];
                }
            }
            [view.superview removeConstraints:constraintsToRemove];
        }
    }
    
    // Create or reuse main vertical stack view to hold all UI elements
    if (!self.mainStackView) {
        self.mainStackView = [[UIStackView alloc] init];
        self.mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
        self.mainStackView.axis = UILayoutConstraintAxisVertical;
        self.mainStackView.alignment = UIStackViewAlignmentFill;
        self.mainStackView.distribution = UIStackViewDistributionFill;
        self.mainStackView.spacing = 12.0;
        [self.view addSubview:self.mainStackView];
    } else {
        // Clear any existing arranged subviews
    for (UIView *subview in self.mainStackView.arrangedSubviews) {
        [self.mainStackView removeArrangedSubview:subview];
        [subview removeFromSuperview];
    }
    }
    
    // Add model selection section to the stack view
    [self.mainStackView addArrangedSubview:self.modelLabel];
    [self.mainStackView addArrangedSubview:self.modelDropdownTextField];
    // Set a proper height for the dropdown text field
    [self.modelDropdownTextField.heightAnchor constraintEqualToConstant:44.0].active = YES;
    
    // Set output text view height
    [self.outputTextView.heightAnchor constraintEqualToConstant:100.0].active = YES;
    [self.mainStackView addArrangedSubview:self.outputTextView];
    
    // Add prompt text field to the stack (on top of buttons)
    [self.mainStackView addArrangedSubview:self.promptTextField];
    // Set a proper height for the prompt text field (multiline)
    [self.promptTextField.heightAnchor constraintEqualToConstant:120.0].active = YES;
    
    // Create a button container stack view (3 rows of 2 buttons)
    UIStackView *buttonRow1 = [[UIStackView alloc] init];
    buttonRow1.axis = UILayoutConstraintAxisHorizontal;
    buttonRow1.alignment = UIStackViewAlignmentFill;
    buttonRow1.distribution = UIStackViewDistributionFillEqually;
    buttonRow1.spacing = 8.0;
    
    UIStackView *buttonRow2 = [[UIStackView alloc] init];
    buttonRow2.axis = UILayoutConstraintAxisHorizontal;
    buttonRow2.alignment = UIStackViewAlignmentFill;
    buttonRow2.distribution = UIStackViewDistributionFillEqually;
    buttonRow2.spacing = 8.0;
    
    UIStackView *buttonRow3 = [[UIStackView alloc] init];
    buttonRow3.axis = UILayoutConstraintAxisHorizontal;
    buttonRow3.alignment = UIStackViewAlignmentFill;
    buttonRow3.distribution = UIStackViewDistributionFillEqually;
    buttonRow3.spacing = 8.0;
    
    // Add buttons to rows
    [buttonRow1 addArrangedSubview:self.initializeButton];
    
    [buttonRow2 addArrangedSubview:self.generateButton];
    [buttonRow2 addArrangedSubview:self.completeButton];
    
    [buttonRow3 addArrangedSubview:self.conversationButton];
    [buttonRow3 addArrangedSubview:self.embeddingButton];
    
    // Add button rows to main stack
    [self.mainStackView addArrangedSubview:buttonRow1];
    [self.mainStackView addArrangedSubview:buttonRow2];
    [self.mainStackView addArrangedSubview:buttonRow3];
    
    // Create a horizontal stack for the last two buttons
    UIStackView *buttonRow4 = [[UIStackView alloc] init];
    buttonRow4.axis = UILayoutConstraintAxisHorizontal;
    buttonRow4.alignment = UIStackViewAlignmentFill;
    buttonRow4.distribution = UIStackViewDistributionFillEqually;
    buttonRow4.spacing = 8.0;
    
    [buttonRow4 addArrangedSubview:self.multimodalButton];
    
    // Initialize TTS button programmatically since there's no storyboard
    if (!self.ttsButton) {
        self.ttsButton = [[UIButton alloc] init];
        self.ttsButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.ttsButton setTitle:@"TTS" forState:UIControlStateNormal];
        [self.ttsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.ttsButton setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]];
        [self.ttsButton.layer setCornerRadius:8.0];
        [self.ttsButton.layer setBorderWidth:1.0];
        [self.ttsButton.layer setBorderColor:[UIColor blackColor].CGColor];
        [self.ttsButton addTarget:self action:@selector(ttsPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.ttsButton setContentEdgeInsets:UIEdgeInsetsMake(8, 16, 8, 16)];
    }
    
    [buttonRow4 addArrangedSubview:self.ttsButton];
    
    // Set button heights - after all buttons are initialized
    CGFloat buttonHeight = 36.0;
    NSArray *allButtons = @[
        self.initializeButton, self.generateButton, self.completeButton, 
        self.conversationButton, self.embeddingButton, self.multimodalButton, 
        self.clearButton, self.ttsButton
    ];
    
    for (UIButton *button in allButtons) {
        [button.heightAnchor constraintEqualToConstant:buttonHeight].active = YES;
    }
    [self.mainStackView addArrangedSubview:buttonRow4];
    
    // Create a row for clear and audio playback buttons
    UIStackView *buttonRow5 = [[UIStackView alloc] init];
    buttonRow5.axis = UILayoutConstraintAxisHorizontal;
    buttonRow5.alignment = UIStackViewAlignmentFill;
    buttonRow5.distribution = UIStackViewDistributionFillEqually;
    buttonRow5.spacing = 8.0;
    
    [buttonRow5 addArrangedSubview:self.clearButton];
    
    // Initialize audio control buttons programmatically since there's no storyboard
    if (!self.playAudioButton) {
        self.playAudioButton = [[UIButton alloc] init];
        self.playAudioButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.playAudioButton setTitle:@"Play Audio" forState:UIControlStateNormal];
        [self.playAudioButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.playAudioButton setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]];
        [self.playAudioButton.layer setCornerRadius:8.0];
        [self.playAudioButton.layer setBorderWidth:1.0];
        [self.playAudioButton.layer setBorderColor:[UIColor blackColor].CGColor];
        [self.playAudioButton addTarget:self action:@selector(playAudioPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.playAudioButton setContentEdgeInsets:UIEdgeInsetsMake(8, 16, 8, 16)];
    }
    
    if (!self.stopAudioButton) {
        self.stopAudioButton = [[UIButton alloc] init];
        self.stopAudioButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.stopAudioButton setTitle:@"Stop Audio" forState:UIControlStateNormal];
        [self.stopAudioButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.stopAudioButton setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]];
        [self.stopAudioButton.layer setCornerRadius:8.0];
        [self.stopAudioButton.layer setBorderWidth:1.0];
        [self.stopAudioButton.layer setBorderColor:[UIColor blackColor].CGColor];
        [self.stopAudioButton addTarget:self action:@selector(stopAudioPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.stopAudioButton setContentEdgeInsets:UIEdgeInsetsMake(8, 16, 8, 16)];
    }
    
    [buttonRow5 addArrangedSubview:self.playAudioButton];
    [buttonRow5 addArrangedSubview:self.stopAudioButton];
    [self.mainStackView addArrangedSubview:buttonRow5];
    
    // Hide audio controls initially
    self.playAudioButton.hidden = YES;
    self.stopAudioButton.hidden = YES;
    
    // Set debug log height (increased to give more space for logging)
    [self.debugLogTextView.heightAnchor constraintEqualToConstant:120.0].active = YES;
    [self.mainStackView addArrangedSubview:self.debugLogTextView];
    
    // Create and configure scroll view
    if (!self.scrollView) {
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.view addSubview:self.scrollView];
        
        // Add constraints for scrollView
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:0.0].active = YES;
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:0.0].active = YES;
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:0.0].active = YES;
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:0.0].active = YES;
    }
    
    // Always add mainStackView to scrollView and set constraints
    [self.mainStackView removeFromSuperview];
    [self.scrollView addSubview:self.mainStackView];
    
    // Add constraints for mainStackView inside scrollView
    [self.mainStackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16.0].active = YES;
    [self.mainStackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16.0].active = YES;
    [self.mainStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:16.0].active = YES;
    [self.mainStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-16.0].active = YES;
    
    // Ensure mainStackView width matches scrollView width
    [self.mainStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32.0].active = YES;
    
    NSLog(@"DEBUG: Model picker view setup completed with stack view layout");
}

// MARK: - Model Segmented Control Action

// MARK: - UIPickerViewDataSource Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    // Only one column for model selection
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    // Return number of available models
    return [self.availableModels count];
}

// MARK: - UIPickerViewDelegate Methods

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    // Create a label with explicit text color to ensure visibility
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 44)];
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    // Set the model name for the row
    label.text = [self.availableModels objectAtIndex:row];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // Handle model selection
    [self dropdownDidSelectModelAtIndex:row];
}

- (void)dropdownDidSelectModelAtIndex:(NSInteger)row {
    if (row >= 0 && row < [self.availableModels count]) {
        NSString *selectedModel = [self.availableModels objectAtIndex:row];
        NSString *modelPath = [self.modelPaths objectForKey:selectedModel];
        
        // Update the text field with the selected model
        self.modelDropdownTextField.text = selectedModel;
        
        NSLog(@"DEBUG: Selected model: %@ (%@)", selectedModel, modelPath);
        [self prependDebugText:[NSString stringWithFormat:@"Selected model: %@\n", selectedModel]];
    }
}

- (void)doneButtonTapped {
    // Dismiss the picker view
    [self.modelDropdownTextField resignFirstResponder];
}

// MARK: - Model Initialization

- (IBAction)initializePressed:(id)sender {
    if (self.modelContext != NULL) {
        llama_mobile_free_context_c(self.modelContext);
        self.modelContext = NULL;
    }
    
    [self.activityIndicator startAnimating];
    [self.outputTextView setText:@"Initializing model...\n"];
    
    // Get selected model from picker view
    NSString *modelPath = nil;
    
    if ([self.availableModels count] == 0) {
        NSString *errorMsg = @"Error: No model files found in app bundle.\n";
        [self.outputTextView setText:errorMsg];
        NSLog(@"ERROR: No model files found in app bundle");
        [self.activityIndicator stopAnimating];
        return;
    }
    
    // Get selected model from dropdown
    NSString *selectedModel = self.modelDropdownTextField.text;
    NSInteger selectedIndex = [self.availableModels indexOfObject:selectedModel];
    
    if (selectedIndex == NSNotFound || selectedIndex >= [self.availableModels count]) {
        // Fallback to first model if no selection or invalid selection
        selectedIndex = 0;
        selectedModel = [self.availableModels objectAtIndex:selectedIndex];
        
        NSLog(@"DEBUG: No valid model selected, using first model: %@", selectedModel);
        
        // Update the dropdown to show the selected model
        [self dropdownDidSelectModelAtIndex:selectedIndex];
    }
    
    modelPath = [self.modelPaths objectForKey:selectedModel];
    NSLog(@"DEBUG: Selected model: %@", selectedModel);
    NSLog(@"DEBUG: Model path: %@", modelPath);
    
    if (!modelPath) {
        NSString *errorMsg = @"Error: Could not get path for selected model.\n";
        [self.outputTextView setText:errorMsg];
        NSLog(@"ERROR: Could not get path for selected model");
        [self.activityIndicator stopAnimating];
        return;
    }
    
    // Prepend new content to show at the top
    [self prependDebugText:[NSString stringWithFormat:@"Trying to load model: %@\n", selectedModel]];
    
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
            // Set up detailed parameters with optimal settings
            llama_mobile_init_params_c_t params = {0}; // Initialize all fields to zero first
            params.model_path = [modelPath UTF8String];
            params.n_ctx = 2048;                   // Context window size
            params.n_gpu_layers = gpuLayers;       // 0 for simulator, 20 for real device
            params.n_threads = 4;                  // Number of CPU threads (optimal for most iOS devices)
            params.progress_callback = progress_callback;
            params.embedding = false;
            params.use_mmap = true;                // Use memory mapping for better memory usage
            params.n_batch = 512;                  // Batch size for generation
            
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
            
            // Call llama_mobile_init_context_c directly with user's exact parameters
            self.modelContext = llama_mobile_init_context_c(&params);
            NSLog(@"DEBUG: llama_mobile_init_context_c returned: %p", self.modelContext);
            
            // Fallback to try without memory mapping if first attempt fails
            if (self.modelContext == NULL) {
                NSLog(@"DEBUG: First initialization attempt failed with use_mmap=true. Trying again without memory mapping...");
                llama_mobile_init_params_c_t fallbackParams = params;
                fallbackParams.use_mmap = false;
                NSLog(@"DEBUG: Calling llama_mobile_init_context_c with use_mmap=false");
                NSLog(@"DEBUG:   model_path: %s", fallbackParams.model_path);
                NSLog(@"DEBUG:   n_ctx: %d", fallbackParams.n_ctx);
                NSLog(@"DEBUG:   n_gpu_layers: %d", fallbackParams.n_gpu_layers);
                NSLog(@"DEBUG:   use_mmap: %d", fallbackParams.use_mmap);
                
                self.modelContext = llama_mobile_init_context_c(&fallbackParams);
                NSLog(@"DEBUG: llama_mobile_init_context_c (fallback) returned: %p", self.modelContext);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{            
                [self.activityIndicator stopAnimating];
                
                if (self.modelContext != NULL) {
                    // Update output text view with success message
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Model initialized successfully!\n"]];
                    // Prepend success message to debug log
                    [self prependDebugText:@"Model initialized successfully with user's parameters!\n"];
                    [self updateButtonStates];
                } else {
                    // Update output text view with error message
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Initialization failed.\n"]];
                    // Prepend error message to debug log
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
                    const unsigned char *bytes = (const unsigned char *)[headerData bytes];
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
        [self prependDebugText:@"Starting advanced completion...\n"];
        [self generateTextWithMode:@"completion"];
    }
    
    - (IBAction)generatePressed:(id)sender {
        NSLog(@"DEBUG: generatePressed button clicked");
        [self prependDebugText:@"Starting text generation...\n"];
        [self generateTextWithMode:@"simple"];
    }
    
    - (void)generateTextWithMode:(NSString *)mode {
        NSLog(@"DEBUG: generateTextWithMode called with mode: %@", mode);
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot generate text");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            [self prependDebugText:@"Error: Model not initialized. Please initialize the model first.\n"];
            return;
        }
        
        if (self.isGenerating) {
            NSLog(@"DEBUG: Generation already in progress - ignoring request");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generation already in progress.\n"]];
            [self prependDebugText:@"Error: Generation already in progress. Please wait for current generation to complete.\n"];
            return;
        }
        
        NSString *userPrompt = self.promptTextField.text;
        NSLog(@"DEBUG: Using user prompt: %@", userPrompt);
        if ([userPrompt length] == 0 || [userPrompt isEqualToString:@"Enter your prompt here..."]) {
            NSLog(@"DEBUG: Empty prompt - cannot generate text");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            [self prependDebugText:@"Error: Empty prompt. Please enter text to generate a response.\n"];
            return;
        }
        
        // Add a system prompt to guide the model's responses
        NSString *systemPrompt = @"System: You are a helpful assistant. Answer concisely and clearly.\n";
        NSString *prompt = [systemPrompt stringByAppendingFormat:@"User: %@\nAssistant:", userPrompt];
        NSLog(@"DEBUG: Full prompt with system instruction: %@", prompt);
        
        self.isGenerating = YES;
        [self updateButtonStates]; // Disable all generation buttons
        [self.activityIndicator startAnimating];
        
        NSLog(@"DEBUG: Starting text generation with mode: %@", mode);
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Generating for prompt: %@\n", prompt]];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\nGenerated text:\n"]];
        [self prependDebugText:[NSString stringWithFormat:@"Generation started with %@ mode...\n", mode]];
        
        // Clear current output
        [self.currentOutput setString:@""];
        
        // Generate text in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            if ([mode isEqualToString:@"completion"]) {
                // Set the static reference for the callback
                tokenCallbackViewController = self;
                
                // Advanced completion with streaming
                llama_mobile_completion_params_c_t completion_params = {
                    .prompt = [prompt UTF8String],
                    .n_predict = 300,          // Increased for more detailed responses
                    .temperature = 0.7,        // Optimal balance between creativity and coherence
                    .top_k = 50,
                    .top_p = 0.9,
                    .n_threads = 4,
                    .seed = -1
                };
                
                NSLog(@"DEBUG: Calling llama_mobile_completion_c with streaming");
                llama_mobile_completion_result_c_t result;
                int status = llama_mobile_completion_c(self.modelContext, &completion_params, &result);
                
                dispatch_async(dispatch_get_main_queue(), ^{                
                    NSLog(@"DEBUG: Completion generation finished with status: %d", status);
                    if (status == 0) {
                        NSLog(@"DEBUG: Completion successful - tokens generated: %d", result.tokens_predicted);
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Tokens generated: %d", result.tokens_predicted]];
                        [self prependDebugText:[NSString stringWithFormat:@"%@ generation completed successfully. Tokens generated: %d", mode, result.tokens_predicted]];
                        // Free memory directly since llama_mobile_free_completion_result_members_c is missing
                        if (result.text) {
                            llama_mobile_free_string_c(result.text);
                        }
                        if (result.stopping_word) {
                            llama_mobile_free_string_c(result.stopping_word);
                        }
                    } else {
                        NSLog(@"DEBUG: Completion failed with status: %d", status);
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Generation failed.\n"]];
                        [self prependDebugText:[NSString stringWithFormat:@"Error: %@ generation failed with status code %d\n", mode, status]];
                    }
                    
                    // Clear the prompt text field after clicking the button (regardless of success/failure)
                    [self.promptTextField setText:@"Enter your prompt here..."];
                    [self.promptTextField setTextColor:[UIColor lightGrayColor]];
                    
                    self.isGenerating = NO;
                    [self updateButtonStates]; // Enable relevant buttons
                    [self.activityIndicator stopAnimating];
                    
                    // Clear the static reference to prevent memory leaks
                    tokenCallbackViewController = nil;
                });
            } else {
                // Simple completion
                NSLog(@"DEBUG: Calling llama_mobile_completion_c (no streaming)");
                llama_mobile_completion_params_c_t completion_params = {
                    .prompt = [prompt UTF8String],
                    .n_predict = 300,          // Increased for more detailed responses
                    .temperature = 0.7,        // Consistent temperature with streaming
                    .n_threads = 4,
                    .seed = -1
                };
                
                llama_mobile_completion_result_c_t result;
                int status = llama_mobile_completion_c(self.modelContext, &completion_params, &result);
                
                dispatch_async(dispatch_get_main_queue(), ^{                
                    NSLog(@"DEBUG: Simple generation finished with status: %d", status);
                    if (status == 0) {
                        NSLog(@"DEBUG: Simple generation successful - tokens generated: %d", result.tokens_predicted);
                        NSString *generatedText = [NSString stringWithUTF8String:result.text];
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:generatedText]];
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nTokens generated: %d\n", result.tokens_predicted]];
                        [self prependDebugText:[NSString stringWithFormat:@"%@ generation completed successfully. Tokens generated: %d\n", mode, result.tokens_predicted]];
                        
                        // Free memory directly since llama_mobile_free_completion_result_members_c is missing
                        if (result.text) {
                            llama_mobile_free_string_c(result.text);
                        }
                        if (result.stopping_word) {
                            llama_mobile_free_string_c(result.stopping_word);
                        }
                    } else {
                        NSLog(@"DEBUG: Simple generation failed with status: %d", status);
                        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Generation failed.\n"]];
                        [self prependDebugText:[NSString stringWithFormat:@"Error: %@ generation failed with status code %d\n", mode, status]];
                    }
                    
                    // Clear the prompt text field after clicking the button (regardless of success/failure)
                    self.promptTextField.text = @"Enter your prompt here...";
                    [self.promptTextField setTextColor:[UIColor lightGrayColor]];
                    
                    self.isGenerating = NO;
                    [self updateButtonStates]; // Enable relevant buttons
                    [self.activityIndicator stopAnimating];
                });
            }
        });
    }
    
    // MARK: - Conversation
    
    - (IBAction)conversationPressed:(id)sender {
        NSLog(@"DEBUG: conversationPressed button clicked");
        [self prependDebugText:@"Starting conversation...\n"];
        
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot start conversation");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            [self prependDebugText:@"Error: Model not initialized. Please initialize the model first.\n"];
            return;
        }
        
        if (self.isGenerating) {
            NSLog(@"DEBUG: Generation already in progress - cannot start conversation");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generation already in progress.\n"]];
            [self prependDebugText:@"Error: Generation already in progress. Please wait for current generation to complete.\n"];
            return;
        }
        
        NSString *userPrompt = self.promptTextField.text;
        NSLog(@"DEBUG: Conversation user prompt: %@", userPrompt);
        if ([userPrompt length] == 0 || [userPrompt isEqualToString:@"Enter your prompt here..."]) {
            NSLog(@"DEBUG: Empty conversation prompt - returning");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            [self prependDebugText:@"Error: Empty prompt. Please enter text to start a conversation.\n"];
            return;
        }
        
        // Add a system prompt to guide the model's responses in conversation mode
        NSString *systemPrompt = @"System: You are a helpful assistant. Answer concisely and clearly.\n";
        NSString *prompt = [systemPrompt stringByAppendingFormat:@"User: %@\nAssistant:", userPrompt];
        NSLog(@"DEBUG: Full conversation prompt with system instruction: %@", prompt);
        
        self.isGenerating = YES;
        [self updateButtonStates]; // Disable all generation buttons
        [self.activityIndicator startAnimating];
        
        NSLog(@"DEBUG: Starting conversation generation");
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Conversation: %@\n", prompt]];
        [self prependDebugText:@"Conversation generation started...\n"];
        
        // Generate conversation response in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            NSLog(@"DEBUG: Calling llama_mobile_continue_conversation_c for conversation");
            llama_mobile_conversation_result_c_t conv_result = llama_mobile_continue_conversation_c(
                                                               self.modelContext,
                                                               [prompt UTF8String],
                                                               300           // Increased for more detailed responses
                                                               );
            
            dispatch_async(dispatch_get_main_queue(), ^{            
                [self.activityIndicator stopAnimating];
                NSLog(@"DEBUG: Conversation generation finished");
                
                // Check if text is valid (success)
                if (conv_result.text != NULL) {
                    NSLog(@"DEBUG: Conversation successful - time to first token: %lld ms, total time: %lld ms, tokens generated: %d", conv_result.time_to_first_token, conv_result.total_time, conv_result.tokens_generated);
                    NSString *response = [NSString stringWithUTF8String:conv_result.text];
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:response]];
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nTime to first token: %lld ms\nTotal time: %lld ms\nTokens generated: %d\n", conv_result.time_to_first_token, conv_result.total_time, conv_result.tokens_generated]];
                    [self prependDebugText:[NSString stringWithFormat:@"Conversation completed successfully. Time to first token: %lld ms, total time: %lld ms\n", conv_result.time_to_first_token, conv_result.total_time]];
                    
                    // Free memory directly since llama_mobile_free_conversation_result_members_c is problematic
                    if (conv_result.text) {
                        llama_mobile_free_string_c(conv_result.text);
                    }
                } else {
                    NSLog(@"DEBUG: Conversation failed - no response text");
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Conversation failed.\n"]];
                    [self prependDebugText:@"Error: Conversation generation failed - no response text\n"];
                }
                
                // Clear the prompt text field after clicking the button (regardless of success/failure)
                [self.promptTextField setText:@"Enter your prompt here..."];
                [self.promptTextField setTextColor:[UIColor lightGrayColor]];

                self.isGenerating = NO;
                [self updateButtonStates]; // Enable relevant buttons
            });
        });
    }
    
    // MARK: - Embeddings
    
    - (IBAction)embeddingPressed:(id)sender {
        NSLog(@"DEBUG: embeddingPressed button clicked");
        [self prependDebugText:@"Generating embeddings...\n"];
        
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot generate embeddings");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            [self prependDebugText:@"Error: Model not initialized. Cannot generate embeddings.\n"];
            return;
        }
        
        NSString *prompt = self.promptTextField.text;
        NSLog(@"DEBUG: Embedding prompt: %@", prompt);
        if ([prompt length] == 0 || [prompt isEqualToString:@"Enter your prompt here..."]) {
            NSLog(@"DEBUG: Empty embedding prompt - returning");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            [self prependDebugText:@"Error: Empty prompt. Please enter text to generate embeddings.\n"];
            return;
        }
        
        NSLog(@"DEBUG: Starting embedding generation");
        [self.activityIndicator startAnimating];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Generating embeddings for: %@\n", prompt]];
        
        // Generate embeddings in background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{        
            NSLog(@"DEBUG: Calling llama_mobile_embedding_c");
            llama_mobile_float_array_c_t embedding = llama_mobile_embedding_c(
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
                    [self prependDebugText:[NSString stringWithFormat:@"Embedding generation successful. Dimension: %d\n", embedding.count]];
                    
                    // Free embedding when done
                    llama_mobile_free_float_array_c(embedding);
                    
                    // Clear the prompt text field after successful generation
                    if ([self.promptTextField isKindOfClass:[UITextView class]]) {
                        UITextView *textView = (UITextView *)self.promptTextField;
                        [textView setText:@"Enter your prompt here..."];
                        [textView setTextColor:[UIColor lightGrayColor]];
                    } else if ([self.promptTextField isKindOfClass:[UITextField class]]) {
                        UITextField *textField = (UITextField *)self.promptTextField;
                        [textField setText:@""];
                    }
                } else {
                    NSLog(@"DEBUG: Embedding generation failed - count is zero");
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Failed to generate embeddings.\n"]];
                    [self prependDebugText:@"Error: Failed to generate embeddings.\n"];
                }
            });
        });
    }
    
    // MARK: - UI Helpers
    
    - (IBAction)clearPressed:(id)sender {
        [self.promptTextField setText:@"Enter your prompt here..."];
        [self.promptTextField setTextColor:[UIColor lightGrayColor]];
        [self.outputTextView setText:@""];
        [self.currentOutput setString:@""];
        // Also clear the debug log text view
        if (self.debugLogTextView) {
            [self.debugLogTextView setText:@""];
        }
        [self prependDebugText:@"UI cleared.\n"];
    }
    
    - (void)updateButtonStates {
        BOOL isModelInitialized = (self.modelContext != NULL);
        [self.generateButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.completeButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.conversationButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.embeddingButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.multimodalButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.ttsButton setEnabled:isModelInitialized && !self.isGenerating];
        [self.playAudioButton setEnabled:self.audioSamples != nil && !self.isPlayingAudio];
        [self.stopAudioButton setEnabled:self.isPlayingAudio];
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
        NSLog(@"DEBUG: multimodalPressed button clicked");
        [self prependDebugText:@"Starting multimodal processing...\n"];
        
        if (self.modelContext == NULL) {
            NSLog(@"DEBUG: Model not initialized - cannot use multimodal");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Model not initialized.\n"]];
            [self prependDebugText:@"Error: Model not initialized. Please initialize the model first.\n"];
            return;
        }
        
        if (self.isGenerating) {
            NSLog(@"DEBUG: Generation already in progress - cannot start multimodal");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generation already in progress.\n"]];
            [self prependDebugText:@"Error: Generation already in progress. Please wait for current generation to complete.\n"];
            return;
        }
        
        NSString *prompt = self.promptTextField.text;
        NSLog(@"DEBUG: Multimodal user prompt: %@", prompt);
        if ([prompt length] == 0 || [prompt isEqualToString:@"Enter your prompt here..."]) {
            NSLog(@"DEBUG: Empty multimodal prompt - returning");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Please enter a prompt.\n"]];
            [self prependDebugText:@"Error: Empty prompt. Please enter text to start multimodal processing.\n"];
            return;
        }
        
        // Initialize multimodal if not already done
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *mmprojPath = [[bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        mmprojPath = [mmprojPath stringByAppendingPathComponent:@"lib/models/mmproj-model.f16.gguf"];
        NSLog(@"DEBUG: Looking for mmproj file at: %@", mmprojPath);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:mmprojPath]) {
            [self prependDebugText:[NSString stringWithFormat:@"Initializing multimodal support from: %@\n", mmprojPath]];
            // Use GPU for multimodal processing if available
            int status = llama_mobile_init_multimodal_c(self.modelContext, [mmprojPath UTF8String], YES);
            if (status != 0) {
                NSLog(@"DEBUG: Failed to initialize multimodal support with status: %d", status);
                [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Error: Failed to initialize multimodal support.\n"]];
                [self prependDebugText:@"Error: Failed to initialize multimodal support.\n"];
                return;
            }
            [self prependDebugText:@"Multimodal support initialized successfully.\n"];
        } else {
            NSLog(@"DEBUG: Multimodal projection file not found, falling back to text only");
            [self prependDebugText:@"Warning: Multimodal projection file not found. Using text only.\n"];
            // Proceed with text-only completion
            [self generateTextWithMode:@"completion"];
            return;
        }
        
        // Show image picker to select an image for multimodal completion
        NSLog(@"DEBUG: Showing image picker for multimodal processing");
        [self prependDebugText:@"Opening image picker for multimodal processing...\n"];
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    
    - (void)processImageWithPrompt:(NSString *)prompt imagePath:(NSString *)imagePath {
        NSLog(@"DEBUG: processImageWithPrompt called with prompt: %@, imagePath: %@", prompt, imagePath);
        
        if (self.isGenerating) {
            NSLog(@"DEBUG: Generation already in progress - cannot process image");
            [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generation already in progress.\n"]];
            [self prependDebugText:@"Error: Generation already in progress. Please wait for current generation to complete.\n"];
            return;
        }
        
        self.isGenerating = YES;
        [self updateButtonStates]; // Disable all generation buttons
        [self.activityIndicator startAnimating];
        
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Multimodal Generation: %@\n", prompt]];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"Using image: %@\n\n", [imagePath lastPathComponent]]];
        [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"Generated text:\n"]];
        [self prependDebugText:@"Multimodal generation started with image...\n"];
        
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
            llama_mobile_completion_params_c_t completion_params = {
                .prompt = [prompt UTF8String],
                .n_predict = 200,
                .temperature = 0.7,
                .top_k = 50,
                .top_p = 0.9,
                .n_threads = 4,
                .seed = -1
            };
            
            NSLog(@"DEBUG: Calling llama_mobile_multimodal_completion_c");
            llama_mobile_completion_result_c_t result;
            int status = llama_mobile_multimodal_completion_c(self.modelContext, &completion_params, localMediaPaths, mediaCount, &result);
            
            dispatch_async(dispatch_get_main_queue(), ^{                
                [self.activityIndicator stopAnimating];
                NSLog(@"DEBUG: Multimodal generation finished with status: %d", status);
                
                if (status == 0) {
                    NSLog(@"DEBUG: Multimodal generation successful - tokens generated: %d", result.tokens_predicted);
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingFormat:@"\n\nGeneration completed. Tokens generated: %d\n", result.tokens_predicted]];
                    [self prependDebugText:[NSString stringWithFormat:@"Multimodal generation completed successfully. Tokens generated: %d\n", result.tokens_predicted]];
                    // Free memory directly since llama_mobile_free_completion_result_members_c is missing
                    if (result.text) {
                        llama_mobile_free_string_c(result.text);
                    }
                    if (result.stopping_word) {
                        llama_mobile_free_string_c(result.stopping_word);
                    }
                } else {
                    NSLog(@"DEBUG: Multimodal generation failed with status: %d", status);
                    [self.outputTextView setText:[self.outputTextView.text stringByAppendingString:@"\n\nError: Multimodal generation failed.\n"]];
                    [self prependDebugText:[NSString stringWithFormat:@"Error: Multimodal generation failed with status code %d\n", status]];
                }
                
                self.isGenerating = NO;
                [self updateButtonStates]; // Enable relevant buttons
                
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
    
    // MARK: - UITextView Delegate
    
    - (void)textViewDidBeginEditing:(UITextView *)textView {
        if ([textView.text isEqualToString:@"Enter your prompt here..."] && [textView.textColor isEqual:[UIColor lightGrayColor]]) {
            [textView setText:@""];
            [textView setTextColor:[UIColor blackColor]];
        }
    }
    
    - (void)textViewDidEndEditing:(UITextView *)textView {
        if ([textView.text isEqualToString:@""]) {
            [textView setText:@"Enter your prompt here..."];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    }
    
    // MARK: - UITextField Delegate
    
    - (BOOL)textFieldShouldReturn:(UITextField *)textField {
        [textField resignFirstResponder];
        return YES;
    }

    // MARK: - Text-to-Speech (TTS)
    
    - (IBAction)ttsPressed:(id)sender {
        NSLog(@"DEBUG: ttsPressed button clicked");
        [self prependDebugText:@"Starting text-to-speech generation...\n"];
        
        if (self.isGenerating) {
            [self prependDebugText:@"Error: Already generating text.\n"];
            return;
        }
        
        if (self.modelContext == NULL) {
            [self prependDebugText:@"Error: Model not initialized.\n"];
            return;
        }
        
        // Get the text to speak from the prompt text field
        NSString *textToSpeak = self.promptTextField.text;
        if ([textToSpeak isEqualToString:@""] || [textToSpeak isEqualToString:@"Enter your prompt here..."]) {
            [self prependDebugText:@"Error: No text entered.\n"];
            return;
        }
        
        // Find the vocoder model file in the bundle
        NSString *vocoderModelPath = [[NSBundle mainBundle] pathForResource:@"WavTokenizer-Large-75-F16" ofType:@"gguf"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:vocoderModelPath]) {
            [self prependDebugText:@"Error: Vocoder model not found in bundle.\n"];
            return;
        }
        
        // Initialize vocoder
        int vocoderStatus = llama_mobile_init_vocoder_c(self.modelContext, [vocoderModelPath UTF8String]);
        if (vocoderStatus != 0) {
            [self prependDebugText:@"Error: Failed to initialize vocoder.\n"];
            return;
        }
        
        self.isGenerating = YES;
        [self updateButtonStates];
        
        // Run TTS generation in a background thread to avoid blocking UI
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ 
            @try {
                NSLog(@"DEBUG: Getting audio completion guide tokens");
                [self prependDebugText:@"Generating audio guide tokens...\n"];
                
                // Set up completion parameters
                llama_mobile_completion_params_t params = {0};
                params.prompt = [textToSpeak UTF8String];
                params.max_tokens = 500;
                params.temperature = 0.7f;
                params.top_k = 40;
                params.top_p = 0.9f;
                params.min_p = 0.0f;
                params.penalty_repeat = 1.1f;
                
                // Generate audio tokens using the C API
                [self prependDebugText:@"Generating audio guide tokens...\n"];
                
                // Use the C API to get audio guide tokens
                llama_mobile_token_array_c_t guideTokensC = llama_mobile_get_audio_guide_tokens_c(self.modelContext, [textToSpeak UTF8String]);
                if (guideTokensC.tokens == NULL || guideTokensC.count == 0) {
                    [self prependDebugText:@"Error: Failed to generate guide tokens.\n"];
                    self.isGenerating = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{ 
                        [self updateButtonStates];
                    });
                    return;
                }
                
                // Convert to std::vector for processing
                std::vector<llama_token> audioTokens(guideTokensC.tokens, guideTokensC.tokens + guideTokensC.count);
                
                NSLog(@"DEBUG: Generated %ld audio tokens", audioTokens.size());
                
                if (audioTokens.empty()) {
                    [self prependDebugText:@"Error: No audio tokens generated.\n"];
                    self.isGenerating = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{ 
                        [self updateButtonStates];
                    });
                    return;
                }
                
                // Decode audio tokens using the C API
                [self prependDebugText:@"Decoding audio tokens...\n"];
                llama_mobile_float_array_c_t audioDataC = llama_mobile_decode_audio_tokens_c(self.modelContext, audioTokens.data(), (int32_t)audioTokens.size());
                if (audioDataC.values == NULL || audioDataC.count == 0) {
                    [self prependDebugText:@"Error: Failed to decode audio tokens.\n"];
                    self.isGenerating = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{ 
                        [self updateButtonStates];
                    });
                    return;
                }
                
                // Convert to std::vector for processing
                std::vector<float> audioData(audioDataC.values, audioDataC.values + audioDataC.count);
                
                // Free the C array memory using the C API functions
                llama_mobile_free_float_array_c(audioDataC);
                llama_mobile_free_token_array_c(guideTokensC);
                
                if (audioData.empty()) {
                    [self prependDebugText:@"Error: Failed to decode audio tokens.\n"];
                    self.isGenerating = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{ 
                        [self updateButtonStates];
                    });
                    return;
                }
                
                // Convert to NSArray of floats
                NSMutableArray *audioSamples = [NSMutableArray arrayWithCapacity:audioData.size()];
                for (float sample : audioData) {
                    [audioSamples addObject:@(sample)];
                }
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), ^{ 
                    self.audioSamples = [audioSamples copy];
                    [self prependDebugText:@"Text-to-speech generation completed successfully!\n"];
                    [self prependDebugText:[NSString stringWithFormat:@"Generated %ld audio samples.\n", audioData.size()]];
                    
                    // Show play button
                    self.playAudioButton.hidden = NO;
                    self.isGenerating = NO;
                    [self updateButtonStates];
                });
                
            } @catch (NSException *exception) {
                NSLog(@"ERROR: TTS generation exception: %@", exception);
                [self prependDebugText:[NSString stringWithFormat:@"Error: TTS generation failed - %@\n", exception.reason]];
                self.isGenerating = NO;
                dispatch_async(dispatch_get_main_queue(), ^{ 
                    [self updateButtonStates];
                });
            }
        });
    }
    
    - (IBAction)playAudioPressed:(id)sender {
        if (self.audioSamples == nil || self.audioSamples.count == 0) {
            [self prependDebugText:@"Error: No audio samples to play.\n"];
            return;
        }
        
        if (self.isPlayingAudio) {
            return;
        }
        
        // Prepare audio data for playback
        NSUInteger sampleCount = self.audioSamples.count;
        float *audioBuffer = (float *)malloc(sampleCount * sizeof(float));
        if (!audioBuffer) {
            [self prependDebugText:@"Error: Failed to allocate audio buffer.\n"];
            return;
        }
        
        for (NSUInteger i = 0; i < sampleCount; i++) {
            audioBuffer[i] = [self.audioSamples[i] floatValue];
        }
        
        // Configure audio format
        AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:24000 channels:1 interleaved:NO];
        
        // Create audio buffer
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:sampleCount];
        pcmBuffer.frameLength = sampleCount;
        
        // Copy audio data to buffer
        memcpy(pcmBuffer.floatChannelData[0], audioBuffer, sampleCount * sizeof(float));
        free(audioBuffer);
        
        // Prepare audio engine
        [self.audioEngine connect:self.audioPlayerNode to:self.audioEngine.mainMixerNode format:audioFormat];
        
        // Schedule playback
        [self.audioPlayerNode scheduleBuffer:pcmBuffer completionHandler:^{ 
            // Playback completed
            dispatch_async(dispatch_get_main_queue(), ^{ 
                self.isPlayingAudio = NO;
                self.playAudioButton.hidden = NO;
                self.stopAudioButton.hidden = YES;
                [self updateButtonStates];
            });
        }];
        
        // Start audio engine if it's not running
        if (!self.audioEngine.running) {
            NSError *error = nil;
            [self.audioEngine startAndReturnError:&error];
            if (error) {
                [self prependDebugText:[NSString stringWithFormat:@"Error: Failed to start audio engine - %@\n", error.localizedDescription]];
                return;
            }
        }
        
        // Start playback
        [self.audioPlayerNode play];
        self.isPlayingAudio = YES;
        
        // Update UI
        self.playAudioButton.hidden = YES;
        self.stopAudioButton.hidden = NO;
        [self updateButtonStates];
    }
    
    - (IBAction)stopAudioPressed:(id)sender {
        if (!self.isPlayingAudio) {
            return;
        }
        
        // Stop playback
        [self.audioPlayerNode stop];
        [self.audioEngine stop];
        [self.audioEngine reset];
        
        // Update UI
        self.isPlayingAudio = NO;
        self.playAudioButton.hidden = NO;
        self.stopAudioButton.hidden = YES;
        [self updateButtonStates];
    }

@end
