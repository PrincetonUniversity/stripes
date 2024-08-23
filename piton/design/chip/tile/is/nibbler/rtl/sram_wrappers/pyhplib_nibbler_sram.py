# Copyright (c) 2024 Princeton University
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holder nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from pyhplib import *

def Get2RW1Header():
  return '''
`include "define.tmp.h"
`ifdef DEFAULT_NETTYPE_NONE
`default_nettype none
`endif
module _PARAMS_NAME
(
input wire MEMCLK,
input wire RESET_N,
input wire CEA,
input wire [_PARAMS_HEIGHT_LOG-1:0] AA,
input wire CEB,
input wire [_PARAMS_HEIGHT_LOG-1:0] AB,
output wire [_PARAMS_WIDTH-1:0] DOUTA,
output wire [_PARAMS_WIDTH-1:0] DOUTB,
input wire CEW,
input wire [_PARAMS_HEIGHT_LOG-1:0] AW,
input wire [_PARAMS_WIDTH-1:0] BW,
input wire [_PARAMS_WIDTH-1:0] DIN,

input wire [`BIST_OP_WIDTH-1:0] BIST_COMMAND,
input wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DIN,
output reg [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT,
input wire [`BIST_ID_WIDTH-1:0] SRAMID
);
  '''

def Get2R1WCache():
  return '''
reg [_PARAMS_WIDTH-1:0] cache [_PARAMS_HEIGHT-1:0];

integer i;
initial
begin
   for (i = 0; i < _PARAMS_HEIGHT; i = i + 1)
   begin
      cache[i] = 0;
   end
end

   reg [_PARAMS_WIDTH-1:0] dout_f0;
   assign DOUTA = dout_f0;
   always @ (posedge MEMCLK)
   begin
      if (CEA)
      begin
        dout_f0 <= cache[AA];
      end
   end

   reg [_PARAMS_WIDTH-1:0] dout_f1;
   assign DOUTB = dout_f1;
   always @ (posedge MEMCLK)
   begin
      if (CEB)
      begin
        dout_f1 <= cache[AB];
      end
   end


   always @ (posedge MEMCLK)
   begin
      if (CEW)
      begin
        cache[AW] <= (DIN & BW) | (cache[AW] & ~BW);
      end
   end
  '''


def Make2R1WDefine(modulename, height_define, heightlog2_define, width_define):
  t = Get2R1WHeader()
  t = t.replace("_PARAMS_HEIGHT_LOG", heightlog2_define)
  t = t.replace("_PARAMS_HEIGHT", height_define)
  t = t.replace("_PARAMS_WIDTH", width_define))
  t = t.replace("_PARAMS_NAME", modulename)
  print(t)
  t = Get2R1WCache()
  t = t.replace("_PARAMS_HEIGHT_LOG", heightlog2_define)
  t = t.replace("_PARAMS_HEIGHT", height_define)
  t = t.replace("_PARAMS_WIDTH", width_define))
  t = t.replace("_PARAMS_NAME", modulename)
  print(t)
  print(" \n\n endmodule")

