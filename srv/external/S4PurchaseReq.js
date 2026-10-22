const cds = require('@sap/cds');

// FAKE S/4: gives every new PR the next number, like an S/4 number range
module.exports = class S4PurchaseReq extends cds.ApplicationService {
  init() {
    const { PurchaseRequisitions } = this.entities;
    let nextNumber = 1000045822;

    this.before('CREATE', PurchaseRequisitions, (req) => {
      req.data.PurchaseRequisition = String(nextNumber++);
    });

    return super.init();
  }
};