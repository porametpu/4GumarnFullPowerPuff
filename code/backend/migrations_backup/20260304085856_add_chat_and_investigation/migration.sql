/*
  Warnings:

  - You are about to drop the column `cancelReason` on the `Booking` table. All the data in the column will be lost.
  - You are about to drop the column `cancelledAt` on the `Booking` table. All the data in the column will be lost.
  - You are about to drop the column `cancelledBy` on the `Booking` table. All the data in the column will be lost.
  - You are about to drop the column `extraLuggageFee` on the `Booking` table. All the data in the column will be lost.
  - You are about to drop the column `extraLuggageSelected` on the `Booking` table. All the data in the column will be lost.
  - You are about to drop the column `extraLuggageType` on the `Booking` table. All the data in the column will be lost.
  - You are about to drop the column `allowExtraLuggage` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `cancelledAt` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `cancelledBy` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `conditions` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `distance` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `distanceMeters` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `duration` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `durationSeconds` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `landmarks` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `maxExtraLuggageType` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `routePolyline` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `routeSummary` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `steps` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `updatedAt` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `waypoints` on the `Route` table. All the data in the column will be lost.
  - You are about to drop the column `deleteRequestAt` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `deleteScheduledFor` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `deletedAt` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `driverSuspendedUntil` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `gender` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `isVerified` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `lastLogin` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `nationalIdExpiryDate` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `nationalIdNumber` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `nationalIdPhotoUrl` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `otpCode` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `passengerSuspendedUntil` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `profilePicture` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `selfiePhotoUrl` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `amenities` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `isDefault` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `photos` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `updatedAt` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the `DriverVerification` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Notification` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Booking" DROP CONSTRAINT "Booking_passengerId_fkey";

-- DropForeignKey
ALTER TABLE "Booking" DROP CONSTRAINT "Booking_routeId_fkey";

-- DropForeignKey
ALTER TABLE "DriverVerification" DROP CONSTRAINT "DriverVerification_userId_fkey";

-- DropForeignKey
ALTER TABLE "Notification" DROP CONSTRAINT "Notification_userId_fkey";

-- DropForeignKey
ALTER TABLE "Route" DROP CONSTRAINT "Route_driverId_fkey";

-- DropForeignKey
ALTER TABLE "Route" DROP CONSTRAINT "Route_vehicleId_fkey";

-- DropIndex
DROP INDEX "Route_createdAt_idx";

-- DropIndex
DROP INDEX "Route_departureTime_idx";

-- DropIndex
DROP INDEX "Route_driverId_idx";

-- DropIndex
DROP INDEX "Route_status_idx";

-- DropIndex
DROP INDEX "Route_vehicleId_idx";

-- DropIndex
DROP INDEX "User_createdAt_idx";

-- DropIndex
DROP INDEX "User_isActive_idx";

-- DropIndex
DROP INDEX "User_isVerified_idx";

-- DropIndex
DROP INDEX "User_nationalIdNumber_key";

-- DropIndex
DROP INDEX "User_nationalIdPhotoUrl_key";

-- DropIndex
DROP INDEX "User_role_idx";

-- DropIndex
DROP INDEX "Vehicle_createdAt_idx";

-- DropIndex
DROP INDEX "Vehicle_seatCapacity_idx";

-- DropIndex
DROP INDEX "Vehicle_userId_idx";

-- DropIndex
DROP INDEX "Vehicle_vehicleType_idx";

-- AlterTable
ALTER TABLE "Booking" DROP COLUMN "cancelReason",
DROP COLUMN "cancelledAt",
DROP COLUMN "cancelledBy",
DROP COLUMN "extraLuggageFee",
DROP COLUMN "extraLuggageSelected",
DROP COLUMN "extraLuggageType",
ALTER COLUMN "pickupLocation" SET DATA TYPE JSONB,
ALTER COLUMN "dropoffLocation" SET DATA TYPE JSONB;

-- AlterTable
ALTER TABLE "Route" DROP COLUMN "allowExtraLuggage",
DROP COLUMN "cancelledAt",
DROP COLUMN "cancelledBy",
DROP COLUMN "conditions",
DROP COLUMN "distance",
DROP COLUMN "distanceMeters",
DROP COLUMN "duration",
DROP COLUMN "durationSeconds",
DROP COLUMN "landmarks",
DROP COLUMN "maxExtraLuggageType",
DROP COLUMN "routePolyline",
DROP COLUMN "routeSummary",
DROP COLUMN "steps",
DROP COLUMN "updatedAt",
DROP COLUMN "waypoints",
ALTER COLUMN "startLocation" SET DATA TYPE JSONB,
ALTER COLUMN "endLocation" SET DATA TYPE JSONB;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "deleteRequestAt",
DROP COLUMN "deleteScheduledFor",
DROP COLUMN "deletedAt",
DROP COLUMN "driverSuspendedUntil",
DROP COLUMN "gender",
DROP COLUMN "isVerified",
DROP COLUMN "lastLogin",
DROP COLUMN "nationalIdExpiryDate",
DROP COLUMN "nationalIdNumber",
DROP COLUMN "nationalIdPhotoUrl",
DROP COLUMN "otpCode",
DROP COLUMN "passengerSuspendedUntil",
DROP COLUMN "profilePicture",
DROP COLUMN "selfiePhotoUrl";

-- AlterTable
ALTER TABLE "Vehicle" DROP COLUMN "amenities",
DROP COLUMN "isDefault",
DROP COLUMN "photos",
DROP COLUMN "updatedAt";

-- DropTable
DROP TABLE "DriverVerification";

-- DropTable
DROP TABLE "Notification";

-- DropEnum
DROP TYPE "CancelReason";

-- DropEnum
DROP TYPE "ExtraLuggageType";

-- DropEnum
DROP TYPE "LicenseType";

-- CreateTable
CREATE TABLE "InvestigationRequest" (
    "id" TEXT NOT NULL,
    "requestNumber" TEXT NOT NULL,
    "authorityName" TEXT NOT NULL,
    "officerName" TEXT NOT NULL,
    "officerPosition" TEXT,
    "contactEmail" TEXT NOT NULL,
    "contactPhone" TEXT NOT NULL,
    "requestDate" TIMESTAMP(3) NOT NULL,
    "bookingId" TEXT NOT NULL,
    "fromDate" TIMESTAMP(3) NOT NULL,
    "toDate" TIMESTAMP(3) NOT NULL,
    "reason" TEXT,
    "officialDocumentUrl" TEXT,
    "officialDocumentName" TEXT,
    "exportedFileUrl" TEXT,
    "exportedAt" TIMESTAMP(3),
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InvestigationRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "InvestigationRequest_requestNumber_key" ON "InvestigationRequest"("requestNumber");

-- AddForeignKey
ALTER TABLE "Route" ADD CONSTRAINT "Route_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Route" ADD CONSTRAINT "Route_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_routeId_fkey" FOREIGN KEY ("routeId") REFERENCES "Route"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_passengerId_fkey" FOREIGN KEY ("passengerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InvestigationRequest" ADD CONSTRAINT "InvestigationRequest_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InvestigationRequest" ADD CONSTRAINT "InvestigationRequest_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
