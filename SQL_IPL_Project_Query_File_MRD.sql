
					   -- Objective Questions- -

use ipl;

# Question 1.- Different dtypes of columns in table “ball_by_ball” (using information schema)

select distinct data_type from information_schema.columns
where table_name = 'Ball_by_Ball' and table_schema = 'ipl';


# Question 2.- What is the total number of runs scored in 1st season by RCB (bonus: also include the extra runs using the extra runs table)

with cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,
b.Team_Batting,t.Team_Name as Team_Batting_Name,
b.Team_Bowling,t1.Team_Name as Team_Bowling_Name,
m.Season_Id,(b.Runs_Scored+coalesce(e.Extra_Runs,0)) as Total_Runs_Scored
from Ball_by_Ball b join Team t 
on t.Team_Id=b.Team_Batting
join Team t1 on t1.Team_Id=b.Team_Bowling
join Matches m on m.Match_Id=b.Match_Id
left join Extra_Runs e on e.Match_Id=b.Match_Id and 
e.Over_Id=b.Over_Id and e.Ball_Id=b.Ball_Id and 
e.Innings_No=b.Innings_No
),
cte1 as(
select * from cte where Team_Batting_Name='Royal Challengers Bangalore' and Season_Id=(select min(Season_Id) from cte)
)
select Team_Batting_Name,sum(Total_Runs_Scored) as Total_Runs_Scored_Season_1 from cte1 
group by Team_Batting_Name;

# Question 3.- How many players were more than the age of 25 during season 2014?

with age_table as (
select Player_Id,Player_Name, timestampdiff(year,DOB,'2014-01-01') as age from Player
),
cte as (
select Match_Id,Player_Id from Player_Match where Match_Id in (
		select distinct Match_Id from Matches where Season_Id=(select Season_Id from Season where Season_Year=2014)
		 )
)
select count(distinct c.player_id) as players_above_25
from cte c
join age_table a on c.player_id = a.player_id
where a.age > 25;

# Question 4.-How many matches did RCB win in 2013? 

with cte as (
select m.Match_Id,m.Match_Winner,m.Season_Id,s.Season_Year from Matches m 
join Season s on m.Season_Id=s.Season_Id
where Season_Year=2013
),
cte1 as (select c.Match_Id,c.Season_Year,t.Team_Name from cte c 
join Team t on c.Match_Winner=t.Team_Id
where Team_Name='Royal Challengers Bangalore')
select count(distinct Match_Id) as RCB_WIN from cte1;



# Question 5.- List the top 10 players according to their strike rate in the last 4 seasons

with season_id_lastfouryears as (
 select distinct Season_Id from Season where Season_Year>=(select max(Season_Year)-3 from Season)
),
cte as (
select distinct Match_Id from Matches where Season_Id in ( select Season_Id from season_id_lastfouryears)
),
player_stats as 
(
select Striker,sum(Runs_Scored) as total_runs_scored,count(Ball_Id) as Total_balls_faced
from Ball_by_Ball 
where Match_Id in (select Match_Id from cte)
group by Striker
),
Strike_Rate as 
(select Striker,total_runs_scored,Total_balls_faced, round((total_runs_scored*100/Total_balls_faced),2) as Strike_Rate
from player_stats)

select p.Player_Name,s.total_runs_scored,s.Total_balls_faced,s.Strike_Rate 
from Strike_Rate s join Player p 
on s.Striker=p.Player_Id
order by s.Strike_Rate desc
limit 10;


# Question 6.-What are the average runs scored by each batsman considering all the seasons?

with cte as (
    select 
        p.player_id,
        p.player_name,
        b.runs_scored,
        b.match_id 
    from 
        player p 
    left join 
        ball_by_ball b 
    on 
        p.player_id = b.striker
)
select 
    player_id,
    player_name,
    coalesce(sum(runs_scored), 0) as total_runs,
    count(distinct match_id) as matches_played,
    coalesce(sum(runs_scored) / nullif(count(distinct match_id), 0), 0) as average_runs
from 
    cte
group by 
    player_id, player_name
order by 
    average_runs desc
limit 10;


# Question 7.- What are the average wickets taken by each bowler considering all the seasons?

with bowling_skills as (
select p.Player_Id,p.Player_Name,b.Bowling_skill 
from Player p join Bowling_Style b 
on p.Bowling_skill=b.Bowling_Id
),
cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,
bs.Player_Name as Bowler_Name,bs.Bowling_skill 
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id 
and b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join bowling_skills bs on bs.Player_Id=b.Bowler
),
cte2 as (
SELECT 
    Bowler_Name, 
    Bowling_skill,
    count(distinct Match_Id) as Total_Matches,
    COUNT(*)  AS Total_Wickets_Taken
FROM 
    cte
GROUP BY 
    Bowler_Name, 
    Bowling_skill
ORDER BY 
    Total_Wickets_Taken DESC
)
select Bowler_Name,Bowling_skill,Total_Wickets_Taken,Total_Matches,round((Total_Wickets_Taken)/(Total_Matches),2) as Average_Wickets
from cte2
order by (Total_Wickets_Taken)/(Total_Matches) desc;


# Question 8.- List all the players who have average runs scored greater than the overall average and who have taken wickets greater than the overall average

-- -- -- For Batting -- -- --
 
