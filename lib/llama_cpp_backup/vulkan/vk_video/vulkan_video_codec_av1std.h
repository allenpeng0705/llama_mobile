#ifndef VULKAN_VIDEO_CODEC_AV1STD_H_
#define VULKAN_VIDEO_CODEC_AV1STD_H_

// Stub header for AV1 video codec support
// This is a minimal implementation to satisfy compilation
// Full AV1 support requires the complete Vulkan Video headers

typedef enum StdVideoAV1Profile {
    STD_VIDEO_AV1_PROFILE_MAIN = 0,
    STD_VIDEO_AV1_PROFILE_HIGH = 1,
    STD_VIDEO_AV1_PROFILE_PROFESSIONAL = 2,
    STD_VIDEO_AV1_PROFILE_INVALID = 0x7FFFFFFF
} StdVideoAV1Profile;

typedef enum StdVideoAV1Level {
    STD_VIDEO_AV1_LEVEL_2_0 = 0,
    STD_VIDEO_AV1_LEVEL_2_1 = 1,
    STD_VIDEO_AV1_LEVEL_2_2 = 2,
    STD_VIDEO_AV1_LEVEL_2_3 = 3,
    STD_VIDEO_AV1_LEVEL_3_0 = 4,
    STD_VIDEO_AV1_LEVEL_3_1 = 5,
    STD_VIDEO_AV1_LEVEL_3_2 = 6,
    STD_VIDEO_AV1_LEVEL_3_3 = 7,
    STD_VIDEO_AV1_LEVEL_4_0 = 8,
    STD_VIDEO_AV1_LEVEL_4_1 = 9,
    STD_VIDEO_AV1_LEVEL_4_2 = 10,
    STD_VIDEO_AV1_LEVEL_4_3 = 11,
    STD_VIDEO_AV1_LEVEL_5_0 = 12,
    STD_VIDEO_AV1_LEVEL_5_1 = 13,
    STD_VIDEO_AV1_LEVEL_5_2 = 14,
    STD_VIDEO_AV1_LEVEL_5_3 = 15,
    STD_VIDEO_AV1_LEVEL_6_0 = 16,
    STD_VIDEO_AV1_LEVEL_6_1 = 17,
    STD_VIDEO_AV1_LEVEL_6_2 = 18,
    STD_VIDEO_AV1_LEVEL_6_3 = 19,
    STD_VIDEO_AV1_LEVEL_7_0 = 20,
    STD_VIDEO_AV1_LEVEL_7_1 = 21,
    STD_VIDEO_AV1_LEVEL_7_2 = 22,
    STD_VIDEO_AV1_LEVEL_7_3 = 23,
    STD_VIDEO_AV1_LEVEL_INVALID = 0x7FFFFFFF
} StdVideoAV1Level;

// Forward declarations for AV1 structures
typedef struct StdVideoAV1SequenceHeader StdVideoAV1SequenceHeader;
typedef struct StdVideoDecodeAV1PictureInfo StdVideoDecodeAV1PictureInfo;
typedef struct StdVideoDecodeAV1ReferenceInfo StdVideoDecodeAV1ReferenceInfo;
typedef struct StdVideoEncodeAV1DecoderModelInfo StdVideoEncodeAV1DecoderModelInfo;
typedef struct StdVideoEncodeAV1OperatingPointInfo StdVideoEncodeAV1OperatingPointInfo;
typedef struct StdVideoEncodeAV1PictureInfo StdVideoEncodeAV1PictureInfo;
typedef struct StdVideoEncodeAV1ReferenceInfo StdVideoEncodeAV1ReferenceInfo;

#endif // VULKAN_VIDEO_CODEC_AV1STD_H_
