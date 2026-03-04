const asyncHandler = require("express-async-handler");
const PDFDocument = require("pdfkit");
const investigationService = require("../services/investigation.service");


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

  res.status(200).json(data);

});


const exportChatLog = asyncHandler(async (req, res) => {

  const messages =
    await investigationService.exportInvestigation(req.params.id);

  const doc = new PDFDocument();

  res.setHeader(
    "Content-Disposition",
    "attachment; filename=chatlog.pdf"
  );

  res.setHeader("Content-Type", "application/pdf");

  doc.pipe(res);

  doc.fontSize(18).text("Chat Log Evidence", { align: "center" });

  doc.moveDown();

  messages.forEach(m => {

    doc.text(
      `${new Date(m.createdAt).toLocaleString()} | ${m.sender?.username || m.senderId}`
    );

    doc.text(m.content);

    doc.moveDown();

  });

  doc.end();

});

module.exports = {
  adminListInvestigations,
  createInvestigation,
  getInvestigationById,
  exportChatLog
};