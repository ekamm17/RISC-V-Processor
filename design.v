module InstructionMemory (clk, rst, read_address, instruction);
    input clk,rst;
    input [31:0]read_address;
    output [31:0]instruction;

    parameter INST_MEMORY_SIZE = 64;
    reg [31:0] instruction_memory [INST_MEMORY_SIZE-1:0];
    assign instruction = instruction_memory[read_address];

    //integer i;
    integer i;
    always @(posedge clk)
    begin
        if (rst)
        begin
            for (i=0; i<INST_MEMORY_SIZE; i=i+1)
        instruction_memory[i] = 32'b0;
        end
    end
endmodule

module ProgramCounter (clk, rst, PC_in, PC_out);
    input clk, rst;
    input [31:0] PC_in;
    output reg [31:0] PC_out;

    always @ (posedge clk)
    begin
        if (rst) PC_out <= 32'b0;
        else PC_out <= PC_in;
    end
endmodule

module PCAdder (adder_in, adder_out);
    input [31:0] adder_in;
    output [31:0] adder_out;

    assign adder_out = adder_in + 32'b100;
endmodule

module Registers (clk, rst, RegWrite, read_reg1, read_reg2, write_reg, write_data, read_data1, read_data2);
    input clk, rst, RegWrite;
    input [4:0] read_reg1, read_reg2, write_reg;
    input [31:0] write_data;
    output [31:0] read_data1, read_data2;
    
    parameter data_reg_number = 32;
    reg [31:0] data_registers [data_reg_number-1:0];

    integer i;
    always @(posedge clk)
    begin
        if (rst)
        begin
            for (i=0; i<data_reg_number; i=i+1)
                data_registers[i] = 32'b0;
        end

        else if (RegWrite) data_registers[write_reg] = write_data;
    end

    assign read_data1 = data_registers[read_reg1];
    assign read_data2 = data_registers[read_reg2];
endmodule

module SignExtend16To32 (input_16bit,output_32bit);
    input [15:0] input_16bit;
    output [31:0] output_32bi;

    assign output_32bit = {{16{input_16bit[15]}}, input_16bit};
endmodule

