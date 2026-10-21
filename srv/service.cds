using { tii.mr as db } from '../db/schema';

service MaterialRequestService {
    @odata.draft.enabled
  entity MaterialRequests as projection on db.MaterialRequests;
  entity RequestItems     as projection on db.RequestItems;
  @readonly
  entity Materials        as projection on db.Materials;
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