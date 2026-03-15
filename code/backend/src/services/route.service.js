const prisma = require('../utils/prisma');
const { Prisma } = require('@prisma/client');
const ApiError = require('../utils/ApiError');
const { RouteStatus, BookingStatus } = require('@prisma/client');
const { checkAndApplyDriverSuspension } = require('./penalty.service');



const toNum = (v) => (typeof v === 'string' ? Number(v) : v);

const pickLatLng = (loc) => {
  if (!loc || typeof loc !== 'object') return null;
  const lat = toNum(loc.lat ?? loc.latitude);
  const lng = toNum(loc.lng ?? loc.lon ?? loc.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { lat, lng };
};

const haversineKm = (lat1, lng1, lat2, lng2) => {
  const R = 6371; // Earth radius in km
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

const isSameLocalDay = (a, b = new Date()) => {
  const d1 = new Date(a);
  const d2 = new Date(b);
  return (
    d1.getFullYear() === d2.getFullYear() &&
    d1.getMonth() === d2.getMonth() &&
    d1.getDate() === d2.getDate()
  );
};

const DRIVER_NEAR_ALERT_COOLDOWN_MINUTES = 1.5;
const DRIVER_NEAR_ALERT_COOLDOWN_MS = DRIVER_NEAR_ALERT_COOLDOWN_MINUTES * 60 * 1000;

/* notify nearby passengers */
const notifyNearbyPassengers = async ({ routeId, driverId, driverLat, driverLng, radiusKm = 5, bookingId }) => {
  const route = await prisma.route.findUnique({
    where: { id: routeId },
    include: {
      booking: {
        where: {
          status: BookingStatus.CONFIRMED,
          ...(bookingId ? { id: bookingId } : {})
        },
        select: {
          id: true,
          passengerId: true,
          pickupLocation: true,
        },
      },
    },
  });

  if (!route) throw new ApiError(404, 'Route not found');
  if (route.driverId !== driverId) throw new ApiError(403, 'Forbidden');
  if (!isSameLocalDay(route.departureTime)) {
    throw new ApiError(400, 'สามารถแจ้งใกล้ถึงได้เฉพาะวันเดินทางเท่านั้น');
  }

  let sentCount = 0;
  let skippedCount = 0;
  const details = [];

  await prisma.$transaction(async (tx) => {
    for (const b of route.booking) {
      const pickup = pickLatLng(b.pickupLocation);
      if (!pickup) {
        skippedCount += 1;
        details.push({ bookingId: b.id, result: 'SKIP', reason: 'pickupLocation invalid' });
        continue;
      }

      const distanceKm = haversineKm(driverLat, driverLng, pickup.lat, pickup.lng);

      if (distanceKm > radiusKm) {
        skippedCount += 1;
        details.push({ bookingId: b.id, result: 'SKIP', reason: 'out_of_radius', distanceKm: Number(distanceKm.toFixed(2)) });
        continue;
      }

      const roundedDistanceKm = Number(distanceKm.toFixed(2));
      const now = new Date();

      const previousAlert = await tx.driverNearAlert.findUnique({
        where: { routeId_bookingId: { routeId, bookingId: b.id } },
      });

      if (previousAlert) {
        const elapsedMs = now.getTime() - new Date(previousAlert.createdAt).getTime();
        if (elapsedMs < DRIVER_NEAR_ALERT_COOLDOWN_MS) {
          skippedCount += 1;
          details.push({
            bookingId: b.id,
            result: 'SKIP',
            reason: 'cooldown_active',
            retryAfterSeconds: Math.ceil((DRIVER_NEAR_ALERT_COOLDOWN_MS - elapsedMs) / 1000),
          });
          continue;
        }

        await tx.driverNearAlert.update({
          where: { id: previousAlert.id },
          data: {
            driverId,
            passengerId: b.passengerId,
            driverLat,
            driverLng,
            distanceKm: roundedDistanceKm,
            createdAt: now,
          },
        });
      } else {
        await tx.driverNearAlert.create({
          data: {
            routeId,
            bookingId: b.id,
            driverId,
            passengerId: b.passengerId,
            driverLat,
            driverLng,
            distanceKm: roundedDistanceKm,
            createdAt: now,
          },
        });
      }

      await tx.notification.create({
        data: {
          userId: b.passengerId,
          type: 'ROUTE',
          title: 'คนขับใกล้ถึงแล้ว',
          body: `คนขับใกล้ถึงจุดรับของคุณแล้ว ห่างประมาณ ${distanceKm.toFixed(1)} กม.`,
          metadata: {
            kind: 'DRIVER_NEARBY',
            routeId,
            bookingId: b.id,
            distanceKm: roundedDistanceKm,
            driverLat,
            driverLng,
            radiusKm,
          },
        },
      });

      // Send Chat Message
      const chatRoom = await tx.chatRoom.findFirst({
        where: { bookingId: b.id }
      });

      if (chatRoom) {
        await tx.message.create({
          data: {
            chatRoomId: chatRoom.id,
            senderId: driverId,
            content: `🚨 คนขับใกล้ถึงจุดรับของคุณแล้ว (ห่างประมาณ ${distanceKm.toFixed(1)} กม.)`,
            type: 'TEXT'
          }
        });
      }

      sentCount += 1;
      details.push({
        bookingId: b.id,
        passengerId: b.passengerId,
        result: 'SENT',
        distanceKm: roundedDistanceKm
      });
    }
  });

  return {
    routeId,
    radiusKm,
    cooldownMinutes: DRIVER_NEAR_ALERT_COOLDOWN_MINUTES,
    sentCount,
    skippedCount,
    totalConfirmed: route.booking.length,
    details,
  };
};






const baseInclude = {
  driver: {
    select: {
      id: true,
      firstName: true,
      lastName: true,
      gender: true,
      profilePicture: true,
      isVerified: true
    }
  },
  vehicle: {
    select: {
      vehicleModel: true,
      vehicleType: true,
      photos: true,
      amenities: true
    }
  }
};

const getAllRoutes = async () => {
  return prisma.route.findMany({
    include: baseInclude,
    orderBy: { createdAt: 'desc' }
  });
};

const searchRoutes = async (opts) => {
  const { startNearLat, startNearLng, endNearLat, endNearLng } = opts || {};
  const hasStart = typeof startNearLat === 'number' && typeof startNearLng === 'number';
  const hasEnd = typeof endNearLat === 'number' && typeof endNearLng === 'number';

  if (hasStart || hasEnd) {
    return searchRoutesByEndpointProximity(opts);
  }

  const {
    page = 1,
    limit = 20,
    q,
    status,
    driverId,
    vehicleId,
    dateFrom,
    dateTo,
    sortBy = 'createdAt',
    sortOrder = 'desc',

    seatsRequired,
  } = opts || {};

  const where = {
    ...(status && { status }),
    ...(driverId && { driverId }),
    ...(vehicleId && { vehicleId }),
    ...(dateFrom || dateTo ? {
      departureTime: {
        ...(dateFrom ? { gte: new Date(dateFrom) } : {}),
        ...(dateTo ? { lte: new Date(dateTo) } : {}),
      }
    } : {}),
    ...(typeof seatsRequired === 'number' ? { availableSeats: seatsRequired } : {}),
    ...(q ? {
      OR: [
        { routeSummary: { contains: q, mode: 'insensitive' } },
        { conditions: { contains: q, mode: 'insensitive' } },
        // ค้นในความสัมพันธ์ด้วย (ชื่อคนขับ / รุ่นรถ / ประเภท / ทะเบียน ถ้ามีใน model อื่น)
        {
          driver: {
            is: {
              OR: [
                { firstName: { contains: q, mode: 'insensitive' } },
                { lastName: { contains: q, mode: 'insensitive' } },
              ]
            }
          }
        },
        {
          vehicle: {
            is: {
              OR: [
                { vehicleModel: { contains: q, mode: 'insensitive' } },
                { vehicleType: { contains: q, mode: 'insensitive' } },
                // ถ้าต้องการค้นทะเบียน ให้ดึงจาก vehicle.licensePlate (มี @unique)
                { licensePlate: { contains: q, mode: 'insensitive' } },
              ]
            }
          }
        },
      ]
    } : {}),
  };

  const skip = (page - 1) * limit;
  const take = limit;

  const [total, data] = await prisma.$transaction([
    prisma.route.count({ where }),
    prisma.route.findMany({
      where,
      include: baseInclude,
      orderBy: { [sortBy]: sortOrder },
      skip, take,
    })
  ]);

  return {
    data,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    }
  };
};

const searchRoutesByEndpointProximity = async (opts = {}) => {

  const {
    page = 1, limit = 20,
    startNearLat, startNearLng,
    endNearLat, endNearLng,
    radiusMeters = 500,
    sortBy = 'createdAt',
    sortOrder = 'desc',
  } = opts;

  const offset = (page - 1) * limit;

  // ป้องกัน SQLi: อนุญาตเฉพาะฟิลด์ที่กำหนด
  const allowedSortFields = ['createdAt', 'departureTime', 'pricePerSeat', 'availableSeats'];
  const sortField = allowedSortFields.includes(sortBy) ? sortBy : 'createdAt';
  const sortDir = (sortOrder || '').toLowerCase() === 'asc' ? 'asc' : 'desc';

  // แปลง undefined -> null เพื่อให้ bind เป็น NULL (ใช้ใน CTE params)
  const sLat = startNearLat ?? null;
  const sLng = startNearLng ?? null;
  const eLat = endNearLat ?? null;
  const eLng = endNearLng ?? null;

  // เลือกเฉพาะ id ก่อน เพื่อทำ include รอบสอง
  // ใช้ Haversine (เป็นเมตร) กับ lat/lng ที่ดึงจาก JSON
  const idsRows = await prisma.$queryRaw(
    Prisma.sql`
      WITH params AS (
        SELECT
          ${sLat}::float AS s_lat,
          ${sLng}::float AS s_lng,
          ${eLat}::float AS e_lat,
          ${eLng}::float AS e_lng,
          ${radiusMeters}::int AS rad
      )
      SELECT r.id
      FROM "Route" r, params p
      WHERE
        -- start within radius (ถ้ามีค่า)
        (
          p.s_lat IS NULL OR p.s_lng IS NULL OR
          6371000 * acos(least(1,
            cos(radians(p.s_lat)) * cos(radians((r."startLocation"->>'lat')::float)) *
            cos(radians((r."startLocation"->>'lng')::float) - radians(p.s_lng)) +
            sin(radians(p.s_lat)) * sin(radians((r."startLocation"->>'lat')::float))
          )) <= p.rad
        )
        AND
        -- end within radius (ถ้ามีค่า)
        (
          p.e_lat IS NULL OR p.e_lng IS NULL OR
          6371000 * acos(least(1,
            cos(radians(p.e_lat)) * cos(radians((r."endLocation"->>'lat')::float)) *
            cos(radians((r."endLocation"->>'lng')::float) - radians(p.e_lng)) +
            sin(radians(p.e_lat)) * sin(radians((r."endLocation"->>'lat')::float))
          )) <= p.rad
        )
      ORDER BY ${Prisma.raw(`r."${sortField}"`)} ${Prisma.raw(sortDir)}
      OFFSET ${offset} LIMIT ${limit};
    `
  );

  const idList = idsRows.map(r => r.id);

  const totalRows = await prisma.$queryRaw(
    Prisma.sql`
      WITH params AS (
        SELECT
          ${sLat}::float AS s_lat,
          ${sLng}::float AS s_lng,
          ${eLat}::float AS e_lat,
          ${eLng}::float AS e_lng,
          ${radiusMeters}::int AS rad
      )
      SELECT count(*)::int AS cnt
      FROM "Route" r, params p
      WHERE
        (p.s_lat IS NULL OR p.s_lng IS NULL OR
          6371000 * acos(least(1,
            cos(radians(p.s_lat)) * cos(radians((r."startLocation"->>'lat')::float)) *
            cos(radians((r."startLocation"->>'lng')::float) - radians(p.s_lng)) +
            sin(radians(p.s_lat)) * sin(radians((r."startLocation"->>'lat')::float))
          )) <= p.rad)
        AND
        (p.e_lat IS NULL OR p.e_lng IS NULL OR
          6371000 * acos(least(1,
            cos(radians(p.e_lat)) * cos(radians((r."endLocation"->>'lat')::float)) *
            cos(radians((r."endLocation"->>'lng')::float) - radians(p.e_lng)) +
            sin(radians(p.e_lat)) * sin(radians((r."endLocation"->>'lat')::float))
          )) <= p.rad);
    `
  );
  const total = totalRows?.[0]?.cnt || 0;

  // ดึงรายละเอียดพร้อม include ตาม id ที่คัดแล้ว
  const data = idList.length
    ? await prisma.route.findMany({
      where: { id: { in: idList } },
      include: {
        driver: { select: { id: true, firstName: true, lastName: true, gender: true, profilePicture: true, isVerified: true } },
        vehicle: { select: { vehicleModel: true, vehicleType: true, photos: true, amenities: true } },
      },
    })
    : [];

  // รักษา order ให้ตรงกับ idList
  const orderMap = new Map(idList.map((id, i) => [id, i]));
  data.sort((a, b) => orderMap.get(a.id) - orderMap.get(b.id));

  return {
    data,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
};

const getRouteById = async (id) => {
  return prisma.route.findUnique({
    where: { id },
    include: {
      booking: {
        include: {
          passenger: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              profilePicture: true
            }
          }
        }
      },
      ...baseInclude
    },
  });
};

