---------------------------------------------------------------------
--  BAGIAN HAITSAM — 
---------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pipeline_alu is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        instr_in    : in  STD_LOGIC_VECTOR(15 downto 0);
        instr_valid : in  STD_LOGIC;
        stall_out   : out STD_LOGIC;
        result_out  : out STD_LOGIC_VECTOR(15 downto 0);
        flags_out   : out STD_LOGIC_VECTOR(3 downto 0)
    );
end pipeline_alu;

architecture Behavioral of pipeline_alu is

---------------------------------------------------------------------
--  BAGIAN NOVA — Register File + ID Stage (Decode)
---------------------------------------------------------------------

    type reg_array is array (0 to 15) of std_logic_vector(15 downto 0);
    signal reg_file : reg_array := (others => (others => '0'));

    signal id_opcode : std_logic_vector(3 downto 0);
    signal id_rd     : std_logic_vector(3 downto 0);
    signal id_rs1    : std_logic_vector(3 downto 0);
    signal id_rs2    : std_logic_vector(3 downto 0);
    signal id_data1  : std_logic_vector(15 downto 0);
    signal id_data2  : std_logic_vector(15 downto 0);

    id_opcode <= instr_in(15 downto 12);
    id_rd     <= instr_in(11 downto 8);
    id_rs1    <= instr_in(7 downto 4);
    id_rs2    <= instr_in(3 downto 0);

    id_data1 <= reg_file(to_integer(unsigned(id_rs1)));
    id_data2 <= reg_file(to_integer(unsigned(id_rs2)));

---------------------------------------------------------------------
--  BAGIAN HAITSAM — Hazard Detection + Stall Logic
---------------------------------------------------------------------

    signal hazard_detected : std_logic;

    process(id_rs1, id_rs2, ex_rd, ex_valid, fg_rd, fg_valid, wb_rd, wb_valid)
    begin
        hazard_detected <= '0';

        if ex_valid = '1' and (ex_rd = id_rs1 or ex_rd = id_rs2) then
            hazard_detected <= '1';
        end if;

        if fg_valid = '1' and (fg_rd = id_rs1 or fg_rd = id_rs2) then
            hazard_detected <= '1';
        end if;

        if wb_valid = '1' and (wb_rd = id_rs1 or wb_rd = id_rs2) then
            hazard_detected <= '1';
        end if;
    end process;

    stall_out <= hazard_detected;

---------------------------------------------------------------------
--  BAGIAN NOVA — Pipeline Register ID → EX (with bubble)
---------------------------------------------------------------------

process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            ex_valid <= '0';
            ex_opcode <= "1111";
            ex_rd <= (others => '0');
            ex_data1 <= (others => '0');
            ex_data2 <= (others => '0');

        elsif hazard_detected = '1' then
            -- bubble
            ex_valid <= '0';
            ex_opcode <= "1111";

        elsif instr_valid = '1' then
            ex_valid <= '1';
            ex_opcode <= id_opcode;
            ex_rd <= id_rd;
            ex_data1 <= id_data1;
            ex_data2 <= id_data2;

        else
            ex_valid <= '0';
        end if;
    end if;
end process;

---------------------------------------------------------------------
-- BAGIAN SABBIA — ALU (EX Stage)
---------------------------------------------------------------------

process(ex_opcode, ex_data1, ex_data2)
    variable v1 : signed(16 downto 0);
    variable v2 : signed(16 downto 0);
begin
    v1 := resize(signed(ex_data1), 17);
    v2 := resize(signed(ex_data2), 17);

    case ex_opcode is
        when "0000" => ex_result_raw <= std_logic_vector(v1 + v2); -- ADD
        when "0001" => ex_result_raw <= std_logic_vector(v1 - v2); -- SUB
        when "0010" => ex_result_raw(15 downto 0) <= ex_data1 and ex_data2; -- AND
        when "0011" => ex_result_raw(15 downto 0) <= ex_data1 or  ex_data2; -- OR
        when "0100" => ex_result_raw(15 downto 0) <= ex_data1 xor ex_data2; -- XOR
        when others => ex_result_raw <= (others => '0');
    end case;
end process;

---------------------------------------------------------------------
-- BAGIAN SABBIA — EX → FG Pipeline Register
---------------------------------------------------------------------

process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            fg_valid  <= '0';
            fg_result <= (others => '0');
            fg_rd     <= (others => '0');

        else
            fg_valid  <= ex_valid;
            fg_result <= ex_result_raw(15 downto 0);
            fg_rd     <= ex_rd;
        end if;
    end if;
end process;

---------------------------------------------------------------------
--  BAGIAN HAITSAM — FLAG GENERATION (FG Stage)
---------------------------------------------------------------------

process(fg_result, fg_valid)
begin
    if fg_valid = '1' then
        fg_flags(3) <= '1' when fg_result = x"0000" else '0'; -- Zero
        fg_flags(0) <= fg_result(15);                        -- Negative
        fg_flags(2) <= '0'; -- Carry (simplified)
        fg_flags(1) <= '0'; -- Overflow (simplified)
    else
        fg_flags <= "0000";
    end if;
end process;

---------------------------------------------------------------------
-- BAGIAN SABBIA — FG → WB Pipeline Register + WB Stage
---------------------------------------------------------------------

process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            wb_valid  <= '0';
            wb_rd     <= (others => '0');
            wb_result <= (others => '0');
            flags_out <= (others => '0');

        else
            wb_valid  <= fg_valid;
            wb_rd     <= fg_rd;
            wb_result <= fg_result;
            flags_out <= fg_flags;
        end if;
    end if;
end process;

---------------------------------------------------------------------
-- 🔵 BAGIAN NOVA — Register File Write-back
---------------------------------------------------------------------

process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            reg_file(0) <= x"0005";
            reg_file(1) <= x"0003";
            reg_file(2) <= x"0001";

        elsif wb_valid = '1' then
            reg_file(to_integer(unsigned(wb_rd))) <= wb_result;
        end if;
    end if;
end process;


result_out <= wb_result;

end Behavioral;