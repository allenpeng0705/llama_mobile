#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(LlamaMobileReactNativeSdk, NSObject)

RCT_EXTERN_METHOD(initialize)
RCT_EXTERN_METHOD(loadModel:(NSString *)modelPath withParams:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(generateText:(NSString *)prompt resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(generateTextStream:(NSString *)prompt resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(stopGeneration)
RCT_EXTERN_METHOD(unloadModel)

@end
