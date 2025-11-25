# 🔴 RCB – IPL Data Analysis Project  
## SQL-based Data Driven Analytics Project  
**Prepared By: Milin Rao Deshmukh**

## 📌 Project Overview  
This project analyzes the performance of **Royal Challengers Bangalore (RCB)** across multiple IPL seasons using **SQL**.  
The goal is to extract strategic insights about:

- RCB’s season-wise match performance  
- Batting & bowling trends  
- Toss and venue influence  
- Home vs away performance  
- Player-level efficiency  
- Identification of all-rounders, power hitters, and death bowlers  
- Data-backed improvement recommendations  

The analysis reveals why RCB struggles with consistency and has yet to win an IPL trophy despite having strong individual performers.

---

## 📊 Dataset Summary  

This project uses a complete **IPL relational database**, including:

- Ball-by-Ball Data  
- Match & Season Data  
- Player Profiles  
- Wicket Details  
- Extra Run Information  
- Team & Venue Mapping  

### **Key Tables**
- `Ball_by_Ball`  
- `Matches`  
- `Player`  
- `Wicket_Taken`  
- `Extra_Runs`  
- `Player_Match`  
- `Venue`  
- `Season`  
- `Team`  

The schema supports deep analysis across batting, bowling, venues, seasons, and match outcomes.

---

## 🔍 SQL Analysis & Key Insights  

### 1. **RCB Season Performance**
- Plays ~14–16 matches per season  
- Best seasons: **2013 & 2016** (9 wins each)  
- Weak seasons: **2014 & 2015**  
**Insight:** RCB’s biggest issue is *seasonal inconsistency*.  

### 2. **Batting Performance**
- Highest total runs: **2016 (2909 runs)**  
- Lowest: **2014 (2053 runs)**  
**Insight:** Strong batting potential but unstable output.  

### 3. **Bowling Performance**
- Strong wicket-taking years: **2013, 2015, 2016**  
- Poor bowling year: **2014**  
**Insight:** Bowling inconsistencies lead to many losses.  

### 4. **Venue Influence**
- Best venue: **M. Chinnaswamy Stadium (~59% win rate)**  
- Several venues show **0% win rate**  
**Insight:** Venue strongly affects match outcomes.  

### 5. **Home vs Away**
- Home win rate: **56.6%**  
- Away win rate: **43.4%**  
**Insight:** Weak away-game strategies.  

### 6. **Top Batsmen (Strike Rate & Average)**
- Players like **LMP Simmons, V Kohli, DA Warner** lead in metrics  
**Insight:** RCB must acquire consistent high-average scorers.  

### 7. **Top Bowlers (Avg. Wickets)**
- Best wicket-takers: **A Nehra, DJ Bravo, B Kumar**  
**Insight:** RCB lacks stable, impact-performing bowlers.  

### 8. **Best All-Rounders**
- Jadeja, Watson, Russell, Henriques  
**Insight:** Strong all-rounders significantly boost team composition.  

### 9. **Chasing vs Defending**
- Wins while chasing: **16**  
- Wins while defending: **14**  
**Insight:** RCB performs better in chasing scenarios.  

---

## ⚙️ Methodology  

### 1. **SQL-Based Data Exploration**
Executed 100+ SQL queries covering:

- Season performance  
- Batting & bowling analysis  
- Venue influence  
- Toss impact  
- Home vs away comparison  
- Strike rate & economy calculations  
- All-rounder and death-bowler identification  
- Power-hitter evaluation (last 4 seasons)  

### 2. **Statistical Breakdown**
Used SQL functions such as:

- `SUM()`, `AVG()`, `COUNT()`, `ROUND()`  
- `GROUP BY`, `ORDER BY`  
- Multi-table **JOINS**  
- **CTEs** for multi-step logic  
- **Window functions** for ranking  

### 3. **Player Performance Segmentation**
- Top batsmen → runs + strike rate  
- Top bowlers → wickets + average  
- All-rounders → dual contributions  
- Venue specialists  
- Death bowlers → overs ≥ 15  
- Power hitters → high strike rates in recent seasons  

---

## 📈 Summary of Insights  

### 🔥 Batting Insights
- Batting is RCB’s strongest area  
- Heavy dependency on top players  
- Performance drops in low-scoring or tough pitch conditions  

### 🎯 Bowling Insights
- Death bowling is the weakest link  
- Wicket-taking bowlers are limited  
- Bowling economy remains inconsistent  

### 🏟️ Venue Insights
- RCB is strongest at **home**  
- Many away venues show poor win rates  
- Venue-specific planning needed  

### 🎲 Toss & Strategy Insights
- Toss advantage varies by stadium  
- Some grounds favor batting first; others favor fielding  

---

## 💡 Data-Driven Recommendations  
- Strengthen **death bowling** with specialist bowlers  
- Recruit **consistent top-order batsmen**  
- Invest in strong **all-rounders**  
- Use **venue-specific strategies** (bat-first vs chase-first)  
- Improve away-game planning  
- Use high strike-rate players during **powerplay & death overs**  
- Build a balanced squad (accumulators, finishers, spinners, pacers)  
- Prioritize low-economy bowlers in auctions  

---

## 🧾 Final Output  
The project generates detailed SQL outputs for:

- Season-wise RCB performance  
- Batting & bowling trends  
- Venue-wise win/loss ratios  
- Home vs away summaries  
- Chasing vs defending results  
- Top batsmen, bowlers, all-rounders  
- Strike rate, economy, wickets, average rankings  
- High-scoring venue patterns  
- Auction-ready player shortlists  

These insights create a comprehensive analytics framework for evaluating and improving RCB’s IPL performance.

---

## 🛠️ Tech Stack  
- **SQL (MySQL)**  
- Queries involving:  
  - JOINS  
  - CTEs  
  - Window functions  
  - Aggregations  
  - Ranking  
  - Data cleaning (UPDATE statements)  

---

## 🚀 Future Work  
- Build a **Power BI dashboard** for all KPIs  
- Add ML models for **match outcome prediction**  
- Perform player segmentation using clustering  
- Build a **recommendation system** for auction strategy  
- Automate venue-wise & player-wise performance reports  

