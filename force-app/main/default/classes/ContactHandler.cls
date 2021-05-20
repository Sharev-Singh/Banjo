/**
 * @description Contact trigger handler class
 */
public without sharing class ContactHandler {
    final String CONTACT_FOR_ACCOUNT_APPROVAL_PROCESS = 'Contact_For_Account';

    /**
     * @description After Insert Trigger actions
     * @param newContactsByIds Trigger.newMap
     * @param oldContactsByIds Trigger.oldMap - for future use
     */
    public void onAfterInsert(Map<Id,Contact> newContactsByIds, Map<Id,Contact> oldContactsByIds) {
        submitContactForApproval(newContactsByIds, null);
    }

    /**
     * @description After Update Trigger actions
     * @param newContactsByIds Trigger.newMap
     * @param oldContactsByIds Trigger.oldMap
     */
    public void onAfterUpdate(Map<Id,Contact> newContactsByIds, Map<Id,Contact> oldContactsByIds) {
        submitContactForApproval(newContactsByIds , oldContactsByIds);
        updateTotalContacts(newContactsByIds , oldContactsByIds);
    }

    /**
     * @description After Delete Trigger actions
     * @param newContactsByIds Trigger.newMap - for future use
     * @param oldContactsByIds Trigger.oldMap
     */
    public void onAfterDelete(Map<Id,Contact> newContactsByIds, Map<Id,Contact> oldContactsByIds) {
        decrementTotalContacts(oldContactsByIds);
    }

    /**
     * @description Decrement the value of field Total Contacts on the Account if related active contact is deleted
     * @param oldContactsByIds map of old contacts
     */
    public void decrementTotalContacts(Map<Id,Contact> oldContactsByIds) {
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();

        for (Contact contact : oldContactsByIds.values()) {
            if(contact.Active__c) {
                accountIds.add(contact.AccountId);
                //todo: probably should set the flag to false as well
            }
        }

        for(Account account : [SELECT Total_Contacts__c FROM Account WHERE Id IN :accountIds]) {
            --account.Total_Contacts__c;
            accountsToUpdate.add(account);
        }

        if(accountsToUpdate.size() > 0) {
            update accountsToUpdate;
        }
    }

    /**
     * @description On adding a contact for an account,trigger an approval process to approve the contact
     * @param newContactsByIds map of new Contacts
     * @param oldContactsByIds map of old Contacts
     */
    public void submitContactForApproval(Map<Id,Contact> newContactsByIds, Map<Id,Contact> oldContactsByIds) {
        Approval.ProcessSubmitRequest [] requestList = new Approval.ProcessSubmitRequest []{};
        for(Id contactId : newContactsByIds.keySet()) {
            if(!newContactsByIds.get(contactId).Active__c &&
                    ((oldContactsByIds == null && newContactsByIds.get(contactId).AccountId != null) ||
                    (oldContactsByIds != null && oldContactsByIds.get(contactId).AccountId != newContactsByIds.get(contactId).AccountId))) {
                //Create approval request
                Approval.ProcessSubmitRequest processRequest = new Approval.ProcessSubmitRequest();
                processRequest.setComments('Submitting request for approval.');
                processRequest.setObjectId(contactId);
                processRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                processRequest.setProcessDefinitionNameOrId(CONTACT_FOR_ACCOUNT_APPROVAL_PROCESS);
                requestList.add(processRequest);
            }
        }

        if(requestList.size() > 0) {
            // Submit the approval request
            Approval.ProcessResult[] processResults = Approval.process(requestList);
            for(Approval.ProcessResult result : processResults) {
                if(!result.isSuccess()) {
                    //todo: log the error
                }
            }
        }
    }

    /**
     * @description update Total_Contacts__c field on Account if related Contact is Active
     * @param newContactsByIds map of new contacts
     * @param oldContactsByIds map of old contacts
     */
    public void updateTotalContacts(Map<Id,Contact> newContactsByIds, Map<Id,Contact> oldContactsByIds) {
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();

        for(Id contactId : newContactsByIds.keySet()) {
            if(newContactsByIds.get(contactId).Active__c && !oldContactsByIds.get(contactId).Active__c) {
                accountIds.add(newContactsByIds.get(contactId).AccountId);
            }
        }
        for(Account account : [SELECT Total_Contacts__c FROM Account WHERE Id IN :accountIds]) {
            ++account.Total_Contacts__c;
            accountsToUpdate.add(account);
        }

        if(accountsToUpdate.size() > 0) {
            update accountsToUpdate;
        }
    }
}