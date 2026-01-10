#import "LlamaMobileReactNativeSdk.h"
#import <llama_mobile/llama_mobile_api.h>

@interface LlamaMobileReactNativeSdk ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, RCTEventEmitter *> *eventEmitters;
@property (nonatomic, assign) llama_mobile_context_t context;
@end

@implementation LlamaMobileReactNativeSdk

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

- (instancetype)init {
  if (self = [super init]) {
    _context = nil;
    _eventEmitters = [NSMutableDictionary dictionary];
    sharedInstance = self;
  }
  return self;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"onToken", @"onCompletion", @"onError"];
}

- (void)startObserving {
  [self sendEventWithName:@"onCompletion" body:@{@"text": @"", @"tokensGenerated": @0}];
}

- (void)stopObserving {
  // No special cleanup needed
}

static LlamaMobileReactNativeSdk *sharedInstance = nil;

static bool tokenCallback(const char* token) {
  if (token && strlen(token) > 0) {
    NSString *tokenStr = [NSString stringWithUTF8String:token];
    dispatch_async(dispatch_get_main_queue(), ^{
      [sharedInstance sendEventWithName:@"onToken" body:@{@"token": tokenStr}];
    });
  }
  return true;
}

RCT_EXPORT_METHOD(initialize) {
  // No explicit initialization needed, handled by init method
}

