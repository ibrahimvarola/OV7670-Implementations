library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity OV7670Capture is
    port(
        PIPCLK          :   in  std_logic;
        PIReset         :   in  std_logic;
        PIVSYNC			:   in  std_logic;
        PIHREF          :   in  std_logic;
        PIData          :   in  std_logic_vector(7 downto 0);
        PODataOut       :   out std_logic_vector(11 downto 0);
        PORAMWriteAddr  :   out std_logic_vector(16 downto 0);
        POWriteEnable   :   out std_logic
    );

end OV7670Capture;

architecture Behavioral of OV7670Capture is

    signal  SPCLK               :   std_logic                       :=  '0';
    signal  SReset              :   std_logic                       :=  '0';
    signal	SVSYNC              :   std_logic                       :=  '0';
    signal  SHREF               :   std_logic                       :=  '0';
    signal  SData               :   std_logic_vector(7 downto 0)    :=  (others => '0');
    signal  SDataReg            :   std_logic_vector(7 downto 0)    :=  (others => '0');
    signal  SDataRegister       :   std_logic_vector(15 downto 0)   :=  (others => '0');
    signal  SDataOut            :   std_logic_vector(11 downto 0)   :=  (others => '0');
    signal  SRAMWriteAddr       :   std_logic_vector(16 downto 0)   :=  (others => '0');
    signal  SWriteEnable        :   std_logic                       :=  '0';

    signal  SHREFPrev           :   std_logic                       :=  '0';
    signal  SHRefCounterInt     :   integer range 0 to 4            :=  0;
    signal  SHRefCounter        :   std_logic_vector(6 downto 0)    :=  (others => '0');
    signal  SPixelCounter       :   integer range 0 to 4            :=  0;
    signal  SLineCounterInt     :   integer range 0 to 480          :=  0;
    signal  SLineCounter        :   std_logic_vector(1 downto 0)    :=  (others => '0');


begin 

    PODataOut       <=  SDataOut;  
    PORAMWriteAddr  <=  SRAMWriteAddr;
    POWriteEnable   <=  SWriteEnable;

    SDataOut        <=  SDataRegister(15 downto 12) & SDataRegister(10 downto 7) & SDataRegister(4 downto 1);

    process(PIPCLK, PIReset)
    begin
        if PIReset = '0' then
            SDataRegister   <=  (others => '0');
            SRAMWriteAddr   <=  (others => '0');
            SLineCounter    <=  (others => '0');
            SHRefCounter    <=  (others => '0');
            SLineCounterInt <=  0;
            SHRefCounterInt <=  0;
            SHREFPrev       <=  '0';
            SWriteEnable    <=  '0';
        elsif rising_edge(PIPCLK) then
            SHREFPrev   <=  SHREF;
            SWriteEnable    <=  '0';
            if SVSYNC = '1' then
                SRAMWriteAddr   <=  (others => '0');
                SLineCounter    <=  (others => '0');
                SHRefCounter    <=  (others => '0');
            else
                if SHREF = '1' and SHREFPrev = '0' then
                    if SLineCounterInt < 3 then
                        SLineCounterInt <=  SLineCounterInt + 1;
                    else
                        SLineCounterInt <=  0;
                    end if;
                    
                    case SLineCounter is
                        when "00" =>
                            SLineCounter    <=  "01";
                        when "01" =>
                            SLineCounter    <=  "10";
                        when "10" =>
                            SLineCounter    <=  "11";
                        when others =>
                            SLineCounter    <=  "00";
                    end case;
                end if;
                    
                if SHREF = '1' then
                    SDataRegister   <=  SDataRegister(7 downto 0) & SData;

                    -- if SHRefCounterInt = 3 then
                    --     if SLineCounterInt = 2 or SLineCounterInt = 3 then
                    --         SWriteEnable    <=  '1';
                    --         SRAMWriteAddr   <=  SRAMWriteAddr + 1;
                    --     end if;
                    --     SHRefCounterInt <=  0;
                    -- else
                    --     SHRefCounterInt <=  SHRefCounterInt + 1;
                    -- end if;
                
                    if SHRefCounter(2) = '1' then
                        if SLineCounter(1) = '1' then
                            SWriteEnable    <=  '1';
                            SRAMWriteAddr   <=  SRAMWriteAddr + 1;
                        end if;
                        SHRefCounter    <=  (others => '0');
                    else
                        SHRefCounter    <=  SHRefCounter(SHRefCounter'high - 1 downto 0) & SHREF;
                    end if;
                end if;
                

            end if;
            
        elsif falling_edge(PIPCLK) then
            SData           <=  PIData;
            SVSYNC          <=	PIVSYNC;
            SHREF           <=  PIHREF; 
        end if;

    end process;
end Behavioral;
