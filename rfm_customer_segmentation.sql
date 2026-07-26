WITH customer_statistic AS (
    SELECT
        ct.CustomerID,
        cr.created_date,
        DATEDIFF(day, MAX(ct.purchase_date), '2022-09-01') AS Recency,
        COUNT(ct.transaction_id) / NULLIF(DATEDIFF(day, cr.created_date, '2022-09-01')/365.0, 0) AS Frequency,
        SUM(ct.gmv) / NULLIF(DATEDIFF(day, cr.created_date, '2022-09-01')/365.0, 0) AS Monetary
    FROM Customer_Registered cr
    JOIN Customer_Transaction ct ON ct.CustomerID = cr.ID
    WHERE ct.purchase_date IS NOT NULL 
      AND cr.created_date < '2022-09-01'
    GROUP BY ct.CustomerID, cr.created_date
),
customer_rn AS (
    SELECT
        cs.*,
        ROW_NUMBER() OVER (ORDER BY cs.Recency ASC)     AS Recency_rn,
        ROW_NUMBER() OVER (ORDER BY cs.Frequency DESC)  AS Frequency_rn,
        ROW_NUMBER() OVER (ORDER BY cs.Monetary DESC)   AS Monetary_rn
    FROM customer_statistic cs
),
customer_rfm AS (
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,
        Recency_rn,
        Frequency_rn,
        Monetary_rn,
        MAX(Recency_rn) OVER () AS total_khach,
        ROUND(MAX(Recency_rn) OVER () * 0.25, 0) AS cutoff_25,
        ROUND(MAX(Recency_rn) OVER () * 0.50, 0) AS cutoff_50,
        ROUND(MAX(Recency_rn) OVER () * 0.75, 0) AS cutoff_75
    FROM customer_rn
)
SELECT
    CASE WHEN Recency_rn   <= cutoff_25 THEN '4' WHEN Recency_rn   <= cutoff_50 THEN '3' WHEN Recency_rn   <= cutoff_75 THEN '2' ELSE '1' END AS R,
    CASE WHEN Frequency_rn <= cutoff_25 THEN '4' WHEN Frequency_rn <= cutoff_50 THEN '3' WHEN Frequency_rn <= cutoff_75 THEN '2' ELSE '1' END AS F,
    CASE WHEN Monetary_rn  <= cutoff_25 THEN '4' WHEN Monetary_rn  <= cutoff_50 THEN '3' WHEN Monetary_rn  <= cutoff_75 THEN '2' ELSE '1' END AS M,
    CONCAT(
        CASE WHEN Recency_rn   <= cutoff_25 THEN '4' WHEN Recency_rn   <= cutoff_50 THEN '3' WHEN Recency_rn   <= cutoff_75 THEN '2' ELSE '1' END,
        CASE WHEN Frequency_rn <= cutoff_25 THEN '4' WHEN Frequency_rn <= cutoff_50 THEN '3' WHEN Frequency_rn <= cutoff_75 THEN '2' ELSE '1' END,
        CASE WHEN Monetary_rn  <= cutoff_25 THEN '4' WHEN Monetary_rn  <= cutoff_50 THEN '3' WHEN Monetary_rn  <= cutoff_75 THEN '2' ELSE '1' END
    ) AS RFM,
    COUNT(*) AS So_khach_hang
FROM customer_rfm
GROUP BY Recency_rn, Frequency_rn, Monetary_rn, cutoff_25, cutoff_50, cutoff_75
ORDER BY RFM DESC;

--lấy ra tổng doanh thu
select sum(GMV) AS TỔNG_DOANH_THU FROM Customer_Transaction UNION
--LẤY RA TỔNG KHÁCH HÀNG
SELECT COUNT(DISTINCT ID) AS TONG_KHACH_HANG FROM Customer_REGISTERED UNION
--DOANH THU TRÊN 1 KHÁCH HÀNG
SELECT 
      SUM(CT.GMV ) AS TÔNG_DOANH_THU,
      COUNT(ID) AS TONG_KHACH_HANG,
      SUM(GMV)/COUNT(ID) AS DOANH_THU_1_KHACH_HANG 
FROM Customer_Registered  CR
JOIN Customer_Transaction CT 
ON   CR.ID=CT.TRANSACTION_ID

--DOANH THU THEO THÁNG
SELECT MONTH(CT.PURCHASE_DATE) AS THANG,
       SUM(CT.GMV ) AS TONG_DOANH_THU,
       COUNT(DISTINCT CR.ID) AS TONG_KHACH_HANG,
       SUM(CT.GMV)/COUNT(CR.ID) AS DOANH_TU_1_KHACH_HANG
FROM Customer_Transaction CT
JOIN CUSTOMER_REGISTERED CR
ON CT.Transaction_ID =CR.ID 
GROUP BY MONTH(CT.Purchase_Date ) 
ORDER BY THANG ASC

