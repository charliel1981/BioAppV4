/**
*	@description : Wrapper class to create/update dof signarure in document
**/
public with sharing class DOFSignatureAsDocument {
	
	public DOF__c dofRecord;

	private Document document;


	/**
	*	@description : Constructor
	* 	@param dofRecord dof record 
	* 	@param folderId Id of the folder the document sits under
	**/
	public DOFSignatureAsDocument(DOF__c dofRecord, Id folderId){
		this.dofRecord = dofRecord;
		this.document = new Document(FolderId = folderId,ContentType = 'image/png',Name= (Test.isRunningTest() ? 'Test' : dofRecord.Name),IsPublic = true);
	}

	/**
	*	@description : Method to update the encoded signature in the document 
	* 	@return Document updated document record
	**/
	public Document updateSignatureInDocument(Id documentId){
		this.document.Body = EncodingUtil.base64Decode(this.dofRecord.Signature_Capture__c.removeStart('data:image/png;base64,'));
		if(documentId != null) this.document.Id =  documentId;
		return this.document;
	}

	/**
	*	@description : Method to update ddocument id in dof record
	**/
	public void updateDocumentIdInDof(){
		this.dofRecord.Signature_Capture_Document_Id__c = this.document.Id;
	}
}