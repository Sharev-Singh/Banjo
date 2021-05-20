trigger ContactTrigger on Contact (after insert, after update, after delete) {
    ContactHandler contactHandler = new ContactHandler();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            contactHandler.onAfterInsert(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isUpdate) {
            contactHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete) {
            contactHandler.onAfterDelete(Trigger.newMap, Trigger.oldMap);
        }
    }
}