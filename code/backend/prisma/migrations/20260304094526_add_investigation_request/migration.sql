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

-- CreateIndex
CREATE INDEX "InvestigationRequest_requestNumber_idx" ON "InvestigationRequest"("requestNumber");

-- CreateIndex
CREATE INDEX "InvestigationRequest_bookingId_idx" ON "InvestigationRequest"("bookingId");

-- CreateIndex
CREATE INDEX "InvestigationRequest_createdById_idx" ON "InvestigationRequest"("createdById");

-- AddForeignKey
ALTER TABLE "InvestigationRequest" ADD CONSTRAINT "InvestigationRequest_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InvestigationRequest" ADD CONSTRAINT "InvestigationRequest_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
