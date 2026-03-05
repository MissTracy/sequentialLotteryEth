export const CONTRACT_ADDR = "0xA5290F34c5F4623A918d3adf515680F5c337E435"
export const ORANGE = "#FF8C00";
export const DARK_BG = "#050505";

export const LOTTO_ABI = [
  "function buyTicket(uint8[] _numbers) external payable",
  "function requestDraw() external",
  "function owner() public view returns (address)",
  "function roundId() public view returns (uint256)",
  "function rounds(uint256) public view returns (address[], uint8[], bool, uint256)", 
  "function pendingWithdrawals(address) public view returns (uint256)",
  "function withdraw() external", 
  "event Winner(address indexed player, uint256 amount, uint8 matches)",
  "event NumbersDrawn(uint256 indexed roundId, uint8[] numbers)"
];
