#ifndef VULKAN_VIDEO_CODEC_VP9STD_H_
#define VULKAN_VIDEO_CODEC_VP9STD_H_

// Stub header for VP9 video codec support
// This is a minimal implementation to satisfy compilation
// Full VP9 support requires the complete Vulkan Video headers

typedef enum StdVideoVP9Profile {
    STD_VIDEO_VP9_PROFILE_0 = 0,
    STD_VIDEO_VP9_PROFILE_1 = 1,
    STD_VIDEO_VP9_PROFILE_2 = 2,
    STD_VIDEO_VP9_PROFILE_3 = 3,
    STD_VIDEO_VP9_PROFILE_INVALID = 0x7FFFFFFF
} StdVideoVP9Profile;

typedef enum StdVideoVP9Level {
    STD_VIDEO_VP9_LEVEL_1_0 = 0,
    STD_VIDEO_VP9_LEVEL_1_1 = 1,
    STD_VIDEO_VP9_LEVEL_2_0 = 2,
    STD_VIDEO_VP9_LEVEL_2_1 = 3,
    STD_VIDEO_VP9_LEVEL_3_0 = 4,
    STD_VIDEO_VP9_LEVEL_3_1 = 5,
    STD_VIDEO_VP9_LEVEL_4_0 = 6,
    STD_VIDEO_VP9_LEVEL_4_1 = 7,
    STD_VIDEO_VP9_LEVEL_5_0 = 8,
    STD_VIDEO_VP9_LEVEL_5_1 = 9,
    STD_VIDEO_VP9_LEVEL_6_0 = 10,
    STD_VIDEO_VP9_LEVEL_6_1 = 11,
    STD_VIDEO_VP9_LEVEL_6_2 = 12,
    STD_VIDEO_VP9_LEVEL_INVALID = 0x7FFFFFFF
} StdVideoVP9Level;

// Forward declarations for VP9 structures
typedef struct StdVideoVP9SequenceHeader StdVideoVP9SequenceHeader;
typedef struct StdVideoVP9PictureInfo StdVideoVP9PictureInfo;
typedef struct StdVideoVP9Segmentation StdVideoVP9Segmentation;
typedef struct StdVideoVP9LoopFilter StdVideoVP9LoopFilter;
typedef struct StdVideoVP9Quantization StdVideoVP9Quantization;
typedef struct StdVideoDecodeVP9PictureInfo StdVideoDecodeVP9PictureInfo;
typedef struct StdVideoDecodeVP9ReferenceInfo StdVideoDecodeVP9ReferenceInfo;

#endif // VULKAN_VIDEO_CODEC_VP9STD_H_
