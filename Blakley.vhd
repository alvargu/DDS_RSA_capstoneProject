library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- UPDATE, IDLE STATE REMOVED
entity Blakley is
    generic (
		C_block_size : integer := 256
	);
    port ( 
           -- Input signals:
           -- Control signals
           clk : in std_logic;
           rst_n : in std_logic;
           start : in std_logic;
           -- Parameter signals
           a : in std_logic_vector(C_block_size-1 downto 0);
           b : in std_logic_vector(C_block_size-1 downto 0);
           n : in std_logic_vector(C_block_size-1 downto 0);
           -- Output signals
           R : out std_logic_vector(C_block_size-1 downto 0);
           done : out std_logic);
end Blakley;

architecture Behavioral of Blakley is
-------------------------------------------------------------------------------
-- Define internal signals of circuit
-------------------------------------------------------------------------------

-- Registers 
signal R_reg, R_reg_nxt : std_logic_vector(C_block_size downto 0);
signal a_shiftreg, a_shiftreg_nxt : std_logic_vector(C_block_size-1 downto 0) := (others => '0');
signal checkbit, checkbit_nxt : std_logic;
signal b_reg, b_reg_nxt : std_logic_vector(C_block_size-1 downto 0);
signal counter, counter_nxt : std_logic_vector(7 downto 0) := (others => '0');
signal Rbign : std_logic := '0';

-- State initialization
type state is (LOAD, FIRSTCALC, COMPARE_N, BITDONE);
signal curr_state, next_state : state;

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin

---------------------------------------------------------------------------------------------------------
-- Update state on rising edge
---------------------------------------------------------------------------------------------------------
process(clk, rst_n)
begin
    if (rst_n = '0') then
        curr_state <= LOAD;
    elsif (clk'event and clk = '1') then
        curr_state <= next_state;
    end if;
end process;


---------------------------------------------------------------------------------------------------------
-- Load values into registers
---------------------------------------------------------------------------------------------------------
process(clk, rst_n)
begin
    if (rst_n = '0') then
        a_shiftreg <= (others => '0');
        b_reg <= (others => '0');
        R_reg <= (others => '0');
        counter <= (others => '0');
    elsif (clk'event and clk = '1') then
        a_shiftreg <= a_shiftreg_nxt;
        b_reg <= b_reg_nxt;
        R_reg <= R_reg_nxt;
        counter <= counter_nxt;
        checkbit <= checkbit_nxt;  
    end if;
end process;


---------------------------------------------------------------------------------------------------------
-- Process for statemachine logic
---------------------------------------------------------------------------------------------------------
process(curr_state, start, counter, R_reg_nxt, Rbign)
begin
    case (curr_state) is
        when LOAD => 
            done <= '0';
            if (start = '1') then
                next_state <= FIRSTCALC;
            else
                next_state <= LOAD;
            end if;
        when FIRSTCALC =>
            if (Rbign = '1') then
                next_state <= COMPARE_N;
            else
                next_state <= BITDONE;
            end if;
        when COMPARE_N => 
            if (Rbign = '1') then
                next_state <= COMPARE_N;
            else
                next_state <= BITDONE;
            end if;
        when BITDONE => 
            if (counter >= C_block_size-1) then
                next_state <= LOAD;
                done <= '1';
            else
                next_state <= FIRSTCALC;
            end if;
        when others =>
            done <= '0';
            next_state <= LOAD;
    end case;
end process;


---------------------------------------------------------------------------------------------------------
-- Process handeling computation for given state
---------------------------------------------------------------------------------------------------------
process(curr_state, counter, R_reg, checkbit, counter, n, b, a, b_reg, a_shiftreg)
variable R_temp : std_logic_vector(C_block_size downto 0) := (others => '0');
variable checkbit_var : std_logic := '0';
begin
    a_shiftreg_nxt <= a_shiftreg;
    b_reg_nxt <= b_reg;
    counter_nxt <= counter;
    case(curr_state) is
        when LOAD => 
            a_shiftreg_nxt <= a;
            b_reg_nxt <= b;
            counter_nxt <= (others => '0');
            R_temp := (others => '0');
            checkbit_var := '0';
        when FIRSTCALC =>
            R_temp := R_reg(C_block_size-1 downto 0) & '0';
            a_shiftreg_nxt <= a_shiftreg(C_block_size-2 downto 0) & '0';
            checkbit_var := a_shiftreg(C_block_size-1);
            if (checkbit_var = '1') then
                R_temp := std_logic_vector(unsigned(R_temp) + unsigned(b_reg));
            end if;
            if (unsigned(R_temp) >= unsigned(n)) then
                Rbign <= '1';
            else
                Rbign <= '0';
            end if;
        when COMPARE_N => 
            R_temp := std_logic_vector(unsigned(R_reg) - unsigned(n));
            if (unsigned(R_temp) >= unsigned(n)) then
                Rbign <= '1';
            else
                Rbign <= '0';
            end if;
        when BITDONE => 
            counter_nxt <= counter + 1;
        when others => 
            a_shiftreg_nxt <= a;
            b_reg_nxt <= b;
            counter_nxt <= (others => '0');
            R_temp := (others => '0');
            checkbit_var := '0';
    end case;

    R_reg_nxt <= R_temp;
    checkbit_nxt <= checkbit_var;
end process;


R <= R_reg(C_block_size-1 downto 0);

end Behavioral;
