library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity RAMReader is
    port(
        PIClock             :   in  std_logic;
        PIReset             :   in  std_logic;
        PIVSYNC             :   in  std_logic;
        PIDisplayEnable     :   in  std_logic;
        PIRAMReadData       :   in  std_logic_vector(11 downto 0);
        PORAMReadAddr       :   out std_logic_vector(16 downto 0);
        PORed               :   out std_logic_vector(7 downto 0);
        POGreen             :   out std_logic_vector(7 downto 0);
        POBlue              :   out std_logic_vector(7 downto 0)
    );

end entity;

architecture Behavioral of RAMReader is
    signal  SVSYNC              :   std_logic                               :=  '0';
    signal  SDisplayEnable      :   std_logic                               :=  '0';
    signal  SRAMReadData        :   std_logic_vector(11 downto 0)           :=  (others => '0');
    signal  SRAMReadAddr        :   std_logic_vector(PORAMReadAddr'range)   :=  (others => '0');
    -- signal  SRed                :   std_logic_vector(7 downto 0)            :=  (others => '0');
    -- signal  SGreen              :   std_logic_vector(7 downto 0)            :=  (others => '0');
    -- signal  SBlue               :   std_logic_vector(7 downto 0)            :=  (others => '0');
begin
    SVSYNC              <=  PIVSYNC;
    SDisplayEnable      <=  PIDisplayEnable;      
    SRAMReadData        <=  PIRAMReadData;
    PORAMReadAddr       <=  SRAMReadAddr;
    -- PORed               <=  SRed;        
    -- POGreen             <=  SGreen;      
    -- POBlue              <=  SBlue;       

    PORed       <=  PIRAMReadData(11 downto 8) & PIRAMReadData(11 downto 8) when SDisplayEnable = '1' 
                    else (others => '0');

    POGreen     <=  PIRAMReadData(7 downto 4) & PIRAMReadData(7 downto 4) when SDisplayEnable = '1' 
                    else (others => '0');

    POBlue      <=  PIRAMReadData(3 downto 0) & SRAMReadData(3 downto 0) when SDisplayEnable = '1' 
                    else (others => '0');


    ADDR_GENERATOR : process (PIClock, PIReset)
    begin
        if (PIReset = '0') then
            SRAMReadAddr    <=  (others => '0');
        elsif rising_edge(PIClock) then
                if SDisplayEnable = '1' then
                    if SRAMReadAddr < 320*240 then
                        SRAMReadAddr    <=  SRAMReadAddr + 1;
                    end if;
                end if;
                if SVSYNC = '0' then
                    SRAMReadAddr    <=  (others => '0');
                end if;

        end if;
    end process;
end architecture;