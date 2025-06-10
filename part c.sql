--DROP TABLE REGISTEREDS 
CREATE TABLE REGISTEREDS  (
EmailAddress varchar(50) not NULL Primary Key,
RegisteredName varchar(30),
[Address-City] varchar(30),
[Address-Country] varchar(30),

constraint CK_EmailAddress CHECK(EmailAddress LIKE '%@%.%')
)


--DROP TABLE CUSTOMERS
CREATE TABLE CUSTOMERS (
EmailAddress varchar(50) not NULL,
CustomerPassword varchar(50) not NULL,

constraint PK_Customers Primary key(EmailAddress),
constraint FK_CustomerEmails Foreign key(EmailAddress) references REGISTEREDS(EmailAddress),
constraint CK_Password CHECK (len(CustomerPassword)>= 8 AND
                                  CustomerPassword LIKE '%[0-9]%' AND
                                  CustomerPassword LIKE '%[A-Z]%' AND
                                  CustomerPassword LIKE '%[a-z]%' )
)


--DROP TABLE HOSTS 
CREATE TABLE HOSTS (
EmailAddress varchar(50)  not NULL,
PhoneNumber char(16) not NULL,
HostLanguage varchar(30),

constraint PK_Hosts Primary key(EmailAddress),
constraint FK_Hosts Foreign key (EmailAddress) references REGISTEREDS(EmailAddress),
constraint CK_PhoneNumber CHECK (PhoneNumber LIKE '[0-9]%' AND LEN(PhoneNumber) >= 8)

)


--DROP TABLE LOCATIONS 
CREATE TABLE LOCATIONS    (
GPS varchar(100) not NULL Primary Key,
Street varchar(100) not NULL,
City varchar(100) not NULL,
Country varchar(100) not NULL,
)


--DROP TABLE EXPERIENCES 
CREATE TABLE EXPERIENCES  (
Experience varchar(100) not NULL Primary key,
ExperienceType varchar(100) not NULL,
Menu varchar(500),
GPS varchar(100) not NULL Foreign key references LOCATIONS(GPS),
EmailAddress varchar(50) not NULL Foreign key references HOSTS(EmailAddress),

)


--DROP TABLE SCHEDULES 
CREATE TABLE SCHEDULES   (
Experience varchar(100) not NULL,
ExperienceDT datetime not NULL,
MaxOfGuest  int,
PricePerGuest money,

constraint PK_Schedules Primary key(Experience, ExperienceDT),
constraint FK_Experiences  Foreign key(Experience) references EXPERIENCES(Experience),
constraint CK_MaxOfGuest CHECK (MaxOfGuest > 0),
constraint CK_PricePerGuest CHECK (PricePerGuest > 0),

)


--DROP TABLE REVIEWS 
CREATE TABLE REVIEWS   (
Experience varchar(100) not NULL,
ReviewID int not NULL,
Rating int not NULL,
ReviewDT datetime not NULL,
Recommendation  varchar(256),
EmailAddress varchar(50) not NULL,

constraint PK_ReviewExperiences Primary key(Experience, ReviewID),
constraint FK_ReviewExperiences Foreign key(Experience) references EXPERIENCES(Experience),
constraint FK_REVIEWSEmailAddress Foreign key(EmailAddress) references CUSTOMERS(EmailAddress),
constraint CK_Rating CHECK(Rating Between 0 and 5),

)


--DROP TABLE SEARCHS 
CREATE TABLE SEARCHS   (
SearchIP varchar(50) not NULL,
SearchDT datetime not NULL,
SearchWord varchar(50),

constraint PK_Searchs Primary key(SearchIP, SearchDT),

)


--DROP TABLE PEFORMBY 
CREATE TABLE PEFORMBY   (
SearchIP varchar(50) not NULL,
SearchDT datetime not NULL,
EmailAddress  varchar(50) not NULL,

constraint PK_PeformBys Primary key(SearchIP, SearchDT, EmailAddress),
constraint FK_PeformIPs Foreign key(SearchIP, SearchDT) references SEARCHS(SearchIP, SearchDT),
constraint FK_PeformEmails Foreign key(EmailAddress) references CUSTOMERS(EmailAddress),
)


--DROP TABLE PAYMENTS 
CREATE TABLE PAYMENTS    (
CardNumber char(16) not NULL Primary Key,
CVC char(4) not NULL,
CardholdersName varchar(30) not NULL,

constraint CK_CardNumber CHECK (CardNumber LIKE '[0-9]%' AND LEN(CardNumber) >= 8), 
constraint CK_CVC CHECK (CVC LIKE '[0-9][0-9][0-9]' OR CVC LIKE '[0-9][0-9][0-9][0-9]')
)


