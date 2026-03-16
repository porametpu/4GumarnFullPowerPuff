const express = require('express');
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const vehicleRoutes = require('./vehicle.routes');
const routeRoutes   = require('./route.routes');
const driverVerifRoutes = require('./driverVerification.routes');
const bookingRoutes = require('./booking.routes');
const notificationRoutes = require('./notification.routes')
const mapRoutes = require('./maps.routes')
const chatRoutes = require('./chat.routes');
<<<<<<< HEAD
const investigationRoutes = require("./investigation.routes");
=======
const investigationRoutes = require('./investigation.routes');
>>>>>>> porametpu

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/vehicles', vehicleRoutes);
router.use('/routes', routeRoutes);
router.use('/driver-verifications', driverVerifRoutes);
router.use('/bookings', bookingRoutes);
router.use('/notifications', notificationRoutes);
router.use('/maps', mapRoutes);
router.use('/chats', chatRoutes);
<<<<<<< HEAD
router.use(investigationRoutes);
=======
router.use('/investigations', investigationRoutes);
>>>>>>> porametpu

module.exports = router;
