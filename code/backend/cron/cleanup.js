const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

cron.schedule('0 3 * * *', async () => {

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
      return;
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

  } catch (error) {
    console.error('[Cleanup Job] ERROR:', error.message);
    console.error(error.stack);
  } finally {
    console.log(`[Cleanup Job] จบการทำงาน: ${new Date().toISOString()}`);
  }
});

process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});