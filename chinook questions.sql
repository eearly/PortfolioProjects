--1) Find the artist who has contributed with the maximum no of albums. Display the artist name and the no of albums.

select art.name, count(alb.artistid) as no_of_albums
from artist art
join album alb on art.artistid = alb.artistid
group by art.name
order by no_of_albums desc limit 1

-- 2nd option
with temp as
    (select alb.artistid
    , count(1) as no_of_albums
    , rank() over(order by count(1) desc) as rnk
    from Album alb
    group by alb.artistid)
select art.name as artist_name, t.no_of_albums
from temp t
join artist art on art.artistid = t.artistid
where rnk = 1;

--2) Display the name, email id, country of all listeners who love Jazz, Rock and Pop music.

select concat(firstname,' ',lastname) as name, cust.email, cust.country
from customer cust
join invoice inv on cust.customerid = inv.customerid
join invoiceline invl on inv.invoiceid = invl.invoiceid
join track tra on invl.trackid = tra.trackid 
join genre gen on tra.genreid = gen.genreid
where gen.genreid in (1, 2, 9)
group by concat(firstname,' ',lastname), cust.email, cust.country

--3) Find the employee who has supported the most no of customers. Display the employee name and designation
with custsup as 
		(select concat(emp.firstname, ' ', emp.lastname) as employee_name, title, count(cust.supportrepid) as no_cust_supported
		from employee emp
		join customer cust on emp.employeeid = cust.supportrepid
		group by concat(emp.firstname, ' ', emp.lastname), title)
select employee_name, title as designation
from custsup
where no_cust_supported	= (select max(no_cust_supported)from custsup)

-- 2nd option
select employee_name, title as designation
from (
    select (e.firstname||' '||e.lastname) as employee_name, e.title
    , count(1) as no_of_customers
    , rank() over(order by count(1) desc) as rnk
    from Customer c
    join employee e on e.employeeid=c.supportrepid
    group by e.firstname,e.lastname, e.title) x
where x.rnk=1;
		
--4) Which city corresponds to the best customers? 

with bestcust as 
	(select billingcity as city, sum(total) as total_bought
	from invoice
	group by city
	)
select city
from bestcust
where total_bought = (select max(total_bought) from bestcust)


--5) The highest number of invoices belongs to which country?

with invbill as 
	(select billingcountry as country, count(invoiceid) as no_of_invoices
	from invoice
	group by billingcountry)
select country
from invbill
where  no_of_invoices = (select max(no_of_invoices) from invbill)

--6) Name the best customer (customer who spent the most money). 

with bestcust as
	(select concat(cust.firstname,' ',cust.lastname) as customer_name, sum(unitprice) as money_spent 
	from customer cust
	join invoice inv on cust.customerid = inv.customerid
	join invoiceline invl on inv.invoiceid = invl.invoiceid
	group by concat(firstname,' ',lastname))
select customer_name
from bestcust
where money_spent = (select max(money_spent) from bestcust)

--7) Suppose you want to host a rock concert in a city and want to know which location should host it.

select inv.billingcity, count(inv.billingcity) as pop_with_rock
from invoice inv 
join invoiceline invl on inv.invoiceid = invl.invoiceid
join track tra on invl.trackid = tra.trackid 
join genre gen on tra.genreid = gen.genreid
where gen.genreid = 1 
group by inv.billingcity
order by count(inv.billingcity) desc

--8) Identify all the albums who have less then 5 track under them.
    --Display the album name, artist name and the no of tracks in the respective album

select alb.title as album_name, tra.composer as artist_name, count(tra.albumid) as no_of_tracks
from album alb
join track tra on alb.albumid = tra.albumid
group by alb.title, tra.composer
having count(tra.albumid) < 5


--9) Display the track, album, artist and the genre for all tracks which are not purchased.

with purchased as 
		(select tra.name as name, alb.title as album, tra.composer as artist, gen.name as genre
		from album alb
		join track tra on alb.albumid = tra.albumid
		join genre gen on tra.genreid = gen.genreid
		join invoiceline invl on tra.trackid = invl.trackid) 
select tra.name as name, alb.title as album, tra.composer as artist, gen.name as genre
from album alb
left join track tra on alb.albumid = tra.albumid
left join genre gen on tra.genreid = gen.genreid
where tra.name not in (select name from purchased)


-- 10) Find artist who have performed in multiple genres. Diplay the aritist name and the genre.
	
with dist_genre as 
		(select count(distinct gen.name) as genre_amt, art.name as artist
		from track tra
		join album alb on tra.albumid = alb.albumid
		join artist art on alb.artistid = art.artistid
		join genre gen on tra.genreid = gen.genreid
		group by art.name 
		)
