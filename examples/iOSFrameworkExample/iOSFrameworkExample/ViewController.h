//
//  ViewController.h
//  iOSFrameworkExample
//
//  Created by on 2024-12-24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <llama_mobile_unified.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, assign) llama_mobile_context_t modelContext;
@property (nonatomic, strong) NSMutableString *currentOutput;
@property (nonatomic, assign) BOOL isGenerating;
@property (nonatomic, assign) BOOL isPlayingAudio;
@property (nonatomic, strong) NSArray *audioSamples;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) AVAudioPlayerNode *audioPlayerNode;

// UI Elements
@property (strong, nonatomic) UITextView *promptTextField;
@property (strong, nonatomic) UITextView *outputTextView;
@property (strong, nonatomic) UIButton *generateButton;
@property (strong, nonatomic) UIButton *clearButton;
@property (strong, nonatomic) UIButton *embeddingButton;
@property (strong, nonatomic) UIButton *conversationButton;
@property (strong, nonatomic) UIButton *initializeButton;
@property (strong, nonatomic) UIButton *completeButton;
@property (strong, nonatomic) UIButton *multimodalButton;
@property (strong, nonatomic) UIButton *ttsButton;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UITextView *debugLogTextView;
@property (nonatomic, strong) UIScrollView *scrollView;

// TTS UI
@property (strong, nonatomic) UIButton *playAudioButton;
@property (strong, nonatomic) UIButton *stopAudioButton;

// Model selection UI
@property (nonatomic, strong) UILabel *modelLabel;
@property (nonatomic, strong) UITextField *modelDropdownTextField;
@property (nonatomic, strong) UIPickerView *modelPickerView;
@property (nonatomic, strong) NSArray *availableModels;
@property (nonatomic, strong) NSMutableDictionary *modelPaths;

// Vocoder model selection UI
@property (nonatomic, strong) UILabel *vocoderModelLabel;
@property (nonatomic, strong) UITextField *vocoderModelDropdownTextField;
@property (nonatomic, strong) UIPickerView *vocoderModelPickerView;
@property (nonatomic, strong) NSArray *availableVocoderModels;
@property (nonatomic, strong) NSMutableDictionary *vocoderModelPaths;

// Projection file selection UI
@property (nonatomic, strong) UILabel *projectionFileLabel;
@property (nonatomic, strong) UITextField *projectionFileDropdownTextField;
@property (nonatomic, strong) UIPickerView *projectionFilePickerView;
@property (nonatomic, strong) NSArray *availableProjectionFiles;
@property (nonatomic, strong) NSMutableDictionary *projectionFilePaths;

// Image picker for multimodal testing
@property (nonatomic, strong) UIButton *imagePickerButton;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, strong) UIImage *selectedImage;

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
- (IBAction)imagePickerPressed:(id)sender;

// Helper methods
- (void)updateButtonStates;
- (void)prependDebugText:(NSString *)text;

@end
