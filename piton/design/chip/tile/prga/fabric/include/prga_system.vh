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

`ifndef PRGA_SYSTEM_VH
`define PRGA_SYSTEM_VH

`define PRGA_ECC_WIDTH                  1

`define PRGA_CREG_ADDR_WIDTH            12
`define PRGA_CREG_DATA_WIDTH            64
`define PRGA_CREG_DATA_BYTES            8

// CREG Adresses:                       address,                    alignment,  actual data size
`define PRGA_CREG_ADDR_BITSTREAM_ID     `PRGA_CREG_ADDR_WIDTH'h800  //  64b     64b
`define PRGA_CREG_ADDR_EFLAGS           `PRGA_CREG_ADDR_WIDTH'h808  //  64b     64b
`define PRGA_CREG_ADDR_ACLK_DIV         `PRGA_CREG_ADDR_WIDTH'h810  //  64b     `PRGA_CLKDIV_WIDTH
`define PRGA_CREG_ADDR_PROG_STATUS      `PRGA_CREG_ADDR_WIDTH'h818  //  64b     `PRGA_PROG_STATUS_WIDTH
`define PRGA_CREG_ADDR_APP_FEATURES     `PRGA_CREG_ADDR_WIDTH'h820  //  64b     64b
`define PRGA_CREG_ADDR_RTC_COUNTDOWN    `PRGA_CREG_ADDR_WIDTH'hF00  //  64b     64b

`define PRGA_CREG_ADDR_APP_RST          `PRGA_CREG_ADDR_WIDTH'hC00  //  64b     `PRGA_PROT_TIMER_WIDTH
`define PRGA_CREG_ADDR_TIMEOUT          `PRGA_CREG_ADDR_WIDTH'hC08  //  64b     `PRGA_PROT_TIMER_WIDTH

// Error Flags
`define PRGA_EFLAGS_CCM_ECC                 0
`define PRGA_EFLAGS_CCM_TIMEOUT             1
`define PRGA_EFLAGS_CCM_INVAL_REQ           2
`define PRGA_EFLAGS_CCM_INVAL_SIZE          3
`define PRGA_EFLAGS_CCM_INVAL_AMO_OPCODE    4
`define PRGA_EFLAGS_CCM_ILLEGAL_NC_REQ      5
`define PRGA_EFLAGS_CCM_ILLEGAL_AMO_REQ     6
`define PRGA_EFLAGS_CCM_ILLEGAL_MT_REQ      7   // illegal multi-thread request
`define PRGA_EFLAGS_CCM_INVAL_AXI4_TRX      8   // illegal AXI4 transaction
`define PRGA_EFLAGS_UREG_ECC                16
`define PRGA_EFLAGS_UREG_TIMEOUT            17
`define PRGA_EFLAGS_PROG_REG_UNDEF          24

`define PRGA_CLKDIV_WIDTH               8                           // limit to 1/512 system clock freq

`define PRGA_PROT_TIMER_WIDTH           32

// APP Feature vector
`define PRGA_APP_UREG_EN_INDEX          0

`define PRGA_APP_UREG_DWIDTH_WIDTH      2
`define PRGA_APP_UREG_DWIDTH_INDEX      `PRGA_APP_UREG_EN_INDEX+1+:`PRGA_APP_UREG_DWIDTH_WIDTH
`define PRGA_APP_UREG_DWIDTH_8B         `PRGA_APP_UREG_DWIDTH_WIDTH'h0
`define PRGA_APP_UREG_DWIDTH_4B         `PRGA_APP_UREG_DWIDTH_WIDTH'h1
`define PRGA_APP_UREG_DWIDTH_2B         `PRGA_APP_UREG_DWIDTH_WIDTH'h2
`define PRGA_APP_UREG_DWIDTH_1B         `PRGA_APP_UREG_DWIDTH_WIDTH'h3

`define PRGA_APP_CCM_EN_INDEX           32
`define PRGA_APP_CCM_NC_EN_INDEX        33
`define PRGA_APP_CCM_ATOMIC_EN_INDEX    34
`define PRGA_APP_CCM_L1CACHE_EN_INDEX   35
`define PRGA_APP_CCM_MTHREAD_EN_INDEX   36

