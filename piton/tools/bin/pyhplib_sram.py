# Copyright (c) 2018 Princeton University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Princeton University nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

def MakeGenericCacheHeader(modulename, type, height_define, heightlog2_define, width_define):
   if type == "1rw":
      t = Get1RWHeader()
   elif type == "1r1w":
      t = Get1R1WHeader()
   elif type == "2rw":
      t = Get2RWHeader()
   elif type == "2r1w":
      t = Get2R1WHeader()
   else:
      assert(0)

   t = t.replace("_PARAMS_HEIGHT_LOG", heightlog2_define)
   t = t.replace("_PARAMS_HEIGHT", height_define)
   t = t.replace("_PARAMS_WIDTH", width_define)
   t = t.replace("_PARAMS_NAME", str(modulename))
   print(t)

   # if type == "1rw":
   #    t = Get1RWCache()
   # elif type == "1r1w":
   #    t = Get1R1WCache()
   # elif type == "2rw":
   #    t = Get2RWCache()
   # else:
   #    assert(0)

   # t = t.replace("_PARAMS_HEIGHT_LOG", heightlog2_define)
   # t = t.replace("_PARAMS_HEIGHT", height_define)
   # t = t.replace("_PARAMS_WIDTH", width_define)
   # t = t.replace("_PARAMS_NAME", str(modulename))
   # print(t)


def MakeGenericCache(modulename, type, height_define, heightlog2_define, width_define):
   if type == "1rw":
      t = Get1RWCache()
   elif type == "1r1w":
      t = Get2RWCache()
   elif type == "2rw":
      t = Get2RWCache()
   elif type == "2r1w":
      t = Get2R1WCache()
   else:
      assert(0)

   t = t.replace("_PARAMS_HEIGHT_LOG", heightlog2_define)
   t = t.replace("_PARAMS_HEIGHT", height_define)
   t = t.replace("_PARAMS_WIDTH", width_define)
   t = t.replace("_PARAMS_NAME", str(modulename))
   print(t)


def MakeSynthesizableBram(modulename, type, height_define, heightlog2_define, width_define):
   if type == "1rw":
      t = '''
bram_1rw_wrapper #(
   .NAME          (""             ),
   .DEPTH         (%s),
   .ADDR_WIDTH    (%s),
   .BITMASK_WIDTH (%s),
   .DATA_WIDTH    (%s)
)   %s (
   .MEMCLK        (MEMCLK     ),
   .RESET_N       (RESET_N     ),
   .CE            (CE_mux         ),
   .A             (A_mux          ),
   .RDWEN         (RDWEN_mux      ),
   .BW            (BW_mux         ),
   .DIN           (DIN_mux        ),
   .DOUT          (DOUT_bram       )
);
      ''' % (height_define, heightlog2_define, width_define, width_define, modulename)

   elif type == "1r1w":
      t = '''
bram_1r1w_wrapper #(
   .NAME          (""             ),
   .DEPTH         (%s),
   .ADDR_WIDTH    (%s),
   .BITMASK_WIDTH (%s),
   .DATA_WIDTH    (%s)
)   %s (
   .MEMCLK        (MEMCLK     ),
   .RESET_N       (RESET_N     ),
   .CEA           (CEA_mux     ),
   .AA            (AA_mux     ),
   .AB            (AB_mux     ),
   .RDWENA        (RDWENA_mux     ),
   .CEB           (CEB_mux     ),
   .RDWENB        (RDWENB_mux     ),
   .BWA           (BWA_mux     ),
   .DINA          (DINA        ),
   .DOUTA         (DOUTA_bram     ),
   .BWB           (BWB_mux     ),
   .DINB          (DINB_mux     ),
   .DOUTB         (DOUTB_bram     )
);
      ''' % (height_define, heightlog2_define, width_define, width_define, modulename)

   elif type == "2rw":
      assert(0) # unimplemented

   elif type == "2r1w":
      t='''
      // WARNING: BRAMs not implemented for 2R1W
      assign DOUTA_bram=%s'b1;
      assign DOUTB_bram=%s'b0;''' %(width_define, width_define) #assert(0) # unimplemented

   print(t)

