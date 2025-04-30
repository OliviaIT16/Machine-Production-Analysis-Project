-- previewing productiometric and quality tables

select *
from BeerBoPrintingProject.productionmetric p 
limit 50;

select *
from BeerBoPrintingProject.quality q
limit 50;

-- checking for null values in both productionmetric and quality tables

select
  SUM(case when prodmetric_stream_key is null then 1 else 0 end) as null_prodmetric_stream_key,
  SUM(case when deviceKey is null then 1 else 0 end) as null_deviceKey,
  SUM(case when start_time is null then 1 else 0 end) as null_start_time,
  SUM(case when end_time is null then 1 else 0 end) as null_end_time,
  SUM(case when good_count is null then 1 else 0 end) as null_good_count,
  SUM(case when reject_count is null then 1 else 0 end) as null_reject_count,
  SUM(case when ideal_time is null then 1 else 0 end) as null_ideal_time,
  SUM(case when run_time is null then 1 else 0 end) as null_run_time,
  SUM(case when unplanned_stop_time is null then 1 else 0 end) as null_unplanned_stop_time,
  SUM(case when planned_stop_time is null then 1 else 0 end) as null_planned_stop_time,
  SUM(case when performance_impact_display_name is null then 1 else 0 end) as null_performance_impact,
  SUM(case when process_state_display_name is null then 1 else 0 end) as null_process_state,
  SUM(case when process_state_reason_display_name is null then 1 else 0 end) as null_process_state_reason,
  SUM(case when job_display_name is null then 1 else 0 end) as null_job_display_name,
  SUM(case when part_display_name is null then 1 else 0 end) as null_part_display_name,
  SUM(case when shift_display_name is null then 1 else 0 end) as null_shift_display_name,
  SUM(case when team_display_name is null then 1 else 0 end) as null_team_display_name
from beerboprintingproject.productionmetric p;

select
	SUM(case when quality_stream_key is null then 1 else 0 end) as null_quality_stream_key,
	SUM(case when deviceKey is null then 1 else 0 end) as null_deviceKey,
	SUM(case when count is null then 1 else 0 end) as null_count,
	SUM(case when reject_reason_display_name is null then 1 else 0 end) as null_reject_reason_display_name,
	SUM(case when prodmetric_stream_key is null then 1 else 0 end) as null_prodmetric_stream_key
from beerboprintingproject.quality q; 

-- 0 nulls were found 
-- checking for duplicates next

select prodmetric_stream_key, count(*)
from beerboprintingproject.productionmetric p 
group by prodmetric_stream_key 
having count(*) > 1;

select quality_stream_key, count(*)
from beerboprintingproject.quality q
group by quality_stream_key 
having count(*) > 1;

-- double checking across all columns for duplicates

select
  deviceKey, start_time, end_time, good_count, reject_count, 
  ideal_time, run_time, unplanned_stop_time, planned_stop_time, 
  performance_impact_display_name, process_state_display_name, 
  process_state_reason_display_name, job_display_name, part_display_name, 
  shift_display_name, team_display_name,
  count(*) as duplicate_count
from beerboprintingproject.productionmetric p 
group by 
  deviceKey, start_time, end_time, good_count, reject_count, 
  ideal_time, run_time, unplanned_stop_time, planned_stop_time, 
  performance_impact_display_name, process_state_display_name, 
  process_state_reason_display_name, job_display_name, part_display_name, 
  shift_display_name, team_display_name
having count(*) > 1;

select
	deviceKey,
	count, 
	reject_reason_display_name,
	prodmetric_stream_key,
	count(*) as duplicate_count
from beerboprintingproject.quality q 
group by 
	deviceKey,
	count,
	reject_reason_display_name,
	prodmetric_stream_key
having count(*) > 1;

-- no duplicates found 
-- checking for inconsistencies in data for the productionmetric table

select 
	good_count, 
	reject_count 
from beerboprintingproject.productionmetric p
where good_count < reject_count;

-- noticed negatives in places where there shouldn't be, but could be corrections or reclassification 

select *
from beerboprintingproject.productionmetric p 
where good_count < 0
or reject_count < 0;

-- checking for incorrect labels 

select unplanned_stop_time, unplanned_stop_time_1 
from beerboprintingproject.productionmetric p 
where unplanned_stop_time != unplanned_stop_time_1;

select *
from beerboprintingproject.productionmetric p 
where unplanned_stop_time > 0
	and (
	performance_impact_display_name != 'Unplanned Stop'
	or process_state_display_name != 'Down'
	or TRIM(process_state_reason_display_name) = ''
	);

-- reverse checking

select *
from beerboprintingproject.productionmetric p 
where performance_impact_display_name = 'Unplanned Stop'
  and unplanned_stop_time = 0;

-- looking for overlaps in time

select 
	a.deviceKey,
	a.start_time as start_a,
	a.end_time as end_a,
	b.start_time as start_b,
	b.end_time as end_b
from beerboprintingproject.productionmetric a
join beerboprintingproject.productionmetric b
	on a.deviceKey = b.deviceKey
	and a.prodmetric_stream_key != b.prodmetric_stream_key
	and a.start_time < b.end_time
	and a.end_time > b.start_time
order by a.deviceKey, a.start_time;

-- finding which prodmetric_stream_keys were overlapping

select 
	a.prodmetric_stream_key as stream_a,
	b.prodmetric_stream_key as stream_b,
	a.deviceKey,
	a.start_time as start_a,
	a.end_time as end_a,
	b.start_time as start_b,
	b.end_time as end_b
