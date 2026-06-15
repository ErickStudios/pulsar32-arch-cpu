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
    ; 00h-0Fh
    Dword           alpha_button_irq ; vector del boton 'A' o mas conocido como Alpha
    Dword           beta_button_irq ; vector del boton 'B' o mas conocido como Beta
    Dword           up_button_irq ; vector del boton 'Up'
    Dword           down_button_irq ; vector del boton 'Down'
    Dword           cassete_irq ; vector del dispositivo de la disquetera de cartuchos del mmfs0 (mounted/maped FileSystem 0)
    Dword           0,0,0,0,0,0,0,0,0,0,0
    ; 10h-20h
    Dword           VideoServices ; putchar para imprimir un caracter
    Dword           put_msg ; print para imprimir un texto
    Dword           DiskServices ; servicios de disquete
    Dword           memcpy  ; memory copping para copiar un bloque de memoria a otro
    Dword           _init   ; reset the pc para reiniciar la pc
    Dword           0,0,0,0,0,0,0,0,0,0,0,0
    ; 21h-30h
    Dword           0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; ===========================================
; mapa de caracteres
;
; 1234567890
; ABCDEFGHIJ
; KLMNOPQRST ^
;   UVWXYZ  <v>
;
char_map:
    Byte            49,50,51,52,53,54,55,56,57,58,48    ; 1-0
    Byte            65,66,67,68,69,70,71,72,73,74       ; A-J
	Byte            75,76,77,78,79,80,81,82,83,84,1     ; K-T & Up
	Byte            85,86,87,88,89,90,2,3,4             ; U-Z & Left/Right & Down

Assume-Fill         0x1F0

; ===========================================
; vectors de funciones del firmware 
; (para mantener compatibilidad)
;
_vectors:
    Word        put_char ; coloca un caracter
    Word        put_msg ; pone un mensaje
    Word        memcpy  ; copia memoria
    Word        readsec ; lee un sector

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
    Ror-Byte        Ax, 0Eh     ; funcion
    Ror-Byte        Bx, 1       ; caracter
    Int-Byte        10h         ; interrupcion
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
; para bootear en el mmfs1
;
C1:
    Lea-Dword       Px
    Jmp-Word-Clasic C2
C2:
    Lea-Dword       cassete_selected_mmfs   ; la direccion
    Out-Byte        0                       ; parte alta
    Out-Byte        0                       ; mmfs0
    Lea-Dword       cassete_external_cmd    ; comando
    Out-Byte        CASSETE_READ_SECTA      ; lee un sector
    Lea-Dword       cassete_sector_read_cmd ; la direccion
    Out-Byte        0                       ; parte alta
    Lea-Dword       Px
    Lea-Dword       Px
    Lea-Dword       Px
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
    Ror-Byte        Ax, 0Eh
    Ror-Byte        Bx, 20h
    Int-Byte        10h
    Jmp-Dword-Clasic Sp         ; regresar

; ===========================================
;           DISK INT
;
; funcion de el disco (12h)
;
;   Ax: 02h - Read Sector Into Memory:
;       Bx-Word: El sector
;       Cx-Word: El Filesystem
;       Dx-Dword: Destino de la informacion leida
;
; ===========================================

DiskServices:
    ; Read Sector Into Memory - Leer sector a la memoria
    Cmp-Byte-Reg-Inm Ax, 02h    ; comparar
    Jmp-Dword-Zero  SECT_MEM_W   ; escribir

DiskServicesEnd:
    Jmp-Dword-Clasic Sp         ; regresar

