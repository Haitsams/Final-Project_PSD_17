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