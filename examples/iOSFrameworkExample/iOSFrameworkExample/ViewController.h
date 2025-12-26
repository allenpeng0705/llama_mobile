//
//  ViewController.h
//  iOSFrameworkExample
//
//  Created by on 2024-12-24.
//

#import <UIKit/UIKit.h>
#include <llama_mobile/llama_mobile_unified.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property (nonatomic, assign) llama_mobile_context_t modelContext;
@property (nonatomic, strong) NSMutableString *currentOutput;
@property (nonatomic, assign) BOOL isGenerating;

// UI Elements
@property (weak, nonatomic) IBOutlet UITextField *promptTextField;
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (weak, nonatomic) IBOutlet UIButton *generateButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UIButton *embeddingButton;
@property (weak, nonatomic) IBOutlet UIButton *conversationButton;
@property (weak, nonatomic) IBOutlet UIButton *initializeButton;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;
@property (weak, nonatomic) IBOutlet UIButton *multimodalButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UITextView *debugLogTextView;

// Actions
- (IBAction)generatePressed:(id)sender;
- (IBAction)clearPressed:(id)sender;
- (IBAction)embeddingPressed:(id)sender;
- (IBAction)conversationPressed:(id)sender;
- (IBAction)initializePressed:(id)sender;
- (IBAction)completePressed:(id)sender;
- (IBAction)multimodalPressed:(id)sender;

// Helper methods
- (void)updateButtonStates;
- (void)prependDebugText:(NSString *)text;

@end
