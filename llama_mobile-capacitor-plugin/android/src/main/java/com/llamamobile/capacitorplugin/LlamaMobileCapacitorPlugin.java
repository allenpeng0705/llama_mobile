package com.llamamobile.capacitorplugin;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.PluginMethod;
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.TTSOptions;
import com.llamamobile.LlamaMobile.SpeechResult;
import com.llamamobile.LlamaMobile.SpeechMetadata;
import com.llamamobile.LlamaMobile.TTSError;
import com.llamamobile.LlamaMobile.Result;
import com.llamamobile.LlamaMobile.ProgressCallback;
import com.llamamobile.LlamaMobile.AudioChunkCallback;
import org.json.JSONObject;

import android.os.Environment;
import android.util.Log;
import android.content.res.AssetManager;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@CapacitorPlugin(name = "LlamaMobileCapacitorPlugin")
public class LlamaMobileCapacitorPlugin extends Plugin {

    private final ExecutorService executor = Executors.newCachedThreadPool();
    private final Map<Long, Long> contextHandles = new HashMap<>();
    private long nextContextHandle = 1;

    private synchronized long getNextContextHandle() {
        return nextContextHandle++;
    }

    private long getContextHandle(PluginCall call) {
        long contextHandle = -1L;
        Object contextHandleObj = call.getData().opt("contextHandle");
        if (contextHandleObj != null) {
            if (contextHandleObj instanceof Integer) {
                contextHandle = ((Integer) contextHandleObj).longValue();
            } else if (contextHandleObj instanceof Long) {
                contextHandle = ((Long) contextHandleObj).longValue();
            } else if (contextHandleObj instanceof Number) {
                contextHandle = ((Number) contextHandleObj).longValue();
            }
        }
        return contextHandle;
    }

    private Long getNativeContextHandle(long contextHandle) {
        Long nativeHandle = contextHandles.get(contextHandle);
        Log.d("LlamaMobilePlugin", "getNativeContextHandle: Called with handle: " + contextHandle);
        Log.d("LlamaMobilePlugin", "getNativeContextHandle: Returning native handle: " + nativeHandle);
        Log.d("LlamaMobilePlugin", "getNativeContextHandle: Current contextHandles: " + contextHandles);
        return nativeHandle;
    }

    @Override
    protected void handleOnDestroy() {
        executor.shutdown();
        for (Long contextHandle : contextHandles.values()) {
            LlamaMobile.releaseContext(contextHandle);
        }
        contextHandles.clear();
    }

    // MARK: - Initialization

