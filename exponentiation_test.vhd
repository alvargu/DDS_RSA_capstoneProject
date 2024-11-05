library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Seems to work! Running simulation will test (84^45 mod 141) which results in 108. 
entity exponentiation_test is
    port ( clk : in std_logic;
           rst : in std_logic;
           start : in std_logic;
           msgin_data : in std_logic_vector(7 downto 0);
           key_e : in std_logic_vector(7 downto 0);
           key_n : in std_logic_vector(7 downto 0);
           msgout_data : out std_logic_vector(7 downto 0);
           done : out std_logic);
end exponentiation_test;

architecture Behavioral of exponentiation_test is

    component Blakley
        port ( clk : in std_logic;
               rst : in std_logic;
               start : in std_logic;
               a : in std_logic_vector(7 downto 0);
               b : in std_logic_vector(7 downto 0);
               n : in std_logic_vector(7 downto 0);
               R : out std_logic_vector(7 downto 0);
               done : out std_logic);
    end component;

    signal checkbit, checkbit_nxt : std_logic := '0';
    signal C_BLAKLEY_EN, C_BLAKLEY_EN_nxt : std_logic := '0';
    signal M_BLAKLEY_EN, M_BLAKLEY_EN_nxt : std_logic := '0';
    signal nreg, nreg_nxt : std_logic_vector(7 downto 0);
    signal mreg, mreg_nxt : std_logic_vector(7 downto 0);
    signal ereg, ereg_nxt : std_logic_vector(7 downto 0);
    signal creg, creg_nxt : std_logic_vector(7 downto 0);
    signal cblakleyout : std_logic_vector(7 downto 0);
    signal mblakleyout : std_logic_vector(7 downto 0);
    signal cblakleydone : std_logic := '0';
    signal mblakleydone : std_logic := '0';
    signal counter, counter_nxt : std_logic_vector(2 downto 0);


    type state is (IDLE, LOAD, FIRSTBIT, CBLAKLEY, SHIFTBIT, MBLAKLEY, BITDONE);
    signal curr_state, next_state : state;

begin

    C_BLAKLEY : Blakley port map (  clk => clk,
                                   rst => rst,
                                   start => C_BLAKLEY_EN,
                                   a => creg,
                                   b => creg,
                                   n => nreg,
                                   R => cblakleyout,
                                   done => cblakleydone);

    M_BLAKLEY : Blakley port map (  clk => clk,
                                    rst => rst,
                                    start => M_BLAKLEY_EN,
                                    a => creg,
                                    b => mreg,
                                    n => nreg,
                                    R => mblakleyout,
                                    done => mblakleydone);

    
    process(clk, rst)
    begin
        if (rst = '1') then
            curr_state <= IDLE;
        else 
            if (clk'event and clk = '1') then
                curr_state <= next_state;
            end if;
        end if;
    end process;

    process(curr_state, start, cblakleydone, mblakleydone, counter)
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
                if (counter >= 7) then
                    next_state <= IDLE;
                    done <= '1';
                else
                    next_state <= CBLAKLEY;
                end if;
            when others => 
                if (start = '1') then
                    next_state <= LOAD;
                else
                    next_state <= IDLE;
                end if;
        end case;
    end process;

    process(clk, rst)
    begin
        if (rst = '1') then
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

    process(curr_state, msgin_data, key_e, key_n, ereg, mreg, cblakleydone, mblakleydone)
    variable checkbit_var : std_logic := '0';
    variable c_temp : std_logic_vector(7 downto 0);
    begin
        case(curr_state) is 
            when IDLE =>
                mreg_nxt <= (others => '0');
                ereg_nxt <= (others => '0');
                nreg_nxt <= (others => '0');
                c_temp := (others => '0');
                checkbit_var := '0';
                C_BLAKLEY_EN_nxt <= '0';
                M_BLAKLEY_EN_nxt <= '0';
                counter_nxt <= (others => '0');
            when LOAD => 
                mreg_nxt <= msgin_data;
                ereg_nxt <= key_e;
                nreg_nxt <= key_n;
            when FIRSTBIT => 
                ereg_nxt <= ereg(6 downto 0) & '0';
                checkbit_var := ereg(7);
                if (checkbit_var = '1') then
                    c_temp := mreg;
                else
                    c_temp := "00000001";
                end if;
            when CBLAKLEY =>
                if (cblakleydone = '1') then 
                    c_temp := cblakleyout;
                    C_BLAKLEY_EN_nxt <= '0';
                else
                    C_BLAKLEY_EN_nxt <= '1';
                end if;
            when SHIFTBIT => 
                ereg_nxt <= ereg(6 downto 0) & '0';
                checkbit_var := ereg(7);
            when MBLAKLEY => 
                if (mblakleydone = '1') then
                    c_temp := mblakleyout;
                    M_BLAKLEY_EN_nxt <= '0';
                else
                    M_BLAKLEY_EN_nxt <= '1';
                end if;
            when BITDONE => 
                counter_nxt <= counter + 1;
            when others =>
                mreg_nxt <= (others => '0');
                ereg_nxt <= (others => '0');
                nreg_nxt <= (others => '0');
                c_temp := (others => '0');
                checkbit_var := '0';
                C_BLAKLEY_EN_nxt <= '0';
                M_BLAKLEY_EN_nxt <= '0';
                counter_nxt <= (others => '0');
        end case;
        creg_nxt <= c_temp;
        checkbit_nxt <= checkbit_var;
    end process;
    
    msgout_data <= creg;
end Behavioral;
