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

// Automatically generated by PRGA's RTL generator
`ifndef PRGA_PKTCHAIN_H
`define PRGA_PKTCHAIN_H

`include "prga_utils.vh"

`define PRGA_PKTCHAIN_FRAME_SIZE_LOG2 5
`define PRGA_PKTCHAIN_PHIT_WIDTH_LOG2 3
`define PRGA_PKTCHAIN_CHAIN_WIDTH_LOG2 0

`define PRGA_PKTCHAIN_FRAME_SIZE (1 << `PRGA_PKTCHAIN_FRAME_SIZE_LOG2)
`define PRGA_PKTCHAIN_PHIT_WIDTH (1 << `PRGA_PKTCHAIN_PHIT_WIDTH_LOG2)
`define PRGA_PKTCHAIN_CHAIN_WIDTH (1 << `PRGA_PKTCHAIN_CHAIN_WIDTH_LOG2)

`define PRGA_PKTCHAIN_LOG2_PHITS_PER_FRAME (`PRGA_PKTCHAIN_FRAME_SIZE_LOG2 - `PRGA_PKTCHAIN_PHIT_WIDTH_LOG2)
`define PRGA_PKTCHAIN_NUM_PHITS_PER_FRAME (1 << `PRGA_PKTCHAIN_LOG2_PHITS_PER_FRAME)

`define PRGA_PKTCHAIN_LOG2_CHAINS_PER_FRAME (`PRGA_PKTCHAIN_FRAME_SIZE_LOG2 - `PRGA_PKTCHAIN_CHAIN_WIDTH_LOG2)
`define PRGA_PKTCHAIN_NUM_CHAINS_PER_FRAME (1 << `PRGA_PKTCHAIN_LOG2_CHAINS_PER_FRAME)

`define PRGA_PKTCHAIN_MSG_TYPE_WIDTH 8
`define PRGA_PKTCHAIN_CHAIN_ID_WIDTH 8
`define PRGA_PKTCHAIN_PAYLOAD_WIDTH 8

`define PRGA_PKTCHAIN_PAYLOAD_BASE 0
`define PRGA_PKTCHAIN_LEAF_ID_BASE (`PRGA_PKTCHAIN_PAYLOAD_BASE + `PRGA_PKTCHAIN_PAYLOAD_WIDTH)
`define PRGA_PKTCHAIN_BRANCH_ID_BASE (`PRGA_PKTCHAIN_LEAF_ID_BASE + `PRGA_PKTCHAIN_CHAIN_ID_WIDTH)
`define PRGA_PKTCHAIN_MSG_TYPE_BASE (`PRGA_PKTCHAIN_BRANCH_ID_BASE + `PRGA_PKTCHAIN_CHAIN_ID_WIDTH)

`define PRGA_PKTCHAIN_PAYLOAD_INDEX `PRGA_PKTCHAIN_PAYLOAD_BASE+:`PRGA_PKTCHAIN_PAYLOAD_WIDTH
`define PRGA_PKTCHAIN_LEAF_ID_INDEX `PRGA_PKTCHAIN_LEAF_ID_BASE+:`PRGA_PKTCHAIN_CHAIN_ID_WIDTH
`define PRGA_PKTCHAIN_BRANCH_ID_INDEX `PRGA_PKTCHAIN_BRANCH_ID_BASE+:`PRGA_PKTCHAIN_CHAIN_ID_WIDTH
`define PRGA_PKTCHAIN_MSG_TYPE_INDEX `PRGA_PKTCHAIN_MSG_TYPE_BASE+:`PRGA_PKTCHAIN_MSG_TYPE_WIDTH 

// Message types
// -- BEGIN AUTO-GENERATION (see prga.prog.pktchain.protocol for more info)
`define PRGA_PKTCHAIN_MSG_TYPE_SOB `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h01
`define PRGA_PKTCHAIN_MSG_TYPE_EOB `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h02
`define PRGA_PKTCHAIN_MSG_TYPE_TEST `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h20
`define PRGA_PKTCHAIN_MSG_TYPE_DATA `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h40
`define PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h41
`define PRGA_PKTCHAIN_MSG_TYPE_DATA_CHECKSUM `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h42
`define PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT_CHECKSUM `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h43
`define PRGA_PKTCHAIN_MSG_TYPE_DATA_ACK `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h80
`define PRGA_PKTCHAIN_MSG_TYPE_ERROR_UNKNOWN_MSG_TYPE `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h81
`define PRGA_PKTCHAIN_MSG_TYPE_ERROR_ECHO_MISMATCH `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h82
`define PRGA_PKTCHAIN_MSG_TYPE_ERROR_CHECKSUM_MISMATCH `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h83
`define PRGA_PKTCHAIN_MSG_TYPE_ERROR_FEEDTHRU_PACKET `PRGA_PKTCHAIN_MSG_TYPE_WIDTH'h84
// -- DONE AUTO-GENERATION

// Fabric-specific
`define PRGA_PKTCHAIN_NUM_BRANCHES              2
`define PRGA_PKTCHAIN_NUM_LEAVES                8
`define PRGA_PKTCHAIN_ROUTER_FIFO_DEPTH_LOG2    7

`endif