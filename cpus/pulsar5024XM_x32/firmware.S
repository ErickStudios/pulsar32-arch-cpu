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

; ===========================================
;           VECTORS & FUNCS
;
; vectors de dispositivos, funciones, ints
; irqs, de reset, etc
;
; ===========================================

; ===========================================
; puntero a la funcion que se ejecuta cuando
; el cpu inicia, no es de la pc es del cpu
; en general
;
_reset_vector:
    Dword           _init

; ===========================================
; vectores de dispositivos y sus irqs que
; los atienden cada vez que lo requieren
;
_devices_vector:
    Dword           alpha_button_irq ; vector del boton 'A' o mas conocido como Alpha
    Dword           beta_button_irq ; vector del boton 'B' o mas conocido como Beta
    Dword           up_button_irq ; vector del boton 'Up'
    Dword           down_button_irq ; vector del boton 'Down'
    Dword           cassete_irq ; vector del dispositivo de la disquetera de cartuchos del mmfs0 (mounted/maped FileSystem 0)

Assume-Fill         0x1F0

; ===========================================
; vectors de funciones del firmware
;
_vectors:
    Word        put_char ; coloca un caracter
    Word        put_msg ; pone un mensaje

; ===========================================
;           STAGES FIRMWARE
;
; etapas del firmware sobre su boot
;
; ===========================================

; ===========================================
; inicializa el firmware
;
_init:
    Lea-dword       firmware_on_flag
    Out-Byte        0

    ; inicializar la consola serial
    Lea-Dword       com1_cmd_mmio
    Out-Byte        SERIAL_MODE_SWITCH
                                ; no esta lista la consola serial o cuando la apagas o
                                ; depues de un comando entonces haces que el proximo
                                ; Byte que envies sea el parametro con el que enviaste 
                                ; el comando
    Add-Byte-Inm-Inm 1, 0       ; el modo de limpiar com1 y por ahora directamente 
                                ; le puedes poner el modo de print out
    Jmp-Word-Call   put_char    ; mandrlo
    Jmp-Dword-Call  fixSerial   ; si no lo sabian si mandas un caracter en estado cuando

    Jmp-Dword-Call  fixSerial   ; arregla la serial
    Lea-Dword       bootmsg     ; manda el mensaje
    Jmp-Dword-Call  put_msg     ; pone el mensaje
    Lea-dword       firmware_on_flag
    Out-Byte        1
    Lea-Dword       sga_row_mmio
    Out-Byte        45
    Lea-Dword       sga_col_mmio
    Out-Byte        45
    Lea-Dword       sga_data_mmio
    Out-Byte        0x22
    Jmp-Word-Clasic C1

; ===========================================
; cuando el firmware espera a cargar el sector
; para bootear en el
;
C1:
    Lea-Dword       Px
    Jmp-Word-Clasic C2
C2:
    Lea-Dword       cassete_external_cmd    ; comando
    Out-Byte        CASSETE_READ_SECTA      ; lee un sector
    Lea-Dword       cassete_sector_read_cmd ; la direccion
    Out-Byte        0                       ; parte alta
    Out-Byte        0                       ; sector 0
C3:
    Hlt                         ; espera
    Lea-Dword       cassete_readed_sector_finish ; la direccion
    Mov-Byte                    ; mover byte
    Push-Byte       Out         ; leer
    Cmp-Byte-Inm-Sp 1           ; verificar
    Jmp-Word-Zero   C4          ; se logro leer
    Jmp-Word-Clasic C3          ; salta
C4:
    Jmp-Word-Clasic cassete_external_sector ; salta al sector el codigo del bootloader
                                            ; de 512 bytes

fixSerial:
    Add-Byte-Inm-Inm ' ', 0
    Jmp-Word-Clasic put_char

; ===========================================
;           SERIAL FUNCS
;
; funciones para la consola serial y el puerto
; de depuracion de la PC
;
; ===========================================

; ===========================================
; manda un caracter a la consola serial
;
put_char:
    Push-Dword      Px          ; poner dword
    Lea-Dword       com1_new_mmio ; el caracter a mandar
    Out-Byte        Out         ; mandar
    Lea-Dword       Sp          ; restaurar la direccion
    Jmp-Dword-Clasic Sp         ; regresar

; ===========================================
; pone un mensaje en la consola serial
;
put_msg:
    Push-Dword      Px          ; guardar dword

; ===========================================
; el loop de poner un mensaje en la consola
; serial
;
put_msg_loop:
    Mov-Byte                    ; obtiene el Byte
    Push-Byte       Out         ; pone el Byte en el stack
    Cmp-Byte-Inm-Sp 0           ; compara con terminador
    Mov-Byte                    ; obtiene el Byte
    Jmp-Word-Zero   put_msg_end ; si es igual terminar
    Jmp-Dword-Call  put_char    ; pone el caracter en la consola serial
    Push-Dword      Px          ; guarda la dword
    Add-Dword-Sp-Inm 1          ; suma la direccion de memoria
    Lea-Dword       Out         ; obtiene dword
    Jmp-Dword-Clasic put_msg_loop ; salta
    
; ===========================================
; el final del mensaje
;
put_msg_end:
    Lea-Dword       Sp          ; lee la dword
    Jmp-Dword-Clasic Sp         ; regresar

; ===========================================
;           FUNC BUTTONS
;
; funciones para los botones de funciones de
; la PC,
; los botones son funciones de rapido acceso}
; para navegar entre menus, seleccionar cosas,
; para confirmacion y cuadros de dialogo, entre
; otras funciones
;
; ===========================================

; ===========================================
; boton 'A'
;
alpha_button_irq:
    Push-Dword      Px
    ; ... comming soon ...
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

