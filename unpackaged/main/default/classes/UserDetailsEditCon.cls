public class UserDetailsEditCon {
    
     
    public PageReference cancelDetails() {
        return new pagereference('/biocomp');
    }


    public PageReference saveDetails() {

        update userObj ;
        
        if(userObj != null && userObj.ContactId != null)
        {
          
          Contact conObj = [select firstname,LastName,Email,Phone from Contact where id=:userObj.ContactId];
          conObj.FirstName  = userObj .FirstName;
          conObj.LastName= userObj .LastName;
          conObj.Email= userObj .Email;
          conObj.Phone= userObj .Phone;
          update conObj;
        }
        return new pagereference('/apex/biocomp');
    }

public User userObj{set;get;}

    public UserDetailsEditCon()
    {
        userObj = new User();
        userObj = [select Firstname,LastName,Id,Email,Phone,CompanyName,ContactId from User where id=:userinfo.getUserId()];   
    }
}