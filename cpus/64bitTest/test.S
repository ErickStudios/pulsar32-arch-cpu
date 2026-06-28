
    org32
vectors: 
    Dword start        ; vector de arranque
    Mode32 EQU 00h ; modo de ejecucion
    Mode64 EQU 01h ; modo de ejecucion

    Byte        0
start:
    dbgAc64                 ; configurar el 64 (skip solo para debug)
    org64                   ; decirle al asm que esta en Pulsar64

    add         r0, 0, 0    ; limpiar r0
    calc        r0          ; limpiar flags

    li64        sp, STACK_TOP;cargar tope del stack
    li64        r0, CPUTABLE; cargar direccion de la tabla
    ltbl        r0          ; cargar tabla

    sub         r0, 7, 7    ; restar ya que asi se calcula
    calc        r0          ; actualizar flags (01 FF FF 23)

    slcinm      02h         ; seleccionar el inm a editar
    rstinm                  ; resetear el inm que se esta editando
    ld64        TestEqual   ; valor a cargar

    jifeq       i(02h)      ; saltar al inmediato 2 (01 FF 3[BitToBeTruthyFor] TI)

    add         r0, 4, 5    ; xd  

TestEqual:
    add         r0, 1, 2    ; xd  
    
    int         12h         ; lanzar int

    Align       128 Byte 0
STACK_START:
    Align       128
STACK_TOP:

    Align       4096
CPUTABLE:
    Qword       InterruptionsTable
    Qword       LevelsSettings
    Qword       MemoryRegionsTable

    Align       16
InterruptionsTable:

    ; ========== 00h a 0Fh reservados para excepciones

    Dword       Mode64, 00h ; permisos de la excepcion de violacion de segmento
    Qword       segfault    ; puntero alli

    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0
    Qword       0,0

    Dword       Mode32      ; modo de ISA en el que operara
    Dword       00h         ; indice de la paleta de nivel de privilegio
    Qword       isr1        ; manejador

    Dword       Mode64      ; modo de ISA en el que operara
    Dword       00h         ; indice de la paleta de nivel de privilegio
    Qword       isr2        ; manejador

    Dword       Mode64      ; modo de ISA en el que operara
    Dword       01h         ; indice de la paleta de nivel de privilegio
    Qword       user_load   ; manejador

    Align       16
LevelsSettings:
    Qword       00h, 0FFFFFFFFH ; IOM + PRIVS (kernel)
    Qword       01h, 0FFFFFFF3H ; IOM + PRIVS (user)

    Align       16
MemoryRegionsTable:
    Qword       00000000h
    Dword       0FFFFFFFFh, 0FFFFFFFFh ; inicio y fin de donde tiene permitido escribir
    Qword       ProgramsSafeZone, EndProgramSafeZone ; final

ProgramsSafeZone:
user_load:
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
    Align 512 Byte  0
EndProgramSafeZone:

    org32
isr1:
    Push-Dword          10  ; probar
    Ror-Dword           Ax, Sp ; recuperar
    Iret                    ; instruccion especial para retornar el contexto

    org64
    Align       4
isr2:
    sub         sp, sp, 8   ; restar
    mwr64       sp, r0      ; poner en el stack

    li64        r0, xd2     ; obtener direccion

    jmp         r0
    add         r0, r0, 7   ; ejemplo para saltar

xd2:
    ifm64       02h, sp     ; obtener del el puntero al stack
    add         sp, sp, 8   ; añadir
    linm        r0, 02h     ; obtener inmediato
    
    iret

    org64
segfault:
    li64        r0, segfault; obtener direccion del label
    jmp         r0          ; saltar