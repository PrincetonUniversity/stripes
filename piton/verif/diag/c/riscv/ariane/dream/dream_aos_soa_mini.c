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
#include "dream_aos_data.h"

void _kernel_(uint32_t id, uint32_t core_num){
}


int main(int argc, char ** argv) {
    volatile static uint32_t amo_cnt = 0;
    uint32_t id, core_num;
    id = argv[0][0];
    core_num = argv[0][1];
    int i;
    uint64_t src_addr, dest_addr, soa_result, aos_source;
    if (id == 0) {
        src_addr = 0x0000000082345680;
        dest_addr = 0x0000000098765420;
        for (i=0; i<40; i++) {
            *(volatile uint64_t*)(src_addr + i*8) = data[i];
        }
        dream_config(1, (void *)0x0, (void *)0x3);
        dream_config(1, (void *)0x1, (void *)src_addr);
        dream_config(1, (void *)0x2, (void *)dest_addr);
        dream_config(1, (void *)0x4, (void *)0x8);
        dream_config(1, (void *)0x5, (void *)0x0303030303030303);
        dream_config(1, (void *)0xa, (void *)0x0000000000000002);
        dream_config(1, (void *)0xb, (void *)0x0000000000000040);
        dream_config(1, (void *)0x7, (void *)0x8000000000000004);

        while (dream_read(1, (void *)0x8) == 0);
        for (i=0; i<32; i++) {
            aos_source = *(volatile uint64_t*)(src_addr + i*8);
            soa_result = *(volatile uint64_t*)(dest_addr + (i%8)*32 + (uint32_t)(i/8)*8);
            if (soa_result != aos_source) {
                printf("Fail! store_value %p, read_value: %p\n", aos_source, soa_result);
                return 1;
            }
        }
        printf("Match!\n");
    }
    return 0;
}