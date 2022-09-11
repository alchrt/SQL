/* Data cleaning project to make the data much more usable and standardized using SQL based on Alex The Analyst's Project Portfolio series,
using Nashville housing data from https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx */

-- Data check

SELECT *
FROM PortfolioProject..Housing;

-- Changing/standardizing the date format

ALTER TABLE PortfolioProject..Housing
ADD SaleDateConverted Date;

UPDATE PortfolioProject..Housing
SET SaleDateConverted = CONVERT(date,SaleDate);

SELECT SaleDateConverted, CONVERT(date,SaleDate)
FROM PortfolioProject..Housing;

--------------------------------------------------------------------------------------------------------

-- Populating the property address data

SELECT *
FROM PortfolioProject..Housing
ORDER BY ParcelID;  -- the ParcelID is going to match the same address every time and serve as a reference point

SELECT a.ParcelID,
	   a.PropertyAddress,
	   b.ParcelID,
	   b.PropertyAddress,
	   ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..Housing a
JOIN PortfolioProject..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..Housing a
JOIN PortfolioProject..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL;


--------------------------------------------------------------------------------------------------------

-- Breaking out the address into individual columns (Address, City, State)
-- PropertyAddress first

SELECT PropertyAddress
FROM PortfolioProject..Housing;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 ) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , Len(PropertyAddress)) AS City
FROM PortfolioProject..Housing;

ALTER TABLE PortfolioProject..Housing
ADD PropertySplitAddress nvarchar(255);

UPDATE PortfolioProject..Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 );

ALTER TABLE PortfolioProject..Housing
ADD PropertySplitCity nvarchar(255);

UPDATE PortfolioProject..Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , Len(PropertyAddress));


-- OwnerAddress next

SELECT OwnerAddress
FROM PortfolioProject..Housing;

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..Housing;

ALTER TABLE PortfolioProject..Housing
ADD OwnerSplitAddress nvarchar(255);

UPDATE PortfolioProject..Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE PortfolioProject..Housing
ADD OwnerSplitCity nvarchar(255);

UPDATE PortfolioProject..Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE PortfolioProject..Housing
ADD OwnerSplitState nvarchar(255);

UPDATE PortfolioProject..Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);


--------------------------------------------------------------------------------------------------------

-- Changing Y and N to Yes and No in the 'Sold as Vacant' field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS DistinctCount
FROM PortfolioProject..Housing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM PortfolioProject..Housing;

UPDATE PortfolioProject..Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END;


--------------------------------------------------------------------------------------------------------

-- Removing duplicates

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM PortfolioProject..Housing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


--------------------------------------------------------------------------------------------------------

-- Removing unused columns

ALTER TABLE PortfolioProject..Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE PortfolioProject..Housing
DROP COLUMN SaleDate;


