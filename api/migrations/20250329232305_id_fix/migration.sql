/*
  Warnings:

  - The primary key for the `TwoFactorCode` table will be changed. If it partially fails, the table could be left without primary key constraint.

*/
-- DropIndex
DROP INDEX "TwoFactorCode_code_key";

-- AlterTable
ALTER TABLE "TwoFactorCode" DROP CONSTRAINT "TwoFactorCode_pkey",
ADD CONSTRAINT "TwoFactorCode_pkey" PRIMARY KEY ("userId", "code");