    @PluginMethod
    public void initContext(PluginCall call) {
        // Log the entire call object
        Log.d("LlamaMobilePlugin", "initContext called with call: " + call);
        Log.d("LlamaMobilePlugin", "initContext: All parameters: " + call.getData());
        
        String modelPath = call.getString("modelPath");
        int nCtx = call.getInt("nCtx", 2048);
        int nGpuLayers = call.getInt("nGpuLayers", 0);
        int nThreads = call.getInt("nThreads", 4);
        boolean embedding = call.getBoolean("embedding", false);
        int poolingType = call.getInt("poolingType", 0);
        int embdNormalize = call.getInt("embdNormalize", 1);
        int imageMinTokens = call.getInt("imageMinTokens", -1);

        if (modelPath == null) {
            Log.d("LlamaMobilePlugin", "initContext: modelPath is null, rejecting call");
            call.reject("modelPath is required");
            return;
        }

        // Log the received model path
        Log.d("LlamaMobilePlugin", "Received model path: " + modelPath);
        
        // Resolve model path if it's just a filename
        String resolvedModelPath = resolveModelPath(modelPath);
        
        // Log the resolved model path
        Log.d("LlamaMobilePlugin", "Resolved model path: " + resolvedModelPath);

        executor.execute(() -> {
            try {
                Log.d("LlamaMobilePlugin", "initContext: Creating InitParams with modelPath: " + resolvedModelPath);
                LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                    resolvedModelPath, nCtx, null, null, 512, 512, nGpuLayers, nThreads, 
                    true, false, embedding, poolingType, embdNormalize, false, 
                    null, null, false, null, imageMinTokens
                );
                
                Log.d("LlamaMobilePlugin", "initContext: Calling LlamaMobile.initContext");
                long nativeContextHandle = LlamaMobile.initContext(params);
                Log.d("LlamaMobilePlugin", "initContext: Native context handle returned: " + nativeContextHandle);

                long handle = getNextContextHandle();
                Log.d("LlamaMobilePlugin", "initContext: Generated handle: " + handle + " for native handle: " + nativeContextHandle);
                
                contextHandles.put(handle, nativeContextHandle);
                Log.d("LlamaMobilePlugin", "initContext: Stored context handle mapping: " + handle + " -> " + nativeContextHandle);
                Log.d("LlamaMobilePlugin", "initContext: Current contextHandles size: " + contextHandles.size());

                JSObject ret = new JSObject();
                ret.put("contextHandle", handle);
                Log.d("LlamaMobilePlugin", "initContext: Resolving call with handle: " + handle);
                call.resolve(ret);
            } catch (Exception e) {
                Log.d("LlamaMobilePlugin", "initContext: Exception occurred: " + e.getMessage());
                e.printStackTrace();
                call.reject("Failed to initialize context: " + e.getMessage());
            }
        });
    }

    // Helper method to resolve model paths
    private String resolveModelPath(String modelPath) {
        // If the path is already absolute, return it as-is
        if (modelPath.startsWith("/")) {
            System.out.println("Model path is already absolute: " + modelPath);
            return modelPath;
        }

        // Check if this is an asset path (starts with "public/models/" or "models/")
        if (modelPath.startsWith("public/models/") || modelPath.startsWith("models/")) {
            System.out.println("Model path appears to be an asset path: " + modelPath);
            // Copy asset to cache directory and return the file path
            try {
                return copyAssetToCache(modelPath);
            } catch (IOException e) {
                System.out.println("Failed to copy asset to cache: " + e.getMessage());
                // Continue with file system search
            }
        }

        // Log the external files directory path
        String externalFilesDir = getContext().getExternalFilesDir(null).getAbsolutePath();
        System.out.println("External files directory: " + externalFilesDir);

        // List of common directories to search for models
        String[] searchDirs = {
            // App's internal files directory
            getContext().getFilesDir().getAbsolutePath(),
            getContext().getFilesDir().getAbsolutePath() + File.separator + "models",
            getContext().getFilesDir().getAbsolutePath() + File.separator + "Downloads",
            getContext().getFilesDir().getAbsolutePath() + File.separator + "Downloads" + File.separator + "models",
            // App's external files directory
            externalFilesDir,
            externalFilesDir + File.separator + "models",
            externalFilesDir + File.separator + "Downloads",
            externalFilesDir + File.separator + "Downloads" + File.separator + "models",
            // Legacy LlamaMobile/models directory (from Android SDK example)
            getContext().getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS).getAbsolutePath() + File.separator + "LlamaMobile" + File.separator + "models"
        };

        // Log all search directories
        System.out.println("Searching for model " + modelPath + " in directories:");
        for (String dir : searchDirs) {
            File directory = new File(dir);
            System.out.println("- " + dir + " (exists: " + directory.exists() + ")");
        }

        // Search for the model file in common directories and their subdirectories
        for (String dir : searchDirs) {
            File directory = new File(dir);
            if (directory.exists() && directory.isDirectory()) {
                String foundPath = searchForModelRecursive(directory, modelPath);
                if (foundPath != null) {
                    System.out.println("Found model at: " + foundPath);
                    return foundPath;
                }
            }
        }

        // If not found in file system, try to find in assets
        String fileName = modelPath.contains("/") ? modelPath.substring(modelPath.lastIndexOf("/") + 1) : modelPath;
        String[] assetPaths = {"public/models/" + fileName, "models/" + fileName};
        for (String assetPath : assetPaths) {
            try {
                getContext().getAssets().open(assetPath).close();
                System.out.println("Found model in assets: " + assetPath);
                return copyAssetToCache(assetPath);
            } catch (IOException e) {
                // Asset doesn't exist, continue
            }
        }

        // If not found, return the original path (will likely fail, but let the error propagate)
        System.out.println("Model not found in any search directory, returning original path: " + modelPath);
        return modelPath;
    }

    // Helper method to copy asset to cache directory
    private String copyAssetToCache(String assetPath) throws IOException {
        String fileName = assetPath.contains("/") ? assetPath.substring(assetPath.lastIndexOf("/") + 1) : assetPath;
        File cacheDir = new File(getContext().getCacheDir(), "models");
        if (!cacheDir.exists()) {
            cacheDir.mkdirs();
        }
        File cachedFile = new File(cacheDir, fileName);
        
        // Check if file already exists in cache
        if (cachedFile.exists()) {
            System.out.println("Model already cached at: " + cachedFile.getAbsolutePath());
            return cachedFile.getAbsolutePath();
        }
        
        // Copy asset to cache
        java.io.InputStream is = getContext().getAssets().open(assetPath);
        java.io.FileOutputStream fos = new java.io.FileOutputStream(cachedFile);
        byte[] buffer = new byte[8192];
        int read;
        while ((read = is.read(buffer)) != -1) {
            fos.write(buffer, 0, read);
        }
        fos.close();
        is.close();
        
        System.out.println("Copied asset to cache: " + cachedFile.getAbsolutePath());
        return cachedFile.getAbsolutePath();
    }

    // Helper method to recursively search for a model file
    private String searchForModelRecursive(File directory, String modelFileName) {
        File[] files = directory.listFiles();
        if (files != null) {
            System.out.println("Scanning directory: " + directory.getAbsolutePath());
            System.out.println("Found " + files.length + " files/directories");
            for (File file : files) {
                if (file.isDirectory()) {
                    // Recursively search subdirectories
                    System.out.println("Entering subdirectory: " + file.getName());
                    String foundPath = searchForModelRecursive(file, modelFileName);
                    if (foundPath != null) {
                        return foundPath;
                    }
                } else {
                    // Check if this file matches the model name
                    System.out.println("Checking file: " + file.getName());
                    if (file.getName().equals(modelFileName)) {
                        System.out.println("Found matching file: " + file.getAbsolutePath());
                        return file.getAbsolutePath();
                    }
                }
            }
        } else {
            System.out.println("No files found in directory: " + directory.getAbsolutePath());
        }
        return null;
    }

    @PluginMethod
    public void releaseContext(PluginCall call) {
        // Log the entire call object to see what's being received
        Log.d("LlamaMobilePlugin", "releaseContext called with call: " + call);
        
        // Log all parameters in the call
        Log.d("LlamaMobilePlugin", "releaseContext: All parameters: " + call.getData());
        
        // Retrieve contextHandle - handle both Integer and Long types
        long contextHandle = -1L;
        Object contextHandleObj = call.getData().opt("contextHandle");
        if (contextHandleObj != null) {
            if (contextHandleObj instanceof Integer) {
                contextHandle = ((Integer) contextHandleObj).longValue();
            } else if (contextHandleObj instanceof Long) {
                contextHandle = ((Long) contextHandleObj).longValue();
            } else if (contextHandleObj instanceof Number) {
                contextHandle = ((Number) contextHandleObj).longValue();
            }
        }
        Log.d("LlamaMobilePlugin", "releaseContext: Retrieved contextHandle: " + contextHandle);

        if (contextHandle == -1) {
            Log.d("LlamaMobilePlugin", "releaseContext: contextHandle is -1, rejecting call");
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = contextHandles.remove(finalContextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.releaseContext(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to release context: " + e.getMessage());
            }
        });
    }

    // Model info class for listModels method
    private static class ModelInfo {
        String name;
        String path;
        String source;

        ModelInfo(String name, String path, String source) {
            this.name = name;
            this.path = path;
            this.source = source;
        }
    }

    @PluginMethod
    public void listModels(PluginCall call) {
        executor.execute(() -> {
            try {
                List<ModelInfo> models = new ArrayList<>();

                // First, scan assets for bundled models
                try {
                    AssetManager assetManager = getContext().getAssets();
                    String[] assetsPaths = new String[]{"public/models", "models"};
                    for (String assetsPath : assetsPaths) {
                        try {
                            String[] assetFiles = assetManager.list(assetsPath);
                            if (assetFiles != null) {
                                for (String fileName : assetFiles) {
                                    if (fileName.toLowerCase().endsWith(".gguf") || 
                                        fileName.toLowerCase().endsWith(".safetensors") ||
                                        fileName.toLowerCase().endsWith(".bin")) {
                                        String assetPath = assetsPath + "/" + fileName;
                                        models.add(new ModelInfo(fileName, assetPath, "asset"));
                                    }
                                }
                            }
                        } catch (IOException e) {
                            // Directory doesn't exist, continue
                        }
                    }
                } catch (Exception e) {
                    // Failed to scan assets, continue with file system
                }

                // List of common directories to search for models
                List<String> modelDirectories = new ArrayList<>();

                // Get documents directory
                String documentsDir = getContext().getFilesDir().getAbsolutePath();
                modelDirectories.add(documentsDir);
                modelDirectories.add(documentsDir + File.separator + "models");
                modelDirectories.add(documentsDir + File.separator + "Downloads");
                modelDirectories.add(documentsDir + File.separator + "Downloads" + File.separator + "models");

                // Add app's external files directory
                String externalFilesDir = getContext().getExternalFilesDir(null).getAbsolutePath();
                modelDirectories.add(externalFilesDir);
                modelDirectories.add(externalFilesDir + File.separator + "models");
                modelDirectories.add(externalFilesDir + File.separator + "Downloads");
                modelDirectories.add(externalFilesDir + File.separator + "Downloads" + File.separator + "models");

                // Add legacy LlamaMobile/models directory
                String legacyExternalDir = getContext().getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS).getAbsolutePath() + File.separator + "LlamaMobile" + File.separator + "models";
                modelDirectories.add(legacyExternalDir);

                // Model file extensions to look for
                List<String> modelExtensions = List.of("gguf", "safetensors", "bin");

                // Scan directories for model files
                for (String directory : modelDirectories) {
                    File dir = new File(directory);
                    if (dir.exists() && dir.isDirectory()) {
                        scanDirectoryForModels(dir, modelExtensions, models);
                    }
                }

                // Remove duplicates by file name, prioritizing assets first
                Map<String, ModelInfo> uniqueModelsMap = new HashMap<>();
                for (ModelInfo model : models) {
                    ModelInfo existing = uniqueModelsMap.get(model.name);
                    if (existing == null || (model.source.equals("asset") && !existing.source.equals("asset"))) {
                        uniqueModelsMap.put(model.name, model);
                    }
                }
                List<ModelInfo> uniqueModels = new ArrayList<>(uniqueModelsMap.values());

                // Convert to the expected format
                List<Map<String, String>> modelArray = new ArrayList<>();
                for (ModelInfo model : uniqueModels) {
                    Map<String, String> modelMap = new HashMap<>();
                    modelMap.put("name", model.name);
                    modelMap.put("path", model.path);
                    modelMap.put("source", model.source);
                    modelArray.add(modelMap);
                }

                JSObject ret = new JSObject();
                ret.put("models", modelArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to list models: " + e.getMessage());
            }
        });
    }

    // Helper method to scan a directory for model files
    private void scanDirectoryForModels(File directory, List<String> modelExtensions, List<ModelInfo> models) {
        File[] files = directory.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isDirectory()) {
                    // Recursively scan subdirectories
                    scanDirectoryForModels(file, modelExtensions, models);
                } else {
                    // Check if file has a model extension
                    String fileName = file.getName().toLowerCase();
                    for (String ext : modelExtensions) {
                        if (fileName.endsWith("." + ext)) {
                            models.add(new ModelInfo(file.getName(), file.getAbsolutePath(), "file"));
                            break;
                        }
                    }
                }
            }
        }
    }

    // MARK: - Completion

    @PluginMethod
    public void generateCompletion(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        JSObject params = call.getObject("params");
        String prompt = params != null ? params.optString("prompt", null) : null;
        int maxTokens = params != null ? params.optInt("maxTokens", 128) : 128;
        double temperature = params != null ? params.optDouble("temperature", 0.8) : 0.8;

        if (contextHandle == -1 || prompt == null) {
            call.reject("contextHandle and params.prompt are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams(
                    prompt, (float) temperature, maxTokens
                );
                LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(
                    nativeContextHandle, completionParams
                );

                JSObject ret = new JSObject();
                ret.put("text", result.getText());
                ret.put("tokensGenerated", result.getTokensGenerated());
                ret.put("tokensEvaluated", result.getTokensEvaluated());
                ret.put("truncated", result.isTruncated());
                ret.put("stoppedEos", result.isStoppedEos());
                ret.put("stoppedWord", result.isStoppedWord());
                ret.put("stoppedLimit", result.isStoppedLimit());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate completion: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateOpenAICompletion(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String openAIJSON = call.getString("openAIJSON");

        if (contextHandle == -1 || openAIJSON == null) {
            call.reject("contextHandle and openAIJSON are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.CompletionResult result = LlamaMobile.generateOpenAICompletion(
                    nativeContextHandle, openAIJSON
                );

                JSObject ret = new JSObject();
                ret.put("text", result.getText());
                ret.put("tokensGenerated", result.getTokensGenerated());
                ret.put("tokensEvaluated", result.getTokensEvaluated());
                ret.put("truncated", result.isTruncated());
                ret.put("stoppedEos", result.isStoppedEos());
                ret.put("stoppedWord", result.isStoppedWord());
                ret.put("stoppedLimit", result.isStoppedLimit());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate OpenAI completion: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void stopCompletion(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.stopCompletion(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to stop completion: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void loadGrammar(PluginCall call) {
        String filePath = call.getString("filePath");

        if (filePath == null) {
            call.reject("filePath is required");
            return;
        }

        executor.execute(() -> {
            try {
                String grammar = LlamaMobile.loadGrammar(filePath);
                JSObject ret = new JSObject();
                ret.put("grammar", grammar);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to load grammar: " + e.getMessage());
            }
        });
    }

    // MARK: - TTS

    @PluginMethod
    public void initVocoder(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String vocoderModelPath = call.getString("vocoderModelPath");

        if (contextHandle == -1 || vocoderModelPath == null) {
            call.reject("contextHandle and vocoderModelPath are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean success = LlamaMobile.initVocoder(
                    nativeContextHandle, vocoderModelPath
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to initialize vocoder: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void releaseVocoder(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.releaseVocoder(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to release vocoder: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void isVocoderEnabled(PluginCall call) {
        // Log the entire call object to see what's being received
        Log.d("LlamaMobilePlugin", "isVocoderEnabled called with call: " + call);
        
        // Log all parameters in the call
        Log.d("LlamaMobilePlugin", "isVocoderEnabled: All parameters: " + call.getData());
        
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        Log.d("LlamaMobilePlugin", "isVocoderEnabled: Retrieved contextHandle: " + contextHandle);

        if (contextHandle == -1) {
            Log.d("LlamaMobilePlugin", "isVocoderEnabled: contextHandle is -1, rejecting call");
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean enabled = LlamaMobile.isVocoderEnabled(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("enabled", enabled);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check vocoder status: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getTTSType(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.TTSModelType type = LlamaMobile.getTTSType(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("type", type.name());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get TTS type: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateSpeechAsync(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");
        String speakerJson = call.getString("speakerJson", "{\"speaker\": \"default\"}");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                Result<SpeechResult, TTSError> result = LlamaMobile.generateSpeech(
                    nativeContextHandle, text, optionsBuilder.build()
                );

                if (result.isSuccess()) {
                    SpeechResult speechResult = result.getValue();
                    
                    // Generate temporary file path
                    String tempFileName = "temp_audio_" + System.currentTimeMillis() + ".wav";
                    
                    // Save audio to temporary file
                    boolean saveSuccess = saveAudioToWavInternal(
                        nativeContextHandle, tempFileName, 
                        speechResult.getAudioSamples(), speechResult.getSampleRate()
                    );

                    if (saveSuccess) {
                        // Resolve with the file path
                        String tempFilePath = getContext().getFilesDir().getAbsolutePath() + "/" + tempFileName;
                        
                        JSObject ret = new JSObject();
                        ret.put("audioPath", tempFilePath);
                        ret.put("sampleRate", speechResult.getSampleRate());
                        ret.put("duration", speechResult.getDuration());
                        ret.put("methodUsed", speechResult.getMethodUsed().toString());
                        call.resolve(ret);
                    } else {
                        call.reject("Failed to save audio to file");
                    }
                } else {
                    TTSError error = result.getError();
                    call.reject("Failed to generate speech: " + error.getMessage());
                }
            } catch (Exception e) {
                call.reject("Failed to generate speech: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateSpeech(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                Result<SpeechResult, TTSError> result = LlamaMobile.generateSpeech(
                    nativeContextHandle, text, optionsBuilder.build()
                );

                if (result.isSuccess()) {
                    SpeechResult speechResult = result.getValue();
                    
                    // Generate temporary file path
                    String tempFileName = "temp_audio_" + System.currentTimeMillis() + ".wav";
                    
                    // Save audio to temporary file
                    boolean saveSuccess = saveAudioToWavInternal(
                        nativeContextHandle, tempFileName, 
                        speechResult.getAudioSamples(), speechResult.getSampleRate()
                    );

                    if (saveSuccess) {
                        // Resolve with the file path
                        String tempFilePath = getContext().getFilesDir().getAbsolutePath() + "/" + tempFileName;
                        
                        JSObject ret = new JSObject();
                        ret.put("audioPath", tempFilePath);
                        ret.put("sampleRate", speechResult.getSampleRate());
                        ret.put("duration", speechResult.getDuration());
                        ret.put("methodUsed", speechResult.getMethodUsed().toString());
                        call.resolve(ret);
                    } else {
                        call.reject("Failed to save audio to file");
                    }
                } else {
                    TTSError error = result.getError();
                    call.reject("Failed to generate speech sync: " + error.getMessage());
                }
            } catch (Exception e) {
                call.reject("Failed to generate speech sync: " + e.getMessage());
            }
        });
    }
    
    // Internal method to save audio to WAV using existing logic
    private boolean saveAudioToWavInternal(long nativeContextHandle, String filePath, short[] audioData, int sampleRate) {
        try {
            // Handle relative file paths by using app's files directory
            String finalFilePath = filePath;
            if (!filePath.startsWith("/")) {
                // Use app's internal files directory for relative paths
                java.io.File filesDir = getContext().getFilesDir();
                finalFilePath = filesDir.getAbsolutePath() + "/" + filePath;
            }

            // Convert short[] to float[] for saveAudioToWav
            float[] floatAudioData = new float[audioData.length];
            for (int i = 0; i < audioData.length; i++) {
                // Convert 16-bit short to float in range [-1, 1]
                floatAudioData[i] = audioData[i] / (float) Short.MAX_VALUE;
            }

            return LlamaMobile.saveAudioToWav(
                nativeContextHandle, finalFilePath, floatAudioData, sampleRate
            );
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @PluginMethod
    public void generateSpeechStreamForLongTextAsync(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.generateSpeechStreamForLongTextAsync(
                    nativeContextHandle, text, optionsBuilder.build(),
                    new ProgressCallback() {
                        @Override
                        public void onProgress(float progress) {
                            notifyListeners("progress", new JSObject().put("progress", progress));
                        }
                    },
                    new AudioChunkCallback() {
                        @Override
                        public void onAudioChunk(short[] audioChunk) {
                            JSArray audioArray = new JSArray();
                            for (short sample : audioChunk) {
                                audioArray.put(sample);
                            }
                            notifyListeners("audioChunk", new JSObject().put("audio", audioArray));
                        }
                    },
                    new LlamaMobile.SpeechMetadataCallback() {
                        @Override
                        public void onResult(Result<SpeechMetadata, TTSError> result) {
                            if (result.isSuccess()) {
                                SpeechMetadata metadata = result.getValue();
                                JSObject ret = new JSObject();
                                ret.put("sampleRate", metadata.getSampleRate());
                                ret.put("duration", metadata.getDuration());
                                ret.put("methodUsed", metadata.getMethodUsed().toString());
                                call.resolve(ret);
                            } else {
                                TTSError error = result.getError();
                                call.reject("Failed to generate speech stream: " + error.getMessage());
                            }
                        }
                    }
                );
            } catch (Exception e) {
                call.reject("Failed to generate speech stream: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void saveAudioToWav(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String filePath = call.getString("filePath");
        JSArray audioDataArray = call.getArray("audioData");

        if (contextHandle == -1 || filePath == null || audioDataArray == null) {
            call.reject("contextHandle, filePath, and audioData are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                // Handle relative file paths by using app's files directory
                String finalFilePath = filePath;
                if (!filePath.startsWith("/")) {
                    // Use app's internal files directory for relative paths
                    java.io.File filesDir = getContext().getFilesDir();
                    finalFilePath = filesDir.getAbsolutePath() + "/" + filePath;
                }

                float[] audioData = new float[(int) audioDataArray.length()];
                for (int i = 0; i < audioDataArray.length(); i++) {
                    audioData[i] = (float) audioDataArray.getDouble(i);
                }

                boolean success = LlamaMobile.saveAudioToWav(
                    nativeContextHandle, finalFilePath, audioData, sampleRate
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to save audio to WAV: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void playAudio(PluginCall call) {
        JSArray audioDataArray = call.getArray("audioData");
        int sampleRate = call.getInt("sampleRate", 24000);

        if (audioDataArray == null) {
            call.reject("audioData is required");
            return;
        }

        executor.execute(() -> {
            try {
                // Convert JSArray to float array
                float[] audioData = new float[(int) audioDataArray.length()];
                for (int i = 0; i < audioDataArray.length(); i++) {
                    audioData[i] = (float) audioDataArray.getDouble(i);
                }

                // Convert float samples to 16-bit PCM
                short[] pcmData = new short[audioData.length];
                for (int i = 0; i < audioData.length; i++) {
                    // Clamp values to [-1, 1] and convert to 16-bit PCM
                    float sample = Math.max(-1.0f, Math.min(1.0f, audioData[i]));
                    pcmData[i] = (short) (sample * Short.MAX_VALUE);
                }

                // Create AudioTrack
                int channelConfig = android.media.AudioFormat.CHANNEL_OUT_MONO;
                int audioFormat = android.media.AudioFormat.ENCODING_PCM_16BIT;
                int bufferSize = android.media.AudioTrack.getMinBufferSize(
                    sampleRate, channelConfig, audioFormat
                );

                android.media.AudioTrack audioTrack = new android.media.AudioTrack(
                    android.media.AudioManager.STREAM_MUSIC,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    bufferSize,
                    android.media.AudioTrack.MODE_STATIC
                );

                // Write audio data
                audioTrack.write(pcmData, 0, pcmData.length);

                // Play audio
                audioTrack.play();

                // Wait for playback to complete
                try {
                    Thread.sleep((long) (pcmData.length * 1000.0 / sampleRate) + 100);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }

                // Release resources
                audioTrack.release();

                JSObject ret = new JSObject();
                ret.put("success", true);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to play audio: " + e.getMessage());
            }
        });
    }
    
    @PluginMethod
    public void playAudioFromFile(PluginCall call) {
        String filePath = call.getString("filePath");

        if (filePath == null) {
            call.reject("filePath is required");
            return;
        }

        executor.execute(() -> {
            try {
                // Handle relative file paths by using app's files directory
                String finalFilePath = filePath;
                if (!filePath.startsWith("/")) {
                    // Use app's internal files directory for relative paths
                    java.io.File filesDir = getContext().getFilesDir();
                    finalFilePath = filesDir.getAbsolutePath() + "/" + filePath;
                }

                // Create MediaPlayer
                android.media.MediaPlayer mediaPlayer = new android.media.MediaPlayer();
                mediaPlayer.setDataSource(finalFilePath);
                mediaPlayer.prepare();
                mediaPlayer.start();

                // Wait for playback to complete
                while (mediaPlayer.isPlaying()) {
                    Thread.sleep(100);
                }

                // Release resources
                mediaPlayer.release();

                JSObject ret = new JSObject();
                ret.put("success", true);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to play audio from file: " + e.getMessage());
            }
        });
    }

    // MARK: - Multimodal

    @PluginMethod
    public void initMultimodal(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String mmprojPath = call.getString("mmprojPath");
        boolean useGpu = call.getBoolean("useGpu", true);

        if (contextHandle == -1 || mmprojPath == null) {
            call.reject("contextHandle and mmprojPath are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean success = LlamaMobile.initMultimodal(
                    nativeContextHandle, mmprojPath, useGpu
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to initialize multimodal: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void releaseMultimodal(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.releaseMultimodal(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to release multimodal: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void isMultimodalEnabled(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean enabled = LlamaMobile.isMultimodalEnabled(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("enabled", enabled);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check multimodal status: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void supportsVision(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean supported = LlamaMobile.supportsVision(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("supported", supported);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check vision support: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void supportsAudio(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean supported = LlamaMobile.supportsAudio(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("supported", supported);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check audio support: " + e.getMessage());
            }
        });
    }

    // MARK: - LoRA

    @PluginMethod
    public void applyLoraAdapters(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        JSArray adaptersArray = call.getArray("adapters");

        if (contextHandle == -1 || adaptersArray == null) {
            call.reject("contextHandle and adapters are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.LoraAdapter[] adapters = new LlamaMobile.LoraAdapter[(int) adaptersArray.length()];
                for (int i = 0; i < adaptersArray.length(); i++) {
                    JSONObject adapterObj = adaptersArray.getJSONObject(i);
                    String path = adapterObj.getString("path");
                    // Resolve LoRA adapter path like we do for model paths
                    String resolvedPath = resolveModelPath(path);
                    double scale = adapterObj.has("scale") ? adapterObj.getDouble("scale") : 1.0;
                    adapters[i] = new LlamaMobile.LoraAdapter(resolvedPath, (float) scale);
                }

                boolean success = LlamaMobile.applyLoraAdapters(
                    nativeContextHandle, adapters
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to apply LoRA adapters: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void removeLoraAdapters(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.removeLoraAdapters(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to remove LoRA adapters: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getLoadedLoraAdapters(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.LoraAdapter[] adapters = LlamaMobile.getLoadedLoraAdapters(
                    nativeContextHandle
                );

                JSArray adaptersArray = new JSArray();
                for (LlamaMobile.LoraAdapter adapter : adapters) {
                    JSObject adapterObj = new JSObject();
                    adapterObj.put("path", adapter.getPath());
                    adapterObj.put("scale", adapter.getScale());
                    adaptersArray.put(adapterObj);
                }

                JSObject ret = new JSObject();
                ret.put("adapters", adaptersArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get loaded LoRA adapters: " + e.getMessage());
            }
        });
    }

    // MARK: - Conversation

    @PluginMethod
    public void generateResponse(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        String userMessage = call.getString("userMessage");
        int maxTokens = call.getInt("maxTokens", 128);

        if (contextHandle == -1 || userMessage == null) {
            call.reject("contextHandle and userMessage are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.ConversationResult result = LlamaMobile.generateResponse(
                    nativeContextHandle, userMessage, maxTokens,
                    new LlamaMobile.TokenCallback() {
                        @Override
                        public boolean onToken(String token) {
                            notifyListeners("token", new JSObject().put("token", token));
                            return true;
                        }
                    }
                );

                JSObject ret = new JSObject();
                ret.put("text", result.getText());
                ret.put("tokensGenerated", result.getTokensGenerated());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate response: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void clearConversation(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.clearConversation(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to clear conversation: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void isConversationActive(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean active = LlamaMobile.isConversationActive(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("active", active);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check conversation status: " + e.getMessage());
            }
        });
    }

    // MARK: - Embeddings

    @PluginMethod
    public void generateEmbeddings(PluginCall call) {
        // Log the entire call object
        Log.d("LlamaMobilePlugin", "generateEmbeddings called with call: " + call);
        Log.d("LlamaMobilePlugin", "generateEmbeddings: All parameters: " + call.getData());
        
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        Log.d("LlamaMobilePlugin", "generateEmbeddings: Final contextHandle: " + contextHandle);
        
        String text = call.getString("text");
        Log.d("LlamaMobilePlugin", "generateEmbeddings: Retrieved text: " + text);

        if (contextHandle == -1 || text == null) {
            Log.d("LlamaMobilePlugin", "generateEmbeddings: Rejecting call - contextHandle: " + contextHandle + ", text: " + text);
            call.reject("contextHandle and text are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                float[] embedding = LlamaMobile.generateEmbeddings(
                    nativeContextHandle, text
                );

                JSArray embeddingArray = new JSArray();
                for (float value : embedding) {
                    embeddingArray.put(value);
                }

                JSObject ret = new JSObject();
                ret.put("embedding", embeddingArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate embeddings: " + e.getMessage());
            }
        });
    }

    // MARK: - Tokenization

    @PluginMethod
    public void tokenize(PluginCall call) {
        // Retrieve contextHandle - handle both Integer and Long types
        long contextHandle = -1L;
        Object contextHandleObj = call.getData().opt("contextHandle");
        if (contextHandleObj != null) {
            if (contextHandleObj instanceof Integer) {
                contextHandle = ((Integer) contextHandleObj).longValue();
            } else if (contextHandleObj instanceof Long) {
                contextHandle = ((Long) contextHandleObj).longValue();
            } else if (contextHandleObj instanceof Number) {
                contextHandle = ((Number) contextHandleObj).longValue();
            }
        }
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int[] tokens = LlamaMobile.tokenize(nativeContextHandle, text);

                JSArray tokensArray = new JSArray();
                for (int token : tokens) {
                    tokensArray.put(token);
                }

                JSObject ret = new JSObject();
                ret.put("tokens", tokensArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to tokenize: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void detokenize(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);
        JSArray tokensArray = call.getArray("tokens");

        if (contextHandle == -1 || tokensArray == null) {
            call.reject("contextHandle and tokens are required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int[] tokens = new int[(int) tokensArray.length()];
                for (int i = 0; i < tokensArray.length(); i++) {
                    tokens[i] = tokensArray.getInt(i);
                }

                String text = LlamaMobile.detokenize(nativeContextHandle, tokens);

                JSObject ret = new JSObject();
                ret.put("text", text);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to detokenize: " + e.getMessage());
            }
        });
    }

    // MARK: - Model Info

    @PluginMethod
    public void getContextWindowSize(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int size = LlamaMobile.getContextWindowSize(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("size", size);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get context window size: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getEmbeddingDimension(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int dimension = LlamaMobile.getEmbeddingDimension(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("dimension", dimension);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get embedding dimension: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getModelDescription(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                String description = LlamaMobile.getModelDescription(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("description", description);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get model description: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getModelSize(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                long size = LlamaMobile.getModelSize(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("size", size);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get model size: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getModelParametersCount(PluginCall call) {
        // Retrieve contextHandle using helper function
        long contextHandle = getContextHandle(call);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        final long finalContextHandle = contextHandle;
        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(finalContextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                long count = LlamaMobile.getModelParametersCount(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("count", count);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get model parameters count: " + e.getMessage());
            }
        });
    }

    // MARK: - Download

    @PluginMethod
    public void downloadModel(PluginCall call) {
        String url = call.getString("url");
        String localPath = call.getString("localPath");

        if (url == null || localPath == null) {
            call.reject("url and localPath are required");
            return;
        }

        executor.execute(() -> {
            try {
                LlamaMobile.DownloadParams.Builder paramsBuilder = new LlamaMobile.DownloadParams.Builder(url, "", localPath);
                LlamaMobile.DownloadParams params = paramsBuilder.build();
                LlamaMobile.DownloadResult result = LlamaMobile.downloadModel(params, (progress, status, downloadedBytes, totalBytes) -> {
                    JSObject progressData = new JSObject();
                    progressData.put("progress", progress);
                    notifyListeners("downloadProgress", progressData);
                });

                JSObject ret = new JSObject();
                ret.put("success", result.isSuccess());
                ret.put("localPath", result.getLocalPath());
                ret.put("errorMessage", result.getErrorMessage());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to download model: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void downloadHfFile(PluginCall call) {
        String repoId = call.getString("repoId");
        String filename = call.getString("filename");
        String localPath = call.getString("localPath");
        String bearerToken = call.getString("bearerToken");
        boolean offline = call.getBoolean("offline", false);

        if (repoId == null || filename == null || localPath == null) {
            call.reject("repoId, filename, and localPath are required");
            return;
        }

        executor.execute(() -> {
            try {
                LlamaMobile.DownloadResult result = LlamaMobile.downloadHfFile(
                    repoId, filename, localPath, bearerToken, offline, (progress, status, downloadedBytes, totalBytes) -> {
                        JSObject progressData = new JSObject();
                        progressData.put("progress", progress);
                        notifyListeners("downloadProgress", progressData);
                    }
                );

                JSObject ret = new JSObject();
                ret.put("success", result.isSuccess());
                ret.put("localPath", result.getLocalPath());
                ret.put("errorMessage", result.getErrorMessage());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to download HuggingFace file: " + e.getMessage());
            }
        });
    }

    // MARK: - Chat

    @PluginMethod
    public void setChatTemplate(PluginCall call) {
        call.resolve();
    }

    @PluginMethod
    public void getModelChatTemplate(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("template", "");
        call.resolve(ret);
    }

    @PluginMethod
    public void formatChatMessages(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("formattedPrompt", "");
        call.resolve(ret);
    }
}
