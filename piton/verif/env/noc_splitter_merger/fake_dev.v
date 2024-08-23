// Copyright (c) 2020 Princeton University
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//==================================================================================================
//  Filename      : fake_dev.v
//  Author        : Fei Gao
//  Description   : fake device which could receive and send NoC messages. 
//==================================================================================================

`include "define.tmp.h"
`include "network_define.v"

module fake_dev
#(
    parameter NUM_REQUESTS   = 1,
    parameter WAIT_TIME0    = 100,
    parameter TARGET_FBITS0 = 4'd0,
    parameter SIZE0         = 0,
    parameter WAIT_TIME1    = 100,
    parameter TARGET_FBITS1 = 4'd0,
    parameter SIZE1         = 0,
    parameter WAIT_TIME2    = 100,
    parameter TARGET_FBITS2 = 4'd0,
    parameter SIZE2         = 0,
    parameter WAIT_TIME3    = 100,
    parameter TARGET_FBITS3 = 4'd0,
    parameter SIZE3         = 0
)
(
    input   clk,
    input   rst_n,

    input                               src_dev_vr_noc_val,
    input       [`NOC_DATA_WIDTH-1:0]   src_dev_vr_noc_dat,
    output                              src_dev_vr_noc_rdy,

    output reg                          dev_dst_vr_noc_val,
    output reg  [`NOC_DATA_WIDTH-1:0]   dev_dst_vr_noc_dat,
    input                               dev_dst_vr_noc_rdy
);

    reg rec_state, rec_state_next;
    reg [7:0] rec_count, rec_count_next;
    localparam  IDLE = 0;
    localparam  REC_COUNT = 1'b1;

    reg [3:0] send_state, send_state_next, recover_state, recover_state_next, next_step_state;
    reg [7:0] send_count, send_count_next;
    reg [9:0] wait_count, wait_count_next;
    localparam  SEND0 = 4'd1;
    localparam  SEND1 = 4'd2;
    localparam  SEND2 = 4'd3;
    localparam  SEND3 = 4'd4;
    localparam  SEND_COUNT = 4'd5;
    localparam  FINISH = 4'd6;

    assign src_dev_vr_noc_rdy = 1;

    // Receive NoC Msg
    always @(posedge clk) begin
        if (~rst_n) begin
            rec_state <= IDLE;
            rec_count <= 0;
        end
        else begin
            rec_state <= rec_state_next;
            rec_count <= rec_count_next;
        end
    end

    always @(*) begin
        rec_count_next = rec_count;
        rec_state_next = rec_state;
        if (rec_state == IDLE) begin
            if (src_dev_vr_noc_val & src_dev_vr_noc_rdy) begin
                rec_count_next = src_dev_vr_noc_dat[`MSG_LENGTH];
                rec_state_next = (|rec_count_next) ? REC_COUNT : IDLE;
            end
        end
        else if (rec_state == REC_COUNT) begin
            rec_count_next = (src_dev_vr_noc_val & src_dev_vr_noc_rdy) ? rec_count - 1 : rec_count;
            rec_state_next = (|rec_count_next) ? REC_COUNT : IDLE;
            
        end 
    end

    // Send NoC Msg
    always @(posedge clk) begin
        if (~rst_n) begin
            wait_count <= WAIT_TIME0;
            send_state <= SEND0;
            recover_state <= IDLE;
            send_count <= 0;
        end
        else begin
            wait_count <= wait_count_next;
            send_state <= send_state_next;
            recover_state <= recover_state_next;
            send_count <= send_count_next;
        end
    end

    reg         test_0;
    reg         test_00;
    reg         test_1;
    reg[1:0]    test_2;

    always @(*) begin
        send_state_next = send_state;
        recover_state_next = recover_state;
        send_count_next = send_count;
        wait_count_next = wait_count;
        
        dev_dst_vr_noc_val = 1'b0;
        dev_dst_vr_noc_dat = {`NOC_DATA_WIDTH{1'b0}};

        case(send_state) 
        SEND0: begin
            dev_dst_vr_noc_val = (wait_count == 0) ? 1'b1 : 1'b0;
            dev_dst_vr_noc_dat[`MSG_LENGTH]     = SIZE0;   
            dev_dst_vr_noc_dat[`MSG_DST_FBITS]  = TARGET_FBITS0;

            next_step_state = (NUM_REQUESTS > 1) ? SEND1 : FINISH;  
            
            send_state_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ?
                              ((SIZE0 == 0) ? next_step_state : SEND_COUNT) : SEND0;
            if (send_state_next == SEND_COUNT) begin
                send_count_next = SIZE0;
                recover_state_next = next_step_state;
            end
            wait_count_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ? WAIT_TIME1 :
                              ((wait_count == 0) ? 0: wait_count - 1);
        end
        SEND1: begin
            dev_dst_vr_noc_val = (wait_count == 0) ? 1'b1 : 1'b0;
            dev_dst_vr_noc_dat[`MSG_LENGTH]     = SIZE1;   
            dev_dst_vr_noc_dat[`MSG_DST_FBITS]  = TARGET_FBITS1;

            next_step_state = (NUM_REQUESTS > 2) ? SEND2 : FINISH;  
            
            send_state_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ?
                              ((SIZE1 == 0) ? next_step_state : SEND_COUNT) : SEND1;
            if (send_state_next == SEND_COUNT) begin
                send_count_next = SIZE1;
                recover_state_next = next_step_state;
            end
            wait_count_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ? WAIT_TIME2 :
                              (wait_count == 0) ? 0: wait_count - 1;
        end
        SEND2: begin
            dev_dst_vr_noc_val = (wait_count == 0) ? 1'b1 : 1'b0;
            dev_dst_vr_noc_dat[`MSG_LENGTH]     = SIZE2;   
            dev_dst_vr_noc_dat[`MSG_DST_FBITS]  = TARGET_FBITS2;

            next_step_state = (NUM_REQUESTS > 3) ? SEND3 : FINISH;  
            
            send_state_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ?
                              ((SIZE2 == 0) ? next_step_state : SEND_COUNT) : SEND2;
            if (send_state_next == SEND_COUNT) begin
                send_count_next = SIZE2;
                recover_state_next = next_step_state;
            end
            wait_count_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ? WAIT_TIME3 :
                              (wait_count == 0) ? 0: wait_count - 1;
        end
        SEND3: begin
            wait_count_next = (wait_count == 0) ? 0: wait_count - 1;
            
            dev_dst_vr_noc_val = (wait_count == 0) ? 1'b1 : 1'b0;
            dev_dst_vr_noc_dat[`MSG_LENGTH]     = SIZE3;   
            dev_dst_vr_noc_dat[`MSG_DST_FBITS]  = TARGET_FBITS3;

            next_step_state = FINISH;  
            
            send_state_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ?
                              ((SIZE0 == 0) ? next_step_state : SEND_COUNT) : SEND3;
            if (send_state_next == SEND_COUNT) begin
                send_count_next = SIZE3;
                recover_state_next = next_step_state;
            end
        end
        SEND_COUNT: begin
            dev_dst_vr_noc_val = 1'b1;
            send_count_next = (dev_dst_vr_noc_val & dev_dst_vr_noc_rdy) ? send_count - 1 : send_count;
            send_state_next = (send_count_next == 0) ? recover_state : SEND_COUNT;
        end
        FINISH: begin
            send_state_next = IDLE;
        end
        endcase
    end

    // Print message
    always @(posedge clk) begin
        if (dev_dst_vr_noc_val && dev_dst_vr_noc_rdy && (send_state != SEND_COUNT )) begin
            $display("#######################");
            $display("#### %m sends a msg:");
            $display("####      payload_length  : %h", dev_dst_vr_noc_dat[`MSG_LENGTH]);
            $display("####      fbits           : %h", dev_dst_vr_noc_dat[`MSG_DST_FBITS]);
            $display("");
        end
        if (dev_dst_vr_noc_val && dev_dst_vr_noc_rdy && (send_state == SEND_COUNT )) begin
            $display("####      sending the following flits!");
            $display("");
        end
        if (src_dev_vr_noc_val && src_dev_vr_noc_rdy && (rec_state != REC_COUNT)) begin
            $display("@@@@@@@@@@@@@@@@@@@@@@@@@@");
            $display("@@@@ %m receives a msg:");
            $display("@@@@      payload_length  : %h", src_dev_vr_noc_dat[`MSG_LENGTH]);
            $display("@@@@      fbits           : %h", src_dev_vr_noc_dat[`MSG_DST_FBITS]);
            $display("");
        end
        if (src_dev_vr_noc_val && src_dev_vr_noc_rdy && (rec_state == REC_COUNT)) begin
            $display("@@@@      receiving the following flits...");
            $display("");
        end
        if (send_state == FINISH) begin
            $display("######################");
            $display("#### %m has sent all messages!");
            $display("");
        end

    end


endmodule


