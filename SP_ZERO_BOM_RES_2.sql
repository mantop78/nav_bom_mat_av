USE [carimali]
GO
/****** Object:  StoredProcedure [dbo].[realBOM]    Script Date: 03/05/2020 17:02:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Paolo Mantoan
-- Create date: 23-04-2020
-- Description:	realBOM
-- =============================================
--[Replenishment System] 0-Purchase,1-Prod,2-Order,3-,4-Assembly
ALTER PROCEDURE [dbo].[realBOM]
AS
DROP TABLE IF EXISTS TempBOM;
WITH ItemCTE
	AS
	-- Anchor member.
	(SELECT 
	rItem.[No_] AS part,
	rBOMline.[No_] AS partChild,
	CAST(rBOMline.[Quantity per] as decimal(5,2)) AS quantityPer,
	CAST(rBOMline.[Quantity] as decimal (5,2)) as quantity,
	rBOMline.[Unit of Measure Code] as um,
	rBOMline.[Ending Date] AS justCheck_date,
	-- CASE WHEN rItem.[Replenishment System] = 0 THEN 'Acqs'
	--	 WHEN rItem.[Replenishment System] = 2 THEN 'Prod'
    --     ELSE 'Asmb' END AS replSystem,
	-- rItem.[Replenishment System] as replenishmentSystemQ,
	rBOMheader.No_ AS originalBom,
	rBOMheader.[Status] as JustStatusCheck,
	1 as [level]
	FROM [CARIMALI S_p_A_$Item] as rItem JOIN [CARIMALI S_p_A_$Production BOM Line] as rBOMline
	ON rItem.[Production BOM No_] = rBOMline.[Production BOM No_] JOIN [CARIMALI S_p_A_$Production BOM Header] as rBOMheader
	ON rBOMheader.No_ = rItem.[Production BOM No_]
	WHERE rItem.[No_] = 'X26-2LM00286' AND 
	([Ending Date] = '1753-01-01 00:00:00.000' OR CAST([Ending Date] as DATE) >= CAST(GETDATE() as DATE)) AND
	rBOMheader.[Status] = 1
	and rItem.[Replenishment System] <> 0
UNION ALL 
	-- Recursive member.
	SELECT 
	rItem.[No_] AS part,
	rBOMlineD.[No_] AS partChild,
	CAST(rBOMlineD.[Quantity per] * ItemCTEr.quantityPer AS decimal(5,2)) as quantityPer,
	CAST(rBOMlineD.[Quantity] as decimal (5,2))  as quantity,
	rBOMlineD.[Unit of Measure Code] as um,
	rBOMlineD.[Ending Date] AS justCheck_date,
	--CASE WHEN rItem.[Replenishment System] = 0 THEN 'Acqs'
	--	 WHEN rItem.[Replenishment System] = 2 THEN 'Prod'
    --     ELSE 'Asmb' END AS replSystem,
	-- rItem.[Replenishment System] as replenishmentSystemQ ,
	originalBom,
	--rBOMheader.No_ AS justCheck_partBH,
	rBOMheader.[Status] as JustStatusCheck,
	ItemCTEr.[level] + 1
	FROM ItemCTE as ItemCTEr JOIN ([CARIMALI S_p_A_$Item] as rItem JOIN [CARIMALI S_p_A_$Production BOM Line] as rBOMlineD
	ON rItem.[Production BOM No_] = rBOMlineD.[Production BOM No_] JOIN [CARIMALI S_p_A_$Production BOM Header] as rBOMheader
	ON rBOMheader.No_ = rItem.[Production BOM No_]) 
	-- CTE on
	ON ItemCTEr.partChild = rItem.No_ AND ItemCTEr.[level] <= 50
	WHERE ([Ending Date] = '1753-01-01 00:00:00.000' OR CAST([Ending Date] as DATE) >= CAST(GETDATE() as DATE)) AND
	rBOMheader.[Status] = 1
	AND rItem.[Replenishment System] <> 0
	)
	SELECT * INTO TempBOM FROM ItemCTE
;

EXEC('ALTER TABLE TempBOM ADD

[Inventory] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Inventory DEFAULT 0.0

,[Qty_ on Purch_ Order_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_onPurch_Order_TDT DEFAULT 0.0

,[Qty_ on Purch_ Order] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_onPurch_Order DEFAULT 0.0

,[Planning Receipt (Qty_)_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlanningReceiptQty_TDT DEFAULT 0.0

,[Planning Receipt (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlanningReceiptQty_ DEFAULT 0.0

,[Scheduled Receipt (Qty_)_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_ScheduledReceiptQty_TDT DEFAULT 0.0

,[Scheduled Receipt (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_ScheduledReceiptQty_ DEFAULT 0.0

,[Planned Order Receipt (Qty_)_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlannedOrderReceiptQty_TDT DEFAULT 0.0

,[Planned Order Receipt (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlannedOrderReceiptQty_ DEFAULT 0.0

,[Purch_ Req_ Receipt (Qty_)_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PurchReqReceiptQty_TDT DEFAULT 0.0

,[Purch_ Req_ Receipt (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PurchReqReceiptQty_ DEFAULT 0.0

,[Qty_ in Transit_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_inTransit_TDT DEFAULT 0.0

,[Qty_ in Transit] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_inTransit DEFAULT 0.0

,[Trans_ Ord_ Receipt (Qty_)_TDT] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Trans_Ord_ReceiptQty_TDT DEFAULT 0.0

,[Trans_ Ord_ Receipt (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Trans_Ord_ReceiptQty_ DEFAULT 0.0

,[Reserved Qty_ on Inventory] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_ReservedQty_onInventory DEFAULT 0.0

,[Scheduled Need (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_ScheduledNeedQty_ DEFAULT 0.0

,[Planning Issues (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlanningIssuesQty_ DEFAULT 0.0

,[Planning Transfer Ship_ (Qty)_] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlanningTransferShip_Qty_ DEFAULT 0.0

,[Qty_ on Sales Order] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_onSalesOrder DEFAULT 0.0

,[Trans. Ord. Shipment (Qty_)] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Trans_Ord_ShipmentQty_ DEFAULT 0.0

,[Qty_ on Purch_ Return] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_onPurch_Return DEFAULT 0.0

,[Qty_ on Sales Return] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Qty_onSalesReturn DEFAULT 0.0

,[Res_ Qty_ on Req_ Line] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_Res_Qty_onReq_Line DEFAULT 0.0

,[replenishmentSystem] INT
,[No Picking Required] tinyint
,[Item Status] nvarchar(10)
,[Critical] tinyint
,[Certified] tinyint

,[BackOrderQty] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_BackOrderQty DEFAULT 0.0

,[GrossRequirement] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_GrossRequirement DEFAULT 0.0

,[ScheduledReceipt] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_ScheduledReceipt DEFAULT 0.0

,[PlannedOrderReceipt] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_PlannedOrderReceipt DEFAULT 0.0

,[ProjAvailBalance] decimal(10,2) NOT NULL
CONSTRAINT D_TempBOM_ProjAvailBalance DEFAULT 0.0
')

-- ,[Spare Part Safety Stock] tinyint

---- CALC AVAILABLE ..TODAY

-- [Qty_ on Purch_ Order_UT] | date filter: [Expected Receipt Date] | location filter: [Location Code]
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ on Purch_ Order_TDT] = Pl.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Purchase Line].[Outstanding Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Purchase Line]
	  WHERE [CARIMALI S_p_A_$Purchase Line].[Document Type] = 1
	  AND [CARIMALI S_p_A_$Purchase Line].[Type] = 2
	  AND CAST([Expected Receipt Date] as DATE) <= CAST(GETDATE() as DATE)
	  GROUP BY [No_]
     ) as Pl
   ON TempBOM.partChild = Pl.[No_]')
-- [Qty_ on Purch_ Order] | date filter: [Expected Receipt Date] | location filter: [Location Code]
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ on Purch_ Order] = Pl.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Purchase Line].[Outstanding Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Purchase Line]
	  WHERE [CARIMALI S_p_A_$Purchase Line].[Document Type] = 1
	  AND [CARIMALI S_p_A_$Purchase Line].[Type] = 2
	  GROUP BY [No_]
     ) as Pl
   ON TempBOM.partChild = Pl.[No_]')

-- [Planning Receipt (Qty_)_UT] | date filter: Due Date | location filter: Location Code !RL!
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Planning Receipt (Qty_)_TDT] = Rl.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Requisition Line].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Requisition Line]
	  WHERE [CARIMALI S_p_A_$Requisition Line].[Type] = 2
	  AND CAST([Due Date] as DATE) <= CAST(GETDATE() as DATE)
	  GROUP BY [No_]
     ) as Rl
   ON TempBOM.partChild = Rl.[No_]')

-- [Planning Receipt (Qty_)] | date filter: Due Date | location filter: Location Code !RL!
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Planning Receipt (Qty_)] = Rl.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Requisition Line].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Requisition Line]
	  WHERE [CARIMALI S_p_A_$Requisition Line].[Type] = 2
	  GROUP BY [No_]
     ) as Rl
   ON TempBOM.partChild = Rl.[No_]')

-- [Scheduled Receipt (Qty_)] || date filter: [Due Date] -- location filter: [Location Code] | status : confermato (2) rilasciato (3)
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Scheduled Receipt (Qty_)] = PrO.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Prod_ Order Line].[Remaining Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Prod_ Order Line]
	  WHERE ([CARIMALI S_p_A_$Prod_ Order Line].[Status] = 2 or [CARIMALI S_p_A_$Prod_ Order Line].[Status] = 3)
	  GROUP BY [Item No_]
     ) as PrO
   ON TempBOM.partChild = PrO.[Item No_]')

   -- [Scheduled Receipt (Qty_)_TDT] || date filter: [Due Date] -- location filter: [Location Code] | status : confermato (2) rilasciato (3)
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Scheduled Receipt (Qty_)_TDT] = PrO.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Prod_ Order Line].[Remaining Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Prod_ Order Line]
	  WHERE ([CARIMALI S_p_A_$Prod_ Order Line].[Status] = 2 or [CARIMALI S_p_A_$Prod_ Order Line].[Status] = 3)
	  AND CAST([Due Date] as DATE) <= CAST(GETDATE() as DATE)
	  GROUP BY [Item No_]
     ) as PrO
   ON TempBOM.partChild = PrO.[Item No_]')

-- [Planned Order Receipt (Qty_)] || date filter: [Due Date] -- location filter: [Location Code] | status : pianificato (1)
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Planned Order Receipt (Qty_)] = PrO.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Prod_ Order Line].[Remaining Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Prod_ Order Line]
	  WHERE ([CARIMALI S_p_A_$Prod_ Order Line].[Status] = 1)
	  GROUP BY [Item No_]
     ) as PrO
   ON TempBOM.partChild = PrO.[Item No_]')

-- [Planned Order Receipt (Qty_)] || date filter: [Due Date] -- location filter: [Location Code] | status : pianificato (1)
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Planned Order Receipt (Qty_)_TDT] = PrO.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Prod_ Order Line].[Remaining Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Prod_ Order Line]
	  WHERE ([CARIMALI S_p_A_$Prod_ Order Line].[Status] = 1)
	  AND CAST([Due Date] as DATE) <= CAST(GETDATE() as DATE)
	  GROUP BY [Item No_]
     ) as PrO
   ON TempBOM.partChild = PrO.[Item No_]')

-- [Purch. Req. Receipt (Qty_)] || date filter: [Due Date] | location filter: [Location Code] !RL!
   EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Purch_ Req_ Receipt (Qty_)] = Rl2.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Requisition Line].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Requisition Line]
	  WHERE [CARIMALI S_p_A_$Requisition Line].[Type] = 2 AND [Planning Line Origin] = ''''
	  GROUP BY [No_]
     ) as Rl2
   ON TempBOM.partChild = Rl2.[No_]')

-- [Purch. Req. Receipt (Qty_)_TDT] || date filter: [Due Date] | location filter: [Location Code] !RL!
   EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Purch_ Req_ Receipt (Qty_)_TDT] = Rl2.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Requisition Line].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Requisition Line]
	  WHERE [CARIMALI S_p_A_$Requisition Line].[Type] = 2 AND [Planning Line Origin] = ''''
	  AND CAST([Due Date] as DATE) <= CAST(GETDATE() as DATE)
	  GROUP BY [No_]
     ) as Rl2
   ON TempBOM.partChild = Rl2.[No_]')

/* [Qty_ in Transit] || date filter: [Receipt Date] -- location filter: [Transfer-to Code]
   EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ in Transit] = TrL.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Transfer Line].[Qty_ in Transit (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Transfer Line]
	  WHERE [Derived From Line No_] = 0
	  GROUP BY [Item No_]
     ) as TrL
   ON TempBOM.partChild = TrL.[Item No_]') */