select art.name as artist, gen.name as genre 
from track tra
join album alb on tra.albumid = alb.albumid
left join artist art on alb.artistid = art.artistid
left join genre gen on tra.genreid = gen.genreid
left join dist_genre d on art.name = d.artist
group by gen.name, art.name, d.genre_amt
having d.genre_amt > 1 
order by art.name


-- 11) Which is the most popular and least popular genre?

with pop_rank as
	(select gen.name as name, count(invl.trackid) as popularity
	from track tra
	join genre gen on tra.genreid = gen.genreid
	join invoiceline invl on tra.trackid = invl.trackid
	group by gen.name
	order by popularity)
select *
from pop_rank
where popularity = (select max(popularity) from pop_rank)
union
select *
from pop_rank
where popularity = (select min(popularity) from pop_rank)


-- 12) Identify if there are tracks more expensive than others. If there are, then
--     display the track name along with the album title and artist name for these expensive tracks.

select tra.name as track_name, alb.title as album_title, art.name as artist_name
from track tra 
join album alb on tra.albumid = alb.albumid
join artist art on alb.artistid = art.artistid
where unitprice > (select min(unitprice) from track)


--13) Identify the 5 most popular artist for the most popular genre.
 --  Popularity is defined based on how many songs an artist has performed in for the particular genre.
  --  Display the artist name along with the no of songs.
 --   [Reason: Now that we know that our customers love rock music, we can decide which musicians to invite to play at the concert.
  --  Lets invite the artists who have written the most rock music in our dataset.]

with popularity as
	(select art.name as artist_name, count(tra.genreid) as no_of_songs, rank() over(order by count(tra.genreid) desc) as rank
	from artist art
	join album alb on alb.artistid = art.artistid
	join track tra on tra.albumid = alb.albumid
	join genre gen on tra.genreid = gen.genreid
	where gen.genreid = 1
	group by art.name)
select art.name, no_of_songs
from popularity pop
join artist art on art.name = pop.artist_name
join album alb on alb.artistid = art.artistid
join track tra on tra.albumid = alb.albumid
join genre gen on tra.genreid = gen.genreid
where rank <= 5
and gen.genreid = 1
group by art.name, no_of_songs
order by no_of_songs desc

-- 2nd option
with most_popular_genre as
            (select name as genre
            from (select g.name
                , count(1) as no_of_purchases
                , rank() over(order by count(1) desc) as rnk
                from InvoiceLine il
                join track t on t.trackid = il.trackid
                join genre g on g.genreid = t.genreid
                group by g.name
                order by 2 desc) x
            where rnk = 1),
        all_data as
            (select art.name as artist_name, count(1) as no_of_songs
            , rank() over(order by count(1) desc) as rnk
            from track t
            join album al on al.albumid = t.albumid
            join artist art on art.artistid = al.artistid
            join genre g on g.genreid = t.genreid
            where g.name in (select genre from most_popular_genre)
            group by art.name
            order by 2 desc)
    select artist_name, no_of_songs
    from all_data
    where rnk <= 5;


--14) Find the artist who has contributed with the maximum no of songs/tracks. Display the artist name and the no of songs.

with tracks as 
	(select art.name as artist_name, count(tra.trackid) as no_of_songs
	from track tra
	join album alb on alb.albumid = tra.albumid
	join artist art on art.artistid = alb.artistid
	group by art.name)
select artist_name, no_of_songs
from tracks
where no_of_songs = (select max(no_of_songs) from tracks)


--15) Are there any albums owned by multiple artist?

select albumid, count(1) 
from Album 
group by albumid 
having count(1) > 1;

--16) Is there any invoice which is issued to a non existing customer?

select inv.invoiceid, inv.customerid
from invoice inv
left join customer cust on inv.customerid = cust.customerid
where inv.customerid is null

-- 2nd option
select * 
from Invoice I
where not exists (select 1 from customer c 
                where c.customerid = I.customerid)


--17) Is there any invoice line for a non existing invoice?
	
select *
from invoice inv
join invoiceline invl on inv.invoiceid = invl.invoiceid
where invl.invoiceid is null

--2nd option
select * 
from Invoice inv
where not exists (select 1 from invoiceline invl 
                where inv.invoiceid = invl.invoiceid)

--18) Are there albums without a title?

select count(*)
from album
where title is null


--19) Are there invalid tracks in the playlist?

select *
from playlisttrack pt
left join track t on t.trackid = pt.trackid
where pt.trackid is null

select * 
from PlaylistTrack pt -- result is 0 which means that all tracks in the playlist do exist hence all are valid
where not exists (select 1 from Track t 
                 where t.trackid = pt.trackid)