with cte as (
    select p.player_id , p.player_name , b.runs_scored , b.match_id 
    from player p 
    left join ball_by_ball b 
    on p.player_id = b.striker
),
cte1 as(
select 
    player_id, player_name,
    coalesce(sum(runs_scored), 0) as total_runs,
    count(distinct match_id) as matches_played,
    coalesce(sum(runs_scored) / nullif(count(distinct match_id), 0), 0) as average_runs
from cte
group by player_id, player_name
order by average_runs desc
)
select * from cte1 where 
average_runs>(select avg(average_runs) from cte1);

-- -- -- For Bowling -- -- --

with bowling_skills as (
select p.Player_Id,p.Player_Name,b.Bowling_skill 
from Player p join Bowling_Style b 
on p.Bowling_skill=b.Bowling_Id
),
cte as (
select b.Match_Id , b.Over_Id , b.Ball_Id,b.Innings_No,b.Bowler,
bs.Player_Name as Bowler_Name , bs.Bowling_skill 
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id 
and b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join bowling_skills bs on bs.Player_Id=b.Bowler
),
cte2 as (
select Bowler_Name, Bowling_skill,
    count(distinct Match_Id) as Total_Matches,
    count(*)  AS Total_Wickets_Taken
from cte
Group by Bowler_Name , Bowling_skill
Order by Total_Wickets_Taken DESC
),
cte3 as (
select Bowler_Name,Bowling_skill,Total_Wickets_Taken,Total_Matches,round((Total_Wickets_Taken)/(Total_Matches),2) as Average_Wickets
from cte2
order by (Total_Wickets_Taken)/(Total_Matches) desc
)
select * from cte3 where Average_Wickets>(select avg(Average_Wickets) from cte3);


# Question 9.- Create a table rcb_record table that shows the wins and losses of RCB in an individual venue.

with cte as 
(select m.Match_Id,m.Team_1,t.Team_Name as team1,m.Team_2,t1.Team_Name as team2,m.Match_Winner,t2.Team_Name as winner,m.Venue_Id,v.Venue_Name
from Matches m join Team t on m.Team_1=t.Team_Id
join Team t1 on m.Team_2=t1.Team_Id 
join Team t2 on m.Match_Winner=t2.Team_Id
join Venue v on v.Venue_Id=m.Venue_Id
),
cte1 as 
(select Match_Id,team1,team2,winner,Venue_Name from cte 
where team1='Royal Challengers Bangalore' or team2='Royal Challengers Bangalore'
)

select Venue_Name, count(case when winner='Royal Challengers Bangalore' then 1 end) as win_count,
count(case when winner != 'Royal Challengers Bangalore' then 1 end) as loss_count
from cte1
group by Venue_Name;



# Question 10.- What is the impact of bowling style on wickets taken?

with bowling_skills as (
select p.Player_Id,p.Player_Name,b.Bowling_skill 
from Player p join Bowling_Style b 
on p.Bowling_skill=b.Bowling_Id
),
cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,
bs.Player_Name as Bowler_Name,bs.Bowling_skill 
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id 
and b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join bowling_skills bs on bs.Player_Id=b.Bowler
)
select Bowling_skill,count(*) as Total_Wickets_Taken 
from cte 
group by Bowling_skill
order by count(*) desc;



# Question 11.-	Write the SQL query to provide a status of whether the performance of the team is better than the previous year's performance on the basis of the number of runs scored by the team in the season and the number of wickets taken 

-- -- -- Number of Runs Scored -- -- --

with cte as 
(
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Team_Batting,
(b.Runs_Scored + IFNULL(e.Extra_Runs, 0)) AS Total_Runs
from Ball_by_Ball b left join Extra_Runs e 
on b.Match_Id=e.Match_Id and 
b.Over_Id=e.Over_Id and b.Ball_Id=e.Ball_Id and 
b.Innings_No=e.Innings_No
),
cte1 as (
select c.Match_Id,year(m.Match_Date) as Year,c.Over_Id,c.Ball_Id,c.Innings_No,c.Team_Batting,c.Total_Runs,t.Team_Name 
from cte c join Matches m on c.Match_Id=m.Match_Id 
join Team t on t.Team_Id=c.Team_Batting)
select 
    team_name,
    sum(case when year = 2013 then total_runs else 0 end) as "2013",
    sum(case when year = 2014 then total_runs else 0 end) as "2014",
    sum(case when year = 2015 then total_runs else 0 end) as "2015",
    sum(case when year = 2016 then total_runs else 0 end) as "2016"
from 
    cte1
group by 
    team_name
order by 
    team_name;
    
-- -- --  Number of Wickets Taken Yearwise by each Team -- -- --

with cte as 
(select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,b.Team_Bowling
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id and 
b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No),
cte1 as 
(select c.Match_Id,year(m.Match_Date) as Year,c.Team_Bowling,
t.Team_Name
from cte c join Matches m on c.Match_Id=m.Match_Id 
join Team t on c.Team_Bowling=t.Team_Id
),
cte2 as 
(select Team_Name,Year,count(*) as Total_Wickets_Taken 
from cte1 
group by Team_Name,Year)
select Team_Name,
sum(case when Year=2013 then Total_Wickets_Taken else 0 end) as "2013",
sum(case when Year=2014 then Total_Wickets_Taken else 0 end) as "2014",
sum(case when Year=2015 then Total_Wickets_Taken else 0 end) as "2015",
sum(case when Year=2016 then Total_Wickets_Taken else 0 end) as "2016"
from cte2 
group by Team_Name
order by Team_Name;



# Question 12.- Can you derive more KPIs for the team strategy?
    
-- KPI 1 :- Number of matches played, matches won, and win percentage for each team.

