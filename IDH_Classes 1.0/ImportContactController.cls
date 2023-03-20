public with sharing class ImportContactController {
    @AuraEnabled
    public static String saveContacts(List<Contact> contacts){
       Set<String> contactEmailIds = new Set<String>();
       List<Contact> filterDuplicate = new List<Contact>();
       List<Contact> contactsToInsert = new List<Contact>();
        
       for(Contact cont : contacts){
       if(!contactEmailIds.contains(cont.Email)){
       contactEmailIds.add(cont.Email);
       filterDuplicate.add(cont);
    }
}
List<Contact> existingContacts = [Select Id, Email from Contact where Email IN: contactEmailIds];
contactEmailIds = new Set<String>();
for(Contact cont : existingContacts){
   if(!contactEmailIds.contains(cont.Email)){
       contactEmailIds.add(cont.Email);
   }
}
for(Contact cont : filterDuplicate){
   if(!contactEmailIds.contains(cont.Email)){
       contactsToInsert.add(cont);
     }
  }
  Insert contactsToInsert;
        return contactsToInsert.size() +' Contacts inserted successfully, '+ (contacts.size() - contactsToInsert.size())+' discarded.';
  
  }
  }