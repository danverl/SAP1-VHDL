`ifndef CONTROL_LOGIC_V
`define CONTROL_LOGIC_V

module control_logic (
    input  wire        i_nclk       , // Input system clock
    input  wire        i_clr        , // Clear input
    input  wire        i_rst        , // Input reset
    input  wire        i_zf         , // Zero flag from ALU
    input  wire        i_cf         , // Carry flag from ALU
    input  wire [3:0]  i_instruction, // 4-bit Opcode from Instruction Register
    
    output wire [18:0] o_control_word // 19-bit control word bus
);

    reg [2:0] instruction_count;
    
    // Microcode counter for instructions, T0 - T5
    always @(posedge i_nclk or posedge i_rst) begin
        if (i_rst || i_clr) begin
            instruction_count <= 3'b000;
        end else begin
            if (instruction_count == 3'b101) begin // Reset back to T0 after T5
                instruction_count <= 3'b000;
            end else begin
                instruction_count <= instruction_count + 1'b1;
            end
        end
    end

    //OP Codes
    localparam LDA = 4'b0001; // Load RAM location into Reg A
    localparam ADD = 4'b0010; // Add Reg B value to Reg A
    localparam SUB = 4'b0011; // Subtract Reg B value from Reg A
    localparam STA = 4'b0100; // Store Reg A value into RAM
    localparam LDIA = 4'b0101; // Load Immediate 4-bit value to Reg A
    localparam JMP = 4'b0110; // Unconditional Jump
    localparam JC  = 4'b0111; // Conditional Jump if Zero flag is 1
    localparam LDB = 4'b1000; //Load Ram location into reg B
    localparam STB = 4'b1001; //Store reg b value into RAM
    localparam LDIB = 4'b1010; //Load immediate 4-bit value into reg b
    localparam NOP5 = 4'b1011; //Availiable instruction
    localparam NOP6 = 4'b1100; //Availiable instruction
    localparam NOP7 = 4'b1101; //Availiable instruction
    localparam OUT = 4'b1110; // Copy Reg A value to Output Module
    localparam HLT = 4'b1111; // Halt CPU execution clock loop

    //Ctrl word
    localparam [18:0] IO  = 19'b100_000_000_000_000_000_0; // IR Out
    localparam [18:0] II  = 19'b010_000_000_000_000_000_0; // IR In
    localparam [18:0] OI  = 19'b001_000_000_000_000_000_0; // Output Module In
    localparam [18:0] J   = 19'b000_100_000_000_000_000_0; // PC Jump Latch
    localparam [18:0] CE  = 19'b000_010_000_000_000_000_0; // PC Count Enable
    localparam [18:0] CO  = 19'b000_001_000_000_000_000_0; // PC Out
    localparam [18:0] MI  = 19'b000_000_100_000_000_000_0; // MAR In
    localparam [18:0] AI  = 19'b000_000_010_000_000_000_0; // Reg A In
    localparam [18:0] AO  = 19'b000_000_001_000_000_000_0; // Reg A Out
    localparam [18:0] FI  = 19'b000_000_000_100_000_000_0; // Flags Register Latch In (Bit 9)
    localparam [18:0] EO  = 19'b000_000_000_010_000_000_0; // ALU Adder Out
    localparam [18:0] SU  = 19'b000_000_000_001_000_000_0; // ALU Subtraction Mode Assert
    localparam [18:0] BI  = 19'b000_000_000_000_001_000_0; // Reg B In
    localparam [18:0] BO  = 19'b000_000_000_000_000_100_0; // Reg B Out
    localparam [18:0] RI  = 19'b000_000_000_000_000_010_0; // RAM In
    localparam [18:0] RO  = 19'b000_000_000_000_000_001_0; // RAM Out
    localparam [18:0] HT  = 19'b000_000_000_000_000_000_1; // Halt System Clock

    localparam [18:0] NOP = 19'b000_000_000_000_000_000_0; // No operation

    wire [18:0] microcode_out;

    assign microcode_out = 
        //Fetch, common for all instructions
        (instruction_count == 3'b000) ? (CO | MI) :       // T0: Move PC to MAR
        (instruction_count == 3'b001) ? (RO | II | CE) :  // T1: Fetch RAM opcode to IR, increment PC

        //Instructions

        // LDA: Load value from designated address into register A
        ({i_instruction, instruction_count} == {LDA, 3'b010}) ? (IO | MI) : // T2: Push operand offset to MAR
        ({i_instruction, instruction_count} == {LDA, 3'b011}) ? (RO | AI) : // T3: Load memory byte into Reg A

             // LDB: Load value from designated address into register B
        ({i_instruction, instruction_count} == {LDB, 3'b010}) ? (IO | MI) : // T2: Push operand offset to MAR
        ({i_instruction, instruction_count} == {LDB, 3'b011}) ? (RO | BI) : // T3: Load memory byte into Reg A
        
        // ADD: Retrieve memory variable, add to Reg A, commit flags
        ({i_instruction, instruction_count} == {ADD, 3'b010}) ? (IO | MI) : // T2: Instruction register out, memory in
        ({i_instruction, instruction_count} == {ADD, 3'b011}) ? (RO | BI) : // T3: Ram out, b reg in
        ({i_instruction, instruction_count} == {ADD, 3'b100}) ? (EO | AI | FI) : // T4: Alu Out, A register in, Flags

        // SUB: Retrieve memory variable, subtract from Reg A, commit flags
        ({i_instruction, instruction_count} == {SUB, 3'b010}) ? (IO | MI) : // T2: Instruction register out, memory in
        ({i_instruction, instruction_count} == {SUB, 3'b011}) ? (RO | BI) : // T3: Ram out, b reg in
        ({i_instruction, instruction_count} == {SUB, 3'b100}) ? (SU | EO | AI | FI) : // T4: Subtract, Alu Out, A register in, Flags
        
        // STA: Write value in register A into a memory block location
        ({i_instruction, instruction_count} == {STA, 3'b010}) ? (IO | MI) : // T2: Target writing address to MAR
        ({i_instruction, instruction_count} == {STA, 3'b011}) ? (AO | RI) : // T3: Drive Reg A to RAM Input

            // STB: Write value in register A into a memory block location
        ({i_instruction, instruction_count} == {STB, 3'b010}) ? (IO | MI) : // T2: Target writing address to MAR
        ({i_instruction, instruction_count} == {STB, 3'b011}) ? (BO | RI) : // T3: Drive Reg A to RAM Input
        
        // LDIA: Load immediate to reg A (4 bits)
        ({i_instruction, instruction_count} == {LDIA, 3'b010}) ? (IO | AI) : // T2: Load immediate 4 bits directly into Reg A     

             // LDIB: Load immediate to reg B (4 bits)
        ({i_instruction, instruction_count} == {LDIB, 3'b010}) ? (IO | BI) : // T2: Load immediate 4 bits directly into Reg B 

        // JMP: Jump 
        ({i_instruction, instruction_count} == {JMP, 3'b010}) ? (IO | J)  : // T2: Drive lower 4 bits of IR directly to PC Jump latch
    
        // JZ: Jump if zero
        ({i_instruction, instruction_count, i_zf} == {JC, 3'b010, 1'b1}) ? (IO | J) : // T2 (True): Read destination from IR to JUMP
        ({i_instruction, instruction_count, i_zf} == {JC, 3'b010, 1'b0}) ? NOP :      // T2 (False): Ignore jump parameter step

        // OUT: Reg A to output register
        ({i_instruction, instruction_count} == {OUT, 3'b010}) ? (AO | OI) : // T2: Dump Reg A into the Digital Tube display
        
        // HLT: Disable clock
        ({i_instruction, instruction_count} == {HLT, 3'b010}) ? (HT) :      // T2: Throw Halt status to Clock module

        NOP; // Default

    assign o_control_word = microcode_out;

endmodule
`endif // CONTROL_LOGIC_V
