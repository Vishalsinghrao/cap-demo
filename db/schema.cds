namespace tii.mr;

using { cuid, managed } from '@sap/cds/common';

using from '@sap/cds/srv/outbox';

entity MaterialRequests : cuid, managed {
    requestNo   : String(10);
    department  : String(40);
    plant       : String(4);
    neededBy    : Date;
    priority    : String(10) enum {High; Medium; Low} default 'Medium';
    status      : String(10) enum {New; Submitted; Approved; Rejected; PRCreated} default 'New';
    justification : String(500);
    approverNote : String(500);
    prNumber    : String(10);
    statusInfo    : Association to Statuses   on statusInfo.code   = status;
    priorityInfo  : Association to Priorities on priorityInfo.code = priority;
    items       : composition of many RequestItems on items.request = $self; 
}

entity RequestItems : cuid {
    request     : Association to MaterialRequests;
    material    : Association to Materials;
    quantity    : Decimal(13,3);
    unit        : String(3);
    remarks     : String(200);
}

entity Materials  {
    key MaterialNo : String(18);
        description : String(40);
        unit        : String(3);
        materialGroup : String(9);
}

entity Statuses {
  key code        : String(10);
      name        : String(20);
      criticality : Integer;
}

entity Priorities {
  key code        : String(10);
      name        : String(20);
      criticality : Integer;
}

entity Departments {
  key code : String(40);
      name : String(40);
}

entity Plants {
  key code : String(4);
      name : String(40);
}