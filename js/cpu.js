class CPU {
  constructor(debug={
    place: (v) => console.log(v)
  }) {
    this.debugger = debug;
    this.memory = new Uint8Array(64001);

    this.pc = 0;
    this.sp = 63000;

    this.stack = new Uint32Array(256);

    this.reg8 = new Uint8Array(16);
    this.reg16 = new Uint16Array(16);
    this.reg32 = new Uint32Array(16);

    this.currentPtrAddrs = 0;

    this.valueRegister = 0;

    this.opcode = 0;
    this.mode = 0;

    this.ir = 0;
  }

  read32(addr) {
    return (
      (this.memory[addr] << 24) |
      (this.memory[addr + 1] << 16) |
      (this.memory[addr + 2] << 8) |
      (this.memory[addr + 3])
    ) >>> 0;
  }

  writeStack32(value) {
    this.memory[this.sp--] = (value >> 24) & 0xff;
    this.memory[this.sp--] = (value >> 16) & 0xff;
    this.memory[this.sp--] = (value >> 8) & 0xff;
    this.memory[this.sp--] = value & 0xff;
  }

  readStack32() {
    const v =
      (this.memory[++this.sp] << 24) |
      (this.memory[++this.sp] << 16) |
      (this.memory[++this.sp] << 8) |
      (this.memory[++this.sp]);

    return v >>> 0;
  }

  tick() {
    this.ir = this.memory[this.pc++];

    switch (this.ir) {

      case 0x01: {
        this.mode = this.memory[this.pc++];

        if (this.mode === 0x20) {
          this.currentPtrAddrs = this.read32(this.pc);
          this.pc += 4;
          this.debugger.place("INM32 LPX 0x" + this.currentPtrAddrs.toString(16));
        }

        if (this.mode === 0x1A) {
          this.debugger.place("STACK32 LPX");
          this.currentPtrAddrs = this.readStack32();
        }

        break;
      }

      case 0x02: {
        this.debugger.place("REGISTER8 LDX");
        this.valueRegister = this.memory[this.currentPtrAddrs];
        break;
      }

      case 0x03: {
        this.mode = this.memory[this.pc++];

        if (this.mode === 0x1F) {
          const r = this.memory[this.pc++];

          if (r === 0x00) {
            this.debugger.place("REGISTER32 PUS $currentPtrAddrs");
            this.writeStack32(this.currentPtrAddrs);
          }

          if (r === 0x01) {
            this.debugger.place("REGISTER8 PUS $valueRegister");
            this.memory[this.sp--] = this.valueRegister;
          }
        }

        break;
      }

      case 0x04: {
        this.opcode = this.memory[this.pc];
        const operator = this.memory[this.pc];
        const bytes = this.memory[this.pc + 1];
        this.pc += 2;

        this.debugger.place(
          `ANONYMUS${bytes * 8} OPR ${operator}`
        );

        break;
      }
    }
  }
} if (typeof window == "undefined") globalThis.window = globalThis;
if (typeof window !== "undefined") window.CPU = CPU;