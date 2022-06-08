USE [MinistryPlatform]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Care_Schedules](
	[Care_Schedule_ID] [int] IDENTITY(1,1) NOT NULL,
	[Contact_ID] [int] NOT NULL,
	[Schedule_Start] [datetime] NOT NULL,
	[Schedule_End] [datetime] NOT NULL,
	[Care_Schedule_Type_ID] [int] NOT NULL,
	[Schedule_Notes] [nvarchar](500) NULL,
	[Location_ID] [int] NOT NULL,
	[Domain_ID] [int] NOT NULL,
	[Cancelled] [bit] NOT NULL,
 CONSTRAINT [PK_Care_Schedules] PRIMARY KEY CLUSTERED 
(
	[Care_Schedule_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Care_Schedules] ADD  CONSTRAINT [DF_Care_Schedules_Schedule_Type_ID]  DEFAULT ((1)) FOR [Care_Schedule_Type_ID]
GO

ALTER TABLE [dbo].[Care_Schedules] ADD  CONSTRAINT [DF_Care_Schedules_Cancelled]  DEFAULT ((0)) FOR [Cancelled]
GO

ALTER TABLE [dbo].[Care_Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Care_Schedules_Care_Schedule_Types] FOREIGN KEY([Care_Schedule_Type_ID])
REFERENCES [dbo].[Care_Schedule_Types] ([Care_Schedule_Type_ID])
GO

ALTER TABLE [dbo].[Care_Schedules] CHECK CONSTRAINT [FK_Care_Schedules_Care_Schedule_Types]
GO

ALTER TABLE [dbo].[Care_Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Care_Schedules_Contacts] FOREIGN KEY([Contact_ID])
REFERENCES [dbo].[Contacts] ([Contact_ID])
GO

ALTER TABLE [dbo].[Care_Schedules] CHECK CONSTRAINT [FK_Care_Schedules_Contacts]
GO

ALTER TABLE [dbo].[Care_Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Care_Schedules_dp_Domains] FOREIGN KEY([Domain_ID])
REFERENCES [dbo].[dp_Domains] ([Domain_ID])
GO

ALTER TABLE [dbo].[Care_Schedules] CHECK CONSTRAINT [FK_Care_Schedules_dp_Domains]
GO

ALTER TABLE [dbo].[Care_Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Care_Schedules_Locations] FOREIGN KEY([Location_ID])
REFERENCES [dbo].[Locations] ([Location_ID])
GO

ALTER TABLE [dbo].[Care_Schedules] CHECK CONSTRAINT [FK_Care_Schedules_Locations]
GO


