import { CPU } from "./cpunode.js";
import { readFileSync } from "node:fs"
import { argv } from "node:process";

let fileName = argv[2];
let fileContent = readFileSync(fileName, 'utf-8');
let cpu = new CPU();

fileContent = fileContent.replaceAll(" ", "\n").replaceAll("\r","");
let contentBytes = fileContent.split("\n").map(v => Number.parseInt(v, 16));
contentBytes.forEach((v,i) => {
    cpu.memory[i] = v;
});

setInterval(() => {
  cpu.tick();
}, 1);