SELECT 
    t.Team_Name, 
    COUNT(m.Match_Id) as Total_Matches,
    sum(case when m.Match_Winner = t.Team_Id then 1 else 0 end) as Total_Wins,
    round((sum(case when m.Match_Winner = t.Team_Id then 1 else 0 end) * 100.0 / count(m.Match_Id)),2) as Win_Percentage
from Matches m
join Team t on m.Team_1 = t.Team_Id or m.Team_2 = t.Team_Id
group by t.Team_Name
order by Win_Percentage desc;

-- KPI 2 :- Players with the highest "Man of the Match" awards.

select 
    p.Player_Name, 
    count(m.Man_of_the_Match) as MOM_Awards
from Matches m
join Player p on m.Man_of_the_Match = p.Player_Id
group by p.Player_Name
order by MOM_Awards desc
limit 10;

-- KPI 3 :- Top 10 player with highest runs scored.

select 
    p.Player_Name, 
    sum(b.Runs_Scored) as Total_Runs
from Ball_by_Ball b
join Player p on b.Striker = p.Player_Id
group by p.Player_Name
order by Total_Runs desc
limit 10;

-- KPI 4 :- Top 10 player with highest wickets taken by each bowler.

select 
    p.Player_Name, 
    count(w.Player_Out) as Total_Wickets
from Wicket_Taken w
join Player p on w.Player_Out = p.Player_Id
group by p.Player_Name
order by Total_Wickets desc
limit 10;

-- KPI 5 :- Toss wins and win percentage after winning the toss for each team.

select 
    t.Team_Name,
    count(m.Match_Id) as Total_Tosses_Won,
    sum(case when m.Toss_Winner = m.Match_Winner then 1 else 0 end) as Wins_After_Toss,
    round((sum(case when m.Toss_Winner = m.Match_Winner then 1 else 0 end) * 100.0 / count(m.Match_Id)),2) as Toss_Win_Percentage
from Matches m
join Team t on m.Toss_Winner = t.Team_Id
group by t.Team_Name
order by Toss_Win_Percentage desc;


# Question 13.-	Using SQL, write a query to find out the average wickets taken by each bowler in each venue. Also, rank the gender according to the average value.

with cte as 
(select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,b.Team_Bowling
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id and 
b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No),
cte1 as 
(select c.Match_Id,year(m.Match_Date) as Year,m.Venue_Id,c.Bowler,c.Team_Bowling,
t.Team_Name
from cte c join Matches m on c.Match_Id=m.Match_Id 
join Team t on c.Team_Bowling=t.Team_Id
),
cte2 as 
(
select c1.Match_Id,c1.Year,c1.Venue_Id,v.Venue_Name,c1.Bowler,p.Player_Name as Bowler_Name,c1.Team_Bowling,c1.Team_Name
from cte1 c1 join Player p on c1.Bowler=p.Player_Id 
join Venue v on v.Venue_Id=c1.Venue_Id
),
cte3 as 
(select 
    cte2.Bowler_Name, 
    cte2.Venue_Name, 
    count(*) as Total_Wickets_Taken, 
    count(distinct cte2.Match_Id) as Matches_Played, 
    cast(count(*) as float) / count(distinct cte2.Match_Id) as Avg_Wickets_Per_Match
from 
    cte2
group by 
    cte2.Bowler_Name, 
    cte2.Venue_Name
order by 
    Avg_Wickets_Per_Match desc
)
select Bowler_Name,Venue_Name,Avg_Wickets_Per_Match,dense_rank() over(order by Avg_Wickets_Per_Match desc) as "Rank"
from cte3
order by Avg_Wickets_Per_Match desc;


# Question 14.-	Which of the given players have consistently performed well in past seasons? (will you use any visualization to solve the problem)

-- -- -- For Batsman -- -- --

	with cte as 
	(select b.Striker,p.Player_Name,b.Runs_Scored,m.Match_Id,m.Venue_Id
	from Ball_by_Ball b join Matches m on b.Match_Id=m.Match_Id
	join Player p on p.Player_Id=b.Striker)

	select Striker as Player_Id,Player_Name,count(distinct Match_Id) as Total_Matches_Played,sum(Runs_Scored) as Total_Runs_Scored,
	sum(Runs_Scored)/count(distinct Match_Id) as Average
	from cte 
	group by Striker,Player_Name
	order by Average desc
	limit 10;
    
-- -- -- For Bowler -- -- --

with cte as (
select b.Match_Id,m.Venue_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler as Player_Id,
p.Player_Name
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id and 
b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join Matches m on m.Match_Id=b.Match_Id
join Player p on p.Player_Id=b.Bowler
)
select Player_Id,Player_Name,count(distinct Match_Id) as Total_Match_Played,
count(*) as Total_Wickets_Taken,
round(count(*) / count(distinct Match_Id),2) as Avrage_Wickets_Taken
from cte 
group by Player_Id,Player_Name
order by Total_Wickets_Taken desc
limit 10;


# Question 15.- Are there players whose performance is more suited to specific venues or conditions? (how would you present this using charts?)

