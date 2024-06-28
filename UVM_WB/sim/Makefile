DV_PATH=../dv

.PHONY: clean


all: build_dv build_tb sim

vivado: vivado_build_dv vivado_build_tb vivado_sim

build_dv:

	vlog $(DV_PATH)/agent/riscv_mem_pkg.sv
	vlog $(DV_PATH)/env/test_pkg.sv

build_tb:
	vlog $(DV_PATH)/tb/top.sv

sim:
	vsim -c top +UVM_TESTNAME=test_base -do "run -a; q"

clean:
	rm -rf work transcript
	rm -fr obj* *.log

vlt : clean
	verilator --binary --exe --cc --main --timing --assert -f vlt.f > vlt_comp.log 2>&1


vivado_build_dv:
	xvlog -sv -L uvm $(DV_PATH)/seq/seq_pkg.sv
	xvlog -sv -L uvm $(DV_PATH)/agent/riscv_mem_pkg.sv
	xvlog -sv -L uvm $(DV_PATH)/env/test_pkg.sv

vivado_build_tb:
	xvlog -sv -L uvm $(DV_PATH)/tb/top.sv
	xelab top -relax -s top -debug wave -timescale 1ns/1ps


vivado_sim:
	xsim  top -testplusarg UVM_TESTNAME=test_1 -runall

vivado_clean:
	rm -rf xsim.dir webtalk* xelab* xvlog* xsim* *.log *.vcd *.wdb

