import { argv } from "node:process";
import * as pulsarAsm from "./asm.js";
import * as fileSystem from "node:fs";

let asmFile = argv[2];
let outpudFile = argv[3];
let asmFileContent = fileSystem.readFileSync(asmFile);
let result = pulsarAsm.AssembleCode(asmFileContent).result;
let hex = result.map(b => b.toString(16).padStart(2, '0')).join('\n');

fileSystem.writeFileSync(outpudFile, hex);