import 'dart:ui';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String subject;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.subject,
  });
}

class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String type;
  bool isCompleted;
  final Offset position;
  final QuizQuestion? quiz;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.type,
    required this.position,
    this.isCompleted = false,
    this.quiz,
  });

  static final List<QuizQuestion> _allQuestions = [
    const QuizQuestion(subject: '🔬 Science', question: 'What is the chemical symbol for water?', options: ['WA', 'H2O', 'HO2', 'W2O'], correctIndex: 1),
    const QuizQuestion(subject: '🔬 Science', question: 'What planet is closest to the Sun?', options: ['Venus', 'Earth', 'Mercury', 'Mars'], correctIndex: 2),
    const QuizQuestion(subject: '🔬 Science', question: 'What gas do plants absorb from the air?', options: ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen'], correctIndex: 2),
    const QuizQuestion(subject: '📐 Math', question: 'What is the square root of 144?', options: ['11', '12', '13', '14'], correctIndex: 1),
    const QuizQuestion(subject: '📐 Math', question: 'What is 15% of 200?', options: ['25', '30', '35', '40'], correctIndex: 1),
    const QuizQuestion(subject: '📐 Math', question: 'How many sides does a hexagon have?', options: ['5', '6', '7', '8'], correctIndex: 1),
    const QuizQuestion(subject: '🌍 Geography', question: 'What is the capital of Japan?', options: ['Beijing', 'Seoul', 'Tokyo', 'Bangkok'], correctIndex: 2),
    const QuizQuestion(subject: '🌍 Geography', question: 'Which is the longest river in the world?', options: ['Amazon', 'Nile', 'Yangtze', 'Mississippi'], correctIndex: 1),
    const QuizQuestion(subject: '💻 Technology', question: 'What does CPU stand for?', options: ['Central Processing Unit', 'Computer Power Unit', 'Central Program Utility', 'Core Processing Unit'], correctIndex: 0),
    const QuizQuestion(subject: '💻 Technology', question: 'Which language is used for web styling?', options: ['HTML', 'Python', 'CSS', 'Java'], correctIndex: 2),
    const QuizQuestion(subject: '📚 English', question: 'What is the synonym of Happy?', options: ['Sad', 'Joyful', 'Angry', 'Tired'], correctIndex: 1),
    const QuizQuestion(subject: '📚 English', question: 'Which word is a noun?', options: ['Run', 'Beautiful', 'Forest', 'Quickly'], correctIndex: 2),
    const QuizQuestion(subject: '🏛️ History', question: 'In which year did World War II end?', options: ['1943', '1944', '1945', '1946'], correctIndex: 2),
    const QuizQuestion(subject: '🏛️ History', question: 'Who invented the telephone?', options: ['Edison', 'Tesla', 'Bell', 'Marconi'], correctIndex: 2),
    const QuizQuestion(subject: '🔬 Science', question: 'How many bones are in the human body?', options: ['196', '206', '216', '226'], correctIndex: 1),
    const QuizQuestion(subject: '🎮 Games', question: 'Which company made Mortal Kombat?', options: ['Capcom', 'NetherRealm', 'Rockstar', 'Ubisoft'], correctIndex: 1),
    const QuizQuestion(subject: '⚙️ Logic', question: 'If all hunters are fast and this hunter is a hunter, then this hunter is?', options: ['Invisible', 'Fast', 'Dead', 'Human'], correctIndex: 1),
  ];

  static List<TaskModel> getForestTasks() => getTasksForRound(1, 3);

  static List<TaskModel> getTasksForRound(int round, int survivorCount) {
    _allQuestions.shuffle();
    final positionsRound1 = <Offset>[
      const Offset(360, 300),
      const Offset(900, 500),
      const Offset(280, 800),
      const Offset(1150, 260),
      const Offset(720, 960),
    ];
    final positionsRound2 = <Offset>[
      const Offset(260, 240),
      const Offset(640, 210),
      const Offset(1050, 280),
      const Offset(1180, 620),
      const Offset(910, 920),
      const Offset(570, 1020),
      const Offset(260, 920),
      const Offset(180, 520),
    ];
    final titles1 = ['Decode the Signal', 'Hack the Terminal', 'Restore Power', 'Seal the Breach', 'Scan the Totem'];
    final titles2 = ['Break the Seal', 'Reboot Core', 'Decrypt Rune', 'Stabilize Rift', 'Charge Obelisk', 'Trigger Beacon', 'Disable Ward', 'Sync Portal'];
    final desc1 = 'Answer the question to complete the objective';
    final desc2 = 'Round 2 challenge — harder zone, faster hunter';

    if (round == 1) {
      const count = 3;
      return List.generate(count, (i) => TaskModel(
            taskId: 'r1_task_${i + 1}',
            title: titles1[i],
            description: desc1,
            type: 'quiz',
            position: positionsRound1[i],
            quiz: _allQuestions[i],
          ));
    }

    final int total = (survivorCount + 3).clamp(4, positionsRound2.length).toInt();
    return List.generate(total, (i) => TaskModel(
          taskId: 'r2_task_${i + 1}',
          title: titles2[i],
          description: desc2,
          type: 'quiz',
          position: positionsRound2[i],
          quiz: _allQuestions[i % _allQuestions.length],
        ));
  }
}
