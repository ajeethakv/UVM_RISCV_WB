class riscv_mem_driver extends uvm_driver#(riscv_seq_item);

   `uvm_component_utils(riscv_mem_driver)

   virtual riscv_mem_if vif;
   // riscv_seq_item req;
   bit [31:0] memory[int];
   int        count,ev;

   function new(string name="riscv_mem_driver", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if( !uvm_config_db#(virtual riscv_mem_if)::get(this,"*", "vif", vif))
        `uvm_fatal(get_full_name(),{"virtual interface must be set for:",".mem_vif"} )
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);
      fork
         mon_clk();
      join_none

      // TODO : driver code
      forever
        begin
           `uvm_info(get_type_name(), "Driver in place-Start", UVM_MEDIUM)
           seq_item_port.get_next_item(req);
           `uvm_info(get_name(), "Got new SEQ_ITEM ", UVM_MEDIUM)
           if(req.valid == 1)
             memory[count] = req.data;
           else
             $display("%p",memory);
           count = count + 1;
           fork
              wdog_for_ev();
           join_none

           do begin
              run_wb();
           end while(!ev) ;
           ev = 0; //ev for transaction completion
           seq_item_port.item_done();
           `uvm_info(get_type_name(), "Driver in place-End"  , UVM_MEDIUM) 

        end

      phase.drop_objection(this);
   endtask

   
   int lv_wdog_c;

   task run_wb();
      begin
	 `uvm_info (get_name(), "run_wb", UVM_MEDIUM)

         fork
            begin
               @(negedge vif.wb_clk_i);
               if((vif.wbm_cyc_o && vif.wbm_stb_o))
                 begin
                    vif.wbm_ack_i = 1'b1;   
                    ev = 1;
                 end
               else                                             //WB-handshake
                 begin
                    vif.wbm_ack_i = 1'b0;
                 end
            end

            begin
               @(negedge vif.wb_clk_i);
               if((vif.wbm_cyc_o && vif.wbm_stb_o && !vif.wbm_we_o))
                 begin
                    vif.wbm_dat_i = memory[vif.wbm_adr_o >> 2]; 
                 end
            end

            begin
               @(negedge vif.wb_clk_i);
               if((vif.wbm_cyc_o && vif.wbm_stb_o && vif.wbm_we_o))
                 begin
                    if(!memory.exists(vif.wbm_adr_o >> 2))
                      begin
                         memory[vif.wbm_adr_o >> 2] = 0;
                      end
                    memory[vif.wbm_adr_o >> 2] = vif.wbm_dat_o;                               //WB-write transaction
                 end
            end                     
            
         join_any
         disable fork;
         `uvm_info (get_name(), "Done with run_wb ", UVM_MEDIUM)
      end
   endtask

   int lv_clk_tick = 0;
   task mon_clk();
      forever begin
         // @(negedge vif.wb_clk_i);
         @(negedge top.inf.wb_clk_i);
         `uvm_info (get_name(), $sformatf("clk tick: %0d", lv_clk_tick), UVM_MEDIUM)
         lv_clk_tick++;
      end
   endtask : mon_clk

   task wdog_for_ev();
      lv_wdog_c = 0;

      while (lv_wdog_c < 10) begin
	 `uvm_info (get_name(), $sformatf("wdog: %0d/100", lv_wdog_c), UVM_MEDIUM)

	 @(negedge vif.wb_clk_i);
	 lv_wdog_c += 1;
      end
      `uvm_warning (get_name(), "WDOG expired at 100")
      ev = 1;
   endtask : wdog_for_ev

endclass
