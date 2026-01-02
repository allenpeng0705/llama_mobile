cmake_minimum_required(VERSION 3.13)

project(mnn_tts VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(BUILD_BERTVITS2 "Build BertVit2 TTS " ON)
option(BUILD_PIPER "Build PIPER TTS " OFF)
option(BUILD_ANDROID "Build for Android" OFF)

if(ANDROID)
    set(BUILD_ANDROID ON CACHE BOOL "Build for Android" FORCE)
endif()

# MNN target is already created by the main MNN CMakeLists.txt
set(MNN_SOURCE_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../../)
message(STATUS "MNN_SOURCE_ROOT: ${MNN_SOURCE_ROOT}")

include_directories(
	${CMAKE_CURRENT_LIST_DIR}/include
	${CMAKE_CURRENT_LIST_DIR}/../3rd_party/include
	${MNN_SOURCE_ROOT}/include
	${MNN_SOURCE_ROOT}/tools/audio/include
	${MNN_SOURCE_ROOT}/transformers/llm/engine/include
)

if(BUILD_BERTVITS2)
  include_directories(
  	${CMAKE_CURRENT_LIST_DIR}/include/bertvits2
  )
endif()

if(BUILD_PIPER)
  include_directories(
  	${CMAKE_CURRENT_LIST_DIR}/include/piper
    ${CMAKE_CURRENT_LIST_DIR}/third_party/piper/espeak-ng/src/include/espeak-ng/
  )
endif()

set(SHARED_SOURCE_FILES
  ${CMAKE_CURRENT_LIST_DIR}/src/mnn_tts_config.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/mnn_tts_sdk.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/mnn_tts_logger.cpp
)

set(BERTVITS2_SOURCE_FILES
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/an_to_cn.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/utils.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/mnn_bertvits2_tts_impl.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/text_preprocessor.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/pinyin.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/chinese_g2p.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/chinese_bert.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/english_bert.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/english_g2p.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/tone_adjuster.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/tts_generator.cpp
  ${CMAKE_CURRENT_LIST_DIR}/src/bertvits2/word_spliter.cpp
)

if(BUILD_PIPER)
  set(PIPER_SOURCE_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/piper/audio_generator.cpp
    ${CMAKE_CURRENT_LIST_DIR}/src/piper/mnn_piper_tts_impl.cpp
    ${CMAKE_CURRENT_LIST_DIR}/src/piper/phoneme_ids.cpp
  )
endif()

if(BUILD_ANDROID)
  set(ANDROID_SOURCE_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/android/tts_service.cpp
    ${CMAKE_CURRENT_LIST_DIR}/src/android/tts_service_jni.cpp
  )
endif()

if(BUILD_PIPER)
  add_subdirectory(third_party/piper/espeak-ng)
endif()

if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME} SHARED ${PIPER_SOURCE_FILES} ${BERTVITS2_SOURCE_FILES} ${SHARED_SOURCE_FILES} ${ANDROID_SOURCE_FILES})
else()
    add_library(${PROJECT_NAME} STATIC ${PIPER_SOURCE_FILES} ${BERTVITS2_SOURCE_FILES} ${SHARED_SOURCE_FILES} ${ANDROID_SOURCE_FILES})
endif()

# Add 16KB page size support for Android
if(BUILD_ANDROID)
    target_link_options(${PROJECT_NAME} PRIVATE "-Wl,-z,max-page-size=16384")
endif()

if(BUILD_ANDROID)
    target_link_libraries(${PROJECT_NAME} log MNN ) 
else()
    target_link_libraries(${PROJECT_NAME} MNN ) 
endif()