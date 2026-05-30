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
;           BITMAP FONT
;
; fuente del texto fuera del com1 serial y dentro
; del adaptador de video
;
; ===========================================

; ===========================================
; multiply font size
;
_bitmap_font_size:
    Byte        2 ; tamaño en altura de pixeles
    Byte        4 ; tamaño en anchura de pixeles
_bitmap_font_size_pixels:
    Byte        8 ; tamaño en altura de pixeles
    Byte        8 ; tamaño en anchura de pixeles
_calculed_font_sizeof:
    Byte        0 ; calculado

; ===========================================
; fuente del firmware en la consola de modo texto
;
_bitmap:
    Dword       0,0; (char8_t)0x00
    Dword       2122425729,3180953982; (char8_t)0x01
    Dword       2130697215,3286761342; (char8_t)0x02
    Dword       1828650750,2084048896; (char8_t)0x03
    Dword       272137470,2084048896; (char8_t)0x04
    Dword       947665150,4269553788; (char8_t)0x05
    Dword       269498492,4269553788; (char8_t)0x06
    Dword       6204,1008205824; (char8_t)0x07
    Dword       4294961091,3286761471; (char8_t)0x08
    Dword       3958338,1113996288; (char8_t)0x09
    Dword       4291008957,3180971007; (char8_t)0x0A
    Dword       252120957,3435973752; (char8_t)0x0B
    Dword       1013343846,1008238104; (char8_t)0x0C
    Dword       1060323120,812708064; (char8_t)0x0D
    Dword       2137227107,1667753664; (char8_t)0x0E
    Dword       2572827879,3879492249; (char8_t)0x0F
    Dword       2162227454,4175462400; (char8_t)0x10
    Dword       34488062,1041105408; (char8_t)0x11
    Dword       406617624,410926104; (char8_t)0x12
    Dword       1717986918,1711302144; (char8_t)0x13
    Dword       2145115003,454761216; (char8_t)0x14
    Dword       1046689900,1815661688; (char8_t)0x15
    Dword       0,2122219008; (char8_t)0x16
    Dword       406617624,2117867775; (char8_t)0x17
    Dword       406617624,404232192; (char8_t)0x18
    Dword       404232216,2117867520; (char8_t)0x19
    Dword       1576190,202899456; (char8_t)0x1A
    Dword       3170558,1613758464; (char8_t)0x1B
    Dword       49344,3237871616; (char8_t)0x1C
    Dword       2385663,1713635328; (char8_t)0x1D
    Dword       1588350,4294901760; (char8_t)0x1E
    Dword       16777086,1008205824; (char8_t)0x1F
    Dword       0,0; (char8_t)0x20
    Dword       813201456,805318656; (char8_t)0x21
    Dword       1819044864,0; (char8_t)0x22
    Dword       1819082348,4268518400; (char8_t)0x23
    Dword       813482104,217591808; (char8_t)0x24
    Dword       13028376,812041728; (char8_t)0x25
    Dword       946616438,3704387072; (char8_t)0x26
    Dword       1616953344,0; (char8_t)0x27
    Dword       405823584,1613764608; (char8_t)0x28
    Dword       1613764632,405823488; (char8_t)0x29
    Dword       6700287,1013317632; (char8_t)0x2A
    Dword       3158268,808452096; (char8_t)0x2B
    Dword       0,3158112; (char8_t)0x2C
    Dword       252,0; (char8_t)0x2D
    Dword       0,3158016; (char8_t)0x2E
    Dword       101455920,1623228416; (char8_t)0x2F
    Dword       2093403870,4142300160; (char8_t)0x30
    Dword       812658736,808516608; (char8_t)0x31
    Dword       2026638392,1624046592; (char8_t)0x32
    Dword       2026638392,214726656; (char8_t)0x33
    Dword       473722060,4262206976; (char8_t)0x34
    Dword       4240504844,214726656; (char8_t)0x35
    Dword       945864952,3435952128; (char8_t)0x36
    Dword       4241230872,808464384; (char8_t)0x37
    Dword       2026687608,3435952128; (char8_t)0x38
    Dword       2026687612,202928128; (char8_t)0x39
    Dword       3158016,3158016; (char8_t)0x3A
    Dword       3158016,3158112; (char8_t)0x3B
    Dword       405823680,1613764608; (char8_t)0x3C
    Dword       64512,16515072; (char8_t)0x3D
    Dword       1613764620,405823488; (char8_t)0x3E
    Dword       2026638360,805318656; (char8_t)0x3F
    Dword       2093407966,3737155584; (char8_t)0x40
    Dword       813223116,4241280000; (char8_t)0x41
    Dword       4234569340,1718025216; (char8_t)0x42
    Dword       1013366976,3227925504; (char8_t)0x43
    Dword       4167853670,1718417408; (char8_t)0x44
    Dword       4267862136,1751318016; (char8_t)0x45
    Dword       4267862136,1751183360; (char8_t)0x46
    Dword       1013366976,3462807040; (char8_t)0x47
    Dword       3435973884,3435973632; (char8_t)0x48
    Dword       2016423984,808482816; (char8_t)0x49
    Dword       504105996,3435952128; (char8_t)0x4A
    Dword       3865472120,1818682880; (char8_t)0x4B
    Dword       4032847968,1650916864; (char8_t)0x4C
    Dword       3337551614,3603351040; (char8_t)0x4D
    Dword       3337025246,3469133312; (char8_t)0x4E
    Dword       946652870,3328980992; (char8_t)0x4F
    Dword       4234569340,1616965632; (char8_t)0x50
    Dword       2026687692,3698859008; (char8_t)0x51
    Dword       4234569340,1818682880; (char8_t)0x52
    Dword       2026692720,483162112; (char8_t)0x53
    Dword       4239667248,808482816; (char8_t)0x54
    Dword       3435973836,3435985920; (char8_t)0x55
    Dword       3435973836,3430428672; (char8_t)0x56
    Dword       3334915798,4277061120; (char8_t)0x57
    Dword       3334892600,946652672; (char8_t)0x58
    Dword       3435973752,808482816; (char8_t)0x59
    Dword       4274424856,845610496; (char8_t)0x5A
    Dword       2019582048,1616934912; (char8_t)0x5B
    Dword       3227529240,201720320; (char8_t)0x5C
    Dword       2014844952,404256768; (char8_t)0x5D
    Dword       272133318,0; (char8_t)0x5E
    Dword       0,255; (char8_t)0x5F
    Dword       808458240,0; (char8_t)0x60
    Dword       30732,2093774336; (char8_t)0x61
    Dword       3764412540,1718017024; (char8_t)0x62
    Dword       30924,3234625536; (char8_t)0x63
    Dword       470551676,3435951616; (char8_t)0x64
    Dword       30924,4240472064; (char8_t)0x65
    Dword       946626800,1616965632; (char8_t)0x66
    Dword       30412,3430681848; (char8_t)0x67
    Dword       3764415606,1718019584; (char8_t)0x68
    Dword       805335088,808482816; (char8_t)0x69
    Dword       201329676,214748280; (char8_t)0x6A
    Dword       3764414060,2020402688; (char8_t)0x6B
    Dword       1882206256,808482816; (char8_t)0x6C
    Dword       52478,4275488256; (char8_t)0x6D
    Dword       63692,3435973632; (char8_t)0x6E
    Dword       30924,3435952128; (char8_t)0x6F
    Dword       56422,1719427312; (char8_t)0x70
    Dword       30412,3430681630; (char8_t)0x71
    Dword       56438,1717628928; (char8_t)0x72
    Dword       31936,2014115840; (char8_t)0x73
    Dword       271612976,808720384; (char8_t)0x74
    Dword       52428,3435951616; (char8_t)0x75
    Dword       52428,3430428672; (char8_t)0x76
    Dword       50902,4278086656; (char8_t)0x77
    Dword       50796,946652672; (char8_t)0x78
    Dword       52428,3430681848; (char8_t)0x79
    Dword       64664,811924480; (char8_t)0x7A
    Dword       472920288,808459264; (char8_t)0x7B
    Dword       404232192,404232192; (char8_t)0x7C
    Dword       3761254428,808509440; (char8_t)0x7D
    Dword       1994129408,0; (char8_t)0x7E
    Dword       1063020,3334929920; (char8_t)0x7F

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
    Lea-Dword       serial_port_cmd
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

    Jmp-Dword-Call  put_char_bitmap

    Lea-Dword       sga_row_mmio
    Out-Byte        3
    Lea-Dword       sga_col_mmio
    Out-Byte        3
    Lea-Dword       sga_data_mmio
    Out-Byte        0xFF
    Jmp-Word-Clasic loop

