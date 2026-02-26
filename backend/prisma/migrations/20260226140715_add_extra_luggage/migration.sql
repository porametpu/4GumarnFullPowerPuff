-- CreateEnum
CREATE TYPE "ExtraLuggageType" AS ENUM ('MEDIUM', 'LARGE', 'EXTRA_LARGE');

-- AlterTable
ALTER TABLE "Booking" ADD COLUMN     "extraLuggageFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "extraLuggageSelected" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "extraLuggageType" "ExtraLuggageType";

-- AlterTable
ALTER TABLE "Route" ADD COLUMN     "allowExtraLuggage" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "maxExtraLuggageType" "ExtraLuggageType";
