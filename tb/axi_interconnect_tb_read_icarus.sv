`timescale 1ns / 1ps
// =============================================================================
// WRITE-ONLY sanity testbench for axi_interconnect (Icarus Verilog friendly)
//   iverilog -g2012 ...      (no classes / mailboxes / structs / rand needed)
//
// Topology : 4 masters x 4 slaves, slave chosen by ADDR[31:30]
// Slaves   : behavioural write FSM + 256-word memory (indexed by ADDR[9:2])
//
// Tests    : T1  single-beat write, master0 -> every slave   (address decode)
//            T2  8-beat burst write, master1 -> slave2        (data, WLAST)
//            T3  4 masters write slave0 at the same time      (arbitration, ID routing)
//
// What is checked (no read-back; everything is checked where the write lands)
//   slave side : AW arrives at the right slave, every WDATA beat == pat(address),
//                WLAST only on the last beat, number of completed writes per slave
//   master side: BID == AWID, BRESP == OKAY, no hang (global timeout)
//
// Read channels: all interface signals stay declared and connected to the DUT;
// the read side is simply held idle (see "READ SIDE - IDLE" below).
// To add reads later: restore a slave read FSM and an rd_burst task.
//
// Output : "TESTBENCH PASSED" / "TESTBENCH FAILED (n errors)", VCD for GTKWave
// =============================================================================
module axi_interconnect_tb_icarus;

    // ---- Configuration (must match DUT defaults) ----------------------------
    localparam MST_AMT           = 4;
    localparam SLV_AMT           = 4;
    localparam MST_ID_W          = 2;                         // $clog2(MST_AMT)
    localparam DATA_WIDTH        = 32;
    localparam ADDR_WIDTH        = 32;
    localparam TRANS_MST_ID_W    = 5;
    localparam TRANS_SLV_ID_W    = TRANS_MST_ID_W + MST_ID_W; // 7
    localparam TRANS_BURST_W     = 2;
    localparam TRANS_DATA_LEN_W  = 3;                         // max 8 beats
    localparam TRANS_DATA_SIZE_W = 3;
    localparam TRANS_WR_RESP_W   = 2;

    localparam [1:0] BURST_INCR  = 2'b01;
    localparam [2:0] SIZE_4B     = 3'd2;
    localparam       TIMEOUT_NS  = 200000;

    // ---- Clock / reset ------------------------------------------------------
    reg ACLK_i;
    reg ARESETn_i;
    initial ACLK_i = 1'b0;
    always #5 ACLK_i = ~ACLK_i;                               // 100 MHz

    // ---- DUT signals (flattened buses, master/slave index = bit slice) ------
    // Master side (driven by TB)
    reg  [TRANS_MST_ID_W*MST_AMT-1:0]    m_AWID_i;
    reg  [ADDR_WIDTH*MST_AMT-1:0]        m_AWADDR_i;
    reg  [TRANS_BURST_W*MST_AMT-1:0]     m_AWBURST_i;
    reg  [TRANS_DATA_LEN_W*MST_AMT-1:0]  m_AWLEN_i;
    reg  [TRANS_DATA_SIZE_W*MST_AMT-1:0] m_AWSIZE_i;
    reg  [MST_AMT-1:0]                   m_AWVALID_i;
    reg  [DATA_WIDTH*MST_AMT-1:0]        m_WDATA_i;
    reg  [MST_AMT-1:0]                   m_WLAST_i;
    reg  [MST_AMT-1:0]                   m_WVALID_i;
    reg  [MST_AMT-1:0]                   m_BREADY_i;
    reg  [TRANS_MST_ID_W*MST_AMT-1:0]    m_ARID_i;
    reg  [ADDR_WIDTH*MST_AMT-1:0]        m_ARADDR_i;
    reg  [TRANS_BURST_W*MST_AMT-1:0]     m_ARBURST_i;
    reg  [TRANS_DATA_LEN_W*MST_AMT-1:0]  m_ARLEN_i;
    reg  [TRANS_DATA_SIZE_W*MST_AMT-1:0] m_ARSIZE_i;
    reg  [MST_AMT-1:0]                   m_ARVALID_i;
    reg  [MST_AMT-1:0]                   m_RREADY_i;
    wire [MST_AMT-1:0]                   m_AWREADY_o;
    wire [MST_AMT-1:0]                   m_WREADY_o;
    wire [TRANS_MST_ID_W*MST_AMT-1:0]    m_BID_o;
    wire [TRANS_WR_RESP_W*MST_AMT-1:0]   m_BRESP_o;
    wire [MST_AMT-1:0]                   m_BVALID_o;
    wire [MST_AMT-1:0]                   m_ARREADY_o;
    wire [TRANS_MST_ID_W*MST_AMT-1:0]    m_RID_o;
    wire [DATA_WIDTH*MST_AMT-1:0]        m_RDATA_o;
    wire [TRANS_WR_RESP_W*MST_AMT-1:0]   m_RRESP_o;
    wire [MST_AMT-1:0]                   m_RLAST_o;
    wire [MST_AMT-1:0]                   m_RVALID_o;

    // Slave side (driven by slave models below)
    reg  [SLV_AMT-1:0]                   s_AWREADY_i;
    reg  [SLV_AMT-1:0]                   s_WREADY_i;
    reg  [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_BID_i;
    reg  [TRANS_WR_RESP_W*SLV_AMT-1:0]   s_BRESP_i;
    reg  [SLV_AMT-1:0]                   s_BVALID_i;
    reg  [SLV_AMT-1:0]                   s_ARREADY_i;
    reg  [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_RID_i;
    reg  [DATA_WIDTH*SLV_AMT-1:0]        s_RDATA_i;
    reg  [TRANS_WR_RESP_W*SLV_AMT-1:0]   s_RRESP_i;
    reg  [SLV_AMT-1:0]                   s_RLAST_i;
    reg  [SLV_AMT-1:0]                   s_RVALID_i;
    wire [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_AWID_o;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        s_AWADDR_o;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     s_AWBURST_o;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  s_AWLEN_o;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] s_AWSIZE_o;
    wire [SLV_AMT-1:0]                   s_AWVALID_o;
    wire [DATA_WIDTH*SLV_AMT-1:0]        s_WDATA_o;
    wire [SLV_AMT-1:0]                   s_WLAST_o;
    wire [SLV_AMT-1:0]                   s_WVALID_o;
    wire [SLV_AMT-1:0]                   s_BREADY_o;
    wire [TRANS_SLV_ID_W*SLV_AMT-1:0]    s_ARID_o;
    wire [ADDR_WIDTH*SLV_AMT-1:0]        s_ARADDR_o;
    wire [TRANS_BURST_W*SLV_AMT-1:0]     s_ARBURST_o;
    wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]  s_ARLEN_o;
    wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0] s_ARSIZE_o;
    wire [SLV_AMT-1:0]                   s_ARVALID_o;
    wire [SLV_AMT-1:0]                   s_RREADY_o;

    // ---- DUT ----------------------------------------------------------------
    axi_interconnect dut (
        .ACLK_i(ACLK_i), .ARESETn_i(ARESETn_i),
        .m_AWID_i(m_AWID_i), .m_AWADDR_i(m_AWADDR_i), .m_AWBURST_i(m_AWBURST_i),
        .m_AWLEN_i(m_AWLEN_i), .m_AWSIZE_i(m_AWSIZE_i), .m_AWVALID_i(m_AWVALID_i),
        .m_WDATA_i(m_WDATA_i), .m_WLAST_i(m_WLAST_i), .m_WVALID_i(m_WVALID_i),
        .m_BREADY_i(m_BREADY_i),
        .m_ARID_i(m_ARID_i), .m_ARADDR_i(m_ARADDR_i), .m_ARBURST_i(m_ARBURST_i),
        .m_ARLEN_i(m_ARLEN_i), .m_ARSIZE_i(m_ARSIZE_i), .m_ARVALID_i(m_ARVALID_i),
        .m_RREADY_i(m_RREADY_i),
        .s_AWREADY_i(s_AWREADY_i), .s_WREADY_i(s_WREADY_i),
        .s_BID_i(s_BID_i), .s_BRESP_i(s_BRESP_i), .s_BVALID_i(s_BVALID_i),
        .s_ARREADY_i(s_ARREADY_i),
        .s_RID_i(s_RID_i), .s_RDATA_i(s_RDATA_i), .s_RRESP_i(s_RRESP_i),
        .s_RLAST_i(s_RLAST_i), .s_RVALID_i(s_RVALID_i),
        .m_AWREADY_o(m_AWREADY_o), .m_WREADY_o(m_WREADY_o),
        .m_BID_o(m_BID_o), .m_BRESP_o(m_BRESP_o), .m_BVALID_o(m_BVALID_o),
        .m_ARREADY_o(m_ARREADY_o),
        .m_RID_o(m_RID_o), .m_RDATA_o(m_RDATA_o), .m_RRESP_o(m_RRESP_o),
        .m_RLAST_o(m_RLAST_o), .m_RVALID_o(m_RVALID_o),
        .s_AWID_o(s_AWID_o), .s_AWADDR_o(s_AWADDR_o), .s_AWBURST_o(s_AWBURST_o),
        .s_AWLEN_o(s_AWLEN_o), .s_AWSIZE_o(s_AWSIZE_o), .s_AWVALID_o(s_AWVALID_o),
        .s_WDATA_o(s_WDATA_o), .s_WLAST_o(s_WLAST_o), .s_WVALID_o(s_WVALID_o),
        .s_BREADY_o(s_BREADY_o),
        .s_ARID_o(s_ARID_o), .s_ARADDR_o(s_ARADDR_o), .s_ARBURST_o(s_ARBURST_o),
        .s_ARLEN_o(s_ARLEN_o), .s_ARSIZE_o(s_ARSIZE_o), .s_ARVALID_o(s_ARVALID_o),
        .s_RREADY_o(s_RREADY_o)
    );

    // ---- Error bookkeeping --------------------------------------------------
    integer errors;
    initial errors = 0;

    task automatic fail(input [8*40-1:0] what, input [31:0] got, input [31:0] exp);
        begin
            errors = errors + 1;
            $display("[FAIL] t=%0t  %0s  got=%h exp=%h", $time, what, got, exp);
        end
    endtask

    // ---- Data pattern: a hash of the beat's byte address --------------------
    // The master sends pat(address); each slave re-computes it from the address
    // it received and compares. This replaces read-back as the data check.
    function automatic [31:0] pat(input [31:0] a);
        pat = a * 32'h9E3779B1;
    endfunction

    // ---- Per-slave count of completed writes (checked at end of test) -------
    integer wr_cnt [0:SLV_AMT-1];
    integer exp_cnt[0:SLV_AMT-1];

    // ---- Slave models: write FSM only, always-ready, 1 write at a time ------
    //   W_IDLE : AWREADY=1; on AW handshake latch id/addr/len, check slave decode
    //   W_DATA : WREADY=1;  per beat -> store, check WDATA & WLAST; last beat -> BVALID
    //   W_RESP : hold BVALID until DUT's BREADY
    genvar g;
    generate
        for (g = 0; g < SLV_AMT; g = g + 1) begin : slv
            localparam W_IDLE = 0, W_DATA = 1, W_RESP = 2;

            reg [31:0] mem [0:255];
            integer    k;
            initial for (k = 0; k < 256; k = k + 1) mem[k] = 32'h0;

            reg [1:0]                  wst;
            reg [TRANS_SLV_ID_W-1:0]   w_id;
            reg [31:0]                 w_addr;
            reg [2:0]                  w_len, w_cnt;
            reg [7:0]                  w_idx;

            always @(posedge ACLK_i) begin
                if (!ARESETn_i) begin
                    wst <= W_IDLE;
                    s_AWREADY_i[g] <= 1'b0;
                    s_WREADY_i[g]  <= 1'b0;
                    s_BVALID_i[g]  <= 1'b0;
                    s_BID_i[g*TRANS_SLV_ID_W +: TRANS_SLV_ID_W] <= 0;
                    s_BRESP_i[g*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] <= 0;
                end else begin
                    case (wst)
                    W_IDLE: begin
                        s_AWREADY_i[g] <= 1'b1;
                        if (s_AWVALID_o[g] && s_AWREADY_i[g]) begin
                            w_id   <= s_AWID_o[g*TRANS_SLV_ID_W +: TRANS_SLV_ID_W];
                            w_addr <= s_AWADDR_o[g*ADDR_WIDTH +: ADDR_WIDTH];
                            w_len  <= s_AWLEN_o[g*TRANS_DATA_LEN_W +: TRANS_DATA_LEN_W];
                            w_cnt  <= 0;
                            if (s_AWADDR_o[g*ADDR_WIDTH+30 +: 2] !== g[1:0])
                                fail("slave got AW for wrong slave", s_AWADDR_o[g*ADDR_WIDTH +: ADDR_WIDTH], g);
                            s_AWREADY_i[g] <= 1'b0;
                            s_WREADY_i[g]  <= 1'b1;
                            wst <= W_DATA;
                        end
                    end
                    W_DATA: begin
                        if (s_WVALID_o[g] && s_WREADY_i[g]) begin
                            w_idx = w_addr[9:2] + w_cnt;                  // 8-bit wrap
                            mem[w_idx] <= s_WDATA_o[g*DATA_WIDTH +: DATA_WIDTH];
                            if (s_WDATA_o[g*DATA_WIDTH +: DATA_WIDTH] !== pat(w_addr + (w_cnt << 2)))
                                fail("slave WDATA mismatch", s_WDATA_o[g*DATA_WIDTH +: DATA_WIDTH], pat(w_addr + (w_cnt << 2)));
                            if (s_WLAST_o[g] !== (w_cnt == w_len))
                                fail("slave WLAST position", s_WLAST_o[g], (w_cnt == w_len));
                            w_cnt <= w_cnt + 1'b1;
                            if (w_cnt == w_len) begin
                                wr_cnt[g]     <= wr_cnt[g] + 1;
                                s_WREADY_i[g] <= 1'b0;
                                s_BVALID_i[g] <= 1'b1;
                                s_BID_i[g*TRANS_SLV_ID_W +: TRANS_SLV_ID_W] <= w_id;
                                s_BRESP_i[g*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] <= 2'b00;
                                wst <= W_RESP;
                            end
                        end
                    end
                    W_RESP: begin
                        if (s_BVALID_i[g] && s_BREADY_o[g]) begin
                            s_BVALID_i[g] <= 1'b0;
                            wst <= W_IDLE;
                        end
                    end
                    default: wst <= W_IDLE;
                    endcase
                end
            end
        end
    endgenerate

    // ---- READ SIDE - IDLE ---------------------------------------------------
    // Ports stay connected to the DUT; the TB just never starts a read and the
    // slaves never respond to one, so nothing is left floating or X.
    //   master side: ARVALID = 0, RREADY = 0   (set in the stimulus init below)
    //   slave side : ARREADY = 0, RVALID = 0, RLAST = 0, RID/RDATA/RRESP = 0
    initial begin
        s_ARREADY_i = {SLV_AMT{1'b0}};
        s_RID_i     = {(TRANS_SLV_ID_W*SLV_AMT){1'b0}};
        s_RDATA_i   = {(DATA_WIDTH*SLV_AMT){1'b0}};
        s_RRESP_i   = {(TRANS_WR_RESP_W*SLV_AMT){1'b0}};
        s_RLAST_i   = {SLV_AMT{1'b0}};
        s_RVALID_i  = {SLV_AMT{1'b0}};
    end

    // ---- Master-side write task (drive at posedge+1ns, sample at posedge) ---
    // AW -> W beats -> wait B. Self-checks BID and BRESP.
    task automatic wr_burst(input integer mst, input [4:0] id,
                            input [31:0] addr, input integer len);
        integer i;
        begin
            // AW channel
            @(posedge ACLK_i); #1;
            m_AWID_i   [mst*TRANS_MST_ID_W    +: TRANS_MST_ID_W]    = id;
            m_AWADDR_i [mst*ADDR_WIDTH        +: ADDR_WIDTH]        = addr;
            m_AWBURST_i[mst*TRANS_BURST_W     +: TRANS_BURST_W]     = BURST_INCR;
            m_AWLEN_i  [mst*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W]  = len[2:0];
            m_AWSIZE_i [mst*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W] = SIZE_4B;
            m_AWVALID_i[mst] = 1'b1;
            @(posedge ACLK_i);
            while (!m_AWREADY_o[mst]) @(posedge ACLK_i);
            #1 m_AWVALID_i[mst] = 1'b0;

            // W channel
            for (i = 0; i <= len; i = i + 1) begin
                m_WDATA_i[mst*DATA_WIDTH +: DATA_WIDTH] = pat(addr + i*4);
                m_WLAST_i[mst]  = (i == len);
                m_WVALID_i[mst] = 1'b1;
                @(posedge ACLK_i);
                while (!m_WREADY_o[mst]) @(posedge ACLK_i);
                #1;
            end
            m_WVALID_i[mst] = 1'b0;
            m_WLAST_i[mst]  = 1'b0;

            // B channel
            m_BREADY_i[mst] = 1'b1;
            @(posedge ACLK_i);
            while (!m_BVALID_o[mst]) @(posedge ACLK_i);
            if (m_BID_o[mst*TRANS_MST_ID_W +: TRANS_MST_ID_W] !== id)
                fail("BID mismatch", m_BID_o[mst*TRANS_MST_ID_W +: TRANS_MST_ID_W], id);
            if (m_BRESP_o[mst*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] !== 2'b00)
                fail("BRESP not OKAY", m_BRESP_o[mst*TRANS_WR_RESP_W +: TRANS_WR_RESP_W], 0);
            #1 m_BREADY_i[mst] = 1'b0;
        end
    endtask

    // ---- Stimulus -----------------------------------------------------------
    integer s;
    reg [8*128-1:0] vcd_file;

    initial begin
        if (!$value$plusargs("VCD=%s", vcd_file)) vcd_file = "wave.vcd";
        $dumpfile(vcd_file);
        $dumpvars(0, axi_interconnect_tb_icarus);
    end

    // Global hang guard
    initial begin
        #(TIMEOUT_NS);
        $display("[FAIL] simulation timeout - DUT hung (no handshake)");
        $display("TESTBENCH FAILED (timeout)");
        $finish;
    end

    initial begin
        // idle values (read channels held idle too)
        m_AWID_i = 0; m_AWADDR_i = 0; m_AWBURST_i = 0; m_AWLEN_i = 0; m_AWSIZE_i = 0; m_AWVALID_i = 0;
        m_WDATA_i = 0; m_WLAST_i = 0; m_WVALID_i = 0; m_BREADY_i = 0;
        m_ARID_i = 0; m_ARADDR_i = 0; m_ARBURST_i = 0; m_ARLEN_i = 0; m_ARSIZE_i = 0; m_ARVALID_i = 0;
        m_RREADY_i = 0;
        for (s = 0; s < SLV_AMT; s = s + 1) wr_cnt[s] = 0;
        // writes each slave should have completed by the end of T1..T3
        exp_cnt[0] = 5;   // T1 + T3 (x4)
        exp_cnt[1] = 1;   // T1
        exp_cnt[2] = 2;   // T1 + T2
        exp_cnt[3] = 1;   // T1
        // reset
        ARESETn_i = 1'b0;
        repeat (5) @(posedge ACLK_i);
        #1 ARESETn_i = 1'b1;
        repeat (3) @(posedge ACLK_i);

        // T1: single-beat write, master 0 -> every slave (address decode)
        $display("T1: single-beat write, master0 -> slave0..3");
        for (s = 0; s < SLV_AMT; s = s + 1)
            wr_burst(0, 5'h01 + s, s*32'h4000_0000 + 32'h100, 0);

        // T2: full 8-beat burst, master 1 -> slave 2
        $display("T2: 8-beat burst write, master1 -> slave2");
        wr_burst(1, 5'h0A, 32'h8000_0040, 7);

        // T3: all 4 masters write slave 0 at once (arbitration + ID routing)
        $display("T3: 4 masters contend for slave0");
        fork
            wr_burst(0, 5'h10, 32'h0000_0000, 3);
            wr_burst(1, 5'h11, 32'h0000_0040, 3);
            wr_burst(2, 5'h12, 32'h0000_0080, 3);
            wr_burst(3, 5'h13, 32'h0000_00C0, 3);
        join

        repeat (5) @(posedge ACLK_i);

        // Every write must have reached its slave
        for (s = 0; s < SLV_AMT; s = s + 1)
            if (wr_cnt[s] !== exp_cnt[s]) begin
                errors = errors + 1;
                $display("[FAIL] slave%0d completed %0d writes, expected %0d", s, wr_cnt[s], exp_cnt[s]);
            end

        if (errors == 0) $display("TESTBENCH PASSED");
        else             $display("TESTBENCH FAILED (%0d errors)", errors);
        $finish;
    end

endmodule
