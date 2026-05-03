// ============== function for opers ==============
// | A instant function for the operations regs   |
// | , inms, stack and other modes                |
// |                                              |
// | #FASTER #STARTER                             |
// ------------------------------------------------
function [31:0] operateInstant; input [3:0] modeOpr; input [7:0] bytesLen; begin
    case (modeOpr)
        4'h0: begin
            operateInstant = readINM(bytesLen, pc);
            pc = pc + bytesLen;
        end
        4'h1: begin
            a = memory[pc];
            pc = pc + 1;

            case (a)
                0: operateInstant = result;
                1: operateInstant = valueRegister;
                2: operateInstant = currentPtrAddrs;
                default: operateInstant = 0;
            endcase
        end
        4'h2: begin
            operateInstant = readINM(bytesLen, sp);
            sp = sp + bytesLen;
        end
        default: begin while (1); end
    endcase
end endfunction