using MaterialRequestService as service from './service';

// 1. Labels for the fields
annotate service.MaterialRequests with {
  requestNo     @title: 'Request No';
  department    @title: 'Department';
  plant         @title: 'Plant';
  neededBy      @title: 'Needed By';
  priority      @title: 'Priority';
  status        @title: 'Status';
  justification @title: 'Justification';
  approverNote  @title: 'Approver Note';
  prNumber      @title: 'PR Number';
}

// 2. The list page: filters and table columns
annotate service.MaterialRequests with @(
  UI.SelectionFields: [ status, priority, plant, department ],

  UI.LineItem: [
    { Value: requestNo },
    { Value: department },
    { Value: plant },
    { Value: neededBy },
    { Value: priority },
    { Value: status },
    { Value: prNumber }
  ]
);

// 3. Object page for a request
annotate service.MaterialRequests with @(
  UI.HeaderInfo: {
    TypeName       : 'Material Request',
    TypeNamePlural : 'Material Requests',
    Title          : { Value: requestNo },
    Description    : { Value: department }
  },

  UI.FieldGroup #General: {
    Data: [
      { Value: department },
      { Value: plant },
      { Value: neededBy },
      { Value: priority },
      { Value: justification }
    ]
  },

  UI.FieldGroup #Approval: {
    Data: [
      { Value: status },
      { Value: approverNote },
      { Value: prNumber }
    ]
  },

  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'General Information', Target: '@UI.FieldGroup#General' },
    { $Type: 'UI.ReferenceFacet', Label: 'Approval',            Target: '@UI.FieldGroup#Approval' },
    { $Type: 'UI.ReferenceFacet', Label: 'Items',               Target: 'items/@UI.LineItem' }
  ]
);

// 4. The items table inside the object page
annotate service.RequestItems with @(
  UI.LineItem: [
    { Value: material_MaterialNo,  Label: 'Material' },
    { Value: material.description, Label: 'Description' },
    { Value: quantity,             Label: 'Quantity' },
    { Value: unit,                 Label: 'Unit' },
    { Value: remarks,              Label: 'Remarks' }
  ] 
);

// 5. Object page for a single item
annotate service.RequestItems with @(
  UI.HeaderInfo: {
    TypeName       : 'Request Item',
    TypeNamePlural : 'Request Items',
    Title          : { Value: material_MaterialNo },
    Description    : { Value: material.description }
  },

  UI.FieldGroup #ItemDetails: {
    Data: [
      { Value: material_MaterialNo, Label: 'Material' },
      { Value: quantity,            Label: 'Quantity' },
      { Value: unit,                Label: 'Unit' },
      { Value: remarks,             Label: 'Remarks' }
    ]
  },

  UI.FieldGroup #MaterialInfo: {
    Data: [
      { Value: material.description,   Label: 'Description' },
      { Value: material.materialGroup, Label: 'Material Group' },
      { Value: material.unit,          Label: 'Base Unit' }
    ]
  },

  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Item Details',         Target: '@UI.FieldGroup#ItemDetails' },
    { $Type: 'UI.ReferenceFacet', Label: 'Material Information', Target: '@UI.FieldGroup#MaterialInfo' }
  ]
);

// 6. Fields the user cannot edit
annotate service.MaterialRequests with {
  requestNo    @readonly;
  status       @readonly;
  approverNote @readonly;
  prNumber     @readonly;
}

// 7. Value help for materials
annotate service.Materials with @cds.odata.valuelist;

// 8. Action buttons on the object page header
annotate service.MaterialRequests with @(
  UI.Identification: [
    { $Type: 'UI.DataFieldForAction', Action: 'MaterialRequestService.submitRequest',  Label: 'Submit' },
    { $Type: 'UI.DataFieldForAction', Action: 'MaterialRequestService.approveRequest', Label: 'Approve' },
    { $Type: 'UI.DataFieldForAction', Action: 'MaterialRequestService.rejectRequest',  Label: 'Reject' }
  ]
);

// 9. When each button is enabled, and what to refresh after clicking
annotate service.MaterialRequests with actions {
  submitRequest @(
    Core.OperationAvailable: { $edmJson: { $Eq: [{ $Path: 'in/status' }, 'New'] } },
    Common.SideEffects.TargetProperties: ['in/status']
  );
  approveRequest @(
    Core.OperationAvailable: { $edmJson: { $Eq: [{ $Path: 'in/status' }, 'Submitted'] } },
    Common.SideEffects.TargetProperties: ['in/status', 'in/approverNote']
  );
  rejectRequest @(
    Core.OperationAvailable: { $edmJson: { $Eq: [{ $Path: 'in/status' }, 'Submitted'] } },
    Common.SideEffects.TargetProperties: ['in/status', 'in/approverNote']
  );
};