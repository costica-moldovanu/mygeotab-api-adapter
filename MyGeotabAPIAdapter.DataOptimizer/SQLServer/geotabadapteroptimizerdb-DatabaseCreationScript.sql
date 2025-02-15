USE [geotabadapteroptimizerdb]
GO
/****** Object:  Table [dbo].[FaultDataT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FaultDataT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[AmberWarningLamp] [bit] NULL,
	[ClassCode] [nvarchar](50) NULL,
	[ControllerId] [nvarchar](100) NOT NULL,
	[ControllerName] [nvarchar](255) NULL,
	[Count] [int] NOT NULL,
	[DateTime] [datetime2](7) NULL,
	[DeviceId] [bigint] NOT NULL,
	[DiagnosticId] [bigint] NOT NULL,
	[DismissDateTime] [datetime2](7) NULL,
	[DismissUserId] [bigint] NULL,
	[FailureModeCode] [int] NULL,
	[FailureModeId] [nvarchar](50) NOT NULL,
	[FailureModeName] [nvarchar](255) NULL,
	[FaultLampState] [nvarchar](50) NULL,
	[FaultState] [nvarchar](50) NULL,
	[MalfunctionLamp] [bit] NULL,
	[ProtectWarningLamp] [bit] NULL,
	[RedStopLamp] [bit] NULL,
	[Severity] [nvarchar](50) NULL,
	[SourceAddress] [int] NULL,
	[DriverId] [bigint] NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[Speed] [real] NULL,
	[Bearing] [real] NULL,
	[Direction] [nvarchar](3) NULL,
	[LongLatProcessed] [bit] NOT NULL,
	[LongLatReason] [tinyint] NULL,
	[DriverIdProcessed] [bit] NOT NULL,
	[DriverIdReason] [tinyint] NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_FaultDataT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LogRecordsT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogRecordsT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[DateTime] [datetime2](7) NOT NULL,
	[DeviceId] [bigint] NOT NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[Speed] [real] NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_LogRecordsT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwFaultDataTWithLagLeadLongLatBatch]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwFaultDataTWithLagLeadLongLatBatch]
AS
with LogRecordsTMinMaxDateTime as
(
	select min(DateTime) as LogRecordsTMinDateTime, max(DateTime) as LogRecordsTMaxDateTime from LogRecordsT
),
LogRecordsTMinMaxDateTimeByDevice as
(
	select DeviceId, min(DateTime) as LogRecordsTMinDateTime, max(DateTime) as LogRecordsTMaxDateTime 
	from LogRecordsT
	group by DeviceId
),
FaultDataTBatch as
(
	select top (750) f.id, f.GeotabId, f.DateTime, f.DeviceId,
		lrmm.LogRecordsTMinDateTime, lrmm.LogRecordsTMaxDateTime,
		dlrmm.LogRecordsTMinDateTime as DeviceLogRecordsTMinDateTime,
		dlrmm.LogRecordsTMaxDateTime as DeviceLogRecordsTMaxDateTime
	from FaultDataT f
	cross join LogRecordsTMinMaxDateTime lrmm
	left join LogRecordsTMinMaxDateTimeByDevice dlrmm
		on f.DeviceId = dlrmm.DeviceId
	where (f.LongLatProcessed = 0 
		and f.DateTime < lrmm.LogRecordsTMaxDateTime)
	order by f.DeviceId, f.DateTime
),
LogRecordsTWithLeads as
(
	select *,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(DateTime) over (order by DeviceId,  DateTime) else NULL end as LeadDateTime,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(Latitude) over (order by DeviceId,  DateTime) else NULL end as LeadLatitude,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(Longitude) over (order by DeviceId,  DateTime) else NULL end as LeadLongitude
	from LogRecordsT
),
InitialResults as
(
	select fb.id, fb.GeotabId, fb.DateTime as FaultDataDateTime, fb.DeviceId,
		l.DateTime as LagDateTime, l.Latitude as LagLatitude, l.Longitude as LagLongitude, l.Speed as LagSpeed, l.LeadDateTime, l.LeadLatitude, l.LeadLongitude,
		fb.LogRecordsTMinDateTime, fb.LogRecordsTMaxDateTime, fb.DeviceLogRecordsTMinDateTime, fb.DeviceLogRecordsTMaxDateTime
	from FaultDataTBatch fb
	left join LogRecordsTWithLeads as l
		on (fb.DeviceId = l.DeviceId 
			and fb.DateTime >= l.DateTime 
			and fb.DateTime <= l.LeadDateTime)
)
select * 
from InitialResults r
where r.FaultDataDateTime <> r.LeadDateTime;
GO
/****** Object:  Table [dbo].[StatusDataT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatusDataT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[Data] [float] NULL,
	[DateTime] [datetime2](7) NULL,
	[DeviceId] [bigint] NOT NULL,
	[DiagnosticId] [bigint] NOT NULL,
	[DriverId] [bigint] NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[Speed] [real] NULL,
	[Bearing] [real] NULL,
	[Direction] [nvarchar](3) NULL,
	[LongLatProcessed] [bit] NOT NULL,
	[LongLatReason] [tinyint] NULL,
	[DriverIdProcessed] [bit] NOT NULL,
	[DriverIdReason] [tinyint] NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_StatusDataT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwStatusDataTWithLagLeadLongLatBatch]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwStatusDataTWithLagLeadLongLatBatch]
AS
with LogRecordsTMinMaxDateTime as
(
	select min(DateTime) as LogRecordsTMinDateTime, max(DateTime) as LogRecordsTMaxDateTime from LogRecordsT
),
LogRecordsTMinMaxDateTimeByDevice as
(
	select DeviceId, min(DateTime) as LogRecordsTMinDateTime, max(DateTime) as LogRecordsTMaxDateTime 
	from LogRecordsT
	group by DeviceId
),
StatusDataTBatch as
(
	select top (2000) s.id, s.GeotabId, s.DateTime, s.DeviceId,
		lrmm.LogRecordsTMinDateTime, lrmm.LogRecordsTMaxDateTime,
		dlrmm.LogRecordsTMinDateTime as DeviceLogRecordsTMinDateTime,
		dlrmm.LogRecordsTMaxDateTime as DeviceLogRecordsTMaxDateTime
	from StatusDataT s
	cross join LogRecordsTMinMaxDateTime lrmm
	left join LogRecordsTMinMaxDateTimeByDevice dlrmm
		on s.DeviceId = dlrmm.DeviceId
	where (s.LongLatProcessed = 0 
		and s.DateTime < lrmm.LogRecordsTMaxDateTime)
	order by s.DeviceId, s.DateTime
),
LogRecordsTWithLeads as
(
	select *,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(DateTime) over (order by DeviceId,  DateTime) else NULL end as LeadDateTime,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(Latitude) over (order by DeviceId,  DateTime) else NULL end as LeadLatitude,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(Longitude) over (order by DeviceId,  DateTime) else NULL end as LeadLongitude
	from LogRecordsT
),
InitialResults as
(
	select sb.id, sb.GeotabId, sb.DateTime as StatusDataDateTime, sb.DeviceId,
		l.DeviceId as LagDeviceId,
		l.DateTime as LagDateTime, l.Latitude as LagLatitude, l.Longitude as LagLongitude, l.Speed as LagSpeed, l.LeadDateTime, l.LeadLatitude, l.LeadLongitude,
		sb.LogRecordsTMinDateTime, sb.LogRecordsTMaxDateTime, sb.DeviceLogRecordsTMinDateTime, sb.DeviceLogRecordsTMaxDateTime
	from StatusDataTBatch sb
	left join LogRecordsTWithLeads as l
		on (sb.DeviceId = l.DeviceId 
			and sb.DateTime >= l.DateTime 
			and sb.DateTime <= l.LeadDateTime)
)
select * 
from InitialResults r
where r.StatusDataDateTime <> r.LeadDateTime;
GO
/****** Object:  Table [dbo].[DriverChangesT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DriverChangesT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[DateTime] [datetime2](7) NULL,
	[DeviceId] [bigint] NOT NULL,
	[DriverId] [bigint] NOT NULL,
	[DriverChangeTypeId] [bigint] NOT NULL,
	[Version] [bigint] NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_DriverChangesT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vwStatusDataTWithLagLeadDriverChangeBatch]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwStatusDataTWithLagLeadDriverChangeBatch]
AS
with DriverChangesTMinMaxDateTime as
(
	select min(DateTime) as DriverChangesTMinDateTime, max(DateTime) as DriverChangesTMaxDateTime from DriverChangesT
),
DriverChangesTMinMaxDateTimeByDevice as
(
	select DeviceId, min(DateTime) as DriverChangesTMinDateTime, max(DateTime) as DriverChangesTMaxDateTime 
	from DriverChangesT
	group by DeviceId
),
StatusDataTBatch as
(
	select top (2000) s.id, s.GeotabId, s.DateTime, s.DeviceId,
		dcmm.DriverChangesTMinDateTime, dcmm.DriverChangesTMaxDateTime,
		ddcmm.DriverChangesTMinDateTime as DeviceDriverChangesTMinDateTime,
		ddcmm.DriverChangesTMaxDateTime as DeviceDriverChangesTMaxDateTime
	from StatusDataT s
	cross join DriverChangesTMinMaxDateTime dcmm
	left join DriverChangesTMinMaxDateTimeByDevice ddcmm
		on s.DeviceId = ddcmm.DeviceId
	where (s.DriverIdProcessed = 0 
		and s.DateTime < dcmm.DriverChangesTMaxDateTime)
		order by s.DeviceId, s.DateTime
),
DriverChangesTWithLeads as
(
	select *,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(DateTime) over (order by DeviceId,  DateTime) else NULL end as LeadDateTime	
	from DriverChangesT
),
InitialResults as
(
	select sb.id, sb.GeotabId, sb.DateTime as StatusDataDateTime, sb.DeviceId,
		d.DriverId, d.DateTime as LagDateTime, d.LeadDateTime,
		sb.DriverChangesTMinDateTime, sb.DriverChangesTMaxDateTime, sb.DeviceDriverChangesTMinDateTime, sb.DeviceDriverChangesTMaxDateTime
	from StatusDataTBatch sb
	left join DriverChangesTWithLeads as d
		on (sb.DeviceId = d.DeviceId 
			and sb.DateTime >= d.DateTime 
			and sb.DateTime <= d.LeadDateTime)
)
select * 
from InitialResults r
where r.StatusDataDateTime <> r.LeadDateTime;
GO
/****** Object:  View [dbo].[vwFaultDataTWithLagLeadDriverChangeBatch]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwFaultDataTWithLagLeadDriverChangeBatch]
AS
with DriverChangesTMinMaxDateTime as
(
	select min(DateTime) as DriverChangesTMinDateTime, max(DateTime) as DriverChangesTMaxDateTime from DriverChangesT
),
DriverChangesTMinMaxDateTimeByDevice as
(
	select DeviceId, min(DateTime) as DriverChangesTMinDateTime, max(DateTime) as DriverChangesTMaxDateTime 
	from DriverChangesT
	group by DeviceId
),
FaultDataTBatch as
(
	select top (2000) f.id, f.GeotabId, f.DateTime, f.DeviceId,
		dcmm.DriverChangesTMinDateTime, dcmm.DriverChangesTMaxDateTime,
		ddcmm.DriverChangesTMinDateTime as DeviceDriverChangesTMinDateTime,
		ddcmm.DriverChangesTMaxDateTime as DeviceDriverChangesTMaxDateTime
	from FaultDataT f
	cross join DriverChangesTMinMaxDateTime dcmm
	left join DriverChangesTMinMaxDateTimeByDevice ddcmm
		on f.DeviceId = ddcmm.DeviceId
	where (f.DriverIdProcessed = 0 
		and f.DateTime < dcmm.DriverChangesTMaxDateTime)
	order by f.DeviceId, f.DateTime
),
DriverChangesTWithLeads as
(
	select *,
		case when DeviceId = lead(DeviceId) over (order by DeviceId,  DateTime)  then lead(DateTime) over (order by DeviceId,  DateTime) else NULL end as LeadDateTime	
	from DriverChangesT
),
InitialResults as
(
	select fb.id, fb.GeotabId, fb.DateTime as FaultDataDateTime, fb.DeviceId,
		d.DriverId, d.DateTime as LagDateTime, d.LeadDateTime,
		fb.DriverChangesTMinDateTime, fb.DriverChangesTMaxDateTime, fb.DeviceDriverChangesTMinDateTime, fb.DeviceDriverChangesTMaxDateTime
	from FaultDataTBatch fb
	left join DriverChangesTWithLeads as d
		on (fb.DeviceId = d.DeviceId 
			and fb.DateTime >= d.DateTime 
			and fb.DateTime <= d.LeadDateTime)
)
select * 
from InitialResults r
where r.FaultDataDateTime <> r.LeadDateTime;
GO
/****** Object:  Table [dbo].[BinaryDataT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BinaryDataT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[BinaryTypeId] [bigint] NOT NULL,
	[ControllerId] [bigint] NOT NULL,
	[Data] [nvarchar](1024) NOT NULL,
	[DateTime] [datetime2](7) NULL,
	[DeviceId] [bigint] NOT NULL,
	[Version] [nvarchar](50) NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_BinaryDataT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BinaryTypesT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BinaryTypesT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_BinaryTypesT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ControllersT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ControllersT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_ControllersT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DevicesT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DevicesT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[ActiveFrom] [datetime2](7) NULL,
	[ActiveTo] [datetime2](7) NULL,
	[Comment] [nvarchar](1024) NULL,
	[DeviceType] [nvarchar](50) NOT NULL,
	[LicensePlate] [nvarchar](50) NULL,
	[LicenseState] [nvarchar](50) NULL,
	[Name] [nvarchar](100) NOT NULL,
	[ProductId] [int] NULL,
	[SerialNumber] [nvarchar](12) NOT NULL,
	[VIN] [nvarchar](50) NULL,
	[EntityStatus] [int] NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_DevicesT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DiagnosticIdsT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiagnosticIdsT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabGUID] [varchar](36) NOT NULL,
	[GeotabId] [nvarchar](100) NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_DiagnosticIdsT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_DiagnosticIdsT] UNIQUE NONCLUSTERED 
(
	[GeotabGUID] ASC,
	[GeotabId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DiagnosticsT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiagnosticsT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabGUID] [varchar](36) NOT NULL,
	[ControllerId] [nvarchar](100) NULL,
	[DiagnosticCode] [int] NULL,
	[DiagnosticName] [nvarchar](255) NOT NULL,
	[DiagnosticSourceId] [nvarchar](50) NOT NULL,
	[DiagnosticSourceName] [nvarchar](255) NOT NULL,
	[DiagnosticUnitOfMeasureId] [nvarchar](50) NOT NULL,
	[DiagnosticUnitOfMeasureName] [nvarchar](255) NOT NULL,
	[OBD2DTC] [nvarchar](50) NULL,
	[EntityStatus] [int] NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_DiagnosticsT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DriverChangeTypesT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DriverChangeTypesT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](100) NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_DriverChangeTypesT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ODbErrors]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ODbErrors](
	[ErrorID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](100) NULL,
	[ErrorNumber] [int] NULL,
	[ErrorState] [int] NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorLine] [int] NULL,
	[ErrorProcedure] [varchar](max) NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ErrorDateTime] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OProcessorTracking]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OProcessorTracking](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[ProcessorId] [nvarchar](50) NOT NULL,
	[OptimizerVersion] [nvarchar](50) NULL,
	[OptimizerMachineName] [nvarchar](100) NULL,
	[EntitiesLastProcessedUtc] [datetime2](7) NULL,
	[AdapterDbLastId] [bigint] NULL,
	[AdapterDbLastGeotabId] [nvarchar](50) NULL,
	[AdapterDbLastRecordCreationTimeUtc] [datetime2](7) NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_DataOptimizerProcessorTracking] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UsersT]    Script Date: 2022-03-08 11:41:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UsersT](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeotabId] [nvarchar](50) NOT NULL,
	[ActiveFrom] [datetime2](7) NOT NULL,
	[ActiveTo] [datetime2](7) NOT NULL,
	[EmployeeNo] [nvarchar](50) NULL,
	[FirstName] [nvarchar](255) NOT NULL,
	[HosRuleSet] [nvarchar](max) NULL,
	[IsDriver] [bit] NOT NULL,
	[LastAccessDate] [datetime2](7) NULL,
	[LastName] [nvarchar](255) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[RecordLastChangedUtc] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_UsersT] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UI_DiagnosticsT_GeotabGUID]    Script Date: 2022-03-08 11:41:42 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UI_DiagnosticsT_GeotabGUID] ON [dbo].[DiagnosticsT]
(
	[GeotabGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FaultDataT] ADD  CONSTRAINT [DF_FaultDataT_LongLatProcessed]  DEFAULT ((0)) FOR [LongLatProcessed]
GO
ALTER TABLE [dbo].[FaultDataT] ADD  CONSTRAINT [DF_FaultDataT_DriverIdProcessed]  DEFAULT ((0)) FOR [DriverIdProcessed]
GO
ALTER TABLE [dbo].[LogRecordsT] ADD  CONSTRAINT [DF__LogRecord__Latit__2E1BDC42]  DEFAULT ((0)) FOR [Latitude]
GO
ALTER TABLE [dbo].[LogRecordsT] ADD  CONSTRAINT [DF__LogRecord__Longi__2F10007B]  DEFAULT ((0)) FOR [Longitude]
GO
ALTER TABLE [dbo].[LogRecordsT] ADD  CONSTRAINT [DF__LogRecord__Speed__300424B4]  DEFAULT ((0)) FOR [Speed]
GO
ALTER TABLE [dbo].[StatusDataT] ADD  CONSTRAINT [DF_StatusDataT_OptimizerStatus]  DEFAULT ((0)) FOR [LongLatProcessed]
GO
ALTER TABLE [dbo].[StatusDataT] ADD  CONSTRAINT [DF_StatusDataT_DriverIdProcessed]  DEFAULT ((0)) FOR [DriverIdProcessed]
GO
ALTER TABLE [dbo].[BinaryDataT]  WITH CHECK ADD  CONSTRAINT [FK_BinaryDataT_BinaryTypesT] FOREIGN KEY([BinaryTypeId])
REFERENCES [dbo].[BinaryTypesT] ([id])
GO
ALTER TABLE [dbo].[BinaryDataT] CHECK CONSTRAINT [FK_BinaryDataT_BinaryTypesT]
GO
ALTER TABLE [dbo].[BinaryDataT]  WITH CHECK ADD  CONSTRAINT [FK_BinaryDataT_ControllersT] FOREIGN KEY([ControllerId])
REFERENCES [dbo].[ControllersT] ([id])
GO
ALTER TABLE [dbo].[BinaryDataT] CHECK CONSTRAINT [FK_BinaryDataT_ControllersT]
GO
ALTER TABLE [dbo].[BinaryDataT]  WITH CHECK ADD  CONSTRAINT [FK_BinaryDataT_DevicesT] FOREIGN KEY([DeviceId])
REFERENCES [dbo].[DevicesT] ([id])
GO
ALTER TABLE [dbo].[BinaryDataT] CHECK CONSTRAINT [FK_BinaryDataT_DevicesT]
GO
ALTER TABLE [dbo].[DiagnosticIdsT]  WITH CHECK ADD  CONSTRAINT [FK_DiagnosticIdsT_DiagnosticsT] FOREIGN KEY([GeotabGUID])
REFERENCES [dbo].[DiagnosticsT] ([GeotabGUID])
GO
ALTER TABLE [dbo].[DiagnosticIdsT] CHECK CONSTRAINT [FK_DiagnosticIdsT_DiagnosticsT]
GO
ALTER TABLE [dbo].[DriverChangesT]  WITH CHECK ADD  CONSTRAINT [FK_DriverChangesT_DevicesT] FOREIGN KEY([DeviceId])
REFERENCES [dbo].[DevicesT] ([id])
GO
ALTER TABLE [dbo].[DriverChangesT] CHECK CONSTRAINT [FK_DriverChangesT_DevicesT]
GO
ALTER TABLE [dbo].[DriverChangesT]  WITH CHECK ADD  CONSTRAINT [FK_DriverChangesT_DriverChangeTypesT] FOREIGN KEY([DriverChangeTypeId])
REFERENCES [dbo].[DriverChangeTypesT] ([id])
GO
ALTER TABLE [dbo].[DriverChangesT] CHECK CONSTRAINT [FK_DriverChangesT_DriverChangeTypesT]
GO
ALTER TABLE [dbo].[DriverChangesT]  WITH CHECK ADD  CONSTRAINT [FK_DriverChangesT_UsersT] FOREIGN KEY([DriverId])
REFERENCES [dbo].[UsersT] ([id])
GO
ALTER TABLE [dbo].[DriverChangesT] CHECK CONSTRAINT [FK_DriverChangesT_UsersT]
GO
ALTER TABLE [dbo].[FaultDataT]  WITH CHECK ADD  CONSTRAINT [FK_FaultDataT_DevicesT] FOREIGN KEY([DeviceId])
REFERENCES [dbo].[DevicesT] ([id])
GO
ALTER TABLE [dbo].[FaultDataT] CHECK CONSTRAINT [FK_FaultDataT_DevicesT]
GO
ALTER TABLE [dbo].[FaultDataT]  WITH CHECK ADD  CONSTRAINT [FK_FaultDataT_DiagnosticsT] FOREIGN KEY([DiagnosticId])
REFERENCES [dbo].[DiagnosticsT] ([id])
GO
ALTER TABLE [dbo].[FaultDataT] CHECK CONSTRAINT [FK_FaultDataT_DiagnosticsT]
GO
ALTER TABLE [dbo].[FaultDataT]  WITH CHECK ADD  CONSTRAINT [FK_FaultDataT_UsersT] FOREIGN KEY([DismissUserId])
REFERENCES [dbo].[UsersT] ([id])
GO
ALTER TABLE [dbo].[FaultDataT] CHECK CONSTRAINT [FK_FaultDataT_UsersT]
GO
ALTER TABLE [dbo].[FaultDataT]  WITH CHECK ADD  CONSTRAINT [FK_FaultDataT_UsersT1] FOREIGN KEY([DriverId])
REFERENCES [dbo].[UsersT] ([id])
GO
ALTER TABLE [dbo].[FaultDataT] CHECK CONSTRAINT [FK_FaultDataT_UsersT1]
GO
ALTER TABLE [dbo].[LogRecordsT]  WITH CHECK ADD  CONSTRAINT [FK_LogRecordsT_DevicesT] FOREIGN KEY([DeviceId])
REFERENCES [dbo].[DevicesT] ([id])
GO
ALTER TABLE [dbo].[LogRecordsT] CHECK CONSTRAINT [FK_LogRecordsT_DevicesT]
GO
ALTER TABLE [dbo].[StatusDataT]  WITH CHECK ADD  CONSTRAINT [FK_StatusDataT_DevicesT] FOREIGN KEY([DeviceId])
REFERENCES [dbo].[DevicesT] ([id])
GO
ALTER TABLE [dbo].[StatusDataT] CHECK CONSTRAINT [FK_StatusDataT_DevicesT]
GO
ALTER TABLE [dbo].[StatusDataT]  WITH CHECK ADD  CONSTRAINT [FK_StatusDataT_DiagnosticsT] FOREIGN KEY([DiagnosticId])
REFERENCES [dbo].[DiagnosticsT] ([id])
GO
ALTER TABLE [dbo].[StatusDataT] CHECK CONSTRAINT [FK_StatusDataT_DiagnosticsT]
GO
ALTER TABLE [dbo].[StatusDataT]  WITH CHECK ADD  CONSTRAINT [FK_StatusDataT_UsersT] FOREIGN KEY([DriverId])
REFERENCES [dbo].[UsersT] ([id])
GO
ALTER TABLE [dbo].[StatusDataT] CHECK CONSTRAINT [FK_StatusDataT_UsersT]
GO
