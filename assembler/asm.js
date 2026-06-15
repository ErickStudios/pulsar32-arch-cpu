export class Context {
  constructor() {
    this.symbols = new Map();
    this.equs = new Map();
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
    if (c === "'") {
      let quoteType = c;
      let value = "";
      i++;
      while (i < code.length && code[i] !== quoteType) {
        value += code[i++];
      }
      i++;
      tokens.push({ type: "number", value: value.charCodeAt(0) });
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

        while (
            i < code.length &&
            (
                isNumber(code[i]) ||
                "ABCDEFabcdef".includes(code[i])
            )
        ) {
            value += code[i++];
        }

        if (
            i < code.length &&
            code[i].toLowerCase() === "h"
        ) {
            i++;
            value = parseInt(value, 16);
        }
        else if (value === "0" && code[i] === "x") {
          i++;
          let value2 = "";
          while (i < code.length && (isNumber(code[i]) || ['A','B','C','D','E','F'].includes(code[i].toUpperCase()))) {
            value2 += code[i++];
          }
          value = parseInt(value2, 16);
        }
        else {
            value = Number(value);
        }

        tokens.push({
            type: "number",
            value
        });

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
export function AssembleLineWithoutContext(line, ctx, len=null) {
  if (len == null) {
    len = ctx.codelen;
  }
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
    if (peek().value === '[') {
      consume();
      let v1 = parsePrimary();
      if (peek().value.toUpperCase() === 'IN') {
        consume();
        let v2 = parsePrimary();
        let result = v2.value + (v1.value - ctx.orgIn);
        expect("]");
        return ({ type: 'inm', value: result });
      }
      else if (peek().value.toUpperCase() === 'SEGMENT') {
        consume();
        let v2 = parsePrimary();
        expect(':');
        let v3 = parsePrimary();
        let result = (v3.value - v2.value) + v1.value;
        expect("]");
        console.log(result);
        return ({ type: 'inm', value: result });
      }
      else if (peek().value.toUpperCase() === 'OUT') {
        consume();
        let v2 = parsePrimary();
        let result = (v1.value - v2.value) + ctx.orgIn;
        expect("]");
        return ({ type: 'inm', value: result });
      }
    }
    if (typeof peek().value === 'number') return ({ type: 'inm', value: consume().value });
    if (peek().value.toUpperCase() === 'SP') {
      consume();
      return ({ type: 'stack' });
    }
    let ident;
    if (peek().type === 'identifier') {
      ident = consume();
      if (ident.value.toUpperCase() === 'OUT') {
        return ({ type: 'symbol', value: 'cpu.registers.result' });
      }
      /*if (ident.value.toUpperCase() === 'DX') {
        return ({ type: 'symbol', value: 'cpu.registers.data' });
      } [[Obsolete]]*/
      if (ident.value.toUpperCase() === 'PX') {
        return ({ type: 'symbol', value: 'cpu.registers.ptr' });
      }
      if (ident.value.toUpperCase() === 'AX') {
        return ({ type: 'symbol', value: 'cpu.registers.ax' });
      }
      if (ident.value.toUpperCase() === 'BX') {
        return ({ type: 'symbol', value: 'cpu.registers.bx' });
      }
      if (ident.value.toUpperCase() === 'CX') {
        return ({ type: 'symbol', value: 'cpu.registers.cx' });
      }
      if (ident.value.toUpperCase() === 'DX') {
        return ({ type: 'symbol', value: 'cpu.registers.dx' });
      }
      if (ctx.symbols.has(ident.value)) {
        return ({ type: 'inm', value: ctx.symbols.get(ident.value) + ctx.orgIn });
      }
      if (ctx.equs.has(ident.value)) {
        return ({ type: 'inm', value: ctx.equs.get(ident.value) });
      }
      return ({ type: 'inm', value: 0 });
    }
    if (ctx.symbols.has(ident.value)) {
      return ({ type: 'inm', value: ctx.symbols.get(ident.value) + ctx.orgIn });
    }
    if (ctx.equs.has(ident.value)) {
      return ({ type: 'inm', value: ctx.equs.get(ident.value) });
    }
    return ({ type: 'inm', value: 0 });

  }
  function parseSymbol(name) {
    if (name === 'cpu.registers.result') {return 0;}
    if (name === 'cpu.registers.data') {return 1;}
    if (name === 'cpu.registers.ptr') {return 2;}
    if (name === 'cpu.registers.ax') {return 3;}
    if (name === 'cpu.registers.bx') {return 4;}
    if (name === 'cpu.registers.cx') {return 5;}
    if (name === 'cpu.registers.dx') {return 6;}

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
  function parseIdent(value) {
    if (typeof value === 'number') return value;
    else if (ctx.symbols.has(value)) return ctx.symbols.get(value);
    return 0;
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
    else if (peek().value.toUpperCase() === 'OUT') {
      consume();
      expect('-');
      result.push(8);
      let sizeof = parseSize(consume().value);
      let expr = parsePrimary();
      if (expr.type === 'inm') {
        result.push(0, sizeof, ...toBigEndianBytes(expr.value, sizeof));
      }
      else if (expr.type == 'symbol') {
        result.push(1, sizeof, parseSymbol(expr.value))
      }
    }
    else if (peek().value.toUpperCase() === 'INT') {
      consume();
      expect('-');
      result.push(9);
      let sizeof = parseSize(consume().value);
      let expr = parsePrimary();
      if (expr.type === 'inm') {
        result.push(0, sizeof, ...toBigEndianBytes(expr.value, sizeof));
      }
      else if (expr.type == 'symbol') {
        result.push(1, sizeof, parseSymbol(expr.value))
      }
      else if (expr.type == 'stack') {
        result.push(2, sizeof);
      }
    }
    else if (peek().value.toUpperCase() === 'LEA') {
      consume();
      expect('-');
      result.push(1);
      let sizeof = parseSize(consume().value);
      let expr = parsePrimary();
      if (expr.type === 'inm') {
        result.push(0, sizeof, ...toBigEndianBytes(expr.value, sizeof));
      }
      else if (expr.type == 'symbol') {
        result.push(1, sizeof, parseSymbol(expr.value))
      }
      else if (expr.type == 'stack') {
        result.push(2, sizeof);
      }
    }
    else if (peek().value.toUpperCase() === 'MOV') {
      consume();
      if (peek().value == '-') {
        consume();
        result.push(4);
        result.push(8);
        let sizeof = parseSize(consume().value);
        result.push(sizeof, 0);
      }
      else {
        expect("[");
        let sizeof;
        let expr;
        let sizeof1 = parseSize(consume().value);
        let expr1 = parsePrimary();
        expect("]");
        expect(",");
        let sizeof2 = parseSize(consume().value);
        let expr2 = parsePrimary();

        result.push(1);
        sizeof = sizeof1;
        expr = expr1;
        if (expr.type === 'inm') { result.push(0, sizeof, ...toBigEndianBytes(expr.value, sizeof)); }
        else if (expr.type == 'symbol') { result.push(1, sizeof, parseSymbol(expr.value)) }
        else if (expr.type == 'stack') { result.push(2, sizeof); }

        result.push(8);
        sizeof = sizeof2;
        expr = expr2;
        if (expr.type === 'inm') { result.push(0, sizeof, ...toBigEndianBytes(expr.value, sizeof)); }
        else if (expr.type == 'symbol') { result.push(1, sizeof, parseSymbol(expr.value)) }
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
      let a0 = casterA(operand1);
       if (a0 && operand2.type !== 'stack') expect(',');
      let a1 = casterA(operand2);
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
        result.push(1);
      }
      else if (expr.type == 'stack') {
        result.push(2);
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
      else if (mode.toUpperCase() === 'CALL') {
        result.push(4);
      }
      if (expr.type === 'inm') {
        result.push(...toBigEndianBytes(expr.value, sizeof));
      }
      else if (expr.type == 'symbol') {
        result.push(parseSymbol(expr.value))
      }
    }
    else if (peek().value.toUpperCase() === 'ADD') parseOperation(1);
    else if (peek().value.toUpperCase() === 'SUB') parseOperation(2);
    else if (peek().value.toUpperCase() === 'MUL') parseOperation(3);
    else if (peek().value.toUpperCase() === 'DIV') parseOperation(4);
    else if (peek().value.toUpperCase() === 'AND') parseOperation(5);
    else if (peek().value.toUpperCase() === 'OR') parseOperation(6);
    else if (peek().value.toUpperCase() === 'XOR') parseOperation(7);
    else if (peek().value.toUpperCase() === 'SHL') parseOperation(9);
    else if (peek().value.toUpperCase() === 'SHR') parseOperation(10);
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
        let primarys = toBigEndianBytes(parseIdent(parsePrimary().value),sizeof);
        while (peek() && peek().value === ",") {
          consume();
          primarys.push(...toBigEndianBytes(
            parseIdent(parsePrimary().value),sizeof
          ));
        }
        result.push(...primarys);
      }
      else if (action.value.toUpperCase() === "FILL") {
        let fillto = consume().value;
        let bytesfill = fillto - len;
        result.push(...Array(bytesfill).fill(0));
      }
    }
    else if (peek().value.toUpperCase() === 'ALIGN') {
      consume();
      let alignTo = consume().value;
      let bytesfill = (alignTo - (len % alignTo)) % alignTo;
      result.push(...Array(bytesfill).fill(0));
    }
    else if (peek().value.toUpperCase() === 'ROR') {
      consume();
      result.push(0xA);
      expect('-');
      let sizeof = parseSize(consume().value);
      let reg = parsePrimary();
      if (reg.type === 'symbol') {
        let a = parseSymbol(reg.value);
        expect(",");
        let expr = parsePrimary();
        if (expr.type === 'inm') {
          result.push(0, sizeof, a, ...toBigEndianBytes(expr.value, sizeof));
        }
        else if (expr.type == 'symbol') {
          result.push(1, sizeof, a, parseSymbol(expr.value))
        }
        else if (expr.type == 'stack') {
          result.push(2, sizeof, a);
        }
      }
    }
    else if (parseSize(peek().value.toUpperCase()) !== undefined) {
      let sizeof = parseSize(consume().value.toUpperCase());
      let primarys = toBigEndianBytes(parseIdent(parsePrimary().value), sizeof);
      while (peek() && peek().value === ",") {
        consume();
        primarys.push(...toBigEndianBytes(
          parseIdent(parsePrimary().value), sizeof
        ));
      }
      result.push(...primarys);
    }
    else if (peek().type === 'symbol' && peek().value === ';') break;
    else if (peek().type === 'identifier' && typeof peek().value === 'string') {
      let varName = consume().value;
      if (peek().type === 'symbol' && peek().value === ':') {
        consume();
        if (!('passDefedNot' in ctx)) ctx.symbols.set(varName, ctx.codelen);
        continue;
      } else if (peek().value.toUpperCase() === 'EQU') {
        consume();
        let v = consume().value;
        if (!('passDefedNot' in ctx)) ctx.equs.set(varName, v);
        continue;
      }else {
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
  let len = 0;
  lines.forEach((line) => {
    let lineAssembled = AssembleLineWithoutContext(line, context,len);
    result.push(...lineAssembled);
    len += lineAssembled.length;
  })
  return { result, context };
}