const asyncHandler = require("express-async-handler");
const chatService = require("../services/chat.service");
const prisma = require("../utils/prisma");

const getChatRoom = asyncHandler(async (req, res) => {
    const { bookingId } = req.params;
    const userId = req.user.sub;
    const room = await chatService.getChatRoom(bookingId, userId);
    res.status(200).json({ success: true, data: room });
});

const getMessages = asyncHandler(async (req, res) => {
    const { roomId } = req.params;
    const userId = req.user.sub;
    const messages = await chatService.getMessages(roomId, userId);
    res.status(200).json({ success: true, data: messages });
});

const sendMessage = asyncHandler(async (req, res) => {
    try {
        const { roomId } = req.params;
        const { content, type } = req.body;
        const userId = req.user.sub;
        console.log(`[sendMessage] Room: ${roomId}, User: ${userId}, Content: ${content}, Type: ${type}`);

        const message = await chatService.sendMessage(roomId, userId, content, type);
        const io = req.app.get('io');
        io.to(roomId).emit('new-message', message);
        const room = await prisma.chatRoom.findUnique({
            where: { id: roomId },
            include: { participants: true }
        });

        if (room) {
            room.participants.forEach(p => {
                io.to(`user_${p.userId}`).emit('message-notification', {
                    roomId: roomId,
                    message: message
                });
            });
        }

        res.status(201).json({ success: true, data: message });
    } catch (error) {
        console.error('[sendMessage Error]', error);
        throw error;
    }
});

const sendImageMessage = asyncHandler(async (req, res) => {
    const { roomId } = req.params;
    const userId = req.user.sub;

    if (!req.file) {
        res.status(400);
        throw new Error('Image file is required');
    }

    const message = await chatService.sendImageMessage(roomId, userId, req.file);
    const io = req.app.get('io');
    io.to(roomId).emit('new-message', message);
    const room = await prisma.chatRoom.findUnique({
        where: { id: roomId },
        include: { participants: true }
    });

    if (room) {
        room.participants.forEach(p => {
            io.to(`user_${p.userId}`).emit('message-notification', {
                roomId: roomId,
                message: message
            });
        });
    }

    res.status(201).json({ success: true, data: message });
});

const getMyChatRooms = asyncHandler(async (req, res) => {
    const userId = req.user.sub;
    const rooms = await chatService.getMyChatRooms(userId);
    res.status(200).json({ success: true, data: rooms });
});

const markAsRead = asyncHandler(async (req, res) => {
    const { roomId } = req.params;
    const userId = req.user.sub;
    await chatService.markAsRead(roomId, userId);
    res.status(200).json({ success: true, message: 'Messages marked as read' });
});

module.exports = {
    getChatRoom,
    getMessages,
    sendMessage,
    sendImageMessage,
    getMyChatRooms,
    markAsRead
};
