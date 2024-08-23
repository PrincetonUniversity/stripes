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
//  Filename      : test_top.v
//  Author        : Fei Gao
//  Description   : testbench for the noc splitter/merger. 
//==================================================================================================

module test_top();
    
    reg clk, rst_n;
    
    wire                                merger_router_vr_noc_val;
    wire [`NOC_DATA_WIDTH-1:0]          merger_router_vr_noc_dat;
    wire                                merger_router_vr_noc_rdy;
    
    wire                                router_splitter_vr_noc_val;
    wire [`NOC_DATA_WIDTH-1:0]          router_splitter_vr_noc_dat;
    wire                                router_splitter_vr_noc_rdy;
    
    wire                                splitter_tile0_vr_noc_val;
    wire [`NOC_DATA_WIDTH-1:0]          splitter_tile0_vr_noc_dat;
    wire                                splitter_tile0_vr_noc_rdy;
    
    wire                                splitter_tile1_vr_noc_val;
    wire [`NOC_DATA_WIDTH-1:0]          splitter_tile1_vr_noc_dat;
    wire                                splitter_tile1_vr_noc_rdy;
    
    wire                                tile0_merger_vr_noc_val;
    wire [`NOC_DATA_WIDTH-1:0]          tile0_merger_vr_noc_dat;
    wire                                tile0_merger_vr_noc_rdy;
    
    wire                                tile1_merger_vr_noc_val;
    wire [`NOC_DATA_WIDTH-1:0]          tile1_merger_vr_noc_dat;
    wire                                tile1_merger_vr_noc_rdy;
    
    initial begin
        
        $dumpfile("test_top.vcd");
        $dumpvars;

        clk = 0;
        rst_n = 0;

        #20
        rst_n = 1;


        #10000
        $finish;
    end

    always #5 clk = ~clk;


    fake_dev #(
        .NUM_REQUESTS    (2),
        .WAIT_TIME0     (100), 
        .TARGET_FBITS0  (1),
        .SIZE0          (0),
        .WAIT_TIME1     (50),
        .TARGET_FBITS1  (0),
        .SIZE1          (3)
    ) router (
        .clk                    (clk               ),                          
        .rst_n                  (rst_n             ),
                                                  
        .src_dev_vr_noc_val     (merger_router_vr_noc_val),
        .src_dev_vr_noc_dat     (merger_router_vr_noc_dat),
        .src_dev_vr_noc_rdy     (merger_router_vr_noc_rdy),
                                                 
        .dev_dst_vr_noc_val     (router_splitter_vr_noc_val),
        .dev_dst_vr_noc_dat     (router_splitter_vr_noc_dat),
        .dev_dst_vr_noc_rdy     (router_splitter_vr_noc_rdy)
    );

    noc_fbits_splitter #(
        .target_num(3'd2),
        .fbits_type0(0),
        .fbits_type1(1)
    ) noc_splitter(
        .clk                        (clk)                     ,
        .rst_n                      (rst_n)                       ,
                                                           
        .src_splitter_vr_noc_val       (router_splitter_vr_noc_val)   ,
        .src_splitter_vr_noc_dat       (router_splitter_vr_noc_dat)   ,
        .src_splitter_vr_noc_rdy       (router_splitter_vr_noc_rdy)   ,
                                                           
        .splitter_dst0_vr_noc_val     (splitter_tile0_vr_noc_val),
        .splitter_dst0_vr_noc_dat     (splitter_tile0_vr_noc_dat),
        .splitter_dst0_vr_noc_rdy     (splitter_tile0_vr_noc_rdy),
                                                           
        .splitter_dst1_vr_noc_val     (splitter_tile1_vr_noc_val),
        .splitter_dst1_vr_noc_dat     (splitter_tile1_vr_noc_dat),
        .splitter_dst1_vr_noc_rdy     (splitter_tile1_vr_noc_rdy),
                                     
        .splitter_dst2_vr_noc_val     (),
        .splitter_dst2_vr_noc_dat     (),
        .splitter_dst2_vr_noc_rdy     (0),
                                     
        .splitter_dst3_vr_noc_val     (),
        .splitter_dst3_vr_noc_dat     (),
        .splitter_dst3_vr_noc_rdy     (0),
                                     
        .splitter_dst4_vr_noc_val     (),
        .splitter_dst4_vr_noc_dat     (),
        .splitter_dst4_vr_noc_rdy     (0)
    );

    noc_prio_merger #(
        .src_num(3'd2)    
    ) noc_merger(   
        .clk                        (clk),
        .rst_n                      (rst_n),
                                                          
        .src0_merger_vr_noc_val       (tile0_merger_vr_noc_val), 
        .src0_merger_vr_noc_dat       (tile0_merger_vr_noc_dat),
        .src0_merger_vr_noc_rdy       (tile0_merger_vr_noc_rdy),
                                                          
        .src1_merger_vr_noc_val       (tile1_merger_vr_noc_val),
        .src1_merger_vr_noc_dat       (tile1_merger_vr_noc_dat),
        .src1_merger_vr_noc_rdy       (tile1_merger_vr_noc_rdy),
                                     
        .src2_merger_vr_noc_val       (0),
        .src2_merger_vr_noc_dat       (0),
        .src2_merger_vr_noc_rdy       (),
                                     
        .src3_merger_vr_noc_val       (0),
        .src3_merger_vr_noc_dat       (0),
        .src3_merger_vr_noc_rdy       (),
                                    
        .src4_merger_vr_noc_val       (0),
        .src4_merger_vr_noc_dat       (0),
        .src4_merger_vr_noc_rdy       (),
                                                          
        .merger_dst_vr_noc_val         (merger_router_vr_noc_val),  
        .merger_dst_vr_noc_dat         (merger_router_vr_noc_dat) ,
        .merger_dst_vr_noc_rdy         (merger_router_vr_noc_rdy)   
    );

    fake_dev #(
        .NUM_REQUESTS    (2),
        .WAIT_TIME0     (300), 
        .TARGET_FBITS0  (3),
        .SIZE0          (3),
        .WAIT_TIME1     (60),
        .TARGET_FBITS1  (3),
        .SIZE1          (3)
    ) tile0 (
        .clk                    (clk               ),                          
        .rst_n                  (rst_n             ),
                                                  
        .src_dev_vr_noc_val     (splitter_tile0_vr_noc_val),
        .src_dev_vr_noc_dat     (splitter_tile0_vr_noc_dat),
        .src_dev_vr_noc_rdy     (splitter_tile0_vr_noc_rdy),
                                                 
        .dev_dst_vr_noc_val     (tile0_merger_vr_noc_val),
        .dev_dst_vr_noc_dat     (tile0_merger_vr_noc_dat),
        .dev_dst_vr_noc_rdy     (tile0_merger_vr_noc_rdy)
    );

    fake_dev #(
        .NUM_REQUESTS    (2),
        .WAIT_TIME0     (300), 
        .TARGET_FBITS0  (4),
        .SIZE0          (4),
        .WAIT_TIME1     (50),
        .TARGET_FBITS1  (4),
        .SIZE1          (10)
    ) tile1 (
        .clk                    (clk               ),                          
        .rst_n                  (rst_n             ),
                                                  
        .src_dev_vr_noc_val     (splitter_tile1_vr_noc_val),
        .src_dev_vr_noc_dat     (splitter_tile1_vr_noc_dat),
        .src_dev_vr_noc_rdy     (splitter_tile1_vr_noc_rdy),
                                                                          
        .dev_dst_vr_noc_val     (tile1_merger_vr_noc_val),
        .dev_dst_vr_noc_dat     (tile1_merger_vr_noc_dat),
        .dev_dst_vr_noc_rdy     (tile1_merger_vr_noc_rdy) 
    );



endmodule