-- -- -- For Batting -- -- --
with cte as 
(select b.Striker,p.Player_Name,b.Runs_Scored,m.Match_Id,m.Venue_Id
from Ball_by_Ball b join Matches m on b.Match_Id=m.Match_Id
join Player p on p.Player_Id=b.Striker),
cte1 as (
select c.Match_Id,c.Venue_Id,v.Venue_Name,c.Striker as Player_Id,c.Player_Name,
c.Runs_Scored  from cte c join Venue v on 
c.Venue_Id=v.Venue_Id)
select Player_Id,Player_Name,Venue_Id,Venue_Name,
count(distinct Match_Id) as Total_Matches_Played,
sum(Runs_Scored) as Total_Runs_Scored,
round(sum(Runs_Scored)/count(distinct Match_Id),2) as Average_Runs_Scored
from cte1 
group by Player_Id,Player_Name,Venue_Id,Venue_Name
order by Average_Runs_Scored desc
limit 10;

-- -- -- For Bowlers -- -- --

with cte as
(
select b.Match_Id,m.Venue_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler as Player_Id,
p.Player_Name
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id and 
b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join Matches m on m.Match_Id=b.Match_Id
join Player p on p.Player_Id=b.Bowler
),
cte1 as 
(select c.Match_Id,c.Venue_Id,v.Venue_Name,c.Over_Id,c.Ball_Id,
c.Innings_No,c.Player_Id,c.Player_Name
from cte c join Venue v 
on c.Venue_Id=v.Venue_Id)
select Player_Id,Player_Name,Venue_Id,Venue_Name,count(distinct Match_Id) as Total_Matches_Played,
count(*) as Total_Wickets_Taken,
round(count(*) / count(distinct Match_Id),2) as Average_Wicket_Taken
from cte1 
group by Player_Id,Player_Name,Venue_Id,Venue_Name
order by Total_Wickets_Taken desc
limit 10;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
				
                -- -- -- Subjective Questions -- -- --

# Question 1.-How does the toss decision affect the result of the match? (which visualizations could be used to present your answer better) And is the impact limited to only specific venues?

with cte as (
SELECT
    m.Match_Id,
    t.Toss_Name AS Toss_Decision,
    m.Match_Winner,
    m.Toss_Winner,
    v.Venue_Name,
    CASE
        WHEN m.Match_Winner = m.Toss_Winner THEN 'Toss Winner Won'
        ELSE 'Toss Winner Lost'
    END AS Toss_Impact
FROM
    Matches m
JOIN Venue v ON m.Venue_Id = v.Venue_Id
JOIN Toss_Decision t ON t.Toss_Id = m.Toss_Decide

),
cte1 as (
select Venue_Name,Toss_Decision,Toss_Impact,count(Match_Id) as Match_Count 
from cte 
group by Venue_Name,Toss_Decision,Toss_Impact
)
select Venue_Name,
sum(case when (Toss_Decision='field' and Toss_Impact='Toss Winner Won') or (Toss_Decision='bat' and Toss_Impact='Toss Winner Lost')
    then Match_Count end) as Field_First_Wins,
sum(case when (Toss_Decision='bat' and Toss_Impact='Toss Winner Won') or (Toss_Decision='field' and Toss_Impact='Toss Winner Lost')
    then Match_Count end) as Bat_First_Wins
from cte1
group by Venue_Name;


# Question 2.-	Suggest some of the players who would be best fit for the team.

-- -- -- For Bowlers -- -- --

with bowling_skills as (
select p.Player_Id,p.Player_Name,b.Bowling_skill 
from Player p join Bowling_Style b 
on p.Bowling_skill=b.Bowling_Id
),
cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,
bs.Player_Name as Bowler_Name,bs.Bowling_skill 
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id 
and b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join bowling_skills bs on bs.Player_Id=b.Bowler
)
SELECT 
    Bowler_Name, 
    Bowling_skill,
    count(distinct Match_Id) as Total_Matches,
    COUNT(*)  AS Total_Wickets_Taken
FROM 
    cte
GROUP BY 
    Bowler_Name, 
    Bowling_skill
ORDER BY 
    Total_Wickets_Taken DESC
    limit 10;
    
-- -- -- For batting -- -- --

with cte as (
    select 
        p.player_id,
        p.player_name,
        b.runs_scored,
        b.match_id 
    from 
        player p 
    left join 
        ball_by_ball b 
    on 
        p.player_id = b.striker
)
select 
    player_id,
    player_name,
    coalesce(sum(runs_scored), 0) as total_runs,
    count(distinct match_id) as matches_played,
    coalesce(sum(runs_scored) / nullif(count(distinct match_id), 0), 0) as average_runs
from 
    cte
group by 
    player_id, player_name
order by 
    average_runs desc
limit 10;


# Question 4.- Which players offer versatility in their skills and can contribute effectively with both bat and ball? (can you visualize the data for the same)

WITH Bowling_Skills AS (
    SELECT p.Player_Id, p.Player_Name, b.Bowling_skill 
    FROM Player p 
    JOIN Bowling_Style b 
    ON p.Bowling_skill = b.Bowling_Id
),
Bowling_Data AS (
    SELECT b.Bowler AS Player_Id, bs.Player_Name, bs.Bowling_skill,
	COUNT(DISTINCT b.Match_Id) AS Total_Matches_Bowled,
	COUNT(*) AS Total_Wickets_Taken
    FROM Ball_by_Ball b
    JOIN Wicket_Taken w 
       ON b.Match_Id = w.Match_Id AND b.Over_Id = w.Over_Id 
       AND b.Ball_Id = w.Ball_Id AND b.Innings_No = w.Innings_No
    JOIN Bowling_Skills bs 
    ON bs.Player_Id = b.Bowler
    GROUP BY b.Bowler, bs.Player_Name, bs.Bowling_skill
),
Batting_Data AS (
    SELECT p.player_id, p.player_name,
	COALESCE(SUM(b.runs_scored), 0) AS Total_Runs,
	COUNT(DISTINCT b.match_id) AS Matches_Played_Batted
    FROM Player p
    LEFT JOIN Ball_by_Ball b 
    ON p.player_id = b.striker
    GROUP BY p.player_id, p.player_name
)
SELECT b.Player_Id, b.Player_Name, b.Total_Wickets_Taken, 
    b.Total_Matches_Bowled, bt.Total_Runs, bt.Matches_Played_Batted
