const socketIo = require('socket.io');

let io;

const defaultOrigins = ['http://localhost:3001', 'http://127.0.0.1:3001'];
const envOrigins = (process.env.SOCKET_CORS_ORIGINS || process.env.CORS_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
const allowedOrigins = Array.from(new Set([...defaultOrigins, ...envOrigins]));

const init = (server) => {
    io = socketIo(server, {
        cors: {
            origin: (origin, callback) => {
                if (!origin) return callback(null, true);
                if (allowedOrigins.includes(origin)) return callback(null, true);
                return callback(new Error(`Socket CORS blocked for origin: ${origin}`));
            },
            methods: ['GET', 'POST'],
            credentials: true
        }
    });

    console.log('[Socket.io] Allowed origins:', allowedOrigins);

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
