// LlamaEngineJavaTest.java — proves the v2 SDK is fully usable from pure Java.
package com.llamamobile;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

@RunWith(AndroidJUnit4.class)
public class LlamaEngineJavaTest {

    @Test
    public void libraryVersionIsV2() {
        String v = LlamaEngine.libraryVersion();
        assertNotNull(v);
        assertTrue("starts with 2.x: " + v, v.startsWith("2."));
    }

    @Test
    public void openMissingModelThrowsFromJava() {
        LlamaEngine.Config config = new LlamaEngine.Config();
        config.setModelPath("/nonexistent/model.gguf");
        try {
            LlamaEngine engine = LlamaEngine.open(config); // static factory (Java)
            engine.close();
            fail("expected open to fail for a missing model");
        } catch (Throwable t) {
            if (t instanceof LlamaException) {
                LlamaException e = (LlamaException) t;
                assertTrue("got " + e.getCode(),
                        e.getCode() == LlamaStatus.MODEL_LOAD.getCode()
                            || e.getCode() == LlamaStatus.MODEL_NOT_FOUND.getCode()
                            || e.getCode() == LlamaStatus.IO.getCode()
                            || e.getCode() == LlamaStatus.INVALID_ARGUMENT.getCode());
            } else {
                throw new AssertionError("unexpected " + t);
            }
        }
    }

    /** Java consumers can call tokenize/modelInfo on a real model. */
    @Test
    public void modelInfoAndTokenizeFromJava() throws Exception {
        java.io.File model = firstReachableModel();
        if (model == null) return; // model not pushed — skip on CI/emulator
        LlamaEngine.Config config = new LlamaEngine.Config();
        config.setModelPath(model.getAbsolutePath());
        config.setEngine(1); // CPU for determinism
        config.setNCtx(2048);
        LlamaEngine engine = LlamaEngine.open(config);
        try {
            LlamaModelInfo info = engine.modelInfo();
            assertTrue("nParams > 0", info.getNParams() > 0);
            assertTrue("nEmbd > 0", info.getNEmbd() > 0);
            int[] tokens = engine.tokenize("Hello from pure Java");
            assertTrue("tokenized", tokens.length > 0);
            String round = engine.detokenize(tokens);
            assertTrue("detokenized", round != null && !round.isEmpty());
        } finally {
            engine.close();
        }
    }

    private static java.io.File firstReachableModel() {
        java.io.File[] candidates = {
            new java.io.File(
                androidx.test.platform.app.InstrumentationRegistry
                    .getInstrumentation().getTargetContext()
                    .getExternalFilesDir(null),
                "SmolLM-360M-Instruct.Q6_K.gguf"),
            new java.io.File("/sdcard/Download/SmolLM-360M-Instruct.Q6_K.gguf"),
        };
        for (java.io.File f : candidates) {
            if (f != null && f.exists()) return f;
        }
        return null;
    }
}
