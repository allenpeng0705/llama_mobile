#import "LlamaMobileReactNativeSdk.h"
#import <llama_mobile/llama_mobile_api.h>

@implementation LlamaMobileReactNativeSdk

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(initialize) {
  llama_mobile_initialize();
}

RCT_EXPORT_METHOD(loadModel:(NSString *)modelPath withParams:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    llama_mobile_model_params_t modelParams = llama_mobile_model_params_default();
    
    // Set parameters from dictionary
    if (params[@"n_threads"] != nil) {
      modelParams.n_threads = [params[@"n_threads"] intValue];
    }
    if (params[@"n_batch"] != nil) {
      modelParams.n_batch = [params[@"n_batch"] intValue];
    }
    if (params[@"n_gpu_layers"] != nil) {
      modelParams.n_gpu_layers = [params[@"n_gpu_layers"] intValue];
    }
    
    const char *modelPathCStr = [modelPath UTF8String];
    llama_mobile_load_model(modelPathCStr, &modelParams);
    resolve(@"Model loaded successfully");
  } @catch (NSException *exception) {
    reject(@"LOAD_MODEL_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(generateText:(NSString *)prompt resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    const char *promptCStr = [prompt UTF8String];
    
    llama_mobile_text_params_t textParams = llama_mobile_text_params_default();
    char *result = llama_mobile_generate_text(promptCStr, &textParams);
    
    if (result != NULL) {
      NSString *resultStr = [NSString stringWithUTF8String:result];
      llama_mobile_free(result);
      resolve(resultStr);
    } else {
      reject(@"GENERATE_TEXT_ERROR", @"Failed to generate text", nil);
    }
  } @catch (NSException *exception) {
    reject(@"GENERATE_TEXT_ERROR", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(generateTextStream:(NSString *)prompt resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  // This would be implemented with event emitters for streaming
  reject(@"NOT_IMPLEMENTED", @"Streaming not implemented yet", nil);
}

RCT_EXPORT_METHOD(stopGeneration) {
  llama_mobile_stop_generation();
}

RCT_EXPORT_METHOD(unloadModel) {
  llama_mobile_unload_model();
}

@end
