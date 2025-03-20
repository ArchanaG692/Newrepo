global class Demo {  // Violates AvoidGlobalModifier
  
    public void excessiveParamsMethod(String param1, String param2, String param3, String param4, String param5) { 
        // Violates ExcessiveParameterList (more than 4 params)
        // System.debug(param1 + param2 + param3 + param4 + param5);
    }

    public void hardCodedIdMethod() {
        String hardcodedId = '0019000000XXXXXXX';  // Violates AvoidHardcodingId
        // Account acc = [SELECT Id, Name FROM Account WHERE Id = :hardcodedId WITH SECURITY_ENFORCED];
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :hardcodedId];
        System.debug('Account'+acc);
   } 

    public void deeplyNestedIfMethod(Integer value) {  
        // Violates AvoidDeeplyNestedIfStmts (nested more than 4 levels)
        if (value > 0) {
            if (value > 10) {
                if (value > 20) {
                    if (value > 30) {
                        System.debug('Heeeeeeeeeeellllllloooooo');
                    }
                }

            }
        }
    }

    public void soqlInjection(String userInput) {  
        // Violates ApexSOQLInjection (Unsafe SOQL query)
        String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'%' + userInput + '%\'';
        List<Account> accounts = Database.query(query);
    }
}
