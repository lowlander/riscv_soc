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

entity ex_stage is
    port ( 
        id_to_ex_buf_i      : in  id_to_ex_buf_type;
        ex_to_me1_buf_o     : out ex_to_me1_buf_type;

        branch_adr_o        : out std_logic_vector(31 downto 0);
        do_branch_o         : out std_logic; 

        rs1_fwd_i           : in  std_logic_vector(31 downto 0);
        rs1_use_fwd_i       : in  std_logic;

        rs2_fwd_i           : in  std_logic_vector(31 downto 0);
        rs2_use_fwd_i       : in  std_logic;

        stall_i             : in  std_logic;
          
        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
end ex_stage;

architecture behavioral of ex_stage is
    --
    --
    --
    component alu is
    port ( 
        a       : in    STD_LOGIC_VECTOR (31 downto 0);
        b       : in    STD_LOGIC_VECTOR (31 downto 0);
        r       : out   STD_LOGIC_VECTOR (31 downto 0);
        opcode  : in    alu_op_type
    );
    end component;
    
    component branch_detect is
    port (
        rs1         : in  std_logic_vector(31 downto 0);
        rs2         : in  std_logic_vector(31 downto 0);
        opcode      : in  opcode_type;
        do_branch   : out std_logic
    );
    end component;
    
    signal alu_op_a : std_logic_vector(31 downto 0);
    signal alu_op_b : std_logic_vector(31 downto 0);

    signal ex_to_me1_buf        : ex_to_me1_buf_type;
    signal next_ex_to_me1_buf   : ex_to_me1_buf_type;

    signal alu_res      : std_logic_vector(31 downto 0);
    signal do_branch    : std_logic;
   
    signal rs1 : std_logic_vector(31 downto 0);
    signal rs2 : std_logic_vector(31 downto 0);
begin
    rs1 <= rs1_fwd_i when rs1_use_fwd_i = '1' else id_to_ex_buf_i.rs1;
    rs2 <= rs2_fwd_i when rs2_use_fwd_i = '1' else id_to_ex_buf_i.rs2;

    process(id_to_ex_buf_i, rs1)
    begin
        case id_to_ex_buf_i.alu_a_sel is
        when ALU_OP_A_RS1 => alu_op_a <= rs1;
        when ALU_OP_A_PC => alu_op_a <= id_to_ex_buf_i.pc;
        when others => alu_op_a <= (others => '-');
        end case;
    end process;

    process(id_to_ex_buf_i, rs2)
    begin
        case id_to_ex_buf_i.alu_b_sel is
        when ALU_OP_B_RS2 => alu_op_b <= rs2;
        when ALU_OP_B_IMM => alu_op_b <= id_to_ex_buf_i.imm;
        when others => alu_op_b <= (others => '-');
        end case;
    end process;

    alu_inst : alu port map (
        a => alu_op_a,
        b => alu_op_b,
        r => alu_res,
        opcode => id_to_ex_buf_i.alu_opcode
    );
    
    branch_detect_inst : branch_detect port map (
        rs1 => rs1,
        rs2 => rs2,
        opcode => id_to_ex_buf_i.opcode,
        do_branch => do_branch
    );

    process(clk_i, rst_i, next_ex_to_me1_buf)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                ex_to_me1_buf <= reset_ex_to_me1_buf;         
            else
                ex_to_me1_buf <= next_ex_to_me1_buf;         
            end if;    
        end if;    
    end process;
    
    process(ex_to_me1_buf, id_to_ex_buf_i, alu_res, rs2)
        variable v : ex_to_me1_buf_type;
    begin
        v := ex_to_me1_buf;
        
        v.nop := id_to_ex_buf_i.nop;
  
        if (v.nop = '1') then
            v.pc := (others => '-');
            v.pc4 := (others => '-');
            v.alu_res := (others => '-');
            v.rd_sel := "00000";
            v.wb_ctrl     := WB_SEL_NONE;
            v.mem_we := "0000";
            v.mem_dat := (others => '-');        
       else
            v.pc := id_to_ex_buf_i.pc;
            v.pc4 := id_to_ex_buf_i.pc4;
            v.alu_res := alu_res;
            v.rd_sel := id_to_ex_buf_i.rd_sel;
            v.mem_we := id_to_ex_buf_i.mem_we;
            v.mem_dat := rs2;
            v.wb_ctrl := id_to_ex_buf_i.wb_ctrl;
        end if;

        next_ex_to_me1_buf <= v;
    end process;

    do_branch_o <= do_branch and not id_to_ex_buf_i.nop;
    branch_adr_o <= alu_res;

    ex_to_me1_buf_o <= ex_to_me1_buf;
end behavioral;
