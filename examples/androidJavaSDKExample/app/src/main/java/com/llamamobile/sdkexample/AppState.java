package com.llamamobile.sdkexample;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.llamamobile.LlamaMobile;
import com.llamamobile.sdk.LlamaMobileSdk;
import com.llamamobile.LlamaMobile.CacheType;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class AppState {
    private static final String TAG = "AppState";
    private static final String MODELS_ASSET_DIR = "models";
    private static final String EXTERNAL_MODELS_DIR = "LlamaMobile/models";
    private static final String GRAMMARS_ASSET_DIR = "grammars";
    private static final String JSON_GRAMMAR_FILE = "json.gbnf";

    private boolean isModelLoaded = false;
    private String modelPath = "";
    private List<Map.Entry<String, String>> availableModels = new ArrayList<>();
    private String errorMessage = null;

    // Feature flags
    private boolean enableChatting = true;
    private boolean enableEmbedding = false;
    private boolean enableMultimodal = false;
    private boolean enableTTS = false;

    // Chat configuration
    private String systemPrompt = "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone.";

    // Model configuration
    private int nGpuLayers = 4;
    private int nThreads = 4;
    private int nCtx = 2048;

    // JSON grammar content
    private String jsonGrammar = null;

    // LlamaMobile SDK instance
    private final LlamaMobileSdk llamaMobileSdk;

    // Handler for UI updates
    private final Handler uiHandler = new Handler(Looper.getMainLooper());

    private final Context context;

    public AppState(Context context) {
        this.context = context;
        this.llamaMobileSdk = new LlamaMobileSdk(context);
    }

    public void init() {
        // Extract models from assets to local storage
        extractModelsFromAssets();
        
        // Extract and load JSON grammar
        jsonGrammar = loadGrammarFromAssets(JSON_GRAMMAR_FILE);
    }

    private void extractModelsFromAssets() {
        AssetManager assetManager = context.getAssets();
        File localModelsDir = new File(context.getFilesDir(), MODELS_ASSET_DIR);
        List<Map.Entry<String, String>> models = new ArrayList<>();

        // Create local models directory if it doesn't exist
        if (!localModelsDir.exists()) {
            localModelsDir.mkdirs();
        }

        try {
            // 1. Extract models from assets/models directory
            String[] assetFiles = assetManager.list(MODELS_ASSET_DIR);
            
            if (assetFiles != null && assetFiles.length > 0) {
                for (String fileName : assetFiles) {
                    if (fileName.endsWith(".gguf")) {
                        File localFile = new File(localModelsDir, fileName);
                        
                        // Extract file if it doesn't exist locally
                        if (!localFile.exists() || localFile.length() == 0L) {
                            extractAssetFile(assetManager, MODELS_ASSET_DIR + "/" + fileName, localFile);
                        }
                        
                        models.add(new Pair<>(fileName, localFile.getAbsolutePath()));
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error extracting models from assets: " + e.getMessage());
        }

        try {
            // 2. Scan external storage for models
            File externalDir = new File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), EXTERNAL_MODELS_DIR);
            if (externalDir.exists() && externalDir.isDirectory()) {
                File[] files = externalDir.listFiles();
                if (files != null) {
                    for (File file : files) {
                        if (file.isFile() && file.getName().endsWith(".gguf")) {
                            models.add(new Pair<>(file.getName(), file.getAbsolutePath()));
                        }
                    }
                }
            } else {
                // Create external models directory if it doesn't exist
                externalDir.mkdirs();
                Log.i(TAG, "Created external models directory: " + externalDir.getAbsolutePath());
            }
        } catch (Exception e) {
            Log.e(TAG, "Error scanning external storage for models: " + e.getMessage());
        }

        // Remove duplicates by file name (keep the first occurrence)
        Map<String, String> uniqueModels = new HashMap<>();
        for (Map.Entry<String, String> pair : models) {
            if (!uniqueModels.containsKey(pair.getKey())) {
                uniqueModels.put(pair.getKey(), pair.getValue());
            }
        }
        availableModels = new ArrayList<>(uniqueModels.entrySet());

        // Set default model path if any models are found
        if (!availableModels.isEmpty()) {
            // Check if current model path is still valid
            boolean currentModelValid = false;
            for (Map.Entry<String, String> pair : availableModels) {
                if (pair.getValue().equals(modelPath)) {
                    currentModelValid = true;
                    break;
                }
            }
            if (!currentModelValid) {
                modelPath = availableModels.get(0).getValue();
            }
        }
    }

    private String loadGrammarFromAssets(String grammarFileName) {
        AssetManager assetManager = context.getAssets();
        File localGrammarDir = new File(context.getFilesDir(), GRAMMARS_ASSET_DIR);

        // Create local grammar directory if it doesn't exist
        if (!localGrammarDir.exists()) {
            localGrammarDir.mkdirs();
        }

        try {
            File localFile = new File(localGrammarDir, grammarFileName);
            
            // Extract file if it doesn't exist locally
            if (!localFile.exists() || localFile.length() == 0L) {
                extractAssetFile(assetManager, GRAMMARS_ASSET_DIR + "/" + grammarFileName, localFile);
            }
            
            // Return grammar content
            try (FileInputStream fis = new FileInputStream(localFile)) {
                byte[] buffer = new byte[(int) localFile.length()];
                fis.read(buffer);
                return new String(buffer);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error loading grammar from assets: " + e.getMessage());
        }
        
        return null;
    }

    private void extractAssetFile(AssetManager assetManager, String assetPath, File localFile) throws IOException {
        try (InputStream inputStream = assetManager.open(assetPath);
             OutputStream outputStream = new FileOutputStream(localFile)) {
            byte[] buffer = new byte[4096];
            int read;
            while ((read = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error extracting asset file " + assetPath + ": " + e.getMessage());
            // Clean up if extraction fails
            if (localFile.exists()) {
                localFile.delete();
            }
            throw e;
        }
    }

    public void loadModel(final LoadModelCallback callback) {
        if (modelPath.isEmpty()) {
            errorMessage = "Please select a valid model";
            callback.onResult(false);
            return;
        }

        errorMessage = null;

        LlamaMobileSdk.ModelConfig config = new LlamaMobileSdk.ModelConfig.Builder(modelPath)
                .contextSize(nCtx)
                .chatTemplate(systemPrompt)
                .cacheType(CacheType.MEMORY)
                .build();

        llamaMobileSdk.loadModelAsync(config, new LlamaMobileSdk.ResultCallback<Boolean>() {
            @Override
            public void onSuccess(Boolean result) {
                uiHandler.post(() -> {
                    isModelLoaded = result;
                    errorMessage = null;
                    callback.onResult(result);
                });
            }

            @Override
            public void onError(Exception e) {
                uiHandler.post(() -> {
                    isModelLoaded = false;
                    errorMessage = e.getLocalizedMessage() != null ? e.getLocalizedMessage() : "Failed to load model";
                    callback.onResult(false);
                });
            }
        });
    }

    public void unloadModel() {
        llamaMobileSdk.release();
        isModelLoaded = false;
        errorMessage = null;
    }

    // Getters and setters
    public boolean isModelLoaded() {
        return isModelLoaded;
    }

    public String getModelPath() {
        return modelPath;
    }

    public void setModelPath(String modelPath) {
        this.modelPath = modelPath;
    }

    public List<Map.Entry<String, String>> getAvailableModels() {
        return availableModels;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public boolean isEnableChatting() {
        return enableChatting;
    }

    public boolean isEnableEmbedding() {
        return enableEmbedding;
    }

    public boolean isEnableMultimodal() {
        return enableMultimodal;
    }

    public boolean isEnableTTS() {
        return enableTTS;
    }

    public String getSystemPrompt() {
        return systemPrompt;
    }

    public void setSystemPrompt(String systemPrompt) {
        this.systemPrompt = systemPrompt;
    }

    public int getNGpuLayers() {
        return nGpuLayers;
    }

    public void setNGpuLayers(int nGpuLayers) {
        this.nGpuLayers = nGpuLayers;
    }

    public int getNThreads() {
        return nThreads;
    }

    public void setNThreads(int nThreads) {
        this.nThreads = nThreads;
    }

    public int getNCtx() {
        return nCtx;
    }

    public void setNCtx(int nCtx) {
        this.nCtx = nCtx;
    }

    public String getJsonGrammar() {
        return jsonGrammar;
    }

    public LlamaMobileSdk getLlamaMobileSdk() {
        return llamaMobileSdk;
    }

    // Callback interface for loadModel
    public interface LoadModelCallback {
        void onResult(boolean success);
    }

    // Helper class to replace Kotlin Pair
    private static class Pair<K, V> implements Map.Entry<K, V> {
        private final K key;
        private final V value;

        public Pair(K key, V value) {
            this.key = key;
            this.value = value;
        }

        @Override
        public K getKey() {
            return key;
        }

        @Override
        public V getValue() {
            return value;
        }

        @Override
        public V setValue(V value) {
            throw new UnsupportedOperationException();
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            Pair<?, ?> pair = (Pair<?, ?>) o;
            return Objects.equals(key, pair.key) && Objects.equals(value, pair.value);
        }

        @Override
        public int hashCode() {
            return Objects.hash(key, value);
        }
    }

    // Helper class for Map.Entry
    private static abstract class AbstractMap {
        public static <K, V> Map.Entry<K, V> simpleEntry(K key, V value) {
            return new Pair<>(key, value);
        }
    }
}