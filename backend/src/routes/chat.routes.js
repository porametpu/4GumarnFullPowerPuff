const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const { protect } = require('../middlewares/auth');
const upload = require('../middlewares/upload.middleware');

router.use(protect);

router.get('/booking/:bookingId', chatController.getChatRoom);
router.get('/history', chatController.getMyChatRooms);
router.get('/:roomId/messages', chatController.getMessages);
router.post('/:roomId/messages', chatController.sendMessage);
router.post('/:roomId/messages/image', upload.single('image'), chatController.sendImageMessage);
router.post('/:roomId/read', chatController.markAsRead);

module.exports = router;
