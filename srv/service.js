const cds = require('@sap/cds');

module.exports = class MaterialRequestService extends cds.ApplicationService {
  init() {
    const { MaterialRequests, RequestItems } = this.entities;

    // Before a new request is saved, give it the next request number
    this.before('CREATE', MaterialRequests, async (req) => {
      const result = await SELECT.one
        .from(MaterialRequests)
        .columns('max(requestNo) as maxNo');

      const lastNumber = result?.maxNo ? parseInt(result.maxNo.split('-')[1]) : 1000;
      req.data.requestNo = `MR-${lastNumber + 1}`;
    });

        // Validate before saving (new or edited requests)
    this.before(['CREATE', 'UPDATE'], MaterialRequests, (req) => {
      const { neededBy, items } = req.data;

      // Rule 1: Needed By cannot be in the past
      const today = new Date().toISOString().slice(0, 10);
      if (neededBy && neededBy < today) {
        req.error(400, 'Needed By date cannot be in the past', 'neededBy');
      }

      // Rule 2: Every item needs a quantity greater than 0
      for (const item of items || []) {
        if (Number(item.quantity) <= 0) {
          req.error(400, `Quantity must be greater than 0 for material ${item.material_MaterialNo}`);
        }
      }
    });

        // SUBMIT: New → Submitted
    this.on('submitRequest', MaterialRequests, async (req) => {
      const request = await SELECT.one.from(req.subject).columns('status');
      if (request.status !== 'New') {
        return req.reject(400, `Only New requests can be submitted. Current status: ${request.status}`);
      }
      await UPDATE(req.subject).with({ status: 'Submitted' });
      req.info('Request submitted for approval');
    });

    // APPROVE: Submitted → Approved → PR created in S/4
    this.on('approveRequest', MaterialRequests, async (req) => {
      const request = await SELECT.one.from(req.subject).columns('ID', 'requestNo', 'plant', 'status');
      if (request.status !== 'Submitted') {
        return req.reject(400, `Only Submitted requests can be approved. Current status: ${request.status}`);
      }

      // 1. Mark as approved
      await UPDATE(req.subject).with({ status: 'Approved', approverNote: req.data.note });

      // 2. Ask S/4 to create the PR
      try {
        const s4 = await cds.connect.to('S4PurchaseReq');
        const { PurchaseRequisitions } = s4.entities;
        const items = await SELECT.from(RequestItems).where({ request_ID: request.ID });

        await s4.run(INSERT.into(PurchaseRequisitions).entries({
          Description: `Material request ${request.requestNo}`,
          Plant: request.plant,
          RequestReference: request.requestNo,
          items: items.map((item, index) => ({
            ItemNo: String((index + 1) * 10).padStart(5, '0'),
            Material: item.material_MaterialNo,
            Quantity: item.quantity,
            Unit: item.unit
          }))
        }));

        // 3. Read back the PR number S/4 gave us
        const pr = await s4.run(
          SELECT.one.from(PurchaseRequisitions).where({ RequestReference: request.requestNo })
        );

        // 4. Save it on our request
        await UPDATE(req.subject).with({ status: 'PRCreated', prNumber: pr.PurchaseRequisition });
        req.info(`Request approved. Purchase Requisition ${pr.PurchaseRequisition} created in S/4.`);

      } catch (err) {
        req.warn(`Request approved, but PR creation in S/4 failed: ${err.message}`);
      }
    });

    // REJECT: Submitted → Rejected (reason required)
    this.on('rejectRequest', MaterialRequests, async (req) => {
      const request = await SELECT.one.from(req.subject).columns('status');
      if (request.status !== 'Submitted') {
        return req.reject(400, `Only Submitted requests can be rejected. Current status: ${request.status}`);
      }
      if (!req.data.note) {
        return req.reject(400, 'Please give a reason for rejection');
      }
      await UPDATE(req.subject).with({ status: 'Rejected', approverNote: req.data.note });
      req.info('Request rejected');
    });

        // Block editing after submit (server-side safety)
    this.before('EDIT', MaterialRequests, async (req) => {
      const request = await SELECT.one.from(req.subject).columns('status');
      if (request.status !== 'New') {
        return req.reject(400, `A request cannot be changed after it is submitted. Current status: ${request.status}`);
      }
    });

        // Tell the UI what the current user is allowed to do
    this.after('READ', MaterialRequests, (data, req) => {
      const isRequester = req.user.is('Requester');
      const isApprover  = req.user.is('Approver');
      for (const row of Array.isArray(data) ? data : [data]) {
        if (row) {
          row.isRequester = isRequester;
          row.isApprover  = isApprover;
        }
      }
    });

    return super.init();
  }
};