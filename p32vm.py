import argparse
import subprocess
import re
import sys
import tkinter
import threading
from PIL import Image, ImageTk

class Object: pass

# =========================================================
# MACHINE DEFINITIONS
# =========================================================

class Pulsar5024XM_x32:
    
    class MonitorSettings:
        def __init__(self):
            self.inited = False
            self.pil: Image.Image = None
            self.photo:ImageTk.PhotoImage = None
    
    def __init__(self):
        self.put_buffer = ""
    def refresh_monitor(self, vvip):

        vvip.mset.photo = ImageTk.PhotoImage(
            vvip.mset.pil
        )

        vvip.label.config(
            image=vvip.mset.photo
        )
    def __envinit__(self):
        vvip = Object()
        monitor = tkinter.Tk()

        monitorSettings = Pulsar5024XM_x32.MonitorSettings()
        monitorSettings.pil = Image.new("RGB", (255, 255), (0,0,0))
        monitorSettings.photo = ImageTk.PhotoImage(monitorSettings.pil)

        monitor.config(bg="#000000")
        monitor.title("vvp + display ErickGA + pulsar5024XM pc sim + display")
        monitor.geometry("255x255")
        
        label = tkinter.Label(
            monitor,
            image=monitorSettings.photo,
            bd=0
        )
        label.pack()
        vvip.label = label
        vvip.monitor = monitor
        vvip.mset = monitorSettings
        
        self.monitor = monitorSettings

        vvip.key_states = ["0"] * 40 

        # 1234567890
        # ABCDEFGHIJ
        # KLMNOPQRST ^
        #   UVWXYZ  <v>
        vvip.key_map = {
            '1':0,'2':1,'3':2,'4':3,'5':4,'6':5,'7':6,'8':7,'9':8,'0':9,
            'A':10,'B':11,'C':12,'D':13,'E':14,'F':15,'G':16,'H':17,'I':18,'J':19,
            'K':20,'L':21,'M':22,'N':23,'O':24,'P':25,'Q':26,'R':27,'S':28,'T':29,
            '^':30,'U':31,'V':32,'W':33,'X':34,'Y':35,'Z':36,'<':37,'v':38,'>':39
        }

        def on_key_press(event):
            key = event.char
            if key in vvip.key_map:
                idx = vvip.key_map[key]
                if vvip.key_states[idx] == "0":
                    vvip.key_states[idx] = "1"
                    write_key_file()

        def on_key_release(event):
            key = event.char
            if key in vvip.key_map:
                idx = vvip.key_map[key]
                if vvip.key_states[idx] == "1":
                    vvip.key_states[idx] = "0"
                    write_key_file()

        def write_key_file():
            content = "\n".join(vvip.key_states)
            with open("hkey_kbad_pc.stat", "w") as al:
                al.write(content)

        monitor.bind("<KeyPress>", on_key_press)
        monitor.bind("<KeyRelease>", on_key_release)
        # -------------------------------------------------------------

        return vvip

    @staticmethod
    def rgb_to_lrrggbb(r, g, b):

        rr = r >> 6
        gg = g >> 6
        bb = b >> 6

        ll = max(rr, gg, bb)

        color = (
            (ll << 6) |
            (rr << 4) |
            (gg << 2) |
            bb
        )

        return color
    
    @staticmethod
    def lrrggbb_to_rgb(color):

        ll = (color >> 6) & 0b11

        rr = (color >> 4) & 0b11
        gg = (color >> 2) & 0b11
        bb = color & 0b11

        r = rr * 85
        g = gg * 85
        b = bb * 85

        return (r, g, b)
    def handle_trace(self, trace):

        ctx  = trace["ctx"]
        args = trace["args"]

        # -------------------------------------------------
        # HARDWARE EVENTS
        # -------------------------------------------------

        if ctx == "HARDWARE":

            if len(args) >= 2:

                device = args[0]
                hwop   = args[1]

                # -----------------------------------------
                # CHARACTER OUTPUT
                # -----------------------------------------

                if device == "PUTCHR":

                    value = int(hwop)

                    print(chr(value), end="")
                    sys.stdout.flush()

                elif device == "PUTPIX":

                    self.monitor.pil.putpixel((int(hwop), int(args[2])), (Pulsar5024XM_x32.lrrggbb_to_rgb(int(args[3]))))

                # -----------------------------------------
                # IRQ
                # -----------------------------------------

                elif device == "IRQ":

                    print(f"\n[IRQ] {args}")

        # -------------------------------------------------
        # DEBUG TRACE
        # -------------------------------------------------

        else:

            cycle = trace["cycle"]
            pc    = trace["pc"]
            op    = trace["op"]

            #print(
            #    f"[{cycle:8}] "
            #    f"PC=0x{pc:08X} "
            #    f"OP={op}"
            #)


