/*
    Created by -  RK Koluri
    Description - Controller class to define Business Rules
*/
public with sharing class BusinessRulesController {
    public static String className = 'BusinessRulesController';

    
    public class TemplatesGroupsMapping {
        @AuraEnabled public String groupName;
        @AuraEnabled public Id groupId;
        @AuraEnabled public String professionalDesgination;
        @AuraEnabled public String template;
        @AuraEnabled public String businessHours;
        @AuraEnabled public String operatingHours;
    }
    @AuraEnabled(cacheable=true)
    public static List<TemplatesGroupsMapping> getTemplatesMapping(){
        List<TemplatesGroupsMapping> tMappingList = new List<TemplatesGroupsMapping>();
        try{
        List<Scheduling_Groups__c> groups = [select id,Operating_Hours__r.Name, name,Operating_Hours_Message__c, IsActive__c from Scheduling_Groups__c where IsActive__c = true];
        for(Scheduling_Groups__c gObj : groups){
            TemplatesGroupsMapping tMapObj = new TemplatesGroupsMapping();
            tMapObj.groupName = 'Group Name - '+gObj.name;
            tMapObj.groupId = gObj.id;
            tMapObj.businessHours = gObj.Operating_Hours_Message__c;
            tMapObj.operatingHours = gObj.Operating_Hours__r.Name;
            if(gObj.name.toUpperCase().contains('OREG')){
                List<String> designations = new List<String>{
                    'MD',
                    'DO',
                    'Pharmacist (PharmD)',
                    'PA',
                    'Medical Assistant',
                    'Office Manager',
                    'Billing Coordinator',
                    'Other'
                };
                tMapObj.professionalDesgination = String.join(designations, ',');
                List<String> templatesList = new List<String>{
                    'Clinical Study Information',
                    'Product Access: Coverage, Reimbursement, Coding, Billing',
                    'General Adverse Event Management',
                    'Patient Education',
                    'Others'
                };

                tMapObj.template = String.join(templatesList, ',');
                
            }

            if(gObj.name.toUpperCase().contains('NE')){
                List<String> designations = new List<String>{
                    'CRNP',
                    'RN'
                };
                tMapObj.professionalDesgination = String.join(designations, ',');
                List<String> templatesList = new List<String>{
                    'General Adverse Event Management',
                    'Patient Education'
                };

                tMapObj.template = String.join(templatesList, ',');
                
            }
            tMappingList.add(tMapObj);
        }
    }catch(Exception ex){
        System.debug('ex-->'+ ex);
        AMOExceptionHandler.logException(ex,className,'getTemplatesMapping','','Apex');

    }
        return tMappingList;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,List<String>> getTemplates(String recordId){
        List<String> templateNames = new List<String>();
        List<String> productsList = new List<String>();
        Map<String,List<String>> templatesMap = new Map<String,List<String>>();
        try{
        Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
        ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(configRecord.JSON_Payload__c, ScheduleRequest.class);
        for(ScheduleRequest.templates str : payload.templates){
            if(str.isSchedulable){
                templateNames.add(str.label);
            }
        }
        for(ScheduleRequest.products pro : payload.products){
            productsList.add(pro.label);
        }
        templatesMap.put('templates', templateNames);
        templatesMap.put('products', productsList);
    }catch(Exception ex){
        System.debug('ex-->'+ ex);
        AMOExceptionHandler.logException(ex,className,'getTemplates','','Apex');

    }
        return templatesMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<Group_Holidays__c> getHolidays(String groupId){
        return [Select Id,  Holiday__r.Name,Holiday__r.Date__c from Group_Holidays__c where Scheduling_Group__c =: groupId and Holiday__r.Date__c = THIS_YEAR ];
    }

    @AuraEnabled(cacheable=true)
    public static String getBusinessHoursName(String grpName){
        System.debug('grpname =>'+grpName);
        Scheduling_Groups__c grp = [Select Id, Name, Operating_Hours__r.Name from Scheduling_Groups__c where Name =: grpName];
        System.debug('grp =>'+grp);
        return grp!=null ? grp.Operating_Hours__r.Name : '';
    }

    @AuraEnabled
    public static String saveHolidays(String holidayName, String holidayDate, String groupId){
        Holidays__c newHoliday = new Holidays__c();
        Group_Holidays__c grpHoliday = new Group_Holidays__c();
        try{
        newHoliday.Name = holidayName;
        newHoliday.Date__c = Date.valueOf(holidayDate);
        insert newHoliday;

        
        grpHoliday.Holiday__c = newHoliday.Id;
        grpHoliday.Scheduling_Group__c  = groupId;
        insert grpHoliday;
        }catch(Exception ex){
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'saveHolidays','','Apex');

        }
        return (String.isNotBlank(newHoliday.ID) && String.isNotBlank(grpHoliday.ID)) ? 'SUCCESS' : 'ERROR';
    }

    @AuraEnabled
    public static void addValuesToJSON(String obj, String recordId){
        Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
        try{
        //System.debug('configRecord => '+ configRecord);
        ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(configRecord.JSON_Payload__c, ScheduleRequest.class);
        //System.debug('payload => '+ payload);
        payload.AssignmentGroups = new List<ScheduleRequest.AssignmentGroups>();
        List<String> businessHourNameList = new List<String>();
        List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(obj);
        //System.debug('Wrapper => '+ fieldList);
        Map<String, Map<String, List<String>>> mapByGrpName = new Map<String, Map<String, List<String>>>();
        Map<String, List<String>> mapofTemplatePFD = new Map<String, List<String>>();
        for(Object fld : fieldList){
            Map<String, Object> data = (Map<String, Object>)fld;
            List<String> professionalDesignation = new List<String>();
            List<Object> pfd = (List<Object>)data.get('designation');
            for(Object a : pfd){
                professionalDesignation.add(String.valueOf(a));
            }
            String st = (String)data.get('businessHoursName');
            if(st!=null){
                businessHourNameList.add(st);   
            }
            //System.debug('pfd => '+ professionalDesignation);    
            mapofTemplatePFD.put(String.valueOf(data.get('group'))+'_'+String.valueOf(data.get('templateName')), professionalDesignation);
            mapByGrpName.put(String.valueOf(data.get('group')), mapofTemplatePFD);
        }
        //System.debug('mapofTemplatePFD => '+ mapofTemplatePFD);
        //System.debug('mapByGrpName => '+ mapByGrpName);
        List<ScheduleRequest.AssignmentGroups> wrapperList = new List<ScheduleRequest.AssignmentGroups>();
        List<Time_Slots__c> timeSlots = [SELECT Id, End_Time__c, Day_of_Week__c, Start_Time__c from Time_Slots__c where Operating_Hours__r.Name IN :businessHourNameList];
        //System.debug('timeSlots => '+ timeSlots);
        for(String grpName: mapByGrpName.keySet()){
            ScheduleRequest.AssignmentGroups asgrps = new ScheduleRequest.AssignmentGroups();
            asgrps.groupName = grpName;
            List<ScheduleRequest.RoutingGroup> routingGrpList = new List<ScheduleRequest.RoutingGroup>();
            for(String templateName : mapByGrpName.get(grpName).keyset()){
                if(templateName.startswith(grpName)){
                    ScheduleRequest.RoutingGroup routingGrps = new ScheduleRequest.RoutingGroup();
                    routingGrps.appointmentTemplate = templateName.split('_')[1];
                    routingGrps.professionalDesignation = mapByGrpName.get(grpName).get(templateName);
                    routingGrpList.add(routingGrps);
                }
            }
            List<ScheduleRequest.BusinessHours> businessHrsList = new List<ScheduleRequest.BusinessHours>();
            for(Time_Slots__c t : timeSlots){
                for(String templateName : mapByGrpName.get(grpName).keyset()){
                    ScheduleRequest.BusinessHours businessHrs = new ScheduleRequest.BusinessHours();
                    businessHrs.weekName = String.valueOf(t.Day_of_Week__c);
                    businessHrs.startTime = String.valueOf(t.Start_Time__c);
                    businessHrs.endTime = String.valueOf(t.End_Time__c);
                    businessHrsList.add(businessHrs);
                }
            }
            asgrps.routingGroup = routingGrpList;
            asgrps.businessHours = businessHrsList;
            wrapperList.add(asgrps);
        }

        //System.debug('wrapperList =>'+wrapperList);
        payload.AssignmentGroups = wrapperList;
        //System.debug('assignment groups =>'+payload.AssignmentGroups);
        configRecord.JSON_Payload__c = JSON.serialize(payload);
    }catch(Exception ex){
        System.debug('ex-->'+ ex);
        AMOExceptionHandler.logException(ex,className,'addValuesToJSON','','Apex');

    }
        update configRecord;
    }

    @AuraEnabled
    public static void addHolidaysByGroup(String recordId){
        try{
        Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
        ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(configRecord.JSON_Payload__c, ScheduleRequest.class);
        //String payload = String.valueOf(configRecord.JSON_Payload__c);
        List<Scheduling_Groups__c> groups = [select id, name, IsActive__c, (select id, name, Holiday__c, Holiday__r.name, Holiday__r.Date__c from Group_Holidays__r) from Scheduling_Groups__c where IsActive__c = true];
        List<ScheduleRequest.HolidaysByGroup> wrapperList = new List<ScheduleRequest.HolidaysByGroup>();
        for(Scheduling_Groups__c gObj : groups){
            ScheduleRequest.HolidaysByGroup hObj = new ScheduleRequest.HolidaysByGroup();
            hObj.groupName = gObj.Name;
            hObj.groupId = gObj.Id;
            hObj.holidays = new List<String>();
            for(Group_Holidays__c ghObj : gObj.Group_Holidays__r){
                hObj.holidays.add(String.valueOf(ghObj.Holiday__r.Date__c));    
            }
            wrapperList.add(hObj);    
        }
        System.debug('holidaysByGrp '+ JSON.serialize(wrapperList));
        //payload = payload.replace('[ ]', JSON.serialize(wrapperList));
        payload.holidaysByGroup=wrapperList;
        configRecord.JSON_Payload__c = JSON.serializePretty(payload, true);
        update configRecord;
    }catch(Exception ex){
        System.debug('ex-->'+ ex);
        AMOExceptionHandler.logException(ex,className,'addHolidaysByGroup','','Apex');

    }
    }



    @AuraEnabled
    public static String getCallRouting(List<String> appointmentTemplates,List<String> products,String recordId){
        String decisionString;
        try {
            List<String> profDesignationList= new List<String>();
            Schema.DescribeFieldResult fieldResult = Event.Professional_Designation__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                profDesignationList.add(pickListVal.getLabel());
            }
            List<Object> grpObj = new List<Object>();
            for(Scheduling_Groups__c grp :[Select Id,Name FROM Scheduling_Groups__c]){
                grpObj.add(new Map<String, String> {
                    'groupId' => grp.Id,
                        'groupName' => grp.Name
                        });
            }
            Map<String,List<Object>> schedulingGroupsObj = new Map<String,List<Object>> ();
            schedulingGroupsObj.put('appointmentTemplate', new List<String> (appointmentTemplates));
            schedulingGroupsObj.put('professionalDesignation',new List<String> (profDesignationList));
            schedulingGroupsObj.put('product',new List<String> (products));
            Map<String,Object> schedulingGroupsMap = new Map<String,Object> ();
            schedulingGroupsMap.put('schedulingGroups',schedulingGroupsObj);
            schedulingGroupsMap.put('groupInfo',new List<Object>(grpObj));
            System.debug('schedulingGroupsMap-->'+schedulingGroupsMap);
            Map<String,Object> tempresponse = new Map<String,Object>();
            decisionString = getDecisionByRules(schedulingGroupsMap);
            System.debug('decisionString-->'+decisionString);
            tempresponse= (Map<String,Object>)JSON.deserializeUntyped(decisionString);
            System.debug('tempresponse-->'+tempresponse);
            String tempDecisionString = decisionString.substring(1, decisionString.length() - 1);
            tempDecisionString = tempDecisionString.removeEnd('}');
            //tempDecisionString = tempDecisionString.replaceAll('professionalDesignation', 'profesionalDesgination');
            Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: recordId ];
            String payload = String.valueOf(configRecord.JSON_Payload__c);
            System.debug('tempDecisionString-->'+tempDecisionString);  
            payload = payload.replace('"assignmentGroups" : [ ]', tempDecisionString);
            //configRecord.JSON_Payload__c = JSON.serialize(payload);
            configRecord.JSON_Payload__c = payload;
            update configRecord;
        } catch (Exception ex) {
            System.debug('ex-->'+ ex);
             System.debug('ex-line->'+ ex.getLineNumber());
            AMOExceptionHandler.logException(ex,className,'getCallRouting','','Apex');
        }
        return decisionString;
    }
    
    @AuraEnabled
    public static string getDecisionByRules(Map<String,Object> schedulingGroupsMap){
        String routingResponse = '';
        try {
            String jsonBody = json.serialize(schedulingGroupsMap);
            Aws_Api_Settings__mdt authorzationDetails = Aws_Api_Settings__mdt.getInstance('AMO_Decision_Manager');
            if ( authorzationDetails != null ){
                String endpoint = authorzationDetails.Hostname__c+authorzationDetails.End_Point_URL__c;
                System.debug('jsonBody-->'+jsonBody);
                String method = 'POST';
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                // request.setEndpoint('https://6dm9ax3raj.execute-api.us-east-2.amazonaws.com/test/assignment-groups');
                request.setEndpoint(endpoint);
                request.setMethod(method);
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', '*/*');
                request.setHeader('x-api-key', authorzationDetails.Api_Key__c);
                request.setBody(jsonBody);
                request.setTimeout(120000);
                response = http.send(request);
                system.debug('response.getStatusCode():'+response.getStatusCode());
                if (response.getStatusCode() == 200) {
                    System.debug('res--->'+response.getBody());
                    routingResponse = String.valueOf(response.getBody());
                }
            }
        } catch (Exception ex) {
            System.debug('ex-->'+ ex);
            AMOExceptionHandler.logException(ex,className,'getDecisionByRules','','Apex');
        }
        return routingResponse;
    }


}