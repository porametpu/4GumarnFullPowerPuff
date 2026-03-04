/*
  Warnings:

  - You are about to drop the `InvestigationRequest` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[nationalIdNumber]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[nationalIdPhotoUrl]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `updatedAt` to the `Route` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Vehicle` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "CancelReason" AS ENUM ('CHANGE_OF_PLAN', 'FOUND_ALTERNATIVE', 'DRIVER_DELAY', 'PRICE_ISSUE', 'WRONG_LOCATION', 'DUPLICATE_OR_WRONG_DATE', 'SAFETY_CONCERN', 'WEATHER_OR_FORCE_MAJEURE', 'COMMUNICATION_ISSUE');

-- CreateEnum
CREATE TYPE "LicenseType" AS ENUM ('PRIVATE_CAR_TEMPORARY', 'PRIVATE_CAR', 'PUBLIC_CAR', 'LIFETIME');

-- CreateEnum
CREATE TYPE "ExtraLuggageType" AS ENUM ('MEDIUM', 'LARGE', 'EXTRA_LARGE');

-- DropForeignKey
ALTER TABLE "Booking" DROP CONSTRAINT "Booking_passengerId_fkey";

-- DropForeignKey
ALTER TABLE "Booking" DROP CONSTRAINT "Booking_routeId_fkey";

-- DropForeignKey
ALTER TABLE "InvestigationRequest" DROP CONSTRAINT "InvestigationRequest_bookingId_fkey";

-- DropForeignKey
ALTER TABLE "InvestigationRequest" DROP CONSTRAINT "InvestigationRequest_createdById_fkey";

-- DropForeignKey
ALTER TABLE "Route" DROP CONSTRAINT "Route_driverId_fkey";

-- DropForeignKey
ALTER TABLE "Route" DROP CONSTRAINT "Route_vehicleId_fkey";

-- DropForeignKey
ALTER TABLE "Vehicle" DROP CONSTRAINT "Vehicle_userId_fkey";

-- AlterTable
ALTER TABLE "Booking" ADD COLUMN     "cancelReason" "CancelReason",
ADD COLUMN     "cancelledAt" TIMESTAMP(3),
ADD COLUMN     "cancelledBy" TEXT,
ADD COLUMN     "extraLuggageFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "extraLuggageSelected" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "extraLuggageType" "ExtraLuggageType",
ALTER COLUMN "pickupLocation" SET DATA TYPE JSON,
ALTER COLUMN "dropoffLocation" SET DATA TYPE JSON;

-- AlterTable
ALTER TABLE "Route" ADD COLUMN     "allowExtraLuggage" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "cancelledAt" TIMESTAMP(3),
ADD COLUMN     "cancelledBy" TEXT,
ADD COLUMN     "conditions" TEXT,
ADD COLUMN     "distance" TEXT,
ADD COLUMN     "distanceMeters" INTEGER,
ADD COLUMN     "duration" TEXT,
ADD COLUMN     "durationSeconds" INTEGER,
ADD COLUMN     "landmarks" JSON,
ADD COLUMN     "maxExtraLuggageType" "ExtraLuggageType",
ADD COLUMN     "routePolyline" TEXT,
ADD COLUMN     "routeSummary" TEXT,
ADD COLUMN     "steps" JSON,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "waypoints" JSON,
ALTER COLUMN "startLocation" SET DATA TYPE JSON,
ALTER COLUMN "endLocation" SET DATA TYPE JSON;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "deleteRequestAt" TIMESTAMP(3),
ADD COLUMN     "deleteScheduledFor" TIMESTAMP(3),
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "driverSuspendedUntil" TIMESTAMP(3),
ADD COLUMN     "gender" TEXT,
ADD COLUMN     "isVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "lastLogin" TIMESTAMP(3),
ADD COLUMN     "nationalIdExpiryDate" TIMESTAMP(3),
ADD COLUMN     "nationalIdNumber" TEXT,
ADD COLUMN     "nationalIdPhotoUrl" TEXT,
ADD COLUMN     "otpCode" TEXT,
ADD COLUMN     "passengerSuspendedUntil" TIMESTAMP(3),
ADD COLUMN     "phoneNumber" TEXT,
ADD COLUMN     "profilePicture" TEXT,
ADD COLUMN     "selfiePhotoUrl" TEXT;

-- AlterTable
ALTER TABLE "Vehicle" ADD COLUMN     "amenities" TEXT[],
ADD COLUMN     "isDefault" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "photos" JSON,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- DropTable
DROP TABLE "InvestigationRequest";

-- CreateTable
CREATE TABLE "DriverVerification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "licenseNumber" TEXT NOT NULL,
    "firstNameOnLicense" TEXT NOT NULL,
    "lastNameOnLicense" TEXT NOT NULL,
    "licenseIssueDate" TIMESTAMP(3) NOT NULL,
    "licenseExpiryDate" TIMESTAMP(3) NOT NULL,
    "licensePhotoUrl" TEXT NOT NULL,
    "selfiePhotoUrl" TEXT NOT NULL,
    "typeOnLicense" "LicenseType" NOT NULL,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DriverVerification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL DEFAULT 'SYSTEM',
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "link" TEXT,
    "metadata" JSON,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "adminReviewedAt" TIMESTAMP(3),

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DriverVerification_userId_key" ON "DriverVerification"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "DriverVerification_licenseNumber_key" ON "DriverVerification"("licenseNumber");

-- CreateIndex
CREATE INDEX "DriverVerification_status_idx" ON "DriverVerification"("status");

-- CreateIndex
CREATE INDEX "DriverVerification_createdAt_idx" ON "DriverVerification"("createdAt");

-- CreateIndex
CREATE INDEX "DriverVerification_licenseIssueDate_idx" ON "DriverVerification"("licenseIssueDate");

-- CreateIndex
CREATE INDEX "DriverVerification_licenseExpiryDate_idx" ON "DriverVerification"("licenseExpiryDate");

-- CreateIndex
CREATE INDEX "Notification_userId_createdAt_idx" ON "Notification"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "Notification_userId_readAt_idx" ON "Notification"("userId", "readAt");

-- CreateIndex
CREATE INDEX "Notification_adminReviewedAt_idx" ON "Notification"("adminReviewedAt");

-- CreateIndex
CREATE INDEX "Route_driverId_idx" ON "Route"("driverId");

-- CreateIndex
CREATE INDEX "Route_vehicleId_idx" ON "Route"("vehicleId");

-- CreateIndex
CREATE INDEX "Route_status_idx" ON "Route"("status");

-- CreateIndex
CREATE INDEX "Route_createdAt_idx" ON "Route"("createdAt");

-- CreateIndex
CREATE INDEX "Route_departureTime_idx" ON "Route"("departureTime");

-- CreateIndex
CREATE UNIQUE INDEX "User_nationalIdNumber_key" ON "User"("nationalIdNumber");

-- CreateIndex
CREATE UNIQUE INDEX "User_nationalIdPhotoUrl_key" ON "User"("nationalIdPhotoUrl");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE INDEX "User_isActive_idx" ON "User"("isActive");

-- CreateIndex
CREATE INDEX "User_isVerified_idx" ON "User"("isVerified");

-- CreateIndex
CREATE INDEX "User_createdAt_idx" ON "User"("createdAt");

-- CreateIndex
CREATE INDEX "Vehicle_userId_idx" ON "Vehicle"("userId");

-- CreateIndex
CREATE INDEX "Vehicle_createdAt_idx" ON "Vehicle"("createdAt");

-- CreateIndex
CREATE INDEX "Vehicle_vehicleType_idx" ON "Vehicle"("vehicleType");

-- CreateIndex
CREATE INDEX "Vehicle_seatCapacity_idx" ON "Vehicle"("seatCapacity");

-- AddForeignKey
ALTER TABLE "DriverVerification" ADD CONSTRAINT "DriverVerification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Route" ADD CONSTRAINT "Route_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Route" ADD CONSTRAINT "Route_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_routeId_fkey" FOREIGN KEY ("routeId") REFERENCES "Route"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_passengerId_fkey" FOREIGN KEY ("passengerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