-- [Qty_ in Transit] || date filter: [Receipt Date] -- location filter: [Transfer-to Code]
-- [Trans_ Ord_ Receipt (Qty_)] || date filter: [Receipt Date] -- location filter: [Transfer-to Code]
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ in Transit] = TrL.Tot
	,TempBOM.[Trans_ Ord_ Receipt (Qty_)] = TrL.Tot2
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Transfer Line].[Qty_ in Transit (Base)]) as Tot,
	  SUM([CARIMALI S_p_A_$Transfer Line].[Outstanding Qty_ (Base)]) as Tot2
	  FROM [CARIMALI S_p_A_$Transfer Line]
	  WHERE [Derived From Line No_] = 0
	  GROUP BY [Item No_]
     ) as TrL
   ON TempBOM.partChild = TrL.[Item No_]')

-- [Qty_ in Transit_TDT] || date filter: [Receipt Date] -- location filter: [Transfer-to Code]
-- [Trans_ Ord_ Receipt (Qty_)_TDT] || date filter: [Receipt Date] -- location filter: [Transfer-to Code]
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ in Transit_TDT] = TrL.Tot
	,TempBOM.[Trans_ Ord_ Receipt (Qty_)_TDT] = TrL.Tot2
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Transfer Line].[Qty_ in Transit (Base)]) as Tot,
	  SUM([CARIMALI S_p_A_$Transfer Line].[Outstanding Qty_ (Base)]) as Tot2
	  FROM [CARIMALI S_p_A_$Transfer Line]
	  WHERE [Derived From Line No_] = 0
	  AND CAST([Receipt Date] as DATE) <= CAST(GETDATE() as DATE)
	  GROUP BY [Item No_]
     ) as TrL
   ON TempBOM.partChild = TrL.[Item No_]')

