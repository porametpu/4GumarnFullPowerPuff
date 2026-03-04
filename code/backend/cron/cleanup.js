const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const runCleanupJob = async () => {
  console.log('[Cleanup Job] เริ่มการทำงาน...');
  try {
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const usersToDelete = await prisma.user.findMany({
      where: {
        deletedAt: {
          lte: ninetyDaysAgo,
        },
        isActive: false,
      },
      select: {
        id: true,
        email: true,
      },
    });

    if (usersToDelete.length === 0) {
      console.log('[Cleanup Job] ไม่พบบัญชีที่ครบกำหนดลบ');
      return 0;
    }

    console.log(`[Cleanup Job] พบ ${usersToDelete.length} บัญชีที่ต้องลบถาวร`);
    await prisma.$transaction(async (tx) => {
      for (const user of usersToDelete) {
        console.log(`[Cleanup Job] กำลังลบผู้ใช้: ${user.email} (ID: ${user.id})`);

        await tx.booking.deleteMany({ where: { passengerId: user.id } });
        await tx.vehicle.deleteMany({ where: { userId: user.id } });
        await tx.route.deleteMany({ where: { driverId: user.id } });
        await tx.notification.deleteMany({ where: { userId: user.id } });

        await tx.user.delete({ where: { id: user.id } });
      }
    });

    console.log(`[Cleanup Job] ลบถาวรสำเร็จทั้งหมด ${usersToDelete.length} บัญชี`);
    return usersToDelete.length;

  } catch (error) {
    console.error('[Cleanup Job] ERROR:', error.message);
    throw error;
  } finally {
    console.log(`[Cleanup Job] จบการทำงาน: ${new Date().toISOString()}`);
  }
};

// Schedule the cron job to run at 3:00 AM every day
cron.schedule('0 3 * * *', async () => {
  await runCleanupJob();
});

// Export for testing
module.exports = {
  runCleanupJob,
  prisma
};

// Handle graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});