FROM Bowling_Data b
JOIN Batting_Data bt 
ON b.Player_Id = bt.player_id
WHERE b.Total_Wickets_Taken > 10 AND bt.Total_Runs > 500     
ORDER BY b.Total_Wickets_Taken DESC, 
bt.Total_Runs DESC;



# Question 5.- Are there players whose presence positively influences the morale and performance of the team? (justify your answer using visualization)

-- -- -- Top 3 Batsman -- -- --


with cte as (
    select 
        p.player_id, p.player_name, b.runs_scored, b.match_id 
    from player p 
    left join ball_by_ball b 
    on p.player_id = b.striker
)
select 
    player_id, player_name,
    coalesce(sum(runs_scored), 0) as total_runs,
    count(distinct match_id) as matches_played,
    coalesce(sum(runs_scored) / nullif(count(distinct match_id), 0), 0) as average_runs
from cte
group by player_id, player_name
order by average_runs desc
limit 3;


-- -- -- Top 3 Bowlers -- -- --

with bowling_skills as (
select p.Player_Id,p.Player_Name,b.Bowling_skill 
from Player p join Bowling_Style b 
on p.Bowling_skill=b.Bowling_Id
),
cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,
bs.Player_Name as Bowler_Name,bs.Bowling_skill 
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id 
and b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No
join bowling_skills bs on bs.Player_Id=b.Bowler
)
SELECT 
    Bowler_Name, Bowling_skill,
    count(distinct Match_Id) as Total_Matches,
    COUNT(*)  AS Total_Wickets_Taken
FROM cte
GROUP BY Bowler_Name, Bowling_skill
ORDER BY Total_Wickets_Taken DESC
limit 3;
    
-- -- -- Top 3 All Rounders -- -- --

WITH Bowling_Skills AS (
    SELECT p.Player_Id, p.Player_Name, b.Bowling_skill 
    FROM Player p 
    JOIN Bowling_Style b 
    ON p.Bowling_skill = b.Bowling_Id
),
Bowling_Data AS (
    SELECT 
        b.Bowler AS Player_Id, bs.Player_Name, bs.Bowling_skill,
        COUNT(DISTINCT b.Match_Id) AS Total_Matches_Bowled,
        COUNT(*) AS Total_Wickets_Taken
    FROM Ball_by_Ball b
    JOIN Wicket_Taken w 
        ON b.Match_Id = w.Match_Id AND b.Over_Id = w.Over_Id 
       AND b.Ball_Id = w.Ball_Id AND b.Innings_No = w.Innings_No
    JOIN Bowling_Skills bs 
    ON bs.Player_Id = b.Bowler
    GROUP BY b.Bowler, bs.Player_Name, bs.Bowling_skill
),
Batting_Data AS (
    SELECT p.player_id, p.player_name,
        COALESCE(SUM(b.runs_scored), 0) AS Total_Runs,
        COUNT(DISTINCT b.match_id) AS Matches_Played_Batted
    FROM Player p
    LEFT JOIN Ball_by_Ball b 
    ON p.player_id = b.striker
    GROUP BY p.player_id, p.player_name
)
SELECT 
    b.Player_Id, b.Player_Name, b.Total_Wickets_Taken, 
    b.Total_Matches_Bowled, bt.Total_Runs, bt.Matches_Played_Batted
FROM Bowling_Data b
JOIN Batting_Data bt 
ON b.Player_Id = bt.player_id
WHERE b.Total_Wickets_Taken > 10 AND bt.Total_Runs > 500     
ORDER BY b.Total_Wickets_Taken DESC, bt.Total_Runs DESC
limit 3;



# Question 6.- What would you suggest to RCB before going to the mega auction? 

-- -- -- Top 10 All Rounders -- -- --

WITH Bowling_Skills AS (
    SELECT p.Player_Id, p.Player_Name, b.Bowling_skill 
    FROM Player p 
    JOIN Bowling_Style b 
    ON p.Bowling_skill = b.Bowling_Id
),
Bowling_Data AS (
    SELECT 
        b.Bowler AS Player_Id, bs.Player_Name, bs.Bowling_skill,
        COUNT(DISTINCT b.Match_Id) AS Total_Matches_Bowled,
        COUNT(*) AS Total_Wickets_Taken
    FROM Ball_by_Ball b
    JOIN Wicket_Taken w 
        ON b.Match_Id = w.Match_Id AND b.Over_Id = w.Over_Id 
       AND b.Ball_Id = w.Ball_Id AND b.Innings_No = w.Innings_No
    JOIN Bowling_Skills bs 
    ON bs.Player_Id = b.Bowler
    GROUP BY b.Bowler, bs.Player_Name, bs.Bowling_skill
),
Batting_Data AS (
    SELECT 
        p.player_id, p.player_name,
        COALESCE(SUM(b.runs_scored), 0) AS Total_Runs,
        COUNT(DISTINCT b.match_id) AS Matches_Played_Batted
    FROM Player p
    LEFT JOIN Ball_by_Ball b 
    ON p.player_id = b.striker
    GROUP BY p.player_id, p.player_name
)
SELECT 
    b.Player_Id, b.Player_Name, b.Total_Wickets_Taken, 
    b.Total_Matches_Bowled, bt.Total_Runs, 
    bt.Matches_Played_Batted
