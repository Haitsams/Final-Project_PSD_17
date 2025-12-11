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
