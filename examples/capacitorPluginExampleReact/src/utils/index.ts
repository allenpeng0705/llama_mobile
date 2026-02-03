// Shared utilities for the application

/**
 * Resolve model path for different platforms
 * @param path - The model path to resolve
 * @returns Promise<string> - The resolved model path
 */
export const resolveModelPath = async (modelPath: string): Promise<string> => {
  try {
    // Check if we're on a native platform
    if (typeof window !== 'undefined' && window.Capacitor) {
      console.log('Resolving model path for native platform:', modelPath);
      
      // For native platforms, check if the path is already an absolute path
      if (modelPath.startsWith('/')) {
        console.log('Returning absolute model path for native platform:', modelPath);
        return modelPath;
      } else {
        // For bundled models, use the public/models directory structure
        // On iOS, Capacitor copies public directory to the app bundle
        const bundledModelPath = `public/models/${modelPath}`;
        console.log('Returning bundled model path for native platform:', bundledModelPath);
        return bundledModelPath;
      }
    } else {
      // For web platform, return the relative path
      console.log('Resolving model path for web platform:', modelPath);
      return `models/${modelPath}`;
    }
  } catch (error) {
    console.error('Error resolving model path:', error);
    // Fallback to the original path if resolution fails
    return modelPath;
  }
};

/**
 * Get the platform the app is running on
 * @returns string - The platform name
 */
export const getPlatform = (): string => {
  if (window.Capacitor) {
    return window.Capacitor.getPlatform();
  }
  return 'web';
};

/**
 * Format bytes to human-readable format
 * @param bytes - Number of bytes
 * @returns string - Formatted string
 */
export const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};