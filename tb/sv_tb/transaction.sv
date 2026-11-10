
class axi_wr_tx #(
    parameter int ADDR_W     =  axi_pkg::DEFAULT_ADDR_WIDTH             ,    
    parameter int DATA_W     =  axi_pkg::DEFAULT_DATA_WIDTH             ,
    parameter int ID_W       =  axi_pkg::DEFAULT_TRANS_MST_ID_W         ,
    parameter int BURST_W    =  axi_pkg::DEFAULT_TRANS_BURST_W          ,    
    parameter int LEN_W      =  axi_pkg::DEFAULT_TRANS_DATA_LEN_W       ,    
    parameter int SIZE_W     =  axi_pkg::DEFAULT_TRANS_DATA_SIZE_W      ,        
    parameter int SLAVE_AMT  =  axi_pkg::DEFAULT_SLV_AMT                ,
    parameter int SLAVE_BIT  =  axi_pkg::DEFAULT_SLV_ID_W                 
);

    //AW channel 
    rand bit [ADDR_W-1:0]  awaddr; 
    rand bit [ID_W-1:0]    awid;
    rand bit [BURST_W-1:0] awburst;    
    rand bit [LEN_W-1:0]   awlen;
    rand bit [SIZE_W-1:0]  awsize;
    
    //W channel - with dynamic array for beats to be accomodated.
    rand bit [DATA_W-1:0]  wdata[];

    //Helpers 
    rand bit [SLAVE_BIT-1:0] target_slave_id;                 //Control knob to select which slave
    int mst_id;                                               //This says which master is transmitting from the master side to the scoreboard, so the scoreboard can assert this with the received s_AWID_o


    //CONSTRAINTS
    
    //Fixing only the slave instance as per the number of slaves 
    constraint slave_id { 
        target_slave_id < SLAVE_BIT ; 
        awaddr[ADDR_W-1 : ADDR_W - $clog2(SLAVE_BIT)] == target_slave_id;
    }
 
    //wdata size is number of beats
    constraint beat_times { wdata.size() == awlen+1 ;}

    //BURST type is only Fixed for now
    constraint burst_type{ awburst == 0; }

    //4 bytes transfer as per data width
    constraint beat_size { awsize == $clog2(DATA_W / 8) ; }


endclass

//Master side monitor, needs this response class to the scoreboard
class axi_wr_resp #(
    parameter int ID_W       =  axi_pkg::DEFAULT_TRANS_MST_ID_W         ,
    parameter int RESP_W     =  axi_pkg::DEFAULT_TRANS_WR_RESP_W
);
    int                 mst_id; 
    bit [ID_W-1:0]      bid;
    bit [RESP_W-1:0]    bresp;

endclass
