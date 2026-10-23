sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"tii/mr/materialrequests/test/integration/pages/MaterialRequestsList.gen",
	"tii/mr/materialrequests/test/integration/pages/MaterialRequestsObjectPage.gen",
	"tii/mr/materialrequests/test/integration/pages/RequestItemsObjectPage.gen"
], function (JourneyRunner, MaterialRequestsListGenerated, MaterialRequestsObjectPageGenerated, RequestItemsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('tii/mr/materialrequests') + '/test/flp.html#app-preview',
        pages: {
			onTheMaterialRequestsListGenerated: MaterialRequestsListGenerated,
			onTheMaterialRequestsObjectPageGenerated: MaterialRequestsObjectPageGenerated,
			onTheRequestItemsObjectPageGenerated: RequestItemsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

