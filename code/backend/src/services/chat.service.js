const prisma = require('../utils/prisma');
const ApiError = require('../utils/ApiError');
const { uploadToCloudinary } = require('../utils/cloudinary');

const getChatRoom = async (bookingId, userId) => {
    let room = await prisma.chatRoom.findUnique({
        where: { bookingId },
        include: {
            participants: true
        }
    });

    if (!room) {
        const booking = await prisma.booking.findUnique({
            where: { id: bookingId },
            include: { route: true, passenger: true }
        });

        if (booking && booking.status === 'CONFIRMED' && (booking.passengerId === userId || booking.route.driverId === userId)) {
            room = await prisma.chatRoom.create({
                data: {
                    bookingId: booking.id,
                    participants: {
                        create: [
                            {
                                userId: booking.route.driverId,
                                displayName: "คนขับรถ",
                            },
                            {
                                userId: booking.passengerId,
                                displayName: `${booking.passenger.firstName || ''} ${booking.passenger.lastName ? booking.passenger.lastName.charAt(0) + '.' : ''}`.trim(),
                            }
                        ]
                    }
                },
                include: { participants: true }
            });
        }
    }

    if (!room) throw new ApiError(404, 'Chat room not found');

    const isParticipant = room.participants.some(p => p.userId === userId);
    if (!isParticipant) {
        throw new ApiError(403, 'You are not a participant in this chat room');
    }

    return room;
};

const getMessages = async (roomId, userId) => {
    const room = await prisma.chatRoom.findUnique({
        where: { id: roomId },
        include: {
            participants: true
        }
    });

    if (!room) throw new ApiError(404, 'Chat room not found');
    const isParticipant = room.participants.some(p => p.userId === userId);
    if (!isParticipant) {
        throw new ApiError(403, 'You are not a participant in this chat room');
    }

    const messages = await prisma.message.findMany({
        where: { chatRoomId: roomId },
        orderBy: { createdAt: 'asc' },
        include: {
            sender: {
                select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    profilePicture: true
                }
            }
        }
    });
    await prisma.message.updateMany({
        where: {
            chatRoomId: roomId,
            senderId: { not: userId },
            isRead: false
        },
        data: { isRead: true }
    });

    return messages.map(msg => {
        const participant = room.participants.find(p => p.userId === msg.senderId);
        return {
            ...msg,
            senderDisplayName: participant ? participant.displayName : 'Unknown',
            senderAvatar: msg.sender?.profilePicture || null,
            isMine: msg.senderId === userId
        };
    });
};

const getMyChatRooms = async (userId) => {
    const participants = await prisma.chatParticipant.findMany({
        where: { userId },
        include: {
            chatRoom: {
                include: {
                    participants: true,
                    messages: {
                        orderBy: { createdAt: 'desc' },
                        take: 1
                    },
                    booking: {
                        include: {
                            route: true
                        }
                    }
                }
            }
        }
    });

    const rooms = await Promise.all(participants.map(async (p) => {
        const room = p.chatRoom;
        const otherParticipant = room.participants.find(part => part.userId !== userId);

        const unreadCount = await prisma.message.count({
            where: {
                chatRoomId: room.id,
                senderId: { not: userId },
                isRead: false
            }
        });

        return {
            id: room.id,
            bookingId: room.bookingId,
            otherParticipantName: otherParticipant ? otherParticipant.displayName : 'Unknown',
            lastMessage: room.messages[0] || null,
            unreadCount,
            booking: room.booking
        };
    }));
    return rooms.sort((a, b) => {
        const dateA = a.lastMessage ? new Date(a.lastMessage.createdAt) : new Date(0);
        const dateB = b.lastMessage ? new Date(b.lastMessage.createdAt) : new Date(0);
        return dateB - dateA;
    });
};

const markAsRead = async (roomId, userId) => {
    return await prisma.message.updateMany({
        where: {
            chatRoomId: roomId,
            senderId: { not: userId },
            isRead: false
        },
        data: { isRead: true }
    });
};

const sendMessage = async (roomId, userId, content, type = 'TEXT') => {
    const room = await prisma.chatRoom.findUnique({
        where: { id: roomId },
        include: {
            participants: true
        }
    });

    if (!room) throw new ApiError(404, 'Chat room not found');
    const isParticipant = room.participants.some(p => p.userId === userId);
    if (!isParticipant) {
        throw new ApiError(403, 'You are not a participant in this chat room');
    }

    const message = await prisma.message.create({
        data: {
            chatRoomId: roomId,
            senderId: userId,
            content,
            type
        }
    });

    const participant = room.participants.find(p => p.userId === userId);

    return {
        ...message,
        senderDisplayName: participant ? participant.displayName : 'Unknown',
        isMine: true
    };
};

const sendImageMessage = async (roomId, userId, file) => {
    const room = await prisma.chatRoom.findUnique({
        where: { id: roomId },
        include: {
            participants: true
        }
    });

    if (!room) throw new ApiError(404, 'Chat room not found');
    const isParticipant = room.participants.some(p => p.userId === userId);
    if (!isParticipant) {
        throw new ApiError(403, 'You are not a participant in this chat room');
    }
    const result = await uploadToCloudinary(file.buffer, 'chat_images');

    const message = await prisma.message.create({
        data: {
            chatRoomId: roomId,
            senderId: userId,
            content: result.url,
            type: 'IMAGE'
        }
    });

    const participant = room.participants.find(p => p.userId === userId);
    const user = await prisma.user.findUnique({ where: { id: userId } });

    return {
        ...message,
        senderDisplayName: participant ? participant.displayName : 'Unknown',
        senderAvatar: user?.profilePicture || null,
        isMine: true
    };
};

module.exports = {
    getChatRoom,
    getMessages,
    sendMessage,
    sendImageMessage,
    getMyChatRooms,
    markAsRead
};
