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
module grady18v2 (
    // user accessible ports
    input wire [0:0] clk
    , input wire [0:0] ce
    , input wire [7:0] in
    , output reg [1:0] out
    , input wire [0:0] cin
    , output reg [0:0] cout

    , input wire [0:0] prog_done
    , input wire [75:0] prog_data
        // prog_data[ 0 +: 38] BLE5A
        //          [ 0 +: 16] LUT4A
        //          [16 +: 16] LUT4B
        //          [32 +:  2] Adder CIN_MODE 
        //          [34 +:  2] Mode select: disabled, arith, LUT5, LUT6
        //          [36 +:  1] FF disable (FF enabled by default)
        //          [37 +:  1] FF ENABLE_CE
        // prog_data[38 +: 38] BLE5B
    );

    // -- Parameters ---------------------------------------------------------
    localparam LUT4_DATA_WIDTH      = 16;
    localparam ADDER_MODE_WIDTH     = 2;
    localparam BLE5_MODE_WIDTH      = 2;

    // adder carry-in modes
    localparam ADDER_MODE_CONST0    = 2'b00;
    localparam ADDER_MODE_CONST1    = 2'b01;
    localparam ADDER_MODE_CHAIN     = 2'b10;
    localparam ADDER_MODE_FABRIC    = 2'b11;

    // BLE5 modes
    localparam BLE5_MODE_DISABLED   = 2'b00;
    localparam BLE5_MODE_ARITH      = 2'b01;
    localparam BLE5_MODE_LUT5       = 2'b10;
    localparam BLE5_MODE_LUT6       = 2'b11;    // BLE5A and BLE5B behave differently in this mode

    // prog_data indexing: BLE5
    localparam LUT4A_DATA           = 0;
    localparam LUT4B_DATA           = LUT4A_DATA + LUT4_DATA_WIDTH;
    localparam ADDER_MODE           = LUT4B_DATA + LUT4_DATA_WIDTH;
    localparam BLE5_MODE            = ADDER_MODE + ADDER_MODE_WIDTH;
    localparam FF_DISABLE           = BLE5_MODE + BLE5_MODE_WIDTH;
    localparam FF_ENABLE_CE         = FF_DISABLE + 1;
    localparam BLE5_DATA_WIDTH      = FF_ENABLE_CE + 1;

    // prog_data indexing: FLE8
    localparam BLE5A_DATA           = 0;
    localparam BLE5B_DATA           = BLE5A_DATA + BLE5_DATA_WIDTH;

    // -- Internal Signals ---------------------------------------------------
    reg [1:0] internal_cin;
    reg [1:0] internal_lut4 [1:0];  // !! BLE5A.LUT4A=[0][0], BLE5A.LUT4B=[1][0], BLE5B.LUT4A=[0][1], BLE5B.LUT4B=[1][1]
    reg [1:0] internal_lut5;
    reg       internal_lut6;
    wire [1:0] internal_sum  [1:0]; // !! BLE5A.{cout, s}=[0], BLE5B.{cout, s}=[1]
    wire [1:0] internal_ce;
    reg [1:0] internal_ff;

    // decode programming data
    wire [BLE5_MODE_WIDTH-1:0]  ble5a_mode;
    wire [BLE5_MODE_WIDTH-1:0]  ble5b_mode;
    wire                        ffa_disable, ffa_ce;
    wire                        ffb_disable, ffb_ce;

    assign ble5a_mode = prog_data[BLE5A_DATA + BLE5_MODE +: BLE5_MODE_WIDTH];
    assign ble5b_mode = prog_data[BLE5B_DATA + BLE5_MODE +: BLE5_MODE_WIDTH];
    assign ffa_disable = prog_data[BLE5A_DATA + FF_DISABLE];
    assign ffa_ce = ~prog_data[BLE5A_DATA + FF_ENABLE_CE] || ce;
    assign ffb_disable = prog_data[BLE5B_DATA + FF_DISABLE];
    assign ffb_ce = ~prog_data[BLE5B_DATA + FF_ENABLE_CE] || ce;

    // -- Implementation -----------------------------------------------------
    // select carry-ins
    always @* begin
        // BLE5A
        case (prog_data[BLE5A_DATA + ADDER_MODE +: ADDER_MODE_WIDTH])
            ADDER_MODE_CONST0:  internal_cin[0] = 1'b0;
            ADDER_MODE_CONST1:  internal_cin[0] = 1'b1;
            ADDER_MODE_CHAIN:   internal_cin[0] = cin;
            ADDER_MODE_FABRIC:  internal_cin[0] = in[6];
        endcase

        // BLE5B
        case (prog_data[BLE5B_DATA + ADDER_MODE +: ADDER_MODE_WIDTH])
            ADDER_MODE_CONST0:  internal_cin[1] = 1'b0;
            ADDER_MODE_CONST1:  internal_cin[1] = 1'b1;
            ADDER_MODE_CHAIN:   internal_cin[1] = internal_sum[0][1];
            ADDER_MODE_FABRIC:  internal_cin[1] = in[6];
        endcase
    end

    // adders
    assign internal_sum[0] = internal_lut4[0][0] + internal_lut4[1][0] + internal_cin[0];
    assign internal_sum[1] = internal_lut4[0][1] + internal_lut4[1][1] + internal_cin[1];

    // LUTs
    always @* begin
        // BLE5A.LUT4A, BLE5A.LUT4B
        case (in[3:0])
            4'd0: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 0];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 0];
            end
            4'd1: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 1];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 1];
            end
            4'd2: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 2];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 2];
            end
            4'd3: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 3];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 3];
            end
            4'd4: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 4];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 4];
            end
            4'd5: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 5];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 5];
            end
            4'd6: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 6];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 6];
            end
            4'd7: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 7];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 7];
            end
            4'd8: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 8];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 8];
            end
            4'd9: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 9];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 9];
            end
            4'd10: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 10];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 10];
            end
            4'd11: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 11];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 11];
            end
            4'd12: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 12];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 12];
            end
            4'd13: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 13];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 13];
            end
            4'd14: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 14];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 14];
            end
            4'd15: begin
                internal_lut4[0][0] = prog_data[BLE5A_DATA + LUT4A_DATA + 15];
                internal_lut4[1][0] = prog_data[BLE5A_DATA + LUT4B_DATA + 15];
            end
        endcase

        // BLE5B.LUT4A, BLE5B.LUT4B
        case ({in[5:4], in[1:0]})
            4'd0: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 0];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 0];
            end
            4'd1: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 1];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 1];
            end
            4'd2: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 2];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 2];
            end
            4'd3: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 3];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 3];
            end
            4'd4: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 4];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 4];
            end
            4'd5: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 5];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 5];
            end
            4'd6: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 6];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 6];
            end
            4'd7: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 7];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 7];
            end
            4'd8: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 8];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 8];
            end
            4'd9: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 9];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 9];
            end
            4'd10: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 10];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 10];
            end
            4'd11: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 11];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 11];
            end
            4'd12: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 12];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 12];
            end
            4'd13: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 13];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 13];
            end
            4'd14: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 14];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 14];
            end
            4'd15: begin
                internal_lut4[0][1] = prog_data[BLE5B_DATA + LUT4A_DATA + 15];
                internal_lut4[1][1] = prog_data[BLE5B_DATA + LUT4B_DATA + 15];
            end
        endcase

        // LUT5
        case (in[6])
            1'b0: internal_lut5 = internal_lut4[0];
            1'b1: internal_lut5 = internal_lut4[1];
        endcase

        // LUT6
        case (in[7])
            1'b0: internal_lut6 = internal_lut5[0];
            1'b1: internal_lut6 = internal_lut5[1];
        endcase
    end

    // Combinational outputs
    reg [1:0] comb_out;
    always @* begin
        comb_out = 2'b0;

        // BLE5A
        case (ble5a_mode)
            BLE5_MODE_DISABLED:     comb_out[0] = 1'b0;
            BLE5_MODE_ARITH:        comb_out[0] = internal_sum[0][0];
            BLE5_MODE_LUT5:         comb_out[0] = internal_lut5[0];
            BLE5_MODE_LUT6:         comb_out[0] = internal_lut6;
        endcase

        // BLE5B
        case (ble5b_mode)
            BLE5_MODE_DISABLED:     comb_out[1] = 1'b0;
            BLE5_MODE_ARITH:        comb_out[1] = internal_sum[1][0];
            BLE5_MODE_LUT5:         comb_out[1] = internal_lut5[1];
            BLE5_MODE_LUT6:         comb_out[1] = 1'b0;
        endcase
    end

    // FFs
    always @(posedge clk) begin
        if (~prog_done) begin
            internal_ff <= 2'b0;
        end else begin
            // BLE5A
            if (ffa_ce) internal_ff[0] <= comb_out[0];

            // BLE5B
            if (ffb_ce) internal_ff[1] <= comb_out[1];
        end
    end

    // -- Outputs ------------------------------------------------------------
    always @* begin
        out = 2'b0;
        cout = 1'b0;

        if (prog_done) begin
            // out[0]
            case (ffa_disable) // synopsys infer_mux
                1'b0:               out[0] = internal_ff[0];
                1'b1:               out[0] = comb_out[0];
            endcase

            // out[1]
            case (ffb_disable) // synopsys infer_mux
                1'b0:               out[1] = internal_ff[1];
                1'b1:               out[1] = comb_out[1];
            endcase

            // cout
            if (ble5b_mode == BLE5_MODE_ARITH) begin
                cout = internal_sum[1][1];
            end else begin
                cout = 1'b0;
            end

        end
    end

endmodule