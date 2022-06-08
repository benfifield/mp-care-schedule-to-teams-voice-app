USE [MinistryPlatform]
GO


CREATE PROCEDURE [dbo].[api_CUSTOM_GetPOCPeoriaContactEmail] 
	-- Add the parameters for the stored procedure here
	@DomainID int = 0
AS
BEGIN
	-- Enter your Pastor on Call Care Schedule Type ID here
	DECLARE @careScheduleTypeID int = 1
	
	select top 1 c.Email_Address as Email, CONCAT(c.Nickname, ' ',c.Last_Name) as Name
	from Contacts C
	inner join Care_Schedules cs on cs.Contact_ID = c.Contact_ID and cs.Care_Schedule_Type_ID = @careScheduleTypeID
	where getdate() between cs.Schedule_Start and cs.Schedule_End
	AND c.Domain_ID = @DomainID and cs.Domain_ID = @DomainID;
END
GO


