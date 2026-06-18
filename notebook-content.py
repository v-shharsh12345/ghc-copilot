# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse_name": "",
# META       "default_lakehouse_workspace_id": ""
# META     },
# META     "environment": {
# META       "environmentId": "35056680-d341-4859-8cee-2906c6672ac1",
# META       "workspaceId": "25b2ebd6-eccc-48eb-8f72-0269361e4c25"
# META     }
# META   }
# META }

# MARKDOWN ********************

# ###### Project Name: Sales
# ###### Notebook Stage: Gold
# ###### Notebook Name : Sales_Gold_FactSales
# ###### Purpose: Notebook for refreshing FactSales
# ###### Parameter Info:
# ###### Revision History:
# | Date     |     Author    |  Description  |  Execution Time  |
# |----------|:-------------:|--------------:|----------------- |
# |Oct 4, 2024|v-parvgupta|Created NoteBook for FactSales For Sales| 1:30 hr||
# |Jun 06, 2025|v-rosyadav| Added changes for IAP| 1:30 hr||
# |Aug 01, 2025|v-rosyadav| Updated join condition as per roll over changes| 1:30 hr |

# CELL ********************

%run CommonUtilitiesFunctions

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

%run Sales_ETL_Tools

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

StreamName = "Sales"
Stage="Gold"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

NotebookName=fabric.resolve_item_name(notebookutils.runtime.context['currentNotebookId'])
Result=GetNotebookStatus(NotebookName,StreamName,Stage)
if '0' in Result:
    notebookutils.notebook.exit("0")
elif '-1' in Result:
    System.exit(-1)
elif '2' in Result:
    notebookutils.notebook.exit("2")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

WorkspaceIdDev=GetWorkspaceIDLakehouseID(StreamName)["WorkspaceID"]
LakehouseIdDev=GetWorkspaceIDLakehouseID(StreamName)["LakehouseID"]

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

WorkspaceId="daa3aeb2-a925-4bfe-91ea-7bb1fec7d6f8"
LakehouseId="902aafd9-1e93-426e-a346-d8930194137d"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

PublishSchema = GetPublishSchema(WorkspaceId,LakehouseId,StreamName,Stage)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

LatestPublishSchema = GetLatestPublishedSchema(WorkspaceId,LakehouseId,StreamName,Stage)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimSalesProduct").createOrReplaceTempView("DimProduct_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/FactECSPurchase").createOrReplaceTempView("FactECSPurchase_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimSPLAR").createOrReplaceTempView("DimSPLAR_gold")
getDataframe(WorkspaceId, LakehouseId, "Silver/DimSKUGroupType_Master").createOrReplaceTempView("DimSKUGroupType_Master_gold") 
getDataframe(WorkspaceIdDev, LakehouseIdDev, PublishSchema + "/DimPartnerAssociation").createOrReplaceTempView("DimPartnerAssociation_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/FactDistiSales").createOrReplaceTempView("FactDistiSales_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimPricingLevel").createOrReplaceTempView("DimPricingLevel_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimBusiness").createOrReplaceTempView("DimBusiness_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimUnifiedPartner").createOrReplaceTempView("DimUnifiedPartner_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimSalesTime").createOrReplaceTempView("DimTime_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimFieldGeography").createOrReplaceTempView("DimFieldGeography_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/FieldGeographyDefinition").createOrReplaceTempView("FieldGeographyDefinition_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimAccountGeographyHierarchy").createOrReplaceTempView("DimAccountGeographyHierarchy_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimOrganizationSubSegment").createOrReplaceTempView("DimOrganizationSubSegment_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimSalesCustomer").createOrReplaceTempView("DimCustomer_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimCustomProduct").createOrReplaceTempView("DimCustomProduct_Gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimCustomRevSumHierarchy").createOrReplaceTempView("DimCustomRevSumHierarchy_Gold")
getDataframe(WorkspaceId, LakehouseId, "Silver" + "/Dim_ActualMWSecurityAllocations").createOrReplaceTempView("Dim_ActualMWSecurityAllocations")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimSalesGeography").createOrReplaceTempView("DimGeography_Gold")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

