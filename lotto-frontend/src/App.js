import React, { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import { CONTRACT_ADDR, LOTTO_ABI } from './constants';
import './App.css';

function App() {
  const [account, setAccount] = useState(null);
  const [isOwner, setIsOwner] = useState(false);
  const [selected, setSelected] = useState([]);
  const [poolBalance, setPoolBalance] = useState("0.000");
  const [claimable, setClaimable] = useState("0.00");
  const [winningHistory, setWinningHistory] = useState([]);
  const [currentRound, setCurrentRound] = useState(0);
  const [myTickets, setMyTickets] = useState([]);
  const [unclaimedRounds, setUnclaimedRounds] = useState([]);

  // TIMER STATE
  const [timeLeft, setTimeLeft] = useState(120); // 2 Minute countdown
  const [isCounting, setIsCounting] = useState(false);

  const updateData = useCallback(async () => {
    if (!window.ethereum || !account) return;
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, provider);

      const balance = await provider.getBalance(CONTRACT_ADDR);
      setPoolBalance(ethers.formatEther(balance));
      
      const rid = await contract.roundId();
      setCurrentRound(Number(rid));

      const pending = await contract.pendingWithdrawals(account);
      setClaimable(ethers.formatEther(pending));

      const ownerAddr = await contract.owner();
      setIsOwner(ownerAddr.toLowerCase() === account.toLowerCase());

      // 1. Fetch YOUR tickets for the current round from Blockchain Events
      const tFilter = contract.filters.TicketPurchased(account, rid);
      const tEvents = await contract.queryFilter(tFilter, -10000);
      setMyTickets(tEvents.map(e => e.args.numbers)); 

      // 2. Winning History
      const hFilter = contract.filters.NumbersDrawn();
      const hEvents = await contract.queryFilter(hFilter, -10000);
      setWinningHistory(hEvents.reverse().slice(0, 5).map(e => ({
        round: e.args[0].toString(),
        nums: e.args[1].join(' - ')
      })));

      setUnclaimedRounds(hEvents.slice(0, 3).map(e => Number(e.args[0])));

    } catch (e) { console.error("Sync error", e); }
  }, [account]);

  // TIMER EFFECT
  useEffect(() => {
    let timer;
    if (isCounting && timeLeft > 0) {
      timer = setInterval(() => setTimeLeft(prev => prev - 1), 1000);
    } else if (timeLeft === 0) {
      setIsCounting(false);
    }
    return () => clearInterval(timer);
  }, [isCounting, timeLeft]);

  useEffect(() => { if (account) updateData(); }, [account, updateData]);

  const connectWallet = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts", []);
    setAccount(accounts[0]);
  };

  const playLotto = async () => {
    if (selected.length !== 7) return alert("Select 7 numbers!");
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
      
      const tx = await contract.buyTicket(selected, { value: ethers.parseEther("0.001") });
      await tx.wait();
      
      // Start Timer on first purchase
      if (!isCounting) setIsCounting(true);
      
      setSelected([]); // Clear selection after buy
      updateData();    // Refresh list from blockchain
    } catch (err) { alert("Purchase failed!"); }
  };

  const claimMyPrize = async (rId) => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
    try {
      const tx = await contract.claimPrize(rId);
      await tx.wait();
      updateData();
    } catch (e) { alert("No win or already claimed."); }
  };

  const withdrawFunds = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
    await (await contract.withdraw()).wait();
    updateData();
  };

  if (!account) {
    return (
      <div className="hero-container">
        <h1 className="hero-title">SEQUENTIAL <span className="accent-orange">ETH</span> LOTTO</h1>
        <p className="hero-subtitle">Guess 7 numbers in sequence. Chainlink VRF Powered.</p>
        <div className="landing-info-spread">
          <div className="info-block"><small>PRICE</small><span>0.001 ETH</span></div>
          <div className="info-block"><small>STATUS</small><span>ONLINE</span></div>
        </div>
        <button onClick={connectWallet} className="btn-primary" style={{width: '200px'}}>Connect Wallet</button>
      </div>
    );
  }

  return (
    <div className="dashboard-grid">
      {/* SELECTION PANEL */}
      <div className="selection-board">
        <div className="section-label">NUMBERS / ROUND #{currentRound}</div>
        <div className="lotto-grid">
          {[...Array(49)].map((_, i) => (
            <button key={i+1} onClick={() => {
                if (selected.includes(i+1)) setSelected(selected.filter(n => n !== i+1));
                else if (selected.length < 7) setSelected([...selected, i+1]);
              }} className={`ball ${selected.includes(i+1) ? 'active' : ''}`}>{i+1}</button>
          ))}
        </div>
        <button onClick={playLotto} className="btn-primary full-width" style={{marginTop: '25px'}}>BUY TICKET</button>

        {/* YOUR PICKED NUMBERS - FETCHED FROM BLOCKCHAIN */}
        {myTickets.length > 0 && (
          <div className="my-entries" style={{marginTop: '40px'}}>
            <div className="section-label">YOUR PLAYED NUMBERS</div>
            {myTickets.map((t, idx) => (
              <div key={idx} className="entry-row">
                <span className="accent-orange">#{idx+1}:</span> {t.join(' - ')}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* STATS PANEL */}
      <div className="stats-panel">
        <div className="section-label">LIVE DATA</div>
        <div className="stat-card">
          <small className="section-label">PRIZE POOL</small>
          <span className="stat-value">{poolBalance} ETH</span>
        </div>

        <div className="stat-card">
          <small className="section-label">TIME UNTIL DRAW</small>
          <span className="stat-value timer">
            {Math.floor(timeLeft/60)}:{String(timeLeft%60).padStart(2,'0')}
          </span>
        </div>

        {/* CLAIM SECTION */}
        {unclaimedRounds.length > 0 && (
          <div className="claim-section">
            <div className="section-label">UNCLAIMED ROUNDS</div>
            {unclaimedRounds.map(rId => (
              <div key={rId} className="claim-row">
                <span>R{rId}</span>
                <button onClick={() => claimMyPrize(rId)} className="btn-claim-small">CHECK WIN</button>
              </div>
            ))}
          </div>
        )}

        {Number(claimable) > 0 && (
          <div className="stat-card winner">
            <small className="section-label">CLAIMABLE</small>
            <span className="stat-value">{claimable} ETH</span>
            <button onClick={withdrawFunds} className="btn-withdraw">WITHDRAW</button>
          </div>
        )}
      </div>

      {/* SYSTEM PANEL */}
      <div className="system-space">
        <div className="section-label">SYSTEM</div>
        <div className="system-tag">SEPOLIA TESTNET</div>
        <div className="system-tag">ID: {account.slice(0,6)}...</div>
        {isOwner && (
          <div className="owner-controls">
            <div className="section-label">ADMIN</div>
            <button onClick={() => alert("Run trigger.js in terminal")} className="btn-admin">TRIGGER DRAW</button>
          </div>
        )}
        <button onClick={() => setAccount(null)} className="logout-link">Logout</button>
      </div>
    </div>
  );
}

export default App;
