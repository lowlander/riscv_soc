----------------------------------------------------------------------------------
--
-- Copyright (c) 2021 Erwin Rol <erwin@erwinrol.com>
--
-- SPDX-License-Identifier: MIT
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package riscv is

type alu_op_type is (
    ALU_OP_NOP,
    ALU_OP_PASS_A,
    ALU_OP_PASS_B,
    ALU_OP_ADDM,
    ALU_OP_ADD,
    ALU_OP_SUB,
    ALU_OP_SLT,
    ALU_OP_SLTU,
    ALU_OP_AND,
    ALU_OP_OR,
    ALU_OP_XOR,
    ALU_OP_SLL,
    ALU_OP_SRL,
    ALU_OP_SRA,
    ALU_OP_MUL,
    ALU_OP_MULH,
    ALU_OP_MULHSU, 
    ALU_OP_MULHU,
    ALU_OP_DIV,
    ALU_OP_DIVU,
    ALU_OP_REM, 
    ALU_OP_REMU
);

type alu_op_a_type is (
    ALU_OP_A_RS1,
    ALU_OP_A_PC
);

type alu_op_b_type is (
    ALU_OP_B_RS2,
    ALU_OP_B_IMM
);

type wb_sel_type is (
    WB_SEL_NONE,
    WB_SEL_PC4,
    WB_SEL_MEM,
    WB_SEL_ALU_RES
);

