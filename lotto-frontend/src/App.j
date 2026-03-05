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
  const [ticketsPurchased, setTicketsPurchased] = useState([]);
  const [winningHistory, setWinningHistory] = useState([]);
  const [timeLeft, setTimeLeft] = useState(120);
  const [isCounting, setIsCounting] = useState(false);
  const [roundReady, setRoundReady] = useState(false);

  const updateData = useCallback(async () => {
    if (!window.ethereum || !account) return;
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const balance = await provider.getBalance(CONTRACT_ADDR);
      setPoolBalance(ethers.formatEther(balance));

      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, provider);
      const ownerAddr = await contract.owner();
      setIsOwner(ownerAddr.toLowerCase() === account.toLowerCase());

      const pending = await contract.pendingWithdrawals(account);
      setClaimable(ethers.formatEther(pending));

      const filter = contract.filters.NumbersDrawn();
      const events = await contract.queryFilter(filter, -10000);
      const lastFive = events.reverse().slice(0, 5).map(e => ({
        round: e.args[0].toString(),
        nums: e.args[1].join(' - ')
      }));
      setWinningHistory(lastFive);
    } catch (e) { console.error("Sync error:", e); }
  }, [account]);

  useEffect(() => {
    let timer;
    if (isCounting && timeLeft > 0) {
      timer = setInterval(() => setTimeLeft(prev => prev - 1), 1000);
    } else if (timeLeft === 0 && isCounting) {
      setIsCounting(false);
      setRoundReady(true);
    }
    return () => clearInterval(timer);
  }, [isCounting, timeLeft]);

  useEffect(() => { if (account) updateData(); }, [account, updateData]);

  const connectWallet = async () => {
    if (!window.ethereum) return alert("Please install MetaMask");
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
      setTicketsPurchased([...ticketsPurchased, selected]);
      setSelected([]);
      if (!isCounting && !roundReady) setIsCounting(true);
      updateData();
    } catch (err) { alert("Purchase failed!"); }
  };

  const triggerDraw = async () => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
      const tx = await contract.requestDraw({ gasLimit: 200000 });
      await tx.wait();
      setRoundReady(false);
      setTimeLeft(120);
      setTicketsPurchased([]);
    } catch (e) { alert("Draw failed!"); }
  };

  const withdrawFunds = async () => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
      await (await contract.withdraw()).wait();
      updateData();
    } catch (e) { alert("Withdrawal failed."); }
  };

  
  if (!account) {
    return (
      <div className="hero-container">
        <h1 className="hero-title">
          SEQUENTIAL <span className="accent-orange">ETH</span> LOTTO
        </h1>
        <p className="hero-subtitle">
          A decentralized high-stakes protocol. Guess 7 numbers in sequence to secure the jackpot. 
          Transparent, secure, and powered by Chainlink VRF.
        </p>
        <div className="landing-info-spread">
          <div className="info-block"><span>0.001 ETH</span><small>TICKET PRICE</small></div>
          <div className="info-block"><span>30% JACKPOT</span><small>FULL SEQUENCE</small></div>
          <div className="info-block"><span>5-10% SHARE</span><small>PARTIAL MATCH</small></div>
        </div>
        <button onClick={connectWallet} className="btn-primary">Connect Wallet</button>
      </div>
    );
  }

  return (
    <div className="dashboard-grid">
      
      <div className="selection-board">
        <h2 className="section-label">NUMBERS <span className="accent-orange">SELECTION</span></h2>
        <div className="lotto-grid">
          {[...Array(49)].map((_, i) => (
            <button 
              key={i+1} 
              onClick={() => {
                if (selected.includes(i+1)) setSelected(selected.filter(n => n !== i+1));
                else if (selected.length < 7) setSelected([...selected, i+1]);
              }} 
              className={`ball ${selected.includes(i+1) ? 'active' : ''}`}
            >
              {i+1}
            </button>
          ))}
        </div>
        <button onClick={playLotto} className="btn-primary full-width" style={{marginTop: '20px'}}>
          BUY TICKET
        </button>
        
        {ticketsPurchased.length > 0 && (
          <div className="entries-list">
            <h4>Active Entries</h4>
            {ticketsPurchased.map((t, idx) => (
              <div key={idx} className="entry-row">#{idx+1}: {t.join(' - ')}</div>
            ))}
          </div>
        )}
      </div>

      {/* CENTER: Stats Dashboard (40%) */}
      <div className="stats-panel">
        <h2 className="section-label">LIVE <span className="accent-orange">STATS</span></h2>
        
        <div className="stat-card">
          <small>CURRENT POOL</small>
          <span className="stat-value">{poolBalance} ETH</span>
        </div>

        <div className="stat-card">
          <small>DRAW STATUS</small>
          {isCounting ? (
            <span className="stat-value timer">
              {Math.floor(timeLeft / 60)}:{String(timeLeft % 60).padStart(2, '0')}
            </span>
          ) : (
            <span className="stat-value" style={{color: roundReady ? '#ff4444' : '#444'}}>
              {roundReady ? "LOCKED" : "WAITING"}
            </span>
          )}
        </div>

        {Number(claimable) > 0 && (
          <div className="stat-card winner">
            <small>CLAIMABLE WINNINGS</small>
            <span className="stat-value">{claimable} ETH</span>
            <button onClick={withdrawFunds} className="btn-withdraw">Withdraw Now</button>
          </div>
        )}

        <div className="history-section">
          <h4>WINNING HISTORY</h4>
          {winningHistory.map((h, i) => (
            <div key={i} className="history-row">
              <span>R{h.round}</span>
              <span className="accent-orange">{h.nums}</span>
            </div>
          ))}
        </div>
      </div>

      {/* RIGHT: System/Border Space (20%) */}
      <div className="system-space">
        <div className="system-tag">NETWORK: SEPOLIA</div>
        <div className="system-tag">USER: {account.slice(0,6)}...{account.slice(-4)}</div>
        
        {isOwner && (
          <div className="owner-controls">
            <p>ADMIN TOOLS</p>
            <button onClick={triggerDraw} className="btn-admin">TRIGGER DRAW</button>
          </div>
        )}
        
        <button onClick={() => setAccount(null)} className="logout-link">Disconnect</button>
      </div>

    </div>
  );
}

export default App;
