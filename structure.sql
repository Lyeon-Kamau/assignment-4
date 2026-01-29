-- Customers Table--

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    Address VARCHAR(255),
    RegistrationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP

  -- Indexes for common queries--

    INDEX idx_customer_email (Email),
    INDEX idx_customer_name (CustomerName)
) ENGINE=InnoDB;


-- Vehicles Table--

CREATE TABLE Vehicles (
    VehicleID INT PRIMARY KEY AUTO_INCREMENT,
    Make VARCHAR(50) NOT NULL,
    Model VARCHAR(50) NOT NULL,
    Year INT NOT NULL,
    LicensePlate VARCHAR(20) UNIQUE NOT NULL,
    DailyRate DECIMAL(10, 2) NOT NULL,
    Status ENUM('Available', 'Rented', 'Unavailable') DEFAULT 'Available',
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP

  -- Composite index for vehicle availability search--
  
    INDEX idx_vehicles_search (Status, DailyRate, Year),
    INDEX idx_vehicles_make_model (Make, Model),
    INDEX idx_vehicle_rate (DailyRate)
) ENGINE=InnoDB;

-- Rentals Table --
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
    FOREIGN KEY (VehicleID) REFERENCES Vehicles(VehicleID)

  -- Performance indexes--
    INDEX idx_rentals_customer (CustomerID),
    INDEX idx_rentals_vehicle (VehicleID),
    INDEX idx_rentals_dates (RentalDate, ReturnDate),
    INDEX idx_rentals_status (Status),
    INDEX idx_rentals_date_status (RentalDate, Status, VehicleID),
    INDEX idx_rentals_return (ReturnDate)
) ENGINE=InnoDB;

-- CustomerPoints Table --
CREATE TABLE CustomerPoints (
    PointID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    TotalPoints DECIMAL(10, 2) DEFAULT 0.00,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    UNIQUE KEY (CustomerID)

--indexes for total points--

  INDEX idx_points_total (TotalPoints DESC)
) ENGINE=InnoDB;

-- PointsHistory Table --
CREATE TABLE PointsHistory (
    HistoryID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    RentalID INT NOT NULL,
    PointsAwarded DECIMAL(10, 2),
    AwardedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    DaysRemaining INT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (RentalID) REFERENCES Rentals(RentalID)

--Indexes for points history --
INDEX idx_history_customer (CustomerID),
    INDEX idx_history_date (AwardedDate)
) ENGINE=InnoDB;