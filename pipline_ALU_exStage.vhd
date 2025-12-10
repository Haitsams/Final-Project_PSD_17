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
