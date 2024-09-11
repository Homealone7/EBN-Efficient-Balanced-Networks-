# Clock (mapped to default ZedBoard clock, 100 MHz)
set_property PACKAGE_PIN Y9 [get_ports clk100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk100mhz]

# Reset signal mapped to BTNU (Up button)
set_property PACKAGE_PIN T18 [get_ports {reset}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset}]

# init_signal mapped to BTNC (Center button)
set_property PACKAGE_PIN P16 [get_ports {init_signal}]
set_property IOSTANDARD LVCMOS33 [get_ports {init_signal}]

# done signal mapped to LD0 (User LED 0)
set_property PACKAGE_PIN T22 [get_ports {done}]
set_property IOSTANDARD LVCMOS33 [get_ports {done}]

set_property PACKAGE_PIN T21 [get_ports {spike_flg}];
set_property IOSTANDARD LVCMOS33 [get_ports {spike_flg}]
# ----------------------------------------------------------------------------
# Comment out unnecessary IO Bank voltage constraints that are causing errors.
# Bank voltage for IO Bank 33 is fixed to 3.3V on ZedBoard. 
# set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]]

# Set the bank voltage for IO Bank 34 to 1.8V by default.
# set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]]

# Set the bank voltage for IO Bank 35 to 1.8V by default.
# set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]]

# Bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard. 
# set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]]
