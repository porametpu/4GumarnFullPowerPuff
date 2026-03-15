-- CreateTable
CREATE TABLE "DriverNearAlert" (
    "id" TEXT NOT NULL,
    "routeId" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "passengerId" TEXT NOT NULL,
    "driverLat" DOUBLE PRECISION NOT NULL,
    "driverLng" DOUBLE PRECISION NOT NULL,
    "distanceKm" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DriverNearAlert_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "DriverNearAlert_passengerId_createdAt_idx" ON "DriverNearAlert"("passengerId", "createdAt");

-- CreateIndex
CREATE INDEX "DriverNearAlert_driverId_createdAt_idx" ON "DriverNearAlert"("driverId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "DriverNearAlert_routeId_bookingId_key" ON "DriverNearAlert"("routeId", "bookingId");

-- AddForeignKey
ALTER TABLE "DriverNearAlert" ADD CONSTRAINT "DriverNearAlert_routeId_fkey" FOREIGN KEY ("routeId") REFERENCES "Route"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DriverNearAlert" ADD CONSTRAINT "DriverNearAlert_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;
