// ========== Copyright Header Begin ============================================
// Copyright (c) 2019 Princeton University
// All rights reserved.
// 
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
// 
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
// ========== Copyright Header End ============================================

`include "define.tmp.h"
`ifdef DEFAULT_NETTYPE_NONE
`default_nettype none
`endif

module scratchpad
(
    input  wire MEMCLK,
    input  wire RESET_N,
    // input  wire CE,
    input  wire [16-1:0]  DREAM_A,
    input  wire           DREAM_RDWEN,
    input  wire [512-1:0] DREAM_BW,
    input  wire [512-1:0] DREAM_DIN,
    output wire [512-1:0] DREAM_DOUT,
    input  wire [16-1:0]  NIBBLER_A,
    input  wire           NIBBLER_RDWEN,
    input  wire [512-1:0] NIBBLER_BW,
    input  wire [512-1:0] NIBBLER_DIN,
    output wire [512-1:0] NIBBLER_DOUT,
    input  wire [`BIST_OP_WIDTH-1:0] BIST_COMMAND,
    input  wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DIN,
    output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT_0,
    output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT_1,
    output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT_2,
    output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT_3,
    input  wire [`BIST_ID_WIDTH-1:0] SRAMID,

    input  wire dream_sp_val,
    input  wire nibbler_sp_val,
    output wire dream_sp_rdy,
    output wire nibbler_sp_rdy
);

assign dream_sp_rdy = (dream_sp_val) ? 1'b1 : 1'b0;
assign nibbler_sp_rdy = (dream_sp_val) ? 1'b0 : 1'b1;

wire dream_sp_hsk = dream_sp_rdy && dream_sp_val;
wire nibbler_sp_hsk = nibbler_sp_rdy && nibbler_sp_val;

// Arbitrate between Dream and Nibbler
wire [15:0]  A     = dream_sp_val ? DREAM_A : NIBBLER_A;
wire         RDWEN = dream_sp_val ? DREAM_RDWEN : NIBBLER_RDWEN;
wire [511:0] BW    = dream_sp_val ? DREAM_BW : NIBBLER_BW;
wire [511:0] DIN   = dream_sp_val ? DREAM_DIN : NIBBLER_DIN;

wire [511:0] DOUT;
assign DREAM_DOUT = DOUT;
assign NIBBLER_DOUT = DOUT;

// no BW for READ
wire [9:0] sp_sram_addr = A >> 6;

wire device_hsk = dream_sp_hsk || nibbler_sp_hsk;
wire read_val = device_hsk && RDWEN;
wire write_val = device_hsk && !RDWEN;
wire sram_ce_0 = (|BW[127:0]   && write_val) || read_val;
wire sram_ce_1 = (|BW[255:128] && write_val) || read_val;
wire sram_ce_2 = (|BW[383:256] && write_val) || read_val;
wire sram_ce_3 = (|BW[511:384] && write_val) || read_val;
 
sp_sram sp_sram_array_0 (
    .MEMCLK         (MEMCLK         ),
    .RESET_N        (RESET_N        ),
    .CE             (sram_ce_0      ),
    .A              (sp_sram_addr   ),
    .RDWEN          (RDWEN          ),
    .BW             (BW[127:0]      ),
    .DIN            (DIN[127:0]     ),
    .DOUT           (DOUT[127:0]    ),
    .BIST_COMMAND   (BIST_COMMAND   ),
    .BIST_DIN       (BIST_DIN       ),
    .BIST_DOUT      (BIST_DOUT_0    ),
    .SRAMID         (SRAMID         )
);

sp_sram sp_sram_array_1 (
    .MEMCLK         (MEMCLK         ),
    .RESET_N        (RESET_N        ),
    .CE             (sram_ce_1      ),
    .A              (sp_sram_addr   ),
    .RDWEN          (RDWEN          ),
    .BW             (BW[255:128]    ),
    .DIN            (DIN[255:128]   ),
    .DOUT           (DOUT[255:128]  ),
    .BIST_COMMAND   (BIST_COMMAND   ),
    .BIST_DIN       (BIST_DIN       ),
    .BIST_DOUT      (BIST_DOUT_1    ),
    .SRAMID         (SRAMID         )
);

sp_sram sp_sram_array_2 (
    .MEMCLK         (MEMCLK         ),
    .RESET_N        (RESET_N        ),
    .CE             (sram_ce_2      ),
    .A              (sp_sram_addr   ),
    .RDWEN          (RDWEN          ),
    .BW             (BW[383:256]    ),
    .DIN            (DIN[383:256]   ),
    .DOUT           (DOUT[383:256]  ),
    .BIST_COMMAND   (BIST_COMMAND   ),
    .BIST_DIN       (BIST_DIN       ),
    .BIST_DOUT      (BIST_DOUT_2    ),
    .SRAMID         (SRAMID         )
);

sp_sram sp_sram_array_3 (
    .MEMCLK         (MEMCLK         ),
    .RESET_N        (RESET_N        ),
    .CE             (sram_ce_3      ),
    .A              (sp_sram_addr   ),
    .RDWEN          (RDWEN          ),
    .BW             (BW[511:384]    ),
    .DIN            (DIN[511:384]   ),
    .DOUT           (DOUT[511:384]  ),
    .BIST_COMMAND   (BIST_COMMAND   ),
    .BIST_DIN       (BIST_DIN       ),
    .BIST_DOUT      (BIST_DOUT_3    ),
    .SRAMID         (SRAMID         )
);


endmodule