const getMyRoutes = async (driverId) => {
  return prisma.route.findMany({
    where: {
      driverId
    },
    include: {

      booking: {
        include: {
          passenger: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              profilePicture: true,
              isVerified: true,
              email: true
            }
          }
        }
      },
      ...baseInclude
    },

    orderBy: { createdAt: 'desc' },
  })
}

const createRoute = async (data) => {
  return prisma.route.create({ data });
};

const updateRoute = async (id, data) => {
  return prisma.route.update({
    where: { id },
    data
  });
};

const deleteRoute = async (id) => {
  await prisma.route.delete({
    where: { id }
  });
  return { id }
};

const cancelRoute = async (routeId, driverId, opts = {}) => {
  const { reason } = opts;

  const route = await prisma.route.findUnique({
    where: { id: routeId },
    include: {
      driver: { select: { id: true } },
      booking: {
        where: { status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] } },
        include: { passenger: { select: { id: true } } }
      }
    }
  });
  if (!route) throw new ApiError(404, 'Route not found');
  if (route.driverId !== driverId) throw new ApiError(403, 'Forbidden');
  if (![RouteStatus.AVAILABLE, RouteStatus.FULL].includes(route.status)) {
    throw new ApiError(400, 'Route cannot be cancelled at this stage');
  }

  const now = new Date();
  const affected = route.booking || [];
  const hasConfirmed = affected.some(b => b.status === BookingStatus.CONFIRMED);

  await prisma.$transaction(async (tx) => {
    //ยกเลิก Route
    await tx.route.update({
      where: { id: routeId },
      data: {
        status: RouteStatus.CANCELLED,
        cancelledBy: 'DRIVER',
        cancelledAt: now
      }
    });

    if (affected.length) {
      //ยกเลิก Booking ที่ค้างทั้งหมด
      await tx.booking.updateMany({
        where: { routeId, status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] } },
        data: {
          status: BookingStatus.CANCELLED,
          cancelledBy: 'DRIVER',
          cancelledAt: now,
          cancelReason: reason
        }
      });

      const notiData = affected.map(b => ({
        userId: b.passengerId,
        type: 'BOOKING',
        title: 'การจองถูกยกเลิกเนื่องจากคนขับยกเลิกเส้นทาง',
        body: 'ขออภัย เส้นทางที่คุณจองถูกยกเลิกโดยคนขับ',
        metadata: { routeId, bookingId: b.id, by: 'DRIVER', reason }
      }));
      // ทำ bulk insert ทีละก้อน
      for (const n of notiData) {
        await tx.notification.create({ data: n });
      }
    }
  });

  //บทลงโทษฝั่งไดรเวอร์
  await checkAndApplyDriverSuspension(driverId, { confirmedOnly: hasConfirmed });

  return { id: routeId, status: RouteStatus.CANCELLED, cancelledBy: 'DRIVER', cancelledAt: now };
};

module.exports = {
  getAllRoutes,
  searchRoutes,
  getRouteById,
  getMyRoutes,
  createRoute,
  updateRoute,
  deleteRoute,
  cancelRoute,
  notifyNearbyPassengers,
};
