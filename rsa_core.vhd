library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256
	);
	
	port (
		clk                    :  in std_logic;
		reset_n                :  in std_logic;
		msgin_valid             : in std_logic;
		msgin_ready             : out std_logic;
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		msgin_last              :  in std_logic;
		msgout_valid            : out std_logic;
		msgout_ready            :  in std_logic;
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		msgout_last             : out std_logic;
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)
	);
end rsa_core;

architecture rtl of rsa_core is

	component exponentiation
		port (
			start : in std_logic;
			done : out std_logic;
	
			--input data
			message 	: in STD_LOGIC_VECTOR (C_BLOCK_SIZE-1 downto 0 );
			key 		: in STD_LOGIC_VECTOR (C_BLOCK_SIZE-1 downto 0 );
	
			--output data
			result 		: out STD_LOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
	
			--modulus
			modulus 	: in STD_LOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);
	
			--utility
			clk 		: in STD_LOGIC;
			reset_n 	: in STD_LOGIC
		);
	end component;

	signal exporesult : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	signal expodone : std_logic := '0';
	signal expo_EN, expo_EN_nxt : std_logic := '0';
    signal mreg, mreg_nxt : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	type state is (IDLE, WAIT_FOR_VALID, LOAD, SEND_READY, EXPO, SEND_VALID, WAIT_FOR_READY);
    signal curr_state, next_state : state;
    --signal validin, validin_nxt : std_logic := '0';
    --signal readyout, readyout_nxt : std_logic := '0';
    --signal validout_nxt : std_logic:= '0';
    --signal readyin_nxt : std_logic:= '0';
begin
		expos : exponentiation port map ( start => expo_EN_nxt,
								done => expodone,
								message => mreg,
								key => key_e_d,
								result => exporesult,
								modulus => key_n,
								clk => clk,
								reset_n => reset_n);
	rsa_status   <= (others => '0');

	process(clk, reset_n)
    begin
        if (reset_n = '0') then
            curr_state <= WAIT_FOR_VALID;
        else 
            if (clk'event and clk = '1') then
                curr_state <= next_state;
            end if;
        end if;
    end process;


	process(clk, reset_n)
    begin
        if (reset_n = '0') then
            mreg <= (others => '0');
            --validin <= '0';
            --readyout <= '0';
            expo_EN <= '0';
        else
            if (clk'event and clk = '1') then
                mreg <= mreg_nxt;
                --validin <= validin_nxt;
                --readyout <= readyout_nxt;    
                expo_EN <= expo_EN_nxt;
            end if;
        end if;
    end process;



process(all)
begin
    next_state <= curr_state;
    expo_EN_nxt <= expo_EN;
    mreg_nxt <= mreg;
    case(curr_state) is
        when IDLE => 
            msgin_ready <= '0';
            msgout_valid <= '0';
            next_state <= WAIT_FOR_VALID;
        when WAIT_FOR_VALID =>
            if (msgin_valid = '1') then
                next_state <= LOAD;
            else
                next_state <= WAIT_FOR_VALID;
            end if;
        when LOAD => 
            mreg_nxt <= msgin_data;
            next_state <= SEND_READY;
        when SEND_READY => 
            msgin_ready <= '1';
            msgout_last <= msgin_last;
            next_state <= EXPO;
        when EXPO => 
            msgin_ready <= '0';
            expo_EN_nxt <= '1';
            if (expodone = '1') then
                next_state <= SEND_VALID;
                expo_EN_nxt <= '0';
            else
                next_state <= EXPO;
            end if;
        when SEND_VALID => 
            msgout_valid <= '1';
            if (msgout_ready = '1') then
                msgout_data <= exporesult;
                next_state <= IDLE;
            else
                next_state <= WAIT_FOR_READY;
            end if;
        when WAIT_FOR_READY => 
            if (msgout_ready = '1') then
                msgout_data <= exporesult;
                next_state <= IDLE;
            else
                next_state <= WAIT_FOR_READY;
            end if;
        when others => 
            next_state <= IDLE;
    end case;
end process;

end rtl;
