/*
Copyright (c) 2019 Princeton University
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
`include "define.tmp.h"
`include "iop.h"

`ifndef DREAM_H
`define DREAM_H

`define LITTLE_ENDIAN 1
`define DCP_DREAM 1

// Operation codes
`define DREAM_OPCODE_WIDTH 4

`define DREAM_LOAD_OP      4'd0
`define DREAM_STAT_OP      4'd1
`define DREAM_COPY_OP      4'd2
`define DREAM_AOS_SOA_OP   4'd3
`define DREAM_SOA_AOS_OP   4'd4

`define DREAM_CONFIG_PKT 8:3
`define DREAM_CONFIG_WIDTH 6
`define DREAM_CONFIG_OP 6'd0
`define DREAM_CONFIG_SRC_ADDR 6'd1
`define DREAM_CONFIG_DEST_ADDR 6'd2
`define DREAM_CONFIG_COPY_SIZE 6'd3

`define NUM_FIELD 6'd4   
`define FIELD_SIZE_0 6'd5    
`define FIELD_SIZE_1 6'd6 
`define NUM_ELEMENT 6'd7
`define DREAM_DONE 6'd8
`define DREAM_STOP 6'd9
`define NUM_ELEMENT_BIT 6'd10
`define STRUCTURE_SIZE 6'd11

`define DREAM_CONFIG_ELEMENT_CNT 6'd3

`define DREAM_MAX_COPY_SIZE_BIT 17
`define DREAM_PADDR_MASK 39:0
`define DREAM_PADDR_HI 40

`define DREAM_CONFIG_DATA_WIDTH 64

// Msg Type codes
`define DREAM_REQ_LOAD       `MSG_TYPE_NC_LOAD_REQ
`define DREAM_REQ_LOAD_ACK   `MSG_TYPE_NC_LOAD_MEM_ACK
`define DREAM_REQ_STORE      `MSG_TYPE_NC_STORE_REQ
`define DREAM_REQ_STORE_ACK  `MSG_TYPE_NC_STORE_MEM_ACK
`define DREAM_RES_NOC2       `MSG_TYPE_DATA_ACK

// Miss buffer structure
`define DREAM_MB_SIZE_BITS   6
`define DREAM_MB_SIZE        64
`define DREAM_MB_DATA_BITS   64
`define DREAM_MB_BASE        8'd145 
`define DREAM_MB_LD_BASE        8'd145 
`define DREAM_MB_ST_BASE        8'd192 
`define DREAM_MB_LD_MSHR_SIZE   6'd47

`define DREAM_MAX_FIELD_SIZE       8'd64
`define DREAM_MAX_FIELD_SIZE_BIT   8
`define DREAM_MAX_FIELD_DATA_SIZE  17'h10000
`define DREAM_MAX_FIELD_DATA_SIZE_BIT   17
`define DREAM_MAX_NUM_FIELD        5'd16
`define DREAM_MAX_NUM_FIELD_BIT    5
`define DREAM_MAX_ELEMENT_SIZE     11'h400
`define DREAM_MAX_ELEMENT_SIZE_BIT 11
`define DREAM_MAX_ELEMENT_LINE     5'h10
`define DREAM_MAX_ELEMENT_LINE_BIT 5
`define DREAM_MAX_NUM_ELEMENT      11'h400
`define DREAM_MAX_NUM_ELEMENT_BIT  11
`define DREAM_MAX_DATA_SIZE        21'h100000
`define DREAM_MAX_DATA_SIZE_BIT    21
`define DREAM_MAX_LOAD_CNT         15'h4000
`define DREAM_MAX_LOAD_CNT_BIT     15
`define DREAM_MAX_STORE_CNT        17'h10000
`define DREAM_MAX_STORE_CNT_BIT    17


`define DREAM_LINE_BYTE            7'd64
`define DREAM_LINE_BYTE_BIT        7
`define DREAM_LINE_BIT             512
`define DREAM_LINE_BIT_HI          9

`define DREAM_PADDR_WIDTH 40

`define DREAM_BUFFER_DATA_WIDTH 512
`define DREAM_BUFFER_ENTRY 16
`define DREAM_NOC1_DATA_WIDTH   128

`endif