RCT_EXPORT_METHOD(loadModel:(NSString *)modelPath withParams:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    // Free existing context if it exists
    if (_context != nil) {
      llama_mobile_free(_context);
      _context = nil;
    }
    
    // Create init params
    llama_mobile_init_params_t initParams;
    memset(&initParams, 0, sizeof(initParams));
    
    initParams.model_path = [modelPath UTF8String];
    initParams.n_ctx = params[@"n_ctx"] ? [params[@"n_ctx"] intValue] : 2048;
    initParams.n_batch = params[@"n_batch"] ? [params[@"n_batch"] intValue] : 512;
    initParams.n_gpu_layers = params[@"n_gpu_layers"] ? [params[@"n_gpu_layers"] intValue] : 0;
    initParams.n_threads = params[@"n_threads"] ? [params[@"n_threads"] intValue] : 4;
    initParams.use_mmap = params[@"use_mmap"] ? [params[@"use_mmap"] boolValue] : true;
    initParams.use_mlock = params[@"use_mlock"] ? [params[@"use_mlock"] boolValue] : false;
    initParams.embedding = params[@"embedding"] ? [params[@"embedding"] boolValue] : false;
    
    // Initialize context
    _context = llama_mobile_init(&initParams);
    
    if (_context != nil) {
      resolve(@"Model loaded successfully");
    } else {
      reject(@"LOAD_MODEL_ERROR", @"Failed to load model", nil);
    }
  } @catch (NSException *exception) {
    reject(@"LOAD_MODEL_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(generateText:(NSString *)prompt withParams:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"GENERATE_TEXT_ERROR", @"No model loaded", nil);
      return;
    }
    
    // Create completion params
    llama_mobile_completion_params_t completionParams;
    memset(&completionParams, 0, sizeof(completionParams));
    
    completionParams.prompt = [prompt UTF8String];
    completionParams.max_tokens = params[@"max_tokens"] ? [params[@"max_tokens"] intValue] : 100;
    completionParams.temperature = params[@"temperature"] ? [params[@"temperature"] doubleValue] : 0.7;
    completionParams.top_k = params[@"top_k"] ? [params[@"top_k"] intValue] : 40;
    completionParams.top_p = params[@"top_p"] ? [params[@"top_p"] doubleValue] : 0.9;
    completionParams.min_p = params[@"min_p"] ? [params[@"min_p"] doubleValue] : 0.05;
    completionParams.penalty_repeat = params[@"penalty_repeat"] ? [params[@"penalty_repeat"] doubleValue] : 1.1;
    
    // Handle stop sequences
    if (params[@"stopSequences"] && [params[@"stopSequences"] isKindOfClass:[NSArray class]]) {
      NSArray *stopSequences = params[@"stopSequences"];
      int count = (int)stopSequences.count;
      if (count > 0) {
        const char **cStopSequences = malloc(count * sizeof(const char *));
        for (int i = 0; i < count; i++) {
          cStopSequences[i] = [stopSequences[i] UTF8String];
        }
        completionParams.stop_sequences = cStopSequences;
        completionParams.stop_sequence_count = count;
      }
    }
    
    // Handle grammar
    if (params[@"grammar"] && [params[@"grammar"] isKindOfClass:[NSString class]]) {
      completionParams.grammar = [params[@"grammar"] UTF8String];
    }
    
    // Set token callback if streaming is enabled
    bool isStreaming = params[@"streaming"] ? [params[@"streaming"] boolValue] : false;
    if (isStreaming) {
      completionParams.token_callback = tokenCallback;
    }
    
    // Generate completion
    llama_mobile_completion_result_t result;
    int status = llama_mobile_completion(_context, &completionParams, &result);
    
    // Free stop sequences if allocated
    if (completionParams.stop_sequences) {
      free((void *)completionParams.stop_sequences);
    }
    
    if (status == 0 && result.text != NULL) {
      NSMutableDictionary *response = [NSMutableDictionary dictionary];
      response[@"text"] = [NSString stringWithUTF8String:result.text];
      response[@"tokensGenerated"] = @(result.tokens_generated);
      response[@"tokensEvaluated"] = @(result.tokens_evaluated);
      response[@"truncated"] = @(result.truncated);
      response[@"stoppedEos"] = @(result.stopped_eos);
      response[@"stoppedWord"] = @(result.stopped_word);
      response[@"stoppedLimit"] = @(result.stopped_limit);
      
      llama_mobile_free_completion_result(&result);
      resolve(response);
    } else {
      if (result.text != NULL) {
        llama_mobile_free_completion_result(&result);
      }
      reject(@"GENERATE_TEXT_ERROR", @"Failed to generate text", nil);
    }
  } @catch (NSException *exception) {
    reject(@"GENERATE_TEXT_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(streamText:(NSString *)prompt withParams:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"STREAM_TEXT_ERROR", @"No model loaded", nil);
      return;
    }
    
    // Create completion params
    llama_mobile_completion_params_t completionParams;
    memset(&completionParams, 0, sizeof(completionParams));
    
    completionParams.prompt = [prompt UTF8String];
    completionParams.max_tokens = params[@"max_tokens"] ? [params[@"max_tokens"] intValue] : 100;
    completionParams.temperature = params[@"temperature"] ? [params[@"temperature"] doubleValue] : 0.7;
    completionParams.top_k = params[@"top_k"] ? [params[@"top_k"] intValue] : 40;
    completionParams.top_p = params[@"top_p"] ? [params[@"top_p"] doubleValue] : 0.9;
    completionParams.min_p = params[@"min_p"] ? [params[@"min_p"] doubleValue] : 0.05;
    completionParams.penalty_repeat = params[@"penalty_repeat"] ? [params[@"penalty_repeat"] doubleValue] : 1.1;
    
    // Handle stop sequences
    if (params[@"stopSequences"] && [params[@"stopSequences"] isKindOfClass:[NSArray class]]) {
      NSArray *stopSequences = params[@"stopSequences"];
      int count = (int)stopSequences.count;
      if (count > 0) {
        const char **cStopSequences = malloc(count * sizeof(const char *));
        for (int i = 0; i < count; i++) {
          cStopSequences[i] = [stopSequences[i] UTF8String];
        }
        completionParams.stop_sequences = cStopSequences;
        completionParams.stop_sequence_count = count;
      }
    }
    
    // Handle grammar
    if (params[@"grammar"] && [params[@"grammar"] isKindOfClass:[NSString class]]) {
      completionParams.grammar = [params[@"grammar"] UTF8String];
    }
    
    // Set up streaming by sending tokens via events
    completionParams.token_callback = tokenCallback;
    
    // Generate completion in a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
      // Generate completion
      llama_mobile_completion_result_t result;
      int status = llama_mobile_completion(_context, &completionParams, &result);
      
      // Free stop sequences if allocated
      if (completionParams.stop_sequences) {
        free((void *)completionParams.stop_sequences);
      }
      
      // Send completion event
      if (status == 0 && result.text != NULL) {
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[@"text"] = [NSString stringWithUTF8String:result.text];
        response[@"tokensGenerated"] = @(result.tokens_generated);
        response[@"tokensEvaluated"] = @(result.tokens_evaluated);
        response[@"truncated"] = @(result.truncated);
        response[@"stoppedEos"] = @(result.stopped_eos);
        response[@"stoppedWord"] = @(result.stopped_word);
        response[@"stoppedLimit"] = @(result.stopped_limit);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
          [sharedInstance sendEventWithName:@"onCompletion" body:response];
        });
        
        llama_mobile_free_completion_result(&result);
      } else {
        if (result.text != NULL) {
          llama_mobile_free_completion_result(&result);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
          [sharedInstance sendEventWithName:@"onError" body:@{@"error": @"Failed to generate text"}];
        });
      }
    });
    
    resolve(@"Streaming started");
  } @catch (NSException *exception) {
    reject(@"STREAM_TEXT_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(stopGeneration) {
  @try {
    if (_context != nil) {
      llama_mobile_stop_completion(_context);
    }
  } @catch (NSException *exception) {
    NSLog(@"Error stopping generation: %@", exception.reason);
  }
}

RCT_EXPORT_METHOD(unloadModel) {
  @try {
    if (_context != nil) {
      llama_mobile_free(_context);
      _context = nil;
    }
  } @catch (NSException *exception) {
    NSLog(@"Error unloading model: %@", exception.reason);
  }
}

RCT_EXPORT_METHOD(tokenize:(NSString *)text resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"TOKENIZE_ERROR", @"No model loaded", nil);
      return;
    }
    
    const char *textCStr = [text UTF8String];
    llama_mobile_token_array_t tokens = llama_mobile_tokenize(_context, textCStr);
    
    NSMutableArray *tokenArray = [NSMutableArray arrayWithCapacity:tokens.count];
    for (int i = 0; i < tokens.count; i++) {
      [tokenArray addObject:@(tokens.tokens[i])];
    }
    
    llama_mobile_free_token_array(tokens);
    resolve(tokenArray);
  } @catch (NSException *exception) {
    reject(@"TOKENIZE_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(detokenize:(NSArray *)tokens resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"DETOKENIZE_ERROR", @"No model loaded", nil);
      return;
    }
    
    // Convert NSArray to int32_t array
    int32_t *tokenArray = malloc(tokens.count * sizeof(int32_t));
    for (int i = 0; i < tokens.count; i++) {
      tokenArray[i] = [tokens[i] intValue];
    }
    
    char *result = llama_mobile_detokenize(_context, tokenArray, (int32_t)tokens.count);
    free(tokenArray);
    
    if (result != NULL) {
      NSString *resultStr = [NSString stringWithUTF8String:result];
      llama_mobile_free_string(result);
      resolve(resultStr);
    } else {
      reject(@"DETOKENIZE_ERROR", @"Failed to detokenize", nil);
    }
  } @catch (NSException *exception) {
    reject(@"DETOKENIZE_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(generateEmbeddings:(NSString *)text resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"EMBEDDINGS_ERROR", @"No model loaded", nil);
      return;
    }
    
    const char *textCStr = [text UTF8String];
    llama_mobile_float_array_t embeddings = llama_mobile_embedding(_context, textCStr);
    
    NSMutableArray *embeddingArray = [NSMutableArray arrayWithCapacity:embeddings.count];
    for (int i = 0; i < embeddings.count; i++) {
      [embeddingArray addObject:@(embeddings.values[i])];
    }
    
    llama_mobile_free_float_array(embeddings);
    resolve(embeddingArray);
  } @catch (NSException *exception) {
    reject(@"EMBEDDINGS_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(applyLoraAdapters:(NSArray *)adapters resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"LORA_ERROR", @"No model loaded", nil);
      return;
    }
    
    int adapterCount = (int)adapters.count;
    if (adapterCount == 0) {
      resolve(@"No adapters to apply");
      return;
    }
    
    // Convert NSArray of dictionaries to llama_mobile_lora_adapter_t array
    llama_mobile_lora_adapter_t *loraAdapters = malloc(adapterCount * sizeof(llama_mobile_lora_adapter_t));
    
    for (int i = 0; i < adapterCount; i++) {
      NSDictionary *adapterDict = adapters[i];
      loraAdapters[i].path = [[adapterDict objectForKey:@"path"] UTF8String];
      loraAdapters[i].scale = [[adapterDict objectForKey:@"scale"] doubleValue];
    }
    
    int status = llama_mobile_apply_lora_adapters(_context, loraAdapters, adapterCount);
    free(loraAdapters);
    
    if (status == 0) {
      resolve(@"LoRA adapters applied successfully");
    } else {
      reject(@"LORA_ERROR", @"Failed to apply LoRA adapters", nil);
    }
  } @catch (NSException *exception) {
    reject(@"LORA_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(removeLoraAdapters resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"LORA_ERROR", @"No model loaded", nil);
      return;
    }
    
    llama_mobile_remove_lora_adapters(_context);
    resolve(@"LoRA adapters removed successfully");
  } @catch (NSException *exception) {
    reject(@"LORA_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(initMultimodal:(NSString *)mmprojPath useGpu:(BOOL)useGpu resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"MULTIMODAL_ERROR", @"No model loaded", nil);
      return;
    }
    
    int status = llama_mobile_init_multimodal(_context, [mmprojPath UTF8String], useGpu);
    
    if (status == 0) {
      resolve(@"Multimodal initialized successfully");
    } else {
      reject(@"MULTIMODAL_ERROR", @"Failed to initialize multimodal", nil);
    }
  } @catch (NSException *exception) {
    reject(@"MULTIMODAL_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(isMultimodalEnabled resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      resolve(@NO);
      return;
    }
    
    bool isEnabled = llama_mobile_is_multimodal_enabled(_context);
    resolve(@(isEnabled));
  } @catch (NSException *exception) {
    reject(@"MULTIMODAL_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(releaseMultimodal resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      resolve(@"No multimodal to release");
      return;
    }
    
    llama_mobile_release_multimodal(_context);
    resolve(@"Multimodal resources released");
  } @catch (NSException *exception) {
    reject(@"MULTIMODAL_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(generateConversationResponse:(NSString *)userMessage maxTokens:(int)maxTokens resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      reject(@"CONVERSATION_ERROR", @"No model loaded", nil);
      return;
    }
    
    llama_mobile_conversation_result_t result;
    int status = llama_mobile_generate_response(_context, [userMessage UTF8String], maxTokens, &result);
    
    if (status == 0 && result.text != NULL) {
      NSMutableDictionary *response = [NSMutableDictionary dictionary];
      response[@"text"] = [NSString stringWithUTF8String:result.text];
      response[@"timeToFirstToken"] = @(result.time_to_first_token);
      response[@"totalTime"] = @(result.total_time);
      response[@"tokensGenerated"] = @(result.tokens_generated);
      
      llama_mobile_free_conversation_result(&result);
      resolve(response);
    } else {
      if (result.text != NULL) {
        llama_mobile_free_conversation_result(&result);
      }
      reject(@"CONVERSATION_ERROR", @"Failed to generate conversation response", nil);
    }
  } @catch (NSException *exception) {
    reject(@"CONVERSATION_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(clearConversation resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    if (_context == nil) {
      resolve(@"No conversation to clear");
      return;
    }
    
    llama_mobile_clear_conversation(_context);
    resolve(@"Conversation cleared successfully");
  } @catch (NSException *exception) {
    reject(@"CONVERSATION_ERROR", exception.reason, nil);
  }
}

@end