FROM Bowling_Data b
JOIN Batting_Data bt 
ON b.Player_Id = bt.player_id
WHERE b.Total_Wickets_Taken > 10 AND bt.Total_Runs > 500     
ORDER BY b.Total_Wickets_Taken DESC, bt.Total_Runs DESC;
    
-- -- -- death bowlers -- -- --

with cte as(
   select b.Bowler,b.Over_Id,b.Ball_Id,b.Innings_No,b.Match_Id,(b.Runs_Scored+coalesce(e.Extra_Runs,0)) as Total_Runs_Scored
   from Ball_by_Ball b left join Extra_Runs e 
   on b.Match_Id=e.Match_Id and b.Over_Id=e.Over_Id and b.Ball_Id=e.Ball_Id 
   and b.Innings_No=e.Innings_No
   ),
   last_five_overs as (select * from cte where Over_Id>=15),
  bowler_stats AS (
    SELECT Bowler, SUM(Total_Runs_Scored) AS Total_Runs,
	COUNT(*) AS Total_Balls
    FROM last_five_overs
    WHERE Total_Runs_Scored IS NOT NULL
    GROUP BY Bowler
),
economy as (
SELECT Bowler,Total_Runs,
    round(Total_Balls / 6.0,2) AS Overs_Bowled,
    round(Total_Runs / (Total_Balls / 6.0),2) AS Economy_Rate
FROM bowler_stats
),
cte1 as(select * from economy where Overs_Bowled>10 order by Economy_Rate limit 10)
select c.Bowler,p.Player_Name,c.Economy_Rate
from cte1 c join Player p on c.Bowler=p.Player_Id;

-- -- -- Power Hitters -- -- --

with season_id_lastfouryears as (
 select distinct Season_Id from Season where Season_Year>=(select max(Season_Year)-3 from Season)
),
cte as (select distinct Match_Id from Matches where Season_Id in 
( select Season_Id from season_id_lastfouryears)),
player_stats as 
(select Striker,sum(Runs_Scored) as total_runs_scored,count(Ball_Id) as Total_balls_faced
from Ball_by_Ball 
where Match_Id in (select Match_Id from cte)
group by Striker),
Strike_Rate as 
(select Striker,total_runs_scored,Total_balls_faced, round((total_runs_scored*100/Total_balls_faced),2) as Strike_Rate
from player_stats)
select p.Player_Name,s.total_runs_scored,s.Total_balls_faced,s.Strike_Rate 
from Strike_Rate s join Player p 
on s.Striker=p.Player_Id
order by s.Strike_Rate desc
limit 10;
   

# Question 7.-	What do you think could be the factors contributing to the high-scoring matches and the impact on viewership and team strategies Venue Affect

with cte as(
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,
(b.Runs_Scored+coalesce(e.Extra_Runs,0)) as Total_Runs_Scored
from Ball_by_Ball b left join Extra_Runs e 
on b.Match_Id=e.Match_Id and b.Over_Id=e.Over_Id and b.Ball_Id=e.Ball_Id
and b.Innings_No=e.Innings_No
),
cte1 as(
select Match_Id,Innings_No,sum(Total_Runs_Scored) as Total_Runs_Scored
from cte
group by Match_Id,Innings_No
),
cte2 as (
select c1.Match_Id,c1.Innings_No,c1.Total_Runs_Scored,
m.Venue_Id
from cte1 c1 join Matches m 
on c1.Match_Id=m.Match_Id
),
cte3 as(
select Venue_Id,Innings_No,round(avg(Total_Runs_Scored),2) as Avg_Runs_Scored
from cte2
group by Venue_Id,Innings_No
),
cte4 as(
select Venue_Id,
avg(case when Innings_No=1 then Avg_Runs_Scored end) as First_Inning_Avg_Score,
avg(case when Innings_No=2 then Avg_Runs_Scored end) as Second_Inning_Avg_Score
from cte3 
group by Venue_Id
)
select c4.Venue_Id,v.Venue_Name,c4.First_Inning_Avg_Score,
c4.Second_Inning_Avg_Score
from cte4 c4 join Venue v 
on c4.Venue_Id=v.Venue_Id;

-- -- -- Players with Highest Runs -- -- --

with cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Striker,
b.Runs_Scored 
from Ball_by_Ball b
),
cte1 as (
select Striker,sum(Runs_Scored) as Total_Runs_Scored,
count(distinct Match_Id) as Total_Matches_Played,
sum(Runs_Scored)/count(distinct Match_Id) as Avg_Runs
from cte
group by Striker
order by Avg_Runs desc
limit 10
)
select c1.Striker,p.Player_Name as Striker_Name,c1.Avg_Runs
from cte1 c1 join Player p 
on c1.Striker=p.Player_Id;

-- -- -- Players with highest Strike Rates -- -- --

with cte as (
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Striker,
b.Runs_Scored 
from Ball_by_Ball b
),
cte1 as (
select Striker,sum(Runs_Scored) as Total_Runs_Scored,
count(Ball_Id) as Total_Balls_Played,
sum(Runs_Scored)*100/count(Ball_Id) as Strike_Rate
from cte
group by Striker
order by Strike_Rate desc
limit 10
)
select c1.Striker,p.Player_Name as Striker_Name,c1.Strike_Rate
from cte1 c1 join Player p 
on c1.Striker=p.Player_Id;


