# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep React Native classes
-keep class com.facebook.react.** {
    *;
}

# Keep LlamaMobile classes
-keep class com.llamamobile.** {
    *;
}

# Keep our React Native module
-keep class com.llamamobile.reactnative.llama_mobile_react_native_sdk.** {
    *;
}
