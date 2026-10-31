import axi_pkg :: *;

class axi_wr_gr;

    
    mailbox #(axi_wr_tr) mbxgd;
    mailbox #(bit)       mbxscogen;


    event done;
    bit ack; 

    int count = 0;

    task run();
        axi_wr_tx tr;
        for (integer i = 0 ; i < count ; i++)begin
            tr = new();
            assert(tr.randomize()) else $display("[GEN] Randomisation Failed");
            $display("[GEN] awaddr : %0h  awid : %0d awburst : %0d awlen : %0d awsize : %0d  wdata : %0p ", tr.awaddr, tr.awid , tr.awburst , tr.awlen , tr.awsize , tr.wdata);
            
            mbxgd.put(tr);
            mbxscogen.get(ack); 
        end
        -> done;        
    endtask




    function new(mailbox #(axi_wr_tr) mbxgd, mbxscogen); 
    
        this.mbxgd = mbxgd;
        this.mbxscogen = mbxscogen;
    
    endfunction

endclass
