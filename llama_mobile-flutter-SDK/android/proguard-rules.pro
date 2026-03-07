# ProGuard rules for llama_mobile Flutter SDK
# Add project specific ProGuard rules here.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep all public classes and methods in the SDK
-dontwarn com.llamamobile.**
-keep class com.llamamobile.** { *; }