--DROP TABLE ORDERS 
CREATE TABLE ORDERS    (
OrderID varchar (100) not NULL Primary key,
OrderDT datetime not NULL,
NumberOfTicek int not NULL,
Experience varchar(100) not NULL,
ExperienceDT datetime not NULL,
EmailAddress  varchar(50) not NULL,
CardNumber  char(16) not NULL,
SearchIP varchar(50) not NULL,
SearchDT datetime not NULL,


constraint FK_OrderExperiences Foreign key(Experience, ExperienceDT) references SCHEDULES(Experience, ExperienceDT),
constraint FK_OrderEmails Foreign key(EmailAddress) references CUSTOMERS(EmailAddress),
constraint FK_OrderCards Foreign key(CardNumber) references PAYMENTS(CardNumber),
constraint FK_OrderSearchs Foreign key(SearchIP, SearchDT) references SEARCHS(SearchIP, SearchDT),

)


--DROP TABLE SEENBY 
CREATE TABLE SEENBY    (
SearchIP varchar(50) not NULL,
SearchDT datetime not NULL,
Experience varchar(100) not NULL,


constraint PK_SeenBys Primary key(SearchIP, SearchDT, Experience),
constraint FK_SeenByIPs Foreign key(SearchIP, SearchDT) references SEARCHS(SearchIP, SearchDT),
constraint FK_SeenByExperiences Foreign key(Experience) references EXPERIENCES(Experience)
)


--DROP TABLE EXPERIENCE_TYPE
Create Table EXPERIENCE_TYPE   (
	Category Varchar(100) not NULL Primary key)

INSERT INTO EXPERIENCE_TYPE VALUES ('Brunch'),('Lunch'),('Dinner'),('Food Workshop'),('Culinary Tour')

Alter Table EXPERIENCES 
ADD constraint FK_ExperienceTypeLookup Foreign key (ExperienceType) references EXPERIENCE_TYPE (Category)








-----Q1-------
SELECT C.EmailAddress, E.Experience, R.Rating
FROM CUSTOMERS as C JOIN REVIEWS as R on C. EmailAddress = R. EmailAddress
            JOIN EXPERIENCES as E on E. Experience = R. Experience
WHERE R.Rating <= 3
GROUP BY C.EmailAddress, E.Experience, R.Rating
ORDER BY R.Rating ASC


-----Q2-------
SELECT E. ExperienceType,
         	Num_Customers = COUNT (DISTINCT C.EmailAddress)
FROM   EXPERIENCES as E JOIN ORDERS AS O ON E. Experience =O.Experience 
                	    JOIN CUSTOMERS AS C ON O.EmailAddress = C.EmailAddress
WHERE E.Experience = O.Experience 
Group by E.ExperienceType
Order By Num_Customers DESC


-----Q3-------
SELECT DISTINCT Country
FROM LOCATIONS AS L
WHERE Country NOT IN (SELECT Country
                      FROM EXPERIENCES AS E JOIN SCHEDULES AS SC 
					       ON E.Experience = SC.Experience 
					       JOIN CUSTOMERS AS C ON E.EmailAddress = C.EmailAddress
						   JOIN LOCATIONS AS L ON E.GPS = L.GPS
                      WHERE YEAR(GETDATE())-YEAR(SC.ExperienceDT)<=1
					  GROUP BY Country
					  HAVING COUNT(DISTINCT E.Experience) > 5 AND COUNT(*) > 15)


----Q4-----

SELECT R.RegisteredName, H.EmailAddress, [count rate %]= 100*cast(COUNT(*) AS float)/
							(SELECT Orders = COUNT(*)
							 FROM ORDERS)

FROM EXPERIENCES AS E JOIN HOSTS AS H ON E.EmailAddress = H.EmailAddress
                      JOIN REGISTEREDS AS R ON R.EmailAddress = H.EmailAddress

GROUP BY R.RegisteredName, H.EmailAddress
ORDER BY [count rate %] desc


-----Q5-------
ALTER TABLE HOSTS
ADD IsActive VARCHAR(10)

UPDATE HOSTS
SET IsActive = 'Active' 
WHERE EmailAddress IN ( SELECT H.EmailAddress
                        FROM HOSTS AS H 
                        WHERE H.EmailAddress NOT IN(SELECT E.EmailAddress
						                          FROM EXPERIENCES AS E JOIN SCHEDULES AS S ON  E.Experience = S.Experience 
						                          WHERE YEAR(GETDATE())-YEAR(S.ExperienceDT)<=3
				                                  GROUP BY E.EmailAddress)
)

SELECT * FROM HOSTS



-----Q6-------

SELECT TOP 10 [Popular Experience] = E.Experience, 
              [Amount of Sales] = SUM(O.NumberOfTicek * S.PricePerGuest)
