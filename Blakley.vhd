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
type state is (LOAD, FIRSTCALC, CHECKBITz, COMPARE_N, BITDONE);
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
        a_shiftreg  <= (others => '0');
        b_reg       <= (others => '0');
        R_reg       <= (others => '0');
        counter     <= (others => '0');
    elsif (clk'event and clk = '1') then
        a_shiftreg  <= a_shiftreg_nxt;
        b_reg       <= b_reg_nxt;
        R_reg       <= R_reg_nxt;
        counter     <= counter_nxt;
        checkbit    <= checkbit_nxt;  
    end if;
end process;


---------------------------------------------------------------------------------------------------------
-- Process for statemachine logic
---------------------------------------------------------------------------------------------------------
process(all)
begin
    next_state  <= curr_state;
    done        <= '0';
    
    case (curr_state) is
        when LOAD       =>  if (start = '1') then
                                next_state  <= FIRSTCALC;
                            else
                                next_state  <= LOAD;
                            end if;
            
        when FIRSTCALC  =>  next_state      <= CHECKBITz;
            
        when CHECKBITz  =>  next_state      <= COMPARE_N;
            
        when COMPARE_N  =>  if (Rbign = '1') then
                                next_state  <= COMPARE_N;
                            else
                                next_state  <= BITDONE;
                            end if; 
            
        when BITDONE    =>  if (counter >= C_block_size-1) then
                                next_state  <= LOAD;
                                done        <= '1';
                            else
                                next_state  <= FIRSTCALC;
                            end if;
            
        when others     =>  next_state      <= LOAD;
    end case;
end process;


---------------------------------------------------------------------------------------------------------
-- Process handeling computation for given state
---------------------------------------------------------------------------------------------------------
process(all)
variable Rbign_temp : std_logic := '0';
begin
    R_reg_nxt       <= R_reg;
    counter_nxt     <= counter;
    checkbit_nxt    <= checkbit;
    b_reg_nxt       <= b_reg;
    a_shiftreg_nxt  <= a_shiftreg;
    
    case(curr_state) is
        when LOAD       =>  a_shiftreg_nxt  <= a;
                            b_reg_nxt       <= b;
                            counter_nxt     <= (others => '0');
                            R_reg_nxt       <= (others => '0');
                            checkbit_nxt    <= '0';
                            Rbign_temp      := '0'; 
            
        when FIRSTCALC  =>  R_reg_nxt       <= R_reg(C_block_size-1 downto 0) & '0';
                            a_shiftreg_nxt  <= a_shiftreg(C_block_size-2 downto 0) & '0';
                            checkbit_nxt    <= a_shiftreg(C_block_size-1);
        
        when CHECKBITz  =>  if (checkbit = '1') then 
                                R_reg_nxt   <= std_logic_vector(unsigned(R_reg) + unsigned(b_reg));
                            end if;
            
        when COMPARE_N  =>  if (unsigned(R_reg) >= unsigned(n)) then
                                Rbign_temp  := '1';
                                R_reg_nxt   <= std_logic_vector(unsigned(R_reg) - unsigned(n));
                            else
                                Rbign_temp  := '0';
                            end if; 
            
        when BITDONE    =>  counter_nxt     <= counter + 1;
            
        when others     =>  a_shiftreg_nxt  <= a;
                            b_reg_nxt       <= b;
                            counter_nxt     <= (others => '0');
                            R_reg_nxt       <= (others => '0');
                            checkbit_nxt    <= '0';
                            Rbign_temp      := '0';             
    end case;
    
    Rbign <= Rbign_temp;

end process;

    R <= R_reg(C_block_size-1 downto 0);

end Behavioral;