def MakeGenericCacheDefine(modulename, type, height_define, heightlog2_define, width_define):
  MakeGenericCacheHeader(modulename, type, height_define, heightlog2_define, width_define)
  print("localparam RAM_SIZE = %s;" % width_define)
  print("localparam RAM_ADDR = %s;" % heightlog2_define)
  print("`ifdef SYNTHESIZABLE_BRAM")
  if type == "1rw":
     print("wire [%s-1:0] DOUT_bram;" % width_define)
     print("assign DOUT = DOUT_bram;")
     print(makeMux())

  else:
     if type != "2r1w":
       print(makeMux1r1w())
     print("wire [%s-1:0] DOUTA_bram;" % width_define)
     print("wire [%s-1:0] DOUTB_bram;" % width_define)
     print("assign DOUTA = DOUTA_bram;")
     print("assign DOUTB = DOUTB_bram;")
  MakeSynthesizableBram(modulename, type, height_define, heightlog2_define, width_define)
  print("`else")
  MakeGenericCache(modulename, type, height_define, heightlog2_define, width_define)
  print("`endif\n")
  print("endmodule\n")

# def MakeGenericCacheDefine(modulename, type, height_define, heightlog2_define, width_define):
#   MakeGenericCacheHeader(modulename, type, height_define, heightlog2_define, width_define)

#   if type == "1rw":
#      print("wire [%s-1:0] DOUT_bram;" % width_define)
#   else:
#      print("wire [%s-1:0] DOUTA_bram;" % width_define)
#      print("wire [%s-1:0] DOUTB_bram;" % width_define)
#   MakeSynthesizableBram(modulename, type, height_define, heightlog2_define, width_define)

#   MakeGenericCache(modulename, type, height_define, heightlog2_define, width_define)

#   if type == "1rw":
#      print('''
#          // comparing correctness
#          always @ (negedge MEMCLK) begin
#             if (DOUT_bram != DOUT) begin
#                $display("Mismatch %s");
#                repeat(5)@(posedge MEMCLK);
#                `MONITOR_PATH.fail("Mismatch L2 state");
#             end
#          end
#       ''' % modulename)
#   else:
#      print('''
#          // comparing correctness
#          always @ (negedge MEMCLK) begin
#             if (DOUTA_bram != DOUTA || DOUTB_bram != DOUTB) begin
#                $display("Mismatch %s");
#                repeat(5)@(posedge MEMCLK);
#                `MONITOR_PATH.fail("Mismatch L2 state");
#             end
#          end
#       ''' % modulename)
#   print("endmodule")

def makeMux():
   return '''
   wire CE_mux = 1'b0 || CE;
   wire [RAM_ADDR-1:0] A_mux = CE ? A : 0;
   wire RDWEN_mux = CE ? RDWEN : 0;
   wire [RAM_SIZE-1:0] BW_mux = CE ? BW : 0;
   wire [RAM_SIZE-1:0] DIN_mux = CE ? DIN : 0;
'''

def makeMux1r1w():
   return '''
   wire CEA_mux = (1'b0 && 0) || CEA;
   wire CEB_mux = (1'b0 && !0) || CEB;
   wire [RAM_ADDR-1:0] AA_mux = CEA ? AA : 0;
   wire [RAM_ADDR-1:0] AB_mux = CEB ? AB : 0;
   wire RDWENA_mux = CEA ? RDWENA : 0;
   wire RDWENB_mux = CEB ? RDWENB : 0;
   wire [RAM_SIZE-1:0] BWA_mux = CEA ? BWA : 0;
   wire [RAM_SIZE-1:0] BWB_mux = CEB ? BWB : 0;
   wire [RAM_SIZE-1:0] DINB_mux = CEB ? DINB : 0;
   wire [RAM_SIZE-1:0] DOUT = DOUTA;
'''

