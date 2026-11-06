// import axi_pkg.sv::*; --> This is taken care inside the environment_pkg.sv

class driver;

    // widths come from the package (imported by axi_env_pkg)
    localparam int ID_W    = DEFAULT_TRANS_MST_ID_W;
    localparam int ADDR_W  = DEFAULT_ADDR_WIDTH;
    localparam int DATA_W  = DEFAULT_DATA_WIDTH;
    localparam int BURST_W = DEFAULT_TRANS_BURST_W;
    localparam int LEN_W   = DEFAULT_TRANS_DATA_LEN_W;
    localparam int SIZE_W  = DEFAULT_TRANS_DATA_SIZE_W;
    
    axi_wr_tx tr;

    mailbox #(axi_wr_tx) mbxgd;
    mailbox #(axi_wr_tx) mbxdm; 

    virtual axi_interface vif;
    
    int mst_id; // Master Port that the driver drives

    function new(mailbox #(axi_wr_tx) mbxgd,
                 mailbox #(axi_wr_tx) mbxdm,
                 virtual axi_interface vif,
                 int mst_id
    );
        this.mbxgd  = mbxgd;
        this.mbxdm  = mbxdm;
        this.vif    = vif;
        this.mst_id = mst_id;

    endfunction

    task init_signals();
        vif.m_AWID_i   [ID_W   *(mst_id+1)-1 -: ID_W   ] <= '0;
        vif.m_AWADDR_i [ADDR_W *(mst_id+1)-1 -: ADDR_W ] <= '0;
        vif.m_AWBURST_i[BURST_W*(mst_id+1)-1 -: BURST_W] <= '0;
        vif.m_AWLEN_i  [LEN_W  *(mst_id+1)-1 -: LEN_W  ] <= '0;
        vif.m_AWSIZE_i [SIZE_W *(mst_id+1)-1 -: SIZE_W ] <= '0;
        vif.m_AWVALID_i[mst_id]                          <= 1'b0;
        vif.m_WDATA_i  [DATA_W *(mst_id+1)-1 -: DATA_W ] <= '0;
        vif.m_WLAST_i  [mst_id]                          <= 1'b0;
        vif.m_WVALID_i [mst_id]                          <= 1'b0;
        vif.m_BREADY_i [mst_id]                          <= 1'b0;
        // read-channel inputs: tie off for now (write-only TB)
        vif.m_ARVALID_i[mst_id]                          <= 1'b0;
        vif.m_RREADY_i [mst_id]                          <= 1'b0;

    endtask

    task run();

        

    endtask

endclass
