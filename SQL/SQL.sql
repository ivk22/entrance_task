drop table if exists dbo.T_CONTRACTOR_SHEDULER
drop table if exists dbo.T_CONTRACTOR_WORK_DAY 
drop procedure if exists dbo.COUNT_WORK_DAYS


-- ������� 1.

create table dbo.T_CONTRACTOR_SHEDULER  
   (ID_NAME int identity(1,1) primary key,  
   FIO nvarchar(25) not null,  
   SHEDULE nvarchar(25) not null,  
   DATE_BEGIN  date not null,
   DATE_END date not null,
   unique(FIO, DATE_BEGIN),
   check(DATE_END>=DATE_BEGIN))

insert dbo.T_CONTRACTOR_SHEDULER (FIO, SHEDULE, DATE_BEGIN, DATE_END)
    values
        ('��������� 1', '��������', '01.01.2019 0:00','10.01.2019 0:00'),
        ('��������� 1', '������', '11.01.2019 0:00','15.01.2019 0:00'),
        ('��������� 1', '��', '16.01.2019 0:00','20.01.2019 0:00'),
        ('��������� 2', '������', '01.01.2019 0:00','07.01.2019 0:00'),
        ('��������� 2', '�����', '08.01.2019 0:00','14.01.2019 0:00'),
        ('��������� 2', '�������', '15.01.2019 0:00','31.12.9999 0:00'),
        ('��������� 3', '������', '01.01.2019 0:00','01.02.2019 0:00'),
        ('��������� 3', '��������', '02.02.2019 0:00','31.12.9999 0:00')

-- ������� 2.
create table dbo.T_CONTRACTOR_WORK_DAY  
   (ID int identity(1,1) primary key,  
   FIO nvarchar(25) not null,   
   DATE_BEGIN  datetime not null,
   DATE_END datetime not null)


-- ������� 3.
go
create procedure dbo.COUNT_WORK_DAYS
(@start date, @end date)
as
begin
    set nocount on
	-- �������� ��������� �������, ���������� ����������� ����
	select substring(FIO,len(FIO),1) as FIO,DATE_BEGIN,DATE_END, SHEDULE, datediff(day,DATE_BEGIN ,(select max(v) 
	   from (values (DATE_BEGIN), (@start)) as value(v)))+1 as START_POS,
	   (select max(v) 
	   from (values (DATE_BEGIN), (@start)) as value(v)) as DATE_START,
	   datediff(day,(select max(v) 
	   from (values (DATE_BEGIN), (@start)) as value(v)), (select min(v) 
	   from (values (DATE_END), (@end)) as value(v)))+1 as DIFF,

	   ceiling((datediff(day, DATE_BEGIN ,(select min(v) 
	   from (values (DATE_END), (@end)) as value(v)))+1)/cast(len(SHEDULE) as float)) as N_REPS

	   into #t from dbo.T_CONTRACTOR_SHEDULER where datediff(day,(select max(v) 
	   from (values (DATE_BEGIN), (@start)) as value(v)),(select min(v) 
	   from (values (DATE_END), (@end)) as value(v))) >=0


	declare @str nvarchar(3000)
	-- ������������ ������, ���������� ���������� � ���������, ������� ����� �������� � �������
	select @str = coalesce(@str,'')+concat(FIO,substring(replicate(SHEDULE,N_REPS),START_POS,DIFF)) from #t


	declare @i int
	declare @j int
	declare @name nvarchar(25)
	declare @ch nvarchar(25)
	declare @id nvarchar(25)
	declare @date datetime

	select @id = '0'

	select @i = 1
	select @j = len(@str)
	-- ����, ���������� �� ������ @str � ����������� ����������� �������� � �������
	while @i<=@j
	begin
		select @ch = substring(@str,@i,1)
		if @ch = '�'
		begin
			insert dbo.T_CONTRACTOR_WORK_DAY (FIO,DATE_BEGIN, DATE_END)
				values
					(concat('��������� ',@id),dateadd(hour,8,@date),dateadd(hour,20,@date))
			select @date = dateadd(day,1,@date)
		end
		else if @ch = '�'
		begin
			insert dbo.T_CONTRACTOR_WORK_DAY (FIO,DATE_BEGIN, DATE_END)
				values
					(concat('��������� ',@id),dateadd(hour,8,@date),dateadd(hour,32,@date))
			select @date = dateadd(day,1,@date)
		end

		else if @ch = '�'
		begin
			insert dbo.T_CONTRACTOR_WORK_DAY (FIO,DATE_BEGIN, DATE_END)
				values
					(concat('��������� ',@id),dateadd(hour,20,@date),dateadd(hour,32,@date))
			select @date = dateadd(day,1,@date)
		end
		else if @ch = '�'
		begin
			select @date = dateadd(day,1,@date)
		end

		else
		begin
			if @ch<>@id
			begin
			select @id = @ch
			select @date=min(DATE_START) from #t where FIO=@id
			end
		end
		select @i = @i+1
	end
end
go

exec COUNT_WORK_DAYS @start='01.01.2019', @end = '31.01.2019';

-- ������� 4.

-- ����� ������� ���� 
select FIO, count(*) as N_WORK_DAYS from dbo.T_CONTRACTOR_WORK_DAY group by fio

-- ���������� � # ������� ���� � ������ ������ 10
select FIO from dbo.T_CONTRACTOR_WORK_DAY group by FIO having count(*)>10

-- ����������, ��� ������� 14,15 � 16 ������
select FIO from dbo.T_CONTRACTOR_WORK_DAY where 
	cast(DATE_BEGIN as date)='14.01.2019' or 
	cast(DATE_BEGIN as date)='15.01.2019' or 
	cast(DATE_BEGIN as date)='16.01.2019' 
	group by FIO having count(*)=3