from beerboprintingproject.productionmetric a
join beerboprintingproject.productionmetric b
	on a.deviceKey = b.deviceKey
	and a.prodmetric_stream_key != b.prodmetric_stream_key
	and a.start_time < b.end_time
	and a.end_time > b.start_time
order by a.deviceKey, a.start_time;

select 
	a.prodmetric_stream_key as stream_a,
	a.deviceKey,
	a.start_time as start_a,
	a.end_time as end_a,
	b.start_time as start_b,
	b.end_time as end_b
from beerboprintingproject.productionmetric a
join beerboprintingproject.productionmetric b
	on a.deviceKey = b.deviceKey
	and a.prodmetric_stream_key != b.prodmetric_stream_key
	and a.start_time < b.end_time
	and a.end_time > b.start_time
order by a.deviceKey, a.start_time;

-- realized a couple of prodmetric_stream_keys for i.e. 5546811 from Line 2 had an 8 day difference with multiple overlaps during that time
-- could be an data logging error


-- checking quality table 

select *
from beerboprintingproject.quality q 
where reject_reason_display_name = 'xyz';

-- Line 1 is shown as the most common deviceKey with xyz as the reject_reason_display_name 
-- xyz could be a placeholder for missing reason codes 
-- Line 1 (occasionally Line 2) could also be using older software 

-- moving on to joining tables 

select
	p.prodmetric_stream_key,
	p.deviceKey,
	p.reject_count,
	p.good_count,
	q.prodmetric_stream_key,
	q.deviceKey,
	q.count
from beerboprintingproject.productionmetric p 
join beerboprintingproject.quality q
on p.prodmetric_stream_key = q.prodmetric_stream_key 
order by p.prodmetric_stream_key, p.deviceKey;

-- showed quality table's count is the cumulative rejects for each unique prodmetric_stream_key 
-- aggregating the reject reasons for more insight
-- deviceKey for both tables are in different formats but as the prodmetric_stream_key works perfectly fine in both tables, the minor formatting issue with the devicekey will be left alone

select
	q.reject_reason_display_name,
	SUM(q.count) as total_rejects
from beerboprintingproject.quality q
group by q.reject_reason_display_name
order by total_rejects desc; 

-- highest is Detected by Max WIP
-- close second is Reject
-- last is Squished

-- finding deviceKey with highest amount of rejects

select 
	q.deviceKey,
	SUM(q.count) as total_count
from beerboprintingproject.quality q 
group by q.deviceKey
order by total_count desc;

-- Line 4 is the highest with 14,157
-- Line 2 lowest with 7,314

-- checking if there are issues with shifts

select
	prodmetric_stream_key,
	deviceKey,
	shift_display_name,
	team_display_name 
from beerboprintingproject.productionmetric p;

select
	p.shift_display_name,
	p.team_display_name,
	SUM(q.count) as total_rejects
from beerboprintingproject.productionmetric p
join beerboprintingproject.quality q 
on p.prodmetric_stream_key = q.prodmetric_stream_key
group by p.shift_display_name, p.team_display_name
order by total_rejects desc;

-- Second Shift Team 2 had the most rejects 6,228
-- Second Shift No Team least rejects with 9 - could be logging error 

select 
	shift_display_name,
	team_display_name,
	count(*) as total_entries,
	SUM(case when shift_display_name = 'Unknown Shift' then 1 else 0 end) as unknown_shift_count,
	SUM(case when shift_display_name = 'No Shift' then 1 else 0 end) as no_shift_count,
	SUM(case when team_display_name = 'No Team' then 1 else 0 end) as no_team_count,
	SUM(case when team_display_name = 'Unknown Team' then 1 else 0 end) as unknown_team_count
from beerboprintingproject.productionmetric p 
group by shift_display_name, team_display_name
order by total_entries desc;

-- First Shift Unknown Team highest count 70
-- No Shift No Team highest count 57
-- First Shift No Team highest count 33
-- Unknown Shift Unknown Team 16 
-- No Shift Unknown Team 1 - potential error 

-- getting the total unknowns 

select
	count(*) as total_entries,
	SUM(case when team_display_name = 'Unknown Team' then 1 else 0 end) as unknown_team_count,
	SUM(case when shift_display_name = 'Unknown Shift' then 1 else 0 end) as unknown_shift_count
from beerboprintingproject.productionmetric p 
where team_display_name = 'Unknown Team'
or shift_display_name = 'Unknown Shift';

-- 199 unknown team counts of the 199, 16 are unknown_shift_counts

-- combining the No Shift Unknown Team with No Shift No Team 

select
	case 
		when shift_display_name = 'No Shift' then 'No Shift'
		else shift_display_name
	end as cleaned_shift,
	case 
		when shift_display_name = 'No Shift' then 'No Team'
		when team_display_name in ('No Team', 'Unknown Team') then 'No Team'
		else team_display_name
	end as cleaned_team,
	count(*) as total_entries
from beerboprintingproject.productionmetric p 
group by 
	case 
		when shift_display_name = 'No Shift' then 'No Shift'
		else shift_display_name
	end,
	case 
		when shift_display_name = 'No Shift' then 'No Team'
		when team_display_name in ('No Team', 'Unknown Team') then 'No Team'
		else team_display_name
	end
	order by total_entries desc;

-- successfully changed the No Shift Unknown Team to No Shift No Team, total entries changing from 57 to 58