module MainControlUnit(opcode, RegDst, Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
    input [5:0] opcode;
    output reg RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    output reg [1:0] ALUOp;
    always @(*)
    begin
        case (opcode)
            6'b000000: //R-type
            begin RegDst <= 1; Branch <= 0; MemRead <= 0; MemtoReg <= 0; ALUOp <= 2'b10; MemWrite <= 0; ALUSrc <=0; RegWrite <=1; end

            6'b100011: //lw
            begin RegDst <= 0; Branch <= 0; MemRead <= 1; MemtoReg <= 1; ALUOp <= 2'b00; MemWrite <= 0; ALUSrc <=1; RegWrite <=1; end

            6'b101011: //sw
            begin RegDst <= 0; Branch <= 0; MemRead <= 0; MemtoReg <= 0; ALUOp <= 2'b00; MemWrite <= 1; ALUSrc <=1; RegWrite <=0; end

            6'b000100: //beq
            begin RegDst <= 0; Branch <= 1; MemRead <= 0; MemtoReg <= 0; ALUOp <= 2'b01; MemWrite <= 0; ALUSrc <=0; RegWrite <=0; end

            default:
            begin RegDst <= 1; Branch <= 0; MemRead <= 0; MemtoReg <= 0; ALUOp <= 2'b10; MemWrite <= 0; ALUSrc <=0; RegWrite <=1; end
        endcase
    end
endmodule

module ALUControlUnit(ALUOp,func,ALU_control);
    input [1:0] ALUOp;
    input [5:0] func;
    output [3:0] ALU_control;
    always @(*)
    begin
        if (ALUOp == 2'b00) ALU_control <= 4'b0010;
        else if (ALUOp == 2'b01) ALU_control <= 4'b0110;
        else if ((ALUOp == 2'b10) && (func == 6'b100000)) ALU_control <= 4'b0010;
        else if ((ALUOp == 2'b10) && (func == 6'b100010)) ALU_control <= 4'b0110;
        else if ((ALUOp == 2'b10) && (func == 6'b100100)) ALU_control <= 4'b0000;
        else if ((ALUOp == 2'b10) && (func == 6'b100101)) ALU_control <= 4'b0001;
        else if ((ALUOp == 2'b10) && (func == 6'b101010)) ALU_control <= 4'b0111;
        else ALU_control <= 4'b0010;
    end
endmodule

module ALU(ALU_in1, ALU_in2, ALU_control, ALU_out, zero);
    input [31:0] ALU_in1, ALU_in2;
    input [3:0] ALU_control;
    output reg [31:0] ALU_out;
    output reg zero;

    always @ (ALU_control or ALU_in1 or ALU_in2)
    begin
        case (ALU_control)
        4'b0010:
        begin 
            zero <= 0; 
            ALU_out <= ALU_in1 + ALU_in2;
        end

        4'b0110: 
        begin
            if(ALU_in1 == ALU_in2) zero <= 1; 
            else zero <= 0;
            ALU_out <= ALU_in1 - ALU_in2; 
        end

        4'b0000: 
        begin 
            zero <= 0; 
            ALU_out <= ALU_in1 & ALU_in2; 
        end

        4'b0001: 
        begin 
            zero <= 0; 
            ALU_out <= ALU_in1 | ALU_in2; 
        end

        4'b0111: 
        begin
            zero <= 0; 
            if (ALU_in1 < ALU_in2) ALU_out <= 4'b1;
            else ALU_out <= 4'b0;
        end

        default: 
        begin 
            zero<=0;
            ALU_out <= ALU_in1; 
        end
        endcase
    end
endmodule

module DataMemory (clk, rst, MemWrite, MemRead, address, write_data, read_data);
    input clk, rst, MemWrite, MemRead;
    input [31:0] address, write_data;
    output [31:0] read_data;

    parameter DATA_MEMORY_SIZE = 64;
    reg [31:0] data_memory [INST_MEMORY_SIZE-1:0];

    if (MemRead) begin assign read_data = data_memory[address]; end
    else begin assign read_data = 32'b0; end

    integer i;
    always @(posedge clk)
    begin
        if (rst)
        begin
            for (i=0; i < DATA_MEMORY_SIZE; i=i+1)
            data_memory[i] <= 32'b0;
        end

        else if (MemWrite)
        begin
            data_memory[address] <= write_data;
        end
    end
endmodule

module Mux2to1 (I0,I1,sel,Y);
    input [31:0] I0,I1;
    input sel;
    output [31:0] Y;
    if (sel == 1'b1)
        assign Y = I1;
    else
        assign Y = I0;
endmodule

module adder_32bit(in1, in2, out);
input [31:0] in1, in2;
output [31:0] out;
assign out = in1 + in2;
endmodule

module RISC_Processor (clk,rst);
input clk,rst;
wire [31:0] PC_out, PC_plus_4, PC_in, instruction, write_reg, reg_write_data, reg_read_data1, reg_read_data2, sign_extended_instr, ALU_in2, ALU_out, mem_read_data, add_result;
wire RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite, ALU_zero, zero_and_branch;
wire [1:0] AluOp;
wire [3:0] ALU_control;

ProgramCounter PC(.clk(clk), .rst(rst), .PC_in(PC_in), .PC_out(PC_out));
PCAdder  PCA(.adder_in(PC_out), .adder_out(PC_plus_4));
InstructionMemory IM(.clk(clk), .rst(rst), .read_address(PC_out), .instruction(instruction));
Mux2to1 m1(.I0(instruction[20:16]), .I1(instruction[15:11]), .sel(RegDst), .Y(write_reg));
Registers r1(.clk(clk), .rst(rst), .RegWrite(RegWrite), .read_reg1(instruction[25:21]), .read_reg2(instruction[20:16]), .write_reg(write_reg), .write_data(reg_write_data), .read_data1(reg_read_data1), .read_data2(reg_read_data2));
MainControlUnit MCU(.opcode(instruction[31:26]), .RegDst(RegDst), .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemRead), .ALUOp(ALUOp), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite));
Mux2to1 m2(.I0(reg_read_data2), .I1(sign_extended_instr), .sel(ALUSrc), .Y(ALU_in2));
ALU alu(.ALU_in1(reg_read_data1), .ALU_in2(ALU_in2), .ALU_control(ALU_control), .ALU_out(ALU_out), .zero(ALU_zero));
SignExtend16To32 SE(.input_16bit(instruction[15:0]), .output_32bit(sign_extended_instr));
ALUControlUnit ACU(.ALUOp(ALUOp), .func(instruction[5:0]), .ALU_control(ALU_control));
DataMemory DM(.clk(clk), .rst(rst), .MemWrite(MemWrite), .MemRead(MemRead), .address(ALU_out), .write_data(reg_read_data2), .read_data(mem_read_data));
Mux2to1 m3(.I0(ALU_out), .I1(mem_read_data), .sel(MemtoReg), .Y(reg_write_data));
and a1(zero_and_branch, ALU_zero, Branch);
adder_32bit ad(.in1(PC_plus_4), .in2((sign_extended_instr<<2)), .out(add_result));
Mux2to1 m4(.I0(PC_plus_4), .I1(add_result), .sel(zero_and_branch), .Y(PC_in));
endmodule