type opcode_type is (
    -- RV32I opcodes
    OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, 
    OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU, 
    OP_LB, OP_LH, OP_LW, OP_LBU, OP_LHU,
    OP_SB, OP_SH, OP_SW,
    OP_ADDI, OP_SLTI, OP_SLTIU, OP_XORI, OP_ORI, OP_ANDI, 
    OP_SLLI, OP_SRLI, OP_SRAI,
    OP_ADD, OP_SUB, OP_SLL, OP_SLT, OP_SLTU, OP_XOR, OP_SRL, OP_SRA, OP_OR, OP_AND,
    OP_FENCE,
    OP_ECALL, OP_EBREAK,
    -- RV64I opcodes
    ---OP_LWU, OP_LD,
    ---OP_SD,
    --OP_SLLI, OP_SRLI, OP_SRAI,
    ---OP_ADDIW,
    ---OP_SLLIW, OP_SRLIW, OP_SRAIW,
    ---OP_ADDW, OP_SUBW, OP_SLLW, OP_SRLW, OP_SRAW,
    -- RV32/RV64 Zifencei
    --OP_FENCE_I,
    -- RV32/RV64 Zicsr
    --OP_CSRRW, OP_CSRRS, OP_CSRRC, OP_CSRRWI, OP_CSRRSI, OP_CSRRCI,
    -- RV32M
    OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU,
    OP_DIV, OP_DIVU,
    OP_REM, OP_REMU,
    -- RV64M
    --OP_MULW,
    --OP_DIVW, OP_DIVUW,
    --OP_REMW, OP_REMUW,
    -- RV32A
    --OP_LR_W, OP_SC_W,
    --OP_AMOSWAP_W, OP_AMOADD_W, OP_AMOXOR_W, OP_AMOAND_W, OP_AMOOR_W, 
    --OP_AMOMIN_W, OP_AMOMAX_W, OP_AMOMINU_W, OP_AMOMAXU_W,
    -- RV64A
    --OP_LR_D, OP_SC_D,
    --OP_AMOSWAP_D, OP_AMOADD_D, OP_AMOXOR_D, OP_AMOAND_D, OP_AMOOR_D, 
    --OP_AMOMIN_D, OP_AMOMAX_D, OP_AMOMINU_D, OP_AMOMAXU_D,
    -- RV32F
    --OP_FLW, OP_FSW,
    --OP_FMADD_S, OP_FMSUB_S, 
    --OP_FNMSUB_S, OP_FNMADD_S, 
    --OP_FADD_S, OP_FSUB_S, OP_FMUL_S, OP_FDIV_S,
    --OP_FSQRT_S, OP_FSGNJ_S, OP_FSGNJN_S, OP_FSGNJX_S,
    --OP_FMIN_S, OP_FMAX_S,
    --OP_FCVT_W_S, OP_FCVT_WU_S,
    --OP_FMV_X_W,
    --OP_FEQ_S, OP_FLT_S, OP_FLE_S,
    --OP_FCLASS_S, OP_FCVT_S_W, OP_FCVT_S_WU,
    --OP_FMV_W_X,
    -- RV64F
    --OP_FCVT_L_S, OP_FCVT_LU_S, OP_FCVT_S_L, OP_FCVT_S_LU,
    -- RV32D
    --OP_FLD, OP_FSD,
    --OP_FMADD_D, OP_FMSUB_D,
    --OP_FNMSUB_D, OP_FNMADD_D, 
    --OP_FADD_D, OP_FSUB_D, OP_FMUL_D, OP_FDIV_D,
    --OP_FSQRT_D, OP_FSGNJ_D, OP_FSGNJN_D, OP_FSGNJX_D,
    --OP_FMIN_D, OP_FMAX_D,
    --OP_FCVT_S_D, OP_FCVT_D_S,
    --OP_FEQ_D, OP_FLT_D, OP_FLE_D,
    --OP_FCLASS_D, OP_FCVT_W_D, OP_FCVT_WU_D, OP_FCVT_D_W, OP_FCVT_D_WU,
    -- RV64D
    --OP_FCVT_L_D, OP_FCVT_LU_D,
   -- OP_FMV_X_D,
    --OP_FCVT_D_L, OP_FCVT_D_LU,
    --OP_FMV_D_X,
    -- RV32Q
    --OP_FLQ, OP_FSQ,
    --OP_FMADD_Q, OP_FMSUB_Q, 
    --OP_FNMSUB_Q, OP_FNMADD_Q, 
    --OP_FADD_Q, OP_FSUB_Q, OP_FMUL_Q, OP_FDIV_Q,
    --OP_FSQRT_Q, OP_FSGNJ_Q, OP_FSGNJN_Q, OP_FSGNJX_Q,
    --OP_FMIN_Q, OP_FMAX_Q,
    --OP_FCVT_S_Q, OP_FCVT_Q_S,
    --OP_FCVT_D_Q, OP_FCVT_Q_D,
    --OP_FEQ_Q, OP_FLT_Q, OP_FLE_Q,
    --OP_FCLASS_Q, OP_FCVT_W_Q, OP_FCVT_WU_Q, OP_FCVT_Q_W, OP_FCVT_Q_WU,
    -- RV64Q
    --OP_FCVT_L_Q, OP_FCVT_LU_Q, OP_FCVT_Q_L, OP_FCVT_Q_LU 
    OP_NOP
);

--
--
--
type if1_to_if2_buf_type is record
    pc      : std_logic_vector(31 downto 0);
    pc4     : std_logic_vector(31 downto 0);
    nop     : std_logic;
end record;

constant reset_if1_to_if2_buf : if1_to_if2_buf_type := (
    (others => '-'),    -- pc
    (others => '-'),    -- pc4
    '1'                 -- nop
);

--
--
--
type if2_to_id_buf_type is record
    pc      : std_logic_vector(31 downto 0);    
    pc4     : std_logic_vector(31 downto 0);    
    instr   : std_logic_vector(31 downto 0);    
    nop     : std_logic;
end record;

constant NOP_INSTR : std_logic_vector(31 downto 0) := X"00000013"; 

constant reset_if2_to_id_buf : if2_to_id_buf_type := (
    (others => '-'),    -- pc
    (others => '-'),    -- pc4
    NOP_INSTR,          -- instr / nop instr
    '1'                 -- nop
);

