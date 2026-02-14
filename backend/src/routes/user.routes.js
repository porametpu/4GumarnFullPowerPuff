const express = require('express');
const userController = require("../controllers/user.controller");
const validate = require('../middlewares/validate');
const upload = require('../middlewares/upload.middleware');
const { idParamSchema, createUserSchema, updateMyProfileSchema, updateUserByAdminSchema, updateUserStatusSchema, listUsersQuerySchema } = require('../validations/user.validation');
const { protect, requireAdmin } = require('../middlewares/auth');

const router = express.Router();

// --- Admin Routes ---
// GET /api/users/admin
router.get(
    '/admin',
    protect,
    requireAdmin,
    validate({ query: listUsersQuerySchema }),
    userController.adminListUsers
);

// PUT /api/users/admin/:id
router.put(
    '/admin/:id',
    protect,
    requireAdmin,
    upload.fields([
        { name: 'nationalIdPhotoUrl', maxCount: 1 },
        { name: 'selfiePhotoUrl', maxCount: 1 },
        { name: 'profilePicture', maxCount: 1 },
    ]),
    validate({ params: idParamSchema, body: updateUserByAdminSchema }),
    userController.adminUpdateUser
);

// DELETE /api/users/admin/:id
router.delete(
    '/admin/:id',
    protect,
    requireAdmin,
    validate({ params: idParamSchema }),
    userController.adminDeleteUser
);

// GET /api/users/admin/:id
router.get(
    '/admin/:id',
    protect,
    requireAdmin,
    validate({ params: idParamSchema }),
    userController.getUserById
);

// PATCH /api/users/admin/:id/status
router.patch(
    '/admin/:id/status',
    protect,
    requireAdmin,
    validate({ params: idParamSchema, body: updateUserStatusSchema }),
    userController.setUserStatus
);

// --- Public / User-specific Routes ---
// GET /api/users/me
router.get(
    '/me',
    protect,
    userController.getMyUser
);

// GET /api/users/:id
router.get(
    '/:id',
    validate({ params: idParamSchema }),
    userController.getUserPublicById
);

// POST /api/users
router.post(
    '/',
    upload.fields([
        { name: 'nationalIdPhotoUrl', maxCount: 1 },
        { name: 'selfiePhotoUrl', maxCount: 1 }
    ]),
    validate({ body: createUserSchema }),
    userController.createUser
);

// PUT /api/users/me
router.put(
    '/me',
    protect,
    upload.fields([
        { name: 'nationalIdPhotoUrl', maxCount: 1 },
        { name: 'selfiePhotoUrl', maxCount: 1 },
        { name: 'profilePicture', maxCount: 1 },
    ]),
    validate({ body: updateMyProfileSchema }),
    userController.updateCurrentUserProfile
);

// POST /api/users/delete-account
router.post('/delete-account', protect, async (req, res) => {
  try {
    const userId = req.user.sub || req.user.id;
    if (!userId) {
      return res.status(401).json({ message: 'Invalid token payload' });
    }

    const { email } = req.body;
    if (!email?.trim()) {
      return res.status(400).json({ message: 'กรุณาส่งอีเมลเพื่อยืนยัน' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, deletedAt: true, deleteScheduledFor: true }
    });

    if (!user) {
      return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    }

    if (user.email.toLowerCase() !== email.trim().toLowerCase()) {
      return res.status(400).json({ message: 'อีเมลไม่ตรงกับบัญชีนี้' });
    }

    if (user.deletedAt) {
      const scheduled = user.deleteScheduledFor 
        ? new Date(user.deleteScheduledFor).toLocaleDateString('th-TH') 
        : 'กำลังดำเนินการ';
      return res.status(400).json({ message: `บัญชีถูกขอให้ลบแล้ว จะถูกลบประมาณ ${scheduled}` });
    }

    const now = new Date();
    const deleteAt = new Date(now);
    deleteAt.setDate(now.getDate() + 90);

    await prisma.user.update({
      where: { id: userId },
      data: {
        deletedAt: now,
        deleteRequestAt: now,
        deleteScheduledFor: deleteAt,
        isActive: false
      }
    });

    res.status(202).json({
      message: 'คำขอการลบบัญชีสำเร็จ',
      detail: 'บัญชีจะถูกลบอย่างถาวรหลังจาก 90 วัน',
      scheduledDate: deleteAt.toISOString()
    });

  } catch (err) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์' });
  }
});

module.exports = router;