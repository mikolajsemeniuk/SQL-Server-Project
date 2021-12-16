use BD2021_Instagram

select top 10 * from users

-- VIEWS
drop view if exists [most_liked_users]
go
create view [most_liked_users] as
select user_id, username, users.sex, count(*) as 'followers'
from users
join user_likes
on user_likes.following_id = users.user_id
group by users.user_id, users.username, users.sex
go


--
drop view if exists [users_who_follow]
go
create view [users_who_follow] as
select user_id, username, count(*) as 'followings'
from users
join user_likes
on user_likes.follower_id = users.user_id
group by users.user_id, users.username
go


--
drop view if exists [users_with_posts]
go
create view [users_with_posts] as
select users.user_id, username, count(*) as 'posts'
from users
join posts
on users.user_id = posts.user_id
group by users.user_id, users.username
go


--
drop view if exists [most_liked_posts]
go
create view [most_liked_posts] as
select posts.post_id, title, count(*) as 'likes'
from posts
join post_likes
on posts.post_id = post_likes.post_id
group by posts.post_id, title
go


--
drop view if exists [posts_with_comments]
go
create view [posts_with_comments] as
select posts.post_id, title, count(*) as 'comments'
from posts
join comments
on posts.post_id = comments.post_id
group by posts.post_id, title
go


--
drop view if exists [most_liked_comments]
go
create view [most_liked_comments] as
select comments.comment_id, comments.content, count(*) as 'likes'
from comments
join comment_likes
on comments.comment_id = comment_likes.comment_id
group by comments.comment_id, comments.content
go


--
drop view if exists [posts_with_rates]
go
create view [posts_with_rates] as
select post_id, count(*) as 'rates'
from post_rates
group by post_id
go


select * from most_liked_users order by followers desc
select * from users_who_follow order by followings desc
select * from users_with_posts order by posts desc
select * from most_liked_posts order by likes desc
select * from posts_with_comments order by comments desc
select * from most_liked_comments order by likes desc
select * from posts_with_rates order by rates desc
go


-- PROCEDURES
drop procedure if exists get_all_users_with_followers_and_posts
go

create procedure get_all_users_with_followers_and_posts
as
select x.user_id, x.username, followers, posts 
from users_with_posts as x
join most_liked_users as y
on x.user_id = y.user_id
go

exec get_all_users_with_followers_and_posts
go


-- get_most_liked_users
drop procedure if exists get_most_liked_users_by_sex
go

create procedure get_most_liked_users_by_sex @Sex bit = 1
as
select * from most_liked_users where sex = @Sex
order by followers desc
go

exec get_most_liked_users_by_sex
go

exec get_most_liked_users_by_sex @Sex = 0
go


-- get_user_with_followers_and_posts
drop procedure if exists get_user_with_followers_and_posts
go

create procedure get_user_with_followers_and_posts @user_id int = null, @username varchar(max) = null
as
select x.user_id, x.username, followers, posts 
from users_with_posts as x
join most_liked_users as y
on x.user_id = y.user_id
where x.user_id = @user_id or x.username = @username
go

exec get_user_with_followers_and_posts @user_id = 4
go

exec get_user_with_followers_and_posts @username = 'Sam Taylor'
go


-- get_posts_with_likes_and_comments
drop procedure if exists get_posts_with_likes_and_comments
go

create procedure get_posts_with_likes_and_comments @columnname NVARCHAR(128)
as
begin
    declare @query nvarchar(max)
    set @query = 'select x.post_id, x.title, likes, comments
                  from most_liked_posts as x
                  join posts_with_comments as y
                  on x.post_id = y.post_id
                  order by ' + @columnname + ' desc';
    exec(@query)
end

exec get_posts_with_likes_and_comments 'likes' -- likes | comments | post_id
go

-- FUNCTIONS
drop function if exists get_all_posts_with_comments_and_likes
go

create function get_all_posts_with_comments_and_likes 
()
returns table
as
return
    select x.post_id, x.title, x.likes, y.comments
    from most_liked_posts as x
    join posts_with_comments as y
    on x.post_id = y.post_id
go

select *
from get_all_posts_with_comments_and_likes()


-- get_post_with_at_least_n_rates
drop function if exists get_post_with_at_least_n_rates
go

create function get_post_with_at_least_n_rates 
(
    @amount SMALLINT
)
returns table
as
return
    select x.post_id, x.title, x.likes, z.comments, y.rates
    from most_liked_posts as x
    join posts_with_rates as y
    on x.post_id = y.post_id
    join posts_with_comments as z
    on z.post_id = y.post_id
    where y.rates >= @amount
go

select *
from get_post_with_at_least_n_rates(10)
order by rates desc