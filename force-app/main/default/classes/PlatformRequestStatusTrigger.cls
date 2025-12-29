trigger PlatformRequestStatusTrigger on Platform_Request__c (after update) {

    if (Trigger.isAfter && Trigger.isUpdate) {
        PlatformRequestStatusEmailService.handleAfterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}
