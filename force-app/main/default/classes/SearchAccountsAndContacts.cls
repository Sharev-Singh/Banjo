/**
 * @description Contains methods to help searching for accounts and contacts
 */

public with sharing class SearchAccountsAndContacts {

    /**
     * @description Search Accounts and Contacts for the user input
     * @param searchKey user input to perform search
     *
     * @return Wrapper class with list of contacts and accounts containing search result
     */
    @AuraEnabled(Cacheable=true)
    public static SearchWrapper getContactsAndAccounts(String searchKey) {
        String searchQuery = 'FIND \'' + searchKey + '\' IN NAME FIELDS RETURNING Account(Id, Name, Counter__c), Contact(Id, FirstName,LastName, Counter__c)';
        List<List<SObject>> searchList = Search.query(searchQuery);
        Account[] searchAccounts = (Account[])searchList[0];
        Contact[] searchContacts = (Contact[])searchList[1];
        SearchWrapper searchWrapper = new SearchWrapper();
        searchWrapper.accountList = searchAccounts;
        searchWrapper.contactList = searchContacts;

        if(searchContacts.size() == 0 && searchAccounts.size() == 0){
            throw new AuraHandledException('No Record Found..');
        }
        return searchWrapper;
    }

    /**
     * @description Increment counter field value on Account or Contact
     * @param counter Current value of counter
     * @param objectName helps in assessing if Contact or Account needs to be updated
     * @param recordId Id of the record that needs to be updated
     *
     * @return incremented counter value to be displayed
     */
    @AuraEnabled
    public static Integer incrementCounter(Integer counter, String objectName, Id recordId) {
        Integer counterInc = counter;
        Database.SaveResult saveResult;

        if(objectName == 'Contact') {
            saveResult =  Database.update(new Contact(Id = recordId, Counter__c = counter + 1));
        }
        else if(objectName == 'Account') {
            saveResult =  Database.update(new Account(Id = recordId, Counter__c = counter + 1));
        }

        if(saveResult != null && saveResult.isSuccess()) {
            ++counterInc;
        }
        else {
            throw new AuraHandledException('There was a problem incrementing the counter.');
        }

        return counterInc;
    }

    /**
     * @description Wrapper class to return list of contacts and acccounts
     */
    public class SearchWrapper {
        @AuraEnabled
        public List<Contact> contactList;
        @AuraEnabled
        public List<Account> accountList;
    }
}