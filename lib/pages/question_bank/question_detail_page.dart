import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/question.dart';

class QuestionDetailPage extends StatefulWidget {
  final Question question;
  final String categoryName;

  const QuestionDetailPage({
    super.key,
    required this.question,
    required this.categoryName,
  });

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  bool showAnswer = false;
  bool showAiAnswer = false;
  bool isInWrongAnswers = false;

  @override
  void initState() {
    super.initState();
    _checkWrongAnswerStatus();
  }

  Future<void> _checkWrongAnswerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final wrongAnswers = prefs.getStringList('wrong_answers') ?? [];
    setState(() {
      isInWrongAnswers = wrongAnswers.contains(widget.question.id.toString());
    });
  }

  Future<void> _toggleWrongAnswer() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> wrongAnswers = prefs.getStringList('wrong_answers') ?? [];
    
    if (isInWrongAnswers) {
      wrongAnswers.remove(widget.question.id.toString());
      // 同时从详细信息中移除
      final wrongAnswerDetails = prefs.getStringList('wrong_answer_details') ?? [];
      wrongAnswerDetails.removeWhere((json) {
        final detail = jsonDecode(json);
        return detail['id'] == widget.question.id;
      });
      await prefs.setStringList('wrong_answer_details', wrongAnswerDetails);
    } else {
      wrongAnswers.add(widget.question.id.toString());
      // 同时保存题目详细信息
      final wrongAnswerDetails = prefs.getStringList('wrong_answer_details') ?? [];
      final questionDetail = {
        'id': widget.question.id,
        'question': widget.question.question,
        'answer': widget.question.answer,
        'ai_answer': widget.question.aiAnswer,
        'difficulty': widget.question.difficulty,
        'tags': widget.question.tags,
        'category': widget.categoryName,
        'addedAt': DateTime.now().toIso8601String(),
      };
      wrongAnswerDetails.add(jsonEncode(questionDetail));
      await prefs.setStringList('wrong_answer_details', wrongAnswerDetails);
    }
    
    await prefs.setStringList('wrong_answers', wrongAnswers);
    setState(() {
      isInWrongAnswers = !isInWrongAnswers;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isInWrongAnswers ? '已添加到错题本' : '已从错题本移除'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '简单';
      case 'medium':
        return '中等';
      case 'hard':
        return '困难';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('题目 #${widget.question.id}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目内容
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '问题:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.question.question,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 答案区域
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '答案:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showAnswer)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.question.answer,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showAnswer = true;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击此区域查看答案',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // AI答案区域
            if (widget.question.aiAnswer != null && widget.question.aiAnswer!.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI答案:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (showAiAnswer)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: MarkdownBody(
                            data: widget.question.aiAnswer!,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14, height: 1.5),
                              h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              code: TextStyle(
                                backgroundColor: Colors.grey[200],
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showAiAnswer = true;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.smart_toy_outlined,
                                  color: Colors.blue[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击此区域查看AI答案',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // 题目信息
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '题目信息:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '难度: ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(widget.question.difficulty),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getDifficultyText(widget.question.difficulty),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.question.tags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        '标签: ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.question.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _toggleWrongAnswer,
            icon: Icon(
              isInWrongAnswers ? Icons.bookmark_remove : Icons.bookmark_add,
            ),
            label: Text(
              isInWrongAnswers ? '从错题本移除' : '添加到错题本',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isInWrongAnswers ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}