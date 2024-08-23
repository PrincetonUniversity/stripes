/*
Copyright (c) 2018 Princeton University
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Princeton University nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
`include "iop.h" 
module nibbler_l15_transducer (
    input                           clk,
    input                           rst_n,

    // nibbler -> Transducer
    input                           nibbler_transducer_csr_wake,
    input                           nibbler_transducer_csr_disable_nibbler,
    input [66:0]                    nibbler_transducer_imemreq_msg,
    input                           nibbler_transducer_imemreq_nc,
    input                           nibbler_transducer_imemreq_val,
    input                           nibbler_transducer_imemresp_rdy,
    input [66:0]                    nibbler_transducer_dmemreq_msg,
    input                           nibbler_transducer_dmemreq_nc,
    input                           nibbler_transducer_dmemreq_val,
    input                           nibbler_transducer_dmemresp_rdy,
    input  [31:0]                   nibbler_transducer_csr_status,
    input                           nibbler_transducer_use_addr_ext,
    input  [7:0]                    nibbler_transducer_memreq_addr_ext,
    input  [31:0]                   nibbler_transducer_memreq_data_ext,

    // L1.5 -> Transducer
    input                           l15_transducer_ack,
    input                           l15_transducer_header_ack,

    // outputs nibbler uses
    // Transducer -> L1.5                    
    output reg [4:0]                    transducer_l15_rqtype,
    output     [`L15_AMO_OP_WIDTH-1:0]  transducer_l15_amo_op,
    output reg [2:0]                    transducer_l15_size,
    output                              transducer_l15_val,
    output     [`PHY_ADDR_WIDTH-1:0]    transducer_l15_address,
    output     [63:0]                   transducer_l15_data,
    output                              transducer_l15_nc,


    // outputs nibbler doesn't use                    
    output [0:0]                    transducer_l15_threadid,
    output                          transducer_l15_prefetch,
    output                          transducer_l15_blockstore,
    output                          transducer_l15_blockinitstore,
    output [1:0]                    transducer_l15_l1rplway,
    output                          transducer_l15_invalidate_cacheline,
    output [32:0]                   transducer_l15_csm_data,
    output [63:0]                   transducer_l15_data_next_entry,
   

    // L1.5 -> Transducer
    input                           l15_transducer_val,
    input [3:0]                     l15_transducer_returntype,
    input [63:0]                    l15_transducer_data_0,
    input [63:0]                    l15_transducer_data_1,
   
    // Transducer -> nibbler
    output reg                      transducer_nibbler_imemreq_rdy,
    output reg [34:0]               transducer_nibbler_imemresp_msg,
    output reg                      transducer_nibbler_imemresp_val,
    output reg                      transducer_nibbler_dmemreq_rdy,
    output reg [34:0]               transducer_nibbler_dmemresp_msg,
    output reg                      transducer_nibbler_dmemresp_val,
    
    output reg                      int_recv
);

    localparam ACK_IDLE = 1'b0;
    localparam ACK_WAIT = 1'b1;
    localparam D_TYPE   = 1'b0;
    localparam I_TYPE   = 1'b1;
    localparam OFFSET_0 = 2'b00;
    localparam OFFSET_1 = 2'b01;
    localparam OFFSET_2 = 2'b10;
    localparam OFFSET_3 = 2'b11;
    localparam WORD     = 2'b00;
    localparam HALF     = 2'b10;
    localparam BYTE     = 2'b01;
    localparam DOUBLE   = 2'b11;

    

    // Variable Declarations //
    
    // Taking requests from Nibbler core
    reg         cur_memreq_type;
    reg  [66:0] my_nibbler_memreq_msg;
    wire [1:0]  nibbler_memreq_len;
    wire        nibbler_memreq_type;
    wire [31:0] nibbler_memreq_addr;
    wire [63:0] nibbler_memreq_data;
    reg         nibbler_memreq_pending;

    // It's a disable if it's a valid request and all lower address bits are 1.
    // If using 40 bit address, ensure high 8 bits are also 1.
    wire nibbler_store_disable = ((nibbler_transducer_dmemreq_val && transducer_nibbler_dmemreq_rdy && (nibbler_transducer_dmemreq_msg[65:34] == 32'hffffffff))
                                && ( !nibbler_transducer_use_addr_ext || (nibbler_transducer_use_addr_ext && (nibbler_transducer_memreq_addr_ext == 8'hff))));

    // Responding back to Nibbler 
    reg  [31:0] rdata_part;
    wire [31:0] nibbler_memresp_data;
    wire        nibbler_memresp_type;
    wire [1:0]  nibbler_memresp_len; 
    reg         nibbler_memresp_val;
    wire [34:0] nibbler_memresp_msg;
    
    reg nibbler_int;

    
    // Nibbler -> L1.5

    /*******************************DECODER!!!!!**************************************/
    
    always @ (posedge clk) begin

      // Reset to idle state. Refuse instruction requests from core until interrupt is received.
      if (!rst_n) begin
        transducer_nibbler_imemreq_rdy <= 1'b0;
        transducer_nibbler_imemresp_msg <= 35'b000_0000000_00000_00000_000_00000_0010011;
        transducer_nibbler_imemresp_val <= 1'b0;

        transducer_nibbler_dmemreq_rdy <= 1'b0;
        transducer_nibbler_dmemresp_msg <= 35'b0;
        transducer_nibbler_dmemresp_val <= 1'b0;

      end
      // Start accepting instruction fetch requests
      else if (nibbler_int) begin
        transducer_nibbler_imemreq_rdy <= 1'b1;
      end
      // Swallow dmem request to 0xfff... and disable all memory requests until woken up again
      else if (nibbler_transducer_csr_disable_nibbler ||  nibbler_store_disable) begin
        transducer_nibbler_imemreq_rdy <= 1'b0;
        transducer_nibbler_imemresp_val <= 1'b0;
        transducer_nibbler_dmemreq_rdy <= 1'b0;
        transducer_nibbler_dmemresp_val <= 1'b0;
      end
      // Prioritize data requests over instruction requests since they are later in the pipeline 
      // Set current state to handle data request. Stall all other memory requests.
      else if (nibbler_transducer_dmemreq_val && transducer_nibbler_dmemreq_rdy) begin
        my_nibbler_memreq_msg <= nibbler_transducer_dmemreq_msg;
        cur_memreq_type  <= D_TYPE;

        transducer_nibbler_imemreq_rdy <= 1'b0;
        transducer_nibbler_imemresp_val <= 1'b0;

        transducer_nibbler_dmemreq_rdy <= 1'b0;
        transducer_nibbler_dmemresp_val <= 1'b0;
      end
      // Set current state to handle instruction request. Stall all other memory requests.
      else if (nibbler_transducer_imemreq_val && transducer_nibbler_imemreq_rdy) begin
        my_nibbler_memreq_msg          <= nibbler_transducer_imemreq_msg;
        cur_memreq_type              <= I_TYPE;

        transducer_nibbler_imemreq_rdy <= 1'b0;
        transducer_nibbler_imemresp_val <= 1'b0;

        transducer_nibbler_dmemreq_rdy <= 1'b0;
        transducer_nibbler_dmemresp_val <= 1'b0;
      end
      // When l15 responds with a store ack or load return, pass the message to the core
      else if (nibbler_memresp_val) begin
        if (cur_memreq_type == D_TYPE) begin
          transducer_nibbler_imemresp_msg <= 35'b000_0000000_00000_00000_000_00000_0010011;
          transducer_nibbler_imemresp_val <= 1'b0;
            
          transducer_nibbler_dmemresp_msg <= nibbler_memresp_msg;
          transducer_nibbler_dmemresp_val <= 1'b1;
        end
        else if (cur_memreq_type == I_TYPE) begin
          transducer_nibbler_imemresp_msg <= nibbler_memresp_msg;
          transducer_nibbler_imemresp_val <= 1'b1;

          transducer_nibbler_dmemresp_msg <= 35'b0;
          transducer_nibbler_dmemresp_val <= 1'b0;
        end
        transducer_nibbler_imemreq_rdy <= 1'b0;
        transducer_nibbler_dmemreq_rdy <= 1'b0;
      end
      // On cycle after instruction is sent to core, prepare for new memory request
      else if (transducer_nibbler_imemresp_val && nibbler_transducer_imemresp_rdy) begin
        transducer_nibbler_imemreq_rdy <= 1'b1;
        transducer_nibbler_imemresp_val <= 1'b0;

        transducer_nibbler_dmemreq_rdy <= 1'b1;
        transducer_nibbler_dmemresp_val <= 1'b0;
      end
      // On cycle after data is returned to core, prepare for new memory request
      else if (transducer_nibbler_dmemresp_val && nibbler_transducer_dmemresp_rdy) begin //LOOK AT THIS
        my_nibbler_memreq_msg           <= nibbler_transducer_imemreq_msg;
        // cur_memreq_type                 <= I_TYPE; // TODO: Why is this assignment here?

        transducer_nibbler_imemreq_rdy  <= 1'b1;
        transducer_nibbler_imemresp_val <= 1'b0;

        transducer_nibbler_dmemreq_rdy  <= 1'b1;
        transducer_nibbler_dmemresp_val <= 1'b0;
      end
    end
 
    assign  nibbler_memreq_type  = my_nibbler_memreq_msg[66];
    assign  nibbler_memreq_addr  = my_nibbler_memreq_msg[65:34];
    assign  nibbler_memreq_len   = my_nibbler_memreq_msg[33:32];
    assign  nibbler_memreq_data  = {nibbler_transducer_memreq_data_ext,my_nibbler_memreq_msg[31:0]};
    //assign nibbler_memreq_pending  = (nibbler_transducer_imemreq_val || nibbler_transducer_dmemreq_val);
    //assign  nibbler_memreq_pending = (nibbler_transducer_imemreq_val && transducer_nibbler_imemreq_rdy) || (nibbler_transducer_dmemreq_val && transducer_nibbler_dmemreq_rdy);
    always @ (posedge clk) begin
      if (!rst_n) begin
        nibbler_memreq_pending <= 1'b0;
      end
      // Set new pending memory request if val/rdy says so and no request is currently pending
      else if ((nibbler_transducer_imemreq_val && transducer_nibbler_imemreq_rdy || (nibbler_transducer_dmemreq_val && transducer_nibbler_dmemreq_rdy) && (!nibbler_store_disable)) && !nibbler_memreq_pending) begin
        nibbler_memreq_pending <= 1'b1;
      end
      // Current request completes when memresp is valid
      else if (nibbler_memreq_pending && nibbler_memresp_val) begin
        nibbler_memreq_pending <= 1'b0;
      end
      // When transducer 
      // else if (transducer_nibbler_dmemresp_val) begin
      //   nibbler_memreq_pending <= 1'b1;
      // end
      /*else if (transducer_nibbler_imemresp_val || transducer_nibbler_dmemresp_val) begin
        transducer_nibbler_imemreq_rdy <= 1'b1;
        transducer_nibbler_imemresp_val <= 1'b0;

        transducer_nibbler_dmemreq_rdy <= 1'b1;
        transducer_nibbler_dmemresp_val <= 1'b0;
      end*/
    end    

    reg current_val;
    reg prev_val;
    
    // is this a new request from Nibbler?
    wire new_request = current_val & ~prev_val;
    always @ (posedge clk)
    begin
        if (!rst_n) begin
           current_val <= 0;
           prev_val <= 0;
        end
        else begin
           current_val <= nibbler_memreq_pending;
           prev_val <= current_val;
        end
    end 

    // are we waiting for an ack
    reg ack_reg;
    reg ack_next;
    always @ (posedge clk) begin
        if (!rst_n) begin
            ack_reg <= 0;
        end
        else begin
            ack_reg <= ack_next;
        end
    end
    always @ (*) begin
        // be careful with these conditionals.
        if (l15_transducer_ack) begin
            ack_next = ACK_IDLE;
        end
        else if (new_request) begin
            ack_next = ACK_WAIT;
        end
        else begin
            ack_next = ack_reg;
        end
    end

    // are we waiting for a header ack
    reg header_ack_reg;
    reg header_ack_next;
    always @ (posedge clk) begin
        if (!rst_n) begin
            header_ack_reg <= 0;
        end
        else begin
            header_ack_reg <= header_ack_next;
        end
    end
    always @ (*) begin
        // be careful with these conditionals.
        if (l15_transducer_header_ack) begin
            header_ack_next = ACK_IDLE;
        end
        else if (new_request) begin
            header_ack_next = ACK_WAIT;
        end
        else begin
            header_ack_next = header_ack_reg;
        end
    end
    
    // if we haven't got a header ack and it's an old request, valid should be high 
    // otherwise valid should be high only if we got a new request
    assign transducer_l15_val = (header_ack_reg == ACK_WAIT) ? nibbler_memreq_pending : new_request;

    reg [63:0] nibbler_wdata_flipped;
    
    // assign transducer's outputs to l15
    assign transducer_l15_address = (cur_memreq_type == D_TYPE) && nibbler_transducer_use_addr_ext ? {nibbler_transducer_memreq_addr_ext, nibbler_memreq_addr} : {{8{nibbler_memreq_addr[31]}}, nibbler_memreq_addr};
    assign transducer_l15_nc = (cur_memreq_type == D_TYPE) ? nibbler_transducer_dmemreq_nc : nibbler_transducer_imemreq_nc;
    assign transducer_l15_data = nibbler_wdata_flipped;
    

    // set rqtype specific data
    always @ *
    begin
        if (nibbler_memreq_pending) begin
            // store operation
            if (nibbler_memreq_type) begin
                transducer_l15_rqtype = `STORE_RQ;
                case(nibbler_memreq_len)
                    DOUBLE: begin
                        transducer_l15_size = `MSG_DATA_SIZE_8B;
                        nibbler_wdata_flipped = {nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[23:16], nibbler_memreq_data[31:24],
                                                 nibbler_memreq_data[39:32], nibbler_memreq_data[47:40], nibbler_memreq_data[55:48], nibbler_memreq_data[63:56]};
                    end
                    WORD: begin
                        transducer_l15_size = `MSG_DATA_SIZE_4B;
                        nibbler_wdata_flipped = {nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[23:16], nibbler_memreq_data[31:24],
                                                 nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[23:16], nibbler_memreq_data[31:24]};
                    end
                    BYTE: begin
                        transducer_l15_size = `MSG_DATA_SIZE_1B;
                        nibbler_wdata_flipped = {nibbler_memreq_data[7:0], nibbler_memreq_data[7:0], nibbler_memreq_data[7:0], nibbler_memreq_data[7:0],
                                                 nibbler_memreq_data[7:0], nibbler_memreq_data[7:0], nibbler_memreq_data[7:0], nibbler_memreq_data[7:0]};
                    end
                    HALF: begin
                        transducer_l15_size = `MSG_DATA_SIZE_2B; 
                        nibbler_wdata_flipped = {nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[7:0], nibbler_memreq_data[15:8],
                                                 nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[7:0], nibbler_memreq_data[15:8]};
                    end
                    default: begin // this should never happen
                        nibbler_wdata_flipped = {nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[23:16], nibbler_memreq_data[31:24],
                                                 nibbler_memreq_data[7:0], nibbler_memreq_data[15:8], nibbler_memreq_data[23:16], nibbler_memreq_data[31:24]};
                        transducer_l15_size = 0;
                    end
                endcase
            end
            // load operation
            else begin
                nibbler_wdata_flipped = 64'b0;
                transducer_l15_rqtype = `LOAD_RQ;
                transducer_l15_size = `MSG_DATA_SIZE_4B;
            end 
        end
        else begin
            nibbler_wdata_flipped = 64'b0;
            transducer_l15_rqtype = 5'b0;
            transducer_l15_size = 3'b0;
        end
    end
    
    
    // L1.5 -> Nibbler

    /***************** ENCODER!!!!*******************/

    reg [31:0] nibbler_memresp_rdata;
    assign  nibbler_memresp_data    = (cur_memreq_type == D_TYPE) ? nibbler_memresp_rdata : {rdata_part[7:0], rdata_part[15:8], rdata_part[23:16], rdata_part[31:24]};

    assign  nibbler_memresp_type     = l15_transducer_returntype == 4'b0000 ? 1'b0 : 1'b1;
    assign  nibbler_memresp_len      = nibbler_memreq_len;
    assign  nibbler_memresp_msg      = {nibbler_memresp_type, nibbler_memresp_len, nibbler_memresp_data};
    
    
    // Keep track of whether we have received the wakeup interrupt
    always @ (posedge clk) begin
        if (!rst_n) begin
            nibbler_int <= 1'b0;
        end
        else if (int_recv || nibbler_transducer_csr_wake) begin
            nibbler_int <= 1'b1;
        end
        else if (nibbler_int) begin
            nibbler_int <= 1'b0;
        end
    end

    always @ (*) begin
        if (l15_transducer_val) begin
            case(l15_transducer_returntype)
                `LOAD_RET: begin
                    // load
                    int_recv = 1'b0;
                    nibbler_memresp_val = 1'b1;
                    // (sub)word of interest is stored in one of 4 parts of l.15 response
                    case(transducer_l15_address[3:2])
                        OFFSET_0: begin
                            rdata_part = l15_transducer_data_0[63:32];
                        end
                        OFFSET_1: begin
                            rdata_part = l15_transducer_data_0[31:0];
                        end
                        OFFSET_2: begin
                            rdata_part = l15_transducer_data_1[63:32];
                        end
                        OFFSET_3: begin
                            rdata_part = l15_transducer_data_1[31:0];
                        end
                        default: begin
                        end
                    endcase 
                end
                `ST_ACK: begin
                    int_recv = 1'b0;
                    nibbler_memresp_val = 1'b1;
                    rdata_part = 32'b0;
                end
                `INT_RET: begin
                    if (l15_transducer_data_0[17:16] == 2'b01) begin
                        int_recv = 1'b1;
                    end
                    else begin
                        int_recv = 1'b0;
                    end
                    nibbler_memresp_val = 1'b0;
                    rdata_part = 32'b0;
                end
                default: begin
                    int_recv = 1'b0;
                    nibbler_memresp_val = 1'b0;
                    rdata_part = 32'b0;
                end
            endcase 
        end
        else begin
            int_recv = 1'b0;
            nibbler_memresp_val = 1'b0;
            rdata_part = 32'b0;
        end
    end

    // Flip around data when it is fed to the Nibbler core.
    always @ (*) begin
        if (l15_transducer_val && (l15_transducer_returntype == `LOAD_RET)) begin
            case (nibbler_memresp_len)
                WORD: begin
                    nibbler_memresp_rdata = {rdata_part[7:0], rdata_part[15:8], rdata_part[23:16], rdata_part[31:24]};
                end
                HALF: begin
                    case(transducer_l15_address[1:0])
                        OFFSET_0: begin
                            nibbler_memresp_rdata = {rdata_part[23:16], rdata_part[31:24], rdata_part[23:16], rdata_part[31:24]};
                        end
                        OFFSET_2: begin
                            nibbler_memresp_rdata = {rdata_part[7:0], rdata_part[15:8], rdata_part[7:0], rdata_part[15:8]};
                        end
                        default: begin
                            nibbler_memresp_rdata = 32'b0;
                        end
                    endcase
                end
                BYTE: begin
                    case(transducer_l15_address[1:0])
                        OFFSET_0: begin
                            nibbler_memresp_rdata = {rdata_part[31:24], rdata_part[31:24], rdata_part[31:24], rdata_part[31:24]};
                        end
                        OFFSET_1: begin
                            nibbler_memresp_rdata = {rdata_part[23:16], rdata_part[23:16], rdata_part[23:16], rdata_part[23:16]};
                        end
                        OFFSET_2: begin
                            nibbler_memresp_rdata = {rdata_part[15:8], rdata_part[15:8], rdata_part[15:8], rdata_part[15:8]};
                        end
                        OFFSET_3: begin
                            nibbler_memresp_rdata = {rdata_part[7:0], rdata_part[7:0], rdata_part[7:0], rdata_part[7:0]};
                        end
                        default: begin
                            nibbler_memresp_rdata = 32'b0;
                        end
                    endcase
                end
                default: begin
                    nibbler_memresp_rdata = 32'b0;
                end
            endcase    
        end
    end

    assign transducer_l15_threadid = 1'b0; // MMU 1, Nibbler 0
    assign transducer_l15_prefetch = 1'b0;
    assign transducer_l15_csm_data = 33'b0;
    assign transducer_l15_data_next_entry = 64'b0;
    assign transducer_l15_blockstore = 1'b0;
    assign transducer_l15_blockinitstore = 1'b0;
    assign transducer_l15_l1rplway = 2'b0; // is this set when something in the l1 gets replaced? Nibbler has no cache
    assign transducer_l15_invalidate_cacheline = 1'b0; // will Nibbler ever need to invalidate cachelines?
    assign  transducer_l15_amo_op = `L15_AMO_OP_WIDTH'd0;


endmodule
