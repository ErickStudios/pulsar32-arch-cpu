# compilacion
node ../../assembler/pulsarAsm.js firmware.S program.hex
node ../../assembler/pulsarAsm.js cassete.asm cassete.hex

# compilar verilog
iverilog -o cpu cpu.v tb.v

C:\Users\erick\AppData\Local\Programs\Python\Python314\python.exe ../../p32vm.py -pc pulsar5024XM_x32 > com1.txt