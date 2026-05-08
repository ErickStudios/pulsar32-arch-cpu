// ============== function for debug ==============
// | the function for convert operation modes to  |
// | human readable words for identific the opera-|
// | tions                                        |
// |                                              |
// | #DEBUG #CASTING #HUMANREADABLE               |
// ------------------------------------------------
function [63:0] castToDebug; input [3:0] modeOpr; begin 
    case (modeOpr)
        4'h0: castToDebug = `STR_INM;               // str inm
        4'h1: castToDebug = `STR_REG;               // str reg
        4'h2: castToDebug = `STR_STK;               // str stack
        default: castToDebug = `STR_UNK;            // str unknown
    endcase 
end endfunction
