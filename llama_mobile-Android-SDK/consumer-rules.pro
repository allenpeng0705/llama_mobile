# Add consumer ProGuard rules here.
# You can control the set of applied configuration files using the
# consumerProguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep the public API of the SDK
-keep public class com.llamamobile.sdk.** {
    public *;
}

# Keep all interfaces
-keep interface com.llamamobile.sdk.** {
    public *;
}

# Keep all enums
-keep enum com.llamamobile.sdk.** {
    public *;
}