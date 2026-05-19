; ===========================================
;       FIRMWARE BY MARKARIAN AND THE
;       PULSAR PROJECT FOR MACHINE
;       'pulsar 5024XM x32 PC'
;
; firmware para la maquina pulsar5024XM de 32 
; bits
;
; ===========================================

Assume-Org          0

SERIAL_MODE_SWITCH  Equ  0x01

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
    _cassete_vec_ptr:
        Assume-Dword cassete_irq

Assume-Fill         0x1F0

; vectors de funciones del firmware
_vectors:
    Assume-Word     put_char
    Assume-Word     put_msg
    Assume-Word     put_msg

_init:
    ; inicializar la consola serial
    Lea-Dword       serial_port_cmd
    Out-Byte        SERIAL_MODE_SWITCH
                              ; no esta lista la consola serial o cuando la apagas o
                              ; depues de un comando entonces haces que el proximo
                              ; byte que envies sea el parametro con el que enviaste 
                              ; el comando
    Add-Byte-Inm-Inm 1, 0     ; el modo de limpiar com1 y por ahora directamente 
                              ; le puedes poner el modo de print out
    Jmp-Word-Call   put_char  ; mandrlo
    Jmp-Dword-Call  fixSerial ; si no lo sabian si mandas un caracter en estado cuando

    Jmp-Dword-Call  fixSerial
    Lea-Dword       bootmsg
    Jmp-Dword-Call  put_msg
loop:
    Hlt
    Jmp-Word-Clasic loop

fixSerial:
    Add-Byte-Inm-Inm ' ', 0
    Jmp-Word-Clasic put_char

; ================= funcs =================

; put a character
put_char:
    Push-Dword      Px
    Lea-Dword       serial_char_send
    Out-Byte        0
    Out-Byte        Out
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

put_msg:
    Push-Dword      Px
put_msg_loop:
    Mov-Byte
    Push-Byte       Out
    Cmp-Byte-Inm-Sp 0
    Mov-Byte
    Jmp-Word-Zero   put_msg_end
    Jmp-Dword-Call  put_char
    Push-Dword      Px
    Add-Dword-Sp-Inm 1
    Lea-Dword       Out
    Jmp-Dword-Clasic put_msg_loop
put_msg_end:
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp


; ================= irqs =================
; the irqs

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

; ===========================================
;           SERIAL MMIO
;
; datos de MMIO para la consola serial y mas
; cosas relacionadas con la depuracion
;
; ===========================================

SERIAL_DEFAULT_VAL  Equ 0       ; valor por defecto de el caracter o dato
                                ; para indicarle a la consola serial que
                                ; no este molestando el cpu y com1          

SERIAL_UNDEF_STATU  Equ 0xFF    ; estado indefinido, si la consola serial no
                                ; funciona o el hardware no es compatible entonces
                                ; no existe puerto serial asi que nunca se actualizara

SERIAL_NON_CMD_SND  Equ 0       ; indica que no hay ningun comando que procesar y que deje
                                ; de procesar comandos hasta que actualizes esa direccion de
                                ; memoria osea la de 'serial_port_cmd'

; ===========================================
; caracter a mandar al puerto serial o datos
; de comando respectivo
;
serial_char_send:
    Assume-Byte     SERIAL_DEFAULT_VAL
; ===========================================
; mandon de comandos al puerto serial
;
serial_port_cmd:
    Assume-Byte     SERIAL_NON_CMD_SND
; ===========================================
; estado del puerto serial
;
serial_port_status:
    Assume-Byte     SERIAL_UNDEF_STATU

Assume-Fill     0x1FFF

bootmsg:
    Assume-Byte     'b', 'o', 'o', 't', 'i', 'n', 'g', ' ', 'f', 'r', 'o',  'm', ' ', 'R', 'O', 'M', 10, 0

Assume-Fill     0x2FFF

; ================= cassete =================
; funciones de cassete

; ===========================================
;       CASSETE IRQ ISR
;
; funcion interna de cassete no el de para 
; obtener funciones si no datos o mas cosas
;
cassete_irq:
    Push-Dword      Px
    Jmp-Dword-Clasic cassete_fnc_end
; ===========================================
; fin de la funcion de cassete
;
cassete_fnc_end:

    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp