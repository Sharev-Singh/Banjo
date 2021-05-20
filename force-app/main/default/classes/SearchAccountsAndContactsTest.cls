@IsTest
public with sharing class SearchAccountsAndContactsTest {
    @TestSetup
    public static void testSetup() {
        insert TestHelper.createContacts(3);
        insert TestHelper.createAccounts(2);
    }

    @IsTest
    public static void getContactsAndAccountsTest() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        Test.startTest();
        Account account = new Account(Name = 'First Account');
        insert account;
        List<Id> fixedSearchResults = new List<Id> {account.Id};
        for(Contact contact : contacts) {
            fixedSearchResults.add(contact.Id);
        }
        Test.setFixedSearchResults(fixedSearchResults);
        SearchAccountsAndContacts.SearchWrapper searchWrapper = SearchAccountsAndContacts.getContactsAndAccounts('Firstname');

        List<Contact> contactList = searchWrapper.contactList;
        List<Account> accountList = searchWrapper.accountList;

        System.assert(contactList.size() > 0, 'Should return contacts with name "first"');
        System.assert(accountList.size() > 0, 'Should return accounts with name "first"');
        Test.stopTest();
    }

    @IsTest
    public static void incrementCounterTestPositive() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        SearchAccountsAndContacts.incrementCounter(2, 'Contact', contact.Id);
        Test.startTest();
        Contact contactRetrieved = [SELECT Id, Counter__c FROM Contact LIMIT 1];
        System.assertEquals(3, contactRetrieved.Counter__c, 'The value of Counter on Contact should increment by 1');

        Account account = [SELECT Id FROM Account LIMIT 1];
        SearchAccountsAndContacts.incrementCounter(1, 'Account', account.Id);
        Account accountRetrieved = [SELECT Id, Counter__c FROM Account LIMIT 1];
        Test.stopTest();
        System.assertEquals(2, accountRetrieved.Counter__c, 'The value of Counter on Account should increment by 1');
    }

    @IsTest
    public static void incrementCounterTestNegative() {
        Test.startTest();
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        AuraHandledException auraException;
        try {
            SearchAccountsAndContacts.incrementCounter(2, 'Asset', contact.Id);
        }
        catch (AuraHandledException ex){
            auraException = ex;
        }
        System.assertNotEquals(null, auraException, 'It should throw an exception for object other than Account or Contact');
        Test.stopTest();
    }

}