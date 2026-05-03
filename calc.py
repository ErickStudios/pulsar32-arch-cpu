import subprocess

subprocess.run(["iverilog", "-o", "cpu.out", "cpu.v", "tb.v"])

proc = subprocess.Popen(
    ["vvp", "cpu.out"],
    stdout=subprocess.PIPE,
    text=True
)

import tkinter as tk
import threading

root = tk.Tk()

display = tk.Label(root, text="0", font=("Courier", 32))
display.pack()

def leer_verilog():
    for line in proc.stdout:
        if "DISPLAY:" in line:
            value = line.split(":")[1].strip()
            display.config(text=value)

threading.Thread(target=leer_verilog, daemon=True).start()

root.mainloop()