--
--
--
type id_to_ex_buf_type is record
    pc          : std_logic_vector(31 downto 0);    
    pc4         : std_logic_vector(31 downto 0);    
    nop         : std_logic;
    opcode      : opcode_type;

    alu_opcode  : alu_op_type;
    alu_a_sel   : alu_op_a_type;
    alu_b_sel   : alu_op_b_type;

    rs1         : std_logic_vector(31 downto 0);
    rs2         : std_logic_vector(31 downto 0);
    imm         : std_logic_vector(31 downto 0);
            
    rs1_sel     : std_logic_vector( 4 downto 0);
    rs2_sel     : std_logic_vector( 4 downto 0);
    rd_sel      : std_logic_vector( 4 downto 0);    

    mem_we      : std_logic_vector(3 downto 0);

    wb_ctrl     : wb_sel_type;  
end record;

constant reset_id_to_ex_buf : id_to_ex_buf_type := (
    (others => '-'),    -- pc
    (others => '-'),    -- pc4
    '1',                -- nop
    OP_NOP,             -- opcode
    ALU_OP_NOP,         -- alu_opcode
    ALU_OP_A_RS1,       -- alu_a_sel
    ALU_OP_B_RS2,       -- alu_b_sel
    (others => '-'),    -- rs1
    (others => '-'),    -- rs2
    (others => '-'),    -- imm
    (others => '-'),    -- rs1_sel
    (others => '-'),    -- rs2_sel
    (others => '0'),    -- rd_sel    
    (others => '0'),    -- mem_we
    WB_SEL_NONE         -- wb_ctrl  
);

--
--
--
type ex_to_me1_buf_type is record
    pc          : std_logic_vector(31 downto 0);    
    pc4         : std_logic_vector(31 downto 0);    
    nop         : std_logic;
    wb_ctrl     : wb_sel_type;
    alu_res     : std_logic_vector(31 downto 0);
    rd_sel      : std_logic_vector(4 downto 0);
    mem_we      : std_logic_vector(3 downto 0);
    mem_dat     : std_logic_vector(31 downto 0);
end record;

constant reset_ex_to_me1_buf : ex_to_me1_buf_type := (
    (others => '-'),    -- pc    
    (others => '-'),    -- pc4    
    '1',                -- nop
    WB_SEL_NONE,        -- wb_ctrl
    (others => '-'),    -- alu_res
    (others => '0'),    -- rd_sel
    (others => '0'),    -- mem_we
    (others => '-')     -- mem_dat
);


--
--
--
type me1_to_me2_buf_type is record
    pc : std_logic_vector(31 downto 0);    
    pc4 : std_logic_vector(31 downto 0);    
    nop : std_logic;
    wb_ctrl : wb_sel_type;
    alu_res : std_logic_vector(31 downto 0);
    rd_sel : std_logic_vector(4 downto 0);    
end record;

constant reset_me1_to_me2_buf : me1_to_me2_buf_type := (
    (others => '-'),    -- pc    
    (others => '-'),    -- pc4    
    '1',                -- nop
    WB_SEL_NONE,        -- wb_ctrl
    (others => '-'),    -- alu_res
    (others => '0')     -- rd_sel
);

--
--
--
type me2_to_wb_buf_type is record
    pc      : std_logic_vector(31 downto 0);    
    pc4     : std_logic_vector(31 downto 0);    
    nop     : std_logic;
    wb_ctrl : wb_sel_type;
    alu_res : std_logic_vector(31 downto 0); 
    rd_sel  : std_logic_vector(4 downto 0);
    mem     : std_logic_vector(31 downto 0);     
end record;

constant reset_me2_to_wb_buf : me2_to_wb_buf_type := (
    (others => '-'),    -- pc    
    (others => '-'),    -- pc4    
    '1',                -- nop
    WB_SEL_NONE,        -- wb_ctrl
    (others => '-'),    -- alu_res
    (others => '0'),    -- rd_sel
    (others => '-')     -- mem
);

end package riscv;
