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
_init:
    Lea-Dword       _alphaBtn_vec_ptr
    Out-Dword       alpha_button_irq
    Lea-Dword       _betaBtn_vec_ptr
    Out-Dword       beta_button_irq
    Lea-Dword       _upBtn_vec_ptr
    Out-Dword       up_button_irq
    Lea-Dword       _downBtn_vec_ptr
    Out-Dword       down_button_irq
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