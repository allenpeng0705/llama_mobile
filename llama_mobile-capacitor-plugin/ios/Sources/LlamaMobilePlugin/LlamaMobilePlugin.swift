import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(LlamaMobilePlugin)
public class LlamaMobilePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LlamaMobilePlugin"
    public let jsName = "LlamaMobile"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getGrammarContent", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "release", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = LlamaMobile()

    @objc func initialize(_ call: CAPPluginCall) {
        guard let params = call.getObject("params") else {
            call.reject("Missing params")
            return
        }
        
        let result = implementation.initialize(params)
        call.resolve([
            "success": result
        ])
    }
    
    @objc func generate(_ call: CAPPluginCall) {
        guard let params = call.getObject("params") else {
            call.reject("Missing params")
            return
        }
        
        if let result = implementation.generate(params) {
            call.resolve([
                "output": result
            ])
        } else {
            call.reject("Generation failed")
        }
    }
    
    @objc func getGrammarContent(_ call: CAPPluginCall) {
        guard let grammarName = call.getString("grammarName") else {
            call.reject("Missing grammarName")
            return
        }
        
        if let content = implementation.getGrammarContent(grammarName) {
            call.resolve([
                "content": content
            ])
        } else {
            call.reject("Grammar not found")
        }
    }
    
    @objc func release(_ call: CAPPluginCall) {
        implementation.release()
        call.resolve()
    }
}
