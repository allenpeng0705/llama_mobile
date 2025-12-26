//
//  ViewController.h
//  iOSFrameworkExample
//
//  Created by on 2024-12-24.
//

#import <UIKit/UIKit.h>
#include <llama_mobile/llama_mobile_unified.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, assign) llama_mobile_context_t modelContext;
@property (nonatomic, assign) llama_mobile_context_vocoder_t vocoderContext;
@property (nonatomic, strong) NSMutableString *currentOutput;
@property (nonatomic, assign) BOOL isGenerating;
@property (nonatomic, assign) BOOL isPlayingAudio;
@property (nonatomic, strong) NSArray *audioSamples;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) AVAudioPlayerNode *audioPlayerNode;

// UI Elements
@property (weak, nonatomic) IBOutlet UITextView *promptTextField;
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (weak, nonatomic) IBOutlet UIButton *generateButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UIButton *embeddingButton;
@property (weak, nonatomic) IBOutlet UIButton *conversationButton;
@property (weak, nonatomic) IBOutlet UIButton *initializeButton;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;
@property (weak, nonatomic) IBOutlet UIButton *multimodalButton;
@property (weak, nonatomic) IBOutlet UIButton *ttsButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UITextView *debugLogTextView;
@property (nonatomic, strong) UIScrollView *scrollView;

// TTS UI
@property (weak, nonatomic) IBOutlet UIButton *playAudioButton;
@property (weak, nonatomic) IBOutlet UIButton *stopAudioButton;

// Model selection UI
@property (nonatomic, strong) UILabel *modelLabel;
@property (nonatomic, strong) UITextField *modelDropdownTextField;
@property (nonatomic, strong) UIPickerView *modelPickerView;
@property (nonatomic, strong) NSArray *availableModels;
@property (nonatomic, strong) NSMutableDictionary *modelPaths;

// Actions
- (IBAction)generatePressed:(id)sender;
- (IBAction)clearPressed:(id)sender;
- (IBAction)embeddingPressed:(id)sender;
- (IBAction)conversationPressed:(id)sender;
- (IBAction)initializePressed:(id)sender;
- (IBAction)completePressed:(id)sender;
- (IBAction)multimodalPressed:(id)sender;
- (IBAction)ttsPressed:(id)sender;
- (IBAction)playAudioPressed:(id)sender;
- (IBAction)stopAudioPressed:(id)sender;

// Helper methods
- (void)updateButtonStates;
- (void)prependDebugText:(NSString *)text;

@end
