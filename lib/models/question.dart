class Question {
  final int id;
  final String question;
  final String answer;
  final String? aiAnswer;
  final String difficulty;
  final List<String> tags;

  Question({
    required this.id,
    required this.question,
    required this.answer,
    this.aiAnswer,
    required this.difficulty,
    required this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      aiAnswer: json['ai_answer'],
      difficulty: json['difficulty'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'aiAnswer': aiAnswer,
      'difficulty': difficulty,
      'tags': tags,
    };
  }
}