
SELECT * FROM [dbo].[Appointments]; -- [ جدول المواعيد ]
SELECT * FROM [dbo].[Departments] ; -- [ جدول الاقسام ]
SELECT * FROM [dbo].[DoctorDepartments]; -- [ جدول اقسام الاطباء  ]
SELECT * FROM [dbo].[Doctors]; -- [ جدول الاطباء ]
SELECT * FROM [dbo].[Patients]; -- [ جدول المرضى ]
SELECT * FROM [dbo].[Prescriptions]; -- [ جدول الوصفات الطبية  ]
SELECT * FROM [dbo].[Treatments]; -- [ جدول الاجراءات الطبية او العلاجات  ]
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

--1 Find patients who visited more than one doctor.[ ابحث عن المرضى الذين زاروا أكثر من طبيب ]

SELECT A.PatientID ,A.FirstName+' '+A.LastName AS" Name " ,count(DISTINCT b.DoctorID) AS "Doctor count"
FROM Patients A
INNER JOIN Appointments B ON A.PatientID = B.PatientID
group by A.PatientID,A.FirstName,A.LastName
HAVING count(DISTINCT b.DoctorID) > 1 ;
-- لايوجد مرضى زارو اكثر من طبيب --

-------------------------------------------------------------------------------------

--2 Find the doctor with the highest average treatment cost.[ابحث عن الطبيب صاحب أعلى متوسط ​​تكلفة علاج]

SELECT TOP 1 B.DoctorID,B.FirstName+' '+B.LastName AS" Name ", AVG(C.COST) AS"Highest average cost"
FROM Appointments A
INNER JOIN Doctors B ON A.DoctorID = B.DoctorID
INNER JOIN Treatments C ON A.AppointmentID = C.AppointmentID
GROUP BY  B.DoctorID,B.FirstName,B.LastName
ORDER BY "Highest average cost" DESC

---------------------------------------------------------
--3 Find all patients whose total treatment cost exceeds the average spending of all patients.
--[ابحث عن جميع المرضى الذين تتجاوز تكلفة علاجهم الإجمالية متوسط ​​إنفاق جميع المرضى]

WITH PatientSpending AS
(
SELECT  A.PatientID,A.FirstName + ' ' + A.LastName AS PatientName, SUM(C.Cost) AS TotalCost
FROM Patients A
    INNER JOIN Appointments B ON A.PatientID = B.PatientID
    INNER JOIN Treatments C ON B.AppointmentID = C.AppointmentID
    GROUP BY A.PatientID, A.FirstName, A.LastName 
    )

SELECT PatientID,  PatientName, TotalCost AS "SUM AStreatment cost"
FROM PatientSpending
WHERE TotalCost > (SELECT AVG(TotalCost) FROM PatientSpending)
ORDER BY TotalCost

-----------------------------------------------------------------------------
--4 Find doctors who have more appointments than the average doctor.
--[ابحث عن الأطباء الذين لديهم مواعيد أكثر من متوسط ​​عدد المواعيد للأطباء.]

WITH DoctorAppointments AS
(
SELECT A.DoctorID,A.FirstName+''+A.LastName as DoctorName,
       A.Specialty,COUNT(B.AppointmentID) AS AppointmentCount

FROM Doctors A
INNER JOIN Appointments B ON A.DoctorID = B.DoctorID 
GROUP BY  A.DoctorID,a.FirstName,a.LastName,a.Specialty
)

SELECT T.DoctorID,T.DoctorName,t.Specialty ,T.AppointmentCount AS TotalAppointments
FROM  DoctorAppointments T
WHERE T.AppointmentCount  > (select avg(AppointmentCount)FROM DoctorAppointments)

------------------------------------------------------------------------------------------

--5 Create a CTE that calculates monthly appointment counts and identify the busiest month.
-- [ أنشئ جدولًا زمنيًا مشتركًا (CTE) لحساب عدد المواعيد الشهرية وتحديد الشهر الأكثر ازدحامًا ]

WITH monthlyAppointmentCounts AS
(
SELECT YEAR(X.AppointmentDate) AS AppointmentYear,
      MONTH(X.AppointmentDate) AS AppointmentMonth,
      COUNT (*) AS TotalAppointmen

FROM Appointments X
GROUP BY  YEAR(X.AppointmentDate) , MONTH(X.AppointmentDate) 
)

