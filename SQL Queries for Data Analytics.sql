--1.1 Trainer Workload Distribution
SELECT 
    t.Trainer_ID,
    t.First_Name + ' ' + t.Last_Name AS Trainer_Name,
    ISNULL(ts.SessionCount, 0) AS Training_Sessions,
    ISNULL(cb.ClassBookings, 0) AS Class_Bookings,
    ISNULL(ts.SessionCount, 0) + ISNULL(cb.ClassBookings, 0) AS Total_Activities
FROM TRAINER t
LEFT JOIN (
    SELECT 
        Trainer_ID,
        COUNT(*) AS SessionCount
    FROM TRAINING_SESSION
    GROUP BY Trainer_ID
) ts ON t.Trainer_ID = ts.Trainer_ID
LEFT JOIN (
    SELECT 
        fc.Trainer_ID,
        COUNT(cb.Booking_ID) AS ClassBookings
    FROM CLASS_BOOKING cb
    JOIN FITNESS_CLASS fc ON cb.Class_ID = fc.Class_ID
    GROUP BY fc.Trainer_ID
) cb ON t.Trainer_ID = cb.Trainer_ID
ORDER BY Total_Activities DESC;

--1.2 Daily Activity Load by Day of Week
SELECT 
    Days.DayOfWeek,
    ISNULL(fc.ClassBookings, 0) AS Fitness_Classes,
    ISNULL(ts.TrainingSessions, 0) AS Training_Sessions,
    ISNULL(fc.ClassBookings, 0) + ISNULL(ts.TrainingSessions, 0) AS Total_Activities
FROM (
    SELECT DISTINCT DATENAME(WEEKDAY, Booking_Date) AS DayOfWeek FROM CLASS_BOOKING
    UNION
    SELECT DISTINCT DATENAME(WEEKDAY, Session_Date) FROM TRAINING_SESSION
) AS Days
LEFT JOIN (
    SELECT 
        DATENAME(WEEKDAY, Booking_Date) AS DayOfWeek,
        COUNT(*) AS ClassBookings
    FROM CLASS_BOOKING
    GROUP BY DATENAME(WEEKDAY, Booking_Date)
) AS fc ON Days.DayOfWeek = fc.DayOfWeek
LEFT JOIN (
    SELECT 
        DATENAME(WEEKDAY, Session_Date) AS DayOfWeek,
        COUNT(*) AS TrainingSessions
    FROM TRAINING_SESSION
    GROUP BY DATENAME(WEEKDAY, Session_Date)
) AS ts ON Days.DayOfWeek = ts.DayOfWeek
ORDER BY 
    CASE 
        WHEN Days.DayOfWeek = 'Monday' THEN 1
        WHEN Days.DayOfWeek = 'Tuesday' THEN 2
        WHEN Days.DayOfWeek = 'Wednesday' THEN 3
        WHEN Days.DayOfWeek = 'Thursday' THEN 4
        WHEN Days.DayOfWeek = 'Friday' THEN 5
        WHEN Days.DayOfWeek = 'Saturday' THEN 6
        WHEN Days.DayOfWeek = 'Sunday' THEN 7
    END;

--2.1 Revenue Over Time
SELECT 
    FORMAT(Payment_Date, 'yyyy-MM') AS Revenue_Month,
    SUM(Amount) AS Total_Revenue
FROM PAYMENT
GROUP BY FORMAT(Payment_Date, 'yyyy-MM')
ORDER BY Revenue_Month;

--2.2 Revenue and Revenue per Transaction by Payment Type
SELECT 
    Payment_Type,
    SUM(Amount) AS TotalRevenue,
    CAST(ROUND(AVG(Amount), 2) AS DECIMAL(10,2)) AS RevenuePerItem
FROM PAYMENT
GROUP BY Payment_Type;

--3.1 Membership Plan Popularity 
SELECT 
    mp.Type_Name AS MembershipType,
    COUNT(m.Mem_ID) AS MemberCount
FROM MEMBER m
JOIN MEMBERSHIP_PLAN mp ON m.Plan_ID = mp.Plan_ID
GROUP BY mp.Type_Name
ORDER BY MemberCount DESC;

--4.1 Member Inactivity Detection 
SELECT 
    m.Mem_ID,
    m.First_Name,
    m.Last_Name,
    MAX(COALESCE(cb.Booking_Date, ts.Session_Date)) AS LastActivity
FROM MEMBER m
LEFT JOIN CLASS_BOOKING cb ON m.Mem_ID = cb.Mem_ID
LEFT JOIN TRAINING_SESSION ts ON m.Mem_ID = ts.Mem_ID
GROUP BY m.Mem_ID, m.First_Name, m.Last_Name
HAVING MAX(COALESCE(cb.Booking_Date, ts.Session_Date)) < DATEADD(MONTH, -1, GETDATE())

--4.2 Trainer Rating Analysis 
SELECT 
    t.Trainer_ID,
    t.First_Name + ' ' + t.Last_Name AS Trainer_Name,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS AverageRating,
    COUNT(*) AS RatingCount
FROM (
    SELECT Trainer_ID, Rating FROM TRAINING_SESSION WHERE Rating IS NOT NULL
    UNION ALL
    SELECT fc.Trainer_ID, cb.Rating 
    FROM CLASS_BOOKING cb
    JOIN FITNESS_CLASS fc ON cb.Class_ID = fc.Class_ID
    WHERE cb.Rating IS NOT NULL
) AS AllRatings
JOIN TRAINER t ON AllRatings.Trainer_ID = t.Trainer_ID
GROUP BY t.Trainer_ID, t.First_Name, t.Last_Name
ORDER BY AverageRating DESC;

--5.1 Attendance Behavior Analysis 
SELECT 
    Attendance_Status,
    COUNT(*) AS TotalBookings
FROM CLASS_BOOKING
GROUP BY Attendance_Status
ORDER BY TotalBookings DESC;

--5.2 Specilisation Demand 
---1. By Fitness Classes
SELECT 
    s.Specialisation,
    COUNT(cb.Booking_ID) AS TotalClassBookings
FROM CLASS_BOOKING cb
JOIN FITNESS_CLASS fc ON cb.Class_ID = fc.Class_ID
JOIN SPECIALISATION s ON fc.Spec_ID = s.Spec_ID
GROUP BY s.Specialisation
ORDER BY TotalClassBookings DESC;

---2. By Sessions 
SELECT 
    s.Specialisation,
    COUNT(ts.Session_ID) AS TotalTrainingSessions
FROM TRAINING_SESSION ts
JOIN TRAINER t ON ts.Trainer_ID = t.Trainer_ID
JOIN SPECIALISATION s ON t.Spec_ID = s.Spec_ID
GROUP BY s.Specialisation
ORDER BY TotalTrainingSessions DESC;
