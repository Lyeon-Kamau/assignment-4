-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 26, 2026 at 11:23 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `assignment 4`
--
CREATE DATABASE IF NOT EXISTS `assignment 4` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `assignment 4`;

-- --------------------------------------------------------

--
-- Table structure for table `customerpoints`
--

CREATE TABLE `customerpoints` (
  `PointID` int(11) NOT NULL,
  `CustomerID` int(11) NOT NULL,
  `TotalPoints` decimal(10,2) DEFAULT 0.00,
  `LastUpdated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `CustomerID` int(11) NOT NULL,
  `CustomerName` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Phone` varchar(20) DEFAULT NULL,
  `Address` varchar(255) DEFAULT NULL,
  `RegistrationDate` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pointshistory`
--

CREATE TABLE `pointshistory` (
  `HistoryID` int(11) NOT NULL,
  `CustomerID` int(11) NOT NULL,
  `RentalID` int(11) NOT NULL,
  `PointsAwarded` decimal(10,2) DEFAULT NULL,
  `AwardedDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `DaysRemaining` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rentals`
--

CREATE TABLE `rentals` (
  `RentalID` int(11) NOT NULL,
  `CustomerID` int(11) NOT NULL,
  `VehicleID` int(11) NOT NULL,
  `RentalDate` date NOT NULL,
  `ReturnDate` date DEFAULT NULL,
  `Status` enum('Reserved','Active','Completed','Cancelled') DEFAULT 'Active',
  `TotalCost` decimal(10,2) DEFAULT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `UpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `rentals`
--
DELIMITER $$
CREATE TRIGGER `trg_award_loyalty_points` AFTER UPDATE ON `rentals` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `vehicles`
--

CREATE TABLE `vehicles` (
  `VehicleID` int(11) NOT NULL,
  `Make` varchar(50) NOT NULL,
  `Model` varchar(50) NOT NULL,
  `Year` int(11) NOT NULL,
  `LicensePlate` varchar(20) NOT NULL,
  `DailyRate` decimal(10,2) NOT NULL,
  `Status` enum('Available','Rented','Unavailable') DEFAULT 'Available',
  `CreatedDate` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `customerpoints`
--
ALTER TABLE `customerpoints`
  ADD PRIMARY KEY (`PointID`),
  ADD UNIQUE KEY `CustomerID` (`CustomerID`),
  ADD KEY `idx_points_total` (`TotalPoints`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`CustomerID`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD KEY `idx_customer_email` (`Email`),
  ADD KEY `idx_customer_name` (`CustomerName`);

--
-- Indexes for table `pointshistory`
--
ALTER TABLE `pointshistory`
  ADD PRIMARY KEY (`HistoryID`),
  ADD KEY `RentalID` (`RentalID`),
  ADD KEY `idx_history_customer` (`CustomerID`),
  ADD KEY `idx_history_date` (`AwardedDate`);

--
-- Indexes for table `rentals`
--
ALTER TABLE `rentals`
  ADD PRIMARY KEY (`RentalID`),
  ADD KEY `idx_rentals_customer` (`CustomerID`),
  ADD KEY `idx_rentals_vehicle` (`VehicleID`),
  ADD KEY `idx_rentals_dates` (`RentalDate`,`ReturnDate`),
  ADD KEY `idx_rentals_status` (`Status`),
  ADD KEY `idx_rentals_date_status` (`RentalDate`,`Status`,`VehicleID`),
  ADD KEY `idx_rentals_return` (`ReturnDate`);

--
-- Indexes for table `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`VehicleID`),
  ADD UNIQUE KEY `LicensePlate` (`LicensePlate`),
  ADD KEY `idx_vehicles_search` (`Status`,`DailyRate`,`Year`),
  ADD KEY `idx_vehicles_make_model` (`Make`,`Model`),
  ADD KEY `idx_vehicle_rate` (`DailyRate`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `customerpoints`
--
ALTER TABLE `customerpoints`
  MODIFY `PointID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `CustomerID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pointshistory`
--
ALTER TABLE `pointshistory`
  MODIFY `HistoryID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rentals`
--
ALTER TABLE `rentals`
  MODIFY `RentalID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vehicles`
--
ALTER TABLE `vehicles`
  MODIFY `VehicleID` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `customerpoints`
--
ALTER TABLE `customerpoints`
  ADD CONSTRAINT `customerpoints_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`);

--
-- Constraints for table `pointshistory`
--
ALTER TABLE `pointshistory`
  ADD CONSTRAINT `pointshistory_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`),
  ADD CONSTRAINT `pointshistory_ibfk_2` FOREIGN KEY (`RentalID`) REFERENCES `rentals` (`RentalID`);

--
-- Constraints for table `rentals`
--
ALTER TABLE `rentals`
  ADD CONSTRAINT `rentals_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`),
  ADD CONSTRAINT `rentals_ibfk_2` FOREIGN KEY (`VehicleID`) REFERENCES `vehicles` (`VehicleID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
