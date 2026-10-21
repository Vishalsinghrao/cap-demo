const cds = require('@sap/cds');

module.exports = class MaterialRequestService extends cds.ApplicationService {
  init() {
    const { MaterialRequests } = this.entities;

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

    // APPROVE: Submitted → Approved
    this.on('approveRequest', MaterialRequests, async (req) => {
      const request = await SELECT.one.from(req.subject).columns('status');
      if (request.status !== 'Submitted') {
        return req.reject(400, `Only Submitted requests can be approved. Current status: ${request.status}`);
      }
      await UPDATE(req.subject).with({ status: 'Approved', approverNote: req.data.note });
      req.info('Request approved');
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

    return super.init();
  }
};