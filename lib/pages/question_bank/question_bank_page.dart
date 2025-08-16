import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../config_manager.dart';
import '../../utils/asset_manager.dart';
import 'question_list_page.dart';

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  List<QuestionModule> modules = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> tagGroups = [];
  bool isLoadingCategories = false;
  String? errorMessage;
  bool isTagView = false; // 是否为标签视图模式

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadCategories().then((_) {
      // 启动时自动加载题库分类为模块
      _autoLoadCategoriesAsModules();
    });
  }

  // 加载保存的模块
  void _loadModules() {
    setState(() {
      modules = ConfigManager.getQuestionModules();
    });
  }

  // 加载题目分类
  Future<void> _loadCategories() async {
    try {
      setState(() {
        isLoadingCategories = true;
        errorMessage = null;
      });

      final data = await AssetManager.loadJsonData(AssetManager.sampleQuestionsData);
      final categoriesList = data['categories'] as List;
      
      setState(() {
         categories = categoriesList.cast<Map<String, dynamic>>();
         _generateTagGroups();
         isLoadingCategories = false;
       });
    } catch (e) {
      setState(() {
        errorMessage = '加载题目分类失败: $e';
        isLoadingCategories = false;
      });
    }
  }

  // 生成标签分组
  void _generateTagGroups() {
    final Map<String, List<Map<String, dynamic>>> tagMap = {};
    
    for (final category in categories) {
      final questions = category['questions'] as List;
      for (final question in questions) {
        final tags = question['tags'] as List;
        for (final tag in tags) {
          final tagStr = tag.toString();
          if (!tagMap.containsKey(tagStr)) {
            tagMap[tagStr] = [];
          }
          tagMap[tagStr]!.add({
            ...question,
            'categoryId': category['id'],
            'categoryName': category['name'],
          });
        }
      }
    }
    
    tagGroups = tagMap.entries.map((entry) => {
      'name': entry.key,
      'questions': entry.value,
      'count': entry.value.length,
    }).toList();
    
    // 按题目数量排序
    tagGroups.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  // 启动时自动加载分类为模块（无需用户确认）
  Future<void> _autoLoadCategoriesAsModules() async {
    if (categories.isEmpty) {
      return;
    }

    // 检查是否已经有模块，如果有则不自动加载
    if (modules.isNotEmpty) {
      return;
    }

    final newModules = categories.map((category) {
      return QuestionModule(
        name: category['name'],
        icon: _mapCategoryIconToModuleIcon(category['icon'] ?? 'folder'),
      );
    }).toList();

    // 添加新模块
    for (final module in newModules) {
      await ConfigManager.addQuestionModule(module.name, icon: module.icon);
    }

    _loadModules();
    
    print('自动加载了 ${newModules.length} 个分类模块');
  }

  // 显示输入框来加载题库分类
  Future<void> _loadCategoriesAsModules() async {
    final TextEditingController urlController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加载题库分类'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '请输入题库文件的URL或路径:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: '例如: https://example.com/questions.json',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  autofocus: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Text(
                  '支持本地文件路径或网络URL',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (urlController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(urlController.text.trim());
                }
              },
              child: const Text('加载'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _loadCategoriesFromUrl(result);
    }
  }

  // 从URL加载分类数据
  Future<void> _loadCategoriesFromUrl(String url) async {
    try {
      setState(() {
        isLoadingCategories = true;
        errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在从 $url 加载题库数据...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 检查是否在Web环境中运行
      if (kIsWeb) {
        // 在Web环境中，由于CORS限制，我们需要使用代理或者提供示例数据
        await _handleWebEnvironmentLoad(url);
        return;
      }

      // 发起HTTP请求获取网页内容（仅在非Web环境中）
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        // 解析HTML内容
        final document = html_parser.parse(response.body);
        final extractedData = _extractQuestionsFromHtml(document, url);
        
        if (extractedData.isNotEmpty) {
          // 将提取的数据转换为分类格式
          final newCategories = [{
            'id': 'web_extracted_${DateTime.now().millisecondsSinceEpoch}',
            'name': extractedData['title'] ?? '网页提取题库',
            'icon': 'web',
            'questions': extractedData['questions'] ?? [],
          }];
          
          setState(() {
            categories.addAll(newCategories);
            _generateTagGroups();
            isLoadingCategories = false;
          });
          
          // 自动创建模块
          await _createModulesFromExtractedData(newCategories);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功提取 ${extractedData['questions']?.length ?? 0} 道题目'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('未能从网页中提取到有效的题目内容');
        }
      } else {
        throw Exception('网页请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = '加载题库失败: $e';
        isLoadingCategories = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // 从HTML文档中提取问题和答案
  Map<String, dynamic> _extractQuestionsFromHtml(dom.Document document, String url) {
    List<Map<String, dynamic>> questions = [];
    String title = '网页提取题库';
    
    try {
      // 提取页面标题
      final titleElement = document.querySelector('title');
      if (titleElement != null) {
        title = titleElement.text.trim();
        // 清理标题，移除网站名称等
        if (title.contains(' - ')) {
          title = title.split(' - ')[0];
        }
      }
      
      // 针对掘金文章的特殊处理
      if (url.contains('juejin.cn')) {
        questions = _extractFromJuejin(document);
      } else {
        // 通用提取逻辑
        questions = _extractGenericQuestions(document);
      }
      
    } catch (e) {
      print('提取内容时出错: $e');
    }
    
    return {
      'title': title,
      'questions': questions,
    };
  }
  
  // 从掘金文章中提取问题
  List<Map<String, dynamic>> _extractFromJuejin(dom.Document document) {
    List<Map<String, dynamic>> questions = [];
    
    try {
      // 查找文章内容区域
      final contentElement = document.querySelector('.markdown-body') ?? 
                           document.querySelector('.article-content') ??
                           document.querySelector('article');
      
      if (contentElement != null) {
        // 查找所有可能是问题的元素（通常以数字开头或包含问号）
        final elements = contentElement.querySelectorAll('h1, h2, h3, h4, h5, h6, p, li');
        
        String currentQuestion = '';
        String currentAnswer = '';
        bool isCollectingAnswer = false;
        
        for (final element in elements) {
          final text = element.text.trim();
          
          // 检查是否是问题（包含数字开头、问号、或特定关键词）
          if (_isQuestionText(text)) {
            // 保存上一个问题
            if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
              questions.add({
                'id': 'q_${questions.length + 1}',
                'question': currentQuestion,
                'answer': currentAnswer,
                'type': 'text',
                'difficulty': 'medium',
                'tags': _extractTags(currentQuestion),
              });
            }
            
            currentQuestion = _cleanQuestionText(text);
            currentAnswer = '';
            isCollectingAnswer = true;
          } else if (isCollectingAnswer && text.isNotEmpty) {
            // 收集答案内容
            if (currentAnswer.isNotEmpty) {
              currentAnswer += '\n\n';
            }
            currentAnswer += text;
          }
        }
        
        // 保存最后一个问题
        if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
          questions.add({
            'id': 'q_${questions.length + 1}',
            'question': currentQuestion,
            'answer': currentAnswer,
            'type': 'text',
            'difficulty': 'medium',
            'tags': _extractTags(currentQuestion),
          });
        }
      }
    } catch (e) {
      print('从掘金提取内容时出错: $e');
    }
    
    return questions;
  }
  
  // 通用问题提取逻辑
  List<Map<String, dynamic>> _extractGenericQuestions(dom.Document document) {
    List<Map<String, dynamic>> questions = [];
    
    try {
      // 查找所有标题元素，通常问题会以标题形式出现
      final headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
      
      for (int i = 0; i < headings.length; i++) {
        final heading = headings[i];
        final questionText = heading.text.trim();
        
        if (_isQuestionText(questionText)) {
          String answer = '';
          
          // 查找下一个标题之前的所有内容作为答案
          dom.Element? nextElement = heading.nextElementSibling;
          while (nextElement != null && !['H1', 'H2', 'H3', 'H4', 'H5', 'H6'].contains(nextElement.localName?.toUpperCase())) {
            final text = nextElement.text.trim();
            if (text.isNotEmpty) {
              if (answer.isNotEmpty) answer += '\n\n';
              answer += text;
            }
            nextElement = nextElement.nextElementSibling;
          }
          
          if (answer.isNotEmpty) {
            questions.add({
              'id': 'q_${questions.length + 1}',
              'question': _cleanQuestionText(questionText),
              'answer': answer,
              'type': 'text',
              'difficulty': 'medium',
              'tags': _extractTags(questionText),
            });
          }
        }
      }
    } catch (e) {
      print('通用提取时出错: $e');
    }
    
    return questions;
  }
  
  // 判断文本是否是问题
  bool _isQuestionText(String text) {
    if (text.length < 5) return false;
    
    // 检查是否包含问号
    if (text.contains('？') || text.contains('?')) return true;
    
    // 检查是否以数字开头（如 "1.什么是..."）
    if (RegExp(r'^\d+[.、]').hasMatch(text)) return true;
    
    // 检查是否包含常见的问题关键词
    final questionKeywords = ['什么是', '如何', '怎么', '为什么', '说说', '解释', '描述', '比较', '区别', '优缺点', '原理', '实现', '使用'];
    for (final keyword in questionKeywords) {
      if (text.contains(keyword)) return true;
    }
    
    return false;
  }
  
  // 清理问题文本
  String _cleanQuestionText(String text) {
    // 移除序号
    text = text.replaceAll(RegExp(r'^\d+[.、]\s*'), '');
    // 移除多余的空白字符
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
  
  // 从问题文本中提取标签
  List<String> _extractTags(String questionText) {
    List<String> tags = [];
    
    // 技术相关标签
    final techKeywords = {
      'HTML': ['html', 'HTML', '标签', '语义化'],
      'CSS': ['css', 'CSS', '样式', '布局', '选择器'],
      'JavaScript': ['js', 'javascript', 'JS', 'JavaScript', '函数', '变量'],
      'Vue': ['vue', 'Vue', 'VUE'],
      'React': ['react', 'React', 'REACT'],
      'HTTP': ['http', 'HTTP', '请求', '响应'],
      '浏览器': ['浏览器', 'browser', '渲染'],
      '前端': ['前端', 'frontend'],
    };
    
    for (final entry in techKeywords.entries) {
      for (final keyword in entry.value) {
        if (questionText.toLowerCase().contains(keyword.toLowerCase())) {
          tags.add(entry.key);
          break;
        }
      }
    }
    
    // 如果没有找到特定标签，添加通用标签
    if (tags.isEmpty) {
      tags.add('通用');
    }
    
    return tags;
  }
  
  // 处理Web环境下的加载
   Future<void> _handleWebEnvironmentLoad(String url) async {
     setState(() {
       isLoadingCategories = false;
     });
     
     // 显示CORS限制说明对话框
     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: const Text('Web环境限制'),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Text('由于浏览器的CORS（跨域资源共享）安全限制，无法直接从网页抓取内容。'),
               const SizedBox(height: 16),
               const Text('建议的解决方案：'),
               const SizedBox(height: 8),
               const Text('1. 使用移动端应用（Android/iOS）'),
               const Text('2. 手动复制网页内容到本地文件'),
               const Text('3. 使用支持CORS的代理服务'),
               const SizedBox(height: 16),
               Text('目标URL: $url', style: const TextStyle(fontSize: 12, color: Colors.grey)),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () {
                 Navigator.of(context).pop();
                 _loadSampleData();
               },
               child: const Text('加载示例数据'),
             ),
             TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: const Text('确定'),
             ),
           ],
         );
       },
     );
   }
   
   // 加载示例数据
   Future<void> _loadSampleData() async {
     try {
       final sampleQuestions = [
         {
           'id': 'web_sample_1',
           'question': '什么是跨域资源共享(CORS)?',
           'answer': 'CORS是一种安全机制，允许或限制网页从一个域向另一个域发起请求。它通过HTTP头来控制跨域访问。',
           'type': 'text',
           'difficulty': 'medium',
           'tags': ['Web', 'HTTP', '安全'],
         },
         {
           'id': 'web_sample_2',
           'question': '如何解决CORS问题?',
           'answer': '可以通过服务器设置Access-Control-Allow-Origin头、使用代理服务器、或者使用JSONP等方式来解决CORS问题。',
           'type': 'text',
           'difficulty': 'medium',
           'tags': ['Web', 'HTTP', '解决方案'],
         },
         {
           'id': 'web_sample_3',
           'question': 'Flutter Web有哪些限制?',
           'answer': 'Flutter Web主要限制包括：文件系统访问受限、网络请求受CORS限制、某些原生功能不可用、性能相比原生应用较低等。',
           'type': 'text',
           'difficulty': 'medium',
           'tags': ['Flutter', 'Web', '限制'],
         },
       ];
 
       final newCategories = [{
         'id': 'web_sample_${DateTime.now().millisecondsSinceEpoch}',
         'name': 'Web环境示例题库',
         'icon': 'web',
         'questions': sampleQuestions,
       }];
       
       setState(() {
         categories.addAll(newCategories);
         _generateTagGroups();
       });
       
       await _createModulesFromExtractedData(newCategories);
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('已加载 ${sampleQuestions.length} 道示例题目'),
           backgroundColor: Colors.green,
         ),
       );
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('加载示例数据失败: $e'),
           backgroundColor: Colors.red,
         ),
       );
     }
   }

  // 从提取的数据创建模块
  Future<void> _createModulesFromExtractedData(List<Map<String, dynamic>> newCategories) async {
    for (final category in newCategories) {
      final moduleName = category['name'];
      final moduleIcon = _mapCategoryIconToModuleIcon(category['icon'] ?? 'web');
      
      // 检查是否已存在同名模块
      final existingModule = modules.firstWhere(
        (module) => module.name == moduleName,
        orElse: () => QuestionModule(name: '', icon: ''),
      );
      
      if (existingModule.name.isEmpty) {
        await ConfigManager.addQuestionModule(moduleName, icon: moduleIcon);
      }
    }
    
    _loadModules();
  }

  // 获取响应式列数
  int _getResponsiveCrossAxisCount(double width) {
    if (width > 1200) {
      return 5;
    } else if (width > 900) {
      return 4;
    } else if (width > 600) {
      return 3;
    } else if (width > 400) {
      return 2;
    } else {
      return 1;
    }
  }

  // 映射分类图标到模块图标
  String _mapCategoryIconToModuleIcon(String categoryIcon) {
    switch (categoryIcon.toLowerCase()) {
      case 'web':
        return 'code';
      case 'server':
        return 'computer';
      case 'mobile':
        return 'phone_android';
      case 'database':
        return 'storage';
      default:
        return 'folder';
    }
  }

  // 可选图标列表
  final List<Map<String, dynamic>> availableIcons = [
    {'name': 'folder', 'icon': Icons.folder, 'label': '文件夹'},
    {'name': 'book', 'icon': Icons.book, 'label': '书本'},
    {'name': 'code', 'icon': Icons.code, 'label': '代码'},
    {'name': 'computer', 'icon': Icons.computer, 'label': '计算机'},
    {'name': 'psychology', 'icon': Icons.psychology, 'label': '心理学'},
    {'name': 'business', 'icon': Icons.business, 'label': '商务'},
    {'name': 'science', 'icon': Icons.science, 'label': '科学'},
    {'name': 'language', 'icon': Icons.language, 'label': '语言'},
    {'name': 'design_services', 'icon': Icons.design_services, 'label': '设计'},
    {'name': 'engineering', 'icon': Icons.engineering, 'label': '工程'},
    {'name': 'account_balance', 'icon': Icons.account_balance, 'label': '金融'},
    {'name': 'data_object', 'icon': Icons.data_object, 'label': '数据'},
  ];

  // 添加新模块
  Future<void> _addModule() async {
    final TextEditingController controller = TextEditingController();
    String selectedIcon = 'folder';
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新增模块'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '请输入模块名称',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text('选择图标:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: availableIcons.length,
                        itemBuilder: (context, index) {
                          final iconData = availableIcons[index];
                          final isSelected = selectedIcon == iconData['name'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIcon = iconData['name'];
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    iconData['icon'],
                                    size: 24,
                                    color: isSelected ? Colors.blue : Colors.grey[600],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    iconData['label'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected ? Colors.blue : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.of(context).pop({
                        'name': controller.text.trim(),
                        'icon': selectedIcon,
                      });
                    }
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result['name']!.isNotEmpty) {
      await ConfigManager.addQuestionModule(result['name']!, icon: result['icon']!);
      _loadModules();
    }
  }

  // 删除模块
  Future<void> _deleteModule(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除模块'),
          content: Text('确定要删除"${modules[index].name}"模块吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await ConfigManager.removeQuestionModule(modules[index].name);
      _loadModules();
    }
  }

  // 显示删除选项（长按触发）
  void _showDeleteOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('删除 "${modules[index].name}"'),
                subtitle: const Text('此操作不可撤销'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteModule(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑模块'),
                subtitle: const Text('修改模块名称和图标'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editModule(index);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 编辑模块
  Future<void> _editModule(int index) async {
    final TextEditingController controller = TextEditingController(text: modules[index].name);
    String selectedIcon = modules[index].icon;
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('编辑模块'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: '模块名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('选择图标:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((iconData) {
                        final isSelected = selectedIcon == iconData['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = iconData['name'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconData['icon'],
                                  color: isSelected ? Colors.blue : Colors.grey,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  iconData['label'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.blue : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.of(context).pop({
                        'name': controller.text.trim(),
                        'icon': selectedIcon,
                      });
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // 更新模块
      final oldModule = modules[index];
      await ConfigManager.removeQuestionModule(oldModule.name);
      await ConfigManager.addQuestionModule(
        result['name']!,
        icon: result['icon']!,
      );
      _loadModules();
    }
  }
  
  // 获取图标
  IconData _getIconData(String iconName) {
    final iconData = availableIcons.firstWhere(
      (icon) => icon['name'] == iconName,
      orElse: () => availableIcons[0],
    );
    return iconData['icon'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTagView ? '标签视图' : '分类视图'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isTagView = !isTagView;
              });
            },
            icon: Icon(isTagView ? Icons.category : Icons.tag),
            tooltip: isTagView ? '切换到分类视图' : '切换到标签视图',
          ),
          if (!isTagView) ...[
             IconButton(
               onPressed: _loadCategoriesAsModules,
               icon: const Icon(Icons.download),
               tooltip: '加载题库分类',
             ),
             IconButton(
               onPressed: _addModule,
               icon: const Icon(Icons.add),
               tooltip: '新增模块',
             ),
           ]
        ],
      ),
      body: isTagView ? _buildTagView() : _buildModuleView(),
      floatingActionButton: !isTagView ? FloatingActionButton(
        onPressed: _addModule,
        tooltip: '新增模块',
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  // 构建标签视图
  Widget _buildTagView() {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (tagGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              '暂无标签数据',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '请等待数据加载完成',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getResponsiveCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: tagGroups.length,
          itemBuilder: (context, index) {
            final tagGroup = tagGroups[index];
            return Card(
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('标签"${tagGroup['name']}"包含 ${tagGroup['count']} 道题目'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          tagGroup['count'].toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tagGroup['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tagGroup['count']} 道题目',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 构建模块视图
  Widget _buildModuleView() {
    if (modules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              '暂无题库模块',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '点击右上角"+"按钮添加新模块',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getResponsiveCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return Card(
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final category = categories.firstWhere(
                    (cat) => cat['name'] == module.name,
                    orElse: () => <String, dynamic>{},
                  );
                  
                  if (category.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionListPage(
                          categoryId: category['id'],
                          categoryName: category['name'],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('未找到${module.name}对应的题目'),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  _showDeleteOptions(context, index);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconData(module.icon),
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        module.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}