SELECT TOP 1 AppointmentYear,AppointmentMonth,TotalAppointmen
FROM monthlyAppointmentCounts
ORDER BY TotalAppointmen desc ;

------------------------------------------------------------------------------------------
--6 For every treatment, display:
-- Treatment Cost [تكلفة العلاج]
-- Average Treatment Cost for that patient[ متوسط ​​تكلفة العلاج لهذا المريض ]

SELECT F.PatientID ,T.TreatmentName , T.Cost AS "Treatment Cost" ,
     AVG(T.Cost)OVER(PARTITION BY F.PatientID) AS "Average Treatment"

FROM Treatments T
INNER JOIN Appointments F ON T.AppointmentID = F.AppointmentID;

----------------------------------------------------------------------
-- 7 Find the previous appointment date for each patient.
-- 8 Find the next appointment date for each patient.
-- 9 Identify the first appointment for every patient.
--[  ابحث عن تاريخ الموعد السابق و موعد المراجعه التاليه و اول موعد لكل مريض  ]

SELECT T1.PatientID,T2.FirstName+' '+T2.LastName "Patients Name",T1.AppointmentDate ,
LAG(T1.AppointmentDate)OVER(PARTITION BY T1.PatientID ORDER BY T1.AppointmentDate) AS "Previous Appointment Date" ,
LEAD(T1.AppointmentDate)OVER(PARTITION BY T1.PatientID ORDER BY T1.AppointmentDate) AS "Next Appointment Date" ,
ROW_NUMBER()OVER(PARTITION BY T1.PatientID ORDER BY T1.AppointmentDate ) AS"the first appointment"
FROM Appointments T1
INNER JOIN Patients T2 ON T1.PatientID = T2.PatientID ;

-------------------------------------------------------------------------------------------------
-- 10 Calculate the percentage contribution of each patient's spending to the hospital's total treatment revenue.
--[ حساب النسبة المئوية لمساهمة إنفاق كل مريض في إجمالي إيرادات العلاج في المستشفى ]
-- 11 Build a patient spending leaderboard showing
--[ Rank ,Patient Name ,Total Spending ,Percentage of Total Revenue]

WITH patientSpending AS
(
SELECT C.PatientID,C.FirstName+' '+C.LastName "PatientsName",
       SUM(A.Cost) AS "TotalSpending"
    
FROM Treatments A
INNER JOIN Appointments B ON A.AppointmentID = B.AppointmentID
INNER JOIN Patients C ON B.PatientID = C.PatientID 

GROUP BY C.PatientID,C.FirstName,C.LastName
)

SELECT RANK()OVER (ORDER BY TotalSpending DESC ) AS"Rank" ,
       PatientID,"PatientsName","TotalSpending",
      ("TotalSpending"*100.0)/SUM("TotalSpending")OVER() AS "Percentage of Total Revenue"
FROM patientSpending ;

-----------------------------------------------------------------------------------
 
 -- 12 Identify "loyal patients" who visited at least 3 times and spent more than the average patient.
 --[عدد المرضى "المخلصين" الذين زاروا العيادة 3 مرات على الأقل وأنفقوا أكثر من متوسط ​​إنفاق المرضى]

 WITH PatientStats AS
(
SELECT C.PatientID,C.FirstName+' '+C.LastName "PatientsName",
       COUNT(B.AppointmentID) AS "NumberVisited" ,
       SUM(A.Cost) AS "TotalSpending" ,
    AVG(SUM(A.Cost))over() as "AveragePatientSpending"
FROM Treatments A
INNER JOIN Appointments B ON A.AppointmentID = B.AppointmentID
INNER JOIN Patients C ON B.PatientID = C.PatientID 

GROUP BY C.PatientID,C.FirstName,C.LastName
)

SELECT PatientID ,PatientsName ,NumberVisited ,TotalSpending,AveragePatientSpending
FROM PatientStats
WHERE NumberVisited >= 3 AND TotalSpending > AveragePatientSpending ;

---------------------------------------------------------------------------------------

-- 13 Create a report showing :
--[  Doctor , Number of Patients , Number of Appointmens , Revenue Generated , Revenue Rank ]
--[ انشئ تقريرًا يُظهر ما يلي: الطبيب , عدد المرضى , عدد المواعيد , الإيرادات المحققة , ترتيب الإيرادات ]


