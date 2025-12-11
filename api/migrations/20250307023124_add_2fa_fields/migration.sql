/*
  Warnings:

  - You are about to drop the column `twoFAEnable` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `twoFAExpiry` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "User" DROP COLUMN "twoFAEnable",
DROP COLUMN "twoFAExpiry",
ADD COLUMN     "twoFACodeExpiry" TIMESTAMP(3),
ADD COLUMN     "twoFAEnabled" BOOLEAN NOT NULL DEFAULT false;
