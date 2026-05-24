![pulsar5024XM_x32](../logo.png)

# MMIO en pulsar

## Como funciona

Para entender la historia de Five Nigths at, ok no..., para ver como funcionan el MMIO tenemos una historia un poco curiosa la verdad

### Historia de como se hizo

El MMIO salio debido a un problema que ocurria, nativamente el CPU no tiene MMIO, tiene forma de leer la memoria con variables pero no es MMIO, ya que este se implementa desde el testbench o el top, esto hacia que para mi programar el MMIO manual fuera tedioso

Debido a que las pcs no por mi si no por que luego ustedes se quejan por adaptar una unidad del CPU a una pc para que sea mas eficiente, esto para que nada fuera desigual y que no tuvieran problemas con la compatibilidad, esto hacia que debido a que ustedes, si los que leen este markdown, aveces pueden estar comentando de que 'el cpu esta modificado' y tienen razon, si esta modificado

Pero esto no se hace por que si, se hace por problemas de diseño y limitaciones, entonces a finales de mayo se empezo a trabajar en una actualizacion que solucionaria este estres asi que se añadio el MMIO nativo

## Donde se ubica

la memoria antes de la version del 24 de mayo de 2026 tenia 64KiB (KB = 1024 B, KiB = 1000 B) + 1 que se me escapo debido a que puse 64000 y no 63999 haciendo que quede uno extra, y ahora tiene 96KiB. Por que?, esto debido a que los 32KiB añadidos son para MMIO, y ya se, no escriban datos importantes de variables alli por que cuando intenten usar esa RAM para comunicarse con los dispositivos se va a comer esos valores

se ubica en la direccion 64000 (en decimal) apartir de alli si se escribe alli se hara la siguiente operacion en el cpu
$$
y = d - 64000
$$
donde d es la direccion de memoria donde se escribio el byte, esto tambien afecta si escribes varios con la instruccion SDX mas conocida como Out en el ensamblador estandart (ojo no confundir con el primario Out que ese sirve para obtener el registro interno conocido como `result` que es donde Cmp, las operaciones matematicas y Mov (que es tambien otra operacion disfrazada de instruccion independiente en el ensamblador) dejan su resultado o residuo) 

## Como usarlo

No se sabe si necesariamente se tiene que crear un device necesario para eso pero mejor no intenten hacerlo sin device o si no tal vez o verilog se vuelve loco o se congela el cpu

pero ya creado un dispositivo por ejemplo
```verilog
device #(.BASE_ADDR(32'h4)) cassete(
    .clk            (clk),
    .reset          (reset),
    .enable         (cassete_enable),
    .data_in        (cassete_data),

    .irq            (irq5),
    .irq_addr       (addr5),
    .irq_data       (data5),
    .irq_ack        (irq_ack5),
    
    .wrt_en         (dev_wrt_en),
    .wrt_addr       (dev_wrt_addr),
    .wrt_val        (dev_wrt_val)
);
```
solo tiene que usar el index del dispositivo que puso en BASE_ADDR y para verificar que le llegaron datos en el allways cada vez que cambia el relog simplemente se pone
```verilog
if (dev_wrt_en && dev_wrt_addr == index_a_tu_device) begin
    // tu codigo ...
end
```
claro siempre y cuando dev_wrt_en y dev_wrt_addr sean correctos en tu declaracion de instancia del cpu por ejemplo es correcto en el caso de
```verilog
cpu uut(
    .clk            (clk),
    .reset          (reset),

    .irq            (irq),
    .irq_addr       (irq_addr),
    .irq_data       (irq_data),
    .irq_ack        (irq_ack),

    .mem_wrt_val    (mwv),
    .mem_wrt_addr   (mwa),
    .mem_wrt_bool   (mwb),

    .mem_rdr_val    (mrv),
    .mem_rdr_addr   (mra),
    .mem_rdr_bool   (mrb),

    .dev_wrt_en     (dev_wrt_en),
    .dev_wrt_addr   (dev_wrt_addr),
    .dev_wrt_val    (dev_wrt_val)
);

```
si no es correcto en otro caso simplemente usa los nombres de las variables a las que ancle los parametros correspondientes,
lo mismo aplica para el device