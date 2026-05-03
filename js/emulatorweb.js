/** @class CPU */
let cpu = new CPU({
    place: (v) => {
        /** @type { HTMLTextAreaElement } */
        let el = document.getElementById("areaText");
        el.value += v + "\n";
        el.scrollTop = el.scrollHeight;
    }
});
cpu.debugger.place("pulsar5024XM_x32 chip debug");