`define PRGA_PROG_STATUS_WIDTH          2
`define PRGA_PROG_STATUS_STANDBY        `PRGA_PROG_STATUS_WIDTH'h0
`define PRGA_PROG_STATUS_PROGRAMMING    `PRGA_PROG_STATUS_WIDTH'h1
`define PRGA_PROG_STATUS_DONE           `PRGA_PROG_STATUS_WIDTH'h2
`define PRGA_PROG_STATUS_ERR            `PRGA_PROG_STATUS_WIDTH'h3

`define PRGA_CCM_ADDR_WIDTH             40
`define PRGA_CCM_DATA_BYTES             8
`define PRGA_CCM_DATA_WIDTH             64
`define PRGA_CCM_CACHELINE_WIDTH        128
`define PRGA_CCM_ECC_WIDTH              1

`define PRGA_CCM_SIZE_WIDTH             3
`define PRGA_CCM_SIZE_1B                `PRGA_CCM_SIZE_WIDTH'b001
`define PRGA_CCM_SIZE_2B                `PRGA_CCM_SIZE_WIDTH'b010
`define PRGA_CCM_SIZE_4B                `PRGA_CCM_SIZE_WIDTH'b011
`define PRGA_CCM_SIZE_8B                `PRGA_CCM_SIZE_WIDTH'b100
`define PRGA_CCM_SIZE_CACHELINE         `PRGA_CCM_SIZE_WIDTH'b111   // only used for cacheable load

`define PRGA_CCM_THREADID_WIDTH         1                           // 2 threads
`define PRGA_CCM_THREAD_COUNT           (1 << `PRGA_CCM_THREADID_WIDTH)

`define PRGA_CCM_REQTYPE_WIDTH          3
`define PRGA_CCM_REQTYPE_LOAD           `PRGA_CCM_REQTYPE_WIDTH'h0
`define PRGA_CCM_REQTYPE_STORE          `PRGA_CCM_REQTYPE_WIDTH'h1
`define PRGA_CCM_REQTYPE_LOAD_NC        `PRGA_CCM_REQTYPE_WIDTH'h2
`define PRGA_CCM_REQTYPE_STORE_NC       `PRGA_CCM_REQTYPE_WIDTH'h3
`define PRGA_CCM_REQTYPE_AMO            `PRGA_CCM_REQTYPE_WIDTH'h4

`define PRGA_CCM_RESPTYPE_WIDTH         3
`define PRGA_CCM_RESPTYPE_LOAD_ACK      `PRGA_CCM_RESPTYPE_WIDTH'h0
`define PRGA_CCM_RESPTYPE_STORE_ACK     `PRGA_CCM_RESPTYPE_WIDTH'h1
`define PRGA_CCM_RESPTYPE_LOAD_NC_ACK   `PRGA_CCM_RESPTYPE_WIDTH'h2
`define PRGA_CCM_RESPTYPE_STORE_NC_ACK  `PRGA_CCM_RESPTYPE_WIDTH'h3
`define PRGA_CCM_RESPTYPE_AMO_ACK       `PRGA_CCM_RESPTYPE_WIDTH'h4

`define PRGA_CCM_AMO_OPCODE_WIDTH       4
`define PRGA_CCM_AMO_OPCODE_NONE        4'b0000
`define PRGA_CCM_AMO_OPCODE_LR          4'b0001
`define PRGA_CCM_AMO_OPCODE_SC          4'b0010
`define PRGA_CCM_AMO_OPCODE_SWAP        4'b0011
`define PRGA_CCM_AMO_OPCODE_ADD         4'b0100
`define PRGA_CCM_AMO_OPCODE_AND         4'b0101
`define PRGA_CCM_AMO_OPCODE_OR          4'b0110
`define PRGA_CCM_AMO_OPCODE_XOR         4'b0111
`define PRGA_CCM_AMO_OPCODE_MAX         4'b1000
`define PRGA_CCM_AMO_OPCODE_MAXU        4'b1001
`define PRGA_CCM_AMO_OPCODE_MIN         4'b1010
`define PRGA_CCM_AMO_OPCODE_MINU        4'b1011
`define PRGA_CCM_AMO_OPCODE_CAS1        4'b1100
`define PRGA_CCM_AMO_OPCODE_CAS2        4'b1101

`define PRGA_CCM_CACHETAG_HIGH          10
`define PRGA_CCM_CACHETAG_LOW           4
`define PRGA_CCM_CACHETAG_INDEX         `PRGA_CCM_CACHETAG_HIGH:`PRGA_CCM_CACHETAG_LOW

