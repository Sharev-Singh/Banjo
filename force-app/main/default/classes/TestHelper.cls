/**
 * @description Helper class for test classes
 *
 */
public with sharing class TestHelper {

    /**
     * @description Create Contacts
     * @param numberOfContacts number of contacts to be created
     *
     * @return List of contacts ready to be inserted
     */
    public static List<Contact> createContacts(Integer numberOfContacts) {
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < numberOfContacts; i++) {
            Contact contact = new Contact(LastName = 'Lastname Test ' + i, FirstName  = 'Firstname Test ' + i);
            contacts.add(contact);
        }
        return contacts;
    }

    /**
     * @description Create Accounts
     * @param numberOfAccounts number of accounts to be created
     *
     * @return List of accounts ready to be inserted
     */
    public static List<Account> createAccounts(Integer numberOfAccounts) {
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < numberOfAccounts; i++) {
            Account account = new Account(Name = 'Account Test ' + i);
            accounts.add(account);
        }
        return accounts;
    }
}