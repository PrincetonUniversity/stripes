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
#include <stdlib.h>
#include "dcpn.h"
#include "util.h"

#define NUM_WORDS 16
static uint64_t D[NUM_WORDS] = {0x3322110033221100,
                                0x7766554477665544,
                                0xBBAA9988BBAA9988,
                                0xFFEEDDCCFFEEDDCC,
                                0x1111153463411111,
                                0x2222225265325f22,
                                0x3333333333333333,
                                0x4444444444444444,
                                0x5555555555555555,
                                0x6666666666666666,
                                0x7777777777777777,
                                0x8888888888888888,
                                0x9999999999999999,
                                0xAAAAAAAAAAAAAAAA,
                                0xBBBBBBBBBBBBBBBB,
                                0xCCCCCCCCCCCCCCCC};


uint64_t spd[1024][8];

void _kernel_(uint32_t id, uint32_t core_num){
    int i, j, addr;
    uint64_t read_result;
    if(id == 0) {
        addr = 0;
        for (i=0; i<1; i++) {
            for (j=0; j<4; j++) {
                spd[i][j] = D[addr/8%16];
                sp_write(1, (void *)addr, (void *)spd[i][j]);
                addr = addr + 8;
            }
        }
        addr = 0;
        for (i=0; i<1; i++) {
            for (j=0; j<4; j++) {
                spd[i][j] = D[addr/8%16];
                read_result = sp_read(1, (void *)addr);
                addr = addr + 8;
                if (read_result != spd[i][j]) {
                    printf("Fail! store_value %p, read_value: %p\n", spd[i][j], read_result);
                    return 1;
                }
            }
        }
        printf("Match!\n");
    }
}
int main(int argc, char ** argv) {
    volatile static uint32_t amo_cnt = 0;
    uint32_t id, core_num;
    id = argv[0][0];
    core_num = argv[0][1];
    _kernel_(id,core_num);
    return 0;
}