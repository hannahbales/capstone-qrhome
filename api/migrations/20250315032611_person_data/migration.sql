/*
  Warnings:

  - You are about to drop the column `dob` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `firstName` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `lastName` on the `User` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[personal_info_id]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `personal_info_id` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "User" DROP COLUMN "dob",
DROP COLUMN "firstName",
DROP COLUMN "lastName",
ADD COLUMN     "personal_info_id" INTEGER NOT NULL;

-- CreateTable
CREATE TABLE "PersonalInfo" (
    "id" SERIAL NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "dob" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PersonalInfo_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_personal_info_id_key" ON "User"("personal_info_id");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_personal_info_id_fkey" FOREIGN KEY ("personal_info_id") REFERENCES "PersonalInfo"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
