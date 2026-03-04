const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

const getInvestigations = async () => {
    return prisma.investigationRequest.findMany({
        orderBy: { createdAt: "desc" },
        include: {
            booking: true,
            createdBy: true,
        },
    });
};

const createInvestigation = async (data) => {
    const requestNumber = `INV-${Date.now()}`;

    return prisma.investigationRequest.create({
        data: {
            requestNumber,

            authorityName: data.authorityName,
            officerName: data.officerName,
            officerPosition: data.officerPosition,

            contactEmail: data.contactEmail,
            contactPhone: data.contactPhone,

            requestDate: new Date(data.requestDate),

            bookingId: data.bookingId,

            fromDate: new Date(data.startDate),
            toDate: new Date(data.endDate),

            reason: data.reason,

            officialDocumentUrl: data.officialDocumentUrl,
            officialDocumentName: data.officialDocumentName,

            createdById: data.createdById,
        },
    });
};

const exportInvestigation = async (investigationId) => {
  const investigation = await prisma.investigationRequest.findUnique({
    where: { id: investigationId },
    include: {
      booking: {
        include: {
          passenger: true,
          route: {
            include: {
              driver: true,
            },
          },
          chatRoom: {
            include: {
              messages: {
                include: {
                  sender: true,
                },
                orderBy: {
                  createdAt: "asc",
                },
              },
            },
          },
        },
      },
    },
  });

  if (!investigation) return null;

  return investigation.booking.chatRoom?.messages || [];
};

const getInvestigationById = async (id) => {

  return prisma.investigationRequest.findUnique({
    where: { id },

    include: {
      booking: {
        include: {
          chatRoom: {
            include: {
              messages: {
                include: {
                  sender: true
                },
                orderBy: {
                  createdAt: "asc"
                }
              }
            }
          }
        }
      },
      createdBy: true
    }
  })
}

module.exports = {
  getInvestigations,
  createInvestigation,
  exportInvestigation,
  getInvestigationById
}