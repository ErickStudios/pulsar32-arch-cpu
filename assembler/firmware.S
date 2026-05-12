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
    Lea-Dword serial_char_send
    Out-Byte 0
    Out-Byte 'x'
loop:
    Hlt
    Jmp-Word-Clasic loop
alpha_button_irq:
    Push-Dword      Px
    Lea-Dword       25
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp
beta_button_irq:
    Push-Dword      Px
    Lea-Dword       30
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp
up_button_irq:
    Push-Dword      Px
    Lea-Dword       35
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp
down_button_irq:
    Push-Dword      Px
    Lea-Dword       40
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

Assume-Fill         0xFFF

; ================= serial =================
; the serial console

; send char
serial_char_send:
    Assume-Byte     1
; command sender
serial_port_cmd:
    Assume-Byte     2
; serial status
serial_port_status:
    Assume-Byte     3