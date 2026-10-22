// Simplified model of S/4HANA's Purchase Requisition API
@impl: 'srv/external/S4PurchaseReq.js'
service S4PurchaseReq {
  entity PurchaseRequisitions {
    key PurchaseRequisition : String(10);
        Description         : String(40);
        Plant               : String(4);
        RequestReference    : String(20);
        CreatedAt           : Timestamp @cds.on.insert: $now;
        items               : Composition of many {
          key ItemNo   : String(5);
              Material : String(18);
              Quantity : Decimal(13,3);
              Unit     : String(3);
        };
  }
}