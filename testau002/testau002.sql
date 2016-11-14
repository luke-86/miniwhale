USE db;
DROP TABLE IF EXISTS Persons;
CREATE TABLE Persons (PersonID int, LastName varchar(255), FirstName varchar(255)); 
INSERT INTO Persons VALUES (1, 'Flury', 'Lukas');
INSERT INTO Persons VALUES (2, 'Muster', 'Hans');
SET profiling = 1;
SELECT * from Persons;
SHOW PROFILES;
