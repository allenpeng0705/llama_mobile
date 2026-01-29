package com.llamamobile.capacitorplugin;

import com.getcapacitor.Logger;
import com.llamamobile.LlamaMobile;

public class LlamaMobileCapacitorPlugin {
    // MARK: - Initialization
    
    public long initContext(String modelPath, int nCtx, int nGpuLayers, int nThreads) {
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath, nCtx);
            long context = LlamaMobile.initContext(params);
            return context;
        } catch (Exception e) {
            Logger.error("initContext", e);
            return -1;
        }
    }
    
    public void releaseContext(long contextHandle) {
        try {
            LlamaMobile.releaseContext(contextHandle);
        } catch (Exception e) {
            Logger.error("releaseContext", e);
        }
    }
    
    // MARK: - Completion
    
    public LlamaMobile.CompletionResult generateCompletion(long contextHandle, String prompt, int maxTokens, double temperature) {
        try {
            return LlamaMobile.generateCompletion(contextHandle, prompt, maxTokens, (float) temperature);
        } catch (Exception e) {
            Logger.error("generateCompletion", e);
            return new LlamaMobile.CompletionResult("", 0, 0, false, false, false, false, "");
        }
    }
    
    public void stopCompletion(long contextHandle) {
        try {
            LlamaMobile.stopCompletion(contextHandle);
        } catch (Exception e) {
            Logger.error("stopCompletion", e);
        }
    }
    
    // MARK: - TTS
    
    public boolean initVocoder(long contextHandle, String vocoderModelPath) {
        try {
            return LlamaMobile.initVocoder(contextHandle, vocoderModelPath);
        } catch (Exception e) {
            Logger.error("initVocoder", e);
            return false;
        }
    }
    
    public void releaseVocoder(long contextHandle) {
        try {
            LlamaMobile.releaseVocoder(contextHandle);
        } catch (Exception e) {
            Logger.error("releaseVocoder", e);
        }
    }
    
    public boolean isVocoderEnabled(long contextHandle) {
        try {
            return LlamaMobile.isVocoderEnabled(contextHandle);
        } catch (Exception e) {
            Logger.error("isVocoderEnabled", e);
            return false;
        }
    }
    
    public String getTTSType(long contextHandle) {
        try {
            return LlamaMobile.getTTSType(contextHandle).name();
        } catch (Exception e) {
            Logger.error("getTTSType", e);
            return "NONE";
        }
    }
    
    // MARK: - Multimodal
    
    public boolean initMultimodal(long contextHandle, String mmprojPath, boolean useGpu) {
        try {
            return LlamaMobile.initMultimodal(contextHandle, mmprojPath, useGpu);
        } catch (Exception e) {
            Logger.error("initMultimodal", e);
            return false;
        }
    }
    
    public void releaseMultimodal(long contextHandle) {
        try {
            LlamaMobile.releaseMultimodal(contextHandle);
        } catch (Exception e) {
            Logger.error("releaseMultimodal", e);
        }
    }
    
    public boolean isMultimodalEnabled(long contextHandle) {
        try {
            return LlamaMobile.isMultimodalEnabled(contextHandle);
        } catch (Exception e) {
            Logger.error("isMultimodalEnabled", e);
            return false;
        }
    }
    
    public boolean supportsVision(long contextHandle) {
        try {
            return LlamaMobile.supportsVision(contextHandle);
        } catch (Exception e) {
            Logger.error("supportsVision", e);
            return false;
        }
    }
    
    public boolean supportsAudio(long contextHandle) {
        try {
            return LlamaMobile.supportsAudio(contextHandle);
        } catch (Exception e) {
            Logger.error("supportsAudio", e);
            return false;
        }
    }
    
    // MARK: - LoRA
    
    public boolean applyLoraAdapters(long contextHandle, Object[] adapters) {
        try {
            java.util.List<LlamaMobile.LoraAdapter> loraAdapters = new java.util.ArrayList<>();
            for (Object adapterObj : adapters) {
                if (adapterObj instanceof java.util.Map) {
                    java.util.Map<?, ?> adapter = (java.util.Map<?, ?>) adapterObj;
                    String path = (String) adapter.get("path");
                    Double scale = (Double) adapter.get("scale");
                    if (path != null) {
                        float loraScale = scale != null ? scale.floatValue() : 1.0f;
                        loraAdapters.add(new LlamaMobile.LoraAdapter(path, loraScale));
                    }
                }
            }
            if (!loraAdapters.isEmpty()) {
                return LlamaMobile.applyLoraAdapters(contextHandle, loraAdapters.toArray(new LlamaMobile.LoraAdapter[0]));
            }
            return true;
        } catch (Exception e) {
            Logger.error("applyLoraAdapters", e);
            return false;
        }
    }
    
    public void removeLoraAdapters(long contextHandle) {
        try {
            LlamaMobile.removeLoraAdapters(contextHandle);
        } catch (Exception e) {
            Logger.error("removeLoraAdapters", e);
        }
    }
    
    // MARK: - Conversation
    
    public LlamaMobile.CompletionResult generateResponse(long contextHandle, String userMessage, int maxTokens) {
        try {
            LlamaMobile.ConversationResult conversationResult = LlamaMobile.generateResponse(contextHandle, userMessage, maxTokens);
            if (conversationResult != null) {
                return new LlamaMobile.CompletionResult(
                    conversationResult.getText(),
                    conversationResult.getTokensGenerated(),
                    0, // tokensEvaluated not available in ConversationResult
                    false, // truncated not available
                    false, // stoppedEos not available
                    false, // stoppedWord not available
                    false, // stoppedLimit not available
                    "" // stoppingWord not available
                );
            } else {
                return new LlamaMobile.CompletionResult("", 0, 0, false, false, false, false, "");
            }
        } catch (Exception e) {
            Logger.error("generateResponse", e);
            return new LlamaMobile.CompletionResult("", 0, 0, false, false, false, false, "");
        }
    }
    
    public void clearConversation(long contextHandle) {
        try {
            LlamaMobile.clearConversation(contextHandle);
        } catch (Exception e) {
            Logger.error("clearConversation", e);
        }
    }
    
    public boolean isConversationActive(long contextHandle) {
        try {
            return LlamaMobile.isConversationActive(contextHandle);
        } catch (Exception e) {
            Logger.error("isConversationActive", e);
            return false;
        }
    }
    
    // MARK: - Embeddings
    
    public float[] generateEmbeddings(long contextHandle, String text) {
        try {
            return LlamaMobile.generateEmbeddings(contextHandle, text);
        } catch (Exception e) {
            Logger.error("generateEmbeddings", e);
            return new float[0];
        }
    }
    
    // MARK: - Tokenization
    
    public int[] tokenize(long contextHandle, String text) {
        try {
            return LlamaMobile.tokenize(contextHandle, text);
        } catch (Exception e) {
            Logger.error("tokenize", e);
            return new int[0];
        }
    }
    
    public String detokenize(long contextHandle, int[] tokens) {
        try {
            return LlamaMobile.detokenize(contextHandle, tokens);
        } catch (Exception e) {
            Logger.error("detokenize", e);
            return "";
        }
    }
    
    // MARK: - Model Info
    
    public int getContextWindowSize(long contextHandle) {
        try {
            return LlamaMobile.getContextWindowSize(contextHandle);
        } catch (Exception e) {
            Logger.error("getContextWindowSize", e);
            return 0;
        }
    }
    
    public int getEmbeddingDimension(long contextHandle) {
        try {
            return LlamaMobile.getEmbeddingDimension(contextHandle);
        } catch (Exception e) {
            Logger.error("getEmbeddingDimension", e);
            return 0;
        }
    }
    
    public String getModelDescription(long contextHandle) {
        try {
            return LlamaMobile.getModelDescription(contextHandle);
        } catch (Exception e) {
            Logger.error("getModelDescription", e);
            return "";
        }
    }
    
    public long getModelSize(long contextHandle) {
        try {
            return LlamaMobile.getModelSize(contextHandle);
        } catch (Exception e) {
            Logger.error("getModelSize", e);
            return 0;
        }
    }
    
    public long getModelParametersCount(long contextHandle) {
        try {
            return LlamaMobile.getModelParametersCount(contextHandle);
        } catch (Exception e) {
            Logger.error("getModelParametersCount", e);
            return 0;
        }
    }
}
