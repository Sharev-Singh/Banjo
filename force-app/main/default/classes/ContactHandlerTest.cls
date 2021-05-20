@IsTest
public with sharing class ContactHandlerTest {

    @TestSetup
    public static void testSetup() {
        insert TestHelper.createContacts(3);
        insert TestHelper.createAccounts(2);
    }

    @IsTest
    public static void submitContactForApprovalOnInsertTestPositive() {
        //test on contacts insertion
        Integer numberOfContacts = 3;
        Account account = [SELECT Id FROM Account LIMIT 1];
        List<ProcessInstanceWorkitem> processInstanceWorkitem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];

        Test.startTest();
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < numberOfContacts; i++) {
            Contact contact = new Contact(LastName = 'Lastname Test ' + i, FirstName  = 'Firstname Test ' + i, AccountId = account.Id);
            contacts.add(contact);
        }
        insert contacts;

        List<ProcessInstanceWorkitem> processInstanceWorkitemRetrieved = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];
        System.assertEquals(processInstanceWorkitem.size() + numberOfContacts, processInstanceWorkitemRetrieved.size(), 'One approval process per contact should be intitalized when added to Accounts');

        //test on contact update
        Contact contactNew = new Contact(LastName = 'Mark');
        insert contactNew;
        List<ProcessInstanceWorkitem> processWorkitemOnUpdate = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];
        System.assertEquals(processInstanceWorkitemRetrieved.size(), processWorkitemOnUpdate.size(), 'No new approval process should be started');

        Contact contactNewRetrieved = [SELECT AccountId FROM Contact WHERE Id =: contactNew.Id];
        contactNewRetrieved.AccountId = account.Id;
        update contactNewRetrieved;
        Test.stopTest();
        List<ProcessInstanceWorkitem> processWorkitemOnUpdateRetrieved = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];
        System.assertEquals(processInstanceWorkitemRetrieved.size() + 1, processWorkitemOnUpdateRetrieved.size(), 'New approval process should be started for updated contact');
    }

    @IsTest
    public static void submitContactForApprovalTestNegative() {
        //test on inserting contacts without AccountId
        List<ProcessInstanceWorkitem> processInstanceWorkitem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];
        Test.startTest();
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 3; i++) {
            Contact contact = new Contact(LastName = 'Lastname Test ' + i, FirstName  = 'Firstname Test ' + i);
            contacts.add(contact);
        }
        insert contacts;
        List<ProcessInstanceWorkitem> processInstanceWorkitemRetrieved = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];
        System.assertEquals(processInstanceWorkitem.size(), processInstanceWorkitemRetrieved.size(), 'No approval process should be intitalized when contacts are inserted without Account');

        //testing with active flag on update
        Contact contact = [SELECT Active__c, AccountId FROM Contact WHERE Id =: contacts[0].Id];
        contact.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
        contact.Active__c = true;
        update contact;
        Test.stopTest();
        List<ProcessInstanceWorkitem> processWorkitem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.Status = 'Pending'];
        System.assertEquals(processInstanceWorkitem.size(), processWorkitem.size(), 'No approval process should be intitalized when contacts are updated to new Account with Active flag');

    }

    /**
     * @description test method for updateTotalContacts(...) and decrementTotalContacts(...)
     */
    @IsTest
    public static void decrementAndUpdateTotalContactsTest() {
        Contact contact = [SELECT Id, Active__c, AccountId  FROM Contact LIMIT 1];
        Account account = [SELECT Id, Total_Contacts__c FROM Account LIMIT 1];
        contact.AccountId = account.Id;
        update contact;
        System.assertEquals(account.Total_Contacts__c, 0, 'Total contacts should be 0 as it has no related contacts');

        //approve Approval Process
        ProcessInstanceWorkitem processItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: contact.Id];
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction('Approve');
        req.setWorkitemId(processItem.Id);
        Approval.process(req);

        //test if Total_Contacts__c incremented after approving Approval process
        Test.startTest();
        Account accountRetrieved = [SELECT Id, Total_Contacts__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(accountRetrieved.Total_Contacts__c, 1, 'Total contacts should be incremented');
        delete contact;
        Test.stopTest();

        //test if Total_Contacts__c decremented after deletion of contact
        Account accountAfterContactDeleted = [SELECT Id, Total_Contacts__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(accountAfterContactDeleted.Total_Contacts__c, 0, 'Total contacts should be decremented');
    }
}