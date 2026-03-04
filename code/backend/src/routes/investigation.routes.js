const express = require("express");
const router = express.Router();

const investigationController = require("../controllers/investigation.controller");
const { protect } = require("../middlewares/auth");

router.get(
  "/admin/investigations",
  protect,
  investigationController.adminListInvestigations
);

router.post(
  "/admin/investigations",
  protect,
  investigationController.createInvestigation
);

router.get(
  "/:id",
  investigationController.getInvestigationById
);

router.get(
  "/:id/export",
  investigationController.exportChatLog
)

module.exports = router;