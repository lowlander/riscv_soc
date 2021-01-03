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

entity hart is
    port ( 
        dbus_adr_o      : out std_logic_vector(31 downto 0);
        dbus_dat_i      : in  std_logic_vector(31 downto 0);
        dbus_dat_o      : out std_logic_vector(31 downto 0);
        dbus_we_o       : out std_logic_vector(3 downto 0);
        dbus_stall_i    : in  std_logic;
               
        ibus_adr_o      : out std_logic_vector(31 downto 0);
        ibus_dat_i      : in  std_logic_vector(31 downto 0);
        ibus_stall_i    : in  std_logic;

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
end hart;

architecture behavioral of hart is
    --
    --
    --
    component forward_unit is
    port ( 
        me1_rd_i            : in  std_logic_vector(31 downto 0);
        me1_rd_sel_i        : in  std_logic_vector(4 downto 0);

        me2_rd_i            : in  std_logic_vector(31 downto 0);
        me2_rd_sel_i        : in  std_logic_vector(4 downto 0);

        wb_rd_i             : in  std_logic_vector(31 downto 0);
        wb_rd_sel_i         : in  std_logic_vector(4 downto 0);
        
        ex_rs1_sel_i        : in  std_logic_vector(4 downto 0);
        ex_rs2_sel_i        : in  std_logic_vector(4 downto 0);

        rs1_fwd_o           : out std_logic_vector(31 downto 0);
        rs1_use_fwd_o       : out std_logic;

        rs2_fwd_o           : out std_logic_vector(31 downto 0);
        rs2_use_fwd_o       : out std_logic;

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;

    --
    --
    --
    component if1_stage
    port (
        if1_to_if2_buf_o    : out if1_to_if2_buf_type;

        branch_adr_i        : in  std_logic_vector(31 downto 0);
        do_branch_i         : in  std_logic;
        
        ibus_adr_o          : out std_logic_vector(31 downto 0);
    
        flush_i             : in  std_logic;
        stall_i             : in  std_logic;

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;

    component if2_stage
    port (
        if1_to_if2_buf_i    : in  if1_to_if2_buf_type;
        if2_to_id_buf_o     : out if2_to_id_buf_type;
                
        ibus_dat_i          : in  std_logic_vector(31 downto 0);
        ibus_stall_i        : in  std_logic;
    
        flush_i             : in  std_logic;
        stall_i             : in  std_logic;
        
        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;
    
    component id_stage
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
    end component;

    component ex_stage
    port (
        id_to_ex_buf_i      : in  id_to_ex_buf_type;
        ex_to_me1_buf_o     : out ex_to_me1_buf_type;
        
        branch_adr_o        : out std_logic_vector(31 downto 0);
        do_branch_o         : out std_logic; 
                
        stall_i             : in  std_logic;

        rs1_fwd_i           : in  std_logic_vector(31 downto 0);
        rs1_use_fwd_i       : in  std_logic;

        rs2_fwd_i           : in  std_logic_vector(31 downto 0);
        rs2_use_fwd_i       : in  std_logic;

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;

    component me1_stage
    port (
        ex_to_me1_buf_i     : in  ex_to_me1_buf_type;
        me1_to_me2_buf_o    : out me1_to_me2_buf_type;
      
        dbus_adr_o          : out std_logic_vector(31 downto 0);
        dbus_dat_o          : out std_logic_vector(31 downto 0);
        dbus_we_o           : out std_logic_vector(3 downto 0);

        fwd_rd_sel_o        : out std_logic_vector(4 downto 0);
        fwd_rd_o            : out std_logic_vector(31 downto 0);

        stall_i             : in  std_logic;

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;
    
    component me2_stage
    port (
        me1_to_me2_buf_i    : in  me1_to_me2_buf_type;
        me2_to_wb_buf_o     : out me2_to_wb_buf_type;

        dbus_dat_i          : in  std_logic_vector(31 downto 0);
        dbus_stall_i        : in  std_logic;

        fwd_rd_sel_o        : out std_logic_vector(4 downto 0);
        fwd_rd_o            : out std_logic_vector(31 downto 0);

        stall_o             : out std_logic;

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;
    
    component wb_stage
    port (
        me2_to_wb_buf_i     : in  me2_to_wb_buf_type;

        rd_sel_o            : out std_logic_vector(4 downto 0);
        rd_o                : out std_logic_vector(31 downto 0);
        rd_we_o             : out std_logic;

        fwd_rd_sel_o        : out std_logic_vector(4 downto 0);
        fwd_rd_o            : out std_logic_vector(31 downto 0);

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
    end component;
    
    signal ex_to_if1_branch_adr : std_logic_vector(31 downto 0);
    signal ex_to_if1_do_branch  : std_logic;

    signal wb_rd                : std_logic_vector(31 downto 0);
    signal wb_rd_sel            : std_logic_vector(4 downto 0);
    signal wb_rd_we             : std_logic;    
    
    signal me2_to_all_stall     : std_logic;

    signal if1_to_if2_bus       : if1_to_if2_buf_type;
    signal if2_to_id_bus        : if2_to_id_buf_type;
    signal id_to_ex_bus         : id_to_ex_buf_type;
    signal ex_to_me1_bus        : ex_to_me1_buf_type;
    signal me1_to_me2_bus       : me1_to_me2_buf_type;
    signal me2_to_wb_bus        : me2_to_wb_buf_type;

    signal fwd_to_ex_rs1        : std_logic_vector(31 downto 0);
    signal fwd_to_ex_rs1_use    : std_logic;

    signal fwd_to_ex_rs2        : std_logic_vector(31 downto 0);
    signal fwd_to_ex_rs2_use    : std_logic;

    signal me1_to_fwd_rd        : std_logic_vector(31 downto 0);
    signal me1_to_fwd_rd_sel    : std_logic_vector(4 downto 0);

    signal me2_to_fwd_rd        : std_logic_vector(31 downto 0);
    signal me2_to_fwd_rd_sel    : std_logic_vector(4 downto 0);

    signal wb_to_fwd_rd         : std_logic_vector(31 downto 0);
    signal wb_to_fwd_rd_sel     : std_logic_vector(4 downto 0);
begin
    if1_stage_inst : if1_stage 
    port map (
        if1_to_if2_buf_o => if1_to_if2_bus,

        branch_adr_i =>     ex_to_if1_branch_adr,
        do_branch_i =>      ex_to_if1_do_branch,
                        
        ibus_adr_o =>       ibus_adr_o,

        flush_i =>          ex_to_if1_do_branch,
        stall_i =>          me2_to_all_stall,
        
        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );

    if2_stage_inst : if2_stage 
    port map (
        if1_to_if2_buf_i => if1_to_if2_bus,
        if2_to_id_buf_o =>  if2_to_id_bus,
                
        flush_i =>          ex_to_if1_do_branch,
        stall_i =>          me2_to_all_stall,

        ibus_dat_i =>       ibus_dat_i,
        ibus_stall_i =>     ibus_stall_i,

        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );

    id_stage_inst : id_stage 
    port map (
        if2_to_id_buf_i =>  if2_to_id_bus,
        id_to_ex_buf_o =>   id_to_ex_bus,

        rd_i =>             wb_rd,
        rd_sel_i =>         wb_rd_sel,
        rd_we_i =>          wb_rd_we,
        
        flush_i =>          ex_to_if1_do_branch,
        stall_i =>          me2_to_all_stall,

        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );

    forward_unit_inst : forward_unit
    port map ( 
        me1_rd_i =>         me1_to_fwd_rd,
        me1_rd_sel_i =>     me1_to_fwd_rd_sel,

        me2_rd_i =>         me2_to_fwd_rd,
        me2_rd_sel_i =>     me2_to_fwd_rd_sel,

        wb_rd_i =>          wb_to_fwd_rd,
        wb_rd_sel_i =>      wb_to_fwd_rd_sel,
        
        ex_rs1_sel_i =>     id_to_ex_bus.rs1_sel,
        ex_rs2_sel_i =>     id_to_ex_bus.rs2_sel,

        rs1_fwd_o =>        fwd_to_ex_rs1,
        rs1_use_fwd_o =>    fwd_to_ex_rs1_use,

        rs2_fwd_o =>        fwd_to_ex_rs2,
        rs2_use_fwd_o =>    fwd_to_ex_rs2_use,

        clk_i =>            clk_i,
        rst_i =>            rst_i
    );

    ex_stage_inst : ex_stage 
    port map (
        id_to_ex_buf_i =>   id_to_ex_bus,
        ex_to_me1_buf_o =>  ex_to_me1_bus,

        do_branch_o =>      ex_to_if1_do_branch, 
        branch_adr_o =>     ex_to_if1_branch_adr, 

        rs1_fwd_i =>        fwd_to_ex_rs1,
        rs1_use_fwd_i =>    fwd_to_ex_rs1_use,

        rs2_fwd_i =>        fwd_to_ex_rs2,
        rs2_use_fwd_i =>    fwd_to_ex_rs2_use,

        stall_i =>          me2_to_all_stall,

        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );

    me1_stage_inst : me1_stage 
    port map (
        ex_to_me1_buf_i =>  ex_to_me1_bus,
        me1_to_me2_buf_o => me1_to_me2_bus,

        dbus_adr_o =>       dbus_adr_o,
        dbus_dat_o =>       dbus_dat_o,
        dbus_we_o =>        dbus_we_o,

        stall_i =>          me2_to_all_stall,

        fwd_rd_sel_o =>     me1_to_fwd_rd_sel,
        fwd_rd_o =>         me1_to_fwd_rd,
        
        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );

    me2_stage_inst : me2_stage 
    port map (
        me1_to_me2_buf_i => me1_to_me2_bus,
        me2_to_wb_buf_o =>  me2_to_wb_bus,

        dbus_dat_i =>       dbus_dat_i,
        dbus_stall_i =>     dbus_stall_i,

        stall_o =>          me2_to_all_stall,

        fwd_rd_sel_o =>     me2_to_fwd_rd_sel,
        fwd_rd_o =>         me2_to_fwd_rd,

        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );

    wb_stage_inst : wb_stage 
    port map (
        me2_to_wb_buf_i =>  me2_to_wb_bus,

        rd_sel_o =>         wb_rd_sel,
        rd_o =>             wb_rd,
        rd_we_o =>          wb_rd_we,

        fwd_rd_sel_o =>     wb_to_fwd_rd_sel,
        fwd_rd_o =>         wb_to_fwd_rd,

        clk_i =>            clk_i, 
        rst_i =>            rst_i
    );
end behavioral;
