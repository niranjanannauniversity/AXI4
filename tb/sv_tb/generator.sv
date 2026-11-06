

class axi_wr_gr;

    
    mailbox #(axi_wr_tx) mbxgd;
    mailbox #(bit)       mbxscogen;


    event done;
    bit ack; 

    int count = 0;

    task run();
        axi_wr_tx tr;
        for (int i = 0 ; i < count ; i++)begin
            tr = new();
            assert(tr.randomize()) else $error("[GEN] Randomisation Failed");
            $display("[GEN] awaddr : %0h  awid : %0d awburst : %0d awlen : %0d awsize : %0d  wdata : %0p ", tr.awaddr, tr.awid , tr.awburst , tr.awlen , tr.awsize , tr.wdata);
            
            mbxgd.put(tr);
            mbxscogen.get(ack); // This is just for the bringup test, this has to be removed when there are more masters transmitting. As this will block the transaction and there will be no contention, but the DUT gives this privilege 
        end
        -> done;        
    endtask




    function new(mailbox #(axi_wr_tx) mbxgd, mbxscogen); 
    
        this.mbxgd = mbxgd;
        this.mbxscogen = mbxscogen;
    
    endfunction

endclass
