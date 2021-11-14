@isTest
private class CommunityControllerTest 
{

    static testMethod void testGetCommunityItemRecords() 
    {    	
        Community_Items__c toiRecord1 = CommunityUtilities.createTopicOfInterestCommunityItem(
        																					'CMS’s proposed rule for hospitals: Reduce antibiotic use or exit Medicare',
        																					'CMS released a proposed rule change to its Conditions of Participation which would, among other changes, require hospitals to implement antibiotic stewardship programs in order to participate in Medicare and Medicaid. Studies have shown that stewardship programs may lower the use of antibiotics by almost 20 percent and have linked such programs to a drop in infection rates.' 
        																					);        														
        Community_Items__c toiRecord2 = CommunityUtilities.createTopicOfInterestCommunityItem(         														
        														'The 2,597 hospitals facing readmissions penalties this year',
        														'CMS will withhold more than $500 million in payments under its readmissions reduction program.'
        														);
        Community_Items__c toiRecord3 = CommunityUtilities.createTopicOfInterestCommunityItem(
        														'A mechanical jack-like mechanism drives spontaneous fracture healing in neonatal mice.',
        														'The Traditional view of fracture healing is being challenged by a new study published in Developmental Cell which has revealed that a fractured arm bone in new-born mice can rapidly realign through a previously unknown mechanism involving bone growth and muscle contraction.'
        														);
        Community_Items__c toiRecord4 = CommunityUtilities.createTopicOfInterestCommunityItem( 
        														'Ontario scientist thinks old drugs could become our new antibiotics',
        														'As the world loses its upper hand in the antibiotics arms race, it raises the spectre of untreatable infections resulting from routine surgeries. But a Canadian scientist has discovered a surprising source of potential antibiotic options.'
        														);		
        insert new List<Community_Items__c>{toiRecord1, toiRecord2, toiRecord3, toiRecord4};
        
        Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(toiRecord1.Id, '');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(toiRecord2.Id, '');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(toiRecord3.Id, '');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(toiRecord4.Id, '');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};
        
        
        Test.startTest();
        	List<CommunityItemWrapper> commItems = CommunityController.getCommunityItemRecords('Topic of Interest / Notices', 10);
        Test.stopTest();
        
