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

    return super.init();
  }
};