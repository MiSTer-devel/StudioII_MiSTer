// CRC16-CCITT cartridge profile database.
//
// The profile values are the abstract profile IDs declared by rcastudioii.
// This file deliberately contains no joystick wiring or machine behavior.

function automatic [7:0] studio2_cart_profile_lookup (
	input [15:0] crc,
	input  [3:0] fallback_start_key
);
	begin
		studio2_cart_profile_lookup = {MAP_8WAY, fallback_start_key};
		case (crc)
			// TV Arcade I - Space War
			16'h45B5, 16'h977C:
				studio2_cart_profile_lookup = {MAP_SPACEWAR, 4'd1};

			// Pinball, Speedway + Tag, Star Wars
			16'h03E6, 16'h8404, 16'h92BA, 16'h9505, 16'hD0DA, 16'hD13E,
			16'hD3E2, 16'hE153:
				studio2_cart_profile_lookup = {MAP_CROSS, 4'd1};

			// Fifteen Puzzle, Invasion v1.00, Rocket v1.01
			16'h127F, 16'h13A3, 16'h2DDB, 16'h3244, 16'h9562,
			16'hD2F0, 16'hD481, 16'hF7A3:
				studio2_cart_profile_lookup = {MAP_CROSS, 4'd1};

			// Sports Fan (Baseball & Sumo Wrestling)
			16'h0192, 16'h8D88, 16'hD4A0:
				studio2_cart_profile_lookup = {MAP_CROSS, 4'd0};

			// TV Arcade IV - Baseball
			16'h2526, 16'hF837:
				studio2_cart_profile_lookup = {MAP_BASEBALL, 4'd0};

			// TV Arcade Series - Gunfighter + Moonship Battle
			16'h043E, 16'h3CDC:
				studio2_cart_profile_lookup = {MAP_TENNIS, 4'd1};

			// TV Arcade III - Tennis + Squash
			16'h88FB, 16'hFB76:
				studio2_cart_profile_lookup = {MAP_TENNIS, 4'd1};

			// Game Pack / Grand Pack
			16'h1594, 16'h3505, 16'h74AB, 16'h815E,
			16'hEF21, 16'hFC34, 16'hFC72:
				studio2_cart_profile_lookup = {MAP_DOODLE, 4'd1};

			// Asteroids / Asteroids Visicom
			16'h1943, 16'hFBEF, 16'h1973, 16'h2B4D,
			16'h6EE1, 16'hA008, 16'hAAFB, 16'hE977:
				studio2_cart_profile_lookup = {MAP_HOMEBREW, 4'd5};

			// Berzerk / Berzerk Visicom v1/v2/v3
			16'h4F61, 16'hAEC7, 16'h787D, 16'hE080,
			16'h2E9E, 16'h2143, 16'h21A3, 16'h4771, 16'h7C7D, 16'h73A0:
				studio2_cart_profile_lookup = {MAP_HOMEBREW, 4'd5};

			// Invaders v1/v2/v3 / Invaders Color
			16'h6F69, 16'h7A5E, 16'hADAB, 16'h0D1D, 16'h69AA, 16'h2D86, 16'h5AC5,
			16'h937A, 16'hA9DA, 16'hFB00:
				studio2_cart_profile_lookup = {MAP_HOMEBREW, 4'd0};

			// Kaboom / Kaboom Color
			16'h6793, 16'hDFCF, 16'h8551, 16'h18DB, 16'h08D3, 16'hF42A:
				studio2_cart_profile_lookup = {MAP_HOMEBREW, 4'd0};

			// Pacman / Pacman Visicom
			16'hC556, 16'h5359, 16'hF4A1, 16'hE00A, 16'h9AF1, 16'h62B4, 16'hB99C:
				studio2_cart_profile_lookup = {MAP_HOMEBREW, 4'd0};

			// Scramble / Scramble Color
			16'hBA0B, 16'hE45F, 16'hFAA9, 16'h1280, 16'hD9F3, 16'hD341, 16'hFE3F:
				studio2_cart_profile_lookup = {MAP_HOMEBREW, 4'd6};

			// Combat v1/v2/v3 / Combat Visicom
			16'h4ADA, 16'h188E, 16'hD87F,
			16'h54C7, 16'h4AA2, 16'hABBA, 16'h4009,
			16'hB70E, 16'h650C, 16'hE142, 16'hFD35:
				studio2_cart_profile_lookup = {MAP_HB2P, 4'd1};

			// Hockey v1/v2/v3 / Hockey Visicom v1/v2
			16'h114A, 16'h4F55, 16'hD5DE,
			16'h554B, 16'h1154, 16'hDE71, 16'hD753,
			16'h0D17, 16'hE320, 16'h63E5, 16'h8DD2, 16'hB075:
				studio2_cart_profile_lookup = {MAP_HB2P, 4'd1};

			// Climber v1.00
			16'h1139, 16'hAD6A:
				studio2_cart_profile_lookup = {MAP_CLIMB, 4'd3};

			// Outbreak v1.00
			16'hA83F, 16'hBE58:
				studio2_cart_profile_lookup = {MAP_CLIMB, 4'd0};

			// Space Explorer
			16'h0C03, 16'h92C7:
				studio2_cart_profile_lookup = {MAP_EXPLORER, 4'd1};

			// Keypad-only software
			16'h0ECC, 16'h29B8, 16'h31AE, 16'h3731, 16'h7A43,
			16'h7D85, 16'h9D0D, 16'hAF65, 16'hB2FF, 16'hBBC8,
			16'hBD53, 16'hC8B4, 16'hCEC2, 16'hEE76:
				studio2_cart_profile_lookup = {MAP_NONE, 4'd1};

			// Biorhythm, Visicom Inspiration, Visicom Gambler, Sansu Drill,
			// Space Command, and Q-Sound Test
			16'h12E8, 16'h2BC5, 16'h2F1A, 16'h5433, 16'h8CDE,
			16'h9BCF, 16'h9F6E, 16'hA7DF, 16'hB7A7, 16'hBF97,
			16'hC106, 16'hC7C6, 16'hDA69, 16'hDCFA, 16'hE4C4,
			16'hEBF4, 16'hF178:
				studio2_cart_profile_lookup = {MAP_NONE, 4'd0};

			// RCA Studio II Resident Games
			16'hB5BF:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// Flappy Pixel
			16'h6D1D, 16'hD124:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// Race / Race Colour v1/v2
			16'h47EA, 16'h5374, 16'h5638, 16'h797C,
			16'hD6C0, 16'hFCC8:
				studio2_cart_profile_lookup = {MAP_RACE, 4'd1};

			// Studio II Point of Sale Demonstration Cartridge
			16'hB334, 16'h3EAF:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// Studio II Programming Examples - Move 1/2/3
			16'hD8C2, 16'hFF76, 16'h0856:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// Studio II Programming Examples - Random 1/2, Show Key, Tone
			16'h51A6, 16'h4447, 16'hC78E, 16'hC903:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// Studio II Test Cartridge
			16'h7BB6, 16'h79C5:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// TV Arcade 2012
			16'hE3CF, 16'h4B55:
				studio2_cart_profile_lookup = {MAP_8WAY, 4'd1};

			// Existing recognized no-controller entries
			16'h1634, 16'hB76F:
				studio2_cart_profile_lookup = {MAP_NONE, 4'd15};
		endcase
	end
endfunction
