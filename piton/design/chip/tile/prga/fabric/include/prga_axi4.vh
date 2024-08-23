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

`ifndef PRGA_AXI4_VH
`define PRGA_AXI4_VH

`include "prga_system.vh"

`define PRGA_AXI4_ID_WIDTH      `PRGA_CCM_THREADID_WIDTH
`define PRGA_AXI4_ID_COUNT      (1 << `PRGA_AXI4_ID_WIDTH)

`define PRGA_AXI4_ADDR_WIDTH    `PRGA_CCM_ADDR_WIDTH
`define PRGA_AXI4_DATA_WIDTH    `PRGA_CCM_DATA_WIDTH
`define PRGA_AXI4_DATA_BYTES    `PRGA_CCM_DATA_BYTES

`define PRGA_AXI4_XRESP_WIDTH   2
`define PRGA_AXI4_XRESP_OKAY    2'b00
`define PRGA_AXI4_XRESP_EXOKAY  2'b01   // not used
`define PRGA_AXI4_XRESP_SLVERR  2'b10   // not used
`define PRGA_AXI4_XRESP_DECERR  2'b11   // not used

`define PRGA_AXI4_AXLEN_WIDTH   8

`define PRGA_AXI4_AXSIZE_WIDTH  3
`define PRGA_AXI4_AXSIZE_1B     3'b000
`define PRGA_AXI4_AXSIZE_2B     3'b001
`define PRGA_AXI4_AXSIZE_4B     3'b010
`define PRGA_AXI4_AXSIZE_8B     3'b011
`define PRGA_AXI4_AXSIZE_16B    3'b100  // not supported
`define PRGA_AXI4_AXSIZE_32B    3'b101  // not supported
`define PRGA_AXI4_AXSIZE_64B    3'b110  // not supported
`define PRGA_AXI4_AXSIZE_128B   3'b111  // not supported

`define PRGA_AXI4_AXBURST_WIDTH 2
`define PRGA_AXI4_AXBURST_FIXED 2'b00
`define PRGA_AXI4_AXBURST_INCR  2'b01
`define PRGA_AXI4_AXBURST_WRAP  2'b10   // not supported

`define PRGA_AXI4_AXCACHE_WIDTH         4
// in practice, we only check "|AxCache[3:2]" to determine if the transaction is cacheable
// i.e., device, bufferable, write-back/write-through and allocation strategy
// are not respected
//
// non-cacheable transactions
`define PRGA_AXI4_AXCACHE_DEV_NB        4'b0000
`define PRGA_AXI4_AXCACHE_DEV_BUF       4'b0001
`define PRGA_AXI4_AXCACHE_NORM_NC_NB    4'b0010
`define PRGA_AXI4_AXCACHE_NORM_NC_BUF   4'b0011
`define PRGA_AXI4_AXCACHE_NORM_NC_BUF   4'b0011
// cacheable reads
`define PRGA_AXI4_ARCACHE_WT_NA         4'b1010
`define PRGA_AXI4_ARCACHE_WT_ALCT       4'b1110
`define PRGA_AXI4_ARCACHE_WT_ALCT_ALT   4'b0110
`define PRGA_AXI4_ARCACHE_WB_NA         4'b1110
`define PRGA_AXI4_ARCACHE_WB_ALCT       4'b1111
`define PRGA_AXI4_ARCACHE_WB_ALCT_ALT   4'b0111
// cacheable writes
`define PRGA_AXI4_AWCACHE_WT_NA         4'b0110
`define PRGA_AXI4_AWCACHE_WT_ALCT       4'b1110
`define PRGA_AXI4_AWCACHE_WT_ALCT_ALT   4'b1010
`define PRGA_AXI4_AWCACHE_WB_NA         4'b0111
`define PRGA_AXI4_AWCACHE_WB_ALCT       4'b1111
`define PRGA_AXI4_AWCACHE_WB_ALCT_ALT   4'b1011

`define PRGA_AXI4_AXPROT_WIDTH          3   // not supported
`define PRGA_AXI4_AXPROT_PRVL_INDEX     0   // privilidged access bit:  not supported
`define PRGA_AXI4_AXPROT_NSCR_INDEX     1   // non-secure access bit:   not supported
`define PRGA_AXI4_AXPROT_INST_INDEX     2   // instruction access bit:  not supported

`define PRGA_AXI4_AXQOS_WIDTH           4   // not supported

`endif /* `ifndef PRGA_AXI4_VH */