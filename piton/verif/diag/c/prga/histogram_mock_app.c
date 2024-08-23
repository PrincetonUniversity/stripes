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
#include "histogram.h"

#define NUM_BINS 32
#define NUM_DATA 256

int main(int argc, char** argv) {
    const uint64_t BIN_WIDTH = 1000;
    const uint64_t BIN_MIN = 0;

    volatile uint64_t data[NUM_DATA] = {
        6688, 10865, 1424, 22034, 23562, 23361, 15128, 18347, 20480, 28439, 30499, 14655, 3760, 21211, 21443, 29087,
        27474, 24581, 9051, 16133, 470, 27175, 28102, 10999, 23150, 29689, 15836, 25092, 6816, 11242, 23081, 28666,
        2753, 31393, 24408, 414, 26745, 27817, 23453, 6425, 3909, 3182, 12526, 16851, 6166, 19659, 285, 16715,
        7069, 1388, 26313, 26926, 31385, 26028, 24762, 25394, 28811, 14344, 3214, 6399, 14043, 27, 29646, 9604,
        20894, 9692, 21003, 9875, 5703, 2969, 22548, 24533, 4815, 11221, 16809, 28907, 4552, 4650, 994, 18882,
        18806, 3726, 6684, 19868, 30361, 2450, 8046, 7544, 28242, 17577, 4961, 3372, 2030, 1147, 2081, 12083,
        15036, 30753, 30237, 23901, 5612, 21532, 18786, 27430, 7553, 930, 8325, 28050, 10232, 14970, 2994, 21443,
        26619, 5135, 22323, 21538, 3130, 10445, 25227, 8178, 2509, 18382, 26354, 15224, 13575, 2677, 26000, 22916,
        7383, 19011, 27165, 27826, 13208, 24084, 18854, 12438, 1607, 5661, 2792, 26737, 27798, 7995, 24453, 13242,
        15428, 18046, 912, 15447, 16364, 26145, 23730, 8579, 17068, 5322, 18967, 6562, 10806, 29145, 27595, 13442,
        23542, 2231, 628, 12075, 31540, 20676, 607, 26286, 2157, 1508, 12477, 16719, 27704, 29150, 11525, 7815,
        28072, 18433, 10638, 11159, 14114, 10718, 15730, 24697, 20523, 8863, 29785, 11690, 5638, 4831, 3176, 4542,
        8629, 12003, 29198, 5370, 30881, 15726, 1654, 28463, 16836, 12271, 30513, 25801, 21451, 26370, 14613, 3452,
        25945, 19373, 2259, 5311, 22438, 19041, 7817, 26135, 2764, 10769, 14796, 22073, 19844, 461, 2418, 21109,
        31389, 31671, 6303, 12860, 29300, 17861, 6986, 8803, 17811, 10342, 27272, 26667, 18036, 10522, 23911, 24658,
        9316, 17828, 15506, 7392, 17316, 9052, 8536, 16711, 14408, 259, 11219, 29067, 6643, 28820, 23078, 12599
    };

    const uint64_t golden[NUM_BINS] = {
        11, 6, 14, 9, 6, 8, 10, 8, 8, 6, 10, 6, 9, 4, 8, 9,
        8, 6, 10, 6, 4, 8, 6, 10, 8, 5, 13, 10, 10, 9, 6, 5
    };

    volatile uint64_t hist[NUM_BINS] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    };

    volatile uint64_t uregv;

    // 0. read cfg status, should return 2
    while ((uregv = read8B(0x818)) != 2) {
        if (uregv == 3) {
            printf("[FAIL] CFG STATUS: 0x%016llx\n", uregv);
            printf("[FAIL] EFLAG STATUS: 0x%016llx\n", read8B(0x808));
            return 1;
        }
    }

    // 1. enable UREG/CCM interface (enable MTHREAD, ATOMIC and NC features)
    write8B(0x820, 0x0000001700000001ull);

    // 2. set clock division (1/2 system clock)
    write8B(0x810, 1);

    // // 2. switch user clock back to core clock 
    // write8B(0x810, 0);

    // 3. set timeout 
    write8B(0xC08, 500);

    // 4. reset (enable) application
    write8B(0xC00, 100);

    // 5. set up its portion of data
    //  hist base addr
    write8B(0x000, (uint64_t)hist);

    //  hist bin count
    write8B(0x008, NUM_BINS);

    //  hist min
    write8B(0x010, BIN_MIN);

    //  hist bin width 
    write8B(0x018, BIN_WIDTH);

    //  data base addr
    write8B(0x020, (uint64_t)data);

    //  data count
    write8B(0x028, NUM_DATA / 2);

    //  data stride
    write8B(0x030, 2);

    //  start app
    write8B(0x038, 1);

    //  make sure the app is up and running
    while ((uregv = read8B(0x808)) || !read8B(0x040)) {
        if (uregv) {
            printf("[FAIL] Prerun EFLAGS: 0x%016llx\n", uregv);
            return 1;
        }
    }

    // 6. do my part of the job
    for (int i = 1; i < NUM_DATA; i += 2) {
        ATOMIC_OP(hist[(data[i] - BIN_MIN) / BIN_WIDTH], 1, add, d);
    }

    // 7. poll app
    while ((uregv = read8B(0x808)) || read8B(0x040)) {
        if (uregv) {
            printf("[FAIL] Postrun EFLAGS: 0x%016llx\n", uregv);
            return 1;
        }
    };

    // 8. check results
    for (int i = 0; i < NUM_BINS; i++) {
        if (hist[i] != golden[i]) {
            printf("[FAIL] Results mismatch: hist[%d] = %d != golden[%d] = %d\n",
                    i, hist[i], i, golden[i]);
            return 1;
        }
    }

    // 9. Passed!
    printf("[PASSED]\n");
    return 0;
}
