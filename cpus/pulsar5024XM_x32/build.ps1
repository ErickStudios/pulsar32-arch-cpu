node ../../js/pulsarAsm.js ../../js/firmware.S program.hex  
iverilog -o cpu src/motherboard/device.v src/cpu.v tb.v
vvp cpu