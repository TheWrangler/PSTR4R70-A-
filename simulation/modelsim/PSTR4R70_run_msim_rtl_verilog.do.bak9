transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+F:/PSTR4R70(A) {F:/PSTR4R70(A)/pwr_rst.v}
vlog -vlog01compat -work work +incdir+F:/PSTR4R70(A) {F:/PSTR4R70(A)/top.v}
vlog -vlog01compat -work work +incdir+F:/PSTR4R70(A) {F:/PSTR4R70(A)/master_spi.v}
vlog -vlog01compat -work work +incdir+F:/PSTR4R70(A) {F:/PSTR4R70(A)/adf4159.v}
vlog -vlog01compat -work work +incdir+F:/PSTR4R70(A) {F:/PSTR4R70(A)/adf4159_spi.v}

vlog -vlog01compat -work work +incdir+F:/PSTR4R70(A) {F:/PSTR4R70(A)/top_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  top_tb

add wave *
view structure
view signals
run -all
