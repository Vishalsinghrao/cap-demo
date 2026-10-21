using { tii.mr as db } from '../db/schema';

service MaterialRequestService {
    @odata.draft.enabled
  entity MaterialRequests as projection on db.MaterialRequests;
  entity RequestItems     as projection on db.RequestItems;
  @readonly
  entity Materials        as projection on db.Materials;
}