package axi_pkg;

    parameter                               int DEFAULT_MST_AMT             = 2;
    parameter                               int DEFAULT_SLV_AMT             = 2;
    parameter                               int DEFAULT_OUTSTANDING_AMT     = 8;
    parameter        [0:(DEFAULT_MST_AMT*32)-1] DEFAULT_MST_WEIGHT          = {32'd2, 32'd1};
    parameter                               int DEFAULT_MST_ID_W            = $clog2(DEFAULT_MST_AMT);
    parameter                               int DEFAULT_SLV_ID_W            = $clog2(DEFAULT_SLV_AMT);
    
    // Transaction configuration
    parameter                               int DEFAULT_DATA_WIDTH          = 32;
    parameter                               int DEFAULT_ADDR_WIDTH          = 32;
    parameter                               int DEFAULT_TRANS_MST_ID_W      = 5;                            // Bus width of master transaction ID 
    parameter                               int DEFAULT_TRANS_SLV_ID_W      = DEFAULT_TRANS_MST_ID_W + DEFAULT_MST_ID_W;    // Bus width of slave transaction ID
    parameter                               int DEFAULT_TRANS_BURST_W       = 2;                            // Width of xBURST 
    parameter                               int DEFAULT_TRANS_DATA_LEN_W    = 3;                            // Bus width of xLEN
    parameter                               int DEFAULT_TRANS_DATA_SIZE_W   = 3;                            // Bus width of xSIZE
    parameter                               int DEFAULT_TRANS_WR_RESP_W     = 2;
    
    // Slave info configuration (address mapping mechanism) (Default: The upper bits)
    parameter                               int DEFAULT_SLV_ID_MSB_IDX      = DEFAULT_ADDR_WIDTH - 1;
    parameter                               int DEFAULT_SLV_ID_LSB_IDX      = DEFAULT_ADDR_WIDTH - $clog2(DEFAULT_SLV_AMT);
    
    // Dispatcher DATA depth configuration
    parameter                               int DEFAULT_DSP_RDATA_DEPTH     = 16;

    //Including all the classes
    `include "transaction.sv"
    `include "generator.sv"

         
endpackage
