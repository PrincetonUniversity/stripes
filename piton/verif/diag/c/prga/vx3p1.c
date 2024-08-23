// Copyright (c) 2024 Princeton University
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the copyright holder nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <stdio.h>
#include "util.h"
#include "stdint.h"
#include "prga.h"
#include "vx3p1.h"

#define N 64

int main(int argc, char** argv) {

    const uint32_t data[N] = {
        6688, 10865, 1424, 22034, 23562, 23361, 15128, 18347, 20480, 28439, 30499, 14655, 3760, 21211, 21443, 29087,
        27474, 24581, 9051, 16133, 470, 27175, 28102, 10999, 23150, 29689, 15836, 25092, 6816, 11242, 23081, 28666,
        2753, 31393, 24408, 414, 26745, 27817, 23453, 6425, 3909, 3182, 12526, 16851, 6166, 19659, 285, 16715,
        7069, 1388, 26313, 26926, 31385, 26028, 24762, 25394, 28811, 14344, 3214, 6399, 14043, 27, 29646, 9604
    };

    volatile uint32_t res[N];
    uint32_t golden[N];

    for (uint32_t i = 0; i < N; i++) {
        golden[i] = data[i] * 3 + 1;
    }

    // read/write registers
    volatile uint64_t uregv;

    // Start bitstream loading
    write4B(0x900, 0x01000000);

    // Load bitstream
    // const static uint32_t bitstream is allocated inside bitstream.h
    for (uint32_t i = 0; i < sizeof(bitstream)/sizeof(bitstream[0]) /* number of elements in array */; i++) {
        write4B(0x900, bitstream[i]);
        if (i % 1024 == 0) {
            printf("%dKB loaded\n", i / 256);

            if ((uregv = read8B(0x818)) == 3) {
                printf("[FAIL] CFG STATUS: 0x%016llx\n", uregv);
                printf("[FAIL] EFLAG STATUS: 0x%016llx\n", read8B(0x808));
                return 1;
            }
        }
    }

    // End bitstream loading
    write4B(0x900, 0x02000000);

    // 0. read cfg status, should return 2
    while ((uregv = read8B(0x818)) != 2) {
        if (uregv == 3) {
            printf("[FAIL] CFG STATUS: 0x%016llx\n", uregv);
            printf("[FAIL] EFLAG STATUS: 0x%016llx\n", read8B(0x808));
            return 1;
        }
    }

    printf("bs dn\n");

    // 1. enable UREG/CCM interface (enable MTHREAD, ATOMIC and NC features)
    write8B(0x820, 0x0000001700000001ull);

    // 2. set clock division (1/8 system clock)
    write8B(0x810, 0);

    // 3. set timeout
    write8B(0xC08, 500);

    // 4. reset (enable) application
    write8B(0xC00, 100);
    printf("init\n");

    // 5. set up its portion of data
    // SRC data base address
    write8B(0x000, (uint64_t) data);

    // DST data base address
    write8B(0x008, (uint64_t) res);

    // VLEN
    write8B(0x010, (uint64_t) N);

    // START
    write8B(0x018, 1);

    // 6. make sure the app is up and running
    while ((uregv = read8B(0x808)) || !read8B(0x020)) {
        if (uregv) {
            printf("[FAIL] Prerun EFLAGS: 0x%016llx\n", uregv);
            return 1;
        }
    }

    // 7. poll app
    while ((uregv = read8B(0x808)) || read8B(0x020)) {
        if (uregv) {
            printf("[FAIL] Postrun EFLAGS: 0x%016llx\n", uregv);
            return 1;
        }
    };

    // 8. check results
    for (int i = 0; i < N; i++) {
        if (res[i] != golden[i]) {
            printf("[FAIL] Results mismatch: res[%d] = %d != golden[%d] = %d\n",
                    i, res[i], i, golden[i]);
            return 1;
        }
    }

    // 9. Passed!
    printf("[PASSED]\n");
    return 0;
}

