const socketIo = require('socket.io');

let io;

const init = (server) => {
    io = socketIo(server, {
        cors: {
            origin: ['http://localhost:3001', 'https://amazing-crisp-9bcb1a.netlify.app'],
            methods: ['GET', 'POST'],
            credentials: true
        }
    });

    io.on('connection', (socket) => {
        console.log(`[Socket.io] New client connected: ${socket.id}`);

        socket.on('join-room', (roomId) => {
            socket.join(roomId);
            console.log(`[Socket.io] Socket ${socket.id} joined room: ${roomId}`);
        });

        socket.on('leave-room', (roomId) => {
            socket.leave(roomId);
            console.log(`[Socket.io] Socket ${socket.id} left room: ${roomId}`);
        });

        socket.on('join-user', (userId) => {
            socket.join(`user-${userId}`);
            console.log(`[Socket.io] Socket ${socket.id} joined user room: user-${userId}`);
        });

        socket.on('disconnect', () => {
            console.log(`[Socket.io] Client disconnected: ${socket.id}`);
        });
    });

    return io;
};

const getIO = () => {
    if (!io) {
        throw new Error('[Socket.io] Not initialized!');
    }
    return io;
};

module.exports = {
    init,
    getIO
};
