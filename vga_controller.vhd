----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:15:00 11/07/2025 
-- Design Name: 
-- Module Name:    vga_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:08 11/06/2025 
-- Design Name: 
-- Module Name:    VGA_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
----------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.NUMERIC_STD.ALL;

ENTITY vga_controller  IS
	 PORT (
		 clk                    : IN  STD_LOGIC; --FPGA Board clcok 50MHz
		 DAC_CLK                : OUT STD_LOGIC; --VGA monitor clock 25MHz

		 SW0, SW1, SW2, SW3     : IN  STD_LOGIC; --Switches on FPGA Board
		 -- SW0 --> P1 Down
		 -- SW1 --> P1 up
		 -- SW2 --> P2 Down
		 -- SW3 --> P2 Up

		 H, V                   : OUT STD_LOGIC; --Sync signlas

		 Rout, Gout, Bout  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	 );
END vga_controller ;

ARCHITECTURE Behavior OF vga_controller IS
	 --hor signal lengths
	 CONSTANT HP               : INTEGER := 96 ;
	 CONSTANT HBP              : INTEGER := 48 ;
	 CONSTANT HA               : INTEGER := 640;
	 CONSTANT HFP              : INTEGER := 16 ;

	 --ver signal lengths
	 CONSTANT VP               : INTEGER := 2  ;
	 CONSTANT VBP              : INTEGER := 33 ;
	 CONSTANT VA               : INTEGER := 480;
	 CONSTANT VFP              : INTEGER := 10 ;

	 --static frame lengths
	 CONSTANT border_from_edge : INTEGER := 20 ;
	 CONSTANT border_width     : INTEGER := 30 ; --Acc width is 30-20 = 10
	 CONSTANT goal_width       : INTEGER := 160; --Acc width is 480-160*2 = 160
	 CONSTANT mid_line_width   : INTEGER := 318; --Acc width is 640-318*2 = 4
	 CONSTANT mid_line_length  : INTEGER := 64;
	 CONSTANT mid_line_length_half :INTEGER := mid_line_length/2;

	 --This is how long the static frame will remain static
	 CONSTANT reset_wait       : INTEGER := 320;
	 --This is how long the static frame will remain static
	 CONSTANT lost_wait        : INTEGER := 320;

	 CONSTANT player_length    : INTEGER := 20; --Acc length is 20*2=40
	 CONSTANT player_width     : INTEGER := 5;
	 CONSTANT player_x_frm_goal: INTEGER := 10;

	 CONSTANT ball_size        : INTEGER := 4; --8x8 ball!

	 --How oftne do I want mechaniocs to update?
	 --25,000,000 is one second
	 CONSTANT mechanics_rate   : INTEGER := 390625; -- 64 per sec


	 --STATIC DISPLAY SIGNALS
	 SIGNAL hactive, vactive   : STD_LOGIC := '0';
	 SIGNAL hsync, vsync       : STD_LOGIC := '0';
	 SIGNAL video_active       : STD_LOGIC := '0';

	 --clk and line coutner
	 SIGNAL xcnt, ycnt         : INTEGER   := 1;

	 --DAC_CLK 25 MHz
	 SIGNAL pxl_clk            : STD_LOGIC := '0';

	 SIGNAL r, g, b            : STD_LOGIC := '0';


	 -- GAME FSM SIGNALS
	 SIGNAL state              : INTEGER   := 0; -- 0 --> reset; 1 --> game; 2 --> lost
	 -- Will use this to count; I plan to have the game display be static for reset_wait frames
	 SIGNAL reset_counter      : INTEGER   := 0;
	 -- Will use this to count; I plan to have the game display be static for lost_wait frames
	 SIGNAL lost_counter       : INTEGER   := 0;
	 -- Will use this to count; mechanics update every 1/25MHz * mechanics_rate per sec
	 SIGNAL mechanics_counter  : INTEGER   := 0;
	 SIGNAL mechanics_signal   : STD_LOGIC := '1';


	 -- GAME MECHANICS SIGNALS

	 --Player coordinates
	 SIGNAL p1, p2             : INTEGER   := 240;

	 --ball x,y coordinates and velocities
	 SIGNAL ball_x, ball_y               : INTEGER   := 0;
	 SIGNAL direction_x, direction_y     : STD_LOGIC := '0';
	 -- 0,0 --> left,  up
	 -- 0,1 --> left,  down
	 -- 1,0 --> right, up
	 -- 1,1 --> right, down
	 SIGNAL ball_color                   : INTEGER   := 0;
	 -- 0 --> white
	 -- 1 --> red
	 -- 2 --> blue

	 --Will use this to determine my ball direction 
	 SIGNAL random                     : INTEGER   := 0;