spark.sql(''' 
SELECT DISTINCT DT.FiscalMonthName
		,DT.FiscalMonthID
		,CAST(DT.FirstDayOfMonth AS DATE) AS FMStartDate
FROM DimTime_gold DT 
WHERE FiscalMonthID > 312
''').createOrReplaceTempView("FiscalMonths_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(''' 
    WITH CTE 
    AS 
    (
    SELECT DS.SPLARID,DS.SPLARKey,ROW_NUMBER() OVER (Partition BY DS.SPLARID ORDER BY DS.SPLARKEY) AS SR
    FROM DimSPLAR_gold DS
    )
    SELECT C.SPLARID 
    ,C.SPLARKey 
    FROM cte C
    WHERE SR = 1 
''').createOrReplaceTempView("SPLAR_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceId, LakehouseId, f"{PublishSchema}" + "/DimRefreshedMonthConfig").createOrReplaceTempView("DimRefreshedMonthConfig_gold")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

minFiscalMonthID = spark.sql("SELECT MinFiscalMonthID FROM DimRefreshedMonthConfig_gold").collect()[0][0]
maxFiscalMonthID = spark.sql("SELECT MaxFiscalMonthID FROM DimRefreshedMonthConfig_gold").collect()[0][0]

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(f'''
    SELECT DISTINCT SubscriptionKey,AgreementID,Enrollment,FiscalMonthID FROM FactECSPurchase_gold WHERE FiscalMonthID BETWEEN {minFiscalMonthID}-1 AND {maxFiscalMonthID}
''').createOrReplaceTempView("SubscriptionsAgreements_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(''' 
SELECT DISTINCT ProductKey AS ProductId, ProductFamilyName, ReportingProductname
FROM DimProduct_gold 
''').createOrReplaceTempView("Product_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(''' 
SELECT DISTINCT PlanKey, Plan
FROM DimSKUGroupType_Master_gold
''').createOrReplaceTempView("DimSKUGroupType_Master_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(''' 
SELECT DISTINCT PartnerID, UpstreamName, UnifiedPartnerKey  
FROM DimUnifiedPartner_gold
''').createOrReplaceTempView("DimUnifiedPartner_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC CREATE OR REPLACE TEMP VIEW DimUnifiedPartner_tmp AS
# MAGIC SELECT DISTINCT
# MAGIC   PartnerID,
# MAGIC   UpstreamName,
# MAGIC   UnifiedPartnerKey
# MAGIC FROM DimUnifiedPartner_gold
# MAGIC WHERE NOT (
# MAGIC   LOWER(TRIM(PartnerID)) = '0'
# MAGIC   AND LOWER(TRIM(UpstreamName)) = 'pcaccount'
# MAGIC   AND LOWER(TRIM(CAST(UnifiedPartnerKey AS STRING))) = 'csp100000'
# MAGIC )

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.types import StructType, StructField, StringType, IntegerType, LongType

schema = StructType([
    StructField("SubscriptionKey", LongType(), True),
    StructField("AgreementID", StringType(), True),
    StructField("Enrollment", StringType(), True),
    StructField("FiscalMonthID", IntegerType(), True)
])



schemaname = 'IntermediateTables'
tablename = 'SubscriptionsMissing_tmp1'
table_path = f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}"


if check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
    notebookutils.fs.rm(table_path, recurse=True)
    print(f"Table {schemaname}/{tablename} removed successfully.")


df = spark.createDataFrame([], schema)
df.write \
    .mode("overwrite") \
    .format("delta") \
    .partitionBy("FiscalMonthID") \
    .option("mergeSchema", "true") \
    .save(table_path)

print(f"Table {schemaname}/{tablename} created successfully.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import threading
processed_months = []
failed_months = []

def pinsert(fiscal_month_id):
    try:
        print(f"Processing SubscriptionsMissing_tmp1 for fiscal month id: {fiscal_month_id}")
        df = spark.sql(f''' 
        SELECT SubscriptionKey, AgreementID, Enrollment, {fiscal_month_id} as FiscalMonthID
        FROM (
            (
                SELECT SubscriptionKey, AgreementID, Enrollment
                FROM SubscriptionsAgreements_tmp 
                WHERE FiscalMonthID = {fiscal_month_id-1}
                EXCEPT 
                SELECT SubscriptionKey, AgreementID, Enrollment
                FROM SubscriptionsAgreements_tmp 
                WHERE FiscalMonthID = {fiscal_month_id}
            ) 
            UNION 
            SELECT SubscriptionKey, AgreementID, Enrollment 
            FROM SubscriptionsAgreements_tmp 
            WHERE FiscalMonthID = {fiscal_month_id}
        )
        ''')

        df.write.format("delta") \
            .mode("overwrite") \
            .option("mergeSchema", "true")\
            .option("replaceWhere", f"FiscalMonthId = {fiscal_month_id}") \
            .partitionBy("FiscalMonthId") \
            .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/SubscriptionsMissing_tmp1")
        
        processed_months.append(fiscal_month_id)
        print(f"Successfully processed SubscriptionsMissing_tmp1 for fiscal month id: {fiscal_month_id}")
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Processing SubscriptionsMissing_tmp1 for fiscal month id: {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids = spark.sql(f""" SELECT DISTINCT fiscalMonthID FROM dimtime_gold 
                                WHERE FiscalMonthID >= {minFiscalMonthID} AND FiscalMonthID <= {maxFiscalMonthID}  
                                ORDER BY FiscalMonthID
                  """).collect() 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = pinsert,
            target_table = 'SubscriptionsMissing_tmp1',
            max_retry_count = 3,
            max_concurrent_threads  = 20,
            processed_months = processed_months,
            failed_months = failed_months
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceIdDev, LakehouseIdDev, "IntermediateTables/SubscriptionsMissing_tmp1").createOrReplaceTempView("SubscriptionsMissing_tmp1")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

failed_months = []
processed_months = []

def insert_net_data(fiscal_month_id):
    try:
        print(f"Processing ECSNetUnits_Base for fiscal month id: {fiscal_month_id}")
        previous_fiscal_month_id = fiscal_month_id - 1
        schemaname = 'IntermediateTables'
        tablename = f'ECSNetUnits_Base_{fiscal_month_id}'
        table_path = f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}"
        if check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
          notebookutils.fs.rm(table_path, recurse=True)

        
        df = spark.sql(f''' 
        SELECT A.PartnerKey_Used 
               ,A.SubscriptionKey 
               ,A.UnitStatusKey 
               ,CASE 
                   WHEN DUPR.PartnerID IS NOT NULL AND LOWER(DUPR.UpstreamName) = 'pcaccount' 
                       THEN DUPR.UnifiedPartnerKey 
                   ELSE A.ResellerTPID 
               END AS ResellerTPID 
               ,A.PricingLevelKey 
               ,A.CustomerTPID 
               ,A.AdvisorTPID 
               ,A.PartnerTPID 
               ,CASE 
                   WHEN DUPD.PartnerID IS NOT NULL AND LOWER(DUPD.UpstreamName) = 'pcaccount' 
                       THEN DUPD.UnifiedPartnerKey 
                   ELSE A.DistributorTPID_Calc 
               END AS DistributorTPID_Calc
               ,A.OlServiceFlagKey 
               ,A.DetailSalesModelKey 
               ,A.ReportedSubsegmentKey 
               ,A.DetailTransactionTypeId 
               ,A.CreditedSubsidiaryKey as SubsidiaryID
               ,A.CountryId
               ,A.CSPPartnerID
               ,A.ReconType
               ,A.UserTypeKey 
               ,A.PurchaseTypeKey 
               ,A.ProgramOfferingTypeID 
               ,A.ProgramOfferingID 
               ,A.ProgramId 
               ,A.BillingTypeID 
               ,A.PurchaseOrderTypeID 
               ,A.AgreementID 
               ,A.Enrollment 
               ,A.BusinessID 
               ,A.TenantKey 
               ,A.CustomerGeographyKey 
               ,A.DataSourceID 
               ,A.LicenseAgreementContractTypeID 
               ,IFNULL(A.CustomerNumber,'-9999') AS CustomerNumber 
               ,A.ProductId 
               ,A.LIRPartnerID 
               ,IFNULL(DS.SPLARKey, 0) AS SPLARKey 
               ,RP.ReportingProductname 
               ,IFNULL(DSKUM.PlanKey, -9999) AS PlanKey 
               ,FM.FMStartDate 
               ,DPA.AssociationID 
               ,A.BillingOptionID 
               ,0 AS IsDisti 
               ,A.SoldSeats 
               ,A.AgreementStatusID
               ,SoldSeats - LAG(SoldSeats, 1, 0) OVER ( PARTITION BY A.PartnerKey_Used ,A.SubscriptionKey ,A.UnitStatusKey ,CASE WHEN DUPR.PartnerID IS NOT NULL AND LOWER(DUPR.UpstreamName) = 'pcaccount' THEN DUPR.UnifiedPartnerKey ELSE A.ResellerTPID END ,A.PricingLevelKey ,A.CustomerTPID ,A.AdvisorTPID ,A.PartnerTPID ,CASE WHEN DUPD.PartnerID IS NOT NULL AND LOWER(DUPD.UpstreamName) = 'pcaccount' THEN DUPD.UnifiedPartnerKey ELSE A.DistributorTPID_Calc END ,A.OlServiceFlagKey ,A.DetailSalesModelKey ,A.StdRptgMidReportedSubsegmentKey ,A.ReportedSubsegmentKey ,A.DetailTransactionTypeId ,A.CreditedSubsidiaryKey ,A.UserTypeKey ,A.PurchaseTypeKey ,A.ProgramOfferingTypeID ,A.ProgramOfferingID ,A.ProgramID ,A.BillingTypeID ,A.PurchaseOrderTypeID ,A.AgreementID ,A.Enrollment ,A.BusinessID ,A.TenantKey ,A.CustomerGeographyKey ,A.DataSourceID ,A.LicenseAgreementContractTypeID ,IFNULL(A.CustomerNumber,'-9999') ,A.ProductId ,A.LIRPartnerID ,IFNULL(DS.SPLARKey, 0) ,IFNULL(DSKUM.PlanKey, -9999) ,DPA.AssociationID ,A.AgreementStatusID ,A.BillingOptionID ORDER BY A.FiscalMonthID ) AS NetSoldSeats 
               ,LEAD(SoldSeats, 1, NULL) OVER ( PARTITION BY A.PartnerKey_Used ,A.SubscriptionKey ,A.UnitStatusKey ,CASE WHEN DUPR.PartnerID IS NOT NULL AND LOWER(DUPR.UpstreamName) = 'pcaccount' THEN DUPR.UnifiedPartnerKey ELSE A.ResellerTPID END ,A.PricingLevelKey ,A.CustomerTPID ,A.AdvisorTPID ,A.PartnerTPID ,CASE WHEN DUPD.PartnerID IS NOT NULL AND LOWER(DUPD.UpstreamName) = 'pcaccount' THEN DUPD.UnifiedPartnerKey ELSE A.DistributorTPID_Calc END ,A.OlServiceFlagKey ,A.DetailSalesModelKey ,A.StdRptgMidReportedSubsegmentKey ,A.ReportedSubsegmentKey ,A.DetailTransactionTypeId ,A.CreditedSubsidiaryKey ,A.UserTypeKey ,A.PurchaseTypeKey ,A.ProgramOfferingTypeID ,A.ProgramOfferingID ,A.ProgramID ,A.BillingTypeID ,A.PurchaseOrderTypeID ,A.AgreementID ,A.Enrollment ,A.BusinessID ,A.TenantKey ,A.CustomerGeographyKey ,A.DataSourceID ,A.LicenseAgreementContractTypeID ,IFNULL(A.CustomerNumber,'-9999') ,A.ProductId ,A.LIRPartnerID ,IFNULL(DS.SPLARKey, 0) ,IFNULL(DSKUM.PlanKey, -9999) ,DPA.AssociationID ,A.BillingOptionID ,A.AgreementStatusID ORDER BY A.FiscalMonthID ) AS NetSoldSeatsLost 
               ,A.DeployedSeats 
               ,DeployedSeats - LAG(DeployedSeats, 1, 0) OVER ( PARTITION BY A.PartnerKey_Used ,A.SubscriptionKey ,A.UnitStatusKey ,CASE WHEN DUPR.PartnerID IS NOT NULL AND LOWER(DUPR.UpstreamName) = 'pcaccount' THEN DUPR.UnifiedPartnerKey ELSE A.ResellerTPID END ,A.PricingLevelKey ,A.CustomerTPID ,A.AdvisorTPID ,A.PartnerTPID ,CASE WHEN DUPD.PartnerID IS NOT NULL AND LOWER(DUPD.UpstreamName) = 'pcaccount' THEN DUPD.UnifiedPartnerKey ELSE A.DistributorTPID_Calc END ,A.OlServiceFlagKey ,A.DetailSalesModelKey ,A.StdRptgMidReportedSubsegmentKey ,A.ReportedSubsegmentKey ,A.DetailTransactionTypeId ,A.CreditedSubsidiaryKey ,A.UserTypeKey ,A.PurchaseTypeKey ,A.ProgramOfferingTypeID ,A.ProgramOfferingID ,A.ProgramID ,A.BillingTypeID ,A.PurchaseOrderTypeID ,A.AgreementID ,A.Enrollment ,A.BusinessID ,A.TenantKey ,A.CustomerGeographyKey ,A.DataSourceID ,A.LicenseAgreementContractTypeID ,IFNULL(A.CustomerNumber,'-9999') ,A.ProductId ,A.LIRPartnerID ,IFNULL(DS.SPLARKey, 0) ,IFNULL(DSKUM.PlanKey, -9999) ,DPA.AssociationID ,A.BillingOptionID ,A.AgreementStatusID ORDER BY A.FiscalMonthID ) AS NetDeployedSeats 
               ,A.ActualRevenueAmt AS SoldSeatsRevenue 
               ,A.ServiceRevenueAmt AS ServiceRevenue 
               ,A.ActualLicenseCnt AS Licenses 
               ,A.fiscalmonthid
               ,A.PublicCustomerNumber
               ,A.OrganizationTypeID
         FROM FactECSPurchase_gold A 
         INNER JOIN Product_tmp RP 
           ON RP.ProductID = A.ProductID 
         INNER JOIN FiscalMonths_tmp FM 
           ON A.FiscalMonthID = FM.FiscalMonthID 
         INNER JOIN DimPartnerAssociation_gold DPA 
           ON A.ResellerTPID = DPA.ResellerPartnerID 
           AND A.AdvisorTPID = DPA.AdvisorTPID 
           AND A.DistributorTPID_Calc = DPA.DistributorPartnerID 
           AND A.PartnerKey_Used = DPA.PartnerID 
           AND A.SubscriptionKey = DPA.SubscriptionKey 
           AND IFNULL(A.LIRPartnerID, 0) = IFNULL(DPA.LIRPartnerID, 0)
           AND IFNULL(A.SPLARID, '0') = IFNULL(DPA.SPLARID, '0')
           AND A.CreditedSubsidiaryKey = DPA.CustomerGeographyKey 
           AND A.CSPPartnerID = DPA.CSPPartnerID
           AND A.ResellerTenantID = DPA.ResellerTenantID
           AND LOWER(TRIM(DPA.IsDisti)) = LOWER(TRIM("No"))
           AND A.FiscalMonthID BETWEEN {previous_fiscal_month_id} AND {fiscal_month_id}
         LEFT JOIN SPLAR_tmp DS 
           ON A.SPLARID = DS.SPLARID 
         LEFT JOIN DimSKUGroupType_Master_tmp DSKUM 
           ON RP.ProductFamilyName = DSKUM.PLAN 
         LEFT JOIN DimUnifiedPartner_tmp DUPR
           ON LOWER(A.ResellerTPID) = LOWER(DUPR.PartnerID)
           AND LOWER(DUPR.UpstreamName) = 'pcaccount'     
         LEFT JOIN DimUnifiedPartner_tmp DUPD
           ON LOWER(A.DistributorTPID_Calc) = LOWER(DUPD.PartnerID)
           AND LOWER(DUPD.UpstreamName) = 'pcaccount'
         
        ''')

        
        df.write.format("delta") \
                .mode("overwrite") \
                .option("mergeSchema", "true") \
                .option("replaceWhere", f"FiscalMonthID = {fiscal_month_id}") \
                .partitionBy("FiscalMonthID") \
                .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")
        
        print(f"Successfully processed ECSNetUnits_Base for fiscal month id: {fiscal_month_id}")
        processed_months.append(fiscal_month_id)
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Failed to process fiscal month id {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************




concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = insert_net_data,
            target_table = 'ECSNetUnits_Base',
            max_retry_count = 3,
            max_concurrent_threads  = 10,
            processed_months = processed_months,
            failed_months = failed_months 
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

for fiscal_month_id in range(minFiscalMonthID, maxFiscalMonthID + 1):
    table_name = f"ECSNetUnits_Base_{fiscal_month_id}"
    table_path = f"IntermediateTables/{table_name}"
    getDataframe(WorkspaceIdDev, LakehouseIdDev, table_path).createOrReplaceTempView(table_name) 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC select FiscalMOnthID, Sum(SoldSeatsRevenue) from ECSNetUnits_Base_434 group by 1 

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimSalesSubscription").createOrReplaceTempView("DimSubscription_gold")
getDataframe(WorkspaceId, LakehouseId, PublishSchema + "/DimDetailTransactionType").createOrReplaceTempView("DimDetailTransactionType_gold")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# MARKDOWN ********************

# #### ECSNetUnits_Net

# CELL ********************

from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DecimalType, ShortType, LongType, DateType

schema = StructType([
    StructField("PartnerKey_Used", IntegerType(), True),
    StructField("SubscriptionKey", LongType(), True),
    StructField("UnitStatusKey", ShortType(), True),
    StructField("ResellerTPID", StringType(), True),
    StructField("PricingLevelKey", IntegerType(), True),
    StructField("CustomerTPID", IntegerType(), True),
    StructField("AdvisorTPID", IntegerType(), True),
    StructField("PartnerTPID", IntegerType(), True),
    StructField("DistributorTPID_Calc", StringType(), True),
    StructField("OlServiceFlagKey", IntegerType(), True),
    StructField("DetailSalesModelKey", IntegerType(), True),
    StructField("ReportedSubsegmentKey", IntegerType(), True),
    StructField("DetailTransactionTypeId", IntegerType(), True),
    StructField("CreditedSubsidiaryKey", IntegerType(), True),
    StructField("CountryID", IntegerType(), True),
    StructField("CSPPartnerID", StringType(), True),
    StructField("ReconType", StringType(), True),
    StructField("UserTypeKey", IntegerType(), True),
    StructField("PurchaseTypeKey", IntegerType(), True),
    StructField("ProgramOfferingTypeID", ShortType(), True),
    StructField("ProgramOfferingID", ShortType(), True),
    StructField("ProgramID", IntegerType(), True),
    StructField("BillingTypeID", ShortType(), True),
    StructField("PurchaseOrderTypeID", ShortType(), True),
    StructField("AgreementID", StringType(), True),
    StructField("Enrollment", StringType(), True),
    StructField("BusinessID", IntegerType(), True),
    StructField("FiscalMonthID", IntegerType(), True),
    StructField("TenantKey", LongType(), True),
    StructField("CustomerGeographyKey", IntegerType(), True),
    StructField("DataSourceID", ShortType(), True),
    StructField("LicenseAgreementContractTypeID", ShortType(), True),
    StructField("CustomerNumber", StringType(), True),
    StructField("productId", IntegerType(), True),
    StructField("LIRPartnerID", LongType(), True),
    StructField("SPLARKey", IntegerType(), True),
    StructField("ReportingProductname", StringType(), True),
    StructField("PlanKey", IntegerType(), True),
    StructField("FMStartDate", DateType(), True),
    StructField("AssociationID", LongType(), True),
    StructField("AgreementStatusID", IntegerType(), True),
    StructField("BillingOptionID", IntegerType(), True),
    StructField("IsDisti", IntegerType(), True),
    StructField("SoldSeats", DecimalType(38, 6), True),
    StructField("NetSoldSeats", DecimalType(38, 6), True),
    StructField("NetSoldSeatsLost", DecimalType(38, 6), True),
    StructField("DeployedSeats", DecimalType(38, 6), True),
    StructField("NetDeployedSeats", DecimalType(38, 6), True),
    StructField("SoldSeatsRevenue", DecimalType(38, 6), True),
    StructField("ServiceRevenue", DecimalType(38, 6), True),
    StructField("Licenses", DecimalType(38, 6), True),
    StructField("PublicCustomerNumber", StringType(), True),
    StructField("OrganizationTypeID", IntegerType(), True)
])


schemaname = 'IntermediateTables'
tablename = 'ECSNetUnits_Net'
table_path = f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}"


if check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
    notebookutils.fs.rm(table_path, recurse=True)


df = spark.createDataFrame([], schema)
df.write \
    .mode("overwrite") \
    .format("delta") \
    .partitionBy("FiscalMonthID") \
    .option("mergeSchema", "true") \
    .save(table_path)

print(f"Table {schemaname}/{tablename} created successfully.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

failed_months = []
processed_months = []
processing_months = []

def insert_net_final_data(fiscal_month_id):
    try:
        processing_months.append(fiscal_month_id)
        print(f"Processing ECSNetUnits_Net for fiscal month id: {fiscal_month_id}")
        
        df = spark.sql(f''' 
        SELECT PartnerKey_Used ,CAST(SubscriptionKey AS LONG) as SubscriptionKey, UnitStatusKey ,ResellerTPID ,PricingLevelKey ,CustomerTPID ,AdvisorTPID, PartnerTPID ,DistributorTPID_Calc ,OlServiceFlagKey ,DetailSalesModelKey ,ReportedSubsegmentKey ,DetailTransactionTypeId ,SubsidiaryID AS CreditedSubsidiaryKey ,CountryID ,CSPPartnerID ,ReconType ,UserTypeKey ,PurchaseTypeKey ,ProgramOfferingTypeID ,ProgramOfferingID ,ProgramID ,BillingTypeID ,PurchaseOrderTypeID ,AgreementID ,Enrollment ,BusinessID ,CAST(TenantKey AS BIGINT) ,CustomerGeographyKey ,DataSourceID ,LicenseAgreementContractTypeID ,CustomerNumber ,productId ,LIRPartnerID ,SPLARKey ,ReportingProductname ,PlanKey ,FMStartDate ,AssociationID ,AgreementStatusID ,BillingOptionID ,IsDisti ,SoldSeats ,NetSoldSeats ,NetSoldSeatsLost ,DeployedSeats ,NetDeployedSeats ,CAST(SoldSeatsRevenue AS DECIMAL(38,6)) ,CAST(ServiceRevenue AS DECIMAL(38,6)) ,Licenses , FiscalMonthID, PublicCustomerNumber, OrganizationTypeID
        FROM ECSNetUnits_Base_{fiscal_month_id} A WHERE A.FiscalMonthID = {fiscal_month_id}
        ''')

        df.write.format("delta") \
            .mode("overwrite") \
            .option("mergeSchema", "true") \
            .option("replaceWhere", f"FiscalMonthID = {fiscal_month_id}") \
            .partitionBy("FiscalMonthID") \
            .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")
        
        processed_months.append(fiscal_month_id)
        print(f"Processed ECSNetUnits_Net for fiscalmonth id: {fiscal_month_id}")
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Failed to process fiscal month id {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)
    finally:
        processing_months.remove(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids = spark.sql(f"""
                    SELECT DISTINCT fiscalMonthID 
                    FROM dimtime_gold 
                    WHERE FiscalMonthID >= {minFiscalMonthID} 
                    AND FiscalMonthID <= {maxFiscalMonthID}  
                    ORDER BY FiscalMonthID
""").collect()

concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = insert_net_final_data,
            target_table = 'ECSNetUnits_Net',
            max_retry_count = 3,
            max_concurrent_threads  = 20,
            processed_months = processed_months,
            failed_months = failed_months
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceIdDev, LakehouseIdDev, "IntermediateTables/ECSNetUnits_Net").createOrReplaceTempView("ECSNetUnits_Net")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

failed_months = []
processed_months = []
processing_months = []

def insert_missing_subscriptions_base(fiscal_month_id):
    try:
        processing_months.append(fiscal_month_id)
        print(f"Processing ECSSubscripitionsMissing for fiscal month id: {fiscal_month_id}")
        
        previous_fiscal_month_id = fiscal_month_id - 1
        schemaname = 'IntermediateTables'
        tablename = f'ECSSubscripitionsMissing_{fiscal_month_id}'
        table_path = f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}"
        
        if check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
            notebookutils.fs.rm(table_path, recurse=True)

        df = spark.sql(f''' 
        SELECT 
            A.PartnerKey_Used,
            A.SubscriptionKey,
            A.UnitStatusKey,
            A.ResellerTPID,
            A.PricingLevelKey,
            A.CustomerTPID,
            A.AdvisorTPID,
            A.PartnerTPID,
            A.DistributorTPID_Calc,
            A.OlServiceFlagKey,
            A.DetailSalesModelKey,
            A.ReportedSubsegmentKey,
            A.DetailTransactionTypeId,
            A.SubsidiaryID as CreditedSubsidiaryKey,
            A.CountryID,
            A.CSPPartnerID,
            A.ReconType,
            A.UserTypeKey,
            A.PurchaseTypeKey,
            A.ProgramOfferingTypeID,
            A.ProgramOfferingID,
            A.ProgramId,
            A.BillingTypeID,
            A.PurchaseOrderTypeID,
            A.AgreementID,
            A.Enrollment,
            A.BusinessID,
            ADD_MONTHS(A.FMStartDate, 1) AS FMStartDate,
            CAST(A.TenantKey AS BIGINT),
            A.CustomerGeographyKey,
            A.DataSourceID,
            A.LicenseAgreementContractTypeID,
            A.CustomerNumber,
            A.productId,
            A.LIRPartnerID,
            A.SPLARKey,
            A.ReportingProductName,
            A.PlanKey,
            A.AssociationID,
            A.AgreementStatusID,
            A.BillingOptionID,
            CAST(0 AS DECIMAL(38,6)) AS SoldSeats,
            A.IsDisti,
            -1 * SoldSeats AS NetSoldSeats,
            -1 * SoldSeats AS NetSoldSeatsLost,
            CAST(0 AS DECIMAL(38,6)) AS DeployedSeats,
            -1 * DeployedSeats AS NetDeployedSeats,
            CAST(0 AS DECIMAL(38,6)) AS SoldSeatsRevenue,
            CAST(0 AS DECIMAL(38,6)) AS ServiceRevenue,
            CAST(0 AS DECIMAL(38,6)) AS Licenses,
            A.FiscalMonthID + 1 AS FiscalMonthID,
            A.PublicCustomerNumber,
            A.OrganizationTypeID
        FROM 
            ECSNetUnits_Base_{fiscal_month_id} A
        JOIN 
            SUbscriptionsMissing_tmp1 S 
        ON 
            A.SubscriptionKey = S.SubscriptionKey 
            AND A.AgreementID = S.AgreementID 
            AND A.Enrollment = S.Enrollment 
            AND A.FiscalMonthID + 1 = S.FiscalMonthID 
            AND A.NetSoldSeatsLost IS NULL 
            AND A.FiscalMonthID = {previous_fiscal_month_id}
            AND S.FiscalMonthID = {fiscal_month_id}
        ''')

        df.write.format("delta") \
            .mode("overwrite") \
            .option("mergeSchema", "true") \
            .option("replaceWhere", f"FiscalMonthID = {fiscal_month_id}") \
            .partitionBy("FiscalMonthID") \
            .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")

        processed_months.append(fiscal_month_id)
        print(f"Processed ECSSubscripitionsMissing for fiscal month id: {fiscal_month_id}")
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Failed to process fiscal month id {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)
    finally:
        processing_months.remove(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import threading
import concurrent.futures
fiscalmonth_ids = spark.sql(f"""
                SELECT DISTINCT fiscalMonthID 
                FROM dimtime_gold 
                WHERE FiscalMonthID >= {minFiscalMonthID} 
                AND FiscalMonthID <= {maxFiscalMonthID}  
                ORDER BY FiscalMonthID
""").collect()

concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = insert_missing_subscriptions_base,
            target_table = 'ECSSubscripitionsMissing',
            max_retry_count = 3,
            max_concurrent_threads  = 20,
            processed_months = processed_months,
            failed_months = failed_months
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

for fiscal_month_id in range(minFiscalMonthID, maxFiscalMonthID + 1):
    table_name = f"ECSSubscripitionsMissing_{fiscal_month_id}"
    table_path = f"IntermediateTables/{table_name}"
    getDataframe(WorkspaceIdDev, LakehouseIdDev, table_path).createOrReplaceTempView(table_name)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************


# CELL ********************

from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DecimalType, ShortType, LongType, DateType

ECSSubscripitionsMissing_schema = StructType([
    StructField("PartnerKey_Used", IntegerType(), True),
    StructField("SubscriptionKey", LongType(), True),
    StructField("UnitStatusKey", ShortType(), True),
    StructField("ResellerTPID", StringType(), True),
    StructField("PricingLevelKey", IntegerType(), True),
    StructField("CustomerTPID", IntegerType(), True),
    StructField("AdvisorTPID", IntegerType(), True),
    StructField("PartnerTPID", IntegerType(), True),
    StructField("DistributorTPID_Calc", StringType(), True),
    StructField("OlServiceFlagKey", IntegerType(), True),
    StructField("DetailSalesModelKey", IntegerType(), True),
    StructField("StdRptgMidReportedSubsegmentKey", IntegerType(), True),
    StructField("ReportedSubsegmentKey", IntegerType(), True),
    StructField("DetailTransactionTypeId", IntegerType(), True),
    StructField("CreditedSubsidiaryKey", IntegerType(), True),
    StructField("CountryID", IntegerType(), True),
    StructField("CSPPartnerID", StringType(), True),
    StructField("ReconType", StringType(), True),
    StructField("UserTypeKey", IntegerType(), True),
    StructField("PurchaseTypeKey", IntegerType(), True),
    StructField("ProgramOfferingTypeID", ShortType(), True),
    StructField("ProgramOfferingID", ShortType(), True),
    StructField("ProgramID", IntegerType(), True),
    StructField("BillingTypeID", ShortType(), True),
    StructField("PurchaseOrderTypeID", ShortType(), True),
    StructField("AgreementID", StringType(), True),
    StructField("Enrollment", StringType(), True),
    StructField("BusinessID", IntegerType(), True),
    StructField("FiscalMonthID", IntegerType(), True),
    StructField("FMStartDate", DateType(), True),  
    StructField("TenantKey", LongType(), True),
    StructField("CustomerGeographyKey", IntegerType(), True),
    StructField("DataSourceID", ShortType(), True),
    StructField("LicenseAgreementContractTypeID", ShortType(), True),
    StructField("CustomerNumber", StringType(), True),
    StructField("productId", IntegerType(), True),
    StructField("LIRPartnerID", LongType(), True),
    StructField("SPLARKey", IntegerType(), True),
    StructField("ReportingProductname", StringType(), True),
    StructField("PlanKey", IntegerType(), True),
    StructField("AssociationID", LongType(), True),
    StructField("AgreementStatusID", IntegerType(), True),
    StructField("BillingOptionID", IntegerType(), True),
    StructField("SoldSeats", DecimalType(38, 6), True),
    StructField("IsDisti", IntegerType(), True),
    StructField("NetSoldSeats", DecimalType(38, 6), True),
    StructField("NetSoldSeatsLost", DecimalType(38, 6), True),
    StructField("DeployedSeats", DecimalType(38, 6), True),
    StructField("NetDeployedSeats", DecimalType(38, 6), True),
    StructField("SoldSeatsRevenue", DecimalType(38, 6), True),
    StructField("ServiceRevenue", DecimalType(38, 6), True),
    StructField("Licenses", DecimalType(38, 6), True),
    StructField("PublicCustomerNumber", StringType(), True),
    StructField("OrganizationTypeID", IntegerType(), True)
])

schemaname = 'IntermediateTables'
tablename = 'ECSSubscripitionsMissing_temp'

if not check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
    df_ECSSubscripitionsMissing_temp = spark.createDataFrame([], ECSSubscripitionsMissing_schema)
    df_ECSSubscripitionsMissing_temp.write.mode("overwrite").format("delta").partitionBy("FiscalMonthID").option("mergeSchema", "true").save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")
    print(f"Created Table {schemaname}/{tablename}")
else:
    print(f"Table {schemaname}/{tablename} Already Exists, Skipped!")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

failed_months = []
processed_months = []
processing_months = []

def insert_missing_subscriptions(fiscal_month_id):

    try:
        schemaname = 'IntermediateTables'
        tablename = 'ECSSubscripitionsMissing_temp'

        processing_months.append(fiscal_month_id)
        print(f"Processing ECSSubscripitionsMissing_temp for Fiscal Month ID: {fiscal_month_id}")
        
        df = spark.sql(f''' 
        SELECT 
            A.PartnerKey_Used,
            A.SubscriptionKey,
            A.UnitStatusKey,
            A.ResellerTPID,
            A.PricingLevelKey,
            A.CustomerTPID,
            A.AdvisorTPID,
            A.PartnerTPID,
            A.DistributorTPID_Calc,
            A.OlServiceFlagKey,
            A.DetailSalesModelKey,
            A.ReportedSubsegmentKey,
            A.DetailTransactionTypeId,
            A.CreditedSubsidiaryKey,
            A.CountryID,
            A.CSPPartnerID,
            A.ReconType,
            A.UserTypeKey,
            A.PurchaseTypeKey,
            A.ProgramOfferingTypeID,
            A.ProgramOfferingID,
            A.ProgramId,
            A.BillingTypeID,
            A.PurchaseOrderTypeID,
            A.AgreementID,
            A.Enrollment,
            A.BusinessID,
            A.FMStartDate,
            CAST(A.TenantKey AS BIGINT),
            A.CustomerGeographyKey,
            A.DataSourceID,
            A.LicenseAgreementContractTypeID,
            A.CustomerNumber,
            A.productId,
            A.LIRPartnerID,
            A.SPLARKey,
            A.ReportingProductName,
            A.PlanKey,
            A.AssociationID,
            A.BillingOptionID,
            A.AgreementStatusID,
            A.SoldSeats,
            A.IsDisti,
            A.NetSoldSeats,
            A.NetSoldSeatsLost,
            A.DeployedSeats,
            A.NetDeployedSeats,
            A.SoldSeatsRevenue,
            A.ServiceRevenue,
            A.Licenses,
            A.FiscalMonthID,
            A.PublicCustomerNumber,
            A.OrganizationTypeID
        FROM ECSSubscripitionsMissing_{fiscal_month_id} AS A
        ''')
        df.write.format("delta") \
            .mode("overwrite") \
            .option("mergeSchema", "true") \
            .option("replaceWhere", f"FiscalMonthID = {fiscal_month_id}") \
            .partitionBy("FiscalMonthID") \
            .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/ECSSubscripitionsMissing_temp")
        
        processed_months.append(fiscal_month_id)
        print(f"Processed ECSSubscripitionsMissing_temp for fiscal month id: {fiscal_month_id}")
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Failed to process fiscal month id {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)
    finally:
        processing_months.remove(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids = spark.sql(f"""
            SELECT DISTINCT fiscalMonthID 
            FROM dimtime_gold 
            WHERE FiscalMonthID >= {minFiscalMonthID} 
            AND FiscalMonthID <= {maxFiscalMonthID}  
            ORDER BY FiscalMonthID
""").collect()

concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = insert_missing_subscriptions,
            target_table = 'ECSSubscripitionsMissing_temp',
            max_retry_count = 3,
            max_concurrent_threads  = 20,
            processed_months = processed_months,
            failed_months = failed_months
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceIdDev, LakehouseIdDev, "IntermediateTables/ECSSubscripitionsMissing_temp").createOrReplaceTempView("ECSSubscripitionsMissing_temp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(''' 
SELECT DISTINCT MAX(ProductKey) AS ProductKey,ProductFamilyID,ReportingProductID,ReportingProductname 
FROM DimProduct_gold
GROUP BY ProductFamilyID,ReportingProductID,ReportingProductname
''').createOrReplaceTempView("Products_tmp")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, DecimalType, ShortType, LongType, DateType, ByteType
)

schema = StructType([
    StructField("PartnerID", IntegerType(), True),
    StructField("SubscriptionKey", LongType(), True),
    StructField("SubscriptionStatusKey", ShortType(), True),
    StructField("ResellerTPID", StringType(), True),
    StructField("DetailPricingLevelID", IntegerType(), True),
    StructField("MSSTPID", IntegerType(), True),
    StructField("AdvisorID", IntegerType(), True),
    StructField("PartnerTPID", IntegerType(), True),
    StructField("DistributorPartnerID", StringType(), True),
    StructField("OlServiceFlagKey", IntegerType(), True),
    StructField("DetailSalesModelID", IntegerType(), True),
    StructField("ReportedSubSegmentID", IntegerType(), True),
    StructField("FiscalMonthID", IntegerType(), True),
    StructField("DetailTransactionTypeId", IntegerType(), True),
    StructField("SubsidiaryID", IntegerType(), True),
    StructField("CountryID", IntegerType(), True),
    StructField("CSPPartnerID", StringType(), True),
    StructField("ReconType", StringType(), True),
    StructField("UserTypeID", IntegerType(), True),
    StructField("PurchaseTypeID", IntegerType(), True),
    StructField("ProgramOfferingTypeID", ShortType(), True),
    StructField("ProgramOfferingID", IntegerType(), True),
    StructField("ProgramId", IntegerType(), True),
    StructField("BillingTypeID", ShortType(), True),
    StructField("PurchaseOrderTypeID", ShortType(), True),
    StructField("AgreementID", StringType(), True),
    StructField("Enrollment", StringType(), True),
    StructField("BusinessID", IntegerType(), True),
    StructField("TenantKey", LongType(), True),
    StructField("CustomerGeographyKey", IntegerType(), True),
    StructField("AllocationID", ShortType(), True),
    StructField("LicenseAgreementContractTypeID", ShortType(), True),
    StructField("CustomerNumber", StringType(), True),
    StructField("ProductKey", IntegerType(), True),
    StructField("LIRPartnerID", LongType(), True),
    StructField("SPLARKey", IntegerType(), True),
    StructField("SoldSeatsEOP", DecimalType(38, 6), True),
    StructField("SoldSeats", DecimalType(38, 6), True),
    StructField("DeployedSeatsEOP", DecimalType(38, 6), True),
    StructField("DeployedSeats", DecimalType(38, 6), True),
    StructField("SoldSeatsRevenue", DecimalType(38, 6), True),
    StructField("ServiceBilledRevenue", DecimalType(38, 6), True),
    StructField("Licenses", DecimalType(38, 6), True),
    StructField("SoldSeatsAdds", DecimalType(38, 6), True),
    StructField("SoldSeatsLost", DecimalType(38, 6), True),
    StructField("Product", StringType(), True),
    StructField("PlanKey", IntegerType(), True),
    StructField("IsDisti", IntegerType(), True),
    StructField("FMStartDate", DateType(), True),
    StructField("AssociationID", LongType(), True),
    StructField("UnitType", StringType(), True),
    StructField("StatusFlag", ByteType(), True),
    StructField("SubscriptionID", StringType(), True),
    StructField("BillingOptionID", IntegerType(), True),
    StructField("ChannelMotionKey", IntegerType(), True),
    StructField("PublicCustomerNumber", StringType(), True),
    StructField("OrganizationTypeID", IntegerType(), True)
])


schemaname = f"{PublishSchema}"
tablename = 'FactSales_Full'


if not check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
    df = spark.createDataFrame([], schema)
    df.write.mode("overwrite").format("delta").partitionBy("FiscalMonthID").option("mergeSchema", "true").save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")
    print(f"Created Table {schemaname}/{tablename}")
else:
    print(f"Table {schemaname}/{tablename} Already Exists, Skipped!")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import threading

failed_months = []
processed_months = []
processing_months = []

def insert_fact_sales_full(fiscal_month_id):
    try:
        processing_months.append(fiscal_month_id)
        print(f"Processing FactSales_Full for fiscal month id: {fiscal_month_id}")
        
        df_factsalesfull = spark.sql(f''' 
        SELECT A.PartnerKey_Used AS PartnerID 
        ,CAST(
        CASE 
            WHEN A.SubscriptionKey = 0 AND A.DistributorTPID_Calc NOT IN ('-9999', '124') THEN 0
            WHEN A.SubscriptionKey = 0 AND A.DistributorTPID_Calc IN ('-9999', '124') THEN -9999
            ELSE A.SubscriptionKey
        END AS LONG
        ) AS SubscriptionKey

        ,A.UnitStatusKey AS SubscriptionStatusKey 
        ,A.ResellerTPID 
        ,A.PricingLevelKey AS DetailPricingLevelID 
        ,A.CustomerTPID AS MSSTPID 
        ,A.AdvisorTPID AS AdvisorID 
        ,A.PartnerTPID 
        ,A.DistributorTPID_Calc AS DistributorTPID 
        ,A.OlServiceFlagKey 
        ,A.DetailSalesModelKey AS DetailSalesModelID 
        ,A.ReportedSubsegmentKey AS ReportedSubSegmentID 
        ,A.DetailTransactionTypeId 
        ,A.CreditedSubsidiaryKey AS SubsidiaryID 
        ,A.CountryID
        ,A.CSPPartnerID
        ,A.ReconType
        ,A.UserTypeKey AS UserTypeID 
        ,A.PurchaseTypeKey AS PurchaseTypeID 
        ,A.ProgramOfferingTypeID 
        ,A.ProgramOfferingID 
        ,A.ProgramId 
        ,A.BillingTypeID 
        ,A.PurchaseOrderTypeID 
        ,A.AgreementID 
        ,A.Enrollment 
        ,A.BusinessID 
        ,CAST(A.TenantKey AS BIGINT) 
        ,A.CustomerGeographyKey 
        ,A.DataSourceID AS AllocationID 
        ,A.LicenseAgreementContractTypeID 
        ,A.CustomerNumber 
        ,A.productId AS ProductKey 
        ,A.LIRPartnerID 
        ,A.SPLARKey 
        ,A.SoldSeats AS SoldSeatsEOP 
        ,A.NetSoldSeats AS SoldSeats 
        ,A.DeployedSeats AS DeployedSeatsEOP 
        ,A.NetDeployedSeats AS DeployedSeats 
        ,A.SoldSeatsRevenue 
        ,A.ServiceRevenue AS ServiceBilledRevenue 
        ,A.Licenses 
        ,CASE 
            WHEN IFNULL(A.NetSoldSeats, 0) < 0 THEN 0 
            ELSE A.NetSoldSeats 
        END AS SoldSeatsAdds 
        ,CASE 
            WHEN IFNULL(A.NetSoldSeats, 0) > 0 THEN 0 
            ELSE A.NetSoldSeats 
        END AS SoldSeatsLost 
        ,A.ReportingProductName AS Product 
        ,PlanKey 
        ,IsDisti
        ,CAST(FMStartDate AS DATE) AS FMStartDate
        ,AssociationID 
        ,DTT.DetailTransactionTypeName AS UnitType 
        ,CASE WHEN A.UnitStatusKey IN ( 1 ,4 ) THEN 1 ELSE 0 END AS StatusFlag 
        ,IFNULL(DS.SubscriptionIdentifierChar, 'No Subscription Found') AS SubscriptionID 
        ,IFNULL(A.BillingOptionID, - 9999) AS BillingOptionID 
        ,CASE 
           WHEN A.ResellerTPID NOT IN ('CSP100000', 'CSP1000000', '0') 
               AND A.DistributorTPID_Calc NOT IN ('CSP100000', 'CSP1000000', '0') 
               AND A.ResellerTPID <> A.DistributorTPID_Calc
               THEN 2 -- Indirect
           WHEN (A.ResellerTPID NOT IN ('CSP100000', 'CSP1000000', '0') 
               AND A.DistributorTPID_Calc IN ('CSP100000', 'CSP1000000', '0'))
               OR (A.ResellerTPID NOT IN ('CSP100000', 'CSP1000000', '0') 
                   AND A.ResellerTPID = A.DistributorTPID_Calc)
               THEN 1 -- Direct
           ELSE 3 -- Unknown
        END AS ChannelMotionKey,
        A.FiscalMonthID,
        A.PublicCustomerNumber,
        A.OrganizationTypeID
        FROM ECSNetUnits_Net A 
        LEFT JOIN DimSubscription_gold DS 
            ON A.SubscriptionKey = DS.SubscriptionKey 
        INNER JOIN DimDetailTransactionType_gold DTT 
            ON A.DetailTransactionTypeId = DTT.DetailTransactionTypeID 
        WHERE FiscalMonthID = {fiscal_month_id} 
        -- MAGIC      
        UNION ALL 
        -- MAGIC      
        SELECT A.PartnerKey_Used 
            ,CAST(CASE 
                WHEN A.SubscriptionKey = 0 AND A.DistributorTPID_Calc NOT IN ( - 9999 ,124 ) THEN 0 
                WHEN A.SubscriptionKey = 0 AND A.DistributorTPID_Calc IN ( - 9999 ,124 ) THEN - 9999 
                ELSE A.SubscriptionKey 
            END AS LONG) AS SubscriptionKey 
            ,A.UnitStatusKey 
            ,A.ResellerTPID 
            ,A.PricingLevelKey 
            ,A.CustomerTPID 
            ,A.AdvisorTPID 
            ,A.PartnerTPID 
            ,A.DistributorTPID_Calc 
            ,A.OlServiceFlagKey 
            ,A.DetailSalesModelKey 
            ,A.ReportedSubsegmentKey 
            ,A.DetailTransactionTypeId 
            ,A.CreditedSubsidiaryKey 
            ,A.CountryID
            ,A.CSPPartnerID
            ,A.ReconType
            ,A.UserTypeKey 
            ,A.PurchaseTypeKey 
            ,A.ProgramOfferingTypeID 
            ,A.ProgramOfferingID 
            ,A.ProgramId 
            ,A.BillingTypeID 
            ,A.PurchaseOrderTypeID 
            ,A.AgreementID 
            ,A.Enrollment 
            ,A.BusinessID 
            ,CAST(A.TenantKey AS BIGINT) 
            ,A.CustomerGeographyKey 
            ,A.DataSourceID 
            ,A.LicenseAgreementContractTypeID 
            ,A.CustomerNumber 
            ,A.productId as ProductKey
            ,A.LIRPartnerID 
            ,A.SPLARKey 
            ,SoldSeats 
            ,A.NetSoldSeats 
            ,A.DeployedSeats 
            ,A.NetDeployedSeats 
            ,A.SoldSeatsRevenue 
            ,A.ServiceRevenue AS ServiceBilledRevenue 
            ,A.Licenses 
            ,0 AS NetSoldSeatsAdd 
            ,A.NetSoldSeatsLost 
            ,A.ReportingProductName AS Product 
            ,A.PlanKey 
            ,A.IsDisti 
            ,CAST(A.FMStartDate AS DATE) AS FMStartDate
            ,A.AssociationID 
            ,DTT.DetailTransactionTypeName AS UnitType 
            ,CASE WHEN A.UnitStatusKey IN ( 1 ,4 ) THEN 1 ELSE 0 END AS StatusFlag 
            ,IFNULL(DS.SubscriptionIdentifierChar, 'No Subscription Found') AS SubscriptionID 
            ,IFNULL(A.BillingOptionID, - 9999) AS BillingOptionID  
            ,CASE 
            WHEN A.ResellerTPID NOT IN ('CSP100000', 'CSP1000000', '0') 
                AND A.DistributorTPID_Calc NOT IN ('CSP100000', 'CSP1000000', '0') 
                AND A.ResellerTPID <> A.DistributorTPID_Calc
                THEN 2 -- Indirect
            WHEN (A.ResellerTPID NOT IN ('CSP100000', 'CSP1000000', '0') 
                AND A.DistributorTPID_Calc IN ('CSP100000', 'CSP1000000', '0'))
                OR (A.ResellerTPID NOT IN ('CSP100000', 'CSP1000000', '0') 
                    AND A.ResellerTPID = A.DistributorTPID_Calc)
                THEN 1 -- Direct
            ELSE 3 -- Unknown
        END AS ChannelMotionKey,
        A.FiscalMonthID,
        A.PublicCustomerNumber,
        A.OrganizationTypeID
        FROM ECSSubscripitionsMissing_temp A 
        LEFT JOIN DimSubscription_gold DS 
            ON A.SubscriptionKey = DS.SubscriptionKey 
        INNER JOIN DimDetailTransactionType_gold DTT 
            ON A.DetailTransactionTypeId = DTT.DetailTransactionTypeID 
        WHERE FiscalMonthID = {fiscal_month_id} 
        -- MAGIC      
        UNION ALL 
        -- MAGIC      
        SELECT 0 AS PartnerID 
        ,CAST(0 AS LONG) AS SubscriptionKey 
        ,- 9999 AS SubscriptionStatusKey 
        ,0 AS ResellerTPID 
        ,FDS.PricingLevelKey AS DetailPricingLevelID 
        ,- 9999 AS MSSTPID 
        ,0 AS AdvisorID 
        ,124 AS PartnerTPID 
        ,FDS.DistiTPID * 10 + 4 AS DistiTPID 
        ,FDS.OlServiceFlagKey 
        ,- 9999 AS DetailSalesModelID 
        ,- 9999 AS ReportedSubsegmentID 
        ,- 9999 AS DetailTransactionTypeId 
        ,FDS.CreditedSubsidiaryKey AS SubsidiaryID 
        ,FDS.CountryID
        ,'00000000-0000-0000-0000-000000000000' AS CSPPartnerID
        ,'' AS ReconType
        ,FDS.UserTypeKey AS UserTypeID 
        ,FDS.PurchaseTypeKey AS PurchaseTypeID 
        ,- 9999 AS ProgramOfferingTypeID 
        ,- 9999 AS ProgramOfferingID 
        ,NULL AS ProgramId 
        ,FDS.BillingTypeID 
        ,FDS.PurchaseOrderTypeID 
        ,NULL AS AgreementID 
        ,NULL AS Enrollment 
        ,FDS.BusinessID 
        ,CAST(- 9999 AS BIGINT) AS TenantKey 
        ,- 9999 AS CustomerGeographyKey 
        ,- 9999 AS AllocationID 
        ,- 9999 AS LicenseAgreementContractTypeID 
        ,'-9999' AS CustomerNumber 
        ,RP.ProductKey 
        ,0 AS LIRPartnerID 
        ,0 AS SPLARKey 
        ,0 AS SoldSeatsEOP 
        ,0 AS SoldSeats 
        ,0 AS DeployedSeatsEOP 
        ,0 AS DeployedSeats 
        ,FDS.ActualRevenueAmt AS SoldSeatsRevenue 
        ,0 AS ServiceBilledRevenue 
        ,FDS.ActualLicenseAmt AS Licenses 
        ,0 AS SoldSeatsAdds 
        ,0 AS SoldSeatsLost 
        ,RP.ReportingProductName AS Product 
        ,CASE 
            WHEN FDS.ProductFamilyKey IS NULL THEN - 9999 
            ELSE (FDS.ProductFamilyKey * 10) + 2 
        END AS PlanKey 
        ,1 AS IsDisti 
        ,CAST(FM.FMStartDate AS DATE) AS FMStartDate
        ,DPA.AssociationID 
        ,'Unknown' AS UnitType 
        ,0 AS StatusFlag 
        ,'No Subscription Found' AS SubscriptionID 
        ,- 9999 AS BillingOptionID 
        ,2 AS ChannelMotionKey,
        FDS.FiscalMonthID,
        '-9999' AS PublicCustomerNumber,
        -9999 AS OrganizationTypeID
        FROM FactDistiSales_gold FDS 
        INNER JOIN Products_tmp RP 
            ON FDS.ProductFamilyKey = RP.ProductFamilyID 
        INNER JOIN FiscalMonths_tmp FM 
            ON FDS.FiscalMonthID = FM.FiscalMonthID 
        INNER JOIN DimPricingLevel_gold PL 
            ON FDS.PricingLevelKey = PL.DetailPricinglevelID 
            AND PL.Is_CSP = 'No' 
        INNER JOIN DimPartnerAssociation_gold DPA 
            ON (FDS.DistiTPID * 10 + 4) = DPA.DistributorPartnerID
            AND FDS.CreditedSubsidiaryKey = DPA.CustomerGeographyKey 
            AND DPA.IsDisti = "Yes" 
            AND FDS.FiscalMonthID = {fiscal_month_id}
                ''')

        df_factsalesfull.write.format("delta") \
            .mode("overwrite") \
            .option("mergeSchema", "true") \
            .option("replaceWhere", f"FiscalMonthID = {fiscal_month_id}") \
            .partitionBy("FiscalMonthID") \
            .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/FactSales_Full")
        
        processed_months.append(fiscal_month_id)
        print(f"Processed FactSales_Full for fiscal month id: {fiscal_month_id}")
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Failed to process fiscal month id {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)
    finally:
        processing_months.remove(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

minFiscalMonthID = 409
maxFiscalMonthID = 441

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids = spark.sql(f"""
    SELECT DISTINCT fiscalMonthID 
    FROM dimtime_gold 
    WHERE FiscalMonthID >= {minFiscalMonthID} 
    AND FiscalMonthID <= {maxFiscalMonthID}  
    ORDER BY FiscalMonthID
""").collect()


concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = insert_fact_sales_full,
            target_table = 'FactSales_Full',
            max_retry_count = 3,
            max_concurrent_threads  = 10,
            processed_months = processed_months,
            failed_months = failed_months
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceId, LakehouseId,"Silver/BillingOption").createOrReplaceTempView("BillingOption_Silver")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

getDataframe(WorkspaceIdDev, LakehouseIdDev, PublishSchema + "/FactSales_Full").createOrReplaceTempView("FactSales_Full")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(''' 
WITH CTE_Fact AS (
  SELECT DISTINCT FA.SubscriptionKey,
   FA.BillingOptionID,
   IFNULL(BO.BillingOptionName,'Unknown') AS BillingOptionName
  FROM FactSales_Full FA
  LEFT JOIN BillingOption_Silver BO
  ON FA.BillingOptionID = BO.BillingOptionID
)
SELECT DISTINCT DS.SubscriptionKey,
FT.BillingOptionID,
DS.SubscriptionStartDate,
DS.SubscriptionEndDate,
FT.BillingOptionName,
CASE
    WHEN DATEDIFF(SubscriptionEndDate, SubscriptionStartDate) <= 35 THEN 'Monthly'
    WHEN DATEDIFF(SubscriptionEndDate, SubscriptionStartDate) > 35 THEN 'Annual'
    ELSE 'Annual-Unknown'
END AS CommitmentTerm,
CASE
    WHEN DATEDIFF(SubscriptionEndDate, SubscriptionStartDate) <= 35 AND TRIM(LOWER(BillingOptionName)) IN ('monthly billing','prepay thru agr. end') THEN 'Monthly-Monthly'
    WHEN DATEDIFF(SubscriptionEndDate, SubscriptionStartDate) > 35 and TRIM(LOWER(FT.Billingoptionname)) IN ('monthly billing') THEN 'Annual-Monthly'
    WHEN DATEDIFF(SubscriptionEndDate, SubscriptionStartDate) > 35 AND TRIM(LOWER(BillingOptionName)) IN ('annual bill thru agr. end','prepay thru agr. end') THEN 'Annual-Annual'
    WHEN DATEDIFF(SubscriptionEndDate, SubscriptionStartDate) <= 35 AND TRIM(LOWER(BillingOptionName)) IN ('unknown') THEN 'Monthly-Unknown'
    ELSE 'Annual-Unknown'
END AS CommitmentTermBillingOption,
CASE 
    WHEN CAST(DS.SubscriptionKey AS BIGINT) < 0
        THEN - 1
      ELSE 1
  END * (ABS(CAST(DS.SubscriptionKey AS BIGINT)) * 1000 + IF(FT.BillingOptionID=-9999, 999, FT.BillingOptionID)) AS CommitmentTermBillingOptionKey
FROM DimSubscription_Gold DS   
INNER JOIN CTE_Fact FT ON DS.SubscriptionKey = FT.SubscriptionKey
''').createOrReplaceTempView("CommitmentTermBillingOption")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

writeTable("CommitmentTermBillingOption", "IntermediateTables/CommitmentTermBillingOption", WorkspaceIdDev, LakehouseIdDev)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceIdDev, LakehouseIdDev, "IntermediateTables/CommitmentTermBillingOption").createOrReplaceTempView("CommitmentTermBillingOption")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, DecimalType, ShortType, LongType, DateType, ByteType
)

schema_factsales = StructType([
    StructField("PartnerID", IntegerType(), True),
    StructField("SubscriptionKey", LongType(), True),
    StructField("SubscriptionStatusKey", ShortType(), True),
    StructField("ResellerPartnerID", StringType(), True),
    StructField("DetailPricingLevelID", IntegerType(), True),
    StructField("MSSTPID", IntegerType(), True),
    StructField("AdvisorID", IntegerType(), True),
    StructField("PartnerTPID", IntegerType(), True),
    StructField("DistributorPartnerID", StringType(), True),
    StructField("OlServiceFlagKey", IntegerType(), True),
    StructField("DetailSalesModelID", IntegerType(), True),
    StructField("ReportedSubSegmentID", IntegerType(), True),
    StructField("FiscalMonthID", IntegerType(), True),
    StructField("DetailTransactionTypeId", IntegerType(), True),
    StructField("CreditedGeographyKey", IntegerType(), True),
    StructField("CountryID", IntegerType(), True),
    StructField("CSPPartnerID", StringType(), True),
    StructField("ReconType", StringType(), True),
    StructField("UserTypeID", IntegerType(), True),
    StructField("PurchaseTypeID", IntegerType(), True),
    StructField("ProgramOfferingTypeID", ShortType(), True),
    StructField("ProgramOfferingID", IntegerType(), True),
    StructField("ProgramId", IntegerType(), True),
    StructField("BillingTypeID", ShortType(), True),
    StructField("PurchaseOrderTypeID", ShortType(), True),
    StructField("AgreementID", StringType(), True),
    StructField("Enrollment", StringType(), True),
    StructField("BusinessID", IntegerType(), True),
    StructField("TenantKey", LongType(), True),
    StructField("CustomerGeographyKey", IntegerType(), True),
    StructField("AllocationID", ShortType(), True),
    StructField("LicenseAgreementContractTypeID", ShortType(), True),
    StructField("CustomerNumber", StringType(), True),
    StructField("ProductKey", IntegerType(), True),
    StructField("LIRPartnerID", LongType(), True),
    StructField("SPLARKey", IntegerType(), True),
    StructField("SoldSeatsEOP", DecimalType(38, 6), True),
    StructField("SoldSeats", DecimalType(38, 6), True),
    StructField("DeployedSeatsEOP", DecimalType(38, 6), True),
    StructField("DeployedSeats", DecimalType(38, 6), True),
    StructField("SoldSeatsRevenue", DecimalType(38, 6), True),
    StructField("Licenses", DecimalType(38, 6), True),
    StructField("SoldSeatsAdds", DecimalType(38, 6), True),
    StructField("SoldSeatsLost", DecimalType(38, 6), True),
    StructField("PlanKey", IntegerType(), True),
    StructField("IsDisti", StringType(), True),
    StructField("FMStartDate", DateType(), True),
    StructField("AssociationID", LongType(), True),
    StructField("UnitType", StringType(), True),
    StructField("StatusFlag", ByteType(), True),
    StructField("BillingOptionID", IntegerType(), True),
    StructField("ChannelMotionKey", IntegerType(), True),
    StructField("CommitmentTermBillingOptionKey", LongType(), True),
    StructField("CustomProductKey", LongType(), True),
    StructField("CustomDetailPricingLevelID", IntegerType(), True),
    StructField("IsRoB", IntegerType(), True),
    StructField("CustomOlServiceFlagKey", IntegerType(), True),
    StructField("CustomRevSumDivisionKey", IntegerType(), True),
    StructField("IsE5BRS500", IntegerType(), True),
    StructField("IsME3", IntegerType(), True),
    StructField("IsFRA", IntegerType(), True),
    StructField("IsTelcoCSPBR", IntegerType(), True),
    StructField("IsCSPCloudFRA", IntegerType(), True),
    StructField("FieldGeographyID", IntegerType(), True),
    StructField("CommitmentTermID", IntegerType(), True),
    StructField("PublicCustomerNumber", StringType(), True),
    StructField("OrganizationTypeID", IntegerType(), True)
])

schemaname = f"{PublishSchema}"
tablename = 'FactSales'


if not check_table_exists(WorkspaceIdDev, LakehouseIdDev, schemaname, tablename):
    df_fact_sales_full = spark.createDataFrame([], schema_factsales)
    df_fact_sales_full.write.mode("overwrite").format("delta").partitionBy("FiscalMonthID").option("mergeSchema", "true").save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")
    print(f"Created Table {schemaname}/{tablename}")
else:
    print(f"Table {schemaname}/{tablename} Already Exists, Skipped!")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import threading

failed_months = []
processed_months = []
processing_months = []


def insert_fact_sales(fiscal_month_id):
    try:
        processing_months.append(fiscal_month_id)
        print(f"Processing factsales fiscal month id: {fiscal_month_id}")
        
        df = spark.sql(f'''
        WITH CTE AS (
                SELECT DISTINCT ProductFamilyID
                FROM DimProduct_Gold
  ),
  CTE_Account AS (
    SELECT DISTINCT 
        SalesUnitId, 
        SalesUnitName, 
        TPAccountId 
    FROM 
        DimAccountGeographyHierarchy_gold
    WHERE 
        TPAccountId IS NOT NULL
)
            SELECT 
                FSF.PartnerID,
                FSF.SubscriptionKey,
                FSF.SubscriptionStatusKey,
                FSF.ResellerTPID AS ResellerPartnerID,
                FSF.DetailPricingLevelID,
                FSF.MSSTPID,
                FSF.AdvisorID,
                FSF.PartnerTPID,
                FSF.DistributorTPID AS DistributorPartnerID,
                FSF.OlServiceFlagKey,
                FSF.DetailSalesModelID,
                FSF.ReportedSubSegmentID,
                FSF.FiscalMonthID,
                FSF.DetailTransactionTypeId,
                FSF.SubsidiaryID AS CreditedGeographyKey,
                FSF.CountryID,
                FSF.CSPPartnerID,
                FSF.ReconType,
                FSF.UserTypeID,
                FSF.PurchaseTypeID,
                FSF.ProgramOfferingTypeID,
                FSF.ProgramOfferingID,
                FSF.ProgramId,
                FSF.BillingTypeID,
                FSF.PurchaseOrderTypeID,
                FSF.AgreementID,
                FSF.Enrollment,
                FSF.BusinessID,
                FSF.TenantKey,
                FSF.CustomerGeographyKey,
                FSF.AllocationID,
                FSF.LicenseAgreementContractTypeID,
                FSF.CustomerNumber,
                FSF.ProductKey,
                FSF.LIRPartnerID,
                FSF.SPLARKey,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.SoldSeatsEOP
                END AS SoldSeatsEOP,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.SoldSeats
                END AS SoldSeats,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.DeployedSeatsEOP
                END AS DeployedSeatsEOP,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.DeployedSeats
                END AS DeployedSeats,
                FSF.SoldSeatsRevenue*IFNULL(D.MetricFactor,1) AS SoldSeatsRevenue,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.Licenses
                END AS Licenses,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.SoldSeatsAdds
                END AS SoldSeatsAdds,
                CASE WHEN D.SourceProductFamilyID = D.TargetProductFamilyID
                THEN 0.000000
                ELSE FSF.SoldSeatsLost
                END AS SoldSeatsLost,
                FSF.PlanKey,
                CASE 
                    WHEN FSF.IsDisti = 1 THEN 'Yes'
                    WHEN FSF.IsDisti = 0 THEN 'No'
                END AS IsDisti,
                FSF.FMStartDate,
                FSF.AssociationID,
                FSF.UnitType,
                FSF.StatusFlag,
                FSF.BillingOptionID,
                FSF.ChannelMotionKey,
                IFNULL(CTB.CommitmentTermBillingOptionKey, -9999) AS CommitmentTermBillingOptionKey,
                COALESCE(D.TargetProductFamilyID,B.ProductFamilyID,C.ProductFamilyID,-9999) AS CustomProductKey,
                IFNULL(DPL.DetailPricingLevelID*10, -9999) AS CustomDetailPricingLevelID,
                CASE   
                      WHEN LOWER(TRIM(DB.BusinessSummaryName)) IN ("field","stores field")
                      AND DS.TopSegmentID IN (1,3) THEN 1
                      ELSE 0
                      END AS IsRoB,
                CASE 
                      WHEN DP.SuperRevSumDivisionID IN (200,201, 213,214,215, 191, 192, 194, 195, 196) THEN 10479  
                      WHEN DP.SuperRevSumDivisionID IN (13,45,212) THEN 10481   
                      WHEN DP.SuperRevSumDivisionID IN (193) THEN 10493   
                      ELSE FSF.OlServiceFlagKey END AS CustomOlServiceFlagKey,
                IFNULL(DP.RevSumDivisionID, -9999) AS CustomRevSumDivisionKey,
                CASE
                      WHEN DP.SuperRevSumDivisionID IN (166,192,198,208,213,214,215) /*'ems - m365 suites e5','o365 - m365 suites e5','windows - m365 suites e5','power bi - m365', 'Power BI - M365'.
                      added these 'EMS - Mini & NextGen Bundle', 'O365 - Mini & NextGen Bundle', 'Windows - Mini & NextGen Bundle' as part of FY25 changes*/
                      AND LOWER(TRIM(DS.CustomSummarySubSegmentName)) NOT IN ('strategic')
                      THEN 1
                      ELSE 0
                    END AS IsE5BRS500,
                    CASE
                      WHEN DP.SuperRevSumDivisionID IN (191,197,207) /*'ems - m365 suites core','o365 - m365 suites core','windows - m365 suites core'*/
                      AND LOWER(TRIM(DS.CustomSummarySubSegmentName)) NOT IN ('strategic')
                      AND DS.CustomSummarySubSegmentID IN (1,4,3) /*'SM&C-C', 'SMB', 'MAJOR'*/
                      AND DS.TopSegmentID IN (1,3)     /* 'Commercial', 'Public Sector' */
                      AND LOWER(TRIM(DB.BusinessSummaryName)) IN ("field","stores field")
                       THEN 1
                      ELSE 0
                    END AS IsME3,
                    CASE
                      WHEN DP.SuperRevSumDivisionID NOT IN (92,-11156600000 )     
                      AND DS.SummarySegmentID <> 17  /*'device partner sales'*/
                      AND DS.TopSegmentID IN (1,3) /*'commercial', 'public'*/ 
                      THEN 1
                      ELSE 0
                    END AS IsFRA,
                    CASE
                      WHEN DPL.ReportingSummaryPricingLevelID =  50 /*'cloud solution provider'*/
                      AND (LOWER(TRIM(DP.SolutionArea)) = 'modern work' OR LOWER(TRIM(DP.SolutionArea)) = 'security')
                      AND (DP.SuperRevSumDivisionID <> 193 OR (DP.SuperRevSumDivisionID = 193 AND DP.RevSumDivisionID = 8646))
                      THEN 1
                      ELSE 0
                    END AS IsTelcoCSPBR,
                    CASE
                      WHEN DS.CustomSummarySegmentSortOrder IN (2,3) /*'SM&C-C', 'SMB'*/
                      AND LOWER(TRIM(DP.SolutionArea)) IN ('modern work','security', 'business applications')
                      AND DPL.ReportingSummaryPricingLevelID =  50 /*'cloud solution provider'*/ 
                      THEN 1
                      ELSE 0
                    END AS IsCSPCloudFRA,
                    IFNULL(FS.FieldGeographyKey, 1) AS FieldGeographyID,
                    CASE
                        WHEN LOWER(TRIM(CTB.CommitmentTerm)) = 'monthly' THEN 1
                        WHEN LOWER(TRIM(CTB.CommitmentTerm)) = 'annual' THEN 2
                        ELSE 0
                    END AS CommitmentTermID,
                    FSF.PublicCustomerNumber,
                    FSF.OrganizationTypeID
            FROM 
                FactSales_Full FSF
            INNER JOIN 
                DimBusiness_gold DB
            ON 
                FSF.BusinessID = DB.BusinessID
                AND LOWER(TRIM(DB.BusinessSummaryName)) IN ('field', 'stores field')
                AND FSF.FiscalMonthID = {fiscal_month_id}
            LEFT JOIN 
                CommitmentTermBillingOption CTB
            ON 
                CTB.SubscriptionKey = FSF.SubscriptionKey
                AND CTB.BillingOptionID = FSF.BillingOptionID
            LEFT JOIN DimProduct_Gold B
            ON (IFNULL(FSF.IsDisti,0) = 0 AND FSF.ProductKey = B.ProductID)
            OR (IFNULL(FSF.IsDisti,0) = 1 AND FSF.ProductKey%10000 <> 0 AND  FSF.ProductKey = B.ProductID)
            LEFT JOIN CTE C
            ON IFNULL(FSF.IsDisti,0) = 1 AND FSF.ProductKey%10000 = 0 AND  FSF.ProductKey/10000 = C.ProductFamilyID
            AND B.ProductID IS NULL
            LEFT JOIN Dim_ActualMWSecurityAllocations D
            ON IFNULL(B.ProductFamilyID,C.ProductFamilyID) = D.SourceProductFamilyID
              AND (
                (FSF.FiscalMonthID >= 433 AND LOWER(TRIM(D.FiscalYear)) = 'fy26')
                OR (FSF.FiscalMonthID >= 421 AND FSF.FiscalMonthID <= 432  AND LOWER(TRIM(D.FiscalYear)) = 'fy25')
                OR (FSF.FiscalMonthID >= 409 AND FSF.FiscalMonthID <= 420  AND LOWER(TRIM(D.FiscalYear)) = 'fy24')
                OR (FSF.FiscalMonthID >= 397 AND FSF.FiscalMonthID <= 408  AND LOWER(TRIM(D.FiscalYear)) = 'fy23')
                OR (FSF.FiscalMonthID >= 385 AND FSF.FiscalMonthID <= 396  AND LOWER(TRIM(D.FiscalYear)) = 'fy22')
              )
            LEFT JOIN DimCustomProduct_Gold DP
            ON COALESCE(D.TargetProductFamilyID,B.ProductFamilyID,C.ProductFamilyID) = DP.ProductKey
            LEFT JOIN DimOrganizationSubSegment_Gold DS ON FSF.ReportedSubsegmentID = DS.SubSegmentKey
            LEFT JOIN DimPricingLevel_Gold DPL ON FSF.DetailPricingLevelID = DPL.DetailPricingLevelID
            LEFT JOIN DimCustomer_Gold AS DC ON FSF.MSSTPID = DC.CustomerKey
            LEFT JOIN CTE_Account AS CA 
            ON DC.CustomerKey = CA.TPAccountId 
            AND LOWER(TRIM(DC.EOU)) = LOWER(TRIM(CA.SalesUnitName))
            LEFT JOIN FieldGeographyDefinition_Gold AS FGD 
            ON CA.SalesUnitId = FGD.SalesUnitId 
            AND DS.StdRptgReportedSubsegmentId = FGD.StdRptgReportedSubsegmentId 
            AND FSF.SubsidiaryID = FGD.CreditedSalesLocationId
            LEFT JOIN DimFieldGeography_Gold AS FS 
            ON FGD.FieldSubsidiaryId = FS.FieldGeographyKey
        ''')

        # Write the transformed data to Delta Lake
        df.write.format("delta") \
            .mode("overwrite") \
            .option("mergeSchema", "true") \
            .option("replaceWhere", f"FiscalMonthID = {fiscal_month_id}") \
            .partitionBy("FiscalMonthID") \
            .save(f"abfss://{WorkspaceIdDev}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseIdDev}/Tables/{schemaname}/{tablename}")
        
        processed_months.append(fiscal_month_id)
        print(f"Processed factsales for fiscal month id: {fiscal_month_id}")
    except KeyboardInterrupt:
        print("Process interrupted by the (KeyboardInterrupt). Exiting gracefully...")
        failed_months.append(fiscal_month_id)
    except Exception as e:
        print(f"Failed to process fiscal month id {fiscal_month_id}: {e}")
        failed_months.append(fiscal_month_id)
    finally:
        processing_months.remove(fiscal_month_id)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

fiscalmonth_ids

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import threading
import concurrent.futures
fiscalmonth_ids = spark.sql(f"""
    SELECT DISTINCT fiscalMonthID 
    FROM dimtime_gold 
    WHERE FiscalMonthID >= {minFiscalMonthID} 
    AND FiscalMonthID <= {maxFiscalMonthID}  
    ORDER BY FiscalMonthID
""").collect()

concurrent_futures_thread_pool_executor(
            processing_fiscalmonths_ids = fiscalmonth_ids,
            task_function  = insert_fact_sales,
            target_table = 'FactSales',
            max_retry_count = 3,
            max_concurrent_threads  = 20,
            processed_months = processed_months,
            failed_months = failed_months
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

PublishSchema = "SalesGold2026031301"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

getDataframe(WorkspaceId, LakehouseId, "SalesGold2026031701" + "/FactSales").createOrReplaceTempView("FactSales_prod")
getDataframe(WorkspaceIdDev, LakehouseIdDev, PublishSchema + "/FactSales").createOrReplaceTempView("FactSales_dev")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC select FiscalMonthID, sum(SoldSeatsRevenue) from factsales_dev where  fiscalmonthid between 433 and 435 group by 1 

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC select FiscalMonthID, sum(SoldSeatsRevenue) from factsales_prod where  fiscalmonthid between 433 and 435 group by 1 

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# latest_schema = f"{LatestPublishSchema}"
# tablename = 'FactSales' 

# if check_table_exists(WorkspaceId, LakehouseId, latest_schema, tablename):
#     historical_data_factsales = getDataframe(WorkspaceId, LakehouseId, latest_schema + "/FactSales")
#     historical_data_factsales_filtered = historical_data_factsales.filter(f"fiscalMonthID < {minFiscalMonthID}")

#     if historical_data_factsales_filtered.count() != 0 :
#         historical_data_factsales_filtered.write.format("delta") \
#             .mode("overwrite") \
#             .option("mergeSchema", "true") \
#             .option("replaceWhere", f"FiscalMonthId < {minFiscalMonthID}") \
#             .partitionBy("FiscalMonthId") \
#             .save(f"abfss://{WorkspaceId}@msit-onelake.dfs.fabric.microsoft.com/{LakehouseId}/Tables/{PublishSchema}/{tablename}")
#         print(f"Historical data has been published up to fiscal month ID {minFiscalMonthID - 1} in the PublishedSchema")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

SetNotebookStatus(NotebookName,StreamName,Stage)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

