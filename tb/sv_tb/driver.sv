// import axi_pkg.sv::*; --> This is taken care inside the environment_pkg.sv

class driver;

    // widths come from the package (imported by axi_env_pkg)
    localparam int ID_W    = DEFAULT_TRANS_MST_ID_W;
    localparam int ADDR_W  = DEFAULT_ADDR_WIDTH;
    localparam int DATA_W  = DEFAULT_DATA_WIDTH;
    localparam int BURST_W = DEFAULT_TRANS_BURST_W;
    localparam int LEN_W   = DEFAULT_TRANS_DATA_LEN_W;
    localparam int SIZE_W  = DEFAULT_TRANS_DATA_SIZE_W;
    localparam int RESP_W  = DEFAULT_TRANS_WR_RESP_W;
    
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

    task write(input axi_wr_tx tr);
        $display("[DRV] Transaction object from generator : AWADDR : %0h AWLEN : %0d AWBURST : %0d AWID : %0d AWSIZE : %0d AWDATA : %0p", tr.awaddr ,tr.awlen, tr.awburst, tr.awid, tr.awsize, tr.wdata);
        mbxdm.put(tr);
        
        @(posedge vif.ACLK_i);
        vif.m_AWVALID_i[mst_id]                          <= 1'b1;
        vif.m_AWADDR_i[ADDR_W*(mst_id+1)-1 -: ADDR_W]    <= tr.awaddr;
        vif.m_AWID_i[ID_W * (mst_id+1)-1 -: ID_W ]       <= tr.awid;
        vif.m_AWLEN_i[LEN_W*(mst_id+1)-1 -: LEN_W]       <= tr.awlen;
        vif.m_AWBURST_i[BURST_W*(mst_id+1)-1 -: BURST_W] <= tr.awburst;
        vif.m_AWSIZE_i[SIZE_W* (mst_id+1)-1 -: SIZE_W]   <= tr.awsize;
        
        do @(posedge vif.ACLK_i); while (!vif.m_AWREADY_o[mst_id]); //Hold the values and move clock until the AWREADY is being asserted.
        vif.m_AWVALID_i[mst_id]                          <= 1'b0;
        
        for(int i = 0; i < tr.wdata.size() ; i++) begin)            //Send as many transfers as per the beat count.The beat count in the constraint 
            vif.m_WVALID_i[mst_id]                            <= 1'b1;
            vif.m_WDATA_i[DATA_W*(mst_id+1)-1 -: DATA_W]      <= tr.wdata[i];
            vif.m_WLAST_i[mst_id]                             <= (i == tr.wdata.size()-1);
            do @(posedge vif.ACLK_i); while (!vif.m_WREADY_o);
        end
        vif.m_WVALID_i[mst_id] <= 1'b0;
        vif.m_WLAST_i[mst_id]  <= 1'b0;

        //After transfer, ready to get the response
        vif.m_BREADY_i[mst_id] <= 1'b1;
        do @(posedge vif.ACLK_i); while (!vif.m_BVALID_o[mst_id]);
        $display("[DRV] Master%0d got BRepsonse: %0d",mst_id, vif.m_BRESP_o[RESP_W * (mst_id+1)-1 -: RESP_W]) ;
        vif.m_BREADY_i[mst_id] <= 1'b0;
    endtask

    task run();
        
        forever begin
            mbxgd.get(tr);
            @(posedge vif.ACLK_i);

            write(tr);
        end    
    endtask

endclass
