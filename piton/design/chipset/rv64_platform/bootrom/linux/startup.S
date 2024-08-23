# start sequence of the bootloader
# 
# 
#include <smp.h>
#define DRAM_BASE 0x80000000

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
# Use x/y configs for wakeup interrupt. (i.e. New IPI vector format in micro_arch.pdf)
# See openpiton micro_arch.pdf and OST1 micro arch spec
# for encoding.
# [17:16] == 01 and [5:0] == 000001 means power on reset
# [63] == 1 means the New IPI vector format
# [25:18] = x, [33:26] = y, [47:34] = chip_id, [51:48] = fbits
# Note that P-Mesh is big endian so our 8B word is flipped
#ifndef NO_PMESH_NOC_WAKEUP
  csrr a0, mhartid
  li t0, 0
  li t1, 0
  li t2, MAX_HARTS
  addi t2, t2, -1

  beq t2, t1, _ipis_sent
  bne a0, t1, _ipis_sent

# set t2 t3 to number of tiles in x and y
# t0 t1 are the current x and y
  li t2, PITON_RV64_X_TILES
  li t3, PITON_RV64_Y_TILES

loop:
  # skip (0,0)
  addi t0, t0, 1
  bltu t0, t2, y_determined
  addi t1, t1, 1
  li   t0, 0

y_determined:
  beq  t1, t3, _ipis_sent 

decades_chip:
  li   t4, DECADES_CHIP
  beqz t4, decoupling_skip_IS_tile
  # target_y = y*2
  slli t5, t0, 18
  slli t6, t1, 27
  or   t5, t5, t6
  j    reverse_byte_order

decoupling_skip_IS_tile:
  li   t4, DECADES_DECOUPLING
  beqz t4, x_determined
  li   t4, 3
  and  t4, t4, t0
  li   t5, 1
  bne  t4, t5, x_determined
  addi t0, t0, 1
  # decoupling only has the single-row configuration 
  # thus changing t2 should be fine
  addi t2, t2, 1

x_determined:
  slli t5, t0, 18
  slli t6, t1, 26
  or   t5, t5, t6

reverse_byte_order:
  li   t6, 0x0100010000000080
  li   t4, 0x0000000000ff0000
  and  t4, t5, t4
  slli t4, t4, 24
  or   t6, t4, t6
  li   t4, 0x00000000ff000000
  and  t4, t5, t4
  slli t4, t4, 8
  or   t6, t4, t6
  li   t4, 0x000000ff00000000
  and  t4, t5, t4
  srli t4, t4, 8
  or   t6, t4, t6
  
  li t4, 0x9800000800
  sd t6, 0(t4)
  j loop
#endif

_ipis_sent:
  smp_pause(s1, s2)
  li sp, 0x84000000
  call main
  smp_resume(s1, s2)
  csrr a0, mhartid
  la a1, _dtb
  li s1, DRAM_BASE
  jr s1

  .section .dtb
  .globl _dtb
  .align 4, 0
_dtb:
  .incbin "rv64_platform.dtb"
