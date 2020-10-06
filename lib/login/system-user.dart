
class SystemUser {

  String email;
  String role;

  static List<SystemUser> systemUsers = [
    SystemUser(email: "elintegro.himalaya@gmail.com", role: "SUPER_USER"),
    SystemUser(email: "kumarsamip03sc@gmail.com", role: "TEAM_MEMBER"),
    SystemUser(email: "aharonmarkus@gmail.com", role: "TEAM_MEMBER"),
    SystemUser(email: "shai200@gmail.com", role: "TEAM_MEMBER"),
    SystemUser(email: "eugenelip@gmail.com", role: "TEAM_MEMBER"),
  ];

  SystemUser({this.email, this.role});

  static String getRole(String email){
    String role = "ROLE_CUSTOMER";
    for(var i=0;i<systemUsers.length;i++){
      if(systemUsers[i].email == email){
        role= systemUsers[i].role;
        break;
      }
    }
    return role;
  }

  static void setSystemUsers(Map<String, dynamic> json) {
    // return SystemUser(
    //   email: json['email'],
    //   role: json['role'],
    // );
  }

}
