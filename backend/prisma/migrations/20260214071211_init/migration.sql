-- AlterTable
ALTER TABLE "User" ADD COLUMN     "deleteRequestAt" TIMESTAMP(3),
ADD COLUMN     "deleteScheduledFor" TIMESTAMP(3);