; ===========================================
; boton 'B'
;
beta_button_irq:
    Push-Dword      Px
    ; ... comming soon ...
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

; ===========================================
; boton 'UP'
;
up_button_irq:
    Push-Dword      Px
    ; ... comming soon ...
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

; ===========================================
; boton 'DOWN'
;
down_button_irq:
    Push-Dword      Px
    ; ... comming soon ...
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

Assume-Fill         0xFFF

; ===========================================
;           SERIAL MMIO
;
; datos de MMIO para la consola serial y mas
; cosas relacionadas con la depuracion,
; la consola serial es una parte escencial
; de la depuracion de programas y mensajes
; de logs, ya que este PC al no haber pantalla
; necesita algo para expresarse
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
    Byte     SERIAL_DEFAULT_VAL
; ===========================================
; mandon de comandos al puerto serial
;
serial_port_cmd:
    Byte     SERIAL_NON_CMD_SND
; ===========================================
; estado del puerto serial
;
serial_port_status:
    Byte     SERIAL_UNDEF_STATU

Assume-Fill     0x1FFF

bootmsg:
    Byte     'b', 'o', 'o', 't', 'i', 'n', 'g', ' ', 'f', 'r', 'o',  'm', ' ', 'R', 'O', 'M', 10, 0
disk_inserted:
    Byte     'c','a','s','s','e','t','e',' ','i','n','s','e','r','t','e','d', 10, 0

; ===========================================
;           CASSETE FUNCS
;
; funciones y MMIO para el cassete del disco
; principal A: alias fs0: blk0: etc
; la unidad principal del dispositivo por donde
; medio se insertan los OS, juegos baremetal
; entre otros programas de arranque post bios
;
; ===========================================

Assume-Fill     0x2FFF

CASSETE_READ_DOT    Equ 12  ; lee un punto en el cassete
                            ; es una respuesta a una de las 
                            ; funciones del bios

CASSETE_READ_SECTA  Equ 18  ; lee un sector del cassete indexado desde
                            ; 0 a chorrocientos millones

CASSETE_WAITING_UE  Equ 24  ; que esta pendiente que se inserto un
                            ; cassete y le esta preguntando al firmware
                            ; que quieres que haga con ese cabron
                            ; osea en espaniol estandart, que el cassete
                            ; se ha insertado hace tiempo o justo ahora y tiene
                            ; pendiente que el bios haga algo con eso

; ===========================================
; variable que indica que va a hacer el cassete
; en la irq que se llamo actualmente
;
; cassete_external_cmd_alias_que_quieres_we:
cassete_external_cmd:
    Byte 0xFF

Assume-Fill 0x4F00

; ===========================================
; variables que indican que el cassete se leyo
; o no? que ya me confundi
;
cassete_readed_sector_finish:
    Byte 0

Assume-Fill 0x4F02

; ===========================================
; variable que indica el sector a leer con read
; sector
;
cassete_readed_sector_finish:
    Word 0

; ===========================================
; variable que indica el sector que ha leido esa cosa
;
Assume-Fill 0x4FFF
;cassete_external_sector_lo_que_lello_este_men:
cassete_external_sector:
    Assume-Fill 0x51FF

; ===========================================
; funcion interna de cassete no el de para 
; obtener funciones si no datos o mas cosas
;
cassete_irq:
    Push-Dword      Px
    Push-Dword      Out
    Lea-Dword       cassete_external_cmd

    Mov-Byte
    Push-Byte       Out
    Cmp-Byte-Inm-Sp CASSETE_WAITING_UE
    Jmp-Word-Zero   cassete_fnc_inserted
    
    Mov-Byte
    Push-Byte       Out
    Cmp-Byte-Inm-Sp CASSETE_READ_SECTA
    Jmp-Word-Zero   cassete_fnc_read_sector

    Jmp-Dword-Clasic cassete_fnc_end

; ===========================================
; cuando leyo un sector
;
cassete_fnc_read_sector:
    Lea-Dword       cassete_readed_sector_finish
    Out-Byte        1
    Jmp-Dword-Clasic cassete_fnc_end

; ===========================================
; cuando se inserto un cassete
;
cassete_fnc_inserted:
    Lea-Dword       disk_inserted ; manda el mensaje
    Jmp-Dword-Call  put_msg     ; pone el mensaje
    Jmp-Dword-Clasic cassete_fnc_end

; ===========================================
; fin de la funcion de cassete
;
cassete_fnc_end:
    Lea-Dword       cassete_external_cmd
    Out-Byte        0
    Add-Dword-Sp-Inm 0
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

Assume-Fill 0x7FFF

firmware_on_flag:
    Byte     0

old_pix_x:
    Byte     0
old_pix_y:
    Byte     0

Assume-Fill 64000

; ===========================================
;           OFITIAL MMIO
;
; vectores de io de mmio para los dispositivos
; reales del PC
;
; ===========================================

alpha_mmio:
                    Byte 0   ; boton A
beta_mmio:          
                    Byte 0   ; boton B
up_mmio:            
                    Byte 0   ; boton arriba
down_mmio:          
                    Byte 0   ; boton abajo
cassete_mmio:       
                    Byte 0   ; mmio del cassete
sga_data_mmio:      
                    Byte 0   ; al ultimo de configurar el SGA row y SGA col se pone el color para esto
sga_row_mmio:       
                    Byte 0   ; posicion y de la SGA
sga_col_mmio:       
                    Byte 0   ; posicion x de la SGA
com1_new_mmio:
                    Byte 0   ; nuevo MMIO del com1
com1_cmd_mmio:
                    Byte 0   ; nuevo MMIO del com1
cassete_sector_read_cmd:
                    Byte 0   ; escribir 2 veces para completar el word