SECT_MEM_W:
    ; obtener
    Lea-Dword       llbasect_sect_low       ; la direccion
    Out-Word        Bx                      ; el sector
    Lea-Dword       llbasect_mmfs_low       ; la direccion
    Out-Word        Cx                      ; el fs

    ; el sector
    Lea-Dword       cassete_selected_mmfs   ; la direccion
    Push-Dword      Px                      ; guardar px
    Lea-Dword       llbasect_mmfs_low       ; el alto
    Mov-Byte                                ; obtener byte
    Lea-Dword       Sp                      ; recuperar px
    Out-Byte        Out                     ; parte alta
    Push-Dword      Px                      ; guardar px
    Lea-Dword       llbasect_mmfs_high      ; el bajo
    Mov-Byte                                ; obtener byte
    Lea-Dword       Sp                      ; recuperar px    
    
    Jmp-Dword-Call  readsec                 ; llamar
    Mov             [Dword memcpy_src], Dword cassete_external_sector ; fuente
    Mov             [Dword memcpy_dst], Dword Dx ; destino
    Mov             [Dword memcpy_siz], Dword 512 ; tamaño
    Int-Byte        13h                     ; el int de copiar memoria
    Jmp-Dword-Clasic DiskServicesEnd        ; regresar

; ===========================================
;           DISPLAY INT
;
; funcion de el display (10h)
;
;   Ax: 0Eh - TTY Write:
;       Bx-Byte: El Caracter
;
;   Ax: 1Eh - TTY WriteMsg:
;       Bx-Dword: El mensaje terminado en null
;                 que sera imprimido en la
;                 consola
;
; ===========================================

VideoServices:
    ; TTY Write Function - Escribir un caracter
    Cmp-Byte-Reg-Inm Ax, 0Eh    ; comparar
    Jmp-Dword-Zero  TTY_WRITE   ; escribir

    ; TTY WriteMsg Function - Escribir un caracter
    Cmp-Byte-Reg-Inm Ax, 1Eh    ; comparar
    Jmp-Dword-Zero  VideoWapperWrtMsgCmpty   ; escribir

VideoServicesEnd:
    Jmp-Dword-Clasic Sp         ; regresar

VideoWapperWrtMsgCmpty:
    Lea-Dword       Bx          ; el
    Int-Byte        11h         ; el int de put_msg
    Jmp-Dword-Clasic VideoServicesEnd   ; regresar

; ===========================================
; manda un caracter a la consola serial
;
TTY_WRITE:
    Push-Dword      Px          ; poner dword
    Lea-Dword       com1_new_mmio ; el caracter a mandar
    Out-Byte        Bx          ; mandar
    Lea-Dword       Sp          ; restaurar la direccion
    Jmp-Dword-Clasic VideoServicesEnd   ; regresar

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
    ; obtener caracter
    Mov-Byte                    ; obtiene el Byte
    Push-Byte       Out         ; pone el Byte en el stack
    Cmp-Byte-Inm-Sp 0           ; compara con terminador
    Jmp-Word-Zero   put_msg_end ; si es igual terminar

    ; escrbir
    Mov-Byte                    ; obtiene el Byte
    Push-Dword      Ax          ; guardar Ax
    Push-Dword      Bx          ; guardar Bx
    Ror-Byte        Ax, 0Eh     ; teletipo
    Ror-Byte        Bx, Out     ; obtener byte
    Int-Byte        10h         ; servicio
    Ror-Dword       Bx, Sp      ; recuperar Bx
    Ror-Dword       Ax, Sp      ; recuperar Ax

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
;           MEMCPY FUNCTION
;
; copia datos de memoria a una ubicacion especifica
;
; ===========================================

memcpy:
    Push-Dword      Px
    Push-Dword      Out
M_LOOP:
M1:
    Lea-Dword       memcpy_src  ; source
    Mov-Dword                   ; obtener dword
    Lea-Dword       Out         ; source real
    Mov-Byte                    ; obtener byte
    Push-Dword      Out         ; guardar out
    Lea-Dword       memcpy_src  ; source
    Mov-Dword                   ; obtener dword
    Push-Dword      Out         ; poner out
    Add-Dword-Sp-Inm 1          ; sumarle out
    Out-Dword       Out         ; ponerlo
    Add-Dword-Sp-Inm 0          ; restaurar out
