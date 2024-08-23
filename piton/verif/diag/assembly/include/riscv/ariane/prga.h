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

#ifndef PRGA_H
#define PRGA_H

/*
 * This header only works with one source file, because global variables and
 * functions are defined instead of "declared" in this header.
 */

// PRGA Tile: (0, 3)
static volatile void * PRGA_BASE_ADDR = (void *)(0xE1039ull << 20);

void write8B(uint64_t offset, uint64_t data) {
    volatile uint64_t * addr = (uint64_t *)(PRGA_BASE_ADDR + offset);
    *addr = data;
}

void write4B(uint64_t offset, uint32_t data) {
    volatile uint32_t * addr = (uint32_t *)(PRGA_BASE_ADDR + offset);
    *addr = data;
}

void write2B(uint64_t offset, uint16_t data) {
    volatile uint16_t * addr = (uint16_t *)(PRGA_BASE_ADDR + offset);
    *addr = data;
}

void write1B(uint64_t offset, uint8_t data) {
    volatile uint8_t * addr = (uint8_t *)(PRGA_BASE_ADDR + offset);
    *addr = data;
}

uint64_t read8B(uint64_t offset) {
    volatile uint64_t * addr = (uint64_t *)(PRGA_BASE_ADDR + offset);
    return *addr;
}

uint32_t read4B(uint64_t offset) {
    volatile uint32_t * addr = (uint32_t *)(PRGA_BASE_ADDR + offset);
    return *addr;
}

uint16_t read2B(uint64_t offset) {
    volatile uint16_t * addr = (uint16_t *)(PRGA_BASE_ADDR + offset);
    return *addr;
}

uint8_t read1B(uint64_t offset) {
    volatile uint8_t * addr = (uint8_t *)(PRGA_BASE_ADDR + offset);
    return *addr;
}

#endif /* ifndef PRGA_H */
