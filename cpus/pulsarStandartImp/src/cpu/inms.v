// ============== function for inms  ==============
// | read a inmediate in the text of the program  |
// |                                              |
// | #NONDEBUG #INM #FUNCTION                     |
// ------------------------------------------------
function [31:0] readINM; input [7:0] bytesLen; input [31:0] baseAddr; begin
    case (bytesLen)
        1: readINM = memory[baseAddr];
        2: readINM = {memory[baseAddr],memory[baseAddr + 1]};
        4: readINM = {memory[baseAddr],memory[baseAddr + 1],memory[baseAddr + 2],memory[baseAddr + 3]
        };
        default: readINM = 0;
    endcase
end endfunction