BEGIN

	 --Clk divider
	 PROCESS (clk)
	 BEGIN
		 IF (clk'EVENT AND clk='1') THEN
			 pxl_clk <= NOT pxl_clk;
		 END IF;
	 END PROCESS;


	 -- Synchronize Display

	 --Per clk
	 PROCESS (pxl_clk)
	 BEGIN
		 IF (pxl_clk'EVENT AND pxl_clk='1') THEN
			 xcnt <= xcnt + 1;

			 --Next line
			 IF (xcnt > (HA + HBP + HFP + HP - 1)) THEN
				 xcnt <= 0;
			 END IF;

			 --Set hsync
			 IF (xcnt < HP) THEN
				 hsync <= '0';
			 ELSE
				 hsync <= '1';
			 END IF;

			 --Set hactive
			 IF ((xcnt > (HP + HBP - 1)) AND (xcnt < (HP + HBP + HA))) THEN
				 hactive <= '1';
			 ELSE 
				 hactive <= '0';
			 END IF;
		 END IF;
	 END PROCESS;

	 --Per Line
	 PROCESS (hsync)
	 BEGIN
		 IF (hsync'EVENT AND hsync='0') THEN
			 ycnt <= ycnt + 1;

			 --Next Frame
			 IF (ycnt > (VA + VBP + VFP + VP - 1)) THEN
				 ycnt <= 0;
			 END IF;

			 --Set vsync
			 IF (ycnt < VP) THEN
				 vsync <= '0';
			 ELSE
				 vsync <= '1';
			 END IF;

			 --Set vactive
			 IF ((ycnt > (VP + VBP)) AND (ycnt < (VP + VBP + VA - 1))) THEN
				 vactive <= '1';
			 ELSE 
				 vactive <= '0';
			 END IF;
		 END IF;
	 END PROCESS;

	 --Video enable
	 video_active <= hactive AND vactive;


	 --MECHANICS SIGNAL
	 PROCESS(pxl_clk)
	 BEGIN
		 IF (pxl_clk'EVENT AND pxl_clk='1') THEN
			 mechanics_counter <= mechanics_counter + 1;
			 IF (mechanics_counter = mechanics_rate) THEN
				 mechanics_signal  <= '1';
				 mechanics_counter <= 0;
			 ELSE
				 mechanics_signal <= '0';
			 END IF;
		 END IF;
	 END PROCESS;

	 --Game mechanics elements
	 PROCESS(mechanics_signal, SW0, SW1, SW2, SW3)
	 BEGIN
		 IF (mechanics_signal'EVENT AND mechanics_signal='1') THEN
		 
			 random <= random + 1;
			 IF (random = 4) THEN
				 random <= 0;
			 END IF;
			 
			 IF (state = 0) THEN --reset state
				 reset_counter <= reset_counter + 1;
				 IF (reset_counter = reset_wait) THEN
					 state <= 1;
					 reset_counter <= 0;
					 p1 <= 240;
					 p2 <= 240;
					 ball_x <= 320;
					 ball_y <= 240;
					 ball_color <= 0;
					 IF (random = 0) THEN
						 direction_x <= '1';
						 direction_y <= '0';
					 ELSIF (random = 1) THEN
						 direction_x <= '0';
						 direction_y <= '0';
					 ELSIF (random = 2) THEN
						 direction_x <= '0';
						 direction_y <= '1';
					 ELSE
						 direction_x <= '1';
						 direction_y <= '1';
					 END IF;
				 END IF;
				 
			 ELSIF (state = 1) THEN --Play
				 
				 --p1 movement
				 IF ((SW0 = '1') AND (SW1 = '0')) THEN
					 p1 <= p1+1;
				 ELSIF ((SW0 = '0') AND (SW1 = '1')) THEN
					 p1 <= p1-1;
				 END IF;
				 
				 
				 --p2 movement
				 IF ((SW2 = '1') AND (SW3 = '0')) THEN
					 p2 <= p2+1;
				 ELSIF ((SW2 = '0') AND (SW3 = '1')) THEN
					 p2 <= p2-1;
				 END IF;
				 
				 
				 --Edge conditions
				 
				 IF (p1 < (border_width+player_length+1)) THEN
					 p1 <= border_width+player_length+1;
				 END IF;
				 
				 IF (p2 < (border_width+player_length+1)) THEN
					 p2 <= border_width+player_length+1;
				 END IF;
				 
				 IF (p1 > (VA-(border_width+player_length+1))) THEN
					 p1 <= VA - (border_width+player_length+1);
				 END IF;
				 
				 IF (p2 > (VA-(border_width+player_length+1))) THEN
					 p2 <= VA -(border_width+player_length+1);
				 END IF;
				 
				 
				 -- Ball movement
				 
				 IF (direction_x = '0') THEN
					 ball_x <= ball_x - 1;
				 ELSE
					 ball_x <= ball_x + 1;
				 END IF;
				 
				 IF (direction_y = '0') THEN
					 ball_y <= ball_y - 1;
				 ELSE
					 ball_y <= ball_y + 1;
				 END IF;
				 
				 
				 -- GOAL conditions
				 IF (((ball_y - ball_size) > (goal_width)) AND ((ball_y + ball_size) < (2*goal_width))) THEN
					 --P2 WINS
					 IF (ball_x < border_width) THEN
						 state <= 2;
						 ball_color <= 2;
					 END IF;
					 
					 --P1 WINS
					 IF (ball_x > (HA-border_width)) THEN
						 state <= 2;
						 ball_color <= 1;
					 END IF;
				 END IF;
				 
				 
				 -- Ball Edge Conditions
				 
				 --Left
				 IF (ball_x > (HA-border_width-ball_size-1) AND NOT 
				 (((ball_y - ball_size) > (goal_width)) AND ((ball_y + ball_size) < (2*goal_width)))) THEN
					 direction_x <= '0';
				 END IF;
				 
				 --Up
				 IF (ball_y > (VA-border_width-ball_size-1)) THEN
					 direction_y <= '0';
				 END IF;
				 
				 --Right
				 IF (ball_x < (border_width+ball_size+1)) AND NOT
				 (((ball_y - ball_size) > (goal_width)) AND ((ball_y + ball_size) < (2*goal_width))) THEN
					 direction_x <= '1';
				 END IF;
				 
				 --Down
				 IF (ball_y < (border_width+ball_size+1)) THEN
					 direction_y <= '1';
				 END IF;
				 
				 
				 -- Ball P1 Right Edge
				 IF (direction_x = '0') THEN
					 IF ((ball_x-ball_size) < (border_width+player_x_frm_goal+player_width+1)) THEN
						 IF ((ball_y < (p1+player_length+1)) AND (ball_y > (p1-player_length-1))) THEN
							 direction_x <= '1';
						 END IF;
					 END IF;
				 END IF;
				 
				 --Ball P2 Left edge
				 IF (direction_x = '1') THEN
					 IF ((ball_x+ball_size) > (HA-border_width-player_x_frm_goal-player_width)) THEN
						 IF ((ball_y < (p2+player_length+1)) AND (ball_y > (p2-player_length-1))) THEN
							 direction_x <= '0';
						 END IF;
					 END IF;
				 END IF;
				 
			 ELSE --Lost
				 lost_counter <= lost_counter + 1;
				 
				 IF (direction_x = '0') THEN
					 ball_x <= ball_x - 1;
				 ELSE
					 ball_x <= ball_x + 1;
				 END IF;
				 
				 IF (direction_y = '0') THEN
					 ball_y <= ball_y - 1;
				 ELSE
					 ball_y <= ball_y + 1;
				 END IF;
				 
				 IF (lost_counter = lost_wait) THEN
					 state <= 0;
					 lost_counter <= 0;
					 p1 <= 240;
					 p2 <= 240;
					 ball_x <= 320;
					 ball_y <= 240;
					 ball_color <= 0;
				 END IF;
			 END IF;
		 END IF;
	 END PROCESS;


	 --Game display
	 PROCESS (pxl_clk, video_active, xcnt, ycnt, p1, p2, ball_x, ball_y, ball_color)
	 BEGIN

		 IF (video_active = '1') THEN
			 
			 --Default
			 r <= '0';
			 g <= '1';
			 b <= '0';
			 
			 
			 -- Static elements
			 
			 --Check if within wide vertical boundary
			 IF ((ycnt > (VP+VBP+border_from_edge-1)) AND (ycnt <(VP+VBP+VA-border_from_edge))) THEN
				 --Check if within these narrow ranges to color entire line
				 IF ((ycnt < (VP+VBP+border_width)) OR (ycnt > (VP+VBP+VA-border_width-1))) THEN
					 --Check if within horizontal range
					 IF ((xcnt > (HP+HBP+border_from_edge-1)) AND (xcnt <(HP+HBP+HA-border_from_edge))) THEN
						 r <= '1';
						 g <= '1';
						 b <= '1';
					 END IF;
				 ELSE --Outside narrow boundary
					 --Check if within wide horizontal boundary
					 IF ((xcnt > (HP+HBP+border_from_edge-1)) AND (xcnt <(HP+HBP+HA-border_from_edge))) THEN
						 --Color the thin vertical lines
						 IF ((xcnt < (HP+HBP+border_width)) OR (xcnt > (HP+HBP+HA-border_width+1))) THEN
							 --Leave gap for goal
							 IF ((ycnt < (VP+VBP+goal_width)) OR (ycnt > (VP+VBP+VA-goal_width+1))) THEN
								 r <= '1';
								 g <= '1';
								 b <= '1';
							 END IF;
						 ELSE --Color thin black boundary in the middle
							 IF ((xcnt > (HP+HBP+mid_line_width-1)) AND (xcnt < (HP+HBP+HA-mid_line_width))) THEN
									 IF ((ycnt rem mid_line_length) < mid_line_length_half) THEN
										 r <= '0';
										 g <= '0';
										 b <= '0';
									 END IF;
							 END IF;
						 END IF;
					 END IF;
				 END IF;
			 END IF;
			 
			 
			 --Game mechanics elements
			 
			 --Color P1
			 IF ((xcnt > (HP+HBP+border_width+player_x_frm_goal-1)) AND 
			 (xcnt < (HP+HBP+border_width+player_x_frm_goal+player_width))) THEN
				 --Check Length
				 IF ((ycnt < (VP+VBP+p1+player_length)) AND (ycnt > (VP+VBP+p1-player_length-1))) THEN
					 r <= '1';
					 g <= '0';
					 b <= '0';
				 END IF;
			 END IF;
			 
			 --Color P2
			 IF ((xcnt > (HP+HBP+HA-(border_width+player_x_frm_goal+player_width))) AND 
			 (xcnt < (HP+HBP+HA-(+border_width+player_x_frm_goal-1)))) THEN
				 --Check Length
				 IF ((ycnt < (VP+VBP+p2+player_length)) AND (ycnt > (VP+VBP+p2-player_length-1))) THEN
					 r <= '0';
					 g <= '0';
					 b <= '1';
				 END IF;
			 END IF;
			 
			 --Color ball
			 IF ((xcnt > (HP+HBP+ball_x-ball_size-1)) AND (xcnt < (HP+HBP+ball_x+ball_size))) THEN
				 --Check Length
				 IF ((ycnt > (VP+VBP+ball_y-ball_size-1)) AND (ycnt < (VP+VBP+ball_y+ball_size))) THEN
					 IF (ball_color = 0) THEN
						 r <= '1';
						 g <= '1';
						 b <= '1';
					 ELSIF (ball_color = 1) THEN
						 r <= '1';
						 g <= '0';
						 b <= '0';
					 ELSE
						 r <= '0';
						 g <= '0';
						 b <= '1';
					 END IF;
				 END IF;
			 END IF;
		 
		 ELSE
			 r <= '0';
			 g <= '0';
			 b <= '0';
		 END IF;
	 END PROCESS;


	 --Assign to ouput pins

	 DAC_CLK <= pxl_clk;

	 H       <= hsync;
	 V       <= vsync;

	 Rout    <= (others => r);
	 Gout    <= (others => g);
	 Bout    <= (others => b);
     
END Behavior;