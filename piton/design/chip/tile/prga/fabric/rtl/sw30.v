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
`timescale 1ns/1ps
module sw30 (
    input wire [29:0] i
    , output reg [0:0] o

    , input wire [0:0] prog_done
    , input wire [4:0] prog_data
    );

    always @* begin
        if (~prog_done) begin
            o = 1'b0;
        end else begin
            o = 1'b0;   // if ``prog_data == 0`` or ``prog_data`` out of bound, output 0
            case (prog_data)
                5'd1: o = i[0];
                5'd2: o = i[1];
                5'd3: o = i[2];
                5'd4: o = i[3];
                5'd5: o = i[4];
                5'd6: o = i[5];
                5'd7: o = i[6];
                5'd8: o = i[7];
                5'd9: o = i[8];
                5'd10: o = i[9];
                5'd11: o = i[10];
                5'd12: o = i[11];
                5'd13: o = i[12];
                5'd14: o = i[13];
                5'd15: o = i[14];
                5'd16: o = i[15];
                5'd17: o = i[16];
                5'd18: o = i[17];
                5'd19: o = i[18];
                5'd20: o = i[19];
                5'd21: o = i[20];
                5'd22: o = i[21];
                5'd23: o = i[22];
                5'd24: o = i[23];
                5'd25: o = i[24];
                5'd26: o = i[25];
                5'd27: o = i[26];
                5'd28: o = i[27];
                5'd29: o = i[28];
                5'd30: o = i[29];
            endcase
        end
    end

endmodule