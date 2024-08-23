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

#define BYTE         8
#define TILE_X       28
#define TILE_Y       24
#define WIDTH        4
#define FIFO         9
#define BASE_MAPLE 0xe100800000
#define BASE_SPD   0xe100900000
#define BASE_MMU   0xe100A00000
#define BASE_DREAM 0xe100B00000
#define BASE_NIBBL 0xe100C00000

void dream_config(uint32_t tile, void *addr, void *value) {
  uint32_t tileno = (tile/WIDTH)*4+3;
  uint64_t base_dream =  BASE_DREAM | ((tile%WIDTH) << TILE_X) | ((tileno) << TILE_Y); 
  uint64_t write_addr = (uint64_t)((uint32_t)addr*BYTE) | base_dream; 
  // printf("Target DREAM addr: %p, write config data: %p\n", write_addr, (uint64_t)value);
  *(volatile uint64_t*)write_addr = (uint64_t)value;
}

uint64_t dream_read(uint32_t tile, void *addr) {
  uint32_t tileno = (tile/WIDTH)*4+3;
  uint64_t base_dream =  BASE_DREAM | ((tile%WIDTH) << TILE_X) | ((tileno) << TILE_Y); 
  uint64_t read_addr = (uint64_t)((uint32_t)addr*BYTE) | base_dream; 
  uint64_t read_val = *(volatile uint64_t*)read_addr;
  // printf("Target DREAM addr: %p, read config data: %p\n", read_addr, read_val);
  return read_val;
}

void sp_write(uint32_t tile, void *addr, void *value) {
  uint32_t tileno = (tile/WIDTH)*4+3;
  uint64_t base_spd =  BASE_SPD | ((tile%WIDTH) << TILE_X) | ((tileno) << TILE_Y); 
  uint64_t write_addr = (uint64_t)((uint32_t)addr) | base_spd; 
  // printf("Target SP addr: %p, write data: %p\n", write_addr, (uint64_t)value);
  *(volatile uint64_t*)write_addr = (uint64_t)value; 
}


uint64_t sp_read(uint32_t tile, void *addr) {
  uint32_t tileno = (tile/WIDTH)*4+3;
  uint64_t base_spd =  BASE_SPD | ((tile%WIDTH) << TILE_X) | ((tileno) << TILE_Y); 
  uint64_t read_addr = (uint64_t)((uint32_t)addr) | base_spd; 
  uint64_t read_val = *(volatile uint64_t*)read_addr;
  // printf("Target SP addr: %p, read data: %p\n", read_addr, read_val);
  return read_val;
}

// Code is a value between 0 and 7 (Nibbler has 8 config regs of 64 bits)
void nibbler_config(uint32_t tile, uint32_t code, uint64_t value) {
  uint32_t tileno = (tile/WIDTH)*4+3;
  uint64_t base_nibbler = BASE_NIBBL | ((tile%WIDTH) << TILE_X) | ((tileno) << TILE_Y); 
  // printf("NB Adr: %p, dat: %p\n", base_nibbler, value);
  uint64_t offset = code*BYTE;
  *(volatile uint64_t*)(offset | base_nibbler) = value;
}

uint64_t nibbler_read(uint32_t tile, void *addr) {
  uint32_t tileno = (tile/WIDTH)*4+3;
  uint64_t base_nibbler = BASE_NIBBL | ((tile%WIDTH) << TILE_X) | ((tileno) << TILE_Y); 
  uint64_t read_addr = (uint64_t)((uint32_t)addr*BYTE) | base_nibbler; 
  uint64_t read_val = *(volatile uint64_t*)read_addr;
  // printf("NB addr: %p, rd dat: %p\n", read_addr, read_val);
  return read_val;
}