# Question 8.- Analyze the impact of home-ground advantage on team performance and identify strategies to maximize this advantage for RCB.

with cte as (
select m.Match_Id,m.Team_1,t1.Team_Name as Team_1_Name,m.Team_2,t2.Team_Name as Team_2_Name,
m.Match_Winner,t3.Team_Name as Match_Winner_Name,m.Venue_Id,v.Venue_Name,m.Season_Id,
s.Season_Year
from Matches m join Team t1 on m.Team_1=t1.Team_Id
join Team t2 on m.Team_2=t2.Team_Id
join Team t3 on m.Match_Winner=t3.Team_Id
join Venue v on v.Venue_Id=m.Venue_Id
join Season s on s.Season_Id=m.Season_Id
),
RCB_Chinnaswamy AS (
    SELECT Match_Id, Venue_Name, Team_1_Name, Team_2_Name, Match_Winner_Name
    FROM cte
    WHERE Venue_Name = 'M Chinnaswamy Stadium' 
        AND (Team_1_Name = 'Royal Challengers Bangalore' OR Team_2_Name = 'Royal Challengers Bangalore')
)
SELECT 
    'Royal Challengers Bangalore' AS Team_Name,
    COUNT(*) AS Total_Matches_Played_At_Chinnaswamy,
    SUM(CASE WHEN Match_Winner_Name = 'Royal Challengers Bangalore' THEN 1 ELSE 0 END) AS Total_Wins_At_Chinnaswamy
FROM RCB_Chinnaswamy;



# Question 9.- Come up with a visual and analytical analysis of the RCB's past season's performance and potential reasons for them not winning a trophy. Past years performance by RCB

with cte as(
select m.Match_Id,m.Team_1,t1.Team_Name as Team_1_Name,m.Team_2,t2.Team_Name as Team_2_Name,
m.Match_Winner,t3.Team_Name as Match_Winner_Name,m.Venue_Id,v.Venue_Name,m.Season_Id,
s.Season_Year
from Matches m join Team t1 on m.Team_1=t1.Team_Id
join Team t2 on m.Team_2=t2.Team_Id
join Team t3 on m.Match_Winner=t3.Team_Id
join Venue v on v.Venue_Id=m.Venue_Id
join Season s on s.Season_Id=m.Season_Id
)
select Season_Id,Season_Year, count(*) as Total_Matches_Played_By_RCB,  
sum(case when Match_Winner_Name='Royal Challengers Bangalore' then 1 end) as Total_Matches_Won_By_RCB
from cte
where Team_1_Name='Royal Challengers Bangalore' or Team_2_Name='Royal Challengers Bangalore'
group by Season_Id,Season_Year
order by Season_Year;

-- -- -- Number of Runs Scored Yearwise by RCB -- -- --

with cte as 
(
select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Team_Batting,
(b.Runs_Scored + IFNULL(e.Extra_Runs, 0)) AS Total_Runs
from Ball_by_Ball b left join Extra_Runs e 
on b.Match_Id=e.Match_Id and 
b.Over_Id=e.Over_Id and b.Ball_Id=e.Ball_Id and 
b.Innings_No=e.Innings_No
),
cte1 as (
select c.Match_Id,year(m.Match_Date) as Year,c.Over_Id,c.Ball_Id,c.Innings_No,c.Team_Batting,c.Total_Runs,t.Team_Name 
from cte c join Matches m on c.Match_Id=m.Match_Id 
join Team t on t.Team_Id=c.Team_Batting),
cte2 as (
select 
    team_name,
    sum(case when year = 2013 then total_runs else 0 end) as "2013",
    sum(case when year = 2014 then total_runs else 0 end) as "2014",
    sum(case when year = 2015 then total_runs else 0 end) as "2015",
    sum(case when year = 2016 then total_runs else 0 end) as "2016"
from cte1
group by team_name
order by team_name
)
select * from cte2 where team_name="Royal Challengers Bangalore";

-- -- -- Number of Wickets Taken Yearwise by RCB -- -- --

with cte as 
(select b.Match_Id,b.Over_Id,b.Ball_Id,b.Innings_No,b.Bowler,b.Team_Bowling
from Ball_by_Ball b join Wicket_Taken w 
on b.Match_Id=w.Match_Id and b.Over_Id=w.Over_Id and 
b.Ball_Id=w.Ball_Id and b.Innings_No=w.Innings_No),
cte1 as 
(select c.Match_Id,year(m.Match_Date) as Year,c.Team_Bowling,
t.Team_Name
from cte c join Matches m on c.Match_Id=m.Match_Id 
join Team t on c.Team_Bowling=t.Team_Id
),
cte2 as 
(select Team_Name,Year,count(*) as Total_Wickets_Taken 
from cte1 
group by Team_Name,Year),
cte3 as (
select Team_Name,
sum(case when Year=2013 then Total_Wickets_Taken else 0 end) as "2013",
sum(case when Year=2014 then Total_Wickets_Taken else 0 end) as "2014",
sum(case when Year=2015 then Total_Wickets_Taken else 0 end) as "2015",
sum(case when Year=2016 then Total_Wickets_Taken else 0 end) as "2016"
from cte2 
group by Team_Name
order by Team_Name
)
select * from cte3 where Team_Name="Royal Challengers Bangalore";

