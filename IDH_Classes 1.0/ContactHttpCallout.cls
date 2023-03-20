global class ContactHttpCallout {
    global static void makePostCallout(Sobject contactrecord){
        System.debug('27--makePostCallout');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://jkw9rha0f4.execute-api.us-east-1.amazonaws.com/dev/invitemail');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
        
        Contact contactData = (Contact) contactrecord;

        Map<String, Object> requestBody = new Map<String, Object>();
        
        // Set the "Query" parameter
        Map<String, String> queryMap = new Map<String, String>{
            'environment' => 'PlayClay'
        };
        requestBody.put('query', queryMap);
        
        // Set the "Body" parameter
        Map<String, Object> BodyMap = new Map<String, Object>{
            'app' => new Map<String, Object>{
                'appId' => 6,
                'appName' => 'Idhini'
            },
            'mailList' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'email' => contactData.Email,
                    'userName' => contactData.Name + ' ' + contactData.Name,
                    'userId' => '',
                    'firstName' => contactData.Name,
                    'lastName' => contactData.Name
                }
            },
            'org' => new Map<String, Object>{
                'orgId' => 1516,
                'orgName' => 'Idhini'
            },
            'invitedBy' => new Map<String, Object>{
                'userName' => 'contact@focalcxm.com'
            },
            'envId' => 9,
            'selfSigned' => true
        };
        requestBody.put('body', BodyMap);
        system.debug('baton user----->'+ requestBody);
        String requestBodyJson = JSON.serialize(requestBody);
        request.setBody(requestBodyJson);
        system.debug('baton user request--->' + requestBodyJson);
        HttpResponse response = http.send(request);
       if(response.getStatusCode() != 200) {
           System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
         
      } else {
          
                System.debug('The status code returned was expected: ' + response.getBody());
          
    
     }
    }
}