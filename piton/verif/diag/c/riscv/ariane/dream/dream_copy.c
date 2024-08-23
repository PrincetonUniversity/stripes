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

void _kernel_(uint32_t id, uint32_t core_num){
}
int main(int argc, char ** argv) {
    volatile static uint32_t amo_cnt = 0;
    uint32_t id, core_num;
    id = argv[0][0];
    core_num = argv[0][1];
    int i;
    uint64_t src_addr, dest_addr, write_addr, read_addr, data_write, data_read;
    if (id == 0) {
        src_addr = 0x0000000082345680;
        dest_addr = 0x0000000098765420;
        for (i=0; i<16; i++) {
            *(volatile uint64_t*)(src_addr + i*8) = D[i%16];
        }
        for (i=0; i<8; i++) {
            *(volatile uint64_t*)(dest_addr + i*8) = D[(i+3)%16];
        }
        dream_config(1, (void *)0x0, (void *)0x2);
        dream_config(1, (void *)0x1, (void *)src_addr);
        dream_config(1, (void *)0x2, (void *)dest_addr);
        dream_config(1, (void *)0x5, (void *)0x0000000000000004);
        dream_config(1, (void *)0x3, (void *)0x8000000000000080);
        while (dream_read(1, (void *)0x8) == 0);
        for (i=0; i<64; i=i+8) {
            write_addr = src_addr + i*8;
            data_write = *(volatile uint64_t*)(write_addr);
            read_addr = dest_addr + i*8;
            data_read = *(volatile uint64_t*)(read_addr);
            if (data_write != data_read) {
                printf("i=%d! st_addr: %p: %p, rd_addr %p: %p\n", i, write_addr, data_write, read_addr, data_read);
                return 1;
            }
        }
        printf("Match!\n");
        
    }
    return 0;
}