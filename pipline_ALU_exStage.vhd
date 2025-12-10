process(ex_opcode, ex_data1, ex_data2)
        variable v1 : signed(16 downto 0);
        variable v2 : signed(16 downto 0);
    begin
        v1 := resize(signed(ex_data1), 17);
        v2 := resize(signed(ex_data2), 17);

        case ex_opcode is
            when "0000" => ex_result_raw <= std_logic_vector(v1 + v2);               -- ADD
            when "0001" => ex_result_raw <= std_logic_vector(v1 - v2);               -- SUB
            when "0010" => ex_result_raw(15 downto 0) <= ex_data1 and ex_data2;      -- AND
            when "0011" => ex_result_raw(15 downto 0) <= ex_data1 or  ex_data2;      -- OR
            when "0100" => ex_result_raw(15 downto 0) <= ex_data1 xor ex_data2;      -- XOR
            when others => ex_result_raw <= (others => '0');
        end case;
    end process;