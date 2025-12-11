-- CreateTable
CREATE TABLE "UserLink" (
    "userId" INTEGER NOT NULL,
    "code" TEXT NOT NULL,

    CONSTRAINT "UserLink_pkey" PRIMARY KEY ("userId")
);

-- CreateIndex
CREATE UNIQUE INDEX "UserLink_code_key" ON "UserLink"("code");

-- AddForeignKey
ALTER TABLE "UserLink" ADD CONSTRAINT "UserLink_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
