import axi_pkg::*;

class transaction #(
  int MASTER_COUNT = DEFAULT_MST_AMT;
  int SLAVE_COUNT  = DEFAULT_SLV_AMT;
  int ADDR_WIDTH   = DEFAULT_ADDR_WIDTH;
  int DATA_WIDTH   = DEFAULT_DATA_WIDTH;
  int TRANS_BURST_W = DEFAULT_TRANS_BURST_W;
  int TRANS_MST_W   = DEFAULT_TRANS_MST_W;
  int TRANS_DATA_LEN_W = DEFAULT_TRANS_DATA_LEN_W;
  int TRANS_DATA_SIZE_W  = DEFAULT_TRANS_DATA_SIZE_W;
  int TRANS_MST_ID_W     = DEFAULT_TRANS_MST_ID_W;
  int TRANS_SLV_ID_W     = DEFAULT_TRANS_SLV_ID_W;
  int TRANS_WR_RESP_W    = DEFAULT_TRANS_WR_RESP_W;
);
    rand   [ID_WIDTH*MASTER_COUNT-1:0]          logic m_AWID_i;
    rand   [ADDR_WIDTH*MASTER_COUNT-1:0]        logic m_AWADDR_i;
    rand   [TRANS_BURST_W*MASTER_COUNT-1:0]     logic m_AWBURST_i;
    rand   [TRANS_MST_ID_W*MASTER_COUNT-1:0]    logic m_AWID_i,
    rand   [ADDR_WIDTH*MASTER_COUNT-1:0]        logic m_AWADDR_i,
    rand   [TRANS_BURST_W*MASTER_COUNT-1:0]     logic m_AWBURST_i,
    rand   [TRANS_DATA_LEN_W*MASTER_COUNT-1:0]  logic m_AWLEN_i,
    rand   [TRANS_DATA_SIZE_W*MASTER_COUNT-1:0] logic m_AWSIZE_i,
    rand   [MASTER_COUNT-1:0]                   logic m_AWVALID_i,
    //  - Write data channel
    rand   [DATA_WIDTH*MASTER_COUNT-1:0]        logic m_WDATA_i,
    rand   [MASTER_COUNT-1:0]                   logic m_WLAST_i,
    rand   [MASTER_COUNT-1:0]                   logic m_WVALID_i,
    //  - Write response channel
    rand   [MASTER_COUNT-1:0]                   logic m_BREADY_i,
    //  - Read address channel
    rand   [TRANS_MST_ID_W*MASTER_COUNT-1:0]    logic m_ARID_i,
    rand   [ADDR_WIDTH*MASTER_COUNT-1:0]        logic m_ARADDR_i,
    rand   [TRANS_BURST_W*MASTER_COUNT-1:0]     logic m_ARBURST_i,
    rand   [TRANS_DATA_LEN_W*MASTER_COUNT-1:0]  logic m_ARLEN_i,
    rand   [TRANS_DATA_SIZE_W*MASTER_COUNT-1:0] logic m_ARSIZE_i,
    rand   [MASTER_COUNT-1:0]                   logic m_ARVALID_i,
    //  - Read data channel
    rand   [MASTER_COUNT-1:0]                   logic m_RREADY_i,
    //  - To slave (master interface of thelogic  interconnect)
    //  - Write address channel (master)
    rand   [SLAVE_COUNT-1:0]                   logic s_AWREADY_i,
    //  - Write data channel (master)
    rand   [SLAVE_COUNT-1:0]                   logic s_WREADY_i,
    //  - Write response channel (master)
    rand   [TRANS_SLV_ID_W*SLAVE_COUNT-1:0]    logic s_BID_i,
    rand   [TRANS_WR_RESP_W*SLAVE_COUNT-1:0]   logic s_BRESP_i,
    rand   [SLAVE_COUNT-1:0]                   logic s_BVALID_i,
    //  - Read address channel (master)
    rand   [SLAVE_COUNT-1:0]                   logic s_ARREADY_i,
    //  - Read data channel (master)
    rand   [TRANS_SLV_ID_W*SLAVE_COUNT-1:0]    logic s_RID_i,
    rand   [DATA_WIDTH*SLAVE_COUNT-1:0]        logic s_RDATA_i,
    rand   [TRANS_WR_RESP_W*SLAVE_COUNT-1:0]   logic s_RRESP_i,
    rand   [SLAVE_COUNT-1:0]                   logic s_RLAST_i,
    rand   [SLAVE_COUNT-1:0]                   logic s_RVALID_i,

endclass