FROM Experiences AS E JOIN Schedules AS S 
     ON S.Experience = E.Experience 
     JOIN Orders AS O ON O.Experience = E.Experience
GROUP BY E.Experience 
EXCEPT
SELECT [Popular Experience] = E.Experience, 
       [Amount of Sales] = SUM(O.NumberOfTicek * S.PricePerGuest)
FROM Experiences AS E JOIN Schedules AS S 
     ON S.Experience = E.Experience 
     JOIN Orders AS O ON O.Experience = E.Experience
     JOIN Reviews AS R ON R.Experience = E.Experience
GROUP BY E.Experience
HAVING AVG(R.Rating) < 4
ORDER BY SUM(O.NumberOfTicek * S.PricePerGuest) DESC



-----Q7-------
SELECT DISTINCT Month, TotalSales,
       [Previous Month Sales] = LAG(TotalSales) OVER (ORDER BY Month),
       [Sales Difference] = (TotalSales - LAG(TotalSales) OVER (ORDER BY Month))
FROM ( SELECT DISTINCT Month = MONTH(O.OrderDT),
              TotalSales = SUM(S.PricePerGuest * O.NumberOfTicek) OVER (ORDER BY MONTH(O.OrderDT)) 
       FROM   ORDERS AS O JOIN SCHEDULES AS S ON S.ExperienceDT = O.ExperienceDT) AS MS


-----Q8-------
SELECT DISTINCT CP.EmailAddress , [Total Purchases],
       [Customer Rank] = RANK() OVER (ORDER BY [Total Purchases] DESC),
       [Contribution Rate] = ([Total Purchases] / SUM([Total Purchases]) OVER ()) * 100
FROM ( SELECT C.EmailAddress,
              [Total Purchases] = SUM(S.PricePerGuest * O.NumberOfTicek) OVER (PARTITION BY C.EmailAddress) 
       FROM ORDERS AS O JOIN CUSTOMERS AS C ON C.EmailAddress = O.EmailAddress
	                 JOIN SCHEDULES AS S ON S.Experience = O.Experience) AS CP
ORDER BY [Contribution Rate] DESC



------WITH-------

WITH 
HostPerformance AS ( SELECT H.EmailAddress, COUNT(*) AS TotalExperiences,
                            SUM(S.PricePerGuest * O.NumberOfTicek) AS TotalRevenue,
                            AVG(S.PricePerGuest * O.NumberOfTicek) AS AverageRevenue
                     FROM HOSTS AS H JOIN EXPERIENCES AS E ON H.EmailAddress = E.EmailAddress
                                     JOIN SCHEDULES AS S ON E.Experience = S.Experience
                                     JOIN ORDERS AS O ON S.ExperienceDT = O.ExperienceDT
                     GROUP BY H.EmailAddress ),


CustomerBehavior AS ( SELECT H.EmailAddress, COUNT(*) AS TotalOrders,
                             SUM(S.PricePerGuest* O.NumberOfTicek) AS TotalSpent,
                             CASE WHEN COUNT(DISTINCT O.Experience) = 1 THEN 'First-time Customer'
                                                                          ELSE 'Returning Customer'
                                                                          END AS CustomerType
                      FROM ORDERS AS O JOIN EXPERIENCES AS E ON O.Experience = E.Experience
					                JOIN SCHEDULES AS S ON E.Experience = E.Experience 
                                    JOIN CUSTOMERS C ON O.EmailAddress = C.EmailAddress
									JOIN HOSTS AS H ON H.EmailAddress = E.EmailAddress
                      GROUP BY H.EmailAddress ),


MonthlyRevenue AS ( SELECT MONTH(O.OrderDT) AS OrderMonth,
                           SUM(O.NumberOfTicek * S.PricePerGuest) AS TotalRevenue
                    FROM ORDERS AS O JOIN SCHEDULES AS S ON S.Experience = O.Experience
                    GROUP BY MONTH(O.OrderDT)
)


SELECT HP.EmailAddress, HP.TotalExperiences, HP.TotalRevenue,
       HP.AverageRevenue, CB.TotalOrders,
       CB.TotalSpent, CB.CustomerType,
       MR.OrderMonth, MR.TotalRevenue AS MonthlTotalyRevenue,
       [RevenueRate] = (MR.TotalRevenue / (SELECT SUM(TotalRevenue) FROM MonthlyRevenue)) * 100 

FROM HostPerformance AS HP LEFT JOIN CustomerBehavior AS CB ON HP.EmailAddress = CB.EmailAddress
                           JOIN ORDERS AS O ON O.EmailAddress = HP.EmailAddress 
                           LEFT JOIN MonthlyRevenue AS MR ON MR.OrderMonth = MONTH(O.OrderDT)
ORDER BY MR.OrderMonth






