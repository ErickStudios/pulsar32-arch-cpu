export class Context {
    constructor() {
        this.symbols = new Map();
        this.codelen = 0;
        this.orgIn = 0;
        this.result = [];
    }
}
export function tokenize(code) {
  const tokens = [];
  let i = 0;
  const isLetter = (c) => /[a-zA-Z_]/.test(c);
  const isNumber = (c) => /[0-9]/.test(c);
  while (i < code.length) {
    let c = code[i];
    if (/\s/.test(c)) {
      i++;
      continue;
    }
    if (c === "/" && code[i + 1] === "/") {
      while (i < code.length && code[i] !== "\n") {
        i++;
      }
      continue;
    }
    if (c === '"' || c === "'") {
      let quoteType = c;
      let value = "";
      i++;
      while (i < code.length && code[i] !== quoteType) {
        value += code[i++];
      }
      i++;
      tokens.push({ type: "string", value });
      continue;
    }
    if (isLetter(c)) {
      let value = "";
      while (i < code.length && (isLetter(code[i]) || isNumber(code[i]))) {
        value += code[i++];
      }
      tokens.push({ type: "identifier", value });
      continue;
    }
    if (isNumber(c)) {
      let value = "";
      while (i < code.length && isNumber(code[i])) {
        value += code[i++];
      }
      tokens.push({ type: "number", value: Number(value) });
      continue;
    }
    tokens.push({ type: "symbol", value: c });
    i++;
  }
  return tokens;
}
export function toBigEndianBytes(n, x) {
    let bytes = [];
    while (n > 0) {
        bytes.push(n & 0xFF);
        n = n >> 8;
    }
    bytes.reverse();
    while (bytes.length < x) {
        bytes.unshift(0);
    }
    return bytes;
}
export function AssembleLineWithoutContext(line, ctx) {
    let tokens = tokenize(line);
    let i = 0;
    let result = [];
    function peek() {
        return tokens[i];
    }
    function consume() {
        return tokens[i++];
    }
    function expect(value) {
        let t = consume();
        if (!t || t.value !== value) {
            throw new Error("Expected " + value);
        }
    }
    function parseSize(name) {
        switch (name.toUpperCase()) {
            case 'BYTE': return 1;
            case 'WORD': return 2;
            case 'DWORD': return 4;
        }
    }
    function parsePrimary() {
        if (typeof peek().value === 'number') return ({type: 'inm', value: consume().value});
        if (peek().type === 'identifier') {
            let ident = consume();

            if (ident.value.toUpperCase() === 'OUT') {
                return ({type: 'symbol', value: 'cpu.registers.result'});
            }
            if (ident.value.toUpperCase() === 'DX') {
                return ({type: 'symbol', value: 'cpu.registers.data'});
            }
            if (ident.value.toUpperCase() === 'PX') {
                return ({type: 'symbol', value: 'cpu.registers.ptr'});
            }
            if (ctx.symbols.has(ident.value)) {
                return ({type: 'inm', value: ctx.symbols.get(ident.value) + ctx.orgIn});
            }
        }
    }
    function parseSymbol(name) {
        if (name === 'cpu.registers.result') {
            return 0;
        }
        if (name === 'cpu.registers.data') {
            return 1;
        }
        if (name === 'cpu.registers.ptr') {
            return 2;
        }
    }
    function operandParse(op) {
        if (op.toUpperCase() == "SP") return { type: 'stack', bind: 2 };
        if (op.toUpperCase() == "INM") return { type: 'inm', bind: 0 };
        if (op.toUpperCase() == "REG") return { type: 'reg', bind: 1 };

    }
    function parseOperation(id) {
        consume();
        result.push(4);
        result.push(id);
        expect('-');
        let sizeof = parseSize(consume().value);
        result.push(sizeof);
        expect('-');
        let operand1 = operandParse(consume().value);
        expect('-');
        let operand2 = operandParse(consume().value);
        result.push((operand1.bind << 4) | operand2.bind);
        let casterA = (operand) => {
            if (operand.type !== 'stack') {
                let primary = parsePrimary();
                if (primary.type === 'symbol' && operand.type === 'reg') {
                    result.push(parseSymbol(primary.value));
                    return true;
                }
                if (primary.type === 'inm' && operand.type === 'inm') {
                    result.push(...toBigEndianBytes(primary.value, sizeof));
                    return true;
                }
            }
            return false;
        }
        if (casterA(operand1)) expect(',');
        casterA(operand2);
    }
    while (i < tokens.length) {
        if (peek().value.toUpperCase() === 'PUSH') {
            consume();
            expect('-');
            result.push(3);
            let sizeof = parseSize(consume().value);
            let expr = parsePrimary();
            if (expr.type === 'inm') {
                result.push(0, sizeof, ...toBigEndianBytes(expr.value, sizeof));
            }
            else if (expr.type == 'symbol') {
                result.push(1, sizeof, parseSymbol(expr.value))
            }
        }
        else if (peek().value.toUpperCase() === 'HLT') {
            consume();
            result.push(5);
        }
        else if (peek().value.toUpperCase() === "CMP") {
            consume();
            result.push(6);
            expect('-');
            let sizeof = parseSize(consume().value);
            result.push(sizeof);
            expect('-');
            let operand1 = operandParse(consume().value);
            expect('-');
            let operand2 = operandParse(consume().value);
            result.push((operand1.bind << 4) | operand2.bind);

            let casterA = (operand) => {
                if (operand.type !== 'stack') {
                    let primary = parsePrimary();
                    if (primary.type === 'symbol' && operand.type === 'reg') {
                        result.push(parseSymbol(primary.value));
                        return true;
                    }
                    if (primary.type === 'inm' && operand.type === 'inm') {
                        result.push(...toBigEndianBytes(primary.value, sizeof));
                        return true;
                    }
                }
                return false;
            }
            if (casterA(operand1)) expect(',');
            casterA(operand2);
        }
        else if (peek().value.toUpperCase() === "JMP") {
            consume();
            result.push(7);
            expect('-');
            let sizeof = parseSize(consume().value);
            result.push(sizeof);
            expect('-');
            let mode = consume().value;
            let expr = parsePrimary();
            if (expr.type === 'inm') {
                result.push(0);
            }
            else if (expr.type == 'symbol') {
                result.push(1)
            }
            if (mode.toUpperCase() === 'CLASIC') {
                result.push(0);
            }
            else if (mode.toUpperCase() === 'ZERO') {
                result.push(1);
            }
            else if (mode.toUpperCase() === 'LESS') {
                result.push(2);
            }
            else if (mode.toUpperCase() === 'GREATER') {
                result.push(3);
            }
            if (expr.type === 'inm') {
                result.push(...toBigEndianBytes(expr.value, sizeof));
            }
            else if (expr.type == 'symbol') {
                result.push(parseSymbol(expr.value))
            }
        }
        else if (peek().value.toUpperCase() === 'ADD') parseOperation(1);
        else if (peek().value.toUpperCase() === 'ASSUME') {
            consume();
            expect('-');
            let action = consume();
            if (action.value.toUpperCase() === 'ORG') {
                let inWhere = consume();
                ctx.orgIn = inWhere.value;
            }
            else if (parseSize(action.value.toUpperCase()) !== undefined) {
                let sizeof = parseSize(action.value.toUpperCase());
                result.push(...toBigEndianBytes(consume().value, sizeof));
            }
        }
        else if (peek().type === 'symbol' && peek().value === ';') break;
        else if (peek().type === 'identifier' && typeof peek().value === 'string') {
            let varName = consume().value;
            if (peek().type === 'symbol' && peek().value === ':') {
                consume();
                if (!('passDefedNot' in ctx)) ctx.symbols.set(varName, ctx.codelen);
                continue;
            } else {
                throw new Error("Unexpected identifier: " + varName);
            }
        }
    }
    return result;
}
export function AssembleCode(code) {
    let lines = code.split('\n');
    let result = [];
    let context = new Context();
    lines.forEach((line) => {
        let lineAssembled = AssembleLineWithoutContext(line, context);
        context.codelen += lineAssembled.length;
    })
    context.passDefedNot = true;
    lines.forEach((line) => {
        let lineAssembled = AssembleLineWithoutContext(line, context);
        result.push(...lineAssembled);
    })
    return {result, context};
}