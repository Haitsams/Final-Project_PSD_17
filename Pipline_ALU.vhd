library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

    -------------------------------------------------------------------------
    -- Haitsam - Entity
    -------------------------------------------------------------------------

entity pipeline_alu is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        instr_in    : in  STD_LOGIC_VECTOR(15 downto 0); -- Input Instruksi
        instr_valid : in  STD_LOGIC;                     -- Penanda ada instruksi masuk
        stall_out   : out STD_LOGIC;                     -- Sinyal ke Fetch Unit untuk stop kirim instruksi
        result_out  : out STD_LOGIC_VECTOR(15 downto 0); -- Output hasil (untuk debug/monitoring)
        flags_out   : out STD_LOGIC_VECTOR(3 downto 0)   -- Z, C, V, N
    );
end pipeline_alu;

architecture Behavioral of pipeline_alu is
    -- Deklarasikan semua sinyal pipeline
    -- Definisi Opcode
    constant OP_ADD : std_logic_vector(3 downto 0) := "0000";
    constant OP_SUB : std_logic_vector(3 downto 0) := "0001";
    constant OP_AND : std_logic_vector(3 downto 0) := "0010";
    constant OP_OR  : std_logic_vector(3 downto 0) := "0011";
    constant OP_XOR : std_logic_vector(3 downto 0) := "0100";
    constant OP_NOP : std_logic_vector(3 downto 0) := "1111";

    -- Register File (16 Register, 16-bit lebar)
    type reg_array is array (0 to 15) of std_logic_vector(15 downto 0);
    signal reg_file : reg_array := (others => (others => '0'));

    -- Pipeline Registers / Signals
    -- Stage 1: ID Signals
    signal id_opcode : std_logic_vector(3 downto 0);
    signal id_rd     : std_logic_vector(3 downto 0);
    signal id_rs1    : std_logic_vector(3 downto 0);
    signal id_rs2    : std_logic_vector(3 downto 0);
    signal id_data1  : std_logic_vector(15 downto 0);
    signal id_data2  : std_logic_vector(15 downto 0);
    signal hazard_detected : std_logic;

    -- Stage 2: EX Signals (Output dari ID/Register pipeline ID_EX)
    signal ex_opcode : std_logic_vector(3 downto 0);
    signal ex_rd     : std_logic_vector(3 downto 0);
    signal ex_data1  : std_logic_vector(15 downto 0);
    signal ex_data2  : std_logic_vector(15 downto 0);
    signal ex_result_raw : std_logic_vector(16 downto 0); -- 17 bit for carry
    signal ex_valid  : std_logic;

    -- Stage 3: FG Signals (Output dari EX/Register pipeline EX_FG)
    signal fg_rd     : std_logic_vector(3 downto 0);
    signal fg_result : std_logic_vector(15 downto 0);
    signal fg_flags  : std_logic_vector(3 downto 0); -- Z, C, V, N
    signal fg_valid  : std_logic;

    -- Stage 4: WB Signals (Output dari FG/Register pipeline FG_WB)
    signal wb_rd     : std_logic_vector(3 downto 0);
    signal wb_result : std_logic_vector(15 downto 0);
    signal wb_valid  : std_logic;
    signal wb_write_en : std_logic;

begin

    -------------------------------------------------------------------------
    -- Haitsam - Instruction Decode & Hazard Detection
    -------------------------------------------------------------------------
    
    -- Parsing Instruksi
    id_opcode <= instr_in(15 downto 12);
    id_rd     <= instr_in(11 downto 8);
    id_rs1    <= instr_in(7 downto 4);
    id_rs2    <= instr_in(3 downto 0);

    -- HAZARD DETECTION LOGIC (RAW - Read After Write)
    -- Cek apakah register sumber (Rs1/Rs2) instruksi saat ini sedang diproses
    -- oleh instruksi sebelumnya di tahap EX, FG, atau WB.
    process(id_rs1, id_rs2, ex_rd, ex_valid, fg_rd, fg_valid, wb_rd, wb_valid)
    begin
        hazard_detected <= '0';
        
        -- Cek konflik dengan stage EX
        if ex_valid = '1' and (ex_rd = id_rs1 or ex_rd = id_rs2) then
            hazard_detected <= '1';
        end if;

        -- Cek konflik dengan stage FG
        if fg_valid = '1' and (fg_rd = id_rs1 or fg_rd = id_rs2) then
            hazard_detected <= '1';
        end if;

        -- Cek konflik dengan stage WB (kecuali jika WB baru saja selesai menulis di clock edge yang sama, 
        -- tapi untuk simplifikasi kita stall juga)
        if wb_valid = '1' and (wb_rd = id_rs1 or wb_rd = id_rs2) then
            hazard_detected <= '1';
        end if;
    end process;

    stall_out <= hazard_detected;

    -- Membaca Data dari Register File (Asynchronous Read)
    id_data1 <= reg_file(to_integer(unsigned(id_rs1)));
    id_data2 <= reg_file(to_integer(unsigned(id_rs2)));
>>>>>>> 332f8f12bea7ca1b534eed8d6d0189599e2346c0