def Get1RWHeader():
  return '''
`include "define.tmp.h"
`ifdef DEFAULT_NETTYPE_NONE
`default_nettype none
`endif
module _PARAMS_NAME
(
input wire MEMCLK,
input wire RESET_N,
input wire CE,
input wire [_PARAMS_HEIGHT_LOG-1:0] A,
input wire RDWEN,
input wire [_PARAMS_WIDTH-1:0] BW,
input wire [_PARAMS_WIDTH-1:0] DIN,
output wire [_PARAMS_WIDTH-1:0] DOUT,
input wire [`BIST_OP_WIDTH-1:0] BIST_COMMAND,
input wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DIN,
output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT,
input wire [`BIST_ID_WIDTH-1:0] SRAMID
);
'''


def Get1RWCache():
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

   reg [_PARAMS_WIDTH-1:0] dout_f;

   assign DOUT = dout_f;

   always @ (posedge MEMCLK)
   begin
      if (CE)
      begin
         if (RDWEN == 1'b0)
            cache[A] <= (DIN & BW) | (cache[A] & ~BW);
         else
            dout_f <= cache[A];
      end
   end
'''

def Get2RWHeader():
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
input wire RDWENA,
input wire CEB,
input wire [_PARAMS_HEIGHT_LOG-1:0] AB,
input wire RDWENB,
input wire [_PARAMS_WIDTH-1:0] BWA,
input wire [_PARAMS_WIDTH-1:0] DINA,
output wire [_PARAMS_WIDTH-1:0] DOUTA,
input wire [_PARAMS_WIDTH-1:0] BWB,
input wire [_PARAMS_WIDTH-1:0] DINB,
output wire [_PARAMS_WIDTH-1:0] DOUTB,
input wire [`BIST_OP_WIDTH-1:0] BIST_COMMAND,
input wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DIN,
output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT,
input wire [`BIST_ID_WIDTH-1:0] SRAMID
);
  '''

def Get2RWCache():
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
         if (RDWENA == 1'b0)
            cache[AA] <= (DINA & BWA) | (cache[AA] & ~BWA);
         else
            dout_f0 <= cache[AA];
      end
   end

   reg [_PARAMS_WIDTH-1:0] dout_f1;
   assign DOUTB = dout_f1;
   always @ (posedge MEMCLK)
   begin
      if (CEB)
      begin
         if (RDWENB == 1'b0)
            cache[AB] <= (DINB & BWB) | (cache[AB] & ~BWB);
         else
            dout_f1 <= cache[AB];
      end
   end
  '''


def Get1R1WHeader():
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
input wire RDWENA,
input wire CEB,
input wire [_PARAMS_HEIGHT_LOG-1:0] AB,
input wire RDWENB,
input wire [_PARAMS_WIDTH-1:0] BWA,
input wire [_PARAMS_WIDTH-1:0] DINA,
output wire [_PARAMS_WIDTH-1:0] DOUTA,
input wire [_PARAMS_WIDTH-1:0] BWB,
input wire [_PARAMS_WIDTH-1:0] DINB,
output wire [_PARAMS_WIDTH-1:0] DOUTB,
input wire [`BIST_OP_WIDTH-1:0] BIST_COMMAND,
input wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DIN,
output wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT,
input wire [`BIST_ID_WIDTH-1:0] SRAMID
);
  '''

def Get1R1WCache():
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
         if (RDWENA == 1'b0)
            cache[AA] <= (DINA & BWA) | (cache[AA] & ~BWA);
         else
            dout_f0 <= cache[AA];
      end
   end

   reg [_PARAMS_WIDTH-1:0] dout_f1;
   assign DOUTB = dout_f1;
   always @ (posedge MEMCLK)
   begin
      if (CEB)
      begin
         if (RDWENB == 1'b0)
            cache[AB] <= (DINB & BWB) | (cache[AB] & ~BWB);
         else
            dout_f1 <= cache[AB];
      end
   end
  '''

def Get2R1WHeader():
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
input wire [_PARAMS_WIDTH-1:0] DIN

// input wire [`BIST_OP_WIDTH-1:0] BIST_COMMAND,
// input wire [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DIN,
// output reg [`SRAM_WRAPPER_BUS_WIDTH-1:0] BIST_DOUT,
// input wire [`BIST_ID_WIDTH-1:0] SRAMID
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
