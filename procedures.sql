use BD2021_Instagram


-- procedure 1 --
drop procedure if exists set_user_like
go

create procedure set_user_like
(
    @following_id int,
    @follower_id int
)
as
begin
    begin try
        if @following_id is null
            throw 51000, '@following_id cannot be null', 1;

        if @follower_id is null
            throw 51000, '@follower_id cannot be null', 1;

        if (select count(*) from user_likes where following_id = @following_id and follower_id = @follower_id) = 1
            delete from user_likes where following_id = @following_id and follower_id = @follower_id
        else
            insert into user_likes (following_id, follower_id) values (@following_id, @follower_id)
    end try
    begin catch
        select error_number() as _error_number, error_message() as _error_message;
    end catch
end
go

-- exec set_user_like 1, 115
-- go

-- select * from user_likes where following_id = 1 and follower_id = 5
-- go


-- procedure 2 --
drop procedure if exists update_user_info
go

create procedure update_user_info
(
    @user_id int,
    @username varchar(255),
    @birthday datetime,
    @sex bit,
    @occupation varchar(255)
)
as
begin
    begin try
        if @user_id is null
            throw 10001, '@user_id cannot be null', 10;

        if @username is null
            throw 10001, '@username cannot be null', 10;

        if datediff(month, @birthday , getdate()) <= 18 * 12
            throw 10001, 'user cannot be under eighteen', 10;

        if (select count(*) from users where user_id = @user_id) = 0
        begin
            declare @message varchar(300) = 'there is no user in database with id: ' + cast(@user_id as varchar);
            throw 10001, @message, 10;
        end

        if (select count(*) from users where lower(username) = lower(@username)) = 1
            throw 10001, 'username is already taken', 10;

        update users
        set username = @username, 
            birthday = @birthday,
            sex = @sex,
            occupation = @occupation,
            updated_at = getdate()
        where user_id = @user_id

    end try
    begin catch
        select error_number() as _error_number, error_message() as _error_message;
    end catch
end
go

-- exec update_user_info 1, 'John Doe', '2000-05-05', 1, 'architect'
-- go

-- procedure 3 --
drop procedure if exists create_new_user
go

create procedure create_new_user
(
	@username varchar(255),
	@sex bit,
	@birthday datetime,
	@occupation varchar(255),
	@info xml output
)
as
begin try
    if @username is null
        throw 10001, '@username cannot be null', 10;

	if datediff(month, @birthday , getdate()) <= 18 * 12
		throw 10001, 'user cannot be under 18 years', 10

    if (select count(*) from users where lower(username) = lower(@username)) = 1
        throw 10001, 'username is already taken', 10;

	begin transaction
        insert into users(username, sex, birthday, occupation, created_at)
		select @username, @sex, @birthday, @occupation, getdate()
	commit tran

	set @info = (select 0 as 'Code', 'User added' as [Message] for xml path('info'))
end try

begin catch
	if @@trancount > 0
		rollback

	set @info = 
	(
		select error_number() as 'Code',
		'Error occured, check details' as [Message],
		(select error_message() as [Message], error_procedure() as [Procedure], error_line() as [code_line] for xml path('Error'), type) for xml path('info')
	)
end catch
go

-- exec create_new_user 'unique', 0, '2000-01-05', 'occupation', '' 

-- delete from users where user_id = 52
-- select * from users

-- procedure 4 --
drop procedure if exists add_comment
go

create procedure [dbo].[add_comment]
(
	@content varchar(max),
	@post_id int,
	@user_id int,
	@info xml output
)
as
begin try
	if @content in ('Asshole', 'Beat Off', 'Blow', 'Blow job', 'Bullshit', 'Bust a nut', 'Camel jockey', 'Carpet muncher', 'Chink', 'Christ', 'Circle Jerk', 'Clit', 'Cock', 'Cock sucker', 'Coon', 'Coochie', 'Cream', 'Cum', 'Cunt', 'Dago', 'Dick', 'Dirty Sanchez', 'Doggy style', 'Dyke', 'Fag', 'Faggot', 'Fingered', 'Fisting', 'Fuck', 'Fudge packer', 'Goddamn', 'Gook', 'Hand job', 'Head', 'Heeb', 'Hershey Highway', 'Jack Off', 'Jerk Off', 'Jesus Christ', 'Jizz', 'Kike', 'Mofo', 'Moist', 'Nigger', 'Pillow Biter', 'Pink', 'Poonani', 'Poontang', 'Prick', 'Pussy', 'Reach Around', 'Rim', 'Rimming', 'Shit', 'Sixty Nine', 'Snatch', 'Spic', 'Skeet', 'Suck', 'Swallow', 'Taint', 'Tits', 'Titties', 'Trim', 'Twat', 'Wet', 'Wetback', 'Whack Off', 'Wigger', 'Wop')
   		throw 50009, 'Not allowed words', 16

	begin transaction
		insert into comments(content, post_id, user_id)
		select @content, @post_id, @user_id
	commit tran

	set @info = (select 0 as 'Code', 'Success' as [Message] for xml path('info'))
end try

begin catch
	if @@trancount > 0
		rollback

	set @info = 
	(
		select error_number() as 'Code',
		'Error occured, check details' as [Message],
		(select error_message() as [Message], error_procedure() as [Procedure], error_line() as [code_line] for xml path('Error'), type) for xml path('info')
	)
end catch
go