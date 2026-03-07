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
  const [myTickets, setMyTickets] = useState([]); // Array to store multiple tickets
  const [status, setStatus] = useState("SYSTEM ONLINE");

  // Timer
  const [timeLeft, setTimeLeft] = useState(120); 
  const [isCounting, setIsCounting] = useState(false);

  // Data syned from blockchain
  const updateData = useCallback(async () => {
    if (!window.ethereum || !account) return;
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, provider);

      // fetch prize pool
      const balance = await provider.getBalance(CONTRACT_ADDR);
      setPoolBalance(ethers.formatEther(balance));
      
      // fech current round
      const rid = await contract.roundId();
      const currentRid = Number(rid);
      setCurrentRound(currentRid);

      //fetch winnings
      const pending = await contract.pendingWithdrawals(account);
      setClaimable(ethers.formatEther(pending));

      // check adim status
      const ownerAddr = await contract.owner();
      setIsOwner(ownerAddr.toLowerCase() === account.toLowerCase());

      // 5. Check tickerts fro round (Multiple entries check)
      // Filters events TicketPurchased(player, roundId, numbers)
      const ticketFilter = contract.filters.TicketPurchased(account, currentRid);
      const ticketEvents = await contract.queryFilter(ticketFilter, -10000); // Scan last 10k blocks
      const tickets = ticketEvents.map(event => Array.from(event.args.numbers));
      setMyTickets(tickets);

      // fetch winning
      const hFilter = contract.filters.NumbersDrawn();
      const hEvents = await contract.queryFilter(hFilter, -5000);
      setWinningHistory(hEvents.reverse().slice(0, 5).map(e => ({
        round: e.args[0].toString(),
        nums: e.args.numbers.join(' - ')
      })));

    } catch (e) { 
      console.error("Sync error:", e); 
    }
  }, [account]);

  // time logic
  useEffect(() => {
    let timer;
    if (isCounting && timeLeft > 0) {
      timer = setInterval(() => setTimeLeft(prev => prev - 1), 1000);
    } else if (timeLeft === 0) {
      setIsCounting(false);
      setStatus("READY FOR DRAW");
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
    if (selected.length !== 7) return alert("Select exactly 7 numbers!");
    try {
      setStatus("SIGNING TRANSACTION...");
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
      
      const tx = await contract.buyTicket(selected, { value: ethers.parseEther("0.001") });
      await tx.wait();
      
      setStatus("TICKET SECURED");
      if (!isCounting) setIsCounting(true);
      setSelected([]); 
      updateData(); // Refresh list to show new ticket
    } catch (err) { 
      console.error(err);
      setStatus("PURCHASE REJECTED");
    }
  };

  const withdrawFunds = async () => {
    try {
      setStatus("CLAIMING FUNDS...");
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
      const tx = await contract.withdraw();
      await tx.wait();
      setStatus("WITHDRAWAL SUCCESSFUL");
      updateData();
    } catch (e) { 
      setStatus("NO FUNDS TO CLAIM");
    }
  };

  const triggerDraw = async () => {
    try {
      setStatus("CONTACTING ORACLE...");
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDR, LOTTO_ABI, signer);
      const tx = await contract.requestDraw({ gasLimit: 500000 });

      await tx.wait();
      setStatus("DRAW IN PROGRESS...");
    } catch (e) {
      setStatus("ADMIN ACCESS REQUIRED");
    }
  };

  if (!account) {
    return (
      <div className="hero-container">
        <h1 className="hero-title">SEQUENTIAL <span className="accent-orange">ETH</span> LOTTO</h1>
        <p className="hero-subtitle">Guess 7 numbers in sequence. Chainlink VRF 2.5 Powered.</p>
        <div className="landing-info-spread">
          <div className="info-block"><small>ENTRY</small><span>0.001 ETH</span></div>
          <div className="info-block"><small>STATUS</small><span>CONNECTED</span></div>
        </div>
        <button onClick={connectWallet} className="btn-primary" style={{width: '240px'}}>INITIALIZE INTERFACE</button>
      </div>
    );
  }

  return (
    <div className="dashboard-grid">
      {/* SELECTION PANEL */}
      <div className="selection-board">
        <div className="section-label">BALL SELECTION POOL / RD #{currentRound}</div>
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
        <button onClick={playLotto} className="btn-primary" style={{marginTop: '25px', width: '100%'}}>
          PURCHASE TICKET
        </button>

        {/* LIST OF MULTIPLE TICKETS BOUGHT BY USER */}
        {myTickets.length > 0 && (
          <div style={{ marginTop: '35px' }}>
            <div className="section-label">YOUR ENTRIES (CURRENT ROUND)</div>
            {myTickets.map((t, i) => (
              <div key={i} className="system-tag" style={{ borderLeft: '3px solid rgb(255, 95, 9)', paddingLeft: '15px' }}>
                <span className="accent-orange">#{i + 1}</span> — {t.join(' - ')}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* STATS PANEL */}
      <div className="stats-panel">
        <div className="section-label">QUANTUM DATA FEED</div>
        <div className="stat-card">
          <small className="section-label">TOTAL PRIZE POOL</small>
          <span className="stat-value">{poolBalance} ETH</span>
        </div>

        <div className="stat-card">
          <small className="section-label">TIME TO DRAW</small>
          <span className="stat-value timer">
            {Math.floor(timeLeft/60)}:{String(timeLeft%60).padStart(2,'0')}
          </span>
        </div>

        {Number(claimable) > 0 && (
          <div className="stat-card winner" style={{ border: '2px solid rgb(255, 95, 9)' }}>
            <small className="section-label">PENDING WITHDRAWAL</small>
            <span className="stat-value">{claimable} ETH</span>
            <button onClick={withdrawFunds} className="btn-primary" style={{width: '100%', marginTop: '10px'}}>
              CLAIM ETH
            </button>
          </div>
        )}

        <div className="history" style={{marginTop: '30px'}}>
           <div className="section-label">WINNING HISTORY</div>
           {winningHistory.map((h, i) => (
             <div key={i} style={{fontSize: '0.8rem', color: '#666', marginBottom: '8px'}}>
               ROUND {h.round}: <span className="accent-orange">{h.nums}</span>
             </div>
           ))}
        </div>
      </div>

      {/* SYSTEM PANEL */}
      <div className="system-space">
        <div className="section-label">SYSTEM LOGS</div>
        <div className="system-tag">NETWORK: SEPOLIA</div>
        <div className="system-tag">USER: {account.slice(0,6)}...{account.slice(-4)}</div>
        <div className="system-tag">STATUS: <span className="accent-orange">{status}</span></div>
        
        {isOwner && (
          <div className="admin-zone" style={{marginTop: '50px'}}>
            <div className="section-label">ADMIN PROTOCOLS</div>
            <button onClick={triggerDraw} className="btn-admin">TRIGGER DRAW [VRF]</button>
          </div>
        )}
        
        <button onClick={() => setAccount(null)} className="logout-link">TERMINATE SESSION</button>
      </div>
    </div>
  );
}

export default App;
