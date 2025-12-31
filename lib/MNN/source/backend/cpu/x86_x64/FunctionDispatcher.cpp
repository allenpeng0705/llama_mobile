//
//  FunctionDispatcher.cpp
//  MNN
//
//  Created by MNN on 2019/08/25.
//  Copyright © 2018, Alibaba Group Holding Limited
//

#include <limits>
#ifndef __APPLE__
#include "avx512/FunctionSummary.hpp"
#include "avx/FunctionSummary.hpp"
#include "avxfma/FunctionSummary.hpp"
#endif
#include "backend/cpu/compute/CommonOptFunction.h"
#include "backend/cpu/compute/ConvOpt.h"
#include "backend/cpu/compute/Int8FunctionsOpt.h"
#include "cpu_id.h"

// https://stackoverflow.com/a/11230437

// Remove AVX2 include since we're not using AVX on iOS
// #include "AVX2Functions.hpp"

struct FunctionGroup {
    int tileNumber                                                                               = 8;
    int eP                                                                                       = 12;
    int lP                                                                                       = 1;
    int hP                                                                                       = 4;
    void (*MNNExpC8)(float* dest, const float* source, float* offset, const float* parameters, size_t countC8);
    void (*MNNSoftmax)(float* softmaxDst, const float* input, float* runningMax, float* runningSum, float* updateScale, int outside, int reduceSize, int kvSeqOffset, int validOffset, int pack, bool mask);
    void (*MNNReluInt8)(int8_t* dst, const int8_t* src, size_t size, ssize_t zeroPoint);
    void (*MNNHardSwish)(float* dst, const float* src, size_t size);
    void (*MNNGelu)(float* dst, const float* src, size_t size, float* parameters);
    void (*MNNNorm)(float *dst, const float *src, const float *gamma, const float *beta, float epsilon, size_t size, bool RMSNorm);
    FunctionGroup() {
        MNNExpC8 = ::MNNExpC8;
        MNNSoftmax = ::MNNSoftmax;
        MNNReluInt8 = ::MNNReluInt8;
        MNNHardSwish = ::MNNHardSwish;
        MNNGelu = ::MNNGelu;
        MNNNorm = ::MNNNorm;
    }
};

static FunctionGroup gFunc;

void _SSEMNNGetMatMulPackMode(int* eP, int *lP, int* hP) {
    *eP = gFunc.eP;
    *lP = gFunc.lP;
    *hP = gFunc.hP;
}

void MNNAvgPoolUint8(int8_t* dst, int8_t* src, size_t outputWidth, size_t inputWidth, size_t kernelx, size_t kernely, size_t stridesx, ssize_t paddingx, ssize_t factor) {
    int pack = 16;
    uint32_t f = static_cast<uint32_t>(factor);
    uint8_t* dstPtr = reinterpret_cast<uint8_t*>(dst);
    const uint8_t* srcPtr = reinterpret_cast<uint8_t*>(src);
    for (int ox = 0; ox < outputWidth; ++ox) {
        std::vector<uint32_t> sum_(pack, 0);
        for (int y = 0; y < kernely; ++y) {
            for (int x = 0; x < kernelx; ++x) {
                const uint8_t *inputPtr = srcPtr + pack* (inputWidth* y + x);
                for (int idx = 0; idx < pack; ++idx) {
                    sum_[idx] += *(inputPtr + idx);
                }
            }
        }
        for (int idx = 0; idx < pack; ++idx) {
            *(dstPtr + idx) = static_cast<uint8_t>((sum_[idx] * f)>>24);
        }
        dstPtr = dstPtr + pack;
        srcPtr = srcPtr + pack* stridesx;
    }
}

void MNNMaxPoolInt8_(int8_t* dst, int8_t* src, size_t outputWidth, size_t inputWidth, size_t kernelx, size_t kernely, size_t stridesx) {
    int pack = 16;
    int8_t* dstPtr = dst;
    const int8_t* srcPtr = src;
    for (int ox = 0; ox < outputWidth; ++ox){
        std::vector<int8_t> results(pack, INT8_MIN);
        for (int y = 0; y < kernely; ++y) {
            for (int x = 0; x < kernelx; ++x) {
                const int8_t* inputPtr = srcPtr + pack* (x + inputWidth* y);
                for (int idx = 0; idx < pack; ++idx) {
                    results[idx] = std::max(results[idx], *(inputPtr + idx));
                }
            }
        }

        for (int idx = 0; idx < pack;++idx) {
            *(dstPtr + idx) = results[idx];
        }
        dstPtr = dstPtr + pack;
        srcPtr = srcPtr + pack* stridesx;
    }
}


// _SSE_ImageProcessInit removed - no SSE support

// ========= CommonOptFunction.cpp functions removed to avoid duplicate symbols ===========
