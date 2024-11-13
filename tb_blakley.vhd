library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_blakley is
    generic (
            C_block_size : integer := 256
        );
end tb_blakley;

architecture Behavioral of tb_blakley is

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

signal clk : std_logic := '0';
signal rst_n : std_logic := '1';
signal start : std_logic := '0';
signal a, b, n : std_logic_vector(C_block_size-1 downto 0);   
signal R : std_logic_vector(C_block_size-1 downto 0);        
signal done : std_logic;
begin
clk <= not clk after 30 ns;
a(C_block_size-1 downto 8) <= (others => '0');
a(7 downto 0) <= "10100101";

b(C_block_size-1 downto 8) <= (others => '0');
b(7 downto 0) <= "10000111";

n(C_block_size-1 downto 8) <= (others => '0');
n(7 downto 0) <= "10101100";

UUT : Blakley port map ( clk => clk,
                         start => start,
                         rst_n => rst_n,
                         a => a,
                         b => b,
                         n => n,
                         R => R,
                         done => done);

process
begin
    wait for 45 ns;
    start <= '1';
    wait for 60 ns;
    start <= '0';
    wait;
end process;
end Behavioral;
