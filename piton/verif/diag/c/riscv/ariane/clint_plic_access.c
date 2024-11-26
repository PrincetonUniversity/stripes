// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 26.11.2018
// Description: Simple hello world program that prints 32 times "hello world".
//

#include <stdio.h>


#define NHARTS       PITON_RV64_TILES
#define PLIC_SOURCES 2
#define CLINT_BASE   0xe103c00000ULL
#define PLIC_BASE    0xe200000000ULL

int main(int argc, char ** argv) {

  printf("Reading CLINT registers...\n");
  
  // only use core 0 to perform test
  if(argv[0][0] == 0) {

      uint64_t *addr;
      // misp registers
      for (uint64_t k = 0; k < NHARTS; k++) {
          addr = (uint64_t*)(CLINT_BASE + k*8);
          printf("CLINT: msip %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
          printf("CLINT: result = 0x%016x\n",*addr);
      }
      // mtimecmp registers
      for (uint64_t k = 0; k < NHARTS; k++) {
          addr = (uint64_t*)(CLINT_BASE + 0x4000 + k*8);
          printf("CLINT: mtimecmp %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
          printf("CLINT: result = 0x%016x\n",*addr);          
      }
      // mtime registers
      for (uint64_t k = 0; k < NHARTS; k++) {
          addr = (uint64_t*)(CLINT_BASE + 0xBFF8 + k*8);
          printf("CLINT: mtime %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
          printf("CLINT: result = 0x%016x\n",*addr);
      }

      printf("Reading PLIC registers...\n");
      volatile uint32_t val2;
      // priorities
      for (uint64_t k = 0; k < PLIC_SOURCES; k++) {
          val2 = *(uint32_t*)(PLIC_BASE + 0x4 + k * 4);
          printf("PLIC: source prio %d = 0x%08x\n",k,val2);
      }
      // pending
      for (uint64_t k = 0; k < 5; k++) {
          val2 = *(uint32_t*)(PLIC_BASE + 0x1000 + k * 4);
          printf("PLIC: pending %d = 0x%08x\n",k,val2);
      }
      // enabling
      for (uint64_t i = 0; i < NHARTS; i++) {
          for (uint64_t k = 0; k < 1; k++) {
              val2 = *(uint32_t*)(PLIC_BASE + 0x2000 + i * 0x100 + k * 4);
              printf("PLIC: hart %d m-mode enable %d = 0x%08x\n", i, k, val2);
          }      
      }

      printf("Done!\n");
  }
      
  return 0;
}
