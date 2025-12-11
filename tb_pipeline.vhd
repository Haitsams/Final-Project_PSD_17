library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pipeline_alu is
end tb_pipeline_alu;

architecture Behavioral of tb_pipeline_alu is

    component pipeline_alu is
        Port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            instr_in    : in  STD_LOGIC_VECTOR(15 downto 0);
            instr_valid : in  STD_LOGIC;
            stall_out   : out STD_LOGIC;
            result_out  : out STD_LOGIC_VECTOR(15 downto 0);
            flags_out   : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal instr_in : std_logic_vector(15 downto 0) := (others => '0');
    signal instr_valid : std_logic := '0';
    signal stall_out : std_logic;
    signal result_out : std_logic_vector(15 downto 0);
    signal flags_out : std_logic_vector(3 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut: pipeline_alu
        Port Map (
            clk => clk,
            rst => rst,
            instr_in => instr_in,
            instr_valid => instr_valid,
            stall_out => stall_out,
            result_out => result_out,
            flags_out => flags_out
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;
        instr_valid <= '1'; 

        instr_in <= "0000" & "0011" & "0000" & "0001"; 
        wait for clk_period;
        instr_in <= "0001" & "0100" & "0000" & "0010"; 
        wait for clk_period;
        instr_in <= "0000" & "0101" & "0011" & "0001"; 
        
        for i in 0 to 5 loop
            wait for 1 ns; 
            if stall_out = '1' then

            else
            end if;
            wait for clk_period - 1 ns;
        end loop;

        instr_in <= "0010" & "0110" & "0001" & "0010"; 
        wait for clk_period;

        instr_valid <= '0';
        wait;
    end process;

end Behavioral;