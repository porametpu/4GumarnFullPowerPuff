const asyncHandler = require("express-async-handler");
const investigationService = require("../services/investigation.service");
const path = require("path");

const adminListInvestigations = asyncHandler(async (req, res) => {

  const list = await investigationService.getInvestigations();

  res.status(200).json({
    success: true,
    message: "Investigations retrieved successfully",
    data: list,
  });

});

const createInvestigation = asyncHandler(async (req, res) => {

  const userId = req.user.sub;

  const payload = {
    ...req.body,
    requestDate: new Date(req.body.requestDate),
    fromDate: new Date(req.body.fromDate),
    toDate: new Date(req.body.toDate),
    createdById: userId,
  };

  const created = await investigationService.createInvestigation(payload);

  res.status(201).json({
    success: true,
    message: "Investigation created",
    data: created,
  });

});

const getInvestigationById = asyncHandler(async (req, res) => {

  const data = await investigationService.getInvestigationById(req.params.id);

  if (!data) {
    return res.status(404).json({
      success: false,
      message: "Investigation not found"
    });
  }

  res.status(200).json({
    success: true,
    data
  });

});

const exportChatLog = asyncHandler(async (req, res) => {

  const investigationId = req.params.id;

  const messages =
    await investigationService.exportInvestigation(investigationId);

  if (!messages || messages.length === 0) {
    return res.status(404).json({
      success: false,
      message: "No chat logs found"
    });
  }

  const doc = new PDFDocument({ margin: 50 });

  res.setHeader(
    "Content-Disposition",
    `attachment; filename=chatlog-${investigationId}.pdf`
  );

  res.setHeader("Content-Type", "application/pdf");

  doc.pipe(res);

  // ===== โหลดฟอนต์ไทย =====
  const fontRegular = path.join(
    __dirname,
    "../fonts/NotoSansThai-Regular.ttf"
  );

  const fontBold = path.join(
    __dirname,
    "../fonts/NotoSansThai-Bold.ttf"
  );

  doc.registerFont("thai", fontRegular);
  doc.registerFont("thai-bold", fontBold);

  // ===== HEADER =====

  doc
    .font("thai-bold")
    .fontSize(20)
    .text("รายงานหลักฐานบทสนทนา (Chat Log Evidence)", {
      align: "center"
    });

  doc.moveDown();

  doc
    .font("thai")
    .fontSize(12)
    .text(`เลขคำร้อง: ${investigationId}`);

  doc.text(`วันที่สร้างรายงาน: ${new Date().toLocaleString("th-TH")}`);

  doc.moveDown();

  doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();

  doc.moveDown();

  // ===== TABLE HEADER =====

  doc.font("thai-bold");

  doc
    .text("ลำดับ", 50)
    .text("เวลา", 90)
    .text("ผู้ส่ง", 220)
    .text("ข้อความ", 350);

  doc.moveDown();

  doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();

  doc.moveDown();

  doc.font("thai");

  // ===== CHAT DATA =====

  const participants = new Set();

  messages.forEach((m, index) => {

    const time = new Date(m.createdAt).toLocaleString("th-TH");

    const sender =
      m.sender?.username ||
      `${m.sender?.firstName || ""} ${m.sender?.lastName || ""}` ||
      m.senderId;

    participants.add(sender);

    doc
      .fontSize(11)
      .text(index + 1, 50)
      .text(time, 90)
      .text(sender, 220)
      .text(m.content || "-", 350);

    doc.moveDown();

  });

  doc.moveDown();

  // ===== SUMMARY =====

  doc.moveTo(50, doc.y).lineTo(550, doc.y).stroke();

  doc.moveDown();

  doc
    .font("thai-bold")
    .fontSize(14)
    .text("สรุปข้อมูลการสนทนา");

  doc.moveDown();

  doc
    .font("thai")
    .fontSize(12)
    .text(`จำนวนข้อความทั้งหมด: ${messages.length} ข้อความ`);

  doc.moveDown();

  doc.text("ผู้ที่เข้าร่วมสนทนา:");

  participants.forEach(user => {
    doc.text(`- ${user}`);
  });

  doc.moveDown();

  doc.text(
    "เอกสารฉบับนี้ถูกสร้างโดยระบบอัตโนมัติเพื่อใช้เป็นหลักฐานในการตรวจสอบข้อมูลการสนทนา"
  );

  doc.end();

});

module.exports = {
  adminListInvestigations,
  createInvestigation,
  getInvestigationById,
  exportChatLog
};