; ===========================================
; el loop que el firmware tiene para ser un
; os pequeño en si mismo y esperar eventos
;
loop:
    Jmp-Word-Clasic loop2
loop2:
    Hlt                         ; espera
    Jmp-Word-Clasic loop        ; salta

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
    Lea-Dword       serial_char_send ; el caracter a mandar
    Out-Byte        0           ; actualizar
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
; pone un caracter en la consola
;
put_char_bitmap:
    Push-Dword      Px          ; palabra
    Push-Dword      Out         ; resultado
    Lea-Dword       sga_col_mmio ; fuente
    Mov-Byte                    ; copiar byte a Out
    Lea-Dword       old_pix_x   ; destino
    Out-Byte        Out         ; colocar byte desde el extraido
    Lea-Dword       sga_row_mmio ; fuente
    Mov-Byte                    ; copiar byte a Out
    Lea-Dword       old_pix_y   ; destino
    Out-Byte        Out         ; colocar byte desde el extraido
put_char_bitmap_calc:
    Lea-Dword       _bitmap_font_size ; altura
    Mov-Byte                    ; obtener byte
    Lea-Dword       _calculed_font_sizeof ; guardar calculo
    Out-Byte        Out         ; colocar calculo
    Lea-Dword       _bitmap_font_size ; base direccion
    Push-Dword      Px          ; poner direccion
    Add-Dword-Sp-Inm 1          ; extraer PX y sumarle al offset
    Lea-Dword       Out         ; obtener anchura
    Mov-Byte                    ; obtener byte
    Push-Byte       Out         ; guardar byte
    Lea-Dword       _calculed_font_sizeof ; calculado
    Mov-Byte                    ; obtener byte
    Push-Byte       Out         ; ponerlo en el stack
    Mul-Byte-Sp-Sp              ; poner sp
    Out-Byte        Out         ; calculado
put_char_bitmap_calc_absolute_dir:
    Mov-Byte                    ; guardarlo
    Push-Dword      Out         ; prepararlo para el cast
    Push-Dword      _bitmap     ; la direccion del bitmap
    Add-Dword-Sp-Sp             ; calcular direccion
    Lea-Dword       Out         ; mandar direccion
put_char_bitmap_end:
    Add-Dword-Sp-Inm 0
    Lea-Dword       Sp
    Jmp-Dword-Clasic Sp

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