        System.assertEquals(4, commItems.size());        																																																					
    }
    
    static testMethod void testGetCommunityItemRecordsInternal() 
    {    	
        Community_Items__c commItem1 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Purchasing', 'Purchasing EU');
    	Community_Items__c commItem2 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Theatre Nurse', 'Theatre Nurse');
    	Community_Items__c commItem3 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Theatre Manager', 'Theatre Manager');
    	Community_Items__c commItem4 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Distributor Rep', 'Distributor Rep');
    	insert new List<Community_Items__c>{commItem1, commItem2, commItem3, commItem4};
    	
    	Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(commItem1.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(commItem2.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(commItem3.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(commItem4.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};
        
        
        Test.startTest();
        	List<CommunityItemWrapper> commItems = CommunityController.getCommunityItemRecords('Internal only', 0);
        Test.stopTest();
        
        System.assertEquals(4, commItems.size());        																																																					
    }
    
    static testMethod void testGetCommunityItemRecordsFeaturedItem() 
    {    	
    	Id recordTypeId = [Select Id from RecordType where SObjectType='Community_Items__c' and DeveloperName='Featured_Item'].Id;
        Community_Items__c commItemf1 = new Community_Items__c(Type__c='Featured Item', 
        														RecordTypeId = recordTypeId,
        														Title__c = 'Featured item1');
    	Community_Items__c commItemf2 = new Community_Items__c(Type__c='Featured Item', 
        														RecordTypeId = recordTypeId,
        														Title__c = 'Featured item2');
        														
        insert new List<Community_Items__c>{commItemf1, commItemf2};
        														
    	Community_Items__c commItem3 = CommunityUtilities.createTopicOfInterestCommunityItem(
        														'A mechanical jack-like mechanism drives spontaneous fracture healing in neonatal mice.',
        														'The Traditional view of fracture healing is being challenged by a new study published in Developmental Cell which has revealed that a fractured arm bone in new-born mice can rapidly realign through a previously unknown mechanism involving bone growth and muscle contraction.'
        														);
        commItem3.Use_this_as_featured_item__c = commItemf1.Id;															
    	Community_Items__c commItem4 = CommunityUtilities.createPublishersLibCommunityItem('Antibiotic-loaded synthetic calcium sulfate beads for prevention of bacterial colonization and biofilm formation in periprosthetic infections.', 
    										'Howlin, R.P., et al.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ', 
    										'Antimicrob Agents Chemother, 2015. 59(1): p. 111-20.');
    	commItem4.Use_this_as_featured_item__c = commItemf2.Id;									
    	insert new List<Community_Items__c>{commItem3, commItem4};
    	
    	Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(commItemf1.Id, '');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(commItemf2.Id, '');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(commItem3.Id, '');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(commItem4.Id, '');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};
        
        
        Test.startTest();
        	List<CommunityItemWrapper> commItems = CommunityController.getCommunityItemRecords('Featured Item', 0);
        Test.stopTest();
        
        System.assertEquals(2, commItems.size());        																																																					
    }
    
    static testMethod void testGetPublisherLibRecords()
    {
    	Community_Items__c commItem1 = CommunityUtilities.createPublishersLibCommunityItem('Antibiotic-loaded synthetic calcium sulfate beads for prevention of bacterial colonization and biofilm formation in periprosthetic infections.', 
    										'Howlin, R.P., et al.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ', 
    										'Antimicrob Agents Chemother, 2015. 59(1): p. 111-20.');
    	Community_Items__c commItem2 = CommunityUtilities.createPublishersLibCommunityItem('An unusual case of salmonella typhimurium and MRSA co-infection of a prosthetic hip joint: Double trouble and a narrow squeak!', 
    										'Nayar, D., S. Thomas, and P. Duffy', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'4th Annual Oxford Bone Infection Conference (OBIC). 2014: Oxford, UK.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
    	Community_Items__c commItem3 = CommunityUtilities.createPublishersLibCommunityItem('Managing lower-extremity osteomyelitis locally with surgical debridement and synthetic calcium sulfate antibiotic tablets.', 
    										'Gauland, C.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Adv Skin Wound Care, 20111. 24(11): p. 515-23', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
    	Community_Items__c commItem4 = CommunityUtilities.createPublishersLibCommunityItem('Osteomyelitis Control by Debridement and Local Antimicrobial Release.', 
    										'Gauland, C.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'The 15th Malvem Diabetic Foot Conference. 2014: Malvem, Worchestershire, UK.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');			
    	insert new List<Community_Items__c>{commItem1, commItem2, commItem3, commItem4};
    	
    	Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(commItem1.Id, '');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(commItem2.Id, '');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(commItem3.Id, '');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(commItem4.Id, '');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};	
        
        Test.startTest();
        	List<CommunityItemWrapper> commItems = CommunityController.getPublisherLibRecords('Publication Library', 10, 0);
        Test.stopTest();
        
        System.assertEquals(4, commItems.size());         																							
    }
    
    static testMethod void testGetLogoURLForUser()
    {
    	Id recordTypeId = [Select Id from RecordType where SObjectType='Community_Items__c' and DeveloperName='Logo'].Id;
    	User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
    	
		Community_Items__c commItem = new Community_Items__c(	RecordTypeId = recordTypeId,
        														Profile__c =  currentUser.Community_View__c,
        														URL_For_Image__c = 'https://biocomposites.force.com/servlet/servlet.ImageServer?id=015U0000003Dual&oid=00DU0000000Levb',
        														ALT_Tag__c = 'example tag'
        													);
       insert commItem;
       
        Test.startTest();
        	String commItems = CommunityController.getLogoURLForUser();
        Test.stopTest();
        
        System.assert(commItems != '');													
    }
    
    static testMethod void testGetColorCodes()
    {
    	CommunityColorMapWithType__c commColor = new CommunityColorMapWithType__c();
    	commColor.Name = '1';
    	commColor.Color_code__c = '#94C14B';
    	commColor.SubType__c = 'Stimulan';
    	commColor.Type__c = 'Marketing collateral';    	
    	insert commColor;
    	
    	Test.startTest();
    		Map<String, String> colorMap = CommunityController.getColorCodes();
    	Test.stopTest();
    	
    	System.assertEquals(1, colorMap.size());
    	System.assert(colorMap.containsKey('Marketing collateral-Stimulan'));
    	System.assertEquals('#94C14B', colorMap.get('Marketing collateral-Stimulan'));
    }
    
    static testMethod void testCheckCommunityItemExists()
    {
    	Community_Items__c commItem1 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Purchasing', 'Purchasing EU');
    	Community_Items__c commItem2 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Theatre Nurse', 'Theatre Nurse');
    	Community_Items__c commItem3 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Theatre Manager', 'Theatre Manager');
    	Community_Items__c commItem4 = CommunityUtilities.createInternalOnlyCommunityItem('Persona - Distributor Rep', 'Distributor Rep');
    	insert new List<Community_Items__c>{commItem1, commItem2, commItem3, commItem4};
    	
    	Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(commItem1.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(commItem2.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(commItem3.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(commItem4.Id, '/servlet/servlet.FileDownload?file=015U0000003hxYl');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};
        
        Test.startTest();
        	Boolean checkCommItem = CommunityController.checkCommunityItemExists('Internal only');
        Test.stopTest();
        
        System.assertEquals(true, checkCommItem);     	
    }
    
    static testMethod void testGetPublisherTotalItems()
    {
    	Community_Items__c commItem1 = CommunityUtilities.createPublishersLibCommunityItem('Antibiotic-loaded synthetic calcium sulfate beads for prevention of bacterial colonization and biofilm formation in periprosthetic infections.', 
    										'Howlin, R.P., et al.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ', 
    										'Antimicrob Agents Chemother, 2015. 59(1): p. 111-20.');
    	Community_Items__c commItem2 = CommunityUtilities.createPublishersLibCommunityItem('An unusual case of salmonella typhimurium and MRSA co-infection of a prosthetic hip joint: Double trouble and a narrow squeak!', 
    										'Nayar, D., S. Thomas, and P. Duffy', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'4th Annual Oxford Bone Infection Conference (OBIC). 2014: Oxford, UK.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
    	Community_Items__c commItem3 = CommunityUtilities.createPublishersLibCommunityItem('Managing lower-extremity osteomyelitis locally with surgical debridement and synthetic calcium sulfate antibiotic tablets.', 
    										'Gauland, C.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Adv Skin Wound Care, 20111. 24(11): p. 515-23', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
    	Community_Items__c commItem4 = CommunityUtilities.createPublishersLibCommunityItem('Osteomyelitis Control by Debridement and Local Antimicrobial Release.', 
    										'Gauland, C.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'The 15th Malvem Diabetic Foot Conference. 2014: Malvem, Worchestershire, UK.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');			
    	insert new List<Community_Items__c>{commItem1, commItem2, commItem3, commItem4};
    	
    	Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(commItem1.Id, '');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(commItem2.Id, '');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(commItem3.Id, '');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(commItem4.Id, '');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};
        
        Test.startTest();
        	Integer countCommItem = CommunityController.getPublisherTotalItems();
        Test.stopTest();
        
        System.assertEquals(4, countCommItem);
    }
    
    static testMethod void testSearchPublications()
    {
    	Community_Items__c commItem1 = CommunityUtilities.createPublishersLibCommunityItem('Antibiotic-loaded synthetic calcium sulfate beads for prevention of bacterial colonization and biofilm formation in periprosthetic infections.', 
    										'Howlin, R.P., et al.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ', 
    										'Antimicrob Agents Chemother, 2015. 59(1): p. 111-20.');
    	Community_Items__c commItem2 = CommunityUtilities.createPublishersLibCommunityItem('An unusual case of salmonella typhimurium and MRSA co-infection of a prosthetic hip joint: Double trouble and a narrow squeak!', 
    										'Nayar, D., S. Thomas, and P. Duffy', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'4th Annual Oxford Bone Infection Conference (OBIC). 2014: Oxford, UK.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
    	Community_Items__c commItem3 = CommunityUtilities.createPublishersLibCommunityItem('Managing lower-extremity osteomyelitis locally with surgical debridement and synthetic calcium sulfate antibiotic tablets.', 
    										'Gauland, C.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'Adv Skin Wound Care, 20111. 24(11): p. 515-23', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
    	Community_Items__c commItem4 = CommunityUtilities.createPublishersLibCommunityItem('Osteomyelitis Control by Debridement and Local Antimicrobial Release.', 
    										'Gauland, C.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 
    										'The 15th Malvem Diabetic Foot Conference. 2014: Malvem, Worchestershire, UK.', 
    										'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');			
    	insert new List<Community_Items__c>{commItem1, commItem2, commItem3, commItem4};
    	
    	Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(commItem1.Id, '');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(commItem2.Id, '');
        Community_Item_Permission_Link__c commlink3 = CommunityUtilities.createPermissionLink(commItem3.Id, '');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(commItem4.Id, '');
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink3, commlink4};
        
        List<String> keywords = new List<String>{'Gauland, C.','Howlin'};
        Id [] fixedSearchResults= new Id[]{commItem1.Id, commItem3.Id, commItem4.Id};
        Test.setFixedSearchResults(fixedSearchResults);
       
        Test.startTest();
        	List<CommunityItemWrapper> commItems = CommunityController.searchPublications(keywords);
        Test.stopTest();
        
        System.assertEquals(3, commItems.size());
    }
    
    static testMethod void testGetCommunityItemRecordsforTOI() 
    {    	
        Community_Items__c toiRecord1 = CommunityUtilities.createTopicOfInterestCommunityItem(
        														'CMS’s proposed rule for hospitals: Reduce antibiotic use or exit Medicare',
        														'CMS released a proposed rule change to its Conditions of Participation which would, among other changes, require hospitals to implement antibiotic stewardship programs in order to participate in Medicare and Medicaid. Studies have shown that stewardship programs may lower the use of antibiotics by almost 20 percent and have linked such programs to a drop in infection rates.' 
        																					);        														
        Community_Items__c toiRecord2 = CommunityUtilities.createTopicOfInterestCommunityItem(         														
        														'The 2,597 hospitals facing readmissions penalties this year',
        														'CMS will withhold more than $500 million in payments under its readmissions reduction program.'
        														);
        Community_Items__c toiRecord3 = CommunityUtilities.createTopicOfInterestCommunityItem(
        														'A mechanical jack-like mechanism drives spontaneous fracture healing in neonatal mice.',
        														'The Traditional view of fracture healing is being challenged by a new study published in Developmental Cell which has revealed that a fractured arm bone in new-born mice can rapidly realign through a previously unknown mechanism involving bone growth and muscle contraction.'
        														);
        Community_Items__c toiRecord4 = CommunityUtilities.createTopicOfInterestCommunityItem( 
        														'Ontario scientist thinks old drugs could become our new antibiotics',
        														'As the world loses its upper hand in the antibiotics arms race, it raises the spectre of untreatable infections resulting from routine surgeries. But a Canadian scientist has discovered a surprising source of potential antibiotic options.'
        														);	
        Community_Items__c toiRecord5 = CommunityUtilities.createTopicOfInterestCommunityItem( 
        														'Top 50 Hospitals for orthopedics in the U.S.',
        														'Nearly 2 million hospital inpatients per year face surgery or special care that poses unusual technical challenges or significantly increased risk of death or harm because of age, physical condition or existing conditions. U.S. News and World Report rankings provide a tool to help such patients find especially skilled inpatient care'
        														);	
        Community_Items__c toiRecord6 = CommunityUtilities.createTopicOfInterestCommunityItem( 
        														'Tasmanian devil milk fights superbugs',
        														'According to Australian researchers, milk from Tasmanian devils could offer up a useful weapon against antibiotic-resistant superbugs. The marsupials milk contains important peptides that appear to be able to kill hard-to-treat infections, including MRSA.'
        														);																													
        															
        insert new List<Community_Items__c>{toiRecord1, toiRecord2, toiRecord3, toiRecord4, toiRecord5, toiRecord6};
        
        Community_Item_Permission_Link__c commlink1 = CommunityUtilities.createPermissionLink(toiRecord1.Id, '');
        Community_Item_Permission_Link__c commlink2 = CommunityUtilities.createPermissionLink(toiRecord2.Id, '');
        Community_Item_Permission_Link__c commlink4 = CommunityUtilities.createPermissionLink(toiRecord4.Id, '');
        Community_Item_Permission_Link__c commlink5 = CommunityUtilities.createPermissionLink(toiRecord5.Id, '');
        Community_Item_Permission_Link__c commlink6 = CommunityUtilities.createPermissionLink(toiRecord6.Id, '');
        
        insert new List<Community_Item_Permission_Link__c>{commlink1, commlink2, commlink4, commlink5, commlink6};
        
        
        Test.startTest();
        	List<CommunityItemWrapper> commItems = CommunityController.getCommunityItemRecords('Topic of Interest / Notices', 5);
        Test.stopTest();
        
        System.assertEquals(5, commItems.size());        																																																					
    }
    
    static testMethod void testCreateCommunityStat() 
    { 
        Community_Items__c toiRecord1 = CommunityUtilities.createTopicOfInterestCommunityItem(
        														'CMS’s proposed rule for hospitals: Reduce antibiotic use or exit Medicare',
        														'CMS released a proposed rule change to its Conditions of Participation which would, among other changes, require hospitals to implement antibiotic stewardship programs in order to participate in Medicare and Medicaid. Studies have shown that stewardship programs may lower the use of antibiotics by almost 20 percent and have linked such programs to a drop in infection rates.' 
        																					);        	
        insert toiRecord1;
        
        Test.startTest();
        	CommunityController.createCommunityStatRemote(toiRecord1.Id);
        Test.stopTest();
        
        List<Community_Stat__c> communityStats = [Select Id, User__c, Community_Item__c from Community_Stat__c];
        System.assert(communityStats != null);
        System.assertEquals(1, communityStats.size());
    }
}