const path = require('path');
const fs = require('fs');

// Load .env from backend directory manually to avoid dependency issues in test environment
const envPath = path.join(__dirname, '../../../../code/backend/.env');
try {
    if (fs.existsSync(envPath)) {
        const envConfig = fs.readFileSync(envPath, 'utf8');
        envConfig.split('\n').forEach(line => {
            const trimmedLine = line.trim();
            if (trimmedLine && !trimmedLine.startsWith('#')) {
                const firstEquals = trimmedLine.indexOf('=');
                if (firstEquals !== -1) {
                    const key = trimmedLine.substring(0, firstEquals).trim();
                    const value = trimmedLine.substring(firstEquals + 1).trim().replace(/^["']|["']$/g, '');
                    process.env[key] = value;
                }
            }
        });
        console.error('[Helper] Successfully loaded environment from .env');
    } else {
        console.error('[Helper] Warning: .env file not found at', envPath);
    }
} catch (err) {
    console.error('[Helper] Error parsing .env file:', err.message);
}

const cleanupPath = path.join(__dirname, '../../../../code/backend/cron/cleanup');

console.error('[Helper] Loading cleanup module from:', cleanupPath);

let cleanupModule;
try {
    cleanupModule = require(cleanupPath);
} catch (e) {
    console.error('[Helper] Failed to require cleanup module:', e.message);
    process.exit(1);
}

const { runCleanupJob, prisma } = cleanupModule;

console.error('[Helper] Imported prisma exists:', !!prisma);
console.error('[Helper] Imported runCleanupJob exists:', !!runCleanupJob);

async function setupTestData(testCase) {
    console.error(`[Helper] Setting up data for: ${testCase}`);

    if (!prisma) {
        console.error('[Helper] CRITICAL: prisma is undefined in imported module!');
        throw new Error('Prisma instance is undefined');
    }

    // Clear existing test users to avoid unique constraint issues
    await prisma.user.deleteMany({
        where: { email: { startsWith: 'test_cleanup_' } }
    });
    console.error(`[Helper] Cleared old test users`);

    const now = new Date();
    const ninetyOneDaysAgo = new Date();
    ninetyOneDaysAgo.setDate(now.getDate() - 91);
    const eightyNineDaysAgo = new Date();
    eightyNineDaysAgo.setDate(now.getDate() - 89);

    if (testCase === 'related_records') {
        console.error(`[Helper] Creating user...`);
        const user = await prisma.user.create({
            data: {
                username: 'test_cleanup_related',
                email: 'test_cleanup_related@test.com',
                password: 'hashedpassword',
                isActive: false,
                deletedAt: ninetyOneDaysAgo,
            }
        });

        console.error(`[Helper] User created: ${user.id}. Creating vehicle...`);
        // We create a vehicle for this user to ensure we don't have hardcoded ID issues
        const vehicle = await prisma.vehicle.create({
            data: {
                userId: user.id,
                vehicleModel: 'Test Model',
                licensePlate: 'UAT-' + Math.floor(Math.random() * 100000),
                vehicleType: 'Sedan',
                color: 'Black',
                seatCapacity: 4,
            }
        });

        console.error(`[Helper] Vehicle created: ${vehicle.id}. Creating route...`);
        const route = await prisma.route.create({
            data: {
                driverId: user.id,
                vehicleId: vehicle.id,
                departureTime: now,
                availableSeats: 4,
                pricePerSeat: 100,
                startLocation: { name: 'A' },
                endLocation: { name: 'B' },
            }
        });

        console.error(`[Helper] Route created: ${route.id}. Creating notification...`);
        await prisma.notification.create({
            data: { userId: user.id, title: 'Test', body: 'Test Notification' }
        });

        console.error(`[Helper] Notification created. Setup done.`);
        return { userId: user.id, email: user.email };

    } else if (testCase === 'many_accounts') {
        const users = [];
        for (let i = 1; i <= 3; i++) {
            const u = await prisma.user.create({
                data: {
                    username: `test_cleanup_batch_${i}`,
                    email: `test_cleanup_batch_${i}@test.com`,
                    password: 'hashedpassword',
                    isActive: false,
                    deletedAt: ninetyOneDaysAgo,
                }
            });
            users.push(u.id);
        }
        return users;

    } else if (testCase === 'no_delete') {
        const user = await prisma.user.create({
            data: {
                username: 'test_cleanup_recent',
                email: 'test_cleanup_recent@test.com',
                password: 'hashedpassword',
                isActive: false,
                deletedAt: eightyNineDaysAgo,
            }
        });
        return user.id;

    } else if (testCase === 'active_account') {
        const user = await prisma.user.create({
            data: {
                username: 'test_cleanup_active',
                email: 'test_cleanup_active@test.com',
                password: 'hashedpassword',
                isActive: true, // Should NOT be deleted
                deletedAt: ninetyOneDaysAgo,
            }
        });
        return user.id;
    }
}

async function verifyState(testCase, idOrIds) {
    if (Array.isArray(idOrIds)) {
        const count = await prisma.user.count({ where: { id: { in: idOrIds } } });
        return count === 0;
    } else {
        const user = await prisma.user.findUnique({ where: { id: idOrIds } });
        if (testCase === 'no_delete' || testCase === 'active_account') {
            return user !== null;
        }
        return user === null;
    }
}

const action = process.argv[2];
const arg1 = process.argv[3];
const arg2 = process.argv[4];

(async () => {
    try {
        if (action === 'setup') {
            const result = await setupTestData(arg1);
            console.log(JSON.stringify(result));
        } else if (action === 'run') {
            console.error(`[Helper] Running cleanup job...`);
            const deletedCount = await runCleanupJob();
            console.log(deletedCount);
        } else if (action === 'verify') {
            const result = await verifyState(arg1, JSON.parse(arg2));
            console.log(result);
        }
        console.error(`[Helper] Disconnecting Prisma...`);
        if (prisma) {
            await prisma.$disconnect();
        }
        console.error(`[Helper] Execution finished.`);
        process.exit(0);
    } catch (err) {
        console.error(`[Helper] ERROR:`, err);
        process.exit(1);
    }
})();
