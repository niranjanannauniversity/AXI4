import axi_pkg :: *;

interface  axi_interface#(
    parameter int MST_AMT    =  axi_pkg::DEFAULT_MST_AMT                ,
    parameter int OUTS_AMT   =  axi_pkg::DEFAULT_OUTSTANDING_AMT        ,
    parameter bit [0:MST_AMT*32-1]MST_WEIGHT =  axi_pkg::DEFAULT_MST_WEIGHT             ,
    parameter int SLAVE_ID_W =  axi_pkg::DEFAULT_TRANS_SLV_ID_W         ,
    parameter int WRITE_RESP =  axi_pkg::DEFAULT_TRANS_WR_RESP_W         ,

    parameter int ADDR_W     =  axi_pkg::DEFAULT_ADDR_WIDTH             ,
    parameter int DATA_W     =  axi_pkg::DEFAULT_DATA_WIDTH             ,
    parameter int ID_W       =  axi_pkg::DEFAULT_TRANS_MST_ID_W         ,
    parameter int BURST_W    =  axi_pkg::DEFAULT_TRANS_BURST_W          ,
    parameter int LEN_W      =  axi_pkg::DEFAULT_TRANS_DATA_LEN_W       ,
    parameter int SIZE_W     =  axi_pkg::DEFAULT_TRANS_DATA_SIZE_W      ,
    parameter int SLAVE_AMT  =  axi_pkg::DEFAULT_SLV_AMT                ,
    parameter int SLAVE_BIT  =  axi_pkg::DEFAULT_SLV_ID_W               ,

    parameter int SLV_ID_MSB_IDX      = axi_pkg::DEFAULT_SLV_ID_MSB_IDX ,
    parameter int SLV_ID_LSB_IDX      = axi_pkg::DEFAULT_SLV_ID_LSB_IDX ,
    parameter int DSP_RDATA_DEPTH     = axi_pkg::DEFAULT_DSP_RDATA_DEPTH

)(input bit ACLK_i);
    
    logic                                 ARESETn_i;
    logic [ID_W*MST_AMT-1:0]              m_AWID_i;
    logic [ADDR_W*MST_AMT-1:0]            m_AWADDR_i;
    logic [BURST_W*MST_AMT-1:0]           m_AWBURST_i;
    logic [LEN_W*MST_AMT-1:0]             m_AWLEN_i;
    logic [SIZE_W*MST_AMT-1:0]            m_AWSIZE_i;
    logic [MST_AMT-1:0]                   m_AWVALID_i;
    
    
    logic [DATA_W*MST_AMT-1:0]            m_WDATA_i;
    logic [MST_AMT-1:0]                   m_WLAST_i;
    logic [MST_AMT-1:0]                   m_WVALID_i;
    
   
    logic [MST_AMT-1:0]                   m_BREADY_i;
    
  
    logic [ID_W*MST_AMT-1:0]              m_ARID_i;
    logic [ADDR_W*MST_AMT-1:0]            m_ARADDR_i;
    logic [BURST_W*MST_AMT-1:0]           m_ARBURST_i;
    logic [LEN_W*MST_AMT-1:0]             m_ARLEN_i;
    logic [SIZE_W*MST_AMT-1:0]            m_ARSIZE_i;
    logic [MST_AMT-1:0]                   m_ARVALID_i;
    
 
    logic [MST_AMT-1:0]                   m_RREADY_i;



    logic [SLAVE_AMT-1:0]                 s_AWREADY_i;
    

    logic [SLAVE_AMT-1:0]                 s_WREADY_i;
    
    logic [SLAVE_ID_W*SLAVE_AMT-1:0]     s_BID_i;
    logic [WRITE_RESP*SLAVE_AMT-1:0]      s_BRESP_i;
    logic [SLAVE_AMT-1:0]                 s_BVALID_i;
    
    
    logic [SLAVE_AMT-1:0]                 s_ARREADY_i;
    
   
    logic [SLAVE_ID_W*SLAVE_AMT-1:0]     s_RID_i;
    logic [DATA_W*SLAVE_AMT-1:0]          s_RDATA_i;
    logic [WRITE_RESP*SLAVE_AMT-1:0]      s_RRESP_i;
    logic [SLAVE_AMT-1:0]                 s_RLAST_i;
    logic [SLAVE_AMT-1:0]                 s_RVALID_i;
    
    logic [MST_AMT-1:0]                   m_AWREADY_o;
    logic [MST_AMT-1:0]                   m_WREADY_o;
    logic [ID_W*MST_AMT-1:0]              m_BID_o;
    logic [WRITE_RESP*MST_AMT-1:0]        m_BRESP_o;
    logic [MST_AMT-1:0]                   m_BVALID_o;
    logic [MST_AMT-1:0]                   m_ARREADY_o;
    logic [ID_W*MST_AMT-1:0]              m_RID_o;
    logic [DATA_W*MST_AMT-1:0]            m_RDATA_o;
    logic [WRITE_RESP*MST_AMT-1:0]        m_RRESP_o;
    logic [MST_AMT-1:0]                   m_RLAST_o;
    logic [MST_AMT-1:0]                   m_RVALID_o;
    
    
    logic [SLAVE_ID_W*SLAVE_AMT-1:0]     s_AWID_o;
    logic [ADDR_W*SLAVE_AMT-1:0]          s_AWADDR_o;
    logic [BURST_W*SLAVE_AMT-1:0]         s_AWBURST_o;
    logic [LEN_W*SLAVE_AMT-1:0]           s_AWLEN_o;
    logic [SIZE_W*SLAVE_AMT-1:0]          s_AWSIZE_o;
    logic [SLAVE_AMT-1:0]                 s_AWVALID_o;
    logic [DATA_W*SLAVE_AMT-1:0]          s_WDATA_o;
    logic [SLAVE_AMT-1:0]                 s_WLAST_o;
    logic [SLAVE_AMT-1:0]                 s_WVALID_o;
    logic [SLAVE_AMT-1:0]                 s_BREADY_o;
    logic [SLAVE_ID_W*SLAVE_AMT-1:0]     s_ARID_o;
    logic [ADDR_W*SLAVE_AMT-1:0]          s_ARADDR_o;
    logic [BURST_W*SLAVE_AMT-1:0]         s_ARBURST_o;
    logic [LEN_W*SLAVE_AMT-1:0]           s_ARLEN_o;
    logic [SIZE_W*SLAVE_AMT-1:0]          s_ARSIZE_o;
    logic [SLAVE_AMT-1:0]                 s_ARVALID_o;
    logic [SLAVE_AMT-1:0]                 s_RREADY_o;


    modport DUT (input ACLK_i,
               ARESETn_i,
               m_AWID_i, m_AWADDR_i, m_AWBURST_i, m_AWLEN_i, m_AWSIZE_i, m_AWVALID_i,
               m_WDATA_i, m_WLAST_i, m_WVALID_i, m_BREADY_i,
               m_ARID_i, m_ARADDR_i, m_ARBURST_i, m_ARLEN_i, m_ARSIZE_i, m_ARVALID_i,
               m_RREADY_i,
               s_AWREADY_i, s_WREADY_i, s_BID_i, s_BRESP_i, s_BVALID_i,
               s_ARREADY_i, s_RID_i, s_RDATA_i, s_RRESP_i, s_RLAST_i, s_RVALID_i, 
                 output m_AWREADY_o, m_WREADY_o, m_BID_o, m_BRESP_o, m_BVALID_o,
               m_ARREADY_o, m_RID_o, m_RDATA_o, m_RRESP_o, m_RLAST_o, m_RVALID_o,
               s_AWID_o, s_AWADDR_o, s_AWBURST_o, s_AWLEN_o, s_AWSIZE_o, s_AWVALID_o,
               s_WDATA_o, s_WLAST_o, s_WVALID_o, s_BREADY_o,
               s_ARID_o, s_ARADDR_o, s_ARBURST_o, s_ARLEN_o, s_ARSIZE_o, s_ARVALID_o,
               s_RREADY_o                 
    );

    modport TEST (input ACLK_i, 
                 m_AWREADY_o, m_WREADY_o, m_BID_o, m_BRESP_o, m_BVALID_o,
                 m_ARREADY_o, m_RID_o, m_RDATA_o, m_RRESP_o, m_RLAST_o, m_RVALID_o,
                 s_AWID_o, s_AWADDR_o, s_AWBURST_o, s_AWLEN_o, s_AWSIZE_o, s_AWVALID_o,
                 s_WDATA_o, s_WLAST_o, s_WVALID_o, s_BREADY_o,
                 s_ARID_o, s_ARADDR_o, s_ARBURST_o, s_ARLEN_o, s_ARSIZE_o, s_ARVALID_o,
                 s_RREADY_o,
                 output ARESETn_i,  
                 m_AWID_i, m_AWADDR_i, m_AWBURST_i, m_AWLEN_i, m_AWSIZE_i, m_AWVALID_i,
                 m_WDATA_i, m_WLAST_i, m_WVALID_i, m_BREADY_i,
                 m_ARID_i, m_ARADDR_i, m_ARBURST_i, m_ARLEN_i, m_ARSIZE_i, m_ARVALID_i,
                 m_RREADY_i,
                 s_AWREADY_i, s_WREADY_i, s_BID_i, s_BRESP_i, s_BVALID_i,
                 s_ARREADY_i, s_RID_i, s_RDATA_i, s_RRESP_i, s_RLAST_i, s_RVALID_i
    
    );

endinterface
