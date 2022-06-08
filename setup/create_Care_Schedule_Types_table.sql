USE [MinistryPlatform]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Care_Schedule_Types](
	[Care_Schedule_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Schedule_Type] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Care_Schedule_Types] PRIMARY KEY CLUSTERED 
(
	[Care_Schedule_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


