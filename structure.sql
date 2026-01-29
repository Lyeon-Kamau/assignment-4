-- Customers Table 

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    Address VARCHAR(255),
    RegistrationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer_email (Email),
    INDEX idx_customer_name (CustomerName)
) ENGINE=InnoDB;


-- Vehicles Table 

CREATE TABLE Vehicles (
    VehicleID INT PRIMARY KEY AUTO_INCREMENT,
    Make VARCHAR(50) NOT NULL,
    Model VARCHAR(50) NOT NULL,
    Year INT NOT NULL,
    LicensePlate VARCHAR(20) UNIQUE NOT NULL,
    DailyRate DECIMAL(10, 2) NOT NULL,
    Status ENUM('Available', 'Rented', 'Unavailable') DEFAULT 'Available',
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicles_search (Status, DailyRate, Year),
    INDEX idx_vehicles_make_model (Make, Model),
    INDEX idx_vehicle_rate (DailyRate)
) ENGINE=InnoDB;

-- Rentals Table 
CREATE TABLE Rentals (
    RentalID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    VehicleID INT NOT NULL,
    RentalDate DATE NOT NULL,
    ReturnDate DATE,
    Status ENUM('Reserved', 'Active', 'Completed', 'Cancelled') DEFAULT 'Active',
    TotalCost DECIMAL(10, 2),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID),
    INDEX idx_rentals_customer (CustomerID),
    INDEX idx_rentals_vehicle (VehicleID),
    INDEX idx_rentals_dates (RentalDate, ReturnDate),
    INDEX idx_rentals_status (Status),
    INDEX idx_rentals_date_status (RentalDate, Status, VehicleID),
    INDEX idx_rentals_return (ReturnDate)
) ENGINE=InnoDB;

-- CustomerPoints Table 
CREATE TABLE CustomerPoints (
    PointID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    TotalPoints DECIMAL(10, 2) DEFAULT 0.00,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    UNIQUE KEY (CustomerID),
    INDEX idx_points_total (TotalPoints DESC)
) ENGINE=InnoDB;

-- PointsHistory Table 
CREATE TABLE PointsHistory (
    HistoryID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    RentalID INT NOT NULL,
    PointsAwarded DECIMAL(10, 2),
    AwardedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    DaysRemaining INT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (RentalID) REFERENCES Rentals(RentalID),
    INDEX idx_history_customer (CustomerID),
    INDEX idx_history_date (AwardedDate)
) ENGINE=InnoDB;
DELIMITER $$

CREATE TRIGGER trg_award_loyalty_points
AFTER UPDATE ON Rentals
FOR EACH ROW
BEGIN
    DECLARE points_to_award DECIMAL(10,2);
    DECLARE days_remaining INT;
    DECLARE last_update_time TIMESTAMP;

    -- Fire only when status changes to Completed
    IF NEW.Status = 'Completed' AND OLD.Status <> 'Completed' THEN
        
        -- Calculate remaining days in current month
        SET days_remaining = DAY(LAST_DAY(CURDATE())) - DAY(CURDATE());

        -- Points formula
        SET points_to_award = days_remaining / 8.0;

        -- Get last update time (if exists)
        SELECT LastUpdated 
        INTO last_update_time
        FROM CustomerPoints
        WHERE CustomerID = NEW.CustomerID;

        -- If points exist and older than 6 months → reset
        IF last_update_time IS NOT NULL 
           AND last_update_time < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 6 MONTH) THEN

            UPDATE CustomerPoints
            SET TotalPoints = 0
            WHERE CustomerID = NEW.CustomerID;

        END IF;

        -- Add new points (insert or update)
        INSERT INTO CustomerPoints (CustomerID, TotalPoints)
        VALUES (NEW.CustomerID, points_to_award)
        ON DUPLICATE KEY UPDATE
            TotalPoints = TotalPoints + points_to_award,
            LastUpdated = CURRENT_TIMESTAMP;

        -- History record
        INSERT INTO PointsHistory 
            (CustomerID, RentalID, PointsAwarded, DaysRemaining)
        VALUES 
            (NEW.CustomerID, NEW.RentalID, points_to_award, days_remaining);

    END IF;
END$$

DELIMITER ;
INSERT INTO Customers (CustomerName, Email, Phone, Address)
SELECT 
    CONCAT('Customer_', n) AS CustomerName,
    CONCAT('customer', n, '@dreamrentals.com') AS Email,
    CONCAT('555-', LPAD(n, 4, '0')) AS Phone,
    CONCAT(n, ' Test Street, City, State') AS Address
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t3,
         (SELECT @row := 5) r
    WHERE @row < 1000
) numbers;
INSERT INTO Vehicles (Make, Model, Year, LicensePlate, DailyRate, Status)
SELECT 
    ELT(MOD(n, 10) + 1, 'Toyota', 'Honda', 'Ford', 'Chevrolet', 'Nissan', 'BMW', 'Mercedes', 'Audi', 'Tesla', 'Hyundai') AS Make,
    ELT(MOD(n, 7) + 1, 'Sedan', 'SUV', 'Truck', 'Coupe', 'Hatchback', 'Minivan', 'Crossover') AS Model,
    2020 + MOD(n, 5) AS Year,
    CONCAT('VEH-', LPAD(n, 4, '0')) AS LicensePlate,
    35.00 + MOD(n, 100) AS DailyRate,
    CASE 
        WHEN MOD(n, 10) = 0 THEN 'Maintenance'
        WHEN MOD(n, 5) = 0 THEN 'Rented'
        ELSE 'Available'
    END AS Status
FROM (
    SELECT @row2 := @row2 + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
          (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t3,
         (SELECT @row2 := 5) r
    WHERE @row2 < 500
) numbers;
INSERT INTO Rentals (CustomerID, VehicleID, RentalDate, ReturnDate, Status, TotalCost)
SELECT 
    1 + MOD(n, 1000) AS CustomerID,
    1 + MOD(n * 7, 500) AS VehicleID,
    DATE_SUB(CURDATE(), INTERVAL MOD(n, 365) DAY) AS RentalDate,
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL MOD(n, 365) DAY), INTERVAL (3 + MOD(n, 10)) DAY) AS ReturnDate,
    ELT(MOD(n, 4) + 1, 'Completed', 'Active', 'Reserved', 'Cancelled') AS Status,
    (40 + MOD(n, 100)) * (3 + MOD(n, 10)) AS TotalCost
FROM (
    SELECT @row3 := @row3 + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t3,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t4,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t5,
         (SELECT @row3 := 5) r
    WHERE @row3 < 100000
) numbers;

SET FOREIGN_KEY_CHECKS = 1;
SELECT 'Database Setup Complete!' AS Status;

SELECT 
    'Customers' AS TableName, 
    COUNT(*) AS RowCount,
    'User accounts' AS Description
FROM Customers
UNION ALL
SELECT 'Vehicles', COUNT(*), 'Vehicle fleet' FROM Vehicles
UNION ALL
SELECT 'Rentals', COUNT(*), 'Rental transactions' FROM Rentals
UNION ALL
SELECT 'CustomerPoints', COUNT(*), 'Loyalty accounts' FROM CustomerPoints;

-- Show index information
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN ('Customers', 'Vehicles', 'Rentals', 'CustomerPoints')
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

SELECT 'Ready for performance testing!' AS Message;