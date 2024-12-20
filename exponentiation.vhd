library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		start : in std_logic;
        done : out std_logic;
		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;

architecture Behavioral of exponentiation is

    ---------------------------------------------------------------------------------------------------------
-- Instantiate Blakley module
---------------------------------------------------------------------------------------------------------
    component Blakley
        port ( clk : in std_logic;
               rst_n : in std_logic;
               start : in std_logic;
               a : in std_logic_vector(C_block_size-1 downto 0);
               b : in std_logic_vector(C_block_size-1 downto 0);
               n : in std_logic_vector(C_block_size-1 downto 0);
               R : out std_logic_vector(C_block_size-1 downto 0);
               done : out std_logic);
    end component;

    -------------------------------------------------------------------------------
    -- Internal signal declaration
    -------------------------------------------------------------------------------
    signal checkbit, checkbit_nxt : std_logic := '0';
    signal C_BLAKLEY_EN, C_BLAKLEY_EN_nxt : std_logic := '0';
    signal M_BLAKLEY_EN, M_BLAKLEY_EN_nxt : std_logic := '0';
    signal nreg, nreg_nxt : std_logic_vector(C_block_size-1 downto 0);
    signal mreg, mreg_nxt : std_logic_vector(C_block_size-1 downto 0);
    signal ereg, ereg_nxt : std_logic_vector(C_block_size-1 downto 0);
    signal creg, creg_nxt : std_logic_vector(C_block_size-1 downto 0);
    signal cblakleyout : std_logic_vector(C_block_size-1 downto 0);
    signal mblakleyout : std_logic_vector(C_block_size-1 downto 0);
    signal cblakleydone : std_logic := '0';
    signal mblakleydone : std_logic := '0';
    signal counter, counter_nxt : std_logic_vector(7 downto 0);
    -- State initialization 
    type state is (IDLE, LOAD, FIRSTBIT, CBLAKLEY, SHIFTBIT, MBLAKLEY, BITDONE, READY_TO_SEND);
    signal curr_state, next_state : state;

begin
    
    -------------------------------------------------------------------------------
    -- Port mapping to Blakley modules
    -------------------------------------------------------------------------------
    C_BLAKLEY : Blakley port map (  clk => clk,
                                   rst_n => reset_n,
                                   start => C_BLAKLEY_EN,
                                   a => creg,
                                   b => creg,
                                   n => nreg,
                                   R => cblakleyout,
                                   done => cblakleydone);

    M_BLAKLEY : Blakley port map (  clk => clk,
                                    rst_n => reset_n,
                                    start => M_BLAKLEY_EN,
                                    a => creg,
                                    b => mreg,
                                    n => nreg,
                                    R => mblakleyout,
                                    done => mblakleydone);

    
    ---------------------------------------------------------------------------------------------------------
    -- Update state on rising edge
    ---------------------------------------------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if (reset_n = '0') then
            curr_state <= IDLE;
        else 
            if (clk'event and clk = '1') then
                curr_state <= next_state;
            end if;
        end if;
    end process;


    ---------------------------------------------------------------------------------------------------------
    -- Process for statemachine logic
    ---------------------------------------------------------------------------
    process(all)
    begin
        case(curr_state) is 
            when IDLE =>
                done <= '0';
                if (start = '1') then
                    next_state <= LOAD;
                else
                    next_state <= IDLE;
                end if;
            when LOAD =>
                next_state <= FIRSTBIT;
            when FIRSTBIT => 
                next_state <= CBLAKLEY;
            when CBLAKLEY => 
                if (cblakleydone = '1') then
                    next_state <= SHIFTBIT;
                else
                    next_state <= CBLAKLEY;
                end if;
            when SHIFTBIT =>
                if (checkbit = '1') then
                    next_state <= MBLAKLEY;
                else
                    next_state <= BITDONE;
                end if;
            when MBLAKLEY => 
                if (mblakleydone = '1') then
                    next_state <= BITDONE;
                else
                    next_state <= MBLAKLEY;
                end if;
            when BITDONE => 
                if (counter >= C_block_size-1) then
                    done <= '1';
                    result <= creg;
                    next_state <= IDLE;
                else
                    next_state <= CBLAKLEY;
                end if;
            when others => 
                next_state <= IDLE;
        end case;
    end process;

    process(clk, reset_n)
    begin
        if (reset_n = '0') then
            mreg <= (others => '0');
            ereg <= (others => '0');
            nreg <= (others => '0');
            creg <= (others => '0');
            C_BLAKLEY_EN <= '0';
            M_BLAKLEY_EN <= '0';
            counter <= (others => '0');
        else
            if (clk'event and clk = '1') then
                mreg <= mreg_nxt;
                ereg <= ereg_nxt;
                nreg <= nreg_nxt;
                creg <= creg_nxt;
                checkbit <= checkbit_nxt;
                counter <= counter_nxt;
                C_BLAKLEY_EN <= C_BLAKLEY_EN_nxt;
                M_BLAKLEY_EN <= M_BLAKLEY_EN_nxt;
            end if;
        end if;
    end process;


    ---------------------------------------------------------------------------------------------------------
    -- Process handeling computation for given state
    ---------------------------------------------------------------------------------------------------------
    process(all)
    variable checkbit_var : std_logic := '0';
    begin
        case(curr_state) is 
            when IDLE =>
                mreg_nxt <= (others => '0');
                ereg_nxt <= (others => '0');
                nreg_nxt <= (others => '0');
                creg_nxt <= (others => '0');
                checkbit_var := '0';
                C_BLAKLEY_EN_nxt <= '0';
                M_BLAKLEY_EN_nxt <= '0';
                counter_nxt <= (others => '0');
            when LOAD => 
                mreg_nxt <= message;
                ereg_nxt <= key;
                nreg_nxt <= modulus;
            when FIRSTBIT => 
                ereg_nxt <= ereg(C_block_size-2 downto 0) & '0';
                checkbit_var := ereg(C_block_size-1);
                if (checkbit_var = '1') then
                    creg_nxt <= mreg;
                else
                    creg_nxt(C_block_size-1 downto 1) <= (others => '0');
                    creg_nxt(0) <= '1';
                end if;
            when CBLAKLEY =>
                C_BLAKLEY_EN_nxt <= '1';
                if (cblakleydone = '1') then 
                    creg_nxt <= cblakleyout;
                    C_BLAKLEY_EN_nxt <= '0';
                end if;
            when SHIFTBIT => 
                ereg_nxt <= ereg(C_block_size-2 downto 0) & '0';
                checkbit_var := ereg(C_block_size-1);
            when MBLAKLEY => 
                M_BLAKLEY_EN_nxt <= '1';
                if (mblakleydone = '1') then
                    creg_nxt <= mblakleyout;
                    M_BLAKLEY_EN_nxt <= '0';
                end if;
            when BITDONE => 
                counter_nxt <= counter + 1;
            when others =>
                mreg_nxt <= (others => '0');
                ereg_nxt <= (others => '0');
                nreg_nxt <= (others => '0');
                creg_nxt <= (others => '0');
                checkbit_var := '0';
                C_BLAKLEY_EN_nxt <= '0';
                M_BLAKLEY_EN_nxt <= '0';
                counter_nxt <= (others => '0');
        end case;
        checkbit_nxt <= checkbit_var;
    end process;
    
end Behavioral;
