###############################################################################
# Created by write_sdc
# Tue Oct 22 15:04:29 2024
###############################################################################
current_design bsg_chip
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name tag_clk -period 5.2000 [get_ports {p_bsg_tag_clk_i}]
set_clock_uncertainty -hold 0.1500 tag_clk
create_clock -name bp_clk -period 2.6000 [get_ports {p_clk_A_i}]
set_clock_uncertainty 0.1500 bp_clk
create_clock -name io_master_clk -period 2.6000 [get_ports {p_clk_B_i}]
set_clock_uncertainty 0.1500 io_master_clk
create_clock -name router_clk -period 2.6000 [get_ports {p_clk_C_i}]
set_clock_uncertainty 0.1500 router_clk
create_clock -name sdi_a_clk -period 5.2000 [get_ports {p_ci_clk_i}]
set_clock_uncertainty 0.1500 sdi_a_clk
create_clock -name sdo_a_tkn_clk -period 5.2000 [get_ports {p_ci2_tkn_i}]
set_clock_uncertainty 0.1500 sdo_a_tkn_clk
create_clock -name sdi_b_clk -period 5.2000 [get_ports {p_co_clk_i}]
set_clock_uncertainty 0.1500 sdi_b_clk
create_clock -name sdo_b_tkn_clk -period 5.2000 [get_ports {p_co2_tkn_i}]
set_clock_uncertainty 0.1500 sdo_b_tkn_clk
set_input_delay 1.4560 -clock [get_clocks {tag_clk}] -add_delay [get_ports {p_bsg_tag_data_i}]
set_input_delay 1.4560 -clock [get_clocks {tag_clk}] -add_delay [get_ports {p_bsg_tag_en_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_0_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_0_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_0_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_0_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_1_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_1_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_1_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_1_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_2_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_2_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_2_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_2_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_3_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_3_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_3_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_3_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_4_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_4_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_4_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_4_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_5_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_5_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_5_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_5_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_6_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_6_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_6_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_6_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_7_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_7_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_7_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_7_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_8_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_8_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_8_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_8_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -min -add_delay [get_ports {p_ci_v_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -max -add_delay [get_ports {p_ci_v_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_a_clk}] -clock_fall -min -add_delay [get_ports {p_ci_v_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_a_clk}] -clock_fall -max -add_delay [get_ports {p_ci_v_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_0_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_0_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_0_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_0_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_1_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_1_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_1_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_1_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_2_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_2_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_2_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_2_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_3_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_3_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_3_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_3_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_4_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_4_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_4_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_4_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_5_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_5_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_5_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_5_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_6_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_6_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_6_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_6_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_7_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_7_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_7_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_7_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_8_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_8_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_8_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_8_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -min -add_delay [get_ports {p_co_v_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -max -add_delay [get_ports {p_co_v_i}]
set_input_delay 0.0520 -clock [get_clocks {sdi_b_clk}] -clock_fall -min -add_delay [get_ports {p_co_v_i}]
set_input_delay 0.7280 -clock [get_clocks {sdi_b_clk}] -clock_fall -max -add_delay [get_ports {p_co_v_i}]
set_multicycle_path -hold\
    -to [list [get_ports {p_ci2_0_o}]\
           [get_ports {p_ci2_1_o}]\
           [get_ports {p_ci2_2_o}]\
           [get_ports {p_ci2_3_o}]\
           [get_ports {p_ci2_4_o}]\
           [get_ports {p_ci2_5_o}]\
           [get_ports {p_ci2_6_o}]\
           [get_ports {p_ci2_7_o}]\
           [get_ports {p_ci2_8_o}]\
           [get_ports {p_ci2_clk_o}]\
           [get_ports {p_ci2_v_o}]\
           [get_ports {p_co2_0_o}]\
           [get_ports {p_co2_1_o}]\
           [get_ports {p_co2_2_o}]\
           [get_ports {p_co2_3_o}]\
           [get_ports {p_co2_4_o}]\
           [get_ports {p_co2_5_o}]\
           [get_ports {p_co2_6_o}]\
           [get_ports {p_co2_7_o}]\
           [get_ports {p_co2_8_o}]\
           [get_ports {p_co2_clk_o}]\
           [get_ports {p_co2_v_o}]] 0
set_multicycle_path -setup\
    -to [list [get_ports {p_ci2_0_o}]\
           [get_ports {p_ci2_1_o}]\
           [get_ports {p_ci2_2_o}]\
           [get_ports {p_ci2_3_o}]\
           [get_ports {p_ci2_4_o}]\
           [get_ports {p_ci2_5_o}]\
           [get_ports {p_ci2_6_o}]\
           [get_ports {p_ci2_7_o}]\
           [get_ports {p_ci2_8_o}]\
           [get_ports {p_ci2_clk_o}]\
           [get_ports {p_ci2_v_o}]\
           [get_ports {p_co2_0_o}]\
           [get_ports {p_co2_1_o}]\
           [get_ports {p_co2_2_o}]\
           [get_ports {p_co2_3_o}]\
           [get_ports {p_co2_4_o}]\
           [get_ports {p_co2_5_o}]\
           [get_ports {p_co2_6_o}]\
           [get_ports {p_co2_7_o}]\
           [get_ports {p_co2_8_o}]\
           [get_ports {p_co2_clk_o}]\
           [get_ports {p_co2_v_o}]] 1
set_false_path\
    -from [list [get_clocks {router_clk}]\
           [get_clocks {tag_clk}]]\
    -to [get_clocks {bp_clk}]
###############################################################################
# Environment
###############################################################################
set_wire_load_mode "enclosed"
###############################################################################
# Design Rules
###############################################################################
