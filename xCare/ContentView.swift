import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    var title: String
    var isDone: Bool = false
}

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Input field + Add button
                HStack {
                    TextField("Enter new task", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: addTask) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding(.top)

                // Task List
                List {
                    ForEach($tasks) { $task in
                        HStack {
                            Button(action: {
                                task.isDone.toggle()
                            }) {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isDone ? .green : .gray)
                            }

                            Text(task.title)
                                .strikethrough(task.isDone, color: .gray)
                                .foregroundColor(task.isDone ? .gray : .primary)
                        }
                    }
                    .onDelete(perform: deleteTask)
                }
            }
            .navigationTitle("My To-Do List")
            .toolbar {
                EditButton()
            }
        }
    }

    // MARK: - Functions
    private func addTask() {
        let task = Task(title: newTaskTitle)
        tasks.append(task)
        newTaskTitle = ""
    }

    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}

