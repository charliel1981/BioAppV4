({
    doInit : function(component, event) {
        var action = component.get("c.findAll");
        action.setCallback(this, function(a) {
            component.set("v.accounts", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    
    searchKeyChange: function(component, event) {
        var searchKey = event.getParam("searchKey");
        var action = component.get("c.findByName");
        action.setParams({
          "searchKey": searchKey
        });
        action.setCallback(this, function(a) {
            component.set("v.accounts", a.getReturnValue());
        });
        $A.enqueueAction(action);
	},
    
     createRecord : function (component, event) {
   	
    var navEvt = $A.get("e.force:navigateToSObject");
    
    navEvt.setParams({
      "recordId": event.target.id,
      "slideDevName": "detail"
    });
        
    navEvt.fire();
}

    
})