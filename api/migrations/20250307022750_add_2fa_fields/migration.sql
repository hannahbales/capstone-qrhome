-- AlterTable
ALTER TABLE "User" ADD COLUMN     "twoFACode" TEXT,
ADD COLUMN     "twoFAEnable" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "twoFAExpiry" TIMESTAMP(3);
