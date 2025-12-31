//
//  MNNC3ToC4Fast.S
//  MNN
//
//  Created by MNN on 2024/08/28.
//  Copyright © 2018, Alibaba Group Holding Limited
//

#ifdef __arm__
#ifndef __aarch64__
#if MNN_USE_NEON

#include "MNNAsmGlobal.h"

.text
.align 5

asm_function MNNC3ToC4Fast
// void MNNC3ToC4Fast(const unsigned char* source, unsigned char* dest, size_t count);
// Auto Load: r0: source, r1: dest, r2: count

push {lr}

vmov.i8 d3, #255
L1:
vld3.8 {d0, d1, d2}, [r0]!
vst4.u8 {d0, d1, d2, d3}, [r1]!
subs r2, r2, #1
bne L1

End:
pop {pc}

#endif // MNN_USE_NEON
#endif
#endif
