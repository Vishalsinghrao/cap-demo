using { tii.mr as db } from '../db/schema';

service MaterialRequestService {
   @odata.draft.enabled
    entity MaterialRequests as projection on db.MaterialRequests {
    *,
    virtual null as isRequester : Boolean,
    virtual null as isApprover  : Boolean
  } actions {
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
  @readonly 
  entity Departments as projection on db.Departments;
  @readonly
  entity Plants as projection on db.Plants;
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

// Authorization
annotate MaterialRequestService with @(requires: 'authenticated-user');

annotate MaterialRequestService.MaterialRequests with @(restrict: [
   { grant: ['READ'],                            to: 'Requester' },
  { grant: ['READ'],                            to: 'Approver', where: 'status != ''New''' },
  { grant: ['CREATE'],                          to: 'Requester' },
  { grant: ['UPDATE', 'DELETE'],                to: ['Requester', 'Approver'] },
  { grant: ['submitRequest'],                   to: 'Requester' },
  { grant: ['approveRequest', 'rejectRequest'], to: 'Approver' }
]);

annotate MaterialRequestService.RequestItems with @(restrict: [
  { grant: ['READ'],  to: ['Requester', 'Approver'] },
  { grant: ['WRITE'], to: 'Requester' }
]);