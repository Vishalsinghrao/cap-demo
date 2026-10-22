using { tii.mr as db } from '../db/schema';

service MaterialRequestService {
   @odata.draft.enabled
    entity MaterialRequests as projection on db.MaterialRequests actions {
    action submitRequest();
    action approveRequest( @title: 'Approver Note' note : String(500) );
    action rejectRequest ( @title: 'Reason for Rejection' note : String(500) );
  };
  entity RequestItems as projection on db.RequestItems;
  @readonly
  entity Materials as projection on db.Materials;
  @readonly
  entity Statuses   as projection on db.Statuses;
  @readonly
  entity Priorities as projection on db.Priorities;
}

// Business rules
annotate MaterialRequestService.MaterialRequests with {
  department @mandatory;
  plant      @mandatory;
  neededBy   @mandatory;
  priority   @mandatory @assert.range;
}

annotate MaterialRequestService.RequestItems with {
  material @mandatory;
  quantity @mandatory;
}