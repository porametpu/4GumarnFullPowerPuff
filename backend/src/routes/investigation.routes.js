const express = require("express");
const router = express.Router();

const investigationController = require("../controllers/investigation.controller");
const { protect } = require("../middlewares/auth");

// admin list investigations
router.get(
  "/admin/investigations",
  protect,
  investigationController.adminListInvestigations
);

// create investigation
router.post(
  "/admin/investigations",
  protect,
  investigationController.createInvestigation
);

// ⭐ export chat log
router.get(
  "/admin/investigations/:id/export",
  protect,
  investigationController.exportChatLog
);

// get investigation by id
router.get(
  "/admin/investigations/:id",
  protect,
  investigationController.getInvestigationById
);

module.exports = router;