SELECT B.DoctorID ,B.FirstName+' ' +B.LastName AS DoctorName ,
       COUNT (DISTINCT C.PatientID) AS NumberPatients ,
       COUNT (A.AppointmentID) AS NumberAppointmens ,
       SUM(D.Cost) AS RevenueGenerated ,
       RANK()OVER(ORDER BY SUM(D.Cost) DESC ) AS RevenueRank
FROM Appointments A
INNER JOIN Doctors B ON A.DoctorID = B.DoctorID
INNER JOIN Patients C ON A.PatientID = C.PatientID
INNER JOIN Treatments D ON A.AppointmentID = D.AppointmentID

GROUP BY  B.DoctorID ,B.FirstName , B.LastName ;

-----------------------------------------------------------------------------------------
-- 14 For each department, find:
-- Top Doctor by Revenue [أفضل طبيب من حيث الإيرادات]
-- Revenue Amount[مبلغ الإيرادات]

 WITH TopDoctorbyRevenue AS
 (
SELECT D.DepartmentName ,B.DoctorID ,B.FirstName+' '+B.LastName AS DoctorName,
       SUM(E.Cost) AS RevenueAmount ,
       ROW_NUMBER()OVER(PARTITION BY D.DepartmentName ORDER BY SUM(E.Cost) DESC ) AS DoctorRank

FROM Appointments A
INNER JOIN Doctors B ON A.DoctorID = B.DoctorID
INNER JOIN DoctorDepartments C ON B.DoctorID = C.DoctorID
INNER JOIN Departments D ON C.DepartmentID = D.DepartmentID
INNER JOIN Treatments E ON A.AppointmentID = E.AppointmentID

GROUP BY D.DepartmentName ,B.DoctorID ,B.FirstName,B.LastName
)

SELECT DepartmentName ,DoctorName ,RevenueAmount , DoctorRank
FROM TopDoctorbyRevenue  
WHERE DoctorRank = 1

--------------------------------------------------------------------------------
-- 15 Calculate patient lifetime value (LTV):[احسب القيمة الدائمة للمريض]
-- [ Total Visits ,Total Treatments , Total Prescriptions ,Total Spending ]
--[ اجمالي كل من الزيارات والعلاجات والوصفات الطبيه والانفاق ]

SELECT  A.PatientID ,
         COUNT(DISTINCT A.AppointmentID) AS TotalVisits ,
         COUNT(DISTINCT B.TreatmentID) AS TotalTreatments ,
         COUNT(DISTINCT C.PrescriptionID) AS TotalPrescriptions ,
         SUM(DISTINCT B.Cost) AS TotalSpending

FROM Appointments A
LEFT JOIN Treatments B ON A.AppointmentID = B.AppointmentID
LEFT JOIN Prescriptions C ON A.AppointmentID = C.AppointmentID

GROUP BY A.PatientID ;

-------------------------------------------------------------------------
-- 16 Build an executive dashboard query returning:[أنشئ استعلامًا للوحة معلومات تنفيذية يُظهر ما يلي]
--[ Total Patients,Total Doctors,Total Appointments,Total Treatments,Total Revenue,Average Revenue per Patient ]
--[ اجمالي كل من المرضى و الاطباءوالمواعيد والعلاجات والايرادات  ومتوسط الايرادات لكل مريض]



SELECT 
        COUNT(DISTINCT C.PatientID) AS TotalPatients ,
        COUNT(DISTINCT B.DoctorID) AS TotalDoctors ,
        COUNT (DISTINCT A.AppointmentID) AS TotalAppointments ,
        COUNT(DISTINCT E.TreatmentID) AS TotalTreatments ,
        SUM (DISTINCT E.Cost) AS TotalRevenue ,
      SUM (E.Cost) / COUNT(DISTINCT C.PatientID) AS AverageRevenue
FROM Appointments A
LEFT JOIN Doctors B ON A.DoctorID = B.DoctorID
LEFT JOIN Patients C ON A.PatientID = C.PatientID
LEFT JOIN Prescriptions D ON A.AppointmentID = D.AppointmentID
LEFT JOIN Treatments E ON A.AppointmentID = E.AppointmentID