/* System-Application Clock-Domain Crossing Interconnect */
`define PRGA_SAX_DATA_WIDTH             144
`define PRGA_ASX_DATA_WIDTH             128

    /* SAX Messages
    *
    *   CCM Load/Store ACK Messages
    *
    *     143   138    137   136  134 133 128 127                           0 
    *    +---------+--------+--------+-------+-------------------------------+
    *    | msgtype | thread |  size  |   -   |             data              |
    *    +---------+--------+--------+-------+-------------------------------+
    *
    *   CREG/UREG Read/Write Messages
    *
    *     143   138 137                           112 83  76 75     64 63   0 
    *    +---------+---------------------------------+------+---------+------+
    *    | msgtype |                ---              | strb | address | data |
    *    +---------+---------------------------------+------+---------+------+
    *
    */

`define PRGA_SAX_MSGTYPE_WIDTH          6
`define PRGA_SAX_MSGTYPE_INDEX          143:138

`define PRGA_SAX_MSGTYPE_CCM_LOAD_ACK           `PRGA_SAX_MSGTYPE_WIDTH'h00
`define PRGA_SAX_MSGTYPE_CCM_LOAD_NC_ACK        `PRGA_SAX_MSGTYPE_WIDTH'h01
`define PRGA_SAX_MSGTYPE_CCM_STORE_ACK          `PRGA_SAX_MSGTYPE_WIDTH'h02
`define PRGA_SAX_MSGTYPE_CCM_STORE_NC_ACK       `PRGA_SAX_MSGTYPE_WIDTH'h03
`define PRGA_SAX_MSGTYPE_CCM_AMO_ACK            `PRGA_SAX_MSGTYPE_WIDTH'h04
`define PRGA_SAX_MSGTYPE_CREG_READ              `PRGA_SAX_MSGTYPE_WIDTH'h20
`define PRGA_SAX_MSGTYPE_CREG_WRITE             `PRGA_SAX_MSGTYPE_WIDTH'h21

`define PRGA_SAX_THREADID_INDEX         137
`define PRGA_SAX_SIZE_INDEX             136:134

`define PRGA_SAX_CREG_DATA_INDEX        63:0
`define PRGA_SAX_CREG_ADDR_HIGH         75
`define PRGA_SAX_CREG_ADDR_INDEX        75:64
`define PRGA_SAX_CREG_STRB_INDEX        83:76
    
    /* ASX Messages
    *
    *   CCM Load/Store Messages
    *
    *     127   122   121    120  118 117  114 113 104 103    64 63     0 
    *    +---------+--------+--------+--------+-------+---------+--------+
    *    | msgtype | thread |  size  | amo op |   -   | address |  data  |
    *    +---------+--------+--------+--------+-------+---------+--------+
    *
    *   CREG/UREG Messages
    *
    *     127   122 121                                       64 63     0  
    *    +---------+--------------------------------------------+--------+
    *    | msgtype |                     ---                    |  data  |
    *    +---------+--------------------------------------------+--------+
    *
    *   Error Messages
    *
    *     127   122 121                                       64 63     0 
    *    +---------+--------------------------------------------+--------+
    *    | msgtype |                     ---                    | eflags |
    *    +---------+--------------------------------------------+--------+
    */

`define PRGA_ASX_MSGTYPE_WIDTH          6
`define PRGA_ASX_MSGTYPE_INDEX          127:122

`define PRGA_ASX_MSGTYPE_CCM_LOAD               `PRGA_ASX_MSGTYPE_WIDTH'h00
`define PRGA_ASX_MSGTYPE_CCM_LOAD_NC            `PRGA_ASX_MSGTYPE_WIDTH'h01
`define PRGA_ASX_MSGTYPE_CCM_STORE              `PRGA_ASX_MSGTYPE_WIDTH'h02
`define PRGA_ASX_MSGTYPE_CCM_STORE_NC           `PRGA_ASX_MSGTYPE_WIDTH'h03
`define PRGA_ASX_MSGTYPE_CCM_AMO                `PRGA_ASX_MSGTYPE_WIDTH'h04
`define PRGA_ASX_MSGTYPE_CREG_READ_ACK          `PRGA_ASX_MSGTYPE_WIDTH'h10
`define PRGA_ASX_MSGTYPE_CREG_WRITE_ACK         `PRGA_ASX_MSGTYPE_WIDTH'h11
`define PRGA_ASX_MSGTYPE_ERR                    `PRGA_ASX_MSGTYPE_WIDTH'h3F

`define PRGA_ASX_THREADID_INDEX         121
`define PRGA_ASX_SIZE_INDEX             120:118
`define PRGA_ASX_AMO_OPCODE_INDEX       117:114
    
`endif /* PRGA_SYSTEM_VH */