M2:
    Push-Dword      Out         ; guardar out
    Lea-Dword       memcpy_dst  ; destino
    Mov-Dword                   ; obtener dword
    Lea-Dword       Out         ; destino real
    Add-Dword-Sp-Inm 0          ; restaurar out
    Out-Byte        Out         ; pegar byte
    Push-Dword      Out         ; guardar out
    Lea-Dword       memcpy_dst  ; destino
    Mov-Dword                   ; obtener dword
    Push-Dword      Out         ; poner out
    Add-Dword-Sp-Inm 1          ; sumarle out
    Out-Dword       Out         ; ponerlo
    Add-Dword-Sp-Inm 0          ; restaurar out
M3:
    Push-Dword      Out         ; guardar out
    Lea-Dword       memcpy_siz  ; destino
    Mov-Dword                   ; obtener dword
    Push-Dword      1           ; 1
    Push-Dword      Out         ; poner out
    Sub-Dword-Sp-Sp             ; restarle a out
    Out-Dword       Out         ; ponerlo
    Add-Dword-Sp-Inm 0          ; restaurar out
    Lea-Dword       memcpy_siz  ; destino
    Mov-Dword                   ; obtener dword
    Push-Dword      Out         ; poner el out
    Cmp-Dword-Inm-Sp 0          ; compara con terminador
    Jmp-Word-Zero   M4          ; si es igual terminar
    Jmp-Word-Clasic M_LOOP      ; loopear
M4:
    Add-Dword-Sp-Inm 0          ; recuperar out
    Lea-Dword       Sp          ; recuperar px
    Jmp-Dword-Clasic Sp         ; retorno

; ===========================================
;           READ SECTOR FUNCTION
;
; lee un sector desde un sector especifico
;
; ===========================================

readsec:
    Push-Dword      Px
    Push-Dword      Out
RS2:
    Lea-Dword       cassete_readed_sector_finish ; la direccion
    Out-Byte        0                       ; byte 0
    Lea-Dword       cassete_external_cmd    ; comando
    Out-Byte        CASSETE_READ_SECTA      ; lee un sector
    Lea-Dword       cassete_sector_read_cmd ; la direccion
    Push-Dword      Px                      ; guardar px
    Lea-Dword       llbasect_sect_low       ; el alto
    Mov-Byte                                ; obtener byte
    Lea-Dword       Sp                      ; recuperar px
    Out-Byte        Out                     ; parte alta
    Push-Dword      Px                      ; guardar px
    Lea-Dword       llbasect_sect_high      ; el bajo
    Mov-Byte                                ; obtener byte
    Lea-Dword       Sp                      ; recuperar px
    Out-Byte        Out                     ; parte baja
RS3:
    Hlt                         ; espera
    Lea-Dword       cassete_readed_sector_finish ; la direccion
    Mov-Byte                    ; mover byte
    Push-Byte       1           ; 1
    Push-Byte       Out         ; leer
    Cmp-Byte-Sp-Sp              ; verificar
    Jmp-Word-Zero   RS4         ; se logro leer
    Jmp-Word-Clasic RS3         ; salta
RS4:
    Add-Dword-Sp-Inm 0          ; recuperar out
    Lea-Dword       Sp          ; recuperar px
    Jmp-Dword-Clasic Sp         ; retorno

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

Assume-Fill 0x7200

; ===========================================
;           DATA SECTION
;
; seccion de datos de los parametros de funciones
; del firmware
;
; ===========================================

; ===========================================
; datos de memcpy
;
memcpy_src:
    Dword           0
memcpy_dst:
    Dword           0
memcpy_siz:
    Dword           0

Assume-Fill 0x720D

; ===========================================
; datos de load sector
;
llbasect_sect_low:
    Byte            0
llbasect_sect_high:
    Byte            0

; ===========================================
; datos de load mmfs
;
llbasect_mmfs_low:
    Byte            0
llbasect_mmfs_high:
    Byte            0


Assume-Fill 0x7FFF

old_pix_x:
    Byte     0
old_pix_y:
    Byte     0

firmware_on_flag:
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
cassete_selected_mmfs:
                    Byte 0   ; disco seleccionado , start = (fs * 512) + sector