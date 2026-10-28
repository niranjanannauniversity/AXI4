import axi_pkg::*;

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

    //Control knob to select which slave
    rand bit target_slave_id = 0;


    //CONSTRAINTS
    
    //Fixing only the slave instance as per the number of slaves 
    constraint slave_id { 
        target_slave_id < SLV_AMT ; 
        awaddr[ADDR_W-1 : ADDR_W - $clog2(SLV_AMT)] == target_slave_id;
    }
   i
    //wdata size is number of beats
    constraint beat_times { wdata.size() == awlen+1 ;}

    //BURST type is only Fixed for now
    constraint burst_type{ awburst == 0; }

    //4 bytes transfer as per data width
    constraint beat_size { awsize == $clog2(DATA_W / 8) ; }

    //For now only 8 beats in a transaction is maintained
    constraint no_of_beats { awlen inside {[0:7]} ; }

endclass
