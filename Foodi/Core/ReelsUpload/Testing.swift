import SwiftUI

struct TestView: View {

    @State var showPostTypeMenu: Bool = true
    
    var body: some View {
        ZStack {
            VStack {
                Text("Welcome to the App!")
                    .padding()
            }
            
        }
        

    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}

