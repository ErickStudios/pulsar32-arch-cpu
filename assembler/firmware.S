Assume-Org          0

_reset_vector:
    Assume-Dword    _init
_devices_vector:
    _alphaBtn_vec_ptr:
        Assume-Dword alpha_button_irq
    _betaBtn_vec_ptr:
        Assume-Dword beta_button_irq
    _upBtn_vec_ptr:
        Assume-Dword up_button_irq
    _downBtn_vec_ptr:
        Assume-Dword down_button_irq 
x:
Assume-Byte 0
y:
Assume-Byte 0
z:
Assume-Byte 0
_start:
_init:
    Lea-Dword x
    Out-Byte 2
    Lea-Dword y
    Out-Byte 3
    Lea-Dword y
    Mov-Byte
    Push-Byte Out
    Lea-Dword x
    Mov-Byte
    Push-Byte Out
    Add-Byte-Sp-Sp
    Lea-Dword z
    Out-Byte Out
loop:
    Hlt
    Jmp-Word-Clasic loop
alpha_button_irq:
    Lea-Dword 25
    Jmp-Word-Clasic loop
beta_button_irq:
    Lea-Dword 30
    Jmp-Word-Clasic loop
up_button_irq:
    Lea-Dword 35
    Jmp-Word-Clasic loop
down_button_irq:
    Lea-Dword 40
    Jmp-Word-Clasic loop