//
//  Login.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/13.
//  Copyright © 2019 周向真. All rights reserved.
//

import SwiftUI
import Combine

class UserInfoModel: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    var userInfo: UserInfo? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var error: APIError? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var querying: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func login(name: String, password: String) {
        querying = true
        LeetCodeService.shared.login(name: name, password: password) { (result) in
            self.querying = false
            switch result {
            case .failure(let error):
                self.error = error
            case .success(let info):
                self.userInfo = info
            }
        }
    }
}

struct Login: View {
    @ObservedObject var userInfo = UserInfoModel()
    
    @State var name: String = ""
    @State var password: String = ""
    @State var quering: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Name")
                    .frame(width: 120.0)
                TextField("User Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Text("Password")
                    .frame(width: 120.0)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button(action: {
                print("name: \(self.name),  password: \(self.password)")
                self.quering = true
                self.userInfo.login(name: self.name, password: self.password)
                }, label: {Text("Log in")})
                .disabled(buttonDisabled)
            
            Spacer()
            
            HStack {
                Text("Error: ")
                Text(userInfo.error != nil ? "Errors" : "No Errors")
            }
            
            HStack {
                Text("Token: ")
                Text("\(userInfo.userInfo?.token ?? "No Token")")
            }
            
            HStack {
                Text("Session: ")
                Text("\(userInfo.userInfo?.session ?? "No Token")")
            }
        }.padding()
    }
    
    var buttonDisabled: Bool {
        name.count < 2 || password.count < 2 || userInfo.querying
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
#endif
