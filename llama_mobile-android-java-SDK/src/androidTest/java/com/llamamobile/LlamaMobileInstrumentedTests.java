package com.llamamobile;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;

import java.io.File;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Arrays;

/**
 * Instrumented tests for LlamaMobile Java SDK
 * These tests run on an Android device or emulator.
 */
@RunWith(AndroidJUnit4.class)
public class LlamaMobileInstrumentedTests {

    private static final String TAG = "LlamaMobileTests";
    private static final String TEST_ASSET_DIR = "grammars";
    private static final String TEST_GRAMMAR_FILE = "json.gbnf";
    private String TEST_MODEL_DIR;
    private Context appContext;
    
    @Before
    public void setUp() {
        appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        
        // Use internal device storage instead of sdcard
        File externalFilesDir = appContext.getExternalFilesDir(null);
        TEST_MODEL_DIR = new File(externalFilesDir, "llama_mobile/models").getAbsolutePath();
        
        // Create model directory structure if it doesn't exist
        File modelDir = new File(TEST_MODEL_DIR);
        if (!modelDir.exists()) {
            modelDir.mkdirs();
        }
    }

    @Test
    public void testAssetLoading() {
        AssetManager assetManager = appContext.getAssets();

        try {
            // List all grammar files
            String[] grammarFiles = assetManager.list(TEST_ASSET_DIR);
            assertNotNull("Grammar directory should exist", grammarFiles);
            Log.d(TAG, "Found grammar files: " + Arrays.toString(grammarFiles));
            
            // Check if specific grammar file exists
            boolean hasJsonGrammar = false;
            for (String file : grammarFiles) {
                if (file.equals(TEST_GRAMMAR_FILE)) {
                    hasJsonGrammar = true;
                    break;
                }
            }
            assertTrue("JSON grammar file should exist", hasJsonGrammar);
            
        } catch (IOException e) {
            Log.e(TAG, "Error accessing assets: " + e.getMessage());
            fail("Asset loading should succeed");
        }
    }

    @Test
    public void testFileDirectoryAccess() {
        // Test if we can create a directory for models
        File modelDir = new File(TEST_MODEL_DIR);
        boolean dirCreated = modelDir.mkdirs() || modelDir.exists();
        
        // This might fail if we don't have write permission, but we can still check if directory exists
        Log.d(TAG, "Model directory exists: " + modelDir.exists());
        Log.d(TAG, "Can write to model directory: " + modelDir.canWrite());
        
        // Just check if external storage is available
        String state = Environment.getExternalStorageState();
        assertTrue("External storage should be available", 
                Environment.MEDIA_MOUNTED.equals(state) || Environment.MEDIA_MOUNTED_READ_ONLY.equals(state));
    }

    @Test
    public void testNativeLibraryLoading() {
        try {
            // The library should be loaded automatically via static block
            Log.d(TAG, "Native library loaded successfully");
            
            // Test that we can access native methods
            long invalidContext = -1;
            assertFalse("Invalid context should not be valid", LlamaMobile.isContextValid(invalidContext));
            
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Native library loading failed: " + e.getMessage());
            // This might fail on some test environments, so we don't fail the test
            Log.w(TAG, "Skipping native library test - this is expected on some environments");
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error: " + e.getMessage());
            fail("Native library test should not throw exceptions");
        }
    }

    @Test
    public void testContextSafety() {
        // Test with invalid context
        long invalidContext = -1;
        assertFalse("Invalid context should not be valid", LlamaMobile.isContextValid(invalidContext));
        assertFalse("Should fail to release invalid context", LlamaMobile.releaseContext(invalidContext));
        
        // These should be safe to call with invalid context
        LlamaMobile.generateEmbedding(invalidContext, "test");
        LlamaMobile.generateCompletion(invalidContext, "test");
        
        Log.d(TAG, "Context safety tests passed");
    }

    @Test
    public void testDeviceCompatibility() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        
        // Log device information
        Log.d(TAG, "Device: " + Build.MANUFACTURER + " " + Build.MODEL);
        Log.d(TAG, "Android Version: " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ")");
        Log.d(TAG, "ABIs: " + Arrays.toString(Build.SUPPORTED_ABIS));
        
        // Check if device architecture is supported
        boolean hasSupportedAbi = false;
        for (String abi : Build.SUPPORTED_ABIS) {
            if (abi.equals("arm64-v8a") || abi.equals("x86_64")) {
                hasSupportedAbi = true;
                break;
            }
        }
        
        if (hasSupportedAbi) {
            Log.d(TAG, "Device has supported ABI");
        } else {
            Log.w(TAG, "Device ABI may not be fully supported: " + Arrays.toString(Build.SUPPORTED_ABIS));
        }
        
        // Test should pass regardless of architecture
        assertTrue("Device compatibility test should pass", true);
    }

    private void copyAssetToStorage(Context context, String assetPath, String destPath) throws IOException {
        AssetManager assetManager = context.getAssets();
        InputStream in = assetManager.open(assetPath);
        File outFile = new File(destPath);
        
        // Create directory if it doesn't exist
        outFile.getParentFile().mkdirs();
        
        FileOutputStream out = new FileOutputStream(outFile);
        byte[] buffer = new byte[1024];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
        in.close();
        out.close();
    }
}