-- [Reserved Qty_ on Inventory] || location filter: Location Code
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Reserved Qty_ on Inventory] = RE.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Reservation Entry].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Reservation Entry]
	  WHERE [CARIMALI S_p_A_$Reservation Entry].[Source Type] = 32 AND
	  [CARIMALI S_p_A_$Reservation Entry].[Source Subtype] = 0 AND
	  [CARIMALI S_p_A_$Reservation Entry].[Reservation Status] = 0
	  GROUP BY [Item No_]
     ) as RE
   ON TempBOM.partChild = RE.[Item No_]')

-- [Inventory] | date filter: Due Date | location filter: [Location Code] addictional [Serial No.]
-- [Drop Shipment]	[Drop Shipment Filter]
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Inventory] = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [item No_],SUM([CARIMALI S_p_A_$Item Ledger Entry].Quantity) as Tot
	  FROM [CARIMALI S_p_A_$Item Ledger Entry]
	  GROUP BY [item No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[Item No_]')

---- CALC GROSS REQ DATA ~ ..01/12/9999

-- [Scheduled Need (Qty_)] || date filter: [Due Date] | location filter: [Location Code]
-- 0-Simulated,1-Planned,2-Firm Planned,3-Released,4-Finished
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Scheduled Need (Qty_)] = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [item No_],SUM([CARIMALI S_p_A_$Prod_ Order Component].[Remaining Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Prod_ Order Component]
	  WHERE ([CARIMALI S_p_A_$Prod_ Order Component].[Status] > 0 AND [CARIMALI S_p_A_$Prod_ Order Component].[Status] < 4)
	  GROUP BY [item No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[Item No_]')
   
--[Planning Issues (Qty_)] || date filter: [Due Date] | location filter: [Location Code]

EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Planning Issues (Qty_)] = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [item No_],SUM([CARIMALI S_p_A_$Planning Component].[Expected Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Planning Component]
	  GROUP BY [item No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[Item No_]')

-- [Planning Transfer Ship_ (Qty)_] || date filter: [Transfer Shipment Date]
-- [Replenishment System]0- Purchase,1- Prod. Order,2- Transfer,3- Assembly,-4 || [Type] 0-,1- G/L Account,2- Item
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Planning Transfer Ship_ (Qty)_]  = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Requisition Line].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Requisition Line]
	  WHERE [CARIMALI S_p_A_$Requisition Line].[Type] = 2 AND [CARIMALI S_p_A_$Requisition Line].[Replenishment System] = 2 
	  GROUP BY [No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[No_]')

-- [Qty_ on Sales Order] || date filter: Shipment Date | location filter : Location Code
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ on Sales Order]  = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Sales Line].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Sales Line]
	  WHERE [CARIMALI S_p_A_$Sales Line].[Type] = 2 AND [CARIMALI S_p_A_$Sales Line].[Document Type] = 1 
	  GROUP BY [No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[No_]')



-- SKIPPED NO RECORD [Qty_ on Service Order]
-- SKIPPED NO RECORD [Qty_ on Job Order]

--[Trans. Ord. Shipment (Qty.)] || date filter: [Shipment Date] | location filter [Transfer-from Code]
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Trans. Ord. Shipment (Qty_)]  = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Transfer Line].[Outstanding Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Transfer Line]
	  WHERE [CARIMALI S_p_A_$Transfer Line].[Derived From Line No_] = 0
	  GROUP BY [Item No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[Item No_]')

-- SKIPPED NO RECORD [Qty. on Asm. Component]

--|| date filter:[Expected Receipt Date] | location filter [Location Code]
-- 0- quote,1- Order,2- Invoice,3- Credit Memo,4- Blanket Order,5- Return Order
-- [Drop Shipment Filter]

EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Qty_ on Purch_ Return] = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [No_],SUM([CARIMALI S_p_A_$Purchase Line].[Outstanding Qty_ (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Purchase Line]
	  WHERE [CARIMALI S_p_A_$Purchase Line].[Document Type] = 5 AND [CARIMALI S_p_A_$Purchase Line].[Type] = 2
	  GROUP BY [No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[No_]')

-- [Res_ Qty_ on Req_ Line] || date filter : Expected Receipt Date | lacation filter : Location Code
-- [Reservation Status] = 0 azzera tutto
EXEC('UPDATE
    TempBOM
SET
    TempBOM.[Res_ Qty_ on Req_ Line]  = Ile.Tot
	FROM TempBOM INNER JOIN
	 ( 
	  SELECT [Item No_],SUM([CARIMALI S_p_A_$Reservation Entry].[Quantity (Base)]) as Tot
	  FROM [CARIMALI S_p_A_$Reservation Entry]
	  WHERE [CARIMALI S_p_A_$Reservation Entry].[Source Type] = 246 AND [CARIMALI S_p_A_$Reservation Entry].[Source Subtype] = 0
	  AND [CARIMALI S_p_A_$Reservation Entry].[Reservation Status] = 0
	  GROUP BY [Item No_]
     ) as Ile
   ON TempBOM.partChild = Ile.[Item No_]')

-- [replenishmentSystem]

EXEC('UPDATE
    TempBOM
SET
    TempBOM.[replenishmentSystem] = [CARIMALI S_p_A_$Item].[Replenishment System],
	TempBOM.[No Picking Required] = [CARIMALI S_p_A_$Item].[No Picking Required],
	TempBOM.[Item Status] = [CARIMALI S_p_A_$Item].[Item Status],
	TempBOM.[Critical] = [CARIMALI S_p_A_$Item].[Critical],
	TempBOM.[Certified] = [CARIMALI S_p_A_$Item].[Certified]

	FROM TempBOM INNER JOIN [CARIMALI S_p_A_$Item] ON [CARIMALI S_p_A_$Item].[No_] = TempBOM.partChild')

--[BackOrderQty]
EXEC('UPDATE TempBOM SET [BackOrderQty] = T.Tot 
 FROM TempBOM tb1 CROSS APPLY
 (SELECT ([Qty_ on Purch_ Order_TDT]+[Scheduled Receipt (Qty_)_TDT]+
 [Planned Order Receipt (Qty_)_TDT]+[Qty_ in Transit_TDT]+[Trans_ Ord_ Receipt (Qty_)_TDT]+
 [Planning Receipt (Qty_)_TDT]+[Purch_ Req_ Receipt (Qty_)_TDT]) as Tot FROM
 TempBOM tb2 where tb1.partChild = tb2.partChild) as T')

--[GrossRequirement]
EXEC('UPDATE TempBOM SET [GrossRequirement] = T.Tot 
 FROM TempBOM tb1 CROSS APPLY
 (SELECT ([Scheduled Need (Qty_)]+[Planning Issues (Qty_)]+[Planning Transfer Ship_ (Qty)_]+
 [Qty_ on Sales Order]+[Trans_ Ord_ Receipt (Qty_)]+[Qty_ on Purch_ Return]
 ) as Tot FROM
 TempBOM tb2 where tb1.partChild = tb2.partChild) as T')