-- -- -- venuewise performance for RCB -- -- --

with cte as(
select m.Match_Id,m.Team_1,t1.Team_Name as Team_1_Name,m.Team_2,t2.Team_Name as Team_2_Name,
m.Match_Winner,t3.Team_Name as Match_Winner_Name,m.Venue_Id,v.Venue_Name,m.Season_Id,
s.Season_Year
from Matches m join Team t1 on m.Team_1=t1.Team_Id
join Team t2 on m.Team_2=t2.Team_Id
join Team t3 on m.Match_Winner=t3.Team_Id
join Venue v on v.Venue_Id=m.Venue_Id
join Season s on s.Season_Id=m.Season_Id
),
cte1 as(
select Venue_Id,Venue_Name,count(Match_Id) as Total_Matches_Played,
coalesce(sum(case when Match_Winner_Name='Royal Challengers Bangalore' then 1 end),0) as Total_Matches_Won_By_RCB,
coalesce(sum(case when Match_Winner_Name!='Royal Challengers Bangalore' then 1 end),0) as Total_Matches_Lost_By_RCB
from cte 
where Team_1_Name='Royal Challengers Bangalore' or Team_2_Name='Royal Challengers Bangalore'
group by Venue_Id,Venue_Name
)
select Venue_Id,Venue_Name,Total_Matches_Played,Total_Matches_Won_By_RCB,Total_Matches_Lost_By_RCB,
round(Total_Matches_Won_By_RCB*100/Total_Matches_Played,2) as Win_Percentage
from cte1
order by Venue_Id;

-- -- -- home/away performance -- -- --

WITH cte AS (
    SELECT m.Match_Id, m.Team_1, t1.Team_Name AS Team_1_Name, m.Team_2, 
        t2.Team_Name AS Team_2_Name,m.Match_Winner, 
        t3.Team_Name AS Match_Winner_Name, m.Venue_Id, v.Venue_Name, 
        m.Season_Id, s.Season_Year
    FROM Matches m 
    JOIN Team t1 ON m.Team_1 = t1.Team_Id
    JOIN Team t2 ON m.Team_2 = t2.Team_Id
    JOIN Team t3 ON m.Match_Winner = t3.Team_Id
    JOIN Venue v ON v.Venue_Id = m.Venue_Id
    JOIN Season s ON s.Season_Id = m.Season_Id
),
cte_summary AS (
    SELECT 
    CASE 
            WHEN Venue_Name = 'M Chinnaswamy Stadium' THEN 'Home'
            ELSE 'Away'
        END AS Location_Type,
        COUNT(Match_Id) AS Total_Matches_Played,
        COALESCE(SUM(CASE WHEN Match_Winner_Name = 'Royal Challengers Bangalore' THEN 1 ELSE 0 END), 0) AS Total_Wins,
        COALESCE(SUM(CASE WHEN Match_Winner_Name != 'Royal Challengers Bangalore' THEN 1 ELSE 0 END), 0) AS Total_Losses
    FROM cte 
    WHERE Team_1_Name = 'Royal Challengers Bangalore' OR Team_2_Name = 'Royal Challengers Bangalore'
    GROUP BY 
        CASE 
            WHEN Venue_Name ='M Chinnaswamy Stadium' THEN 'Home'
            ELSE 'Away'
        END
),
final_summary AS (
    SELECT 
        Location_Type, 
        SUM(Total_Matches_Played) AS Total_Matches,
        SUM(Total_Wins) AS Total_Wins,
        SUM(Total_Losses) AS Total_Losses,
        ROUND(SUM(Total_Wins) * 100.0 / SUM(Total_Matches_Played), 2) AS Win_Percentage
    FROM cte_summary
    GROUP BY Location_Type
)
SELECT * FROM final_summary;

-- -- -- chasing/defending -- -- --

with cte as (
select m.Match_Id,m.Team_1,t.Team_Name as Team1_Name,m.Team_2,t1.Team_Name as Team2_Name,m.Match_Winner,t2.Team_Name as Match_Winner_Name,
w.Win_Type
from Matches m join Win_By w 
on m.Win_Type=w.Win_Id
join Team t on t.Team_Id=m.Team_1
join Team t1 on t1.Team_Id=m.Team_2
join Team t2 on t2.Team_Id=m.Match_Winner
),
cte1 as(
select Match_Id,Team1_Name,Team2_Name,Match_Winner_Name,Win_Type
from cte where Team1_Name='Royal Challengers Bangalore' or Team2_Name='Royal Challengers Bangalore'
)
select "RCB" as Team_Name,count(case when Match_Winner_Name='Royal Challengers Bangalore' then Match_Id end) as Total_Wins, 
count(case when Match_Winner_Name='Royal Challengers Bangalore' and Win_Type='runs' then Match_Id end) as Total_Wins_Defending,
count(case when Match_Winner_Name='Royal Challengers Bangalore' and Win_Type='wickets' then Match_Id end) as Total_Wins_Chasing,
count(case when Match_Winner_Name='Royal Challengers Bangalore' and Win_Type='Tie' then Match_Id end) as Total_Wins_Tie
from cte1;

# Question 10.- Solution for this question is in documnts file, because it's a theory question

# Question 11.- In the "Match" table, some entries in the "Opponent_Team" column are incorrectly spelled as "Delhi_Capitals" instead of "Delhi_Daredevils". Write an SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".

UPDATE Matches SET Opponent_Team = 'Delhi_Daredevils'  WHERE Opponent_Team = 'Delhi_Capitals';
