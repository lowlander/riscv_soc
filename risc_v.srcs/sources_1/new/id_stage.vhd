----------------------------------------------------------------------------------
--
-- Copyright (c) 2021 Erwin Rol <erwin@erwinrol.com>
--
-- SPDX-License-Identifier: MIT
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.riscv.all;

entity id_stage is
    port (
        if2_to_id_buf_i     : in  if2_to_id_buf_type;
        id_to_ex_buf_o      : out id_to_ex_buf_type;
        
        rd_i                : in  std_logic_vector(31 downto 0);
        rd_sel_i            : in  std_logic_vector( 4 downto 0);
        rd_we_i             : in  std_logic;
        
        flush_i             : in  std_logic;
        stall_i             : in  std_logic;
         
        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
end id_stage;

architecture behavioral of id_stage is
    constant BO_LOAD        : std_logic_vector(6 downto 0) := "0000011";
    constant BO_STORE       : std_logic_vector(6 downto 0) := "0100011";
    constant BO_MADD        : std_logic_vector(6 downto 0) := "1000011";
    constant BO_BRANCH      : std_logic_vector(6 downto 0) := "1100011";
    constant BO_LOAD_FP     : std_logic_vector(6 downto 0) := "0000111";
    constant BO_STORE_FP    : std_logic_vector(6 downto 0) := "0100111";
    constant BO_MSUB        : std_logic_vector(6 downto 0) := "1000111";
    constant BO_JALR        : std_logic_vector(6 downto 0) := "1100111";
    constant BO_CUSTOM_0    : std_logic_vector(6 downto 0) := "0001011";
    constant BO_CUSTOM_1    : std_logic_vector(6 downto 0) := "0101011";
    constant BO_NMSUB       : std_logic_vector(6 downto 0) := "1001011";
    constant BO_RESERVED_0  : std_logic_vector(6 downto 0) := "1101011";
    constant BO_MISC_MEM    : std_logic_vector(6 downto 0) := "0001111";
    constant BO_AMO         : std_logic_vector(6 downto 0) := "0101111";
    constant BO_NMADD       : std_logic_vector(6 downto 0) := "1001111";
    constant BO_JAL         : std_logic_vector(6 downto 0) := "1101111";
    constant BO_OP_IMM      : std_logic_vector(6 downto 0) := "0010011";
    constant BO_OP          : std_logic_vector(6 downto 0) := "0110011";
    constant BO_OP_FP       : std_logic_vector(6 downto 0) := "1010011";
    constant BO_SYSTEM      : std_logic_vector(6 downto 0) := "1110011";
    constant BO_AUIPC       : std_logic_vector(6 downto 0) := "0010111";
    constant BO_LUI         : std_logic_vector(6 downto 0) := "0110111";
    constant BO_RESERVED_1  : std_logic_vector(6 downto 0) := "1010111";
    constant BO_RESERVED_2  : std_logic_vector(6 downto 0) := "1110111";
    constant BO_OP_IMM_32   : std_logic_vector(6 downto 0) := "0011011";
    constant BO_OP_32       : std_logic_vector(6 downto 0) := "0111011";
    constant BO_CUSTOM_2    : std_logic_vector(6 downto 0) := "1011011";
    constant BO_CUSTOM_3    : std_logic_vector(6 downto 0) := "1111011";


    --
    --
    --
    component register_file is
    port ( 
        rs1_o       : out std_logic_vector(31 downto 0);
        rs2_o       : out std_logic_vector(31 downto 0);
        rd_i        : in  std_logic_vector(31 downto 0);
        rs1_sel_i   : in  std_logic_vector( 4 downto 0);
        rs2_sel_i   : in  std_logic_vector( 4 downto 0);
        rd_sel_i    : in  std_logic_vector( 4 downto 0);
        rd_we_i     : in  std_logic;
        clk_i       : in  std_logic;
        rst_i       : in  std_logic
    );
    end component;
    
    signal id_to_ex_buf         : id_to_ex_buf_type;
    signal next_id_to_ex_buf    : id_to_ex_buf_type;
    
    signal rs1                  : std_logic_vector(31 downto 0);
    signal rs2                  : std_logic_vector(31 downto 0);

    signal rs1_sel              : std_logic_vector(4 downto 0);
    signal rs2_sel              : std_logic_vector(4 downto 0);
begin

    register_file_inst : register_file port map (
        rs1_o       => rs1,
        rs2_o       => rs2,
        rd_i        => rd_i,
        rs1_sel_i   => rs1_sel,
        rs2_sel_i   => rs2_sel,
        rd_sel_i    => rd_sel_i,
        rd_we_i     => rd_we_i,
        clk_i       => clk_i,
        rst_i       => rst_i
    );

    decode : process (id_to_ex_buf, if2_to_id_buf_i, flush_i, rs1, rs2)
        constant zero           : std_logic_vector(31 downto 0) := (others => '0');

        variable instr          : std_logic_vector(31 downto 0);
        variable nop            : std_logic;
        variable base_opcode    : std_logic_vector(6 downto 0);
        variable funct3         : std_logic_vector(2 downto 0);
        variable funct7         : std_logic_vector(6 downto 0);
        variable sign           : std_logic_vector(31 downto 0);
        variable i_imm          : std_logic_vector(31 downto 0);
        variable s_imm          : std_logic_vector(31 downto 0);
        variable b_imm          : std_logic_vector(31 downto 0);
        variable u_imm          : std_logic_vector(31 downto 0);
        variable j_imm          : std_logic_vector(31 downto 0);
        variable shamt          : std_logic_vector(31 downto 0);

        variable v              : id_to_ex_buf_type;
    begin
        v := id_to_ex_buf;
    
        v.rs1 := rs1;
        v.rs2 := rs2;
        
        v.pc := if2_to_id_buf_i.pc; 
        v.pc4 := if2_to_id_buf_i.pc4;

        v.imm         := (others => '-');
        v.opcode      := OP_NOP;

        instr := if2_to_id_buf_i.instr;
        nop := if2_to_id_buf_i.nop;

        v.rs1_sel     := instr(19 downto 15);
        v.rs2_sel     := instr(24 downto 20);
        v.rd_sel      := instr(11 downto  7); 

        v.wb_ctrl     := WB_SEL_NONE;

        v.alu_opcode  := ALU_OP_NOP;
        v.alu_a_sel   := ALU_OP_A_RS1;
        v.alu_b_sel   := ALU_OP_B_RS2;

        v.mem_we         := "0000";

        base_opcode := instr( 6 downto  0);
        funct3      := instr(14 downto 12);
        funct7      := instr(31 downto 25);

        sign        := (others => instr(31));

        i_imm       := sign(31 downto 11) & instr(30 downto 20);
        s_imm       := sign(31 downto 11) & instr(30 downto 25) & instr(11 downto 7);
        b_imm       := sign(31 downto 12) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0';
        u_imm       := instr(31 downto 12) & "000000000000";
        j_imm       := sign(31 downto 20) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0';

        shamt       := zero(31 downto 5) & instr(24 downto 20);
    
        case base_opcode is
            
        when BO_LUI     => v.opcode := OP_LUI;    v.alu_opcode := ALU_OP_PASS_B; v.imm := u_imm; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_b_sel := ALU_OP_B_IMM; v.rs1_sel := "00000"; v.rs2_sel := "00000";
        when BO_AUIPC   => v.opcode := OP_AUIPC;  v.alu_opcode := ALU_OP_ADDM; v.imm := u_imm; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM; v.rs1_sel := "00000"; v.rs2_sel := "00000";                        
        when BO_JAL     => v.opcode := OP_JAL;    v.alu_opcode := ALU_OP_ADDM; v.imm := j_imm; v.wb_ctrl := WB_SEL_PC4; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM; v.rs1_sel := "00000"; v.rs2_sel := "00000";
        
        when BO_JALR    =>  
            case funct3 is
                when "000"  => v.opcode := OP_JALR; v.alu_opcode := ALU_OP_ADDM; v.imm := i_imm; v.wb_ctrl := WB_SEL_PC4; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM; v.rs2_sel := "00000";
                when others => null;
            end case;

        when BO_BRANCH =>
            case funct3 is
                when "000" => v.opcode := OP_BEQ;     v.alu_opcode := ALU_OP_ADDM; v.imm := b_imm; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM;
                when "001" => v.opcode := OP_BNE;     v.alu_opcode := ALU_OP_ADDM; v.imm := b_imm; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM;
                when "100" => v.opcode := OP_BLT;     v.alu_opcode := ALU_OP_ADDM; v.imm := b_imm; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM;
                when "101" => v.opcode := OP_BGE;     v.alu_opcode := ALU_OP_ADDM; v.imm := b_imm; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM;
                when "110" => v.opcode := OP_BLTU;    v.alu_opcode := ALU_OP_ADDM; v.imm := b_imm; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM;
                when "111" => v.opcode := OP_BGEU;    v.alu_opcode := ALU_OP_ADDM; v.imm := b_imm; v.alu_a_sel := ALU_OP_A_PC; v.alu_b_sel := ALU_OP_B_IMM;
                when others => null;
            end case;

        when BO_LOAD =>
            case funct3 is
                when "000" => v.opcode := OP_LB;  v.alu_opcode := ALU_OP_ADD; v.imm := i_imm; v.wb_ctrl := WB_SEL_MEM; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2; v.rs2_sel := "00000";
                when "001" => v.opcode := OP_LH;  v.alu_opcode := ALU_OP_ADD; v.imm := i_imm; v.wb_ctrl := WB_SEL_MEM; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2; v.rs2_sel := "00000";
                when "010" => v.opcode := OP_LW;  v.alu_opcode := ALU_OP_ADD; v.imm := i_imm; v.wb_ctrl := WB_SEL_MEM; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2; v.rs2_sel := "00000";
                when "100" => v.opcode := OP_LBU; v.alu_opcode := ALU_OP_ADD; v.imm := i_imm; v.wb_ctrl := WB_SEL_MEM; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2; v.rs2_sel := "00000";
                when "101" => v.opcode := OP_LHU; v.alu_opcode := ALU_OP_ADD; v.imm := i_imm; v.wb_ctrl := WB_SEL_MEM; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2; v.rs2_sel := "00000";
                when others => null;
            end case;
            
        when BO_STORE =>
            case funct3 is
                when "000" => v.opcode := OP_SB; v.alu_opcode := ALU_OP_ADD; v.imm := s_imm; v.mem_we := "0001"; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;
                when "001" => v.opcode := OP_SH; v.alu_opcode := ALU_OP_ADD; v.imm := s_imm; v.mem_we := "0011"; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;
                when "010" => v.opcode := OP_SW; v.alu_opcode := ALU_OP_ADD; v.imm := s_imm; v.mem_we := "1111"; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;
                when others => null;
            end case;

        when BO_OP_IMM =>
            case funct3 is
                when "000" => v.opcode := OP_ADDI;  v.alu_opcode := ALU_OP_ADD; v.imm := i_imm;v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM; v.rs2_sel := "00000";
                when "010" => v.opcode := OP_SLTI;  v.alu_opcode := ALU_OP_SLT; v.imm := i_imm; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;v.rs2_sel := "00000";
                when "011" => v.opcode := OP_SLTIU; v.alu_opcode := ALU_OP_SLTU; v.imm := i_imm;v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;v.rs2_sel := "00000";
                when "100" => v.opcode := OP_XORI;  v.alu_opcode := ALU_OP_XOR; v.imm := i_imm; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;v.rs2_sel := "00000";
                when "110" => v.opcode := OP_ORI;   v.alu_opcode := ALU_OP_OR; v.imm := i_imm; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;v.rs2_sel := "00000";
                when "111" => v.opcode := OP_ANDI;  v.alu_opcode := ALU_OP_AND; v.imm := i_imm; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;v.rs2_sel := "00000";
                
                when "001" => 
                    case funct7 is
                        when "0000000" => v.opcode := OP_SLLI; v.alu_opcode := ALU_OP_SLL; v.imm := shamt; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM; v.rs2_sel := "00000";
                        when others => null;
                    end case;

                when "101" => 
                    case funct7 is
                        when "0000000" => v.opcode := OP_SRLI; v.alu_opcode := ALU_OP_SRL; v.imm := shamt;v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM; v.rs2_sel := "00000";
                        when "0100000" => v.opcode := OP_SRAI; v.alu_opcode := ALU_OP_SRA; v.imm := shamt; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_IMM;v.rs2_sel := "00000";
                        when others => null;
                     end case;
                    
                when others => null;
            end case;

       when BO_OP =>
            case funct3 is
                when "000" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_ADD; v.alu_opcode := ALU_OP_ADD; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0100000" => v.opcode := OP_SUB; v.alu_opcode := ALU_OP_SUB; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_MUL; v.alu_opcode := ALU_OP_MUL; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;
                    
                when "001" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_SLL; v.alu_opcode := ALU_OP_SLL; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_MULH; v.alu_opcode := ALU_OP_MULH; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;
                    
                when "010" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_SLT; v.alu_opcode := ALU_OP_SLT; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_MULHSU; v.alu_opcode := ALU_OP_MULHSU;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;
                    
                when "011" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_SLTU; v.alu_opcode := ALU_OP_SLTU; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_MULHU; v.alu_opcode := ALU_OP_MULHU;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;
                    
                when "100" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_XOR; v.alu_opcode := ALU_OP_XOR; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_DIV; v.alu_opcode := ALU_OP_DIV; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;

                when "101" => 
                    case funct7 is
                        when "0000000" => v.opcode := OP_SRL; v.alu_opcode := ALU_OP_SRL; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0100000" => v.opcode := OP_SRA; v.alu_opcode := ALU_OP_SRA;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_DIVU; v.alu_opcode := ALU_OP_DIVU;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;
                    
                when "110" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_OR; v.alu_opcode := ALU_OP_OR; v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_REM; v.alu_opcode := ALU_OP_REM;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;

                when "111" =>
                    case funct7 is
                        when "0000000" => v.opcode := OP_AND; v.alu_opcode := ALU_OP_AND;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when "0000001" => v.opcode := OP_REMU; v.alu_opcode := ALU_OP_REMU;  v.wb_ctrl := WB_SEL_ALU_RES; v.alu_a_sel := ALU_OP_A_RS1; v.alu_b_sel := ALU_OP_B_RS2;
                        when others => null;
                    end case;

                when others => null;

            end case;

        when BO_SYSTEM =>
            case instr(31 downto 7) is
                when "0000000000000000000000000" => v.opcode := OP_ECALL; v.rs1_sel := "00000"; v.rs2_sel := "00000";
                when "0000000000010000000000000" => v.opcode := OP_EBREAK; v.rs1_sel := "00000"; v.rs2_sel := "00000";
                when others => null;
            end case;

        when BO_MISC_MEM =>
            case funct3 is
                when "000" => v.opcode := OP_FENCE; v.rs1_sel := "00000"; v.rs2_sel := "00000"; --TODO
                when others => null;
            end case;
        
        when BO_LOAD_FP =>
            null;
        
        when BO_STORE_FP =>
            null;

        when BO_MADD =>
            null;
        
        when BO_MSUB =>
            null;
            
        when BO_NMADD =>
            null;

        when BO_NMSUB =>
            null;
                            
            
        when BO_AMO =>
            null;
                        
        when BO_OP_IMM_32 =>
            null;
         
        when BO_OP_32 =>
            null;

        when BO_OP_FP =>
            null;
                    
        when BO_RESERVED_0 =>
            null;
        
        when BO_RESERVED_1 =>
            null;
            
        when BO_RESERVED_2 =>
            null;
            
        when BO_CUSTOM_0 =>
            null;
        
        when BO_CUSTOM_1 =>
            null;

        when BO_CUSTOM_2 =>
            null;
        
        when BO_CUSTOM_3 =>
            null;
        
        when others =>
            null;

        end case;
         
        v.nop := nop or flush_i;         

        if (flush_i = '1' or nop = '1') then
            v.opcode := OP_NOP;
            v.alu_opcode := ALU_OP_NOP;
            v.wb_ctrl     := WB_SEL_NONE;
            v.rd_sel := "00000";
            v.mem_we := "0000";
        end if;

        -- never write back to X0
        if (v.rd_sel = "00000") then
            v.wb_ctrl     := WB_SEL_NONE;
        end if;

        rs1_sel <= v.rs1_sel;
        rs2_sel <= v.rs2_sel;

        next_id_to_ex_buf <= v;
    end process;


    process(clk_i, rst_i, next_id_to_ex_buf)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                id_to_ex_buf <= reset_id_to_ex_buf;
            else
                id_to_ex_buf <= next_id_to_ex_buf;         
            end if;    
        end if;
    end process;

    id_to_ex_buf_o <= id_to_ex_buf;
    
end behavioral;
