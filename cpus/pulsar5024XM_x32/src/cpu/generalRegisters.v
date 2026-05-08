// ============== general registers ==============
reg  [31:0]     currentPtrAddrs;                    // register of the current uint8_t* ptr
wire [7:0]      PXB1 = currentPtrAddrs  [31:24];    // byte 1 of PX
wire [7:0]      PXB2 = currentPtrAddrs  [23:16];    // byte 2 of PX
wire [7:0]      PXB3 = currentPtrAddrs  [15:8];     // byte 3 of PX
wire [7:0]      PXB4 = currentPtrAddrs  [7:0];      // byte 4 of PX
reg  [7:0]      OprOperator;                        // operator operation
reg  [7:0]      OprOperationBytes;                  // operation bytes length
reg  [7:0]      valueRegister;                      // DX = *(uint8_t*)PX
reg  [7:0]      op_id;                              // operation id
reg  [31:0]     a, b, result;                       // result