# =========================================================
# PARSER
# =========================================================

TRACE_REGEX = re.compile(
    r"\s*(\d+)\s+\(([0-9a-fA-F]+)\)\s+(\S+)\s+(\S+)(.*)"
)


def parse_trace(line):

    m = TRACE_REGEX.match(line)

    if not m:
        return None

    cycle = int(m.group(1))
    pc    = int(m.group(2), 16)
    ctx   = m.group(3)
    op    = m.group(4)

    rest = m.group(5).split()

    return {
        "cycle": cycle,
        "pc": pc,
        "ctx": ctx,
        "op": op,
        "args": rest
    }


# =========================================================
# MACHINE TABLE
# =========================================================

MACHINES = {
    "pulsar5024XM_x32": Pulsar5024XM_x32
}


# =========================================================
# MAIN
# =========================================================
def main():
    parser = argparse.ArgumentParser(prog="pqemu", description="Pulsar QEMU-like monitor")
    parser.add_argument("-pc", required=True, choices=MACHINES.keys(), help="Machine type")
    parser.add_argument("-mx", action="store_true", help="out to the file")
    parser.add_argument("-cpu", default="cpu", help="vvp target")
    parser.add_argument("--raw", action="store_true", help="Show raw trace lines")
    args = parser.parse_args()

    machine = MACHINES[args.pc]()
    vvip = Object()
    mx = bool(args.mx)
    if hasattr(machine, "__envinit__"): 
        vvip = machine.__envinit__()

    with open("hkey_kbad_pc.stat", "w") as al:
            al.write("\n".join(["0"] * 40))

    # Lanzar subproceso del simulador Verilog
    proc = subprocess.Popen(
        ["vvp", args.cpu],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        bufsize=1
    )

    f = open("pc.log.vm", "w") if mx else None

    # =====================================================
    # HILO DE TRABAJO: Lee VVP en segundo plano
    # =====================================================
    def vvp_reader_thread():
        try:
            for line in proc.stdout:
                if mx and f:
                    f.write(line)
                    f.flush()

                line_str = line.rstrip()
                if args.raw:
                    print("[RAW]", line_str)
                
                trace = parse_trace(line_str)
                if trace is None:
                    continue

                machine.handle_trace(trace)
        except Exception as e:
            print(f"\n[ERROR EN HILO VVP]: {e}")
        finally:
            if f: f.close()

    # Arrancamos el hilo lector de VVP de forma asíncrona
    reader = threading.Thread(target=vvp_reader_thread, daemon=True)
    reader.start()

    # =====================================================
    # HILO PRINCIPAL: Refresco periódico de pantalla
    # =====================================================
    def update_monitor():
        if hasattr(vvip, "monitor"):
            try:
                machine.refresh_monitor(vvip)
                # Volvemos a agendar el refresco gráfico cada 16ms (~60 FPS)
                vvip.monitor.after(16, update_monitor)
            except tkinter.TclError:
                return

    vvip.monitor.protocol("WM_DELETE_WINDOW", lambda:[
        proc.kill(), 
        vvip.monitor.destroy()
    ])

    # Iniciar la cola de refrescos y el bucle nativo de Tkinter
    vvip.monitor.after(16, update_monitor)
    
    # El hilo principal se queda aquí escuchando clicks y pintando píxeles de forma nativa
    vvip.monitor.mainloop() 

    # Al cerrar la ventana, liquidar el proceso de simulación
    if proc.poll() is None:
        proc.kill()
    proc.wait()

if __name__ == "__main__":
    main()