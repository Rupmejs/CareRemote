import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    var title: String
    var isDone: Bool = false
}

struct contentView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Input field + Add button
            HStack {
                TextField("Enter new task", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 200)

                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .disabled(newTaskTitle.isEmpty)
            }
            .padding()

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

                        Spacer()

                        // Trash button
                        Button(action: {
                            deleteTask(task: task)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle()) // macOS requirement
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(minWidth: 300, minHeight: 400)
        }
        .padding()
    }

    // MARK: - Functions
    private func addTask() {
        let task = Task(title: newTaskTitle)
        tasks.append(task)
        newTaskTitle = ""
    }

    private func deleteTask(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
    }
}

#Preview {
    ContentView()
}
