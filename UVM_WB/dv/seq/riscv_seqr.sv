`ifndef VERILATOR
typedef uvm_sequencer #(riscv_seq_item, riscv_seq_item) riscv_seqr;
`else
class riscv_seqr extends uvm_sequencer #(riscv_seq_item, riscv_seq_item);
   `uvm_component_utils(riscv_seqr)
   function new(string name="riscv_seqr", uvm_component parent = null);
      super.new(name, parent);
   endfunction
endclass : riscv_seqr 
`endif // VERILATOR
